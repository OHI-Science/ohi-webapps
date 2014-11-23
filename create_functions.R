# one-time fixes ----

rename_sc_annex <- function(name){
  # rename annex directories
  
  d = filter(sc_studies, sc_name == name)
  path_from = file.path(dir_annex, str_replace_all(d$gl_rgn_name, ' ', '_'))
  path_to   = file.path(dir_annex, d$sc_key)
  if (file.exists(path_from) & !file.exists(path_to)) {
    message(sprintf(' moving %s -> %s', path_from, basename(path_to)))
    file.rename(path_from, path_to)  
  } else {
    message(sprintf(' skipping %s -> %s, since from !exists or to exists', path_from, basename(path_to)))
  }
} 
#lapply(sc_studies$sc_name, rename_sc_annex) # done 2014-11-02 by bbest

create_gh_repo <- function(key, gh_token=gh_token, verbosity=1){

  repo_name = key
  res = system(sprintf('git ls-remote git@github.com:ohi-science/%s.git', repo_name), ignore.stderr=T, intern=T)
  repo_exists = ifelse(res != 128, T, F)
  if (!repo_exists){    
    if (verbosity > 0){
      message(sprintf('%s: creating github repo -- %s', repo_name, format(Sys.time(), '%X')))
    }
    # create using Github API: https://developer.github.com/v3/repos/#create
    cmd = sprintf('curl --silent -u "bbest:%s" https://api.github.com/orgs/ohi-science/repos -d \'{"name":"%s"}\'', gh_token, repo_name)
    cmd_res = paste(capture.output(fromJSON(system(cmd, intern=T))), collapse='\n')
  } 
  
  # return data.frame
  data.frame(
    sc_key      = key, 
    repo_exists = repo_exists,
    cmd         = ifelse(repo_exists, cmd),
    cmd_res     = ifelse(repo_exists, cmd_res))
}
#lapply(sc_studies$sc_key, create_gh_repo, verbosity=1)


rename_gh_repo <- function(key, verbosity=1){ # key='are'
  # rename github repo. if new exists, not old, and not exception
  
  d = subset(sc_studies, sc_key == key)
  repo_new = key
  repo_old = sprintf('ohi-%s', d$sc_key_old)
  name     = d$sc_name
  repo_new_exists = system(sprintf('git ls-remote git@github.com:ohi-science/%s.git', repo_new), ignore.stderr=T, intern=T)[1] != 128
  repo_old_exists = system(sprintf('git ls-remote git@github.com:ohi-science/%s.git', repo_old), ignore.stderr=T, intern=T)[1] != 128

  cmd_condition = repo_old_exists & !repo_new_exists & !name %in% sc_names_existing_repos
  cmd = sprintf('curl --silent -u "bbest:%s" -X PATCH -d \'{"name": "%s"}\' https://api.github.com/repos/ohi-science/%s', gh_token, repo_new, repo_old)
  if (cmd_condition){
    if (verbosity > 0){
      message(sprintf('%s: renaming repo "%s" -> "%s" -- %s\n', key, repo_old, repo_new, format(Sys.time(), '%X')))
    }
    cmd_res = paste(capture.output(fromJSON(system(cmd, intern=T))), collapse='\n')
  }
  
  # return data.frame
  data.frame(
    sc_key          = key, 
    sc_name         = name,
    cmd             = ifelse(cmd_condition, cmd), 
    cmd_res         = ifelse(cmd_condition, cmd_res),
    repo_old_exists = repo_old_exists, 
    repo_new_exists = repo_new_exists, 
    name_excepted   = name %in% sc_names_existing_repos)
}    
#results <- rbind_all(lapply(sc_studies$sc_key, rename_gh_repo, verbosity=1)) # done 2014-11-02 by bbest
#repo_todo <- filter(results, !repo_new_exists)$sc_key

zip_shapefiles <- function(key){ # key='ecu'
  dir_sp = file.path(dir_neptune, 'git-annex/clip-n-ship', key, 'spatial')
  zip_sp = sprintf('%s/www_subcountry2014/%s_shapefiles.zip', dir_neptune, key)
  message(basename(zip_sp), ': ', Sys.time())
  zip(zip_sp, dir_sp, flags='-r9Xq')
}
#lapply(sc_studies$sc_key, zip_shapefiles) # done 2014-11-21 by bbest

