## populate_prep.r

populate_prep <- function(){
  
  ## clone repo
  wd = getwd()
  if (!file.exists(dir_repo)) system(sprintf('git clone %s %s', git_url, dir_repo))
  setwd(dir_repo)
  repo = repository(dir_repo)
  
  # pull the latest from draft branch
  system('git checkout draft; git pull')
  
  ## create prep dir
  dir.create('prep', showWarnings=F)
  file.copy(file.path(dir_github, 'ohi-webapps/README_prep.md'), 
            file.path('prep/README.md'), overwrite=T)
  
  ## create subfolders in prep folder
  prep_subfolders = c('FIS', 'MAR', 'AO', 'NP', 'CS', 'CP', 'LIV', 'ECO', 'TR', 'CW',
                      'ICO', 'LSP', 'SPP', 'HAB', 'pressures', 'resilience')
  sapply(file.path(sprintf('prep/%s', prep_subfolders)), dir.create)
  
  ## populate prep folder's subfolders
  # file.create(file.path(sprintf('prep/%s', prep_subfolders), 'README.md'))
  file.copy(file.path(dir_github, 'ohi-webapps/README_prep_subfolders.md'), 
            file.path(sprintf('prep/%s/README.md', prep_subfolders)), overwrite=T)
  
  ## git add, commit and push
  system(sprintf('git add -A; git commit -a -m "%s repo populated with prep folders"', key))
  system('git push origin draft')
  
  ## TO ADD 
  # ## create and populate prep/tutorials folder 
  # dir_tutes = file.path(dir_github, 'ohimanual/tutorials/R_tutes')
  # 
  # dir.create(file.path(dir_repo, default_scenario, 'prep/tutorials'))
  # file.copy(file.path(dir_tutes, 'R_tutes_all.md'), 
  #           file.path(default_scenario, 'prep/tutorials', 'R_intro.md'), overwrite=T)
  # readLines(file.path(dir_tutes, 'R_tutes.r')) %>%
  #   str_replace("setwd.*", 
  #               paste0("setwd('", file.path(dir_github, key, default_scenario, 'prep/tutorials'), "')")) %>%
  #   writeLines(file.path(default_scenario, 'prep/tutorials', 'R_tutorial.r'))    
  # 
  
}