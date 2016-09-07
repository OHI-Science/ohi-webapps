## calculate_scores_check

calculate_scores_check <- function(){ 
  
  ## libraries
  suppressWarnings(require(ohicore))
  
  ## ensure on master branch
  #git2r::checkout(repo, 'master')
  
  # iterate through all scenarios (by finding layers.csv)
  dirs_scenario = normalizePath(dirname(list.files('.', '^layers.csv$', recursive=T, full.names=T)))
  for (dir_scenario in dirs_scenario){ # dir_scenario=dirs_scenario[1]
    
    # set working directory to scenario
    setwd(dir_scenario)
    cat('\n\nCALCULATE SCORES for SCENARIO', basename(dir_scenario), '\n')
    
    # load scenario configuration
    conf <<- Conf('conf')
    
    # run checks on scenario layers
    CheckLayers('layers.csv', 'layers', flds_id=conf$config$layers_id_fields)
    
    # load scenario layers
    layers <<- Layers('layers.csv', 'layers')
    
    # calculate scenario scores
    scores = CalculateAll(conf, layers)
    write.csv(scores, 'scores.csv', na='', row.names=F)
    
    # document versions of packages and specifics of ohicore
    cat(
      capture.output(sessionInfo()), '\n\n',
      readLines(file.path(system.file(package='ohicore'), 'DESCRIPTION')),
      file='session.txt', sep='\n')
  }
  
}