---
layout: post
title: Creating imbalanced data benchmarks
description: Tutorial with MNIST
---



The goal of this post is to show how to create unbalanced classification data
sets for use with our recently proposed [SOAK
algorithm](https://arxiv.org/abs/2410.08643), which will be able to
tell us if we can train on imbalanced data, and get accurate
predictions on balanced data (and vice versa).

## Read and order MNIST data

We begin by reading the MNIST data,


``` r
library(data.table)
MNIST_dt <- fread("~/projects/cv-same-other-paper/data_Classif/MNIST.csv")
data.table(
  name=names(MNIST_dt),
  first_row=unlist(MNIST_dt[1]),
  last_row=unlist(MNIST_dt[.N]))
```

```
##                name first_row last_row
##              <char>    <char>   <char>
##   1: predefined.set     train     test
##   2:              y         5        6
##   3:              0         0        0
##   4:              1         0        0
##   5:              2         0        0
##  ---                                  
## 782:            779         0        0
## 783:            780         0        0
## 784:            781         0        0
## 785:            782         0        0
## 786:            783         0        0
```

We see that these MNIST data have a `predefined.set` column, which we
will ignore (use all data from train and test). The class distribution
is as follows:


``` r
(multi_counts <- MNIST_dt[, .(
  count=.N,
  prop=.N/nrow(MNIST_dt)
), by=y][order(-prop)])
```

```
##         y count       prop
##     <int> <int>      <num>
##  1:     1  7877 0.11252857
##  2:     7  7293 0.10418571
##  3:     3  7141 0.10201429
##  4:     2  6990 0.09985714
##  5:     9  6958 0.09940000
##  6:     0  6903 0.09861429
##  7:     6  6876 0.09822857
##  8:     8  6825 0.09750000
##  9:     4  6824 0.09748571
## 10:     5  6313 0.09018571
```

We see in the table above that there are about an equal amount of data
for each class, from 9% to about 11%.  We would like to preserve these
proportions when we take subsamples of the data.  To do that, we first
take a random order of the data (in case the original file had some
special structure), and then we assign a new proportional ordering
based on the label value.


``` r
my.seed <- 1
set.seed(my.seed)
rand_ord <- MNIST_dt[, sample(.N)]
prop_ord <- data.table(y=MNIST_dt$y[rand_ord])[
, prop_y := seq(0,1,l=.N), by=y
][, order(prop_y)]
ord_list <- list(
  random=rand_ord,
  proportional=rand_ord[prop_ord])
ord_prop_dt_list <- list()
for(ord_name in names(ord_list)){
  ord_vec <- ord_list[[ord_name]]
  y_ord <- MNIST_dt$y[ord_vec]
  for(prop_data in c(0.01, 0.1, 1)){
    N <- nrow(MNIST_dt)*prop_data
    N_props <- data.table(y=y_ord[1:N])[, .(
      count=.N,
      prop_y=.N/N
    ), by=y][order(-prop_y)]
    ord_prop_dt_list[[paste(ord_name, prop_data)]] <- data.table(
      ord_name, prop_data, N_props)
  }
}
ord_prop_dt <- rbindlist(ord_prop_dt_list)
dcast(ord_prop_dt, ord_name + prop_data ~ y, value.var="prop_y")
```

```
## Key: <ord_name, prop_data>
##        ord_name prop_data          0         1          2          3          4          5          6         7
##          <char>     <num>      <num>     <num>      <num>      <num>      <num>      <num>      <num>     <num>
## 1: proportional      0.01 0.09857143 0.1128571 0.10000000 0.10142857 0.09714286 0.09000000 0.09857143 0.1042857
## 2: proportional      0.10 0.09857143 0.1125714 0.09985714 0.10200000 0.09742857 0.09014286 0.09828571 0.1041429
## 3: proportional      1.00 0.09861429 0.1125286 0.09985714 0.10201429 0.09748571 0.09018571 0.09822857 0.1041857
## 4:       random      0.01 0.10142857 0.1028571 0.11285714 0.08571429 0.09142857 0.12142857 0.08571429 0.1171429
## 5:       random      0.10 0.10114286 0.1117143 0.10114286 0.10285714 0.08985714 0.09685714 0.10000000 0.1040000
## 6:       random      1.00 0.09861429 0.1125286 0.09985714 0.10201429 0.09748571 0.09018571 0.09822857 0.1041857
##             8          9
##         <num>      <num>
## 1: 0.09714286 0.10000000
## 2: 0.09757143 0.09942857
## 3: 0.09750000 0.09940000
## 4: 0.11285714 0.06857143
## 5: 0.09914286 0.09328571
## 6: 0.09750000 0.09940000
```

The output above shows that the proportional ordering is much more
stable than the random ordering, which has lots of variations in each
column, between the different rows (values of prop_data).

## Converting to binary

To convert the data to a binary problem, we can create a new column
that indicates if the `y` label is odd=1 or even=0 (this will be used as
the label in supervised binary classification).


``` r
(binary_counts <- MNIST_dt[
, odd := y %% 2
][, .(
  count=.N,
  prop=.N/nrow(MNIST_dt)
), by=odd][order(-prop)])
```

```
##      odd count      prop
##    <num> <int>     <num>
## 1:     1 35582 0.5083143
## 2:     0 34418 0.4916857
```

Above we see that each of the two classes is about equally prevalent.

## Creating class imbalance

We will create different versions of MNIST, each version having two subsets:

* one which is balanced: 50% positive labels (odd=1), 50% negative labels (odd=0).
* one which is unbalanced: 50% positive labels (odd=1), and a smaller
  proportion of negative labels (from 10% to 0.1%).

To do that, we use the following code to compute the number of samples
we would need:


``` r
larger_N <- binary_counts$count[1]/2
target_prop <- c(0.5, 0.1, 0.05, 0.01, 0.005, 0.001)
(smaller_dt <- data.table(
  target_prop,
  count=as.integer(target_prop*larger_N/(1-target_prop))
)[
, prop := count/(count+larger_N)
][])
```

```
##    target_prop count         prop
##          <num> <int>        <num>
## 1:       0.500 17791 0.5000000000
## 2:       0.100  1976 0.0999645874
## 3:       0.050   936 0.0499813104
## 4:       0.010   179 0.0099610462
## 5:       0.005    89 0.0049776286
## 6:       0.001    17 0.0009546271
```

Above we see 

* `target_prop`, the desired proportion of negative labels in the unbalanced subset,
* `count`, the number of negative labels in the unbalanced subset which gives the best proportion closest to the target,
* `prop`, the proportion of negative labels in the unbalanced subset, that corresponds to the actual count.

It is clear from the table above that the empirical proportions are
consistent with the target proportions. To create the different unbalanced data
sets, we first create a table with one row for each target proportion in the unbalanced subset:


``` r
(unb_small_dt <- data.table(
  subset="unbalanced",
  binary_counts[2,.(odd)],
  smaller_dt[-1]))
```

```
##        subset   odd target_prop count         prop
##        <char> <num>       <num> <int>        <num>
## 1: unbalanced     0       0.100  1976 0.0999645874
## 2: unbalanced     0       0.050   936 0.0499813104
## 3: unbalanced     0       0.010   179 0.0099610462
## 4: unbalanced     0       0.005    89 0.0049776286
## 5: unbalanced     0       0.001    17 0.0009546271
```

The table above has one row for each unbalanced variant (from 10% to
0.1%) that we will create based on the original MNIST data. Below we
use a for loop over the rows of this table, to assign rows to each
subset of each unbalanced variant (each corresponding to a column of
`subset_mat`).


``` r
subset_mat <- matrix(
  NA, nrow(MNIST_dt), nrow(unb_small_dt),
  dimnames=list(
    NULL,
    target_prop=paste0(
      "seed",
      my.seed,
      "_prop",
      unb_small_dt$target_prop)))
emp_y_list <- list()
emp_props_list <- list()
MNIST_ord <- MNIST_dt[, .(odd, .I)][ord_list$proportional]
for(unb_i in 1:nrow(unb_small_dt)){
  unb_row <- unb_small_dt[unb_i]
  unb_count_dt <- rbind(
    data.table(subset="balanced", binary_counts[,.(odd)], smaller_dt[1]),
    data.table(subset="unbalanced", binary_counts[1,.(odd)], smaller_dt[1]),
    unb_row)
  MNIST_ord[, subset := NA_character_]
  for(o in c(1,0)){
    o_dt <- unb_count_dt[odd==o]
    sub_vals <- o_dt[, rep(subset, count)]
    o_idx <- which(MNIST_ord$odd==o)
    some_idx <- o_idx[1:length(sub_vals)]
    MNIST_ord[some_idx, subset := sub_vals]
  }
  subset_mat[MNIST_ord$I, unb_i] <- MNIST_ord$subset
  ## Check to make unbalanced is a subset of the previous larger one.
  if(unb_i>1)stopifnot(all(which(
    subset_mat[,unb_i]=="unbalanced"
  ) %in% which(
    subset_mat[,unb_i-1]=="unbalanced"
  )))
  ## Check to make sure balanced is the same as previous.
  if(unb_i>1)stopifnot(identical(
    which(subset_mat[,unb_i]=="balanced"),
    which(subset_mat[,unb_i-1]=="balanced")
  ))
  (unb_MNIST <- data.table(
    target_prop=unb_row$target_prop,
    subset=subset_mat[,unb_i],
    odd=MNIST_dt$odd,
    y=MNIST_dt$y)[, idx := .I][!is.na(subset)])
  emp_y_list[[unb_i]] <- unb_MNIST[, .(
    count=.N
  ), by=.(target_prop,subset,y)]
  emp_props_list[[unb_i]] <- unb_MNIST[, .(
    count=.N,
    first=idx[1], 
    last=idx[.N]
  ), by=.(target_prop,subset,odd)
  ][
  , prop_in_subset := count/sum(count)
  , by=subset
  ][]
}
emp_y <- rbindlist(emp_y_list)
(emp_props <- rbindlist(emp_props_list))
```

```
##     target_prop     subset   odd count first  last prop_in_subset
##           <num>     <char> <num> <int> <int> <int>          <num>
##  1:       0.100   balanced     1 17791     1 69997   0.5000000000
##  2:       0.100   balanced     0 17791     2 70000   0.5000000000
##  3:       0.100 unbalanced     1 17791     4 69999   0.9000354126
##  4:       0.100 unbalanced     0  1976    19 69990   0.0999645874
##  5:       0.050   balanced     1 17791     1 69997   0.5000000000
##  6:       0.050   balanced     0 17791     2 70000   0.5000000000
##  7:       0.050 unbalanced     1 17791     4 69999   0.9500186896
##  8:       0.050 unbalanced     0   936   198 69973   0.0499813104
##  9:       0.010   balanced     1 17791     1 69997   0.5000000000
## 10:       0.010   balanced     0 17791     2 70000   0.5000000000
## 11:       0.010 unbalanced     1 17791     4 69999   0.9900389538
## 12:       0.010 unbalanced     0   179   198 69888   0.0099610462
## 13:       0.005   balanced     1 17791     1 69997   0.5000000000
## 14:       0.005   balanced     0 17791     2 70000   0.5000000000
## 15:       0.005 unbalanced     1 17791     4 69999   0.9950223714
## 16:       0.005 unbalanced     0    89   770 69828   0.0049776286
## 17:       0.001   balanced     1 17791     1 69997   0.5000000000
## 18:       0.001   balanced     0 17791     2 70000   0.5000000000
## 19:       0.001 unbalanced     1 17791     4 69999   0.9990453729
## 20:       0.001 unbalanced     0    17  2715 66154   0.0009546271
##     target_prop     subset   odd count first  last prop_in_subset
```

The table above can be used to verify that the subset assignments are
consistent with the target label proportions. It has one row for each
unique combination of target proportion, subset, and label (odd). For
each value of target proportion, 

* each balanced subset has the same data, as can be seen by examining
  columns count, first, and last. The `prop_in_subset` column shows
  that the class labels are balanced (half of each).
* each unbalanced subset has the same first index values, but
  different last index values. The smaller
  unbalanced subsets are strict subsets of the larger unbalanced
  subsets (for example the 5% unbalanced subset is
  also a part of the 10% unbalanced subset).
  
To verify that the underlying multi-class proportion is consistent in
the down-sampled subsets, we use the code below:


``` r
dcast(emp_y, subset + target_prop ~ y, value.var="count")
```

```
## Key: <subset, target_prop>
##         subset target_prop     0     1     2     3     4     5     6     7     8     9
##         <char>       <num> <int> <int> <int> <int> <int> <int> <int> <int> <int> <int>
##  1:   balanced       0.001  3568  3939  3613  3571  3528  3156  3554  3646  3528  3479
##  2:   balanced       0.005  3568  3939  3613  3571  3528  3156  3554  3646  3528  3479
##  3:   balanced       0.010  3568  3939  3613  3571  3528  3156  3554  3646  3528  3479
##  4:   balanced       0.050  3568  3939  3613  3571  3528  3156  3554  3646  3528  3479
##  5:   balanced       0.100  3568  3939  3613  3571  3528  3156  3554  3646  3528  3479
##  6: unbalanced       0.001     3  3938     4  3570     3  3157     4  3647     3  3479
##  7: unbalanced       0.005    18  3938    18  3570    17  3157    18  3647    18  3479
##  8: unbalanced       0.010    36  3938    37  3570    35  3157    36  3647    35  3479
##  9: unbalanced       0.050   188  3938   190  3570   185  3157   187  3647   186  3479
## 10: unbalanced       0.100   397  3938   401  3570   391  3157   395  3647   392  3479
```

The table above has one row per subset, and one column per class
(there are ten original classes in MNIST, 0-9). It is clear that 

* the balanced subset always has the same number of data, for each
  value of target proportion.
* the unbalanced subset number of data depends on the class label:
  * for odd labels, there are always the same number of samples.
  * for even labels, the number of samples depends on the target
    proportion, and is uniform across classes (0 about the same number
    as 2 for example).

## Write the subset columns to a new CSV file

Finally, we create new columns for each subset.


``` r
fwrite(subset_mat, "2025-03-21-unbalanced.csv")
```

```
## conversion automatique de classe pour x : matrix vers data.table
```

``` r
system("head 2025-03-21-unbalanced.csv")
```

## Putting it all together

What if we wanted to do the same thing on several data sets?
Or for several different random seeds?
See code below.


``` r
library(data.table)
data_Classif <- "~/projects/cv-same-other-paper/data_Classif/"
for(data.name in c("EMNIST", "FashionMNIST", "MNIST")){
  data.csv <- paste0(
    data_Classif,
    data.name,
    ".csv")
  MNIST_dt <- fread(data.csv)
  seed_mat_list <- list()
  for(seed in 1:2){
    set.seed(seed)
    rand_ord <- MNIST_dt[, sample(.N)]
    prop_ord <- data.table(y=MNIST_dt$y[rand_ord])[
    , prop_y := seq(0,1,l=.N), by=y
    ][, order(prop_y)]
    ord_list <- list(
      random=rand_ord,
      proportional=rand_ord[prop_ord])
    (binary_counts <- MNIST_dt[
    , odd := y %% 2
    ][, .(
      count=.N,
      prop=.N/nrow(MNIST_dt)
    ), by=odd][order(-prop, -odd)])
    larger_N <- binary_counts$count[1]/2
    target_prop <- c(0.5, 0.1, 0.05, 0.01, 0.005, 0.001)
    (smaller_dt <- data.table(
      target_prop,
      count=as.integer(target_prop*larger_N/(1-target_prop))
    )[
    , prop := count/(count+larger_N)
    ][])
    (unb_small_dt <- data.table(
      subset="unbalanced",
      binary_counts[2,.(odd)],
      smaller_dt[-1]))
    subset_mat <- matrix(
      NA, nrow(MNIST_dt), nrow(unb_small_dt),
      dimnames=list(
        NULL,
        target_prop=paste0(
          "seed",
          seed,
          "_prop",
          unb_small_dt$target_prop)))
    emp_y_list <- list()
    emp_props_list <- list()
    MNIST_ord <- MNIST_dt[, .(odd, .I)][ord_list$proportional]
    for(unb_i in 1:nrow(unb_small_dt)){
      unb_row <- unb_small_dt[unb_i]
      unb_count_dt <- rbind(
        data.table(subset="balanced", binary_counts[,.(odd)], smaller_dt[1]),
        data.table(subset="unbalanced", binary_counts[1,.(odd)], smaller_dt[1]),
        unb_row)
      MNIST_ord[, subset := NA_character_]
      for(o in c(1,0)){
        o_dt <- unb_count_dt[odd==o]
        sub_vals <- o_dt[, rep(subset, count)]
        o_idx <- which(MNIST_ord$odd==o)
        some_idx <- o_idx[1:length(sub_vals)]
        MNIST_ord[some_idx, subset := sub_vals]
      }
      subset_mat[MNIST_ord$I, unb_i] <- MNIST_ord$subset
      ## Check to make unbalanced is a subset of the previous larger one.
      if(unb_i>1)stopifnot(all(which(
        subset_mat[,unb_i]=="unbalanced"
      ) %in% which(
        subset_mat[,unb_i-1]=="unbalanced"
      )))
      ## Check to make sure balanced is the same as previous.
      if(unb_i>1)stopifnot(identical(
        which(subset_mat[,unb_i]=="balanced"),
        which(subset_mat[,unb_i-1]=="balanced")
      ))
      (unb_MNIST <- data.table(
        target_prop=unb_row$target_prop,
        subset=subset_mat[,unb_i],
        odd=MNIST_dt$odd,
        y=MNIST_dt$y)[, idx := .I][!is.na(subset)])
      emp_y_list[[unb_i]] <- unb_MNIST[, .(
        count=.N
      ), by=.(target_prop,subset,y)]
      emp_props_list[[unb_i]] <- unb_MNIST[, .(
        count=.N,
        first=idx[1], 
        last=idx[.N]
      ), keyby=.(target_prop,subset,odd)
      ][
      , prop_in_subset := count/sum(count)
      , by=subset
      ][]
    }
    emp_y <- rbindlist(emp_y_list)
    (emp_props <- rbindlist(emp_props_list))
    seed_mat_list[[seed]] <- subset_mat
  }
  print(data.name)
  print(dcast(emp_y, subset + target_prop ~ y, value.var="count"))
  (seed_dt <- do.call(data.table, seed_mat_list))
  (out.csv <- sub("data_Classif", "data_Classif_unbalanced", data.csv))
  dir.create(dirname(out.csv), showWarnings = FALSE, recursive = FALSE)
  fwrite(seed_dt, out.csv)
}
```

```
## [1] "EMNIST"
## Key: <subset, target_prop>
##         subset target_prop     0     1     2     3     4     5     6     7     8     9
##         <char>       <num> <int> <int> <int> <int> <int> <int> <int> <int> <int> <int>
##  1:   balanced       0.001  3500  3500  3500  3500  3500  3500  3500  3500  3500  3500
##  2:   balanced       0.005  3500  3500  3500  3500  3500  3500  3500  3500  3500  3500
##  3:   balanced       0.010  3500  3500  3500  3500  3500  3500  3500  3500  3500  3500
##  4:   balanced       0.050  3500  3500  3500  3500  3500  3500  3500  3500  3500  3500
##  5:   balanced       0.100  3500  3500  3500  3500  3500  3500  3500  3500  3500  3500
##  6: unbalanced       0.001     4  3500     3  3500     3  3500     3  3500     4  3500
##  7: unbalanced       0.005    18  3500    17  3500    17  3500    17  3500    18  3500
##  8: unbalanced       0.010    36  3500    35  3500    35  3500    35  3500    35  3500
##  9: unbalanced       0.050   185  3500   184  3500   184  3500   184  3500   184  3500
## 10: unbalanced       0.100   389  3500   388  3500   389  3500   389  3500   389  3500
## [1] "FashionMNIST"
## Key: <subset, target_prop>
##         subset target_prop     0     1     2     3     4     5     6     7     8     9
##         <char>       <num> <int> <int> <int> <int> <int> <int> <int> <int> <int> <int>
##  1:   balanced       0.001  3500  3500  3500  3500  3500  3500  3500  3500  3500  3500
##  2:   balanced       0.005  3500  3500  3500  3500  3500  3500  3500  3500  3500  3500
##  3:   balanced       0.010  3500  3500  3500  3500  3500  3500  3500  3500  3500  3500
##  4:   balanced       0.050  3500  3500  3500  3500  3500  3500  3500  3500  3500  3500
##  5:   balanced       0.100  3500  3500  3500  3500  3500  3500  3500  3500  3500  3500
##  6: unbalanced       0.001     3  3500     3  3500     4  3500     4  3500     3  3500
##  7: unbalanced       0.005    17  3500    17  3500    18  3500    18  3500    17  3500
##  8: unbalanced       0.010    35  3500    35  3500    36  3500    35  3500    35  3500
##  9: unbalanced       0.050   184  3500   184  3500   185  3500   184  3500   184  3500
## 10: unbalanced       0.100   389  3500   389  3500   389  3500   389  3500   388  3500
## [1] "MNIST"
## Key: <subset, target_prop>
##         subset target_prop     0     1     2     3     4     5     6     7     8     9
##         <char>       <num> <int> <int> <int> <int> <int> <int> <int> <int> <int> <int>
##  1:   balanced       0.001  3568  3939  3613  3570  3528  3157  3554  3646  3528  3479
##  2:   balanced       0.005  3568  3939  3613  3570  3528  3157  3554  3646  3528  3479
##  3:   balanced       0.010  3568  3939  3613  3570  3528  3157  3554  3646  3528  3479
##  4:   balanced       0.050  3568  3939  3613  3570  3528  3157  3554  3646  3528  3479
##  5:   balanced       0.100  3568  3939  3613  3570  3528  3157  3554  3646  3528  3479
##  6: unbalanced       0.001     3  3938     4  3571     3  3156     4  3647     3  3479
##  7: unbalanced       0.005    18  3938    18  3571    17  3156    18  3647    18  3479
##  8: unbalanced       0.010    36  3938    37  3571    35  3156    36  3647    35  3479
##  9: unbalanced       0.050   188  3938   190  3571   185  3156   187  3647   186  3479
## 10: unbalanced       0.100   397  3938   401  3571   391  3156   395  3647   392  3479
```

``` r
system(paste("head", file.path(dirname(out.csv), "*")))
```

Note in the output above that the minority class is the same in each
data set (even=0 minority, odd=1 majority).

## Conclusions

This tutorial showed how to create unbalanced data sets. Each
unbalanced data set is represented as a new column (with the same
number of rows as the original data file), with two values: balanced
and imbalanced, that can be efficiently saved to a new CSV file
(without having to copy or modify the original data CSV). We checked
that the new data obey certain constraints:

* balanced subsets are the same for different imbalance ratios,
* imbalanced subsets are nested (smaller one is strict subset of larger one).

Each column in the resulting CSV files can be used to create a
different mlr3 Task (each with a different definition of subset), so
our recently proposed [SOAK
algorithm](https://arxiv.org/abs/2410.08643) can be used to determine
if a learning algorithm is able to generalize between data subsets
with different proportions of labels (50% minority class versus 1%,
etc).

## Session info


``` r
sessionInfo()
```

```
## R version 4.4.3 (2025-02-28)
## Platform: x86_64-pc-linux-gnu
## Running under: Ubuntu 24.04.2 LTS
## 
## Matrix products: default
## BLAS:   /usr/lib/x86_64-linux-gnu/blas/libblas.so.3.12.0 
## LAPACK: /usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.12.0
## 
## locale:
##  [1] LC_CTYPE=fr_FR.UTF-8       LC_NUMERIC=C               LC_TIME=fr_FR.UTF-8        LC_COLLATE=fr_FR.UTF-8    
##  [5] LC_MONETARY=fr_FR.UTF-8    LC_MESSAGES=fr_FR.UTF-8    LC_PAPER=fr_FR.UTF-8       LC_NAME=C                 
##  [9] LC_ADDRESS=C               LC_TELEPHONE=C             LC_MEASUREMENT=fr_FR.UTF-8 LC_IDENTIFICATION=C       
## 
## time zone: Europe/Paris
## tzcode source: system (glibc)
## 
## attached base packages:
## [1] stats     graphics  grDevices utils     datasets  methods   base     
## 
## other attached packages:
## [1] data.table_1.17.99
## 
## loaded via a namespace (and not attached):
## [1] compiler_4.4.3 tools_4.4.3    knitr_1.50     xfun_0.51      evaluate_1.0.3
```
