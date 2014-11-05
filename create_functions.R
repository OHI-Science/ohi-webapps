# one-time fixes ----

rename_sc_annex <- function(name){
  # rename annex directories
  
  d = filter(sc_studies, sc_name == name)
  path_from = file.path(dir_annex, str_replace_all(d$gl_rgn_name, ' ', '_'))
  path_to   = file.path(dir_annex, d$sc_key)
  if (file.exists(path_from) & !file.exists(path_to)) {
    message(sprintf(' moving %s -> %s', path_from, basename(path_to)))
    file.rename(path_from, path_to)  
  } else {
    message(sprintf(' skipping %s -> %s, since from !exists or to exists', path_from, basename(path_to)))
  }
} 
#lapply(sc_studies$sc_name, rename_sc_annex) # done 2014-11-02 by bbest

create_gh_repo <- function(key, gh_token=gh_token, verbosity=1){

  repo_name = key
  res = system(sprintf('git ls-remote git@github.com:ohi-science/%s.git', repo_name), ignore.stderr=T, intern=T)
  repo_exists = ifelse(res != 128, T, F)
  if (!repo_exists){    
    if (verbosity > 0){
      message(sprintf('%s: creating github repo -- %s', repo_name, format(Sys.time(), '%X')))
    }
    # create using Github API: https://developer.github.com/v3/repos/#create
    cmd = sprintf('curl --silent -u "bbest:%s" https://api.github.com/orgs/ohi-science/repos -d \'{"name":"%s"}\'', gh_token, repo_name)
    cmd_res = paste(capture.output(fromJSON(system(cmd, intern=T))), collapse='\n')
  } 
  
  # return data.frame
  data.frame(
    sc_key      = key, 
    repo_exists = repo_exists,
    cmd         = ifelse(repo_exists, cmd),
    cmd_res     = ifelse(repo_exists, cmd_res))
}
#lapply(sc_studies$sc_key, create_gh_repo, verbosity=1)


rename_gh_repo <- function(key, verbosity=1){ # key='are'
  # rename github repo. if new exists, not old, and not exception
  
  d = subset(sc_studies, sc_key == key)
  repo_new = key
  repo_old = sprintf('ohi-%s', d$sc_key_old)
  name     = d$sc_name
  repo_new_exists = system(sprintf('git ls-remote git@github.com:ohi-science/%s.git', repo_new), ignore.stderr=T, intern=T)[1] != 128
  repo_old_exists = system(sprintf('git ls-remote git@github.com:ohi-science/%s.git', repo_old), ignore.stderr=T, intern=T)[1] != 128

  cmd_condition = repo_old_exists & !repo_new_exists & !name %in% sc_names_existing_repos
  cmd = sprintf('curl --silent -u "bbest:%s" -X PATCH -d \'{"name": "%s"}\' https://api.github.com/repos/ohi-science/%s', gh_token, repo_new, repo_old)
  if (cmd_condition){
    if (verbosity > 0){
      message(sprintf('%s: renaming repo "%s" -> "%s" -- %s\n', key, repo_old, repo_new, format(Sys.time(), '%X')))
    }
    cmd_res = paste(capture.output(fromJSON(system(cmd, intern=T))), collapse='\n')
  }
  
  # return data.frame
  data.frame(
    sc_key          = key, 
    sc_name         = name,
    cmd             = ifelse(cmd_condition, cmd), 
    cmd_res         = ifelse(cmd_condition, cmd_res),
    repo_old_exists = repo_old_exists, 
    repo_new_exists = repo_new_exists, 
    name_excepted   = name %in% sc_names_existing_repos)
}    
#results <- rbind_all(lapply(sc_studies$sc_key, rename_gh_repo, verbosity=1)) # done 2014-11-02 by bbest
#repo_todo <- filter(results, !repo_new_exists)$sc_key

# update Github repo with Description, Website and default branch
edit_gh_repo <- function(key, default_branch='master', verbosity=1){ # key='abw'
  
  # vars
  d           = subset(sc_studies, sc_key == key)
  repo        = d$sc_key
  description = sprintf('Ocean Health Index for %s', d$sc_name)
  website     = sprintf('http://ohi-science.org/%s', repo)
  
  # setup JSON metadata object to inject
  kv = list(
    name           = repo, 
    description    = description,
    homepage       = website,
    default_branch = default_branch)
  json = toJSON(kv, auto_unbox = T)
  
  cmd = sprintf('git ls-remote git@github.com:ohi-science/%s.git', repo)
  cmd_res = system(cmd, ignore.stderr=T, intern=T)
  repo_exists = ifelse(res[1] != 128, T, F)  
  if (repo_exists){
    if (verbosity > 0){
      message(sprintf('%s: updating github repo attributes -- %s', key, format(Sys.time(), '%X')))
      if (verbosity > 1){
        message(paste(sprintf('  %s: %s', names(kv), as.character(kv)), collapse='\n'))
      }
    }
    cmd = sprintf('curl --silent -u "bbest:%s" -X PATCH -d \'%s\' https://api.github.com/repos/ohi-science/%s', gh_token, json, repo)
    cmd_res = paste(capture.output(fromJSON(system(cmd, intern=T))), collapse='\n')
  }
  
  # return data.frame
  data.frame(
    sc_key         = key, 
    sc_name        = d$sc_name, 
    repo_exists    = repo_exists,
    cmd            = cmd, 
    cmd_res        = cmd_res, 
    description    = ifelse(repo_exists, description), 
    website        = ifelse(repo_exists, website),
    default_branch = ifelse(repo_exists, default_branch),
    stringsAsFactors=F)
}    
#results = rbind_all(lapply(sc_studies$sc_key[1:3], edit_gh_repo, verbosity=2)) # done 2014-11-02 by bbest


rename_branches <- function(key, verbosity=1){ # key='ecu'
  # rename: master -> published, dev -> draft
  
  dir_repo = file.path(dir_repos, key)
  setwd(dir_repo)  
  
  rename_branch <- function(branch_old, branch_new){
    branches = system('git branch -l', intern=T) %>% str_replace(fixed('*'), '') %>% str_trim()
    
    if (!branch_new %in% branches & branch_old %in% branches){
      # if new not exists, and old exists
      
      system(sprintf('git branch -m %s %s', branch_old, branch_new))
      system(sprintf('git push -u origin %s', branch_new)) # push and set upstream to origin
    }
    
    if (!branch_new %in% branches & !branch_old %in% branches){
      # if neither branch found, create off existing except gh-pages
      
      branch_beg = setdiff(branches, 'gh-pages')[1]
      system(sprintf('git checkout %s', branch_beg))      
      system(sprintf('git checkout -b %s', branch_new))
      system(sprintf('git push -u origin %s', branch_new)) # push and set upstream to origin
    }
    
  }
      
  # new branches
  rename_branch('dev', 'draft')
  rename_branch('master', 'published')
      
  # set default branch to draft
  res = edit_gh_repo(key, default_branch='draft')
  
  # delete old branches remotely and locally, if exist
  branches = system('git branch -l', intern=T) %>% str_replace(fixed('*'), '') %>% str_trim()
  for (b in intersect(c('dev','master'), branches)){
    system(sprintf('git push origin :%s', b))
  }  
}    
#results = rbind_all(lapply(sc_studies$sc_key[1:3], edit_gh_repo, verbosity=2)) # done 2014-11-02 by bbest
