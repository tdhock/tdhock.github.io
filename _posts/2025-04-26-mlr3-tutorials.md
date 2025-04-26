---
layout: post
title: mlr3 tutorials
description: Links to other blogs
---

Over the past few months, I have written quite a few blog posts
related to mlr3, so here is an overview of the different topics,
simplest to most complex.

* Generalization to new subsets in
  [R](https://tdhock.github.io/blog/2023/R-gen-new-subsets/) and
  [Python](https://tdhock.github.io/blog/2022/generalization-to-new-subsets/)
  explains how to code [SOAK](https://arxiv.org/abs/2410.08643) from first principles.
* [Comparing ML
  Frameworks](https://tdhock.github.io/blog/2023/comparing-ml-frameworks/)
  discusses advantages of mlr3 relative to a basic for loop, and the
  more recent tidymodels framework in R.
* [New code for various kinds of
  cross-validation](https://tdhock.github.io/blog/2024/cv-all-same-new/)
  explains how to use `mlr3resampling` to implement
  [SOAK](https://arxiv.org/abs/2410.08643), and variable sized train
  sets.
* [Mammouth
  tutorial](https://tdhock.github.io/blog/2024/mammouth-tutorial/)
  explains how to use a SLURM computer cluster for massive speedups of
  machine learning benchmark experiments.
* [Cross-validation experiments with torch
  learners](https://tdhock.github.io/blog/2024/mlr3torch/) explains
  how to compare linear models in torch with other learners from
  outside torch like `glmnet`.
* [Comparing neural network architectures using mlr3torch](https://tdhock.github.io/blog/2025/mlr3torch-conv/) explains how to implement different neural network architectures, and make figures to compare their subtrain/validation/test error rates.
* [Torch learning with binary
  classification](https://tdhock.github.io/blog/2025/mlr3torch-binary/)
  explains how to implement a custom loss function for binary
  classification in mlr3torch.
* TODO [lazy tensor](https://mlr3torch.mlr-org.com/articles/lazy_tensor.html) blog, show memory advantages. 
* [Toulouse RUG
  slides](https://github.com/tdhock/2023-res-baz-az/tree/main?tab=readme-ov-file#april-2025-talk-at-toulouse-rug)
  explain advantages of torch and mlr3.
