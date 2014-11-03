# one-time fixes ----

# rename annex directories
rename_sc_annex <- function(name){
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

# rename github repo. if new exists, not old, and not exception
rename_gh_repo <- function(key){ # key='are'
  
  d = subset(sc_studies, sc_key == key)
  repo_new = key
  repo_old = sprintf('ohi-%s', d$sc_key_old)
  name     = d$sc_name
  repo_new_exists = system(sprintf('git ls-remote git@github.com:ohi-science/%s.git', repo_new), ignore.stderr=T) != 128
  repo_old_exists = system(sprintf('git ls-remote git@github.com:ohi-science/%s.git', repo_old), ignore.stderr=T) != 128
  
  if (repo_old_exists & !repo_new_exists & !name %in% sc_names_existing_repos){  
    message(sprintf('%s: renaming repo "%s" -> "%s" -- %s\n', key, repo_old, repo_new, format(Sys.time(), '%X')))
    cmd = sprintf('curl -u "bbest:%s" -X PATCH -d \'{"name": "%s"}\' https://api.github.com/repos/ohi-science/%s', gh_token, repo_new, repo_old)
    system(cmd)
  }
  data.frame(sc_key=key, sc_name=name, repo_old_exists=repo_old_exists, repo_new_exists=repo_new_exists, name_excepted=name %in% sc_names_existing_repos)
}    
#results <- rbind_all(lapply(sc_studies$sc_key, rename_gh_repo)) # done 2014-11-02 by bbest
#repo_todo <- filter(results, !repo_new_exists)$sc_key

# create / update Github repo with Description and Website
edit_gh_repo <- function(key, default_branch='master'){ # key='abw'
  
  # vars
  d           = subset(sc_studies, sc_key == key)
  repo        = d$sc_key
  description = sprintf('Ocean Health Index for %s', d$sc_name)
  website     = sprintf('http://ohi-science.org/%s', repo)
  
  # setup JSON metadata object to inject
  json = toJSON(
    list(
      name           = repo, 
      description    = description,
      homepage       = website,
      default_branch = default_branch),
    auto_unbox = T)
  
  repo_exists = system(sprintf('git ls-remote git@github.com:ohi-science/%s.git', repo), ignore.stderr=T) != 128
  
  if (repo_exists){  
    message(sprintf('%s: updating attributes -- %s\n', key, format(Sys.time(), '%X')))
    cmd = sprintf('curl -u "bbest:%s" -X PATCH -d \'%s\' https://api.github.com/repos/ohi-science/%s', gh_token, json, repo)
    system(cmd)
  }
  
  # return data.frame
  data.frame(
    sc_key         = key, 
    sc_name        = d$sc_name, 
    repo_exists    = repo_exists, 
    description    = description, 
    website        = website,
    default_branch = default_branch)
}    
results = rbind_all(lapply(sc_studies$sc_key, edit_gh_repo)) # done 2014-11-02 by bbest
results %>% filter(!repo_exists)


