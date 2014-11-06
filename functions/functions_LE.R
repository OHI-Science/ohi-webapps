LE = function(scores, layers){
  
  # calculate LE scores
  scores.LE = scores %.% 
    filter(goal %in% c('LIV','ECO') & dimension %in% c('status','trend','score','future')) %.%
    dcast(region_id + dimension ~ goal, value.var='score') %.%
    mutate(score = rowMeans(cbind(ECO, LIV), na.rm=T)) %.%
    select(region_id, dimension, score) %.%
    mutate(goal  = 'LE')
  
  # rbind to all scores
  scores = scores %.%
    rbind(scores.LE)  
  
  # return scores
  return(scores)  
}
