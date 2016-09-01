## turn layers.csv description column into md

library(dplyr)
library(readr)

dir_tmp <- '~/github/ohi-webapps/tmp'

## read layers.csv
dir_layers <- '~/github/ohi-global/eez2016'

l  <- readr::read_csv(file.path(dir_layers, 'layers.csv'))
ld <- l %>%
  select(layer, description)

write_csv(ld, file.path(dir_tmp, 'ld.csv'))
