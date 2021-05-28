---
layout: post
title: Update about data reshaping and visualization in R and python
description: data.table, tidyr, nc, pandas, datatable, plotnine, altair, bokeh
---

My [paper about regular expressions for data
reshaping](https://github.com/tdhock/nc-article) was recently accepted
into R journal. I used visualization of the iris data as a example to
motivate reshaping. To make a facetted histogram I proposed to do


```r
iris.long <- nc::capture_melt_single(
  iris, part=".*", "[.]", dim=".*", value.name="cm")
library(ggplot2)
ggplot()+
  geom_histogram(aes(
    cm, fill=Species),
    color="black",
    data=iris.long)+
  facet_grid(part ~ dim)
```

```
## `stat_bin()` using `bins = 30`. Pick better value with `binwidth`.
```

![plot of chunk unnamed-chunk-1](figure/unnamed-chunk-1-1.png)

## Comparison of python pl
