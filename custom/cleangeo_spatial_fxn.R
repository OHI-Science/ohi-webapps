# cleangeo_spatial.r
# J. Lowndes @jules32, August 2015
# check for and clean any 'orphaned holes': http://gis.stackexchange.com/questions/113964/fixing-orphaned-holes-in-r
# ------------------

cleangeo_spatial <- function(sp_data) {
  
  # identify any issues in spatial sp_data ----
  library(rgdal)
  library(cleangeo) # devtools::install_github('eblondel/cleangeo')  # https://github.com/eblondel/cleangeo
  
  # find original CRS and transform if necessary
  p4s_wgs84 <- '+init=epsg:4326 +proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0'
  if(proj4string(sp_data) != p4s_wgs84) {
    # transforming from one CRS (Mercator which is in meters) to another (lat/long)
    sp_data <- spTransform(sp_data, CRS(p4s_wgs84))
  }
  
  cat('checking for orphan holes or invalid geometries...')
  
  #get a report of geometry validity & issues for a spatial object
  report  <- clgeo_CollectionReport(sp_data)
  summary <- clgeo_SummaryReport(report)
  issues  <- report[report$valid == FALSE, ]
  
  if(nrow(issues) > 0) {
    cat(sprintf('these are the issues pre-clean: \n %s \n\n', issues %>% select(warning_msg)))
    
    # to fix  
    cat('fixing any orphan holes or invalid geometries...')
    
    sp_data_clean <- clgeo_Clean(sp_data_tmp, print.log=T) # mybhi.clean_archive = mybhi.clean # save a copy
    report_clean  <- clgeo_CollectionReport(sp_data_clean)
    summary_clean <- clgeo_SummaryReport(report_clean)
    issues <- report_clean[report_clean$valid == FALSE,]
    cat(sprintf('these are the issues post-clean: \n %s \n\n', issues %>% select(warning_msg)))
  } else {
    cat('no invalid geometries...\n')
    sp_data_clean <- sp_data
  }
  
  return(sp_data_clean)
} 