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
(xp_neg <- min(Target_prop))
```

```
## [1] 1e-05
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
(n_pos_max <- 2*Tpos*(1-xp_neg)/(3-2*xp_neg))
```

```
## [1] 3886069
```

``` r
(n_pos_max_neg <- n_pos_max*xp_neg/(1-xp_neg))
```

```
## [1] 38.86108
```

``` r
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
Maxing out the negative examples does not leave enough extra positive examples.
The other constraint must be active.

### Computing subset sizes


``` r
extab <- function(Tprop, N, Tpos, Tneg){
  dt <- data.table(
    p_neg=sort(c(0.5, Tprop)),
    n_bal=2L*N
  )[, let(
    n_neg=as.integer(round(2*N*p_neg))
  )][, let(
    n_pos=n_bal-n_neg
  )][, let(
    n_imb=n_pos+n_neg,
    unused_pos=Tpos-n_pos-N,
    unused_neg=Tneg-n_neg-N
  )][]
  list(props=dt, params=dt[, data.table(
    extra_pos=max(n_pos-N),
    extra_neg=max(n_neg-N),
    N)])
}
extab(Target_prop, n_pos_max_N, Tpos, Tneg)
```

```
## $props
##    p_neg   n_bal   n_neg   n_pos   n_imb unused_pos unused_neg
##    <num>   <int>   <int>   <int>   <int>      <int>      <int>
## 1: 1e-05 3886106      39 3886067 3886106          3    3227785
## 2: 1e-04 3886106     389 3885717 3886106        353    3227435
## 3: 1e-03 3886106    3886 3882220 3886106       3850    3223938
## 4: 1e-02 3886106   38861 3847245 3886106      38825    3188963
## 5: 1e-01 3886106  388611 3497495 3886106     388575    2839213
## 6: 5e-01 3886106 1943053 1943053 3886106    1943017    1284771
## 
## $params
##    extra_pos extra_neg       N
##        <int>     <int>   <int>
## 1:   1943014         0 1943053
```

We see above that `n_bal == n_imb` for each row, which means the two subsets have the same number of samples, and we can create hierarchical subsets.

### Other constraint active

When would the other constraint become active?
If there are not enough negative samples, for example ten times fewer:


``` r
Tpos=5829123L
Tneg=517087L

(n_pos_max <- 2*Tpos*(1-xp_neg)/(3-2*xp_neg))
```

```
## [1] 3886069
```

``` r
(n_pos_max_neg <- n_pos_max*xp_neg/(1-xp_neg))
```

```
## [1] 38.86108
```

``` r
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
## [1] -3369019
```

Above the negative number indicates that there are not enough negative samples for this constraint to be active.
Below we compute the feasibility for the other constraint.


``` r
(Tneg_N <- as.integer(floor(Tneg/2)))
```

```
## [1] 258543
```

``` r
(Tneg_n_pos <- Tneg*(1-xp_neg))
```

```
## [1] 517081.8
```

``` r
(Tneg_imb_pos <- Tneg_n_pos+Tneg_N)
```

```
## [1] 775624.8
```

``` r
Tpos-Tneg_imb_pos
```

```
## [1] 5053498
```

Above we see a positive number, which indicates that the number of positive samples is feasible.


``` r
extab(Target_prop, Tneg_N, Tpos, Tneg)
```

```
## $props
##    p_neg  n_bal  n_neg  n_pos  n_imb unused_pos unused_neg
##    <num>  <int>  <int>  <int>  <int>      <int>      <int>
## 1: 1e-05 517086      5 517081 517086    5053499     258539
## 2: 1e-04 517086     52 517034 517086    5053546     258492
## 3: 1e-03 517086    517 516569 517086    5054011     258027
## 4: 1e-02 517086   5171 511915 517086    5058665     253373
## 5: 1e-01 517086  51709 465377 517086    5105203     206835
## 6: 5e-01 517086 258543 258543 517086    5312037          1
## 
## $params
##    extra_pos extra_neg      N
##        <int>     <int>  <int>
## 1:    258538         0 258543
```

Above we see `extra_neg` close to zero, indicating the number of negative samples was the limiting factor.

### Large target proportion of negative samples in imbalanced subset

