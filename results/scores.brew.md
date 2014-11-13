---
layout: article
title: "Scores"
excerpt: "OHI scores for <%=study_area%> and regions contained"
share: false
ads: false
branch: <%=branch%>
scenario: <%=scenario%>
toc: true
---

<% 
for (i in 1:nrow(rgns)){
  flower_png  = sprintf('{{ site.baseurl }}/results/%s/%s/figures/flower_%s.png', branch, scenario, gsub(' ','_', rgns$name[i]))
  scores_csv  = sprintf('results/%s/%s/tables/scores_%s.csv'                    , branch, scenario, gsub(' ','_', rgns$name[i]))
  -%>

## <%=rgns$title[i]%> [<%=rgns$id[i]%>]
  
![](<%=flower_png%>)

<%= cat(str_replace(kable(read.csv(scores_csv), format='markdown'), fixed('|X.'), '|  '), sep='\n') %>

<% } -%>
