## create_repo_map.r

create_repo_map <- function(key=key, dir_shp_in=dir_shp_in, dir_spatial=dir_spatial){ 
  
  ## load libraries quietly ----
  suppressWarnings(suppressPackageStartupMessages({
    library(dplyr)
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
  
  ## get map centroid and zoom level and save to separate map file----
  shp_bb    <- data.frame(shp@bbox) # max of 2.25
  shp_range <- dplyr::transmute(shp_bb, range = max - min)
  shp_ctr   <- rowMeans(shp_bb) 
  shp_zoom  <- 12 - as.integer(cut(max(shp_range), 
                                 breaks = c(0, 0.25, 0.5, 1, 2.5, 5, 10, 20, 40, 80, 160, 320, 360)))
  
  ## save as separate file...
  
  ## set map center and zoom level
  s = s %>%
    str_replace("map_lat.*", sprintf('map_lat=%g; map_lon=%g; map_zoom=%d', 
                                     shp_ctr['y'], shp_ctr['x'], shp_zoom)) # updated JSL to overwrite any map info
  
  ## use just rgn_labels (not rgn_global)
  s = gsub('rgn_global', 'rgn_labels', s)
  
  
}
