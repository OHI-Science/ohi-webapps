
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

create_gh_repo <- function(key, gh_token=gh_token, verbosity=1){ # gh_token=gh_token; verbosity=1
  
  repo_name = key
  #cmd = sprintf('git ls-remote https://github.com/OHI-Science/%s.git', repo_name)
  cmd = sprintf('git ls-remote git@github.com:ohi-science/%s.git', repo_name)
  res = system(cmd, ignore.stderr=T, intern=T)
  repo_exists = # ifelse(length(res)==0, T, F) # set to F for bhi-rgns?
    if (!repo_exists){
      if (verbosity > 0){
        message(sprintf('%s: creating github repo -- %s', repo_name, format(Sys.time(), '%X')))
      }
      # create using Github API: https://developer.github.com/v3/repos/#create
      cmd = sprintf('curl --silent -u "jules32:%s" https://api.github.com/orgs/ohi-science/repos -d \'{"name":"%s"}\'', gh_token, repo_name)
      cmd_res = paste(capture.output(fromJSON(system(cmd, intern=T))), collapse='\n')
    } else{
      cmd_res = NA
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
  unlink(zip_sp)
  zip(zip_sp, dir_sp, flags='-r9Xq')
}
#lapply(sc_studies$sc_key, zip_shapefiles) # done 2014-11-21 by bbest
#lapply('esp', zip_shapefiles) # done 2014-11-25 post inland1km/offshore1km Spain shp fix by bbest
#lapply(c('kor', 'are', 'zaf'), zip_shapefiles) # done 2014-11-25 post inland1km/offshore1km Spain shp fix by bbest (done: 'esp')

make_status <- function(){
  # after create_init.R
  
  #require(jsonlite) # see how jsonlite is more compiant with github json: http://www.r-bloggers.com/new-package-jsonlite-a-smarter-json-encoderdecoder/
  
  sc_not_gadm = read.csv('tmp/rgn_notmatching_gadm_manual_utf-8.csv')
  stopifnot(nrow(anti_join(sc_not_gadm, sc_studies, by=c('rgn_name'='gl_rgn_name')))==0)
  
  dirs_annex = list.dirs('/Volumes/data_edit/git-annex/clip-n-ship', recursive=F, full.names=F)
  stopifnot(nrow(setdiff(dirs_annex, d$sc_key))==0)
  
  d = sc_studies %>%
    left_join(
      sc_not_gadm %>%
        mutate(
          gadm_not_matching = TRUE,
          gadm_splits       = rgn_to_gadm_splitting,
          gadm_lumps        = rgn_to_gadm_lumping) %>%
        select(
          gl_rgn_name = rgn_name,
          starts_with('gadm_')),
      by='gl_rgn_name')
  
  d %>%
    arrange(sc_key) %>%
    transmute(
      repo       = sc_key,
      study_area = sc_name,
      status     = NA,
      last_mod   = NA,
      map_url    = NA,
      n_regions  = NA) %>%
    write.csv('~/github/subcountry/_data/status.csv', row.names=F, na='')
  
  #system(sprintf('git push -u origin %s', branch_new)) # push and set upstream to origin
}

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
  
  cmd = sprintf('git ls-remote https://github.com/OHI-Science/%s.git', repo)
  cmd_res = system(cmd, ignore.stderr=T, intern=T)
  repo_exists = ifelse(is.null(attr(cmd_res, 'status')), T, F)
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

# update Github repo with Description, Website and default branch
edit_gh_repo_custom <- function(key, default_branch='draft', verbosity=1){ # key='abw'
  
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
  
  cmd = sprintf('git ls-remote https://github.com/OHI-Science/%s.git', repo)
  cmd_res = system(cmd, ignore.stderr=T, intern=T)
  repo_exists = ifelse(is.null(attr(cmd_res, 'status')), T, F)
  if (repo_exists){
    if (verbosity > 0){
      message(sprintf('%s: updating github repo attributes -- %s', key, format(Sys.time(), '%X')))
      if (verbosity > 1){
        message(paste(sprintf('  %s: %s', names(kv), as.character(kv)), collapse='\n'))
      }
    }
    cmd = sprintf('curl --silent -u "bbest:%s" -X PATCH -d \'%s\' https://api.github.com/repos/ohi-science/%s', gh_token, json, repo) # this worked; thought I would need to change to jules32
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
  system('git fetch; git pull')
  branches = system('git branch -l', intern=T) %>% str_replace(fixed('*'), '') %>% str_trim()
  for (b in intersect(c('dev','master'), branches)){
    system(sprintf('git push origin :%s', b))
  }
}
#results = rbind_all(lapply(sc_studies$sc_key[1:3], edit_gh_repo, verbosity=2)) # done 2014-11-02 by bbest

delete_extra_branches <- function(dir_repo=getwd(), branches_keep=c('draft','published','gh-pages','app')){ # key='ecu'
  setwd(dir_repo)
  repo = repository(dir_repo)
  remote_branches = sapply(branches(repo, 'remote'), function(x) str_split(x@name, '/')[[1]][2])
  for (b in setdiff(remote_branches, branches_keep)){
    system(sprintf('git push origin :%s', b))
  }
}

populate_draft_branch <- function(){
  
  wd = getwd()
  library(rgdal)
  
  # clone repo
  setwd(dir_repos)
  unlink(dir_repo, recursive=T, force=T)
  repo = clone(git_url, normalizePath(dir_repo, mustWork=F))
  setwd(dir_repo)
  
  # get remote branches
  remote_branches = sapply(branches(repo, 'remote'), function(x) str_split(x@name, '/')[[1]][2])
  
  # initialize
  if (length(remote_branches)==0){
    system('touch README.md')
    system('git add -A; git commit -m "first commit"')
    try(system('git remote rm origin')) # added by JSL Mar 13 2015; http://stackoverflow.com/questions/1221840/remote-origin-already-exists-on-git-push-to-new-repository
    system(sprintf('git remote add origin https://github.com/OHI-Science/%s.git', key))
    system('git push -u origin master')
    system('git pull')
    remote_branches = sapply(branches(repo, 'remote'), function(x) str_split(x@name, '/')[[1]][2])
  }
  
  # rename if draft & published don't already exist
  if (length(setdiff(c('draft','published'), remote_branches)) > 0 & length(remote_branches) > 0){
    rename_branches(key)
    remote_branches = sapply(branches(repo, 'remote'), function(x) str_split(x@name, '/')[[1]][2])
  }
  
  # ensure on draft branch ----
  checkout(repo, 'draft')
  
  #   dir_errors = file.path(dir_repos, '_errors')
  #   dir.create(dir_errors, showWarnings=F)
  #
  
  # recreate empty dir, except hidden .git
  del_except = ''
  for (f in setdiff(list.files(dir_repo, all.files=F), del_except)) unlink(file.path(dir_repo, f), recursive=T, force=T)
  
  # README
  brew(sprintf('%s/ohi-webapps/README.brew.md', dir_github), 'README.md')
  
  # add Rstudio project files. cannabalized devtools::add_rstudio_project() which only works for full R packages.
  file.copy(system.file('templates/template.Rproj', package='devtools'), sprintf('%s.Rproj', key))
  writeLines(c('.Rproj.user', '.Rhistory', '.RData'), '.gitignore')
  
  if (key != 'bhi') { #hack: BHI stop here and paste baltic2015 folder back over
    # create and cd to scenario
    dir_scenario = file.path(dir_repo, basename(default_branch_scenario))
    dir.create(dir_scenario, showWarnings=F)
    setwd(dir_scenario)
    
    # create dirs
    for (dir in c('tmp','layers','conf','spatial', 'prep')) dir.create(dir, showWarnings=F)
    
    # copy layers from global
    write.csv(lyrs_gl, sprintf('tmp/layers_%s.csv', sfx_global), na='', row.names=F)
  } # end (key != 'bhi')
  
  
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
    # file.copy(f, sprintf('baltic2015/spatial/%s', basename(f)), overwrite=T) # BHI hack
  }
  
  
  if (key != 'bhi') { ## hack: BHI stop here
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
    
    # old global to new custom regions
    if (all(is.na(sc_rgns$gl_rgn_id))){
      
      # hack for BHI #1/2
      sc_rgns$gl_rgn_name = sc_studies$gl_rgn_name[sc_studies$sc_key == key] 
      
      # for all custom repos
      sc_rgns = sc_rgns %>%
        select(-gl_rgn_id) %>%
        left_join(sc_studies %>%
                    select(gl_rgn_name = sc_name, 
                           gl_rgn_id), 
                  by= 'gl_rgn_name')
      
      # hack for BHI #2/2
      sc_rgns = distinct(sc_rgns)
      
    }
    
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
    
    # old global to new custom countries
    if (dim(sc_cntry)[1] != dim(sc_rgns)[1]) { # make sure Guayaquil doesn't match to both ECU and Galapagos
      #dots = list(subset(sc_studies$gl_rgn_key, sc_studies$sc_key == key))
      sc_cntries = subset(sc_studies, sc_key == key, gl_rgn_key, drop=T)
      sc_cntry = sc_cntry %>%
        #filter(cntry_key == (.dots = dots))
        filter(cntry_key %in% sc_cntries)
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
    population_inland25km = read.csv(file.path(dir_annex_sc, 'layers' , 'mar_coastalpopn_inland25km_lyr.csv')) %>%      # DUMMY file March 16.
      filter(year == dw_year) %>%
      mutate(
        dw = popsum / sum(popsum)) %>%
      select(rgn_id, dw)
    # fix Canada (can) with Nunavet [10] repeats b/c of spatial funk, presume just need to add
    #   read.csv(file.path(dir_annex_sc, 'layers' , 'mar_coastalpopn_inland25km_lyr.csv')) %>%
    #     group_by(rgn_id, year) %>%
    #     summarize(popsum = sum(popsum)) %>%
    #     write.csv(file.path(dir_annex_sc, 'layers' , 'mar_coastalpopn_inland25km_lyr.csv'), na='', row.names=F)
    area_offshore         = read.csv(file.path(dir_annex_sc, 'spatial', 'rgn_offshore_data.csv')) %>%
      mutate(
        dw = area_km2 / sum(area_km2)) %>%
      select(rgn_id, dw)
    #   area_offshore_3nm     = read.csv(file.path(dir_annex_sc, 'spatial', 'rgn_offshore3nm_data.csv')) %>%     # error, no file March 16
    #     mutate(
    #       dw = area_km2 / sum(area_km2)) %>%
    #     select(rgn_id, dw)
    #
    # swap out spatial area layers
    area_layers = c(
      'rgn_area'             = 'rgn_offshore_data.csv')
    #     'rgn_area_inland1km'   = 'rgn_inland1km_data.csv',
    #     'rgn_area_offshore3nm' = 'rgn_offshore3nm_data.csv')
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
    for (j in 1:nrow(lyrs_sc)){ # j=56
      
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
            dplyr::rename(rgn_id=sc_rgn_id) %>%
            select_(.dots = as.list(c('rgn_id', setdiff(names(d), 'cntry_key'))))
        }
        
        if (lyrs_sc$layer[j]=='rgn_labels'){
          csv_out = 'layers/rgn_labels.csv'
          lyrs_sc$filename[j] = basename(csv_out)
          d = d %>%
            merge(sc_rgns, by.x='rgn_id', by.y='sc_rgn_id') %>%
            select(rgn_id, type, label=sc_rgn_name)
        }
        
        # downweight: area_offshore, equal, equal , population_inland25km,
        # shp = '/Volumes/data_edit/git-annex/clip-n-ship/data/Albania/rgn_inland25km_mol.shp'
        downweight = str_trim(lyrs_sc$clip_n_ship_disag[j])
        downweightings = c('area_offshore'='area-offshore', 'population_inland25km'='popn-inland25km')
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
    
    # populate empty layers with global averages.
    for (lyr in subset(lyrs, data_na, layer, drop=T)){ # lyr = subset(lyrs, data_na, layer, drop=T)[1]
      
      message(' for empty layer ', lyr, ', getting global avg')
      
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
      #if (lyr == 'mar_coastalpopn_inland25km') browser()
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
            sc_rgns %>%  ## Poland Trouble Found it Eureka!
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
  } # end (key != 'bhi')
  
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
  
  # copy goals documentation
  file.copy(file.path(dir_github, 'ohi-webapps/subcountry2014/conf/goals.Rmd'), 'conf/goals.Rmd', overwrite=T)
  
  # save shortcut files not specific to operating system
  write_shortcuts('.', os_files=0)
  
  # add travis.yml file
  setwd(dir_repo)
  brew(travis_draft_yaml_brew, '.travis.yml')
  
  # copy regions map image
  dir.create(sprintf('%s/reports/figures', default_scenario), showWarnings=F, recursive=T)
  file.copy(
    file.path(dir_neptune, 'git-annex/clip-n-ship', key, 'gh-pages/images/regions_600x400.png'),
    sprintf('%s/reports/figures/regions_600x400.png', default_scenario), overwrite=T)
  
  
  # create subfolders in prep folder
  prep_subfolders = c('1.1_FIS', '1.2_MAR', '2_AO', '3_NP', '4_CS', '5_CP', '6.1_LIV', '6.2_ECO', '7_TR', '8_CW',
                      '9.1_ICO', '9.2_LSP', '10.1_SPP', '10.2_HAB', 'pressures', 'resilience')
  sapply(file.path(default_scenario, sprintf('prep/%s', prep_subfolders)), dir.create)
  
  # populate prep folder's supfolders
  file.create(file.path(default_scenario, sprintf('prep/%s', prep_subfolders), 'README.txt'))
  #   file.append(file.path(dir_github, 'ohi-webapps/tmp/README_template_prepgoals.txt'),  # this should append, but doesn't. Also tried file.create
  #     file.path(default_scenario, sprintf('prep/%s', prep_subfolders), 'README.txt'))  
  #  
  file.copy(file.path(dir_github, 'ohi-webapps/tmp/README_template_prep.txt'), 
            file.path(default_scenario, 'prep/README.txt'), overwrite=T)
  
  setwd(wd)
}

update_draft <- function(key, msg='ohi-webapps/create_functions.R - update_website()'){
  # key='ecu'
  
  # get subcountry vars specific to key
  key <<- key
  source(file.path(dir_github, 'ohi-webapps/create_init_sc.R'))
  
  # cd into repo, checkout gh-pages
  wd = getwd()
  if (!file.exists(dir_repo)) system(sprintf('git clone %s %s', git_url, dir_repo))
  setwd(dir_repo)
  repo = repository(dir_repo)
  
  # switch to draft branch and get latest
  system('git checkout draft; git pull')
  
  # create and cd to scenario
  dir_scenario = file.path(dir_repo, basename(default_branch_scenario))
  dir.create(dir_scenario, showWarnings=F)
  setwd(dir_scenario)
  
  # TODO: merge existing subcountry layers.csv with global layers.csv for updated descriptions
  read.csv('layers.csv') %>%
    merge(lyrs_gl) %>%
    mutate(...) %>%
    #head()
    write.csv('layers.csv')
  
  # TODO: update functions.R
  
  # copy configuration files
  conf_files = c('functions.R','goals.csv','pressures_matrix.csv','resilience_matrix.csv','resilience_weights.csv')
  for (f in conf_files){ # f = conf_files[2]
    
    f_in  = sprintf('%s/conf/%s', dir_global, f)
    f_out = sprintf('conf/%s', f)
    
    # read in file
    s = readLines(f_in, warn=F, encoding='UTF-8')
    
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
    # TODO: Need to borrow code back from original populate_draft_branch() to get proper layer names?
    #       Or create a lookup table of old to new layer names.
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
  
  # copy goals documentation
  file.copy(file.path(dir_github, 'ohi-webapps/subcountry2014/conf/goals.Rmd'), 'conf/goals.Rmd', overwrite=T)
  
  setwd(wd)
}


populate_website <- function(key, delete_first=T, copy_images=T, copy_flag=T, msg='populate_website()'){
  
  # get subcountry vars specific to key
  key <<- key
  source(file.path(dir_github, 'ohi-webapps/create_init_sc.R'))
  
  # cd into repo, checkout gh-pages
  wd = getwd()
  if (!file.exists(dir_repo)) system(sprintf('git clone %s %s', git_url, dir_repo))
  setwd(dir_repo)
  repo = repository(dir_repo)
  remote_branches = sapply(branches(repo, 'remote'), function(x) str_split(x@name, '/')[[1]][2])
  if (!'gh-pages' %in% remote_branches){
    system('git checkout --orphan gh-pages')
    system('git rm -rf .')
  } else {
    system('git checkout gh-pages; git pull')
  }
  if (delete_first){
    system('rm -rf *') # clear existing
  }
  
  # copy template files from ohi-webapps/gh-pages (including _config.brew.yml, which identifies the shiny server location (app_url))
  file.copy(list.files(file.path(dir_github, 'ohi-webapps/gh-pages'), full.names=T), '.', overwrite=T, recursive=T)
  file.copy(file.path(dir_github, 'ohi-webapps/gh-pages', c('.travis.yml','.gitignore')), '.', overwrite=T, recursive=T)
  
  # copy images
  if (copy_images){
    for (f in c('app_400x250.png','regions_1600x800.png',	'regions_30x20.png', 'regions_400x250.png')){
      f_from = file.path(dir_neptune, 'git-annex/clip-n-ship', key, 'gh-pages/images', f)
      message('copying ', f_from)
      stopifnot(file.copy(f_from, file.path('images', f), overwrite=T))
    }
  }
  
  # copy flag, i.e., national flag
  if (copy_flag){
    flag_in = sprintf('%s/ohi-webapps/flags/small/%s.png', dir_github, str_replace(subset(sc_studies, sc_key==key, gl_rgn_name, drop=T), ' ', '_'))
    if (file.exists(flag_in)){
      flag_out = file.path(dir_repo, 'images/flag_80x40.png')
      unlink(flag_out)
      system(sprintf("convert -resize '80x40' %s %s", flag_in, flag_out)) } }  # Requires that imageMagick be installed. See below and http://stackoverflow.com/questions/25460047/cants-install-imagemagick-with-brew-on-mac-os-x-mavericks
  # From terminal:
  # $ brew update
  # $ brew install imagemagick --disable-openmp --build-from-source
  
  # brew config and README
  brew('_config.brew.yml', '_config.yml')
  unlink('_config.brew.yml')
  brew(sprintf('%s/ohi-webapps/README.brew.md', dir_github), 'README.md')
  
  # add Rstudio project files, plus _site to ignore if testing with local jekyll serve --baseurl ''
  file.copy(system.file('templates/template.Rproj', package='devtools'), sprintf('%s.Rproj', key))
  writeLines(c('.Rproj.user', '.Rhistory', '.RData', '_site','_asset_bundler_cache','.sass','.sass-cache','.DS_Store'), '.gitignore')
  
  # git add, commit and push
  system(sprintf('git add -A; git commit -a -m "%s"', msg))
  system('git push origin gh-pages')
  system('git branch --set-upstream-to=origin/gh-pages gh-pages')
  system('git fetch; git pull')
  setwd(wd)
}
#d = read.csv('tmp/webapp_travis_status.csv', stringsAsFactors=F); head(d); table(d$travis_status)
# keys = subset(d, travis_status %in% c('canceled','passed'), sc_key, drop=T)
#keys = subset(d, travis_status %in% c('failed'), sc_key, drop=T)
#sapply(keys[(which(keys=='asm')+1):length(keys)], populate_website, delete_first=F, copy_images=F, copy_flag=F, msg='add Google Translate via populate_website()')
#sapply(keys, populate_website, delete_first=F, copy_images=F, copy_flag=F, msg='add Google Translate via populate_website()')

update_website <- function(key, msg='ohi-webapps/create_functions.R - update_website()'){
  # key='abw'
  
  # get subcountry vars specific to key
  key <<- key
  source(file.path(dir_github, 'ohi-webapps/create_init_sc.R'))
  
  # cd into repo, checkout gh-pages
  wd = getwd()
  if (!file.exists(dir_repo)) system(sprintf('git clone %s %s', git_url, dir_repo))
  setwd(dir_repo)
  repo = repository(dir_repo)
  
  # switch to gh-pages and get latest
  system('git checkout gh-pages; git pull')
  
  # copy template web files over
  file.copy(list.files(file.path(dir_github, 'ohi-webapps/gh-pages'), full.names=T), '.', overwrite=T, recursive=T)
  
  # brew config and README
  brew('_config.brew.yml', '_config.yml')
  unlink('_config.brew.yml')
  brew(sprintf('%s/ohi-webapps/README.brew.md', dir_github), 'README.md')
  
  # git add, commit and push
  system(sprintf('git add -A; git commit -a -m "%s"', msg))
  system('git push origin gh-pages')
  setwd(wd)
}

revert_website <- function(key, previous='2015-03-23 08:00:00'){
  # key='abw'
  
  # convert previous string to datetime
  previous_t = as.POSIXct(strptime(previous, '%Y-%m-%d %H:%M:%S'))
  
  # get subcountry vars specific to key
  key <<- key
  source(file.path(dir_github, 'ohi-webapps/create_init_sc.R'))
  
  # cd into repo, checkout gh-pages
  wd = getwd()
  if (!file.exists(dir_repo)) system(sprintf('git clone %s %s', git_url, dir_repo))
  setwd(dir_repo)
  repo = repository(dir_repo)
  
  # switch to gh-pages and get latest
  system('git checkout gh-pages; git pull')
  
  # get commit history
  library(git2r)
  ks = commits(repository(dir_repo), topological=F, time=T, reverse=F)
  d = 
    data.frame(
      sha     = sapply(ks, function(x) x@sha),
      when    = sapply(ks, function(x) as.POSIXct(strptime(when(x), '%Y-%m-%d %H:%M:%S'))),
      message = sapply(ks, function(x) x@message),
      v       = NA, stringsAsFactors=F)
  
  # get most recent commit before previous datetime
  sha = subset(d, when < previous_t, sha, drop=T)[1]
  
  # checkout, commit and push
  system(sprintf("git checkout %s .; git commit -m 'reverting to %.7s'; git push origin gh-pages", sha, sha))  
  
  # change back to working directory
  setwd(wd)
}

# keys = sc_studies %>% filter(!is.na(sc_annex_dir)) %>% select(sc_key)
# keys = keys[,1]
# sapply(keys, revert_website, '2015-03-23 08:00:00') # done 2015-03-24 by bbest, jules32

deploy_app <- function(key){ # key='ecu'
  
  key <<- key # assign key to the global namespace so available for other functions
  source(file.path(dir_github, 'ohi-webapps/create_init_sc.R'))
  
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
    system('git rm -rf .')     # ERROR: fatal: pathspec '.' did not match any files
  } else {
    system('git checkout app')
  }
  system('rm -rf *')
  
  # copy installed ohicore shiny app files
  # good to have latest dev ohicore first:
  devtools::install_github('ohi-science/ohicore@dev')  # update by JSL March 19. Could cause problems since need to make sure pulled latest version
  dir_ohicore_app = '~/github/ohicore/inst/shiny_app' #file.path(system.file(package='ohicore'), 'shiny_app') #
  shiny_files = list.files(dir_ohicore_app, recursive=T)
  for (f in shiny_files){ # f = shiny_files[1]
    dir.create(dirname(f), showWarnings=F, recursive=T)
    suppressWarnings(file.copy(file.path(dir_ohicore_app, f), f, overwrite=T, recursive=T, copy.mode=T, copy.date=T))
  }
  
  # get commit version of ohicore app files
  lns = readLines(file.path(dir_ohicore_app, '../../DESCRIPTION'))
  g = sapply(str_split(lns[grepl('^Github', lns)], ': '), function(x) setNames(x[2], x[1]))
  #ohicore_app_commit = sprintf('%s/%s@%s,%.7s', g[['GithubUsername']], g[['GithubRepo']], , g[['GithubSHA1']])
  ohicore_app = list(ohicore_app=list(
    git_owner  = 'jules32', #g[['GithubUsername']],   ## generalize-- DESCRIPTION not found...
    git_repo   = 'gye', # g[['GithubRepo']],
    git_branch = 'draft', # g[['GithubRef']],
    git_commit = 'initial commit')) #g[['GithubSHA1']]))
  
  brew(file.path(dir_github, 'ohi-webapps/app.brew.yml'), 'app.yml')
  file.copy(file.path(dir_github, 'ohi-webapps/travis_app.yml'), '.travis.yml') # overwrite=T)
  
  # add Rstudio project files. cannabalized devtools::add_rstudio_project() which only works for full R packages.
  file.copy(system.file('templates/template.Rproj', package='devtools'), sprintf('%s.Rproj', key))
  writeLines(c('.Rproj.user', '.Rhistory', '.RData', 'github', git_repo), '.gitignore')
  
  # shiny::runApp()    # test app locally
  
  # clean up cloned / archived repos which get populated if testing app
  unlink(git_repo, recursive=T, force=T)
  unlink('github', recursive=T, force=T)
  
  # deploy
  # Error: You must register an account using setAccountInfo prior to proceeding. Sign in to shinyapps.io via Github as bbest, Settings > Tokens to use setAccountInfo('ohi-science',...). March 16 Error: did as above. In console: shinyapps::setAccountInfo(name='jules32', token='...', secret='...')
  deployApp(appDir='.', appName=app_name, upload=T, launch.browser=T, lint=F) # Change this with Nick Brand
  # copying over ssh to the server with Nick Brand. From terminal
  # rm first (rsync would be able to delete stuff that's missing)
  # scp -r gye jstewart@fitz:/srv/shiny-server/ # scp is how to copy over ssh,  -r is recursive
  
  # push files to github app branch
  system('git add -A; git commit -a -m "deployed app"')
  push_branch('app')
  system('git fetch')
  system('git branch --set-upstream-to=origin/app app')
  
  # restore wd
  setwd(wd)
}

deploy_app_nceas <- function(key, nceas_user = 'jstewart'){ # key='ecu' # eventually combine with deploy_app and keep that name.
  
  #   source('ohi-webapps/ohi-travis-functions.r')
  
  key <<- key # assign key to the global namespace so available for other functions
  source(file.path(dir_github, 'ohi-webapps/create_init_sc.R'))
  
  # delete old
  dir_app_old <- sprintf('%s/git-annex/clip-n-ship/%s/shinyapps.io', dir_neptune, git_repo)
  unlink(dir_app_old, recursive=T)
  
  # cd into repo, checkout app
  wd = getwd()
  if (!file.exists(dir_repo)) system(sprintf('git clone %s %s', git_url, dir_repo))
  setwd(dir_repo)
  repo = repository(dir_repo)
  remote_branches = sapply(branches(repo, 'remote'), function(x) str_split(x@name, '/')[[1]][2])
  system('git pull')
  if (!'app' %in% remote_branches){
    system('git checkout --orphan app')
    system('git rm -rf .')     # ERROR: fatal: pathspec '.' did not match any files
  } else {
    system('git fetch origin; git checkout -b app origin/app; git checkout app; git pull')
  }
  system('rm -rf *')
  
  # copy installed ohicore shiny app files
  # good to have latest dev ohicore first:
  # devtools::install_github('ohi-science/ohicore@dev')  # update by JSL March 19. Could cause problems since need to make sure pulled latest version
  dir_ohicore_app = file.path(system.file(package='ohicore'), 'shiny_app') # jules32: '~/github/ohicore/inst/shiny_app'
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
  
  brew(file.path(dir_github, 'ohi-webapps/app.brew.yml'), 'app.yml')
  file.copy(file.path(dir_github, 'ohi-webapps/travis_app.yml'), '.travis.yml', overwrite=T)
  
  # add Rstudio project files. cannabalized devtools::add_rstudio_project() which only works for full R packages.
  file.copy(system.file('templates/template.Rproj', package='devtools'), sprintf('%s.Rproj', key), overwrite=T)
  writeLines(c('.Rproj.user', '.Rhistory', '.RData', 'github', git_repo), '.gitignore')
  
  # shiny::runApp()    # test app locally # need to rm('dir_scenario')
  
  # clean up cloned / archived repos which get populated if testing app
  unlink(git_repo, recursive=T, force=T)
  unlink('github', recursive=T, force=T)
  
  # deploy by copying over ssh to the NCEAS server with Nick Brand
  #   system(sprintf('sudo chown -R %s /srv/shiny-server/%s'), nceas_user, app_name) # may have to run this from Terminal if permission errors
  system(sprintf('rsync -r --delete ../%s %s@fitz.nceas.ucsb.edu:/srv/shiny-server/', app_name, nceas_user))
  system(sprintf("ssh %s@fitz.nceas.ucsb.edu 'chmod g+w -R /srv/shiny-server/%s'", nceas_user, app_name))
  
  # push files to github app branch
  system('git add -A; git commit -a -m "deployed app"; git push origin app')
  #   push_branch('app')
  #   system('git fetch')
  #   system('git branch --set-upstream-to=origin/app app')
  
  # restore wd
  setwd(wd)
}

create_maps = function(key='ecu'){ # key='abw' # setwd('~/github/clip-n-ship/ecu')
  
  # load libraries quietly
  suppressWarnings(suppressPackageStartupMessages({
    library(sp)
    library(rgdal)
    library(raster)
    library(rgeos)
    #library(dismo)
    library(ggplot2)
    library(ggmap) # devtools::install_github('dkahle/ggmap') # want 2.4 for stamen toner-lite
    library(dplyr)
    library(grid) # for unit
    merge = base::merge # override git2r
    diff  = base::diff
  }))
  
  # vars
  buffers = c('offshore'=0.2, 'inland'=0.2, 'inland1km'=0.8, 'inland25km'=0.4, 'offshore3nm'=0.4, 'offshore1km'=0.8) # and transparency
  if (key=='usa'){ # extra buffers making R crash presumably at fortify step b/c so big for USA
    buffers = c('offshore'=0.2, 'inland25km'=0.2, 'inland25km'=0.4) # and transparency
  }
  
  # paths (dir_neptune, dir_github already set by source('~/github/ohi-webapps/create_init.R')
  key <<- key
  source(file.path(dir_github, 'ohi-webapps/create_init_sc.R'))
  dir_data    = file.path(dir_neptune, 'git-annex/clip-n-ship')
  dir_spatial = file.path(dir_data, key, 'spatial')
  dir_pages   = file.path(dir_data, key, 'gh-pages')
  
  # read shapefiles
  shps = setNames(sprintf('%s/rgn_%s_gcs', dir_spatial, names(buffers)), names(buffers))
  plys = lapply(shps, function(x) try(readOGR(dirname(x), basename(x))))
  
  # drop failed buffers
  bufs_valid = sapply(plys, function(x) !'try-error' %in% class(x))
  txt_shp_error = sprintf('%s/%s_readOGR_fails.txt', dir_errors, key)
  unlink(txt_shp_error)
  if (sum(!bufs_valid) > 0){
    cat(sprintf('%s:%s\n', key, paste(names(bufs_valid)[!bufs_valid], collapse=',')), file=txt_shp_error)
  }
  plys = plys[bufs_valid]
  
  # fortify and set rgn_names as factor of all inland rgns
  rgn_names = factor(plys[['inland']][['rgn_name']])
  plys.df = lapply(plys, function(x){
    x = fortify(x, region='rgn_name')
    x$id = factor(as.character(x$id), rgn_names)
    return(x)
  })
  
  # keep only coastal subcountry regions
  ids_offshore = unique(plys.df[['offshore']][['id']])
  
  # get extent from inland and offshore, expanded 10%
  bb_inland25km = bbox(plys[['inland25km']])
  bb_offshore   = bbox(plys[['offshore']])
  
  create_map = function(f_png, width=400, height=250, res=72, effect='toycamera'){
    
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
    cat('bb:',bb,'\n')
    m = try(get_map(location=bb, source='stamen', maptype='toner-lite', crop=T))
    if (class(m) == 'try-error'){
      # fallback to ggmap default map
      m = get_map(location=bb, crop=T)
    }
    p = ggmap(m, extent='device')
    
    # offshore
    if ('offshore' %in% names(plys)){
      p = p + geom_polygon(
        aes(x=long, y=lat, group=group, fill=id), alpha=buffers[['offshore']],
        data=plys.df[['offshore']])
    }
    
    # offshore3nm
    if ('offshore3nm' %in% names(plys)){
      p = p + geom_polygon(
        aes(x=long, y=lat, group=group, fill=id), alpha=buffers[['offshore3nm']],
        data=plys.df[['offshore3nm']])
    }
    
    # offshore1km
    if ('offshore1km' %in% names(plys)){
      p = p + geom_polygon(
        aes(x=long, y=lat, group=group, fill=id), alpha=buffers[['offshore1km']],
        data=plys.df[['offshore1km']])
    }
    
    # inland
    if ('inland' %in% names(plys)){
      p = p + geom_polygon(
        aes(x=long, y=lat, group=group, fill=id), alpha=buffers[['inland']],
        data=subset(plys.df[['inland']], id %in% ids_offshore))
    }
    
    # inland25km
    if ('inland25km' %in% names(plys)){
      p = p + geom_polygon(
        aes(x=long, y=lat, group=group, fill=id), alpha=buffers[['inland25km']],
        data=subset(plys.df[['inland25km']], id %in% ids_offshore))
    }
    
    # inland1km
    if ('inland1km' %in% names(plys)){
      p = p + geom_polygon(
        aes(x=long, y=lat, group=group, fill=id), alpha=buffers[['inland1km']],
        data=subset(plys.df[['inland1km']], id %in% ids_offshore))
    }
    
    # tweaks
    p = p +
      labs(fill='', xlab='', ylab='') +
      theme(
        legend.position='none')
    
    tmp_png = tempfile(tmpdir=dirname(f_png), fileext='.png')
    ggsave(tmp_png, plot=p, width=width/res, height=height/res, dpi=res, units='in', type='cairo-png')
    #system(sprintf('open %s', tmp_png))
    
    unlink(f_png)
    if (effect == 'toycamera'){
      toycamera_options = '-i 5 -o 150 -d 5 -h -3 -t yellow -a 10 -I 0.75 -O 5'
      system(sprintf('%s/ohi-webapps/toycamera %s %s %s', dir_github, toycamera_options, tmp_png, f_png)) # need to make this executable: chmod 77f toycamera
    } else if (effect == 'app'){
      app_png = file.path(dir_github, 'ohi-webapps/fig/app_400x250.png')
      system(sprintf('convert -size 400x250 -composite %s %s -geometry 262x178+136+57 -depth 8 %s', app_png, tmp_png, f_png, f_png))
    } else {
      file.copy(tmp_png, f_png)
    }
    unlink(tmp_png)
    #system(sprintf('open %s', f_png))
  }
  
  dir_pfx = file.path(dir_annex, key, 'gh-pages/images')
  dir.create(dir_pfx, showWarnings=F, recursive=T)
  
  # create maps
  create_map( # for home page banner
    f_png = file.path(dir_pfx, 'regions_1600x800.png'),
    res=72, width=1600, height=800, effect='toycamera')
  create_map( # for regions page
    f_png = file.path(dir_pfx, 'regions_600x400.png'),
    res=72, width=600, height=400, effect='')
  create_map( # for nav regions
    f_png = file.path(dir_pfx, 'regions_400x250.png'),
    res=72, width=400, height=250, effect='')
  create_map( # for nav app
    f_png = file.path(dir_pfx, 'app_400x250.png'),
    res=72, width=262, height=178, effect='app')
  create_map( # for status thumbnail
    f_png = file.path(dir_pfx, 'regions_30x20.png'),
    res=72, width=30, height=20, effect='')
}
#sc_maps_todo = setdiff(str_replace(list.files('~/github/ohi-webapps/errors/map'), '_map.txt', ''), 'aus')
#lapply(as.list(sc_maps_todo[which(sc_maps_todo=='cok'):length(sc_maps_todo)]), create_maps)

custom_maps = function(key){ # key='abw' # setwd('~/github/clip-n-ship/ecu')
  
  # load libraries quietly
  suppressWarnings(suppressPackageStartupMessages({
    library(sp)
    library(rgdal)
    library(raster)
    library(rgeos)
    #library(dismo)
    library(ggplot2)
    library(ggmap) # devtools::install_github('dkahle/ggmap') # want 2.4 for stamen toner-lite
    library(dplyr)
    library(grid) # for unit
    library(tools)
    merge = base::merge # override git2r
    diff  = base::diff
  }))
  
  # vars
  buffers = c('offshore'=0.2, 'inland'=0.2, 'inland1km'=0.8, 'inland25km'=0.4, 'offshore3nm'=0.4, 'offshore1km'=0.8) # and transparency
  if (key=='usa'){ # extra buffers making R crash presumably at fortify step b/c so big for USA
    buffers = c('offshore'=0.2, 'inland25km'=0.2, 'inland25km'=0.4) # and transparency
  }
  
  # paths (dir_neptune, dir_github already set by source('~/github/ohi-webapps/create_init.R')
  key <<- key
  source(file.path(dir_github, 'ohi-webapps/create_init_sc.R'))
  #   key = 'bhi' # necessary for creating baltic map
  dir_data    = file.path(dir_neptune, 'git-annex/clip-n-ship')
  dir_spatial = file.path(dir_data, key, 'spatial') # baltic: dir_spatial = file.path(dir_data, 'bhi', 'spatial') 
  dir_custom  = file.path(dir_spatial, 'custom')
  dir_pages   = file.path(dir_data, key, 'gh-pages')
  
  # process shapefiles:
  
  # read shapefiles, rename headers and save in dir_spatial
  shp_name = file_path_sans_ext(list.files(dir_custom))[1]
  shp_orig = readOGR(dir_custom, shp_name) # inspect: shp_orig
  #names(shp_orig@data) = c('rgn_id', 'rgn_name', 'area_km2', 'hectares')  # for GYE     ## generalize!
  crs = CRS("+proj=longlat +datum=WGS84")
  shp = spTransform(shp_orig,crs) # inspect as data.frame: shp@data // inspect a column: shp@data$rgn_name
  writeOGR(shp, dsn=dir_spatial, 'rgn_offshore_gcs', driver='ESRI Shapefile')
  
  # read shapefiles, store as list
  plys = lapply(shp_name, function(x){
    shp_orig = readOGR(dir_custom, shp_name)
    crs = CRS("+proj=longlat +datum=WGS84")
    shp = spTransform(shp_orig,crs) # shp
    return(shp)
  })
  
  # drop failed buffers
  bufs_valid = sapply(plys, function(x) !'try-error' %in% class(x))
  txt_shp_error = sprintf('%s/%s_readOGR_fails.txt', dir_errors, key)
  unlink(txt_shp_error)
  if (sum(!bufs_valid) > 0){
    cat(sprintf('%s:%s\n', key, paste(names(bufs_valid)[!bufs_valid], collapse=',')), file=txt_shp_error)
  }
  plys = plys[bufs_valid]
  
  # fortify and set rgn_names as factor of all inland rgns
  rgn_names = factor(plys[[1]][['rgn_name']])  # orig: rgn_name, gye:Zona, bhi:rgn_name # need to generalize this
  plys.df = lapply(plys, function(x){
    x = fortify(x, region='rgn_name')              # orig: rgn_name, gye:Zona, bhi:rgn_name # need to generalize this
    x$id = factor(as.character(x$id), rgn_names)
    return(x)
  })         # head(as.data.frame(plys.df))
  
  # keep only coastal subcountry regions
  #   ids_offshore = unique(plys.df[['offshore']][['id']])
  
  # get extent from inland and offshore, expanded 10%
  #   bb_inland25km = bbox(plys[['inland25km']])
  bb_offshore   = bbox(plys[[1]])
  #
  custom_map = function(f_png, width=400, height=250, res=72, effect='toycamera'){
    
    x  = extendrange(c(bb_offshore['x',], bb_offshore['x',]), f=0.1)
    y  = extendrange(c(bb_offshore['y',], bb_offshore['y',]), f=0.1)
    
    # make bbox proportional to desired output image dimensions
    if (diff(x) < width / height * diff(y)){
      x = c(-1, 1) * diff(y)/2 * width/height + mean(x)
    } else {
      y = c(-1, 1) * diff(x)/2 * height/width + mean(y)
    }
    bb = c(x[1], y[1], x[2], y[2])
    
    # plot basemap
    cat('bb:',bb,'\n')
    m = try(get_map(location=bb, source='stamen', maptype='toner-lite', crop=T))
    if (class(m) == 'try-error'){
      # fallback to ggmap default map
      m = get_map(location=bb, crop=T)
    }
    p = ggmap(m, extent='device')
    
    # overlay region buffers as colors; see create_map above for each individual buffer (offshore, offshore3nm etc)
    p = p + geom_polygon(
      aes(x=long, y=lat, group=group, fill=id), alpha=buffers[['offshore']],
      data=plys.df[[1]])
    
    # tweaks
    p = p +
      labs(fill='', xlab='', ylab='') +
      theme(
        legend.position='none')
    
    tmp_png = tempfile(tmpdir=dirname(f_png), fileext='.png')
    ggsave(tmp_png, plot=p, width=width/res, height=height/res, dpi=res, units='in', type='cairo-png')
    #system(sprintf('open %s', tmp_png))
    
    unlink(f_png)
    if (effect == 'toycamera'){
      toycamera_options = '-i 5 -o 150 -d 5 -h -3 -t yellow -a 10 -I 0.75 -O 5'
      system(sprintf('%s/ohi-webapps/toycamera %s %s %s', dir_github, toycamera_options, tmp_png, f_png)) # need to make this executable: chmod 77f toycamera
    } else if (effect == 'app'){
      app_png = file.path(dir_github, 'ohi-webapps/fig/app_400x250.png')
      system(sprintf('convert -size 400x250 -composite %s %s -geometry 262x178+136+57 -depth 8 %s', app_png, tmp_png, f_png, f_png))
    } else {
      file.copy(tmp_png, f_png)
    }
    unlink(tmp_png)
    #system(sprintf('open %s', f_png))
  }
  
  # create gh-pages/images directory
  dir_pfx = file.path(dir_annex, key, 'gh-pages/images')
  dir.create(dir_pfx, showWarnings=F, recursive=T)
  
  # create maps
  custom_map( # for home page banner
    f_png = file.path(dir_pfx, 'regions_1600x800.png'),
    res=72, width=1600, height=800, effect='toycamera')
  custom_map( # for regions page
    f_png = file.path(dir_pfx, 'regions_600x400.png'),
    res=72, width=600, height=400, effect='')
  custom_map( # for nav regions
    f_png = file.path(dir_pfx, 'regions_400x250.png'),
    res=72, width=400, height=250, effect='')
  custom_map( # for nav app
    f_png = file.path(dir_pfx, 'app_400x250.png'),
    res=72, width=262, height=178, effect='app')
  custom_map( # for status thumbnail
    f_png = file.path(dir_pfx, 'regions_30x20.png'),
    res=72, width=30, height=20, effect='')
}

status_travis = function(key, clone=F, enable=T, 
                         csv_status=file.path(dir_github, 'ohi-webapps/tmp/webapp_travis_status.csv')){
  
  wd = getwd()
  key <<- key
  source(file.path(dir_github, 'ohi-webapps/create_init_sc.R'))
  
  if (!file.exists(dir_repo) | clone){
    setwd(dir_repos)
    unlink(dir_repo, recursive=T, force=T)
    system(sprintf('git clone %s', git_url))
  }
  repo = repository(dir_repo)
  res = try(checkout(repo, 'draft'))
  if (class(res)=='try-error'){
    status = 'no draft repo'
  } else {
    setwd(dir_repo)
    system('git pull; git checkout draft; git pull')
    res = suppressWarnings(system(sprintf('travis history -i -r %s -b draft -l 1 2>&1', git_slug), intern=T)) 
    if (length(res) > 0){
      status = str_split(res, ' ')[[1]][2] %>% str_replace(':','')
    } else {
      status = 'no history'
    }
  }
  states = c('canceled','repository not known','passed','errored','failed','no build yet','started','no history','no draft repo')
  #status = states[sapply(states, function(x) grepl(x, res))]
  stopifnot(length(status)==1 | !status %in% states)
  
  # turn on Travis
  if (!status %in% c('no history', 'no build yet','repository not known') & enable==T & !file.exists('.travis.yml')){
    status = paste(status, '& missing .travis.yml')
  }  else if (enable==T & file.exists('.travis.yml')) { # previously also (status %in% c('no history', 'no build yet','repository not known','failed', 'passed', 'created', 'logged')
    system(sprintf('travis encrypt -r %s GH_TOKEN=%s --add env.global', git_slug, gh_token))
    system(sprintf('travis enable -r %s', git_slug))
    system('git commit -am "enabled travis.yml with encrypted github token"; git pull; git push')
    # status = 'enabled' # JSL May 21: I don't think we want to overwrite all the status values 
  }
  
  # update status csv
  read.csv(csv_status, stringsAsFactors=F, na.strings='') %>%
    filter(sc_key != key) %>%
    rbind(
      data.frame(
        sc_key = key,
        travis_status = status,
        date_checked = as.character(Sys.time()))) %>%
    #arrange(sc_key) %>%
    write.csv(csv_status, row.names=F, na='')
  message(sprintf('Travis %s: %s', key, status))
  
  setwd(wd)
  return(status)
}
#res = sapply(intersect(sc_studies$sc_key, sc_annex_dirs), status_travis)
#keys = intersect(sc_studies$sc_key, sc_annex_dirs) # which(keys=='mus')
#travis = read.csv(file.path(dir_github, 'ohi-webapps/tmp/webapp_travis_status.csv'), na='')
#read.csv(file.path(dir_github, 'ohi-webapps/tmp/webapp_travis_status.csv')) %>%
#  select(travis_status) %>% table()
# 2014-11-28
#                            enabled                            errored                             failed no build yet & missing .travis.yml                             passed
#                                 64                                 14                                 20                                  3                                 81
#               repository not known
#                                  5
# 2014-11-28 5:10 pm
#                            enabled                            errored                             failed no build yet & missing .travis.yml                             passed               repository not known
#                                 64                                 14                                 20                                  3                                 81                                  5
# 2014-11-28 6:35
#   canceled     failed no history     passed
#          6         61         15        105
#    filter(travis_status == 'no history') %>%
#    arrange(sc_key) %>%
#    subset(select=sc_key, drop=T) %>% as.character() -> keys
#res = sapply(keys[which(keys=='nld'):length(keys)], status_travis)
#res = sapply(c('aia','alb'), status_travis)
# keys_ghtoken = c('are','asm','aus','bel','ben','bgd','bgr','bhr','bhs','bmu','bra','brb','brn','can','chl',
#                  'dji','kir','kwt','lca','mhl','mmr','mne','mrt','nic','niu','nor','sau','sdn','sen','sgp','shn')
# res = sapply(keys_ghtoken, status_travis, clone=T)
#res = sapply(keys[(which(keys=='chn')+1):length(keys)], status_travis, enable=F)
#table(res)
# redo
#c('bih','bvt','cog','cpt','cuw','egy','est','fin','fra','fro','ggy','gtm','guy','hmd','ind','iot','jey','jpn','kor','ltu','lva','maf',
#  'mco','nfk','nld','pol','sgs','tto','rus','spm')

# tto
# Error in plot.new() :
# could not open file 'reports/figures/flower_Couva/Tabaquite/Talparo.png'
# Calls: eval ... create_results -> PlotFlower -> plot -> plot.default -> plot.new

#lapply(as.list(c('aus','bmu','bra','can','chl','deu','dji','dnk','eri','esh','fsm','gbr','geo','hrv','hti','idn','irn','isl','ita','jam','kir','lca','lka','mhl','mmr','mne','mrt','nic','niu','nor','sau','sdn','sen','sgp','shn','slb','sle','stp','zaf')), enable_travis)
#lapply(intersect(sc_studies$sc_key, sc_annex_dirs), enable_travis)

update_status <- function(){
  # TODO: cleanup function b/c manually set iteration from civ below and dedented lines
  
  # get status repo  depth of 1 only
  if (file.exists('~/github/subcountry')){
    system('cd ~/github/subcountry; git pull')
  } else {
    system('git clone --depth=1 https://github.com/OHI-Science/subcountry ~/github/subcountry')
  }
  csv_status = '~/github/subcountry/_data/status.csv'
  #read.csv(csv_status, stringsAsFactors=F) %>% head
  
  d_sc = sc_studies %>%
    select(sc_key, sc_name, gl_rgn_name, sc_annex_dir) %>%
    left_join(
      read.csv(file.path(dir_github, 'ohi-webapps/tmp/rgn_notmatching_gadm_manual_utf-8.csv'), na.strings='') %>%
        select(
          sc_name  = rgn_name,
          gadm_name,
          gadm_lumped = rgn_to_gadm_lumping,
          gadm_split  = rgn_to_gadm_splitting),
      by='sc_name') %>%
    left_join(
      read.csv(file.path(dir_github, 'ohi-webapps/tmp/webapp_travis_status.csv')),
      by='sc_key') %>%
    left_join(
      read.csv(file.path(dir_github, 'subcountry/_data/status.csv'), na.strings=''), # repo, study_area, status, last_mod, last_sha, last_msg, map_url, n_regions
      by = c('sc_key'='repo')) %>%
    select(-study_area, -gl_rgn_name) %>%
    rename(travis_checked=date_checked)
  
  # TODO: mutate(travis_checked = 'passed','failed','lumped to GADM','split to GADM','not created b/c accented rename')
  
  subset(d_sc, travis_status=='no draft repo')
  #   sc_key     sc_name                                 sc_annex_dir     gadm_name gadm_lumped gadm_split travis_status      travis_checked                       status last_mod last_sha last_msg map_url n_regions
  #   31    civ Ivory Coast /Volumes/data_edit/git-annex/clip-n-ship/civ Côte d'Ivoire          NA         NA no draft repo 2014-11-28 23:54:59 draft repo not yet generated     <NA>     <NA>     <NA>    <NA>        NA
  table(is.na(d_sc$travis_status))
  # FALSE  TRUE
  #   187    34
  # built  not   total
  #   186   35 = 221
  table(d_sc$travis_status)
  #      canceled        failed no draft repo        passed
  #             6            26             1           154
  #   failed     passed   built
  #       26        160 = 186
  d_sc %>%
    filter(is.na(d_sc$travis_status)) %>%
    mutate(
      status_general = ifelse(
        grepl('lumped in GADM', status),
        'lumped in GADM',
        ifelse(
          grepl('split in GADM', status),
          'split in GADM',
          ifelse(
            grepl('not found in GADM', status),
            'not found in GADM',
            as.character(status))))) %>%
    select(status_general) %>% table
  #    not found in GADM   split in GADM  lumped in GADM
  #                   26               3               3
  #   Antarctica  Israel   Ivory Coast
  #            1       1             1                   = 35 not built
  
  # TODO: close issues!!
  
  # handle NAs ----
  d_na = filter(d_sc, is.na(status) & is.na(travis_status)) %>%
    mutate(
      status = ifelse(
        !is.na(gadm_lumped),
        sprintf('%s lumped in GADM to %s', sc_name, gadm_name),
        ifelse(
          !is.na(gadm_split),
          sprintf('%s split in GADM to %s', sc_name, gadm_name),
          sprintf('%s not found in GADM', sc_name)
        ))) %>%
    mutate(
      last_mod = as.character(Sys.Date())) %>%
    select(repo = sc_key, status, last_mod)
  
  rbind_list(
    read.csv(csv_status, stringsAsFactors=F) %>%
      filter(!repo %in% d_na$repo),
    read.csv(csv_status, stringsAsFactors=F) %>%
      filter(repo %in% d_na$repo) %>%
      select(-status, -last_mod) %>%
      left_join(
        d_na %>%
          select(repo, status, last_mod),
        by='repo')) %>%
    arrange(repo) %>%
    select(repo, study_area, status, last_mod, last_sha, last_msg, map_url, n_regions) %>%
    write.csv(csv_status, row.names=F, na='')
  
  # handle others ----
  #subset(d_sc, is.na(status) & !is.na(travis_status), c(sc_key, travis_status))
  
  wd = getwd()
  keys = subset(d_sc, is.na(status) & !is.na(travis_status), sc_key, drop=T)
  for (key in keys[which(keys=='civ'):length(keys)]){ # key='bih'
    
    key <<- key
    source(file.path(dir_github, 'ohi-webapps/create_init_sc.R'))
    #message(sprintf('key: %s, dir_repo:%s', key, dir_repo))
    setwd(dir_repo)
    
    system('cd ~/github/subcountry; git pull')
    d = read.csv(csv_status, stringsAsFactors=F)
    i = which(d$repo == key)
    
    # get this repo's info
    repo = repository(dir_repo)
    res = try(checkout(repo, 'draft'))
    if (class(res)=='try-error'){
      d$status[i]    = 'draft repo not yet generated'
    } else {
      k = commits(repo)[[1]]
      
      rgns_csv = file.path(default_scenario, 'reports/tables/region_titles.csv')
      if (file.exists(rgns_csv)){
        n_rgns = read.csv(rgns_csv) %>% nrow() - 1
      } else {
        n_rgns = NA
      }
      
      # update d
      d$status[i]    = sprintf('[![](https://api.travis-ci.org/OHI-Science/%s.svg?branch=draft)](https://travis-ci.org/OHI-Science/%s/branches)', git_repo, git_repo)
      d$last_mod[i]  = sprintf('%0.10s', as(k@author@when, 'character'))
      d$last_sha[i]  = sprintf('%0.7s', k@sha)
      d$last_msg[i]  = k@summary
      d$map_url[i]   = sprintf('http://ohi-science.org/%s/images/regions_30x20.png', git_repo)
      d$n_regions[i] = n_rgns
    }
    
    # update status repo
    write.csv(d, csv_status, row.names=F, na='')
    system(sprintf('cd ~/github/subcountry; git commit -a -m "updated status for %s commit %0.7s"', key, k@sha))
    system('cd ~/github/subcountry; git push https://${GH_TOKEN}@github.com/OHI-Science/subcountry.git HEAD:gh-pages')
    
  }
  
  # return to original directory
  setwd(wd)
}

# other updates ----

additions_draft <- function(key, msg='ohi-webapps/create_functions.R - additions_draft()'){
  # by @bbest 2015-04-23 (previously update_travis_yml()) , @jules32 2015-05-13
  
  # get subcountry vars specific to key
  key <<- key
  source(file.path(dir_github, 'ohi-webapps/create_init_sc.R'))
  
  # clone repo
  wd = getwd()
  if (!file.exists(dir_repo)) system(sprintf('git clone %s %s', git_url, dir_repo))
  setwd(dir_repo)
  repo = repository(dir_repo)
  
  # switch to draft branch and get latest
  system('git checkout draft; git pull')
  
  ## 1. update .travis.yml file a la github.com/OHI-Science/issues/issues/427
  readLines('.travis.yml') %>%
    str_replace_all('- default_branch_scenario=', '- default_branch_scenario: ') %>%
    str_replace_all('- study_area=',              '- study_area: ') %>%
    str_replace_all('- secure=',                  '- secure: ') %>%
    writeLines('.travis.yml')
  
  ## 2. update setwd() in assessment/scenario/calculate_scores.r
  readLines(file.path(default_scenario, 'calculate_scores.r')) %>%
    str_replace("setwd.*", paste0("setwd('", file.path(dir_github, key, default_scenario), "')")) %>%
    writeLines(file.path(default_scenario, 'calculate_scores.r'))
  
  ## 3. update launch_app() call in assessment/scenario/launch_app_code.r
  readLines(file.path(default_scenario, 'launch_app_code.r')) %>%
    str_replace(".*launch_app.*", paste0("ohicore::launch_app('", file.path(dir_github, key, default_scenario), "')")) %>%
    writeLines(file.path(default_scenario, 'launch_app_code.r'))
  
  ## 4. save ohi-webapps/install_ohicore.r
  fn = 'install_ohicore.r'
  file.copy(file.path('~/github/ohi-webapps', fn), 
            file.path(dir_repo, default_scenario, fn), overwrite=T)
  
  ## 5a. create and populate prep folder if it doesn't exist
  if ( !'prep' %in% list.dirs(default_scenario, full.names=F) ) {
    prep_subfolders = c('FIS', 'MAR', 'AO', 'NP', 'CS', 'CP', 'LIV', 'ECO', 'TR', 'CW', 'ICO', 'LSP', 'SPP', 'HAB', 
                        'pressures', 'resilience')
    # prep folder and README.md
    dir.create(file.path(dir_repo, default_scenario, 'prep'))
    file.copy(file.path(dir_github, 'ohi-webapps/tmp/README_template_prep.md'), 
              file.path(default_scenario, 'prep', 'README.md'), overwrite=T)
    # goal folders and README.md's
    sapply(file.path(dir_repo, default_scenario, sprintf('prep/%s', prep_subfolders)), dir.create)
    file.copy(file.path(dir_github, 'ohi-webapps/tmp/README_template_goal.md'), 
              file.path(default_scenario, sprintf('prep/%s', prep_subfolders), 'README.md'), overwrite=T)
    
    ## 5b. create and populate prep/tutorials folder 
    dir_tutes = file.path(dir_github, 'ohimanual/tutorials/R_tutes')
    
    dir.create(file.path(dir_repo, default_scenario, 'prep/tutorials'))
    file.copy(file.path(dir_tutes, 'R_tutes_all.md'), 
              file.path(default_scenario, 'prep/tutorials', 'R_intro.md'), overwrite=T)
    readLines(file.path(dir_tutes, 'R_tutes.r')) %>%
      str_replace("setwd.*", 
                  paste0("setwd('", file.path(dir_github, key, default_scenario, 'prep/tutorials'), "')")) %>%
      writeLines(file.path(default_scenario, 'prep/tutorials', 'R_tutorial.r'))    
  }
  
  # git add, commit and push
  system(sprintf('git add -A; git commit -a -m "%s"', msg))
  system('git push origin draft')
  
  # ensure on draft branch 
  checkout(repo, 'draft')
  
  # merge published with the draft branch
  system('git checkout published')
  system('git merge draft')
  system('git push origin published')
  
  setwd(wd)
}


fix_travis_yml <- function(key, msg='no updated needed, ohi-webapps/create_functions.R - fix_travis_yml()', 
                           csv_st=file.path(dir_github, 'ohi-webapps/tmp/webapp_yml_secure_recip.csv')){
  # with @bbest 2015-05-19
  
  # get subcountry vars specific to key
  key <<- key
  source(file.path(dir_github, 'ohi-webapps/create_init_sc.R'))
  
  # clone repo
  wd = getwd()
  if (!file.exists(dir_repo)) system(sprintf('git clone %s %s', git_url, dir_repo))
  setwd(dir_repo)
  repo = repository(dir_repo)
  
  # switch to draft branch and get latest
  system('git checkout draft; git pull')
  
  yml_log = read.csv(csv_st) %>%
    filter(sc_key == key)
  
  if ( !yml_log$travis_secure | !yml_log$travis_recip ){
    
    msg='fix secure/recip, ohi-webapps/create_functions.R - fix_travis_yml()'
    
    # rebrew travis
    brew(travis_draft_yaml_brew, '.travis.yml')
    
    # run status_travis
    st = status_travis(key)
    
    # switch to draft branch and get latest
    system('git checkout draft; git pull')
    
    # may no longer be necessary
    readLines('.travis.yml') %>% 
      str_replace_all('- secure=', '- secure: ') %>%
      writeLines('.travis.yml')
    
    # run checks again
    yml = file.path(dir_repo, '.travis.yml')
    y = yaml.load_file(yml)
    
    # check #1: has secure var?
    secure = 'secure' %in% names(unlist(y$env$global))
    
    # check #2: has lowndes as a recipient # TODO: switch to ohi-science@nceas.ucsb.edu?
    recip = 'lowndes@nceas.ucsb.edu' %in% unlist(y$notifications$email$recipients)
    
    # update log
    read.csv(csv_st, stringsAsFactors=F, na.strings='') %>%
      filter(sc_key != key) %>%
      rbind(
        data.frame(
          sc_key = key,
          travis_secure = secure,
          travis_recip  = recip,
          travis_status = st,
          date_checked  = as.character(Sys.time()))) %>%
      write.csv(csv_st, row.names=F, na='')    
  }
  
  # git add, commit and push
  system(sprintf('git add -A; git commit -a -m "%s"', msg))
  system('git push origin draft')
  
  setwd(wd)
  
}


status_travis_check = function(key, csv_check=file.path(dir_github, 'ohi-webapps/tmp/webapp_travis_status_check.csv')){
  # travis commandline tips http://blog.travis-ci.com/2013-01-21-more-cli-tricks/
  
  wd = getwd()
  key <<- key
  source(file.path(dir_github, 'ohi-webapps/create_init_sc.R'))
  
  if (!file.exists(dir_repo)){
    setwd(dir_repos)
    unlink(dir_repo, recursive=T, force=T)
    system(sprintf('git clone %s', git_url))
  }
  repo = repository(dir_repo)
  res = try(checkout(repo, 'draft'))
  if (class(res)=='try-error'){
    status = 'no draft repo'
  } else {
    setwd(dir_repo)
    system('git pull; git checkout draft; git pull')
    res = suppressWarnings(system(sprintf('travis history -i -r %s -b draft -l 6 2>&1', git_slug), intern=T)) # 'travis history' to stdout failed
    if (length(res) > 0){
      status = str_split(res[1], ' ')[[1]][2] %>% str_replace(':','')
    } else {
      status = 'no history'
    }
  }
  
  # update status csv
  read.csv(csv_check, stringsAsFactors=F, na.strings='') %>%
    filter(sc_key != key) %>%
    rbind(
      data.frame(
        sc_key = key,
        travis_status = status,
        date_checked = as.character(Sys.time()))) %>%
    write.csv(csv_check, row.names=F, na='')
  message(sprintf('Travis %s: %s', key, status))
  
  setwd(wd)
  
}

travis_passing_compare = function(
  status_orig_csv = 'https://raw.githubusercontent.com/OHI-Science/ohi-webapps/9c7a3f152ba10000b7ad7380de1d7d13eb486898/tmp/webapp_travis_status.csv', 
  status_now_csv = '~/github/ohi-webapps/tmp/webapp_travis_status_check.csv') {
  
  # 1. access travis status from November 2014
  keys_2014_11_28 = readr::read_csv(status_orig_csv, col_types = 'cc_') # don't need to read in date column, see github.com/hadley/readr

  # 2. check and save the current travis status (don't use status_travis() because that will enable travis, we just want to check)
  keys_2015_05_21 = read.csv(status_now_csv)

  # 3. identify which keys are now not passing that were in Nov2014
  keys_now_not_passing = keys_2014_11_28 %>%
  select(sc_key, status_orig = travis_status) %>%
  full_join(keys_2015_05_21 %>%
              select(sc_key, status_now = travis_status) %>%
              mutate(sc_key = as.character(sc_key), 
                     status_now = as.character(status_now)), 
            by= 'sc_key') %>%
  filter(status_orig == 'passed' & status_now != 'passed') 

  return(keys_now_not_passing)
}

merge_published_draft <- function(key, msg='ohi-webapps/create_functions.R - merge_published_draft()'){
  
  # get subcountry vars specific to key
  key <<- key
  source(file.path(dir_github, 'ohi-webapps/create_init_sc.R'))
  
  # clone repo
  wd = getwd()
  if (!file.exists(dir_repo)) system(sprintf('git clone %s %s', git_url, dir_repo))
  setwd(dir_repo)
  repo = repository(dir_repo)
  
  # switch to draft branch and get latest
  system('git checkout draft; git pull')
  
  # merge published with the draft branch
  system('git checkout published')
  system('git merge draft')
  system('git push origin published')
  
  setwd(wd)
}

