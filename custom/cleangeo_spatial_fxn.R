# cleangeo_spatial.r
# J. Lowndes @jules32, August 2015
# check for and clean any 'orphaned holes': http://gis.stackexchange.com/questions/113964/fixing-orphaned-holes-in-r
# ------------------

cleangeo_spatial <- function(sp_data) {
  
  # identify any issues in spatial sp_data ----
  library(rgdal)
  library(cleangeo) # devtools::install_github('eblondel/cleangeo')  # https://github.com/eblondel/cleangeo
  
  cat('checking for orphan holes or invalid geometries...\n')
  
  #get a report of geometry validity & issues for a spatial object
  report <- clgeo_CollectionReport(sp_data)
  issues <- report[report$valid == FALSE,]
  cat(sprintf('these are the issues pre-clean: \n %s \n\n', issues %>% dplyr::select(warning_msg)))
  
  
  if(nrow(issues) > 0) {
    # fix identify any issues in spatial sp_data ----
    cat('fixing any orphan holes or invalid geometries...\n')
    sp_data_clean <- clgeo_Clean(sp_data, print.log = T) 
    report_clean  <- clgeo_CollectionReport(sp_data_clean)
    issues <- report_clean[report_clean$valid == FALSE,]
    cat(sprintf('these are the issues post-clean: \n %s \n\n', issues %>% dplyr::select(warning_msg)))
  } else {
    sp_data_clean <- sp_data
    cat('no invalid geometries. \n')
  }
  
  return(sp_data_clean)
} 