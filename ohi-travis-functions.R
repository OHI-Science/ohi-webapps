calculate_scores <- function(){
  
  # load required libraries
  suppressWarnings(require(ohicore))

  # ensure on draft repo
  checkout(repo, 'draft')
  
  # iterate through all scenarios (by finding layers.csv)
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

create_results <- function(res=72){
  
  library(ohicore)
  library(tidyr)
  library(dplyr)
  
  # load required libraries
  suppressWarnings(require(ohicore))
  
  # ensure draft repo
  system('git checkout draft')
  
  # iterate through all scenarios (by finding layers.csv)
  dirs_scenario = normalizePath(dirname(list.files('.', 'layers.csv', recursive=T, full.names=T)))
  for (dir_scenario in dirs_scenario){ # dir_scenario = '~/github/clip-n-ship/alb/alb2014'
  
    # load scenario configuration, layers and scores
    setwd(dir_scenario)
    conf = Conf('conf')
    layers = Layers('layers.csv', 'layers')
    scores = read.csv('scores.csv')
    
    # get goals for flowers, all and specific to weights
    goals.all = arrange(conf$goals, order_color)[['goal']]
    
    # get colors for aster, based on 10 colors, but extended to all goals. subselect for goals.wts
    cols.goals.all = colorRampPalette(RColorBrewer::brewer.pal(10, 'Spectral'), space='Lab')(length(goals.all))
    names(cols.goals.all) = goals.all
    
    # get subgoals and goals, not supragoals, for doing flower plot
    goals_supra = na.omit(unique(conf$goals$parent))
    wts = with(subset(conf$goals, !goal %in% goals_supra, c(goal, weight)), setNames(weight, goal))
    goal_labels = gsub('\\n', '\n', with(conf$goals, setNames(name_flower, goal))[names(wts)], fixed=T)
    
    # region names, ordered by GLOBAL and alphabetical
    rgn_names = rbind(
      data.frame(
        region_id=0, 
        rgn_name='GLOBAL'),
      SelectLayersData(layers, layers=conf$config$layer_region_labels, narrow=T) %>%
        select(
          region_id=id_num, 
          rgn_name=val_chr)  %>% 
        arrange(rgn_name))
    
    # use factors to sort by goal and dimension in scores
    conf$goals = arrange(conf$goals, order_hierarchy)
    scores$goal_label = factor(
      scores$goal, 
      levels = c('Index', conf$goals$goal),
      labels = c('Index', ifelse(!is.na(conf$goals$parent),
                                 sprintf('. %s', conf$goals$name),
                                 conf$goals$name)),
      ordered=T)
    scores$dimension_label = factor(
      scores$dimension,
      levels = names(conf$config$dimension_descriptions),
      ordered=T)
    
    # loop through regions
    for (rgn_id in unique(scores$region_id)){ # rgn_id=0

      # rgn vars
      rgn_name    = subset(rgn_names, region_id==rgn_id, rgn_name, drop=T)
      flower_png  = sprintf('reports/figures/flower_%s.png', gsub(' ','_', rgn_name))
      scores_csv  = sprintf('reports/tables/scores_%s.csv', gsub(' ','_', rgn_name))      
            
      # create directories, if needed
      dir.create(dirname(flower_png), showWarnings=F)
      dir.create(dirname(scores_csv), showWarnings=F)

      # region scores    
      g_x = with(subset(scores, dimension=='score' & region_id==rgn_id ),
                 setNames(score, goal))[names(wts)]
      x   = subset(scores, dimension=='score' & region_id==rgn_id & goal == 'Index', score, drop=T)
            
      # flower plot ----
      png(flower_png, width=res*7, height=res*7)
      PlotFlower(
        #main = rgn_name,
        lengths=ifelse(
          is.na(g_x),
          100,
          g_x),
        widths=wts,
        fill.col=ifelse(
          is.na(g_x), 
          'grey80', 
          cols.goals.all[names(wts)]),
        labels  =ifelse(
          is.na(g_x), 
          paste(goal_labels, '-', sep='\n'), 
          paste(goal_labels, round(x), sep='\n')),
        center=round(x),
        max.length = 100, disk=0.4, label.cex=0.9, label.offset=0.155, cex=2.2, cex.main=2.5)
      dev.off()
      #system(sprintf('convert -density 150x150 %s %s', fig_pdf, fig_png)) # imagemagick's convert
      
      # table csv ---- 
      scores %>% 
        filter(region_id == rgn_id) %>%
        select(goal_label, dimension_label, score) %>%
        spread(dimension_label, score) %>%
        dplyr::rename(' '=goal_label) %>%
        write.csv(scores_csv, row.names=F, na='')
    }
  }
}

generate_pages <- function(){
  
}

push_changes <- function(){
  
}

# main
args <- commandArgs(trailingOnly=T)
if (length(args)>0){
  
  fxns <- c('calculate_scores', 'generate_pages', 'push_changes', 'create_results')
  fxn = args[1]
  if (length(args)==1){
    eval(parse(text=sprintf('%s()', fxn)))
  } else {
    eval(parse(text=sprintf('%s(%s)', fxn, paste(args[2:length(args)], collapse=', '))))
  }
}