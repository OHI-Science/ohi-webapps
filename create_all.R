
# set vars and get functions
setwd('~/github/ohi-webapps')
source('create_init.R')
source('create_functions.R')

# loop through countries
for (key in sc_studies$sc_key){
  
  # set vars by subcountry key
  source('create_init_sc.R')
      
  # create / rename github repo ----
  
  github_repo_exists = system(sprintf('git ls-remote git@github.com:ohi-science/%s.git', repo_name), ignore.stderr=T) != 128    
  # create repo. using Github API: https://developer.github.com/v3/repos/#create
  if (!github_repo_exists){    
    edit_gh_repo(key, default_branch='master')
    
  }
  
# TODO: automate later
git checkout dev
Rscript create_figures

cd /github/ecu
cp -r subcountry2014 ~/tmp/subcountry2014
git checkout gh-pages
mkdir _data/dev
cp -r ~/tmp/subcountry2014 _data/dev/subcountry2014

  
  # reclone locally
  cat(sprintf('  re-cloning github repo -- %s\n', format(Sys.time(), '%X')))
  setwd(dir_repos)
  unlink(dir_repo, recursive=T, force=T)  
  system(sprintf('git clone %s %s', git_url, dir_repo))
  setwd(dir_repo)
  
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
    cat(sprintf('# Ocean Health Index - %s', Country), file='README.md')
    add(repo, 'README.md')
    commit(repo, 'add README.md')    
    system(sprintf('git remote add origin %s', git_url))
    system('git push -u origin master')    
  }
  
  
  # populate dev repo ----
  
  cat(sprintf('  populating local dev repo with scenario files -- %s\n', format(Sys.time(), '%X')))
    
  # switch to dev branch
  system('git checkout -b dev')
  system('git push -u origin dev')
  
  # recreate empty dir, except hidden .git and README.md
  del_except = 'README.md'
  for (f in setdiff(list.files(dir_repo), del_except)) unlink(file.path(dir_repo, f), recursive=T, force=T)

  # add Rstudio project files. cannabalized devtools::add_rstudio_project() which only works for full R packages.
  cat('  adding RStudio project files\n')
  (sprintf('Ocean Health Index - %s', Country))
  file.copy(system.file('templates/template.Rproj', package='devtools'), sprintf('%s.Rproj', cntry_key))
  writeLines(c('.Rproj.user', '.Rhistory', '.RData'), '.gitignore')  

  # create and cd to scenario
  dir_scenario = file.path(dir_repo, scenario)
  dir.create(dir_scenario, showWarnings=F)
  setwd(dir_scenario)
  
  # create dirs
  for (dir in c('tmp','layers','conf','spatial')) dir.create(dir, showWarnings=F)

  # copy layers from global
  write.csv(lyrs_gl, sprintf('tmp/layers_%s.csv', sfx_global), na='', row.names=F)

  # create spatial if needed
  f_js      = file.path(dir_annex, country, 'regions_gcs.js')
  f_geojson = file.path(dir_annex, country, 'regions_gcs.geojson')
  if (!file.exists(f_js)){
    f_shp = file.path(dir_annex, country, 'spatial', 'rgn_offshore_gcs.shp')
    #f_lyr = tools::file_path_sans_ext(basename(f_shp))
    #x = rgdal::readOGR(dsn=f_shp, layer=f_lyr, drop_unsupported_fields=T) #  proj4string=sp::CRS('+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs')
    #ogrInfo(f_shp, f_lyr)        
    cat(sprintf('  shp_to_geojson -- %s\n', format(Sys.time(), '%X')))    
    v = try(shp_to_geojson(f_shp, f_js, f_geojson))
    if (class(v)=='try-error'){
      dir_score_errors = file.path(dir_repos, 'score_errors')
      dir.create(dir_score_errors, showWarnings=F)
      cat(as.character(traceback(v)), file=sprintf('%s/%s_shp_to_geojson.txt', dir_score_errors, cntry))
      next
    }
  }
  for (f in c(f_js, f_geojson)){ # f = f_spatial[1]
    file.copy(f, sprintf('spatial/%s', basename(f)), overwrite=T)
  }

  # modify layers
  lyrs_sc = lyrs_gl %>%
    select(
      targets, layer, name, description, 
      fld_value, units, filename,       
      starts_with('clip_n_ship')) %>%
    mutate(
      layer_gl = layer,
      path_in  = file.path(dir_global, 'layers', filename),
      rgns_in  = 'global',
      filename = sprintf('%s_%s.csv', layer, sfx_global)) %>%
    arrange(targets, layer)
  
  # csvs for regions and countries
  rgn_sc_csv   = file.path(dir_annex, cntry, 'spatial', 'rgn_offshore_data.csv')
  
  # old global to new subcountry regions
  rgn_sc = read.csv(rgn_sc_csv) %>%
    select(rgn_id_sc=rgn_id, rgn_name_sc=rgn_name) %>%
    mutate(rgn_name_gl = Country) %>%
    merge(
      rgn_gl %>%
        select(rgn_name_gl=label, rgn_id_gl=rgn_id),
      by='rgn_name_gl', all.x=T) %>%
    select(rgn_id_sc, rgn_name_sc, rgn_id_gl, rgn_name_gl) %>%
    arrange(rgn_name_sc)

  # old global to new subcountry countries
  cntry_sc = cntry_gl %>%
    select(cntry_key, rgn_id_gl=rgn_id) %>%
    merge(
      rgn_sc,
      by='rgn_id_gl') %>%
    group_by(cntry_key, rgn_id_sc) %>%
    summarise(n=n()) %>%
    select(cntry_key, rgn_id_sc) %>%
    as.data.frame()

  # bind single cntry_key
  if (length(unique(cntry_sc$cntry_key)) > 1){
    
    # remove old error
    mcntry_error = sprintf('%s/score_errors/%s_cntry-key-length-gt-1.txt', dir_repos, cntry)
    unlink(mcntry_error)
    
    # extract non-na rows from lookup
    d_mcntry = mcntry %>% filter(gl_rgn_name == Country & !is.na(sc_rgn_name))
    
    # log error if no rows defined
    if (nrow(d_mcntry) == 0){
      cat(sprintf('  multi-country lookup not registered yet in %s. NEXT!\n', csv_mcntry))
      write.csv(d_mcntry, mcntry_error, row.names=F, na='')
      next
    }
    
    # update cntry key
    cntry_sc = d_mcntry %>%
      select(
        cntry_key = gl_cntry_key,
        rgn_id_sc = sc_rgn_id)    
  }    
  
  # swap out custom mar_coastalpopn_inland25mi for mar_coastalpopn_inland25km (NOTE: mi -> km)
  ix = which(lyrs_sc$layer=='mar_coastalpopn_inland25mi')
  lyrs_sc$layer[ix]       = 'mar_coastalpopn_inland25km'
  lyrs_sc$path_in[ix]     = file.path(dir_annex, cntries[i], 'layers', 'mar_coastalpopn_inland25km_lyr.csv')
  lyrs_sc$name[ix]        = str_replace(lyrs_sc$name[ix]       , fixed('miles'), 'kilometers')
  lyrs_sc$description[ix] = str_replace(lyrs_sc$description[ix], fixed('miles'), 'kilometers')
  lyrs_sc$filename[ix]    = 'mar_coastalpopn_inland25km_sc2014-raster.csv'
  lyrs_sc$rgns_in[ix]     = 'subcountry'
  
  # get layers used to downweight from global: area_offshore, area_offshore_3nm, equal, equal , population_inland25km, 
  population_inland25km = read.csv(file.path(dir_annex, cntries[i], 'layers' , 'mar_coastalpopn_inland25km_lyr.csv')) %>%
    filter(year == dw_year) %>%
    mutate(
      dw = popsum / sum(popsum)) %>%
    select(rgn_id, dw)
  area_offshore         = read.csv(file.path(dir_annex, cntries[i], 'spatial', 'rgn_offshore_data.csv')) %>%
    mutate(
      dw = area_km2 / sum(area_km2)) %>%
    select(rgn_id, dw)
  area_offshore_3nm     = read.csv(file.path(dir_annex, cntries[i], 'spatial', 'rgn_offshore3nm_data.csv')) %>%
    mutate(
      dw = area_km2 / sum(area_km2)) %>%
    select(rgn_id, dw)
  
  # swap out spatial area layers
  area_layers = c(
    'rgn_area'             = 'rgn_offshore_data.csv',
    'rgn_area_inland1km'   = 'rgn_inland1km_data.csv',
    'rgn_area_offshore3nm' = 'rgn_offshore3nm_data.csv')
  for (lyr in names(area_layers)){
    csv = area_layers[lyr]
    ix = which(lyrs_sc$layer==lyr)
    lyrs_sc$rgns_in[ix]     = 'subcountry'
    lyrs_sc$path_in[ix]     = file.path(dir_annex, cntries[i], 'spatial', csv)
    lyrs_sc$filename[ix]    = str_replace(lyrs_sc$filename[ix], fixed('_gl2014.csv'), '_sc2014-area.csv')
  }    

  # write layers data files
  for (j in 1:nrow(lyrs_sc)){ # i=56
    
    lyr     = lyrs_sc$layer[j]
    rgns_in = lyrs_sc$rgns_in[j]
    csv_in  = lyrs_sc$path_in[j]
    csv_out = sprintf('layers/%s', lyrs_sc$filename[j])
    
    d = read.csv(csv_in) # , na.strings='')
    flds = names(d)
    
    if (rgns_in == 'global'){
    
      if ('rgn_id' %in% names(d)){
        d = d %>%
          filter(rgn_id %in% rgn_sc$rgn_id_gl) %>%
          merge(rgn_sc, by.x='rgn_id', by.y='rgn_id_gl') %>%
          mutate(rgn_id=rgn_id_sc) %>%
          subset(select=flds)
      }
      
      if ('cntry_key' %in% names(d)){
        d = d %>%
          filter(cntry_key %in% cntry_sc$cntry_key)
      }
        
      if (lyrs_sc$layer[j]=='rgn_labels'){
        csv_out = 'layers/rgn_labels.csv'
        lyrs_sc$filename[j] = basename(csv_out)
        d = d %>%
          merge(rgn_sc, by.x='rgn_id', by.y='rgn_id_sc') %>%
          select(rgn_id, type, label=rgn_name_sc)
      }
      
      # downweight: area_offshore, area_offshore_3nm, equal, equal , population_inland25km, 
      # shp = '/Volumes/data_edit/git-annex/clip-n-ship/data/Albania/rgn_inland25km_mol.shp'    
      # TODO: raster, raster | area_inland1km, raster | area_offshore, raster | area_offshore3nm, raster | equal
      downweight = str_trim(lyrs_sc$clip_n_ship_disag[j])
      downweightings = c('area_offshore'='area-offshore', 'area_offshore_3nm'='area-offshore3nm', 'population_inland25km'='popn-inland25km')
      if (downweight %in% names(downweightings) & !'cntry_key' %in% names(d) & nrow(d) > 0){
        
        # update data frame with downweighting
        i.v  = ncol(d) # assume value in right most column
        #if (downweight=='population_inland25km') browser()
        d = inner_join(d, get(downweight), by='rgn_id')
        i.dw = ncol(d) # assume downweight in right most column after join
        d[i.v] = d[i.v] * d[i.dw]
        d = d[,-i.dw]
  
        # update layer filename to reflect downweighting
        csv_out = file.path(
          'layers',
          str_replace(
            lyrs_sc$filename[j], 
            fixed('_gl2014.csv'), 
            sprintf('_sc2014-%s.csv', downweightings[downweight])))
        lyrs_sc$filename[j] = basename(csv_out)
      }
    }
    write.csv(d, csv_out, row.names=F, na='')
  }

  #   # copy custom layers
  #   dir_layers_in = file.path(dir_annex, cntry, 'layers')
  #   for (f in list.files(dir_layers_in, full.names=T)){ # f = list.files(dir_layers_in, full.names=T)[1]
  #     
  #     # update layer
  #     lyr = tools::file_path_sans_ext(basename(f))
  #     stopifnot(lyr %in% lyrs_sc$layer)
  #     
  #     # remove old global equal value file, copy custom file, update lyrs_sc
  #     unlink(file.path('layers', lyrs_sc[lyrs_sc$layer==lyr, 'filename']))
  #     file.copy(f, file.path('layers', basename(f)), overwrite=T)
  #     lyrs_sc[lyrs_sc$layer==lyr, 'filename'] = basename(f)    
  #   }

  # layers registry
  write.csv(lyrs_sc, 'layers.csv', row.names=F, na='')
  
  # check for empty layers
  CheckLayers('layers.csv', 'layers', 
              flds_id=c('rgn_id','cntry_key','country_id','saup_id','fao_id','fao_saup_id'))
  lyrs = read.csv('layers.csv', na='')  
  lyrs_empty = filter(lyrs, data_na==T)
  if (nrow(lyrs_empty) > 0){
    dir.create('tmp/layers-empty_global-values', showWarnings=F)
    write.csv(lyrs_empty, 'layers-empty_swapping-global-mean.csv', row.names=F, na='')
  }
  
  # populate empty layers with global averages
  for (lyr in subset(lyrs, data_na, layer, drop=T)){ # lyr = subset(lyrs, data_na, layer, drop=T)[1]
    
    # copy global layer
    #lyr == 'mar_harvest_tonnes'

    # get all global data for layer
    l = subset(lyrs, layer==lyr)
    csv_gl  = as.character(l$path_in)
    csv_tmp = sprintf('tmp/layers-empty_global-values/%s', l$filename)
    csv_out = sprintf('layers/%s', l$filename)
    file.copy(csv_gl, csv_tmp, overwrite=T)    
    a = read.csv(csv_tmp)    

    # calculate global categorical means using non-standard evaluation, ie dplyr::*_()
    fld_key         = names(a)[1]
    fld_value       = names(a)[ncol(a)]
    flds_other = setdiff(names(a), c(fld_key, fld_value))
    
    if (class(a[[fld_value]]) %in% c('factor','character') & l$fld_val_num == fld_value){
      cat(sprintf('  DOH! For empty layer "%s" field "%s" is factor/character but registered as [fld_val_num] not [fld_val_chr].\n', lyr, fld_value))
    }
    
    # exceptions
    if (lyr == 'mar_trend_years'){
      rgn_sc %>%
        mutate(trend_yrs = '5_yr') %>%
        select(rgn_id = rgn_id_sc, trend_yrs) %>%
        arrange(rgn_id) %>%
        write.csv(csv_out, row.names=F, na='')
      
      next
    }

    if (class(a[[fld_value]]) %in% c('factor','character')){
      cat(sprintf('  DOH! For empty layer "%s" field "%s" is factor/character but continuing with presumption of numeric.\n', lyr, fld_value))
    }
    
    # presuming numeric...
    if (length(flds_other) > 0){
      b = a %>%
        group_by_(.dots=flds_other) %>%
        summarize_(
          .dots = setNames(
            sprintf('mean(%s, na.rm=T)', fld_value),
            fld_value))
    } else {
      b = a %>%
        summarize_(
          .dots = setNames(
            sprintf('mean(%s, na.rm=T)', fld_value),
            fld_value))
    }
    
    # bind single cntry_key
    if ('cntry_key' %in% names(a)){
      #b$cntry_key = unique(cntry_sc$cntry_key)
      b = b %>%
        merge(
          data.frame(
            cntry_key = as.character(unique(cntry_sc$cntry_key))))      
    }    
    
    # bind many rgn_ids
    if ('rgn_id' %in% names(a)){
      # get outer join, aka Cartesian product
      b = b %>%
        merge(
          rgn_sc %>%
            select(rgn_id = rgn_id_sc), 
          all=T) %>%
        select(one_of('rgn_id', flds_other, fld_value)) %>%
        arrange(rgn_id)
    }
    
    #if (lyr == 'mar_harvest_tonnes') browser()
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
      p_shp  = file.path(dir_annex, cntry, 'spatial', 'rgn_offshore_gcs.shp')
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
        
    # substitute old layer names with new
    lyrs_dif = lyrs_sc %>% filter(layer!=layer_gl)
    for (i in 1:nrow(lyrs_dif)){ # i=1
      s = str_replace_all(s, fixed(lyrs_dif$layer_gl[i]), lyrs_dif$layer[i])
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
  #browser()
  # devtools::install_github('ohi-science/ohicore', ref='dev')
  #options(error=browser)
  #devtools::load_all(dir_ohicore); setwd('/Users/bbest/github/clip-n-ship/ohi-anguilla/subcountry2014')
  #scores = CalculateAll(conf, layers, debug=T)
  library(ohicore)
  layers = Layers('layers.csv', 'layers')
  conf   = Conf('conf')  
  
  # Doh! Need to get coastal population for every year 2005 to 2015!
#   browser()
#   conf   = Conf('conf')  
#   scores = CalculateAll(conf, layers, debug=T)
  
  scores = try(CalculateAll(conf, layers, debug=T))
    
#   lyrs = read.csv('layers.csv', na='')
#   for (j in 1:nrow(lyrs)){
#     cat(sprintf('%03d: %s\n', j, lyrs$layer[j]))
#     d = read.csv(file.path('layers',lyrs$filename[j]))
#     cat(sprintf('  dim:: %s\n', as.character(dim(d))))    
#   }
  
  # if problem calculating, log problem and move on to next one an
  if (class(scores)=='try-error'){
    dir_score_errors = file.path(dir_repos, 'score_errors')
    dir.create(dir_score_errors, showWarnings=F)
    #unlink(sprintf('%s/%s_dput.txt', dir_score_errors, cntry))
    cat(as.character(traceback(scores)), file=sprintf('%s/%s_calc-scores.txt', dir_score_errors, cntry))
    next
  }
    
  # write scores
  write.csv(scores, 'scores.csv', na='', row.names=F)
     
  # save shortcut files not specific to operating system
  write_shortcuts('.', os_files=0)  
  # check app manually
  #launch_app()
  
  # commit changes, push to github repo
  setwd(dir_repo)
  repo = repository(dir_repo)
  if (sum(sapply(status(repo), length)) > 0){
    system('git add --all')
    system(sprintf('git commit -m "%s"', commit_msg))
    system('git push')
  }
  
  if (redo_app){
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
    if (file.exists(dir_repo'github')){
      unlink('github', recursive=T, force=T)
    }
  
    # app_name='lebanon'; dir_app=sprintf('/Volumes/data_edit/git-annex/clip-n-ship/%s/shinyapps.io', app_name) 
    # shiny::runApp(dir_app)    # test app locally; delete, ie unlink, github files before deploy
    shinyapps::deployApp(appDir=dir_app, appName=app_name, upload=T, launch.browser=T, lint=F)

  } # end redo_app
} # end for (cntry in cntries)

y = y %>%
  select(Country, init_app, status, url_github_repo, url_shiny_app, error) %>%
  arrange(desc(init_app), status, error, Country)

write.csv(y, '~/github/ohi-webapps/tmp/webapp_status.csv', row.names=F, na='')

table(y$error) %>%
  as.data.frame() %>% 
  select(error = Var1, count=Freq) %>%
  filter(error != '') %>%
  arrange(desc(count)) %>%
  knitr::kable()