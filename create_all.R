## create_all.R. 
## by @bbest on @master branch. See original notes at the bottom or @bbest's last commit, 9c7a3f152. 
## updated by @jules32 a lot here on @dev branch. Source this from create_custom.r (TBCreated). And make all of this repo a package. 

## edit_webapps.rmd is now a companion script for updating existing repos.

## summary ----
## This script will create repos and webapps for each 'key', which is the 
## 3-letter code (there are exceptions) for each study/assessment area. 
## Here we just make custom repos/webapps without travis-ci; 
## see @master branch for how we made
## ~200 repos for global eez with gadm regions and travis-ci

## setup ----

setwd('~/github/ohi-webapps')

source('create_init.R')            # load all libraries, set directories relevant to all keys
source('create_functions.R')       # all functions for creating and updating repos and webapps
source('R/copy_layer.r')

## make a custom repo for a specific  ----
# this is in order of steps from start to finish, but these functions can also be run individually

create_new_repo = F
redo_maps = F

key = 'arc'; multi_nation = T # figure out somewhere else to put this

# set vars by subcountry key
setwd(dir_repos)
source(sprintf('%s/ohi-webapps/create_init_sc.R', dir_github))    

# create github repo on github.com
if (create_new_repo) repo = create_gh_repo(key)

# set working dir
setwd(dir_repo)

# create custom_maps() by @jules32
if (!all(file.exists(  
  file.path(dir_annex, key,
            'gh-pages/images',
            c('regions_1600x800.png', 'regions_600x400.png', 'regions_400x250.png',
              'app_400x250.png', 'regions_30x20.png'))))
  | redo_maps){
  res = try(custom_maps(key)) ## TODO: inspect more closely; erroring out 6/6/16 with fortify line
}


# populate draft branch of repo
populate_draft_branch()    # TODO jun 2016: see if buffers necessary, etc. 
additions_draft(key)   ## TODO june 2016: necessary anymore?

source('~/github/ohi-webapps/ohi-functions.R')          # all functions to update the webapp without Travis

# push draft branch ~ adapted from create.all
setwd(dir_repo)
push_branch('draft') # source('ohi-functions.r')
system('git pull')

# calculate scores ~~ adapted from create.all
setwd(dir_repo)
calculate_scores_notravis() # consider just calling CalculateAll() here instead of this function. Will need to add git2r info

## created ARC up to here. 
## TODO: 
# - update calculate_scores.r
# - copy 'temp/referencePoints.csv' --> change tmp/ to temp/
# - update # setwd('~/github/arc/circle2016') --> update eez2016's calculate_scores.r directly
# - conf/pressure_categories.csv
# - pre_scores.r from arc
# - use tidyr::expand() to create dummy variables: 
      # df <- data_frame(
      #   year   = c(2010, 2010, 2010, 2010, 2012, 2012, 2012),
      #   qtr    = c(   1,    2,    3,    4,    1,    2,    3),
      #   return = rnorm(7)
      # )
      # df %>% expand(year, qtr)
      # df %>% expand(year = 2010:2012, qtr)
      # df %>% expand(year = full_seq(year, 1), qtr)
      # df %>% complete(year = full_seq(year, 1), qtr)
# - consider deleting the Thailand MAR message

# functions.r errors: 
# MAR: https://github.com/OHI-Science/arc/commit/8ee59d0e14b998490e00be81ef0236ebd37ffdba
# ICO: Error in eval(expr, envir, enclos) : object 'val_chr' not found 

## layers to fix: 
# ICO: 'ico_spp_extinction_status' 


# create flower plot and table
setwd(dir_repo)
update_results() # run this one time only; afterwards let webapps generate their own figures with report.r TODO: what is this?

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
