---
layout: page
title: Software
permalink: /software/
description: Free/open-source software for statistical machine learning and data visualization 
---

My main contributions to free/open-source software are
[R](http://r-project.org) packages that provide implementations of the
methods described in my research papers (see below). 

### R and statistical software research community

- Since 2021, I am an editor for [rOpenSci Statistical
  Software](https://ropenscilabs.github.io/statistical-software-review-book/#welcome).
- Since 2018, I am an editor for [Journal of Statistical
  Software](https://www.jstatsoft.org/about/editorialTeam).
- Since 2012, I am co-administrator and mentor for the
  [R project in Google Summer of Code](https://github.com/rstats-gsoc/)
  -- I have been helping teach college students all over the world how
  to write R packages. Because of this work, the R Foundation gave me
  the [toby.hocking@r-project.org](mailto:toby.hocking@r-project.org)
  email address.
- I was president of the organizing committee for "R in Montreal 2018,"
  a local conference for useRs and developeRs.
  
### SPARSEMODr: SPAtial Resolution-SEnsitive Models of Outbreak Dynamics

To support our paper about infectious disease modeling, we
created the [SPARSEMODr](https://github.com/NAU-CCL/SPARSEMODr/)
R package. [Preprint medRxiv](https://www.medrxiv.org/content/10.1101/2021.05.13.21256216v1)

### RcppDeepState: fuzz testing compiled code in R packages

To support our R consortium funded project about fuzz testing C++
functions in R packages that use Rcpp, we created the
[RcppDeepState](https://github.com/akhikolla/RcppDeepState) R package.

### LOPART: Labeled Optimal Partitioning

To support our paper about Labeled Optimal Partitioning, we
created the [LOPART](https://github.com/tdhock/LOPART) R
package. [arXiv:2006.13967](https://arxiv.org/abs/2006.13967)

### gfpop: Graph-constrained Functional Pruning Optimal Partitioning

To support our paper about graph-constrained optimal changepoint
detection, we created the [gfpop](https://github.com/vrunge/gfpop) and
[gfpopgui](https://github.com/julianstanley/gfpopgui) R
packages. [arXiv:2002.03646](https://arxiv.org/abs/2002.03646)

### PeakSeg: up-down constrained changepoint detection

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
  provides log-linear time algorithms for computing optimal models
  with multiple peaks for a single sample, to support our [JMLR'20
  paper](http://jmlr.org/papers/v21/18-843.html).
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
  provides a supervised machine learning pipeline for genome-wide peak
  calling in multiple samples and cell types, as described in our
  [PSB'20
  paper](http://psb.stanford.edu/psb-online/proceedings/psb20/Hocking.pdf).
- [FLOPART](https://github.com/tdhock/FLOPART), Functional Labeled
  Optimal Partitioning, provides a supervised peak detection algorithm
  with label constraints. (paper in progress)
- [CROCS](https://github.com/aLiehrmann/CROCS) supports our BMC
  Bioinformatics 2021 paper (accepted, to appear), and provides an
  interface to various peak detection models as well as an
  implementation of our proposed algorithm, Changepoints for a Range
  Of
  ComplexitieS. [arXiv:2012.06848](https://arxiv.org/abs/2012.06848)

### PeakError: label error computation for peak models

To support our
[Bioinformatics (2017)
paper](https://www.ncbi.nlm.nih.gov/pubmed/27797775) about a labeling method for supervised peak detection, we
created the R package
[PeakError](https://CRAN.R-project.org/package=PeakError) which computes
the number of incorrect labels for a given set of predicted peaks.

### clusterpath: convex clustering

To support our
[ICML'11 paper](http://www.icml-2011.org/papers/419_icmlpaper.pdf)
about the "clusterpath," a convex formulation of hierarchical
clustering, we created the clusterpath R package, available on
[R-Forge](http://clusterpath.r-forge.r-project.org/). 

### rankSVMcompare: support vector machines for ranking and comparing

To support our
paper about a Support Vector Machine (SVM) algorithm
for ranking and comparing (in preparation,
[arXiv:1401.8008](http://arxiv.org/abs/1401.8008)), we created the
[rankSVMcompare](https://github.com/tdhock/rankSVMcompare) R package.

### animint: animated interactive grammar of graphics

To support our
[JCGS](https://amstat.tandfonline.com/doi/full/10.1080/10618600.2018.1513367)
paper about animated and interactive extensions to the grammar of
graphics, and our [useR2016 tutorial on interactive
graphics](https://github.com/tdhock/interactive-tutorial), we created
the [animint](https://github.com/tdhock/animint) R package. The more
recent version is [animint2](https://github.com/tdhock/animint2).

### fpop: functional pruning optimal partitioning

To support our
[Statistics and Computing](https://link.springer.com/article/10.1007/s11222-016-9636-3)
(2016) paper about a functional pruning optimal
partitioning algorithm, we created the
[fpop](https://r-forge.r-project.org/R/?group_id=1851) R package.

### mmit: max margin interval trees

To support our
[NeurIPS'17](http://papers.nips.cc/paper/7080-maximum-margin-interval-trees)
paper about max margin interval trees, we created the
[mmit](https://github.com/aldro61/mmit) R package and Python module.

### penaltyLearning: supervised changepoint detection

To support our
[ICML'13 paper](http://proceedings.mlr.press/v28/hocking13.html) and
[useR2017 tutorial](http://members.cbio.mines-paristech.fr/~thocking/change-tutorial/Supervised.html)
about learning penalty functions for changepoint detection, we created
the
[penaltyLearning](https://CRAN.R-project.org/package=penaltyLearning)
R package.

### iregnet: elastic net regularized interval regression

To support our paper about elastic net regularized interval regression
models (in preparation), we created the
[iregnet](https://github.com/anujkhare/iregnet) R package.

### directlabels: automatic label placement on figures

To support my poster "Adding direct labels to plots" which won
[Best Student Poster at useR 2011](https://www.r-project.org/conferences/useR-2011/),
we created the
[directlabels](https://CRAN.R-project.org/package=directlabels) R
package.

### inlinedocs: documentation generation

To support our
[Journal of Statistical Software (2013) paper](https://www.jstatsoft.org/article/view/v054i06)
about documentation generation for R, we created the
[inlinedocs](https://CRAN.R-project.org/package=inlinedocs) R package.

### namedCapture: regular expressions for text parsing

To support our [R Journal
paper](https://journal.r-project.org/archive/2019/RJ-2019-050/index.html)
about R packages for regular expressions, we created the
[namedCapture](https://CRAN.R-project.org/package=namedCapture) R
package, and provided various contributions to base R:

* We wrote a [patch for
  regexpr/gregexpr](https://bugs.r-project.org/bugzilla3/show_bug.cgi?id=14518)
  which implements named capture regular expression support. Brian
  Ripley merged the patch into R (since version 2.14 in 2011).
* We sent R-devel a [bug report for
  substring](https://stat.ethz.ch/pipermail/r-devel/2019-February/077393.html)
  and [a patch for
  gregexpr](https://stat.ethz.ch/pipermail/r-devel/2019-February/077315.html). Tomas
  Kalibera merged the fixes into R (since version 3.6 in 2019).

### nc: named capture regular expressions for text parsing and data reshaping

To support our [R Journal
submission](https://github.com/tdhock/nc-article) about data reshaping
using regular expressions, we created the
[nc](https://CRAN.R-project.org/package=nc) R package. To get a more
efficient and fully-featured implementation of data reshaping, [we
contributed C code and the new measure
function](https://github.com/Rdatatable/data.table/pull/4731) to the
[data.table](https://github.com/Rdatatable/data.table/pull/4731)
package (since version 1.14.1 in 2021).

### binsegRcpp: binary segmentation

To use as a baseline efficient implementation of binary segmentation
in various papers such as [Labeled Optimal
Partitioning](https://arxiv.org/abs/2006.13967) and [Linear time model
selection](https://arxiv.org/abs/2003.02808), we created the
[binsegRcpp](https://cloud.r-project.org/web/packages/binsegRcpp/) R
package.

