---
layout: post
title: Benchmarking a change in data.table
description: Progress reporting for group by operations
---

[data.table](https://github.com/rdatatable/data.table) is an R package for efficient data manipulation.
I have an NSF POSE grant about expanding the open-source ecosystem of users and contributors around `data.table`.
Part of that project is improving performance testing. 
The goal of this post is to explain how to use
[atime](https://github.com/tdhock/atime) to explore the performance
impact of different versions of a `data.table` group by operation.



# Background

`data.table` provides a simple syntax for a large number of data manipulation operations: `DT[i,j,by]` where 
* `i` is used to subset rows,
* `j` computes on columns,
* `by` specifies columns to group by.

Often there are a large number of values of the `by` columns, and/or
the `j` computations are time-intensive. In this case, we may have to
wait some time before the computation completes. When using R
interactively, we may wonder how long we have to wait. This was
reported by one user, in
[issue#3060](https://github.com/Rdatatable/data.table/issues/3060).

Joshua Wu is an excellent Google Summer of Code contributor, who is
working on fixing this in
[PR#6228](https://github.com/Rdatatable/data.table/pull/6228), and I
am mentoring him.

# Performance

We would like to evaluate the performance (time and memory usage) of
`data.table` before and after the changes proposed by Joshua in that
PR. Ideally, we should see about the same time and memory usage before
and after. How can we verify that?

I have created the [atime](https://github.com/tdhock/atime) R package
to help answer performance-related questions like this.

# showProgress=TRUE versus FALSE

The PR introduces a new `showProgress` argument, `DT[i,j,by,showProgress]`, which can be either `TRUE` or `FALSE`. We would like to compare the performance of these two options. 

First we need to install the code from that PR.
The [list of commits in that
PR](https://github.com/Rdatatable/data.table/pull/6228/commits)
currently shows that b3d9a8d151982616ef46bb058554d65c1eb4fbc3 is the
last commit, we install that using the code below.


```r
pr.sha <- "b3d9a8d151982616ef46bb058554d65c1eb4fbc3"
repo.sha <- paste0("Rdatatable/data.table@", pr.sha)
remotes::install_github(repo.sha)
```

```
## Using github PAT from envvar GITHUB_PAT
```

```
## Skipping install of 'data.table' from a github remote, the SHA1 (b3d9a8d1) has not changed since last install.
##   Use `force = TRUE` to force installation
```

To use atime, we need to do a computation as a function of some data
of size `N`. In this case `N` could be the number of rows, or the
number of groups. Let us make `N` the number of groups,


```r
N <- 5
rows.per.group <- 2
N.rows <- N*rows.per.group
library(data.table)
(DT <- data.table(i=1:N.rows, g=rep(1:N,each=rows.per.group)))
```

```
##         i     g
##     <int> <int>
##  1:     1     1
##  2:     2     1
##  3:     3     2
##  4:     4     2
##  5:     5     3
##  6:     6     3
##  7:     7     4
##  8:     8     4
##  9:     9     5
## 10:    10     5
```

```r
DT[, .(m=mean(i)), by=g]
```

```
##        g     m
##    <int> <num>
## 1:     1   1.5
## 2:     2   3.5
## 3:     3   5.5
## 4:     4   7.5
## 5:     5   9.5
```

The code above computed mean by group for a single data size `N` (number of groups). To convert that to `atime` we just 
* put the data creation code, which makes `DT`, in the `setup` argument
* put the code that you want to measure some other named arguments


```r
a.result <- atime::atime(
  setup = {
    rows.per.group <- 2
    N.rows <- N*rows.per.group
    DT <- data.table(i=1:N.rows, g=rep(1:N,each=rows.per.group))
  },
  default = DT[, .(m=mean(i)), by=g],
  "TRUE"  = DT[, .(m=mean(i)), by=g, showProgress=TRUE],
  "FALSE" = DT[, .(m=mean(i)), by=g, showProgress=FALSE]
)
```

The code above has three expressions to measure:

* `default` leaves `showProgress` unspecified, taking the default value,
* `TRUE` and `FALSE` use those values for `showProgress`.


```r
plot(a.result)
```

![plot of chunk showProgress-default-true-false](/assets/img/2024-07-17-atime-showProgress/showProgress-default-true-false-1.png)

The plot above shows that there is no significant performance
difference between the three expressions. This is a good thing!

# Comparing versions

We would also like to make sure that the new code is just as fast as
the old code (before the PR). So how can we find a version of the code before that PR? First go to the [PR commits page](https://github.com/Rdatatable/data.table/pull/6228/commits), then examine the [details of the first commit, 20b213738fdb500369201f6ff584dae3a1bcd44b](https://github.com/Rdatatable/data.table/commit/20b213738fdb500369201f6ff584dae3a1bcd44b). That page shows that its parent is [6df30c39cc5d1e910e6f4ab84ccdcc693c64315c](https://github.com/Rdatatable/data.table/commit/6df30c39cc5d1e910e6f4ab84ccdcc693c64315c), so that is a good candidate.

In summary, we would like to compare the performance of `DT[i,j,by]` in two different versions of `data.table`
* 6df30c39cc5d1e910e6f4ab84ccdcc693c64315c is master before adding the showProgress argument,
* b3d9a8d151982616ef46bb058554d65c1eb4fbc3 is the last commit in the PR which adds showProgress.

To compare those two versions of the code, we can use `atime_versions`
function as below.


```r
edit.data.table <- function(old.Package, new.Package, sha, new.pkg.path) {
  pkg_find_replace <- function(glob, FIND, REPLACE) {
    atime::glob_find_replace(file.path(new.pkg.path, glob), FIND, REPLACE)
  }
  Package_regex <- gsub(".", "_?", old.Package, fixed = TRUE)
  Package_ <- gsub(".", "_", old.Package, fixed = TRUE)
  new.Package_ <- paste0(Package_, "_", sha)
  pkg_find_replace(
    "DESCRIPTION",
    paste0("Package:\\s+", old.Package),
    paste("Package:", new.Package))
  pkg_find_replace(
    file.path("src", "Makevars.*in"),
    Package_regex,
    new.Package_)
  pkg_find_replace(
    file.path("R", "onLoad.R"),
    Package_regex,
    new.Package_)
  pkg_find_replace(
    file.path("R", "onLoad.R"),
    sprintf('packageVersion\\("%s"\\)', old.Package),
    sprintf('packageVersion\\("%s"\\)', new.Package))
  pkg_find_replace(
    file.path("src", "init.c"),
    paste0("R_init_", Package_regex),
    paste0("R_init_", gsub("[.]", "_", new.Package_)))
  pkg_find_replace(
    "NAMESPACE",
    sprintf('useDynLib\\("?%s"?', Package_regex),
    paste0('useDynLib(', new.Package_))
}
v.result <- atime::atime_versions(
  pkg.path="~/R/data.table",
  pkg.edit.fun=edit.data.table,
  seconds.limit=0.1,
  N=as.integer(10^seq(1,9,by=0.5)),
  setup = {
    rows.per.group <- 2
    N.rows <- N*rows.per.group
    DT <- data.table(i=1:N.rows, g=rep(1:N,each=rows.per.group))
  },
  expr = data.table:::`[.data.table`(DT, , .(m=mean(i)), by=g),
  master="6df30c39cc5d1e910e6f4ab84ccdcc693c64315c",
  showProgress=pr.sha)
```

The code above contains a few new arguments:

* `pkg.path` is the file path of a git repository containing an R package, in which we can find the `master` and `showProgress` commits,
* `pkg.edit.fun` is a function (here specific to `data.table`) which is applied to each git version of the package, in order to make it suitable for installation under the name `PKG.SHA`,
* `seconds.limit` is the max number of seconds any timing can take (past which we stop trying larger N). Default is 0.01, and we increased it to 0.1 in the code above.


```r
plot(v.result)
```

![plot of chunk master-showProgress](/assets/img/2024-07-17-atime-showProgress/master-showProgress-1.png)

The plot above shows that there is no significant performance
difference between the new `showProgress` version of the code, and the
previous `master` version.

# Conclusion

We have shown how to use `atime` to check if there are any performance differences between 

* different R code/data, same package version, via `atime()`,
* different package versions, same R code/data, via `atime_versions()`.

For future work, you may consider changing `setup` and the code to
measure, if you thin the simple example we considered above is not
actually representative of real use cases.
