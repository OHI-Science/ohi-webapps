---
layout: article
title: "How to modify OHI+ Ecuador"
excerpt: "documentation on getting started"
tags: []
image:
  feature:
  teaser:
  thumb:
toc: true
share: false
---

## Overview

Welcome to OHI+ {{ site.study_area }} (**{{ site.git_repo }}**)!

This website is a starting point for your assessment: it is a template, based on data from the global assessment. To use the Ocean Health Index (OHI) to better capture the local characteristics and priorities of {{ site.study_area }}, you can modify goal models, reevaluate local pressures and resilience, and incorporate the best locally available data, indicators, and cultural preferences. Information to get you started is below; please learn more about how to conduct Ocean Health Index+ assessments at [ohi-science.org](http://ohi-science.org).  


## Purpose

This website was created to facilitate planning and communication for teams conducting OHI+ assessments. All input data and models displayed here are stored at [github.com/{{ site.git_slug }}](https://github.com/{{ site.git_slug }}). GitHub is an online platform for development, sharing and versioning, and stores all information specific to OHI+ {{ site.study_area }} within one place, called a *repository*. Using GitHub will make it possible for multiple members of your team to simulateneously and remotely modify data layers or goal models tracking changes made and by whom. Changes to data layers and goal models will be reflected in this website, [ohi-science.org/{{ site.git_repo }}](http://ohi-science.org/{{ site.git_repo }}), for your whole team to view.

While it is possible to edit data layers and goal models directly from [github.com/{{ site.git_slug }}](https://github.com/{{ site.git_slug }}), we recommend working locally on your own computer and syncing information back to [github.com/{{ site.git_slug }}](https://github.com/{{ site.git_slug }}). Working on their own computers, any member of your team can modify data layers using any software program (Excel, R, etc) and sync back to the online repository using the GitHub application for [Mac](https://mac.github.com/) or [Windows]. Technical changes to goal models will require [R](http://cran.r-project.org/), and we highly recommend also using [RStudio](http://www.rstudio.com/). Please see the Ocean Health Index Toolbox Manual for details about syncing and using GitHub.

** Branches and scenarios **  

GitHub stores all data files and scripts for your OHI+ assessment in a repository ('repo'), which is essentially a folder. Different copies or complements to these folders, called *branches* can also exist, which aid with versioning and drafting. This website displays information for two branches, which are currently identical:

1. [**draft**](https://github.com/{{ site.git_slug }}/tree/draft) branch is for editing. This is the default branch and the main working area where existing scenario data files can be edited and new scenarios added.

1. [**published**](https://github.com/{{ site.git_slug }}/tree/published) branch is a vetted copy of the draft branch, not for direct editing.

...scenarios


## Regions within {{ site.study_area }}

Template data for {{ site.study_area }} has the following subcountry regions, each with a unique ID:

{% capture regions_csv %}regions_{{ site.default_branch_scenario | replace:'/','_' }}{% endcapture %}
{% assign regions = site.data[regions_csv] %}

| ID               | NAME            |
|-----------------:|:----------------|
{% for rgn in regions %}| {{ rgn.region_id }} | {{ rgn.rgn_title }} |
{% endfor %}

The entire study area ({{ site.study_area }}) has a special region ID of 0.  IDs for subcountry regions were assigned geographically by increasing longitude. Exclusive economic zones (EEZs) were identified by [www.marineregions.org/](http://www.marineregions.org/) and the largest subcountry regions were identified by [gadm.org](http://www.gadm.org). Region boundaries were extended offshore to divide the EEZ of {{ site.study_area }} offshore regions. It is possible to use different regions than the ones provided here: see [ohi-science.org/pages/create_regions.html](http://ohi-science.org/pages/create_regions.html) for more details.  
