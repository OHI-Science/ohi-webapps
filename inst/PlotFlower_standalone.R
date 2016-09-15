## Ocean Health Index flower plot
# To make an Ocean Health Index flower plot, you will need information in the following format:
# a data frame object with four columns: goal, dimension, region_id, scores (e.g. 'scores.csv')


## install packages and load libraries
library(devtools) # install.packages('devtools')
devtools::install_github('ohi-science/ohicore')
library(ohicore)
library(dplyr) # install.packages('dplyr')


## example call using OHI Global 2015 data
source('https://raw.githubusercontent.com/OHI-Science/ohi-webapps/dev/inst/PlotFlowerMulti.R') 
scores       <- read.csv('https://raw.githubusercontent.com/OHI-Science/ohi-global/v2015.1/eez2015/scores.csv')
rgns_to_plot <- c(10:15)    # this will make flower plots for regions 10 through 15
rgn_names    <- read.csv('https://raw.githubusercontent.com/OHI-Science/ohi-global/v2015.1/eez2015/layers/rgn_global.csv')
goals        <- read.csv('https://raw.githubusercontent.com/OHI-Science/ohi-global/v2015.1/eez2015/conf/goals.csv')

PlotFlowerMulti(scores          = scores,
                rgns_to_plot    = rgns_to_plot,
                rgn_names       = rgn_names,
                assessment_name = 'Global',
                goals           = goals,
                save_fig        = TRUE,
                name_fig        = 'reports/figures/flower') # set filepath to save the figures

