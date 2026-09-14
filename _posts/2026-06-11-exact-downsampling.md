---
layout: post
title: More precise imbalanced data generation
description: No more rounding issues
---



The purpose of this page is to continue the exploration of [Creating large imbalanced data benchmarks](https://tdhock.github.io/blog/2025/imbalance-openml/).

## Problem

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
lseq <- 10^seq(-1, -5)
(Target_prop <- sort(c(4.5*lseq, lseq)))
```

```
##  [1] 1.0e-05 4.5e-05 1.0e-04 4.5e-04 1.0e-03 4.5e-03 1.0e-02 4.5e-02 1.0e-01 4.5e-01
```

Below we repeat the calculations in the previous post:


``` r
library(data.table)
(orig_dt <- data.table(
  Target_prop,
  N_pos_neg = as.integer(Tpos/(3-2*Target_prop))
)[
, n_pos := Tpos-N_pos_neg
][
, n_neg := as.integer(Target_prop*n_pos/(1-Target_prop))
][
, n_imb := n_pos+n_neg
][, let(
  pos=n_pos+N_pos_neg,
  neg=n_neg+N_pos_neg,
  check_prop = n_neg/n_imb
)][])
```

```
##     Target_prop N_pos_neg   n_pos   n_neg   n_imb     pos     neg   check_prop
##           <num>     <int>   <int>   <int>   <int>   <int>   <int>        <num>
##  1:     1.0e-05   1943053 3886070      38 3886108 5829123 1943091 9.778421e-06
##  2:     4.5e-05   1943099 3886024     174 3886198 5829123 1943273 4.477384e-05
##  3:     1.0e-04   1943170 3885953     388 3886341 5829123 1943558 9.983684e-05
##  4:     4.5e-04   1943624 3885499    1749 3887248 5829123 1945373 4.499327e-04
##  5:     1.0e-03   1944337 3884786    3888 3888674 5829123 1948225 9.998267e-04
##  6:     4.5e-03   1948887 3880236   17539 3897775 5829123 1966426 4.499747e-03
##  7:     1.0e-02   1956081 3873042   39121 3912163 5829123 1995202 9.999839e-03
##  8:     4.5e-02   2003135 3825988  180282 4006270 5829123 2183417 4.499996e-02
##  9:     1.0e-01   2081829 3747294  416366 4163660 5829123 2498195 1.000000e-01
## 10:     4.5e-01   2775772 3053351 2498196 5551547 5829123 5273968 4.500000e-01
```

* `Target_prop` is the desired proportion of negative samples in the imbalanced subset.
* `N_pos_neg` is the number of positive and negative samples in the balanced subset.
* `n_pos` and `n_neg` are the numbers of samples in the imbalanced subset, and `n_imb` is their sum.
* `pos` and `neg` are the total numbers of samples, across both subsets. We see that `pos=Tpos` in every row, and that `neg<Tneg` is true in every row except the last.
* `check_prop` is the actual proportion of negative samples in the imbalanced subset.

The numbers above seem reasonable, but

* There are almost the same number of samples in the imbalanced and balanced subsets, but not quite (difference shown in `extra_imb` column below).
* `Target_prop=4.5e-01` (almost balanced) has `neg>Tneg=5170877` which is not possible (not enough negative samples, shown as negative value in `unused_neg` column below).


``` r
orig_dt[, .(
  Target_prop,
  prop_diff=check_prop-Target_prop,
  extra_imb=n_imb - N_pos_neg*2,
  unused_neg=Tneg-neg,
  unused_pos=Tpos-pos
)]
```

```
##     Target_prop     prop_diff extra_imb unused_neg unused_pos
##           <num>         <num>     <num>      <int>      <int>
##  1:     1.0e-05 -2.215790e-07         2    3227786          0
##  2:     4.5e-05 -2.261619e-07         0    3227604          0
##  3:     1.0e-04 -1.631612e-07         1    3227319          0
##  4:     4.5e-04 -6.729697e-08         0    3225504          0
##  5:     1.0e-03 -1.733239e-07         0    3222652          0
##  6:     4.5e-03 -2.533497e-07         1    3204451          0
##  7:     1.0e-02 -1.610362e-07         1    3175675          0
##  8:     4.5e-02 -3.744131e-08         0    2987460          0
##  9:     1.0e-01  0.000000e+00         2    2672682          0
## 10:     4.5e-01 -2.701950e-08         3    -103091          0
```

## Proposed fix

To fix the issues above, we start with the idea that for any target proportion, we want `n_neg` to be the largest integer such that the number of positive samples used is less than or equal the total number of samples: `N + n_pos <= Tpos` (and same for negative).
We use these facts

* `2*N_pos_neg = n_pos + n_neg`
* `p_neg = n_neg/(n_neg+n_pos)`
* `N_pos_neg + n_pos <= Tpos`
* `N_pos_neg + n_neg <= Tneg`

Starting with the inequality `N_pos_neg + n_neg <= Tneg`, we use the definition of `N_pos_neg` and `p_neg` to get `n_neg/(2*p_neg)*(2*p_neg+1) <= Tneg`, which we solve for `n_neg`. Same for the `Tpos` inequality.
If the variable were real numbers, it would be a linear program, and we could interpret the code below as solving by attempting to identify which constraint is active.

Actually the variables are integers, so we need to do some rounding.
The approach below first rounds `N_pos_neg` which is the number of negative and positive samples in the balanced subset, which therefore has `N_pos_neg*2` samples (always an even number).
To make sure the imbalanced subset has the same number of samples, we round the counts of the smaller class (`n_small` in the code below), and then define the counts of the larger class to be consistent.
That gives us the code below,


``` r
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
(fix_dt <- compute_target_counts(p_neg, Tpos, Tneg))
```

```
##        p_neg N_pos_neg   n_pos   n_neg     pos     neg   check_prop     prop_diff extra_imb unused_neg unused_pos
##        <num>     <int>   <int>   <int>   <int>   <int>        <num>         <num>     <int>      <int>      <int>
##  1: 0.999990   1723637      34 3447240 1723671 5170877 9.999901e-01  1.371344e-07         0          0    4105452
##  2: 0.999955   1723677     155 3447199 1723832 5170876 9.999550e-01  3.797985e-08         0          1    4105291
##  3: 0.999900   1723740     345 3447135 1724085 5170875 9.998999e-01 -7.309687e-08         0          2    4105038
##  4: 0.999550   1724142    1552 3446732 1725694 5170874 9.995499e-01 -7.893781e-08         0          3    4103429
##  5: 0.999000   1724775    3450 3446100 1728225 5170875 9.989999e-01 -1.304518e-07         0          2    4100898
##  6: 0.995500   1728812   15559 3442065 1744371 5170877 9.955001e-01  8.907851e-08         0          0    4084752
##  7: 0.990000   1735193   34704 3435682 1769897 5170875 9.900000e-01 -4.034133e-08         0          2    4059226
##  8: 0.955000   1776933  159924 3393942 1936857 5170875 9.550000e-01 -8.441511e-09         0          2    3892266
##  9: 0.900000   1846741  369348 3324134 2216089 5170875 9.000001e-01  5.414944e-08         0          2    3613034
## 10: 0.550000   2462322 2216090 2708554 4678412 5170876 5.500000e-01 -4.061207e-08         0          1    1150711
## 11: 0.450000   2721514 2993665 2449363 5715179 5170877 4.500001e-01  7.348851e-08         0          0     113944
## 12: 0.100000   2081829 3747292  416366 5829121 2498195 1.000000e-01  4.803468e-08         0    2672682          2
## 13: 0.045000   2003135 3825988  180282 5829123 2183417 4.499996e-02 -3.744131e-08         0    2987460          0
## 14: 0.010000   1956081 3873040   39122 5829121 1995203 1.000010e-02  9.713299e-08         0    3175674          2
## 15: 0.004500   1948887 3880234   17540 5829121 1966427 4.500004e-03  4.361464e-09         0    3204450          2
## 16: 0.001000   1944337 3884785    3889 5829122 1948226 1.000084e-03  8.383320e-08         0    3222651          1
## 17: 0.000450   1943624 3885499    1749 5829123 1945373 4.499327e-04 -6.729697e-08         0    3225504          0
## 18: 0.000100   1943170 3885951     389 5829121 1943559 1.000942e-04  9.417601e-08         0    3227318          2
## 19: 0.000045   1943099 3886023     175 5829122 1943274 4.503116e-05  3.115899e-08         0    3227603          1
## 20: 0.000010   1943053 3886067      39 5829120 1943092 1.003575e-05  3.575301e-08         0    3227785          3
##        p_neg N_pos_neg   n_pos   n_neg     pos     neg   check_prop     prop_diff extra_imb unused_neg unused_pos
##        <num>     <int>   <int>   <int>   <int>   <int>        <num>         <num>     <int>      <int>      <int>
```

Above we see `check_prop` is still nearly equal to `p_neg` in every row, and the issues are fixed:

* it works for negative proportions greater than 0.5, unlike the previous code.
* There are always the same number of samples in the imbalanced and balanced subsets (`extra_imb=0` in every row).
* Every row has a valid `neg <= Tneg = 5170877` (no more `neg` values that are too large to create), even for large values of the target proportion for the negative class, `p_neg >= 0.45`. This is verified above: all rows have non-negative numbers in the `unused` columns.

Below we do the computation for a simple example with 140 positive samples, and 60 negative samples, which should be easy to split into

* a balanced subset with 50 positive and 50 negative samples,
* and an imbalanced subset with 90 positive and 10 negative samples (10% imbalance).


``` r
compute_target_counts(seq(0.05, 0.15, by=0.01), 140L, 60L)
```

```
##     p_neg N_pos_neg n_pos n_neg   pos   neg check_prop    prop_diff extra_imb unused_neg unused_pos
##     <num>     <int> <int> <int> <int> <int>      <num>        <num>     <int>      <int>      <int>
##  1:  0.05        48    91     5   139    53 0.05208333  0.002083333         0          7          1
##  2:  0.06        48    90     6   138    54 0.06250000  0.002500000         0          6          2
##  3:  0.07        48    89     7   137    55 0.07291667  0.002916667         0          5          3
##  4:  0.08        49    90     8   139    57 0.08163265  0.001632653         0          3          1
##  5:  0.09        49    89     9   138    58 0.09183673  0.001836735         0          2          2
##  6:  0.10        50    90    10   140    60 0.10000000  0.000000000         0          0          0
##  7:  0.11        49    87    11   136    60 0.11224490  0.002244898         0          0          4
##  8:  0.12        48    84    12   132    60 0.12500000  0.005000000         0          0          8
##  9:  0.13        47    82    12   129    59 0.12765957 -0.002340426         0          1         11
## 10:  0.14        46    79    13   125    59 0.14130435  0.001304348         0          1         15
## 11:  0.15        46    78    14   124    60 0.15217391  0.002173913         0          0         16
```

Above we can see that this method is accurate:

* for `p_neg=0.1`, we get `N_pos_neg=50`, `n_pos=90`, and `n_neg=10`.
* for other `p_neg` values (target proportion of negative samples in imbalanced subset), we get reasonable results (small `prop_diff` values).

## Visualization

The goal of this visualization is to understand how the number of samples in each class varies, as a function of `p_neg`, the target proportion of negative samples in the imbalanced subset.


``` r
br <- c(10^seq(-5, -1), 0.5)
breaks <- unique(c(br, 1-br))
p_lo <- c(
  seq(0.01, 0.5, by=0.01),
  10^seq(-5, -1, by=0.1))
p_grid <- unique(sort(c(p_lo, 1-p_lo)))
(grid_dt <- compute_target_counts(p_grid, Tpos, Tneg))
```

```
##             p_neg N_pos_neg   n_pos   n_neg     pos     neg   check_prop     prop_diff extra_imb unused_neg unused_pos
##             <num>     <int>   <int>   <int>   <int>   <int>        <num>         <num>     <int>      <int>      <int>
##   1: 1.000000e-05   1943053 3886067      39 5829120 1943092 1.003575e-05  3.575301e-08         0    3227785          3
##   2: 1.258925e-05   1943057 3886065      49 5829122 1943106 1.260900e-05  1.974294e-08         0    3227771          1
##   3: 1.584893e-05   1943061 3886060      62 5829121 1943123 1.595421e-05  1.052764e-07         0    3227754          2
##   4: 1.995262e-05   1943066 3886054      78 5829120 1943144 2.007137e-05  1.187486e-07         0    3227733          3
##   5: 2.511886e-05   1943073 3886048      98 5829121 1943171 2.521779e-05  9.892215e-08         0    3227706          2
##  ---                                                                                                                  
## 174: 9.999749e-01   1723654      87 3447221 1723741 5170875 9.999748e-01 -1.182192e-07         0          2    4105382
## 175: 9.999800e-01   1723648      69 3447227 1723717 5170875 9.999800e-01 -6.306451e-08         0          2    4105406
## 176: 9.999842e-01   1723643      55 3447231 1723698 5170874 9.999840e-01 -1.056480e-07         0          3    4105425
## 177: 9.999874e-01   1723640      43 3447237 1723683 5170877 9.999875e-01  1.156517e-07         0          0    4105440
## 178: 9.999900e-01   1723637      34 3447240 1723671 5170877 9.999901e-01  1.371344e-07         0          0    4105452
```

The table above shows the results computed on a grid of input values.
The code above includes `p_lo` on the log and linear scale, because we want to visualize the results on both scales below.
First, the code below does the linear scale visualization.


``` r
library(ggplot2)
mygg <- function(dt, ref.vec){
  grid_long <- melt(
    dt,
    measure.vars=measure(prefix, class, pattern="^(|n_|N_)(pos|neg)$")
  )[, subset := ifelse(prefix=="", "imbalanced\n+balanced", "imbalanced")]
  n_max <- grid_long[, .SD[value==max(value)], by=.(subset, class)]
  ref.df <- data.frame(
    vjust=c(-0.5, 1.5),
    class=c("pos","neg"),
    value=ref.vec)
  ggplot()+
   theme_bw()+
   scale_linewidth_manual(values=c(
     neg=3, pos=1))+
   scale_linetype_manual(values=c(
     "solid",
     "dotted",
     "dashed"))+
   geom_line(aes(
     p_neg, value, color=class, linewidth=class, linetype=subset),
     data=grid_long)+
   geom_hline(aes(
     yintercept=value),
     data=ref.df)+
   geom_text(aes(
     0, value,
     vjust=vjust,
     label=sprintf(
       " Total %s samples = %s",
       class, format(value, big.mark=",", scientific=FALSE, trim=TRUE))),
     hjust=0,
     data=ref.df)+
    scale_fill_manual(values=c(max="black"))+
    scale_y_continuous("Number of samples (linear scale)")+
    scale_x_continuous(
      "Proportion of negative samples in imbalanced subset (linear scale)")+
   geom_point(aes(
     p_neg, value, color=class, fill=point),
     shape=21,
     data=n_max[, point := "max"])
}
(gg <- mygg(grid_dt, c(Tpos, Tneg)))
```

![plot of chunk higgs](/assets/img/2026-06-11-exact-downsampling/higgs-1.png)

Above, the linear scale visualization emphasizes the details near the largest function values.
In these data, we see that 

* for small values of the proportion of negative samples in the imbalanced subset, all positive samples are used, and some negative samples are unused.
* for large values of the proportion of negative samples in the imbalanced subset, all negative samples are used, and some positive samples are unused.

Below, we do the log scale visualization,


``` r
mylog <- function(g){
  g+
    scale_x_continuous(
      "Proportion of negative samples in imbalanced subset (logit scale)",
      transform="logit", breaks=breaks)+
    scale_y_log10("Number of samples (log scale)")
}
mylog(gg)
```

```
## Scale for x is already present.
## Adding another scale for x, which will replace the existing scale.
## Scale for y is already present.
## Adding another scale for y, which will replace the existing scale.
```

```
## Warning in scale_x_continuous("Proportion of negative samples in imbalanced subset (logit scale)", : prob-logis
## transformation introduced infinite values.
```

![plot of chunk higgs-log](/assets/img/2026-06-11-exact-downsampling/higgs-log-1.png)

Above, the log scale visualization emphasizes the details near the smallest values.
In particular, the linear trends on the log scale indicate that the number of positive/negative samples calculated is linearly related to `p_neg`, the desired proportion of negative samples in the imbalanced subset.

## Laribi2024 data

These data come from the [zenodo](https://zenodo.org/records/12954673) of Laribi, Raymond, Taseen, Poenaru, Vallières. Leveraging patients’ longitudinal data to improve the Hospital One-year Mortality Risk. Health Information Science and Systems (2024).


``` r
Laribi_dt <- fread("~/projects/stratified-group-cv/data/Laribi2024.csv")
(ltab <- table(Laribi_dt$target))
```

```
## 
##      1      2 
## 211780  36705
```

``` r
min.n <- 10
(Laribi_grid_dt <- compute_target_counts(p_grid, ltab[1], ltab[2])[min.n <= n_neg & min.n <= n_pos])
```

```
##             p_neg N_pos_neg n_pos n_neg    pos   neg   check_prop     prop_diff extra_imb unused_neg unused_pos
##             <num>     <int> <int> <int>  <int> <int>        <num>         <num>     <int>      <int>      <int>
##   1: 0.0001584893     36693 73374    12 110067 36705 0.0001635189  5.029608e-06         0          0     101713
##   2: 0.0001995262     36690 73365    15 110055 36705 0.0002044154  4.889141e-06         0          0     101725
##   3: 0.0002511886     36686 73354    18 110040 36704 0.0002453252 -5.863451e-06         0          1     101740
##   4: 0.0003162278     36681 73339    23 110020 36704 0.0003135138 -2.713958e-06         0          1     101760
##   5: 0.0003981072     36675 73321    29 109996 36704 0.0003953647 -2.742481e-06         0          1     101784
##  ---                                                                                                           
## 146: 0.9990000000     12243    24 24462  12267 36705 0.9990198481  1.984808e-05         0          0     199513
## 147: 0.9992056718     12241    19 24463  12260 36704 0.9992239196  1.824785e-05         0          1     199520
## 148: 0.9993690427     12240    15 24465  12255 36705 0.9993872549  1.821225e-05         0          0     199525
## 149: 0.9994988128     12239    12 24466  12251 36705 0.9995097639  1.095110e-05         0          0     199529
## 150: 0.9996018928     12238    10 24466  12248 36704 0.9995914365 -1.045632e-05         0          1     199532
```

``` r
(gg <- mygg(Laribi_grid_dt, as.numeric(ltab)))
```

![plot of chunk Laribi](/assets/img/2026-06-11-exact-downsampling/Laribi-1.png)

In these data we see that for any values of the proportion of negative samples in the imbalanced subset, all negative samples are used, and some positive samples are unused.


``` r
mylog(gg)
```

```
## Scale for x is already present.
## Adding another scale for x, which will replace the existing scale.
## Scale for y is already present.
## Adding another scale for y, which will replace the existing scale.
```

```
## Warning in scale_x_continuous("Proportion of negative samples in imbalanced subset (logit scale)", : prob-logis
## transformation introduced infinite values.
```

![plot of chunk Laribi-log](/assets/img/2026-06-11-exact-downsampling/Laribi-log-1.png)

Note the x axis limits in the figure above denote the extreme negative class proportions which can be supported using these data, with a max of at least 10 samples from each class in each subset.

## Conclusions

We have studied a robust method for dividing a binary classification data set into one balanced subset, and another imbalanced subset, with a variable amount of class imbalance. We showed that the proposed method guarantees the same number of samples in each subset, so this method can be used with [SOAK](https://onlinelibrary.wiley.com/doi/10.1002/sam.70055), for comparing machine learning algorithms for imbalanced binary classification. Future work includes

* application to benchmark data (Higgs, MNIST, etc).
* generalization to multiple classes.

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
