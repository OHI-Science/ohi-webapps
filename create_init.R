library(stringr)
library(git2r)
library(dplyr)
library(rgdal)
library(shiny)
library(shinyapps)
library(stringr)
library(jsonlite)
library(brew)
merge <- base::merge # override git2r::merge
tags  <- shiny::tags # override git2r::tags, otherwise get "Error in tags$head : object of type 'closure' is not subsettable"

# vars
# get paths based on host machine
dir_neptune <- '/Volumes/data_edit'
dir_github  <- '~/github'

dir_annex   <- sprintf('%s/git-annex/clip-n-ship', dir_neptune) # 'N:/git-annex/clip-n-ship/data'
dir_repos   <- sprintf('%s/clip-n-ship', dir_github)
dir_ohicore <- sprintf('%s/ohicore', dir_github)
dir_global  <- sprintf('%s/ohi-global/eez2014', dir_github)
csv_mcntry  <- sprintf('%s/ohi-webapps/tmp/gl-rgn_multiple-cntry_sc-rgn_manual.csv', dir_github)
csv_gl_rgn  <- sprintf('%s/ohiprep/Global/NCEAS-Regions_v2014/manual_output/sp_rgn_manual.csv', dir_github) # for rgn_key
sfx_global  <- 'gl2014'
dw_year     <- 2014
git_branch  <- 'master'
tabs_hide   <- 'Calculate, Report' # , Compare'
commit_msg  <- "downweighted layers based on popn-inland25km, area-offshore, area-offshore3nm"
redo_layers <- T
redo_app    <- T
sc_names_existing_repos <- c('Canada','China','Fiji','Israel') # for avoiding renaming
fxn_swap    <- c(
  'LIV_ECO' = file.path(dir_github, 'ohi-webapps/functions/functions_LIV_ECO.R'),
  'LE'      = file.path(dir_github, 'ohi-webapps/functions/functions_LE.R'))
goal_swap   <- list(
  'LIV' = list(preindex_function="LIV_ECO(layers, subgoal='LIV')"),
  'ECO' = list(preindex_function="LIV_ECO(layers, subgoal='ECO')"))

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

# lookups
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
sc_studies = filter(sc_studies, !is.na(gl_rgn_key))
stopifnot(count(sc_studies, sc_key) %>% filter(n > 1) %>% nrow == 0)