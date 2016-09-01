## turn layers.csv description column into md

library(dplyr)
library(readr)

dir_tmp <- '~/github/ohi-webapps/tmp'

## read layers.csv
dir_layers <- '~/github/ohi-global/eez2016'

l  <- readr::read_csv(file.path(dir_layers, 'layers.csv'))
ld <- l %>%
  select(layer, description) %>%
  arrange(layer)
dim(ld)

write_csv(ld, file.path(dir_tmp, 'ld.csv'))


## Then, save this as a .csv

## In Text Wrangler, 2 search-replaces:

### 1. 
### search: `^(\w+\_\w{2,}),(.*)`
### replace: `\n## \1\n\n#### description\n\n\2`

### 2. 
### search: `Data sources:\n\n(\- .*)`
### replace: `#### citation\n\n\1\n\n#### preparation\n`

# Then clean up: 
# remove line 1, clean up FAO wierdnesses, 
# search for `â`, replace with `-` or `-`
# Text > Process Lines Containing: `^## ` and make sure count matches dim(ld)[1]
# search `"`, replace ``
# check hab_extent - will need to move `preparation` lower because multiple refs
# also will need to add citation/preparation to ALL the LE layers



