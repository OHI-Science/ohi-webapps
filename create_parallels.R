library(parallel)

# set vars and get functions
setwd('~/github/ohi-webapps')
source('create_init.R')
source('create_functions.R')
source('ohi-travis-functions.R')

log     = file.path(dir_github, 'ohi-webapps/tmp/create_parallels_log.txt')
results = file.path(dir_github, 'ohi-webapps/tmp/create_parallels_results.Rdata')
cat('', file=log)

create_all = function(key, redo_maps=F){ # key='are'
  
  cat(sprintf('INIT %s [%s]\n', key, Sys.time()), file=log, append=T)
  key <<- key
  
  # set vars by subcountry key
  setwd(dir_repos)
  source(sprintf('%s/ohi-webapps/create_init_sc.R', dir_github))

  # create github repo
  #create_gh_repo(key)
  
  # create maps
  txt_map_error = sprintf('%s/%s_map.txt', dir_errors, key)
  unlink(txt_map_error)  
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
  
#   # turn on Travis [NOT NEPTUNE]
#   setwd(dir_repo)
#   system('git checkout draft')
#   system(sprintf('travis encrypt -r %s GH_TOKEN=%s --add env.global', git_slug, gh_token))
#   system(sprintf('travis enable -r %s', git_slug))
#   system('git commit -am "enabled travis.yml with encrypted github token"; git pull; git push')
  
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
  
}

# # get rgns with spatial data not yet run
# system('cd ~/github/subcountry; git pull')
# sc_todo = subset(
#   read.csv('~/github/subcountry/_data/status.csv', na.strings='', stringsAsFactors=F),
#   is.na(status),
#   repo, drop=T)
# sc_annex = list.dirs(file.path(dir_neptune, 'git-annex/clip-n-ship'), recursive=F, full.names=F)
# sc_run   = intersect(sc_todo, sc_annex)

# get keys without a build passing status
just_passed = c('ago','abw','com','cok','irq','irl','grl','fji','ken','kna')
read.csv(file.path(dir_github, 'ohi-webapps/tmp/webapp_travis_status.csv')) %>%
#  select(travis_status) %>% table()
# 2014-11-28
#                            enabled                            errored                             failed no build yet & missing .travis.yml                             passed 
#                                 64                                 14                                 20                                  3                                 81 
#               repository not known 
#                                  5
  filter(travis_status != 'passed' & !sc_key %in% just_passed) %>%
  subset(select=sc_key, drop=T) %>% as.character() -> sc_run


# redo after fix buffers from readOGR fails
#sc_run = c('can','chn','fin','fji','fro','grl','idn','ind','irl','irn','irq','isl','ita','jpn','kna','lca','lka','mmr','mne','nld','nzl','rus','sau','sdn','sen','shn','slb','sle','som','spm','stp','sur','svn','syr')

# loop through countries on max detected cores - 1
# debug with lapply: 
#lapply(cntries, make_sc_coastpop_lyr, redo=T)  
cat(sprintf('\n\nlog starting for parallell::mclapply (%s)\n\n', Sys.time()), file=log)
res = mclapply(sc_run, create_all, mc.cores = detectCores() - 3, mc.preschedule=F)
save(res, file=results)

# load('~/github/ohi-webapps/tmp/create_parallels_results.Rdata', verbose=T)

# to kill processes from terminal
# after running from https://neptune.nceas.ucsb.edu/rstudio/:
#   kill $(ps -U bbest | grep rsession | awk '{print $1}')
# after running from terminal: Rscript ~/github/ohi-webapps/create_parallels.R &
#   kill $(ps -U bbest | grep R | awk '{print $1}')
# tracking progress:
#   log=/var/data/ohi/git-annex/clip-n-ship/make_sc_coastpop_lyr_log.txt; cat $log
# see: https://github.com/OHI-Science/ohi-webapps/blob/master/process_rasters.R#L113
#      https://github.com/OHI-Science/issues/issues/269#issuecomment-61531150
