---
layout: post
title: When is it useful to train with combined groups?
description: An exploration using cross-validation
---



The goal of this blog post is to explore machine learning in the
context of relatively small data, which may not be large enough
(relative to the strength of the signal) to learn the pattern. In that
case, we may wish to combine our small data set with another data set,
to see if the learning algorithm works better.  For example, in a
collaboration with Bruce Hungate and Jeff Propster of NAU ECOSS, we
have several qSIP data sets (quantitative Stable Isotope Probing),
from different experiments/sites/etc, and we would like to know if we
can combine them, and learn a more accurate model, than if we learned
separate models for each group. Here we explore what kinds of data
could result in better learning, when we combine data sets.

## Simulation

In [a previous
blog](https://tdhock.github.io/blog/2023/variable-size-train/) we
explained how to use `mlr3resampling::ResamplingVariableSizeTrain`,
with simulated regression problems. Here we adapt one of those
simulations, of data with one feature and and output/label with a sin
pattern.


```r
N <- 300
abs.x <- 20
set.seed(1)
x.vec <- runif(N, -abs.x, abs.x)
str(x.vec)
```

```
##  num [1:300] -9.38 -5.12 2.91 16.33 -11.93 ...
```

```r
library(data.table)
(task.dt <- data.table(
  x=x.vec,
  y = sin(x.vec)+rnorm(N,sd=0.5)))
```

```
##               x           y
##   1:  -9.379653  0.17998438
##   2:  -5.115044  0.91074391
##   3:   2.914135  0.06646766
##   4:  16.328312 -1.04599970
##   5: -11.932723 -0.15164176
##  ---                       
## 296:   7.257701 -0.67659452
## 297: -16.033236 -0.36348886
## 298: -15.243898 -0.65963855
## 299: -17.982414  0.88088493
## 300:  17.170157 -2.16547007
```

```r
reg.task <- mlr3::TaskRegr$new(
  "sin", task.dt, target="y"
)
library(animint2)
ggplot()+
  geom_point(aes(
    x, y),
    shape=1,
    data=task.dt)
```

![plot of chunk simulationScatter](/assets/img/2024-01-26-when-is-all-better-than-same/simulationScatter-1.png)

Above we see a scatterplot of the simulated data. The goal of the
learning algorithm will be to predict y from x.

### Visualizing test error as a function of train set size

In the code below, we define a K-fold cross-validation experiment,
with K=2 folds.


```r
reg_size_cv <- mlr3resampling::ResamplingVariableSizeTrainCV$new()
reg_size_cv$param_set$values$train_sizes <- 20
reg_size_cv$param_set$values$folds <- 2
(reg.learner.list <- list(
  if(requireNamespace("rpart"))mlr3::LearnerRegrRpart$new(),
  mlr3::LearnerRegrFeatureless$new()))
```

```
## [[1]]
## <LearnerRegrRpart:regr.rpart>: Regression Tree
## * Model: -
## * Parameters: xval=0
## * Packages: mlr3, rpart
## * Predict Types:  [response]
## * Feature Types: logical, integer, numeric, factor, ordered
## * Properties: importance, missings, selected_features, weights
## 
## [[2]]
## <LearnerRegrFeatureless:regr.featureless>: Featureless Regression Learner
## * Model: -
## * Parameters: robust=FALSE
## * Packages: mlr3, stats
## * Predict Types:  [response], se
## * Feature Types: logical, integer, numeric, character, factor, ordered, POSIXct
## * Properties: featureless, importance, missings, selected_features
```

```r
(reg.bench.grid <- mlr3::benchmark_grid(
  reg.task,
  reg.learner.list,
  reg_size_cv))
```

```
##    task          learner             resampling
## 1:  sin       regr.rpart variable_size_train_cv
## 2:  sin regr.featureless variable_size_train_cv
```

```r
if(require(future))plan("multisession")
lgr::get_logger("mlr3")$set_threshold("warn")
(reg.bench.result <- mlr3::benchmark(
  reg.bench.grid, store_models = TRUE))
```

```
## <BenchmarkResult> of 240 rows with 2 resampling runs
##  nr task_id       learner_id          resampling_id iters warnings errors
##   1     sin       regr.rpart variable_size_train_cv   120        0      0
##   2     sin regr.featureless variable_size_train_cv   120        0      0
```

```r
reg.bench.score <- mlr3resampling::score(reg.bench.result)
train_size_vec <- unique(reg.bench.score$train_size)

ggplot()+
  scale_x_log10(
    breaks=train_size_vec)+
  scale_y_log10(
    "Mean squared error on test set")+
  geom_line(aes(
    train_size, regr.mse,
    group=paste(algorithm, seed),
    color=algorithm),
    shape=1,
    data=reg.bench.score)+
  geom_point(aes(
    train_size, regr.mse, color=algorithm),
    shape=1,
    data=reg.bench.score)+
  facet_grid(
    test.fold~.,
    labeller=label_both,
    scales="free")
```

![plot of chunk VariableSizeTrainCV](/assets/img/2024-01-26-when-is-all-better-than-same/VariableSizeTrainCV-1.png)

Above we plot the test error for each fold and train set size. We can
see that the rpart learning algorithm can not learn anything if there
are less than about 100 samples. So if we have groups of data that
really are the same, but each is smaller than this critical threshold
for this problem, then rpart will not be able to learn anything unless
we put the groups together. Let's try it!

## Simulating and combining identical groups

The code below assigns three test groups to the randomly simulated
data.


```r
task.dt[, random_group := rep(1:3, l=.N)][]
```

```
##               x           y random_group
##   1:  -9.379653  0.17998438            1
##   2:  -5.115044  0.91074391            2
##   3:   2.914135  0.06646766            3
##   4:  16.328312 -1.04599970            1
##   5: -11.932723 -0.15164176            2
##  ---                                    
## 296:   7.257701 -0.67659452            2
## 297: -16.033236 -0.36348886            3
## 298: -15.243898 -0.65963855            1
## 299: -17.982414  0.88088493            2
## 300:  17.170157 -2.16547007            3
```

```r
table(group.tab <- task.dt$random_group)
```

```
## 
##   1   2   3 
## 100 100 100
```

The output above shows that 
there are an equal number (1) 
of each group. 
Below we define a task using that group,


```r
(group.task <- reg.task <- mlr3::TaskRegr$new(
  "sin", task.dt, target="y"
)$set_col_roles("random_group",c("group","stratum")))
```

```
## <TaskRegr:sin> (300 x 2)
## * Target: y
## * Properties: groups, strata
## * Features (1):
##   - dbl (1): x
## * Strata: random_group
## * Groups: random_group
```

Below we define cross-validation using two folds, as above.


```r
same_other_cv <- mlr3resampling::ResamplingSameOtherCV$new()
same_other_cv$param_set$values$folds <- 2
```

So using the 2-fold cross-validation, half of the data in each group
will be assigned to train, and the other half to test. So each "same"
train set will have only 50 samples (for the same group), each "other"
train set will have 100 samples, and each "all" train set will have
150 samples. In the previous section, we saw that rpart needs at least
100 samples to learn, so we should expect that "same" is just as
inaccurate as featureless, "other" is a bit better, and "all" is
better still.
We compute and plot the results using the code below,


```r
(same.other.grid <- mlr3::benchmark_grid(
  group.task,
  reg.learner.list,
  same_other_cv))
```

```
##    task          learner    resampling
## 1:  sin       regr.rpart same_other_cv
## 2:  sin regr.featureless same_other_cv
```

```r
(same.other.result <- mlr3::benchmark(
  same.other.grid, store_models = TRUE))
```

```
## <BenchmarkResult> of 36 rows with 2 resampling runs
##  nr task_id       learner_id resampling_id iters warnings errors
##   1     sin       regr.rpart same_other_cv    18        0      0
##   2     sin regr.featureless same_other_cv    18        0      0
```

```r
same.other.score <- mlr3resampling::score(same.other.result)
same.other.score[1]
```

```
##    train.groups test.fold test.group random_group iteration                  test                 train
## 1:          all         1          1            1         1 22,25,28,31,40,52,...  1, 4, 7,10,13,16,...
##                                   uhash nr           task task_id                learner learner_id
## 1: 1df22821-8fa0-4495-ad13-99ef0b897976  1 <TaskRegr[48]>     sin <LearnerRegrRpart[38]> regr.rpart
##                     resampling resampling_id           prediction  regr.mse algorithm
## 1: <ResamplingSameOtherCV[20]> same_other_cv <PredictionRegr[19]> 0.4780074     rpart
```

```r
ggplot()+
  geom_point(aes(
    regr.mse, train.groups, color=algorithm),
    data=same.other.score)+
  facet_grid(. ~ test.group, labeller=label_both, scales="free")+
  scale_x_log10(
    "Mean squared prediction error (test set)")
```

![plot of chunk SameOtherCV](/assets/img/2024-01-26-when-is-all-better-than-same/SameOtherCV-1.png)

The figure above shows a test group in each panel, the train groups on
the y axis, the test error on the x axis, the two different algorithms
are shown in two different colors. We can clearly see that 

* For `train.groups=same`, rpart has about the same test error as
  featureless, which indicates that nothing has been learned (not
  enough data).
* For `train.groups=other`, rpart test error is significantly smaller
  than featureless, indicating that some non-trivial relationship
  between inputs and outputs has been learned.
* For `train.groups=all`, rpart test error is smaller still, which
  indicates that combining all of the groups is beneficial in this
  case (when the pattern is exactly the same in the different
  groups).
  
## Conclusions

We have shown how to use `mlr3resampling` to determine the number of
train samples which is required to get non-trivial prediction
accuracy. In the simulation above, that number was about 100 train
samples. We then defined groups and cross-validation such that there
were only 50 train samples per group, so training on just samples from
the same group is not enough (at least for the rpart learning
algorithm). We observed smaller test error rates when training on
other/all groups (larger train sets, all with the same
distribution). Overall this is a convincing demonstration that it is
possible for "other" and "all" to be more accurate than "same" --- for
the case where the groups really do have an identical pattern. If in
real data we see the opposite (same is the best), then this implies
that there is a different pattern to learn in each group.

## Session info


```r
sessionInfo()
```

```
## R Under development (unstable) (2024-01-23 r85822 ucrt)
## Platform: x86_64-w64-mingw32/x64
## Running under: Windows 10 x64 (build 19045)
## 
## Matrix products: default
## 
## 
## locale:
## [1] LC_COLLATE=English_United States.utf8  LC_CTYPE=English_United States.utf8    LC_MONETARY=English_United States.utf8
## [4] LC_NUMERIC=C                           LC_TIME=English_United States.utf8    
## 
## time zone: America/Phoenix
## tzcode source: internal
## 
## attached base packages:
## [1] stats     graphics  grDevices utils     datasets  methods   base     
## 
## other attached packages:
## [1] future_1.33.0      animint2_2024.1.24 data.table_1.14.8 
## 
## loaded via a namespace (and not attached):
##  [1] crayon_1.5.2             cli_3.6.1                knitr_1.45               rlang_1.1.1             
##  [5] xfun_0.41                highr_0.10               stringi_1.7.12           labeling_0.4.3          
##  [9] RJSONIO_1.3-1.8          glue_1.6.2               future.apply_1.11.0      colorspace_2.1-0        
## [13] listenv_0.9.0            backports_1.4.1          plyr_1.8.9               mlr3measures_0.5.0      
## [17] paradox_0.11.1           mlr3misc_0.13.0          scales_1.2.1             grid_4.4.0              
## [21] evaluate_0.23            munsell_0.5.0            mlr3_0.17.0              reshape2_1.4.4          
## [25] palmerpenguins_0.1.1     lifecycle_1.0.4          stringr_1.5.0            compiler_4.4.0          
## [29] mlr3resampling_2024.1.23 codetools_0.2-19         Rcpp_1.0.11              farver_2.1.1            
## [33] digest_0.6.33            R6_2.5.1                 parallelly_1.36.0        parallel_4.4.0          
## [37] magrittr_2.0.3           rpart_4.1.23             checkmate_2.3.0          uuid_1.1-1              
## [41] tools_4.4.0              gtable_0.3.4             globals_0.16.2           lgr_0.4.4
```