How does the algorithm work for target proportion greater than one half?
In that case there are two inequalities to check:

* `N + n_neg <= Tneg`
* `2*N <= Tpos`


``` r
Tpos=5829123L
Tneg=5170877L
(Target_prop <- 1-10^seq(-1, -5))
```

```
## [1] 0.90000 0.99000 0.99900 0.99990 0.99999
```

``` r
(xp_neg <- max(Target_prop))
```

```
## [1] 0.99999
```

``` r
(n_neg_max <- 2*Tneg*xp_neg/(1+2*xp_neg))
```

```
## [1] 3447240
```

``` r
(n_neg_max_pos <- n_neg_max*(1-xp_neg)/xp_neg)
```

```
## [1] 34.47274
```

``` r
(n_neg_max_N <- (n_neg_max_pos+n_neg_max)/2)
```

```
## [1] 1723637
```

``` r
(n_neg_max_bal_pos <- n_neg_max_N*2)
```

```
## [1] 3447274
```

``` r
Tpos-n_neg_max_bal_pos
```

```
## [1] 2381849
```

Above the positive number indicates that are enough positive samples for this constraint to be active.
Below we compute the feasibility for the other constraint.


``` r
(Tpos_N <- as.integer(floor(Tpos/2)))
```

```
## [1] 2914561
```

``` r
(Tpos_n_pos <- Tpos*(1-xp_neg))
```

```
## [1] 58.29123
```

``` r
(Tpos_n_neg <- Tpos_N*2-Tpos_n_pos)
```

```
## [1] 5829064
```

``` r
(Tpos_imb_neg <- Tpos_n_neg+Tpos_N)
```

```
## [1] 8743625
```

``` r
Tneg-Tpos_imb_neg
```

```
## [1] -3572748
```

The negative number indicates this second constraint is not active.

### General code for both cases

The function below works for both cases.


``` r
ntab <- function(Target_prop, Tpos, Tneg){
  if(all(Target_prop<0.5)){
    Tminor <- Tneg
    Tmajor <- Tpos
    p_minor <- Target_prop
  }else if(all(Target_prop>0.5)){
    Tminor <- Tpos
    Tmajor <- Tneg
    p_minor <- 1-Target_prop
  }else stop("Target_prop should be numeric, with each entry greater than 0.5, or each entry less than 0.5")
  xp_minor <- min(p_minor)
  (n_pos_max <- 2*Tmajor*(1-xp_minor)/(3-2*xp_minor))
  (n_pos_max_neg <- n_pos_max*xp_minor/(1-xp_minor))
  (n_pos_max_N <- as.integer(floor((n_pos_max_neg+n_pos_max)/2)))
  (n_pos_max_bal_neg <- n_pos_max_N*2)
  (Tminor_N <- as.integer(floor(Tminor/2)))
  N <- if(Tminor<n_pos_max_bal_neg)Tminor_N else n_pos_max_N
  extab(Target_prop, N, Tpos, Tneg)
}
ntab(1-10^seq(-1, -5), 5829123L, 5170877L)
```

```
## $props
##      p_neg   n_bal   n_neg   n_pos   n_imb unused_pos unused_neg
##      <num>   <int>   <int>   <int>   <int>      <int>      <int>
## 1: 0.50000 3447274 1723637 1723637 3447274    2381849    1723603
## 2: 0.90000 3447274 3102547  344727 3447274    3760759     344693
## 3: 0.99000 3447274 3412801   34473 3447274    4071013      34439
## 4: 0.99900 3447274 3443827    3447 3447274    4102039       3413
## 5: 0.99990 3447274 3446929     345 3447274    4105141        311
## 6: 0.99999 3447274 3447240      34 3447274    4105452          0
## 
## $params
##    extra_pos extra_neg       N
##        <int>     <int>   <int>
## 1:         0   1723603 1723637
```

``` r
ntab(1-10^seq(-1, -5), 582912L, 5170877L)
```

