---
layout: article
title: "Layers"
excerpt: "OHI layers for <%=study_area%>"
share: false
ads: false
branch_scenario: <%=branch%>/<%=scenario%>
toc: true
---

The following data layers are used in Ocean Health Index calculations for goal status, trend, pressures, and resilience. Values for {{ site.study_area }} were extracted from the global assessment and saved for each region to serve as a template as you gather higher-resolution data and indicators. Note that many values do not have a range because they were equally extracted from the global data layer.

<%
library(dplyr)
library(markdown)

d = arrange(read.csv(file.path(dir_archive, branch_scenario, 'layers.csv'), stringsAsFactors=F), layer)

for (i in 1:nrow(d)){ -%>

## <%=d$layer[i]%>

<%=d$name[i]%>

| metadata          | value                                                                |
|-------------------|----------------------------------------------------------------------|
| filename          | <%=d$filename[i]%>                                                   |
| value units       | <%=d$units[i]%>                                                      |
| value range       | <%=d$val_min[i]%> to <%=d$val_max[i]%>                               |
| global extraction | <%=d$clip_n_ship_disag[i]%>: <%=d$clip_n_ship_disag_description[i]%> |

<%=renderMarkdown(file=NULL, output=NULL, text=d$description[i])%>

<%} -%>
