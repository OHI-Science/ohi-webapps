#shinyapps::deployApp(appDir='~/github/ohi-webapps/test_git2r', appName='test_git2r', upload=T, launch.browser=T, lint=T)
#setwd('~/github/ohi-webapps/test_git2r')
library(git2r)

# Clone the git2r repository
dir_repo = 'ohi-israel'
dir.create(dir_repo, recursive=TRUE)
message(sprintf('pwd: %s\nlist.files(): %s', getwd(), paste(list.files(), collapse=', ')))
if ( !file.exists(file.path(dir_repo, '.git')) ){
  message('cloning repo')
  repo = clone(sprintf('https://github.com/ohi-science/%s', dir_repo), dir_repo)
  message(summary(repo))
}
message(sprintf('pwd: %s\nlist.files(dir_repo): %s', getwd(), paste(list.files(dir_repo), collapse=', ')))
repo = repository(dir_repo)
message(summary(repo))
cfg = config(repo, user.name='OHI ShinyApps', user.email='bbest@nceas.ucsb.edu')
#message(summary(cfg))
pull(repo)