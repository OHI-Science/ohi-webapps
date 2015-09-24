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
    + `system()`: how you run things on the commandline but from R
    + many directories involved in this workflow. Most steps begin with cloning the existing repo to your local workspace `~/github/clip-n-ship` (but `clip-n-ship` is **not** version-controlled
    + `.travis.yml` is how scores are calculated automatically. Still exists for active repos that don't use travis-CI; all branches are blacklisted
    + FITZ is our server that houses the shiny apps: `ssh jstewart@fitz.nceas.ucsb.edu; cd /srv/shiny-server`

## Important directories

- `dir_repos    = '~/github/clip-n-ship` -- *this is **not** version controlled, just a working directory*
- `dir_repo     = '~/github/clip-n-ship/[key]` -- *temporary workspace where the [key] repo is cloned and then developed*
- `dir_annex_sc = file.path(dir_neptune, 'git-annex/clip-n-ship` -- *permanent storage for maps, etc, specific to [key]. subfolders: 'spatial', 'layers', 'gh-pages'*
- `~/tmp/ohi-webapps` and `~/tmp/[key]` -- *where gh-pages branch is brewed and developed*

## Important scripts

## Important .csv files

## Workflow: create_all.r 