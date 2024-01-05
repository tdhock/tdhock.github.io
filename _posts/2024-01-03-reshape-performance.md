---
layout: post
title: Reshape performance comparison
description: Demonstration of asymptotic timing comparisons
---



The goal of this blog post is to explain how to use
[atime](https://github.com/tdhock/atime) to compare the asymptotic
performance (time and memory usage) of different versions of an R
package.

## Example: wide to long reshape 

Data reshaping means changing the shape of the data, in order to get
it into a more appropriate format, for learning/plotting/etc.  Here we
consider wide to long reshape, which means we start with a wide table
(many columns) and end up with a long table (fewer columns). One
example is the iris data, which starts wide


```r
library(data.table)
(iris.wide <- data.table(iris)[, flower := .I][])
```

```
##      Sepal.Length Sepal.Width Petal.Length Petal.Width   Species flower
##             <num>       <num>        <num>       <num>    <fctr>  <int>
##   1:          5.1         3.5          1.4         0.2    setosa      1
##   2:          4.9         3.0          1.4         0.2    setosa      2
##   3:          4.7         3.2          1.3         0.2    setosa      3
##   4:          4.6         3.1          1.5         0.2    setosa      4
##   5:          5.0         3.6          1.4         0.2    setosa      5
##  ---                                                                   
## 146:          6.7         3.0          5.2         2.3 virginica    146
## 147:          6.3         2.5          5.0         1.9 virginica    147
## 148:          6.5         3.0          5.2         2.0 virginica    148
## 149:          6.2         3.4          5.4         2.3 virginica    149
## 150:          5.9         3.0          5.1         1.8 virginica    150
```

If we wanted to make a histogram of each numeric variable, we first
need to reshape, for example using the code below,


```r
(iris.long <- melt(iris.wide, measure.vars = patterns(".*[.].*")))
```

```
##        Species flower     variable value
##         <fctr>  <int>       <fctr> <num>
##   1:    setosa      1 Sepal.Length   5.1
##   2:    setosa      2 Sepal.Length   4.9
##   3:    setosa      3 Sepal.Length   4.7
##   4:    setosa      4 Sepal.Length   4.6
##   5:    setosa      5 Sepal.Length   5.0
##  ---                                    
## 596: virginica    146  Petal.Width   2.3
## 597: virginica    147  Petal.Width   1.9
## 598: virginica    148  Petal.Width   2.0
## 599: virginica    149  Petal.Width   2.3
## 600: virginica    150  Petal.Width   1.8
```

The output above is a table with 600 rows, which is four times the
usual 150 rows in the iris data, because we have reshaped the four
numeric columns. Using this format, we can create a multi-panel
histogram using the code below,


```r
library(ggplot2)
ggplot()+
  geom_histogram(aes(
    value),
    data=iris.long)+
  facet_wrap(~variable)
```

```
## `stat_bin()` using `bins = 30`. Pick better value with `binwidth`.
```

![plot of chunk irisHist](/assets/img/2024-01-03-reshape-performance/irisHist-1.png)

The figure above shows a panel for each numeric variable in the iris
data, with a histogram in each panel.

## Reshape using nc package

[nc](https://github.com/tdhock/nc), short for named capture, is a
package which supports wide to long data reshaping, using the
`capture_melt_single` and `capture_melt_multiple` functions, such as in the code below,


```r
nc::capture_melt_single(iris.wide, variable=".*[.].*")
```

```
##        Species flower     variable value
##         <fctr>  <int>       <char> <num>
##   1:    setosa      1 Sepal.Length   5.1
##   2:    setosa      2 Sepal.Length   4.9
##   3:    setosa      3 Sepal.Length   4.7
##   4:    setosa      4 Sepal.Length   4.6
##   5:    setosa      5 Sepal.Length   5.0
##  ---                                    
## 596: virginica    146  Petal.Width   2.3
## 597: virginica    147  Petal.Width   1.9
## 598: virginica    148  Petal.Width   2.0
## 599: virginica    149  Petal.Width   2.3
## 600: virginica    150  Petal.Width   1.8
```

The result above is exactly the same as from `melt`. In fact,
nc uses
`data.table::melt` under the hood, so will benefit from the
[improvements I
proposed](https://github.com/Rdatatable/data.table/pull/4731), which
are currently merged into the `data.table` master branch on GitHub,
and which will hopefully soon appear in a CRAN release of `data.table`
(1.15.0). 

* nc was modified in [PR#17](https://github.com/tdhock/nc/pull/17) to
  take advantage of the new features in `data.table`. The last commit
  in that PR has SHA1 hash
  [eecced8ea46fbd26c295293fe70e761561a27726](https://github.com/tdhock/nc/pull/17/commits/eecced8ea46fbd26c295293fe70e761561a27726). [That
  version](https://github.com/tdhock/nc/blob/eecced8ea46fbd26c295293fe70e761561a27726/R/capture_melt_single.R#L27)
  of `capture_melt_single` returns the result of `data.table::melt`,
  and the `measure.vars` argument has meta-data about the variable
  columns, computed by
  [measure_single](https://github.com/tdhock/nc/blob/eecced8ea46fbd26c295293fe70e761561a27726/R/measure.R#L52).
* The first commit in that PR has SHA1 hash
  [8a045299302bd431eb9dcfacca83c2cd0e83600d](https://github.com/tdhock/nc/pull/17/commits/8a045299302bd431eb9dcfacca83c2cd0e83600d),
  and just modifies a test. That version of the code [uses a
  join](https://github.com/tdhock/nc/blob/8a045299302bd431eb9dcfacca83c2cd0e83600d/R/capture_melt_single.R#L73)
  to combine variable column meta-data with reshaped data columns, and
  is less efficient.
  
In this blog post we will compare the computational efficiency of
these two versions of nc. But first, here we explain the advantages of
the new reshape features. Consider the code below, which does a
similar reshape as above, but with two named arguments (part and dim)
instead of one (variable).


```r
nc::capture_melt_single(iris.wide, part=".*", "[.]", dim=".*")
```

```
##        Species flower   part    dim value
##         <fctr>  <int> <char> <char> <num>
##   1:    setosa      1  Sepal Length   5.1
##   2:    setosa      2  Sepal Length   4.9
##   3:    setosa      3  Sepal Length   4.7
##   4:    setosa      4  Sepal Length   4.6
##   5:    setosa      5  Sepal Length   5.0
##  ---                                     
## 596: virginica    146  Petal  Width   2.3
## 597: virginica    147  Petal  Width   1.9
## 598: virginica    148  Petal  Width   2.0
## 599: virginica    149  Petal  Width   2.3
## 600: virginica    150  Petal  Width   1.8
```

The result above has a column for each named argument (part and dim),
in which the values come from the text captured by the regular
expression, from the corresponding substring of the column name
(Sepal/Length/Petal/Width). In the old version of nc, the result above
was computed by first doing the reshape, then doing a join with the
meta-data from the regular expression parsing of column names
(relatively inefficient because of the join/copy). In the new version
of nc, we use the new data table reshape feature, which allows
meta-data columns (part and dim) to be created at the same time as the
reshape table (no copy necessary). The analogous new
`data.table::melt` code would be:


```r
melt(iris.wide, measure.vars=measure(part, dim, pattern="(.*)[.](.*)"))
```

```
##        Species flower   part    dim value
##         <fctr>  <int> <char> <char> <num>
##   1:    setosa      1  Sepal Length   5.1
##   2:    setosa      2  Sepal Length   4.9
##   3:    setosa      3  Sepal Length   4.7
##   4:    setosa      4  Sepal Length   4.6
##   5:    setosa      5  Sepal Length   5.0
##  ---                                     
## 596: virginica    146  Petal  Width   2.3
## 597: virginica    147  Petal  Width   1.9
## 598: virginica    148  Petal  Width   2.0
## 599: virginica    149  Petal  Width   2.3
## 600: virginica    150  Petal  Width   1.8
```

Note that the result above is the same, and the pattern is slightly
different.  In `data.table::measure()` we need to specify each capture
group using a pair of parentheses (typical for regex engines), whereas
in nc we simply use named arguments (no parentheses necessary).

## Comparison code

In this section we compare the computational efficiency of the
different reshape operations explained above. To explore computational
efficiency, we will need to compute time/memory usage for different
data sizes. To do that with the iris data, we will generate index
vectors of a given size, as below.


```r
N <- 200
(row.numbers <- rep(1:nrow(iris), l=N))
```

```
##   [1]   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  25  26  27  28
##  [29]  29  30  31  32  33  34  35  36  37  38  39  40  41  42  43  44  45  46  47  48  49  50  51  52  53  54  55  56
##  [57]  57  58  59  60  61  62  63  64  65  66  67  68  69  70  71  72  73  74  75  76  77  78  79  80  81  82  83  84
##  [85]  85  86  87  88  89  90  91  92  93  94  95  96  97  98  99 100 101 102 103 104 105 106 107 108 109 110 111 112
## [113] 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140
## [141] 141 142 143 144 145 146 147 148 149 150   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18
## [169]  19  20  21  22  23  24  25  26  27  28  29  30  31  32  33  34  35  36  37  38  39  40  41  42  43  44  45  46
## [197]  47  48  49  50
```

```r
(iris.wide.N <- iris.wide[row.numbers])
```

```
##      Sepal.Length Sepal.Width Petal.Length Petal.Width Species flower
##             <num>       <num>        <num>       <num>  <fctr>  <int>
##   1:          5.1         3.5          1.4         0.2  setosa      1
##   2:          4.9         3.0          1.4         0.2  setosa      2
##   3:          4.7         3.2          1.3         0.2  setosa      3
##   4:          4.6         3.1          1.5         0.2  setosa      4
##   5:          5.0         3.6          1.4         0.2  setosa      5
##  ---                                                                 
## 196:          4.8         3.0          1.4         0.3  setosa     46
## 197:          5.1         3.8          1.6         0.2  setosa     47
## 198:          4.6         3.2          1.4         0.2  setosa     48
## 199:          5.3         3.7          1.5         0.2  setosa     49
## 200:          5.0         3.3          1.4         0.2  setosa     50
```

The output above shows the indices used to construct a data table
which will be the input of the wide to long reshape operation.  The
idea is to do the same as above, but for different sizes `N`, varying
from 10 to 100 to 1000, etc.
The code below computes an R expression to execute for each version of nc.

* the first argument `pkg.path` is a path to a git repository containing the R package,
* the second argument `expr` is an R expression, which will be run for each different version of the R package.
* the third and fourth arguments specify R package versions (names are identifiers that will appear in plots/output, and values are SHA1 hash values identifying commits).


```r
(nc.expr.list <- atime::atime_versions_exprs(
  pkg.path = "~/R/nc", 
  expr = nc::capture_melt_single(iris.wide.N, part=".*", "[.]", dim=".*"),
  "nc(old)"="8a045299302bd431eb9dcfacca83c2cd0e83600d",
  "nc(new)"="eecced8ea46fbd26c295293fe70e761561a27726"))
```

```
## $`nc(old)`
## nc.8a045299302bd431eb9dcfacca83c2cd0e83600d::capture_melt_single(iris.wide.N, 
##     part = ".*", "[.]", dim = ".*")
## 
## $`nc(new)`
## nc.eecced8ea46fbd26c295293fe70e761561a27726::capture_melt_single(iris.wide.N, 
##     part = ".*", "[.]", dim = ".*")
```

The output above shows how `atime` works, by replacing each package name double colon prefix in `expr` (`nc::`), with a new package name that depends on the commit (for example `nc.eecced8ea46fbd26c295293fe70e761561a27726::`).
In fact `atime` creates and installs a package with a new name, that depends on the commit, for every version specified.
Below we measure asymptotic time/memory usage for the two versions,

* The first argument `N` is a sequence of data sizes,
* The second argument `setup` is an R expression that will be evaluated for each value in `N`, to create data of a given size,
* The third argument `expr.list` is the list of expressions for which time/memory usage will be measured. 
* Finally, `seconds.limit` may optionally be specified. If an expression is slower than this limit for any data size, then no larger data sizes will be measured.


```r
seconds.limit <- 1
(atime.result <- atime::atime(
  N=10^seq(1, 6, by=0.5),
  setup={
    row.numbers <- rep(1:nrow(iris), l=N)
    iris.wide.N <- iris.wide[row.numbers]
  }, 
  expr.list=nc.expr.list,
  seconds.limit=seconds.limit))  
```

```
## Warning: Some expressions had a GC in every iteration; so filtering is disabled.
```

```
## atime list with 22 measurements for
## nc(new)(N=10 to 1e+06)
## nc(old)(N=10 to 1e+06)
```

```r
plot(atime.result)
```

![plot of chunk atimeResult](/assets/img/2024-01-03-reshape-performance/atimeResult-1.png)

The result aboe shows that the new version of nc uses less time and
memory, by a constant factor (same asymptotic slopes on log-log plot).
Below we add asymptotic reference lines, to show the estimated asymptotic time and memory complexity, 


```r
(atime.refs <- atime::references_best(atime.result))
```

```
## references_best list with 44 measurements, best fit complexity:
## nc(old) (N kilobytes, N log N seconds)
## nc(new) (N kilobytes, N log N seconds)
```

```r
plot(atime.refs)
```

![plot of chunk atimeRefs](/assets/img/2024-01-03-reshape-performance/atimeRefs-1.png)

The output and figure above includes violet reference lines, in which
the text labels can be interpreted in terms of big O notation
(asymptotic time and memory usage). Two violet reference lines are
shown (closest upper and lower bound of empirical data). For both new
and old versions of nc, linear O(N) seems to be a good fit.
A third step/plot is computed below,


```r
(atime.pred <- predict(atime.refs, seconds=seconds.limit, kilobytes=10000))
```

```
## atime_prediction object
##         unit expr.name unit.value         N
##       <char>    <char>      <num>     <num>
## 1:   seconds   nc(old)          1 517652.88
## 2: kilobytes   nc(old)      10000  24468.05
## 3: kilobytes   nc(new)      10000  57627.11
```

```r
plot(atime.pred)
```

```
## Warning: Transformation introduced infinite values in continuous x-axis
```

![plot of chunk atimePred](/assets/img/2024-01-03-reshape-performance/atimePred-1.png)

In the plot above, the data size `N` which can be handled in a given
amount of time/memory is shown. It is clear that the new version of nc
can handle a larger `N` for the given time/memory limit.

## Comparison with `data.table::melt`


```r
meas.lang <- quote(measure(part,dim))
lang.list <- list()
meas.arg.list <- list(sep=".", pattern="(Sepal|Petal)[.](Width|Length)")
for(meas.arg.name in names(meas.arg.list)){
  this.lang <- meas.lang
  this.lang[[meas.arg.name]] <- meas.arg.list[[meas.arg.name]]
  out.name <- sprintf("measure(%s)", meas.arg.name)
  lang.list[[out.name]] <- substitute(melt(wide.dt, measure.vars=M), list(M=this.lang))
}
lang.list
```

```
## $`measure(sep)`
## melt(wide.dt, measure.vars = measure(part, dim, sep = "."))
## 
## $`measure(pattern)`
## melt(wide.dt, measure.vars = measure(part, dim, pattern = "(Sepal|Petal)[.](Width|Length)"))
```

## Session info


```r
sessionInfo()
```

```
## R Under development (unstable) (2023-12-22 r85721)
## Platform: x86_64-pc-linux-gnu
## Running under: Ubuntu 22.04.3 LTS
## 
## Matrix products: default
## BLAS:   /usr/lib/x86_64-linux-gnu/blas/libblas.so.3.10.0 
## LAPACK: /usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.10.0
## 
## locale:
##  [1] LC_CTYPE=fr_FR.UTF-8       LC_NUMERIC=C               LC_TIME=fr_FR.UTF-8        LC_COLLATE=fr_FR.UTF-8    
##  [5] LC_MONETARY=fr_FR.UTF-8    LC_MESSAGES=fr_FR.UTF-8    LC_PAPER=fr_FR.UTF-8       LC_NAME=C                 
##  [9] LC_ADDRESS=C               LC_TELEPHONE=C             LC_MEASUREMENT=fr_FR.UTF-8 LC_IDENTIFICATION=C       
## 
## time zone: America/Phoenix
## tzcode source: system (glibc)
## 
## attached base packages:
## [1] stats     graphics  utils     datasets  grDevices methods   base     
## 
## other attached packages:
## [1] ggplot2_3.4.4      data.table_1.14.99
## 
## loaded via a namespace (and not attached):
##  [1] directlabels_2023.8.25                                vctrs_0.6.5                                          
##  [3] cli_3.6.2                                             knitr_1.45                                           
##  [5] rlang_1.1.2                                           xfun_0.41                                            
##  [7] bench_1.1.3                                           highr_0.10                                           
##  [9] generics_0.1.3                                        glue_1.6.2                                           
## [11] labeling_0.4.3                                        nc_2024.1.4                                          
## [13] colorspace_2.1-0                                      scales_1.3.0                                         
## [15] fansi_1.0.6                                           quadprog_1.5-8                                       
## [17] grid_4.4.0                                            munsell_0.5.0                                        
## [19] evaluate_0.23                                         tibble_3.2.1                                         
## [21] profmem_0.6.0                                         lifecycle_1.0.4                                      
## [23] compiler_4.4.0                                        nc.eecced8ea46fbd26c295293fe70e761561a27726_2020.10.6
## [25] dplyr_1.1.4                                           pkgconfig_2.0.3                                      
## [27] nc.8a045299302bd431eb9dcfacca83c2cd0e83600d_2020.5.16 atime_2023.12.7                                      
## [29] lattice_0.22-5                                        farver_2.1.1                                         
## [31] R6_2.5.1                                              tidyselect_1.2.0                                     
## [33] utf8_1.2.4                                            pillar_1.9.0                                         
## [35] magrittr_2.0.3                                        tools_4.4.0                                          
## [37] withr_2.5.2                                           gtable_0.3.4
```
