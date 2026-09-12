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
Tpos=5829123
Tneg=5170877
```

Below are the target proportions of the minority negative class:


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
##           <num>     <int>   <num>   <int>   <num>   <num>   <int>        <num>
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

* `Target_prop=4.5e-01` (almost balanced) has `neg>Tneg=5170877` which is not possible (not enough negative samples).
* the `Target_prop` (desired imbalance) is often a bit larger than `check_prop` (actual imbalance).

## Proposed fix

To fix the issues above, we start with the idea that for any target proportion, we want `n_neg` to be the largest integer such that the number of positive samples used is less than or equal the total number of samples: `N + n_pos <= Tpos` (and same for negative).
That gives us the code below, which also works for negative proportions greater than 0.5:


``` r
compute_target_counts <- function(p_neg, Tpos, Tneg){
  p_small <- ifelse(p_neg<0.5, p_neg, 1-p_neg)
  n_small = as.integer(pmin(
    2*Tpos*p_small/(3*(1-p_neg)+p_neg),
    2*Tneg*p_small/(1+2*p_neg)
  ))
  data.table(p_neg)[, let(
    n_pos = ifelse(
      p_neg<0.5,
      n_small*(1-p_neg)/p_neg,
      n_small),
    n_neg = ifelse(
      p_neg<0.5,
      n_small,
      n_small*p_neg/(1-p_neg))
  )][
  , n_imb := n_pos+n_neg
  ][
  , N_pos := n_imb/2
  ][
  , N_neg := n_imb-N_pos
  ][, let(
    pos=n_pos+N_pos,
    neg=n_neg+N_neg
  )][
  , check_prop := n_neg/n_imb
  ][]
}
p_neg <- sort(c(Target_prop, 1-Target_prop), decreasing = TRUE)
compute_target_counts(p_neg, Tpos, Tneg)
```

```
##        p_neg   n_pos   n_neg   n_imb   N_pos   N_neg     pos     neg check_prop
##        <num>   <num>   <num>   <num>   <num>   <num>   <num>   <num>      <num>
##  1: 0.999990      34 3399966 3400000 1700000 1700000 1700034 5099966   0.999990
##  2: 0.999955     155 3444289 3444444 1722222 1722222 1722377 5166512   0.999955
##  3: 0.999900     344 3439656 3440000 1720000 1720000 1720344 5159656   0.999900
##  4: 0.999550    1551 3445116 3446667 1723333 1723333 1724884 5168449   0.999550
##  5: 0.999000    3449 3445551 3449000 1724500 1724500 1727949 5170051   0.999000
##  6: 0.995500   15559 3441997 3457556 1728778 1728778 1744337 5170774   0.995500
##  7: 0.990000   34703 3435597 3470300 1735150 1735150 1769853 5170747   0.990000
##  8: 0.955000  159924 3393943 3553867 1776933 1776933 1936857 5170876   0.955000
##  9: 0.900000  369348 3324132 3693480 1846740 1846740 2216088 5170872   0.900000
## 10: 0.550000 2216090 2708554 4924644 2462322 2462322 4678412 5170877   0.550000
## 11: 0.450000 2993665 2449362 5443027 2721513 2721513 5715178 5170875   0.450000
## 12: 0.100000 3747285  416365 4163650 2081825 2081825 5829110 2498190   0.100000
## 13: 0.045000 3825985  180282 4006267 2003133 2003133 5829118 2183415   0.045000
## 14: 0.010000 3872979   39121 3912100 1956050 1956050 5829029 1995171   0.010000
## 15: 0.004500 3880017   17539 3897556 1948778 1948778 5828794 1966317   0.004500
## 16: 0.001000 3884112    3888 3888000 1944000 1944000 5828112 1947888   0.001000
## 17: 0.000450 3884918    1749 3886667 1943333 1943333 5828251 1945082   0.000450
## 18: 0.000100 3879612     388 3880000 1940000 1940000 5819612 1940388   0.000100
## 19: 0.000045 3866493     174 3866667 1933333 1933333 5799826 1933507   0.000045
## 20: 0.000010 3799962      38 3800000 1900000 1900000 5699962 1900038   0.000010
##        p_neg   n_pos   n_neg   n_imb   N_pos   N_neg     pos     neg check_prop
```

Above we see the issues are fixed:

* Every row has a valid `neg <= Tneg = 5170877` (no more `neg` values that are too large to create), even for large values of the target proportion for the negative class, `p_neg >= 0.45`.
* `check_prop` is equal to `p_neg` in every row (no more small differences).

Below we do the computation for some other target proportions:


``` r
compute_target_counts(
  sort(seq(0.25, 0.75, by=0.05), decreasing = TRUE),
  Tpos, Tneg)
