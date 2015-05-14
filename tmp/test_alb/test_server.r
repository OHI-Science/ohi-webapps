# test whether deploy_app_nceas is working with the server or whether it breaks App page

# 1. ohi-science.org/alb/app works perfectly; build passing ----

# 2. edit gh-pages and draft branches (temporarily_ ----
# based on `update_website`

setwd('~/github/ohi-webapps')
source('create_init.R')
source('create_functions.R')

key = 'alb'
key <<- key
source(file.path(dir_github, 'ohi-webapps/create_init_sc.R'))

# cd into repo, checkout gh-pages
wd = getwd()
if (!file.exists(dir_repo)) system(sprintf('git clone %s %s', git_url, dir_repo))
setwd(dir_repo)
repo = repository(dir_repo)

# switch to gh-pages and get latest
system('git checkout gh-pages; git pull')

# copy template web files over
file.copy('images/flag_80x40.png', '~/github/ohi-webapps/tmp/test_alb')
file.remove('images/flag_80x40.png')

# git add, commit and push
msg = 'testing'
system(sprintf('git add -A; git commit -a -m "%s"', msg))
system('git push origin gh-pages')

# switch to draft and get latest
system('git checkout draft; git pull')

# changed setwd() by hand in `calculate_scores.r`

# git add, commit and push
msg = 'testing'
system(sprintf('git add -A; git commit -a -m "%s"', msg))
system('git push origin draft')

# 3. log into nceas server in terminal
# cd .ssh
# ssh jstewart@fitz.nceas.ucsb.edu
# cd /srv/shiny-server


# 4. run deploy_app_nceas
key = 'alb'
deploy_app_nceas(key)


# 5. put the flag image back ----

setwd('~/github/ohi-webapps')
source('create_init.R')
source('create_functions.R')

key = 'alb'
key <<- key
source(file.path(dir_github, 'ohi-webapps/create_init_sc.R'))

# cd into repo, checkout gh-pages
wd = getwd()
if (!file.exists(dir_repo)) system(sprintf('git clone %s %s', git_url, dir_repo))
setwd(dir_repo)
repo = repository(dir_repo)

# switch to gh-pages and get latest
system('git checkout gh-pages; git pull')

# copy template web files over
file.copy('~/github/ohi-webapps/tmp/test_alb', 'images/flag_80x40.png')

# git add, commit and push
msg = 'testing'
system(sprintf('git add -A; git commit -a -m "%s"', msg))
system('git push origin gh-pages')

# 6. try deploy_app_nceas again
key = 'alb'
deploy_app_nceas(key)


# fin----