# Workflow for creating custom WebApps

1. Add the custom region to the lookup table: `~/github/ohi-webapps/tmp/gl_rgn_custom.csv`
1. Add an empty folder in git-annex on Neptune: e.g.
`git-annex/clip-n-ship/gye`

1. run `create_custom.r`
```
# create github repo
repo = create_gh_repo(key)
```

2. `process_rasters.r` creates all of the coastal pop clips by year--time consuming. But it relies on already having the inland and offshore buffers clipped. Has the function make_sc_coastpop_lyr(), which will downweight.
3. `create_subcountry_regions.py` joins each country to its gadm region and extracts. This is what creates a lot of the files in the `spatial` folder above, and also does thiessen polygons, etc.  
4. `create_all.r` actually builds the webapp once all other pieces are in place (layers, spatial, etc)
5. `create_parallel.r` seems to be very similar to `create_all.r`; one may supersede the other


Will need to work with `lyrs_gl` from `create_int.r`

and `sc_studies`

sc_key sc_name sc_key_old gl_rgn_id gl_rgn_name gl_rgn_key                            sc_annex_dir
1    abw   Aruba      aruba       250       Aruba        ABW /var/data/ohi/git-annex/clip-n-ship/abw

create_functions::populate_draft_branch clones the repo already on github--what creates those repos?
