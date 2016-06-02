
library(ohicore) # source('install_ohicore.r')
library(stringr)
## 
setwd('eez2016') 
scenario = 'eez2016' # TODO add this to the functions.R setup 

# load conf
conf = Conf('conf')

# run checks on layers
CheckLayers('layers.csv', 'layers', flds_id=conf$config$layers_id_fields)

# load layers
layers = Layers('layers.csv', 'layers')

# calculate scores
scores = CalculateAll(conf, layers)
write.csv(scores, 'scores.csv', na='', row.names=F)


## 1. add scenario = 'eez2016' ----
# Calculating Status and Trend for each region for CS...
#  Error in sprintf("temp/cs_data_%s.csv", scenario) : 
#   object 'scenario' not found 

## 2. add library(stringr) -- LIV

## 3. swapping out LIV_ECO functions and testing. 
# Calculating Status and Trend for each region for LIV...
#  Error in LIV_ECO(layers, subgoal = "LIV", liv_workforcesize_year = 2012,  : 
#   unused arguments (liv_workforcesize_year = 2012, eco_rev_adj_min_year = 2000) 
# --->>>so deleted these lines from goals.csv for LIV, ECO. 
# then,
# Calculating Status and Trend for each region for LIV...
#  Error in eval(expr, envir, enclos) : object 'id_num' not found --> can't continue testing because need to swap out cntry_key: create_functions.r#L508. 
