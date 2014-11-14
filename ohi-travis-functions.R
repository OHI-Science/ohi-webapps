calculate_scores <- function(){
  
  # load required libraries
  wd = getwd()
  suppressWarnings(require(ohicore))

  # ensure on draft repo
  library(git2r)
  repo = repository('.')
  checkout(repo, 'draft')
  
  # iterate through all scenarios (by finding layers.csv)
  dirs_scenario = normalizePath(dirname(list.files('.', 'layers.csv', recursive=T, full.names=T)))
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
    scores = CalculateAll(conf, layers, debug=F)
    write.csv(scores, 'scores.csv', na='', row.names=F)
    
    # document versions of packages and specifics of ohicore
    cat(
      capture.output(sessionInfo()), '\n\n',
      readLines(file.path(system.file(package='ohicore'), 'DESCRIPTION')), 
      file='session.txt', sep='\n')   
  }  
  
  setwd(wd)
}

create_results <- function(res=72){
  
  library(ohicore)
  library(tidyr)
  library(dplyr)
  
  # load required libraries
  suppressWarnings(require(ohicore))
  
  # ensure draft repo
  system('git checkout draft --force')
  
  # iterate through all scenarios (by finding scores.csv)
  wd = getwd() # presumably in top level folder of repo containing scenario folders 
  dirs_scenario = normalizePath(dirname(list.files('.', 'scores.csv', recursive=T, full.names=T)))
  for (dir_scenario in dirs_scenario){ # dir_scenario = '~/github/clip-n-ship/alb/alb2014' # dir_scenario = dirs_scenario[1]
  
    # load scenario configuration, layers and scores
    setwd(dir_scenario)
    conf = Conf('conf')
    layers      = Layers('layers.csv', 'layers')
    scores      = read.csv('scores.csv')
    regions_csv = 'reports/tables/region_titles.csv'
    
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
        rgn_name='GLOBAL',
        rgn_title=study_area),
      SelectLayersData(layers, layers=conf$config$layer_region_labels, narrow=T) %>%
        select(
          region_id=id_num, 
          rgn_name=val_chr)  %>% 
        mutate(
          rgn_title=rgn_name) %>%
        arrange(rgn_name))
    dir.create(dirname(regions_csv), showWarnings=F, recursive=T)
    write.csv(rgn_names, regions_csv, row.names=F, na='')
    
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
  library(dplyr)
  library(knitr)
  library(stringr)
  library(rmarkdown)
  
  # TODO: cd to proper dir whether local or on Travis
  # setwd('~/github/clip-n-ship/ecu')
  
  # get results brew files from ohi-webapps
  # TODO: clone ohi-webapps/results
  dir_brew = '~/github/ohi-webapps/results'
  
  # copy draft branch scenarios
  #system('git checkout draft; git pull')
  #system('rm -rf ~/tmp_draft; mkdir ~/tmp_draft; cp -R * ~/tmp_draft/.')

  # get default_branch_scenario set by .travis.yml
  repo = repository(getwd())
  checkout(repo, 'draft', force=T)  
  default_branch_scenario  = Sys.getenv('default_branch_scenario')
  study_area               = Sys.getenv('study_area')
  if (default_branch_scenario == '' | study_area == ''){    
    # if not set, then running locally so read in yaml
    travis_yaml = yaml.load_file('.travis.yml')    
    for (var in travis_yaml$env$global){ # var = travis_yaml$env$global[[2]]
      if (is.null(names(var))){
        var_parts = str_trim(str_split(var, '=')[[1]])
        assign(var_parts[1], str_replace_all(var_parts[2], '\"',''))
      }
    }
  }
  
  # archive branches
  dir_archive <- '~/tmp_repo_archive'
  unlink(dir_archive, recursive=T)
  git_branches   = setdiff(sapply(git2r::branches(repo, flags='remote'), function(x) str_replace(x@name, 'origin/', '')), c('HEAD','gh-pages','app'))
  branch_commits = list()
  for (branch in git_branches){ # branch = 'published'
    
    checkout(repo, branch=branch, force=T)
    pull(repo)
    branch_commits[[branch]] = commits(repo)
    
    dir_branch = file.path(dir_archive, branch)    
    files = list.files(dir_repo, recursive=T)
    for (f in files){ # f = shiny_files[1]
      dir.create(dirname(file.path(dir_branch, f)), showWarnings=F, recursive=T)
      file.copy(file.path(dir_repo, f), file.path(dir_branch, f), overwrite = T, copy.mode=T, copy.date=T) # suppressWarnings)
    }
  }
  
  # switch to gh-pages branch
  checkout(repo, branch='gh-pages', force=T)
  
  # get list of all branch/scenarios and directory to output
  branch_scenarios = dirname(list.files(dir_archive, 'scores.csv', recursive=T))
  dir_bs_pages = setNames(
    ifelse(
      branch_scenarios == default_branch_scenario, 
      '.', 
      branch_scenarios),
    branch_scenarios)
  
  # iterate over branch/scenarios
  for (branch_scenario in branch_scenarios){ # branch_scenario=branch_scenarios[2]
    
    # get vars
    branch      =  dirname(branch_scenario)
    scenario    = basename(branch_scenario)
    dir_bs_data = normalizePath(file.path(dir_archive, branch_scenario))
    rgns         = file.path(dir_bs_data, 'scores.csv') %>% read.csv %>% select(region_id) %>% unique %>% getElement('region_id')
    layers       = ohicore::Layers(file.path(dir_bs_data, 'layers.csv'), file.path(dir_bs_data, 'layers'))
    conf         = ohicore::Conf(file.path(dir_bs_data, 'conf'))
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
    dir_data_results  =  file.path(dir_archive, branch_scenario, 'reports')
    dir_pages_results =  file.path('results', branch_scenario)
    dir.create(dir_pages_results, showWarnings=F, recursive=T)
    file.copy(list.files(dir_data_results, full.names=T), dir_pages_results, recursive=T)
    
    # render Rmarkdown files and prepend with frontmatter, ie for Goal equations
    for (f_rmd in list.files(dir_brew, '.*\\.html\\.Rmd', full.names=T)){ # f_rmd = list.files(dir_brew, '.*\\.html\\.Rmd', full.names=T)[1]
      
      section     = str_replace(basename(f_rmd), fixed('.html.Rmd'), '')
      navbar_html = file.path(dir_bs_pages[[branch_scenario]], section, 'branch_scenario_navbar.html')
      f_out_html  = file.path(dir_bs_pages[[branch_scenario]], section, 'index.html')  
      cat(sprintf('%s -> %s\n', f_rmd, f_out_html))
      
      dir.create(dirname(navbar_html), showWarnings=F, recursive=T)
      brew(file.path(dir_brew, 'navbar.brew.html'), navbar_html)

      f_in_front = sprintf('%s/%s_frontmatter.brew.html', dir_brew, str_replace(basename(f_rmd), fixed('.html.Rmd'), ''))
      stopifnot(file.exists(f_in_front))
      dir.create(dirname(f_out_html), showWarnings=F, recursive=T)
      brew(f_in_front, f_out_html)
      f_tmp = tempfile()
      render(f_rmd, 'html_document', output_file=f_tmp)
      cat(readLines(f_tmp), file=f_out_html, append=T)
      unlink(f_tmp)
    }
    
    # brew markdown files
    for (f_brew in list.files(dir_brew, '.*\\.brew\\.md', full.names=T)){ # f_brew = list.files(dir_brew, '.*\\.brew\\.md', full.names=T)[1]
      section = str_replace(basename(f_brew), fixed('.brew.md'), '')
      branch_scenario_navbar = utils::capture.output({ brew(file.path(dir_brew, 'navbar.brew.html')) })
      f_md = file.path(dir_bs_pages[[branch_scenario]], section, 'index.md')
      dir.create(dirname(f_md), showWarnings=F, recursive=T)
      cat(sprintf('%s -> %s\n', f_brew, f_md))
      brew(f_brew, f_md)
    }
    
    # copy regions
    file.copy(file.path(dir_data_results, 'tables/region_titles.csv'), sprintf('_data/regions_%s.csv', str_replace(branch_scenario, '/', '_')))
  }  
}

push_branch <- function(branch='draft'){  
  # set message with [ci skip] to skip travis-ci build for next time

  if (all(Sys.getenv('GH_TOKEN') > '', Sys.getenv('TRAVIS_COMMIT') > '', Sys.getenv('TRAVIS_REPO_SLUG') > '')){
    
    # working on travis-ci
    system('git add -A')
    system('git commit -a -m "auto-calculate from commit ${TRAVIS_COMMIT}\n[ci skip]"')
    system('git remote set-url origin "https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG}.git"')
    system(sprintf('git push origin HEAD:%s', branch))
    
  } else {
    
    # working locally, gh_token set in create_init.R, repo_name set in create_init_sc.Rs
    system('git add -A')
    system('git commit -a -m "auto-calculate from commit `git rev-parse HEAD`\n[ci skip]"')
    system(sprintf('git remote set-url origin "https://%s@github.com/%s.git"', gh_token, git_slug))
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