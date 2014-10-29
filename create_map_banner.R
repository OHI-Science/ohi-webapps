# load libraries quietly
suppressWarnings(suppressPackageStartupMessages({
  library(sp)
  library(rgdal)
  library(raster)
  library(rgeos)
  library(dismo)
  library(ggplot2)
  library(ggmap)
  library(dplyr)
}))

# meta-paths
dir_neptune = '/Volumes/data_edit'
dir_github  = '~/github'

# paths and vars
dir_data  = file.path(dir_neptune, 'git-annex/clip-n-ship')
buffers   = c('offshore'=0.5, 'inland'=0.5, 'inland1km'=0.5, 'inland25km'=0.5, 'offshore3nm'=0.5, 'offshore1km'=0.5) # and transparency

  
# iterate through countries
cntries = list.files(dir_data)
for (Cntry in cntries){ # Cntry     = 'Ecuador'

  # country vars
  i           = which(Cntry==cntries)
  dir_spatial = file.path(dir_data, Cntry, 'spatial')
  dir_pages   = file.path(dir_data, Cntry, 'gh-pages')
  png_map     = file.path(dir_pages, 'img/map.png')
  png_banner  = file.path(dir_pages, 'img/banner.png')
  
  # create output directory if don't exist
  dir.create(dirname(png_map), recursive=T, showWarnings=F)

  # read shapefiles  
  shps = setNames(sprintf('%s/rgn_%s_gcs', dir_spatial, names(buffers)), names(buffers))
  plys = lapply(shps, function(x) readOGR(dirname(x), basename(x)))
  
  # get first two buffers, inland and offshore, for extent
  
  bbox(plys[['inland']])
  bbox(plys[['offshore']])
  
  for (j in 1:2){
    
    # get bounding box extent, with extended range
    x = extendrange(bbox(ply_abs)['x',], f=0.25)
    y = extendrange(bbox(ply_abs)['y',], f=0.25)
    bb = c(x[1], y[1], x[2], y[2])
    
    
      
  }
  
  buf = 'offshore'

  
  
  pts_sp = readOGR(dirname(shp_presence), basename(shp_presence))
  
  
# prep data for plotting with ggplot2
xy_sp  = as.data.frame(coordinates(pts_sp))
xy_abs = as.data.frame(coordinates(pts_abs))
names(xy_sp)  = c('lon','lat')
names(xy_abs) = c('lon','lat')
ply_abs@data$id = rownames(ply_abs@data)
ply_abs.points  = fortify(ply_abs, region='id')
ply_abs.df      = inner_join(ply_abs.points, ply_abs@data, by='id')

# get bounding box extent, with extended range
x = extendrange(bbox(ply_abs)['x',], f=0.25)
y = extendrange(bbox(ply_abs)['y',], f=0.25)
bb = c(x[1], y[1], x[2], y[2])

# get map
m = suppressWarnings(get_map(location=bb, source='google', maptype='terrain', crop=T))

# plot
png(map_png, width=1000, height=800, res=72)
ggmap(m, extent='device', darken=c(0.4,'white')) + 
  geom_point(
    data=xy_sp, aes(x=lon, y=lat), color='darkgreen', alpha=0.5) +
  geom_polygon(
    data=ply_abs.df, aes(x=long, y=lat, group=group), color='darkblue', fill=NA) +
  geom_point(
    data=xy_abs, aes(x=lon, y=lat), color='red', alpha=0.5)
dev.off()