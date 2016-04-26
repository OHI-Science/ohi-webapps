#CODE TO DOWNLOAD GEOJSON FILES FROM OHI GITHUB ARCHIVE, CONVERT TO ESRI SHAPEFILES
#AND SAVE TO DESTINATION FOLDER
#
#WRITTEN BY CHARLOTTE MARCINKO 08-04-2016
#UNIVERSITY OF SOUTHAMPTON AND NATIONAL OCEANOGRAPHY CENTRE UK 
#
#######################################################################################

#HOUSE KEEPING

rm(list = ls())

library(sp) 
library(rgdal)
library(utils)

#READ IN LIST OF COUNTRY CODES 
#testcodes<-c("aus", "bra","can","ind","usa","rus")

codes.data<-read.csv("D:\\GULLS\\DataIn\\OHI_EEZ_gadm\\Country_codes_ohi.csv",sep=",")
codes<-codes.data$repo

  
#LOOP THROUGH COUNTRY CODE 
  for (ii in 1:length(codes)) {
    
#INCLUDE TRYCATCH TO SKIP TO NEXT REPO CODE IF DATA MISSING FROM ARCHIVE
    possibleError<-tryCatch({
      
#SET DESTINATION FILE FOR DOWNLOAD
  
      destfile<-paste("C:\\Users\\grw\\GULLS\\OHI_EEZ_GADM\\regions_gcs_",codes[ii],".geojson",sep="")  
 
#SET URL FOR REQUIRED DATA
  
      url<-paste("https://raw.githubusercontent.com/OHI-Science",codes[ii],"draft/subcountry2014/spatial/regions_gcs.geojson",sep="/")
 
#DOWNLOAD OHI GEOJSON FILE FOR COUNTRY ii
      download.file(url, destfile, method = "wininet")

#READ IN COUNTRY GEOJSON FILE ii  
      x = readOGR(dsn = destfile,"OGRGeoJSON")
  
#SET DESTINATION PATH FOR SHAPEFILE AND LAYER NAME
      ESRIpath<-paste("C:\\Users\\grw\\GULLS\\OHI_EEZ_GADM\\regions_gcs_",codes[ii],sep="")  
      layerName<-paste(codes[ii],"_EEZGADM1",sep="")

#WRITE COUNTRY ii FILE AS ESRI SHAPEFILE  
      writeOGR(x, dsn = ESRIpath,
             layer = layerName, driver = 'ESRI Shapefile', overwrite=T)

# REMOVE X FOR NEXT ITERATION 
      rm(x,ESRIpath,layerName,url,destfile)

   
},error=function(e) e) # END OF TRYCATCH 
    
#IF ERROR IN DATA AQUISITION THEN SKIP TO NEXT ii    
    
    if(inherits(possibleError, "error")) next
    
  } #END LOOP 

