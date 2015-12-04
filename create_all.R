# create_all.R. 
# by @bbest, cleaned up by @jules32. See original notes at the bottom or @bbest's last commit, 9c7a3f152. 
# edit_webapps.rmd is now a companion script for updating existing repos.

## summary ----
# This script will create repos and webapps for each 'key', which is the 
# 3-letter code (there are exceptions) for each study/assessment area. Study
# areas were originally every country from the global assessment, but we now do
# custom study areas as well (eg. Gulf of Guayaquil, GYE).
# 

## setup ----

setwd('~/github/ohi-webapps')

source('create_init.R')            # load all libraries, set directories relevant to all keys
source('create_functions.R')       # all functions for creating and updating repos and webapps

## loop through keys ----
# this is in order of steps from start to finish, but these functions can also be run individually

map_custom = T  # make a custom map based on map from OHI+ group
redo_maps = F
enable_travis = F

keys_redo = c('ohibc')             # list whichever keys to make repos and webapps (originally was full list)

for (key in keys_redo){ # key = 'usa' # key = 'rus' # key = sc_studies$sc_key[1] 
  
  # set vars by subcountry key
  setwd(dir_repos)
  source(sprintf('%s/ohi-webapps/create_init_sc.R', dir_github))    
  setwd(dir_repo)
  
  # create github repo on github.com
  repo = create_gh_repo(key)
  
  # create maps
  if (!map_custom) {  # create_maps() original by @bbest
    txt_map_error = sprintf('%s/%s_map.txt', dir_errors, key)
    unlink(txt_map_error)  
    txt_shp_error = sprintf('%s/%s_readOGR_fails.txt', dir_errors, key)
    unlink(txt_shp_error)
    if (!all(file.exists(
      file.path(dir_annex, key, 
                'gh-pages/images', 
                c('regions_1600x800.png', 'regions_600x400.png', 'regions_400x250.png', 
                  'app_400x250.png', 'regions_30x20.png')))) 
      | redo_maps){
      res = try(create_maps(key))
      if (class(res)=='try-error'){
        cat(as.character(traceback(res)), file=txt_map_error)
        next
      }
    }
  } else { # create custom_maps() by @jules32
    if (!all(file.exists(
      file.path(dir_annex, key,
                'gh-pages/images', 
                c('regions_1600x800.png', 'regions_600x400.png', 'regions_400x250.png', 
                  'app_400x250.png', 'regions_30x20.png'))))
      | redo_maps){
      res = try(custom_maps(key))
    }
  }
  
  # populate draft branch of repo
  populate_draft_branch()    # turn buffers back on if making buffers
  additions_draft() 
  
  if (enable_travis) { # enable_travis = T
    
    source('~/github/ohi-webapps/ohi-travis-functions.R')   # all functions to update the webapp with Travis
    
    # push draft branch
    setwd(dir_repo)
    push_branch('draft') # source('ohi-travis-functions.r')
    system('git pull')
    
    # calculate_scores
    setwd(dir_repo)
    res = try(calculate_scores())
    # if problem calculating, log problem and move on to next subcountry key
    txt_calc_error = sprintf('%s/%s_calc-scores.txt', dir_errors, key)
    unlink(txt_calc_error)
    if (class(res)=='try-error'){
      cat(as.character(traceback(res)), file=txt_calc_error)
      next
    }
    
    # create flower plot and table
    setwd(dir_repo)
    create_results()
    
    # push draft and published branches
    setwd(dir_repo)
    push_branch('draft')
    push_branch('published')
    system('git checkout published; git pull; git checkout draft')
    
    # populate website
    populate_website(key)
    
    # ensure draft is default branch, delete extras (like old master)
    edit_gh_repo(key, default_branch='draft', verbosity=1)
    delete_extra_branches()
    
    # create pages based on results
    setwd(dir_repo)
    system('git pull; git checkout draft; git pull')
    create_pages()
    system('git checkout gh-pages; git pull; git checkout published; git pull')
    
    # enable Travis if on Mac
    # install Travis client: `sudo gem install travis; travis login --org --auto` on Terminal (https://github.com/travis-ci/travis.rb)
    if (Sys.info()[['sysname']] == 'Darwin'){
      source(file.path(dir_github, 'ohi-webapps/create_init_sc.R'))   # Error in system(sprintf("travis history -i -r %s -b draft -l 1 2>&1",  :error in running command 
      status_travis(key)
    }
    
    # deploy app
    #devtools::install_github('ohi-science/ohicore@dev') # install latest ohicore, with DESCRIPTION having commit etc to add to app
    res = try(deploy_app_nceas(key, nceas_user))
    # if problem calculating, log problem and move on to next subcountry key
    txt_app_error = sprintf('%s/%s_app.txt', dir_errors, key)
    unlink(txt_app_error)
    if (class(res)=='try-error'){
      cat(as.character(traceback(res)), file=txt_app_error)
      next
    }
    
  } else { # enable_travis = F
    
    source('~/github/ohi-webapps/ohi-functions.R')          # all functions to update the webapp without Travis
    
    # push draft branch ~ adapted from create.all
    setwd(dir_repo)
    push_branch('draft') # source('ohi-functions.r')
    system('git pull')
    
    # calculate scores ~~ adapted from create.all
    setwd(dir_repo)
    calculate_scores_notravis() # consider just calling CalculateAll() here instead of this function. Will need to add git2r info
    
    # create flower plot and table
    setwd(dir_repo)
    update_results() # run this one time only; afterwards let webapps generate their own figures with report.r
    
    # push/merge draft and published branches 
    setwd(dir_repo)
    push_branch('draft')
    merge_published_draft(key) # from create_functions
    system('git checkout draft')
    
    # populate website
    populate_website(key)
    update_website(key)
    
    # update pages based on results (not create_pages())
    setwd(dir_repo)
    system('git pull; git checkout draft; git pull')
    update_pages()     # source('ohi-functions.r')
    system('git checkout gh-pages; git pull; git checkout published; git pull')
    
    # deploy app to fitz!
    deploy_app_nceas(key, nceas_user)
    system('git checkout draft; git pull')
    
  } # end if (enable_travis)
  
} # end for (key in keys)