```
## $props
##      p_neg  n_bal  n_neg  n_pos  n_imb unused_pos unused_neg
##      <num>  <int>  <int>  <int>  <int>      <int>      <int>
## 1: 0.50000 582912 291456 291456 582912          0    4587965
## 2: 0.90000 582912 524621  58291 582912     233165    4354800
## 3: 0.99000 582912 577083   5829 582912     285627    4302338
## 4: 0.99900 582912 582329    583 582912     290873    4297092
## 5: 0.99990 582912 582854     58 582912     291398    4296567
## 6: 0.99999 582912 582906      6 582912     291450    4296515
## 
## $params
##    extra_pos extra_neg      N
##        <int>     <int>  <int>
## 1:         0    291450 291456
```

``` r
ntab(10^seq(-1, -5), 5829123L, 5170877L)
```

```
## $props
##    p_neg   n_bal   n_neg   n_pos   n_imb unused_pos unused_neg
##    <num>   <int>   <int>   <int>   <int>      <int>      <int>
## 1: 1e-05 3886106      39 3886067 3886106          3    3227785
## 2: 1e-04 3886106     389 3885717 3886106        353    3227435
## 3: 1e-03 3886106    3886 3882220 3886106       3850    3223938
## 4: 1e-02 3886106   38861 3847245 3886106      38825    3188963
## 5: 1e-01 3886106  388611 3497495 3886106     388575    2839213
## 6: 5e-01 3886106 1943053 1943053 3886106    1943017    1284771
## 
## $params
##    extra_pos extra_neg       N
##        <int>     <int>   <int>
## 1:   1943014         0 1943053
```

``` r
ntab(10^seq(-1, -5), 5829123L, 517087L)
```

```
## $props
##    p_neg  n_bal  n_neg  n_pos  n_imb unused_pos unused_neg
##    <num>  <int>  <int>  <int>  <int>      <int>      <int>
## 1: 1e-05 517086      5 517081 517086    5053499     258539
## 2: 1e-04 517086     52 517034 517086    5053546     258492
## 3: 1e-03 517086    517 516569 517086    5054011     258027
## 4: 1e-02 517086   5171 511915 517086    5058665     253373
## 5: 1e-01 517086  51709 465377 517086    5105203     206835
## 6: 5e-01 517086 258543 258543 517086    5312037          1
## 
## $params
##    extra_pos extra_neg      N
##        <int>     <int>  <int>
## 1:    258538         0 258543
```

``` r
ntab(10^seq(-1, -2), 3000L, 2000L)
```

```
## $props
##    p_neg n_bal n_neg n_pos n_imb unused_pos unused_neg
##    <num> <int> <int> <int> <int>      <int>      <int>
## 1:  0.01  2000    20  1980  2000         20        980
## 2:  0.10  2000   200  1800  2000        200        800
## 3:  0.50  2000  1000  1000  2000       1000          0
## 
## $params
##    extra_pos extra_neg     N
##        <int>     <int> <int>
## 1:       980         0  1000
```

We see in all the results above that `n_bal == n_imb`.
Either positive or negative numbers are the limiting factor.

## Creating CSV data based on counts

After having computed the target number of samples in each subset, we need to assign rows to A/B/E sets.
Here is a dummy data table,


``` r
dummy.dt <- data.table(y=rep(0:1, c(2000,3000)))
Tlist <- setNames(as.list(table(dummy.dt$y)), c("Tneg", "Tpos"))
Tlist$Target_prop <- 10^seq(-1, -2)
Tlist
```

```
## $Tneg
## [1] 2000
## 
## $Tpos
## [1] 3000
## 
## $Target_prop
## [1] 0.10 0.01
```

``` r
(count.list <- do.call(ntab, Tlist))
```

```
## $props
##    p_neg n_bal n_neg n_pos n_imb unused_pos unused_neg
##    <num> <int> <int> <int> <int>      <int>      <int>
## 1:  0.01  2000    20  1980  2000         20        980
## 2:  0.10  2000   200  1800  2000        200        800
## 3:  0.50  2000  1000  1000  2000       1000          0
## 
## $params
##    extra_pos extra_neg     N
##        <int>     <int> <int>
## 1:       980         0  1000
```

Above we see the expected counts for a small problem with 2000 samples in A and B, with 980 extra positives.


``` r
set.seed(1)
(ind.dt <- dummy.dt[
, row := .I
][sample(.N)][
, set := NA_character_
][])
```

