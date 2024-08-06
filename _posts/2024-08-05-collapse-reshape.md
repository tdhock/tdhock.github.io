---
layout: post
title: Collapse reshape benchmark
description: Comparison with data.table
---

[data.table](https://github.com/rdatatable/data.table) is an R package
for efficient data manipulation.  I have an NSF POSE grant about
expanding the open-source ecosystem of users and contributors around
`data.table`.  Part of that project is benchmarking time and memory
usage, and comparing with similar packages.  Similar to previous posts
about
[reshaping](https://tdhock.github.io/blog/2024/reshape-performance/)
and
[reading/writing/summarization](https://tdhock.github.io/blog/2023/dt-atime-figures/),
the goal of this post is to explain how to use
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
  N=2^seq(1,50),
  setup={
    (row.id.vec <- 1+(seq(0,N-1) %% nrow(iris)))
    N.df <- iris[row.id.vec,]
    (N.dt <- data.table(N.df))
  },
  seconds.limit=0.1,
  "stats\nreshape"=suppressWarnings(stats::reshape(N.df, direction="long", varying=list(cols.to.reshape), v.names="cm")),
  "data.table\nmelt"=melt(N.dt, measure.vars=cols.to.reshape, value.name="cm"),
  "tidyr\npivot_longer"=tidyr::pivot_longer(N.df, cols.to.reshape, values_to = "cm"),
  "collapse\npivot"=collapse::pivot(N.df, values=cols.to.reshape, names=list("variable", "cm")))
a.refs <- atime::references_best(a.res)
a.pred <- predict(a.refs)
plot(a.pred)+coord_cartesian(xlim=c(1e2,1e7))
```

```
## Warning in ggplot2::scale_x_log10("N", breaks = meas[, 10^seq(ceiling(min(log10(N))), : log-10 transformation
## introduced infinite values.
```

![plot of chunk atime-tall](/assets/img/2024-08-05-collapse-reshape/atime-tall-1.png)

The result above shows that `collapse` is fastest, but `data.table` is
almost as fast (by small a constant factor).

## Regex and multiple column support

In my [paper about the nc
package](https://journal.r-project.org/archive/2021/RJ-2021-029/index.html),
I proposed a new syntax for defining wide-to-tall reshape operations,
using regular expressions (regex). The motivating example in that
paper was a scatterplot to show that Sepals are larger than
Petals, as we see in the code/plot below.


``` r
iris.parts <- nc::capture_melt_multiple(iris.dt, column=".*", "[.]", dim=".*")
ggplot()+
  geom_point(aes(
    Petal, Sepal, color=Species),
    data=iris.parts)+
  facet_grid(. ~ dim, labeller=label_both)+
  coord_equal()+
  theme_bw()+
  geom_abline(slope=1, intercept=0, color="grey50")
```

![plot of chunk iris-scatter](/assets/img/2024-08-05-collapse-reshape/iris-scatter-1.png)

Other ways to do that reshape operation are shown in the code below:


``` r
stats::reshape(two.iris.wide, cols.to.reshape, direction="long", timevar="dim", sep=".")
```

```
##            Species    dim Sepal Petal id
## 1.Length    setosa Length   5.1   1.4  1
## 2.Length virginica Length   5.9   5.1  2
## 1.Width     setosa  Width   3.5   0.2  1
## 2.Width  virginica  Width   3.0   1.8  2
```

``` r
melt(data.table(two.iris.wide), measure.vars=measure(value.name, part, pattern="(.*)[.](.*)"))
```

```
##      Species   part Sepal Petal
##       <fctr> <char> <num> <num>
## 1:    setosa Length   5.1   1.4
## 2: virginica Length   5.9   5.1
## 3:    setosa  Width   3.5   0.2
## 4: virginica  Width   3.0   1.8
```

``` r
tidyr::pivot_longer(two.iris.wide, cols.to.reshape, names_pattern = "(.*)[.](.*)", names_to = c(".value","part"))
```

```
## # A tibble: 4 × 4
##   Species   part   Sepal Petal
##   <fct>     <chr>  <dbl> <dbl>
## 1 setosa    Length   5.1   1.4
## 2 setosa    Width    3.5   0.2
## 3 virginica Length   5.9   5.1
## 4 virginica Width    3     1.8
```

However `?collapse::pivot` explains that it "currently does not
support concurrently melting/pivoting longer to multiple columns."
Below we compare the performance of these methods:


``` r
r.res <- atime::atime(
  N=2^seq(1,50),
  setup={
    (row.id.vec <- 1+(seq(0,N-1) %% nrow(iris)))
    N.df <- iris[row.id.vec,]
    (N.dt <- data.table(N.df))
  },
  seconds.limit=0.1,
  "nc::capture\nmelt_multiple"=nc::capture_melt_multiple(N.dt, column=".*", "[.]", dim=".*"),
  "stats\nreshape"=stats::reshape(N.df, cols.to.reshape, direction="long", timevar="dim", sep="."),
  "data.table\nmeasure"=melt(N.dt, measure.vars=measure(value.name, part, pattern="(.*)[.](.*)")),
  "tidyr\nnames_pattern"=tidyr::pivot_longer(N.df, cols.to.reshape, names_pattern = "(.*)[.](.*)", names_to = c(".value","part")))
r.refs <- atime::references_best(r.res)
r.pred <- predict(r.refs)
plot(r.pred)+coord_cartesian(xlim=c(1e2,1e7))
```

```
## Warning in ggplot2::scale_x_log10("N", breaks = meas[, 10^seq(ceiling(min(log10(N))), : log-10 transformation
## introduced infinite values.
```

![plot of chunk atime-regex](/assets/img/2024-08-05-collapse-reshape/atime-regex-1.png)

## Reshape wider

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
## Warning in reshapeWide(data, idvar = idvar, timevar = timevar, varying = varying, : some constant variables
## (orig.col.i) are really varying
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

In all of the code examples above there are a few common elements

* ID: used to identify unique output rows must be specified, 
* Name: used for column names of output,
* Value: used to fill in elements of output.

| function             | ID             | Name           | Value         |
|----------------------|----------------|----------------|---------------|
| `data.table::dcast`  | LHS of formula | RHS of formula | `value.var`   |
| `stats::reshape`     | `idvar`        | `timevar`      | `v.names`     |
| `tidyr::pivot_wider` | `id_cols`      | `names_from`   | `values_from` |
| `collapse::pivot`    | `ids`          | `names`        | `values`      |

Timings below


``` r
w.res <- atime::atime(
  N=2^seq(1,50),
  setup={
    (row.id.vec <- 1+(seq(0,N-1) %% nrow(iris)))
    N.df <- iris[row.id.vec,]
    N.tall.df <- reshape_taller(N.df,1:4)
    N.tall.dt <- data.table(N.tall.df)
  },
  seconds.limit=0.1,
  "data.table\ndcast"=dcast(N.tall.dt, orig.row.i ~ orig.col.name, value.var = "value"),
  "stats\nreshape"=suppressWarnings(stats::reshape(N.tall.df, direction = "wide", idvar=c("orig.row.i","Species"), timevar="orig.col.name", v.names="value")),
  "tidyr\npivot_wider"=tidyr::pivot_wider(N.tall.df, names_from=orig.col.name, values_from=value, id_cols=orig.row.i),
  "collapse\npivot"=collapse::pivot(N.tall.df, how="w", ids="orig.row.i", values="value", names="orig.col.name"))
w.refs <- atime::references_best(w.res)
w.pred <- predict(w.refs)
plot(w.pred)+coord_cartesian(xlim=c(NA,1e7))
```

```
## Warning in ggplot2::scale_x_log10("N", breaks = meas[, 10^seq(ceiling(min(log10(N))), : log-10 transformation
## introduced infinite values.
```

![plot of chunk atime-wide](/assets/img/2024-08-05-collapse-reshape/atime-wide-1.png)

The comparison above shows that `collapse` is actually a bit faster
than `data.table`, for this tall to wide reshape operation which
involved just copying data (no summarization). But close inspection of
the log-log plot above shows different slopes for the different lines,
which suggests that they have different asymptotic complexity
classes. To estimate them, we use the code below,


``` r
plot(w.refs)
```

```
## Warning in ggplot2::scale_y_log10(""): log-10 transformation introduced infinite values.
```

![plot of chunk atime-wide-refs](/assets/img/2024-08-05-collapse-reshape/atime-wide-refs-1.png)

The plot above suggests that all methods have the same linear asymptotic memory usage, O(N).
But `data.table` is the only method which is clearly linear time.

* `collapse::pivot` and `tidyr::pivot_wider` appear to be log-linear, O(N log N).
* `stats::reshape` appears between linear and log-linear.

## Reshape wider with summarization

Sometimes we want to do a reshape wider operation with summarization
functions. For example, in the code below, we use `mean` for every `orig.col.name` and `Species`:


``` r
dcast(N.tall.dt, orig.col.name + Species ~ ., mean)
```

```
## Key: <orig.col.name, Species>
##     orig.col.name    Species     .
##            <char>     <fctr> <num>
##  1:  Petal.Length     setosa 1.462
##  2:  Petal.Length versicolor 4.260
##  3:  Petal.Length  virginica 5.552
##  4:   Petal.Width     setosa 0.246
##  5:   Petal.Width versicolor 1.326
##  6:   Petal.Width  virginica 2.026
##  7:  Sepal.Length     setosa 5.006
##  8:  Sepal.Length versicolor 5.936
##  9:  Sepal.Length  virginica 6.588
## 10:   Sepal.Width     setosa 3.428
## 11:   Sepal.Width versicolor 2.770
## 12:   Sepal.Width  virginica 2.974
```

``` r
stats::aggregate(N.tall.df[,"value",drop=FALSE], by=with(N.tall.df, list(orig.col.name=orig.col.name,Species=Species)), FUN=mean)
```

```
##    orig.col.name    Species value
## 1   Petal.Length     setosa 1.462
## 2    Petal.Width     setosa 0.246
## 3   Sepal.Length     setosa 5.006
## 4    Sepal.Width     setosa 3.428
## 5   Petal.Length versicolor 4.260
## 6    Petal.Width versicolor 1.326
## 7   Sepal.Length versicolor 5.936
## 8    Sepal.Width versicolor 2.770
## 9   Petal.Length  virginica 5.552
## 10   Petal.Width  virginica 2.026
## 11  Sepal.Length  virginica 6.588
## 12   Sepal.Width  virginica 2.974
```

``` r
N.tall.df$name <- "foo"
tidyr::pivot_wider(N.tall.df, names_from=name, values_from=value, id_cols=c(orig.col.name,Species), values_fn=mean)
```

```
## # A tibble: 12 × 3
##    orig.col.name Species      foo
##    <chr>         <fct>      <dbl>
##  1 Sepal.Length  setosa     5.01 
##  2 Sepal.Length  versicolor 5.94 
##  3 Sepal.Length  virginica  6.59 
##  4 Sepal.Width   setosa     3.43 
##  5 Sepal.Width   versicolor 2.77 
##  6 Sepal.Width   virginica  2.97 
##  7 Petal.Length  setosa     1.46 
##  8 Petal.Length  versicolor 4.26 
##  9 Petal.Length  virginica  5.55 
## 10 Petal.Width   setosa     0.246
## 11 Petal.Width   versicolor 1.33 
## 12 Petal.Width   virginica  2.03
```

``` r
collapse::pivot(N.tall.df, how="w", ids=c("orig.col.name","Species"), values="value", names="name", FUN=mean)
```

```
##    orig.col.name    Species   foo
## 1   Sepal.Length     setosa 5.006
## 2   Sepal.Length versicolor 5.936
## 3   Sepal.Length  virginica 6.588
## 4    Sepal.Width     setosa 3.428
## 5    Sepal.Width versicolor 2.770
## 6    Sepal.Width  virginica 2.974
## 7   Petal.Length     setosa 1.462
## 8   Petal.Length versicolor 4.260
## 9   Petal.Length  virginica 5.552
## 10   Petal.Width     setosa 0.246
## 11   Petal.Width versicolor 1.326
## 12   Petal.Width  virginica 2.026
```

Note in the code above that to get the `tidyr` and `collapse` methods
to work, a "name" column must be created, whereas in `data.table` it
not necessary (you just specify `.` in right side of formula to
indicate that only one column should be output). The table below summarizes the differences in syntax between the different R functions:

| function             | ID             | Name             | Value            | Aggregation     |
|----------------------|----------------|------------------|------------------|-----------------|
| `data.table::dcast`  | LHS of formula | RHS of formula   | `value.var`      | `fun.aggregate` |
| `stats::aggregate`   | `by`           | all column names | all input values | `FUN`           |
| `tidyr::pivot_wider` | `id_cols`      | `names_from`     | `values_from`    | `values_fn`     |
| `collapse::pivot`    | `ids`          | `names`          | `values`         | `FUN`           |

Below we compare the performance of these different functions.


``` r
m.res <- atime::atime(
  N=2^seq(1,50),
  setup={
    (row.id.vec <- 1+(seq(0,N-1) %% nrow(iris)))
    N.df <- iris[row.id.vec,]
    N.tall.df <- reshape_taller(N.df,1:4)
    N.tall.df$name <- "foo"
    N.tall.dt <- data.table(N.tall.df)
  },
  seconds.limit=0.1,
  "stats\naggregate"=stats::aggregate(N.tall.df[,"value",drop=FALSE], by=with(N.tall.df, list(orig.col.name=orig.col.name,Species=Species)), FUN=mean),
  "tidyr\npivot_wider"=tidyr::pivot_wider(N.tall.df, names_from=name, values_from=value, id_cols=c(orig.col.name,Species), values_fn=mean),
  "collapse\npivot"=collapse::pivot(N.tall.df, how="w", ids=c("orig.col.name","Species"), values="value", names="name", FUN=mean),
  "data.table\ndcast"=dcast(N.tall.dt, orig.col.name + Species ~ ., mean))
m.refs <- atime::references_best(m.res)
m.pred <- predict(m.refs)
plot(m.pred)+coord_cartesian(xlim=c(NA,1e7))
```

```
## Warning in ggplot2::scale_x_log10("N", breaks = meas[, 10^seq(ceiling(min(log10(N))), : log-10 transformation
## introduced infinite values.
```

![plot of chunk atime-agg](/assets/img/2024-08-05-collapse-reshape/atime-agg-1.png)

The result above shows that `data.table` is a bit faster than
`collapse`. Upon close inspection of the log-log plot above, we see
that `data.table` has a smaller slope than `collapse`, which means
that `data.table has an asymptotically more efficient complexity
class. To estimate the asymptotic complexity class, we can use the
plot below.


``` r
plot(m.refs)
```

```
## Warning in ggplot2::scale_y_log10(""): log-10 transformation introduced infinite values.
```

![plot of chunk atime-agg-refs](/assets/img/2024-08-05-collapse-reshape/atime-agg-refs-1.png)

The plot above indicates that all methods use asymptotically linear memory, O(N).
It also suggests that `collapse` and `stats` are asymptotically log-linear time,
`O(N log N)`, in the number of input rows `N`, whereas `data.table` and `tidyr` are
linear time, `O(N)`.

## Multiple aggregation functions

It is often useful to provide a list of aggregation functions, instead of just one. For example, in visualization results of machine learning predictions, we would like to use

* `mean` to compute the mean prediction error over several train/test splits,
* `sd` to get the standard deviation,
* `length` to double-check that the number of items to summarize is the same as the number of cross-validation folds.

In `data.table` we can provide a list of functions as in the code below,


``` r
dcast(N.tall.dt, orig.col.name + Species ~ ., list(mean, sd, length))
```

```
## Key: <orig.col.name, Species>
##     orig.col.name    Species value_mean  value_sd value_length
##            <char>     <fctr>      <num>     <num>        <int>
##  1:  Petal.Length     setosa      1.462 0.1727847          100
##  2:  Petal.Length versicolor      4.260 0.4675317          100
##  3:  Petal.Length  virginica      5.552 0.5518947           50
##  4:   Petal.Width     setosa      0.246 0.1048520          100
##  5:   Petal.Width versicolor      1.326 0.1967514          100
##  6:   Petal.Width  virginica      2.026 0.2746501           50
##  7:  Sepal.Length     setosa      5.006 0.3507049          100
##  8:  Sepal.Length versicolor      5.936 0.5135576          100
##  9:  Sepal.Length  virginica      6.588 0.6358796           50
## 10:   Sepal.Width     setosa      3.428 0.3771450          100
## 11:   Sepal.Width versicolor      2.770 0.3122095          100
## 12:   Sepal.Width  virginica      2.974 0.3224966           50
```

However this feature is not supported in other packages. 

* `?stats::aggregate` says "FUN: a function to compute the summary
  statistics which can be applied to all data subsets."
* `?collapse::pivot` says "FUN: function to aggregate values. At
  present, only a single function is allowed."
* `?tidyr::pivot_wider` says `values_fn` argument "can be a named list
  if you want to apply different aggregations to different
  `values_from` columns."

## Conclusion

We have shown how to use `atime` to check if there are any performance
differences between data reshaping functions in R. We observed large
differences between functions when doing a reshape in the wider
direction, with no aggregation (`collapse` is about 50x faster than
`data.table` for this case, which involves just copying values to a
new table). For reshape in the tall/long direction, and for reshape
wider with aggregation, we observed small constant factor differences
between methods (`collapse` was still fastest but by only 2x).

In terms of functionality, we observed a few differences. Wide-to-tall
reshape defined by a `regex` is supported by
`tidyr::pivot_longer(names_pattern=regex)` and
`data.table::measure(pattern=regex)`, whereas `stats::reshape` only
supports multiple outputs via the `sep` argument (separator, not
regex), and `collapse::pivot` does not support multiple outputs at
all. Also, we observed that `data.table::dcast` is the only function
that supports multiple aggregation functions, which can be useful for
simultaneously computing a variety of summary statistics, such as
`mean`, `sd`, and `length`. The table below summarizes these
differences in functionality.

|              | reshape long     | reshape long | reshape wide  | reshape wide | reshape wide |
| package      | multiple outputs | using regex  | multiple agg. | single agg.  | no agg.      |
|--------------|------------------|--------------|---------------|--------------|--------------|
| `data.table` | yes              | yes          | yes           | O(N)         | O(N)         |
| `tidyr`      | yes              | yes          | no            | O(N)         | O(N log N)   |
| `stats`      | yes              | no           | no            | O(N log N)   | O(N log N)   |
| `collapse`   | no               | no           | no            | O(N log N)   | O(N log N)   |

For future work, 

* `data.table`/`tidyr` may consider trying to speed up the constant factors in the reshape wide code without aggregation.
* `collapse` reshape wide with aggregation is currently asymptotically log-linear, and so may consider speeding up to be asymptotically linear.
* `tidyr`/`collapse` may consider implementing the advanced reshaping features that `data.table` currently supports (multiple outputs, regex).

## Session info


``` r
sessionInfo()
```

```
## R version 4.4.1 (2024-06-14 ucrt)
## Platform: x86_64-w64-mingw32/x64
## Running under: Windows 11 x64 (build 22631)
## 
## Matrix products: default
## 
## 
## locale:
## [1] LC_COLLATE=English_United States.utf8  LC_CTYPE=English_United States.utf8    LC_MONETARY=English_United States.utf8
## [4] LC_NUMERIC=C                           LC_TIME=English_United States.utf8    
## 
## time zone: America/Toronto
## tzcode source: internal
## 
## attached base packages:
## [1] stats     graphics  utils     datasets  grDevices methods   base     
## 
## other attached packages:
## [1] data.table_1.15.4 ggplot2_3.5.1    
## 
## loaded via a namespace (and not attached):
##  [1] gtable_0.3.5           dplyr_1.1.4            compiler_4.4.1         highr_0.11             crayon_1.5.3          
##  [6] tidyselect_1.2.1       Rcpp_1.0.12            collapse_2.0.15        parallel_4.4.1         tidyr_1.3.1           
## [11] scales_1.3.0           directlabels_2024.1.21 lattice_0.22-6         R6_2.5.1               labeling_0.4.3        
## [16] generics_0.1.3         knitr_1.48             tibble_3.2.1           munsell_0.5.1          atime_2024.4.23       
## [21] pillar_1.9.0           rlang_1.1.4            utf8_1.2.4             xfun_0.45              quadprog_1.5-8        
## [26] cli_3.6.3              withr_3.0.0            magrittr_2.0.3         grid_4.4.1             nc_2024.2.21          
## [31] lifecycle_1.0.4        vctrs_0.6.5            bench_1.1.3            evaluate_0.24.0        glue_1.7.0            
## [36] farver_2.1.2           profmem_0.6.0          fansi_1.0.6            colorspace_2.1-0       purrr_1.0.2           
## [41] tools_4.4.1            pkgconfig_2.0.3
```
