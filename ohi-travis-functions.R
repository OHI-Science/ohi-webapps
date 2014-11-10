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
  wd = getwd() # presumably in top level folder of repo containing scenario folders 
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
  setwd(wd)
}

create_pages <- function(){
  
  library(yaml)
  library(brew)
  library(ohicore)
  
  # get results brew files from ohi-webapps
  dir_brew = '~/github/ohi-webapps/results'
  
  # copy draft branch scenarios
  system('git checkout draft; git pull')
  system('rm -rf ~/tmp_draft; mkdir ~/tmp_draft; cp -R * ~/tmp_draft/.')

  # get default_scenario set by .travis.yml
  default_scenario = Sys.getenv('default_scenario')
  study_area       = Sys.getenv('study_area')
  if (default_scenario == '' | study_area == ''){    
    # if not set, then running locally so read in yaml
    travis_yaml = yaml.load_file('.travis.yml')    
    for (var in travis_yaml$env$global){ # var = travis_yaml$env$global[[2]]
      if (is.null(names(var))){
        var_parts = str_trim(str_split(var, '=')[[1]])
        assign(var_parts[1], str_replace_all(var_parts[2], '\"',''))
      }
    }
  }
  
  # copy published branch scenarios
  system('git checkout published; git pull')
  system('rm -rf ~/tmp_published; mkdir ~/tmp_published; cp -R * ~/tmp_published/.')
  
  # switch to gh-pages branch
  system('git checkout gh-pages')
  
  # iterate over branches
  for (branch in c('published','draft')){ # branch='published'
    
    # per branch vars
    dir_data_branch  = sprintf('~/tmp_%s', branch)
    dir_pages_branch = c(published='.', draft='./draft')[[branch]]
    
    # iterate through all scenarios (by finding scores.csv)
    dirs_scenario = normalizePath(dirname(list.files(dir_data_branch, 'scores.csv', recursive=T, full.names=T)))
    for (dir_scenario in dirs_scenario){ # dir_scenario = dirs_scenario[1]
      
      # scenario vars
      scenario = basename(dir_scenario)
      rgns     = file.path(dir_scenario, 'scores.csv') %>% read.csv %>% select(region_id) %>% unique %>% getElement('region_id')
      layers   = ohicore::Layers(file.path(dir_scenario, 'layers.csv'), file.path(dir_scenario, 'layers'))
      conf     = ohicore::Conf(file.path(dir_scenario, 'conf'))
      # region names, ordered by GLOBAL and alphabetical
      rgns = rbind(
        data.frame(
          id    = 0, 
          name  = 'GLOBAL',
          title = study_area,
          stringsAsFactors=F),
        ohicore::SelectLayersData(layers, layers=conf$config$layer_region_labels, narrow=T) %>%
          select(
            id    = id_num, 
            name  = val_chr) %>%
          mutate(
            title = name)  %>% 
          arrange(title))
      
      # copy results: figures and tables
      dir_data_results  =  file.path(dir_data_branch, scenario, 'reports')
      dir_pages_results =  file.path('results', branch, scenario)
      dir.create(dir_pages_results, showWarnings=F, recursive=T)
      file.copy(list.files(dir_data_results, full.names=T), dir_pages_results, recursive=T)
      
      # brew markdown files
      dir_pages_md = ifelse(
        scenario == default_scenario, 
        dir_pages_branch, 
        file.path(dir_pages_branch, scenario))      
      for (f_brew in list.files(dir_brew, '.*\\.brew\\.md', full.names=T)){ # f_brew = list.files(dir_brew, '.*\\.brew\\.md', full.names=T)[4]
        f_md = file.path(dir_pages_md, str_replace(basename(f_brew), fixed('.brew.md'), ''), 'index.md')
        dir.create(dirname(f_md), showWarnings=F, recursive=T)
        brew(f_brew, f_md)
      }      
    }
  }  
}

push_branch <- function(branch='draft'){  
  # set message with [ci skip] to skip travis-ci build for next time

  if (all(Sys.getenv('GH_TOKEN') > '', Sys.getenv('TRAVIS_COMMIT') > '', Sys.getenv('TRAVIS_REPO_SLUG') > '')){
    
    # working on travis-ci
    system('git commit -a -m "auto-calculate from commit ${TRAVIS_COMMIT}\n[ci skip]"')
    system('git remote set-url origin "https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG}.git"')
    system(sprintf('git push origin HEAD:%s', branch))
    
  } else {
    
    # working locally, gh_token set in create_init.R, repo_name set in create_init_sc.Rs
    owner_repo = sprintf('ohi-science/%s', repo_name)
    system('git commit -a -m "auto-calculate from commit `git rev-parse HEAD`\n[ci skip]"')
    system(sprintf('git remote set-url origin "https://%s@github.com/%s.git"', gh_token, owner_repo))
    system(sprintf('git push origin HEAD:%s', branch))
    
  }
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