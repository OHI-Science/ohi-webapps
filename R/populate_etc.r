# populate_etc.r

populate_etc <- function(key=key) {
  
  ## copy calculate_scores.r ## TODO: make this a template. ----
  fn <- 'calculate_scores.r'
  file.copy(file.path('~/github/ohi-webapps/inst', fn),
            file.path(dir_repo, default_scenario, fn), overwrite=TRUE)
  
  ## update source() in calculate_scores.r
  readLines(file.path(dir_repo, default_scenario, fn)) %>%
    str_replace("source.*", paste0("source('", file.path(dir_github, key, default_scenario, fn), "')")) %>%
    writeLines(file.path(dir_repo, default_scenario, fn))

  ## copy configure_toolbox.r ## TODO: make this a template. ----
  fn <- 'configure_toolbox.r'
  file.copy(file.path('~/github/ohi-webapps/inst', fn),
            file.path(dir_repo, default_scenario, fn), overwrite=TRUE)
  
  ## update setwd() in configure_toolbox.r
  readLines(file.path(dir_repo, default_scenario, fn)) %>%
    str_replace("setwd.*", paste0("setwd('", file.path(dir_github, key, default_scenario), "')")) %>%
    writeLines(file.path(dir_repo, default_scenario, fn))
  
  
  ## copy install_ohicore.r
  fn <- 'install_ohicore.r'
  file.copy(file.path('~/github/ohi-webapps/inst', fn), 
            file.path(dir_repo, fn), overwrite=TRUE)
  
 
  ## copy temp/referencePoints.csv
  fn <- 'referencePoints.csv'
  dir_temp = file.path(dir_repo, default_scenario, 'temp')
  dir.create(dir_temp)
  file.copy(file.path('~/github/ohi-webapps/inst', fn), 
            file.path(dir_temp, fn), overwrite=TRUE)
  
 
}

# calculate_scores.r, install_ohicore