calculate_scores <- function(){
  
  # load required libraries
  suppressWarnings(require(ohicore))
    
  dirs_scenario = normalizePath(dirname(list.files('.', 'layers.csv', recursive=T, full.names=T)))
  for (dir_scenario in dirs_scenario){
    
    # set working directory to scenario
    setwd(dir_scenario)
    cat('\n\nCALCULATE SCORES for SCENARIO', basename(dir_scenario), '\n')
    
    # load scenario configuration
    conf = Conf('conf')
    
    # run checks on scenario layers
    CheckLayers('layers.csv', 'layers', flds_id=conf$config$layers_id_fields)
    
    # load scenario layers
    layers = Layers('layers.csv', 'layers')
    
    # calculate scenario scores
    scores = CalculateAll(conf, layers, debug=F)
    write.csv(scores, 'scores.csv', na='', row.names=F)
  }  
}

generate_pages <- function(){
  
}

push_changes <- function(){
  
}

# main
args <- commandArgs(trailingOnly=T)
fxns <- c('calculate_scores', 'generate_pages', 'push_changes')
if (length(args)==0 || !args[1] %in% fxns) stop('The first argument needs to be one of: %s', paste(fxns, collapse=', '))
fxn = args[1]
if (length(args)==1){
  eval(parse(text=sprintf('%s()', fxn)))
} else {
  eval(parse(text=sprintf('%s(%s)', fxn, paste(args[2:length(args)], collapse=', '))))
}