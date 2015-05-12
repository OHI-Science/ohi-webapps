# set vars and get functions
setwd('~/github/ohi-webapps')
source('create_init.R')
source('create_functions.R')

# update About page 2015-01-23 by bbest, jules32 ----
# first, make any changes you want to the files in gh-pages; ex: ohi-webapps/gh-pages/about/index.md
# keys = sc_studies %>% filter(!is.na(sc_annex_dir)) %>% select(sc_key)
# keys = keys[,1]
# sapply(keys, update_website, 'update About using ohi-webapps/create_functions.R - update_website()')

# TODO: fix update_draft function to copy functions.R and update layers.csv descriptions.
#sapply(keys, update_draft, 'update About using ohi-webapps/create_functions.R - update_draft()') 

# Move Apps to NCEAS server ----
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
deploy_app_nceas(key='ohi-global')

# update travis 2015-04-23 by bbest, jules32 ----
# 2 steps: 1) run update_travis_yml. 2) run deploy_app_nceas on key = 'abw'. Done 2015-04-23. 
# 2) run deploy_app_nceas on all keys. Not yet done ...
keys = sc_studies %>% filter(!is.na(sc_annex_dir)) %>% select(sc_key)
keys = keys[,1]
# update .travis.yml 
sapply(keys, update_travis_yml, 'update travis.yml ohi-webapps/create_functions.R - update_travis_yml()')
sapply(keys, deploy_app_nceas)

# update_travis_yml(key='gye', msg='update travis.yml ohi-webapps/create_functions.R - update_travis_yml()')
# deploy_app_nceas(key='gye')
# additions_draft(key='tto') # ultimately fold update_travis_yml() action into additions_draft() 
# since all operations can happen together and there will be fewer functions


