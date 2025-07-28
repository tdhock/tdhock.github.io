---
layout: post
title: A custom DataLoader for mlr3torch
description: Stratified sampling for imbalanced classification
---



The goal of this post is to show how to use a custom torch sampler with mlr3torch, in order to use stratified sampling, which can ensure that each batch in gradient descent has a minimum number of samples from each class.

## Motivation: imbalanced classification

We consider imbalanced classification problems, which occur frequently in many different areas.
For example, in a recent project involving predicting childhood autism, we used data from the National Survey of Children's Health (NSCH), which had about 3% autism, and 20K rows.


``` r
library(data.table)
```

```
## data.table 1.17.8 using 3 threads (see ?getDTthreads).  Latest news: r-datatable.com
```

``` r
prop.pos <- 0.03
Nrow <- 20000
(aut_sim <- data.table(autism=rep(c(1,0), c(prop.pos, 1-prop.pos)*Nrow)))
```

```
##        autism
##         <num>
##     1:      1
##     2:      1
##     3:      1
##     4:      1
##     5:      1
##    ---       
## 19996:      0
## 19997:      0
## 19998:      0
## 19999:      0
## 20000:      0
```

To learn with these data in torch, we can use stochastic gradient descent.
To do that, we need to wrap the data table in a `dataset` as below:


``` r
ds_gen <- torch::dataset(
  initialize=function(){},
  .getbatch=function(i)aut_sim[i]$autism,
  .length=function()nrow(aut_sim))
```

After that, we need to attach the `dataset` to a `dataloader` with a
certain batch size, which we define as 100 below:


``` r
ds <- ds_gen()
batch_size <- 100
dl <- torch::dataloader(ds, batch_size=batch_size, shuffle=TRUE)
```

To iterate through the `dataloader` we use a loop, and we count the
number of each class in each batch:


``` r
torch::torch_manual_seed(1)
count_dt_list <- list()
coro::loop(for (batch_tensor in dl) {
  batch_vec <- torch::as_array(batch_tensor)
  batch_id <- length(count_dt_list) + 1L
  count_dt_list[[batch_id]] <- data.table(
    batch_id,
    num_0=sum(batch_vec==0),
    num_1=sum(batch_vec==1))
})
(count_dt <- rbindlist(count_dt_list))
```

```
##      batch_id num_0 num_1
##         <int> <int> <int>
##   1:        1   100     0
##   2:        2    96     4
##   3:        3    96     4
##   4:        4    97     3
##   5:        5    98     2
##  ---                     
## 196:      196    98     2
## 197:      197    96     4
## 198:      198    98     2
## 199:      199    96     4
## 200:      200    96     4
```

``` r
count_dt[num_1==0]
```

```
##     batch_id num_0 num_1
##        <int> <int> <int>
##  1:        1   100     0
##  2:        6   100     0
##  3:        9   100     0
##  4:       23   100     0
##  5:       44   100     0
##  6:       67   100     0
##  7:       70   100     0
##  8:       77   100     0
##  9:       93   100     0
## 10:       98   100     0
## 11:      107   100     0
```

We can see above that there are 200 batches that have no positive labels.
On average there should be 3 positive labels per batch, and in fact that is true:


``` r
quantile(count_dt$num_1)
```

```
##   0%  25%  50%  75% 100% 
##    0    2    3    4    9
```

Above we see that the 50% quantile (median) of the number of positive labels per batch is equal to 3, as expected.

