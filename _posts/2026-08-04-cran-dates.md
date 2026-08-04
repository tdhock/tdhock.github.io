---
layout: post
title: Automatic related software tables
description: Parsing CRAN web pages
---



The purpose of this page is to automatically get publication dates off CRAN Archive web pages.

To construct a related work table for a paper, we want publication dates from CRAN packages.

As mentioned in [my previous post](https://data-table-raft.netlify.app/posts/2026-04-15-happy_birthday-toby_hocking/) about `data.table`’s 20th birthday, we can download the CRAN archive meta-data via:


``` r
adb <- tools::CRAN_archive_db()
head(adb)
```

```
## $a11yShiny
##                                   size isdir mode               mtime               ctime               atime  uid  gid
## a11yShiny/a11yShiny_0.1.3.tar.gz 71907 FALSE  664 2026-03-30 15:20:21 2026-07-28 00:04:54 2026-07-28 00:54:13 1010 1001
##                                   uname    grname
## a11yShiny/a11yShiny_0.1.3.tar.gz ligges cranadmin
## 
## $A3
##                     size isdir mode               mtime               ctime               atime  uid  gid  uname
## A3/A3_0.9.1.tar.gz 45252 FALSE  664 2013-02-07 04:00:29 2026-07-28 00:04:52 2026-07-27 20:42:44 1001 1001 hornik
## A3/A3_0.9.2.tar.gz 45907 FALSE  664 2013-03-26 14:58:40 2026-07-28 00:04:52 2026-07-27 20:42:41 1010 1001 ligges
## A3/A3_1.0.0.tar.gz 42810 FALSE  664 2015-08-16 17:05:54 2026-07-28 00:04:52 2026-07-28 01:00:20 1001 1001 hornik
##                       grname
## A3/A3_0.9.1.tar.gz cranadmin
## A3/A3_0.9.2.tar.gz cranadmin
## A3/A3_1.0.0.tar.gz cranadmin
## 
## $a5R
##                         size isdir mode               mtime               ctime               atime  uid  gid  uname
## a5R/a5R_0.2.0.tar.gz 3685016 FALSE  664 2026-03-16 15:10:23 2026-07-28 00:04:54 2026-07-28 01:00:25 1010 1001 ligges
## a5R/a5R_0.3.1.tar.gz 3706043 FALSE  664 2026-03-26 08:30:08 2026-07-28 00:04:54 2026-07-28 01:00:26 1010 1001 ligges
## a5R/a5R_0.4.0.tar.gz 3579867 FALSE  664 2026-05-14 09:00:11 2026-07-28 00:04:54 2026-07-28 00:55:51 1010 1001 ligges
##                         grname
## a5R/a5R_0.2.0.tar.gz cranadmin
## a5R/a5R_0.3.1.tar.gz cranadmin
## a5R/a5R_0.4.0.tar.gz cranadmin
## 
## $aamatch
##                                size isdir mode               mtime               ctime               atime  uid  gid
## aamatch/aamatch_0.3.7.tar.gz 222104 FALSE  664 2025-06-24 05:40:05 2026-07-28 00:04:54 2026-07-28 01:00:36 1010 1001
##                               uname    grname
## aamatch/aamatch_0.3.7.tar.gz ligges cranadmin
## 
## $aaMI
##                        size isdir mode               mtime               ctime               atime uid  gid uname
## aaMI/aaMI_1.0-0.tar.gz 2968 FALSE  664 2005-06-24 11:55:17 2026-07-28 00:04:52 2026-07-28 01:00:34   0 1001  root
## aaMI/aaMI_1.0-1.tar.gz 3487 FALSE  664 2005-10-17 15:24:18 2026-07-28 00:04:52 2026-07-28 01:00:34   0 1001  root
##                           grname
## aaMI/aaMI_1.0-0.tar.gz cranadmin
## aaMI/aaMI_1.0-1.tar.gz cranadmin
## 
## $aaSEA
##                             size isdir mode               mtime               ctime               atime  uid  gid
## aaSEA/aaSEA_1.0.0.tar.gz 1474389 FALSE  664 2019-08-01 05:10:08 2026-07-28 00:04:52 2026-07-28 01:00:34 1010 1001
## aaSEA/aaSEA_1.1.0.tar.gz 1531632 FALSE  664 2019-11-09 11:20:04 2026-07-28 00:04:52 2026-07-28 01:00:36 1010 1001
##                           uname    grname
## aaSEA/aaSEA_1.0.0.tar.gz ligges cranadmin
## aaSEA/aaSEA_1.1.0.tar.gz ligges cranadmin
```

Above we see a list of matrices, one per package.

Below we define the packages of interest by parsing an org-mode readme file using a regular expression.


``` r
(pdt <- nc::capture_all_str(
  "~/projects/sparse-label-positions/README.org",
  " ",
  pkg="[^ ]+?",
  "::"))
```

```
##            pkg
##         <char>
##  1:     monreg
##  2:    fdrtool
##  3:        cir
##  4:        Iso
##  5:       clue
##  6: logcondens
##  7:   sandwich
##  8:     intcox
##  9:       SAGx
## 10:     smacof
## 11:    isotone
## 12:   quadprog
```

Above we see a table with one row per package of interest.

Below we query the current CRAN web pages to determine if each package is currently published.


``` r
pdt[, available := {
  tfile <- file.path(tempdir(), pkg)
  if(!file.exists(tfile)){
    u <- sprintf("https://cloud.r-project.org/web/packages/%s", pkg)
    download.file(u, tfile)
  }
  adt <- nc::capture_all_str(tfile, dl="tar.gz")
  nrow(adt)>0
}, by=pkg][]
```

```
##            pkg available
##         <char>    <lgcl>
##  1:     monreg      TRUE
##  2:    fdrtool      TRUE
##  3:        cir      TRUE
##  4:        Iso      TRUE
##  5:       clue      TRUE
##  6: logcondens      TRUE
##  7:   sandwich      TRUE
##  8:     intcox     FALSE
##  9:       SAGx     FALSE
## 10:     smacof      TRUE
## 11:    isotone      TRUE
## 12:   quadprog      TRUE
```

Above we see that all but two packages are currently available.

Below we create a data table for packages of interest.


``` r
library(data.table)
(time.dt <- pdt[
, as.data.table(adb[[paste(pkg)]])[, .(mtime)], by=.(pkg=factor(pkg, pkg), available)
][
, year := strftime(mtime, "%Y")
][])
```

```
##           pkg available               mtime   year
##        <fctr>    <lgcl>              <POSc> <char>
##   1:   monreg      TRUE 2009-02-25 03:29:22   2009
##   2:   monreg      TRUE 2013-02-14 09:47:21   2013
##   3:   monreg      TRUE 2015-03-04 15:31:32   2015
##   4:   monreg      TRUE 2020-04-26 03:00:11   2020
##   5:   monreg      TRUE 2006-01-30 15:10:27   2006
##  ---                                              
## 256: quadprog      TRUE 2010-04-09 13:30:51   2010
## 257: quadprog      TRUE 2011-05-12 06:25:50   2011
## 258: quadprog      TRUE 2013-04-17 07:42:50   2013
## 259: quadprog      TRUE 2019-04-26 09:21:16   2019
## 260: quadprog      TRUE 2019-05-06 15:00:04   2019
```

Above we see a table with one row per publication time, per package of interest.

Below we reshape to one row per package:


``` r
time.wide <- dcast(
  time.dt,
  pkg + available ~ .,
  list(min, max),
  value.var=c("mtime", "year")
)[
, years := sprintf("%s–%s", year_min, year_max)
][]
time.wide[, .(pkg, available, years)]
```

```
## Key: <pkg, available>
##            pkg available     years
##         <fctr>    <lgcl>    <char>
##  1:     monreg      TRUE 2006–2020
##  2:    fdrtool      TRUE 2006–2021
##  3:        cir      TRUE 2008–2024
##  4:        Iso      TRUE 2008–2020
##  5:       clue      TRUE 2004–2026
##  6: logcondens      TRUE 2006–2023
##  7:   sandwich      TRUE 2004–2026
##  8:     intcox     FALSE 2006–2013
##  9:       SAGx     FALSE 2005–2006
## 10:     smacof      TRUE 2008–2024
## 11:    isotone      TRUE 2009–2023
## 12:   quadprog      TRUE 1999–2019
```

Above we see the packages presented in the same order as they were defined.


``` r
time.wide[order(mtime_min), .(pkg, available, years)]
```

```
##            pkg available     years
##         <fctr>    <lgcl>    <char>
##  1:   quadprog      TRUE 1999–2019
##  2:   sandwich      TRUE 2004–2026
##  3:       clue      TRUE 2004–2026
##  4:       SAGx     FALSE 2005–2006
##  5:     monreg      TRUE 2006–2020
##  6:     intcox     FALSE 2006–2013
##  7:    fdrtool      TRUE 2006–2021
##  8: logcondens      TRUE 2006–2023
##  9:        cir      TRUE 2008–2024
## 10:        Iso      TRUE 2008–2020
## 11:     smacof      TRUE 2008–2024
## 12:    isotone      TRUE 2009–2023
```

Above packages are sorted by first publication date.

Below packages are sorted by last publication date.


``` r
time.wide[order(mtime_max), .(pkg, available, years)]
```

```
##            pkg available     years
##         <fctr>    <lgcl>    <char>
##  1:       SAGx     FALSE 2005–2006
##  2:     intcox     FALSE 2006–2013
##  3:   quadprog      TRUE 1999–2019
##  4:     monreg      TRUE 2006–2020
##  5:        Iso      TRUE 2008–2020
##  6:    fdrtool      TRUE 2006–2021
##  7:    isotone      TRUE 2009–2023
##  8: logcondens      TRUE 2006–2023
##  9:     smacof      TRUE 2008–2024
## 10:        cir      TRUE 2008–2024
## 11:       clue      TRUE 2004–2026
## 12:   sandwich      TRUE 2004–2026
```

## Conclusions

We have shown how to get CRAN publication dates for a list of R packages of interest.

## session info


``` r
sessionInfo()
```

```
## R Under development (unstable) (2026-07-28 r90311)
## Platform: x86_64-pc-linux-gnu
## Running under: Ubuntu 24.04.4 LTS
## 
## Matrix products: default
## BLAS:   /usr/lib/x86_64-linux-gnu/blas/libblas.so.3.12.0 
## LAPACK: /usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.12.0  LAPACK version 3.12.0
## 
## locale:
##  [1] LC_CTYPE=en_US.UTF-8       LC_NUMERIC=C               LC_TIME=fr_FR.UTF-8        LC_COLLATE=en_US.UTF-8    
##  [5] LC_MONETARY=fr_FR.UTF-8    LC_MESSAGES=en_US.UTF-8    LC_PAPER=fr_FR.UTF-8       LC_NAME=C                 
##  [9] LC_ADDRESS=C               LC_TELEPHONE=C             LC_MEASUREMENT=fr_FR.UTF-8 LC_IDENTIFICATION=C       
## 
## time zone: America/Toronto
## tzcode source: system (glibc)
## 
## attached base packages:
## [1] stats     graphics  grDevices utils     datasets  methods   base     
## 
## other attached packages:
## [1] data.table_1.18.4
## 
## loaded via a namespace (and not attached):
## [1] compiler_4.7.0 nc_2026.4.20   cli_3.6.6      tools_4.7.0    knitr_1.51     xfun_0.60      rlang_1.3.0   
## [8] evaluate_1.0.5
```
