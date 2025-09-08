---
layout: post
title: Stratified batch sampler for mlr3torch
description: Demonstrations and verifications of correctness using sonar data
---



The goal of this post is to show how to use a custom torch sampler with mlr3torch, in order to use stratified sampling, which can ensure that each batch in gradient descent has a minimum number of samples from each class.
This is a continuation of [a previous post on the same subject](https://tdhock.github.io/blog/2025/mlr3torch-sampler/).

## Motivation: imbalanced classification

We consider imbalanced classification problems, which occur frequently in many different areas.
For example, let us consider the sonar data set.


``` r
sonar_task <- mlr3::tsk("sonar")
(count_tab <- table(sonar_task$data(sonar_task$row_ids, "Class")$Class))
```

```
## 
##   M   R 
## 111  97
```

The sonar label count table above is relatively balanced.
Below we compute the frequencies.


``` r
count_tab/sum(count_tab)
```

```
## 
##         M         R 
## 0.5336538 0.4663462
```

We typically measure class imbalance by using the minority class proportion, which is 46.6% in this case.
This is not much imbalance, because perfectly balanced data would be 50% minority class.
We could consider an even greater imbalance by sub-sampling, which has been discussed in two previous posts:

* [Creating large imbalanced data benchmarks](https://tdhock.github.io/blog/2025/imbalance-openml/), Tutorial with OpenML/higgs data.
* [Creating imbalanced data benchmarks](https://tdhock.github.io/blog/2025/unbalanced/), Tutorial with MNIST.

With sonar we can do:


``` r
sonar_task$filter(208:86)
(count_tab <- table(sonar_task$data(sonar_task$row_ids, "Class")$Class))
```

```
## 
##   M   R 
## 111  12
```

``` r
count_tab/sum(count_tab)
```

```
## 
##          M          R 
## 0.90243902 0.09756098
```

The output above shows 10% minority class, which is substantially more imbalance.
In `mlr3` the column role `stratum` can be used to ensure that sampling is proportion to the class imbalance, so that each sub-sample also has 10% minority class. To do that we use the code below:


``` r
sonar_task$col_roles$stratum <- "Class"
```

## Custom torch batch sampler

In `mlr3` we have a `task`, and in `torch` the analogous concept is `dataset`.
We access the `dataset` via a `dataloader`, which is the `torch` concept for dividing subtrain set samples into batches for gradient descent.
Each batch of samples is used to compute a gradient, and then update the model parameters.
For certain loss functions, we need at least two classes in the batch to get a non-zero gradient.
An example is the Area Under the Minimum (AUM) of False Positives and False Negatives, which we recently proposed for ROC curve optimization, in [Journal of Machine Learning Research 2023](https://jmlr.org/papers/v24/21-0751.html).
We would like to use the `stratum` of the `task` in the context of the `dataloader`.
To ensure that each batch has at least one of the minority class labels, we can define a batch sampler, as below.


``` r
library(data.table)
batch_sampler_stratified <- function(min_samples_per_stratum, shuffle=TRUE){
  torch::sampler(
    "StratifiedSampler",
    initialize = function(data_source) {
      self$data_source <- data_source
      TSK <- data_source$task
      self$stratum <- TSK$col_roles$stratum
      if(length(self$stratum)==0)stop(TSK$id, "task missing stratum column role")
      self$stratum_dt <- data.table(
        TSK$data(cols=self$stratum),
        row.id=1:TSK$nrow)
      self$set_batch_list()
    },
    set_batch_list = function() {
      get_indices <- if(shuffle){
        function(n)torch::as_array(torch::torch_randperm(n))+1L
      }else{
        function(n)1:n
      }
      index_dt <- self$stratum_dt[
        get_indices(.N)
      ][
      , i.in.stratum := 1:.N, by=c(self$stratum)
      ][]
      count_dt <- index_dt[, .(
        max.i=max(i.in.stratum)
      ), by=c(self$stratum)][order(max.i)]
      count_min <- count_dt$max.i[1]
      num_batches <- max(1, count_min %/% min_samples_per_stratum)
      max_samp <- num_batches * min_samples_per_stratum
      index_dt[
      , n.samp := i.in.stratum/max(i.in.stratum)*max_samp
      , by=c(self$stratum)
      ][
      , batch.i := ceiling(n.samp/min_samples_per_stratum)
      ][]
      save_list$count[[paste("epoch", length(save_list$count)+1)]] <<- dcast(
        index_dt,
        batch.i ~ Class,
        list(length, indices=function(x)paste(x, collapse=",")),
        value.var="row.id"
      )[
      , labels := index_dt[, paste(Class, collapse=""), by=batch.i][order(batch.i), V1]
      ]
      self$batch_list <- split(index_dt$row.id, index_dt$batch.i)
      self$batch_sizes <- sapply(self$batch_list, length)
      self$batch_size_tab <- sort(table(self$batch_sizes))
      self$batch_size <- as.integer(names(self$batch_size_tab)[length(self$batch_size_tab)])
    },
    .iter = function() {
      batch.i <- 0
      function() {
        if (batch.i < length(self$batch_list)) {
          batch.i <<- batch.i + 1L
          indices <- self$batch_list[[batch.i]]
          save_list$indices[[length(save_list$indices)+1]] <<- indices
          if (batch.i == length(self$batch_list)) {
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
}
```

Note in the definition above that

* `initialize` derives the stratification from the `stratum` role defined in the task.
* `set_batch_list` sets `self$batch_list` which is a list with one element for each batch, each element is an integer vector of indices.
* If `shuffle=FALSE`, then samples are seen in a deterministic order that matches the source data set.
* If `shuffle=TRUE`, then samples are seen in a random order, and this order is different in each epoch because `set_batch_list` is called to set a new `self$batch_list` after each epoch is complete.

We can use the code above to create the `batch_sampler` parameter to our learner.

## Learner

Before defining the learner, we need to define its loss function.
In binary classification, the typical loss function is the logistic loss, `torch::bce_with_logits_loss`.
The module below has a special forward method that saves the targets (so we can see if the stratification worked), and then uses that loss function.


``` r
nn_bce_with_logits_loss_save <- torch::nn_module(
  "nn_print_loss",
  inherit = torch::nn_mse_loss,
  initialize = function() {
    super$initialize()
    self$bce <- torch::nn_bce_with_logits_loss()
  },
  forward = function(input, target) {
    save_list$target[[length(save_list$target)+1]] <<- target
    self$bce(input, target)
  }
)
```

Then we create a new MLP learner, which by default is a linear model.


``` r
set.seed(4)
mlp_learner <- mlr3torch::LearnerTorchMLP$new(
  task_type="classif",
  loss=nn_bce_with_logits_loss_save)
mlp_learner$predict_type <- "prob"
```

Then we set several learner parameters in the code below.


``` r
mlp_learner$param_set$set_values(
  epochs=1,
  p=0, # dropout probability.
  batch_size=1, # ignored.
  batch_sampler=batch_sampler_stratified(min_samples_per_stratum = 1))
```

In the code above we set parameters:

* `epochs=1` for one epoch of learning.
* `p=0` for no dropout regularization.
* `batch_size=1` to avoid the error that this parameter is required, but it actually is ignored because we also specify a `batch_sampler`. This a bug which should be fixed by [this PR](https://github.com/mlr-org/mlr3torch/pull/425).
* `batch_sampler` is set to our proposed stratified sampler, with min 1 sample per stratum.

In the code below we first initialize `save_list`, then we train:


``` r
save_list <- list()
mlp_learner$train(sonar_task)
names(save_list)
```

```
## [1] "count"   "indices" "target"
```

The output above indicates that some data were created in `save_list` during training.
We can look at `count` to see how many labels were in each batch:


``` r
save_list$count
```

```
## $`epoch 1`
## Key: <batch.i>
##     batch.i row.id_length_M row.id_length_R               row.id_indices_M row.id_indices_R      labels
##       <num>           <int>           <int>                         <char>           <char>      <char>
##  1:       1               9               1   105,98,9,41,101,60,18,109,43              119  MMRMMMMMMM
##  2:       2               9               1    53,62,96,40,30,104,44,27,83              113  MRMMMMMMMM
##  3:       3               9               1   75,14,16,26,19,110,42,93,107              115  RMMMMMMMMM
##  4:       4              10               1  6,79,46,37,21,66,58,54,100,39              114 RMMMMMMMMMM
##  5:       5               9               1     69,51,31,65,36,81,59,28,95              116  MMMMMMMMMR
##  6:       6               9               1     34,50,35,73,13,77,90,80,94              122  MMMMMMMMMR
##  7:       7               9               1     92,29,102,17,33,91,45,7,64              112  MMMMMMMMMR
##  8:       8              10               1    85,32,8,38,48,3,61,4,106,57              121 MMMMMMMMMMR
##  9:       9               9               1      63,68,10,74,2,22,70,52,72              123  MMMMMMMRMM
## 10:      10               9               1    78,97,86,55,47,12,76,24,108              120  MMMMMMMMMR
## 11:      11               9               1      23,5,89,25,84,56,67,15,49              118  MMMMMMMMMR
## 12:      12              10               1 20,103,87,88,111,1,99,71,82,11              117 MMMMMMMMMRM
## 
## $`epoch 2`
## Key: <batch.i>
##     batch.i row.id_length_M row.id_length_R               row.id_indices_M row.id_indices_R      labels
##       <num>           <int>           <int>                         <char>           <char>      <char>
##  1:       1               9               1      30,87,60,2,101,38,48,5,34              120  MMMMRMMMMM
##  2:       2               9               1     36,7,82,80,53,58,16,110,79              112  MMMMMMRMMM
##  3:       3               9               1    35,103,76,70,97,46,14,89,47              116  RMMMMMMMMM
##  4:       4              10               1 40,85,23,94,56,62,100,65,95,68              113 RMMMMMMMMMM
##  5:       5               9               1     93,74,73,25,1,29,105,63,75              118  MMMMMMMMMR
##  6:       6               9               1      107,21,9,44,91,45,92,6,52              123  MMMMMMMMMR
##  7:       7               9               1   98,24,55,88,108,99,106,66,10              117  MMMMMMMMMR
##  8:       8              10               1 51,109,11,59,64,49,39,86,41,19              119 MMMMMMMMMRM
##  9:       9               9               1      71,54,3,32,78,67,31,37,43              114  MMMMMMMMMR
## 10:      10               9               1     77,4,81,96,50,61,111,69,84              121  MMMMMRMMMM
## 11:      11               9               1    102,18,42,26,104,13,27,90,8              115  MMMMMMMMMR
## 12:      12              10               1  33,83,22,20,57,17,15,12,28,72              122 MMMMMMMRMMM
```

The output above comes from `set_batch_list`, and shows

* there are two tables printed, one for the first epoch, and one for the second (computed but not used yet).
* each row represents a batch.
* in each table, the `row.id_length_*` columns show the number of positive and negative labels in a batch.
* the number of minority class samples (R) is always 1, because we specified `min_samples_per_stratum = 1` in the call to `batch_sampler_stratified` in the code above.
* the first batch in the first table has the same label counts as the first batch in the second table, etc.
* the first batch `row.id_indices_M` in the first table are different from the corresponding indices in the second table.
* so each epoch uses the samples in a different order, but with the same label counts in each batch.

## Double-check correct indices and labels

The code below checks that the targets (=labels) seen by the loss function in each batch are consistent with the indices.


``` r
sonar_dataset <- mlp_learner$dataset(sonar_task)
for(batch.i in 1:length(save_list$target)){
  index_vec <- save_list$indices[[batch.i]]
  target_tensor <- save_list$target[[batch.i]]
  target_vec <- torch::as_array(target_tensor)
  label_vec <- names(count_tab)[ifelse(target_vec==1, 1, 2)]
  set(
    save_list$count[["epoch 1"]],
    i=batch.i,
    j="check",
    value=paste(label_vec, collapse=""))
  stopifnot(all.equal(
    target_tensor$flatten(),
    sonar_dataset$.getbatch(index_vec)$y$flatten()
  ))
}
save_list$count[["epoch 1"]]
```

```
## Key: <batch.i>
##     batch.i row.id_length_M row.id_length_R               row.id_indices_M row.id_indices_R      labels       check
##       <num>           <int>           <int>                         <char>           <char>      <char>      <char>
##  1:       1               9               1   105,98,9,41,101,60,18,109,43              119  MMRMMMMMMM  MMRMMMMMMM
##  2:       2               9               1    53,62,96,40,30,104,44,27,83              113  MRMMMMMMMM  MRMMMMMMMM
##  3:       3               9               1   75,14,16,26,19,110,42,93,107              115  RMMMMMMMMM  RMMMMMMMMM
##  4:       4              10               1  6,79,46,37,21,66,58,54,100,39              114 RMMMMMMMMMM RMMMMMMMMMM
##  5:       5               9               1     69,51,31,65,36,81,59,28,95              116  MMMMMMMMMR  MMMMMMMMMR
##  6:       6               9               1     34,50,35,73,13,77,90,80,94              122  MMMMMMMMMR  MMMMMMMMMR
##  7:       7               9               1     92,29,102,17,33,91,45,7,64              112  MMMMMMMMMR  MMMMMMMMMR
##  8:       8              10               1    85,32,8,38,48,3,61,4,106,57              121 MMMMMMMMMMR MMMMMMMMMMR
##  9:       9               9               1      63,68,10,74,2,22,70,52,72              123  MMMMMMMRMM  MMMMMMMRMM
## 10:      10               9               1    78,97,86,55,47,12,76,24,108              120  MMMMMMMMMR  MMMMMMMMMR
## 11:      11               9               1      23,5,89,25,84,56,67,15,49              118  MMMMMMMMMR  MMMMMMMMMR
## 12:      12              10               1 20,103,87,88,111,1,99,71,82,11              117 MMMMMMMMMRM MMMMMMMMMRM
```

The output above has a new `check` column which is consistent with the previous `labels` column, as expected.
Both show the vector of labels in each batch.

## Varying batch size

In our proposed batch sampler, we are not able to directly control batch size.
The input parameter is `min_samples_per_stratum`, which affects the batch size.
In the previous section, we enforced min 1 sample per stratum (in each batch), which made batches of size 10 or 11.
Below we study how this parameter affects batch size.


``` r
label_count_dt_list <- list()
for(min_samples_per_stratum in c(1:7,20)){
  mlp_learner$param_set$set_values(
    epochs=1,
    p=0, # dropout probability.
    batch_size=1, # ignored.
    batch_sampler=batch_sampler_stratified(min_samples_per_stratum = min_samples_per_stratum))
  save_list <- list()
  mlp_learner$train(sonar_task)
  label_count_dt_list[[paste0(
    "min_samples_per_stratum=", min_samples_per_stratum
  )]] <- save_list$count[["epoch 1"]][, data.table(
    batch.i, row.id_length_M, row.id_length_R, batch_size=row.id_length_M+row.id_length_R)]
}
label_count_dt_list
```

```
## $`min_samples_per_stratum=1`
## Key: <batch.i>
##     batch.i row.id_length_M row.id_length_R batch_size
##       <num>           <int>           <int>      <int>
##  1:       1               9               1         10
##  2:       2               9               1         10
##  3:       3               9               1         10
##  4:       4              10               1         11
##  5:       5               9               1         10
##  6:       6               9               1         10
##  7:       7               9               1         10
##  8:       8              10               1         11
##  9:       9               9               1         10
## 10:      10               9               1         10
## 11:      11               9               1         10
## 12:      12              10               1         11
## 
## $`min_samples_per_stratum=2`
## Key: <batch.i>
##    batch.i row.id_length_M row.id_length_R batch_size
##      <num>           <int>           <int>      <int>
## 1:       1              18               2         20
## 2:       2              19               2         21
## 3:       3              18               2         20
## 4:       4              19               2         21
## 5:       5              18               2         20
## 6:       6              19               2         21
## 
## $`min_samples_per_stratum=3`
## Key: <batch.i>
##    batch.i row.id_length_M row.id_length_R batch_size
##      <num>           <int>           <int>      <int>
## 1:       1              27               3         30
## 2:       2              28               3         31
## 3:       3              28               3         31
## 4:       4              28               3         31
## 
## $`min_samples_per_stratum=4`
## Key: <batch.i>
##    batch.i row.id_length_M row.id_length_R batch_size
##      <num>           <int>           <int>      <int>
## 1:       1              37               4         41
## 2:       2              37               4         41
## 3:       3              37               4         41
## 
## $`min_samples_per_stratum=5`
## Key: <batch.i>
##    batch.i row.id_length_M row.id_length_R batch_size
##      <num>           <int>           <int>      <int>
## 1:       1              55               6         61
## 2:       2              56               6         62
## 
## $`min_samples_per_stratum=6`
## Key: <batch.i>
##    batch.i row.id_length_M row.id_length_R batch_size
##      <num>           <int>           <int>      <int>
## 1:       1              55               6         61
## 2:       2              56               6         62
## 
## $`min_samples_per_stratum=7`
## Key: <batch.i>
##    batch.i row.id_length_M row.id_length_R batch_size
##      <num>           <int>           <int>      <int>
## 1:       1             111              12        123
## 
## $`min_samples_per_stratum=20`
## Key: <batch.i>
##    batch.i row.id_length_M row.id_length_R batch_size
##      <num>           <int>           <int>      <int>
## 1:       1             111              12        123
```

The output above shows that the batch size is always about 10x the value of `min_samples_per_stratum`, because the data set had about 10% minority class labels.
When `min_samples_per_stratum` is 7 or larger, we get a single batch with all samples (same as full gradient method).

## `shuffle` parameter

The `shuffle` argument to `batch_sampler_stratified` controls whether or not the data are seen in a random order in each epoch.
We can see the effect of this parameter via the code below.


``` r
shuffle_list <- list()
for(shuffle in c(TRUE, FALSE)){
  mlp_learner$param_set$set_values(
    epochs=1,
    p=0, # dropout probability.
    batch_size=1, # ignored.
    batch_sampler=batch_sampler_stratified(min_samples_per_stratum = 1, shuffle = shuffle))
  save_list <- list()
  mlp_learner$train(sonar_task)
  shuffle_list[[paste0("shuffle=", shuffle)]] <- save_list$count
}
shuffle_list
```

```
## $`shuffle=TRUE`
## $`shuffle=TRUE`$`epoch 1`
## Key: <batch.i>
##     batch.i row.id_length_M row.id_length_R              row.id_indices_M row.id_indices_R      labels
##       <num>           <int>           <int>                        <char>           <char>      <char>
##  1:       1               9               1      43,39,2,14,57,93,89,41,9              112  MMMMMMMMMR
##  2:       2               9               1   44,31,109,18,68,55,5,12,110              116  MMMMMMMMMR
##  3:       3               9               1  75,42,77,50,96,108,103,10,98              115  MMMMMMRMMM
##  4:       4              10               1  30,3,51,53,72,8,67,33,107,27              123 RMMMMMMMMMM
##  5:       5               9               1   73,83,34,102,52,63,99,49,29              118  RMMMMMMMMM
##  6:       6               9               1  79,105,65,88,101,47,37,19,62              120  RMMMMMMMMM
##  7:       7               9               1  111,60,66,80,84,97,45,100,90              122  RMMMMMMMMM
##  8:       8              10               1  15,69,17,46,6,11,32,40,86,13              121 RMMMMMMMMMM
##  9:       9               9               1   25,28,95,22,23,78,87,106,71              114  RMMMMMMMMM
## 10:      10               9               1    81,16,20,38,82,91,36,70,76              119  RMMMMMMMMM
## 11:      11               9               1      59,21,85,7,61,48,24,4,35              113  RMMMMMMMMM
## 12:      12              10               1 26,58,104,64,94,92,56,1,74,54              117 RMMMMMMMMMM
## 
## $`shuffle=TRUE`$`epoch 2`
## Key: <batch.i>
##     batch.i row.id_length_M row.id_length_R               row.id_indices_M row.id_indices_R      labels
##       <num>           <int>           <int>                         <char>           <char>      <char>
##  1:       1               9               1    29,21,102,43,18,16,33,44,10              123  RMMMMMMMMM
##  2:       2               9               1 105,14,90,101,41,66,109,108,70              121  RMMMMMMMMM
##  3:       3               9               1   94,111,34,110,52,62,74,64,39              113  MMRMMMMMMM
##  4:       4              10               1 57,75,72,81,37,79,103,99,47,45              119 RMMMMMMMMMM
##  5:       5               9               1       4,6,76,31,59,65,89,95,27              120  RMMMMMMMMM
##  6:       6               9               1       93,5,35,55,46,8,92,85,11              117  MMMMMMMRMM
##  7:       7               9               1      40,63,20,104,24,1,61,13,9              118  MMMMMMMMMR
##  8:       8              10               1  17,60,48,96,83,97,68,23,71,54              122 MMMMMMMMMMR
##  9:       9               9               1     78,56,53,49,88,12,26,84,28              116  MMMMMMMMMR
## 10:      10               9               1      42,51,98,19,77,7,36,58,32              115  MMMMMMMRMM
## 11:      11               9               1    22,15,67,3,100,38,107,91,86              112  MRMMMMMMMM
## 12:      12              10               1  2,106,80,69,25,87,82,30,50,73              114 MMMMMMMRMMM
## 
## 
## $`shuffle=FALSE`
## $`shuffle=FALSE`$`epoch 1`
## Key: <batch.i>
##     batch.i row.id_length_M row.id_length_R                        row.id_indices_M row.id_indices_R      labels
##       <num>           <int>           <int>                                  <char>           <char>      <char>
##  1:       1               9               1                       1,2,3,4,5,6,7,8,9              112  MMMMMMMMMR
##  2:       2               9               1              10,11,12,13,14,15,16,17,18              113  MMMMMMMMMR
##  3:       3               9               1              19,20,21,22,23,24,25,26,27              114  MMMMMMMMMR
##  4:       4              10               1           28,29,30,31,32,33,34,35,36,37              115 MMMMMMMMMMR
##  5:       5               9               1              38,39,40,41,42,43,44,45,46              116  MMMMMMMMMR
##  6:       6               9               1              47,48,49,50,51,52,53,54,55              117  MMMMMMMMMR
##  7:       7               9               1              56,57,58,59,60,61,62,63,64              118  MMMMMMMMMR
##  8:       8              10               1           65,66,67,68,69,70,71,72,73,74              119 MMMMMMMMMMR
##  9:       9               9               1              75,76,77,78,79,80,81,82,83              120  MMMMMMMMMR
## 10:      10               9               1              84,85,86,87,88,89,90,91,92              121  MMMMMMMMMR
## 11:      11               9               1            93,94,95,96,97,98,99,100,101              122  MMMMMMMMMR
## 12:      12              10               1 102,103,104,105,106,107,108,109,110,111              123 MMMMMMMMMMR
## 
## $`shuffle=FALSE`$`epoch 2`
## Key: <batch.i>
##     batch.i row.id_length_M row.id_length_R                        row.id_indices_M row.id_indices_R      labels
##       <num>           <int>           <int>                                  <char>           <char>      <char>
##  1:       1               9               1                       1,2,3,4,5,6,7,8,9              112  MMMMMMMMMR
##  2:       2               9               1              10,11,12,13,14,15,16,17,18              113  MMMMMMMMMR
##  3:       3               9               1              19,20,21,22,23,24,25,26,27              114  MMMMMMMMMR
##  4:       4              10               1           28,29,30,31,32,33,34,35,36,37              115 MMMMMMMMMMR
##  5:       5               9               1              38,39,40,41,42,43,44,45,46              116  MMMMMMMMMR
##  6:       6               9               1              47,48,49,50,51,52,53,54,55              117  MMMMMMMMMR
##  7:       7               9               1              56,57,58,59,60,61,62,63,64              118  MMMMMMMMMR
##  8:       8              10               1           65,66,67,68,69,70,71,72,73,74              119 MMMMMMMMMMR
##  9:       9               9               1              75,76,77,78,79,80,81,82,83              120  MMMMMMMMMR
## 10:      10               9               1              84,85,86,87,88,89,90,91,92              121  MMMMMMMMMR
## 11:      11               9               1            93,94,95,96,97,98,99,100,101              122  MMMMMMMMMR
## 12:      12              10               1 102,103,104,105,106,107,108,109,110,111              123 MMMMMMMMMMR
```

The output above shows that

* when `shuffle=TRUE`, batch 1 has different indices in epoch 1 than in epoch 2 (and similarly for other batches).
* when `shuffle=FALSE`, batch 1 has same indices in epoch 1 and 2 (and they are the first few indices of each class).

These results indicate that the `shuffle` parameter of the proposed sampler behaves as expected (consistent with standard batching in torch).

## Randomness control, part 1: random weights

A torch model is initialized with random weights.
This is actually pseudo-randomness which can be controlled by the torch random seed.
By default `mlr3torch` learners will always use a different random intiailization.
This can be controlled via the `seed` parameter, as demonstrated by the code below,


``` r
param_list <- list()
set.seed(5) # controls what is used as the torch random seed (if param not set).
for(set_seed in c(0:1)){
  for(rep_i in 1:2){
    L <- mlr3torch::LearnerTorchMLP$new(task_type="classif")
    L$param_set$set_values(epochs=0, batch_size=10)
    if(set_seed)L$param_set$values$seed <- 1 # torch random seed.
    L$train(sonar_task)
    param_list[[sprintf("set_seed=%d rep=%d", set_seed, rep_i)]] <- unlist(lapply(
      L$model$network$parameters, torch::as_array))
  }
}
```

The code above uses 0 epochs of training, so the weights simply come from the random initialization.
The first for loop is over `set_seed` values: 0 means to take the default (torch random seed depends on R random seed), 1 means to set the torch random seed to 1.
The second for loop is over `rep_i` values, which are simply repetitions, so we can see if we get the same weights after running the code twice.
Below we see the first few weights using each of the methods:


``` r
do.call(rbind, param_list)[, 1:5]
```

```
##                    0.weight1   0.weight2   0.weight3  0.weight4   0.weight5
## set_seed=0 rep=1  0.03279998 -0.06481405  0.07047248 0.08959757 -0.09685164
## set_seed=0 rep=2 -0.01949527  0.07055710  0.02056149 0.09997202  0.03222404
## set_seed=1 rep=1  0.06652019 -0.05698169 -0.02502741 0.06059527 -0.12153898
## set_seed=1 rep=2  0.06652019 -0.05698169 -0.02502741 0.06059527 -0.12153898
```

We see above that

* the first two rows have different weight values, which indicates that the default is to use different random weights in each initialization.
* the last two rows have the same weight values, which indicates that the `seed` parameter controls the random weight initialization.

## Randomness control, part 2: batching

What happens when we run gradient descent?
By default we go through batches in a random order, which induces another kind of randomness (other than the weight initialization), that is also controlled by the `seed` parameter, as shown by the experiment below.


``` r
param_list <- list()
set.seed(5) # controls what is used as the torch random seed (if param not set).
for(set_batch_sampler in c(0:1)){
  for(rep_i in 1:2){
    L <- mlr3torch::LearnerTorchMLP$new(task_type="classif")
    L$param_set$set_values(epochs=1, batch_size=10, seed=1)
    if(set_batch_sampler)L$param_set$values$batch_sampler <- batch_sampler_stratified(1)
    L$train(sonar_task)
    param_list[[sprintf("set_batch_sampler=%d rep=%d", set_batch_sampler, rep_i)]] <- unlist(lapply(
      L$model$network$parameters, torch::as_array))
  }
}
```

The code above replaces `set_seed` (now always 1) with `set_batch_sampler` in the first for loop.
When the batch sampler is not set, we use the usual batching mechanism, with `batch_size=10`.
When the batch sampler is set, we use our custom sampler defined above.
The other difference is that we have change `epochs` from 0 to 1, so that we are using gradient descent to get weight values (in addition to the random initialization).


``` r
do.call(rbind, param_list)[, 1:5]
```

```
##                            0.weight1   0.weight2   0.weight3   0.weight4  0.weight5
## set_batch_sampler=0 rep=1 0.07897462 -0.04479400 -0.01260542  0.07326440 -0.1090717
## set_batch_sampler=0 rep=2 0.07897462 -0.04479400 -0.01260542  0.07326440 -0.1090717
## set_batch_sampler=1 rep=1 0.14044657 -0.06968932  0.08062322 -0.05977938 -0.1097272
## set_batch_sampler=1 rep=2 0.14044657 -0.06968932  0.08062322 -0.05977938 -0.1097272
```

The output above shows that the first two rows are identical, as are the last two rows.
This result indicates that setting the `seed` parameter is sufficient to control randomness of both initialization and batching (using both the usual sampler, and our proposed sampler).
Note that this would not have been possible if we used R's randomness in `batch_sampler_stratified` (exercise for the reader: replace `torch::torch_randperm` with `sample` and show that you get different weights between repetitions).

## Conclusions

We have explained how to create a custom stratified sampler for use in the `mlr3torch` framework. This will be useful in experiments with loss functions that require a minimal number of samples of each class to get a non-zero gradient.

For practical applications of this sampler, rather than using the code on this page (which has un-necessary `save_list` instrumentation), please check out the `batch_sampler` branch of `library(mlr3resampling)` on github, in [this PR](https://github.com/tdhock/mlr3resampling/pull/43).
The version of the function in the package has the instrumentation removed.


``` r
remotes::install_github("tdhock/mlr3resampling@batch_sampler")
```

```
## Using github PAT from envvar GITHUB_PAT. Use `gitcreds::gitcreds_set()` and unset GITHUB_PAT in .Renviron (or elsewhere) if you want to use the more secure git credential store instead.
```

```
## Skipping install of 'mlr3resampling' from a github remote, the SHA1 (1cba9566) has not changed since last install.
##   Use `force = TRUE` to force installation
```

``` r
mlr3resampling:::batch_sampler_stratified
```

```
## function (min_samples_per_stratum, shuffle = TRUE) 
## {
##     torch::sampler("StratifiedSampler", initialize = function(data_source) {
##         self$data_source <- data_source
##         TSK <- data_source$task
##         self$stratum <- TSK$col_roles$stratum
##         if (length(self$stratum) == 0) 
##             stop(TSK$id, "task missing stratum column role")
##         self$stratum_dt <- data.table(TSK$data(cols = self$stratum), 
##             row.id = 1:TSK$nrow)
##         self$set_batch_list()
##     }, set_batch_list = function() {
##         get_indices <- if (shuffle) {
##             function(n) torch::as_array(torch::torch_randperm(n)) + 
##                 1L
##         }
##         else {
##             function(n) 1:n
##         }
##         index_dt <- self$stratum_dt[get_indices(.N)][, `:=`(i.in.stratum, 
##             1:.N), by = c(self$stratum)][]
##         count_dt <- index_dt[, .(max.i = max(i.in.stratum)), 
##             by = c(self$stratum)][order(max.i)]
##         count_min <- count_dt$max.i[1]
##         num_batches <- max(1, count_min%/%min_samples_per_stratum)
##         max_samp <- num_batches * min_samples_per_stratum
##         index_dt[, `:=`(n.samp, i.in.stratum/max(i.in.stratum) * 
##             max_samp), by = c(self$stratum)][, `:=`(batch.i, 
##             ceiling(n.samp/min_samples_per_stratum))][]
##         self$batch_list <- split(index_dt$row.id, index_dt$batch.i)
##         self$batch_sizes <- sapply(self$batch_list, length)
##         self$batch_size_tab <- sort(table(self$batch_sizes))
##         self$batch_size <- as.integer(names(self$batch_size_tab)[length(self$batch_size_tab)])
##     }, .iter = function() {
##         batch.i <- 0
##         function() {
##             if (batch.i < length(self$batch_list)) {
##                 batch.i <<- batch.i + 1L
##                 indices <- self$batch_list[[batch.i]]
##                 if (batch.i == length(self$batch_list)) {
##                   self$set_batch_list()
##                 }
##                 return(indices)
##             }
##             coro::exhausted()
##         }
##     }, .length = function() {
##         length(self$batch_list)
##     })
## }
## <bytecode: 0x5bf5f1d48c00>
## <environment: namespace:mlr3resampling>
```

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
