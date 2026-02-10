---
layout: post
title: Markdown links to bibtex
description: Regular expressions exercise
---



The purpose of this page is to convert markdown links to bibtex using regular expressions.

## Problem

I am using markdown (actually quarto) to write two online "books"

* [Animated interactive data visualization using animint2 in R](https://animint-manual-en.netlify.app/)
* [Visualisation interactive de données dans R avec animint2](https://animint-manual-fr.netlify.app/)

Including hyperlinks in markdown is via the syntax

```
[text that will appear](hyperlink)
```

This works fine for HTML output, where we can click the link.
But in PDF output we get blue text, and the link is lost when the document is printed.
An example is shown below.

![french and english links](/assets/img/2026-02-10/links-diff.png)

* left we see the French version with bibtex references.
* right we see the English version with markdown hyperlinks.
* top we see the web page output.
* bottom we see the PDF output (and https URL in references section of French version).

I already wrote a CI script [test-references.R](https://github.com/animint/animint-manual-en/pull/19) that errors if it finds markdown links.


``` r
chapters <- "~/R/animint-manual-en/chapters"
qmd.files <- c(
  Sys.glob(file.path(chapters, "*qmd"),
  Sys.glob(file.path(chapters, "*/index.qmd"))
library(data.table)
violations <- list()
for(qmd in qmd.files){
  link_dt <- nc::capture_all_str(
    qmd,
    "\\]\\(",
    url="http.*?",
    "\\)")
  if(nrow(link_dt)){
    violations[[qmd]] <- link_dt$url
  }
}
print(violations)
```

```
## Error in parse(text = input): <text>:5:1: unexpected symbol
## 4:   Sys.glob(file.path(chapters, "*/index.qmd"))
## 5: library
##    ^
```

The goal of this post is to write a conversion to bibtex.
The source code to find is `please consult our [wiki FAQ](https://github.com/tdhock/animint2/wiki/FAQ#web-browser-on-local-indexhtml-file-is-blank)`.
We want to change it to

```
please consult our wiki FAQ [@animintFAQ]
```

```bib
@unpublished{animintFAQ,
  title={Animint FAQ},
  author={Toby Hocking},
  url={https://github.com/tdhock/animint2/wiki/FAQ#web-browser-on-local-indexhtml-file-is-blank},
  year={2025}
}
```

## one link


``` r
qmd_lines <- readLines(qmd)
```

```
## Error:
## ! object 'qmd' not found
```

``` r
link_dt <- nc::capture_all_str(
  qmd,
  "\\]\\(",
  url="http.*?",
  "\\)")
```

```
## Error:
## ! object 'qmd' not found
```

## session info


``` r
sessionInfo()
```

```
## R version 4.5.2 (2025-10-31 ucrt)
## Platform: x86_64-w64-mingw32/x64
## Running under: Windows 11 x64 (build 26100)
## 
## Matrix products: default
##   LAPACK version 3.12.1
## 
## locale:
## [1] LC_COLLATE=English_United States.utf8 
## [2] LC_CTYPE=English_United States.utf8   
## [3] LC_MONETARY=English_United States.utf8
## [4] LC_NUMERIC=C                          
## [5] LC_TIME=English_United States.utf8    
## 
## time zone: America/Toronto
## tzcode source: internal
## 
## attached base packages:
## [1] stats     graphics  utils     datasets  grDevices methods   base     
## 
## loaded via a namespace (and not attached):
##  [1] compiler_4.5.2    nc_2025.3.24      cli_3.6.5         tools_4.5.2      
##  [5] pillar_1.11.1     otel_0.2.0        glue_1.8.0        vctrs_0.7.0      
##  [9] data.table_1.18.0 knitr_1.51        xfun_0.56         lifecycle_1.0.5  
## [13] rlang_1.1.7       evaluate_1.0.5
```
