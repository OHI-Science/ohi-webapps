# create initial Baltic layers based on Global2013.www2013 layers
# Requirements:
#  1. spatial prep
#  1. use RStudio to setup project
#  1. install ohicore: http://ohi-science.org/pages/install.html
#  1. clone of https://github.com/ohi-science/ohibaltic in ../ohicore

library(stringr)
library(git2r)

# vars
# get paths based on host machine
dirs = list(
  neptune_data  = '/Volumes/data_edit', 
  github        = '~/github')

dir_data    = sprintf('%s/git-annex/clip-n-ship/data', dirs['neptune_data']) # 'N:/git-annex/clip-n-ship/data'
dir_repos   = sprintf('%s/clip-n-ship', dirs['github'])
dir_ohicore = sprintf('%s/ohicore', dirs['github'])
dir_global  = sprintf('%s/ohi-global/eez2014', dirs['github'])
sfx_global  = 'global2014'

# read global layers, add clip_n_ship columns from Google version
lyrs_g      = read.csv(file.path(dir_global, 'layers.csv'))
lyrs_google = read.csv(file.path(dir_global, 'temp/layers_0-google.csv'))
lyrs_g = lyrs_g %>%
  left_join(
    lyrs_google %>%
      select(layer, starts_with('clip_n_ship')),
    by='layer')

# load ohicore, development mode
devtools::load_all(dir_ohicore)

# read in github token outside of repo, generated via https://help.github.com/articles/creating-an-access-token-for-command-line-use
token = scan('~/.github-token', 'character')

# get list of countries with prepped data
cntries = list.files(dir_data)

# loop through countries
#for (cntry in cntries){
# DEBUG!
  cntry = 'Albania'  
  
  # repo name
  repo     = sprintf('ohi-%s', tolower(str_replace_all(cntry,fixed(' '),'_')))
  url_repo = sprintf('https://github.com/OHI-Science/%s', repo)
  dir_repo = file.path(dir_repos, repo)

  # create github repo if doesn't exist
  github_repo_exists = system(sprintf('git ls-remote git@github.com:ohi-science/%s.git', repo), ignore.stderr=T) != 128
  if (!github_repo_exists){    
    # create using Github API: https://developer.github.com/v3/repos/#create
    cmd = sprintf('curl -u "bbest:%s" https://api.github.com/orgs/ohi-science/repos -d \'{"name":"%s"}\'', token, repo)
    system(cmd)
  }

  # create dir
  dir.create(dir_repo, recursive=TRUE)
  setwd(dir_repo)

  # intialize repo
  # touch README.md; git init; git add README.md; git commit -m "first commit"; git push -u origin master
  r = init(dir_repo)
  cat(sprintf('# Ocean Health Index - %s', cntry), file=file.path(dir_repo, 'README.md'))
  add(r, 'README.md')
  commit(r, 'add README.md')
  remote_add(r, 'origin', 'https://github.com/OHI-Science/ohi-albania.git')
  system('git push -u origin master')

  # create dirs
  for (dir in c('tmp','layers','conf','spatial')) dir.create(dir, showWarnings=F)

  # copy layers from global
  write.csv(lyrs_g, sprintf('tmp/layers_%s.csv', sfx_global), na='', row.names=F)

  # create spatial if needed
  f_js      = file.path(dir_data, cntry, 'regions_gcs.js')
  f_geojson = file.path(dir_data, cntry, 'regions_gcs.geojson')
  if (!file.exists(f_js)){
    f_shp = file.path(dir_data, cntry, 'rgn_offshore_gcs.shp')
    shp_to_geojson(f_shp, f_js, f_geojson)
  }

  # modify
  lyrs_c = lyrs_g %>%
    select(
      targets, layer, name, description, 
      fld_value, units,
      filename_old=filename,
      starts_with('clip_n_ship')) %>%
    mutate(
      filename = sprintf('%s_%s.csv', layer, sfx_global)) %>%
    arrange(targets, layer)
  write.csv(lyrs_c, 'tmp/layers.csv', na='', row.names=F)

  # csvs for regions and countries
  rgn_new_csv   = file.path(dir_data, cntry, 'rgn_offshore_data.csv') # rgn_new_csv   = file.path(dir_data, cntry, 'rgn_inland25km_data.csv')
  rgn_old_csv   = sprintf('%s/layers/rgn_labels.csv', dir_global)
  cntry_old_csv = sprintf('%s/layers/cntry_rgn.csv', dir_global)

  # old to new regions
  rgn_new = read.csv(rgn_new_csv) %>%
    select(rgn_id_new=rgn_id, rgn_name_new=rgn_name) %>%
    mutate(rgn_name_old = 'Israel') %>%
    merge(
      read.csv(rgn_old_csv, na.strings='') %>%
        select(rgn_name_old=label, rgn_id_old=rgn_id),
      by='rgn_name_old', all.x=T) %>%
    select(rgn_id_new, rgn_name_new, rgn_id_old, rgn_name_old) %>%
    arrange(rgn_name_new)

  # old to new countries
  cntry_new = read.csv(cntry_old_csv) %>%
    select(cntry_key, rgn_id_old=rgn_id) %>%
    merge(
      rgn_new,
      by='rgn_id_old') %>%
    group_by(cntry_key, rgn_id_new) %>%
    summarise(n=n()) %>%
    select(cntry_key, rgn_id_new) %>%
    as.data.frame()


  for (i in 1:nrow(lyrs_c)){ # i=1
    csv_in  = sprintf('%s/layers/%s', dir_global, lyrs_c$filename_old[i])
    csv_out = sprintf('layers/%s', lyrs_c$filename[i])
    
    d = read.csv(csv_in, na.strings='')
    flds = names(d)
    
    if ('rgn_id' %in% names(d)){
      d = d %>%
        filter(rgn_id %in% rgn_new$rgn_id_old) %>%
        merge(rgn_new, by.x='rgn_id', by.y='rgn_id_old') %>%
        mutate(rgn_id=rgn_id_new) %>%
        subset(select=flds)
    }
    
    if ('cntry_key' %in% names(d)){
      d = d %>%
        filter(cntry_key %in% cntry_new$cntry_key)
    }
      
    if (lyrs_c$layer[i]=='rgn_labels'){
      csv_out = sprintf('layers/%s_israel2014.csv', lyrs_c$layer[i])
      lyrs_c$filename[i] = basename(csv_out)
      d = d %>%
        merge(rgn_new, by.x='rgn_id', by.y='rgn_id_new') %>%
        select(rgn_id, type, label=rgn_name_new)
    }
    write.csv(d, csv_out, row.names=F, na='')
    
    if (nrow(d)==0) {
      dir.create('tmp/layers_empty', showWarnings=F)
      file.copy(csv_in, file.path('tmp/layers_empty', lyrs_c$filename[i]))
    }
    
    # downweight: area_offshore, area_offshore_3nm, equal, equal , population_inland25km, 
    
    shp = '/Volumes/data_edit/git-annex/clip-n-ship/data/Albania/rgn_inland25km_mol.shp'
    
    # handle: raster, raster | area_inland1km, raster | area_offshore, raster | area_offshore3nm, raster | equal
    
    
  }

