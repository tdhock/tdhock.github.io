---
layout: post
title: New ideas for classification
description: Weston-Watkins multiclass SVM and AUC optimization
---

Recently I have been reading some interesting machine learning
research papers about classification.

### Multi-class support vector machines

The support vector machine or SVM is a machine learning algorithm for
binary classification. It is based on the idea of learning a decision
boundary which maximizes the margin, which is a geometric concept
(this is a discriminative rather than probabilistic model / loss
function). 

During my PhD and postdoc years I studied the SVM and [proposed an
extension for learning ranking and comparison
functions](https://arxiv.org/abs/1401.8008). In this context the data
consist of pairs of items such as chess players; each player has a
feature vector and each match has a label which can take one of three
values (win, lose, draw). 

Although naively this can be viewed as a multi-class problem (three
possible label values), I showed that it can be converted to a binary
problem, with labels that correspond to "somebody wins" and "draw"
(aka significant rank difference between items or not). In this paper
we showed that this framework allows learning a ranking function
(which predicts a real-valued rank for any item/player) and a
comparison function (which predicts a win/lose/draw label given a pair
of items/players).

Other extensions to the binary SVM include various formulations for
supporting multi-class. One of the most well known approaches is the
Weston-Watkins SVM. Each component of the loss function is a hinge
loss of the difference between predicted values (between the target
class for each example, and another class). The loss is then summed
over all observations, and all other classes.

The new paper [An exact solver for the Weston-Watkins SVM
subproblem](https://arxiv.org/abs/2102.05640) proposes a new algorithm
for solving the dual problem using block coordinate descent. This
basically means holding all optimization variables constant, and only
optimizing some subset (here the subset is the dual variables involved
with a particular labeled example). The subproblem to solve is a
quadratic program (quadratic objective function to minimize, subject
to linear constraints). There is a very interesting and complicated
derivation of the exact solver, and a proof of linear convergence. The
experimental section compares with a previous iterative subproblem
solver, and shows substantial speedups when there are a large number
of classes.

The same authors had a paper at NeurIPS last year, [Weston-Watkins
Hinge Loss and Ordered Partitions](https://arxiv.org/abs/2006.07346),
which explores the same model from a more theoretical angle. Other
authors had already showed that the Crammer-Singer SVM is "calibrated"
for the discrete abstention loss. In this context calibration refers
to the ability of the learning algorithm to find the Bayes optimal
decision boundary in the large sample limit. Similarly, the
Lee-Lin-Wahba SVM, and other hinge losses mentioned in this paper,
were previously shown to be calibrated for the 0-1 loss. This new
paper shows that the WW-SVM is calibrated for a new discrete loss,
which they call the ordered partition loss. This paper has a great
related work section.

### AUC optimization

There are many papers which discuss ways to optimize the Area Under
the ROC Curve (AUC), which is often used to evaluate learned binary
classification models. Most of the papers involve optimizing a convex
surrogate of the
[Mann-Whitney-Wilcoxon](https://en.wikipedia.org/wiki/Mann%E2%80%93Whitney_U_test)
statistic, which involves a double sum, over all negative and positive
examples. Computing this loss function and using it for learning is
therefore quadratic in the number of labeled examples, which means it
is not feasible to scale to large data.

Some possible solutions are discussed in [Robust Deep AUC
Maximization: A New Surrogate Loss and Empirical Studies on Medical
Image Classification](https://arxiv.org/abs/2012.03173). One of the
interesting ideas discussed therein (but not original) is taking the
dual of the problem, in order to obtain a loss function which is
linear rather than quadratic. The main idea they suggest in this paper
is to replace the square loss with the squared hinge loss, which makes
sense in the context of classification (as explained intuitively in
their Figure 1). However the idea of using the squared hinge loss as a
surrogate is not new; in fact it dates back (at least) to [Yan
2003](https://home.cs.colorado.edu/~mozer/Research/Selected%20Publications/reprints/wilcoxon_mann_whitney.pdf).

Another paper by the same group involves extending these ideas to the
setting of huge data distributed over several servers, [Federated Deep
AUC Maximization for Heterogeneous Data with a Constant Communication
Complexity](https://arxiv.org/abs/2102.04635). The interesting result
in this paper is that AUC can be optimized in a federated algorithm in
a reasonable amount of time, despite the fact that the AUC is not
separable on examples/observations.


