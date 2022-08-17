---
layout: post
title: Positive and negative log transform
description: A nonlinear transformation for heatmaps
---



I recently used the following code/transformation to make an
[informative plot of linear model
coefficients](https://rcdata.nau.edu/genomic-ml/nn_embedding_with_interpretable_figures/compare_weights_heat_map.png),


```r
normalize <- function(x)(x-min(x))/(max(x)-min(x))
curve(sign(x)*normalize(log10(abs(x))),-9,9.1)
```

![plot of chunk unnamed-chunk-1](/assets/img/2022-07-14-pos-and-neg-log-transform-unnamed-chunk-1-1.png)

This curve is a nonlinear transformation which makes it easy to
visualize log-scale changes in both positive and negative numbers, so
is ideal for a diverging color scale.


