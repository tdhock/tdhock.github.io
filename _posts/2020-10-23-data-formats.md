---
layout: post
title: New packages for data storage and reshaping
description: tidyfast, tidyfst, fst, arrow, feather, parquet
---

This morning I was doing some reading on statistical software that may
be worth mentioning as related work in my [R Journal submission about
data reshaping using regular
expressions](https://github.com/tdhock/nc-article#paper).  For that
paper I performed computational experiments in which I recorded the
timings of various R functions for data reshaping, as a function of
data set size. Recently, I [computed
results](https://github.com/tdhock/nc-article#11-oct-2020) for the
`tidyfast::dt_pivot_longer` function. Since it is a wrapper on top of
`data.table::melt`, I expected it to be about as fast, and it is for
the case of returning 0 capture columns (no conversion of reshaped
variable names). However for the case of 4 capture columns, it is
actually a bit slower, because currently these capture columns must be
created via a post-processing step. The author
[has](https://github.com/TysonStanley/tidyfast/issues/39)
[plans](https://github.com/TysonStanley/tidyfast/issues/40) to
eventually support additional features that should make this
computation "fast" as the package name suggests.

On the [data.table Articles wiki
page](https://github.com/Rdatatable/data.table/wiki/Articles) I found
a few other interesting related works. [One article describes a
comparison with stata data reshaping
tools](https://grantmcdermott.com/even-more-reshape/). Another article
describes the
[tidyfst](https://hope-data-science.github.io/tidyfst/articles/example3_reshape.html)
package (yes the a in "fast" is missing, no relation to the other
"tidyfast" package), which supports some basic reshaping using the
`tidyfst::longer_dt` function. Again this is just a wrapper on top of
`data.table::melt`. The main difference/novelty of my proposed
[nc::capture_melt_*](https://cloud.r-project.org/web/packages/nc/vignettes/v3-capture-melt.html)
functions is that a concise/non-repetitive regular expression syntax
is used to define the set of input columns to reshape, and the
names/types of the output capture columns.

So what does the tidyfst package name mean? Well the "tidy" is a
reference to the tidyverse, which provides some popular packages such
as dplyr for data manipulation (tidyfst mimics dplyr syntax). On the
topic of tidyverse, there is a funny post by Holger K. von
Jouanne-Diedrich about why he does not use the tidyverse, which has
[an even funnier comment about how one recruiter views (unfavorably)
tidyverse
fanboys](https://blog.ephorie.de/why-i-dont-use-the-tidyverse#comment-9072). I'm
not so dogmatic, and I actually think the tidyverse is really great
for the R community. Because of its ease of use and quality of
documentation, it makes R much easier for newbies. 

And actually the "fst" in "tidyfst" is a reference to [its support
for](https://hope-data-science.github.io/tidyfst/articles/example5_fst.html)
the [fst package for data table
serialization](http://www.fstpackage.org/). The fst benchmarks show
that it is apparently very fast, and supports "random access" which
means that you don't have to read the whole file into memory, you can
specify row start/end indices and column names to read. Some other new
serialization formats include feather and parquet, which can be
[quickly read into memory as either data table or arrow
format](https://ursalabs.org/blog/2019-10-columnar-perf/). That may be
useful for big data analysis, but for now using CSV (plain text rather
than binary files) for most of my projects is simpler, and fast enough
thanks to `data.table::fread`. 

One exception is that we use [qs](https://github.com/traversc/qs) for
serialization of arbitrary R objects that are randomly generated
during fuzz testing, for the
[RcppDeepState](https://github.com/akhikolla/RcppDeepState) project
that has been graciously funded by the [R
Consortium](https://www.r-consortium.org/projects/call-for-proposals). Actually,
we would have used readRDS for simplicity (minimize package
dependencies), but [it did not work from within RInside in a DeepState
test harness](https://github.com/akhikolla/RcppDeepState/issues/48).
