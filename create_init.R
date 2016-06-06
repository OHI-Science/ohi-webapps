# create_init.R
# by @bbest. load all libraries, set directories relevant to all keys

# devtools::install_github('ohi-science/ohicore@dev')
library(stringr)
library(git2r)     # install.packages('git2r')
library(dplyr)
library(tidyr)
library(readr)
library(rgdal)
library(stringr)
library(jsonlite)
library(brew)
library(yaml)
merge <- base::merge # override git2r::merge
tags  <- shiny::tags # override git2r::tags, otherwise get "Error in tags$head : object of type 'closure' is not subsettable"
select <- dplyr::select

# set working dir
setwd('~/github/ohi-webapps') # setwd('~/github/clip-n-ship/alb')

# vars
# get paths based on host machine
dir_M <- c('Windows' = '//mazu.nceas.ucsb.edu/ohi',
           'Darwin'  = '/Volumes/ohi',    ### connect (cmd-K) to smb://mazu/ohi
           'Linux'   = '/home/shares/ohi')[[ Sys.info()[['sysname']] ]]

# set username for copying app files onto fitz.nceas
nceas_user = c('bbest'='bbest','julialowndes'='jstewart','jstewart'='jstewart')[Sys.info()["user"]]


dir_github  <- '~/github'

dir_annex   <- sprintf('%s/git-annex/clip-n-ship', dir_M) 
dir_repos   <- sprintf('%s/clip-n-ship', dir_github)
dir_errors  <- sprintf('%s/ohi-webapps/errors', dir_github)
dir_ohicore <- sprintf('%s/ohicore', dir_github)
dir_global  <- sprintf('%s/ohi-global/eez2016', dir_github) # TODO: could isolate scenario
csv_mcntry  <- sprintf('%s/ohi-webapps/tmp/gl-rgn_multiple-cntry_sc-rgn_manual.csv', dir_github) # TODO DELETE
csv_gl_rgn  <- sprintf('%s/ohiprep/Global/NCEAS-Regions_v2014/manual_output/sp_rgn_manual.csv', dir_github) # for rgn_key 
sfx_global  <- 'gl2016'
dw_year     <- 2014 # downweight year for mar_coastalpopn_inland25km_lyr on Mazu
git_branch  <- 'master'
tabs_hide   <- c('Calculate','Report') # , Compare'
## commit_msg  <- "downweighted layers based on popn-inland25km, area-offshore, area-offshore3nm" # TODODELETE if tested
redo_layers <- T
redo_app    <- T
# sc_names_existing_repos <- c('Canada','China','Fiji','Israel') # for avoiding renaming # TODODELETE if tested
fxn_swap    <- c(
  'LIV_ECO' = file.path(dir_github, 'ohi-webapps/functions/functions_LIV_ECO.R'),
  'LE'      = file.path(dir_github, 'ohi-webapps/functions/functions_LE.R'))
goal_swap   <- list(
  'LIV' = list(preindex_function="LIV_ECO(layers, subgoal='LIV')"),
  'ECO' = list(preindex_function="LIV_ECO(layers, subgoal='ECO')"))
# travis_draft_yaml_brew <- sprintf('%s/ohi-webapps/travis_draft.brew.yml', dir_github) # TODODELETE if tested
# travis_pages_yaml_brew <- sprintf('%s/ohi-webapps/travis_gh-pages.brew.yml', dir_github) # TODODELETE if tested

# load ohicore
library(ohicore) # devtools::install_github('ohi-science/ohicore@dev')

# read global layers, add clip_n_ship columns from Master layers doc (originally layers_global on Google docs)
lyrs_gl     <- read.csv(file.path(dir_global, 'layers.csv'), stringsAsFactors = F)
lyrs_google <- read.csv(file.path('~/github/ohi-global', 'layers_eez.csv'), stringsAsFactors = F)
lyrs_gl <- lyrs_gl %>%
  left_join(
    lyrs_google %>%
      select(layer, starts_with('clip_n_ship')),
    by='layer')

# read in github token outside of repo, generated via https://help.github.com/articles/creating-an-access-token-for-command-line-use
gh_token <- scan('~/.github-token', 'character', quiet = T)
Sys.setenv(GH_TOKEN=gh_token)

##lookups ## TODODELETE if tested
gl_sc_mcntry <- read.csv(csv_mcntry)

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
# lumpers repeat:
# - Guadeloupe [GLP] and Martinique [MTQ -> [ZGM]
# - Puerto Rico [PRI] and Virgin Islands of the United States [VIR] -> [ZPV]
# 
# get list of subcountry study areas with prepped data
# set lowercase global country ISO [gl_rgn_key] as study area key [sc_key]
sc_annex_dirs <- list.dirs(dir_annex, full.names=F, recursive=F)
sc_studies <- gl_rgns %>%
  mutate(
    sc_key  = tolower(gl_rgn_key),
    sc_name = gl_rgn_name)  %>%
  left_join(
    data.frame(
      sc_key       = sc_annex_dirs,
      sc_annex_dir = file.path(dir_annex, sc_annex_dirs)),
    by = 'sc_key') %>%
  mutate(
    sc_key_old = tolower(str_replace_all(sc_name, ' ', '_')),
    sc_key     = tolower(gl_rgn_key)) %>%
  select(sc_key, sc_name, sc_key_old, gl_rgn_id, gl_rgn_name, gl_rgn_key, sc_annex_dir) %>%
  arrange(sc_key)

# read in custom sc studies
sc_custom = read.csv('custom/sc_studies_custom.csv', stringsAsFactors=F)
sc_studies = sc_studies %>%
  anti_join(sc_custom, by = c('sc_key', 'sc_name', 'gl_rgn_id')) %>%  # removes original chn, col
    rbind(                                                            # rbinds custom chn, col
  sc_custom[, names(sc_studies)])
stopifnot(count(sc_studies, sc_key) %>% filter(n > 1) %>% nrow == 0)

# report on subcountries without annex data dirs
if (nrow(filter(sc_studies, is.na(sc_annex_dir))) > 0){
  message(
    sprintf(
      'Looking for prepped data folders by subcountry key (lowercase gl_rgn_key):\n    %s\n  The following global regions were not found:\n    %s',
      dir_annex, paste(with(filter(sc_studies, is.na(sc_annex_dir)), sprintf('%s (%s)', gl_rgn_name, sc_key)), collapse = '\n    ')))
}

write.csv(
  sc_studies %>%
    filter(is.na(sc_annex_dir)) %>%
    select(gl_rgn_id, gl_rgn_name, sc_key) %>%
    arrange(gl_rgn_name), 'tmp/gl-rgns_no-sc-annex-data.csv', row.names=F, na='')
#sc_studies = filter(sc_studies, !is.na(gl_rgn_key))
stopifnot(count(sc_studies, sc_key) %>% filter(n > 1) %>% nrow == 0)
