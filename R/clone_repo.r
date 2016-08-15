# clone_repo.r

clone_repo <- function(dir_repos, dir_repo, git_url) {
  
  ## clone repo
  unlink(dir_repo, recursive=T, force=T)
  repo = clone(git_url, normalizePath(dir_repo, mustWork=F))
  
  ## get remote branches
  remote_branches = sapply(git2r::branches(repo, 'remote'), function(x) str_split(x@name, '/')[[1]][2])
  
}