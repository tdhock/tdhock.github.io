---
layout: page
title: software
permalink: /software/
description: Machine learning and data visualization software
---

### PeakSeg 

The PeakSeg R packages contain algorithms for inferring optimal
segmentation models subject to the constraint that up changes must be
followed by down changes, and vice versa. This ensures that the model
can be interpreted in terms of peaks (after up changes) and background
(after down changes). The figure below compares the previous
unconstrained maximum likelihood segmentation model (top panel, not
feasible for up-down constraint) to the PeakSeg constrained model
(bottom panel, feasible for up-down constraint but lower
log-likelihood).

<div>
    <img class="col" src="{{ site.baseurl }}/assets/img/figure-PeakSeg.png">
</div>

- [PeakSegDP](https://CRAN.R-project.org/package=PeakSegDP) provides a
  heuristic quadratic time algorithm for computing models from 1 to S
  segments for a single sample. This was the original algorithm
  described in our
  [ICML'15 paper](http://jmlr.org/proceedings/papers/v37/hocking15.html),
  but it is neither fast nor optimal, so in practice we recommend to
  use our newer PeakSegOptimal package instead.
- [PeakSegOptimal](https://CRAN.R-project.org/package=PeakSegOptimal)
  provides optimal log-linear time algorithms for computing models
  for a single sample. [arXiv:1703.03352](https://arxiv.org/abs/1703.03352)
- [PeakSegJoint](https://github.com/tdhock/PeakSegJoint) provides a
  fast heuristic algorithm for computing models with a single common
  peak in 0,...,S
  samples. [arXiv:1506.01286](https://arxiv.org/abs/1506.01286)
- [PeakSegPipeline](https://github.com/tdhock/PeakSegPipeline)
  provides a pipeline for genome-wide peak calling using
  PeakSeg. (work in progress)

### PeakError 

To support our paper
[Optimizing ChIP-seq peak detectors using visual labels and supervised machine learning](https://www.ncbi.nlm.nih.gov/pubmed/27797775),
we created the R package
[PeakError](https://CRAN.R-project.org/package=PeakError) to compute the number
of incorrect labels for a given set of predicted peaks. The figure
below shows incorrect labels (false positives + false negatives) for
two labeled ChIP-seq data sets.

<div>
    <img class="col" src="{{ site.baseurl }}/assets/img/figure-PeakError.png">
</div>



