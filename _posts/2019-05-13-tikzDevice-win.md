---
layout: post
title: tikzDevice on windows
description: Fixing missing packages
---

The [tikzDevice](https://CRAN.R-project.org/package=tikzDevice) R
package is a great way to make figures with mathematical notation. I
have used it extensively in previous papers, e.g. 

* Figures 1-2 of [A log linear-time algorithm for constrained
  changepoint detection](https://arxiv.org/abs/1703.03352)
* Figure 3 of [Generalized Functional Pruning Optimal Partitioning
  (GFPOP) for Constrained Changepoint Detection in Genomic
  Data](https://arxiv.org/abs/1810.00117)
* Figure 2 of [Maximum margin interval
  trees](http://papers.nips.cc/paper/7080-maximum-margin-interval-trees)
  
Here is a screenshot of the MMIT figure, generated via this [R
script](https://github.com/tdhock/mmit-paper/blob/master/figure-algorithm-steps.R):

![mmit-figure-2]({{ site.url }}/assets/img/cropped-mmit.png)

The notation in the figure is consistent with the notation in the
paper, because the figure is rendered via LaTeX at the same time as
the paper.

So today on my Windows desktop I ran into the issue described in this
[stackoverflow
post](https://stackoverflow.com/questions/51023447/r-tikzdevice-cannot-find-latex).

At least on my computer, the problem was due to missing LaTeX
packages. I managed to fix it by creating a figures.tex file with the
following header,

```
\usepackage{pgf,preview,everyshi,graphics,infwarerr,xcolor,tikz}
```

When I ran miktex on that file, it asked to install all of those
packages. Then when I re-made the figure in R, everything worked fine.
