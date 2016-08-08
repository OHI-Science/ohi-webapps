# populate_layers.r

populate_layers <- function(key=key, lyrs_gl=lyrs_gl, default_scenario=default_scenario, 
                            sfx_global=sfx_global, 
                            multi_nation=multi_nation){
  
  ## clone repo and remotes
  clone_repo()  
  
  ## create layers folder
  dir.create(file.path(dir_repo, default_scenario, 'layers'))
  
  ## copy layers.csv from global ----
  write.csv(lyrs_gl, sprintf('%s/tmp/layers_%s.csv', default_scenario, sfx_global), 
            na='', row.names=F)
  
  ## modify tmp/layers.csv -- RETHINK THIS!! JSL July 2016
  lyrs_sc = lyrs_gl %>%
    select(
      targets, layer, filename, fld_value, units,
      name, description,
      starts_with('clip_n_ship')) %>%
    mutate(
      layer_gl = layer,
      path_in  = file.path(dir_global, 'layers', filename),
      rgns_in  = 'global',
      filename = sprintf('%s_%s.csv', layer, sfx_global)) %>%
    arrange(targets, layer)
  
  ## swap out custom mar_coastalpopn_inland25mi for mar_coastalpopn_inland25km (NOTE: mi -> km)
  ix = which(lyrs_sc$layer=='mar_coastalpopn_inland25mi')
  lyrs_sc$layer[ix]       = 'mar_coastalpopn_inland25km'
  lyrs_sc$path_in[ix]     = file.path(dir_annex, key, 'layers', 'mar_coastalpopn_inland25km_lyr.csv')
  lyrs_sc$name[ix]        = str_replace(lyrs_sc$name[ix]       , fixed('miles'), 'kilometers')
  lyrs_sc$description[ix] = str_replace(lyrs_sc$description[ix], fixed('miles'), 'kilometers')
  lyrs_sc$filename[ix]    = 'mar_coastalpopn_inland25km_sc2014-raster.csv'
  lyrs_sc$rgns_in[ix]     = 'subcountry'
  
  # swap out spatial area layers
  area_layers = c('rgn_area'= 'rgn_offshore_data.csv')
  
  for (lyr in names(area_layers)){
    csv = area_layers[lyr]
    ix = which(lyrs_sc$layer==lyr)
    lyrs_sc$rgns_in[ix]     = 'subcountry'
    lyrs_sc$path_in[ix]     = file.path(dir_annex_sc, 'spatial', csv)
    lyrs_sc$filename[ix]    = str_replace(lyrs_sc$filename[ix], fixed('_gl2014.csv'), '_sc2014-area.csv')
  }
  
  TODO: check why rgn_area had rownames--need readr::write_csv()
  - PASTE rgn_labels somewhere more useful
  - change subcountry2014!
    - copy_webapps_templates.r
  
  ## drop cntry_* layers
  lyrs_sc = filter(lyrs_sc, !grepl('^cntry_', layer))
  
  ## drop all layers no longer being used (especially LE)
  lyrs_le_rm = c(
    'le_gdp_pc_ppp','le_jobs_cur_adj_value','le_jobs_cur_base_value','le_jobs_ref_adj_value','le_jobs_ref_base_value',
    'le_rev_cur_adj_value','le_rev_cur_base_value','le_rev_cur_base_value','le_rev_ref_adj_value','le_rev_ref_base_value',
    'le_rev_sector_year','le_revenue_adj','le_wage_cur_adj_value','le_wage_cur_base_value','le_wage_ref_adj_value',
    'le_wage_ref_base_value','liveco_status','liveco_trend', 
    'cntry_rgn', 'cntry_georegions')
  lyrs_sc = filter(lyrs_sc, !layer %in% lyrs_le_rm)
  
  
  ## match OHI+ regions to global regions ----
  sc_rgns = read.csv(file.path(dir_annex_sc, 'spatial', 'rgn_offshore_data.csv')) %>%
    select(sc_rgn_id   = rgn_id,
           sc_rgn_name = rgn_name) %>%
    mutate(gl_rgn_name = name) %>%
    merge(
      gl_rgns %>%
        select(gl_rgn_name, gl_rgn_id),
      by='gl_rgn_name', all.x=T) %>%
    select(sc_rgn_id, sc_rgn_name, gl_rgn_id, gl_rgn_name) %>%
    arrange(sc_rgn_name)
  
  ## if OHI+ match not possible...
  if (all(is.na(sc_rgns$gl_rgn_id))){
    sc_rgns = sc_rgns %>%
      select(-gl_rgn_id) %>%
      left_join(sc_studies %>%
                  select(gl_rgn_name = sc_name, gl_rgn_id),
                by= 'gl_rgn_name')
  }
  
  ## old global regions to new OHI+ regions -- proper setup for all cases
  sc_cntry = gl_cntries %>%
    select(gl_cntry_key, gl_rgn_id) %>%
    merge(
      sc_rgns,
      by='gl_rgn_id') %>%
    group_by(gl_cntry_key, sc_rgn_id) %>%
    summarise(n=n()) %>%
    select(cntry_key = gl_cntry_key, sc_rgn_id) %>%
    as.data.frame()
  
  if (!multi_nation) {
    
    ## old global to new custom countries
    if (dim(sc_cntry)[1] != dim(sc_rgns)[1]) { # make sure Guayaquil doesn't match to both ECU and Galapagos
      sc_cntries = subset(sc_studies, sc_key == key, gl_rgn_key, drop=T)
      sc_cntry = sc_cntry %>%
        filter(cntry_key %in% sc_cntries)
    }
    
    ## for each layer (not multi_nation)...
    for (lyr in lyrs_sc$layer){ # lyr = "ao_access"
      
      ## call copy_layer and write to layer to csv
      d <- copy_layer(lyr, sc_cntry,
                      global_rgn_id = unique(sc_rgns$gl_rgn_id),
                      write_to_csv  = TRUE)
    }
    
  } else { # multi_nation == TRUE
    
    ## overwrite sc_rgns if multi_nation
    sc_rgns_lookup <- read.csv(sprintf('~/github/ohi-webapps/custom/%s/sc_rgns_lookup.csv', key))
    sc_rgns = sc_rgns_lookup %>%
      merge(
        gl_rgns %>%
          select(gl_rgn_name, gl_rgn_id),
        by='gl_rgn_name', all.x=T) %>%
      select(sc_rgn_id, sc_rgn_name, gl_rgn_id, gl_rgn_name) %>%
      arrange(sc_rgn_name)
    
    ## old global to multi_nation
    sc_cntry = sc_cntry %>%
      group_by(cntry_key) %>%
      filter(row_number() == 1) %>%
      ungroup()
    if (dim(sc_cntry)[1] != dim(sc_rgns)[1]) { # so GYE doesn't match both ECU+Galapagos
      sc_cntry = sc_cntry %>%
        filter(cntry_key %in% unique(sc_rgns_lookup$gl_rgn_key))
    }
    
    ## for each layer...(multi_nation)
    for (lyr in lyrs_sc$layer){ # lyr = "ao_access" 
      
      ## call copy_layer and then write to layer to csv as separate step
      d <- copy_layer(lyr, sc_cntry,
                      global_rgn_id = unique(sc_rgns$gl_rgn_id), 
                      write_to_csv  = FALSE) 
      if ('rgn_id' %in% names(d)) d = d %>% arrange(rgn_id)
      
      ## write to csv as separate step
      csv_out = sprintf('layers/%s', lyrs_sc$filename[lyrs_sc$layer == lyr])
      write_csv(d, csv_out)
      
    }
  } ## end if (!multi_nation)
  
  ## create layers.csv registry ----
  lyrs_reg = lyrs_sc %>%
    select(
      targets,
      layer,
      filename,
      fld_value,
      units,
      name,
      description,
      clip_n_ship_disag,
      clip_n_ship_disag_description,
      layer_gl,
      path_in)
  write.csv(lyrs_reg, 'layers.csv', row.names=F, na='')

  ## check for empty layers
  CheckLayers('layers.csv', 'layers',
              flds_id=c('rgn_id','country_id','saup_id','fao_id','fao_saup_id')) ##TODO: check if necessary
  lyrs = read.csv('layers.csv', na='')
  lyrs_empty = filter(lyrs, data_na==T)
  if (nrow(lyrs_empty) > 0){
    dir.create('tmp/layers-empty_global-values', showWarnings=F)
    write.csv(lyrs_empty, 'layers-empty_swapping-global-mean.csv', row.names=F, na='')
  }

  ## populate empty layers with global averages. ## TODO see if a better way...
  for (lyr in subset(lyrs, data_na, layer, drop=T)){ # lyr = subset(lyrs, data_na, layer, drop=T)[1]

    message(' for empty layer ', lyr, ', getting global avg')

    ## get all global data for layer
    l = subset(lyrs, layer==lyr)
    csv_gl  = as.character(l$path_in)
    csv_tmp = sprintf('tmp/layers-empty_global-values/%s', l$filename)
    csv_out = sprintf('layers/%s', l$filename)
    file.copy(csv_gl, csv_tmp, overwrite=T)
    a = read.csv(csv_tmp)

    ## calculate global categorical means using non-standard evaluation, ie dplyr::*_()
    fld_key         = names(a)[1]
    fld_value       = names(a)[ncol(a)]
    flds_other = setdiff(names(a), c(fld_key, fld_value))

    if (class(a[[fld_value]]) %in% c('factor','character') & l$fld_val_num == fld_value){
      cat(sprintf('  DOH! For empty layer "%s" field "%s" is factor/character but registered as [fld_val_num] not [fld_val_chr].\n', lyr, fld_value))
    }

    ## exceptions
    if (lyr == 'mar_trend_years'){
      sc_rgns %>%
        mutate(trend_yrs = '5_yr') %>%
        select(rgn_id = sc_rgn_id, trend_yrs) %>%
        arrange(rgn_id) %>%
        write.csv(csv_out, row.names=F, na='')

      next
    }

    if (class(a[[fld_value]]) %in% c('factor','character')){
      cat(sprintf('  DOH! For empty layer "%s" field "%s" is factor/character but continuing with presumption of numeric.\n', lyr, fld_value))
    }

    ## presuming numeric...
    ## get mean
    #if (lyr == 'mar_coastalpopn_inland25km') browser()
    if (length(flds_other) > 0){
      b = a %>%
        group_by_(.dots=flds_other) %>%
        summarize_(
          .dots = setNames(
            sprintf('mean(%s, na.rm=T)', fld_value),
            fld_value))
    } else {
      b = a %>%
        summarize_(
          .dots = setNames(
            sprintf('mean(%s, na.rm=T)', fld_value),
            fld_value))
    }

    ## bind many rgn_ids
    if ('rgn_id' %in% names(a) | 'cntry_key' %in% names(a)){
      b = b %>%
        merge(
          sc_rgns %>%  
            select(rgn_id = sc_rgn_id),
          all=T) %>%
        select(one_of('rgn_id', flds_other, fld_value)) %>%
        arrange(rgn_id)
    }

    #if (lyr == 'mar_harvest_tonnes') browser()
    write.csv(b, csv_out, row.names=F, na='')

  } # end for (lyr in subset(lyrs, data_na, layer, drop=T))

  ## update layers.csv with empty layers now populated by global averages
  CheckLayers('layers.csv', 'layers',
              flds_id=c('rgn_id','country_id','saup_id')) ##,'fao_id','fao_saup_id'))

  ## someday fix these warnings that happened with COL July 2016
# Warning messages:
# 1: In CheckLayers("layers.csv", "layers", flds_id = c("rgn_id", "country_id",  :
# Missing files...these files are not found in the layers folder
# rgn_labels: rgn_labels_gl2016.csv
# 2: In CheckLayers("layers.csv", "layers", flds_id = c("rgn_id", "country_id",  :
# Unused fields...
# fis_b_bmsy: taxon_name
# fis_meancatch: taxon_name_key
# rgn_area: rgn_name
# 3: In CheckLayers("layers.csv", "layers", flds_id = c("rgn_id", "country_id",  :
# Rows duplicated...
# fis_b_bmsy: 69951
# fis_meancatch: 108700
# ico_spp_extinction_status: 9
# ico_spp_popn_trend: 9

}

# calculate_scores.r, install_ohicore