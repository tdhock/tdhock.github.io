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
count_dt[num_1==0]
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

We can see above that there are 201 batches that have no positive labels.
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

``` r
class_counts[`1` < min_samples_per_stratum]
```

```
## Key: <batch.i>
## Empty data.table (0 rows and 3 cols): batch.i,0,1
```

The table above has one row per batch, and one column per class label.
We see that the class counts are constant across batches, consistent with stratified random sampling.

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
##   5:        5    98     3
##  ---                     
## 196:      196    98     3
## 197:      197    97     3
## 198:      198    97     3
## 199:      199    97     3
## 200:      200    98     4
```

## Plugging into mlr3torch

First, note that to get the code below to work, I needed to propose a modification to mlr3torch, which is available in this branch -- [PR](https://github.com/mlr-org/mlr3torch/pull/419) was merged, and an update was submitted to CRAN.
Note in the code below we either need to specify `batch_size` (even though it is un-ncessary), or use the fix in this other [PR](https://github.com/mlr-org/mlr3torch/pull/425).

We can then create a simple linear model torch learner in the `mlr3torch` system, and apply it to the sonar data set, using the stratified sampling strategy:


``` r
sonar_task <- mlr3::tsk("sonar")
sonar_task$col_roles$stratum <- "Class"
measure_list <- mlr3::msrs(c("classif.auc", "classif.logloss"))
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
    ## batch_size is actually min_samples_per_stratum, the number of
    ## samples from the smallest stratum in each batch.
    batch_size <- 10
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
    , batch.i := ceiling(n.samp/batch_size)
    ][]
    self$batch_list <- split(shuffle_dt$row.id, shuffle_dt$batch.i)
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
mlp_learner <- mlr3torch::LearnerTorchMLP$new(task_type="classif")
mlp_learner$predict_type <- "prob"
mlp_learner$param_set$set_values(
  epochs=10,
  p=0,
  batch_size=1,
  batch_sampler=stratified_sampler_class,
  measures_valid=measure_list,
  measures_train=measure_list)
mlr3::set_validate(mlp_learner, 0.5)
mlp_learner$callbacks <- mlr3torch::t_clbk("history")
mlp_learner$train(sonar_task)
mlp_learner$model$callbacks$history
```

```
## Key: <epoch>
##     epoch train.classif.auc train.classif.logloss valid.classif.auc valid.classif.logloss
##     <num>             <num>                 <num>             <num>                 <num>
##  1:     1         0.5241815             0.6960188         0.4782931             0.6949892
##  2:     2         0.5483631             0.6912082         0.5439703             0.6905079
##  3:     3         0.5796131             0.6873733         0.5862709             0.6882407
##  4:     4         0.6030506             0.6842948         0.5102041             0.6929740
##  5:     5         0.6205357             0.6814849         0.4938776             0.6933464
##  6:     6         0.6432292             0.6791373         0.5202226             0.6922777
##  7:     7         0.6540179             0.6769112         0.5632653             0.6880635
##  8:     8         0.6722470             0.6745022         0.4448980             0.6990532
##  9:     9         0.6837798             0.6724846         0.4244898             0.7006367
## 10:    10         0.6956845             0.6701525         0.5135436             0.6904479
```

## Conclusions

We have explained how to create a custom stratified sampler for use in the `mlr3torch` framework. This will be useful in experiments with loss functions that require a minimal number of samples of each class to get a non-zero gradient.

## Session info


``` r
sessionInfo()
```

```
## R version 4.5.1 (2025-06-13 ucrt)
## Platform: x86_64-w64-mingw32/x64
## Running under: Windows 11 x64 (build 26100)
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
## [1] data.table_1.17.99
## 
## loaded via a namespace (and not attached):
##  [1] crayon_1.5.3         knitr_1.50           cli_3.6.5            xfun_0.53            rlang_1.1.6         
##  [6] processx_3.8.6       torch_0.16.0         coro_1.1.0           bit_4.6.0            mlr3pipelines_0.9.0 
## [11] listenv_0.9.1        backports_1.5.0      mlr3measures_1.1.0   ps_1.9.1             paradox_1.0.1       
## [16] mlr3misc_0.18.0      evaluate_1.0.5       mlr3_1.1.0           palmerpenguins_0.1.1 mlr3torch_0.3.1.9000
## [21] compiler_4.5.1       codetools_0.2-20     Rcpp_1.1.0           future_1.67.0        digest_0.6.37       
## [26] R6_2.6.1             parallelly_1.45.1    parallel_4.5.1       magrittr_2.0.3       callr_3.7.6         
## [31] checkmate_2.3.3      uuid_1.2-1           tools_4.5.1          withr_3.0.2          bit64_4.6.0-1       
## [36] globals_0.18.0       lgr_0.5.0
```
