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
  csv_lyr = sprintf('%s/%s/layers/mar_coastalpopn_inland25km_lyr.csv', dir_data, cntry)
  
  # loop through years
  for (yr in 2005:2015){
    tif_g = sprintf('%s/model/GL-NCEAS-CoastalPopulation_v2013/data/popdensity_%d_mol.tif', dirs['neptune_data'], yr)
    tif_c = file.path(dir_data, cntry, 'spatial/rgn_inland25km_mol.tif')
    csv_a = file.path(dir_data, cntry, 'spatial/rgn_inland25km_data.csv')
    csv_y = sprintf('%s/%s/layers/mar_coastalpopn_inland25km_%s.csv', dir_data, cntry, yr)
    fxn   = 'mean'
  
    cat(sprintf('  %d\n', yr, Sys.time()))
    
    if (file.exists(csv_lyr)){
      cat('    already done\n')
      next
    } 
  
    dir.create(file.path(dir_data, cntry, 'layers'), showWarnings=FALSE)
  
    if (!all(file.exists(tif_g), file.exists(tif_c), file.exists(csv_a))){
      cat('    SKIPPING! not all needed input files found\n')
      next  
    }
  
    cat(sprintf('    zonal %s x %s -> %s (%s)\n', basename(tif_g), basename(tif_c), basename(csv_y), Sys.time()))
      
    # perform (time consuming) raster op
    r_g = raster(tif_g)
    r_c = raster(tif_c)
    if (!compareRaster(r_g, r_c, stopiffalse=F)){
      tif_g_p = sprintf('%s/model/GL-NCEAS-CoastalPopulation_v2013/data/popdensity_%d_projected_mol.tif', dirs['neptune_data'], yr)
      if (!file.exists(tif_g_p)){
        cat(sprintf('    projecting %s -> %s (%s)\n', basename(tif_g), basename(tif_g_p), Sys.time()))
        r_g = projectRaster(r_g, r_c, method='bilinear', filename=tif_g_p)   
      } else {
        r_g = raster(tif_g_p)
      }
    }
    z   = zonal(r_g, r_c, fun=fxn, na.rm=T)    
    
    # calculate population per subregion
    a   = read.csv(csv_a)
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
        year      = yr,
        popn_sum  = popn_mean_per_km2 * area_km2) %>%    # calculate population sum
      arrange(rgn_id)
    
    # write csv with region names
    write.csv(d, csv_y, row.names=F, na='')
  }
  
  # write layer csv
  rbind_all(
    lapply(2013:2014, function(yr){
      csv_y = sprintf('%s/%s/layers/mar_coastalpopn_inland25km_%s.csv', dir_data, cntry, yr)
      read.csv(csv_y) %>%
        select(rgn_id, year, popn_sum)})) %>%
    write.csv(csv_lyr, row.names=F, na='')
  
}