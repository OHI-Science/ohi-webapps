rollback_webapp = function(dir_repo, commit_id){
  # reset all webapp repo's layers to a specific commit
  
  # inputs and sample call
  # dir_repo  : root directory for the repo 
  # commit_id : commit identifier  
  # rollback_webapp(dir_repo = '~/github/ohi-ecuador', commit_id = '723312a')

  suppressPackageStartupMessages(suppressWarnings({
    library(git2r)
    library(stringr)
    library(dplyr)
    library(ohicore)
  }))
  
  # set dirs
  dir_lyr = 'subcountry2014/layers'
  setwd(file.path(dir_repo, dir_lyr))
  
  # update all layers to commit_id
  for (f in list.files(file.path(dir_repo, dir_lyr), glob2rx('*.csv'), full.names = T)){ # f = "~/github/ohi-ecuador/subcountry2014/layers/alien_species_gl2014.csv" 
    
    read_git_csv(dir_repo, commit_id, file.path(dir_lyr, basename(f))) %>% 
      write.csv(f, row.names=F, na='')
  }
  
}