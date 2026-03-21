---
layout: post
title: Asypmptotic timing of text parsing
description: Regular expressions exercise
---



The purpose of this page is to compare efficiency of different methods for parsing text.

## Problem

I recently wrote the test code below,


``` r
sacct.txt <- system.file(
  package="slurm", "extdata", "sacct-e-rorqual-2026-03-20.txt", mustWork=TRUE)
computed <- slurm::sacct_fields(paste("cat", sacct.txt))
sacct.lines <- readLines(sacct.txt)
expected <- strsplit(gsub(" +", " ", paste(sacct.lines, collapse=" ")), " ")[[1]]
identical(computed, expected)
```

```
## [1] TRUE
```

Are the two methods comparable speed?

## Test

The atime package allows us to see differences in computation time as a function of data size.


``` r
ares <- atime::atime(
  setup={
    Nlines <- rep(sacct.lines, N)
  },
  seconds.limit = 0.1,
  do.call=do.call(c, strsplit(Nlines, " +")),
  unlist=unlist(strsplit(Nlines, " +")),
  strsplit=strsplit(paste(Nlines, collapse=" "), " +")[[1]],
  capture_all_str=nc::capture_all_str(Nlines, field="\\w+")$field)
plot(ares)
```

![plot of chunk atime](/assets/img/2026-03-20-atime-regex/atime-1.png)

We can see above that there are some constant factor time and memory differences.

## session info


``` r
sessionInfo()
```

```
## R Under development (unstable) (2026-02-07 r89380)
## Platform: x86_64-pc-linux-gnu
## Running under: Ubuntu 24.04.4 LTS
## 
## Matrix products: default
## BLAS:   /usr/lib/x86_64-linux-gnu/blas/libblas.so.3.12.0 
## LAPACK: /usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.12.0  LAPACK version 3.12.0
## 
## locale:
##  [1] LC_CTYPE=en_US.UTF-8       LC_NUMERIC=C               LC_TIME=fr_FR.UTF-8       
##  [4] LC_COLLATE=en_US.UTF-8     LC_MONETARY=fr_FR.UTF-8    LC_MESSAGES=en_US.UTF-8   
##  [7] LC_PAPER=fr_FR.UTF-8       LC_NAME=C                  LC_ADDRESS=C              
## [10] LC_TELEPHONE=C             LC_MEASUREMENT=fr_FR.UTF-8 LC_IDENTIFICATION=C       
## 
## time zone: America/Toronto
## tzcode source: system (glibc)
## 
## attached base packages:
## [1] stats     graphics  grDevices utils     datasets  methods   base     
## 
## loaded via a namespace (and not attached):
##  [1] directlabels_2025.6.24 vctrs_0.7.1            knitr_1.51             cli_3.6.5             
##  [5] xfun_0.56              rlang_1.1.7            otel_0.2.0             bench_1.1.4           
##  [9] generics_0.1.4         S7_0.2.1               data.table_1.18.2.1    glue_1.8.0            
## [13] nc_2026.2.20           scales_1.4.0           quadprog_1.5-8         grid_4.6.0            
## [17] evaluate_1.0.5         tibble_3.3.1           profmem_0.7.0          lifecycle_1.0.5       
## [21] compiler_4.6.0         dplyr_1.2.0            RColorBrewer_1.1-3     pkgconfig_2.0.3       
## [25] atime_2025.9.30        farver_2.1.2           lattice_0.22-9         R6_2.6.1              
## [29] tidyselect_1.2.1       pillar_1.11.1          slurm_2026.3.20        magrittr_2.0.4        
## [33] tools_4.6.0            withr_3.0.2            gtable_0.3.6           ggplot2_4.0.2
```