# major updates ----

# update Github repo with Description, Website and default branch
edit_gh_repo <- function(key, default_branch='draft', verbosity=1){ # key='abw'
  
  # vars
  d           = subset(sc_studies, sc_key == key)
  repo        = d$sc_key
  description = sprintf('Ocean Health Index for %s', d$sc_name)
  website     = sprintf('http://ohi-science.org/%s', repo)
  
  # setup JSON metadata object to inject
  kv = list(
    name           = repo, 
    description    = description,
    homepage       = website,
    default_branch = default_branch)
  json = toJSON(kv, auto_unbox = T)
  
  cmd = sprintf('git ls-remote git@github.com:ohi-science/%s.git', repo)
  cmd_res = system(cmd, ignore.stderr=T, intern=T)
  repo_exists = ifelse(res[1] != 128, T, F)  
  if (repo_exists){
    if (verbosity > 0){
      message(sprintf('%s: updating github repo attributes -- %s', key, format(Sys.time(), '%X')))
      if (verbosity > 1){
        message(paste(sprintf('  %s: %s', names(kv), as.character(kv)), collapse='\n'))
      }
    }
    cmd = sprintf('curl --silent -u "bbest:%s" -X PATCH -d \'%s\' https://api.github.com/repos/ohi-science/%s', gh_token, json, repo)
    cmd_res = paste(capture.output(fromJSON(system(cmd, intern=T))), collapse='\n')
  }
  
  # return data.frame
  data.frame(
    sc_key         = key, 
    sc_name        = d$sc_name, 
    repo_exists    = repo_exists,
    cmd            = cmd, 
    cmd_res        = cmd_res, 
    description    = ifelse(repo_exists, description), 
    website        = ifelse(repo_exists, website),
    default_branch = ifelse(repo_exists, default_branch),
    stringsAsFactors=F)
}    
#results = rbind_all(lapply(sc_studies$sc_key[1:3], edit_gh_repo, verbosity=2)) # done 2014-11-02 by bbest


rename_branches <- function(key, verbosity=1){ # key='ecu'
  # rename: master -> published, dev -> draft
  
  dir_repo = file.path(dir_repos, key)
  setwd(dir_repo)  
  
  rename_branch <- function(branch_old, branch_new){
    branches = system('git branch -l', intern=T) %>% str_replace(fixed('*'), '') %>% str_trim()
    
    if (!branch_new %in% branches & branch_old %in% branches){
      # if new not exists, and old exists
      
      system(sprintf('git branch -m %s %s', branch_old, branch_new))
      system(sprintf('git push -u origin %s', branch_new)) # push and set upstream to origin
    }
    
    if (!branch_new %in% branches & !branch_old %in% branches){
      # if neither branch found, create off existing except gh-pages
      
      branch_beg = setdiff(branches, 'gh-pages')[1]
      system(sprintf('git checkout %s', branch_beg))      
      system(sprintf('git checkout -b %s', branch_new))
      system(sprintf('git push -u origin %s', branch_new)) # push and set upstream to origin
    }
    
  }
      
  # new branches
  rename_branch('dev', 'draft')
  rename_branch('master', 'published')
      
  # set default branch to draft
  res = edit_gh_repo(key, default_branch='draft')
  
  # delete old branches remotely and locally, if exist
  branches = system('git branch -l', intern=T) %>% str_replace(fixed('*'), '') %>% str_trim()
  for (b in intersect(c('dev','master'), branches)){
    system(sprintf('git push origin :%s', b))
  }  
}    
#results = rbind_all(lapply(sc_studies$sc_key[1:3], edit_gh_repo, verbosity=2)) # done 2014-11-02 by bbest

