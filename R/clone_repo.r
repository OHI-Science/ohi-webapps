# clone_repo.r

clone_repo <- function(dir_repos = dir_repos, 
                       dir_repo  = dir_repo,
                       git_url   = git_url) {
  
  wd = getwd()
  
  ## clone repo
  setwd(dir_repos)
  unlink(dir_repo, recursive=T, force=T)
  repo = clone(git_url, normalizePath(dir_repo, mustWork=F))
  setwd(dir_repo)
  
  ## get remote branches
  remote_branches = sapply(branches(repo, 'remote'), function(x) str_split(x@name, '/')[[1]][2])
  
}