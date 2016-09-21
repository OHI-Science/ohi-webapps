## turn layers.csv description column into md

library(tidyverse); library(stringr)
## will heavily use tidyr::separate and stringr::str_replace_all

## read layers.csv -- make sure you pull these first
# dir_layers <- '~/github/ohi-global/eez2016'
dir_layers <- '~/github/bhi/baltic2015'

## read in layers.csv 
l  <- readr::read_csv(file.path(dir_layers, 'layers.csv'))

## select and general cleanup
ld <- l %>%
  select(layer, targets, description) %>%
  arrange(layer) %>%
  mutate(description = 
           str_replace_all(description, c('"' = '',            ## remove quotes
                                          "â" = "'",         ## remove weird FAO character
                                          "ï¿" = "'" ))) %>%  ## remove weird AO character

## separate description column
  separate(description, 
           into = c('description', 'source'),
           sep = "Data sources:",
           extra = "merge") %>%

## clean up; separate source column into multiple sources
  mutate(source = 
           str_replace_all(source, c("\n- Feely" = "\n\n- Feely", ## clean up this one Feely reference
                                     "\n\n"      = ""))) %>%
  separate(source, 
           into = c('source1', 'source2', 'source3', 'source4', 'source5', 'source6', 'source7', 'source8', 'source9', 'source10'),
           sep  = c("\n-", "\n-", "\n-", "\n-", "\n-", "\n-", "\n-", "\n-", "\n-"), 
           extra = "merge") %>%

## separate 'source1'
   separate(source1, 
           into = c('source1', 'source_url1'),
           sep  = c("\\]\\("), 
           extra = "merge") %>%
  mutate(source1 = str_replace_all(source1, 
                                   c("\\- \\[" = "",       ## remove - and beginning of md link
                                     "\\- "    = "",       ## remove beginning of citation without md link
                                     "\\["    = "" )),     ## remove beginning of md link
         source_url1 = str_replace_all(source_url1, 
                                       c("\\)" = ""))) %>% ## remove end of md link


## separate 'source2'
   separate(source2, 
           into = c('source2', 'source_url2'),
           sep  = c("\\]\\("), 
           extra = "merge") %>%
  mutate(source2 = str_replace_all(source2, 
                                   c("\\- \\[" = "",        ## remove - and beginning of md link
                                     "\\- "    = "",        ## remove beginning of citation without md link
                                     "\\["    = "" )),      ## remove beginning of md link
         source_url2 = str_replace_all(source_url2, 
                                       c("\\)" = ""))) %>%  ## remove end of md link

##separate 'source3'
   separate(source3, 
           into = c('source3', 'source_url3'),
           sep  = c("\\]\\("), 
           extra = "merge") %>%
  mutate(source3 = str_replace_all(source3, 
                                   c("\\- \\[" = "",        ## remove - and beginning of md link
                                     "\\- "    = "",        ## remove beginning of citation without md link
                                     "\\["    = "" )),      ## remove beginning of md link
         source_url3 = str_replace_all(source_url3, 
                                       c("\\)" = ""))) %>%  ## remove end of md link

## add data prep url column
  mutate(data_prep_url = "") %>%


## tidyr::gather
  gather(field_name, field_info, -(1:2)) %>%
  arrange(targets, layer) %>%
  
## remove NAs
  filter(!is.na(field_info)) %>%

## save
  write_csv(file.path(dir_layers, 'layers_meta.csv'))