```

```
##     p_neg   n_pos   n_neg   n_imb   N_pos   N_neg     pos     neg check_prop
##     <num>   <num>   <num>   <num>   <num>   <num>   <num>   <num>      <num>
##  1:  0.75 1034175 3102525 4136700 2068350 2068350 3102525 5170875       0.75
##  2:  0.70 1292719 3016344 4309063 2154532 2154532 3447251 5170876       0.70
##  3:  0.65 1573745 2922669 4496414 2248207 2248207 3821952 5170876       0.65
##  4:  0.60 1880318 2820477 4700795 2350398 2350398 4230716 5170875       0.60
##  5:  0.55 2216090 2708554 4924644 2462322 2462322 4678412 5170877       0.55
##  6:  0.50 2585438 2585438 5170876 2585438 2585438 5170876 5170876       0.50
##  7:  0.45 2993665 2449362 5443027 2721513 2721513 5715178 5170875       0.45
##  8:  0.40 3179521 2119681 5299202 2649601 2649601 5829123 4769282       0.40
##  9:  0.35 3294720 1774080 5068800 2534400 2534400 5829120 4308480       0.35
## 10:  0.30 3400320 1457280 4857600 2428800 2428800 5829120 3886080       0.30
## 11:  0.25 3497472 1165824 4663296 2331648 2331648 5829120 3497472       0.25
```

``` r
compute_target_counts(
  sort(seq(0.45, 0.55, by=0.01), decreasing = TRUE),
  Tpos, Tneg)
```

```
##     p_neg   n_pos   n_neg   n_imb   N_pos   N_neg     pos     neg check_prop
##     <num>   <num>   <num>   <num>   <num>   <num>   <num>   <num>      <num>
##  1:  0.55 2216090 2708554 4924644 2462322 2462322 4678412 5170877       0.55
##  2:  0.54 2287118 2684878 4971996 2485998 2485998 4773116 5170875       0.54
##  3:  0.53 2359526 2660742 5020268 2510134 2510134 4869660 5170876       0.53
##  4:  0.52 2433353 2636132 5069485 2534743 2534743 4968096 5170875       0.52
##  5:  0.51 2508643 2611037 5119680 2559840 2559840 5068483 5170876       0.51
##  6:  0.50 2585438 2585438 5170876 2585438 2585438 5170876 5170876       0.50
##  7:  0.49 2663784 2559322 5223106 2611553 2611553 5275337 5170875       0.49
##  8:  0.48 2743730 2532674 5276404 2638202 2638202 5381932 5170876       0.48
##  9:  0.47 2825324 2505476 5330800 2665400 2665400 5490724 5170876       0.47
## 10:  0.46 2908617 2477711 5386328 2693164 2693164 5601781 5170875       0.46
## 11:  0.45 2993665 2449362 5443027 2721513 2721513 5715178 5170875       0.45
```

``` r
compute_target_counts(
  sort(seq(0.99, 0.999, by=0.001), decreasing = TRUE),
  Tpos, Tneg)
