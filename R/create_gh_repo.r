create_gh_repo <- function(key, gh_token=gh_token, github_user=github_user){
  
  repo_name <- key
  cmd <- sprintf('git ls-remote git@github.com:ohi-science/%s.git', repo_name)
  res <- system(cmd, ignore.stderr=T, intern=T)
  repo_exists <- ifelse(length(res)!=0, T, F) 
  
  ## create and run command call using Github API: https://developer.github.com/v3/repos/#create
  if (!repo_exists){
    message(sprintf('%s: creating github repo -- %s', repo_name, format(Sys.time(), '%X')))
    
    ## create command
    cmd <- sprintf('curl --silent -u "%s:%s" https://api.github.com/orgs/ohi-science/repos -d \'{"name":"%s"}\'', 
                   github_user, gh_token, repo_name)
    ## run command
    cmd_res = paste(capture.output(fromJSON(system(cmd, intern=T))), collapse='\n')
    
  } else{
    message(sprintf('%s: repo already exists.', repo_name))
  }
}