```
##           y   row    set
##       <int> <int> <char>
##    1:     0  1017   <NA>
##    2:     1  4775   <NA>
##    3:     1  2177   <NA>
##    4:     0  1533   <NA>
##    5:     1  4567   <NA>
##   ---                   
## 4996:     0  1397   <NA>
## 4997:     1  2779   <NA>
## 4998:     0  1255   <NA>
## 4999:     1  2262   <NA>
## 5000:     1  2606   <NA>
```

Above we see a random ordering of the data rows, set not yet assigned.


``` r
label.list <- list(pos=1,neg=0)
N <- count.list$params$N
for(label.name in names(label.list)){
  label.value <- label.list[[label.name]]
  label.extra <- count.list$params[[paste0("extra_", label.name)]]
  set.values <- rep(c("X","Y","E"), c(N,N,label.extra))
  label.i <- which(ind.dt$y==label.value)[seq_along(set.values)]
  ind.dt[label.i, set := set.values]
}
ind.dt[, table(set, y, useNA="always")]
```

```
##       y
## set       0    1 <NA>
##   E       0  980    0
##   X    1000 1000    0
##   Y    1000 1000    0
##   <NA>    0   20    0
```

Above we see set has been assigned,

* 1000 positive samples in each of X and Y,
* 1000 negative samples in each of X and Y,
* 980 positive samples in E,
* 20 unused positive samples (missing set).

We assign fold below too.


``` r
n.folds <- 5L
ind.dt[, fold := rep(1:n.folds, length.out=.N), by=.(set, y)][]
```

```
##           y   row    set  fold
##       <int> <int> <char> <int>
##    1:     0  1017      X     1
##    2:     1  4775      X     1
##    3:     1  2177      X     2
##    4:     0  1533      X     2
##    5:     1  4567      X     3
##   ---                         
## 4996:     0  1397      Y     4
## 4997:     1  2779   <NA>     3
## 4998:     0  1255      Y     5
## 4999:     1  2262   <NA>     4
## 5000:     1  2606   <NA>     5
```

Now we create the output columns representing the different subsets.


``` r
(out.unsort <- ind.dt[, data.table(
  fold,
  Xb_Yb=ifelse(set %in% c("X","Y"), set, NA))])
```

```
##        fold  Xb_Yb
##       <int> <char>
##    1:     1      X
##    2:     1      X
##    3:     2      X
##    4:     2      X
##    5:     3      X
##   ---             
## 4996:     4      Y
## 4997:     3   <NA>
## 4998:     5      Y
## 4999:     4   <NA>
## 5000:     5   <NA>
```

``` r
out.unsort[, table(fold, Xb_Yb)]
```

```
##     Xb_Yb
## fold   X   Y
##    1 400 400
##    2 400 400
##    3 400 400
##    4 400 400
##    5 400 400
```

``` r
imb.counts <- count.list$props[p_neg != 0.5]
pos.part <- function(x)ifelse(x<0, 0, x)
for(cformat in c("Xineg%s_Yb", "Xb_Yineg%s")){
  for(imb.i in nrow(imb.counts):1){
    imb.row <- imb.counts[imb.i]
    add.dt <- data.table(ind.dt)
    imb.set <- ifelse(grepl("Xi", cformat), "X", "Y")
    for(label.name in names(label.list)){
      label.value <- label.list[[label.name]]
      label.n <- imb.row[[paste0("n_", label.name)]]
      rm.vec <- ind.dt[, which(y==label.value & set==imb.set)]
      rm.n <- pos.part(N-label.n)
      rm.indices <- rm.vec[seq_len(rm.n)]
      add.dt[rm.indices, set := NA]
      add.vec <- ind.dt[, which(y==label.value & set=="E")]
      add.n <- pos.part(label.n-N)
      add.indices <- add.vec[seq_len(add.n)]
      add.dt[add.indices, set := imb.set]
    }
    add.dt[set=="E", set := NA]
    add.dt[, table(fold, paste(set, y))]#check
    set(
      out.unsort,
      j=sprintf(cformat, imb.row$p_neg),
      value=add.dt$set)
  }
}
```

Finally we sort back to the original row order:


``` r
orig.ord <- order(ind.dt$row)
print(data.table(ind.dt[, .(y, set)], out.unsort)[orig.ord], topn=50)
```

