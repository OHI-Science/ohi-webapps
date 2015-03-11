library(raster)
library(dplyr)
library(parallel)

# set temporary directory to folder on neptune disk big enough to handle it
tmpdir='~/ssd/R_raster_tmp'
dir.create(tmpdir, showWarnings=F)
rasterOptions(tmpdir=tmpdir)

# get paths based on host machine, now on neptune
dirs = list(
  neptune_data  =  c(
    'Windows' = '//neptune.nceas.ucsb.edu/data_edit',
    'Darwin'  = '/Volumes/data_edit',
    'Linux'   = '/var/data/ohi')[[ Sys.info()[['sysname']] ]], 
  github        = '~/github')

dir_data    = sprintf('%s/git-annex/clip-n-ship', dirs['neptune_data']) # 'N:/git-annex/clip-n-ship/data'
dir_repos   = sprintf('%s/clip-n-ship', dirs['github'])
dir_ohicore = sprintf('%s/ohicore', dirs['github'])
dir_global  = sprintf('%s/ohi-global/eez2014', dirs['github'])
log         = sprintf('%s/git-annex/clip-n-ship/make_sc_coastpop_lyr_log.txt', dirs['neptune_data'])
redo        = T
years       = 2005:2015

# function to parallelize
make_sc_coastpop_lyr = function(cntry, redo=F){ # cntry='usa'
  
  #cat(sprintf('%03d (of %d): %s\n', i, length(cntries), cntry))
  csv_lyr = sprintf('%s/%s/layers/mar_coastalpopn_inland25km_lyr.csv', dir_data, cntry)
  
  if (file.exists(csv_lyr) & !redo){
    cat(sprintf('%s: %s already done\n', cntry, csv_lyr), file=log, append=T)
    next
  } 
  
  # loop through years
  for (yr in years){ # yr=2005
    tif_g = sprintf('%s/model/GL-NCEAS-CoastalPopulation_v2013/data/popdensity_%d_mol.tif', dirs['neptune_data'], yr)
    tif_c = file.path(dir_data, cntry, 'spatial/rgn_inland25km_mol.tif')
    csv_a = file.path(dir_data, cntry, 'spatial/rgn_inland25km_data.csv')
    csv_y = sprintf('%s/%s/layers/mar_coastalpopn_inland25km_%s.csv', dir_data, cntry, yr)
    fxn   = 'mean'
    
    if (file.exists(csv_y) & !redo){
      next
    } 
    
    if (!all(file.exists(tif_g), file.exists(tif_c), file.exists(csv_a))){
      cat(sprintf('%s - %d: SKIPPING! not all needed input files found\n', cntry, yr), file=log, append=T)
      next  
    }
    
    # perform (time consuming) raster op
    cat(sprintf('%s - %d: zonal %s x %s -> %s (%s)\n', cntry, yr, basename(tif_g), basename(tif_c), basename(csv_y), Sys.time()), file=log, append=T)
    dir.create(file.path(dir_data, cntry, 'layers'), showWarnings=FALSE)
    r_g = raster(tif_g)
    r_c = raster(tif_c)
    if (!compareRaster(r_g, r_c, stopiffalse=F)){
      tif_g_p = sprintf('%s/model/GL-NCEAS-CoastalPopulation_v2013/data/popdensity_%d_projected_mol.tif', dirs['neptune_data'], yr)      
      if (!file.exists(tif_g_p)){
        cat(sprintf('    projecting %s -> %s (%s)\n', basename(tif_g), basename(tif_g_p), Sys.time()), file=log, append=T)
        # SLOW!: took 7 hrs for popdensity_2005_mol.tif -> popdensity_2005_projected_mol.tif VS 1.5 min in ArcGIS!
        r_g = projectRaster(r_g, r_c, method='bilinear', filename=tif_g_p)   
      } else {
        r_g = raster(tif_g_p)
      }
      if (!compareRaster(r_g, r_c, stopiffalse=F)){
        cat(sprintf('    cropping r_g (%s)\n', Sys.time()), file=log, append=T)
        r_g = crop(r_g, r_c)
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
  cat(sprintf('%s: concat to layer file %s (%s)\n', cntry, csv_lyr, Sys.time()), file=log, append=T)  
  rbind_all(
    lapply(years, function(yr){
      csv_y = sprintf('%s/%s/layers/mar_coastalpopn_inland25km_%s.csv', dir_data, cntry, yr)
      read.csv(csv_y) %>%
        select(rgn_id, year, popsum=popn_sum)})) %>%
    write.csv(csv_lyr, row.names=F, na='')  
  
  return(csv_y)
}

# get list of countries with prepped data
cntries = list.files(dir_data)
cntries = c('rus','spm')

# loop through countries on max detected cores - 1
# debug with lapply: 
#lapply(cntries, make_sc_coastpop_lyr, redo=T)  
cat(sprintf('\n\nlog starting for parallell::mclapply (%s)\n\n', Sys.time()), file=log)
res = mclapply(cntries, make_sc_coastpop_lyr, redo=T, mc.cores = detectCores() - 1, mc.preschedule=F)  

# to kill processes from terminal
# after running from https://neptune.nceas.ucsb.edu/rstudio/:
#   kill $(ps -U bbest | grep rsession | awk '{print $1}')
# after running from terminal: Rscript ~/github/ohi-webapps/process_rasters.R &
#   kill $(ps -U bbest | grep R | awk '{print $1}')
# tracking progress:
#   log=/var/data/ohi/git-annex/clip-n-ship/make_sc_coastpop_lyr_log.txt; cat $log