With typical loss functions, such as the cross-entropy (logistic) loss, you can still do gradient descent learning with a batch of all negative examples.
However that is not the case with complex loss functions like Area Under the Minimum (AUM) of False Positives and False Negatives, which we recently proposed for ROC curve optimization, in [Journal of Machine Learning Research 2023](https://jmlr.org/papers/v24/21-0751.html).
Computing the AUM requires computing a ROC curve, which is not possible without at least one positive and one negative example.
So in gradient descent learning with a batch of all negative examples, we can not compute the AUM, and we must skip it (waste of time).
It would be better if we could use stratified sampling, to control the number of minority class samples per batch.

## Stratified sampling

One way to implement stratified sampling is via the code below.
First we define a minimum number of samples per stratum:


``` r
(min_samples_per_stratum <- prop.pos*batch_size)
```

```
## [1] 3
```

The output above shows that there will be at least 3 samples from each stratum in each batch.
Below we shuffle the data set, and count the number of samples in each stratum:


``` r
stratum <- "autism"
set.seed(1)
(shuffle_dt <- aut_sim[
, row.id := 1:.N
][sample(.N)][
, i.in.stratum := 1:.N, keyby=stratum
][])
```

```
## Key: <autism>
##        autism row.id i.in.stratum
##         <num>  <int>        <int>
##     1:      0  17401            1
##     2:      0   4775            2
##     3:      0  13218            3
##     4:      0  10539            4
##     5:      0   8462            5
##    ---                           
## 19996:      1    372          596
## 19997:      1    473          597
## 19998:      1    437          598
## 19999:      1    264          599
## 20000:      1    561          600
```

The output above shows two new columns:

* `row.id` is the row number in the original data table.
* `i.in.stratum` is the row number of the shuffled data, relative to the stratum (autism).

Next, we count the number of samples per stratum.


``` r
(count_dt <- shuffle_dt[, .(max.i=max(i.in.stratum)), by=stratum][order(max.i)])
```

```
##    autism max.i
##     <num> <int>
## 1:      1   600
## 2:      0 19400
```

``` r
(count_min <- count_dt$max.i[1])
```

```
## [1] 600
```

Above, we see the smallest stratum has 600 samples.
Next, we add a column `n.samp` with values between 0 and 600:


``` r
shuffle_dt[
, n.samp := i.in.stratum/max(i.in.stratum)*count_min, by=stratum
][]
```

```
## Key: <autism>
##        autism row.id i.in.stratum       n.samp
##         <num>  <int>        <int>        <num>
##     1:      0  17401            1   0.03092784
##     2:      0   4775            2   0.06185567
##     3:      0  13218            3   0.09278351
##     4:      0  10539            4   0.12371134
##     5:      0   8462            5   0.15463918
##    ---                                        
## 19996:      1    372          596 596.00000000
## 19997:      1    473          597 597.00000000
## 19998:      1    437          598 598.00000000
## 19999:      1    264          599 599.00000000
## 20000:      1    561          600 600.00000000
```

The idea is that `n.samp` can be used to control the number of samples we take from the smallest stratum.
If `n.samp <= 1`, then we take 1 sample from the smallest stratum, with a number of samples from other strata that is proportional.
In other words, we can use `n.samp` to define `batch.i`, a batch number:


``` r
shuffle_dt[
, batch.i := ceiling(n.samp/min_samples_per_stratum)
][]
```

```
## Key: <autism>
##        autism row.id i.in.stratum       n.samp batch.i
##         <num>  <int>        <int>        <num>   <num>
##     1:      0  17401            1   0.03092784       1
##     2:      0   4775            2   0.06185567       1
##     3:      0  13218            3   0.09278351       1
##     4:      0  10539            4   0.12371134       1
##     5:      0   8462            5   0.15463918       1
##    ---                                                
## 19996:      1    372          596 596.00000000     199
## 19997:      1    473          597 597.00000000     199
## 19998:      1    437          598 598.00000000     200
## 19999:      1    264          599 599.00000000     200
## 20000:      1    561          600 600.00000000     200
```

We see from the output above that `batch.i` is an integer from 1 to 200, that indicates in which batch each sample appears.
Below we see counts of each batch and class label.


``` r
dcast(shuffle_dt, batch.i ~ autism, length)
```

```
## Key: <batch.i>
##      batch.i     0     1
##        <num> <int> <int>
##   1:       1    97     3
##   2:       2    97     3
##   3:       3    97     3
##   4:       4    97     3
##   5:       5    97     3
##  ---                    
## 196:     196    97     3
## 197:     197    97     3
## 198:     198    97     3
## 199:     199    97     3
## 200:     200    97     3
```

The table above has one row per batch, and one column per class label.
We see that the class counts are constant across batches, consistent with stratified random sampling.

## Custom sampler

How to use the code above with `mlr3torch`?
We need to define a sampler class, as in the code below:


``` r
hack_sampler_class <- torch::sampler(
  "HackSampler",
  initialize = function(data_source) {
    self$data_source <- data_source
  },
  .iter_batch = function(batch_size) {
    shuffle_dt <- aut_sim[
    , row.id := 1:.N
    ][sample(.N)][
    , i.in.stratum := 1:.N, keyby=stratum
    ][]
    count_dt <- shuffle_dt[, .(max.i=max(i.in.stratum)), by=stratum][order(max.i)]
    count_min <- count_dt$max.i[1]
    shuffle_dt[
    , n.samp := i.in.stratum/max(i.in.stratum)*count_min, by=stratum
    ][
    , batch.i := ceiling(n.samp/min_samples_per_stratum)
    ][]
    batch_list <- split(shuffle_dt, shuffle_dt$batch.i)
    count <- 0
    function() {
      if (count < length(batch_list)) {
        count <<- count + 1L
        return(batch_list[[count]]$row.id)
      }
      coro::exhausted()
    }
  },
  .length = function() {
    length(self$data_source)
  }
)
```

I call the code above a "hack" because it takes the same fixed value
for `min_samples_per_stratum` as defined in a previous code block (TODO: make this a parameter).
To use the sampler class, we must first instantiate it with a data set:


``` r
hack_sampler_instance <- hack_sampler_class(ds)
```

Then we specify that instance as the sampler argument of the dataloader:


``` r
hack_dl <- torch::dataloader(ds, sampler = hack_sampler_instance)
```

Finally we can loop over batches, to verify that the stratified sampling works.


``` r
torch::torch_manual_seed(1)
count_dt_list <- list()
coro::loop(for (batch_tensor in hack_dl) {
  batch_vec <- torch::as_array(batch_tensor)
  batch_id <- length(count_dt_list) + 1L
  count_dt_list[[batch_id]] <- data.table(
    batch_id,
    num_0=sum(batch_vec==0),
    num_1=sum(batch_vec==1))
})
(count_dt <- rbindlist(count_dt_list))
```

```
##      batch_id num_0 num_1
##         <int> <int> <int>
##   1:        1    97     3
##   2:        2    97     3
##   3:        3    97     3
##   4:        4    97     3
##   5:        5    97     3
##  ---                     
## 196:      196    97     3
## 197:      197    97     3
## 198:      198    97     3
## 199:      199    97     3
## 200:      200    97     3
```

## Plugging into mlr3torch

TODO

## Conclusions

TODO

## Session info


``` r
sessionInfo()
```

```
## R version 4.5.1 (2025-06-13 ucrt)
## Platform: x86_64-w64-mingw32/x64
## Running under: Windows 11 x64 (build 22631)
## 
## Matrix products: default
##   LAPACK version 3.12.1
## 
## locale:
## [1] LC_COLLATE=English_United States.utf8  LC_CTYPE=English_United States.utf8    LC_MONETARY=English_United States.utf8
## [4] LC_NUMERIC=C                           LC_TIME=English_United States.utf8    
## 
## time zone: America/Toronto
## tzcode source: internal
## 
## attached base packages:
## [1] stats     graphics  utils     datasets  grDevices methods   base     
## 
## other attached packages:
## [1] data.table_1.17.8
## 
## loaded via a namespace (and not attached):
##  [1] coro_1.1.0     R6_2.6.1       xfun_0.52      bit_4.6.0      magrittr_2.0.3 torch_0.15.1   knitr_1.50    
##  [8] bit64_4.6.0-1  ps_1.9.1       cli_3.6.5      processx_3.8.6 callr_3.7.6    compiler_4.5.1 tools_4.5.1   
## [15] evaluate_1.0.4 Rcpp_1.1.0     rlang_1.1.6
```
