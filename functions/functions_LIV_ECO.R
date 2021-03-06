LIV_ECO = function(layers, subgoal){
  
  ## read in all data: gdp, wages, jobs and workforce_size data 
  le_gdp   = SelectLayersData(layers, layers='le_gdp')  %>%
    dplyr::select(rgn_id = id_num, year, gdp_usd = val_num)
  
  le_wages = SelectLayersData(layers, layers='le_wage_sector_year') %>%
    dplyr::select(rgn_id = id_num, year, sector = category, wage_usd = val_num)
  
  le_jobs  = SelectLayersData(layers, layers='le_jobs_sector_year') %>%
    dplyr::select(rgn_id = id_num, year, sector = category, jobs = val_num)
  
  le_workforce_size = SelectLayersData(layers, layers='le_workforcesize_adj') %>%
    dplyr::select(rgn_id = id_num, year, jobs_all = val_num)
  
  le_unemployment = SelectLayersData(layers, layers='le_unemployment') %>%
    dplyr::select(rgn_id = id_num, year, pct_unemployed = val_num)
  
  
  # multipliers from Table S10 (Halpern et al 2012 SOM)
  multipliers_jobs = data.frame('sector' = c('tour','cf', 'mmw', 'wte','mar'), 
                                'multiplier' = c(1, 1.582, 1.915, 1.88, 2.7)) # no multiplers for tour (=1)
  # multipliers_rev  = data.frame('sector' = c('mar', 'tour'), 'multiplier' = c(1.59, 1)) # not used because GDP data is not by sector
  
  
  # calculate employment counts
  le_employed = le_workforce_size %>%
    left_join(le_unemployment, by = c('rgn_id', 'year')) %>%
    mutate(proportion_employed = (100 - pct_unemployed) / 100, 
           employed            = jobs_all * proportion_employed)
  
  # reworded from SOM p.26-27
  #reference point for wages is the reference region (r) with the highest average wages across all sectors. 
  #Reference points for jobs (j) and revenue (e) employ a moving baseline. The two metrics (j, e) are calculated
  #as relative values: the value in the current year (or most recent year), c, relative to the value in a recent 
  #moving reference period, r, defined as 5 years prior to c. This reflects an implicit goal of maintaining coastal
  #livelihoods and economies (L&E) on short time scales, allowing for decadal or generational shifts in what people 
  #want and expect for coastal L&E. The most recent year c must be 2000 or later in order for the data to be included.
  
  liv =
    # adjust jobs
    le_jobs %>%
    left_join(multipliers_jobs, by = 'sector') %>%
    mutate(jobs_mult = jobs * multiplier) %>%  # adjust jobs by multipliers
    left_join(le_employed, by= c('rgn_id', 'year')) %>%
    mutate(jobs_adj = jobs_mult * proportion_employed) %>% # adjust jobs by proportion employed
    left_join(le_wages, by=c('rgn_id','year','sector')) %>%
    arrange(year, sector, rgn_id)
  
  # LIV calculations ----
  
  # LIV status
  liv_status = liv %>%
    filter(!is.na(jobs_adj) & !is.na(wage_usd))
  # aia/subcountry2014 crashing b/c no concurrent wage data, so adding this check
  if (nrow(liv_status)==0){
    liv_status = liv %>%
      dplyr::select(region_id=rgn_id) %>%
      group_by(region_id) %>%
      summarize(
        goal      = 'LIV',
        dimension = 'status',
        score     = NA)
    liv_trend = liv %>%
      dplyr::select(region_id=rgn_id) %>%
      group_by(region_id) %>%
      summarize(
        goal      = 'LIV',
        dimension = 'trend',
        score     = NA)
  } else {
    liv_status = liv_status %>%
      filter(year >= max(year, na.rm=T) - 4) %>% # reference point is 5 years ago
      arrange(rgn_id, year, sector) %>%
      # summarize across sectors
      group_by(rgn_id, year) %>%
      summarize(
        # across sectors, jobs are summed
        jobs_sum  = sum(jobs_adj, na.rm=T),
        # across sectors, wages are averaged
        wages_avg = mean(wage_usd, na.rm=T)) %>%
      group_by(rgn_id) %>%
      arrange(rgn_id, year) %>%
      mutate(
        # reference for jobs [j]: value in the current year (or most recent year) [c], relative to the value in a recent moving reference period [r] defined as 5 years prior to [c]
        jobs_sum_first  = first(jobs_sum),                     # note:  `first(jobs_sum, order_by=year)` caused segfault crash on Linux with dplyr 0.3.0.2, so using arrange above instead
        # original reference for wages [w]: target value for average annual wages is the highest value observed across all reporting units
        # new reference for wages [w]: value in the current year (or most recent year) [c], relative to the value in a recent moving reference period [r] defined as 5 years prior to [c]
        wages_avg_first = first(wages_avg)) %>% # note:  `first(jobs_sum, order_by=year)` caused segfault crash on Linux with dplyr 0.3.0.2, so using arrange above instead
      # calculate final scores
      ungroup() %>%
      mutate(
        x_jobs  = pmax(-1, pmin(1,  jobs_sum / jobs_sum_first)),
        x_wages = pmax(-1, pmin(1, wages_avg / wages_avg_first)),
        score   = mean(c(x_jobs, x_wages), na.rm=T) * 100) %>%
      # filter for most recent year
      filter(year == max(year, na.rm=T)) %>%
      # format
      dplyr::select(
        region_id = rgn_id,
        score) %>%
      mutate(
        goal      = 'LIV',
        dimension = 'status')
    
    # LIV trend
    # From SOM p. 29: trend was calculated as the slope in the individual sector values (not summed sectors)
    # over the most recent five years...
    # with the average weighted by the number of jobs in each sector
    # ... averaging slopes across sectors weighted by the revenue in each sector
    
    # get trend across years as slope of individual sectors for jobs and wages
    liv_trend = liv %>%
      filter(!is.na(jobs_adj) & !is.na(wage_usd)) %>%
      # TODO: consider "5 year time spans" as having 5 [(max(year)-4):max(year)] or 6 [(max(year)-5):max(year)] member years
      filter(year >= max(year, na.rm=T) - 4) %>% # reference point is 5 years ago
      # get sector weight as total jobs across years for given region
      arrange(rgn_id, year, sector) %>%
      group_by(rgn_id, sector) %>%
      mutate(
        weight = sum(jobs_adj, na.rm=T)) %>%
      # reshape into jobs and wages columns into single metric to get slope of both with one do() call
      reshape2::melt(id=c('rgn_id','year','sector','weight'), variable='metric', value.name='value') %>%
      mutate(
        sector = as.character(sector),
        metric = as.character(metric)) %>%
      # get linear model coefficient per metric
      group_by(metric, rgn_id, sector, weight) %>%
      do(mdl = lm(value ~ year, data=.)) %>%
      summarize(
        metric = metric,
        weight = weight,
        rgn_id = rgn_id,
        sector = sector,
        # TODO: consider how the units affect trend; should these be normalized? cap per sector or later?
        sector_trend = pmax(-1, pmin(1, coef(mdl)[['year']] * 5))) %>%
      arrange(rgn_id, metric, sector) %>%
      # get weighted mean across sectors per region-metric
      group_by(metric, rgn_id) %>%
      summarize(
        metric_trend = weighted.mean(sector_trend, weight, na.rm=T)) %>%
      # get mean trend across metrics (jobs, wages) per region
      group_by(rgn_id) %>%
      summarize(
        score = mean(metric_trend, na.rm=T)) %>%
      # format
      mutate(
        goal      = 'LIV',
        dimension = 'trend') %>%
      dplyr::select(
        goal, dimension,
        region_id = rgn_id,
        score)
  }
  
  
  # ECO calculations ----
  eco = le_gdp %>%
    mutate(
      rev_adj = gdp_usd,
      sector = 'gdp') %>% 
    # adjust rev with national GDP rates if available. Example: (rev_adj = gdp_usd / ntl_gdp) 
    dplyr::select(rgn_id, year, sector, rev_adj)
  
  # ECO status
  eco_status = eco %>%
    filter(!is.na(rev_adj)) %>%
    filter(year >= max(year, na.rm=T) - 4) %>% # reference point is 5 years ago
    # across sectors, revenue is summed
    group_by(rgn_id, year) %>%
    summarize(
      rev_sum  = sum(rev_adj, na.rm=T)) %>%
    # reference for revenue [e]: value in the current year (or most recent year) [c], relative to the value in a recent moving reference period [r] defined as 5 years prior to [c]  
    arrange(rgn_id, year) %>%
    group_by(rgn_id) %>%
    mutate(
      rev_sum_first  = first(rev_sum)) %>%
    # calculate final scores
    ungroup() %>%
    mutate(
      score  = pmin(rev_sum / rev_sum_first, 1) * 100) %>%
    # get most recent year
    filter(year == max(year, na.rm=T)) %>%
    # format
    mutate(
      goal      = 'ECO',
      dimension = 'status') %>%
    dplyr::select(
      goal, dimension,
      region_id = rgn_id,
      score)
  
  # ECO trend
  eco_trend = eco %>%
    filter(!is.na(rev_adj)) %>%
    filter(year >= max(year, na.rm=T) - 4 ) %>% # 5 year trend
    # get sector weight as total revenue across years for given region
    arrange(rgn_id, year, sector) %>%
    group_by(rgn_id, sector) %>%
    mutate(
      weight = sum(rev_adj, na.rm=T)) %>%
    # get linear model coefficient per region-sector
    group_by(rgn_id, sector, weight) %>%
    do(mdl = lm(rev_adj ~ year, data=.)) %>%
    summarize(
      weight = weight,
      rgn_id = rgn_id,
      sector = sector,
      # TODO: consider how the units affect trend; should these be normalized? cap per sector or later?
      sector_trend = pmax(-1, pmin(1, coef(mdl)[['year']] * 5))) %>%
    # get weighted mean across sectors per region
    group_by(rgn_id) %>%
    summarize(
      score = weighted.mean(sector_trend, weight, na.rm=T)) %>%
    # format
    mutate(
      goal      = 'ECO',
      dimension = 'trend') %>%
    dplyr::select(
      goal, dimension,
      region_id = rgn_id,
      score)
  
  # report LIV and ECO scores separately
  if (subgoal=='LIV'){
    d = rbind(liv_status, liv_trend)
  } else if (subgoal=='ECO'){
    d = rbind(eco_status, eco_trend)
  } else {
    stop('LIV_ECO function only handles subgoal of "LIV" or "ECO"')
  }
  return(d)
  
}
