LE = function(scores, layers){
  
  # calculate LE scores
  scores.LE = scores %>%
    dplyr::filter(goal %in% c('LIV','ECO') & dimension %in% c('status','trend','score','future')) %>%
    tidyr::spread(key = goal, value = score) %>%
    dplyr::mutate(score = rowMeans(cbind(ECO, LIV), na.rm=T)) %>%
    dplyr::select(region_id, dimension, score) %>%
    dplyr::mutate(goal  = 'LE')
 
  # rbind to all scores
  scores = scores %>%
    rbind(scores.LE)  
  
  # return scores
  return(scores)  
}
