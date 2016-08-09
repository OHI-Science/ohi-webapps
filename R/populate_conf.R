# populate_conf.r

populate_conf <- function(key=key) {
  
  ## create conf folder
  dir.create(file.path(dir_repo, default_scenario, 'conf'))
  
  ## list conf files to copy
  conf_files = c('config.R','functions.R','goals.csv',
                 'pressures_matrix.csv','resilience_matrix.csv',
                 'pressure_categories.csv', 'resilience_categories.csv')
  
  for (f in conf_files){ # f = conf_files[1]
    
    f_in  = sprintf('%s/conf/%s', dir_global, f)
    f_out = sprintf('conf/%s', f)
    
    # read in file
    s = readLines(f_in, warn=F, encoding='UTF-8')
    
    # ## update confugration
    # if (f=='config.R'){
    #   
    #   ## get map centroid and zoom level
    #   # TODO: save this to separate map file...
    #   # TODO: would be great to set this info when making maps so center is reset if map changes, not sure that's feasible...
    #   # TODO: http://gis.stackexchange.com/questions/76113/dynamically-set-zoom-level-based-on-a-bounding-box
    #   # var regions_group = new L.featureGroup(regions); map.fitBounds(regions_group.getBounds());
    #   p_shp  = file.path(dir_annex_sc, 'spatial', 'rgn_offshore_gcs.shp')
    #   p      = rgdal::readOGR(dirname(p_shp), tools::file_path_sans_ext(basename(p_shp)))
    #   p_bb   = data.frame(p@bbox) # max of 2.25
    #   p_ctr  = rowMeans(p_bb)
    #   p_zoom = 12 - as.integer(cut(max(transmute(p_bb, range = max - min)), 
    #                                c(0, 0.25, 0.5, 1, 2.5, 5, 10, 20, 40, 80, 160, 320, 360)))
    #   
    #   ## set map center and zoom level
    #   s = s %>%
    #     str_replace("map_lat.*", sprintf('map_lat=%g; map_lon=%g; map_zoom=%d', 
    #                                      p_ctr['y'], p_ctr['x'], p_zoom)) # updated JSL to overwrite any map info
    #   
    #   ## use just rgn_labels (not rgn_global)
    #   s = gsub('rgn_global', 'rgn_labels', s)
    # } 
    
    ## swap out custom functions
    if (f=='functions.R'){
      
      ## TODO: delete PreGlobalScores(): https://github.com/OHI-Science/ohicore/blob/master/R/CalculateAll.R#L217-L221
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
      
      
      ## rethink because ref points stuff might be useful. will find this: write.csv(d_check, sprintf('temp/cs_data_%s.csv', scenario), row.names=FALSE)    
      s <-  s %>%
        str_replace("write.csv\\(tmp, 'temp/.*", '') %>%
        str_replace('^.*sprintf\\(\'temp\\/.*', '')
      
    }
    
    ## substitute old layer names with new
    lyrs_dif = lyrs_sc %>% filter(!layer %in% layer_gl) # changed from layer != layer_gl JSL 08-24-2015
    for (i in 1:nrow(lyrs_dif)){ # i=1
      s = str_replace_all(s, fixed(lyrs_dif$layer_gl[i]), lyrs_dif$layer[i])
    }
    
    writeLines(s, f_out)
    
  } # end for (f in conf_files)
  
  ## swap fields in goals.csv
  goals = read.csv('conf/goals.csv', stringsAsFactors=F)
  for (g in names(goal_swap)){ # g = names(goal_swap)[1]
    for (fld in names(goal_swap[[g]])){
      goals[goals$goal==g, fld] = goal_swap[[g]][[fld]]
    }
  }
  write.csv(goals, 'conf/goals.csv', row.names=F, na='')
  
  ## copy goals documentation ## JSL revisit: necessary?
  file.copy(file.path(dir_github, 'ohi-webapps/subcountry2014/conf/goals.Rmd'), 'conf/goals.Rmd', overwrite=T)
  
}
