# create_init_sc.R
# by @bbest. # load all variables, set directories specific to individual key

stopifnot(exists('key'))
i             = which(repo_registry$key==key)
sc            = repo_registry[i,]
name          = sc$study_area
study_area    = name
# name_gl_rgn       = sc$sc_key_old TO DELETE
name_gl_rgn_cap   = sc$gl_rgn_name
gl_rgn_id         = sc$gl_rgn_id
# repo_name     = key
git_owner     = 'OHI-Science'
git_repo      = key
git_slug      = sprintf('%s/%s', git_owner, git_repo)
git_url       = sprintf('https://github.com/%s', git_slug)
pages_url     = sprintf('http://ohi-science.org/%s', git_repo)
dir_repo      = file.path(dir_sandbox, repo_name)
if (key %in% repo_registry$key){
  default_scenario = subset(repo_registry, key==key, default_scenario, drop=T)
} else {
  message('Please enter a scenario name in `custom/sc_studies_custom.csv`/n') # no longer default to 'subcountry2014'
}

dir_scenario <- file.path(dir_repo, default_scenario)
dir_spatial <- file.path(dir_annex, key, 'spatial')

# set custom default_scenario
if (key == 'chn') default_scenario = 'province2015'

# set default branch # TODO sort out branches
default_branch          = 'published'
default_branch_scenario = sprintf('%s/%s', default_branch, default_scenario)

#  dir_ap_old    = file.path(dir_annex, cntries[i], 'shinyapps.io')
dir_annex_sc  = file.path(dir_annex, key)
app_name      = key # sprintf('%s_app', key)
csv_pop_inland25km = file.path(dir_M, 'git-annex/clip-n-ship', key, 'layers/mar_coastalpopn_inland25km_lyr.csv') # TODO: sort out mar_pop_inland stuff

study_area = subset(repo_registry, key==key, study_area, drop=T)

#message(sprintf('\n%03d of %d: %s [%s] -- %s', i, nrow(repo_registry), name, key, format(Sys.time(), '%X')))    
stopifnot(!is.na(key))


if (!file.exists(csv_pop_inland25km)){
  #cat('  mar_coastalpopn_inland25km_lyr.csv NOT PRESENT, skipping!\n')
  #next
} else if (!'year' %in% names(read.csv(csv_pop_inland25km))){
  cat('  mar_coastalpopn_inland25km_lyr.csv WITHOUT YEAR, skipping!\n')
  #next
} 

