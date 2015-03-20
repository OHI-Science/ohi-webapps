# create_custom.r
# by J. Lowndes lowndes@nceas.ucsb.edu, March 2015
#
# This script creates custom OHI+ repos and WebApps 
# It is based off of create_all.r by B. Best, Fall 2014
#
# Requirements: 
# 1. Save shp files in ...


# set vars and get functions
setwd('~/github/ohi-webapps')

# source('process_rasters.r') 
source('create_init_custom.R') # by J. Lowndes Mar 11 2015
source('create_functions.R')
source('ohi-travis-functions.R')

dir_neptune <- c(
  'Windows' = '//neptune.nceas.ucsb.edu/data_edit',
  'Darwin'  = '/Volumes/data_edit',
  'Linux'   = '/var/data/ohi')[[ Sys.info()[['sysname']] ]]

# Multiple country lookup
csv_mcntry  <- sprintf('%s/ohi-webapps/tmp/gl-rgn_multiple-cntry_sc-rgn_manual.csv', dir_github)
gl_sc_mcntry <- read.csv(csv_mcntry)


# # loop through countries
redo_repo = F
redo_maps = F
keys_custom = c('gye') # set up an 'if exists, skip

for (key in keys_custom){ # key = 'gye' 
   
  # setup
  repo_name     = key
  git_owner     = 'jules32'
  git_repo      = repo_name
  dir_repo = sprintf('~/tmp/%s', git_repo) 
  git_slug  = sprintf('%s/%s', git_owner, git_repo)
  git_url   = sprintf('https://github.com/%s', git_slug) 
  pages_url     = sprintf('http://ohi-science.org/%s', git_repo)
  dir_annex_sc  = file.path(dir_annex, key)
  study_area = 'Golfo de Guayaquil' # make generalizable with ohi-webapps/tmp/gl_rgn_custom
  default_branch          = 'published'
  default_scenario        = 'region2015'  # generalize this
  default_branch_scenario = 'published/region2015'  # generalize this
  sc_studies = sc_studies %>%
    filter(sc_key == key)
  name = sc_studies$sc_name 
  

  # create empty github repo 
  if(redo_repo) repo = create_gh_repo(key)
  
  # create maps
  if (!all(file.exists(
    file.path(dir_annex, key, 
              'gh-pages/images', c('regions_1600x800.png', 'regions_600x400.png', 'regions_400x250.png', 'app_400x250.png', 'regions_30x20.png'))))
    | redo_maps){
    res = try(custom_maps(key))
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
  
  # create flower plot and table
  setwd(dir_repo)
  create_results()
  
  # push draft and published branches
  setwd(dir_repo)
  push_branch('draft')
  push_branch('published')
  system('git checkout published; git pull; git checkout draft')
  
  # populate WebApp (pages will be empty)
  populate_website(key)
  
  # ensure draft is default branch, delete extras (like old master)
  edit_gh_repo_custom(key, default_branch='draft', verbosity=1)
  delete_extra_branches()            # must be in dir_repo = sprintf('~/tmp/%s', key)
  
  # create pages on WebApp based on results
  setwd(dir_repo)
  system('git pull; git checkout draft; git pull')
  create_pages()  # make a custom because the error-checking throws an error since custom repos aren't included in the master list
#   system('git checkout gh-pages; git commit -m "updated jules32 from bbest" ')
  system('git checkout gh-pages; git pull; git checkout published; git pull')
  
  # enable Travis if on Mac
  if (Sys.info()[['sysname']] == 'Darwin'){
    status_travis(key)
  }
  
  # deploy app
  #devtools::install_github('ohi-science/ohicore@dev') # install latest ohicore, with DESCRIPTION having commit etc to add to app
#   source(file.path(dir_github, 'ohi-webapps/create_init_sc.R'))
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