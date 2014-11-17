---
layout: article
title: "Regions"
excerpt: "OHI regions for <%=study_area%>"
share: false
ads: false
branch_scenario: <%=branch_scenario%>
toc: true
---

Regions are the key spatial units of the Ocean Health Index: scores are calculated for each region and combined, with an offshore area-weighted average, to produce scores for the entire study area of {{ site.study_area }}. 

<%= branch_scenario_navbar %>

<!--script src="https://embed.github.com/view/geojson/<%=git_slug%>/<%=branch_scenario%>/spatial/regions_gcs.geojson"></script-->

![]({{ site.baseurl }}/results/{{ page.branch_scenario }}/figures/regions_600x400.png)

Template data for {{ site.study_area }} has the following subcountry regions, each with a unique ID:

{% capture regions_csv %}regions_{{ page.branch_scenario | replace:'/','_' }}{% endcapture %}
{% assign regions = site.data[regions_csv] %}

| ID               | NAME            |
|-----------------:|:----------------|
{% for rgn in regions %}| {{ rgn.region_id }} | {{ rgn.rgn_title }} |
{% endfor %}

The entire study area ({{ site.study_area }}) has a special region ID of 0.  IDs for subcountry regions were assigned geographically by increasing longitude. Exclusive economic zones (EEZs) were identified by [www.marineregions.org/](http://www.marineregions.org) and the largest subcountry regions were identified by [gadm.org](http://www.gadm.org). Region boundaries were extended offshore to divide the EEZ of {{ site.study_area }} offshore regions. It is possible to use different regions than the ones provided here: see [ohi-science.org/pages/create_regions.html](http://ohi-science.org/pages/create_regions.html) for more details.
