---
layout: post
title: Parallel machine learning benchmarks
description: A new approach using targets and crew.cluster
---



I recently wrote about [New parallel computing frameworks in
R](https://tdhock.github.io/blog/2025/rush/). The goal of this blog is
to explore how these new frameworks may be used for parallelizing
machine learning benchmark experiments.

## Introduction to machine learning

Typically when we parallelize machine learning benchmark experiments with mlr3, we use the following pipeline:

* `mlr3::benchmark_grid()` creates a grid of tasks, learners, and resampling iterations.
* `batchtools::makeExperimentRegistry()` creates a registry directory.
* `mlr3batchmark::batchmark()` save the grid into the registry directory.
* `batchtools::submitJobs()` launches the jobs on the cluster.
* `mlr3batchmark::reduceResultsBatchmark()` combines the results into a single file.

This approach is discussed in the following blogs:

* [The importance of hyper-parameter
  tuning](https://tdhock.github.io/blog/2024/hyper-parameter-tuning/)
  explains how to use the auto-tuner.
* [Cross-validation experiments with torch
  learners](https://tdhock.github.io/blog/2024/mlr3torch/) explains
  how to compare linear models in torch with other learners from
  outside torch like `glmnet`.
* [Torch learning with binary
  classification](https://tdhock.github.io/blog/2025/mlr3torch-binary/)
  explains how to implement a custom loss function for binary
  classification in mlr3torch.
* [Comparing neural network architectures using mlr3torch](https://tdhock.github.io/blog/2025/mlr3torch-conv/) explains how to implement different neural network architectures, and make figures to compare their subtrain/validation/test error rates.

While this approach is very useful, there are some dis-advantages:

* jobs can have very different times, which induces an inefficient use of the scheduler (which requires specifying a single max time/memory for all heterogeneous tasks within a single job/experiment).
* the data must be serialized to the network file system, which can be slow.

## Simulate data for ML experiment

This example is taken from `?mlr3resampling::pvalue`:


``` r
N <- 80
library(data.table)
set.seed(1)
reg.dt <- data.table(
  x=runif(N, -2, 2),
  person=factor(rep(c("Alice","Bob"), each=0.5*N)))
reg.pattern.list <- list(
  easy=function(x, person)x^2,
  impossible=function(x, person)(x^2)*(-1)^as.integer(person))
SOAK <- mlr3resampling::ResamplingSameOtherSizesCV$new()
viz.dt.list <- list()
reg.task.list <- list()
for(pattern in names(reg.pattern.list)){
  f <- reg.pattern.list[[pattern]]
  task.dt <- data.table(reg.dt)[
  , y := f(x,person)+rnorm(N, sd=0.5)
  ][]
  task.obj <- mlr3::TaskRegr$new(
    pattern, task.dt, target="y")
  task.obj$col_roles$feature <- "x"
  task.obj$col_roles$stratum <- "person"
  task.obj$col_roles$subset <- "person"
  reg.task.list[[pattern]] <- task.obj
  viz.dt.list[[pattern]] <- data.table(pattern, task.dt)
}
(viz.dt <- rbindlist(viz.dt.list))
```

```
##         pattern          x person          y
##          <char>      <num> <fctr>      <num>
##   1:       easy -0.9379653  Alice  0.7975172
##   2:       easy -0.5115044  Alice  0.1349559
##   3:       easy  0.2914135  Alice  0.4334035
##   4:       easy  1.6328312  Alice  2.9444692
##   5:       easy -1.1932723  Alice  1.0795209
##  ---                                        
## 156: impossible  1.5687933    Bob  1.9371203
## 157: impossible  1.4573579    Bob  2.8444709
## 158: impossible -0.4400418    Bob -0.3142869
## 159: impossible  1.1092828    Bob  1.4364957
## 160: impossible  1.8424720    Bob  3.2041650
```

The data table above represents simulated regression problem, which is visualized using the code below.


``` r
library(ggplot2)
ggplot()+
  geom_point(aes(
    x, y),
    data=viz.dt)+
  facet_grid(pattern ~ person, labeller=label_both)
```

![plot of chunk sim-data](/assets/img/2025-05-20-mlr3-targets/sim-data-1.png)

The figure above shows data for two simulated patterns: 

* easy (top) has same pattern in the two people.
* impossible (bottom) has different patterns in the two people.

## mlr3 benchmark grid

To use mlr3 on these data, we create a benchmark grid with a list of tasks and learners in the code below.


``` r
reg.learner.list <- list(
  mlr3::LearnerRegrFeatureless$new())
if(requireNamespace("rpart")){
  reg.learner.list$rpart <- mlr3::LearnerRegrRpart$new()
}
(bench.grid <- mlr3::benchmark_grid(
  reg.task.list,
  reg.learner.list,
  SOAK))
```

```
##          task          learner          resampling
##        <char>           <char>              <char>
## 1:       easy regr.featureless same_other_sizes_cv
## 2:       easy       regr.rpart same_other_sizes_cv
## 3: impossible regr.featureless same_other_sizes_cv
## 4: impossible       regr.rpart same_other_sizes_cv
```

The output above indicates that we want to run `same_other_sizes_cv`
resampling on two different tasks, and two different learners.
To run that in sequence, we use the typical mlr3 functions in the code below.


``` r
bench.result <- mlr3::benchmark(bench.grid)
```

```
## INFO  [07:36:58.385] [mlr3] Running benchmark with 72 resampling iterations
## INFO  [07:36:58.390] [mlr3] Applying learner 'regr.featureless' on task 'easy' (iter 1/18)
## INFO  [07:36:58.396] [mlr3] Applying learner 'regr.featureless' on task 'easy' (iter 2/18)
## INFO  [07:36:58.403] [mlr3] Applying learner 'regr.featureless' on task 'easy' (iter 3/18)
## INFO  [07:36:58.409] [mlr3] Applying learner 'regr.featureless' on task 'easy' (iter 4/18)
## INFO  [07:36:58.416] [mlr3] Applying learner 'regr.featureless' on task 'easy' (iter 5/18)
## INFO  [07:36:58.422] [mlr3] Applying learner 'regr.featureless' on task 'easy' (iter 6/18)
## INFO  [07:36:58.429] [mlr3] Applying learner 'regr.featureless' on task 'easy' (iter 7/18)
## INFO  [07:36:58.435] [mlr3] Applying learner 'regr.featureless' on task 'easy' (iter 8/18)
## INFO  [07:36:58.442] [mlr3] Applying learner 'regr.featureless' on task 'easy' (iter 9/18)
## INFO  [07:36:58.452] [mlr3] Applying learner 'regr.featureless' on task 'easy' (iter 10/18)
## INFO  [07:36:58.459] [mlr3] Applying learner 'regr.featureless' on task 'easy' (iter 11/18)
## INFO  [07:36:58.465] [mlr3] Applying learner 'regr.featureless' on task 'easy' (iter 12/18)
## INFO  [07:36:58.473] [mlr3] Applying learner 'regr.featureless' on task 'easy' (iter 13/18)
## INFO  [07:36:58.481] [mlr3] Applying learner 'regr.featureless' on task 'easy' (iter 14/18)
## INFO  [07:36:58.487] [mlr3] Applying learner 'regr.featureless' on task 'easy' (iter 15/18)
## INFO  [07:36:58.493] [mlr3] Applying learner 'regr.featureless' on task 'easy' (iter 16/18)
## INFO  [07:36:58.500] [mlr3] Applying learner 'regr.featureless' on task 'easy' (iter 17/18)
## INFO  [07:36:58.506] [mlr3] Applying learner 'regr.featureless' on task 'easy' (iter 18/18)
## INFO  [07:36:58.513] [mlr3] Applying learner 'regr.rpart' on task 'easy' (iter 1/18)
## INFO  [07:36:58.649] [mlr3] Applying learner 'regr.rpart' on task 'easy' (iter 2/18)
## INFO  [07:36:58.658] [mlr3] Applying learner 'regr.rpart' on task 'easy' (iter 3/18)
## INFO  [07:36:58.667] [mlr3] Applying learner 'regr.rpart' on task 'easy' (iter 4/18)
## INFO  [07:36:58.676] [mlr3] Applying learner 'regr.rpart' on task 'easy' (iter 5/18)
## INFO  [07:36:58.684] [mlr3] Applying learner 'regr.rpart' on task 'easy' (iter 6/18)
## INFO  [07:36:58.693] [mlr3] Applying learner 'regr.rpart' on task 'easy' (iter 7/18)
## INFO  [07:36:58.701] [mlr3] Applying learner 'regr.rpart' on task 'easy' (iter 8/18)
## INFO  [07:36:58.709] [mlr3] Applying learner 'regr.rpart' on task 'easy' (iter 9/18)
## INFO  [07:36:58.718] [mlr3] Applying learner 'regr.rpart' on task 'easy' (iter 10/18)
## INFO  [07:36:58.727] [mlr3] Applying learner 'regr.rpart' on task 'easy' (iter 11/18)
## INFO  [07:36:58.739] [mlr3] Applying learner 'regr.rpart' on task 'easy' (iter 12/18)
## INFO  [07:36:58.748] [mlr3] Applying learner 'regr.rpart' on task 'easy' (iter 13/18)
## INFO  [07:36:58.757] [mlr3] Applying learner 'regr.rpart' on task 'easy' (iter 14/18)
## INFO  [07:36:58.767] [mlr3] Applying learner 'regr.rpart' on task 'easy' (iter 15/18)
## INFO  [07:36:58.776] [mlr3] Applying learner 'regr.rpart' on task 'easy' (iter 16/18)
## INFO  [07:36:58.786] [mlr3] Applying learner 'regr.rpart' on task 'easy' (iter 17/18)
## INFO  [07:36:58.795] [mlr3] Applying learner 'regr.rpart' on task 'easy' (iter 18/18)
## INFO  [07:36:58.805] [mlr3] Applying learner 'regr.featureless' on task 'impossible' (iter 1/18)
## INFO  [07:36:58.813] [mlr3] Applying learner 'regr.featureless' on task 'impossible' (iter 2/18)
## INFO  [07:36:58.820] [mlr3] Applying learner 'regr.featureless' on task 'impossible' (iter 3/18)
## INFO  [07:36:58.831] [mlr3] Applying learner 'regr.featureless' on task 'impossible' (iter 4/18)
## INFO  [07:36:58.837] [mlr3] Applying learner 'regr.featureless' on task 'impossible' (iter 5/18)
## INFO  [07:36:58.843] [mlr3] Applying learner 'regr.featureless' on task 'impossible' (iter 6/18)
## INFO  [07:36:58.850] [mlr3] Applying learner 'regr.featureless' on task 'impossible' (iter 7/18)
## INFO  [07:36:58.857] [mlr3] Applying learner 'regr.featureless' on task 'impossible' (iter 8/18)
## INFO  [07:36:58.863] [mlr3] Applying learner 'regr.featureless' on task 'impossible' (iter 9/18)
## INFO  [07:36:58.869] [mlr3] Applying learner 'regr.featureless' on task 'impossible' (iter 10/18)
## INFO  [07:36:58.876] [mlr3] Applying learner 'regr.featureless' on task 'impossible' (iter 11/18)
## INFO  [07:36:58.883] [mlr3] Applying learner 'regr.featureless' on task 'impossible' (iter 12/18)
## INFO  [07:36:58.889] [mlr3] Applying learner 'regr.featureless' on task 'impossible' (iter 13/18)
## INFO  [07:36:58.895] [mlr3] Applying learner 'regr.featureless' on task 'impossible' (iter 14/18)
## INFO  [07:36:58.905] [mlr3] Applying learner 'regr.featureless' on task 'impossible' (iter 15/18)
## INFO  [07:36:58.912] [mlr3] Applying learner 'regr.featureless' on task 'impossible' (iter 16/18)
## INFO  [07:36:58.919] [mlr3] Applying learner 'regr.featureless' on task 'impossible' (iter 17/18)
## INFO  [07:36:58.925] [mlr3] Applying learner 'regr.featureless' on task 'impossible' (iter 18/18)
## INFO  [07:36:58.932] [mlr3] Applying learner 'regr.rpart' on task 'impossible' (iter 1/18)
## INFO  [07:36:58.940] [mlr3] Applying learner 'regr.rpart' on task 'impossible' (iter 2/18)
## INFO  [07:36:58.948] [mlr3] Applying learner 'regr.rpart' on task 'impossible' (iter 3/18)
## INFO  [07:36:58.957] [mlr3] Applying learner 'regr.rpart' on task 'impossible' (iter 4/18)
## INFO  [07:36:58.965] [mlr3] Applying learner 'regr.rpart' on task 'impossible' (iter 5/18)
## INFO  [07:36:58.974] [mlr3] Applying learner 'regr.rpart' on task 'impossible' (iter 6/18)
## INFO  [07:36:58.982] [mlr3] Applying learner 'regr.rpart' on task 'impossible' (iter 7/18)
## INFO  [07:36:58.994] [mlr3] Applying learner 'regr.rpart' on task 'impossible' (iter 8/18)
## INFO  [07:36:59.003] [mlr3] Applying learner 'regr.rpart' on task 'impossible' (iter 9/18)
## INFO  [07:36:59.011] [mlr3] Applying learner 'regr.rpart' on task 'impossible' (iter 10/18)
## INFO  [07:36:59.020] [mlr3] Applying learner 'regr.rpart' on task 'impossible' (iter 11/18)
## INFO  [07:36:59.028] [mlr3] Applying learner 'regr.rpart' on task 'impossible' (iter 12/18)
## INFO  [07:36:59.037] [mlr3] Applying learner 'regr.rpart' on task 'impossible' (iter 13/18)
## INFO  [07:36:59.045] [mlr3] Applying learner 'regr.rpart' on task 'impossible' (iter 14/18)
## INFO  [07:36:59.053] [mlr3] Applying learner 'regr.rpart' on task 'impossible' (iter 15/18)
## INFO  [07:36:59.062] [mlr3] Applying learner 'regr.rpart' on task 'impossible' (iter 16/18)
## INFO  [07:36:59.074] [mlr3] Applying learner 'regr.rpart' on task 'impossible' (iter 17/18)
## INFO  [07:36:59.082] [mlr3] Applying learner 'regr.rpart' on task 'impossible' (iter 18/18)
## INFO  [07:36:59.097] [mlr3] Finished benchmark
```

``` r
bench.score <- mlr3resampling::score(bench.result, mlr3::msr("regr.rmse"))
bench.score[, .(task_id, algorithm, train.subsets, test.fold, test.subset, regr.rmse)]
```

```
##        task_id   algorithm train.subsets test.fold test.subset regr.rmse
##         <char>      <char>        <char>     <int>      <fctr>     <num>
##  1:       easy featureless           all         1       Alice 0.8417981
##  2:       easy featureless           all         1         Bob 1.4748311
##  3:       easy featureless           all         2       Alice 1.3892457
##  4:       easy featureless           all         2         Bob 1.2916491
##  5:       easy featureless           all         3       Alice 1.1636785
##  6:       easy featureless           all         3         Bob 1.0491199
##  7:       easy featureless         other         1       Alice 0.8559209
##  8:       easy featureless         other         1         Bob 1.4567103
##  9:       easy featureless         other         2       Alice 1.3736439
## 10:       easy featureless         other         2         Bob 1.2943787
## 11:       easy featureless         other         3       Alice 1.1395756
## 12:       easy featureless         other         3         Bob 1.0899069
## 13:       easy featureless          same         1       Alice 0.8667528
## 14:       easy featureless          same         1         Bob 1.5148801
## 15:       easy featureless          same         2       Alice 1.4054366
## 16:       easy featureless          same         2         Bob 1.2897447
## 17:       easy featureless          same         3       Alice 1.1917033
## 18:       easy featureless          same         3         Bob 1.0118805
## 19:       easy       rpart           all         1       Alice 0.6483484
## 20:       easy       rpart           all         1         Bob 0.5780414
## 21:       easy       rpart           all         2       Alice 0.7737929
## 22:       easy       rpart           all         2         Bob 0.6693803
## 23:       easy       rpart           all         3       Alice 0.4360203
## 24:       easy       rpart           all         3         Bob 0.5599774
## 25:       easy       rpart         other         1       Alice 0.7000487
## 26:       easy       rpart         other         1         Bob 1.3295572
## 27:       easy       rpart         other         2       Alice 1.2688572
## 28:       easy       rpart         other         2         Bob 0.9847977
## 29:       easy       rpart         other         3       Alice 0.8686188
## 30:       easy       rpart         other         3         Bob 0.8957394
## 31:       easy       rpart          same         1       Alice 0.9762360
## 32:       easy       rpart          same         1         Bob 1.3404500
## 33:       easy       rpart          same         2       Alice 1.1213335
## 34:       easy       rpart          same         2         Bob 1.1853491
## 35:       easy       rpart          same         3       Alice 0.7931738
## 36:       easy       rpart          same         3         Bob 0.9980859
## 37: impossible featureless           all         1       Alice 1.8015752
## 38: impossible featureless           all         1         Bob 2.0459690
## 39: impossible featureless           all         2       Alice 1.9332069
## 40: impossible featureless           all         2         Bob 1.3513960
## 41: impossible featureless           all         3       Alice 1.4087384
## 42: impossible featureless           all         3         Bob 1.5117399
## 43: impossible featureless         other         1       Alice 2.7435334
## 44: impossible featureless         other         1         Bob 3.0650008
## 45: impossible featureless         other         2       Alice 3.0673372
## 46: impossible featureless         other         2         Bob 2.4200628
## 47: impossible featureless         other         3       Alice 2.5631614
## 48: impossible featureless         other         3         Bob 2.7134959
## 49: impossible featureless          same         1       Alice 1.1982239
## 50: impossible featureless          same         1         Bob 1.2037929
## 51: impossible featureless          same         2       Alice 1.2865945
## 52: impossible featureless          same         2         Bob 1.1769211
## 53: impossible featureless          same         3       Alice 1.0677617
## 54: impossible featureless          same         3         Bob 0.9738987
## 55: impossible       rpart           all         1       Alice 1.9942054
## 56: impossible       rpart           all         1         Bob 2.9047858
## 57: impossible       rpart           all         2       Alice 1.9339810
## 58: impossible       rpart           all         2         Bob 1.6467536
## 59: impossible       rpart           all         3       Alice 1.6622025
## 60: impossible       rpart           all         3         Bob 1.7632037
## 61: impossible       rpart         other         1       Alice 2.9498727
## 62: impossible       rpart         other         1         Bob 3.0738533
## 63: impossible       rpart         other         2       Alice 3.5994187
## 64: impossible       rpart         other         2         Bob 2.9526543
## 65: impossible       rpart         other         3       Alice 2.5892647
## 66: impossible       rpart         other         3         Bob 3.1410587
## 67: impossible       rpart          same         1       Alice 0.9056522
## 68: impossible       rpart          same         1         Bob 1.3881235
## 69: impossible       rpart          same         2       Alice 0.8927662
## 70: impossible       rpart          same         2         Bob 0.7149474
## 71: impossible       rpart          same         3       Alice 0.9229746
## 72: impossible       rpart          same         3         Bob 0.6295206
##        task_id   algorithm train.subsets test.fold test.subset regr.rmse
```

The table of scores above shows the root mean squared error for each
combination of task, algorithm, train subset, test fold, and test
subset. These error values are summarized in the visualization below.


``` r
bench.plist <- mlr3resampling::pvalue(bench.score)
plot(bench.plist)
```

![plot of chunk pvalue](/assets/img/2025-05-20-mlr3-targets/pvalue-1.png)

The figure above shows:

* in black, mean plus or minus standard deviation, for each
  combination of task, test subset, algorithm, and train subsets.
* in grey, P-values for differences between same/all and same/other
  (two-sided paired T-test).
  
## Porting to targets

To run the same computations using targets, we first loop over the
benchmark grid, and create a data table with one row per train/test split.


``` r
target_dt_list <- list()
for(bench_row in seq_along(bench.grid$resampling)){
  cv <- bench.grid$resampling[[bench_row]]
  cv$instantiate(bench.grid$task[[bench_row]])
  it_vec <- seq_len(cv$iters)
  target_dt_list[[bench_row]] <- data.table(bench_row, iteration=it_vec)
}
(target_dt <- rbindlist(target_dt_list))
```

```
##     bench_row iteration
##         <int>     <int>
##  1:         1         1
##  2:         1         2
##  3:         1         3
##  4:         1         4
##  5:         1         5
##  6:         1         6
##  7:         1         7
##  8:         1         8
##  9:         1         9
## 10:         1        10
## 11:         1        11
## 12:         1        12
## 13:         1        13
## 14:         1        14
## 15:         1        15
## 16:         1        16
## 17:         1        17
## 18:         1        18
## 19:         2         1
## 20:         2         2
## 21:         2         3
## 22:         2         4
## 23:         2         5
## 24:         2         6
## 25:         2         7
## 26:         2         8
## 27:         2         9
## 28:         2        10
## 29:         2        11
## 30:         2        12
## 31:         2        13
## 32:         2        14
## 33:         2        15
## 34:         2        16
## 35:         2        17
## 36:         2        18
## 37:         3         1
## 38:         3         2
## 39:         3         3
## 40:         3         4
## 41:         3         5
## 42:         3         6
## 43:         3         7
## 44:         3         8
## 45:         3         9
## 46:         3        10
## 47:         3        11
## 48:         3        12
## 49:         3        13
## 50:         3        14
## 51:         3        15
## 52:         3        16
## 53:         3        17
## 54:         3        18
## 55:         4         1
## 56:         4         2
## 57:         4         3
## 58:         4         4
## 59:         4         5
## 60:         4         6
## 61:         4         7
## 62:         4         8
## 63:         4         9
## 64:         4        10
## 65:         4        11
## 66:         4        12
## 67:         4        13
## 68:         4        14
## 69:         4        15
## 70:         4        16
## 71:         4        17
## 72:         4        18
##     bench_row iteration
```

In the output above, `bench_row` is the row number of the benchmark
grid table, and `iteration` is the row number in the corresponding
instantiated resampling. To use these data with targets, we first
define a compute function.


``` r
compute <- function(target_num){
  ##library(data.table)
  target_row <- target_dt[target_num]
  it.dt <- bench.grid$resampling[[target_row$bench_row]]$instance$iteration.dt
  L <- bench.grid$learner[[target_row$bench_row]]
  this_task <- bench.grid$task[[target_row$bench_row]]
  set_rows <- function(set_name)it.dt[[set_name]][[target_row$iteration]]
  L$train(this_task, set_rows("train"))
  pred <- L$predict(this_task, set_rows("test"))
  it.dt[target_row$iteration, .(
    task_id=this_task$id, algorithm=sub("regr.","",L$id),
    train.subsets, test.fold, test.subset, 
    ##groups, seed, n.train.groups,
    regr.rmse=pred$score(mlr3::msrs("regr.rmse")))]
}
compute(1)
```

```
##    task_id   algorithm train.subsets test.fold test.subset regr.rmse
##     <char>      <char>        <char>     <int>      <fctr>     <num>
## 1:    easy featureless           all         1       Alice 0.9907855
```

``` r
compute(2)
```

```
##    task_id   algorithm train.subsets test.fold test.subset regr.rmse
##     <char>      <char>        <char>     <int>      <fctr>     <num>
## 1:    easy featureless           all         1         Bob  1.300868
```

We then save the data and function to a file on disk.


``` r
save(target_dt, bench.grid, compute, file="2025-05-20-mlr3-targets-in.RData")
```

Then we create a tar script which begins by reading the data, and ends
with a list of targets.


``` r
targets::tar_script({
  load("2025-05-20-mlr3-targets-in.RData")
  job_targs <- tarchetypes::tar_map(
    list(target_num=seq_len(nrow(target_dt))),
    targets::tar_target(result, compute(target_num)))
  list(
    tarchetypes::tar_combine(combine, job_targs, command=rbind(!!!.x)),
    job_targs)
}, ask=FALSE)
```

The trick in the code above is the use of two functions:

* `tar_map()` creates a target for each value of `target_num`, saving the list of targets to `job_targs`.
* `tar_combine()` creates a target that depends on all of the targets in the `job_targs` list.

The code below computes the results.


``` r
if(FALSE){
  targets::tar_manifest()
  targets::tar_visnetwork()
}
targets::tar_make()
```

```
## + result_70 dispatched
## ✔ result_70 completed [44ms, 283 B]
## + result_48 dispatched
## ✔ result_48 completed [143ms, 285 B]
## + result_71 dispatched
## ✔ result_71 completed [12ms, 279 B]
## + result_49 dispatched
## ✔ result_49 completed [10ms, 282 B]
## + result_72 dispatched
## ✔ result_72 completed [12ms, 282 B]
## + result_1 dispatched
## ✔ result_1 completed [8ms, 280 B]
## + result_10 dispatched
## ✔ result_10 completed [8ms, 281 B]
## + result_11 dispatched
## ✔ result_11 completed [8ms, 283 B]
## + result_12 dispatched
## ✔ result_12 completed [8ms, 278 B]
## + result_13 dispatched
## ✔ result_13 completed [9ms, 280 B]
## + result_14 dispatched
## ✔ result_14 completed [8ms, 282 B]
## + result_15 dispatched
## ✔ result_15 completed [8ms, 280 B]
## + result_16 dispatched
## ✔ result_16 completed [12ms, 279 B]
## + result_17 dispatched
## ✔ result_17 completed [8ms, 282 B]
## + result_18 dispatched
## ✔ result_18 completed [8ms, 281 B]
## + result_19 dispatched
## ✔ result_19 completed [10ms, 277 B]
## + result_2 dispatched
## ✔ result_2 completed [8ms, 280 B]
## + result_20 dispatched
## ✔ result_20 completed [11ms, 277 B]
## + result_21 dispatched
## ✔ result_21 completed [11ms, 278 B]
## + result_22 dispatched
## ✔ result_22 completed [14ms, 274 B]
## + result_23 dispatched
## ✔ result_23 completed [11ms, 278 B]
## + result_24 dispatched
## ✔ result_24 completed [10ms, 278 B]
## + result_25 dispatched
## ✔ result_25 completed [11ms, 277 B]
## + result_26 dispatched
## ✔ result_26 completed [9ms, 280 B]
## + result_27 dispatched
## ✔ result_27 completed [10ms, 277 B]
## + result_28 dispatched
## ✔ result_28 completed [10ms, 275 B]
## + result_29 dispatched
## ✔ result_29 completed [14ms, 276 B]
## + result_3 dispatched
## ✔ result_3 completed [8ms, 278 B]
## + result_30 dispatched
## ✔ result_30 completed [9ms, 278 B]
## + result_31 dispatched
## ✔ result_31 completed [10ms, 275 B]
## + result_32 dispatched
## ✔ result_32 completed [10ms, 277 B]
## + result_33 dispatched
## ✔ result_33 completed [9ms, 282 B]
## + result_34 dispatched
## ✔ result_34 completed [9ms, 279 B]
## + result_35 dispatched
## ✔ result_35 completed [13ms, 279 B]
## + result_36 dispatched
## ✔ result_36 completed [10ms, 279 B]
## + result_37 dispatched
## ✔ result_37 completed [8ms, 282 B]
## + result_38 dispatched
## ✔ result_38 completed [8ms, 280 B]
## + result_39 dispatched
## ✔ result_39 completed [8ms, 284 B]
## + result_4 dispatched
## ✔ result_4 completed [8ms, 279 B]
## + result_40 dispatched
## ✔ result_40 completed [8ms, 283 B]
## + result_41 dispatched
## ✔ result_41 completed [12ms, 283 B]
## + result_42 dispatched
## ✔ result_42 completed [8ms, 286 B]
## + result_43 dispatched
## ✔ result_43 completed [8ms, 280 B]
## + result_44 dispatched
## ✔ result_44 completed [7ms, 285 B]
## + result_45 dispatched
## ✔ result_45 completed [8ms, 286 B]
## + result_46 dispatched
## ✔ result_46 completed [8ms, 284 B]
## + result_47 dispatched
## ✔ result_47 completed [7ms, 283 B]
## + result_5 dispatched
## ✔ result_5 completed [8ms, 279 B]
## + result_50 dispatched
## ✔ result_50 completed [8ms, 285 B]
## + result_51 dispatched
## ✔ result_51 completed [8ms, 285 B]
## + result_52 dispatched
## ✔ result_52 completed [8ms, 287 B]
## + result_53 dispatched
## ✔ result_53 completed [8ms, 287 B]
## + result_54 dispatched
## ✔ result_54 completed [8ms, 285 B]
## + result_55 dispatched
## ✔ result_55 completed [10ms, 279 B]
## + result_56 dispatched
## ✔ result_56 completed [10ms, 278 B]
## + result_57 dispatched
## ✔ result_57 completed [13ms, 278 B]
## + result_58 dispatched
## ✔ result_58 completed [11ms, 281 B]
## + result_59 dispatched
## ✔ result_59 completed [10ms, 281 B]
## + result_6 dispatched
## ✔ result_6 completed [7ms, 283 B]
## + result_60 dispatched
## ✔ result_60 completed [10ms, 281 B]
## + result_61 dispatched
## ✔ result_61 completed [10ms, 280 B]
## + result_62 dispatched
## ✔ result_62 completed [10ms, 282 B]
## + result_63 dispatched
## ✔ result_63 completed [10ms, 283 B]
## + result_64 dispatched
## ✔ result_64 completed [10ms, 280 B]
## + result_65 dispatched
## ✔ result_65 completed [10ms, 277 B]
## + result_66 dispatched
## ✔ result_66 completed [10ms, 281 B]
## + result_67 dispatched
## ✔ result_67 completed [10ms, 282 B]
## + result_68 dispatched
## ✔ result_68 completed [10ms, 285 B]
## + result_69 dispatched
## ✔ result_69 completed [14ms, 282 B]
## + result_7 dispatched
## ✔ result_7 completed [8ms, 282 B]
## + result_8 dispatched
## ✔ result_8 completed [9ms, 281 B]
## + result_9 dispatched
## ✔ result_9 completed [8ms, 279 B]
## + combine dispatched
## ✔ combine completed [0ms, 992 B]
## ✔ ended pipeline [1.4s, 73 completed, 0 skipped]
```

``` r
(tar_score_dt <- targets::tar_read(combine))
```

```
##        task_id   algorithm train.subsets test.fold test.subset regr.rmse
##         <char>      <char>        <char>     <int>      <fctr>     <num>
##  1:       easy featureless           all         1       Alice 0.9907855
##  2:       easy featureless           all         1         Bob 1.3008678
##  3:       easy featureless           all         2       Alice 0.9543573
##  4:       easy featureless           all         2         Bob 1.3303316
##  5:       easy featureless           all         3       Alice 1.3635807
##  6:       easy featureless           all         3         Bob 1.2370617
##  7:       easy featureless         other         1       Alice 0.9914137
##  8:       easy featureless         other         1         Bob 1.2762933
##  9:       easy featureless         other         2       Alice 0.9832029
## 10:       easy featureless         other         2         Bob 1.3212197
## 11:       easy featureless         other         3       Alice 1.3653704
## 12:       easy featureless         other         3         Bob 1.2055645
## 13:       easy featureless          same         1       Alice 1.0329491
## 14:       easy featureless          same         1         Bob 1.3572628
## 15:       easy featureless          same         2       Alice 0.9302700
## 16:       easy featureless          same         2         Bob 1.3432935
## 17:       easy featureless          same         3       Alice 1.3642008
## 18:       easy featureless          same         3         Bob 1.2703672
## 19:       easy       rpart           all         1       Alice 0.4311639
## 20:       easy       rpart           all         1         Bob 0.6687888
## 21:       easy       rpart           all         2       Alice 0.8491932
## 22:       easy       rpart           all         2         Bob 0.5917313
## 23:       easy       rpart           all         3       Alice 0.5898475
## 24:       easy       rpart           all         3         Bob 0.4972741
## 25:       easy       rpart         other         1       Alice 0.8816927
## 26:       easy       rpart         other         1         Bob 1.0974634
## 27:       easy       rpart         other         2       Alice 0.8300939
## 28:       easy       rpart         other         2         Bob 0.9037082
## 29:       easy       rpart         other         3       Alice 1.1442886
## 30:       easy       rpart         other         3         Bob 0.6604022
## 31:       easy       rpart          same         1       Alice 0.8544508
## 32:       easy       rpart          same         1         Bob 1.1207956
## 33:       easy       rpart          same         2       Alice 0.6105662
## 34:       easy       rpart          same         2         Bob 1.3054000
## 35:       easy       rpart          same         3       Alice 0.9651013
## 36:       easy       rpart          same         3         Bob 1.0334799
## 37: impossible featureless           all         1       Alice 1.9454542
## 38: impossible featureless           all         1         Bob 2.1334055
## 39: impossible featureless           all         2       Alice 1.7045394
## 40: impossible featureless           all         2         Bob 1.1520164
## 41: impossible featureless           all         3       Alice 1.4892815
## 42: impossible featureless           all         3         Bob 1.5684921
## 43: impossible featureless         other         1       Alice 2.7995421
## 44: impossible featureless         other         1         Bob 3.1692606
## 45: impossible featureless         other         2       Alice 2.9193144
## 46: impossible featureless         other         2         Bob 2.3225307
## 47: impossible featureless         other         3       Alice 2.6808761
## 48: impossible featureless         other         3         Bob 2.6837346
## 49: impossible featureless          same         1       Alice 1.5196359
## 50: impossible featureless          same         1         Bob 1.2789725
## 51: impossible featureless          same         2       Alice 0.9755388
## 52: impossible featureless          same         2         Bob 0.9608841
## 53: impossible featureless          same         3       Alice 0.8906583
## 54: impossible featureless          same         3         Bob 1.1235452
## 55: impossible       rpart           all         1       Alice 1.6741137
## 56: impossible       rpart           all         1         Bob 2.3836980
## 57: impossible       rpart           all         2       Alice 1.8404374
## 58: impossible       rpart           all         2         Bob 0.8826633
## 59: impossible       rpart           all         3       Alice 1.6903242
## 60: impossible       rpart           all         3         Bob 1.7301464
## 61: impossible       rpart         other         1       Alice 3.0262472
## 62: impossible       rpart         other         1         Bob 3.3728469
## 63: impossible       rpart         other         2       Alice 2.9450909
## 64: impossible       rpart         other         2         Bob 2.4264216
## 65: impossible       rpart         other         3       Alice 2.7310131
## 66: impossible       rpart         other         3         Bob 3.1240620
## 67: impossible       rpart          same         1       Alice 1.2828829
## 68: impossible       rpart          same         1         Bob 1.1630270
## 69: impossible       rpart          same         2       Alice 0.7275858
## 70: impossible       rpart          same         2         Bob 0.4470869
## 71: impossible       rpart          same         3       Alice 0.9512479
## 72: impossible       rpart          same         3         Bob 1.0282527
##        task_id   algorithm train.subsets test.fold test.subset regr.rmse
```

The table above shows the test error, and the code below plots it.


``` r
tar_pval_list <- mlr3resampling::pvalue(tar_score_dt)
plot(tar_pval_list)
```

![plot of chunk tar-pval](/assets/img/2025-05-20-mlr3-targets/tar-pval-1.png)

The result figure above is consistent with the result figure that was
computed with the usual mlr3 benchmark function.

## Dynamic targets

Next, we implement [dynamic
branching](https://books.ropensci.org/targets/dynamic.html#branching),
which is apparently faster for lots of branches.


``` r
targets::tar_script({
  load("2025-05-20-mlr3-targets-in.RData")
  list(
    targets::tar_target(target_num, seq_len(nrow(target_dt))),
    targets::tar_target(result, compute(target_num), pattern=map(target_num)))
}, ask=FALSE)
```

The code above uses `map(target_num)` to create a different result for
each value of `target_num`, which is combined together into a single
result table, computed and shown below.


``` r
targets::tar_make()
```

```
## + result declared [72 branches]
## ✔ result completed [873ms, 20.21 kB]
## ✔ ended pipeline [1.1s, 72 completed, 1 skipped]
```

``` r
(dyn_score_dt <- targets::tar_read(result))
```

```
##        task_id   algorithm train.subsets test.fold test.subset regr.rmse
##         <char>      <char>        <char>     <int>      <fctr>     <num>
##  1:       easy featureless           all         1       Alice 0.9907855
##  2:       easy featureless           all         1         Bob 1.3008678
##  3:       easy featureless           all         2       Alice 0.9543573
##  4:       easy featureless           all         2         Bob 1.3303316
##  5:       easy featureless           all         3       Alice 1.3635807
##  6:       easy featureless           all         3         Bob 1.2370617
##  7:       easy featureless         other         1       Alice 0.9914137
##  8:       easy featureless         other         1         Bob 1.2762933
##  9:       easy featureless         other         2       Alice 0.9832029
## 10:       easy featureless         other         2         Bob 1.3212197
## 11:       easy featureless         other         3       Alice 1.3653704
## 12:       easy featureless         other         3         Bob 1.2055645
## 13:       easy featureless          same         1       Alice 1.0329491
## 14:       easy featureless          same         1         Bob 1.3572628
## 15:       easy featureless          same         2       Alice 0.9302700
## 16:       easy featureless          same         2         Bob 1.3432935
## 17:       easy featureless          same         3       Alice 1.3642008
## 18:       easy featureless          same         3         Bob 1.2703672
## 19:       easy       rpart           all         1       Alice 0.4311639
## 20:       easy       rpart           all         1         Bob 0.6687888
## 21:       easy       rpart           all         2       Alice 0.8491932
## 22:       easy       rpart           all         2         Bob 0.5917313
## 23:       easy       rpart           all         3       Alice 0.5898475
## 24:       easy       rpart           all         3         Bob 0.4972741
## 25:       easy       rpart         other         1       Alice 0.8816927
## 26:       easy       rpart         other         1         Bob 1.0974634
## 27:       easy       rpart         other         2       Alice 0.8300939
## 28:       easy       rpart         other         2         Bob 0.9037082
## 29:       easy       rpart         other         3       Alice 1.1442886
## 30:       easy       rpart         other         3         Bob 0.6604022
## 31:       easy       rpart          same         1       Alice 0.8544508
## 32:       easy       rpart          same         1         Bob 1.1207956
## 33:       easy       rpart          same         2       Alice 0.6105662
## 34:       easy       rpart          same         2         Bob 1.3054000
## 35:       easy       rpart          same         3       Alice 0.9651013
## 36:       easy       rpart          same         3         Bob 1.0334799
## 37: impossible featureless           all         1       Alice 1.9454542
## 38: impossible featureless           all         1         Bob 2.1334055
## 39: impossible featureless           all         2       Alice 1.7045394
## 40: impossible featureless           all         2         Bob 1.1520164
## 41: impossible featureless           all         3       Alice 1.4892815
## 42: impossible featureless           all         3         Bob 1.5684921
## 43: impossible featureless         other         1       Alice 2.7995421
## 44: impossible featureless         other         1         Bob 3.1692606
## 45: impossible featureless         other         2       Alice 2.9193144
## 46: impossible featureless         other         2         Bob 2.3225307
## 47: impossible featureless         other         3       Alice 2.6808761
## 48: impossible featureless         other         3         Bob 2.6837346
## 49: impossible featureless          same         1       Alice 1.5196359
## 50: impossible featureless          same         1         Bob 1.2789725
## 51: impossible featureless          same         2       Alice 0.9755388
## 52: impossible featureless          same         2         Bob 0.9608841
## 53: impossible featureless          same         3       Alice 0.8906583
## 54: impossible featureless          same         3         Bob 1.1235452
## 55: impossible       rpart           all         1       Alice 1.6741137
## 56: impossible       rpart           all         1         Bob 2.3836980
## 57: impossible       rpart           all         2       Alice 1.8404374
## 58: impossible       rpart           all         2         Bob 0.8826633
## 59: impossible       rpart           all         3       Alice 1.6903242
## 60: impossible       rpart           all         3         Bob 1.7301464
## 61: impossible       rpart         other         1       Alice 3.0262472
## 62: impossible       rpart         other         1         Bob 3.3728469
## 63: impossible       rpart         other         2       Alice 2.9450909
## 64: impossible       rpart         other         2         Bob 2.4264216
## 65: impossible       rpart         other         3       Alice 2.7310131
## 66: impossible       rpart         other         3         Bob 3.1240620
## 67: impossible       rpart          same         1       Alice 1.2828829
## 68: impossible       rpart          same         1         Bob 1.1630270
## 69: impossible       rpart          same         2       Alice 0.7275858
## 70: impossible       rpart          same         2         Bob 0.4470869
## 71: impossible       rpart          same         3       Alice 0.9512479
## 72: impossible       rpart          same         3         Bob 1.0282527
##        task_id   algorithm train.subsets test.fold test.subset regr.rmse
```

The table above shows the test error for each train/test split, which
we can visualize via the code below.


``` r
dyn_pval_list <- mlr3resampling::pvalue(dyn_score_dt)
plot(dyn_pval_list)
```

![plot of chunk dyn-pval](/assets/img/2025-05-20-mlr3-targets/dyn-pval-1.png)

The graphics above are consistent with the previous result plots.

## How does it work?

When you run `tar_make()`, files are created:


``` r
dir("_targets/objects/")
```

```
##   [1] "combine"                 "result_048013f7868011a2" "result_069f3e315217e27e" "result_06fbe6983d495e3e"
##   [5] "result_08182d7c2dd20ec3" "result_0a7ef7123d5dabba" "result_0ce4e0f358d155c2" "result_0cfba70ed70981ba"
##   [9] "result_1"                "result_10"               "result_11"               "result_112b8e8eb7cb2258"
##  [13] "result_12"               "result_13"               "result_14"               "result_15"              
##  [17] "result_16"               "result_17"               "result_18"               "result_19"              
##  [21] "result_19d8739f61397012" "result_1ad069a12018aded" "result_2"                "result_20"              
##  [25] "result_21"               "result_217edb41f1e1082c" "result_22"               "result_23"              
##  [29] "result_230c1adef6729d2a" "result_24"               "result_25"               "result_26"              
##  [33] "result_2642222ace1a8999" "result_26eea39b7d448957" "result_27"               "result_28"              
##  [37] "result_29"               "result_3"                "result_30"               "result_30ad7aaf16e0425c"
##  [41] "result_31"               "result_32"               "result_33"               "result_3335271ef176ee7d"
##  [45] "result_33fd60fe0ca79d55" "result_34"               "result_35"               "result_36"              
##  [49] "result_362cf35358864bd2" "result_37"               "result_374540b1e56f7c86" "result_38"              
##  [53] "result_3810136c1e7ea9dd" "result_39"               "result_4"                "result_40"              
##  [57] "result_41"               "result_42"               "result_42c258fc60339ee0" "result_43"              
##  [61] "result_44"               "result_44073cf47ef7b79b" "result_45"               "result_46"              
##  [65] "result_47"               "result_48"               "result_49"               "result_4ce971cae9ec41b0"
##  [69] "result_4ea130c79d8b0145" "result_5"                "result_50"               "result_505a84845a98b49f"
##  [73] "result_51"               "result_52"               "result_52403ac3c08f16b1" "result_53"              
##  [77] "result_54"               "result_55"               "result_56"               "result_57"              
##  [81] "result_58"               "result_59"               "result_5988fa8b2158f568" "result_6"               
##  [85] "result_60"               "result_61"               "result_62"               "result_629197c9dbf038d8"
##  [89] "result_63"               "result_64"               "result_65"               "result_66"              
##  [93] "result_67"               "result_67a6334df4f3cb9f" "result_68"               "result_680cea198cec81c9"
##  [97] "result_69"               "result_6c441d6a6c30445c" "result_6f306d25112dfefc" "result_7"               
## [101] "result_70"               "result_71"               "result_72"               "result_782c1e65d42fbd5e"
## [105] "result_7b9e20e914e1fb61" "result_8"                "result_816e13c2c98b9e18" "result_87f744b85f5dad72"
## [109] "result_89798851f17c5680" "result_9"                "result_93d076702b1a583c" "result_96d566b82b926d0d"
## [113] "result_9923d497ceb6b102" "result_9cf4fd39c387e4e3" "result_a0ff5af59f312179" "result_a32afd757f23673e"
## [117] "result_a33abcbd8b6c98fe" "result_a61ff9d7312ea260" "result_a68d3652aca4719a" "result_acfa949b32418563"
## [121] "result_b374702926094bb2" "result_b5e4139f56b67a58" "result_b742ae4f7df7cfde" "result_b919058f1fbddce3"
## [125] "result_ba6896f8e7742065" "result_bd433e7b7c989d62" "result_c02d2c95a677f106" "result_c3deea6fa5e4df56"
## [129] "result_c5163c701caa8d22" "result_c657ea0162b77a47" "result_c99aa5d7bf7eeae2" "result_cb00ccc443f5e8a0"
## [133] "result_cc60dd0ed08ff3b4" "result_ddb5f7dce171b8bc" "result_e4e1e52a9ba31254" "result_e5ce627ae4f143c5"
## [137] "result_e67ea3f6d2a3af5a" "result_e880aeaa6145c3a9" "result_f03929ed35b91f56" "result_f28570d89c20d11c"
## [141] "result_f532d44d01f4b505" "result_f8604114a575a8a2" "result_fba9b281047808f0" "result_fbe65e427b1c0cdb"
## [145] "result_fd387e0d10c90edf" "target_num"
```

Each target has a corresponding file.

## How to run in parallel?

To run targets in parallel, you can use `tar_option_set(controller=)`
some crew controller, as explained on the [Distributed computing
page](https://books.ropensci.org/targets/crew.html). Below we use a
local crew of 2 workers.


``` r
unlink("_targets", recursive = TRUE)
targets::tar_script({
  tar_option_set(controller = crew::crew_controller_local(workers = 2))
  load("2025-05-20-mlr3-targets-in.RData")
  list(
    targets::tar_target(target_num, seq_len(nrow(target_dt))),
    targets::tar_target(result, compute(target_num), pattern=map(target_num)))
}, ask=FALSE)
targets::tar_make()
```

```
## + target_num dispatched
## ✔ target_num completed [5ms, 97 B]
## + result declared [72 branches]
## ✔ result completed [1.5s, 20.21 kB]
## ✔ ended pipeline [3.4s, 73 completed, 0 skipped]
```

``` r
targets::tar_read(result)
```

```
##        task_id   algorithm train.subsets test.fold test.subset regr.rmse
##         <char>      <char>        <char>     <int>      <fctr>     <num>
##  1:       easy featureless           all         1       Alice 0.9907855
##  2:       easy featureless           all         1         Bob 1.3008678
##  3:       easy featureless           all         2       Alice 0.9543573
##  4:       easy featureless           all         2         Bob 1.3303316
##  5:       easy featureless           all         3       Alice 1.3635807
##  6:       easy featureless           all         3         Bob 1.2370617
##  7:       easy featureless         other         1       Alice 0.9914137
##  8:       easy featureless         other         1         Bob 1.2762933
##  9:       easy featureless         other         2       Alice 0.9832029
## 10:       easy featureless         other         2         Bob 1.3212197
## 11:       easy featureless         other         3       Alice 1.3653704
## 12:       easy featureless         other         3         Bob 1.2055645
## 13:       easy featureless          same         1       Alice 1.0329491
## 14:       easy featureless          same         1         Bob 1.3572628
## 15:       easy featureless          same         2       Alice 0.9302700
## 16:       easy featureless          same         2         Bob 1.3432935
## 17:       easy featureless          same         3       Alice 1.3642008
## 18:       easy featureless          same         3         Bob 1.2703672
## 19:       easy       rpart           all         1       Alice 0.4311639
## 20:       easy       rpart           all         1         Bob 0.6687888
## 21:       easy       rpart           all         2       Alice 0.8491932
## 22:       easy       rpart           all         2         Bob 0.5917313
## 23:       easy       rpart           all         3       Alice 0.5898475
## 24:       easy       rpart           all         3         Bob 0.4972741
## 25:       easy       rpart         other         1       Alice 0.8816927
## 26:       easy       rpart         other         1         Bob 1.0974634
## 27:       easy       rpart         other         2       Alice 0.8300939
## 28:       easy       rpart         other         2         Bob 0.9037082
## 29:       easy       rpart         other         3       Alice 1.1442886
## 30:       easy       rpart         other         3         Bob 0.6604022
## 31:       easy       rpart          same         1       Alice 0.8544508
## 32:       easy       rpart          same         1         Bob 1.1207956
## 33:       easy       rpart          same         2       Alice 0.6105662
## 34:       easy       rpart          same         2         Bob 1.3054000
## 35:       easy       rpart          same         3       Alice 0.9651013
## 36:       easy       rpart          same         3         Bob 1.0334799
## 37: impossible featureless           all         1       Alice 1.9454542
## 38: impossible featureless           all         1         Bob 2.1334055
## 39: impossible featureless           all         2       Alice 1.7045394
## 40: impossible featureless           all         2         Bob 1.1520164
## 41: impossible featureless           all         3       Alice 1.4892815
## 42: impossible featureless           all         3         Bob 1.5684921
## 43: impossible featureless         other         1       Alice 2.7995421
## 44: impossible featureless         other         1         Bob 3.1692606
## 45: impossible featureless         other         2       Alice 2.9193144
## 46: impossible featureless         other         2         Bob 2.3225307
## 47: impossible featureless         other         3       Alice 2.6808761
## 48: impossible featureless         other         3         Bob 2.6837346
## 49: impossible featureless          same         1       Alice 1.5196359
## 50: impossible featureless          same         1         Bob 1.2789725
## 51: impossible featureless          same         2       Alice 0.9755388
## 52: impossible featureless          same         2         Bob 0.9608841
## 53: impossible featureless          same         3       Alice 0.8906583
## 54: impossible featureless          same         3         Bob 1.1235452
## 55: impossible       rpart           all         1       Alice 1.6741137
## 56: impossible       rpart           all         1         Bob 2.3836980
## 57: impossible       rpart           all         2       Alice 1.8404374
## 58: impossible       rpart           all         2         Bob 0.8826633
## 59: impossible       rpart           all         3       Alice 1.6903242
## 60: impossible       rpart           all         3         Bob 1.7301464
## 61: impossible       rpart         other         1       Alice 3.0262472
## 62: impossible       rpart         other         1         Bob 3.3728469
## 63: impossible       rpart         other         2       Alice 2.9450909
## 64: impossible       rpart         other         2         Bob 2.4264216
## 65: impossible       rpart         other         3       Alice 2.7310131
## 66: impossible       rpart         other         3         Bob 3.1240620
## 67: impossible       rpart          same         1       Alice 1.2828829
## 68: impossible       rpart          same         1         Bob 1.1630270
## 69: impossible       rpart          same         2       Alice 0.7275858
## 70: impossible       rpart          same         2         Bob 0.4470869
## 71: impossible       rpart          same         3       Alice 0.9512479
## 72: impossible       rpart          same         3         Bob 1.0282527
##        task_id   algorithm train.subsets test.fold test.subset regr.rmse
```

Above we see that the same result table has been computed in parallel.

## Conclusions

We can use `targets` to declare and compute machine learning benchmark
experiments in parallel. Next steps will be to verify if this approach
works for larger experiments on the SLURM compute cluster, with
different sized data sets, and algorithms with different run-times.

## Session info


``` r
sessionInfo()
```

```
## R version 4.5.0 (2025-04-11)
## Platform: x86_64-pc-linux-gnu
## Running under: Ubuntu 24.04.2 LTS
## 
## Matrix products: default
## BLAS:   /usr/lib/x86_64-linux-gnu/blas/libblas.so.3.12.0 
## LAPACK: /usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.12.0  LAPACK version 3.12.0
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
## [1] stats     graphics  grDevices datasets  utils     methods   base     
## 
## other attached packages:
## [1] mlr3resampling_2025.3.30 mlr3_0.23.0              future_1.49.0            ggplot2_3.5.2           
## [5] data.table_1.17.2       
## 
## loaded via a namespace (and not attached):
##  [1] base64url_1.4        gtable_0.3.6         future.apply_1.11.3  dplyr_1.1.4          compiler_4.5.0      
##  [6] crayon_1.5.3         rpart_4.1.24         tidyselect_1.2.1     bspm_0.5.7           parallel_4.5.0      
## [11] dichromat_2.0-0.1    callr_3.7.6          globals_0.18.0       scales_1.4.0         yaml_2.3.10         
## [16] uuid_1.2-1           R6_2.6.1             labeling_0.4.3       generics_0.1.4       igraph_2.1.4        
## [21] knitr_1.50           targets_1.11.3       palmerpenguins_0.1.1 backports_1.5.0      checkmate_2.3.2     
## [26] tibble_3.2.1         paradox_1.0.1        pillar_1.10.2        RColorBrewer_1.1-3   mlr3measures_1.0.0  
## [31] rlang_1.1.6          xfun_0.52            lgr_0.4.4            mlr3misc_0.17.0      cli_3.6.5           
## [36] withr_3.0.2          magrittr_2.0.3       ps_1.9.1             processx_3.8.6       digest_0.6.37       
## [41] grid_4.5.0           rstudioapi_0.17.1    secretbase_1.0.5     lifecycle_1.0.4      prettyunits_1.2.0   
## [46] vctrs_0.6.5          evaluate_1.0.3       glue_1.8.0           farver_2.1.2         listenv_0.9.1       
## [51] codetools_0.2-20     parallelly_1.44.0    tools_4.5.0          pkgconfig_2.0.3
```
