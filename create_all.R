
# set vars and get functions
setwd('~/github/ohi-webapps')
source('create_init.R')
source('create_functions.R')
source('ohi-travis-functions.R')

# loop through countries
for (key in sc_studies$sc_key){ # key = 'ago'
  
  # set vars by subcountry key
  setwd(dir_repos)
  source('create_init_sc.R')

  # create github repo
  #create_gh_repo(key)
  
  # create maps
  create_maps(key)
  
  # clone and cd
  system(sprintf('git clone %s %s', git_url, dir_repo))
  setwd(dir_repo)
  
  # populate draft branch
  populate_draft_branch()
  
  # push draft branch
  setwd(dir_repo)
  push_branch('draft')
  system('git checkout draft; git pull')
  
  # calculate_scores
  setwd(dir_repo)
  res = try(calculate_scores())
  # if problem calculating, log problem and move on to next subcountry key
  txt_calc_error = sprintf('%s/%s_calc-scores.txt', dir_errors, key)
  unlink(txt_calc_error)
  if (class(res)=='try-error'){
    cat(as.character(traceback(res)), file=txt_calc_error)
    next
  }

  # create flower plot and table
  setwd(dir_repo)
  create_results()
  
  # push draft and published branches
  setwd(dir_repo)
  push_branch('draft')
  push_branch('published')
  system('git pull')
  
  # populate website
  populate_website()
  
  # if master lingering, delete
  delete_extra_branches()
  
  # ensure draft is default branch
  #edit_gh_repo(key, default_branch='draft', verbosity=1)
  
  # create pages based on results
  create_pages()
  
  # turn on Travis
  setwd(dir_repo)
  system('git checkout draft')
  system(sprintf('travis encrypt -r %s GH_TOKEN=%s --add env.global', git_slug, gh_token))
  system(sprintf('travis enable -r %s', git_slug))
  system('git commit -am "enabled travis.yml with encrypted github token"; git push')
  
  # deploy app
  #devtools::install_github('ohi-science/ohicore@dev') # install latest ohicore, with DESCRIPTION having commit etc to add to app
  setwd(dir_repos)
  deploy_app(key)  

} # end for (key in keys)
# 
# y = y %>%
#   select(Country, init_app, status, url_github_repo, url_shiny_app, error) %>%
#   arrange(desc(init_app), status, error, Country)
# 
# write.csv(y, '~/github/ohi-webapps/tmp/webapp_status.csv', row.names=F, na='')
# 
# table(y$error) %>%
#   as.data.frame() %>% 
#   select(error = Var1, count=Freq) %>%
#   filter(error != '') %>%
#   arrange(desc(count)) %>%
#   knitr::kable()