# Brief reference for making OHI+ Repos and WebApps
Making Sweet, Sweet WebApps. 
See below for @bbest developer notes

## Overview

- **`ohi-webapps` is an OHI-Science repo that creates all repos and webapps per **'key'**, which identifies the study/assessment area (usually a 3-letter code). Each repo has 4 branches ('draft', 'published', 'app', 'gh-pages'), and .Rproj, .git files, etc. Example repo for Aruba (key = 'abw': [OHI-Science/abw](https://github.com/OHI-Science/abw), example webapp: [ohi-science.org/abw](http://ohi-science.org/abw).**
- **All functions are stored in**:
    + `create_functions.r` -- *all functions for creating and updating repos and webapps*
    + `ohi-travis-functions.r` -- *all functions to update the webapp with Travis*
    + `ohi-functions.r` -- *all functions to update the webapp without Travis*
- **Initalizing scripts**: 
    + `create_init.r` -- *load all libraries, set directories relevant to all keys* 
    + `create_init_sc.r` -- *load all variables, set directories specific to individual key*  
- **Workflow**:
    + `create_all.r` -- *original by @bbest, create repos and webapps from scratch*
    + `edit_webapps.rmd` -- *by @bbest and @jules32: update existing repos and webapps*
- **Other important elements**
    + `library(brew)`: brew templates specific to each key (amazingly powerful and super cool)
    + `sprintf`: make strings from strings+variables eg: `source(sprintf('%s/ohi-webapps/create_init_sc.R', dir_github))`
    + `system()`: how you run things on the commandline but from R
    + to be an RStudio project, needs a .Rproj. To be traced by github, needs a .git
    + `.yml` = 'yet another markdown language'
    + many directories involved in this workflow. Most steps begin with cloning the existing repo to your local workspace `~/github/clip-n-ship` (but `clip-n-ship` is **not** version-controlled
    + `.travis.yml` is how scores are calculated automatically. Still exists for active repos that don't use travis-CI; all branches are blacklisted
    + `FITZ` is our server that houses the shiny apps: `ssh jstewart@fitz.nceas.ucsb.edu; cd /srv/shiny-server`

## Important directories

- `dir_repos    = '~/github/clip-n-ship` -- *this is **not** version controlled, just a working directory*
- `dir_repo     = '~/github/clip-n-ship/[key]` -- *<span style = "color:pink">temporary workspace where the [key] repo is cloned and then developed</span>*
- `dir_annex_sc = file.path(dir_neptune, 'git-annex/clip-n-ship` -- *<span style = "color:green">permanent storage for maps, etc, specific to [key]. subfolders: 'spatial', 'layers', 'gh-pages'</span>*
- `~/tmp/ohi-webapps` and `~/tmp/[key]` -- *<span style = "color:blue">where gh-pages branch is brewed and developed</span>*

## Important scripts

- `create_all.r` -- *original by @bbest, create repos and webapps from scratch*
- `edit_webapps.rmd` -- *by @bbest and @jules32: update existing repos and webapps*

## Important variables/.csv files

- `sc_studies` variable lists the following info for each key, example below. This variable is generated in `create_init.r` as a combination of searching through global regions combined with information inputted manually in `custom/sc_studies_custom.csv`.


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
Functions are from `create_functions.r` unless otherwise noted

1. `create_gh_repo()`
    + creates the [key] repo on github.com
2. `create_maps()` or `custom_maps()`
    + <span style = "color:green">change shapefiles</span> to `rgn_offshore_gcs.*` in `file.path(dir_annex_sc, key, spatial)`
    + make buffers (inland, offshore)
    + zoom to centroid, save map-images to `file.path(dir_annex_sc, key, gh-pages)`
3. `populate_draft_branch()`
    + <span style = "color:pink">clone repo</span>
    + initialize README.md
    + create and rename draft and published branches
    + brew README.md
    + add .Rproj and .git files
    + create scenario folder + subfolders: tmp, conf, layers, spatial, prep
        + scenario folder = `subcountry2014` or custom from `custom/sc_studies_custom.csv`
    + change shapefiles to .json and .geojson (script from `ohicore`)    
    + copy layers
    + rename rgn_ids from global to subcountry
    + swap out certain files stored in `dir_annex_sc`
    + downweight appropriately based on `disagg(?)` column in Google Drive `layers_global`
    + drop LE layers (use OHI+ version)
    + check layers, populate empty layers with global average, save file indicating this
    + copy config files: `config.r`, `functions.r` (swap LE), `goals.rmd`, `pressures_matrix.csv`,  `resilience_matrix.csv`
    + brew `.travis.yml`
    + make prep subfolders per goal and pressures/resilience, populate with READMEs
4. `push_branch()` -- from `ohi-travis-functions.r` or `ohi-functions.r`
5. `calculate_scores()` or `calculate_scores_notravis()` -- from `ohi-travis-functions.r` or `ohi-functions.r`
6. `create_results()` or `update_results()` -- from `ohi-travis-functions.r` or `ohi-functions.r`
    + <span style = "color:pink">draft branch</span>, find `^scores.csv$`
    + get goal weightings and scores
    + make flower plots
    + make table 
7. `push_branch()` -- from `ohi-travis-functions.r` or `ohi-functions.r`
    + `merge_published_branch()`
8. `populate_website` or `update_website`
    + <span style = "color:pink">checkout gh-pages branch</span>
    + copy templates from ohi-webapps/gh-pages
    + copy maps, images, national flag
    + brew config and README
    + add .Rproj, .git
9. `create_pages` or `update_pages()` -- from `ohi-travis-functions.r` or `ohi-functions.r`    
    + <span style = "color:pink">pull draft branch</span>
    + git owner stuff
    + copy gh-pages: regions, layers, goals, scores, navbar (check if any OHI+ updates)
    + <span style = "color:blue">clone repo and all branches</span>, archive
    + checkout gh-pages
    + copy tables and figs
    + brew gh-pages regions, layers, goals, scores, navbar
    + push gh-pages
    + update internal status log
10. `deploy_app_nceas()` -- *previously `deploy_app()` was used to push to RStudio Shiny server
    + <span style = "color:pink">clone repo</span>, checkout app branch
    + copy shiny app files from `ohicore`
    + get version commit
    + brew `app.yml`, `.travis.yml`
    + add .Rproj
    + system() delete chn from `fitz`
    + system() deploy to fitz, chmod, chown
    + push app!

# ohi-webapps developer notes (@bbest)


Deploy OHI web apps

## Discussion

Main elements:
- [Subcountry front page sketch](https://github.com/OHI-Science/ohi-webapps/blob/master/tmp/gh-pages_sketch.png)
    - banner like [Adv GIS course site](http://ucsb-bren.github.io/esm296-4f/), except image of country map having buffers like [OHI-Israel regions](https://github.com/OHI-Science/ohi-israel#regions) using ggmap with stamen gray background (see [create_map_banner.R](https://github.com/OHI-Science/ohi-webapps/blob/master/create_map_banner.R) and a [tiltshift effect](http://www.fmwconcepts.com/imagemagick/tiltshift/index.php) applied for snazz
    - use snazzy sizable icons from [Font Awesome](http://fortawesome.github.io/Font-Awesome/) and [Octicons](https://octicons.github.com/) to describe components wrapped in tidy boxes
    - use tidy boxes. See http://bootswatch.com for free bootstrap themes. See http://jekyllthemes.org, http://startbootstrap.com/template-overviews/clean-blog/, http://startbootstrap.com/template-overviews/small-business/, http://www.blacktie.co/demo/solid/, http://jekyllthemes.org/themes/skinny-bones/, https://github.com/dbtek/jekyll-bootstrap-3 using kramdown, http://getbootstrap.com/getting-started/, http://www.stephaniehicks.com/githubPages_tutorial/pages/githubpages-jekyll.html, https://github.com/kbroman/simple_site, http://www.carlboettiger.info/2012/12/30/learning-jekyll.html, http://virtuallyhyper.com/2014/05/migrate-from-wordpress-to-jekyll/, https://github.com/plusjade/jekyll-bootstrap, https://github.com/yannickwurm/bootstrapy. See clean gh-pages examples from [P2PU course templates](http://howto.p2pu.org/modules/start/your-own-course/): [Intro to Python](http://mechanicalmooc.org/), [LCL](http://learn.media.mit.edu/lcl/)
    - use [Jekyll variables](http://jekyllrb.com/docs/github-pages/) and [Metadata from Github](https://help.github.com/articles/repository-metadata-on-github-pages/) to template the pages
    - take advantage of other [Github allowed Jekyll plugins](https://help.github.com/articles/using-jekyll-plugins-with-github-pages/) + [sitemap](https://help.github.com/articles/sitemaps-for-github-pages/) with [kramdown](https://help.github.com/articles/migrating-your-pages-site-from-maruku/) parser
    - on seperate page embed iframe of shinyapps with black nav bar at top like [OHI-Science.org](OHI-Science.org). See initial physically constrained version at [http://ohi-science.org/ohi-albania/](ohi-science.org/ohi-albania), but want unconstrained more like [OHI Ecuador App](https://ohi-science.shinyapps.io/ecuador/).
    - include travis-ci linked build status image like (https://travis-ci.org/OHI-Science/ohi-ecuador.svg?branch=master)
- [Home - OHI-Science.org](http://ohi-science.org/) - to add: "Subcountry" page listing countries, status, map and link to site

TODO next round:

- While downweighting by area_offshore, area_offshore_3nm, and population_inland25km have been handled, as listed in the clip_n_ship_disag column of [layers_global](https://docs.google.com/a/nceas.ucsb.edu/spreadsheet/ccc?key=0At9FvPajGTwJdEJBeXlFU2ladkR6RHNvbldKQjhiRlE&usp=drive_web&pli=1#gid=0), the following categories are still unhandled: raster, raster | area_inland1km, raster | area_offshore, raster | area_offshore3nm, raster | equal (see [create_all.R]( https://github.com/OHI-Science/ohi-webapps/blob/612f31da32ae66165a27f5f3132fb05b268fd027/create_all.R#L370))

TODO seperately:

- fix broken links now reported by html-proofer in new [travis-ci build of ohi-science.org](https://travis-ci.org/OHI-Science/ohi-science.github.io)


Other cool icons for potential use:

- Fonts Awesome: [rocket](http://fortawesome.github.io/Font-Awesome/icon/rocket/), [pencil edit](http://fortawesome.github.io/Font-Awesome/icon/pencil-square-o/), [gamepad](http://fortawesome.github.io/Font-Awesome/icon/gamepad/), [puzzle-piece/](http://fortawesome.github.io/Font-Awesome/icon/puzzle-piece/), [wrench](http://fortawesome.github.io/Font-Awesome/icon/wrench/), [bolt](http://fortawesome.github.io/Font-Awesome/icon/bolt/), [eye](http://fortawesome.github.io/Font-Awesome/icon/eye/), [fire](http://fortawesome.github.io/Font-Awesome/icon/fire/), [beaker flask](http://fortawesome.github.io/Font-Awesome/icon/flask/), [?](http://fortawesome.github.io/Font-Awesome/icon/question/), [water drop](http://fortawesome.github.io/Font-Awesome/icon/tint/) 
- Octicons: [forked](https://octicons.github.com/icon/repo-forked/), [cloud-upload](https://octicons.github.com/icon/cloud-upload/), [cloud-download](https://octicons.github.com/icon/cloud-download/), [repo-clone](https://octicons.github.com/icon/repo-clone/), [rocket](https://octicons.github.com/icon/rocket/), [squirrel](https://octicons.github.com/icon/squirrel/)
- [Bootstrap Glyphicons](http://glyphicons.bootstrapcheatsheets.com/) and [more](http://marcoceppi.github.io/bootstrap-glyphicons/)
