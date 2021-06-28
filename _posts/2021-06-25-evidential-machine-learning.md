---
layout: post
title: Evidential machine learning
description: An alternative to probability
---

These days I skim almost every thread on
[R-devel](https://stat.ethz.ch/mailman/listinfo/r-devel), which is the
email list for discussion about improving base R and its internal
functionality. I also occasionally skim selected threads in
[R-package-devel](https://stat.ethz.ch/mailman/listinfo/r-package-devel),
which is the email list for discussion about R package development
(how to get your package accepted on CRAN).

Since I have studied/lived in France for 4 years, I am usually excited
to read messages from French colleagues on these email lists. In [one
thread](https://stat.ethz.ch/pipermail/r-package-devel/2021q2/007009.html)
I noticed the French name Thierry Denouex, who wrote for help about
his `evclust` package. I studied clustering during my PHD, and in [my
ICML'11 clusterpath
paper](http://www.icml-2011.org/papers/419_icmlpaper.pdf), I proposed
a new algorithm for convex clustering. So I was interested to read
about Thierry's proposed clustering algorithm.

I followed the link in his email signature to his web page, where I
found that he is a member of [the HEUDIASYC
laboratory](https://www.hds.utc.fr/presentation/annuaire.html). Coincidentally
that is also the workplace of Yves Grandvalet, who was one of the
people who officially reviewed and approved [my
PHD](https://tel.archives-ouvertes.fr/tel-00906029/). Small world!

About clustering, the goal is to group N observations into K clusters,
where each cluster should contain a subset of observations which are
similar in some sense. Classical algorithms include
[hierarchical/agglomerative
clustering](https://en.wikipedia.org/wiki/Hierarchical_clustering),
[K-means](https://en.wikipedia.org/wiki/K-means_clustering), and
Gaussian [mixture models](https://en.wikipedia.org/wiki/Mixture_model)
(Expectation-Maximization). [The evclust package
vignette](https://cloud.r-project.org/web/packages/evclust/vignettes/evclust_vignette.pdf)
begins by reviewing these and other algorithms (fuzzy k-means, sparse
k-means, etc). K-means is an example of a "hard" clustering algorithm,
because each observation is assigned to exactly one cluster (an
integer value from 1 to K). In contrast, "soft" clustering algorithms
like Gaussian mixtures give each observation a vector of K real
numbers --- one for each cluster, larger values mean that cluster is
more likely for this observation. Typically these numbers are
constrained to be on the [probability
simplex](https://en.wikipedia.org/wiki/Simplex) (non-negative, sum to
one). When the sum to one constraint is removed, we obtain
"possibilistic clustering." When each observation is assigned a set of
clusters, we obtain "rough clustering." 

The "evidential clustering" approach uses mass functions and focal
sets, and generalizes most of these other methods. It is based on the
the Dempster-Shafer theory that assumes a question has one answer
among a finite set of possibilities. The mass function takes a subset
of possibilities, and returns a value in [0,1]. Each subset with mass
function value greater than 0 is called a focal set, and summing over
all subsets must yield one. To apply this formalism to clustering, the
set of K clusters is used as the finite set of possibilities, and each
observation has a corresponding mass function (the N-tuple of mass
functions is called a credal/evidential partition). Some special cases
are

* When mass functions are Bayesian (focal sets are singletons, meaning
  only one element in each set) we get a fuzzy/soft partition (vector
  of real numbers, one for each cluster).
* When mass functions are logical (only one focal set) we get a rough
  partition (each observation assigned a set of clusters).
* When mass functions are certain (both Bayesian and logical, meaning
  the only focal set is a singleton containing the cluster ID for that
  observation) we get a hard partition (like K-means).
* When mass functions are consonant (focal sets are nested, meaning
  for any two sets, one must be a subset of the other) we get
  possibilistic clustering algorithms (vector of real numbers with no
  sum to one constraint).

How interesting! I wonder why this alternative to / generalization of
probability is not more commonly discussed in the statistical machine
learning literature? [Thierry's Belief Functions and Machine Learning
page](https://www.hds.utc.fr/~tdenoeux/dokuwiki/en/publi/belief_art)
lists dozens of publications on the subject. He implemented
classification algorithms based on Belief functions theory in the
[evclass
package](https://cran.r-project.org/web/packages/evclass/vignettes/Introduction.html),
which can handle "the case where there is an unknown class, not
represented in the learning set." 

