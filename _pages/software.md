---
layout: page
title: Software
permalink: /software/
description: Free/open-source software for statistical machine learning and data visualization 
---

My main contributions to free/open-source software are
[R](http://r-project.org) packages that provide implementations of the
methods described in my research papers (see below). 

### R community

- Since 2012, I am co-administrator and mentor for the
  [R project in Google Summer of Code](https://github.com/rstats-gsoc/)
  -- I have been helping teach college students all over the world how
  to write R packages. Because of this work, the R Foundation gave me
  the [toby.hocking@r-project.org](mailto:toby.hocking@r-project.org)
  email address.
- I was president of the organizing committee for "R in Montreal 2018,"
  a local conference for useRs and developeRs of R.
- I am an editor for the Journal of Statistical Software.

### PeakSeg

The PeakSeg R packages contain algorithms for inferring optimal
segmentation models subject to the constraint that up changes must be
followed by down changes, and vice versa. This ensures that the model
can be interpreted in terms of peaks (after up changes) and background
(after down changes). 

- [PeakSegDP](https://CRAN.R-project.org/package=PeakSegDP) provides a
  heuristic quadratic time algorithm for computing models from 1 to S
  segments for a single sample. This was the original algorithm
  described in our
  [ICML'15 paper](http://jmlr.org/proceedings/papers/v37/hocking15.html),
  but it is neither fast nor optimal, so in practice we recommend to
  use our newer packages below instead.
- [PeakSegOptimal](https://CRAN.R-project.org/package=PeakSegOptimal)
  provides log-linear time algorithms for computing optimal
  models with multiple peaks for a single
  sample. [arXiv:1703.03352](https://arxiv.org/abs/1703.03352)
- [PeakSegDisk](https://github.com/tdhock/PeakSegDisk) provides an
  on-disk implementation of optimal log-linear algorithms for
  computing multiple peaks in a single sample (same as PeakSegOptimal
  but works for much larger data sets because disk is used for storage
  instead of memory).
  [arXiv:1810.00117](https://arxiv.org/abs/1810.00117)
- [PeakSegJoint](https://CRAN.R-project.org/package=PeakSegJoint) provides a
  fast heuristic algorithm for computing models with a single common
  peak in 0,...,S
  samples. [arXiv:1506.01286](https://arxiv.org/abs/1506.01286)
- [PeakSegPipeline](https://github.com/tdhock/PeakSegPipeline)
  provides a pipeline for genome-wide peak calling using
  PeakSeg. (work in progress)

### PeakError

To support our
[Bioinformatics (2017)
paper](https://www.ncbi.nlm.nih.gov/pubmed/27797775) about a labeling method for supervised peak detection, we
created the R package
[PeakError](https://CRAN.R-project.org/package=PeakError) which computes
the number of incorrect labels for a given set of predicted peaks.

### Clusterpath

To support our
[ICML'11 paper](http://www.icml-2011.org/papers/419_icmlpaper.pdf)
about the "clusterpath," a convex formulation of hierarchical
clustering, we created the clusterpath R package, available on
[R-Forge](http://clusterpath.r-forge.r-project.org/). 

### rankSVMcompare

To support our
paper about a Support Vector Machine (SVM) algorithm
for ranking and comparing (in preparation,
[arXiv:1401.8008](http://arxiv.org/abs/1401.8008)), we created the
[rankSVMcompare](https://github.com/tdhock/rankSVMcompare) R package.

### animint

To support our paper about animated and interactive extensions to the
grammar of graphics (in preparation), and our
[useR2016 tutorial on interactive graphics](https://github.com/tdhock/interactive-tutorial),
we created the [animint](https://github.com/animint) R package.

### fpop

To support our
[Statistics and Computing](https://link.springer.com/article/10.1007/s11222-016-9636-3)
(2016) paper about a functional pruning optimal
partitioning algorithm, we created the
[fpop](https://r-forge.r-project.org/R/?group_id=1851) R package.

### mmit

To support our
[NeurIPS'17](http://papers.nips.cc/paper/7080-maximum-margin-interval-trees)
paper about max margin interval trees, we created the
[mmit](https://github.com/aldro61/mmit) R package and Python module.


### penaltyLearning

To support our
[ICML'13 paper](http://proceedings.mlr.press/v28/hocking13.html) and
[useR2017 tutorial](http://members.cbio.mines-paristech.fr/~thocking/change-tutorial/Supervised.html)
about learning penalty functions for changepoint detection, we created
the
[penaltyLearning](https://CRAN.R-project.org/package=penaltyLearning)
R package.

### iregnet

To support our paper about elastic net regularized interval regression
models (in preparation), we created the
[iregnet](https://github.com/anujkhare/iregnet) R package.

### Directlabels

To support my poster "Adding direct labels to plots" which won
[Best Student Poster at useR 2011](http://web.warwick.ac.uk/statsdept/useR-2011/),
we created the
[directlabels](https://CRAN.R-project.org/package=directlabels) R
package.

### inlinedocs

To support our
[Journal of Statistical Software (2013) paper](https://www.jstatsoft.org/article/view/v054i06)
about documentation generation for R, we created the
[inlinedocs](https://CRAN.R-project.org/package=inlinedocs) R package.

### namedCapture

To support our
[R Journal submission](https://github.com/tdhock/namedCapture-article)
about R packages for regular expressions, we created the
[namedCapture](https://CRAN.R-project.org/package=namedCapture) R package.
