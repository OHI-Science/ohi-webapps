# prep_bhi.r
# create baltic repo. See Issue #407: https://github.com/OHI-Science/issues/issues/407


## setup ----

library(dplyr)
library(readr)
library(stringr)
library(rgdal)
library(raster)

setwd('~/github/ohi-webapps')



## 1. view map and accompanying data; save with ohi data frame ----

# read in shp files and save with desired headers in data frame
redo_shp = F 

if (redo_shp) {
  bhi = readOGR(dsn=file.path(dir_neptune, 'git-annex/clip-n-ship/bhi/spatial/custom/raw'),
                layer='Inters_BALTIC_EEZ_PLC1')
  plot(bhi) # see image below
  bhi@data # view data
  bhi@data = bhi@data %>%
    mutate(rgn_id = 1:25) %>%
    select(rgn_id,
           rgn_name,
           area_km2 = Area,
           cntry_name = Name,
           basin_name = SUBNAME)
  
  writeOGR(bhi, dsn = file.path(dir_neptune, 'git-annex/clip-n-ship/bhi/spatial/custom'), 
           layer = 'baltic_shp', driver = 'ESRI Shapefile')
  
  # create lookup table with unique rgn_ids
  bhi_sc = read_csv('custom/sc_studies_custom.csv'); head(bhi_sc)
  
  baltic_rgns = bhi@data %>%
    left_join(bhi_sc %>%
                select(sc_key, 
                       cntry_name = gl_rgn_name, 
                       gl_rgn_key), 
              by='cntry_name') %>%
    mutate(baltic_rgn_key = tolower(gl_rgn_key)) %>%
    select(-gl_rgn_key) %>%
    group_by(cntry_name) %>%
    mutate(sc_id = 1:n()); head(baltic_rgns)
  
  write_csv(baltic_rgns, 'custom/bhi/baltic_rgns_to_bhi_rgns_lookup.csv')
  
}


## 2. add all Baltic countries to sc_studies_custom.csv by hand ----


## 3. create directories in github/clip-n-ship ----
ind_bhi = str_detect(sc_custom$sc_key, 'bhi')
bhi_rgn = sc_custom$sc_key[ind_bhi] # bhi_rgn = c("bhi-swe", "bhi-fin", "bhi-dnk", "bhi-deu", "bhi-est", "bhi-pol", "bhi-rus", "bhi-lva", "bhi-ltu")

sapply(sprintf('~/github/clip-n-ship/%s', bhi_rgn), dir.create)


## 4. create directories in git-annex/clip-n-ship and copy required files for populate_draft_branch() ----

redo_bhi_dirs = F

if (redo_bhi_dirs) {
  # first create the directories
  sapply(sprintf(file.path(dir_neptune, 'git-annex/clip-n-ship/%s'), bhi_rgn), dir.create)
  sapply(sprintf(file.path(dir_neptune, 'git-annex/clip-n-ship/%s/spatial'), bhi_rgn), dir.create)
  sapply(sprintf(file.path(dir_neptune, 'git-annex/clip-n-ship/%s/layers'), bhi_rgn), dir.create)
  
  # for each bhi_rgn
  for (b in bhi_rgn) { # b = 'bhi-rus'
    
    # copy the spatial files
    dir_in  = sprintf(file.path(dir_neptune, 'git-annex/clip-n-ship/%s/spatial'), str_replace(b, 'bhi-', ''))
    dir_out = sprintf(file.path(dir_neptune, 'git-annex/clip-n-ship/%s/spatial'), b)
    
    f_gcs = extension(list.files(dir_in, pattern = 'rgn_offshore_gcs'))
    
    for (f in f_gcs) {
      file.copy(sprintf(file.path(dir_neptune, 'git-annex/clip-n-ship/%s/spatial/rgn_offshore_gcs%s'), str_replace(b, 'bhi-', ''), f),
                sprintf(file.path(dir_neptune, 'git-annex/clip-n-ship/%s/spatial/rgn_offshore_gcs%s'), b, f), overwrite=T)
    }
    
    # copy rgn_offshore_data.csv
    file.copy(sprintf(file.path(dir_neptune, 'git-annex/clip-n-ship/%s/spatial/rgn_offshore_data.csv'), str_replace(b, 'bhi-', '')),
              sprintf(file.path(dir_neptune, 'git-annex/clip-n-ship/%s/spatial/rgn_offshore_data.csv'), b), overwrite=T)
    
    # copy mar_coastalpopn_inland25km_lyr.csv
    file.copy(sprintf(file.path(dir_neptune, 'git-annex/clip-n-ship/%s/layers/mar_coastalpopn_inland25km_lyr.csv'), str_replace(b, 'bhi-', '')),
              sprintf(file.path(dir_neptune, 'git-annex/clip-n-ship/%s/layers/mar_coastalpopn_inland25km_lyr.csv'), b), overwrite=T)
    
  }
  
  # this was close but not quite. for loop instead, above.
  # bhi_rgn_orig = str_replace_all(bhi_rgn, 'bhi-', '')
  # sapply(sprintf(file.path(dir_neptune, 'git-annex/clip-n-ship/%s/spatial/rgn_offshore_gcs.shp'), bhi_rgn_orig),
  #        sprintf(file.path(dir_neptune, 'git-annex/clip-n-ship/%s/spatial/rgn_offshore_gcs.shp'), bhi_rgn),
  #        file.copy)
  
}

