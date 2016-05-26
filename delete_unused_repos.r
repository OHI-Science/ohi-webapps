## To delete unused ohi-webapps made with eez2014 data. 

## See https://github.com/OHI-Science/issues/issues/660. 
## by @bbest, @jules32, May 2016. 
# deleting because:
#   - wrong boundaries
#   - using 2014 data vs now 2015
#   - pressures/resilience out of sync
#   - people turned off b/c already looks "done"


## set gh_token for privileges (bbest, jules32)
gh_token <- scan('~/.github-token', 'character', quiet = T)


## list of repos to delete
to_keep <- c('ohi-israel', 'ohi-canada', 'ohi-global', 'ohi-fiji', 'ohi-northeast', 'ohi-uswest', 'ohi-china',
             'chn', 'gye', 
             'bhi', 'col', 'ohibc', 'cdz',  'arc', 'chl',
             'can', 'esp')

## repos_delete
r_delete <- sc_studies %>%
  filter(!sc_key %in% to_keep)

repos_delete <- sc_studies %>%
  filter(sc_key %in% c('bes', 'ben'))


# repos_delete <- c('alb', 'aia')

## loop through and delete repos
for (r in repos_delete) { # r <- "test_delete"
  
  ## delete using Github API: https://developer.github.com/v3/repos/#create
  cmd = sprintf('curl -X DELETE -H "Authorization: token %s" https://api.github.com/repos/ohi-science/%s', gh_token, r)
  system(cmd, intern=T)
} 

## update status.csv that displays on ohi-science.org/subcountry
## modified from https://github.com/OHI-Science/ohi-webapps/blob/b9e12ffd304018680f5dd693b9cd328a523a440c/ohi-functions.r#L370-L399

# update status log: documentation ----

# get status repo  depth of 1 only
if (file.exists('~/tmp/subcountry')){
  system('cd ~/tmp/subcountry; git pull')
} else {
  dir.create(dirname('tmp'), showWarnings=F, recursive=T)
  system('git clone --depth=1 https://github.com/OHI-Science/subcountry ~/tmp/subcountry')
}
csv_status = '~/tmp/subcountry/_data/status.csv'
d = read.csv(csv_status, stringsAsFactors=F)

# # get this repo's info
# n_rgns = file.path(dir_archive, default_branch_scenario, 'reports/tables/region_titles.csv') %>% read.csv() %>% nrow() - 1
# k = branch_commits[['draft']][[1]]
# 
# # update status log
# i = which(d$repo == git_repo)
# d$status[i]    = sprintf('[![](https://api.travis-ci.org/OHI-Science/%s.svg?branch=draft)](https://travis-ci.org/OHI-Science/%s/branches)', 
#                          git_repo, git_repo)
# d$last_mod[i]  = sprintf('%0.10s', as(k@author@when, 'character'))
# d$last_sha[i]  = sprintf('%0.7s', k@sha)
# d$last_msg[i]  = k@summary
# d$map_url[i]   = sprintf('http://ohi-science.org/%s/images/regions_30x20.png', git_repo)
# d$n_regions[i] = n_rgns

# update status repo
write.csv(d, csv_status, row.names=F, na='')
system(sprintf('cd ~/tmp/subcountry; git commit -a -m "updated status from %s commit %0.7s"', git_repo, k@sha))
system('cd ~/tmp/subcountry; git push https://${GH_TOKEN}@github.com/OHI-Science/subcountry.git HEAD:gh-pages')

# return to original directory
setwd(wd)