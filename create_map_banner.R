# load libraries quietly
suppressWarnings(suppressPackageStartupMessages({
  library(sp)
  library(rgdal)
  library(raster)
  library(rgeos)
  library(dismo)
  library(ggplot2)
  library(ggmap) # devtools::install_github('dkahle/ggmap') # want 2.4 for stamen toner-lite
  library(dplyr)
  library(grid) # for unit
}))

# meta-paths
dir_neptune = '/Volumes/data_edit'
dir_github  = '~/github'

# paths and vars
dir_data  = file.path(dir_neptune, 'git-annex/clip-n-ship')
buffers   = c('offshore'=0.2, 'inland'=0.2, 'inland1km'=0.8, 'inland25km'=0.4, 'offshore3nm'=0.4, 'offshore1km'=0.8) # and transparency
  
# iterate through countries
cntries = list.files(dir_data)
for (Cntry in cntries){ # Cntry = 'Ecuador'

  # country vars
  i           = which(Cntry==cntries)
  dir_spatial = file.path(dir_data, Cntry, 'spatial')
  dir_pages   = file.path(dir_data, Cntry, 'gh-pages')
  png_map     = file.path(dir_pages, 'img/map.png')
  png_effect  = file.path(dir_pages, 'img/map_effect.png')
  
  # create output directory if don't exist
  dir.create(dirname(png_map), recursive=T, showWarnings=F)

  # read shapefiles  
  shps = setNames(sprintf('%s/rgn_%s_gcs', dir_spatial, names(buffers)), names(buffers))
  plys = lapply(shps, function(x) readOGR(dirname(x), basename(x)))
  
  # fortify and set rgn_names as factor of all inland rgns
  rgn_names = factor(plys[['inland']][['rgn_name']])
  plys.df = lapply(plys, function(x){
    x = fortify(x, region='rgn_name')
    x$id = factor(as.character(x$id), rgn_names)
    return(x)
  })
  ids_offshore = unique(plys.df[['offshore']][['id']])
  
  # get extent from inland and offshore, expanded 10%
  bb_inland25km = bbox(plys[['inland25km']])
  bb_offshore   = bbox(plys[['offshore']])
  x  = extendrange(c(bb_inland25km['x',], bb_offshore['x',]), f=0.1)
  y  = extendrange(c(bb_inland25km['y',], bb_offshore['y',]), f=0.1)
  
  # make bbox proportional to desired output image dimensions of 1600 x 800, ie 2 x 1
  if (diff(x) < 2 * diff(y)){
    x = c(-1, 1) * diff(y) + mean(x)
  } else {
    y = c(-1, 1) * diff(x)/2 + mean(y)
  }
  bb = c(x[1], y[1], x[2], y[2])
  
  # plot
  m = get_map(location=bb, source='stamen', maptype='toner-lite', crop=T)
  
  unlink(png_map)
  png(png_map, width=1600, height=800, res=150, type='cairo-png')
  ggmap(m, extent='device') + 
    # offshore
    geom_polygon(
      aes(x=long, y=lat, group=group, fill=id), alpha=buffers[['offshore']], 
      data=plys.df[['offshore']]) +
    # offshore3nm
    geom_polygon(
      aes(x=long, y=lat, group=group, fill=id), alpha=buffers[['offshore3nm']], 
      data=plys.df[['offshore3nm']]) +  
    # offshore1km
    geom_polygon(
      aes(x=long, y=lat, group=group, fill=id), alpha=buffers[['offshore1km']], 
      data=plys.df[['offshore1km']]) +  
    # inland
    geom_polygon(
      aes(x=long, y=lat, group=group, fill=id), alpha=buffers[['inland']], 
      data=subset(plys.df[['inland']], id %in% ids_offshore)) +  
    # inland25km
    geom_polygon(
      aes(x=long, y=lat, group=group, fill=id), alpha=buffers[['inland25km']], 
      data=subset(plys.df[['inland25km']], id %in% ids_offshore)) +  
    # inland1km
    geom_polygon(
      aes(x=long, y=lat, group=group, fill=id), alpha=buffers[['inland1km']], 
      data=subset(plys.df[['inland1km']], id %in% ids_offshore)) +
    # tweaks
    labs(fill='', xlab='', ylab='') + 
    theme(
      legend.position='none')
  #     legend.justification = c(1,0),   # anchor legend to max x, min y of graph
  #     legend.position      = c(1,0),   # from anchor position max x, min y
  #     legend.key.size      = unit(2.5, 'cm'),
  #     legend.text          = element_text(size = 20),
  #     axis.line            = element_line(color = NA))
  dev.off()
  system(sprintf('open %s', png_map))
  
  toycamera_options = '-i 5 -o 150 -d 5 -h -3 -t yellow -a 10 -I 0.75 -O 5'
  system(sprintf('./toycamera %s %s %s', toycamera_options, png_map, png_effect))
  system(sprintf('open %s', png_effect))
  
}