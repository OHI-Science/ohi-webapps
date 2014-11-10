---
layout: article
title: "Scores"
excerpt: "OHI scores for <%=country%> and regions contained"
share: false
ads: false
branch: <%=branch%>
scenario: <%=scenario%>
toc: true
---

<% 
library(dplyr)
library(knitr)

for (rgn_id in rgns){
  rgn_name    = subset(rgn_names, region_id==rgn_id, rgn_name, drop=T) 
  dir_results = sprintf('{{ site.baseurl }}/results/%s/%s', branch, scenario)
  flower_png  = sprintf('%s/figures/flower_%s.png', dir_results, gsub(' ','_', rgn_name))
  scores_csv  = sprintf('%s/tables/scores_%s.csv', dir_results, gsub(' ','_', rgn_name))  
  -%>

## <%=rgn_name%> [<%=rgn_id%>]
  
![](<%=flower_png%>)

<%=scores_csv -> kable(format='markdown') %>

<% } -%>