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
cat(renderMarkdown(normalizePath(goals_Rmd), output=NULL))
%>

<script>
// add bootstrap table styles to pandoc tables
$(document).ready(function () {
  $('tr.header').parent('thead').parent('table').addClass('table table-condensed');
});

// dynamically load mathjax for compatibility with self-contained
(function () {
  var script = document.createElement("script");
  script.type = "text/javascript";
  script.src  = "https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML";
  document.getElementsByTagName("head")[0].appendChild(script);
})();
</script>
