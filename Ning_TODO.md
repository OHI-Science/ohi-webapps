## Ning to Add
JSL add this to Ning's TODO issue

- [ ] `/spatial/regions_list.csv`; just so there's a quick reference
- [ ] layers that were empty (could not be populated with template data) have placeholders as the global mean. Suffix=`_glXXXXmean.csv`. I haven't done the downweighting, so there are no _sc2014 layers anymore. 


Julie TODO: 
- [ ] run CHL's calculate_scores.r to see if without _sc2014 it works
   - check for files all NA (warnings below), and fix other files too (see errors)
- [ ] populate_conf()
- [ ] rethink edit_repos.rmd (should just be scripts called 'repopulate_more_regions' ex)
- [ ] check if can delete /tmp folder with mean swapping stuff in populate_layers()

placeholder layers: 

- le_wage_sector_year --->>>>le_wage_sector_year_gl2016mean.csv in layers.csv register
 
Warning messages:
1: In min(d$year, na.rm = T) :
  no non-missing arguments to min; returning Inf
2: In max(d$year, na.rm = T) :
  no non-missing arguments to max; returning -Inf
3: In min(d$year, na.rm = T) :
  no non-missing arguments to min; returning Inf
4: In max(d$year, na.rm = T) :
  no non-missing arguments to max; returning -Inf
5: In ohicore::CheckLayers("layers.csv", "layers", flds_id = conf$config$layers_id_fields) :
  Missing files...these files are not found in the layers folder
    rgn_labels: rgn_labels_gl2016.csv
6: In ohicore::CheckLayers("layers.csv", "layers", flds_id = conf$config$layers_id_fields) :
  Unused fields...
    ico_spp_iucn_status: iucn_sid
7: In ohicore::CheckLayers("layers.csv", "layers", flds_id = conf$config$layers_id_fields) :
  Rows duplicated...
    ico_spp_iucn_status: 816
8: In ohicore::CheckLayers("layers.csv", "layers", flds_id = conf$config$layers_id_fields) :
  Layers missing data, ie all NA ...
    le_wage_sector_year: le_wage_sector_year_gl2016.csv
    np_blast: np_blast_gl2016.csv
    np_cyanide: np_cyanide_gl2016.csv
    fp_art_hb: fp_art_hb_gl2016.csv
    hd_subtidal_hb: hd_subtidal_hb_gl2016.csv
    element_wts_cp_km2_x_protection: element_wts_cp_km2_x_protection_gl2016.csv
    element_wts_cs_km2_x_storage: element_wts_cs_km2_x_storage_gl2016.csv
    tr_travelwarnings: tr_travelwarnings_gl2016.csv
    
Errors: layers = ohicore::Layers('layers.csv', 'layers')
Layer element_wts_cp_km2_x_protection has no rows of data.
Layer element_wts_cs_km2_x_storage has no rows of data.
Layer fp_art_hb has no rows of data.
Layer hd_subtidal_hb has no rows of data.
Layer le_wage_sector_year has no rows of data.
Layer np_blast has no rows of data.
Layer np_cyanide has no rows of data.
Error in file(file, "rt") : cannot open the connection
In addition: Warning message:
In file(file, "rt") :
  cannot open file 'layers/rgn_labels_gl2016.csv': No such file or directory    
    
Error::scores = ohicore::CalculateAll(conf, layers)
Running Setup()...
Calculating Status and Trend for each region for FIS...
Calculating Status and Trend for each region for MAR...
95th percentile for MAR ref pt is: 0.0746978761490516

95th percentile rgn_id for MAR ref pt is: 1

Calculating Status and Trend for each region for AO...
Calculating Status and Trend for each region for NP...
Calculating Status and Trend for each region for CS...
 Error in eval(expr, envir, enclos) : object 'status' not found     
    
sc_rgns
   sc_rgn_id                    sc_rgn_name gl_rgn_id gl_rgn_name
1         11                          Aisén       224       Chile
2          2                    Antofagasta       224       Chile
3          9                      Araucanía       224       Chile
4         15             Arica y Parinacota       224       Chile
5          3                        Atacama       224       Chile
6          8                        Bío-Bío       224       Chile
7          4                       Coquimbo       224       Chile
8         17                  Easter Island       224       Chile
9         16 Juan Fernandez y Desventuradas       224       Chile
10        10                      Los Lagos       224       Chile
11        14                       Los Ríos       224       Chile
12        12                     Magallanes       224       Chile
13         7                          Maule       224       Chile
14         6                      O'Higgins       224       Chile
15         1                       Tarapacá       224       Chile
16         5                     Valparaíso       224       Chile

sc_cntry
       cntry_key sc_rgn_id
1            CHL         1
2            CHL         2
3            CHL         3
4            CHL         4
5            CHL         5
6            CHL         6
7            CHL         7
8            CHL         8
9            CHL         9
10           CHL        10
11           CHL        11
12           CHL        12
13           CHL        14
14           CHL        15
15           CHL        16
16           CHL        17
17 Easter Island         1
18 Easter Island         2
19 Easter Island         3
20 Easter Island         4
21 Easter Island         5
22 Easter Island         6
23 Easter Island         7
24 Easter Island         8
25 Easter Island         9
26 Easter Island        10
27 Easter Island        11
28 Easter Island        12
29 Easter Island        14
30 Easter Island        15
31 Easter Island        16
32 Easter Island        17