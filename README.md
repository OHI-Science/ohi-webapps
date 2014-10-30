ohi-webapps
=================

Deploy OHI web apps

## Discussion

Main elements:
- [Subcountry front page sketch](https://github.com/OHI-Science/ohi-webapps/blob/master/tmp/gh-pages_sketch.png) - front page sketch
    - banner like [Adv GIS course site](http://ucsb-bren.github.io/esm296-4f/), except image of country map having buffers like [OHI-Israel regions https://github.com/OHI-Science/ohi-israel#regions] using ggmap with stamen gray background (see [create_map_banner.R](https://github.com/OHI-Science/ohi-webapps/blob/master/create_map_banner.R) and a [tiltshift effect](http://www.fmwconcepts.com/imagemagick/tiltshift/index.php) applied for snazz
    - use snazzy sizable icons from [Font Awesome](http://fortawesome.github.io/Font-Awesome/) and [Octicons](https://octicons.github.com/) to describe components wrapped in tidy boxes
    - use tidy boxes. see clean gh-pages examples from [P2PU course templates](http://howto.p2pu.org/modules/start/your-own-course/): [Intro to Python](http://mechanicalmooc.org/), [LCL](http://learn.media.mit.edu/lcl/
    - use [Jekyll variables](http://jekyllrb.com/docs/github-pages/) and [Metadata from Github](https://help.github.com/articles/repository-metadata-on-github-pages/) to template the pages
    - take advantage of other [Github allowed Jekyll plugins](https://help.github.com/articles/using-jekyll-plugins-with-github-pages/) + [sitemap](https://help.github.com/articles/sitemaps-for-github-pages/) with [kramdown](https://help.github.com/articles/migrating-your-pages-site-from-maruku/) parser
    - on seperate page embed iframe of shinyapps with black nav bar at top like [OHI-Science.org](OHI-Science.org). See initial physically constrained version at [http://ohi-science.org/ohi-albania/](ohi-science.org/ohi-albania), but want unconstrained more like [OHI Ecuador App](https://ohi-science.shinyapps.io/ecuador/).
    - include travis-ci linked build status image like [![](https://travis-ci.org/OHI-Science/ohi-ecuador.svg?branch=master)](https://travis-ci.org/OHI-Science/ohi-ecuador)
- [Home - OHI-Science.org](http://ohi-science.org/) - to add: "Subcountry" page listing countries, status, map and link to site

TODO next round:

- While downweighting by area\_offshore, area\_offshore\_3nm, and population\_inland25km have been handled, as listed in the clip\_n\_ship\_disag column of [layers\_global](https://docs.google.com/a/nceas.ucsb.edu/spreadsheet/ccc?key=0At9FvPajGTwJdEJBeXlFU2ladkR6RHNvbldKQjhiRlE&usp=drive_web&pli=1#gid=0), the following categories are still unhandled: raster, raster | area\_inland1km, raster | area\_offshore, raster | area\_offshore3nm, raster | equal (see [create\_all.R]( https://github.com/OHI-Science/ohi-webapps/blob/612f31da32ae66165a27f5f3132fb05b268fd027/create_all.R#L370))
- 

TODO seperately:

- fix broken links now reported by html-proofer in new [travis-ci build of ohi-science.org](https://travis-ci.org/OHI-Science/ohi-science.github.io)
