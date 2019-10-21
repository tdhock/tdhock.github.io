---
layout: post
title: Tinyverse
description: Complex software dependencies considered harmful
---

Recently I have been working on a new R package
[nc](https://github.com/tdhock/nc) which provides a new syntax for
melting data (converting from wide to tall data tables). I write
"tables" rather than "frames" here because this package actually has a
hard dependency (Imports) on the excellent
[data.table](http://www.r-datatable.com/) package, which provides
an efficient implementation of the melt function. 

Today I noticed that data.table is one of the two packages mentioned
in the "[Getting Started in R -- Tinyverse
Edition](https://github.com/eddelbuettel/gsir-te)" guide published by
[Dirk Eddelbuettel](http://dirk.eddelbuettel.com/). The other package
mentioned in that guide is [ggplot2](https://ggplot2.tidyverse.org/),
which is part of the "tidyverse" in R. The
[Tinyverse](http://www.tinyverse.org/) is a reaction against the
tidyverse, which is notorious for a complex network of
dependencies. The main Tinyverse principle is that hard dependencies
should be limited. For example, another member of the Tinyverse is
[tinytest](https://github.com/markvanderloo/tinytest) which is a
testing framework which has much fewer hard dependencies (actually
only recommended packages that come with every version of R) than the
popular [testthat](https://github.com/r-lib/testthat).

On the one hand, I agree with the tinyverse principle of few
dependencies -- it makes software less complicated to install, and
easier to maintain. On the other hand, some "killer apps" like ggplot2
are really important tools, even if they have a lot of
dependencies. 

Finally [this blog
post](http://dirk.eddelbuettel.com/blog/2018/02/28/#017_dependencies)
by Dirk shows how to compute recursive dependencies. Below I show the
difference between tiny (data.table, essentially no dependencies) and
tidy (ggplot2, 44 hard dependencies).

```
> AP <- available.packages()
> tools::package_dependencies(package=c("data.table", "ggplot2"), recursive=TRUE, db=AP)
$data.table
[1] "methods"

$ggplot2
 [1] "digest"       "grDevices"    "grid"         "gtable"       "lazyeval"    
 [6] "MASS"         "mgcv"         "reshape2"     "rlang"        "scales"      
[11] "stats"        "tibble"       "viridisLite"  "withr"        "graphics"    
[16] "utils"        "methods"      "nlme"         "Matrix"       "splines"     
[21] "plyr"         "Rcpp"         "stringr"      "labeling"     "munsell"     
[26] "R6"           "RColorBrewer" "cli"          "crayon"       "fansi"       
[31] "pillar"       "pkgconfig"    "assertthat"   "lattice"      "colorspace"  
[36] "utf8"         "vctrs"        "glue"         "magrittr"     "stringi"     
[41] "tools"        "backports"    "ellipsis"     "zeallot"     

> packageVersion("data.table")
[1] ‘1.12.5’
> packageVersion("ggplot2")
[1] ‘3.2.0’
> 
```