```
##           y    set  fold  Xb_Yb Xineg0.1_Yb Xineg0.01_Yb Xb_Yineg0.1 Xb_Yineg0.01
##       <int> <char> <int> <char>      <char>       <char>      <char>       <char>
##    1:     0      Y     1      Y           Y            Y        <NA>         <NA>
##    2:     0      Y     2      Y           Y            Y           Y            Y
##    3:     0      Y     2      Y           Y            Y        <NA>         <NA>
##    4:     0      X     1      X        <NA>         <NA>           X            X
##    5:     0      Y     4      Y           Y            Y        <NA>         <NA>
##    6:     0      Y     5      Y           Y            Y        <NA>         <NA>
##    7:     0      X     5      X        <NA>         <NA>           X            X
##    8:     0      Y     4      Y           Y            Y        <NA>         <NA>
##    9:     0      X     3      X        <NA>         <NA>           X            X
##   10:     0      Y     4      Y           Y            Y           Y         <NA>
##   11:     0      X     5      X        <NA>         <NA>           X            X
##   12:     0      Y     2      Y           Y            Y        <NA>         <NA>
##   13:     0      Y     3      Y           Y            Y           Y         <NA>
##   14:     0      X     5      X        <NA>         <NA>           X            X
##   15:     0      X     1      X        <NA>         <NA>           X            X
##   16:     0      X     4      X        <NA>         <NA>           X            X
##   17:     0      X     2      X        <NA>         <NA>           X            X
##   18:     0      Y     2      Y           Y            Y        <NA>         <NA>
##   19:     0      Y     1      Y           Y            Y        <NA>         <NA>
##   20:     0      Y     1      Y           Y            Y        <NA>         <NA>
##   21:     0      Y     3      Y           Y            Y        <NA>         <NA>
##   22:     0      X     1      X        <NA>         <NA>           X            X
##   23:     0      X     4      X        <NA>         <NA>           X            X
##   24:     0      Y     5      Y           Y            Y           Y         <NA>
##   25:     0      Y     3      Y           Y            Y        <NA>         <NA>
##   26:     0      Y     5      Y           Y            Y        <NA>         <NA>
##   27:     0      X     4      X        <NA>         <NA>           X            X
##   28:     0      Y     5      Y           Y            Y        <NA>         <NA>
##   29:     0      X     3      X        <NA>         <NA>           X            X
##   30:     0      Y     1      Y           Y            Y        <NA>         <NA>
##   31:     0      Y     5      Y           Y            Y           Y         <NA>
##   32:     0      Y     2      Y           Y            Y        <NA>         <NA>
##   33:     0      Y     4      Y           Y            Y        <NA>         <NA>
##   34:     0      X     2      X        <NA>         <NA>           X            X
##   35:     0      Y     2      Y           Y            Y           Y         <NA>
##   36:     0      X     5      X        <NA>         <NA>           X            X
##   37:     0      X     4      X        <NA>         <NA>           X            X
##   38:     0      X     4      X           X         <NA>           X            X
##   39:     0      X     2      X        <NA>         <NA>           X            X
##   40:     0      X     1      X        <NA>         <NA>           X            X
##   41:     0      X     2      X        <NA>         <NA>           X            X
##   42:     0      Y     1      Y           Y            Y        <NA>         <NA>
##   43:     0      Y     1      Y           Y            Y        <NA>         <NA>
##   44:     0      X     1      X        <NA>         <NA>           X            X
##   45:     0      Y     4      Y           Y            Y        <NA>         <NA>
##   46:     0      X     1      X        <NA>         <NA>           X            X
##   47:     0      Y     4      Y           Y            Y        <NA>         <NA>
##   48:     0      X     5      X        <NA>         <NA>           X            X
##   49:     0      Y     5      Y           Y            Y           Y         <NA>
##   50:     0      X     3      X           X         <NA>           X            X
##   ---                                                                            
## 4951:     1      X     5      X           X            X           X            X
## 4952:     1      Y     1      Y           Y            Y           Y            Y
## 4953:     1      X     5      X           X            X           X            X
## 4954:     1      Y     3      Y           Y            Y           Y            Y
## 4955:     1      Y     1      Y           Y            Y           Y            Y
## 4956:     1      Y     3      Y           Y            Y           Y            Y
## 4957:     1      Y     4      Y           Y            Y           Y            Y
## 4958:     1      Y     3      Y           Y            Y           Y            Y
## 4959:     1      E     3   <NA>           X            X           Y            Y
## 4960:     1      X     5      X           X            X           X            X
## 4961:     1      E     4   <NA>           X            X           Y            Y
## 4962:     1      Y     2      Y           Y            Y           Y            Y
## 4963:     1      X     4      X           X            X           X            X
## 4964:     1      X     5      X           X            X           X            X
## 4965:     1      Y     4      Y           Y            Y           Y            Y
## 4966:     1      E     4   <NA>           X            X           Y            Y
## 4967:     1      X     1      X           X            X           X            X
## 4968:     1      X     3      X           X            X           X            X
## 4969:     1      E     4   <NA>           X            X           Y            Y
## 4970:     1      Y     1      Y           Y            Y           Y            Y
## 4971:     1      X     1      X           X            X           X            X
## 4972:     1      E     4   <NA>           X            X           Y            Y
## 4973:     1      E     3   <NA>           X            X           Y            Y
## 4974:     1      Y     1      Y           Y            Y           Y            Y
## 4975:     1      X     2      X           X            X           X            X
## 4976:     1      Y     1      Y           Y            Y           Y            Y
## 4977:     1      Y     4      Y           Y            Y           Y            Y
## 4978:     1      E     3   <NA>           X            X           Y            Y
## 4979:     1      Y     3      Y           Y            Y           Y            Y
## 4980:     1      E     4   <NA>           X            X           Y            Y
## 4981:     1      E     2   <NA>        <NA>            X        <NA>            Y
## 4982:     1      Y     4      Y           Y            Y           Y            Y
## 4983:     1      X     4      X           X            X           X            X
## 4984:     1      E     1   <NA>           X            X           Y            Y
## 4985:     1      X     2      X           X            X           X            X
## 4986:     1      Y     4      Y           Y            Y           Y            Y
## 4987:     1      Y     1      Y           Y            Y           Y            Y
## 4988:     1      Y     2      Y           Y            Y           Y            Y
## 4989:     1      Y     3      Y           Y            Y           Y            Y
## 4990:     1      E     2   <NA>           X            X           Y            Y
## 4991:     1      X     1      X           X            X           X            X
## 4992:     1      X     1      X           X            X           X            X
## 4993:     1      X     3      X           X            X           X            X
## 4994:     1      E     5   <NA>           X            X           Y            Y
## 4995:     1      E     3   <NA>           X            X           Y            Y
## 4996:     1      Y     5      Y           Y            Y           Y            Y
## 4997:     1      Y     5      Y           Y            Y           Y            Y
## 4998:     1      E     4   <NA>           X            X           Y            Y
## 4999:     1      X     2      X           X            X           X            X
## 5000:     1      X     1      X           X            X           X            X
```

