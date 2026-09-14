---
layout: post
title: Hierarchical imbalanced data generation
description: More controlled comparisons
---



The purpose of this page is to continue the exploration of [More precise imbalanced data generation](https://tdhock.github.io/blog/2026/exact-downsampling).
That post explained how to divide a binary classification data set into two subsets:

* one balanced subset with 50% positive, 50% negative labels.
* one imbalanced subset with an arbitrary proportion of negative labels, `p_neg`.
* such that the two subsets have the same number of samples.

That setup can be used for comparing imbalanced versus balanced training, in the context of our recently proposed [SOAK algorithm, Hocking et al, Comp Stat Data Anal 2026](https://doi.org/10.1002/sam.70055).
However that method does not allow for controlled comparison of training on different imbalance ratios, which would be interesting to explore how much class imbalance a learning algorithm can handle.
That would require a hierarchical definition of imbalanced subsets, which was discussed in [another previous blog](https://tdhock.github.io/blog/2025/imbalance-openml/) (but without control for sample size).
In this blog we explain a method which has both properties: 

* subsets have equal sample sizes,
* and different imbalance proportions are hierarchical.

Both properties are desirable, to ensure controlled comparison.
If we see a difference in test error rates, we want to be sure that the effect is due to the class imbalance, and not some other difference between train sets (like number of samples or which samples were used).

## Problem with previous method

We are creating machine learning algorithms for imbalanced classification problems.
We would like to know if these algorithms work well for training on imbalanced data, and predicting on balanced data, and vice versa.
We therefore would like to create different subsets for testing.
Assume we start with the `higgs` data, binary classification with this many data in each class:


``` r
Tpos=5829123L
Tneg=5170877L
```

Below are the target proportions of the negative class:


``` r
(Target_prop <- 10^seq(-1, -5))
```

```
## [1] 1e-01 1e-02 1e-03 1e-04 1e-05
```

Below we repeat the calculations in the previous post:


``` r
library(data.table)
compute_target_counts <- function(p_neg, Tpos, Tneg){
  n_pos_max <- 2*Tpos*(1-p_neg)/(3-2*p_neg)
  n_pos_max_neg <- n_pos_max*p_neg/(1-p_neg)
  n_pos_max_N <- (n_pos_max_neg+n_pos_max)/2
  n_pos_max_neg_extra <- Tneg-n_pos_max_neg-n_pos_max_N
  n_neg_max <- 2*Tneg*p_neg/(1+2*p_neg)
  n_neg_max_pos <- n_neg_max*(1-p_neg)/p_neg
  n_neg_max_N <- (n_neg_max_pos+n_neg_max)/2
  ##n_neg_max_pos_extra <- Tpos-n_neg_max_pos-n_neg_max_N
  N_pos_neg <- as.integer(floor(
    ifelse(n_pos_max_neg_extra<0, n_neg_max_N, n_pos_max_N)))
  n_small <- as.integer(round(ifelse(
    p_neg<0.5,
    ifelse(n_pos_max_neg_extra<0, n_neg_max, n_pos_max_neg),
    ifelse(n_pos_max_neg_extra<0, n_neg_max_pos, n_pos_max))))
  n_large <- 2L*N_pos_neg-n_small
  data.table(
    p_neg,
    N_pos_neg,
    n_pos=ifelse(p_neg<0.5, n_large, n_small),
    n_neg=ifelse(p_neg<0.5, n_small, n_large)
  )[, let(
    pos = n_pos + N_pos_neg,
    neg = n_neg + N_pos_neg,
    check_prop = n_neg/(n_neg+n_pos)
  )][, let(
    prop_diff=check_prop-p_neg,
    extra_imb=n_pos+n_neg - 2L*N_pos_neg,
    unused_neg=Tneg-neg,
    unused_pos=Tpos-pos
  )][]
}
p_neg <- sort(c(Target_prop, 1-Target_prop), decreasing = TRUE)
(prev_dt <- compute_target_counts(p_neg, Tpos, Tneg))
```

```
##       p_neg N_pos_neg   n_pos   n_neg     pos     neg   check_prop     prop_diff extra_imb unused_neg unused_pos
##       <num>     <int>   <int>   <int>   <int>   <int>        <num>         <num>     <int>      <int>      <int>
##  1: 0.99999   1723637      34 3447240 1723671 5170877 9.999901e-01  1.371344e-07         0          0    4105452
##  2: 0.99990   1723740     345 3447135 1724085 5170875 9.998999e-01 -7.309687e-08         0          2    4105038
##  3: 0.99900   1724775    3450 3446100 1728225 5170875 9.989999e-01 -1.304518e-07         0          2    4100898
##  4: 0.99000   1735193   34704 3435682 1769897 5170875 9.900000e-01 -4.034133e-08         0          2    4059226
##  5: 0.90000   1846741  369348 3324134 2216089 5170875 9.000001e-01  5.414944e-08         0          2    3613034
##  6: 0.10000   2081829 3747292  416366 5829121 2498195 1.000000e-01  4.803468e-08         0    2672682          2
##  7: 0.01000   1956081 3873040   39122 5829121 1995203 1.000010e-02  9.713299e-08         0    3175674          2
##  8: 0.00100   1944337 3884785    3889 5829122 1948226 1.000084e-03  8.383320e-08         0    3222651          1
##  9: 0.00010   1943170 3885951     389 5829121 1943559 1.000942e-04  9.417601e-08         0    3227318          2
## 10: 0.00001   1943053 3886067      39 5829120 1943092 1.003575e-05  3.575301e-08         0    3227785          3
```

Above we see the results from the previous post.

* it works for negative proportions greater than 0.5.
* There are always the same number of samples in the imbalanced and balanced subsets (`extra_imb=0` in every row).
* Every row has a valid `neg <= Tneg = 5170877` (no `neg` values that are too large to create), even for large values of the target proportion for the negative class, `p_neg >= 0.45`. This is verified above: all rows have non-negative numbers in the `unused` columns.

So each row defines a valid pair of subsets (one balanced, one imbalanced), but the rows are not consistent with each other.
Look at the `N_pos_neg` column. Values are not quite the same, so we can’t use this method to create hierarchical subsets.
We would like to have, for example:

* `p_neg=0.01` and `p_neg=0.1` having the same sized subsets, and
* `p_neg=0.01` having a subset of the negative examples of `p_neg=0.1`, and
* `p_neg=0.1` having a subset of the positive examples of `p_neg=0.01`.

## New hierarchical method

We assume there is a list of desired proportions of the negative class in the imbalanced subset:


``` r
Target_prop
```

```
## [1] 1e-01 1e-02 1e-03 1e-04 1e-05
```

The most extreme is:


``` r
xp_neg <- min(Target_prop)
```

The main idea of the new method is to divide the whole data into three sets:

* two sets X and Y with equal numbers of positive and negative samples,
* one set E with some extra samples of either the positive or negative class.

For each target proportion of negative samples in the imbalanced subset,
these sets will be used to create subsets:

* Xi versus Y: an imbalanced version of X, created by removing the first few rows of the minority class, and by adding the first few rows of E.
* X versus Yi: an imbalanced version of Y, created by removing the first few rows of the minority class, and by adding the first few rows of E.
* X versus Y: both subsets balanced, for comparing prediction error rates with a baseline training method.

### Identifying active constraint

There are two inequality constraints to consider in the computation of `N`, the number of positive samples (and negative samples) in A and B (there are 2N samples in A, 2N samples in B, 4N samples total across A and B).

First constraint is the same as the previous method, `N + n_pos <= Tpos`.
If this is active, then the number of positive samples in the most imbalanced subset is the limiting factor.


``` r
n_pos_max <- 2*Tpos*(1-xp_neg)/(3-2*xp_neg)
n_pos_max_neg <- n_pos_max*xp_neg/(1-xp_neg)
(n_pos_max_N <- as.integer(floor((n_pos_max_neg+n_pos_max)/2)))
```

```
## [1] 1943053
```

``` r
(n_pos_max_bal_neg <- n_pos_max_N*2)
```

```
## [1] 3886106
```

``` r
Tneg-n_pos_max_bal_neg
```

```
## [1] 1284771
```

We see above that there are many negative samples left over, so this works.
Below we consider the other option, could N be limited by the number of negative samples in the balanced subset?


``` r
(Tneg_N <- as.integer(floor(Tneg/2)))
```

```
## [1] 2585438
```

``` r
(Tneg_n_pos <- Tneg*(1-xp_neg))
```

```
## [1] 5170825
```

``` r
(Tneg_imb_pos <- Tneg_n_pos+Tneg_N)
```

```
## [1] 7756263
```

``` r
Tpos-Tneg_imb_pos
```

```
## [1] -1927140
```

We see above a negative value, indicating this is not feasible.
The other constraint must be active.

### Computing subset sizes



``` r
data.table(
  Target_prop=c(0.5, Target_prop),
  n_bal=2L*n_pos_max_N
)[, let(
  n_neg=as.integer(round(2*n_pos_max_N*Target_prop))
)][, let(
  n_pos=n_bal-n_neg
)][, let(
  n_imb=n_pos+n_neg,
  extra_pos=Tpos-n_pos-n_pos_max_N,
  extra_neg=Tneg-n_neg-n_pos_max_N
)][]
```

```
##    Target_prop   n_bal   n_neg   n_pos   n_imb extra_pos extra_neg
##          <num>   <int>   <int>   <int>   <int>     <int>     <int>
## 1:       5e-01 3886106 1943053 1943053 3886106   1943017   1284771
## 2:       1e-01 3886106  388611 3497495 3886106    388575   2839213
## 3:       1e-02 3886106   38861 3847245 3886106     38825   3188963
## 4:       1e-03 3886106    3886 3882220 3886106      3850   3223938
## 5:       1e-04 3886106     389 3885717 3886106       353   3227435
## 6:       1e-05 3886106      39 3886067 3886106         3   3227785
```

TODO target prop > 0.5.
TODO sizes from other constraints.

## Conclusions

TODO

## session info


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
## [1] ggplot2_4.0.3       data.table_1.18.6.1
## 
## loaded via a namespace (and not attached):
##  [1] labeling_0.4.3     RColorBrewer_1.1-3 R6_2.6.1           tidyselect_1.2.1   xfun_0.60          farver_2.1.2      
##  [7] magrittr_2.0.5     gtable_0.3.6       glue_1.8.1         tibble_3.3.1       knitr_1.51         pkgconfig_2.0.3   
## [13] generics_0.1.4     dplyr_1.2.1        lifecycle_1.0.5    cli_3.6.6          S7_0.2.2           scales_1.4.0      
## [19] vctrs_0.7.3        grid_4.7.0         withr_3.0.3        compiler_4.7.0     tools_4.7.0        pillar_1.11.1     
## [25] evaluate_1.0.5     otel_0.2.0         rlang_1.3.0
```
