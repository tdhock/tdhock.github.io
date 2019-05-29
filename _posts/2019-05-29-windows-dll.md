---
layout: post
title: R package installation on windows considered harmful
description: Warning for unsuccessful DLL copy should be an error
---

Recently I have been getting this warning in R on windows while
installing my
[penaltyLearning](https://cloud.r-project.org/package=penaltyLearning)
package for supervised changepoint detection:

```
** testing if installed package can be loaded from temporary location
WARNING: moving package to final location failed, copying instead
Warning in file.copy(instdir, dirname(final_instdir), recursive = TRUE,  :
  problem copying C:\Program Files\R\R-3.6.0\library\00LOCK-penaltyLearning\00new\penaltyLearning\libs\x64\penaltyLearning.dll to C:\Program Files\R\R-3.6.0\library\penaltyLearning\libs\x64\penaltyLearning.dll: Permission denied
** testing if installed package can be loaded from final location
```

This happens on Windows when the package is in use but you try to
install it from source. It tries to copy the DLL but the copy fails
with a warning because the DLL is in use, AND THEN PACKAGE
INSTALLATION CONTINUES. This is a serious problem that could lead to
hard to find bugs, because the old DLL file could be incompatible with
the newly installed R code. I think the most obvious fix would be to
stop package installation with an error rather than a warning.

Today I noticed one of my students was also having this issue, so I
decided to investigate to see if there is a known solution. I'm not
the first to have this issue.

* [data.table](https://github.com/Rdatatable/data.table/issues/3056) had
  this issue, and they filed a [base R
  bug](https://bugs.r-project.org/bugzilla/show_bug.cgi?id=17478)
  which has not yet been addressed.
* [remotes](https://github.com/r-lib/remotes/issues/113) also had this
  issue. They filed [a different bug in base
  R](https://bugs.r-project.org/bugzilla/show_bug.cgi?id=17453) which
  was apparently addressed by [this
  commit](https://github.com/wch/r-source/commit/828a04f9c428403e476620b1905a1d8ca41d0bcd)
  to R-3.5.1.
  
However I am having this issue now in R-3.6.0 -- was there a
regression? A reproducible example is below, but here is a summary:

* I start R with --vanilla and set options repos=cloud and warn=2
  (which I expect should convert warnings to errors).
* In the first command line I install the penaltyLearning package from
  source, which results in a successful installation.
* In the second command line I first do library(penaltyLearning) and
  then install the package from source, which results in the
  warnings. I expected there should be an error.
* The third command line is the same as the first, and gives the same
  result.

```
th798@cmp2986 MINGW64 ~/R
$ R --vanilla -e "options(repos='https://cloud.r-project.org', warn=2);install.packages('penaltyLearning', type='source');getOption('warn');sessionInfo()"

R version 3.6.0 (2019-04-26) -- "Planting of a Tree"
Copyright (C) 2019 The R Foundation for Statistical Computing
Platform: x86_64-w64-mingw32/x64 (64-bit)

R is free software and comes with ABSOLUTELY NO WARRANTY.
You are welcome to redistribute it under certain conditions.
Type 'license()' or 'licence()' for distribution details.

R is a collaborative project with many contributors.
Type 'contributors()' for more information and
'citation()' on how to cite R or R packages in publications.

Type 'demo()' for some demos, 'help()' for on-line help, or
'help.start()' for an HTML browser interface to help.
Type 'q()' to quit R.

> options(repos='https://cloud.r-project.org', warn=2);install.packages('penaltyLearning', type='source');getOption('warn');sessionInfo()
trying URL 'https://cloud.r-project.org/src/contrib/penaltyLearning_2018.09.04.tar.gz'
Content type 'application/x-gzip' length 2837289 bytes (2.7 MB)
==================================================
downloaded 2.7 MB

* installing *source* package 'penaltyLearning' ...
** package 'penaltyLearning' successfully unpacked and MD5 sums checked
** using staged installation
** libs
c:/Rtools/mingw_64/bin/g++  -std=gnu++11 -I"C:/PROGRA~1/R/R-36~1.0/include" -DNDEBUG          -O2 -Wall  -mtune=generic -c interface.cpp -o interface.o
c:/Rtools/mingw_64/bin/g++  -std=gnu++11 -I"C:/PROGRA~1/R/R-36~1.0/include" -DNDEBUG          -O2 -Wall  -mtune=generic -c largestContinuousMinimum.cpp -o largestContinuousMinimum.o
largestContinuousMinimum.cpp: In function 'int largestContinuousMinimum(int, double*, double*, int*)':
largestContinuousMinimum.cpp:38:27: warning: 'start' may be used uninitialized in this function [-Wmaybe-uninitialized]
       index_vec[0] = start;
                           ^
c:/Rtools/mingw_64/bin/g++  -std=gnu++11 -I"C:/PROGRA~1/R/R-36~1.0/include" -DNDEBUG          -O2 -Wall  -mtune=generic -c modelSelection.cpp -o modelSelection.o
/usr/bin/sed: -e expression #1, char 1: unknown command: `C'
c:/Rtools/mingw_64/bin/g++ -shared -s -static-libgcc -o penaltyLearning.dll tmp.def interface.o largestContinuousMinimum.o modelSelection.o -LC:/PROGRA~1/R/R-36~1.0/bin/x64 -lR
installing to C:/Program Files/R/R-3.6.0/library/00LOCK-penaltyLearning/00new/penaltyLearning/libs/x64
** R
** data
** byte-compile and prepare package for lazy loading
** help
*** installing help indices
  converting help for package 'penaltyLearning'
    finding HTML links ... done
    GeomTallRect                            html  
    IntervalRegressionCV                    html  
    IntervalRegressionCVmargin              html  
    IntervalRegressionInternal              html  
    IntervalRegressionRegularized           html  
    IntervalRegressionUnregularized         html  
    ROChange                                html  
    change.colors                           html  
    change.labels                           html  
    changeLabel                             html  
    check_features_targets                  html  
    check_target_pred                       html  
    coef.IntervalRegression                 html  
    demo8                                   html  
    featureMatrix                           html  
    featureVector                           html  
    geom_tallrect                           html  
    labelError                              html  
    largestContinuousMinimumC               html  
    largestContinuousMinimumR               html  
    modelSelection                          html  
    modelSelectionC                         html  
    modelSelectionR                         html  
    neuroblastomaProcessed                  html  
    oneSkip                                 html  
    plot.IntervalRegression                 html  
    predict.IntervalRegression              html  
    print.IntervalRegression                html  
    squared.hinge                           html  
    targetIntervalROC                       html  
    targetIntervalResidual                  html  
    targetIntervals                         html  
    theme_no_space                          html  
** building package indices
** testing if installed package can be loaded from temporary location
** testing if installed package can be loaded from final location
** testing if installed package keeps a record of temporary installation path
* DONE (penaltyLearning)

The downloaded source packages are in
	'C:\Users\th798\AppData\Local\Temp\RtmpwDPOGo\downloaded_packages'
[1] 2
R version 3.6.0 (2019-04-26)
Platform: x86_64-w64-mingw32/x64 (64-bit)
Running under: Windows 10 x64 (build 17134)

Matrix products: default

locale:
[1] LC_COLLATE=English_United States.1252 
[2] LC_CTYPE=English_United States.1252   
[3] LC_MONETARY=English_United States.1252
[4] LC_NUMERIC=C                          
[5] LC_TIME=English_United States.1252    

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

loaded via a namespace (and not attached):
[1] compiler_3.6.0 tools_3.6.0   
> 
> 
]0;MINGW64:/c/Users/th798/R
th798@cmp2986 MINGW64 ~/R
$ R --vanilla -e "options(repos='https://cloud.r-project.org', warn=2);library(penaltyLearning);install.packages('penaltyLearning', type='source');getOption('warn');sessionInfo()"

R version 3.6.0 (2019-04-26) -- "Planting of a Tree"
Copyright (C) 2019 The R Foundation for Statistical Computing
Platform: x86_64-w64-mingw32/x64 (64-bit)

R is free software and comes with ABSOLUTELY NO WARRANTY.
You are welcome to redistribute it under certain conditions.
Type 'license()' or 'licence()' for distribution details.

R is a collaborative project with many contributors.
Type 'contributors()' for more information and
'citation()' on how to cite R or R packages in publications.

Type 'demo()' for some demos, 'help()' for on-line help, or
'help.start()' for an HTML browser interface to help.
Type 'q()' to quit R.

> options(repos='https://cloud.r-project.org', warn=2);library(penaltyLearning);install.packages('penaltyLearning', type='source');getOption('warn');sessionInfo()
Loading required package: data.table
Registered S3 methods overwritten by 'ggplot2':
  method         from 
  [.quosures     rlang
  c.quosures     rlang
  print.quosures rlang
trying URL 'https://cloud.r-project.org/src/contrib/penaltyLearning_2018.09.04.tar.gz'
Content type 'application/x-gzip' length 2837289 bytes (2.7 MB)
==================================================
downloaded 2.7 MB

* installing *source* package 'penaltyLearning' ...
** package 'penaltyLearning' successfully unpacked and MD5 sums checked
** using staged installation
** libs
c:/Rtools/mingw_64/bin/g++  -std=gnu++11 -I"C:/PROGRA~1/R/R-36~1.0/include" -DNDEBUG          -O2 -Wall  -mtune=generic -c interface.cpp -o interface.o
c:/Rtools/mingw_64/bin/g++  -std=gnu++11 -I"C:/PROGRA~1/R/R-36~1.0/include" -DNDEBUG          -O2 -Wall  -mtune=generic -c largestContinuousMinimum.cpp -o largestContinuousMinimum.o
largestContinuousMinimum.cpp: In function 'int largestContinuousMinimum(int, double*, double*, int*)':
largestContinuousMinimum.cpp:38:27: warning: 'start' may be used uninitialized in this function [-Wmaybe-uninitialized]
       index_vec[0] = start;
                           ^
c:/Rtools/mingw_64/bin/g++  -std=gnu++11 -I"C:/PROGRA~1/R/R-36~1.0/include" -DNDEBUG          -O2 -Wall  -mtune=generic -c modelSelection.cpp -o modelSelection.o
/usr/bin/sed: -e expression #1, char 1: unknown command: `C'
c:/Rtools/mingw_64/bin/g++ -shared -s -static-libgcc -o penaltyLearning.dll tmp.def interface.o largestContinuousMinimum.o modelSelection.o -LC:/PROGRA~1/R/R-36~1.0/bin/x64 -lR
installing to C:/Program Files/R/R-3.6.0/library/00LOCK-penaltyLearning/00new/penaltyLearning/libs/x64
** R
** data
** byte-compile and prepare package for lazy loading
** help
*** installing help indices
  converting help for package 'penaltyLearning'
    finding HTML links ... done
    GeomTallRect                            html  
    IntervalRegressionCV                    html  
    IntervalRegressionCVmargin              html  
    IntervalRegressionInternal              html  
    IntervalRegressionRegularized           html  
    IntervalRegressionUnregularized         html  
    ROChange                                html  
    change.colors                           html  
    change.labels                           html  
    changeLabel                             html  
    check_features_targets                  html  
    check_target_pred                       html  
    coef.IntervalRegression                 html  
    demo8                                   html  
    featureMatrix                           html  
    featureVector                           html  
    geom_tallrect                           html  
    labelError                              html  
    largestContinuousMinimumC               html  
    largestContinuousMinimumR               html  
    modelSelection                          html  
    modelSelectionC                         html  
    modelSelectionR                         html  
    neuroblastomaProcessed                  html  
    oneSkip                                 html  
    plot.IntervalRegression                 html  
    predict.IntervalRegression              html  
    print.IntervalRegression                html  
    squared.hinge                           html  
    targetIntervalROC                       html  
    targetIntervalResidual                  html  
    targetIntervals                         html  
    theme_no_space                          html  
** building package indices
** testing if installed package can be loaded from temporary location
WARNING: moving package to final location failed, copying instead
Warning in file.copy(instdir, dirname(final_instdir), recursive = TRUE,  :
  problem copying C:\Program Files\R\R-3.6.0\library\00LOCK-penaltyLearning\00new\penaltyLearning\libs\x64\penaltyLearning.dll to C:\Program Files\R\R-3.6.0\library\penaltyLearning\libs\x64\penaltyLearning.dll: Permission denied
** testing if installed package can be loaded from final location
** testing if installed package keeps a record of temporary installation path
* DONE (penaltyLearning)

The downloaded source packages are in
	'C:\Users\th798\AppData\Local\Temp\RtmpUrOoFE\downloaded_packages'
[1] 2
R version 3.6.0 (2019-04-26)
Platform: x86_64-w64-mingw32/x64 (64-bit)
Running under: Windows 10 x64 (build 17134)

Matrix products: default

locale:
[1] LC_COLLATE=English_United States.1252 
[2] LC_CTYPE=English_United States.1252   
[3] LC_MONETARY=English_United States.1252
[4] LC_NUMERIC=C                          
[5] LC_TIME=English_United States.1252    

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
[1] penaltyLearning_2018.09.04 data.table_1.12.2         

loaded via a namespace (and not attached):
 [1] Rcpp_1.0.1       assertthat_0.2.1 dplyr_0.8.1      crayon_1.3.4    
 [5] R6_2.4.0         grid_3.6.0       plyr_1.8.4       magic_1.5-9     
 [9] gtable_0.3.0     magrittr_1.5     scales_1.0.0     ggplot2_3.1.1   
[13] pillar_1.4.0     rlang_0.3.4      lazyeval_0.2.2   geometry_0.4.1  
[17] tools_3.6.0      glue_1.3.1       purrr_0.3.2      munsell_0.5.0   
[21] abind_1.4-7      compiler_3.6.0   pkgconfig_2.0.2  colorspace_1.4-1
[25] tidyselect_0.2.5 tibble_2.1.1    
> 
> 
]0;MINGW64:/c/Users/th798/R
th798@cmp2986 MINGW64 ~/R
$ R --vanilla -e "options(repos='https://cloud.r-project.org', warn=2);install.packages('penaltyLearning', type='source');getOption('warn');sessionInfo()"

R version 3.6.0 (2019-04-26) -- "Planting of a Tree"
Copyright (C) 2019 The R Foundation for Statistical Computing
Platform: x86_64-w64-mingw32/x64 (64-bit)

R is free software and comes with ABSOLUTELY NO WARRANTY.
You are welcome to redistribute it under certain conditions.
Type 'license()' or 'licence()' for distribution details.

R is a collaborative project with many contributors.
Type 'contributors()' for more information and
'citation()' on how to cite R or R packages in publications.

Type 'demo()' for some demos, 'help()' for on-line help, or
'help.start()' for an HTML browser interface to help.
Type 'q()' to quit R.

> options(repos='https://cloud.r-project.org', warn=2);install.packages('penaltyLearning', type='source');getOption('warn');sessionInfo()
trying URL 'https://cloud.r-project.org/src/contrib/penaltyLearning_2018.09.04.tar.gz'
Content type 'application/x-gzip' length 2837289 bytes (2.7 MB)
==================================================
downloaded 2.7 MB

* installing *source* package 'penaltyLearning' ...
** package 'penaltyLearning' successfully unpacked and MD5 sums checked
** using staged installation
** libs
c:/Rtools/mingw_64/bin/g++  -std=gnu++11 -I"C:/PROGRA~1/R/R-36~1.0/include" -DNDEBUG          -O2 -Wall  -mtune=generic -c interface.cpp -o interface.o
c:/Rtools/mingw_64/bin/g++  -std=gnu++11 -I"C:/PROGRA~1/R/R-36~1.0/include" -DNDEBUG          -O2 -Wall  -mtune=generic -c largestContinuousMinimum.cpp -o largestContinuousMinimum.o
largestContinuousMinimum.cpp: In function 'int largestContinuousMinimum(int, double*, double*, int*)':
largestContinuousMinimum.cpp:38:27: warning: 'start' may be used uninitialized in this function [-Wmaybe-uninitialized]
       index_vec[0] = start;
                           ^
c:/Rtools/mingw_64/bin/g++  -std=gnu++11 -I"C:/PROGRA~1/R/R-36~1.0/include" -DNDEBUG          -O2 -Wall  -mtune=generic -c modelSelection.cpp -o modelSelection.o
/usr/bin/sed: -e expression #1, char 1: unknown command: `C'
c:/Rtools/mingw_64/bin/g++ -shared -s -static-libgcc -o penaltyLearning.dll tmp.def interface.o largestContinuousMinimum.o modelSelection.o -LC:/PROGRA~1/R/R-36~1.0/bin/x64 -lR
installing to C:/Program Files/R/R-3.6.0/library/00LOCK-penaltyLearning/00new/penaltyLearning/libs/x64
** R
** data
** byte-compile and prepare package for lazy loading
** help
*** installing help indices
  converting help for package 'penaltyLearning'
    finding HTML links ... done
    GeomTallRect                            html  
    IntervalRegressionCV                    html  
    IntervalRegressionCVmargin              html  
    IntervalRegressionInternal              html  
    IntervalRegressionRegularized           html  
    IntervalRegressionUnregularized         html  
    ROChange                                html  
    change.colors                           html  
    change.labels                           html  
    changeLabel                             html  
    check_features_targets                  html  
    check_target_pred                       html  
    coef.IntervalRegression                 html  
    demo8                                   html  
    featureMatrix                           html  
    featureVector                           html  
    geom_tallrect                           html  
    labelError                              html  
    largestContinuousMinimumC               html  
    largestContinuousMinimumR               html  
    modelSelection                          html  
    modelSelectionC                         html  
    modelSelectionR                         html  
    neuroblastomaProcessed                  html  
    oneSkip                                 html  
    plot.IntervalRegression                 html  
    predict.IntervalRegression              html  
    print.IntervalRegression                html  
    squared.hinge                           html  
    targetIntervalROC                       html  
    targetIntervalResidual                  html  
    targetIntervals                         html  
    theme_no_space                          html  
** building package indices
** testing if installed package can be loaded from temporary location
** testing if installed package can be loaded from final location
** testing if installed package keeps a record of temporary installation path
* DONE (penaltyLearning)

The downloaded source packages are in
	'C:\Users\th798\AppData\Local\Temp\RtmpCeEYVI\downloaded_packages'
[1] 2
R version 3.6.0 (2019-04-26)
Platform: x86_64-w64-mingw32/x64 (64-bit)
Running under: Windows 10 x64 (build 17134)

Matrix products: default

locale:
[1] LC_COLLATE=English_United States.1252 
[2] LC_CTYPE=English_United States.1252   
[3] LC_MONETARY=English_United States.1252
[4] LC_NUMERIC=C                          
[5] LC_TIME=English_United States.1252    

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

loaded via a namespace (and not attached):
[1] compiler_3.6.0 tools_3.6.0   
> 
> 
]0;MINGW64:/c/Users/th798/R
th798@cmp2986 MINGW64 ~/R
$ 
```
