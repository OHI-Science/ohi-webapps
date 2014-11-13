
# set vars and get functions
setwd('~/github/ohi-webapps')
source('create_init.R')
source('create_functions.R')
source('ohi-travis-functions.R')

# loop through countries
for (key in sc_studies$sc_key){ # key = 'ecu'
  
  # set vars by subcountry key
  source('create_init_sc.R')
      
  # create github repo
  #create_gh_repo(key)
  
  # populate draft branch
  #populate_draft_branch()

  # move into draft branch
  setwd(dir_repo)
  repo=repository(dir_repo)
  checkout(repo, 'draft')
  
  # calculate_scores
  res = try(calculate_scores())
  # if problem calculating, log problem and move on to next subcountry key
  txt_calc_error = sprintf('%s/%s_calc-scores.txt', dir_errors, key)
  unlink(txt_calc_error)
  if (class(res)=='try-error'){
    cat(as.character(traceback(res)), file=txt_calc_error)
    next
  }

  # create flower plot and table
  create_results()
  
  # push draft branch
  push_branch('draft')
  
  # publish draft branch
  push_branch('published')
  
  # populate website
  populate_website()
  
  # create pages based on results
  create_pages()

  # install latest ohicore, with DESCRIPTION having commit etc to add to app
  #devtools::install_github('ohi-science/ohicore@dev')
  
  # deploy app
  deploy_app()
  

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