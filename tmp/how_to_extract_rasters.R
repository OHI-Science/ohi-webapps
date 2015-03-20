# How to extract data from a raster using a polygon
# March 19, 2015. afflerbach@nceas.ucsb.edu and lowndes@nceas.ucsb.edu

# read in a population raster, then extract data using a shapefile polygon. 
# this example is to ultimately find the proportion of population for Guayaquil's 3 regions in proportion to Ecuador's population.

## read in files and transform ----
# pop raster
pop = raster(file.path(dir_neptune, 'model/GL-NCEAS-CoastalPopulation_v2013/data/popdensity_2015_projected_mol.tif')) # 290 mb is big, but 'a nice size'
plot(pop)
pop_crs = crs(pop) # check crs (coodinate ref system) = mollweide. Always easier to reproject a shapefile rather than a raster.

# gye polygon
shp_gye = file_path_sans_ext(list.files(dir_custom))[1]
shp_orig = readOGR(dir_custom, shp_gye)

shp = spTransform(shp_orig,pop_crs) # transforming shpfile to crs of pop raster
ext_gye = extent(shp_gye) #in meters now

# ecu polygon
shp_ecu_dir = file.path(dir_neptune, 'git-annex/clip-n-ship/ecu/spatial')
shp_ecu = readOGR(shp_ecu_dir, 'rgn_inland_mol')
plot(shp_ecu)
ext_ecu = extent(shp_ecu)


## cropping the raster so we're dealing with a more managable amount of data ----

# crop to the ECU extent
pop_crop_ecu = crop(pop, ext_ecu, progress='text') #always do for progress
plot(pop_crop_ecu)
plot(shp,add=T) # overlay!
plot(shp_ecu,add=T) # overlay!

# crop to the GYE extent
pop_crop_gye = crop(pop, ext_bye, progress='text') #always do for progress
plot(pop_crop_gye)
plot(shp,add=T) # overlay!


## extracting data and summing ----

# extract to Ecuador as a whole
pop_extract_ecu = extract(pop_crop_ecu, shp_ecu, fun=function(x){sum(x,na.rm=T)}, progress='text') # this will return a list of 3: all values in each region

# extract to GYE regions
pop_extract_gye = extract(pop_crop, shp, fun=function(x){sum(x,na.rm=T)}, progress='text') # this will return a list of 3: all values in each region


## calculate proportion ----

# proportion of GYE regions to total pop to be used to downweight GDP, etc
pop_total_ecu = sum(pop_extract_ecu)
proportion_gye = pop_extract_gye/pop_total_ecu


## don't 'clip' (which is called 'mask') ----

# just for not fun: clip the global raster to the region shapefile rather than crop
# if I ever want to do clipping, talk to Jamie about setting up temporary files
# pop_clip = mask(pop, shp, progress='text',filename=) # takes forever, only do on Neptune if necessary; crop took a tiny amount
# plot(pop_clip)