```

```
##     p_neg n_pos   n_neg   n_imb   N_pos   N_neg     pos     neg check_prop
##     <num> <int>   <num>   <num>   <num>   <num>   <num>   <num>      <num>
##  1: 0.999  3449 3445551 3449000 1724500 1724500 1727949 5170051      0.999
##  2: 0.998  6903 3444597 3451500 1725750 1725750 1732653 5170347      0.998
##  3: 0.997 10362 3443638 3454000 1727000 1727000 1737362 5170638      0.997
##  4: 0.996 13825 3442425 3456250 1728125 1728125 1741950 5170550      0.996
##  5: 0.995 17293 3441307 3458600 1729300 1729300 1746593 5170607      0.995
##  6: 0.994 20766 3440234 3461000 1730500 1730500 1751266 5170734      0.994
##  7: 0.993 24243 3439043 3463286 1731643 1731643 1755886 5170686      0.993
##  8: 0.992 27725 3437900 3465625 1732812 1732812 1760537 5170712      0.992
##  9: 0.991 31212 3436788 3468000 1734000 1734000 1765212 5170788      0.991
## 10: 0.990 34703 3435597 3470300 1735150 1735150 1769853 5170747      0.990
```

``` r
compute_target_counts(
  sort(seq(0.001, 0.01, by=0.001), decreasing = TRUE),
  Tpos, Tneg)
```

```
##     p_neg   n_pos n_neg   n_imb   N_pos   N_neg     pos     neg check_prop
##     <num>   <num> <int>   <num>   <num>   <num>   <num>   <num>      <num>
##  1: 0.010 3872979 39121 3912100 1956050 1956050 5829029 1995171      0.010
##  2: 0.009 3874259 35185 3909444 1954722 1954722 5828982 1989907      0.009
##  3: 0.008 3875620 31255 3906875 1953438 1953438 5829058 1984692      0.008
##  4: 0.007 3876956 27330 3904286 1952143 1952143 5829099 1979473      0.007
##  5: 0.006 3878257 23410 3901667 1950833 1950833 5829090 1974243      0.006
##  6: 0.005 3879505 19495 3899000 1949500 1949500 5829005 1968995      0.005
##  7: 0.004 3880665 15585 3896250 1948125 1948125 5828790 1963710      0.004
##  8: 0.003 3881986 11681 3893667 1946833 1946833 5828819 1958514      0.003
##  9: 0.002 3883218  7782 3891000 1945500 1945500 5828718 1953282      0.002
## 10: 0.001 3884112  3888 3888000 1944000 1944000 5828112 1947888      0.001
```

Above we can see that this method is accurate even for 

## Visualization


``` r
br <- c(10^seq(-5, -1), 0.5)
breaks=unique(c(br, 1-br))
p_lo <- c(
  seq(0.01, 0.5, by=0.01),
  10^seq(-5, -1, by=0.1))
