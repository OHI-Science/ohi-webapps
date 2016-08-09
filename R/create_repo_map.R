## create_repo_map.r

create_repo_map <- function(key=key, dir_shp_in=dir_shp_in, dir_spatial=dir_spatial){ 
  
  ## load libraries quietly ----
  suppressWarnings(suppressPackageStartupMessages({
    library(sp)
    library(rgdal)
    library(tools)
  }))
  
  ## process shapefiles; ensure projection and rename ----
  shp_name = tools::file_path_sans_ext(list.files(dir_shp_in))[1]
  shp_orig = rgdal::readOGR(dsn=dir_shp_in, layer=shp_name) 
  crs = sp::CRS("+proj=longlat +datum=WGS84")
  shp = sp::spTransform(shp_orig,crs) 
  rgdal::writeOGR(shp, dsn=dir_spatial, 'rgn_offshore_gcs', driver='ESRI Shapefile', overwrite=TRUE)
  
  
  ## geojson files ----
  
  ## create regions_gcs.geojson and regions_gcs.js in git annex
  f_js      = file.path(dir_annex_sc, 'spatial', 'regions_gcs.js')
  f_geojson = file.path(dir_annex_sc, 'spatial', 'regions_gcs.geojson')
  f_shp     = file.path(dir_annex_sc, 'spatial', 'rgn_offshore_gcs.shp')
  
  cat(sprintf('  creating geojson file with ohirepos::shp_to_geojson -- %s\n', format(Sys.time(), '%X')))
  shp_to_geojson(f_shp, f_js, f_geojson) # TODO: preappend ohirepos::
  
  ## copy geojson files to repo
  for (f in c(f_js, f_geojson)){ # f = f_js
    file.copy(from = f, 
              to   = sprintf('%s/%s/spatial/%s', dir_repo, default_scenario, basename(f)), overwrite=T)
    cat(sprintf('\n copying from %s', f))
  }
  
  # and save the info from config.r here 
  
}
