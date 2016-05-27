## To delete unused ohi-webapps made with eez2014 data. 

## See https://github.com/OHI-Science/issues/issues/660. 
## by @bbest, @jules32, May 2016. 
# deleting because:
#   - wrong boundaries
#   - using 2014 data vs now 2015
#   - pressures/resilience out of sync
#   - people turned off b/c already looks "done"

## setup ----
source('create_init.r')
library(dplyr)
library(readr)
library(jsonlite)

## set gh_token for privileges (bbest, jules32)
gh_token <- scan('~/.github-token', 'character', quiet = T)


## lists of repos ----

## TODO:
## get full list of current, existing ohi-science repos 
## using Github API: https://developer.github.com/v3/repos/#list-organization-repositories: # GET /orgs/:org/repos
suppressWarnings(rm('repo_info'))
end = F; p = 1
while (!end){
  
  # construct curl command; must paginate https://developer.github.com/v3/#pagination
  cmd = sprintf('curl -X GET -H "Authorization: token %s" https://api.github.com/orgs/ohi-science/repos?page=%d', gh_token, p)

  # read JSON response
  v = fromJSON(system(cmd, intern=T))
  
  if (length(v) > 0){
    # since field owner is class of data.frame, get just first 3 columns
    #   more: [dplyr - R-Error: data_frames can only contain 1d atomic vectors and lists - Stack Overflow](http://stackoverflow.com/questions/34443410/r-error-data-frames-can-only-contain-1d-atomic-vectors-and-lists)
    v = tbl_df(v[,1:3])
    
    if (exists('repo_info')){
      repo_info = repo_info %>%
        bind_rows(v)
    } else {
      repo_info = v
    }
  } else {
    end = T
  }
  
  # iterate to next page
  p = p + 1
}
## save full list of repos prior to delete
write.csv(repo_info, 'ohi-science_repos_pre_delete_2016_05_27.csv', row.names=FALSE) 

  
## delete repos ----  
  
## ohi+ repos to keep
to_keep <- c('chn', 'gye', 'ohi-israel', 'ohi-canada', 'ohi-fiji', 'ohi-uswest', # completed
             'bhi', 'col', 'cdz', 'ohibc', 'ohi-northeast', 'ohi-global',        # in progress
             'arc', 'chl', 'can', 'esp', 'ecu', 'rus', 'blz',                    # keep as examples for now
             'swe', 'fin', 'dnk', 'deu', 'est', 'pol', 'lva', 'ltu', 'rus')      # bhi regions keep for now

## repos to delete
sc_studies_to_delete <- sc_studies %>%
  filter(!sc_key %in% to_keep)
write_csv(sc_studies_to_delete, 'sc_studies_to_delete.csv')

repos_to_delete = sc_studies_to_delete %>%
  left_join(repo_info %>%
              dplyr::rename(sc_key = name), 
            by = 'sc_key') 
# repos_to_delete.csv written below

## double-check urls for these; see if indications of use (any forks or commits) 
repos_to_delete$sc_key

## DANGER::loop through and delete repos_to_delete. uncomment cmd lines to execute.  -----
for (r in repos_to_delete$sc_key) { # r <- "atg"
  
  ## delete using Github API: https://developer.github.com/v3/repos/#create # DELETE /repos/:owner/:repo
  # cmd = sprintf('curl -X DELETE -H "Authorization: token %s" https://api.github.com/repos/ohi-science/%s', gh_token, r)
  # system(cmd, intern=T)
} 

repos_to_delete2 <- c('ohi-baltic', 'ohi-china', 
                      'bhi-swe', 'bhi-fin', 'bhi-dnk', 'bhi-deu', 'bhi-est', 'bhi-pol', 'bhi-lva', 'bhi-ltu', 'bhi-rus', 
                      'Example-Repo')
write.csv(c(repos_to_delete$sc_key, repos_to_delete2), 'repos_to_delete.csv', row.names=FALSE)

## DANGER: loop through other repos to delete
for (r in repos_to_delete2) { 
  
  ## delete using Github API: https://developer.github.com/v3/repos/#create # DELETE /repos/:owner/:repo
  # cmd = sprintf('curl -X DELETE -H "Authorization: token %s" https://api.github.com/repos/ohi-science/%s', gh_token, r)
  # system(cmd, intern=T)
} 


## list current ohi-science repos now. from above. 
suppressWarnings(rm('repo_info'))
end = F; p = 1
while (!end){
  
  # construct curl command; must paginate https://developer.github.com/v3/#pagination
  cmd = sprintf('curl -X GET -H "Authorization: token %s" https://api.github.com/orgs/ohi-science/repos?page=%d', gh_token, p)
  
  # read JSON response
  v = fromJSON(system(cmd, intern=T))
  
  if (length(v) > 0){
    v = tbl_df(v[,1:3])
    
    if (exists('repo_info')){
      repo_info = repo_info %>%
        bind_rows(v)
    } else {
      repo_info = v
    }
  } else {
    end = T
  }
  
  # iterate to next page
  p = p + 1
}
## save full list of repos post delete
write.csv(repo_info, 'ohi-science_repos_post_delete_2016_05_27.csv', row.names=FALSE) 




## one-time update status.csv that displays on ohi-science.org/subcountry; will need to make workflow to update as move on. 
## modified from https://github.com/OHI-Science/ohi-webapps/blob/b9e12ffd304018680f5dd693b9cd328a523a440c/ohi-functions.r#L370-L399

## get status repo depth of 1 only
if (file.exists('~/tmp/subcountry')){
  system('cd ~/tmp/subcountry; git pull')
} else {
  dir.create(dirname('tmp'), showWarnings=F, recursive=T)
  system('git clone --depth=1 https://github.com/OHI-Science/subcountry ~/tmp/subcountry')
}

## update status.csv with to_keep only
d <- '~/tmp/subcountry/_data/status.csv'
read_csv(d) %>%
  select(repo, study_area, map_url, n_regions) %>%
  filter(repo %in% to_keep) %>%
  write_csv(d, na='')

## push; GH_TOKEN set in create_init.r. Note: the GH_TOKEN caused the rpostback askpass error on El Capitan
system('cd ~/tmp/subcountry; git commit -a -m "updated status.csv from ohi-webapps/delete_unused_repos"')
system('cd ~/tmp/subcountry; git push https://${GH_TOKEN}@github.com/OHI-Science/subcountry.git HEAD:gh-pages')


## also delete by hand ---
# 'ohi-china',


suppressWarnings(rm('repo_info'))
end = F; p = 1
while (!end){
  
  # construct curl command; must paginate https://developer.github.com/v3/#pagination
  cmd = sprintf('curl -X GET -H "Authorization: token %s" https://api.github.com/orgs/ohi-science/repos?page=%d', gh_token, p)
  
  # read JSON response
  v = fromJSON(system(cmd, intern=T))
  
  if (length(v) > 0){
    # since field owner is class of data.frame, get just first 3 columns
    #   more: [dplyr - R-Error: data_frames can only contain 1d atomic vectors and lists - Stack Overflow](http://stackoverflow.com/questions/34443410/r-error-data-frames-can-only-contain-1d-atomic-vectors-and-lists)
    v = tbl_df(v[,1:3])
    
    if (exists('repo_info')){
      repo_info = repo_info %>%
        bind_rows(v)
    } else {
      repo_info = v
    }
  } else {
    end = T
  }
  
  # iterate to next page
  p = p + 1
}