populate_draft_branch <- function(){
  
  wd = getwd()
  
  # clone repo
  setwd(dir_repos)
  unlink(dir_repo, recursive=T, force=T)
  repo = clone(git_url, normalizePath(dir_repo, mustWork=F))
  setwd(dir_repo)
  
  # rename/create branches: draft, published
  remote_branches = sapply(branches(repo, 'remote'), function(x) str_split(x@name, '/')[[1]][2])
  if (length(setdiff(c('draft','published'), remote_branches)) > 0){
    rename_branches(key)
  }
  
  # ensure on draft branch ----
  checkout(repo, 'draft')
  
  dir_errors = file.path(dir_repos, '_errors')
  dir.create(dir_errors, showWarnings=F)
  
  #cat(sprintf('  populating local dev repo with scenario files -- %s\n', format(Sys.time(), '%X')))
  
  # recreate empty dir, except hidden .git
  del_except = ''
  for (f in setdiff(list.files(dir_repo, all.files=F), del_except)) unlink(file.path(dir_repo, f), recursive=T, force=T)
  
  # README
  brew(sprintf('%s/ohi-webapps/README.brew.md', dir_github), 'README.md')
  
  # add Rstudio project files. cannabalized devtools::add_rstudio_project() which only works for full R packages.
  file.copy(system.file('templates/template.Rproj', package='devtools'), sprintf('%s.Rproj', key))
  writeLines(c('.Rproj.user', '.Rhistory', '.RData'), '.gitignore')  
  
  # create and cd to scenario
  dir_scenario = file.path(dir_repo, basename(default_branch_scenario))
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
  if (length(unique(sc_cntry$cntry_key)) > 1){
    
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
  
  # drop LE layers no longer being used
  lyrs_le_rm = c(
    'le_gdp_pc_ppp','le_jobs_cur_adj_value','le_jobs_cur_base_value','le_jobs_ref_adj_value','le_jobs_ref_base_value',
    'le_rev_cur_adj_value','le_rev_cur_base_value','le_rev_cur_base_value','le_rev_ref_adj_value','le_rev_ref_base_value',
    'le_rev_sector_year','le_revenue_adj','le_wage_cur_adj_value','le_wage_cur_base_value','le_wage_ref_adj_value',
    'le_wage_ref_base_value','liveco_status','liveco_trend')
  lyrs_sc = filter(lyrs_sc, !layer %in% lyrs_le_rm)
  
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
  
  # save shortcut files not specific to operating system
  write_shortcuts('.', os_files=0)
  
  # add travis.yml file
  brew(travis_draft_yaml_brew, '.travis.yml')
  
  setwd(wd)  
}

populate_website <- function(){
  
  # TODO: enxure on gh-pages branch and exists
  # TODO: copy ecu/gh-pages, brew template pages and store in ohi-webapps/gh-pages
  
  # README
  brew(sprintf('%s/ohi-webapps/README.brew.md', dir_github), 'README.md')

  # add Rstudio project files, plus _site to ignore if testing with local jekyll serve --baseurl ''
  file.copy(system.file('templates/template.Rproj', package='devtools'), sprintf('%s.Rproj', key))
  writeLines(c('.Rproj.user', '.Rhistory', '.RData', '_site','_asset_bundler_cache','.sass','.sass-cache','.DS_Store'), '.gitignore')  
  
}

deploy_app <- function(key){ # key='ecu'
  
  source('create_init_sc.R')
  
  # delete old
  dir_app_old <- sprintf('%s/git-annex/clip-n-ship/%s/shinyapps.io', dir_neptune, git_repo)
  unlink(dir_app_old, recursive=T)
  
  # cd into repo, checkout app
  wd = getwd()
  if (!file.exists(dir_repo)) system(sprintf('git clone %s %s', git_url, dir_repo))
  setwd(dir_repo)
  repo = repository(dir_repo)
  remote_branches = sapply(branches(repo, 'remote'), function(x) str_split(x@name, '/')[[1]][2])
  if (!'app' %in% remote_branches){
    system('git checkout --orphan app')
    system('git rm -rf .')
  } else {
    system('git checkout app')
    system('rm -rf *')
  }  
  
  # copy installed ohicore shiny app files
  # good to have latest dev ohicore first: devtools::install_github('ohi-science/ohicore@dev') 
  dir_ohicore_app = file.path(system.file(package='ohicore'), 'shiny_app')
  shiny_files = list.files(dir_ohicore_app, recursive=T)  
  for (f in shiny_files){ # f = shiny_files[1]
    dir.create(dirname(f), showWarnings=F, recursive=T)
    suppressWarnings(file.copy(file.path(dir_ohicore_app, f), f, overwrite=T, recursive=T, copy.mode=T, copy.date=T))
  }
    
  # get commit version of ohicore app files
  lns = readLines(file.path(dir_ohicore_app, '../DESCRIPTION'))
  g = sapply(str_split(lns[grepl('^Github', lns)], ': '), function(x) setNames(x[2], x[1]))
  #ohicore_app_commit = sprintf('%s/%s@%s,%.7s', g[['GithubUsername']], g[['GithubRepo']], , g[['GithubSHA1']])
  ohicore_app = list(ohicore_app=list(
    git_owner  = g[['GithubUsername']],
    git_repo   = g[['GithubRepo']],
    git_branch = g[['GithubRef']],      
    git_commit = g[['GithubSHA1']]))
  
  # write config
  brew(file.path(dir_github, 'ohi-webapps/app.brew.yml'), 'app.yml')
    
  # add Rstudio project files. cannabalized devtools::add_rstudio_project() which only works for full R packages.
  file.copy(system.file('templates/template.Rproj', package='devtools'), sprintf('%s.Rproj', key))
  writeLines(c('.Rproj.user', '.Rhistory', '.RData', 'github', git_repo), '.gitignore')  
  
  # shiny::runApp()    # test app locally
  
  # clean up cloned / archived repos which get populated if testing app
  unlink(git_repo, recursive=T, force=T)
  unlink('github', recursive=T, force=T)
  
  # deploy
  deployApp(appDir='.', appName=app_name, upload=T, launch.browser=T, lint=F)
  
  # push files to github app branch
  system('git add -A; git commit -a -m "deployed app"')
  push_branch('app')
  
  # restore wd
  setwd(wd)
}

create_maps = function(key='ecu', width=400, height=250, effect='toycamera'){ # key='ecu' # setwd('~/github/clip-n-ship/ecu')
    
  # map_1600x800.png
  # regions_400x250.png
  #   key='ecu'
  #   width=400
  #   height=250
  #   effect = 'toycamera'
  #   png = file.path(dir_neptune, 'git-annex/clip-n-ship', key, 'gh-pages/images/regions_400x250.png')  
  #   # app-inset_262x178.png # TODO: composite
  #   width=262
  #   height=178
  #   effect = 'app'
  #   png = file.path(dir_neptune, 'git-annex/clip-n-ship', key, 'gh-pages/images/app_400x250.png')  
  # width  = 600
  # height = 400
  # effect = ''
  # res    = 72
  # png = file.path(dir_neptune, 'git-annex/clip-n-ship', key, 'gh-pages/images/regions_600x400.png')    
  
  # load libraries quietly
  suppressWarnings(suppressPackageStartupMessages({
    library(sp)
    library(rgdal)
    library(raster)
    library(rgeos)
    library(dismo)
    library(ggplot2)
    library(ggmap) # devtools::install_github('dkahle/ggmap') # want 2.4 for stamen toner-lite
    library(dplyr)
    library(grid) # for unit
    merge = base::merge # override git2r
    diff  = base::diff    
  }))
  
  # vars 
  buffers   = c('offshore'=0.2, 'inland'=0.2, 'inland1km'=0.8, 'inland25km'=0.4, 'offshore3nm'=0.4, 'offshore1km'=0.8) # and transparency  
  
  # paths (dir_neptune, dir_github already set by source('~/github/ohi-webapps/create_init.R')
  source(file.path(dir_github, 'ohi-webapps/create_init_sc.R'))
  dir_data  = file.path(dir_neptune, 'git-annex/clip-n-ship')
  dir_spatial = file.path(dir_data, key, 'spatial')
  dir_pages   = file.path(dir_data, key, 'gh-pages')
  
  # create output directory if don't exist
  dir.create(dirname(png), recursive=T, showWarnings=F)
  
  # read shapefiles  
  shps = setNames(sprintf('%s/rgn_%s_gcs', dir_spatial, names(buffers)), names(buffers))
  plys = lapply(shps, function(x) readOGR(dirname(x), basename(x)))
  
  # fortify and set rgn_names as factor of all inland rgns
  rgn_names = factor(plys[['inland']][['rgn_name']])
  plys.df = lapply(plys, function(x){
    x = fortify(x, region='rgn_name')
    x$id = factor(as.character(x$id), rgn_names)
    return(x)
  })
  ids_offshore = unique(plys.df[['offshore']][['id']])
  
  # get extent from inland and offshore, expanded 10%
  bb_inland25km = bbox(plys[['inland25km']])
  bb_offshore   = bbox(plys[['offshore']])
  x  = extendrange(c(bb_inland25km['x',], bb_offshore['x',]), f=0.1)
  y  = extendrange(c(bb_inland25km['y',], bb_offshore['y',]), f=0.1)
  
  # make bbox proportional to desired output image dimensions
  if (diff(x) < width / height * diff(y)){
    x = c(-1, 1) * diff(y)/2 * width/height + mean(x)
  } else {
    y = c(-1, 1) * diff(x)/2 * height/width + mean(y)
  }
  bb = c(x[1], y[1], x[2], y[2])
  
  # plot
  m = get_map(location=bb, source='stamen', maptype='toner-lite', crop=T)
  
  tmp_png = tempfile(fileext='.png')
  png(tmp_png, width=width, height=height, res=150, type='cairo-png')
  ggmap(m, extent='device') + 
    # offshore
    geom_polygon(
      aes(x=long, y=lat, group=group, fill=id), alpha=buffers[['offshore']], 
      data=plys.df[['offshore']]) +
    # offshore3nm
    geom_polygon(
      aes(x=long, y=lat, group=group, fill=id), alpha=buffers[['offshore3nm']], 
      data=plys.df[['offshore3nm']]) +  
    # offshore1km
    geom_polygon(
      aes(x=long, y=lat, group=group, fill=id), alpha=buffers[['offshore1km']], 
      data=plys.df[['offshore1km']]) +  
    # inland
    geom_polygon(
      aes(x=long, y=lat, group=group, fill=id), alpha=buffers[['inland']], 
      data=subset(plys.df[['inland']], id %in% ids_offshore)) +  
    # inland25km
    geom_polygon(
      aes(x=long, y=lat, group=group, fill=id), alpha=buffers[['inland25km']], 
      data=subset(plys.df[['inland25km']], id %in% ids_offshore)) +  
    # inland1km
    geom_polygon(
      aes(x=long, y=lat, group=group, fill=id), alpha=buffers[['inland1km']], 
      data=subset(plys.df[['inland1km']], id %in% ids_offshore)) +
    # tweaks
    labs(fill='', xlab='', ylab='') + 
    theme(
      legend.position='none')
  #     legend.justification = c(1,0),   # anchor legend to max x, min y of graph
  #     legend.position      = c(1,0),   # from anchor position max x, min y
  #     legend.key.size      = unit(2.5, 'cm'),
  #     legend.text          = element_text(size = 20),
  #     axis.line            = element_line(color = NA))
  dev.off()
  
  unlink(png)
  if (effect == 'toycamera'){
    toycamera_options = '-i 5 -o 150 -d 5 -h -3 -t yellow -a 10 -I 0.75 -O 5'
    system(sprintf('./toycamera %s %s %s', toycamera_options, tmp_png, png))
  } else if (effect == 'app'){
    app_png = file.path(dir_github, 'ohi-webapps/fig/app_400x250.png')
    system(sprintf('convert -size 400x250 -composite %s %s -geometry 262x178+136+57 -depth 8 %s', app_png, tmp_png, png, png))
  } else {
    file.copy(tmp_png, png)
  }
  unlink(tmp_png)
  #system(sprintf('open %s', png))  
}

