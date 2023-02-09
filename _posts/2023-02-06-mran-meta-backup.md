---
layout: post
title: CRAN Meta-data
description: Backing up MRAN
---



The Microsoft R Application Network (MRAN) [time
machine](https://mran.microsoft.com/documents/rro/reproducibility#timemachine)
keeps daily CRAN snapshots, so we can access historical packages.rds
files going back to its inception on September 17th, 2014. However it
is going offline in July 2023, so here we explain how to make a
backup.


```r
library(data.table)
get_packages <- function(date){
  date.str <- paste(date)
  date.dir <- file.path("~/R/dt-deps-time", date.str)
  dir.create(date.dir,showWarnings=FALSE,recursive=TRUE)
  packages.rds <- file.path(date.dir, "packages.rds")
  tryCatch({
    if(!file.exists(packages.rds)){
      u <- paste0(
        "https://cran.microsoft.com/snapshot/",
        date.str,
        "/web/packages/packages.rds")
      print(packages.rds)
      download.file(u, packages.rds)
    }
    packages <- readRDS(packages.rds)
    data.table(packages)
  }, error=function(e){
    NULL
  })
}
pkg.dt <- get_packages("2014-09-17")
names(pkg.dt)
```

```
##  [1] "Package"                 "Version"                
##  [3] "Priority"                "Depends"                
##  [5] "Imports"                 "LinkingTo"              
##  [7] "Suggests"                "Enhances"               
##  [9] "License"                 "License_is_FOSS"        
## [11] "License_restricts_use"   "OS_type"                
## [13] "Archs"                   "MD5sum"                 
## [15] "NeedsCompilation"        "Authors@R"              
## [17] "Author"                  "BugReports"             
## [19] "Contact"                 "Copyright"              
## [21] "Description"             "Encoding"               
## [23] "Language"                "Maintainer"             
## [25] "Title"                   "URL"                    
## [27] "SystemRequirements"      "Type"                   
## [29] "Path"                    "Classification/ACM"     
## [31] "Classification/JEL"      "Classification/MSC"     
## [33] "Published"               "VignetteBuilder"        
## [35] "Additional_repositories" "Reverse depends"        
## [37] "Reverse imports"         "Reverse linking to"     
## [39] "Reverse suggests"        "Reverse enhances"       
## [41] "MD5sum"
```

```r
(rev.imports.str <- pkg.dt["data.table", on="Package"][["Reverse imports"]])
```

```
## [1] "aLFQ, benford.analysis, Causata, DataCombine, eeptools, FAOSTAT, freqweights, gems, IAT, Kmisc, lar, lllcrc, miscset, optiRum, pxweb, qdapTools, randomNames, RAPIDR, RbioRXN, rbison, rfisheries, rgauges, rgbif, rlist, rnoaa, rplos, SGP, simPH, spocc, sweSCB, taxize, treebase, treemap"
```

The code below downloads meta-data for every day,


```r
date.vec <- seq(as.IDate("2014-09-17"), as.IDate(Sys.time()), by="day")
date.pkgs.list <- list()
for(date.i in seq_along(date.vec)){
  date <- date.vec[[date.i]]
  pkg.dt <- get_packages(date)
  value <- if(is.data.table(pkg.dt)){
    dim(pkg.dt)
  }else{
    c(0,0)
  }
  date.pkgs.list[[paste(date)]] <- data.table(
    date,
    variable=c("nrow","ncol"),
    value)
}
```

```
## [1] "~/R/dt-deps-time/2015-06-04/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2015-06-04/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2015-06-05/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2015-06-05/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2015-06-06/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2015-06-06/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2015-06-07/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2015-06-07/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2015-06-08/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2015-06-08/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2015-07-03/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2015-07-03/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2015-07-04/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2015-07-04/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2015-07-05/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2015-07-05/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2015-07-06/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2015-07-06/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2016-05-05/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2016-05-05/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2016-05-06/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2016-05-06/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2016-05-07/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2016-05-07/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2016-05-08/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2016-05-08/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2016-05-09/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2016-05-09/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2016-05-10/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2016-05-10/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2016-05-11/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2016-05-11/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2016-05-12/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2016-05-12/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2016-05-13/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2016-05-13/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2016-05-14/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2016-05-14/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2016-05-15/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2016-05-15/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2016-05-16/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2016-05-16/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2016-05-17/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2016-05-17/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2016-12-04/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2016-12-04/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2017-03-29/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2017-03-29/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2018-07-18/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2018-07-18/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2019-06-27/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2019-06-27/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2019-11-20/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2019-11-20/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2019-12-31/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2019-12-31/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2020-01-03/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2020-01-03/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2020-02-05/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2020-02-05/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2020-02-13/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2020-02-13/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2020-02-18/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2020-02-18/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2020-06-25/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2020-06-25/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2020-08-06/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2020-08-06/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2020-09-10/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2020-09-10/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2020-09-16/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2020-09-16/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2020-09-23/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2020-09-23/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2020-11-14/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2020-11-14/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2021-04-04/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2021-04-04/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2021-04-05/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2021-04-05/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2021-04-21/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2021-04-21/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2021-04-22/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2021-04-22/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2021-04-23/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2021-04-23/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2021-04-24/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2021-04-24/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2021-04-25/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2021-04-25/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2021-04-26/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2021-04-26/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2021-04-27/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2021-04-27/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2021-04-28/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2021-04-28/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2021-04-29/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2021-04-29/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2021-08-14/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2021-08-14/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2021-10-27/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2021-10-27/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2021-11-09/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2021-11-09/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2021-11-10/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2021-11-10/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2021-11-12/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2021-11-12/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2021-12-14/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2021-12-14/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2022-03-01/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2022-03-01/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2022-03-16/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2022-03-16/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2022-03-19/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2022-03-19/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2022-03-20/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2022-03-20/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2022-04-23/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2022-04-23/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2022-07-12/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2022-07-12/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2022-07-27/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2022-07-27/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2022-07-28/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2022-07-28/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2022-07-29/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2022-07-29/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2022-07-30/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2022-07-30/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2022-07-31/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2022-07-31/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2022-08-01/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2022-08-01/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2022-08-02/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2022-08-02/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2022-08-03/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2022-08-03/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2022-08-04/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2022-08-04/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2022-08-05/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2022-08-05/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2022-08-06/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2022-08-06/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2022-08-07/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2022-08-07/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2022-08-08/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2022-08-08/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2022-08-18/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2022-08-18/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2022-08-22/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2022-08-22/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2022-09-11/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2022-09-11/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2022-09-16/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2022-09-16/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2022-12-17/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2022-12-17/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2022-12-18/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2022-12-18/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2023-01-10/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2023-01-10/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2023-01-19/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2023-01-19/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2023-01-30/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2023-01-30/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```
## [1] "~/R/dt-deps-time/2023-02-02/packages.rds"
```

```
## Warning in download.file(u, packages.rds): downloaded length 0 != reported
## length 202
```

```
## Warning in download.file(u, packages.rds): cannot open URL
## 'https://cran.microsoft.com/snapshot/2023-02-02/web/packages/packages.rds': HTTP
## status was '500 Internal Server Error'
```

```r
(date.pkgs <- rbindlist(date.pkgs.list))
```

```
##             date variable value
##           <IDat>   <char> <num>
##    1: 2014-09-17     nrow  5899
##    2: 2014-09-17     ncol    41
##    3: 2014-09-18     nrow  5902
##    4: 2014-09-18     ncol    41
##    5: 2014-09-19     nrow  5909
##   ---                          
## 6132: 2023-02-07     ncol    67
## 6133: 2023-02-08     nrow 19173
## 6134: 2023-02-08     ncol    67
## 6135: 2023-02-09     nrow 19181
## 6136: 2023-02-09     ncol    67
```

Finally we can plug these count data into a ggplot,


```r
library(ggplot2)
ggplot()+
  theme_bw()+
  facet_grid(variable ~ ., scales="free")+
  geom_point(aes(
    date, value),
    shape=21,
    data=date.pkgs)
```

![plot of chunk dimTimeSeries](/assets/img/2023-02-06-mran-meta-backupdimTimeSeries-1.png)

We can see in the figure above that the number of packages (nrow) has
been increasing over time until 2022, when there was a period where
more packages were removed than packages added. Also we see that the
number of fields/features per package (ncol) has generally increased
over time, from 41 in 2014, to more than 60 currently. (the one
exception is when a field was removed in 2019)