``` r
out.sort <- out.unsort[orig.ord]
```

The table above is a CSV data file that we can save alongside the original CSV data file.


``` r
fwrite(out.sort, tf <- tempfile())
system(paste("head", tf))
```

The output above shows the first few lines of the CSV file that describes the cross-validation experiment we have created.

## Verification

Now we verify that the counts are reasonable.


``` r
check.dt.list <- list()
for(sub.col.i in 2:ncol(out.sort)){
  sub.col.name <- names(out.sort)[sub.col.i]
  two.cols <- out.sort[, c(1, sub.col.i), with=FALSE]
  setnames(two.cols, c("fold", "subset"))
  count.dt <- data.table(dummy.dt, two.cols)[, .(
    rows=.N
  ), keyby=.(y, fold, subset)]
  stats.dt <- dcast(
    count.dt,
    subset + y ~ .,
    list(sum, var, length),
    value.var="rows")
  check.dt.list[[sub.col.name]] <- data.table(sub.col.name, stats.dt)
}
(check.dt <- rbindlist(check.dt.list))
```

```
##     sub.col.name subset     y rows_sum rows_var rows_length
##           <char> <char> <int>    <int>    <num>       <int>
##  1:        Xb_Yb   <NA>     1     1000        0           5
##  2:        Xb_Yb      X     0     1000        0           5
##  3:        Xb_Yb      X     1     1000        0           5
##  4:        Xb_Yb      Y     0     1000        0           5
##  5:        Xb_Yb      Y     1     1000        0           5
##  6:  Xineg0.1_Yb   <NA>     0      800        0           5
##  7:  Xineg0.1_Yb   <NA>     1      200        0           5
##  8:  Xineg0.1_Yb      X     0      200        0           5
##  9:  Xineg0.1_Yb      X     1     1800        0           5
## 10:  Xineg0.1_Yb      Y     0     1000        0           5
## 11:  Xineg0.1_Yb      Y     1     1000        0           5
## 12: Xineg0.01_Yb   <NA>     0      980        0           5
## 13: Xineg0.01_Yb   <NA>     1       20        0           5
## 14: Xineg0.01_Yb      X     0       20        0           5
## 15: Xineg0.01_Yb      X     1     1980        0           5
## 16: Xineg0.01_Yb      Y     0     1000        0           5
## 17: Xineg0.01_Yb      Y     1     1000        0           5
## 18:  Xb_Yineg0.1   <NA>     0      800        0           5
## 19:  Xb_Yineg0.1   <NA>     1      200        0           5
## 20:  Xb_Yineg0.1      X     0     1000        0           5
## 21:  Xb_Yineg0.1      X     1     1000        0           5
## 22:  Xb_Yineg0.1      Y     0      200        0           5
## 23:  Xb_Yineg0.1      Y     1     1800        0           5
## 24: Xb_Yineg0.01   <NA>     0      980        0           5
## 25: Xb_Yineg0.01   <NA>     1       20        0           5
## 26: Xb_Yineg0.01      X     0     1000        0           5
## 27: Xb_Yineg0.01      X     1     1000        0           5
## 28: Xb_Yineg0.01      Y     0       20        0           5
## 29: Xb_Yineg0.01      Y     1     1980        0           5
##     sub.col.name subset     y rows_sum rows_var rows_length
```

