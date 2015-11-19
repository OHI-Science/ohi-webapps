# create_init_sc.R
# by @bbest. # load all variables, set directories specific to individual key

stopifnot(exists('key'))
i             = which(sc_studies$sc_key==key)
sc            = sc_studies[i,]
name          = sc$sc_name
study_area    = name
name_gl_rgn       = sc$sc_key_old
name_gl_rgn_cap   = sc$gl_rgn_name
gl_rgn_id         = sc$gl_rgn_id
#  Country       = Countries[i](cntries[i], '_', ' ')
#  country       = tolower(str_replace_all(cntries[i], ' ', '_')
#  cntry         = tolower(as.character(subset(rgn_keys_gl, rgn_name==Country, rgn_key, drop=T)))  
#  cntry_key     = as.character(subset(rgn_keys_gl, rgn_name==Country, rgn_key, drop=T))
#  repo_name_old = sprintf('ohi-%s', country)
repo_name     = key
#  git_url_old   = sprintf('https://github.com/OHI-Science/ohi-%s', country)
git_owner     = 'OHI-Science'
git_repo      = repo_name
git_slug      = sprintf('%s/%s', git_owner, git_repo)
git_url       = sprintf('https://github.com/%s', git_slug)
pages_url     = sprintf('http://ohi-science.org/%s', git_repo)
#  dir_repo_old  = file.path(dir_repos, repo_name_old)
dir_repo      = file.path(dir_repos, repo_name)
#  scenario_old  = 'subcountry2014'
if (key %in% sc_custom$sc_key){
  default_scenario = subset(sc_custom, sc_key==key, default_scenario, drop=T)
} else {
  default_scenario = 'subcountry2014'
}

# set custom default_scenario
if (key == 'chn') default_scenario = 'province2015'

# set default branch
default_branch          = 'published'
default_branch_scenario = sprintf('%s/%s', default_branch, default_scenario)

#  dir_ap_old    = file.path(dir_annex, cntries[i], 'shinyapps.io')
dir_annex_sc  = file.path(dir_annex, key)
app_name      = key # sprintf('%s_app', key)
csv_pop_inland25km = file.path(dir_neptune, 'git-annex/clip-n-ship', key, 'layers/mar_coastalpopn_inland25km_lyr.csv')
# dir_annex_old  = str_replace_all(Country, ' ', '_')
study_area = subset(sc_studies, sc_key==key, sc_name, drop=T)

#message(sprintf('\n%03d of %d: %s [%s] -- %s', i, nrow(sc_studies), name, key, format(Sys.time(), '%X')))    
stopifnot(!is.na(key))


# TODO: get status of subcountry key ----

#   if (file.exists(file.path(dir_app, 'app_config.yaml')) & !redo_layers){
#     cat('  done, skipping!\n')
#     y$init_app[i] = T
#     y$url_github_repo[i] = git_url
#     y$url_shiny_app[i]   = sprintf('https://ohi-science.shinyapps.io/%s', app_name)
#     next    
#   }

if (!file.exists(csv_pop_inland25km)){
  #cat('  mar_coastalpopn_inland25km_lyr.csv NOT PRESENT, skipping!\n')
  #next
} else if (!'year' %in% names(read.csv(csv_pop_inland25km))){
  cat('  mar_coastalpopn_inland25km_lyr.csv WITHOUT YEAR, skipping!\n')
  #next
} 

# catalog status ----

#   # fixing calc errors
#   txt_calc_err = sprintf('%s/score_errors/%s_calc-scores.txt', dir_repos, country)
#   if (file.exists(txt_calc_err)) unlink(txt_calc_err)

# uncomment below to quickly capture table of status

# txt_country_err = sprintf('%s/score_errors/%s_cntry-key-length-gt-1.txt', dir_repos, country)
# if (file.exists(txt_country_err)){
#   cat('  multi country\n')
#   y$init_app[i] = F
#   y$status[i]   = 'cntry_key multiple'
#   next        
# }
#  
# txt_calc_err = sprintf('%s/score_errors/%s_calc-scores.txt', dir_repos, country)
# if (file.exists(txt_calc_err)){
#    cat('  calc error\n')
#    y$init_app[i] = F
#    y$status[i]   = 'calc'
#    y$error[i]    = paste(readLines(txt_calc_err), collapse='    ')
#    next    
# }   
# 
# txt_shp_err = sprintf('%s/score_errors/%s_shp_to_geojson.txt', dir_repos, country)
# if (file.exists(txt_shp_err)){
#   cat('  shp error\n')
#   y$init_app[i] = F
#   y$status[i]   = 'shp_to_geojson'
#   y$error[i]    = paste(readLines(txt_shp_err), collapse='    ')
#   next        
# }  

