# set vars and get functions
setwd('~/github/ohi-webapps')
source('create_init.R')
source('create_functions.R')

# 2015-Jan, 2015-May: Uupdate WebApps (gh-pages) by bbest, jules32 ----
# first, make any changes you want to the files in gh-pages; ex: ohi-webapps/gh-pages/about/index.md
# keys = sc_studies %>% filter(!is.na(sc_annex_dir)) %>% select(sc_key)
# keys = keys[,1]
# sapply(keys, update_website, 'update About using ohi-webapps/create_functions.R - update_website()')

# TODO: fix update_draft function to copy functions.R and update layers.csv descriptions.
#sapply(keys, update_draft, 'update About using ohi-webapps/create_functions.R - update_draft()') 

# 2015-March: Move Apps to NCEAS server ----
# change app_url to https://ohi-science.nceas.ucsb.edu/ (from https://ohi-science.shinyapps.io) in: 
#   1. ohi-webapps/gh-pages/_config.brew.yml
#   2. ohi-webapps/app.brew.yml
keys = sc_studies %>% filter(!is.na(sc_annex_dir)) %>% select(sc_key)
keys = keys[,1] # keys = 'blz'
# keys = keys[1:3]
# sapply(keys, deploy_app_nceas)
# sapply(keys, update_website,   'move Shiny App onto NCEAS server - update_website()')
# sapply(keys[1:3], revert_website, '2015-03-23 08:00:00') # done 2015-03-24 by bbest, jules32
sapply(keys, deploy_app_nceas)
# restart R and run above before line below
sapply(keys, update_website,   'move Shiny App onto NCEAS server - update_website()')

# fixing GYE 2015-03-25 ----
revert_website('gye', '2015-03-23 08:00:00')
update_website('gye', 'move Shiny App onto NCEAS server - update_website()')
deploy_app_nceas('gye', nceas_user='bbest')

# created ohi-global ----
key = 'ohi-global'
update_website(key, msg='update _config.yml branch_scenario, ohi-webapps/create_functions.R - update_website()')
deploy_app_nceas(key)

# 2015-May: Updates to app branch; additions to draft branch ----
keys = sc_studies %>% filter(!is.na(sc_annex_dir)) %>% select(sc_key) %>% 
  filter(!sc_key %in% c('gye', 'bhi', 'chn', 'aia', 'tto', 'asm', 'civ'))
keys = keys[,1] # keys = keys[1:10,1]
sapply(keys, additions_draft, msg='update travis.yml + additions, ohi-webapps/create_functions.R - additions_draft()')
sapply(keys, update_website, msg='update _config.yml branch_scenario, ohi-webapps/create_functions.R - update_website()')
# `jstewart@fitz:/srv/shiny-server$ sudo service shiny-server restart` restart fitz server in terminal
sapply(keys, deploy_app_nceas)

# update .travis.yml with env:global:secure variable with encrypted string that sets GH_TOKEN
status_travis('cog')

# quick code to iterate over repos. prob better as standalone function with repo as input arg so goes in create_functions as fix_yaml() or some such
# TODO: record in data.frame or fix inline...
for (dir in list.dirs(dir_repos, recursive=F)){ # dir = '/Users/jstewart/github/clip-n-ship/cog'
  yml = file.path(dir, '.travis.yml')
  # TODO: checkout right branch
  if (file.exists(yml)){
    y = yaml.load_file(yml)
    
    # check #1: has secure var?
    if ('secure' %in% names(unlist(y$env$global))){
      # TODO: record that has secure var
    } else {
      # TODO: record that repo does NOT have secure var so that you can run status_travis
    }
  
    # check #2: has lowndes as a recipient
    # TODO: switch to ohi-science@nceas.ucsb.edu?
    if ('lowndes' %in% names(unlist(y$notifications$email$recipients))){
      # TODO: record that has lowndes already a recipient
    } else {
      # TODO: record that lowndes not already a recipient, so rebrew yaml and run status_travis        
    }
  }
}