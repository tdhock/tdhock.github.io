---
layout: post
title: Reformatting NEWS files
description: Regular expression example
---



To make my research about new machine learning algorithms more
reproducible, I provide free/open-source implementations as R
packages, published on the CRAN (Comprehensive R Archive Network). In
2022, CRAN introduced a new policy that NEWS files must be in a
standard format, so I started to get CRAN check messages as below,

```
Flavor: r-devel-linux-x86_64-debian-gcc
Check: package subdirectories, Result: NOTE
  Problems with news in 'NEWS':
    Cannot process chunk/lines:
      Line search C++ code review, exclude speed and line search vignettes from CRAN.
    Cannot process chunk/lines:
      aum_diffs_penalty now correctly handles denominator="rate" (previously
    Cannot process chunk/lines:
      there could be problems if there are more examples in error table than
```

The first few lines of my old NEWS file were


```r
NEWS <- "~/R/aum/NEWS"
NEWS <- "~/teaching/regex-tutorial/NEWS/old/aum.txt"
NEWS.lines <- readLines(NEWS)
```

```
## Warning in readLines(NEWS): incomplete final line found on
## '~/teaching/regex-tutorial/NEWS/old/aum.txt'
```

```r
cat(head(NEWS.lines, 19), sep="\n")
```

```
## TODOs
## 
## 2022.2.7
## 
## Add arXiv link to DESCRIPTION, clarify outputs in aum_diffs.
## 
## 2022.2.3
## 
## Remove un-necessary C++ code, just keep aum_sort and interface.
## 
## 2022.1.27
## 
## rename test file.
## 
## 2021.9.23
## 
## aum_sort.cpp: fix read out of bound when err_N=1, use std::sort
## instead of qsort.
```

Since there is some structure, we can use a regular expression to
parse the news items into a data table...


```r
change.dt <- nc::capture_all_str(
  NEWS.lines,
  version="[0-9]+[.][0-9]+[.][0-9]+",
  "\\s*\n",
  changes="(?:[^0-9].*\n*)*")
change.dt[, .(version, changes=substr(changes,1,50))]
```

```
##       version                                              changes
##        <char>                                               <char>
##  1:  2022.2.7   Add arXiv link to DESCRIPTION, clarify outputs in 
##  2:  2022.2.3   Remove un-necessary C++ code, just keep aum_sort a
##  3: 2022.1.27                                rename test file.\n\n
##  4: 2021.9.23   aum_sort.cpp: fix read out of bound when err_N=1, 
##  5:  2021.3.9   vignette comparing logistic regression and other l
##  6:  2021.3.2   Use qsort (standard C) instead of qsort_r (not sta
##  7: 2021.2.20   error checking for min.lambda values input to aum_
##  8: 2021.2.16   aum supports names for predictions (copied to row 
##  9: 2021.2.15 more C++ error checking / tests.\n\nvignette compari
## 10: 2021.2.14   aum_diffs, aum_diffs_binary, aum_diffs_penalty for
## 11: 2021.2.12                                         First draft.
```

...then convert them into the correct format,


```r
change.dt[, change.list := strsplit(changes, "\n\n")]
change.dt[, new.str := sapply(change.list, function(change.vec){
  no.newline <- gsub("\n", " ", change.vec)
  with.dash <- paste0("- ", no.newline)
  paste(with.dash, collapse="\n")
})]
change.dt[, new.block := sprintf(
  "Changes in version %s\n\n%s", version, new.str)]
out.str <- paste(change.dt$new.block, collapse="\n\n")
cat(out.str)
```

```
## Changes in version 2022.2.7
## 
## - Add arXiv link to DESCRIPTION, clarify outputs in aum_diffs.
## 
## Changes in version 2022.2.3
## 
## - Remove un-necessary C++ code, just keep aum_sort and interface.
## 
## Changes in version 2022.1.27
## 
## - rename test file.
## 
## Changes in version 2021.9.23
## 
## - aum_sort.cpp: fix read out of bound when err_N=1, use std::sort instead of qsort.
## 
## Changes in version 2021.3.9
## 
## - vignette comparing logistic regression and other loss functions to aum minimization.
## 
## Changes in version 2021.3.2
## 
## - Use qsort (standard C) instead of qsort_r (not standard).
## 
## Changes in version 2021.2.20
## 
## - error checking for min.lambda values input to aum_diffs_penalty.
## - new aum_sort_interface C++ function (faster), older function renamed to aum_map_interface, separate source and header files.
## 
## Changes in version 2021.2.16
## 
## - aum supports names for predictions (copied to row names of derivative_mat).
## 
## Changes in version 2021.2.15
## 
## - more C++ error checking / tests.
## - vignette comparing speed with penaltyLearning::ROChange.
## 
## Changes in version 2021.2.14
## 
## - aum_diffs, aum_diffs_binary, aum_diffs_penalty for creating error diffs data frame required for input to aum.
## - aum_errors for converting aum_diffs to canonical error functions (which start at fp=0 and end at fn=0). plot.aum_diffs uses this to show a default plot of the error functions.
## - fn.not.zero example data taken from feaure-learning-benchmark.
## 
## Changes in version 2021.2.12
## 
## - First draft.
```
