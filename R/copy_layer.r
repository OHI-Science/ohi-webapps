## copy_layer.r
## extracted from create_functions.r - populate_draft_branch(); make its own function.
# https://github.com/OHI-Science/ohi-webapps/blob/26054a43d118a50c275ed75da41430147ab35d0e/create_functions.R#L487-L554

copy_layer <- function(lyr, sc_rgns,
                       dir_global, sfx_global,
                       lyrs_sc, write_to_csv = TRUE){ 
  
  ## setup
  csv_in        <- sprintf('%s/layers/%s.csv', dir_global, lyr)
  global_rgn_id <-  unique(sc_rgns$gl_rgn_id)
  
  d = read.csv(csv_in) 
  flds = names(d)
  
  if ('rgn_id' %in% names(d)){
    d = d %>%
      filter(rgn_id %in% global_rgn_id) %>%
      merge(sc_rgns, by.x = 'rgn_id', by.y = 'gl_rgn_id') %>%
      mutate(rgn_id = as.integer(sc_rgn_id)) %>%
      subset(select = flds) %>%
      arrange(rgn_id)
  }
  
  if ('cntry_key' %in% names(d)){
    # convert cntry_key to rgn_id, drop cntry_key
    d = d %>%
      mutate(cntry_key = as.character(cntry_key)) %>%
      inner_join(
        sc_rgns %>%
          mutate(cntry_key = as.character(cntry_key)),
        by='cntry_key') %>%
      dplyr::rename(rgn_id=sc_rgn_id) %>%
      select_(.dots = as.list(c('rgn_id', setdiff(names(d), 'cntry_key')))) %>%
      arrange(rgn_id)
  }
  
  ## update rgn_labels
  if (lyr =='rgn_labels'){
    csv_out = sprintf('%s/layers/rgn_labels.csv', dir_scenario)
    lyrs_sc$filename[lyrs_sc$layer == lyr] = basename(csv_out)
    d <- d %>%
      merge(sc_rgns, by.x='rgn_id', by.y='sc_rgn_id') %>%
      select(rgn_id, type, label=sc_rgn_name) %>%
      arrange(rgn_id)
  }
  
  ## update rgn_global csv name
  if (lyr =='rgn_global'){
    csv_out = sprintf('%s/layers/rgn_global.csv', dir_scenario)
    lyrs_sc$filename[lyrs_sc$layer == lyr] = basename(csv_out)
  }
  
  ## TODO: comment out for now; see if this is actually happening. 
  ## downweight: area_offshore, equal, equal, population_inland25km,
  # shp = '/Volumes/data_edit/git-annex/clip-n-ship/data/Albania/rgn_inland25km_mol.shp'
  # downweight = str_trim(lyrs_sc$clip_n_ship_disag[lyrs_sc$layer == lyr])
  # downweightings = c('area_offshore'='area-offshore', 'population_inland25km'='popn-inland25km')
  # if (downweight %in% names(downweightings) & nrow(d) > 0){
  #   
  #   ## update data frame with downweighting
  #   i.v  = ncol(d) # assume value in right most column
  #   #if (downweight=='population_inland25km') browser()
  #   d = inner_join(d, get(downweight), by='rgn_id')
  #   i.dw = ncol(d) # assume downweight in right most column after join
  #   d[i.v] = d[i.v] * d[i.dw]
  #   d = d[,-i.dw]
  #   
  #   ## update layer filename to reflect downweighting
  #   csv_out = file.path(
  #     'layers',
  #     str_replace(
  #       lyrs_sc$filename[lyrs_sc$layer == lyr],
  #       fixed('_gl2016.csv'), 
  #       sprintf('_sc2014-%s.csv', downweightings[downweight])))
  #   lyrs_sc$filename[lyrs_sc$layer == lyr] = basename(csv_out)
  # }
  
  ## fill with placeholder data if d is empty ----
  if (nrow(d) < 1) { 
    
    ## create layer full of NAs
    dtmp <- sc_rgns %>%
      select(sc_rgn_id) %>%
      bind_rows(d) %>%
      select(-rgn_id) %>%
      rename(rgn_id = sc_rgn_id)
    
    ## fill 0 as placeholder for pressures and resilience
    if (any(names(dtmp) %in% c('pressures.score', 'pressure_score', 'resilience.score'))) {
      dtmp[is.na(dtmp)] <- as.integer(0)
    }
    
    ## fill 'cf' as placeholder for LIV/ECO
    if ('sector' %in% names(dtmp)) {
      dtmp$sector[is.na(dtmp$sector)] <- 'cf'
    }
    
    ## fill 'seagrass' as placeholder for HAB
    if ('habitat' %in% names(dtmp)) {
      dtmp$habitat[is.na(dtmp$habitat)] <- 'seagrass'
    }
    
    ## fill global year as placeholder for year
    if ('year' %in% names(dtmp)) {
      dtmp$year <- as.integer(stringr::str_extract(dir_global, "\\d{4}"))
    }
    
    ## fill global year as placeholder for any others
    dtmp[is.na(dtmp)] <- as.integer(stringr::str_extract(dir_global, "\\d{4}"))
    
    ## replace d with dtmp
    d <- dtmp
    
    ## rename layername
    placeholder_csv <- stringr::str_replace(lyrs_sc$filename[lyrs_sc$layer == lyr], '\\.', 'placeholder.')
    lyrs_sc$filename[lyrs_sc$layer == lyr] = placeholder_csv
    
  }

  ## create csv_out (with or without placeholder added)
  csv_out <- sprintf('%s/layers/%s', dir_scenario, lyrs_sc$filename[lyrs_sc$layer == lyr])
  
  d$rgn_id <- as.integer(d$rgn_id)
  
  ## write to csv if TRUE
  if (write_to_csv) {
    
    write_csv(d, csv_out, na='')
    return(csv_out)
    
  } else {
    
    ## TODO needs to return csv_out and d as a list
    return(csv_out)
  }
}