# copy custom layers
for (f in list.files('tmp/layers_custom', full.names=T)){ # f = list.files('tmp/layers_custom', full.names=T)[1]
  file.copy(f, file.path('layers', basename(f)), overwrite=T)  
}

# layers registry
write.csv(select(lyrs_c, -filename_old), 'layers.csv', row.names=F, na='')

# run checks on layers
CheckLayers('layers.csv', 'layers', 
            flds_id=c('rgn_id','cntry_key','country_id','saup_id','fao_id','fao_saup_id'))

# order for layers for substitution old to new name in files
lyrs_c = lyrs_c %>%
  arrange(desc(nchar(as.character(layer_old))))

# copy configuration files
conf_files = c('config.R','functions.R','goals.csv','pressures_matrix.csv','resilience_matrix.csv','resilience_weights.csv')
for (f in conf_files){ # f = conf_files[1]
  
  f_in  = sprintf('%s/conf/%s', dir_global, f)
  f_out = sprintf('conf/%s', f)
  
  # read in file
  s = readLines(f_in, warn=F, encoding='UTF-8')
  
#   # substitute old layer names with new
#   for (i in 1:nrow(lyrs_c)){ # i=1
#     s = gsub(lyrs_c$layer_old[i], lyrs_c$layer[i], s, fixed=T)
#   }
#   writeLines(s, f_out)
  
  # update confugration
  if (f=='config.R'){
    # set map center and zoom level
    s = gsub('map_lat=0; map_lon=0; map_zoom=3', 'map_lat=32.5; map_lon=34.5; map_zoom=8', s) # Israel specific
    # use just rgn_labels (not rgn_global)
    s = gsub('rgn_global', 'rgn_labels', s)
  }
  
  writeLines(s, f_out)
}

# append custom functions to overwrite others
cat(
  paste(c(
    '\n\n\n# CUSTOM FUNCTIONS ----\n',
    readLines('tmp/functions_custom.R', warn=F, encoding='UTF-8')), 
    collapse='\n'), 
  file='conf/functions.R', append=T)
    
# DEBUG: copy custom layers
for (f in list.files('tmp/layers_custom', full.names=T)){ # f = list.files('tmp/layers_custom', full.names=T)[1]
  file.copy(f, file.path('layers', basename(f)), overwrite=T)  
}

# calculate scores
layers = Layers('layers.csv', 'layers')
conf   = Conf('conf') # load_all(dirs$ohicore)
scores = CalculateAll(conf, layers, debug=T)
write.csv(scores, 'scores.csv', na='', row.names=F)

# spatial
for (f in c(f_js, f_geojson)){ # f = f_spatial[1]
  file.copy(f, sprintf('spatial/%s', basename(f)), overwrite=T)
}
 
# save shortcut files not specific to operating system
write_shortcuts('.', os_files=0)

# launch on Mac
system('open launch_app.command')


#} # end for (cntry in cntries)