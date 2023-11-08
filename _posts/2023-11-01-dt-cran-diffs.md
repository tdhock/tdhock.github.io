---
layout: post
title: data.table CRAN diffs
description: Verifying consistency between CRAN and github
---



As a part of my NSF POSE funded project about expanding the ecosystem
of users and contributors around the `data.table` package in R, it
will be important to create tools that increase developer confidence
in the release process. One tool that could be useful is monitoring
the CRAN code to see if it is consistent with the corresponding tag in
the github repo. In this post I aim to create a proof of concept. 

## Getting old versions from CRAN archive

The data.table cran archive is

https://cran.r-project.org/src/contrib/Archive/data.table/

A [previous post](https://tdhock.github.io/blog/2022/release-history/)
explained how to parse the Archive, which we do using the code below:


```r
R.dir <- "~/R"
Archive.dir <- file.path(R.dir, "Archive")
dir.create(Archive.dir, showWarnings = FALSE)
Archive.url <- "https://cloud.r-project.org/src/contrib/Archive/"
get_Archive <- function(Package){
  pkg.html <- file.path(Archive.dir, paste0(Package, ".html"))
  if(!file.exists(pkg.html)){
    u <- paste0(Archive.url, Package)
    download.file(u, pkg.html)
  }
  nc::capture_all_str(
    pkg.html,
    tar.gz=list(
      paste0(Package, "_"),
      version="[0-9.-]+",
      "[.]tar[.]gz"),
    "</a>\\s+",
    date.str=".*?",
    "\\s"
  )[order(date.str)]
}
(Archive.dt <- get_Archive("data.table"))
```

```
##                         tar.gz  version   date.str
##  1:      data.table_1.0.tar.gz      1.0 2006-04-14
##  2:      data.table_1.1.tar.gz      1.1 2008-08-27
##  3:      data.table_1.2.tar.gz      1.2 2008-09-01
##  4:    data.table_1.4.1.tar.gz    1.4.1 2010-05-03
##  5:      data.table_1.5.tar.gz      1.5 2010-09-14
##  6:    data.table_1.5.1.tar.gz    1.5.1 2011-01-08
##  7:    data.table_1.5.2.tar.gz    1.5.2 2011-01-21
##  8:    data.table_1.5.3.tar.gz    1.5.3 2011-02-11
##  9:      data.table_1.6.tar.gz      1.6 2011-04-24
## 10:    data.table_1.6.1.tar.gz    1.6.1 2011-06-29
## 11:    data.table_1.6.2.tar.gz    1.6.2 2011-07-02
## 12:    data.table_1.6.3.tar.gz    1.6.3 2011-08-04
## 13:    data.table_1.6.4.tar.gz    1.6.4 2011-08-10
## 14:    data.table_1.6.5.tar.gz    1.6.5 2011-08-25
## 15:    data.table_1.6.6.tar.gz    1.6.6 2011-08-25
## 16:    data.table_1.7.1.tar.gz    1.7.1 2011-10-22
## 17:    data.table_1.7.2.tar.gz    1.7.2 2011-11-07
## 18:    data.table_1.7.3.tar.gz    1.7.3 2011-11-25
## 19:    data.table_1.7.4.tar.gz    1.7.4 2011-11-29
## 20:    data.table_1.7.5.tar.gz    1.7.5 2011-12-04
## 21:    data.table_1.7.6.tar.gz    1.7.6 2011-12-13
## 22:    data.table_1.7.7.tar.gz    1.7.7 2011-12-15
## 23:    data.table_1.7.8.tar.gz    1.7.8 2012-01-25
## 24:    data.table_1.7.9.tar.gz    1.7.9 2012-01-31
## 25:   data.table_1.7.10.tar.gz   1.7.10 2012-02-07
## 26:    data.table_1.8.0.tar.gz    1.8.0 2012-07-16
## 27:    data.table_1.8.2.tar.gz    1.8.2 2012-07-17
## 28:    data.table_1.8.4.tar.gz    1.8.4 2012-11-09
## 29:    data.table_1.8.6.tar.gz    1.8.6 2012-11-13
## 30:    data.table_1.8.8.tar.gz    1.8.8 2013-03-06
## 31:   data.table_1.8.10.tar.gz   1.8.10 2013-09-03
## 32:    data.table_1.9.2.tar.gz    1.9.2 2014-02-27
## 33:    data.table_1.9.4.tar.gz    1.9.4 2014-10-02
## 34:    data.table_1.9.6.tar.gz    1.9.6 2015-09-19
## 35:    data.table_1.9.8.tar.gz    1.9.8 2016-11-25
## 36:   data.table_1.10.0.tar.gz   1.10.0 2016-12-03
## 37:   data.table_1.10.2.tar.gz   1.10.2 2017-01-31
## 38:   data.table_1.10.4.tar.gz   1.10.4 2017-02-01
## 39: data.table_1.10.4-1.tar.gz 1.10.4-1 2017-10-09
## 40: data.table_1.10.4-2.tar.gz 1.10.4-2 2017-10-12
## 41: data.table_1.10.4-3.tar.gz 1.10.4-3 2017-10-27
## 42:   data.table_1.11.0.tar.gz   1.11.0 2018-05-01
## 43:   data.table_1.11.2.tar.gz   1.11.2 2018-05-08
## 44:   data.table_1.11.4.tar.gz   1.11.4 2018-05-27
## 45:   data.table_1.11.6.tar.gz   1.11.6 2018-09-19
## 46:   data.table_1.11.8.tar.gz   1.11.8 2018-09-30
## 47:   data.table_1.12.0.tar.gz   1.12.0 2019-01-13
## 48:   data.table_1.12.2.tar.gz   1.12.2 2019-04-07
## 49:   data.table_1.12.4.tar.gz   1.12.4 2019-10-03
## 50:   data.table_1.12.6.tar.gz   1.12.6 2019-10-18
## 51:   data.table_1.12.8.tar.gz   1.12.8 2019-12-09
## 52:   data.table_1.13.0.tar.gz   1.13.0 2020-07-24
## 53:   data.table_1.13.2.tar.gz   1.13.2 2020-10-19
## 54:   data.table_1.13.4.tar.gz   1.13.4 2020-12-08
## 55:   data.table_1.13.6.tar.gz   1.13.6 2020-12-30
## 56:   data.table_1.14.0.tar.gz   1.14.0 2021-02-21
## 57:   data.table_1.14.2.tar.gz   1.14.2 2021-09-27
## 58:   data.table_1.14.4.tar.gz   1.14.4 2022-10-17
## 59:   data.table_1.14.6.tar.gz   1.14.6 2022-11-16
##                         tar.gz  version   date.str
```

The table above contains one row for every CRAN release of
`data.table`. 

## github repo tags

Which of the versions above has a corresponding tag on github? First
we get all the tags in the github repo:


```r
dt.dir <- file.path(R.dir, "data.table")
(tag.tib <- gert::git_tag_list(repo=dt.dir))
```

```
## # A tibble: 61 × 3
##    name   ref              commit                                  
##  * <chr>  <chr>            <chr>                                   
##  1 1.10.0 refs/tags/1.10.0 81cf17e3c28d22dad818db22dafea3f7a830be2d
##  2 1.10.2 refs/tags/1.10.2 b40ec30b61a54040acfcd6ce62b17b43ca8cb272
##  3 1.10.4 refs/tags/1.10.4 8b201fd28f5d4afcc4be026a5d9eb4bb6dd62955
##  4 1.11.0 refs/tags/1.11.0 d59c486d80b1afb57fa898755f04b5f0809cb07f
##  5 1.11.2 refs/tags/1.11.2 18ebbf60f3f8d1d136bfccc53b993003eb757608
##  6 1.11.4 refs/tags/1.11.4 06d055b7295838925890a958c30eb76be9510895
##  7 1.11.6 refs/tags/1.11.6 a4e26b50beaf0bb2aac40bbf47f9d1745579154a
##  8 1.11.8 refs/tags/1.11.8 76bb569fd7736b5f89471a35357e6a971ae1d424
##  9 1.12.0 refs/tags/1.12.0 34796cd1524828df9bf13a174265cb68a09fcd77
## 10 1.12.2 refs/tags/1.12.2 86034855f9b305e948d83014af89352fc42e27f2
## # ℹ 51 more rows
```

## intersection of tags and CRAN versions

The table below shows what versions are different between the github
tags and CRAN:


```r
library(data.table)
tag.dt <- data.table(tag.tib)[, .(version=name)]
setkey(tag.dt, version)
setkey(Archive.dt, version)
tag.dt[!Archive.dt]
```

```
##    version
## 1:  1.14.8
## 2:     1.3
## 3:     1.4
## 4:   1.5.4
## 5:   1.6.7
## 6:   1.7.0
## 7:   1.9.0
```

```r
Archive.dt[!tag.dt]
```

```
##                        tar.gz  version   date.str
## 1:      data.table_1.0.tar.gz      1.0 2006-04-14
## 2:      data.table_1.1.tar.gz      1.1 2008-08-27
## 3: data.table_1.10.4-1.tar.gz 1.10.4-1 2017-10-09
## 4: data.table_1.10.4-2.tar.gz 1.10.4-2 2017-10-12
## 5: data.table_1.10.4-3.tar.gz 1.10.4-3 2017-10-27
```

The tables above show that there are currently 7 tags which were never
submitted to CRAN, and there are 5 CRAN versions which never got a
tag. For this analysis, I am interested in the intersection (versions
with both a tag on github, and a release on CRAN):


```r
(both.dt <- tag.dt[Archive.dt, nomatch=0L])
```

```
##     version                   tar.gz   date.str
##  1:  1.10.0 data.table_1.10.0.tar.gz 2016-12-03
##  2:  1.10.2 data.table_1.10.2.tar.gz 2017-01-31
##  3:  1.10.4 data.table_1.10.4.tar.gz 2017-02-01
##  4:  1.11.0 data.table_1.11.0.tar.gz 2018-05-01
##  5:  1.11.2 data.table_1.11.2.tar.gz 2018-05-08
##  6:  1.11.4 data.table_1.11.4.tar.gz 2018-05-27
##  7:  1.11.6 data.table_1.11.6.tar.gz 2018-09-19
##  8:  1.11.8 data.table_1.11.8.tar.gz 2018-09-30
##  9:  1.12.0 data.table_1.12.0.tar.gz 2019-01-13
## 10:  1.12.2 data.table_1.12.2.tar.gz 2019-04-07
## 11:  1.12.4 data.table_1.12.4.tar.gz 2019-10-03
## 12:  1.12.6 data.table_1.12.6.tar.gz 2019-10-18
## 13:  1.12.8 data.table_1.12.8.tar.gz 2019-12-09
## 14:  1.13.0 data.table_1.13.0.tar.gz 2020-07-24
## 15:  1.13.2 data.table_1.13.2.tar.gz 2020-10-19
## 16:  1.13.4 data.table_1.13.4.tar.gz 2020-12-08
## 17:  1.13.6 data.table_1.13.6.tar.gz 2020-12-30
## 18:  1.14.0 data.table_1.14.0.tar.gz 2021-02-21
## 19:  1.14.2 data.table_1.14.2.tar.gz 2021-09-27
## 20:  1.14.4 data.table_1.14.4.tar.gz 2022-10-17
## 21:  1.14.6 data.table_1.14.6.tar.gz 2022-11-16
## 22:     1.2    data.table_1.2.tar.gz 2008-09-01
## 23:   1.4.1  data.table_1.4.1.tar.gz 2010-05-03
## 24:     1.5    data.table_1.5.tar.gz 2010-09-14
## 25:   1.5.1  data.table_1.5.1.tar.gz 2011-01-08
## 26:   1.5.2  data.table_1.5.2.tar.gz 2011-01-21
## 27:   1.5.3  data.table_1.5.3.tar.gz 2011-02-11
## 28:     1.6    data.table_1.6.tar.gz 2011-04-24
## 29:   1.6.1  data.table_1.6.1.tar.gz 2011-06-29
## 30:   1.6.2  data.table_1.6.2.tar.gz 2011-07-02
## 31:   1.6.3  data.table_1.6.3.tar.gz 2011-08-04
## 32:   1.6.4  data.table_1.6.4.tar.gz 2011-08-10
## 33:   1.6.5  data.table_1.6.5.tar.gz 2011-08-25
## 34:   1.6.6  data.table_1.6.6.tar.gz 2011-08-25
## 35:   1.7.1  data.table_1.7.1.tar.gz 2011-10-22
## 36:  1.7.10 data.table_1.7.10.tar.gz 2012-02-07
## 37:   1.7.2  data.table_1.7.2.tar.gz 2011-11-07
## 38:   1.7.3  data.table_1.7.3.tar.gz 2011-11-25
## 39:   1.7.4  data.table_1.7.4.tar.gz 2011-11-29
## 40:   1.7.5  data.table_1.7.5.tar.gz 2011-12-04
## 41:   1.7.6  data.table_1.7.6.tar.gz 2011-12-13
## 42:   1.7.7  data.table_1.7.7.tar.gz 2011-12-15
## 43:   1.7.8  data.table_1.7.8.tar.gz 2012-01-25
## 44:   1.7.9  data.table_1.7.9.tar.gz 2012-01-31
## 45:   1.8.0  data.table_1.8.0.tar.gz 2012-07-16
## 46:  1.8.10 data.table_1.8.10.tar.gz 2013-09-03
## 47:   1.8.2  data.table_1.8.2.tar.gz 2012-07-17
## 48:   1.8.4  data.table_1.8.4.tar.gz 2012-11-09
## 49:   1.8.6  data.table_1.8.6.tar.gz 2012-11-13
## 50:   1.8.8  data.table_1.8.8.tar.gz 2013-03-06
## 51:   1.9.2  data.table_1.9.2.tar.gz 2014-02-27
## 52:   1.9.4  data.table_1.9.4.tar.gz 2014-10-02
## 53:   1.9.6  data.table_1.9.6.tar.gz 2015-09-19
## 54:   1.9.8  data.table_1.9.8.tar.gz 2016-11-25
##     version                   tar.gz   date.str
```

The table above shows the versions in the intersection. 

## git status and diff

Below we do the following steps for each version:

* clone github repo and checkout that version/tag,
* download source package from CRAN, then untar it so that the files
  over-write the files in the github clone,
* run git status and git diff to see what files have changed or have
  been added.


```r
versions.dir <- file.path(R.dir,"data.table-versions")
versions.dt.dir <- file.path(versions.dir, "data.table")
diff.csv <- file.path(versions.dir,"diff.csv")
status.csv <- file.path(versions.dir,"status.csv")
dir.create(versions.dir, showWarnings = FALSE)
if(file.exists(diff.csv)){
  diff.dt <- fread(diff.csv)
  status.dt <- fread(status.csv)
}else{
  diff.dt.list <- list()
  status.dt.list <- list()
  for(version.i in 1:nrow(both.dt)){
    version.row <- both.dt[version.i]
    system(paste("cd",versions.dir,"&& git clone",dt.dir))
    system(paste("cd",versions.dt.dir,"&& git checkout",version.row$version))
    version.url <- paste0(Archive.url,"data.table/",version.row$tar.gz)
    version.tar.gz <- file.path(versions.dir,version.row$tar.gz)
    if(!file.exists(version.tar.gz))download.file(version.url, version.tar.gz)
    system(paste("cd",versions.dir,"&& tar xf",version.row$tar.gz))
    meta.row <- version.row[,.(version)]
    status.dt.list[[version.i]] <- data.table(
      meta.row, gert::git_status(repo=versions.dt.dir))
    diff.dt.list[[version.i]] <- data.table(
      meta.row, gert::git_diff(repo=versions.dt.dir))
    dest.dir <- file.path(versions.dir,version.row$version)
    unlink(dest.dir,recursive = TRUE)
    file.rename(versions.dt.dir,dest.dir)
  }
  diff.dt <- rbindlist(diff.dt.list)
  status.dt <- rbindlist(status.dt.list)
  fwrite(diff.dt, diff.csv)
  fwrite(status.dt, status.csv)
}
```

Below we look at the status of the most recent dot zero versions:


```r
status.dt[version=="1.14.0"]
```

```
##     version                          file   status staged
##  1:  1.14.0                        build/      new  FALSE
##  2:  1.14.0                   DESCRIPTION modified  FALSE
##  3:  1.14.0                       inst/cc      new  FALSE
##  4:  1.14.0                     inst/doc/      new  FALSE
##  5:  1.14.0 inst/tests/benchmark.Rraw.bz2      new  FALSE
##  6:  1.14.0     inst/tests/froll.Rraw.bz2      new  FALSE
##  7:  1.14.0    inst/tests/nafill.Rraw.bz2      new  FALSE
##  8:  1.14.0     inst/tests/other.Rraw.bz2      new  FALSE
##  9:  1.14.0     inst/tests/tests.Rraw.bz2      new  FALSE
## 10:  1.14.0     inst/tests/types.Rraw.bz2      new  FALSE
## 11:  1.14.0                           MD5      new  FALSE
## 12:  1.14.0                       NEWS.md modified  FALSE
## 13:  1.14.0                    src/init.c modified  FALSE
```

```r
status.dt[version=="1.13.0"]
```

```
##     version                          file   status staged
##  1:  1.13.0                        build/      new  FALSE
##  2:  1.13.0                   DESCRIPTION modified  FALSE
##  3:  1.13.0                       inst/cc      new  FALSE
##  4:  1.13.0                     inst/doc/      new  FALSE
##  5:  1.13.0 inst/tests/benchmark.Rraw.bz2      new  FALSE
##  6:  1.13.0     inst/tests/froll.Rraw.bz2      new  FALSE
##  7:  1.13.0    inst/tests/nafill.Rraw.bz2      new  FALSE
##  8:  1.13.0     inst/tests/other.Rraw.bz2      new  FALSE
##  9:  1.13.0     inst/tests/tests.Rraw.bz2      new  FALSE
## 10:  1.13.0     inst/tests/types.Rraw.bz2      new  FALSE
## 11:  1.13.0                           MD5      new  FALSE
## 12:  1.13.0                       NEWS.md modified  FALSE
## 13:  1.13.0                    src/init.c modified  FALSE
```

```r
status.dt[version=="1.12.0"]
```

```
##    version        file   status staged
## 1:  1.12.0      build/      new  FALSE
## 2:  1.12.0 DESCRIPTION modified  FALSE
## 3:  1.12.0   inst/doc/      new  FALSE
## 4:  1.12.0         MD5      new  FALSE
## 5:  1.12.0     NEWS.md modified  FALSE
## 6:  1.12.0  src/init.c modified  FALSE
```

```r
status.dt[version=="1.11.0"]
```

```
##    version        file   status staged
## 1:  1.11.0      build/      new  FALSE
## 2:  1.11.0 DESCRIPTION modified  FALSE
## 3:  1.11.0   inst/doc/      new  FALSE
## 4:  1.11.0         MD5      new  FALSE
## 5:  1.11.0     NEWS.md modified  FALSE
```

Among the files which have been modified, `init.c` is the only
code. How many modifications to C and R files are there over all
versions?


```r
status.dt[grepl("[cR]$",file)&status=="modified"]
```

```
##     version                file   status staged
##  1:     1.2         R/between.R modified  FALSE
##  2:     1.2        R/c.factor.R modified  FALSE
##  3:     1.2      R/data.table.R modified  FALSE
##  4:     1.2         R/getdots.R modified  FALSE
##  5:     1.2            R/last.R modified  FALSE
##  6:     1.2            R/like.R modified  FALSE
##  7:     1.2            R/plus.R modified  FALSE
##  8:     1.2          R/setkey.R modified  FALSE
##  9:     1.2          R/tables.R modified  FALSE
## 10:     1.2            R/take.R modified  FALSE
## 11:     1.2 R/test.data.table.R modified  FALSE
## 12:     1.2      R/time.taken.R modified  FALSE
## 13:     1.2            R/trim.R modified  FALSE
## 14:     1.2     R/which.first.R modified  FALSE
## 15:     1.2      R/which.last.R modified  FALSE
## 16:     1.2             R/zzz.R modified  FALSE
## 17:     1.2       src/duplist.c modified  FALSE
## 18:     1.2   src/sortedmatch.c modified  FALSE
## 19:     1.2        src/vecref.c modified  FALSE
## 20:  1.11.4          R/setkey.R modified  FALSE
## 21:  1.11.8           R/fcast.R modified  FALSE
## 22:  1.11.8           R/fmelt.R modified  FALSE
## 23:  1.11.8           R/fread.R modified  FALSE
## 24:  1.12.0          src/init.c modified  FALSE
## 25:  1.12.2          src/init.c modified  FALSE
## 26:  1.12.4          src/init.c modified  FALSE
## 27:  1.12.6          src/init.c modified  FALSE
## 28:  1.12.8          src/init.c modified  FALSE
## 29:  1.13.0          src/init.c modified  FALSE
## 30:  1.13.2          src/init.c modified  FALSE
## 31:  1.13.4          src/init.c modified  FALSE
## 32:  1.13.6          src/init.c modified  FALSE
## 33:  1.14.0          src/init.c modified  FALSE
##     version                file   status staged
```

The table above has 33 rows for modified code files. 19 of them are in
version 1.2 (very old). Four rows are 1.11.* R code files. The rest
are init.c modifications in 1.12.0 and newer.


```r
init.dt <- diff.dt[new=="src/init.c"]
cat(init.dt[1, patch])
```

```
## diff --git a/src/init.c b/src/init.c
## index a5f6d4a..0b6c9ed 100644
## --- a/src/init.c
## +++ b/src/init.c
## @@ -326,6 +326,6 @@ SEXP hasOpenMP() {
##  
##  SEXP dllVersion() {
##    // .onLoad calls this and checks the same as packageVersion() to ensure no R/C version mismatch, #3056
## -  return(ScalarString(mkChar(""1.12.1"")));
## +  return(ScalarString(mkChar(""1.12.0"")));
##  }
## 
```

```r
cat(init.dt[.N, patch])
```

```
## diff --git a/src/init.c b/src/init.c
## index 714608c..0b442f0 100644
## --- a/src/init.c
## +++ b/src/init.c
## @@ -414,6 +414,6 @@ SEXP initLastUpdated(SEXP var) {
##  
##  SEXP dllVersion() {
##    // .onLoad calls this and checks the same as packageVersion() to ensure no R/C version mismatch, #3056
## -  return(ScalarString(mkChar(""1.14.1"")));
## +  return(ScalarString(mkChar(""1.14.0"")));
##  }
## 
```


The above output shows that the only difference is the version number
(+ 1.14.0 is from CRAN, -1.14.1 is from github). This is consistent
with what Matt wrote in [`CRAN_Release.cmd`](https://github.com/Rdatatable/data.table/blob/master/.dev/CRAN_Release.cmd):
"DO NOT commit or push to GitHub. Leave 4 files
(.dev/CRAN_Release.cmd, DESCRIPTION, NEWS and init.c) edited and not
committed. Include these in a single and final bump commit below.  DO
NOT even use a PR. Because PRs build binaries and we don't want any
binary versions of even release numbers available from anywhere other
than CRAN... Bump dllVersion() in init.c ... Push to master ... run
`git tag 1.14.8 96c..sha..d77` then `git push origin 1.14.8`"


## Conclusions

This code can be used to automatically create a report of differences
and files added in CRAN, with respect to the corresponding github
tag. This analysis may be useful for encouraging developer
confidence/trust in the CRAN maintainer.
