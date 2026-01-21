---
layout: post
title: mlr3 learners list
description: And class projects
---



The purpose of this vignette is to make lists of

* learners that currently exist in mlr3,
* CRAN packages that do not yet have a learner.

## Current Learners

mlr3 web site has [a list of learners](https://mlr-org.com/learners.html), created using [learners.qmd](https://github.com/mlr-org/mlr3website/blob/main/mlr-org/learners.qmd).


``` r
pkgs <- c("mlr3", "mlr3learners", "mlr3extralearners", "mlr3proba", "mlr3cluster", "mlr3torch", "torchvision")
remotes::install_github("mlr-org/mlr3extralearners")
```

```
## Using GitHub PAT from the git credential store.
```

```
## Skipping install of 'mlr3extralearners' from a github remote, the SHA1 (f48cc99b) has not changed since last install.
##   Use `force = TRUE` to force installation
```

``` r
for(pkg in pkgs){
  if(!requireNamespace(pkg))install.packages(pkg)
  requireNamespace(pkg)
}
library(data.table)
content = as.data.table(mlr3::mlr_learners, objects = TRUE)
content[, base_package := purrr::map(object, function(x) strsplit(x$man, "::", TRUE)[[1]][1])]
content[, packages := purrr::pmap(list(packages, base_package), function(x, y) setdiff(x, c(y, "mlr3")))]
learners = rlang::set_names(content$object, content$key)
content[, `:=`(object = NULL, task_type = NULL)]

# fix mlr3probaproba
content[is.na(base_package), base_package := "mlr3proba"]

content
```

```
## Key: <key>
##                     key                           label
##                  <char>                          <char>
##   1: classif.AdaBoostM1               Adaptive Boosting
##   2:        classif.C50                Tree-based Model
##   3:        classif.IBk               Nearest Neighbour
##   4:        classif.J48                Tree-based Model
##   5:       classif.JRip     Propositional Rule Learner.
##  ---                                                   
## 254:         surv.rfsrc         Random Survival Forests
## 255:         surv.rpart                   Survival Tree
## 256:           surv.svm Survival Support Vector Machine
## 257:   surv.xgboost.aft   Extreme Gradient Boosting AFT
## 258:   surv.xgboost.cox   Extreme Gradient Boosting Cox
##                                         feature_types                  packages
##                                                <list>                    <list>
##   1:                   integer,numeric,factor,ordered                     RWeka
##   2:                           numeric,factor,ordered                       C50
##   3:                   integer,numeric,factor,ordered                     RWeka
##   4:                   integer,numeric,factor,ordered                     RWeka
##   5:                   integer,numeric,factor,ordered                     RWeka
##  ---                                                                           
## 254:                   logical,integer,numeric,factor mlr3proba,randomForestSRC
## 255: logical,integer,numeric,character,factor,ordered     rpart,distr6,survival
## 256:         logical,integer,numeric,character,factor     mlr3proba,survivalsvm
## 257:                                  integer,numeric         mlr3proba,xgboost
## 258:                                  integer,numeric         mlr3proba,xgboost
##                                                   properties     predict_types
##                                                       <list>            <list>
##   1:                             marshal,multiclass,twoclass     response,prob
##   2:                    missings,multiclass,twoclass,weights     response,prob
##   3:                             marshal,multiclass,twoclass     response,prob
##   4:                    marshal,missings,multiclass,twoclass     response,prob
##   5:                             marshal,multiclass,twoclass     response,prob
##  ---                                                                          
## 254: importance,missings,oob_error,selected_features,weights       crank,distr
## 255:           importance,missings,selected_features,weights             crank
## 256:                                                            crank,response
## 257:  importance,internal_tuning,missings,validation,weights crank,lp,response
## 258:  importance,internal_tuning,missings,validation,weights    crank,distr,lp
##           base_package
##                 <list>
##   1: mlr3extralearners
##   2: mlr3extralearners
##   3: mlr3extralearners
##   4: mlr3extralearners
##   5: mlr3extralearners
##  ---                  
## 254: mlr3extralearners
## 255:         mlr3proba
## 256: mlr3extralearners
## 257: mlr3extralearners
## 258: mlr3extralearners
```

The table above seems consistent with the learners web page.

## wish list

I asked in [an issue](https://github.com/mlr-org/mlr3extralearners/issues/539), and there is a [list of issues which are learners to implement](https://github.com/mlr-org/mlr3extralearners/issues?q=is%3Aissue%20state%3Aopen%20label%3A%22Learner%20Status%3A%20Request%22) (CRAN packages with no mlr3 Learner written yet).
These would be good options for student projects in my class.

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
## other attached packages:
## [1] data.table_1.18.0
## 
## loaded via a namespace (and not attached):
##  [1] tidyselect_1.2.1             dplyr_1.1.4                 
##  [3] farver_2.1.2                 mlr3extralearners_1.3.1.9000
##  [5] mlr3pipelines_0.10.0         S7_0.2.1                    
##  [7] paradox_1.0.1                digest_0.6.39               
##  [9] lifecycle_1.0.5              cluster_2.1.8.1             
## [11] survival_3.8-3               processx_3.8.6              
## [13] magrittr_2.0.4               kernlab_0.9-33              
## [15] compiler_4.5.2               rlang_1.1.7                 
## [17] tools_4.5.2                  knitr_1.51                  
## [19] bit_4.6.0                    mclust_6.1.2                
## [21] curl_7.0.0                   distr6_1.8.4                
## [23] RColorBrewer_1.1-3           withr_3.0.2                 
## [25] purrr_1.2.1                  mlr3misc_0.19.0             
## [27] nnet_7.3-20                  ooplah_0.2.0                
## [29] grid_4.5.2                   stats4_4.5.2                
## [31] dictionar6_0.1.3             mlr3proba_0.8.6             
## [33] future_1.69.0                ggplot2_4.0.1               
## [35] globals_0.18.0               scales_1.4.0                
## [37] fpc_2.2-14                   MASS_7.3-65                 
## [39] prabclus_2.3-5               zeallot_0.2.0               
## [41] cli_3.6.5                    crayon_1.5.3                
## [43] generics_0.1.4               remotes_2.5.0               
## [45] otel_0.2.0                   mlr3torch_0.3.2             
## [47] robustbase_0.99-6            modeltools_0.2-24           
## [49] splines_4.5.2                parallel_4.5.2              
## [51] coro_1.1.0                   vctrs_0.7.0                 
## [53] Matrix_1.7-4                 jsonlite_2.0.0              
## [55] torchvision_0.8.0            callr_3.7.6                 
## [57] bit64_4.6.0-1                clue_0.3-66                 
## [59] listenv_0.10.0               mlr3learners_0.14.0         
## [61] diptest_0.77-2               lgr_0.5.0                   
## [63] mlr3cmprsk_0.0.1             glue_1.8.0                  
## [65] parallelly_1.46.1            DEoptimR_1.1-4              
## [67] codetools_0.2-20             ps_1.9.1                    
## [69] gtable_0.3.6                 mlr3_1.3.0                  
## [71] palmerpenguins_0.1.1         tibble_3.3.1                
## [73] mlr3cluster_0.1.12           pillar_1.11.1               
## [75] set6_0.2.6                   torch_0.16.3                
## [77] R6_2.6.1                     evaluate_1.0.5              
## [79] lattice_0.22-7               survdistr_0.0.1             
## [81] backports_1.5.0              class_7.3-23                
## [83] Rcpp_1.1.1                   uuid_1.2-1                  
## [85] flexmix_2.3-20               checkmate_2.3.3             
## [87] xfun_0.56                    param6_0.2.4                
## [89] pkgconfig_2.0.3
```
