
# set vars and get functions
setwd('~/github/ohi-webapps')
source('create_init.R')
source('create_functions.R')

# loop through countries
#for (key in sc_studies$sc_key){ # 
key = 'alb'
  
  # set vars by subcountry key
  source('create_init_sc.R')
      
  # create github repo
  #create_gh_repo(key)
  
  # clone clean local repo
  setwd(dir_repos)
  unlink(dir_repo, recursive=T, force=T)
  repo = clone(git_url, normalizePath(dir_repo, mustWork=F))
  setwd(dir_repo)
  
  # rename/create branches: draft, published
  remote_branches = sapply(branches(repo, 'remote'), function(x) str_split(x@name, '/')[[1]][2])
  if (length(setdiff(c('draft','published'), remote_branches)) > 0){
    rename_branches(key)
  }
  # switch to dev branch
  #system('git checkout -b dev')
  #system('git pushd -u origin dev')
    
  # populate draft repo ----
  checkout(repo, 'draft')
  
  dir_errors = file.path(dir_repos, '_errors')
  dir.create(dir_errors, showWarnings=F)
  
  #cat(sprintf('  populating local dev repo with scenario files -- %s\n', format(Sys.time(), '%X')))
  
  # recreate empty dir, except hidden .git
  del_except = ''
  for (f in setdiff(list.files(dir_repo, all.files=F), del_except)) unlink(file.path(dir_repo, f), recursive=T, force=T)

  # README
  brew(
    text='# Ocean Health Index for <%=name%> (<%=toupper(key)%>)\n\n[![](https://travis-ci.org/OHI-Science/<%=key%>/svg?branch=draft)](https://travis-ci.org/OHI-Science/<%=key%>)\n',
    output='README.md')
  
  # add Rstudio project files. cannabalized devtools::add_rstudio_project() which only works for full R packages.
  file.copy(system.file('templates/template.Rproj', package='devtools'), sprintf('%s.Rproj', key))
  writeLines(c('.Rproj.user', '.Rhistory', '.RData'), '.gitignore')  

  # create and cd to scenario
  dir_scenario = file.path(dir_repo, scenario)
  dir.create(dir_scenario, showWarnings=F)
  setwd(dir_scenario)
  
  # create dirs
  for (dir in c('tmp','layers','conf','spatial')) dir.create(dir, showWarnings=F)

  # copy layers from global
  write.csv(lyrs_gl, sprintf('tmp/layers_%s.csv', sfx_global), na='', row.names=F)

  # spatial
  f_js_old      = file.path(dir_annex_sc, 'regions_gcs.js')
  f_geojson_old = file.path(dir_annex_sc, 'regions_gcs.geojson')
  f_js          = file.path(dir_annex_sc, 'spatial', 'regions_gcs.js')
  f_geojson     = file.path(dir_annex_sc, 'spatial', 'regions_gcs.geojson')
  if (file.exists(f_js_old)) file.rename(f_js_old, f_js)
  if (file.exists(f_geojson_old)) file.rename(f_geojson_old, f_geojson)
  txt_shp_error = sprintf('%s/%s_shp_to_geojson.txt', dir_errors, key)
  unlink(txt_shp_error)
  if (!file.exists(f_js)){
    f_shp = file.path(dir_annex, key, 'spatial', 'rgn_offshore_gcs.shp')
    cat(sprintf('  shp_to_geojson -- %s\n', format(Sys.time(), '%X')))    
    v = try(shp_to_geojson(f_shp, f_js, f_geojson))
    if (class(v)=='try-error'){
      cat(as.character(traceback(v)), file=txt_shp_error)
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
  sc_rgns_csv = file.path(dir_annex_sc, 'spatial', 'rgn_offshore_data.csv')
  
  # old global to new subcountry regions
  # rgn_id_sc->sc_rgn_id, rgn_name_sc->sc_rgn_name, rgn_id_gl-> gl_rgn_id, rgn_name_gl-> gl_rgn_name
  sc_rgns = read.csv(sc_rgns_csv) %>%
    select(sc_rgn_id=rgn_id, sc_rgn_name=rgn_name) %>%
    mutate(gl_rgn_name = name) %>%
    merge(
      gl_rgns %>%
        select(gl_rgn_name, gl_rgn_id),
      by='gl_rgn_name', all.x=T) %>%
    select(sc_rgn_id, sc_rgn_name, gl_rgn_id, gl_rgn_name) %>%
    arrange(sc_rgn_name)

  # old global to new subcountry countries
  sc_cntry = gl_cntries %>%
    select(gl_cntry_key, gl_rgn_id) %>%
    merge(
      sc_rgns,
      by='gl_rgn_id') %>%
    group_by(gl_cntry_key, sc_rgn_id) %>%
    summarise(n=n()) %>%
    select(cntry_key = gl_cntry_key, sc_rgn_id) %>%
    as.data.frame()

  # bind single cntry_key
  if (length(unique(sc_cntry$gl_cntry_key)) > 1){
        
    # extract non-na rows from lookup
    d_mcntry = gl_sc_mcntry %>% filter(gl_rgn_name == name & !is.na(sc_rgn_name))
    
    # log error if no rows defined
    txt_mcntry_error = sprintf('%s/%s_cntry-key-length-gt-1.txt', dir_errors, key)
    unlink(txt_mcntry_error)
    if (nrow(d_mcntry) == 0){
      cat(sprintf('  multi-country lookup not registered yet in %s. NEXT!\n', csv_mcntry))
      write.csv(d_mcntry, txt_mcntry_error, row.names=F, na='')
      next
    }
    
    # update cntry key
    sc_cntry = d_mcntry %>%
      select(
        cntry_key = gl_cntry_key,
        sc_rgn_id = sc_rgn_id)    
  }    
  
  # swap out custom mar_coastalpopn_inland25mi for mar_coastalpopn_inland25km (NOTE: mi -> km)
  ix = which(lyrs_sc$layer=='mar_coastalpopn_inland25mi')
  lyrs_sc$layer[ix]       = 'mar_coastalpopn_inland25km'
  lyrs_sc$path_in[ix]     = file.path(dir_annex, key, 'layers', 'mar_coastalpopn_inland25km_lyr.csv')
  lyrs_sc$name[ix]        = str_replace(lyrs_sc$name[ix]       , fixed('miles'), 'kilometers')
  lyrs_sc$description[ix] = str_replace(lyrs_sc$description[ix], fixed('miles'), 'kilometers')
  lyrs_sc$filename[ix]    = 'mar_coastalpopn_inland25km_sc2014-raster.csv'
  lyrs_sc$rgns_in[ix]     = 'subcountry'
  
  # get layers used to downweight from global: area_offshore, area_offshore_3nm, equal, equal , population_inland25km, 
  population_inland25km = read.csv(file.path(dir_annex_sc, 'layers' , 'mar_coastalpopn_inland25km_lyr.csv')) %>%
    filter(year == dw_year) %>%
    mutate(
      dw = popsum / sum(popsum)) %>%
    select(rgn_id, dw)
  area_offshore         = read.csv(file.path(dir_annex_sc, 'spatial', 'rgn_offshore_data.csv')) %>%
    mutate(
      dw = area_km2 / sum(area_km2)) %>%
    select(rgn_id, dw)
  area_offshore_3nm     = read.csv(file.path(dir_annex_sc, 'spatial', 'rgn_offshore3nm_data.csv')) %>%
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
    lyrs_sc$path_in[ix]     = file.path(dir_annex_sc, 'spatial', csv)
    lyrs_sc$filename[ix]    = str_replace(lyrs_sc$filename[ix], fixed('_gl2014.csv'), '_sc2014-area.csv')
  }

  # drop cntry_* layers
  lyrs_sc = filter(lyrs_sc, !grepl('^cntry_', layer))

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
          filter(rgn_id %in% sc_rgns$gl_rgn_id) %>%
          merge(sc_rgns, by.x='rgn_id', by.y='gl_rgn_id') %>%
          mutate(rgn_id=sc_rgn_id) %>%
          subset(select=flds)
      }
      
      if ('cntry_key' %in% names(d)){
        # convert cntry_key to rgn_id, drop cntry_key
        d = d %>%
          inner_join(
            sc_cntry,
            by='cntry_key') %>%
          rename(rgn_id=sc_rgn_id) %>%
          select_(.dots = as.list(c('rgn_id', setdiff(names(d), 'cntry_key'))))          
      }
        
      if (lyrs_sc$layer[j]=='rgn_labels'){
        csv_out = 'layers/rgn_labels.csv'
        lyrs_sc$filename[j] = basename(csv_out)
        d = d %>%
          merge(sc_rgns, by.x='rgn_id', by.y='sc_rgn_id') %>%
          select(rgn_id, type, label=sc_rgn_name)
      }
      
      # downweight: area_offshore, area_offshore_3nm, equal, equal , population_inland25km, 
      # shp = '/Volumes/data_edit/git-annex/clip-n-ship/data/Albania/rgn_inland25km_mol.shp'    
      # TODO: raster, raster | area_inland1km, raster | area_offshore, raster | area_offshore3nm, raster | equal
      downweight = str_trim(lyrs_sc$clip_n_ship_disag[j])
      downweightings = c('area_offshore'='area-offshore', 'area_offshore_3nm'='area-offshore3nm', 'population_inland25km'='popn-inland25km')
      if (downweight %in% names(downweightings) & nrow(d) > 0){
        
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
  #   dir_layers_in = file.path(dir_annex_sc, 'layers')
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
              flds_id=c('rgn_id','country_id','saup_id','fao_id','fao_saup_id'))
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
      sc_rgns %>%
        mutate(trend_yrs = '5_yr') %>%
        select(rgn_id = sc_rgn_id, trend_yrs) %>%
        arrange(rgn_id) %>%
        write.csv(csv_out, row.names=F, na='')
      
      next
    }

    if (class(a[[fld_value]]) %in% c('factor','character')){
      cat(sprintf('  DOH! For empty layer "%s" field "%s" is factor/character but continuing with presumption of numeric.\n', lyr, fld_value))
    }
    
    # presuming numeric...
    # get mean
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
    
    # bind many rgn_ids
    if ('rgn_id' %in% names(a) | 'cntry_key' %in% names(a)){
      # get outer join, aka Cartesian product
      b = b %>%
        merge(
          sc_rgns %>%
            select(rgn_id = sc_rgn_id), 
          all=T) %>%
        select(one_of('rgn_id', flds_other, fld_value)) %>%
        arrange(rgn_id)
    }
    
    #if (lyr == 'mar_harvest_tonnes') browser()
    write.csv(b, csv_out, row.names=F, na='')    
  }  
  
  # update layers.csv with empty layers now populated by global averages
  CheckLayers('layers.csv', 'layers', 
              flds_id=c('rgn_id','country_id','saup_id','fao_id','fao_saup_id'))

  # copy configuration files
  conf_files = c('config.R','functions.R','goals.csv','pressures_matrix.csv','resilience_matrix.csv','resilience_weights.csv')
  for (f in conf_files){ # f = conf_files[2]
    
    f_in  = sprintf('%s/conf/%s', dir_global, f)
    f_out = sprintf('conf/%s', f)
    
    # read in file
    s = readLines(f_in, warn=F, encoding='UTF-8')
        
    # update confugration
    if (f=='config.R'){
      
      # get map centroid and zoom level
      # TODO: http://gis.stackexchange.com/questions/76113/dynamically-set-zoom-level-based-on-a-bounding-box
      # var regions_group = new L.featureGroup(regions); map.fitBounds(regions_group.getBounds());
      p_shp  = file.path(dir_annex_sc, 'spatial', 'rgn_offshore_gcs.shp')
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
    
    # swap out custom functions
    if (f=='functions.R'){
            
      # iterate over goals with functions to swap
      for (g in names(fxn_swap)){ # g = names(fxn_swap)[1]
        
        # get goal=line# index for functions.R
        fxn_idx = setNames(
          grep('= function', s),
          str_trim(str_replace(grep('= function', s, value=T), '= function.*', '')))

        # read in new goal function
        s_g = readLines(fxn_swap[g], warn=F, encoding='UTF-8')
                
        # get line numbers for current and next goal to begin and end excision
        ln_beg = fxn_idx[g] - 1
        ln_end = fxn_idx[which(names(fxn_idx)==g) + 1]
        
        # inject new goal function
        s = c(s[1:ln_beg], s_g, '\n', s[ln_end:length(s)])
      }      
    }
            
    # substitute old layer names with new
    lyrs_dif = lyrs_sc %>% filter(layer!=layer_gl)
    for (i in 1:nrow(lyrs_dif)){ # i=1
      s = str_replace_all(s, fixed(lyrs_dif$layer_gl[i]), lyrs_dif$layer[i])
    }
    
    writeLines(s, f_out)
  }

  # swap fields in goals.csv
  goals = read.csv('conf/goals.csv', stringsAsFactors=F)
  for (g in names(goal_swap)){ # g = names(goal_swap)[1]
    for (fld in names(goal_swap[[g]])){
      goals[goals$goal==g, fld] = goal_swap[[g]][[fld]]
    }
  }
  write.csv(goals, 'conf/goals.csv', row.names=F, na='')

  #   # DEBUG: copy custom layers
  #   for (f in list.files('tmp/layers_custom', full.names=T)){ # f = list.files('tmp/layers_custom', full.names=T)[1]
  #     file.copy(f, file.path('layers', basename(f)), overwrite=T)  
  #   }
  
  # calculate scores
  #browser()
  # devtools::install_github('ohi-science/ohicore', ref='dev')
  #options(error=browser)
  devtools::load_all(dir_ohicore) #; setwd('/Users/bbest/github/clip-n-ship/ohi-anguilla/subcountry2014')
  #scores = CalculateAll(conf, layers, debug=T)
  #library(ohicore)
  layers = Layers('layers.csv', 'layers')
  conf   = Conf('conf')
  scores = CalculateAll(conf, layers, debug=T)
  #scores = try(CalculateAll(conf, layers, debug=T))

#   lyrs = read.csv('layers.csv', na='')
#   for (j in 1:nrow(lyrs)){
#     cat(sprintf('%03d: %s\n', j, lyrs$layer[j]))
#     d = read.csv(file.path('layers',lyrs$filename[j]))
#     cat(sprintf('  dim:: %s\n', as.character(dim(d))))    
#   }
  
  # if problem calculating, log problem and move on to next one an
  txt_calc_error = sprintf('%s/%s_calc-scores.txt', dir_errors, key)
  unlink(txt_calc_error)
  if (class(scores)=='try-error'){
    cat(as.character(traceback(scores)), file=txt_calc_error)
    next
  }
    
  # write scores
  write.csv(scores, 'scores.csv', na='', row.names=F)
     
  # save shortcut files not specific to operating system
  write_shortcuts('.', os_files=0)  
  # check app manually
  #launch_app()

# REST IN R script to be executed after success

  # copy current files (except hidden files like .travis.yml, .gitignore)

# TODO: GIT COMMIT, travis-ci from here
# iterate over branches, published?

# # create figures
# git checkout dev
# Rscript create_figures
# 
# # copy dev scenarios to tmp before switching to other branches
# cd /github/ecu
# cp -r subcountry2014 ~/tmp/subcountry2014
# git checkout gh-pages
# mkdir _data/dev
# cp -r ~/tmp/subcountry2014 _data/dev/subcountry2014
# 
# 
# 
#   # commit changes, push to github repo
#   setwd(dir_repo)
#   repo = repository(dir_repo)
#   if (sum(sapply(status(repo), length)) > 0){
#     system('git add --all')
#     system(sprintf('git commit -m "%s"', commit_msg))
#     system('git push')
#   }
#   
#   if (redo_app){
#     # create app dir to contain data and shiny files
#     dir.create(dir_app, showWarnings=F)
#     setwd(dir_app)
#       
#     # copy ohicore shiny app files
#     shiny_files = list.files(file.path(dir_ohicore, 'inst/shiny_app'), recursive=T)
#     for (f in shiny_files){ # f = shiny_files[1]
#       dir.create(dirname(f), showWarnings=F, recursive=T)
#       suppressWarnings(file.copy(file.path(dir_ohicore, 'inst/shiny_app', f), f, overwrite=T, recursive=T, copy.mode=T, copy.date=T))
#     }
#     
#     # write config
#     cat(sprintf('# configuration for ohi-science.shinyapps.io/%s
# git_url: %s
# git_branch: %s
# dir_scenario: %s
# tabs_hide: %s
# debug: False
# last_updated: %s
# ', app_name, git_url, git_branch, scenario, tabs_hide, Sys.Date()), file='app_config.yaml')
#     
#     
#     # allow app to populate github repo locally
#     if (file.exists(dir_repo'github')){
#       unlink('github', recursive=T, force=T)
#     }
#   
#     # app_name='lebanon'; dir_app=sprintf('/Volumes/data_edit/git-annex/clip-n-ship/%s/shinyapps.io', app_name) 
#     # shiny::runApp(dir_app)    # test app locally; delete, ie unlink, github files before deploy
#     shinyapps::deployApp(appDir=dir_app, appName=app_name, upload=T, launch.browser=T, lint=F)
# 
#   } # end redo_app
# } # end for (key in keys)
# 
# y = y %>%
#   select(Country, init_app, status, url_github_repo, url_shiny_app, error) %>%
#   arrange(desc(init_app), status, error, Country)
# 
# write.csv(y, '~/github/ohi-webapps/tmp/webapp_status.csv', row.names=F, na='')
# 
# table(y$error) %>%
#   as.data.frame() %>% 
#   select(error = Var1, count=Freq) %>%
#   filter(error != '') %>%
#   arrange(desc(count)) %>%
#   knitr::kable()