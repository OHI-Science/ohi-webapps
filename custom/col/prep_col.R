# libraries
library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(rgdal)
library(raster)


col_tmp = readOGR(dsn = '~/Dropbox/NCEAS_Julie/OHI_Regional/OHI-Colombia/Shapefiles',
              layer = 'ISO_Caribe')
# Error in ogrInfo(dsn = dsn, layer = layer, encoding = encoding, use_iconv = use_iconv,  : 
#   Cannot open file

