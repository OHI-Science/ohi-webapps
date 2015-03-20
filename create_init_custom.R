devtools::install_github('ohi-science/ohicore@dev')
library(stringr)
library(tools)
library(git2r)     # devtools::install_github('ropensci/git2r')
library(dplyr)
library(shiny)
library(shinyapps) # devtools::install_github('rstudio/shinyapps')
library(stringr)
library(jsonlite)
library(brew)
library(yaml)
merge <- base::merge # override git2r::merge
tags  <- shiny::tags # override git2r::tags, otherwise get "Error in tags$head : object of type 'closure' is not subsettable"
select <- dplyr::select

#
setwd('~/github/ohi-webapps') # setwd('~/github/clip-n-ship/alb')

# vars
# get paths based on host machine
dir_neptune <- c(
  'Windows' = '//neptune.nceas.ucsb.edu/data_edit',
  'Darwin'  = '/Volumes/data_edit',
  'Linux'   = '/var/data/ohi')[[ Sys.info()[['sysname']] ]]

dir_github  <- '~/github'

dir_annex   <- sprintf('%s/git-annex/clip-n-ship', dir_neptune) # 'N:/git-annex/clip-n-ship/data'
dir_repos   <- sprintf('%s/clip-n-ship', dir_github)
dir_errors  <- sprintf('%s/ohi-webapps/errors', dir_github)
dir_ohicore <- sprintf('%s/ohicore', dir_github)
dir_global  <- sprintf('%s/ohi-global/eez2014', dir_github)
csv_mcntry  <- sprintf('%s/ohi-webapps/tmp/gl-rgn_multiple-cntry_sc-rgn_manual.csv', dir_github)
csv_gl_rgn  <- sprintf('%s/ohiprep/Global/NCEAS-Regions_v2014/manual_output/sp_rgn_manual.csv', dir_github) # for rgn_key
csv_custom  <- sprintf('%s/ohi-webapps/tmp/gl_rgn_custom.csv', dir_github)
sfx_global  <- 'gl2014'
dw_year     <- 2014
git_branch  <- 'master'
tabs_hide   <- c('Calculate','Report') # , Compare'
commit_msg  <- "downweighted layers based on popn-inland25km, area-offshore"
redo_layers <- T
redo_app    <- T
fxn_swap    <- c(
  'LIV_ECO' = file.path(dir_github, 'ohi-webapps/functions/functions_LIV_ECO.R'),
  'LE'      = file.path(dir_github, 'ohi-webapps/functions/functions_LE.R'))
goal_swap   <- list(
  'LIV' = list(preindex_function="LIV_ECO(layers, subgoal='LIV')"),
  'ECO' = list(preindex_function="LIV_ECO(layers, subgoal='ECO')"))
travis_draft_yaml_brew <- sprintf('%s/ohi-webapps/travis_draft.brew.yml', dir_github)
travis_pages_yaml_brew <- sprintf('%s/ohi-webapps/travis_gh-pages.brew.yml', dir_github)  # I don't see this

# load ohicore
library(ohicore) # devtools::load_all(dir_ohicore)

# read global layers, add clip_n_ship columns from Google version
lyrs_gl     <- read.csv(file.path(dir_global, 'layers.csv'), stringsAsFactors = F)
lyrs_google <- read.csv(file.path(dir_global, 'temp/layers_0-google.csv'), stringsAsFactors = F)
lyrs_gl <- lyrs_gl %>%
  left_join(
    lyrs_google %>%
      select(layer, starts_with('clip_n_ship')),
    by='layer')

# read in github token outside of repo, generated via https://help.github.com/articles/creating-an-access-token-for-command-line-use
gh_token <- scan('~/.github-token', 'character', quiet = T)
Sys.setenv(GH_TOKEN=gh_token)

# lookups
gl_cntries <- read.csv(sprintf('%s/layers/cntry_rgn.csv', dir_global)) %>%
  select(
    gl_cntry_key = cntry_key, 
    gl_rgn_id    = rgn_id) %>%
  arrange(gl_cntry_key)

gl_rgns <- read.csv(csv_gl_rgn, stringsAsFactors=F) %>%
  distinct(rgn_id, rgn_name, rgn_key) %>%
  filter(rgn_type == 'eez') %>%
  select(
    gl_rgn_id   = rgn_id,
    gl_rgn_name = rgn_name,
    gl_rgn_key  = rgn_key) %>%
  arrange(gl_rgn_key, gl_rgn_name)
stopifnot(count(gl_rgns, gl_rgn_key) %>% filter(n > 1) %>% nrow == 0)

cu_rgns = read.csv(csv_custom, stringsAsFactors=F) %>% # custom regions
  left_join(gl_rgns, 
            by='gl_rgn_key') 

# get list of subcountry study areas with prepped data
# set lowercase global country ISO [gl_rgn_key] as study area key [sc_key]
sc_annex_dirs <- list.dirs(dir_annex, full.names=F, recursive=F)
sc_studies = read.csv('tmp/sc_studies_custom.csv')          # March 16: this is now a .csv file called ohi-webapps/tmp/sc_studies_custom.csv

stopifnot(count(sc_studies, sc_key) %>% filter(n > 1) %>% nrow == 0)
