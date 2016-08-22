## Ning to Add
JSL add this to Ning's TODO issue

- [ ] `/spatial/regions_list.csv`; just so there's a quick reference
- [ ] layers that were empty (could not be populated with template data) have placeholders as the global mean. Suffix=`_glXXXXmean.csv`. I haven't done the downweighting, so there are no _sc2014 layers anymore. 
- [ ] `placeholder` suffixes
- [ ] update mhi/README with updated link to tutorials


Julie TODO: 
- [x] run CHL's calculate_scores.r to see if without _sc2014 it works
   - [x]  fill NAs and save as placeholder layers (warnings below) 
   - [x]  fix other files too (see errors) (did this with some help from Mel and eez2016 layers
   - [ ] look into pressures, resilience matrix stuff  <<-- do this next
- [ ] populate_conf()
- [ ] rethink edit_repos.rmd (should just be scripts called 'repopulate_more_regions' ex)
- [ ] check if can delete /tmp folder with mean swapping stuff in populate_layers()

Calculating Pressures for each region...
There are 6 pressures subcategories: pollution, alien_species, habitat_destruction, fishing_pressure, climate_change, social 
The following `from` values were not present in `x`: x
These goal-elements are in the weighting data layers, but not included in the pressure_matrix.csv:
HAB-1, LIV-1, ECO-1, LIV-2, ECO-2, LIV-3, ECO-3, LIV-4, ECO-4, LIV-5, ECO-5, NP-1, NP-2, NP-3, NP-4, NP-5, NP-6
These goal-elements are in the pressure_matrix.csv, but not included in the weighting data layers:
ECO-aqf, ECO-cf, ECO-mar, ECO-tour, LIV-cf, LIV-mar, LIV-tour, NP-corals, NP-fish_oil, NP-ornamentals, NP-seaweeds, CP-coral, CP-mangrove, CP-saltmarsh, CP-seagrass, CS-mangrove, CS-saltmarsh, CS-seagrass, HAB-coral, HAB-mangrove, HAB-saltmarsh, HAB-seagrass, HAB-soft_bottom, NP-shells, NP-sponges, ECO-mmw, LIV-mmw, LIV-ph, LIV-tran, CP-seaice_shoreline, HAB-seaice_edge, ECO-wte, LIV-wte, LIV-sb
There are 7 Resilience subcategories: ecological, alien_species, goal, fishing_pressure, habitat_destruction, pollution, social
These goal-elements are in the weighting data layers, but not included in the resilience_matrix.csv:
HAB-1, NP-1, NP-2, NP-3, NP-4, NP-5, NP-6
These goal-elements are in the resilience_matrix.csv, but not included in the weighting data layers:
CP-coral, CP-saltmarsh, CP-seagrass, CS-saltmarsh, CS-seagrass, HAB-coral, HAB-saltmarsh, HAB-seagrass, HAB-soft_bottom, NP-corals, NP-fish_oil, NP-ornamentals, NP-seaweeds, CP-mangrove, CS-mangrove, HAB-mangrove, NP-shells, NP-sponges, HAB-seaice_edge, CP-seaice_shoreline
Calculating Goal Score and Likely Future for each region for NP...
  missing pressures dimension, assigning NA!
  missing resilience dimension, assigning NA!
Calculating Goal Score and Likely Future for each region for CS...
  missing pressures dimension, assigning NA!
  missing resilience dimension, assigning NA!
Calculating Goal Score and Likely Future for each region for CP...
  missing pressures dimension, assigning NA!
  missing resilience dimension, assigning NA!
Calculating Goal Score and Likely Future for each region for TR...
Calculating Goal Score and Likely Future for each region for LIV...
  missing pressures dimension, assigning NA!
Calculating Goal Score and Likely Future for each region for ECO...
  missing pressures dimension, assigning NA!
Calculating Goal Score and Likely Future for each region for ICO...
Calculating Goal Score and Likely Future for each region for LSP...
Calculating Goal Score and Likely Future for each region for CW...
Calculating Goal Score and Likely Future for each region for HAB...
  missing pressures dimension, assigning NA!
  missing resilience dimension, assigning NA!
 Warning messages:
1: In left_join_impl(x, y, by$x, by$y, suffix$x, suffix$y) :
  joining factor and character vector, coercing into character vector
2: In left_join_impl(x, y, by$x, by$y, suffix$x, suffix$y) :
  joining factors with different levels, coercing to character vector
3: In left_join_impl(x, y, by$x, by$y, suffix$x, suffix$y) :
  joining factor and character vector, coercing into character vector
4: In left_join_impl(x, y, by$x, by$y, suffix$x, suffix$y) :
  joining factors with different levels, coercing to character vector
5: In left_join_impl(x, y, by$x, by$y, suffix$x, suffix$y) :
  joining factor and character vector, coercing into character vector
6: In min(d$r, na.rm = T) : no non-missing arguments to min; returning Inf
7: In max(d$r, na.rm = T) : no non-missing arguments to max; returning -Inf
8: In min(d$p, na.rm = T) : no non-missing arguments to min; returning Inf
9: In max(d$p, na.rm = T) : no non-missing arguments to max; returning -Inf
...
28
 
Warning messages:
1: In `[<-.factor`(`*tmp*`, thisvar, value = 2016) :
  invalid factor level, NA generated
2: In `[<-.factor`(`*tmp*`, thisvar, value = 2016) :
  invalid factor level, NA generated
3: In CheckLayers(layers_csv, file.path(dir_scenario, "layers"), flds_id = c("rgn_id",  :
  Unused fields...
    ico_spp_iucn_status: iucn_sid
4: In CheckLayers(layers_csv, file.path(dir_scenario, "layers"), flds_id = c("rgn_id",  :
  Rows duplicated...
    ico_spp_iucn_status: 816
5: In CheckLayers(layers_csv, file.path(dir_scenario, "layers"), flds_id = c("rgn_id",  :
  Unused fields...
    ico_spp_iucn_status: iucn_sid
6: In CheckLayers(layers_csv, file.path(dir_scenario, "layers"), flds_id = c("rgn_id",  :
  Rows duplicated...
    ico_spp_iucn_status: 816