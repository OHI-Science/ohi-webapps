# Brief reference for making OHI+ Repos and WebApps
Making Sweet, Sweet WebApps

## Overview

- `ohi-webapps` is an OHI-Science repo that creates all repos and webapps per **'key'**, which identifies the study/assessment area (usually a 3-letter code). Each repo has 4 branches ('draft', 'published', 'app', 'gh-pages'), and .Rproj, .git files, etc. Example repo for Aruba (key = 'abw': [OHI-Science/abw](https://github.com/OHI-Science/abw], example webapp: [ohi-science.org/abw](http://ohi-science.org/abw].
- All functions are stored in:
    + `create_functions.r` -- *all functions for creating and updating repos and webapps*
    + `ohi-travis-functions.r` -- *all functions to update the webapp with Travis*
    + `ohi-functions.r` -- *all functions to update the webapp without Travis*
- Initalizing scripts: 
    + `create_init.r` -- *load all libraries, set directories relevant to all keys* 
    + `create_init_sc.r` -- *load all variables, set directories specific to individual key*  
- Workflow
    + `create_all.r` -- *original by @bbest, create repos and webapps from scratch*
    + `edit_webapps.rmd` -- *by @bbest and @jules32: update existing repos and webapps*
- Other important elements
    + `library(brew)`: brew templates specific to each key (amazingly powerful and super cool)
    + `sprintf`: make strings from strings+variables eg: `source(sprintf('%s/ohi-webapps/create_init_sc.R', dir_github))`
    + `system()`: how you run things on the commandline but from R
    + to be an RStudio project, needs a .Rproj. To be traced by github, needs a .git
    + .yml = 'yet another markdown language'
    + many directories involved in this workflow. Most steps begin with cloning the existing repo to your local workspace `~/github/clip-n-ship` (but `clip-n-ship` is **not** version-controlled
    + `.travis.yml` is how scores are calculated automatically. Still exists for active repos that don't use travis-CI; all branches are blacklisted
    + FITZ is our server that houses the shiny apps: `ssh jstewart@fitz.nceas.ucsb.edu; cd /srv/shiny-server`

## Important directories

- `dir_repos    = '~/github/clip-n-ship` -- *this is **not** version controlled, just a working directory*
- `dir_repo     = '~/github/clip-n-ship/[key]` -- *temporary workspace where the [key] repo is cloned and then developed*
- `dir_annex_sc = file.path(dir_neptune, 'git-annex/clip-n-ship` -- *permanent storage for maps, etc, specific to [key]. subfolders: 'spatial', 'layers', 'gh-pages'*
- `~/tmp/ohi-webapps` and `~/tmp/[key]` -- *where gh-pages branch is brewed and developed*

## Important scripts

## Important variables/.csv files

`sc_studies` variable lists the following info for each key, example below. This variable is generated in `create_init.r` as a combination of searching through global regions combined with information inputted manually in `custom/sc_studies_custom.csv`.


```{r}
tail(sc_studies)
        sc_key            sc_name       sc_key_old gl_rgn_id      gl_rgn_name gl_rgn_key                                        sc_annex_dir
222        gye Golfo de Guayaquil          ecuador       137          Ecuador        ECU        /Volumes/data_edit/git-annex/clip-n-ship/gye
223        chn              China            china       209            China        CHN        /Volumes/data_edit/git-annex/clip-n-ship/chn
224        bhi             Baltic           baltic        NA           Baltic        BHI        /Volumes/data_edit/git-annex/clip-n-ship/bhi
225 ohi-global             Global           global        NA           Global        GLO /Volumes/data_edit/git-annex/clip-n-ship/ohi-global
226        arc             Arctic           arctic        NA           Arctic        ARC        /Volumes/data_edit/git-annex/clip-n-ship/arc
227      ohibc   British Columbia british columbia        NA British Columbia      OHIBC      /Volumes/data_edit/git-annex/clip-n-ship/ohibc
```


## Other tips
+ For @jules32, to search where variables are used or sourced, etc, I find it super helpful to search the whole repo. Can do this from github.com or from Atom (command-shift-F)


## Workflow: create_all.r 

1. `create_gh_repo()`
    + creates the [key] repo on github.com
2. `create_maps()` or `custom_maps()`
    + change shapefiles to `rgn_offshore_gcs.*` in `file.path(dir_annex_sc, key, spatial)`
    + make buffers (inland, offshore)
    + zoom to centroid, save map-images to `file.path(dir_annex_sc, key, gh-pages)`
3. `populate_draft_branch()`
    + clone repo to `dir_repo`
    + initialize README.md
    + create and rename draft and published branches
    + brew README.md
    + add .Rproj and .git files
    + create scenario folder + subfolders: tmp, conf, layers, spatial, prep
        + scenario folder = `subcountry2014` or `custom from `custom/sc_studies_custom.csv`
    + change shapefiles to .json and .geojson (script from `ohicore`)    
    + copy layers
    + rename rgn_ids from global to subcountry
    + swap out certain files stored in `dir_annex_sc`
    + downweight appropriately based on `disagg(?)` column in Google Drive `layers_global`
    + drop LE layers (use OHI+ version)
    + check layers, populate empty layers with global average, save file indicating this
    + copy config files: `config.r`, `functions.r` (swap LE), `goals.rmd`, `pressures_matrix.csv`,  `resilience_matrix.csv
    + brew `.travis.yml`
    + make prep subfolders per goal and pressures/resilience, populate with READMEs
