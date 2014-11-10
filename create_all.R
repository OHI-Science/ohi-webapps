
# set vars and get functions
setwd('~/github/ohi-webapps')
source('create_init.R')
source('create_functions.R')
source('ohi-travis-functions.R')

# loop through countries
for (key in sc_studies$sc_key){ # key = 'alb'
  
  # set vars by subcountry key
  source('create_init_sc.R')
      
  # create github repo
  #create_gh_repo(key)
  
  # populate draft branch
  populate_draft_branch()

  # calculate_scores
  res = try(calculate_scores())
  # if problem calculating, log problem and move on to next subcountry key
  txt_calc_error = sprintf('%s/%s_calc-scores.txt', dir_errors, key)
  unlink(txt_calc_error)
  if (class(res)=='try-error'){
    cat(as.character(traceback(res)), file=txt_calc_error)
    next
  }

  # create flower plot and table
  create_results()
  
  # push draft branch
  push_branch('draft')
  
  # publish draft branch
  push_branch('published')
  
  # p
  create_pages()
  
# switch to dev branch
#system('git checkout -b dev')
#system('git pushd -u origin dev')


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

# check app manually
#launch_app()



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