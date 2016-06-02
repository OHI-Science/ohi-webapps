# presume that working directory in current scenario directory, eg:
# 

devtools::install_github('ohi-science/ohicore@dev')
library(ohicore)
setwd('~/github/ohi-global/eez2016')
# load conf
conf = Conf('conf')

# run checks on layers
CheckLayers('layers.csv', 'layers', flds_id=conf$config$layers_id_fields)

# load layers
layers = Layers('layers.csv', 'layers')

# calculate scores
scores = CalculateAll(conf, layers)
write.csv(scores, 'scores.csv', na='', row.names=F)
