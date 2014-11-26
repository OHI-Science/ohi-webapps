
# set vars and get functions
setwd('~/github/ohi-webapps')
source('create_init.R')
source('create_functions.R')
source('ohi-travis-functions.R')

# loop through countries

# limit to those that were able to calculate scores last time
status_prev = read.csv('tmp/webapp_status_2014-10-23.csv')
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
redo_maps = F

#for (key in sc_studies$sc_key){ # key = 'fji' # key = sc_studies$sc_key[1]
#sc_run = c('can'=T,'chn'=T,'fin','fji','fro','grl','idn','ind','irl','irn','irq','isl','ita','jpn','kna','lca','lka','mmr','mne','nld','nzl','rus','sau','sdn','sen','shn','slb','sle', 'som','spm','stp','sur','svn','syr')
for (key in 'usa'){ # key = 'usa' # key = 'rus' # key = sc_studies$sc_key[1]  
  
  # set vars by subcountry key
  setwd(dir_repos)
  source(sprintf('%s/ohi-webapps/create_init_sc.R', dir_github))

  # create github repo
  #repo = create_gh_repo(key)
  
  # create maps
  txt_map_error = sprintf('%s/%s_map.txt', dir_errors, key)
  unlink(txt_map_error)  
  txt_shp_error = sprintf('%s/%s_readOGR_fails.txt', dir_errors, key)
  unlink(txt_shp_error)
  if (!all(file.exists(file.path(dir_annex, key, 'gh-pages/images', c('regions_1600x800.png', 'regions_600x400.png', 'regions_400x250.png', 'app_400x250.png', 'regions_30x20.png')))) | redo_maps){
    res = try(create_maps(key))
    if (class(res)=='try-error'){
      cat(as.character(traceback(res)), file=txt_map_error)
      next
    }
  }
  
  # populate draft branch
  populate_draft_branch()
  
  # push draft branch
  setwd(dir_repo)
  push_branch('draft')
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
  populate_website()
  
  # ensure draft is default branch, delete extras (like old master)
  edit_gh_repo(key, default_branch='draft', verbosity=1)
  delete_extra_branches()
  
  # create pages based on results
  setwd(dir_repo)
  system('git pull; git checkout draft; git pull')
  create_pages()
  system('git checkout gh-pages; git pull; git checkout published; git pull')
  
  # enable Travis if on Mac
  if (Sys.info()[['sysname']] == 'Darwin'){
    enable_travis()
  }
  
  # deploy app
  #devtools::install_github('ohi-science/ohicore@dev') # install latest ohicore, with DESCRIPTION having commit etc to add to app
  res = try(deploy_app(key))
  # if problem calculating, log problem and move on to next subcountry key
  txt_app_error = sprintf('%s/%s_app.txt', dir_errors, key)
  unlink(txt_app_error)
  if (class(res)=='try-error'){
    cat(as.character(traceback(res)), file=txt_app_error)
    next
  }
  

} # end for (key in keys)

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