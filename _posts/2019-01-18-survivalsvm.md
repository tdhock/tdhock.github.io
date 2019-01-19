---
layout: post
title: survivalsvm
description: Support vector machine for survival analysis
---

Today I read 
[an R Journal paper about the survivalsvm package](https://journal.r-project.org/archive/2018/RJ-2018-005/index.html), 
which discusses several support vector machines for survival analysis, which is like regression, but some outputs are right-censored. 
That means you don't know the exact output/label value, but you know that the predicted value should be greater than some number. 

For example say you are interested in learning a function that predicts
the number of miles you need to drive a new car until the timing belt fails. 
Some cars may be taken into the garage to replace the timing belt after it has failed
(in this case the output/label in un-censored, because we can just look at the odometer to find out how many miles it was driven 
before the failure). 
In contrast, some car owners prefer preventative maintenance,
and have the timing belt replaced before it breaks. 
My car manufacturer recommended replacement after 120,000 miles or 
5 years, whichever comes first. Even though my car only has 100,000 miles,
I decided to replace my timing belt earlier this week, because the car was made in 2010!
Therefore, we will never know how many miles my car would have gone before the timing belt failed
(in this case the output is right censored, since we know the true number of miles must be greater than 100,000).

The paper discusses an R package that implements algorithms for three previously proposed models for such data. 
Each model is implemented using either a quadratic programming FORTRAN solver (quadprog R package) or 
a pure-R solver for the SVM-like problem formulation.

The "regression" model discussed in the paper is quite similar to the max-margin interval regression
model that I proposed at [ICML'13](http://proceedings.mlr.press/v28/hocking13.html).
However there are several differences:

* the survivalsvm paper considers the case of un-censored and right-censored outputs; 
  my paper does not consider un-censored outputs, but does consider all other censoring types
  (left, right, interval).
* the survivalsvm paper only discusses the soft-margin formulation with slack variables; 
  my paper discusses the hard-margin formulation, and a convex relaxation based on the squared hinge loss.
* the survival predicted values are evaluated using the concordance index;
  in my paper the predicted penalty values are used to select a changepoint model,
  which is evaluated using changepoint labels.
