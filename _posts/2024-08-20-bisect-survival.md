---
layout: post
title: History of supervised change-point detection
description: Using git bisect to find a survival bug
---

In my research about supervised change-point detection, I discovered a
link with previous work in the statistics literature: censored
regression, which is implemented in the R package survival. This post
is about how `git bisect` can be used to find a commit when survival
introduced a bug.

## Background: history of supervised change-point detection

During my PHD, I was working at the Institute Curie, with medical
doctors who were interested in classifying tumors based on their DNA
copy number profiles. These data sets are like time series, but
measured along space (positions on a chromosome), rather than time. If
there are abrupt changes within a sequence, then the tumor is said to
have ``segmental copy number alternations,'' and is likely to require
more aggressive treatment (compared to a more benign sub-type in which
these abrupt changes are not present).

Therefore, to accurately diagnose cancer patients, and propose
appropriate treatments, it is important to accurately characterize the
presence/absence of these abrupt changes. So I did a literature review
of algorithms which could be used for detecting these change-points,
and in [my BMC Bioinformatics (2013)
paper](https://bmcbioinformatics.biomedcentral.com/articles/10.1186/1471-2105-14-164),
we showed that the algorithms based on dynamic programming were most
accurate, such as:

* The "segment neighborhood" method computes the best change-points
  for a given number of segments. R implementations of this method can
  be found in `jointseg::Fpsn`,
  `changepoint::cpt.mean(method="SegNeigh")`, and (now archived)
  [Segmentor3IsBack](https://cloud.r-project.org/src/contrib/Archive/Segmentor3IsBack/),
  [cghseg::segmeanCO](https://cloud.r-project.org/src/contrib/Archive/cghseg/).
* The "optimal partitioning" method computes the best change-points
  for a given penalty, which is actually the same as the segment
  neighborhood result, for some number of segments. R implementations
  of this method can be found in `fpop::Fpop`,
  `changepoint::cpt.mean(method="PELT")` and (now archived)
  [gfpop](https://cran.r-project.org/src/contrib/Archive/gfpop/).

To use these algorithms in practice for accurate detection, a model
complexity parameter needs to be carefully chosen. That is either the
number of segments (in the segment neighborhood method), or the
penalty for each change (in the optimal partitioning method).  There
are theoretical arguments that can be used to choose the model
complexity parameter (AIC or BIC for example), in the unsupervised
setting (no labels which indicate presence/absence of change-points in
particular regions of data sequences). However, when there are labels
available, our [ICML'13
paper](https://proceedings.mlr.press/v28/hocking13.html) showed that
it is much more accurate to use a supervised learning approach. The
learning algorithm we proposed in that paper was called "max margin
interval regression," which uses gradient descent with a linear model
and a squared hinge loss, where the label/output used in training is
an interval of good penalty values for each labeled data sequence. Our
algorithm is implemented in the penaltyLearning R package:
`penaltyLearning::IntervalRegressionUnregularized` (un-regularized)
and `penaltyLearning::IntervalRegressionCV` (degree of L1
regularization chosen using cross-validation).

The link with the statistics literature is that, in the context of
survival analysis, and in particular censored regression, the
label/output used in training can also be an interval. These
statistical models are called "Accelerated Failure Time" or AFT, and
are implemented as `survival::survreg` in R. Fitting the AFT Gaussian
model corresponds to minimizing a loss function with quadratic tails,
similar to our ICML'13 proposal based on the squared hinge loss. 
With Rebecca Killick, we presented a tutorial at useR'17 about
change-point detection, including
[figures](https://tdhock.github.io/change-tutorial/Supervised.html)
that show the similarity between these two kinds of loss
functions. With my GSOC'19 student Avinash Barnwal, and co-mentor
Philip Cho, we wrote [a JCGS
paper](https://www.tandfonline.com/doi/full/10.1080/10618600.2022.2067548)
which described how the AFT loss functions could be used for censored
regression using the popular XGboost library.

Whereas `survival::survreg` is un-regularized, our proposal in ICML'13
was to use L1 regularization. I worked with several students to
implement [iregnet](https://github.com/tdhock/iregnet), an R package
which attempts to implement AFT loss functions with L1
regularization. This package was meant to be analogous to glmnet, but
we never got the pruning rules to work as quickly as glmnet. I
suspect it would be better to implement L1-regularized AFT using the
new version of glmnet, which apparently can support all generalized
linear models, as described in the recent [JSS
paper](https://www.jstatsoft.org/article/view/v106i01).

Another supervised change-point detection algorithm, similar to our
ICML'13 paper, was proposed by Charles Truong in EUSIPCO'17, but there
is no R package that implements this method.

## Issue

Back in 2017 when I was preparing the tutorial for useR, I ran into an
[issue](https://github.com/therneau/survival/issues/8) about `survreg`
not converging when all train labels are censored. After that fix,
survreg worked well enough so that I could use it to prepare [my
useR'17 tutorial on supervised change-point
detection](https://tdhock.github.io/change-tutorial/Supervised.html). 

Recently, a GSOC student tried reproducing some code from that time. TODO

* [old](https://rcdata.nau.edu/genomic-ml/animint-gallery/2017-05-08-BIC-versus-learned-penalty/index.html)
* [new](https://tdhock.github.io/2023-08-interval-regression-BIC-vs-learned/)

survreg on a similar data set, and observed that it
did not converge.

```
git log --reverse
```

https://github.com/therneau/survival/issues/270

https://cloud.r-project.org/src/base/R-3/

## Conclusion

TODO
