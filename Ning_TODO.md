## Ning to Add
JSL add this to Ning's TODO issue

- [ ] layers_meta.csv instructions


Julie TODO: 
- [ ] update ohirepos::deploy_website to also work without a scenario folder
- [ ] update ohirepos::create_repo_map.R for brittleness .shp. TODO if statement. Also see if so many copies are necessary..
- [ ] update process for custom folder map checks. Revisit
- [x] update edit_repos.rmd with pace of ohirepos (get rid of _source_and_load.r)
- [x] delete R/ scripts that are in ohirepos
- [ ] transfer from ohi-functions.r to ohirepos
- [ ] check config.r post Shiny https://github.com/OHI-Science/bhi/blob/draft/baltic2015/conf/config.R#L25-L27
- [ ] populate_conf() -- PreGlobalScores etc.
    - [ ] check functions.r; had to delete ICO gapfilling section for Northeast
- [ ] check if can delete /tmp folder with mean swapping stuff in populate_layers()
- [ ] revisit create_init and create_init_sc and make more lightweight
- [ ] move to ohirepos
- [ ] deal with /reports, which isn't created now (and not deleted by unpopulate_layers_conf.r)
- [ ] check why couldn't create ohibc map:  Error in ogrInfo(dsn = dsn, layer = layer, encoding = encoding, use_iconv = use_iconv,  : Cannot open layer 
- [ ] confirm nothing needed from create_functions.r - update_draft()
- [ ] populate layers: had to update hd_subtidal_hb with 0's for Northeast


can-atl push error: 
remote: error: GH001: Large files detected. You may want to try Git Large File Storage - https://git-lfs.github.com.        
remote: error: Trace: f4757c4ae37d6fdd17f2608d95b779d4        
remote: error: See http://git.io/iEPt8g for more information.        
remote: error: File region2017/spatial/regions_gcs.geojson is 111.49 MB; this exceeds GitHub's file size limit of 100.00 MB        
remote: error: File region2017/spatial/regions_gcs.js is 111.49 MB; this exceeds GitHub's file size limit of 100.00 MB        
To https://4c3d120bf1af113d108093fc7452fa8411acb9f4@github.com/OHI-Science/can-atl.git
 ! [remote rejected] HEAD -> master (pre-receive hook declined)
error: failed to push some refs to 'https://4c3d120bf1af113d108093fc7452fa8411acb9f4@github.com/OHI-Science/can-atl.git'
> system('git pull')