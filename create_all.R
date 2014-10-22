library(stringr)
library(git2r)
library(dplyr)
library(rgdal)
library(shiny)
library(shinyapps)
library(stringr)
merge = base::merge # override git2r::merge
tags  = shiny::tags # override git2r::tags, otherwise get "Error in tags$head : object of type 'closure' is not subsettable"

# vars
# get paths based on host machine
dirs = list(
  neptune_data  = '/Volumes/data_edit', 
  github        = '~/github')

dir_data    = sprintf('%s/git-annex/clip-n-ship', dirs['neptune_data']) # 'N:/git-annex/clip-n-ship/data'
dir_repos   = sprintf('%s/clip-n-ship', dirs['github'])
dir_ohicore = sprintf('%s/ohicore', dirs['github'])
dir_global  = sprintf('%s/ohi-global/eez2014', dirs['github'])
sfx_global  = 'global2014'
scenario    = 'subcountry2014'
git_branch  = 'master'
tabs_hide   = 'Calculate, Report, Compare'

# load ohicore, development mode
#devtools::load_all(dir_ohicore)# deploy error: The package was installed locally from source. Only packages installed from CRAN, BioConductor and GitHub are supported.
library(ohicore)

# read global layers, add clip_n_ship columns from Google version
lyrs_g      = read.csv(file.path(dir_global, 'layers.csv'))
lyrs_google = read.csv(file.path(dir_global, 'temp/layers_0-google.csv'))
lyrs_g = lyrs_g %>%
  left_join(
    lyrs_google %>%
      select(layer, starts_with('clip_n_ship')),
    by='layer')

# read in github token outside of repo, generated via https://help.github.com/articles/creating-an-access-token-for-command-line-use
token = scan('~/.github-token', 'character')

# get list of countries with prepped data
cntries = list.files(dir_data)

gl_cntry = read.csv(cntry_old_csv)
gl_rgn = read.csv(rgn_old_csv, na.strings='') %>%
  mutate(
    label = plyr::revalue(label, c('R_union'='Reunion'))) %>% arrange(label)

