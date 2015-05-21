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

# 2015-May: Update .travis.yml with env:global:secure variable w/ encrypted string that sets GH_TOKEN ----
# with @bbest. and rerun additions_draft because errant extra `ohicore::`.
# keys = 'blz' bad example because this one had an error in functions.r. 
# keys = 'nld' # failing
keys = sc_studies %>% filter(!is.na(sc_annex_dir)) %>% select(sc_key) %>% 
  filter(!sc_key %in% c('gye', 'bhi', 'chn', 'aia', 'tto', 'asm', 'civ'))

# read in csv of keys that originally were passing; now aren't. 
# filter(pass_orig==T & pass_now==F)
keys_2014_11 = readr::read_csv('http://raw.githubusercontent.com/OHI-Science/subcountry/1982aff6d13e172fc880db38a4122bc74c73735b/_data/status.csv')

keys = keys[11:100,1] # keys = keys[1:10,1]
# sapply(keys, additions_draft, msg='update travis.yml + additions, ohi-webapps/create_functions.R - additions_draft()')
# sapply(keys, update_website, msg='update _config.yml branch_scenario, ohi-webapps/create_functions.R - update_website()')
sapply(keys, fix_travis_yml)
sapply(keys, deploy_app_nceas)
#khm rsync error

## 2015-May-20: Create `webapp_yml_secure_recip.csv`, a list of which repos have secure/recipient problems:

csv_status=file.path(dir_github, 'ohi-webapps/tmp/webapp_yml_secure_recip.csv')
for (dir in list.dirs(dir_repos, recursive=F)){ # dir = '/Users/jstewart/github/clip-n-ship/cog'
 
  key = str_split_fixed(dir, '/', 6)[6]
  key <<- key
  source(file.path(dir_github, 'ohi-webapps/create_init_sc.R'))
  
  # switch to draft branch and get latest
  system('git checkout draft; git pull')
  
  yml = file.path(dir, '.travis.yml')
  
  if ( file.exists(yml) ){
    y = yaml.load_file(yml)
  
    # check #1: has secure var?
    secure = 'secure' %in% names(unlist(y$env$global))
    
    # check #2: has lowndes as a recipient # TODO: switch to ohi-science@nceas.ucsb.edu?
    recip = 'lowndes@nceas.ucsb.edu' %in% unlist(y$notifications$email$recipients)
    
    # add to csv_status log
    read.csv(csv_status, stringsAsFactors=F, na.strings='') %>%
      filter(sc_key != key) %>%
      rbind(
        data.frame(
          sc_key = key,
          travis_secure = secure,
          travis_recip  = recip,
          travis_status = '',
          date_checked  = as.character(Sys.time()))) %>%
      write.csv(csv_status, row.names=F, na='')    
  }
}