p_grid <- unique(sort(c(p_lo, 1-p_lo)))
(grid_dt <- compute_target_counts(p_grid, Tpos, Tneg))
```

```
##             p_neg   n_pos   n_neg   n_imb   N_pos   N_neg     pos     neg   check_prop
##             <num>   <num>   <num>   <num>   <num>   <num>   <num>   <num>        <num>
##   1: 1.000000e-05 3799962      38 3800000 1900000 1900000 5699962 1900038 1.000000e-05
##   2: 1.258925e-05 3812728      48 3812776 1906388 1906388 5719115 1906436 1.258925e-05
##   3: 1.584893e-05 3848779      61 3848840 1924420 1924420 5773199 1924481 1.584893e-05
##   4: 1.995262e-05 3859065      77 3859142 1929571 1929571 5788636 1929648 1.995262e-05
##   5: 2.511886e-05 3861543      97 3861640 1930820 1930820 5792362 1930917 2.511886e-05
##  ---                                                                                  
## 174: 9.999749e-01      86 3423636 3423722 1711861 1711861 1711947 5135497 9.999749e-01
## 175: 9.999800e-01      68 3408005 3408073 1704037 1704037 1704105 5112042 9.999800e-01
## 176: 9.999842e-01      54 3407116 3407170 1703585 1703585 1703639 5110700 9.999842e-01
## 177: 9.999874e-01      43 3415568 3415611 1707806 1707806 1707849 5123374 9.999874e-01
## 178: 9.999900e-01      34 3399966 3400000 1700000 1700000 1700034 5099966 9.999900e-01
```

``` r
grid_dt[, diff := p_neg-check_prop][order(abs(diff))]
```

```
##             p_neg   n_pos   n_neg   n_imb   N_pos   N_neg     pos     neg   check_prop          diff
##             <num>   <num>   <num>   <num>   <num>   <num>   <num>   <num>        <num>         <num>
##   1: 1.000000e-05 3799962      38 3800000 1900000 1900000 5699962 1900038 1.000000e-05  0.000000e+00
##   2: 1.584893e-05 3848779      61 3848840 1924420 1924420 5773199 1924481 1.584893e-05  0.000000e+00
##   3: 1.995262e-05 3859065      77 3859142 1929571 1929571 5788636 1929648 1.995262e-05  0.000000e+00
##   4: 2.511886e-05 3861543      97 3861640 1930820 1930820 5792362 1930917 2.511886e-05  0.000000e+00
##   5: 3.981072e-05 3868151     154 3868305 1934153 1934153 5802304 1934307 3.981072e-05  0.000000e+00
##  ---                                                                                                
## 174: 6.400000e-01 1632908 2902948 4535856 2267928 2267928 3900836 5170875 6.400000e-01 -1.110223e-16
## 175: 6.700000e-01 1458452 2961100 4419552 2209776 2209776 3668228 5170875 6.700000e-01 -1.110223e-16
## 176: 6.900000e-01 1347035 2998239 4345274 2172637 2172637 3519672 5170876 6.900000e-01  1.110223e-16
## 177: 7.000000e-01 1292719 3016344 4309063 2154532 2154532 3447251 5170876 7.000000e-01 -1.110223e-16
## 178: 7.100000e-01 1239301 3034151 4273452 2136726 2136726 3376027 5170877 7.100000e-01 -1.110223e-16
```

``` r
library(ggplot2)
(grid_long <- melt(grid_dt, measure.vars=measure(prefix, class, pattern="^(|n_|N_)(pos|neg)$")))
```

```
##              p_neg   n_imb   check_prop          diff prefix  class   value
##              <num>   <num>        <num>         <num> <char> <char>   <num>
##    1: 1.000000e-05 3800000 1.000000e-05  0.000000e+00     n_    pos 3799962
##    2: 1.258925e-05 3812776 1.258925e-05 -1.694066e-21     n_    pos 3812728
##    3: 1.584893e-05 3848840 1.584893e-05  0.000000e+00     n_    pos 3848779
##    4: 1.995262e-05 3859142 1.995262e-05  0.000000e+00     n_    pos 3859065
##    5: 2.511886e-05 3861640 2.511886e-05  0.000000e+00     n_    pos 3861543
##   ---                                                                      
## 1064: 9.999749e-01 3423722 9.999749e-01  0.000000e+00           neg 5135497
## 1065: 9.999800e-01 3408073 9.999800e-01  0.000000e+00           neg 5112042
## 1066: 9.999842e-01 3407170 9.999842e-01  0.000000e+00           neg 5110700
## 1067: 9.999874e-01 3415611 9.999874e-01  0.000000e+00           neg 5123374
## 1068: 9.999900e-01 3400000 9.999900e-01  0.000000e+00           neg 5099966
```

``` r
n_max <- grid_long[, .SD[value==max(value)], by=.(prefix, class)]

(gg <- ggplot()+
   ggtitle("total counts")+
   theme_bw()+
   scale_size_manual(values=c(
     neg=3, pos=1))+
   scale_linetype_manual(values=c(
     "solid",
     "dotted",
     "dashed"))+
   geom_line(aes(
     p_neg, value, color=class, size=class, linetype=prefix),
     data=grid_long)+
   geom_hline(aes(
     yintercept=value),
     data=data.frame(value=c(Tpos, Tneg)))+
   scale_fill_manual(values=c(max="black"))+
   geom_point(aes(
     p_neg, value, color=class, fill=point),
     shape=21,
     data=n_max[, point := "max"]))
