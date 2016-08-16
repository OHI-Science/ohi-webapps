# populate_etc.r

populate_etc <- function(key, dir_scenario) {
  
  ## calculate_scores.r:: copy ## TODO: make this a template. ----
  fn <- 'calculate_scores.r'
  file.copy(file.path('~/github/ohi-webapps/inst', fn),
            file.path(dir_scenario, fn), overwrite=TRUE)
  
  ## calculate_scores.r:: update source()
  readLines(file.path(dir_scenario, fn)) %>%
    str_replace("source.*", paste0("source('", file.path(dir_github, key, default_scenario, fn), "')")) %>% 
    writeLines(file.path(dir_scenario, fn))

  ## configure_toolbox.r:: copy ## TODO: make this a template. ----
  fn <- 'configure_toolbox.r'
  file.copy(file.path('~/github/ohi-webapps/inst', fn),
            file.path(dir_scenario, fn), overwrite=TRUE)
  
  ## configure_toolbox.r:: update setwd()
  readLines(file.path(dir_scenario, fn)) %>%
    str_replace("setwd.*", paste0("setwd('", file.path(dir_github, key, default_scenario), "')")) %>%
    writeLines(file.path(dir_scenario, fn))
  
  
  ## copy install_ohicore.r
  fn <- 'install_ohicore.r'
  file.copy(file.path('~/github/ohi-webapps/inst', fn), 
            file.path(dir_repo, fn), overwrite=TRUE)
  
 
  ## copy temp/referencePoints.csv
  fn <- 'referencePoints.csv'
  dir_temp = file.path(dir_scenario, 'temp')
  dir.create(dir_temp)
  file.copy(file.path('~/github/ohi-webapps/inst', fn), 
            file.path(dir_temp, fn), overwrite=TRUE)
  
}
