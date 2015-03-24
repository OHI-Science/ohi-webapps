# set vars and get functions
setwd('~/github/ohi-webapps')
source('create_init.R')
source('create_functions.R')

# update About page
# first, make any changes you want to the files in gh-pages; ex: ohi-webapps/gh-pages/about/index.md
# keys = sc_studies %>% filter(!is.na(sc_annex_dir)) %>% select(sc_key)
# keys = keys[,1]
# sapply(keys, update_website, 'update About using ohi-webapps/create_functions.R - update_website()')
# done 2015-01-23 by bbest, jules32

# TODO: fix update_draft function to copy functions.R and update layers.csv descriptions.
#sapply(keys, update_draft, 'update About using ohi-webapps/create_functions.R - update_draft()') 

# Move Apps to NCEAS server
# change app_url to https://ohi-science.nceas.ucsb.edu/ (from https://ohi-science.shinyapps.io) in: 
#   1. ohi-webapps/gh-pages/_config.brew.yml
#   2. ohi-webapps/app.brew.yml
keys = sc_studies %>% filter(!is.na(sc_annex_dir)) %>% select(sc_key)
keys = keys[,1] # keys = 'blz'
# keys = keys[1:3]
sapply(keys, deploy_app_nceas)
sapply(keys, update_website,   'move Shiny App onto NCEAS server - update_website()')
