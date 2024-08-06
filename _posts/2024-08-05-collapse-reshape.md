---
layout: post
title: Collapse reshape benchmark
description: Comparison with data.table
---

[data.table](https://github.com/rdatatable/data.table) is an R package
for efficient data manipulation.  I have an NSF POSE grant about
expanding the open-source ecosystem of users and contributors around
`data.table`.  Part of that project is benchmarking time and memory
usage, and comparing with similar packages.  Similar to [a previous
post](https://tdhock.github.io/blog/2024/reshape-performance/), the
goal of this post is to explain how to use
[atime](https://github.com/tdhock/atime) to benchmark `data.table`
reshape with similar packages.



## Background about data reshaping

Data reshaping means changing the shape of the data, in order to get
it into a more appropriate format, for learning/plotting/etc. It is
perhaps best explained using a simple example. Here we consider the
iris data, which has four numeric columns, and we show the first two rows below:


``` r
(two.iris.wide <- iris[c(1,150),])
```

```
##     Sepal.Length Sepal.Width Petal.Length Petal.Width   Species
## 1            5.1         3.5          1.4         0.2    setosa
## 150          5.9         3.0          5.1         1.8 virginica
```

Note the table above has 8 numbers, arranged into a table of 2 rows
and 4 columns. What if we wanted to make a facetted histogram of the
numeric iris data columns, with one panel/facet for each column? With
ggplots we have to first reshape to "long" (or I like to say "tall")
format:


``` r
cols.to.reshape <- c("Sepal.Length","Sepal.Width","Petal.Length","Petal.Width")
two.iris.wide.mat <- as.matrix(two.iris.wide[,cols.to.reshape])
row.i <- as.integer(row(two.iris.wide.mat))
(two.iris.tall <- data.frame(
  row.i,
  Species=two.iris.wide$Species[row.i],
  row.name=rownames(two.iris.wide)[row.i],
  col.name=cols.to.reshape[as.integer(col(two.iris.wide.mat))],
  cm=as.numeric(two.iris.wide.mat)))
```

```
##   row.i   Species row.name     col.name  cm
## 1     1    setosa        1 Sepal.Length 5.1
## 2     2 virginica      150 Sepal.Length 5.9
## 3     1    setosa        1  Sepal.Width 3.5
## 4     2 virginica      150  Sepal.Width 3.0
## 5     1    setosa        1 Petal.Length 1.4
## 6     2 virginica      150 Petal.Length 5.1
## 7     1    setosa        1  Petal.Width 0.2
## 8     2 virginica      150  Petal.Width 1.8
```

Note the table above has the same 8 numbers, but arranged into a table
of 8 rows and 1 column, which is the desired input for ggplots.

## Making a function

Here is how we would do it using a function:


``` r
reshape_taller <- function(DF, col.i){
  orig.row.i <- 1:nrow(DF)
  wide.mat <- as.matrix(DF[, col.i])
  orig.col.i <- as.integer(col(wide.mat))
  other.values <- DF[, -col.i, drop=FALSE]
  rownames(other.values) <- NULL
  data.frame(
    orig.row.i,
    orig.row.name=rownames(DF)[orig.row.i],
    orig.col.i,
    orig.col.name=names(DF)[orig.col.i],
    other.values,
    value=as.numeric(wide.mat))
}
reshape_taller(two.iris.wide,1:4)
```

```
##   orig.row.i orig.row.name orig.col.i orig.col.name   Species value
## 1          1             1          1  Sepal.Length    setosa   5.1
## 2          2           150          1  Sepal.Length virginica   5.9
## 3          1             1          2   Sepal.Width    setosa   3.5
## 4          2           150          2   Sepal.Width virginica   3.0
## 5          1             1          3  Petal.Length    setosa   1.4
## 6          2           150          3  Petal.Length virginica   5.1
## 7          1             1          4   Petal.Width    setosa   0.2
## 8          2           150          4   Petal.Width virginica   1.8
```

And below is with the full iris data set:


``` r
iris.tall <- reshape_taller(iris,1:4)
library(ggplot2)
ggplot()+
  geom_histogram(aes(
    value),
    bins=50,
    data=iris.tall)+
  facet_wrap("orig.col.name")
```

![plot of chunk hist](/assets/img/2024-08-05-collapse-reshape/hist-1.png)

## Comparison with other functions

The function defined above works, and there are other functions which
provide similar functionality. For example,


``` r
head(stats::reshape(
  iris, direction="long", varying=list(cols.to.reshape), v.names="cm"))
```

```
##     Species time  cm id
## 1.1  setosa    1 5.1  1
## 2.1  setosa    1 4.9  2
## 3.1  setosa    1 4.7  3
## 4.1  setosa    1 4.6  4
## 5.1  setosa    1 5.0  5
## 6.1  setosa    1 5.4  6
```

``` r
library(data.table)
iris.dt <- data.table(iris)
melt(iris.dt, measure.vars=cols.to.reshape, value.name="cm")
```

```
##        Species     variable    cm
##         <fctr>       <fctr> <num>
##   1:    setosa Sepal.Length   5.1
##   2:    setosa Sepal.Length   4.9
##   3:    setosa Sepal.Length   4.7
##   4:    setosa Sepal.Length   4.6
##   5:    setosa Sepal.Length   5.0
##  ---                             
## 596: virginica  Petal.Width   2.3
## 597: virginica  Petal.Width   1.9
## 598: virginica  Petal.Width   2.0
## 599: virginica  Petal.Width   2.3
## 600: virginica  Petal.Width   1.8
```

``` r
tidyr::pivot_longer(iris, cols.to.reshape, values_to = "cm")
```

```
## # A tibble: 600 × 3
##    Species name            cm
##    <fct>   <chr>        <dbl>
##  1 setosa  Sepal.Length   5.1
##  2 setosa  Sepal.Width    3.5
##  3 setosa  Petal.Length   1.4
##  4 setosa  Petal.Width    0.2
##  5 setosa  Sepal.Length   4.9
##  6 setosa  Sepal.Width    3  
##  7 setosa  Petal.Length   1.4
##  8 setosa  Petal.Width    0.2
##  9 setosa  Sepal.Length   4.7
## 10 setosa  Sepal.Width    3.2
## # ℹ 590 more rows
```

``` r
head(collapse::pivot(iris, values=cols.to.reshape, names=list("variable", "cm")))
```

```
##   Species     variable  cm
## 1  setosa Sepal.Length 5.1
## 2  setosa Sepal.Length 4.9
## 3  setosa Sepal.Length 4.7
## 4  setosa Sepal.Length 4.6
## 5  setosa Sepal.Length 5.0
## 6  setosa Sepal.Length 5.4
```

Below we define a larger version of iris data, as a function of number
of rows `N`:


``` r
N <- 250
(row.id.vec <- 1+(seq(0,N-1) %% nrow(iris)))
```

```
##   [1]   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  25  26  27  28
##  [29]  29  30  31  32  33  34  35  36  37  38  39  40  41  42  43  44  45  46  47  48  49  50  51  52  53  54  55  56
##  [57]  57  58  59  60  61  62  63  64  65  66  67  68  69  70  71  72  73  74  75  76  77  78  79  80  81  82  83  84
##  [85]  85  86  87  88  89  90  91  92  93  94  95  96  97  98  99 100 101 102 103 104 105 106 107 108 109 110 111 112
## [113] 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140
## [141] 141 142 143 144 145 146 147 148 149 150   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18
## [169]  19  20  21  22  23  24  25  26  27  28  29  30  31  32  33  34  35  36  37  38  39  40  41  42  43  44  45  46
## [197]  47  48  49  50  51  52  53  54  55  56  57  58  59  60  61  62  63  64  65  66  67  68  69  70  71  72  73  74
## [225]  75  76  77  78  79  80  81  82  83  84  85  86  87  88  89  90  91  92  93  94  95  96  97  98  99 100
```

``` r
N.df <- iris[row.id.vec,]
(N.dt <- data.table(N.df))
```

```
##      Sepal.Length Sepal.Width Petal.Length Petal.Width    Species
##             <num>       <num>        <num>       <num>     <fctr>
##   1:          5.1         3.5          1.4         0.2     setosa
##   2:          4.9         3.0          1.4         0.2     setosa
##   3:          4.7         3.2          1.3         0.2     setosa
##   4:          4.6         3.1          1.5         0.2     setosa
##   5:          5.0         3.6          1.4         0.2     setosa
##  ---                                                             
## 246:          5.7         3.0          4.2         1.2 versicolor
## 247:          5.7         2.9          4.2         1.3 versicolor
## 248:          6.2         2.9          4.3         1.3 versicolor
## 249:          5.1         2.5          3.0         1.1 versicolor
## 250:          5.7         2.8          4.1         1.3 versicolor
```

Below we use `atime` to compare the performance of the reshape
functions:


``` r
a.res <- atime::atime(
  setup={
    (row.id.vec <- 1+(seq(0,N-1) %% nrow(iris)))
    N.df <- iris[row.id.vec,]
    (N.dt <- data.table(N.df))
  },
  seconds.limit=0.1,
  reshape_taller=reshape_taller(N.df,1:4),
  "stats::reshape"=stats::reshape(N.df, direction="long", varying=list(cols.to.reshape), v.names="cm"),
  "data.table::melt"=melt(N.dt, measure.vars=cols.to.reshape, value.name="cm"),
  "tidyr::pivot_longer"=tidyr::pivot_longer(N.df, cols.to.reshape, values_to = "cm"),
  "collapse::pivot"=collapse::pivot(N.df, values=cols.to.reshape, names=list("variable", "cm")))
a.refs <- atime::references_best(a.res)
a.pred <- predict(a.refs)
plot(a.pred)+coord_cartesian(xlim=c(1e2,1e7))
```

```
## Warning in ggplot2::scale_x_log10("N", breaks = meas[, 10^seq(ceiling(min(log10(N))), : log-10 transformation
## introduced infinite values.
```

![plot of chunk atime-tall](/assets/img/2024-08-05-collapse-reshape/atime-tall-1.png)

## reshape wider

Above we did a wide to tall reshape. The inverse of that operation is
a tall to wide reshape,


``` r
matrix(
  two.iris.tall$cm, nrow(two.iris.wide), length(cols.to.reshape),
  dimnames = list(
    two.iris.tall$row.name[1:nrow(two.iris.wide)],
    cols.to.reshape))
```

```
##     Sepal.Length Sepal.Width Petal.Length Petal.Width
## 1            5.1         3.5          1.4         0.2
## 150          5.9         3.0          5.1         1.8
```

More generically to do that, we would need to consider missing
entries, as in the code below.


``` r
reshape_wider <- function(DF){
  dimnames <- list()
  other.names <- setdiff(
    names(DF),
    c("orig.row.i", "orig.row.name", "orig.col.i", "orig.col.name", "value"))
  for(dim.type in c('row','col')){
    f <- function(suffix)paste0('orig.',dim.type,'.',suffix)
    u <- unique(DF[, c(
      f(c("i","name")),
      if(dim.type=='row')other.names
    )])
    s <- u[order(u[,f("i")]), ]
    dimnames[[dim.type]] <- s[, f("name")]
    if(dim.type=='row')other.df <- s[,other.names,drop=FALSE]
  }
  mat <- matrix(
    NA_real_, length(dimnames$row), length(dimnames$col),
    dimnames = dimnames)
  mat[cbind(DF$orig.row.i, DF$orig.col.i)] <- DF$value
  data.frame(mat, other.df)
}
(missing.one <- reshape_taller(two.iris.wide,1:4)[-1,])
```

```
##   orig.row.i orig.row.name orig.col.i orig.col.name   Species value
## 2          2           150          1  Sepal.Length virginica   5.9
## 3          1             1          2   Sepal.Width    setosa   3.5
## 4          2           150          2   Sepal.Width virginica   3.0
## 5          1             1          3  Petal.Length    setosa   1.4
## 6          2           150          3  Petal.Length virginica   5.1
## 7          1             1          4   Petal.Width    setosa   0.2
## 8          2           150          4   Petal.Width virginica   1.8
```

``` r
reshape_wider(missing.one)
```

```
##     Sepal.Length Sepal.Width Petal.Length Petal.Width   Species
## 1             NA         3.5          1.4         0.2    setosa
## 150          5.9         3.0          5.1         1.8 virginica
```

Other functions for doing that below:


``` r
library(data.table)
N.tall.df <- reshape_taller(N.df,1:4)
str(reshape_wider(N.tall.df))
```

```
## 'data.frame':	250 obs. of  5 variables:
##  $ Sepal.Length: num  5.1 4.9 4.7 4.6 5 5.4 4.6 5 4.4 4.9 ...
##  $ Sepal.Width : num  3.5 3 3.2 3.1 3.6 3.9 3.4 3.4 2.9 3.1 ...
##  $ Petal.Length: num  1.4 1.4 1.3 1.5 1.4 1.7 1.4 1.5 1.4 1.5 ...
##  $ Petal.Width : num  0.2 0.2 0.2 0.2 0.2 0.4 0.3 0.2 0.2 0.1 ...
##  $ Species     : Factor w/ 3 levels "setosa","versicolor",..: 1 1 1 1 1 1 1 1 1 1 ...
```

``` r
N.tall.dt <- data.table(N.tall.df)
str(dcast(N.tall.dt, orig.row.i ~ orig.col.name, value.var = "value"))
```

```
## Classes 'data.table' and 'data.frame':	250 obs. of  5 variables:
##  $ orig.row.i  : int  1 2 3 4 5 6 7 8 9 10 ...
##  $ Petal.Length: num  1.4 1.4 1.3 1.5 1.4 1.7 1.4 1.5 1.4 1.5 ...
##  $ Petal.Width : num  0.2 0.2 0.2 0.2 0.2 0.4 0.3 0.2 0.2 0.1 ...
##  $ Sepal.Length: num  5.1 4.9 4.7 4.6 5 5.4 4.6 5 4.4 4.9 ...
##  $ Sepal.Width : num  3.5 3 3.2 3.1 3.6 3.9 3.4 3.4 2.9 3.1 ...
##  - attr(*, ".internal.selfref")=<externalptr> 
##  - attr(*, "sorted")= chr "orig.row.i"
```

``` r
str(stats::reshape(N.tall.df, direction = "wide", idvar=c("orig.row.i","Species"), timevar="orig.col.name", v.names="value"))
```

```
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
```

```
## 'data.frame':	250 obs. of  8 variables:
##  $ orig.row.i        : int  1 2 3 4 5 6 7 8 9 10 ...
##  $ orig.row.name     : chr  "1" "2" "3" "4" ...
##  $ orig.col.i        : int  1 1 1 1 1 1 1 1 1 1 ...
##  $ Species           : Factor w/ 3 levels "setosa","versicolor",..: 1 1 1 1 1 1 1 1 1 1 ...
##  $ value.Sepal.Length: num  5.1 4.9 4.7 4.6 5 5.4 4.6 5 4.4 4.9 ...
##  $ value.Sepal.Width : num  3.5 3 3.2 3.1 3.6 3.9 3.4 3.4 2.9 3.1 ...
##  $ value.Petal.Length: num  1.4 1.4 1.3 1.5 1.4 1.7 1.4 1.5 1.4 1.5 ...
##  $ value.Petal.Width : num  0.2 0.2 0.2 0.2 0.2 0.4 0.3 0.2 0.2 0.1 ...
##  - attr(*, "reshapeWide")=List of 5
##   ..$ v.names: chr "value"
##   ..$ timevar: chr "orig.col.name"
##   ..$ idvar  : chr [1:2] "orig.row.i" "Species"
##   ..$ times  : chr [1:4] "Sepal.Length" "Sepal.Width" "Petal.Length" "Petal.Width"
##   ..$ varying: chr [1, 1:4] "value.Sepal.Length" "value.Sepal.Width" "value.Petal.Length" "value.Petal.Width"
```

``` r
str(tidyr::pivot_wider(N.tall.df, names_from=orig.col.name, values_from=value, id_cols=orig.row.i))
```

```
## tibble [250 × 5] (S3: tbl_df/tbl/data.frame)
##  $ orig.row.i  : int [1:250] 1 2 3 4 5 6 7 8 9 10 ...
##  $ Sepal.Length: num [1:250] 5.1 4.9 4.7 4.6 5 5.4 4.6 5 4.4 4.9 ...
##  $ Sepal.Width : num [1:250] 3.5 3 3.2 3.1 3.6 3.9 3.4 3.4 2.9 3.1 ...
##  $ Petal.Length: num [1:250] 1.4 1.4 1.3 1.5 1.4 1.7 1.4 1.5 1.4 1.5 ...
##  $ Petal.Width : num [1:250] 0.2 0.2 0.2 0.2 0.2 0.4 0.3 0.2 0.2 0.1 ...
```

``` r
str(collapse::pivot(N.tall.df, how="w", ids="orig.row.i", values="value", names="orig.col.name"))
```

```
## 'data.frame':	250 obs. of  5 variables:
##  $ orig.row.i  : int  1 2 3 4 5 6 7 8 9 10 ...
##  $ Sepal.Length: num  5.1 4.9 4.7 4.6 5 5.4 4.6 5 4.4 4.9 ...
##  $ Sepal.Width : num  3.5 3 3.2 3.1 3.6 3.9 3.4 3.4 2.9 3.1 ...
##  $ Petal.Length: num  1.4 1.4 1.3 1.5 1.4 1.7 1.4 1.5 1.4 1.5 ...
##  $ Petal.Width : num  0.2 0.2 0.2 0.2 0.2 0.4 0.3 0.2 0.2 0.1 ...
```

Timings below


``` r
w.res <- atime::atime(
  setup={
    (row.id.vec <- 1+(seq(0,N-1) %% nrow(iris)))
    N.df <- iris[row.id.vec,]
    N.tall.df <- reshape_taller(N.df,1:4)
    N.tall.dt <- data.table(N.tall.df)
  },
  seconds.limit=0.1,
  "reshape\nwider"=reshape_wider(N.tall.df),
  "data.table\ndcast"=dcast(N.tall.dt, orig.row.i ~ orig.col.name, value.var = "value"),
  "stats\nreshape"=stats::reshape(N.tall.df, direction = "wide", idvar=c("orig.row.i","Species"), timevar="orig.col.name", v.names="value"),
  "tidyr\npivot_wider"=tidyr::pivot_wider(N.tall.df, names_from=orig.col.name, values_from=value, id_cols=orig.row.i),
  "collapse\npivot"=collapse::pivot(N.tall.df, how="w", ids="orig.row.i", values="value", names="orig.col.name"))
```

```
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : certaines variables constantes
## (orig.col.i) varient
```

``` r
w.refs <- atime::references_best(w.res)
w.pred <- predict(w.refs)
plot(w.pred)+coord_cartesian(xlim=c(NA,1e8))
```

```
## Warning in ggplot2::scale_x_log10("N", breaks = meas[, 10^seq(ceiling(min(log10(N))), : log-10 transformation
## introduced infinite values.
```

![plot of chunk atime-wide](/assets/img/2024-08-05-collapse-reshape/atime-wide-1.png)

The comparison above shows that collapse is actually quite a bit
faster (50x) for this tall to wide reshape operation which involved
just copying data (no summarization).

## Conclusion

We have shown how to use `atime` to check if there are any performance differences between data reshaping functions in R.
