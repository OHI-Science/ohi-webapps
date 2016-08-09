## create_repo_map.r

create_repo_map <- function(key=key, dir_shp_in=dir_shp_in, dir_spatial=dir_spatial){ 
  
  ## load libraries quietly
  suppressWarnings(suppressPackageStartupMessages({
    # library(sp)
    library(rgdal)
    library(tools)
  }))
  
  ## process shapefiles: rename headers and save in dir_spatial
  shp_name = tools::file_path_sans_ext(list.files(dir_shp_in))[1]
  shp_orig = rgdal::readOGR(dir_shp_in, shp_name) 
  crs = rgdal::CRS("+proj=longlat +datum=WGS84")
  shp = rgdal::spTransform(shp_orig,crs) 
  rgdal::writeOGR(shp, dsn=dir_spatial, 'rgn_offshore_gcs', driver='ESRI Shapefile', overwrite=TRUE)
  
  # TODO: add the geojson making here from populate_draft_branch(), 
  # and save the info from config.r here 
  
}
