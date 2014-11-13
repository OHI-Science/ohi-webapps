library(raster)
library(dplyr)

# set temporary directory to folder on neptune disk big enough to handle it
tmpdir='~/ssd/R_raster_tmp'
dir.create(tmpdir, showWarnings=F)
rasterOptions(tmpdir=tmpdir)

# get paths based on host machine, now on neptune
dir_neptune_data  = '/Volumes/data_edit'

# loop through years
for (yr in 2005:2015){
  tif_g = sprintf('%s/model/GL-NCEAS-CoastalPopulation_v2013/data/popdensity_%d_mol.tif', dir_neptune_data, yr)
  tif_c = file.path(dir_neptune_data, 'git-annex/clip-n-ship', cntry, 'spatial/rgn_inland25km_mol.tif')
  r_g = raster(tif_g)
  r_c = raster(tif_c)
  if (!compareRaster(r_g, r_c, stopiffalse=F)){
    tif_g_p = sprintf('%s/model/GL-NCEAS-CoastalPopulation_v2013/data/popdensity_%d_projected_mol.tif', dir_neptune_data, yr)
    cat(sprintf('    project %s -> %s\n', basename(tif_g), basename(tif_g_p)))
  }
}

raster('/Volumes/data_edit/model/GL-NCEAS-Halpern2008/data/masked_model.tif')
raster('/Volumes/data_edit/model/GL-NCEAS-CoastalPopulation_v2013/tmp/rgn_inland_25mi_mol.tif')
raster('/Volumes/data_edit/git-annex/clip-n-ship/albania/spatial/rgn_inland25km_mol.tif')


cat('mask: N:\\model\\GL-NCEAS-Halpern2008\\data\\masked_model.tif')
cat('dir: ', dirname(tif_c))