## @bbest's original notes ----

# AT THE BOTTOM OF CREATE.R
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

# AT THE TOP OF CREATE.R
# limit to those that were able to calculate scores last time
# status_prev = read.csv('tmp/webapp_status_2014-10-23.csv')
# sc_studies = sc_studies %>%
#   semi_join(
#     status_prev %>% 
#       filter(finished==T),
#     by=c('sc_name'='Country')) %>%  # n=138
#   arrange(sc_key) %>%
#   filter(sc_key >= 'mar') 
# TODO:
# - are : create_maps: readOGR('/Volumes/data_edit/git-annex/clip-n-ship/are/spatial', 'rgn_inland1km_gcs') # Error in ogrInfo(dsn = dsn, layer = layer, encoding = encoding, use_iconv = use_iconv) : Multiple # dimensions:
# - aus : create_maps: ggmap tile not found prob
# - nic : missing spatial/rgn_offshore3nm_data.csv
# - zaf : inland1km Error in ogrInfo(dsn = dsn, layer = layer, encoding = encoding, use_iconv = use_iconv) : Multiple # dimensions: 

# studies not part of loop
# sc_studies %>%
#   anti_join(
#     status_prev %>% 
#       filter(finished==T),
#     by=c('sc_name'='Country')) %>%
#   select(sc_key, sc_name) %>%
#   arrange(sc_key)
# priority areas todo:
# c('esp','usa','chn','chl','fin','kor','fji') # 'isr' no spatial


# fix "/" in names for Trinidad and Tobago (tto)
# for (csv in list.files('/Volumes/data_edit/git-annex/clip-n-ship/tto', '\\.csv$', recursive=T, full.names=T)){ # csv = list.files('/Volumes/data_edit/git-annex/clip-n-ship/tto', '\\.csv$', recursive=T, full.names=T)[1]
#   d = read.csv(csv)
#   if ('rgn_name' %in% names(d)){
#     d %>%
#       mutate(
#         rgn_name = str_replace_all(rgn_name, '/', '-')) %>%
#       write.csv(csv, row.names=F, na='')
#   }
# }

#for (key in sc_studies$sc_key){ # key = 'fji' # key = sc_studies$sc_key[1]
#sc_run = c('can'=T,'chn'=T,'fin','fji','fro','grl','idn','ind','irl','irn','irq','isl','ita','jpn','kna','lca','lka','mmr','mne','nld','nzl','rus','sau','sdn','sen','shn','slb','sle', 'som','spm','stp','sur','svn','syr')
#keys_redo = c('bih','bvt','cog','cpt','cuw','egy','est','fin','fra','fro','ggy','gtm','guy','hmd','ind','iot','jey','jpn','kor','ltu','lva','maf','mco','nfk','nld','pol','sgs')

# TODO: 'rus','spm' after neptune process_rasters
# TODO: 'syr' inland1km, vnm offshore3nm
#