# loop through countries
#for (i in 1:length(cntries)){ # i=1
for (i in 108:length(cntries)){ # i=76   # which(cntries=='Pakistan')
  
  # setup vars
  Country   = str_replace_all(cntries[i], '_', ' ')
  cntry     = tolower(cntries[i])
  repo_name = sprintf('ohi-%s', cntry)
  git_url  = sprintf('https://github.com/OHI-Science/%s', repo_name)
  dir_repo  = file.path(dir_repos, repo_name)
  dir_app   = file.path(dir_data, cntries[i], 'shinyapps.io')
  app_name  = cntry
  cat(sprintf('\n\n\n\n%03d of %d: %s -- %s\n', i, length(cntries), Country, format(Sys.time(), '%X')))  
  
  if (Country %in% c('Brazil','Canada','China','Fiji')){
    cat('  Skipping!\n')
    next
  }
  
  # create github repo ----
  github_repo_exists = system(sprintf('git ls-remote git@github.com:ohi-science/%s.git', repo_name), ignore.stderr=T) != 128
  if (!github_repo_exists){    
    cat(sprintf('  creating github repo -- %s\n', format(Sys.time(), '%X')))
    
    # create using Github API: https://developer.github.com/v3/repos/#create
    cmd = sprintf('curl -u "bbest:%s" https://api.github.com/orgs/ohi-science/repos -d \'{"name":"%s"}\'', token, repo_name)
    system(cmd)
  }
  
  # get existing repo
  repo = try(repository(dir_repo), silent=T)
  
  # create local repo ----
  if (class(repo)=='try-error'){
    cat(sprintf('  creating local repo -- %s\n', format(Sys.time(), '%X')))
    
    # recreate empty dir
    unlink(dir_repo, recursive=T, force=T)    
    dir.create(dir_repo, recursive=T, showWarnings=F)
    
    # intialize repo ----
    # system cmd line: touch README.md; git init; git add README.md; git commit -m "first commit"; git push -u origin master
    repo = init(dir_repo)
    setwd(dir_repo)
    cat(sprintf('# Ocean Health Index - %s', cntry), file='README.md')
    add(repo, 'README.md')
    commit(repo, 'add README.md')    
    system(sprintf('git remote add origin %s', git_url))
    system('git push -u origin master')    
  }
  
  # populate repo ----
  cat(sprintf('  populating local repo with scenario files -- %s\n', format(Sys.time(), '%X')))
  
  # recreate empty dir, except hidden .git and README.md
  del_except = 'README.md'
  for (f in setdiff(list.files(dir_repo), del_except)) unlink(f, recursive=T, force=T)

  # create and cd to scenario
  dir_scenario = file.path(dir_repo, scenario)
  dir.create(dir_scenario, showWarnings=F)
  setwd(dir_scenario)
  
  # create dirs
  for (dir in c('tmp','layers','conf','spatial')) dir.create(dir, showWarnings=F)

  # copy layers from global
  write.csv(lyrs_g, sprintf('tmp/layers_%s.csv', sfx_global), na='', row.names=F)

  # create spatial if needed
  f_js      = file.path(dir_data, cntry, 'regions_gcs.js')
  f_geojson = file.path(dir_data, cntry, 'regions_gcs.geojson')
  if (!file.exists(f_js)){
    f_shp = file.path(dir_data, cntry, 'spatial', 'rgn_offshore_gcs.shp')
    cat(sprintf('  shp_to_geojson -- %s\n', format(Sys.time(), '%X')))
    shp_to_geojson(f_shp, f_js, f_geojson)
  }
  for (f in c(f_js, f_geojson)){ # f = f_spatial[1]
    file.copy(f, sprintf('spatial/%s', basename(f)), overwrite=T)
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
  rgn_new_csv   = file.path(dir_data, cntry, 'spatial', 'rgn_offshore_data.csv')
  rgn_old_csv   = sprintf('%s/layers/rgn_labels.csv', dir_global)
  cntry_old_csv = sprintf('%s/layers/cntry_rgn.csv', dir_global)
  
  # old to new regions
  rgn_new = read.csv(rgn_new_csv) %>%
    select(rgn_id_new=rgn_id, rgn_name_new=rgn_name) %>%
    mutate(rgn_name_old = Country) %>%
    merge(
      gl_rgn %>%
        select(rgn_name_old=label, rgn_id_old=rgn_id),
      by='rgn_name_old', all.x=T) %>%
    select(rgn_id_new, rgn_name_new, rgn_id_old, rgn_name_old) %>%
    arrange(rgn_name_new)

  # old to new countries
  cntry_new = gl_cntry %>%
    select(cntry_key, rgn_id_old=rgn_id) %>%
    merge(
      rgn_new,
      by='rgn_id_old') %>%
    group_by(cntry_key, rgn_id_new) %>%
    summarise(n=n()) %>%
    select(cntry_key, rgn_id_new) %>%
    as.data.frame()

  # bind single cntry_key
  if (length(unique(cntry_new$cntry_key)) > 1){
    cat('  length(cntry_key) > 1 - not handled yet. NEXT\n')
    dput(unique(cntry_new$cntry_key), sprintf('%s/%s_cntry-key-length-gt-1.txt', file.path(dir_repos, 'score_errors'), cntry))
    next
  }    
  
  # write layers data files
  for (j in 1:nrow(lyrs_c)){ # i=56
    csv_in  = sprintf('%s/layers/%s', dir_global, lyrs_c$filename_old[j])
    csv_out = sprintf('layers/%s', lyrs_c$filename[j])
    
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
      
    if (lyrs_c$layer[j]=='rgn_labels'){
      csv_out = sprintf('layers/%s.csv', lyrs_c$layer[j])
      lyrs_c$filename[j] = basename(csv_out)
      d = d %>%
        merge(rgn_new, by.x='rgn_id', by.y='rgn_id_new') %>%
        select(rgn_id, type, label=rgn_name_new)
    }
    
    # empty layers
    if (nrow(na.omit(d))==0) {      
      dir.create('tmp/layers-empty_global-values', showWarnings=F)
      file.copy(csv_in, file.path('tmp/layers-empty_global-values', lyrs_c$filename[j]))            
    }        
    
    # TODO: downweight: area_offshore, area_offshore_3nm, equal, equal , population_inland25km, 
    # shp = '/Volumes/data_edit/git-annex/clip-n-ship/data/Albania/rgn_inland25km_mol.shp'    
    # handle: raster, raster | area_inland1km, raster | area_offshore, raster | area_offshore3nm, raster | equal
    
    write.csv(d, csv_out, row.names=F, na='')
  }

  #   # copy custom layers
  #   dir_layers_in = file.path(dir_data, cntry, 'layers')
  #   for (f in list.files(dir_layers_in, full.names=T)){ # f = list.files(dir_layers_in, full.names=T)[1]
  #     
  #     # HACK! Swapping 25 km -> 25 mi: rgn_popnsum_inland25km for mar_coastalpopn_inland25mi
  #     if (basename(f) == 'rgn_popnsum_inland25km.csv'){      
  #       f_old = f
  #       f = file.path(dir_layers_in, 'mar_coastalpopn_inland25mi.csv')
  #       file.copy(f_old, f, overwrite=T)
  #       unlink(f_old)
  #     }
  #     
  #     # update layer
  #     lyr = tools::file_path_sans_ext(basename(f))
  #     stopifnot(lyr %in% lyrs_c$layer)
  #     
  #     # remove old global equal value file, copy custom file, update lyrs_c
  #     unlink(file.path('layers', lyrs_c[lyrs_c$layer==lyr, 'filename']))
  #     file.copy(f, file.path('layers', basename(f)), overwrite=T)
  #     lyrs_c[lyrs_c$layer==lyr, 'filename'] = basename(f)    
  #   }

  # layers registry
  write.csv(select(lyrs_c, -filename_old), 'layers.csv', row.names=F, na='')
  
  # check for empty layers
  CheckLayers('layers.csv', 'layers', 
              flds_id=c('rgn_id','cntry_key','country_id','saup_id','fao_id','fao_saup_id'))
  lyrs = read.csv('layers.csv')  
  lyrs_empty = filter(lyrs, data_na==T)
  if (nrow(lyrs_empty) > 0){
    write.csv(lyrs_empty, 'layers-empty_swapping-global-mean.csv', row.names=F, na='')
  }
  
  # populate empty layers with global averages
  for (lyr in subset(lyrs, data_na, layer, drop=T)){ # lyr = subset(lyrs, data_na, layer, drop=T)[1]
    #lyr = 'le_wage_sector_year'

    # get all global data for layer
    l = subset(lyrs, layer==lyr)
    a = read.csv(file.path('tmp/layers-empty_global-values', l$filename))
    csv_out = sprintf('layers/%s', l$filename)
    
    # calculate global categorical means using non-standard evaluation, ie dplyr::*_()
    fld_key         = names(a)[1]
    fld_value       = names(a)[ncol(a)]
    flds_other = setdiff(names(a), c(fld_key, fld_value))    
    if (length(flds_other) > 0){
      b = a %>%
        group_by_(.dots=flds_other) %>%
        summarize_(
          .dots = setNames(
            sprintf('mean(%s)', fld_value),
            fld_value))
    } else {
      b = a %>%
        summarize_(
          .dots = setNames(
            sprintf('mean(%s)', fld_value),
            fld_value))
    }
      
    # bind single cntry_key
    if ('cntry_key' %in% names(a)){
      b$cntry_key = unique(cntry_new$cntry_key)
    }    
    
    # bind many rgn_ids
    if ('rgn_id' %in% names(a)){
      # get outer join, aka Cartesian product
      b = b %>%
        merge(
          rgn_new %>%
            select(rgn_id = rgn_id_new), 
          all=T) %>%
        select(one_of('rgn_id', flds_other, fld_value)) %>%
        arrange(rgn_id)
    }
    
    write.csv(b, csv_out, row.names=F, na='')    
  }  
  
  # update layers.csv with empty layers now populated by global averages
  CheckLayers('layers.csv', 'layers', 
              flds_id=c('rgn_id','cntry_key','country_id','saup_id','fao_id','fao_saup_id'))

  # copy configuration files
  conf_files = c('config.R','functions.R','goals.csv','pressures_matrix.csv','resilience_matrix.csv','resilience_weights.csv')
  for (f in conf_files){ # f = conf_files[1]
    
    f_in  = sprintf('%s/conf/%s', dir_global, f)
    f_out = sprintf('conf/%s', f)
    
    # read in file
    s = readLines(f_in, warn=F, encoding='UTF-8')
        
    # update confugration
    if (f=='config.R'){
      
      # get map centroid and zoom level
      # TODO: http://gis.stackexchange.com/questions/76113/dynamically-set-zoom-level-based-on-a-bounding-box
      # var regions_group = new L.featureGroup(regions); map.fitBounds(regions_group.getBounds());
      p_shp  = file.path(dir_data, cntry, 'spatial', 'rgn_offshore_gcs.shp')
      p      = readOGR(dirname(p_shp), tools::file_path_sans_ext(basename(p_shp)))
      p_bb   = data.frame(p@bbox) # max of 2.25
      p_ctr  = rowMeans(p_bb)
      p_zoom = 12 - as.integer(cut(max(transmute(p_bb, range = max - min)), c(0, 0.25, 0.5, 1, 2.5, 5, 10, 20, 40, 80, 160, 320, 360)))
      
      # set map center and zoom level
      s = gsub(
        'map_lat=0; map_lon=0; map_zoom=3', 
        sprintf('map_lat=%g; map_lon=%g; map_zoom=%d', p_ctr['y'], p_ctr['x'], p_zoom), 
        s)
      # use just rgn_labels (not rgn_global)
      s = gsub('rgn_global', 'rgn_labels', s)
    }
    
    writeLines(s, f_out)
  }
  
  # append custom functions to overwrite others
  #   cat(
  #     paste(c(
  #       '\n\n\n# CUSTOM FUNCTIONS ----\n',
  #       readLines('tmp/functions_custom.R', warn=F, encoding='UTF-8')), 
  #       collapse='\n'), 
  #     file='conf/functions.R', append=T)
      
  #   # DEBUG: copy custom layers
  #   for (f in list.files('tmp/layers_custom', full.names=T)){ # f = list.files('tmp/layers_custom', full.names=T)[1]
  #     file.copy(f, file.path('layers', basename(f)), overwrite=T)  
  #   }
  
  # calculate scores
  # devtools::load_all('~/github/ohicore'); setwd('/Users/bbest/github/clip-n-ship/ohi-albania/subcountry2014')
  layers = Layers('layers.csv', 'layers') # devtools::load_all(dir_ohicore)
  conf   = Conf('conf')
  scores = try(CalculateAll(conf, layers, debug=T))
  
  # if problem calculating, log problem and move on to next one an
  if (class(scores)=='try-error'){
    dir_score_errors = file.path(dir_repos, 'score_errors')
    dir.create(dir_score_errors, showWarnings=F)
    dput(scores, sprintf('%s/%s_dput.txt', dir_score_errors, cntry))
    next
  }
    
  # write scores
  write.csv(scores, 'scores.csv', na='', row.names=F)
     
  # save shortcut files not specific to operating system
  write_shortcuts('.', os_files=0)  
  # check app manually
  #launch_app()
  
  # commit changes, push to github repo
  repo = init(dir_repo)
  if (sum(sapply(status(repo), length)) > 0){
    pull(repo)
    add(repo, scenario)
    commit(repo, 'initial subcountry values all equal to global2014 country values')
    #push(repo) # Error in 'git2r_push': HTTP parser error: the on_headers_complete callback failed
    system('git push') # -u origin master')
  }
    
  # create app dir to contain data and shiny files
  dir.create(dir_app, showWarnings=F)
  setwd(dir_app)
    
  # copy ohicore shiny app files
  shiny_files = list.files(file.path(dir_ohicore, 'inst/shiny_app'), recursive=T)
  for (f in shiny_files){ # f = shiny_files[1]
    dir.create(dirname(f), showWarnings=F, recursive=T)
    suppressWarnings(file.copy(file.path(dir_ohicore, 'inst/shiny_app', f), f, overwrite=T, recursive=T, copy.mode=T, copy.date=T))
  }
  
  # write config
  cat(sprintf('# configuration for ohi-science.shinyapps.io/%s
git_url: %s
git_branch: %s
dir_scenario: %s
tabs_hide: %s
debug: False
last_updated: %s
', app_name, git_url, git_branch, scenario, tabs_hide, Sys.Date()), file='app_config.yaml')
  
  # allow app to populate github repo locally
  if (file.exists('github')){
    unlink('github', recursive=T, force=T)
  }

  # app_name='lebanon'; dir_app=sprintf('/Volumes/data_edit/git-annex/clip-n-ship/%s/shinyapps.io', app_name) 
  # shiny::runApp(dir_app)    # test app locally; delete, ie unlink, github files before deploy
  shinyapps::deployApp(appDir=dir_app, appName=app_name, upload=T, launch.browser=T, lint=F)
    
} # end for (cntry in cntries)