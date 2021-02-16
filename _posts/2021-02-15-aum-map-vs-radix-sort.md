---
layout: post
title: Faster AUM computation?
description: Log-linear C++ STL containers vs linear time radix sort
---

To support our paper about gradient-based optimization of the Area
Under the Minimum (AUM) of the False Positives and Negatives, I
recently wrote [some C++
code](https://github.com/tdhock/aum/blob/main/src/aum.cpp) which does
the computation. It uses the
[std::map](https://www.cplusplus.com/reference/map/map/) container
from the Standard Template Library. The container is a key-value store
which keeps its elements sorted by key (using a [red-black
tree](https://en.wikipedia.org/wiki/Red%E2%80%93black_tree)
internally). In my application the keys are prediction thresholds, and
the values are total differences in false positives and false
negatives which occur at that threshold (summed over all examples). If
there are N thresholds with error differences over all examples, then
we need to perform N find/insert operations, each of which is a
log-time operation, O(log N). The overall time complexity of the
algorithm is therefore log-linear O(N log N). 

I had previously implemented this algorithm in [pure R
code](https://github.com/tdhock/penaltyLearning/blob/master/R/ROChange.R)
which uses the excellent `data.table` package. I wanted to compare the
new C++ implementation to the R implementation (which uses C code
under the hood). So I wrote [a
vignette](https://github.com/tdhock/aum/blob/main/vignettes/speed-comparison.Rmd)
which does speed comparisons. I expected that the two algorithms would
have the same log-linear asymptotic time complexity. The average
timings in seconds for the two methods (penaltyLearning, aum) on
several data sizes (N.pred) are shown below, along with the speedup
(penaltyLearning/aum).

```
   N.pred penaltyLearning        aum   speedup
1:     10      0.07699782 0.00006470 1190.0745
2:     31      0.07808582 0.00007602 1027.1747
3:    100      0.11383554 0.00013244  859.5254
4:    316      0.22861260 0.00032450  704.5072
5:   1000      0.59400916 0.00097234  610.9068
```

I was not surprised to observe that the C++ code (aum) was orders of
magnitude faster than the R code (penaltyLearning). That is to be
expected due to the overhead of interpreting/evaluating R
code. However I was surprised to observe that the speedup consistency
decreases as the data size (N.pred) increases. 

This can be explained by remembering that R/data.table uses the linear
time radix sort, which is asymptotically faster than the C++ STL
container. For small data sizes (as above) the log-linear C++ code is
faster; for large data sizes (1 million or more?) the R/data.table
code may actually be faster.

This begs the question, should we use radix sort instead of the
log-linear C++ STL map container? Theoretically yes. However I do not
know of any off-the-shelf radix sort C/C++ library function. The
problem with radix sort is that the implementation is highly dependent
on the data type to sort (here a double). I found an interesting
tutorial, [Radix Sort
Revisited](http://www.codercorner.com/RadixSortRevisited.htm), which
explains how to implement a radix sort (for float), but it would
introduce substantial complexity to the code. Another option would be
to use the radix sort code in R/data.table, but I would prefer a pure
C/C++ solution. Maybe
[boost::sort::spreadsort::float_sort](https://www.boost.org/doc/libs/1_67_0/libs/sort/doc/html/boost/sort/spreadsort/float_sort_idp31797616.html)
would do the job? It is "an extremely fast hybrid radix sort
algorithm" with best, average, and worst case time complexity of N, N
sqrt(Log N), min(N log N, N key_length). For now I'll settle for
log-linear time and the STL for simplicity and portability.