```

```
## Warning: Using `size` aesthetic for lines was deprecated in ggplot2 3.4.0.
## ℹ Please use `linewidth` instead.
## This warning is displayed once every 8 hours.
## Call `lifecycle::last_lifecycle_warnings()` to see where this warning was
## generated.
```

![plot of chunk higgs](/assets/img/2026-06-11-exact-downsampling/higgs-1.png)


``` r
gg+
  scale_x_continuous(transform="logit", breaks=breaks)+
  scale_y_log10()
```

![plot of chunk higgs-log](/assets/img/2026-06-11-exact-downsampling/higgs-log-1.png)

## other data


``` r
Laribi_dt <- fread("~/projects/stratified-group-cv/data/Laribi2024.csv")
```


``` r
ltab <- table(Laribi_dt$target)
(Laribi_grid_dt <- compute_target_counts(p_grid, ltab[1], ltab[2])[is.finite(check_prop)])
```

```
##             p_neg    n_pos    n_neg    n_imb     N_pos     N_neg       pos      neg   check_prop
##             <num>    <num>    <num>    <num>     <num>     <num>     <num>    <num>        <num>
##   1: 1.584893e-05 63094.73     1.00 63095.73 31547.867 31547.867 94642.602 31548.87 1.584893e-05
##   2: 1.995262e-05 50117.72     1.00 50118.72 25059.362 25059.362 75177.085 25060.36 1.995262e-05
##   3: 2.511886e-05 39809.72     1.00 39810.72 19905.359 19905.359 59715.076 19906.36 2.511886e-05
##   4: 3.162278e-05 63243.55     2.00 63245.55 31622.777 31622.777 94866.330 31624.78 3.162278e-05
##   5: 3.981072e-05 50235.73     2.00 50237.73 25118.864 25118.864 75354.593 25120.86 3.981072e-05
##  ---                                                                                            
## 165: 9.998741e-01     3.00 23826.85 23829.85 11914.924 11914.924 11917.924 35741.77 9.998741e-01
## 166: 9.999000e-01     2.00 19998.00 20000.00 10000.000 10000.000 10002.000 29998.00 9.999000e-01
## 167: 9.999206e-01     1.00 12588.25 12589.25  6294.627  6294.627  6295.627 18882.88 9.999206e-01
## 168: 9.999369e-01     1.00 15847.93 15848.93  7924.466  7924.466  7925.466 23772.40 9.999369e-01
## 169: 9.999499e-01     1.00 19951.62 19952.62  9976.312  9976.312  9977.312 29927.93 9.999499e-01
```

``` r
Laribi_grid_dt[, diff := p_neg-check_prop][order(abs(diff))]
```

```
##             p_neg    n_pos    n_neg    n_imb    N_pos    N_neg      pos      neg   check_prop          diff
##             <num>    <num>    <num>    <num>    <num>    <num>    <num>    <num>        <num>         <num>
##   1: 1.584893e-05 63094.73     1.00 63095.73 31547.87 31547.87 94642.60 31548.87 1.584893e-05  0.000000e+00
##   2: 1.995262e-05 50117.72     1.00 50118.72 25059.36 25059.36 75177.09 25060.36 1.995262e-05  0.000000e+00
##   3: 2.511886e-05 39809.72     1.00 39810.72 19905.36 19905.36 59715.08 19906.36 2.511886e-05  0.000000e+00
##   4: 3.162278e-05 63243.55     2.00 63245.55 31622.78 31622.78 94866.33 31624.78 3.162278e-05  0.000000e+00
##   5: 3.981072e-05 50235.73     2.00 50237.73 25118.86 25118.86 75354.59 25120.86 3.981072e-05  0.000000e+00
##  ---                                                                                                       
## 165: 3.700000e-01 26579.19 15610.00 42189.19 21094.59 21094.59 47673.78 36704.59 3.700000e-01 -5.551115e-17
## 166: 4.400000e-01 21866.73 17181.00 39047.73 19523.86 19523.86 41390.59 36704.86 4.400000e-01  5.551115e-17
## 167: 4.600000e-01 20645.61 17587.00 38232.61 19116.30 19116.30 39761.91 36703.30 4.600000e-01  5.551115e-17
## 168: 4.500000e-01 21249.56 17386.00 38635.56 19317.78 19317.78 40567.33 36703.78 4.500000e-01  1.110223e-16
## 169: 5.500000e-01 15730.00 19225.56 34955.56 17477.78 17477.78 33207.78 36703.33 5.500000e-01  1.110223e-16
```

``` r
(grid_long <- melt(Laribi_grid_dt, measure.vars=measure(prefix, class, pattern="^(|n_|N_)(pos|neg)$")))
```

```
##              p_neg    n_imb   check_prop  diff prefix  class    value
##              <num>    <num>        <num> <num> <char> <char>    <num>
##    1: 1.584893e-05 63095.73 1.584893e-05     0     n_    pos 63094.73
##    2: 1.995262e-05 50118.72 1.995262e-05     0     n_    pos 50117.72
##    3: 2.511886e-05 39810.72 2.511886e-05     0     n_    pos 39809.72
##    4: 3.162278e-05 63245.55 3.162278e-05     0     n_    pos 63243.55
##    5: 3.981072e-05 50237.73 3.981072e-05     0     n_    pos 50235.73
##   ---                                                                
## 1010: 9.998741e-01 23829.85 9.998741e-01     0           neg 35741.77
## 1011: 9.999000e-01 20000.00 9.999000e-01     0           neg 29998.00
## 1012: 9.999206e-01 12589.25 9.999206e-01     0           neg 18882.88
## 1013: 9.999369e-01 15848.93 9.999369e-01     0           neg 23772.40
## 1014: 9.999499e-01 19952.62 9.999499e-01     0           neg 29927.93
```

``` r
n_max <- grid_long[, .SD[value==max(value)], by=.(prefix, class)]

