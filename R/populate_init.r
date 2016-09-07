## populate_init.r

populate_init <- function(key){
  
  ## clone repo
  setwd(dir_repos)
  unlink(dir_repo, recursive=T, force=T)
  repo <- clone(git_url, normalizePath(dir_repo, mustWork=F))
  setwd(dir_repo)
  
  ## get remote branches
  remote_branches <- sapply(branches(repo, 'remote'), function(x) str_split(x@name, '/')[[1]][2])
  
  ## initialize repo
  if (length(remote_branches)==0){
    system('touch README.md')
    system('git add -A; git commit -m "first commit"')
    try(system('git remote rm origin')) # stackoverflow.com/questions/1221840/remote-origin-already-exists-on-git-push-to-new-repository
    system(sprintf('git remote add origin https://github.com/OHI-Science/%s.git', key))
    system('git push -u origin master')
    system('git pull')
    remote_branches = sapply(branches(repo, 'remote'), function(x) str_split(x@name, '/')[[1]][2])
  }
  
  ## recreate empty dir, except hidden .git
  del_except <- ''
  for (f in setdiff(list.files(dir_repo, all.files=F), del_except)) unlink(file.path(dir_repo, f), recursive=T, force=T)
  
  ## add Rstudio project files. cannabalized devtools::add_rstudio_project() which only works for full R packages.
  file.copy(system.file('templates/template.Rproj', package='devtools'), sprintf('%s.Rproj', key))
  writeLines(c('.Rproj.user', '.Rhistory', '.RData'), '.gitignore')
  
  ## README 
  brew(sprintf('%s/ohi-webapps/README.brew.md', dir_github), 'README.md')
  
  ## git add, commit and push
  system(sprintf('git add -A; git commit -a -m "%s repo populated with initial files"', key))
  system('git push origin master')
  
}