# common.r; common information to use

## NOTE: moved all but these to ohirepos, do we need them? 
library(rgdal)
library(jsonlite)

# merge <- base::merge # override git2r::merge
# select <- dplyr::select

# # set working dir
# setwd('~/github/ohi-webapps') 

# vars
# get paths based on host machine
dir_M <- c('Windows' = '//mazu.nceas.ucsb.edu/ohi',
           'Darwin'  = '/Volumes/ohi',    ### connect (cmd-K) to smb://mazu/ohi
           'Linux'   = '/home/shares/ohi')[[ Sys.info()[['sysname']] ]]

# set username for copying app files onto fitz.nceas
nceas_user  <- c('bbest'='bbest','julialowndes'='jstewart','jstewart'='jstewart')[Sys.info()["user"]]
github_user <- c('bbest'='bbest','julialowndes'='jules32')[Sys.info()["user"]]

# dir_annex   <- sprintf('%s/git-annex/clip-n-ship', dir_M) 
dir_sandbox <- '~/github/clip-n-ship'
dir_origin  <- '~/github/ohi-global/eez2016'

# dw_year     <- 2014 # downweight year for mar_coastalpopn_inland25km_lyr on Mazu # TODO DELETE?
git_branch  <- 'master'

fxn_swap    <- c(
  'LIV_ECO' = file.path(dir_github, 'ohi-webapps/functions/functions_LIV_ECO.R'),
  'LE'      = file.path(dir_github, 'ohi-webapps/functions/functions_LE.R'), 
  'ICO'     = file.path(dir_github, 'ohi-webapps/functions/functions_ICO.R'))
goal_swap   <- list(
  'LIV' = list(preindex_function="LIV_ECO(layers, subgoal='LIV')"),
  'ECO' = list(preindex_function="LIV_ECO(layers, subgoal='ECO')"))


# read global layers, add clip_n_ship columns from Master layers doc (originally layers_global on Google docs)
lyrs_gl     <- read.csv(file.path(dir_global, 'layers.csv'), stringsAsFactors = F)
# lyrs_google <- read.csv(file.path('~/github/ohi-global', 'layers_eez.csv'), stringsAsFactors = F)
# lyrs_gl <- lyrs_gl %>%
#   left_join(
#     lyrs_google # %>% select(layer, starts_with('clip_n_ship'))
#     , by='layer')

# read in github token outside of repo, generated via https://help.github.com/articles/creating-an-access-token-for-command-line-use
gh_token <- scan('~/.github-token', 'character', quiet = T)
Sys.setenv(GH_TOKEN=gh_token)

gl_cntries <- read.csv(sprintf('%s/layers/cntry_rgn.csv', dir_global)) %>%
  select(
    gl_cntry_key = cntry_key,
    gl_rgn_id    = rgn_id) %>%
  arrange(gl_cntry_key)

csv_gl_rgn  <- 'sp_rgn_manual_v2014.csv' # for rgn_key # TODO JSL see if this is necessary Dec 2016
gl_rgns <- read.csv(csv_gl_rgn, stringsAsFactors=F) %>%
  dplyr::distinct(rgn_id, rgn_name, rgn_key, .keep_all = TRUE) %>%
  filter(rgn_type == 'eez') %>%
  select(
    gl_rgn_id   = rgn_id,
    gl_rgn_name = rgn_name,
    gl_rgn_key  = rgn_key) %>%
  arrange(gl_rgn_key, gl_rgn_name)
stopifnot(count(gl_rgns, gl_rgn_key) %>% filter(n > 1) %>% nrow == 0)

# read in repo_registry
repo_registry = readr::read_csv('repo_registry.csv')
