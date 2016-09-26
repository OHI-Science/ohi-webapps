## convert layers_meta.csv into .rmd

## TODO: create_layers_meta: deal with element_wts_cp_km2_x_protection (no sources)
## TODO still FAOâs

## debug
library(tidyverse)
library(stringr)
dir_layers_meta <- '~/github/ohi-global/eez2016'


## To discuss with Mel: where/when do we want this called from/and how? From the gh-pages branch potentially?

convert_layers_meta_rmd <- function(dir_layers_meta) {
  
  ## TODO: checks
  ## check that layers_meta.csv exists
  ## check/report mismatches between layers_meta.csv and layers.csv
  
  
  ## read in layers_meta.csv 
  m <- read_csv(file.path(dir_layers_meta, 'layers_meta.csv')) %>%
    mutate(field_info = str_replace_all(field_info, 'NA', '')) ## TODO-- get rid of these NAs
  
  ## setup front matter
  rmd <- paste0('----\n\n')
  
  
  ## loop through each layer, create markdown string
  lyrs <- unique(m$layer)
  for (lyr in lyrs) { # lyr <- 'ao_access'
    
    meta <- m %>%
      filter(layer %in% lyr)
    
    ## create string with lyr, description, citation
    s <- paste0('## ', lyr, '\n\n',
                
                '#### description\n\n',
                meta$field_info[meta$field_name == 'description'], # TODO: consider stripping excess \n\n 
                
                '#### citation\n\n', 
                '- [', meta$field_info[meta$field_name == 'source1'], '](', 
                meta$field_info[meta$field_name == 'source_url1'], ')\n\n')
    
    
    
    ## add multiple citations
    ## if exists multiple sources
    # figure out how many sources
    # loop through
    # s <- paste0(s, ...)
    
    ## add data_prep_url
    s <- paste0(s, 
                '#### preparation\n', 
                meta$field_info[meta$field_name == 'data_prep_url'], '\n\n', 
                '----\n\n')
    
    
    
    ## bind rows 
    rmd <- rbind(rmd, s)
    
  }
  
  ## write rmd. --> TODO: save where?
  write_lines(rmd, 'testing_rmd.rmd')
  
  
}