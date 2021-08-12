---
layout: post
title: Stress testing reshape operations on list columns
description: Advantages of updated data.table::melt
---

My [paper about regular expressions for data
reshaping](https://github.com/tdhock/nc-article) was recently accepted
into R journal. It proposes a new syntax for wide-to-tall data
reshaping, and uses `data.table::melt` internally. I recently
submitted a few PRs to `data.table` in order to improve its
functionality. Here are two examples related to consistency of reshape
operations on list columns. Code was run with R-4.1.0 and
data.table-1.14.1 (from GitHub).

## What is a missing list element?

Let us begin with a simple exploration about the nature of missing
values in R.


```r
is.na(L <- list(NULL, NA, c(NA,NA)))
```

```
## [1] FALSE  TRUE FALSE
```

The above shows that base R considers a list element missing if it
contains a scalar `NA`. 


```r
str(na.omit(L))
```

```
## List of 3
##  $ : NULL
##  $ : logi NA
##  $ : logi [1:2] NA NA
```

```r
str(L[!is.na(L)])
```

```
## List of 2
##  $ : NULL
##  $ : logi [1:2] NA NA
```

I assumed the two results above should be the same, so I think this is
a bug in `na.omit`. To simplify from now on let us assume that
[is.na](https://github.com/wch/r-source/blob/b560647e74459fa2f40262dcaf1abf171c197efc/src/main/coerce.c#L2247-L2271)
gives us the one true definition of what is a missing value in R. 

## Reshape with missing list element

Now let's put that list into a column of a data table,


```r
library(data.table)
```

```
## data.table 1.14.1 IN DEVELOPMENT built 2021-07-24 13:52:54 UTC using 1 threads (see ?getDTthreads).  Latest news: r-datatable.com
```

```r
(DT.wide <- data.table(L))
```

```
##         L
##    <list>
## 1:       
## 2:     NA
## 3:  NA,NA
```

Reshaping that data table gives


```r
(DT.melt <- melt(DT.wide, measure="L"))
```

```
##    variable  value
##      <fctr> <list>
## 1:        L       
## 2:        L     NA
## 3:        L  NA,NA
```

```r
(DT.pivot <- tidyr::pivot_longer(DT.wide, cols="L"))
```

```
## # A tibble: 3 x 2
##   name  value    
##   <chr> <list>   
## 1 L     <NULL>   
## 2 L     <lgl [1]>
## 3 L     <lgl [2]>
```

Let's try to remove missing values with melt,


```r
na.omit(DT.melt)
```

```
##    variable  value
##      <fctr> <list>
## 1:        L       
## 2:        L  NA,NA
```

```r
melt(DT.wide, measure="L", na.rm=TRUE)
```

```
##    variable  value
##      <fctr> <list>
## 1:        L       
## 2:        L  NA,NA
```

Both results above seem to be correct. Now something strange happens
when we try to remove missing values with tidyr,


```r
na.omit(DT.pivot)
```

```
## # A tibble: 3 x 2
##   name  value    
##   <chr> <list>   
## 1 L     <NULL>   
## 2 L     <lgl [1]>
## 3 L     <lgl [2]>
```

```r
tidyr::pivot_longer(DT.wide, cols="L", values_drop_na=TRUE)
```

```
## # A tibble: 2 x 2
##   name  value    
##   <chr> <list>   
## 1 L     <lgl [1]>
## 2 L     <lgl [2]>
```

The two results above are different, and both seem to be
incorrect. Both incorrectly contain NA, and the second does not have
NULL (which is not considered missing by `is.na`).

## Reshape missing list column

What if there are several list columns to reshape?


```r
dt.wide <- data.table(num_1=1, num_2=2, list_1=list(1), list_3=list(3))
print(dt.wide, class=TRUE)
```

```
##    num_1 num_2 list_1 list_3
##    <num> <num> <list> <list>
## 1:     1     2      1      3
```

Above is some data with a "missing" `list_2` column. We reshape below:


```r
(melt.tall <- melt(dt.wide, measure=measure(value.name, int=as.integer)))
```

```
##      int   num   list
##    <int> <num> <list>
## 1:     1     1      1
## 2:     2     2     NA
## 3:     3    NA      3
```

Note that in in `melt.tall` the missing `list_2` column is represented
by `NA`, which is recognized as missing by `is.na`. If we exclude
missing values the result is consistent,


```r
na.omit(melt.tall)
```

```
##      int   num   list
##    <int> <num> <list>
## 1:     1     1      1
```

```r
melt(
  dt.wide,
  measure=measure(value.name, int=as.integer),
  na.rm=TRUE)
```

```
##      int   num   list
##    <int> <num> <list>
## 1:     1     1      1
```

Now we do the same operation using tidyr,


```r
names_pattern <- "(.*)_(.*)"
(pivot.tall <- tidyr::pivot_longer(
  dt.wide,
  matches(names_pattern),
  names_pattern=names_pattern,
  names_to=c(".value", "int")))
```

```
## # A tibble: 3 x 3
##   int     num list     
##   <chr> <dbl> <list>   
## 1 1         1 <dbl [1]>
## 2 2         2 <NULL>   
## 3 3        NA <dbl [1]>
```

Note that in `pivot.tall` the missing `list_2` column is represented
by `NULL`.  However as we have seen above, R `is.na` recognizes scalar
`NA` (not NULL) as a missing list element. This results in an
inconsistency if we remove rows with any NA:


```r
na.omit(pivot.tall)
```

```
## # A tibble: 2 x 3
##   int     num list     
##   <chr> <dbl> <list>   
## 1 1         1 <dbl [1]>
## 2 2         2 <NULL>
```

```r
tidyr::pivot_longer(
  dt.wide,
  matches(names_pattern),
  names_pattern=names_pattern,
  names_to=c(".value", "int"),
  values_drop_na=TRUE)
```

```
## # A tibble: 3 x 3
##   int     num list     
##   <chr> <dbl> <list>   
## 1 1         1 <dbl [1]>
## 2 2         2 <NULL>   
## 3 3        NA <dbl [1]>
```

The `na.omit` result incorrectly includes row 2, and the
`values_drop_na=TRUE` result incorrectly includes rows 2 and 3.

## Conclusion

When there are list columns, the `data.table` functions are more
correct and consistent in terms of reshape operations and treatment of
missing values.

## Follow-up

I posted [a thread on R-devel](https://stat.ethz.ch/pipermail/r-devel/2021-August/080994.html) about `na.omit` on lists and data frames
with list columns.
