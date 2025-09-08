---
layout: post
title: A custom DataLoader for mlr3torch
description: Stratified sampling for imbalanced classification
---



The goal of this post is to show how to use a custom torch sampler with mlr3torch, in order to use stratified sampling, which can ensure that each batch in gradient descent has a minimum number of samples from each class.

## Motivation: imbalanced classification

We consider imbalanced classification problems, which occur frequently in many different areas.
For example, in a recent project involving predicting childhood autism, we used data from the National Survey of Children's Health (NSCH), which had about 3% autism, and 20K rows (plus 50 to show how to handle a small batch at the end).


``` r
library(data.table)
prop.pos <- 0.03
Nrow <- 20050
(aut_sim <- data.table(autism=rep(c(1,0), round(c(prop.pos, 1-prop.pos)*Nrow))))
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
## 20046:      0
## 20047:      0
## 20048:      0
## 20049:      0
## 20050:      0
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
##   1:        1    98     2
##   2:        2    97     3
##   3:        3    97     3
##   4:        4    97     3
##   5:        5    96     4
##  ---                     
## 197:      197    95     5
## 198:      198    99     1
## 199:      199    99     1
## 200:      200    99     1
## 201:      201    49     1
```

``` r
(batches_without_positive_labels <- count_dt[num_1==0])
```

```
##    batch_id num_0 num_1
##       <int> <int> <int>
## 1:       25   100     0
## 2:       26   100     0
## 3:       47   100     0
## 4:       55   100     0
## 5:       57   100     0
## 6:       59   100     0
## 7:      105   100     0
## 8:      110   100     0
## 9:      161   100     0
```

We can see above that there are 9 batches that have no positive labels.
On average there should be 3 positive labels per batch, and in fact that is true:


``` r
quantile(count_dt$num_1)
```

```
##   0%  25%  50%  75% 100% 
##    0    2    3    4    8
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
## 20046:      1    425          598
## 20047:      1    589          599
## 20048:      1    437          600
## 20049:      1    225          601
## 20050:      1     33          602
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
## 1:      1   602
## 2:      0 19448
```

``` r
(count_min <- count_dt$max.i[1])
```

```
## [1] 602
```

``` r
(num_batches <- count_min %/% min_samples_per_stratum)
```

```
## [1] 200
```

``` r
(max_samp <- num_batches * min_samples_per_stratum)
```

```
## [1] 600
```

Above, we see the smallest stratum has 602 samples.
The number of batches is `num_batches` which uses integer division so that we never have fewer than `min_samples_per_stratum` in any batch.
Next, we add a column `n.samp` with values between 0 and `max_samp`:


``` r
shuffle_dt[
, n.samp := i.in.stratum/max(i.in.stratum)*max_samp, by=stratum
][]
```

```
## Key: <autism>
##        autism row.id i.in.stratum      n.samp
##         <num>  <int>        <int>       <num>
##     1:      0  17401            1   0.0308515
##     2:      0   4775            2   0.0617030
##     3:      0  13218            3   0.0925545
##     4:      0  10539            4   0.1234060
##     5:      0   8462            5   0.1542575
##    ---                                       
## 20046:      1    425          598 596.0132890
## 20047:      1    589          599 597.0099668
## 20048:      1    437          600 598.0066445
## 20049:      1    225          601 599.0033223
## 20050:      1     33          602 600.0000000
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
##        autism row.id i.in.stratum      n.samp batch.i
##         <num>  <int>        <int>       <num>   <num>
##     1:      0  17401            1   0.0308515       1
##     2:      0   4775            2   0.0617030       1
##     3:      0  13218            3   0.0925545       1
##     4:      0  10539            4   0.1234060       1
##     5:      0   8462            5   0.1542575       1
##    ---                                               
## 20046:      1    425          598 596.0132890     199
## 20047:      1    589          599 597.0099668     200
## 20048:      1    437          600 598.0066445     200
## 20049:      1    225          601 599.0033223     200
## 20050:      1     33          602 600.0000000     200
```

We see from the output above that `batch.i` is an integer from 1 to 200, that indicates in which batch each sample appears.
Below we see counts of each batch and class label.


``` r
(class_counts <- dcast(shuffle_dt, batch.i ~ autism, length))
```

```
## Key: <batch.i>
##      batch.i     0     1
##        <num> <int> <int>
##   1:       1    97     3
##   2:       2    97     3
##   3:       3    97     3
##   4:       4    97     3
##   5:       5    98     3
##  ---                    
## 196:     196    98     3
## 197:     197    97     3
## 198:     198    97     3
## 199:     199    97     3
## 200:     200    98     4
```