(gg <- ggplot()+
   ggtitle("total counts")+
   theme_bw()+
   scale_size_manual(values=c(
     neg=3, pos=1))+
   scale_linetype_manual(values=c(
     "solid",
     "dotted",
     "dashed"))+
   geom_line(aes(
     p_neg, value, color=class, size=class, linetype=prefix),
     data=grid_long)+
   scale_fill_manual(values=c(max="black"))+
   geom_point(aes(
     p_neg, value, color=class, fill=point),
     shape=21,
     data=n_max[, point := "max"]))
```

![plot of chunk Laribi](/assets/img/2026-06-11-exact-downsampling/Laribi-1.png)


``` r
gg+
  scale_x_continuous(transform="logit", breaks=breaks)+
  scale_y_log10()
```

![plot of chunk Laribi-log](/assets/img/2026-06-11-exact-downsampling/Laribi-log-1.png)

## session info


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
## [1] ggplot2_3.5.1     data.table_1.17.0
## 
## loaded via a namespace (and not attached):
##  [1] labeling_0.4.3   R6_2.5.1         tidyselect_1.2.1 xfun_0.50        farver_2.1.2     magrittr_2.0.3  
##  [7] gtable_0.3.6     glue_1.8.0       tibble_3.2.1     knitr_1.49       pkgconfig_2.0.3  generics_0.1.3  
## [13] dplyr_1.1.4      lifecycle_1.0.4  cli_3.6.3        scales_1.3.0     grid_4.5.0       vctrs_0.6.5     
## [19] withr_3.0.2      compiler_4.5.0   tools_4.5.0      pillar_1.10.1    evaluate_1.0.3   munsell_0.5.1   
## [25] colorspace_2.1-1 crayon_1.5.3     rlang_1.1.5
```
