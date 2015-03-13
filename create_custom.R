# set vars and get functions
setwd('~/github/ohi-webapps')
source('process_rasters.r') 
source('create_init_custom.R') # by J. Lowndes Mar 11 2015
source('create_functions.R')
source('ohi-travis-functions.R')

repo_name     = key
git_owner     = 'OHI-Science'
git_repo      = repo_name
dir_repo = sprintf('~/tmp/%s', git_repo) 
git_slug  = sprintf('%s/%s', git_owner, git_repo)
git_url   = sprintf('https://github.com/%s', git_slug) 

# view map and accompanying data: 
library(rgdal) 
dir_neptune <- c(
  'Windows' = '//neptune.nceas.ucsb.edu/data_edit',
  'Darwin'  = '/Volumes/data_edit',
  'Linux'   = '/var/data/ohi')[[ Sys.info()[['sysname']] ]]

gye = readOGR(dsn=file.path(dir_neptune, 'git-annex/tmp/GYE_shp'), 
              layer='Regiones')
plot(gye)
gye@data


# back to the script
make_sc_coastpop_lyr(gye, redo=F)

# loop through countries

redo_maps = F

keys_custom = c('gye')
for (key in keys_custom){ # key = 'gye' 
   
  # set vars by subcountry key
#   setwd(dir_repos)
#   source(sprintf('%s/ohi-webapps/create_init_sc.R', dir_github))

  # create github repo
  repo = create_gh_repo(key)
  
  # create maps
  txt_map_error = sprintf('%s/%s_map.txt', dir_errors, key)
  unlink(txt_map_error)  
  txt_shp_error = sprintf('%s/%s_readOGR_fails.txt', dir_errors, key)
  unlink(txt_shp_error)
  if (!all(file.exists(file.path(dir_annex, key, 'gh-pages/images', c('regions_1600x800.png', 'regions_600x400.png', 'regions_400x250.png', 'app_400x250.png', 'regions_30x20.png')))) | redo_maps){
    res = try(custom_maps(key))
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
  if (Sys.info()[['sysname']] == 'Darwin'){
    status_travis(key)
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