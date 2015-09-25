# cleangeo_spatial.r
# J. Lowndes @jules32, August 2015
# check for and clean any 'orphaned holes': http://gis.stackexchange.com/questions/113964/fixing-orphaned-holes-in-r
# ------------------

cleangeo_spatial = function(sp_data) {
  
  # identify any issues in spatial sp_data ----
  library(rgdal)
  library(raster)
  library(cleangeo) # devtools::install_github('eblondel/cleangeo')  # https://github.com/eblondel/cleangeo
  
  cat('checking for orphan holes or invalid geometries...\n')
  
  #get a report of geometry validity & issues for a spatial object
  report = clgeo_CollectionReport(sp_data)
  summary = clgeo_SummaryReport(report)
  issues = report[report$valid == FALSE,]
  cat(sprintf('these are the issues pre-clean: \n %s \n\n', issues %>% select(warning_msg)))
  
  # fix identify any issues in spatial sp_data ----
  cat('fixing any orphan holes or invalid geometries...\n')
  
  sp_data_tmp = sp_data
  sp_data_clean = clgeo_Clean(sp_data_tmp, print.log=T) 
  report_clean = clgeo_CollectionReport(sp_data_clean)
  summary_clean = clgeo_SummaryReport(report_clean)
  issues = report_clean[report_clean$valid == FALSE,]
  cat(sprintf('these are the issues post-clean: \n %s \n\n', issues %>% select(warning_msg)))
  
  return(sp_data_clean)
} 