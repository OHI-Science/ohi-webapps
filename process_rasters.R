library(raster)
library(dplyr)

# set temporary directory to folder on neptune disk big enough to handle it
tmpdir='~/big/R_raster_tmp'
dir.create(tmpdir, showWarnings=F)
rasterOptions(tmpdir=tmpdir)

# get paths based on host machine, now on neptune
dirs = list(
  neptune_data  = '/var/data/ohi', 
  github        = '~/github')

dir_data    = sprintf('%s/git-annex/clip-n-ship', dirs['neptune_data']) # 'N:/git-annex/clip-n-ship/data'
dir_repos   = sprintf('%s/clip-n-ship', dirs['github'])
dir_ohicore = sprintf('%s/ohicore', dirs['github'])
dir_global  = sprintf('%s/ohi-global/eez2014', dirs['github'])

# get list of countries with prepped data
cntries = list.files(dir_data)

# loop through countries
for (i in 1:length(cntries)){ # cntry = 'Albania'  
  
  # setup vars
  cntry = cntries[i]
  cat(sprintf('%03d (of %d): %s\n', i, length(cntries), cntry))
  tif_g = sprintf('%s/model/GL-NCEAS-CoastalPopulation_v2013/data/popdensity_2014_mol.tif', dirs['neptune_data'])
  tif_c = file.path(dir_data, cntry, 'spatial/rgn_inland25km_mol.tif')
  csv_a = file.path(dir_data, cntry, 'spatial/rgn_inland25km_data.csv')
  csv_old = file.path(dir_data, cntry, 'layers/mar_coastalpopn_inland25mi.csv')
  csv   = file.path(dir_data, cntry, 'layers/mar_coastalpopn_inland25km.csv')
  fxn   = 'mean'
  
  if (file.exists(csv_old)){
    cat(sprintf('  renaming %s -> %s', basename(csv_old), basename(csv)))
    file.rename(csv_old, csv)
    next    
  } 
  
  dir.create(file.path(dir_data, cntry, 'layers'), showWarnings=FALSE)
  
  # check for files
  csv_orig = file.path(dir_data, cntry, 'layers/rgn_popnsum_inland25km.csv')
  if (file.exists(csv_orig)){
    cat(sprintf('  moving %s -> %s\n', 'rgn_popnsum_inland25km.csv', 'mar_coastalpopn_inland25mi.csv'))
    file.copy(csv_orig, csv, overwrite=T)    
    unlink(csv_orig)
    next  
  } 
  if (file.exists(csv)){
    cat('  already done\n')
    next  
  }
  if (!all(file.exists(tif_g), file.exists(tif_c), file.exists(csv_a))){
    cat('  SKIPPING! not all needed input files found\n')
    next  
  }
  
  cat(sprintf('  zonal %s x %s -> %s (%s)\n', basename(tif_g), basename(tif_c), basename(csv), Sys.time()))
  #cat('  files in cntry/layers: ', paste(list.files(file.path(dir_data, cntry, 'layers/mar_coastalpopn_inland25mi.csv')), collapse=', '))
    
  # perform (time consuming) raster op
  r_g = raster(tif_g)
  r_c = raster(tif_c)
  a   = read.csv(csv_a)
  z   = zonal(r_g, r_c, fun=fxn, na.rm=T)
  
  # calculate population per subregion
  d = z %>% as.data.frame() %>%
    filter(zone != 0) %>%                              # regions without a coast are in zone 0
    select(rgn_id=zone, popn_mean_per_km2 = mean) %>%
    mutate(
      rgn_id = as.integer(rgn_id)) %>%                 # convert to integer so rgn_id's match
    inner_join(
      a %>%
        mutate(
          rgn_id = as.integer(rgn_id)), 
      by='rgn_id') %>%
    mutate(
      popn_sum  = popn_mean_per_km2 * area_km2) %>%    # calculate population sum
    arrange(rgn_id)
  
  # write csv
  write.csv(d, csv, row.names=F, na='')
  
}