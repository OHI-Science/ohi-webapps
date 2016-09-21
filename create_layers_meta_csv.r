## turn layers.csv description column into md

library(tidyverse)
## will heavily use tidyr::separate and stringr::str_replace_all


dir_tmp <- '~/github/ohi-webapps/tmp'

## read layers.csv
dir_layers <- '~/github/ohi-global/eez2016'

## Step 1: read in layers.csv
l  <- readr::read_csv(file.path(dir_layers, 'layers.csv'))
ld <- l %>%
  select(layer, targets, description) %>%
  arrange(layer) %>%
  mutate(description = str_replace_all(description, '"', ''))

## Step 2: separate description column into 2 columns
ld2 <- ld %>%
  separate(description, 
           into = c('description', 'source'),
           sep = "Data sources:")

## Step 3: separate md in source column into 2 columns
ld3 <- ld2 %>%
  mutate(source = str_replace_all(source, c("\n- Feely" = "\n\n- Feely", ## clean up this one Feely reference
                                            "\n\n"      = ""))) %>%
  separate(source, 
           into = c('source', 'source_url'),
           sep  = c("\n-"), 
           extra = "merge")

## now separate 'source_url' into 'source_url' and 'source2'...



data.frame(ld[4,"description"])
data.frame(ld3[4,"source"])
data.frame(ld3[4,"source_url"])


# sep = "\\]\\(" ) %>%             ## separate by middle of md link

##clean up
ld3 %>% ld3 %>%  
  mutate(source = str_replace_all(source, 
                                  c("\\- \\[" = "", ## remove beginning of md link
                                    "\\- "    = "",    ## remove beginning of citation without md link
                                    "â"       =  "'"))) %>%     ## remove weird FAO character
  mutate(source_url = str_replace_all(source_url, 
                                      c("\\)"     =  "")))    ## remove end of md link

## Step 4: add data prep url column
ld4 <- ld3 %>%
  mutate(data_prep_url = "")

## Step 5: tidyr::gather
ld5 <- ld4 %>%
  gather(field, information, -(1:2)) %>%
  arrange(targets, layer)


data.frame(ld[3,"description"])  
data.frame(ld[4,"description"])  
data.frame(ld3[4,"source"])
data.frame(ld3[4,"source"])
data.frame(ld3[4,"source_url"])




write_csv(ld, file.path(dir_tmp, 'layersd.csv'))


## Then, save this as layers.rmd

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



