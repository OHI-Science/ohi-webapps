library(raster)


# get list of countries with prepped data
cntries = list.files(dir_data)

# loop through countries
#for (cntry in cntries){
# DEBUG!
cntry = 'Albania'  


  # process raster layers
  lyrs_raster = c(
    mar_coastalpopn_inland25mi = list(
      tif_g = sprintf('%s/model/GL-NCEAS-CoastalPopulation_v2013/data/popdensity_2014_mol.tif', dirs['neptune_data']),
      tif_c = 'rgn_inland25km_mol.tif',
      fxn   = 'sum')
    
    r_g = raster(tif_g)
    r_c = raster(file.path(dir_data, cntry, tif_c))
    z = zonal(r_g, r_c, fxn, na.rm=T)