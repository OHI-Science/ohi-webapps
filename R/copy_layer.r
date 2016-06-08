## copy_layer.r
## extracted from create_functions.r - populate_draft_branch(); make its own function.
# for (j in 1:nrow(lyrs_sc)){ .... ~L473

copy_layer <- function(lyr, 
                       global_rgn_id = sc_rgns$gl_rgn_id, 
                       write_to_csv  = TRUE){ #  j=14; lyr = lyrs_sc$layer[j]
  
  rgns_in = lyrs_sc$rgns_in[lyrs_sc$layer == lyr]
  csv_in  = lyrs_sc$path_in[lyrs_sc$layer == lyr]
  csv_out = sprintf('layers/%s', lyrs_sc$filename[lyrs_sc$layer == lyr])
  
  d = read_csv(csv_in)
  flds = names(d)
  
  ## TODO: if (sc_rgns$gl_rgn_id is all NAs) -- need to use placeholder information
  # head(sc_rgns)
  # sc_rgn_id    sc_rgn_name gl_rgn_name gl_rgn_id
  # 1         1         Alaska      Arctic        NA
  # 2         3   Beaufort Sea      Arctic        NA
  # 3         9 East Greenland      Arctic        NA
  # 4         7      Jan Mayen      Arctic        NA
  # 5         6         Norway      Arctic        NA
  # 6         2        Nunavut      Arctic        NA
  
  if (rgns_in == 'global'){
    
    if ('rgn_id' %in% names(d)){
      d = d %>%
        filter(rgn_id %in% global_rgn_id) %>%
        merge(sc_rgns, by.x='rgn_id', by.y='gl_rgn_id') %>%
        mutate(rgn_id=sc_rgn_id) %>%
        subset(select=flds) %>%
        arrange(rgn_id)
    }
    
    if ('cntry_key' %in% names(d)){
      # convert cntry_key to rgn_id, drop cntry_key
      d = d %>%
        inner_join(
          sc_cntry,
          by='cntry_key') %>%
        dplyr::rename(rgn_id=sc_rgn_id) %>%
        select_(.dots = as.list(c('rgn_id', setdiff(names(d), 'cntry_key')))) %>%
        arrange(rgn_id)
    }
    
    if (lyrs_sc$layer[lyrs_sc$layer == lyr] =='rgn_labels'){
      csv_out = 'layers/rgn_labels.csv'
      lyrs_sc$filename[lyrs_sc$layer == lyr] = basename(csv_out)
      d = d %>%
        merge(sc_rgns, by.x='rgn_id', by.y='sc_rgn_id') %>%
        select(rgn_id, type, label=sc_rgn_name) %>%
        arrange(rgn_id)
    }
    
    ## downweight: area_offshore, equal, equal , population_inland25km,
    # shp = '/Volumes/data_edit/git-annex/clip-n-ship/data/Albania/rgn_inland25km_mol.shp'
    downweight = str_trim(lyrs_sc$clip_n_ship_disag[lyrs_sc$layer == lyr])
    downweightings = c('area_offshore'='area-offshore', 'population_inland25km'='popn-inland25km')
    if (downweight %in% names(downweightings) & nrow(d) > 0){
      
      ## update data frame with downweighting
      i.v  = ncol(d) # assume value in right most column
      #if (downweight=='population_inland25km') browser()
      d = inner_join(d, get(downweight), by='rgn_id')
      i.dw = ncol(d) # assume downweight in right most column after join
      d[i.v] = d[i.v] * d[i.dw]
      d = d[,-i.dw]
      
      ## update layer filename to reflect downweighting
      csv_out = file.path(
        'layers',
        str_replace(
          lyrs_sc$filename[lyrs_sc$layer == lyr],
          fixed('_gl2016.csv'), ## TODO: no hardcoding here
          sprintf('_sc2014-%s.csv', downweightings[downweight])))
      lyrs_sc$filename[lyrs_sc$layer == lyr] = basename(csv_out)
    }
  }
  ## write to csv if TRUE
  if (write_to_csv) {
    write_csv(d, csv_out, na='')
  } else { 
    return(d)
  }
}
