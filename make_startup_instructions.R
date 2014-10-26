# make_startup_instructions.r

# snippets that will eventually be inserted into ohi-webapps/create_all.r when looping through countries. Bits from create_all.r have been stolen from here as a proof of concept


## setup from create_all.r ----
library(stringr)
library(git2r)
library(dplyr)
library(rgdal)
library(shiny)
library(shinyapps)
library(stringr)
merge = base::merge # override git2r::merge
tags  = shiny::tags # override git2r::tags, otherwise get "Error in tags$head : object of type 'closure' is not subsettable"

# vars
# get paths based on host machine
dirs = list(
  neptune_data  = '/Volumes/data_edit', 
  github        = '~/github')

dir_data    = sprintf('%s/git-annex/clip-n-ship', dirs['neptune_data']) # 'N:/git-annex/clip-n-ship/data'
dir_repos   = sprintf('%s/clip-n-ship', dirs['github'])

# get list of countries with prepped data
cntries = list.files(dir_data)

# loop through countries
for (i in 1:length(cntries)){ # i=1
    
  # setup vars
  Country   = str_replace_all(cntries[i], '_', ' ')
  cntry     = tolower(cntries[i])
  repo_name = sprintf('ohi-%s', cntry)
  git_url  = sprintf('https://github.com/OHI-Science/%s', repo_name)
  dir_repo  = file.path(dir_repos, repo_name)
  dir_app   = file.path(dir_data, cntries[i], 'shinyapps.io')
  app_name  = cntry
  cat(sprintf('\n\n\n\n%03d of %d: %s -- %s\n', i, length(cntries), Country, format(Sys.time(), '%X')))
  
  ## new content JSL to be placed AFTER THE rgn_new VARIABLE:::: ----
  
  # copy template file and overwrite the copy
  
  f = 'startup_instructions_tmp.rmd' 
  stopifnot(file.copy('startup_instructions.rmd', file.path(f), overwrite=T))
  
  s = readLines(f, warn=F, encoding='UTF-8')
  s = str_replace_all(s, fixed('!repo'), fixed(repo_name)) 
  s = str_replace_all(s, fixed('!study_area'), fixed(Country)) 
  s = str_replace_all(s, fixed('!x'), fixed(dim(rgn_new)[1])) 
  
  writeLines(s, f)  # TODO: save this as 'README.md'? Or 'sprintf('startup_', repo_name)?
}
  
  
  
  

