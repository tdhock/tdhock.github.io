---
layout: post
title: Benchmarking with foil
description: Comparison with atime
---



Recently Visruth Srimath Kandali asked me to review his [`foil` proposal](https://visruthsk.github.io/foil-ISC-2026/).

## Comments about memory measurement

I told him that in general it would be great to have a tool that lets us measure the peak memory used outside of the regular R memory.

In comparison, my R package [atime](https://atime-docs.netlify.app/) is for asymptotic benchmarking, and is limited to measuring regular R memory, because it uses [bench::mark()](https://bench.r-lib.org/reference/mark.html) for each data size.
The plus side is that this is portable to all different versions of R (mac win linux).
The minus side is that it only works for the R memory manager, not other memory.

## Comments about asymptotic measurement

The distinctive feature of `atime` is measuring time, memory and other quantities as a function of data size, which makes it a lot easier to see differences between versions.
This feature is called asymptotic measurement, because the goal is to determine the computation requirements for the big data regime.
This feature is not present in the other packages mentioned in the proposal.
And it is important because if you only use one fixed data size, you don’t know if the algorithm is in its asymptotic regime (big data), which is the important regime for most statistical software.
For example, consider sparse matrix or dense vector allocation (Figure 4 of [atime R Journal paper](https://rjournal.github.io/articles/RJ-2026-013/)).


``` r
library(Matrix)
vec.mat.result <- atime::atime(
  seconds.limit=0.1,
  N = 10^seq(1, 8, by=0.25),  
  vector = numeric(N),
  matrix = matrix(0, N, N),
  Matrix = Matrix(0, N, N),
  result = function(x)data.frame(length = length(x)))
plot(vec.mat.result)
```

```
## Warning in ggplot2::scale_y_log10("median line, min/max band"): log-10 transformation introduced infinite values.
## log-10 transformation introduced infinite values.
## log-10 transformation introduced infinite values.
```

![plot of chunk atime-vec-mat](/assets/img/2026-09-11-foil-atime/atime-vec-mat-1.png)

* Above we see that `vector` allocation is faster than sparse `Matrix` allocation by a constant factor (for small N), but they take the same (linear) time in the asymptotic regime (`N>1e6` on this machine).
* We also see that dense `matrix` allocation and `vector` allocation are the same speed for small N, but dense `matrix` allocation is asymptotically slower.

The amount of data needed to get to the asymptotic regime depends on the particular computer you are using.
So if you benchmark only one data size,

* it may be in the constant factor regime on one machine,
* and in the asymptotic regime on another machine.

This is a drawback of other non-asymptotic benchmarking software (besides atime), such as `foil`, `touchstone`, etc.

## Comments on comparing package versions

Another unique feature of `atime` is running different package versions in the same R session, whereas other software runs the different versions in different R sessions, which may be a source of noise.
The drawback of this feature is that you may have to create a custom `pkg.edit.fun` for editing modified package versions, so that they can install in the same R session.
This was the case for `data.table`, which requires a rather complex `pkg.edit.fun`, due to its non-standard installation scripts for compiled code, and its need for back-compatibility.
However, this is not necessary for most R packages, which use standard installation and Rcpp.
Example `atime` test case definitions for GitHub Actions CI:

* [animint2](https://github.com/animint/animint2/blob/master/.ci/atime/tests.R)
* [binsegRcpp](https://github.com/tdhock/binsegRcpp/blob/master/.ci/atime/tests.R)
* [data.table](https://github.com/Rdatatable/data.table/blob/master/.ci/atime/tests.R)

## Paired comparison

A central feature of `foil` is paired comparison, which I believe means running benchmarks like this (for the matrix/vector example discussed above)

* matrix run 1
* vector run 1
* matrix run 2
* vector run 2
* …
* matrix run 10
* vector run 10

This approach is preferred by `foil` to limit drift, which means that the earlier runs may be faster or slower than later runs.
In contrast `atime` uses `bench::mark`, and the man page does not specify the order, but the source code says

```r
        for (i in seq_len(length(exprs))) {
            res <- eval_one(exprs[[i]], memory)
```

which means that it does all of the runs for one expression, than the other:

* matrix run 1
* matrix run 2
* …
* matrix run 10
* vector run 1
* vector run 2
* …
* vector run 10

This method would be more sensitive to drift.
For example if there was some background task during earlier runs, but not later runs, then the matrix runs may appear slower than they should (if there was no background task).

However, the focus in `foil` and `touchstone` on comparing two expressions can be a limitation in the context of performance testing (in which the expressions are different software versions that may be relevant in the context of a GitHub Pull Request).
Whereas `foil` and `touchstone` are limited to comparing two versions (PR branch and base=main), `atime_pkg()` by default includes other relevant versions (merge-base, CRAN) and can also show user defined historical versions (this has been very important in `data.table`, which had many performance issues reported over the years, so many historical versions to run as references of fast and slow code).

## Test case definition

In `atime` performance testing, test cases are defined in a special file, `package/.ci/atime/tests.R`.
In the `foil` proposal, I did not see any mention of how the tests are defined.
I think it's pretty important that test cases for performance should be separate from other test cases like unit tests, which have small data sizes and so are irrelevant for performance.
That is the main drawback of previous systems like [Rperform](https://github.com/analyticalmonk/Rperform), which is limited to measuring time and memory of `testthat` test cases.

## Other figures

Here, we continue the `atime` code example, in order to highlight its other unique features (not related to performance testing different versions of R packages).
The code below computes best asymptotic references, which can be used to infer the asymptotic complexity classes (big-O notation).


``` r
vec.mat.ref <- atime::references_best(vec.mat.result)
plot(vec.mat.ref)
```

```
## Warning in ggplot2::scale_y_log10(""): log-10 transformation introduced infinite values.
```

![plot of chunk atime-ref](/assets/img/2026-09-11-foil-atime/atime-ref-1.png)

We see above linear time, `O(N)`, for `vector` and sparse `Matrix`, but quadratic time, `O(N^2)` for dense `matrix`.

The code below computes the throughput, or the data size we can handle with a given time limit.


``` r
vec.mat.pred <- predict(
  vec.mat.ref,
  seconds=vec.mat.ref$seconds.limit,
  kilobytes=1000,
  length=1e6)
plot(vec.mat.pred)
```

```
## Warning in ggplot2::scale_x_log10("N", breaks = meas[, 10^seq(ceiling(min(log10(N))), : log-10 transformation
## introduced infinite values.
```

```
## Warning in ggplot2::scale_y_log10("median line, min/max band"): log-10 transformation introduced infinite values.
```

![plot of chunk atime-pred](/assets/img/2026-09-11-foil-atime/atime-pred-1.png)

Above we see

* top panel: the `N` at the memory limit of 1000 kilobytes is about the same for sparse `Matrix` and `vector`, both orders of magnitude larger than the `N` for dense `matrix`.
* center panel: the `N` with length=1e6 is the same for sparse `Matrix` and dense `matrix`, both 1000 times smaller than `N` for `vector`.
* bottom panel: the `N` at the time limit is about the same for sparse `Matrix` and `vector`, both orders of magnitude larger than the `N` for dense `matrix`.

Overall, we have highlighted the unique features of `atime` for benchmarking R code.

## Session info


``` r
sessionInfo()
```

```
## R Under development (unstable) (2026-07-28 r90311)
## Platform: x86_64-pc-linux-gnu
## Running under: Ubuntu 24.04.5 LTS
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
## [1] Matrix_1.7-6
## 
## loaded via a namespace (and not attached):
##  [1] directlabels_2026.8.28 vctrs_0.7.3            cli_3.6.6              knitr_1.51             rlang_1.3.0           
##  [6] xfun_0.60              otel_0.2.0             bench_1.1.4            generics_0.1.4         S7_0.2.2              
## [11] data.table_1.18.6.1    glue_1.8.1             scales_1.4.0           grid_4.7.0             evaluate_1.0.5        
## [16] tibble_3.3.1           profmem_0.7.0          lifecycle_1.0.5        compiler_4.7.0         dplyr_1.2.1           
## [21] RColorBrewer_1.1-3     Rcpp_1.1.2             pkgconfig_2.0.3        atime_2026.4.2         farver_2.1.2          
## [26] lattice_0.22-9         R6_2.6.1               tidyselect_1.2.1       pillar_1.11.1          magrittr_2.0.5        
## [31] withr_3.0.3            tools_4.7.0            gtable_0.3.6           ggplot2_4.0.3
```
