## _source_and_load.r
# temporary file to load/source all the scripts necessary for the ohirepos package. 

## R scripts
to_source <- list.files('~/github/ohi-webapps/R', all.files=TRUE, full.names=TRUE)[-c(1,2)]
sapply(to_source, source)

# directories
dir_webapps <- '~/github/ohi-webapps'
dir_M <- c('Windows' = '//mazu.nceas.ucsb.edu/ohi',
           'Darwin'  = '/Volumes/ohi',
           'Linux'   = '/home/shares/ohi')[[ Sys.info()[['sysname']] ]]

if (Sys.info()[['sysname']] != 'Linux' & !file.exists(dir_M)){
  warning(sprintf("The Mazu directory dir_M set in src/R/common.R does not exist. Do you need to mount Mazu: %s?", dir_M))
}

# libraries
library(tidyverse)
library(rgdal)
