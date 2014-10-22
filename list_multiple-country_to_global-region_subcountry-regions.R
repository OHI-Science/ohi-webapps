setwd('~/github/ohi-webapps')
library(dplyr)

# vars
dir_neptune = '/Volumes/data_edit'
dir_github  = '~/github'
dir_global  = sprintf('%s/ohi-global/eez2014'   , dir_github)
dir_data    = sprintf('%s/git-annex/clip-n-ship', dir_neptune)
csv_out     = 'tmp/gl-rgn_multiple-cntry_sc-rgn.csv'
  
# get global (gl_*) data
gl_rgns    = read.csv(file.path(dir_global, 'layers/rgn_labels.csv'))
gl_cntries = read.csv(file.path(dir_global, 'layers/cntry_rgn.csv'))

# get list of global regions having more than one country lookup
d = gl_cntries %>%
  group_by(rgn_id) %>%
  mutate(
    n = n()) %>%
  filter(n > 1) %>%
  left_join(
    gl_rgns,
    by='rgn_id') %>%
  select(
    gl_rgn_id    = rgn_id,
    gl_rgn_name  = label,
    gl_cntry_key = cntry_key,
    gl_cntry_count = n) %>%
  ungroup()
d_cols = names(d)

# iterate through global regions, getting available subcountry regions
for (gl_rgn_n in unique(as.character(d$gl_rgn_name))){ # gl_rgn_n = unique(as.character(d$gl_rgn_name))[1]
  
  # get subcountry regions
  sc_rgns_offshore_csv = file.path(dir_data, gl_rgn_name, 'spatial', 'rgn_offshore_data.csv')
  sc_rgns_inland_shp   = file.path(dir_data, gl_rgn_name, 'spatial', 'rgn_inland_gcs.shp')
  
  if (file.exists(sc_rgns_offshore_csv)){
    
    # if offshore csv exists, shp should exist
    stopifnot(file.exists(sc_rgns_inland_shp))
    
    # get subcountry region names
    d_sc = read.csv(sc_rgns_offshore_csv) %>%
      select(
        sc_rgn_id   = rgn_id,
        sc_rgn_name = rgn_name) %>%
      mutate(
        gl_rgn_name = gl_rgn_n,
        sc_rgn_inland_shp = sc_rgns_inland_shp)
    
    # insert data
    d_gl_sc = d %>%
      select(one_of(d_cols)) %>%
      filter(gl_rgn_name == gl_rgn_n) %>%
      left_join(
        d_sc,
        by='gl_rgn_name')
    d = rbind_list(
      d %>%
        anti_join(
          d_gl_sc,
          by='gl_rgn_name'),
      d_gl_sc)
          
  }  
}

# write out csv of lookups
write.csv(d, csv_out)