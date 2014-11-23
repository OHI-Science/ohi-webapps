---
layout: article
title: "Goals"
excerpt: "OHI goals for <%=study_area%>"
share: false
ads: false
branch_scenario: <%=branch%>/<%=scenario%>
toc: true
output: html_document
---

The following goal models are from the global assessment in 2014. These models should be modified when better data or indicators are available.

<%= branch_scenario_navbar %>

<%
# render goals to html
library(rmarkdown)

goals_Rmd = file.path(dir_archive, branch_scenario, 'conf/goals.Rmd')
f_tmp     = tempfile()

render(goals_Rmd, 
  html_document(
    toc=F, smart=T, self_contained=F, theme='default', mathjax='default', template='default', css=NULL, includes=NULL, keep_md=F, lib_dir = NULL, pandoc_args = NULL), 
  output_file=f_tmp)
cat(suppressWarnings(readLines(f_tmp)))
unlink(f_tmp)
%>


