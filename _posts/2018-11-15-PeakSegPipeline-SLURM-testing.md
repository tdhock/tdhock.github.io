---
layout: post
title: Testing PeakSegPipeline on Travis with SLURM
description: Also batchtools and texinfo
---

I originally developed my
[PeakSegPipeline R package](https://github.com/tdhock/PeakSegPipeline)
to work with PBS/qsub, which is the batch/cluster system that was
running on Compute Canada's Guillimin (I was using that cluster during
my postdoc at McGill). Now I am at NAU where the Monsoon cluster is
running [SLURM](https://slurm.schedmd.com). In this note I describe
how I got PeakSegPipeline running on SLURM.

First of all I wrote the new `jobs_create` function which returns a
data.table with one row for every job and three columns (`step`,
`fun`, `arg`). The idea is that each `step` is an integer from 1 to 6,
and smaller numbers should be run first; `fun` is the name of a
PeakSegPipeline function to be run with the argument `arg`. For
example step 1 computes the target interval for labeled
samples/contigs via `problem.target`. Step 2 should be run after all
Step 1 jobs finish, because it is the model training, which uses the
target intervals to learn a regression model. Step 3 requires the
trained model to do prediction on all samples/contigs, etc.

Then I wrote the `jobs_submit_batchtools` function which takes the job
data.table described above, and launches the jobs on a SLURM
cluster. I decided to use the batchtools R package because it has
[great documentation](https://mllg.github.io/batchtools/articles/batchtools.html). Even
though batchtools
[does not directly support dependencies between jobs at this time](https://github.com/mllg/batchtools/issues/204),
I managed to get launch jobs with dependencies by creating
[a new template](https://github.com/tdhock/PeakSegPipeline/blob/master/inst/templates/slurm-afterok.tmpl). The
idea is that batchtools uses the template to generate a shell script
that is run via `sbatch` (which is the SLURM command to launch
jobs). My template adds a line like `#SBATCH
--depend=afterok:PREV_JOB_ID` where `PREV_JOB_ID` is the job ID of the
previous step. The only trick is that for each step I had to create a
"registry", which is a directory that contains meta-data about the
jobs (shell scripts, logs, etc). The registry directories I created
are in `data.dir/registry/STEP` where `STEP` is the step number (from
1 to 6). To tell batchtools to use the special template I put the
following code in my `~/.batchtools.conf.R` file:

```r
cluster.functions = makeClusterFunctionsSlurm(system.file(
  file.path("templates", "slurm-afterok.tmpl"),
  package="PeakSegPipeline",
  mustWork=TRUE))
```

Finally to test that these new functions are working properly, I had
to install SLURM on Travis by adding the following commands to my
`.travis.yml` config file:

```
before_install:
  - sudo mkdir /etc/slurm-llnl
  - sudo cp slurm.conf /etc/slurm-llnl
  - cp batchtools.conf.R tests/testthat
  - sudo apt-get install -y slurm-llnl
  - sudo /usr/sbin/create-munge-key
  - sudo service munge start
```

The first two lines install
[a basic SLURM config file](https://github.com/tdhock/PeakSegPipeline/blob/master/slurm.conf),
which I had to generate using
`/usr/share/doc/slurmctld/slurm-wlm-configurator.easy.html` on my
laptop. Note that Travis runs Ubuntu 14.04 which has the `slurm-llnl`
package but my laptop is running Ubuntu 18.04 which has the
`slurm-wlm` package. The last two lines were required to avoid the the
following error

```
── 1. Error: index.html is created via batchtools (@test-pipeline-noinput.R#149)
Listing of jobs failed (exit code 1);
cmd: 'squeue --user=$USER --states=R,S,CG --noheader --format=%i -r'
output:
squeue: error: Munge encode failed: Failed to access "/var/run/munge/munge.socket.2": No such file or directory (retrying ...)
squeue: error: Munge encode failed: Failed to access "/var/run/munge/munge.socket.2": No such file or directory (retrying ...)
squeue: error: Munge encode failed: Failed to access "/var/run/munge/munge.socket.2": No such file or directory
squeue: error: authentication: Socket communication error
slurm_load_jobs error: Protocol authentication error
1: jobs_submit_batchtools(jobs, res.list) at testthat/test-pipeline-noinput.R:149
2: batchtools::submitJobs(chunks, resources = resources, reg = reg)
3: .findOnSystem(reg = reg, cols = c("job.id", "batch.id"))
4: getBatchIds(reg, status = "all")
5: unique(cf$listJobsRunning(reg))
6: cf$listJobsRunning(reg)
7: listJobs(reg, args)
8: OSError("Listing of jobs failed", res)
9: stopf("%s (exit code %i);\ncmd: '%s'\noutput:\n%s", msg, res$exit.code, stri_flatten(c(res$sys.cmd, 
       res$sys.args), collapse = " "), stri_flatten(res$output, "\n"))
```

In
[the testing code that launches the SLURM jobs](https://github.com/tdhock/PeakSegPipeline/blob/master/tests/testthat/test-pipeline-noinput.R),
I used the following code to wait until the last step of the pipeline
has finished:

```
  reg.dir <- file.path(data.dir, "registry", "6")
  reg <- batchtools::loadRegistry(reg.dir)
  result <- batchtools::waitForJobs(reg=reg, sleep=function(i){
    system("squeue")
    10
  })
```

Note that `squeue` is used to display the job progress every 10
seconds, in order to avoid falsely failing builds (Travis kills builds
which display no output after 10 minutes).

Finally I had to `apt-get install texlive texlive-fonts-extra texinfo`
to avoid the following WARNING about incorrectly generated R
documentation,


```
* checking PDF version of manual ... WARNING
LaTeX errors when creating PDF version.
This typically indicates Rd problems.
```