The table above has one row per batch, and one column per class label.
We see that the class counts are mostly constant across batches, consistent with stratified random sampling.


``` r
class_counts[`1` < min_samples_per_stratum]
```

```
## Key: <batch.i>
## Empty data.table (0 rows and 3 cols): batch.i,0,1
```

The output above shows that there are now batches with fewer positive examples than the specified minimum.

## Custom sampler

How to use the code above with `torch`?
We need to define a sampler class, as in the code below:


``` r
hack_sampler_class <- torch::sampler(
  "HackSampler",
  initialize = function(data_source) {
    shuffle_dt <- data.table(
      row.id = 1:length(data_source)
    )[
    , autism := data_source$.getbatch(row.id)
    ][sample(.N)][
    , i.in.stratum := 1:.N, keyby=stratum
    ][]
    count_dt <- shuffle_dt[, .(max.i=max(i.in.stratum)), by=stratum][order(max.i)]
    count_min <- count_dt$max.i[1]
    num_batches <- count_min %/% min_samples_per_stratum
    max_samp <- num_batches * min_samples_per_stratum
    shuffle_dt[
    , n.samp := i.in.stratum/max(i.in.stratum)*max_samp, by=stratum
    ][
    , batch.i := ceiling(n.samp/min_samples_per_stratum)
    ][]
    self$batch_list <- split(shuffle_dt, shuffle_dt$batch.i)
  },
  .iter = function() {
    count <- 0
    function() {
      if (count < length(self$batch_list)) {
        count <<- count + 1L
        return(self$batch_list[[count]]$row.id)
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
hack_dl <- torch::dataloader(ds, batch_sampler = hack_sampler_instance)
```

Finally we can loop over batches, to verify that the stratified sampling works.


``` r
torch::torch_manual_seed(1)
count_dt_list <- list()
coro::loop(for (batch_tensor in hack_dl) {
  batch_id <- length(count_dt_list) + 1L
  batch_dt <- data.table(
    batch_id,
    class=torch::as_array(batch_tensor))
  count_dt_list[[batch_id]] <- dcast(batch_dt, batch_id ~ class, length)
})
(count_dt <- rbindlist(count_dt_list))
```

```
##      batch_id     0     1
##         <int> <int> <int>
##   1:        1    97     3
##   2:        2    97     3
##   3:        3    97     3
##   4:        4    97     3
##   5:        5    98     3
##  ---                     
## 196:      196    98     3
## 197:      197    97     3
## 198:      198    97     3
## 199:      199    97     3
## 200:      200    98     4
```

## Plugging into mlr3torch

