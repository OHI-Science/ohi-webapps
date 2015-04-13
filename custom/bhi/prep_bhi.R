# prep_bhi.r
# create baltic repo

library(dplyr)
library(readr)
library(stringr)

dir_neptune <- c(
  'Windows' = '//neptune.nceas.ucsb.edu/data_edit',
  'Darwin'  = '/Volumes/data_edit',
  'Linux'   = '/var/data/ohi')[[ Sys.info()[['sysname']] ]]

setwd('~/github/ohi-webapps')

## 1. add all Baltic countries to sc_studies_custom.csv by hand ----

## 2. create directories in github/clip-n-ship ----
sc_tmp = read_csv('custom/sc_studies_custom.csv'); head(sc_tmp)
ind_bhi = str_detect(sc_tmp$sc_key, 'bhi')
bhi_rgn = sc_tmp$sc_key[ind_bhi] # bhi_rgn = c("bhi-swe", "bhi-fin", "bhi-dnk", "bhi-deu", "bhi-est", "bhi-pol", "bhi-lva", "bhi-ltu")

sapply(sprintf('~/github/clip-n-ship/%s', bhi_rgn), dir.create)


## 3. create directories in git-annex/clip-n-ship and copy required files for populate_draft_branch() ----

# first create the directories
sapply(sprintf(file.path(dir_neptune, 'git-annex/clip-n-ship/%s'), bhi_rgn), dir.create)
sapply(sprintf(file.path(dir_neptune, 'git-annex/clip-n-ship/%s/spatial'), bhi_rgn), dir.create)
sapply(sprintf(file.path(dir_neptune, 'git-annex/clip-n-ship/%s/layers'), bhi_rgn), dir.create)

# for each bhi_rgn
for (b in bhi_rgn) {

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

## 4. ----
# set unique regions and rbind






## 5. run create_all.r ----
keys_redo = bhi_rgn
key = keys_redo[1]

# in custom_maps.r, uncomment key = bhi






## view map and accompanying data ----

library(rgdal)
dir_neptune <- c(
  'Windows' = '//neptune.nceas.ucsb.edu/data_edit',
  'Darwin'  = '/Volumes/data_edit',
  'Linux'   = '/var/data/ohi')[[ Sys.info()[['sysname']] ]]


orig = readOGR(dsn=file.path(dir_neptune, 'git-annex/clip-n-ship/bhi/spatial/custom/raw'),
              layer='Inters_BALTIC_EEZ_PLC1')

bhi = readOGR(dsn=file.path(dir_neptune, 'git-annex/clip-n-ship/bhi/spatial/custom/raw'),
              layer='Inters_BALTIC_EEZ_PLC1')
plot(bhi) # see image below
bhi@data # view data
# bhi@data = bhi@data %>%
#     mutate(rgn_id = 1:25) %>%
#     select(rgn_id,
#            rgn_name,
#            area_km2 = Area,
#            cntry_name = Name,
#            basin_name = SUBNAME)
#

write_csv(bhi@data )

writeOGR(bhi, dsn = file.path(dir_neptune, 'git-annex/clip-n-ship/bhi/spatial/custom'), layer = 'baltic_shp', driver = 'ESRI Shapefile')


x = readOGR(dsn=file.path(dir_neptune, 'git-annex/clip-n-ship/bhi/spatial/custom'),
              layer='baltic_shp')

# plot(bhi) # see image below
# balt# view data
#
