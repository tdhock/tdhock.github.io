---
layout: post
title: Simple methods for defining small data by row
description: Comparison with base R and tribble
---


It is often useful to define a small data frame literally in R code,
and we show a simple way to do this in base R.

## A few examples

In [our recent paper about spatially explicit stochastic disease
models](https://www.medrxiv.org/content/10.1101/2021.05.13.21256216v1)
(currently in peer review), there is some R code that defines time
windows. It was my suggestion to present the data/code as follows,
with each time window on a line:


```r
one.window <- function(start, end, r0)data.frame(start, end, r0)
library(lubridate)
(time.window.args <- rbind(# Specify the components of 5 time windows
  one.window(mdy("1-1-20"),mdy("1-31-20"),3.0),
  one.window(mdy("2-1-20"),mdy("2-15-20"),0.8),
  one.window(mdy("2-16-20"),mdy("3-10-20"),0.8),
  one.window(mdy("3-11-20"),mdy("3-21-20"),1.4),
  one.window(mdy("3-22-20"),mdy("5-1-20"),1.4)))
```

```
##        start        end  r0
## 1 2020-01-01 2020-01-31 3.0
## 2 2020-02-01 2020-02-15 0.8
## 3 2020-02-16 2020-03-10 0.8
## 4 2020-03-11 2020-03-21 1.4
## 5 2020-03-22 2020-05-01 1.4
```

Another example comes from [code to make a figure showing label
errors in an upcoming paper about a Functional Labeled Optimal
Partitioning (FLOPART)
algorithm](https://github.com/tdhock/LabeledFPOP-paper/blob/master/figure-Mono27ac-new-labels.R).


```r
lab <- function(chromStart, chromEnd, annotation){
  data.frame(chrom="chr11", chromStart, chromEnd, annotation)
}
(new.labels <- rbind(
  lab(100000, 200000, "noPeaks"),
  lab(206000, 207000, "peakStart"),
  lab(208000, 220000, "peakEnd"),
  lab(300000, 308250, "peakStart"),
  lab(308260, 320000, "peakEnd")))
```

```
##   chrom chromStart chromEnd annotation
## 1 chr11     100000   200000    noPeaks
## 2 chr11     206000   207000  peakStart
## 3 chr11     208000   220000    peakEnd
## 4 chr11     300000   308250  peakStart
## 5 chr11     308260   320000    peakEnd
```

A third example comes from [code to make a timings figure for our
upcoming paper about gradient-based optimization of the Area Under the
Minimum (AUM) of false positive and false negative
functions](https://github.com/tdhock/max-generalized-auc/blob/master/figure-aum-grad-speed.R).


```r
finfo <- function(Problem, file.csv, col.name, col.value){
  data.frame(Problem, file.csv, col.name, col.value)
}
(csv.file.info <- rbind(
  finfo("Changepoint detection","figure-aum-grad-speed-data.csv","pred.type","pred.rnorm"),
  finfo("Binary classification","figure-aum-grad-speed-binary-cpp-data.csv","prediction.order","unsorted")))
```

```
##                 Problem                                  file.csv         col.name  col.value
## 1 Changepoint detection            figure-aum-grad-speed-data.csv        pred.type pred.rnorm
## 2 Binary classification figure-aum-grad-speed-binary-cpp-data.csv prediction.order   unsorted
```

## Remove repetition

In the code above we need to repeat the column names twice: once in
the function arguments, another time in the function body. How can we
remove this repetition? We can use R meta-programming, as in the
function below:


```r
row_fun <- function(...){
  form.list <- as.list(match.call()[-1])
  sym <- sapply(form.list, is.symbol)
  names(form.list)[sym] <- form.list[sym]
  form.list[sym] <- NA
  make_row <- function(){}
  formals(make_row) <- form.list
  symbol.names <- c("data.frame", names(form.list))
  body(make_row) <- as.call(lapply(symbol.names, as.symbol))
  make_row
}
```

The function above creates and returns a function which outputs a data
frame:



```r
(win <- row_fun(start, end, r0))
```

```
## function (start = NA, end = NA, r0 = NA) 
## data.frame(start, end, r0)
## <environment: 0x9f39120>
```

```r
win(1, 2, 3)
```

```
##   start end r0
## 1     1   2  3
```

This may be useful if you want to define several different tables with
the same column names: 


```r
lab <- row_fun(chromStart, chromEnd, annotation, chrom="chr11") 
(fig1.labels <- rbind(
  lab(100, 200, "noPeaks"),
  lab(300, 350, "peakStart")))
```

```
##   chromStart chromEnd annotation chrom
## 1        100      200    noPeaks chr11
## 2        300      350  peakStart chr11
```

```r
(fig2.labels <- rbind(
  lab(100, 150, "noPeaks"),
  lab(200, 250, "peakEnd")))
```

```
##   chromStart chromEnd annotation chrom
## 1        100      150    noPeaks chr11
## 2        200      250    peakEnd chr11
```

The code above does not have the repetition of column names, but it
does require repeating the row-making function name, `lab`.

## Comparison with tribble

There is a similar function,


```r
(fig1.labels <- tibble::tribble(
  ~chromStart, ~chromEnd, ~annotation, ~chrom,
  100, 200, "noPeaks", "chr11",
  300, 350, "peakStart", "chr11"))
```

```
## # A tibble: 2 x 4
##   chromStart chromEnd annotation chrom
##        <dbl>    <dbl> <chr>      <chr>
## 1        100      200 noPeaks    chr11
## 2        300      350 peakStart  chr11
```

```r
(fig2.labels <- tibble::tribble(
  ~chromStart, ~chromEnd, ~annotation, ~chrom,
  100, 150, "noPeaks", "chr11",
  200, 250, "peakEnd", "chr11"))
```

```
## # A tibble: 2 x 4
##   chromStart chromEnd annotation chrom
##        <dbl>    <dbl> <chr>      <chr>
## 1        100      150 noPeaks    chr11
## 2        200      250 peakEnd    chr11
```

The code above requires repeating the column names for each table, and
it does not allow for a simple definition of a default column value.
