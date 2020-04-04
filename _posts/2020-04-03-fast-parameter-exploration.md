---
layout: post
title: Fast parameter exploration
description: Caching and parallel execution
---

In machine learning there are hyper-parameters which must be fixed
before running a learning algorithm. For example in [one of my
screencasts for my CS499 Deep Learning
class](https://www.youtube.com/watch?v=AvCQnlrFCQY&list=PLwc48KSH3D1PYdSd_27USy-WFAHJIfQTK&index=8),
a hyper-parameter is the number of random subtrain/validation
splits. Another example is [the number of hidden units in a neural
network](https://www.youtube.com/watch?v=7QdAzojIuV4&list=PLwc48KSH3D1MvTf_JOI00_eIPcoeYMM_o&index=2).

The optimal values of these hyper-parameters are not known in advance,
so some experimentation is typically necessary to find a set of values
to try (with the goal of finding one particular value that minimizes
the prediction error with respect to a held-out validation set). At
first this may look like just a few manually specified values, e.g. in R code

```
n.splits.vec <- c(1, 2, 5, 10)
```

or a grid of values, e.g.

```
> (hidden.units.vec <- 10^seq(1, 3))
[1]   10  100 1000
```

After seeing the results for the initial set of hyper-parameter values
you typically have some idea about how the results may be improved,
e.g. by including more values

```
n.splits.vec <- c(1:10, 20, 30)
```

or by expanding the grid range/density:

```
> (hidden.units.vec <- as.integer(10^seq(1, 4, by=0.5)))
[1]    10    31   100   316  1000  3162 10000
```

This kind of interactive experimentation can be time consuming, so
here are some ideas for optimizing this process.

### Parallel rather than sequential evaluation

Typically each hyper-parameter value can be computed/evaluated
independently, so speedups can be achieved by converting sequential
for loops to parallel map calls. In R the sequential code would look
something like

```
results.dt.list <- list() #(1)
for(hidden.units in hidden.units.vec){
  ## fit a model with that number of hidden units.
  results.dt.list[[paste(hidden.units)]] <- data.table(
    hidden.units, result.for.hidden.units)#(2)
}
results.dt <- do.call(rbind, results.dt.list)#(3)
```

The code above is a typical example of the "list of data tables" idiom
which is extremely useful in R. It consists of (1) initializing an
empty list which will be filled with data tables, (2) adding a data
table to that list at the end of each iteration of a for loop, and (3)
combining the results into a single data table after the for loop is
done.

To parallelize that code we need to make two modifications to the
code: (1) rather than a for loop use `future.apply::future_lapply`,
and (2) remove the assignment of the data table to a list element:

```
future::plan("multiprocess")#(0)
results.dt.list <- future.apply::future_lapply(
  hidden.units.vec, function(hidden.units){#(1)
  ## fit a model with that number of hidden units.
  data.table(hidden.units, result.for.hidden.units)#(2)
}
results.dt <- do.call(rbind, results.dt.list)#(3)
```

The arguments to `future_lapply` (1) are the values to iterate over,
and the function to call with each one of those values. The return
value of that function (2) will be used as elements of the
`results.dt.list`, which will still be a list of data tables that can
be combined into a single result data table using the same code
(3). Note that a future plan such as multiprocess must be declared (0)
in order to do a parallel computation (default is sequential if no
future plan declared).

### Cache in memory

After having computed a few results, we may want to compute results
for new hyper-parameter values, and combine them with the previously
computed results. To adapt the previous idiom for this use case, we
need to create separate variables which represent "all results" and
"new results" so the first thing to do is determine which are the new
hyper-parameter values:

```
if(! "results.all.list" %in% ls()){
  ## only initialize if the object does not exist yet,
  ## in order to keep previously computed results.
  results.all.list <- list() 
}
hidden.units.all <- 2^seq(1, 10)
hidden.units.new <- hidden.units.all[
  ! hidden.units.all %in% names(results.all.list)]
```

Note that during the first execution of the code `results.all.list`
will be initialized to an empty list and `hidden.units.new` will be
the same as `hidden.units.all`. After results are stored in
`results.all.list` (code below), then the next time we run the code
above `hidden.units.new` will be a subset of `hidden.units.all` (the
set of values for which we do not yet have results). Then we modify
the `future_lapply` call to only use the new values:

```
results.new.list <- future.apply::future_lapply(
  hidden.units.new, function(hidden.units){
  ## fit a model with that number of hidden units.
  data.table(hidden.units, result.for.hidden.units)
}
```

After computing these new results we need to save them in the list of
all results, then combine them:

```
results.all.list[paste(hidden.units.new)] <- results.new.list
results.all <- do.call(rbind, results.all.list)
```

If you want to start over with an empty list of results (e.g. if you
have changed the function which computes the results), then you need
to do that yourself, e.g. `results.all.list <- list()` or
`rm(results.all.list)`.

### Cache results on disk

A final modification / optimization that you may consider is caching
the results on disk, which may be useful if you want to stop R after
having computed some results and then restart where you left off in a
new R session. To do that we need to modify the initialization of the
"all results" list:

```
results.all.list <- if(file.exists("hidden-units-results.rds")
  readRDS("hidden-units-results.rds")
}else list()
```

The code above reads the result list from an `rds` file if it exists,
and otherwise it initializes an empty list. The other modification we
need to do is saving the results to disk after having computed them:

```
results.all.list[paste(hidden.units.new)] <- results.new.list
saveRDS(results.all.list, "hidden-units-results.rds")
results.all <- do.call(rbind, results.all.list)
```

### Summary

In conclusion, we have proposed several idioms for optimizing R code,
via parallelization and caching. Putting all the ideas together yields
this code:

```
results.all.list <- if(file.exists("hidden-units-results.rds")
  readRDS("hidden-units-results.rds")
}else list()
hidden.units.all <- 2^seq(1, 10) ## define hyper-parameters.
hidden.units.new <- hidden.units.all[
  ! hidden.units.all %in% names(results.all.list)]
future::plan("multiprocess")
results.new.list <- future.apply::future_lapply(
  hidden.units.new, function(hidden.units){
  ## code that computes result for a given hyper-parameter.
  data.table(hidden.units, result.for.hidden.units)
}
results.all.list[paste(hidden.units.new)] <- results.new.list
saveRDS(results.all.list, "hidden-units-results.rds")
results.all <- do.call(rbind, results.all.list)
```
