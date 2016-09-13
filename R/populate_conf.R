# populate_conf.r

populate_conf <- function(key, dir_scenario, dir_global) {
  
  ## create conf folder
  if (!dir.exists(sprintf('%s/conf', dir_scenario))) {
    dir.create(sprintf('%s/conf', dir_scenario), showWarning=FALSE)
  }
    
  ## list conf files to copy
  conf_files = c('config.R','functions.R','goals.csv',
                 'pressures_matrix.csv','resilience_matrix.csv',
                 'pressure_categories.csv', 'resilience_categories.csv')
  
  for (f in conf_files){ # f = conf_files[1] f = "functions.R" 
    
    f_in  = sprintf('%s/conf/%s', dir_global,   f)
    f_out = sprintf('%s/conf/%s', dir_scenario, f)
    
    # read in file
    s = readLines(f_in, warn=F, encoding='UTF-8')
    
    ## swap out custom functions
    if (f == 'functions.R'){
      
      ## TODO: delete eez2013 from functions. r --Setup()
      
      ## iterate over goals with functions to swap
      ## TODO: when update LIV_ECO approach, can delete csv_gl_rgn var from create_init.r
      for (g in names(fxn_swap)){ # g = names(fxn_swap)[1]
        
        ## get goal=line# index for functions.R
        fxn_idx = setNames(
          grep('= function', s),
          str_trim(str_replace(grep('= function', s, value=T), '= function.*', '')))
        
        # read in new goal function
        s_g = readLines(fxn_swap[g], warn=F, encoding='UTF-8')
        
        # get line numbers for current and next goal to begin and end excision
        ln_beg = fxn_idx[g] - 1
        ln_end = fxn_idx[which(names(fxn_idx)==g) + 1]
        
        # inject new goal function
        s = c(s[1:ln_beg], s_g, '\n', s[ln_end:length(s)])
      }
      
      
      ## rethink because ref points stuff might be useful. will find this: 
      ## write.csv(d_check, sprintf('temp/cs_data_%s.csv', scenario), row.names=FALSE)    
      s <-  s %>%
        str_replace("write.csv\\(tmp, 'temp/.*", '') %>%
        str_replace('^.*sprintf\\(\'temp\\/.*', '')
    
      ## TODO: Delete PreGlobalScores(): https://github.com/OHI-Science/ohicore/blob/master/R/CalculateAll.R#L217-L221
      
      del_begin <- s %>% str_locate("PreGlobalScores.*")
      del_begin <- which(!is.na(del_begin[,1]))
      del_ends <- s %>% str_locate("\\}") 
      del_ends <- which(!is.na(del_ends[,1]))
      
     # Finish this logic: need to extract the del_ends that follows del_begin, then delete those lines from s. 
      
    } ## end if(f == 'functions.R')
    
    
    ## substitute old layer names with new ## JSL Aug 2016; don't think there are any global layers at this point that not needed. comment out bc not working the way we want...
    # lyrs_sc <- read_csv(sprintf('%s/layers.csv', dir_scenario))
    # lyrs_dif = lyrs_sc %>% filter(!layer %in% layer_gl)
    # for (i in 1:nrow(lyrs_dif)){ # i=1
    #   s = str_replace_all(s, fixed(lyrs_dif$layer_gl[i]), lyrs_dif$layer[i])
    # }
    
    writeLines(s, f_out)
    
  } # end for (f in conf_files)
  
  ## swap fields in goals.csv
  goals = read.csv(sprintf('%s/conf/goals.csv', dir_scenario), stringsAsFactors=F)
  for (g in names(goal_swap)){ # g = names(goal_swap)[1]
    for (fld in names(goal_swap[[g]])){
      goals[goals$goal==g, fld] = goal_swap[[g]][[fld]]
    }
  }
  write.csv(goals, sprintf('%s/conf/goals.csv', dir_scenario), row.names=F, na='')
  
  ## copy goals documentation ## TODO JSL revisit: necessary?
  file.copy(sprintf('%s/ohi-webapps/inst/goals.Rmd', dir_github), 
            sprintf('%s/conf/goals.Rmd', dir_scenario), overwrite=T)
  
}
