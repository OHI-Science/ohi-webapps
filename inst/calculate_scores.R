## calculate_scores.R 

## calculate_scores.R ensures all files are properly configured and calculates OHI scores.
  ## pre_scores.r is in your repository and ensures proper configuration
  ## CalculateAll() is from the `ohicore` R package and calculates OHI scores.  

## When you begin, pre_scores.r and CalculateAll() will calculate scores using
## the 'templated' data and goal models provided. We suggest you work
## goal-by-goal as you prepare data in the prep folder and develop goal models
## in functions.r. Running pre_scores.R and a specific goal model in functions.R
## is a good workflow.

## run the pre_scores.r script to check configuration
source('~/github/ohi-global/eez2016/pre_scores.R')

## calculate scenario scores
scores = ohicore::CalculateAll(conf, layers)

## save scores as scores.csv
write.csv(scores, 'scores.csv', na='', row.names=F)

