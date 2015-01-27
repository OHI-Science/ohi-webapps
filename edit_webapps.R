# set vars and get functions
setwd('~/github/ohi-webapps')
source('create_init.R')
source('create_functions.R')

# update About page
keys = sc_studies %>% filter(!is.na(sc_annex_dir)) %>% select(sc_key)
keys = keys[,1]
sapply(keys, update_website, 'update About using ohi-webapps/create_functions.R - update_website()')
# done 2015-01-23 by bbest, jules32

# TODO: fix update_draft function to copy functions.R and update layers.csv descriptions.
#sapply(keys, update_draft, 'update About using ohi-webapps/create_functions.R - update_draft()') 
