# clean_spatial_bhi.r
# J. Lowndes @jules32, August 2015

# check for any 'orphaned hole' error encountered in Step 9 below 
# # http://gis.stackexchange.com/questions/113964/fixing-orphaned-holes-in-r

# if running this script 

library(cleangeo) # devtools::install_github('eblondel/cleangeo')  # https://github.com/eblondel/cleangeo

#get a report of geometry validity & issues for a spatial object
report = clgeo_CollectionReport(bhi)
summary = clgeo_SummaryReport(report)
issues = report[report$valid == FALSE,]
issues
#              type valid    issue_type error_msg                                                                   warning_msg
# 2  rgeos_validity FALSE GEOM_VALIDITY      <NA> Ring Self-intersection at or near point 4430577.6700999998 3666341.7962000002
# 3  rgeos_validity FALSE GEOM_VALIDITY      <NA> Ring Self-intersection at or near point 4328223.1637000004 3639978.0762999998
# 13 rgeos_validity FALSE GEOM_VALIDITY      <NA> Ring Self-intersection at or near point 4535820.6182109704 3514687.9852597499
# 25 rgeos_validity FALSE GEOM_VALIDITY      <NA> Ring Self-intersection at or near point 5015347.3856208101 3964209.1151626799
# 28 rgeos_validity FALSE GEOM_VALIDITY      <NA>   Ring Self-intersection at or near point 5045222.6945961704 3965187.96423954
# 30 rgeos_validity FALSE GEOM_VALIDITY      <NA>             Ring Self-intersection at or near point 4955402.6003 4125640.9978
# 31 rgeos_validity FALSE GEOM_VALIDITY      <NA> Ring Self-intersection at or near point 5037563.5394350197 4056149.6710306802
# 32 rgeos_validity FALSE GEOM_VALIDITY      <NA> Ring Self-intersection at or near point 5233455.4231000002 4252975.0427000001
# 33 rgeos_validity FALSE GEOM_VALIDITY      <NA> Ring Self-intersection at or near point 5327810.1221000003 4308200.1273999996
# 34 rgeos_validity FALSE GEOM_VALIDITY      <NA> Ring Self-intersection at or near point 5159648.8906439999 4149144.5315939998
# 36 rgeos_validity FALSE GEOM_VALIDITY      <NA> Ring Self-intersection at or near point 5014393.0338173797 4161220.1811509398
# 38 rgeos_validity FALSE GEOM_VALIDITY      <NA> Ring Self-intersection at or near point 4936654.3310757102 4325528.2384644197
# 40 rgeos_validity FALSE GEOM_VALIDITY      <NA> Ring Self-intersection at or near point 4899952.2333000004 4488036.3326000003
# 41 rgeos_validity FALSE GEOM_VALIDITY      <NA>       Ring Self-intersection at or near point 4968614.6113 4806255.6562000001
# 42 rgeos_validity FALSE GEOM_VALIDITY      <NA> Ring Self-intersection at or near point 4986423.1500936802 4806660.7997369496

# to fix  
mybhi = bhi
mybhi.clean = clgeo_Clean(mybhi, print.log=T)
report.clean = clgeo_CollectionReport(mybhi.clean)
summary.clean = clgeo_SummaryReport(report.clean)
issues = report.clean[report.clean$valid == FALSE,]
issues
#[1] type        valid       issue_type  error_msg   warning_msg
# <0 rows> (or 0-length row.names)

bhi = mybhi.clean
bhi@data

bhi

# defining coordinate reference system 
proj4string(bhi_clean) <- CRS("+init=EPSG:3857") # EPSG:3857 Mercator--typical for Stamen Maps

# transforming from one CRS (Mercator which is in meters) to another (lat/long)
newBHI = spTransform(bhi_clean, CRS('+init=epsg:4326')) # WGS84
bhi=newBHI
# 

writeOGR(bhi, dsn = file.path(dir_neptune,
                              'git-annex/clip-n-ship/bhi/spatial/custom'), 
         layer = 'baltic_shp', driver = 'ESRI Shapefile',overwrite=T)

# NEEDS rgn_names!!!
