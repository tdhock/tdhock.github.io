---
layout: post
title: Torch learning with binary classification
description: Implementing AUM loss in mlr3torch
---



The goal of this post is to show how to use our recently proposed AUM
loss (useful for unbalanced classification problems), with the
mlr3torch package in R.  This post explains [the code I
used](https://github.com/tdhock/2023-res-baz-az/blob/main/HOCKING-slides-TRUG.R)
to prepare slides for a talk last week for Toulouse R User Group.

## Intro/issue

While preparing the talk, I ran into an
[issue](https://github.com/mlr-org/mlr3torch/issues/374), which can be
understood using the simple example code below,

```r
library(mlr3torch)
nn_bce_loss3 = nn_module(c("nn_bce_with_logits_loss3", "nn_loss"),
  initialize = function(weight = NULL, reduction = "mean", pos_weight = NULL) {
    self$loss = nn_bce_with_logits_loss(weight, reduction, pos_weight)
  },
  forward = function(input, target) {
    self$loss(input$reshape(-1), target$to(dtype = torch_float())-1)
  }
)
loss = nn_bce_loss3()
loss(torch_randn(10, 1), torch_randint(0, 1, 10))
task = tsk("sonar")
graph = po("torch_ingress_num") %>>%
  nn("linear", out_features = 1) %>>%
  po("torch_loss", loss = nn_bce_loss3) %>>%
  po("torch_optimizer") %>>%
  po("torch_model_classif",
     epochs = 1,
     batch_size = 32,
     predict_type="prob")
glrn = as_learner(graph)
glrn$train(task)
glrn$predict(task)
```

The code above has `predict_type="prob"` and `out_features=1` so I got
the following error, using what was mlr3torch main branch at the time,

```r
if(FALSE){#broke
  remotes::install_github("mlr-org/mlr3torch@6e99e02908788275622a7b723d211f357081699a")
  glrn$predict(task)
  ## Erreur dans dimnames(x) <- dn : 
  ##   la longueur de 'dimnames' [2] n'est pas égale à l'étendue du tableau
  ## This happened PipeOp torch_model_classif's $predict()
}
```

The error happens because the torch model outputs only one column, but some later code assumes there are two.

## My PR

I hacked a solution that fixes this (see below), and I filed a [PR](https://github.com/mlr-org/mlr3torch/pull/375).

```r
if(FALSE){#fix
  remotes::install_github("tdhock/mlr3torch@69d4adda7a71c05403d561bf3bb1ffb279978d0d")
  glrn$predict(task)
  ## <PredictionClassif> for 208 observations:
  ##  row_ids truth response
  ##        1     R        M
  ##        2     R        M
  ##        3     R        M
  ##      ---   ---      ---
  ##      206     M        M
  ##      207     M        M
  ##      208     M        M
}
```

## Newer PR

My PR was not generic enough, so Seb Fischer proposed another
[PR](https://github.com/mlr-org/mlr3torch/pull/385).


``` r
remotes::install_github("mlr-org/mlr3torch@c03d61a18e9785e2dbb5b20e2b6dada74a9b58b8")
```

```
## Using github PAT from envvar GITHUB_PAT. Use `gitcreds::gitcreds_set()` and unset GITHUB_PAT in .Renviron (or elsewhere) if you want to use the more secure git credential store instead.
```

```
## Skipping install of 'mlr3torch' from a github remote, the SHA1 (c03d61a1) has not changed since last install.
##   Use `force = TRUE` to force installation
```

``` r
stask <- mlr3::tsk("sonar")
po_list <- list(
  mlr3torch::PipeOpTorchIngressNumeric$new(),
  mlr3torch::nn("head"),
  mlr3pipelines::po(
    "torch_loss",
    loss = torch::nn_bce_with_logits_loss),
  mlr3pipelines::po("torch_optimizer"),
  mlr3pipelines::po(
    "torch_model_classif",
    epochs = 1,
    batch_size = 1000,
    predict_type="prob"))
graph <- Reduce(mlr3pipelines::concat_graphs, po_list)
glrn <- mlr3::as_learner(graph)
glrn$train(stask)
glrn$predict(stask)
```

```
## <PredictionClassif> for 208 observations:
##  row_ids truth response    prob.M    prob.R
##        1     R        R 0.4804875 0.5195125
##        2     R        R 0.4401275 0.5598725
##        3     R        R 0.4467701 0.5532299
##      ---   ---      ---       ---       ---
##      206     M        R 0.4735614 0.5264386
##      207     M        R 0.4552953 0.5447047
##      208     M        R 0.4528149 0.5471851
```

It looks like this PR improves the mlr3torch support for binary classification!
It is important to note a few things about the implementation.

## Binary labels in torch and R

First, at the R level, binary labels are represented as a factor with two levels.
In the case of the sonar data, the two levels are R and M:


``` r
(Class <- stask$data()$Class)
```

```
##   [1] R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R
##  [58] R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R R M M M M M M M M M M M M M M M M M
## [115] M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M
## [172] M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M M
## Levels: M R
```

The mlr3torch package converts this representation into a torch float tensor. 
We can see that by defining a custom loss function, for example my proposed AUM loss for ROC curve optimization.


``` r
Proposed_AUM <- function(pred_tensor, label_2d_tensor){
  label_tensor <- label_2d_tensor$flatten()
  is_positive = label_tensor == 1
  is_negative = label_tensor != 1
  fn_diff = torch::torch_where(is_positive, -1, 0)
  fp_diff = torch::torch_where(is_positive, 0, 1)
  thresh_tensor = -pred_tensor$flatten()
  sorted_indices = torch::torch_argsort(thresh_tensor)
  fp_denom = torch::torch_sum(is_negative) #or 1 for AUM based on count instead of rate
  fn_denom = torch::torch_sum(is_positive) #or 1 for AUM based on count instead of rate
  sorted_fp_cum = fp_diff[sorted_indices]$cumsum(dim=1)/fp_denom
  sorted_fn_cum = -fn_diff[sorted_indices]$flip(1)$cumsum(dim=1)$flip(1)/fn_denom
  sorted_thresh = thresh_tensor[sorted_indices]
  sorted_is_diff = sorted_thresh$diff() != 0
  sorted_fp_end = torch::torch_cat(c(sorted_is_diff, torch::torch_tensor(TRUE)))
  sorted_fn_end = torch::torch_cat(c(torch::torch_tensor(TRUE), sorted_is_diff))
  uniq_thresh = sorted_thresh[sorted_fp_end]
  uniq_fp_after = sorted_fp_cum[sorted_fp_end]
  uniq_fn_before = sorted_fn_cum[sorted_fn_end]
  FPR = torch::torch_cat(c(torch::torch_tensor(0.0), uniq_fp_after))
  FNR = torch::torch_cat(c(uniq_fn_before, torch::torch_tensor(0.0)))
  roc <- list(
    FPR=FPR,
    FNR=FNR,
    TPR=1 - FNR,
    "min(FPR,FNR)"=torch::torch_minimum(FPR, FNR),
    min_constant=torch::torch_cat(c(torch::torch_tensor(-Inf), uniq_thresh)),
    max_constant=torch::torch_cat(c(uniq_thresh, torch::torch_tensor(Inf))))
  min_FPR_FNR = roc[["min(FPR,FNR)"]][2:-2]
  constant_diff = roc$min_constant[2:N]$diff()
  torch::torch_sum(min_FPR_FNR * constant_diff)
}
nn_AUM_loss <- torch::nn_module(
  "nn_AUM_loss",
  inherit = torch::nn_mse_loss,
  initialize = function() {
    super$initialize()
  },
  forward = function(input, target) {
    print(input, n=5)
    print(target, n=5)
    print(table(as.integer(target)))
    Proposed_AUM(input, target)
  }
)
po_list <- list(
  mlr3torch::PipeOpTorchIngressNumeric$new(),
  mlr3torch::nn("head"),
  mlr3pipelines::po(
    "torch_loss",
    loss = nn_AUM_loss),
  mlr3pipelines::po("torch_optimizer"),
  mlr3pipelines::po(
    "torch_model_classif",
    epochs = 1,
    batch_size = 1000,
    predict_type="prob"))
graph <- Reduce(mlr3pipelines::concat_graphs, po_list)
glrn <- mlr3::as_learner(graph)
set.seed(2)#controls order of batches.
glrn$train(stask)
```

```
## torch_tensor
## -0.4830
## -0.4993
## -0.5074
## -0.5193
## -0.5348
## ... [the output was truncated (use n=-1 to disable)]
## [ CPUFloatType{208,1} ][ grad_fn = <AddmmBackward0> ]
## torch_tensor
##  0
##  1
##  1
##  0
##  1
## ... [the output was truncated (use n=-1 to disable)]
## [ CPUFloatType{208,1} ]
## 
##   0   1 
##  97 111
```

``` r
table(Class, as.integer(Class))
```

```
##      
## Class   1   2
##     M 111   0
##     R   0  97
```

We see in the table above that we have the following correspondence:

| R factor level | M | R |
| R integer      | 1 | 2 |
| torch float    | 1 | 0 |

So the first factor level in R is considered the positive class in
torch, which has the float value 1. The negative class is the second
factor level, which gets converted to the float value 0.

## Conclusions

The mlr3torch now supports binary classification, with neural networks
that output a scalar value (larger for more likely to be positive
class).

## Session Info


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
## [1] stats     graphics  grDevices utils     datasets  methods   base     
## 
## loaded via a namespace (and not attached):
##  [1] crayon_1.5.3         knitr_1.50           cli_3.6.4            xfun_0.51            rlang_1.1.5         
##  [6] processx_3.8.6       torch_0.14.2         coro_1.1.0           data.table_1.17.0    bit_4.6.0           
## [11] mlr3pipelines_0.7.2  listenv_0.9.1        backports_1.5.0      ps_1.9.0             paradox_1.0.1       
## [16] mlr3misc_0.16.0      evaluate_1.0.3       mlr3_0.23.0          palmerpenguins_0.1.1 mlr3torch_0.2.1-9000
## [21] compiler_4.5.0       codetools_0.2-20     Rcpp_1.0.14          future_1.34.0        digest_0.6.37       
## [26] R6_2.6.1             curl_6.2.2           parallelly_1.43.0    parallel_4.5.0       magrittr_2.0.3      
## [31] callr_3.7.6          checkmate_2.3.2      uuid_1.2-1           tools_4.5.0          withr_3.0.2         
## [36] bit64_4.6.0-1        globals_0.16.3       lgr_0.4.4            remotes_2.5.0
```
