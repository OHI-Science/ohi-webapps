#shinyapps::deployApp(appDir='~/github/ohi-webapps/test_git2r', appName='test_git2r', upload=T, launch.browser=T, lint=T)
#setwd('~/github/ohi-webapps/test_git2r')
library(git2r)
# tag   = shiny::tag
# tags  = shiny::tags
# merge = base::merge
# diff  = base::diff



dir_repo = 'ohi-global'
setwd('~/github/ohi-webapps/test_git2r')
unlink(dir_repo, recursive=T)

repo = clone('https://github.com/ohi-science/ohi-global', 'ohi-global')
branches(repo)             
# [[1]]
# [22ddc7] (Local) (HEAD) master
# 
# [[2]]
# [5cf185] (origin @ https://github.com/ohi-science/ohi-global) dev
# 
# [[3]]
# [22ddc7] (origin @ https://github.com/ohi-science/ohi-global) master

checkout(branches(repo)[[1]])
# OK

checkout(branches(repo)[[2]])
# Error in checkout(branches(repo)[[2]]) : 
#  Error in 'git2r_checkout_branch': Reference 'refs/heads/origin/dev' not found


branches(repo)[[2]]

dir.create(dir_repo, recursive=TRUE, showWarnings=F)

if ( !file.exists(file.path(dir_repo, '.git')) ){
  
  
  fetch(repo,'origin')
  
  setwd(dir_repo)
  cat('testing', file='test.txt')
  add(repo, 'test.txt')
  
  
  show(repo)
  
  setwd(dir_repo)
  system('git checkout dev')
} else {
  repo = repository(dir_repo)
  
  repo
  
  branches(repo)
  
  branch_get_upstream(branches(repo)[[2]])
  branch_remote_name(branches(repo)[[2]])
  
  remotes(repo)
  
  tree(branches(repo)[[2]])
  
  checkout(branches(repo)[[1]])
  
  x = branches(repo)[[2]]
  slotNames(x)
  x@name = 'dev'
  x@type = 1
  x@repo
  
  checkout(x)
  
  
  Luckily, the command syntax for this is quite simple:
    git checkout --track -b 
  <local branch> <remote>/<tracked branch>
    So in my case, I used this command:
    git checkout --track -b haml origin/haml
  You can also use a simpler version:
    git checkout -t origin/haml
  
  setwd(dir_repo)  
}
cfg = git2r::config(repo, user.name='OHI ShinyApps', user.email='bbest@nceas.ucsb.edu')
git2r::pull(repo)
#system('git pull')