First, note that this work resulted in a [doc improvement to torch](https://github.com/mlverse/torch/pull/1363) and several modifications to mlr3torch:

* learner `batch_sampler` and `sampler` params are now set to the class (not instance), [PR](https://github.com/mlr-org/mlr3torch/pull/419). The sampler is instanteiated at the same time as the learner.
* informative error added when the sampler `.length` is not consistent with the number of times `.iter` can be called before returning `coro::exhausted()`, [PR](https://github.com/mlr-org/mlr3torch/pull/433).
* in the code below we either need to specify `batch_size` (even though it is un-ncessary), or use the fix in this other [PR](https://github.com/mlr-org/mlr3torch/pull/425), which removes the error for no `batch_size` when `batch_sampler` is specified.

We can then create a simple linear model torch learner in the `mlr3torch` system, and apply it to the sonar data set, using the stratified sampling strategy.
First we create a sonar task with `stratum`, which will be used for stratification in our custom sampler.


``` r
sonar_task <- mlr3::tsk("sonar")
sonar_task$col_roles$stratum <- "Class"
```

Then we create a new MLP learner, which by default is a linear model.


``` r
mlp_learner <- mlr3torch::LearnerTorchMLP$new(task_type="classif")
mlp_learner$predict_type <- "prob"
```

Then we set several learner parameters in the code below.
Also note in the `stratified_sampler_class` that

* `initialize` derives the stratification from the `stratum` role defined in the task.
* `set_batch_list` sets `self$batch_list` which is a list with one element for each batch, each element is an integer vector of indices.
* Samples are seen in a random order because of `sample(.N)` and this order is different in each epoch because `set_batch_list` is called to set a new `self$batch_list` after each epoch is complete.


``` r
min_samples_per_stratum <- 10
stratified_sampler_class <- torch::sampler(
  "StratifiedSampler",
  initialize = function(data_source) {
    self$data_source <- data_source
    TSK <- data_source$task
    self$stratum <- TSK$col_roles$stratum
    self$stratum_dt <- data.table(
      TSK$data(cols=self$stratum),
      row.id=1:TSK$nrow)
    self$set_batch_list()
  },
  set_batch_list = function() {
    shuffle_dt <- self$stratum_dt[sample(.N)][
    , i.in.stratum := 1:.N, by=c(self$stratum)
    ][]
    count_dt <- shuffle_dt[, .(
      max.i=max(i.in.stratum)
    ), by=c(self$stratum)][order(max.i)]
    count_min <- count_dt$max.i[1]
    num_batches <- count_min %/% min_samples_per_stratum
    max_samp <- num_batches * min_samples_per_stratum
    shuffle_dt[
    , n.samp := i.in.stratum/max(i.in.stratum)*max_samp
    , by=c(self$stratum)
    ][
    , batch.i := ceiling(n.samp/min_samples_per_stratum)
    ][]
    print(dcast(
      shuffle_dt,
      batch.i ~ Class,
      list(length, indices=function(x)paste(x, collapse=",")),
      value.var="row.id"))
    self$batch_list <- split(shuffle_dt$row.id, shuffle_dt$batch.i)
    self$batch_sizes <- sapply(self$batch_list, length)
    self$batch_size_tab <- sort(table(self$batch_sizes))
    self$batch_size <- as.integer(names(self$batch_size_tab)[length(self$batch_size_tab)])
  },
  .iter = function() {
    count <- 0
    function() {
      if (count < length(self$batch_list)) {
        count <<- count + 1L
        indices <- self$batch_list[[count]]
        if (count == length(self$batch_list)) {
          self$set_batch_list()
        }
        return(indices)
      }
      coro::exhausted()
    }
  },
  .length = function() {
    length(self$batch_list)
  }
)
mlp_learner$param_set$set_values(
  epochs=1,
  p=0, # dropout probability.
  batch_size=1, # ignored.
  batch_sampler=stratified_sampler_class)
```

In the code above we set parameters:

* `epochs=1` for one epoch of learning.
* `p=0` for no dropout regularization.
* `batch_size=1` to avoid the error that this parameter is required, but it actually is ignored because we also specify a `batch_sampler`. This a bug which should be fixed by [this PR](https://github.com/mlr-org/mlr3torch/pull/425).

In the code below we train:


``` r
mlp_learner$train(sonar_task)
```

```
## Key: <batch.i>
##    batch.i row.id_length_M row.id_length_R                                    row.id_indices_M                 row.id_indices_R
##      <num>           <int>           <int>                                              <char>                           <char>
## 1:       1              12              10     159,165,195,163,157,158,193,186,202,114,204,191     2,89,65,94,17,83,57,39,84,27
## 2:       2              12              11      196,177,206,140,98,153,201,149,151,127,203,126  30,66,26,72,5,59,51,71,96,52,56
## 3:       3              13              11 152,155,190,194,120,106,146,160,172,181,130,171,154   54,60,24,46,6,55,18,1,79,40,58
## 4:       4              12              11     115,131,145,188,164,109,185,100,192,118,107,147  53,68,95,8,22,73,61,62,77,97,31
## 5:       5              12              10     112,125,166,133,123,143,141,180,116,189,167,208     78,43,93,11,85,23,9,33,76,70
## 6:       6              13              11 135,110,178,199,117,128,156,150,101,138,108,168,132  36,80,91,74,28,88,50,41,12,7,35
## 7:       7              12              11     103,179,137,162,182,173,119,111,136,148,174,139 47,16,32,21,75,20,44,13,82,38,69
## 8:       8              12              11      104,105,124,175,99,169,200,207,184,122,113,187  87,10,15,49,92,67,37,3,19,63,42
## 9:       9              13              11 176,161,170,198,183,197,144,129,102,121,134,142,205  90,14,81,25,86,48,45,34,29,4,64
## Key: <batch.i>
##    batch.i row.id_length_M row.id_length_R                                    row.id_indices_M                 row.id_indices_R
##      <num>           <int>           <int>                                              <char>                           <char>
## 1:       1              12              10     174,118,106,172,196,125,178,103,107,132,199,207     70,16,44,86,40,75,47,6,61,78
## 2:       2              12              11     123,206,176,113,112,138,147,135,116,192,119,194  27,21,7,29,51,79,31,92,38,12,89
## 3:       3              13              11  115,162,155,167,146,166,98,202,122,161,195,149,148  90,1,53,30,58,67,52,69,57,45,84
## 4:       4              12              11     193,184,104,164,114,190,127,203,133,173,189,142  62,88,25,39,49,10,8,19,56,76,83
## 5:       5              12              10     139,121,201,102,158,204,154,171,170,180,186,137     81,94,9,37,71,68,23,97,73,93
## 6:       6              13              11 208,181,187,131,182,136,145,101,124,188,144,160,128  43,28,60,32,96,18,65,80,2,85,91
## 7:       7              12              11      117,99,120,156,126,183,111,197,134,100,191,105 55,41,11,34,26,36,50,77,20,87,82
## 8:       8              12              11     157,143,108,205,110,179,150,177,168,151,169,141   95,5,63,35,54,4,64,14,15,59,33
## 9:       9              13              11 153,140,109,200,175,198,130,185,159,129,163,152,165  24,13,48,3,46,22,72,74,17,42,66
```

The output above is from the print statement inside `set_batch_list`, which shows 

* there are two tables printed, one for the first epoch, and one for the second (not used).
* each row represents a batch.
* in each table, the `row.id_length_*` columns show the number of positive and negative labels in a batch.
* the number of minority class samples (R) is always at least 10.
* the first batch in the first table has the same label counts as the first batch in the second table, etc.
* the first batch `row.id_indices_M` in the first table are different from the corresponding indices in the second table.
* so each epoch uses the samples in a different order, but with the same label counts in each batch.

## Conclusions

We have explained how to create a custom stratified sampler for use in the `mlr3torch` framework. This will be useful in experiments with loss functions that require a minimal number of samples of each class to get a non-zero gradient.

Read [the next post](https://tdhock.github.io/blog/2025/mlr3torch-batch-samplers/) to see how we extended this method, exploring different `min_samples_per_stratum` values, and verifying its correctness.

## Session info


``` r
sessionInfo()
```

```
## R version 4.5.1 (2025-06-13)
## Platform: x86_64-pc-linux-gnu
## Running under: Ubuntu 24.04.3 LTS
## 
## Matrix products: default
## BLAS:   /usr/lib/x86_64-linux-gnu/blas/libblas.so.3.12.0 
## LAPACK: /usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.12.0  LAPACK version 3.12.0
## 
## locale:
##  [1] LC_CTYPE=fr_FR.UTF-8       LC_NUMERIC=C               LC_TIME=fr_FR.UTF-8        LC_COLLATE=fr_FR.UTF-8     LC_MONETARY=fr_FR.UTF-8   
##  [6] LC_MESSAGES=fr_FR.UTF-8    LC_PAPER=fr_FR.UTF-8       LC_NAME=C                  LC_ADDRESS=C               LC_TELEPHONE=C            
## [11] LC_MEASUREMENT=fr_FR.UTF-8 LC_IDENTIFICATION=C       
## 
## time zone: America/Toronto
## tzcode source: system (glibc)
## 
## attached base packages:
## [1] stats     graphics  grDevices datasets  utils     methods   base     
## 
## other attached packages:
## [1] data.table_1.17.8
## 
## loaded via a namespace (and not attached):
##  [1] crayon_1.5.3             knitr_1.50               cli_3.6.5                xfun_0.53                rlang_1.1.6             
##  [6] processx_3.8.6           torch_0.16.0             coro_1.1.0               bit_4.6.0                mlr3pipelines_0.9.0     
## [11] listenv_0.9.1            backports_1.5.0          pkgbuild_1.4.8           ps_1.9.1                 paradox_1.0.1           
## [16] mlr3misc_0.18.0          evaluate_1.0.5           mlr3_1.1.0               palmerpenguins_0.1.1     mlr3torch_0.3.1         
## [21] compiler_4.5.1           mlr3resampling_2025.7.30 codetools_0.2-20         Rcpp_1.1.0               future_1.67.0           
## [26] digest_0.6.37            R6_2.6.1                 curl_7.0.0               parallelly_1.45.1        parallel_4.5.1          
## [31] magrittr_2.0.3           callr_3.7.6              checkmate_2.3.3          withr_3.0.2              bit64_4.6.0-1           
## [36] uuid_1.2-1               tools_4.5.1              globals_0.18.0           bspm_0.5.7               lgr_0.5.0               
## [41] remotes_2.5.0            desc_1.4.3
```