## 5. run create.r through populate_draft_branch() ----
# note: problems with create_gh_repo; must set `repo_exists = F`


## 6. create bhi repo ----

dir_bhi = file.path(dir_repos, 'bhi')

# file.copy(list.dirs(file.path(dir_repos, 'bhi-deu')), # Apr 17 this was giving an error; I copied by hand
#           dir_bhi) 

# rename .Rproj
file.rename(file.path(dir_bhi, 'bhi-deu.Rproj'),
            file.path(dir_bhi, 'bhi.Rproj'))

# rename scenario folder
# by hand for the moment


## 7. bind possible layers for each bhi-xxx ----

setwd('~/github/ohi-webapps')

# read in lookup table
lkp_baltic = read_csv('~/github/ohi-webapps/custom/bhi/baltic_rgns_to_bhi_rgns_lookup.csv'); lkp_baltic

# list all layers in b
lyrs_list = list.files(file.path(dir_repos, 'bhi/baltic2015/layers'), glob2rx('*.csv'), full.names=T) 
# hack: cannot handle 2 layers; removed them from the layers folder and dealt with them separately
# lsp_prot_area_inland1km_gl2014.csv
# lsp_prot_area_offshore3nm_gl2014.csv

for (f in lyrs_list){ # f = "~/github/clip-n-ship/bhi/baltic2015/layers/ao_access_gl2014.csv" 
  
  # read in layer, save names, delete all but headers (a bit hacky this way)
  lyr_tmp = read_csv(f)
  lyr_col = names(lyr_tmp)
  
  # only works for rgn_ids; FIS layers different
  if ('rgn_id' %in% lyr_col){
    
    # delete all data in layer
    lyr_bind = lyr_tmp %>%
      filter(rgn_id == 0)
    
    
    # for every b repo in bhi_rgn list
    for (b in bhi_rgn) { # b = 'bhi-deu'  # could rename this as key (confusing?)
      
      key = b
      source('create_init_sc.r')
      
      # read in b's layer
      s = read_csv(file.path(dir_repo, default_scenario, 'layers', basename(f)))
      
      # make sure classes are correct; was a problem for ico_spp_extinction_status_gl2014.csv. 
      # See http://stackoverflow.com/questions/27361081/r-assign-or-copy-column-classes-from-a-data-frame-to-another
      s[] = mapply(FUN = as, s, sapply(lyr_tmp, class), SIMPLIFY=F)
      
      # filter baltic lookp for b
      lkp_b = lkp_baltic %>%
        filter(sc_key == b)
      
      # join lookup with layer and select original columns using non-standard evaluation, ie dplyr::*_()
      t = s %>%
        rename(sc_id = rgn_id) %>%
        right_join(lkp_b, by='sc_id') %>%
        select_(.dots = lyr_col)
      
      # bind all together
      lyr_bind = bind_rows(lyr_bind, t)  
      
    }
    
    # save file
    lyr_save = lyr_bind %>%
      arrange(rgn_id)
    
    write_csv(lyr_save, f)
    
  } else {
    print(f)
    # "/Users/jstewart/github/clip-n-ship/bhi/baltic2015/layers/fis_b_bmsy_gl2014.csv"
    # "/Users/jstewart/github/clip-n-ship/bhi/baltic2015/layers/fis_meancatch_gl2014.csv"
    # "/Users/jstewart/github/clip-n-ship/bhi/baltic2015/layers/mar_harvest_species_gl2014.csv"
  }
}
# These errors with MAR: I had to also move them temporarily out of the folder, although they seemed to have processed
# In addition: Warning messages:
# 1: 15 problems parsing '~/github/clip-n-ship/bhi-pol/region2015/layers/mar_harvest_tonnes_gl2014.csv'. See problems(...) for more details. 
# 2: 10 problems parsing '~/github/clip-n-ship/bhi-lva/region2015/layers/mar_harvest_tonnes_gl2014.csv'. See problems(...) for more details. 
# 3: 5 problems parsing '~/github/clip-n-ship/bhi-ltu/region2015/layers/mar_harvest_tonnes_gl2014.csv'. See problems(...) for more details. 

 
## handle several layers individually ----