The table above has one row per combination of CSV column, subset, and label. We see that the results are reasonable.

* subset is either X or Y.
* number of rows per subset is always 2000.
* no variance between number of rows across folds, which means fold assignment respects stratification and subsets.

## Conclusions

We have shown how to split a binary classification data set into two subsets.

* Either the two subsets are both balanced (baseline),
* or one or the other subset is imbalanced to given proportions.
* each subset always has the same sample size, 
* and more imbalanced subsets are hierarchical: minor class samples are removed, major class samples are added (so there is a certain kind of continuity between imbalance proportions).

This code will be useful for creating imbalanced classification benchmarks, for comparing various machine learning algorithms.

## Session info


``` r
sessionInfo()
```

```
## R Under development (unstable) (2025-02-06 r87694)
## Platform: x86_64-pc-linux-gnu
## Running under: Ubuntu 22.04.5 LTS
## 
## Matrix products: default
## BLAS:   /usr/lib/x86_64-linux-gnu/blas/libblas.so.3.10.0 
## LAPACK: /usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.10.0  LAPACK version 3.10.0
## 
## locale:
##  [1] LC_CTYPE=fr_FR.UTF-8       LC_NUMERIC=C               LC_TIME=fr_FR.UTF-8        LC_COLLATE=fr_FR.UTF-8    
##  [5] LC_MONETARY=fr_FR.UTF-8    LC_MESSAGES=fr_FR.UTF-8    LC_PAPER=fr_FR.UTF-8       LC_NAME=C                 
##  [9] LC_ADDRESS=C               LC_TELEPHONE=C             LC_MEASUREMENT=fr_FR.UTF-8 LC_IDENTIFICATION=C       
## 
## time zone: America/Toronto
## tzcode source: system (glibc)
## 
## attached base packages:
## [1] stats     graphics  utils     datasets  grDevices methods   base     
## 
## other attached packages:
## [1] data.table_1.17.0
## 
## loaded via a namespace (and not attached):
## [1] compiler_4.5.0 tools_4.5.0    knitr_1.49     xfun_0.50      evaluate_1.0.3
```
