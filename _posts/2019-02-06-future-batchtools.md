---
layout: post
title: future.batchtools
description: Simple parallel R code on a computer cluster
---

I have been using the
[batchtools](https://mllg.github.io/batchtools/articles/batchtools.html)
R package in
[PeakSegPipeline/R/jobs.R](https://github.com/tdhock/PeakSegPipeline/blob/master/R/jobs.R)
in order to run several steps of my machine learning ChIP-seq software
on compute cluster. The batchtools package actually supports
dependencies between jobs,
[as I wrote about previously](https://tdhock.github.io/blog/2018/PeakSegPipeline-SLURM-testing/). 

I have also been using
[future.apply](https://cran.r-project.org/package=future.apply) in
another unrelated context. In
[penaltyLearning/R/IntervalRegression.R](https://github.com/tdhock/penaltyLearning/blob/master/R/IntervalRegression.R)
I use `future.apply::future_lapply` to parallel K-fold
cross-validation when training an L1-regularized interval regression
model. It is user-friendly because it acts as a drop-in replacement
for the base `lapply` function. So I typically use it via

```
LAPPLY <- if(requireNamespace("future.apply")){
  future.apply::future_lapply
}else{
  lapply
}
```

The user of my package can customize the parallel backend using
`future::plan` before calling my
`penaltyLearning::IntervalRegressionCV` function (which uses `LAPPLY`
as above).

Today I tried using
[future.batchtools](https://cran.r-project.org/package=future.batchtools),
which is a future backend that uses the batchtools package. In my script I used

```
future::plan(
  future.batchtools::batchtools_slurm,
  template="~/path/to/slurm.tmpl",
  resources=list(
    walltime=60,#minutes
	memory=1000,
	ncpus=1,
	ntasks=1,
	chunks.as.arrayjobs=TRUE))
future.apply::future_lapply(some.values, function(value){
  compute_something(value)
})
```

The
[slurm.tmpl](https://github.com/tdhock/PeakSegPipeline/blob/master/inst/templates/slurm-afterok.tmpl)
file is a bash script that is used to launch the jobs. It gets filled
in with values specified in the resources list.

Executing `future_lapply` in R ran the function on the slurm cluster,
as expected. Some jobs finished, but others ran out of time (the
walltime I specified was too low for some of them). I even got an
informative error at the R terminal:

```
Error: BatchtoolsExpiration: Future ('<none>') expired ...
...
slurmstepd: error: *** JOB 16590036 ON cdr699 CANCELLED DUE TO TIME LIMIT ***
```

So in summary, future/future.apply/future.batchtools provide a
user-friendly interface for submitting jobs on the cluster using
R. Most of the details of the batchtools package (creating a registry,
etc) are taken care of automatically. For full control, using
batchtools directly should be preferred. But for a simple interface,
future.batchtools is great!