redo_lyrs_individually = F
if (redo_lyrs_individually) {
  
  # recreate rgn_global_gl2014.csv
  tmp = lkp_baltic %>%
    select(rgn_id, 
           label = rgn_name)
  write_csv(tmp, file.path(dir_repos, 'bhi/baltic2015/layers/rgn_global_gl2014.csv'))
  
  # recreate rgn_labels.csv 
  tmp = lkp_baltic %>%
    mutate(type = 'eez') %>%
    select(rgn_id, type, 
           label = rgn_name)
  write_csv(tmp, file.path(dir_repos, 'bhi/baltic2015/layers/rgn_labels.csv'))
  
  # recreate rgn_area_sc2014-area.csv
  tmp = lkp_baltic %>%
    select(rgn_id, rgn_name, area_km2)
  write_csv(tmp, file.path(dir_repos, 'bhi/baltic2015/layers/rgn_area_sc2014-area.csv'))
  
  # recreate rgn_area_inland1km_gl2014.csv and rgn_area_offshore3nm_gl2014.csv
  tmp = lkp_baltic %>%
    select(rgn_id) %>%
    mutate(area_km2 = 5) # placeholder
  write_csv(tmp, file.path(dir_repos, 'bhi/baltic2015/layers/rgn_area_inland1km_gl2014.csv'))
  write_csv(tmp, file.path(dir_repos, 'bhi/baltic2015/layers/rgn_area_offshore3nm_gl2014.csv'))
  
  # recreate lsp_prot_area_inland1km_gl2014.csv and lsp_prot_area_offshore3nm_gl2014.csv
  # weird errors with not being able to see areakm2: Error in eval(expr, envir, enclos) : object 'area_km2' not found 
  tmp = read_csv(file.path(dir_repos, 'bhi/baltic2015/layers/mar_coastalpopn_inland25km_sc2014-raster.csv')) %>%
    mutate(area_km2 = 10) %>% # placeholder; NA caused errors
    select(-popsum)
  write_csv(tmp, file.path(dir_repos, 'bhi/baltic2015/layers/lsp_prot_area_inland1km_gl2014.csv'))
  write_csv(tmp, file.path(dir_repos, 'bhi/baltic2015/layers/lsp_prot_area_offshore3nm_gl2014.csv'))
  ## !!! BB came upon this too, from populate_draft_branch:  if (class(a[[fld_value]]) %in% c('factor','character')){
#       cat(sprintf('  DOH! For empty layer "%s" field "%s" is factor/character but continuing with presumption of numeric.\n', lyr, fld_value))
#     }
#   

# recreate rgn_georegions_gl2014.csv very hacky 
 tmp = read_csv(file.path(dir_repos, 'bhi/baltic2015/layers/rgn_georegions_gl2014.csv')) %>%
  select(-rgn_id) %>%
  distinct()
tmp2 = bind_rows(
  data.frame(rgn_id = 1:25) %>%
    mutate(level = tmp$level[1]) %>%
    mutate(georgn_id = tmp$georgn_id[1]), 
  data.frame(rgn_id = 1:25) %>%
    mutate(level = tmp$level[2]) %>%
    mutate(georgn_id = tmp$georgn_id[2]),
  data.frame(rgn_id = 1:25) %>%
    mutate(level = tmp$level[3]) %>%
    mutate(georgn_id = tmp$georgn_id[3]))
write_csv(tmp2, file.path(dir_repos, 'bhi/baltic2015/layers/rgn_georegions_gl2014.csv'))

# recreate rgn_georegion_labels_gl2014.csv
tmp = read_csv(file.path(dir_repos, 'bhi/baltic2015/layers/rgn_georegion_labels_gl2014.csv')) %>%
  select(-rgn_id) %>%
  distinct()
tmp2 = bind_rows(
  data.frame(rgn_id = 1:25) %>%
    mutate(level = tmp$level[1]) %>%
    mutate(label = tmp$label[1]), 
  data.frame(rgn_id = 1:25) %>%
    mutate(level = tmp$level[2]) %>%
    mutate(label = tmp$label[2]),
  data.frame(rgn_id = 1:25) %>%
    mutate(level = tmp$level[3]) %>%
    mutate(label = tmp$label[3]))
write_csv(tmp2, file.path(dir_repos, 'bhi/baltic2015/layers/rgn_georegion_labels_gl2014.csv'))

}
## 6. proceed create_all.r ----
# first copy whole bhi directory to a tmp location because it will be overwritten
# I copied by hand but this should be scripted!!!

keys_redo = 'bhi'
key = keys_redo[1]

# populate_draft branch



# in custom_maps.r, uncomment key = bhi



# make a temporary resilience placeholder file since errors with calculating resilince
a = read_csv('~/github/ohi-global/eez2014/scores.csv') %>%
  filter(dimension == 'resilience', 
         region_id < 26 & region_id != 0) %>%
  mutate(score = 70)
write_csv(a, '~/github/ohi-webapps/custom/bhi/resilience_scores_baltic_placeholder.csv') 


# plot(bhi) # see image below
# balt# view data
#
