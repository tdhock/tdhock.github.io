---
layout: post
title: Ordinary least squares algorithms
description: Comparing computation time in R
---



The goal of this post is to explore time complexity of various methods
for computing least squares regression models.

## Introduction 

Least squares regression is a fundamental and classic model in
statistics and in machine learning. When you learn about it in a
stats class, you usually see its computation via the matrix inverse,
but when you look at `?lm` in R you see

```
  method: the method to be used; for fitting, currently only ‘method =
          "qr"’ is supported...
```

- [Arbenz
  notes](https://people.inf.ethz.ch/arbenz/ewp/Lnotes/chapter4.pdf)
  say that QR time complexity is `O(N^3)`
- R `?solve` says LAPACK [dgesv](https://netlib.org/lapack/explore-html-3.6.1/d7/d3b/group__double_g_esolve_ga5ee879032a8365897c3ba91e3dc8d512.html) is used, which says [LU decomposition](https://en.wikipedia.org/wiki/LU_decomposition) is used, which is same complexity as matrix multiplication, typically `O(N^3)` as well.

So the asymptotic time complexity is the same. Why is QR preferred?
For numerical stability, which means that it is more likely to compute
a valid result, for numerically unusual inputs.

## R implementations


``` r
Nrow <- 5
Ncol <- 2
set.seed(1)
X <- matrix(runif(Nrow*Ncol), Nrow, Ncol)
y <- runif(Nrow)
Xt <- t(X)
qres <- qr(X)
rbind(
  LU=as.numeric(solve(Xt %*% X) %*% (Xt %*% y)),
  QR=solve(qres, y),
  lm=as.numeric(coef(lm(y ~ X + 0))))
```

```
##        [,1]        [,2]
## LU 0.768795 -0.03883457
## QR 0.768795 -0.03883457
## lm 0.768795 -0.03883457
```

Above we see the three methods compute the same result.

### Number of rows increases with N

Converting the examples above to atime code below, (with a constant number of columns=2)


``` r
atime.vary.rows <- atime::atime(
  setup={
    Ncol <- 2
    set.seed(1)
    X <- matrix(runif(N*Ncol), N, Ncol)
    y <- runif(N)
  },
  seconds.limit=0.1,
  LU={
    Xt <- t(X)
    as.numeric(solve(Xt %*% X) %*% (Xt %*% y))
  },
  QR={
    qres <- qr(X)
    solve(qres, y)
  },
  lm=as.numeric(coef(lm(y ~ X + 0))))
plot(atime.vary.rows)
```

```
## Warning in ggplot2::scale_y_log10("median line, min/max band"): log-10 transformation introduced infinite values.
## log-10 transformation introduced infinite values.
## log-10 transformation introduced infinite values.
```

![plot of chunk atime-vary-rows](/assets/img/2024-09-17-ordinary-least-squares-algos/atime-vary-rows-1.png)

The plot above shows that `solve` in R (LU decomposition, LAPACK
dgesv) is fastest, looks like by constant factors. The code below
estimates asymptotic time complexity.


``` r
refs.vary.rows <- atime::references_best(atime.vary.rows)
plot(refs.vary.rows)
```

```
## Warning in ggplot2::scale_y_log10(""): log-10 transformation introduced infinite values.
```

![plot of chunk refs-vary-rows](/assets/img/2024-09-17-ordinary-least-squares-algos/refs-vary-rows-1.png)

The plot above shows almost linear trends for all methods, contrary to
the expectation of cubic.

### Rows and columns increase with N

The code below additionally increases the number of columns.


``` r
atime.vary.rows.cols <- atime::atime(
  setup={
    Ncol <- N-1
    set.seed(1)
    X <- matrix(runif(N*Ncol), N, Ncol)
    y <- runif(N)
  },
  seconds.limit=0.1,
  LU={
    Xt <- t(X)
    as.numeric(solve(Xt %*% X) %*% (Xt %*% y))
  },
  QR={
    qres <- qr(X)
    solve(qres, y)
  },
  lm=as.numeric(coef(lm(y ~ X + 0))))
plot(atime.vary.rows.cols)
```

```
## Warning in ggplot2::scale_y_log10("median line, min/max band"): log-10 transformation introduced infinite values.
## log-10 transformation introduced infinite values.
## log-10 transformation introduced infinite values.
```

![plot of chunk atime-vary-rows-cols](/assets/img/2024-09-17-ordinary-least-squares-algos/atime-vary-rows-cols-1.png)

The plot above shows that `QR` and `lm` are about the same, which
makes sense, because `lm` uses QR decomposition method. The difference
between them for small `N` can be attributed to the overhead of the
`lm` formula parsing, etc. Both are slightly faster than `LU` in this case.
Below we estimate asymptotic complexity classes.


``` r
refs.vary.rows.cols <- atime::references_best(atime.vary.rows.cols)
plot(refs.vary.rows.cols)
```

```
## Warning in ggplot2::scale_y_log10(""): log-10 transformation introduced infinite values.
```

![plot of chunk refs-vary-rows-cols](/assets/img/2024-09-17-ordinary-least-squares-algos/refs-vary-rows-cols-1.png)

The plot above suggests cubic `N^3` asymptotic time for all methods, and
quadratic `N^2` asymptotic memory.

## Conclusions

We have shown that there is no large asymptotic time/memory
differences between the different methods of estimating least squares
regression coefficients.

## Session info


``` r
sessionInfo()
```

```
## R version 4.4.1 (2024-06-14)
## Platform: x86_64-pc-linux-gnu
## Running under: Ubuntu 22.04.5 LTS
## 
## Matrix products: default
## BLAS:   /usr/lib/x86_64-linux-gnu/blas/libblas.so.3.10.0 
## LAPACK: /usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.10.0
## 
## locale:
##  [1] LC_CTYPE=fr_FR.UTF-8       LC_NUMERIC=C               LC_TIME=fr_FR.UTF-8        LC_COLLATE=fr_FR.UTF-8    
##  [5] LC_MONETARY=fr_FR.UTF-8    LC_MESSAGES=fr_FR.UTF-8    LC_PAPER=fr_FR.UTF-8       LC_NAME=C                 
##  [9] LC_ADDRESS=C               LC_TELEPHONE=C             LC_MEASUREMENT=fr_FR.UTF-8 LC_IDENTIFICATION=C       
## 
## time zone: America/New_York
## tzcode source: system (glibc)
## 
## attached base packages:
## [1] stats     graphics  utils     datasets  grDevices methods   base     
## 
## loaded via a namespace (and not attached):
##  [1] directlabels_2024.1.21 vctrs_0.6.5            cli_3.6.2              knitr_1.47             rlang_1.1.3           
##  [6] xfun_0.45              highr_0.11             bench_1.1.3            generics_0.1.3         data.table_1.16.0     
## [11] glue_1.7.0             colorspace_2.1-0       scales_1.3.0           fansi_1.0.6            quadprog_1.5-8        
## [16] grid_4.4.1             evaluate_0.23          munsell_0.5.0          tibble_3.2.1           profmem_0.6.0         
## [21] lifecycle_1.0.4        compiler_4.4.1         dplyr_1.1.4            pkgconfig_2.0.3        atime_2024.4.23       
## [26] farver_2.1.1           lattice_0.22-6         R6_2.5.1               tidyselect_1.2.1       utf8_1.2.4            
## [31] pillar_1.9.0           magrittr_2.0.3         withr_3.0.0            tools_4.4.1            gtable_0.3.4          
## [36] ggplot2_3.5.1
```
