---
layout: post
title: R batchtools on Monsoon
description: Cluster computing tutorial for NAU students
---

NEW 26 Oct 2020: [video screencast tutorial](https://youtu.be/K_vJDKNLn28)!

In machine learning research we often need to run the same algorithm
on a bunch of different data sets, and/or run several algorithms on
the same data set. Here is the protocol I use these days for such
computational experiments.

First I will try to get it working on my local computer, using at
least two data sets and/or algorithms. Two is the important number
here, because it is the smallest number that requires your code to be
general. But for testing/debugging we want to get quick feedback about
whether or not the code works, so it is important to use a small
number of data sets/algorithms. For example in [my neuroblastoma-data
repo](https://github.com/tdhock/neuroblastoma-data/tree/master/data)
there are 19 benchmark data sets. I would start by making sure my
script works for two of them on my local computer. Then we can run all
19 in parallel on the compute cluster.

## login and installation

At NAU we have the Monsoon compute cluster, and I assume you have a
shell on the login node (wind). If not, check the Monsoon web page
docs to find out how to register for an account, and check [my X
forwarding on windows
tutorial](https://tdhock.github.io/blog/2019/cygwin-x-forwarding/) to
see how to login and have your emacs/rstudio window forwarded to your
local X server.

```
th798@cmp2986 ~
$ ssh -Y th798@monsoon.hpc.nau.edu
th798@monsoon.hpc.nau.edu's password: 
Last login: Wed Feb 12 10:29:42 2020 from cmp2986.computers.nau.edu

################################################################################
#
# Welcome to Monsoon - login node: [wind]
#
# CentOS release 6.10 (Final) - Kernel: 2.6.32-696.18.7.el6.x86_64
# slurm 19.05.5
#
# You are logged in as th798
#
# Information:
# - /scratch : files auto DELETED after 30 days 
#
# Issues or questions: hpcsupport@nau.edu
#
# Upcoming maintenance:
# - None at this time 
#
# Random tip: 
#   "sprio -l" -- List the priority of all jobs in the pending queue
#
################################################################################

th798@wind:~$
```

The first thing you should do is get an interactive job on a compute
node, because you aren't supposed to run any compute-intensive jobs on
the login node:

```
th798@wind:~/R/PeakSegPipeline(temp-db)$ srun -t 24:00:00 --mem=4GB --cpus-per-task=1 --pty bash 
srun: job 27549104 queued and waiting for resources
srun: job 27549104 has been allocated resources
th798@cn41:~/R/PeakSegPipeline(temp-db)$
```

Now I have a shell on cn41, one of the compute nodes. The next thing I
do is open up emacs:

```
th798@cn69:~/R/PeakSegPipeline(temp-db)$ emacs & 
[1] 853
th798@cn69:~/R/PeakSegPipeline(temp-db)$ 
```

Or Rstudio:

```
th798@cn69:~/R/PeakSegPipeline(temp-db)$ module load rstudio
th798@cn69:~/R/PeakSegPipeline(temp-db)$ rstudio &
[2] 6502
th798@cn69:~/R/PeakSegPipeline(temp-db)$ 
```

Note that the emacs and rstudio commands above should open up a new
window on your system. If you are on NAU wifi this may be slow
(e.g. 50 seconds to load rstudio) relative to if you are on NAU
ethernet. You should consider learning emacs and
[ESS](http://ess.r-project.org/) because even on a really slow
connection, you can still use interactive `emacs -nw` in the terminal
(with all of the same editing/help/completion/etc features of Rstudio,
more customizability, and support for more different programming
languages).

If you use some other software, and Monsoon doesn't have it, then you
can either (1) request that the system administrators install the
software via [this form](https://in.nau.edu/hpc/request-software/), or
(2) install it yourself under $HOME, or (3) use conda to install it
under $HOME. If there are pre-built binaries available, option (2) is
probably easiest since you can just download them to ~/bin, e.g. I
have downloaded bigWigToBedGraph and some other utilities from
[UCSC](http://hgdownload.soe.ucsc.edu/admin/exe/). If your software
provides source code but no binaries, you could build it yourself
under $HOME, but that may be complicated/time-consuming, so in that
case I would recommend options (1) or (3). For example emacs provides
[source code](http://mirror.team-cymru.com/gnu/emacs/) only (no
binaries) so I requested that the sysadmins install the most recent
version, rather than trying to build/install it myself. If your
software is common enough, it is likely provided by conda, so you
could use option (3), e.g. 

```
module load anaconda3
conda create -n emacs1 -c conda-forge emacs
conda activate emacs1
emacs
```

By the way the above code block stopped working during June 2020
because it had `anaconda` rather than `anaconda3` (the Monsoon admins
changed the name of the anaconda module). To get a list of the current
module names you can do `module avail`.

The other advantage to option (1) is that all other users of
the cluster system can use the software, whereas with option (2-3)
only you can use the software. I put these lines of code in my
~/.bashrc file to get access to this software (and for git branch display):

```
function star_if_dirty {
  [[ $(git status 2> /dev/null | tail -n1 | awk '{print $1}') != "nothing" ]] && echo "*"
}
function parse_git_branch {
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/[*] \(.*\)/(\1$(star_if_dirty))/"
}
export PS1='\u@\h:\w$(parse_git_branch)$ '
export EDITOR="emacs -nw"
export TERM=xterm-color
module load R/3.6.2    #or just module load R
module load emacs/26.3 #or just module load emacs
```

You may need to install the batchtools package. I had to tell R to
install to a library directory under my home, by putting the following
in my ~/.bashrc file:

```
export R_LIBS_USER=$HOME/R/%v
```

That means when you run `install.packages` in R, the default place to
put them should be in e.g. `~/R/3.6` so make sure that directory
exists (create it via mkdir). Then put the following in your
~/.Rprofile, which tells R to download packages from the cloud (aka
closest/fastest CRAN mirror):

```
options(repos="http://cloud.r-project.org")
```

Then you can install batchtools (note it goes to
/projects/genomic-ml/R/3.6 rather than ~/R/3.6 because I symlinked ~/R
to /projects/genomic-ml/R, but you should probably install under your
home dir).

```
> install.packages("batchtools")
Installing package into ‘/projects/genomic-ml/R/3.6’
(as ‘lib’ is unspecified)
trying URL 'http://cloud.r-project.org/src/contrib/batchtools_0.9.12.tar.gz'
Content type 'application/x-gzip' length 694694 bytes (678 KB)
==================================================
downloaded 678 KB

* installing *source* package ‘batchtools’ ...
** package ‘batchtools’ successfully unpacked and MD5 sums checked
** using staged installation
** libs
gcc -I"/packages/R/3.6.2/lib64/R/include" -DNDEBUG   -I/usr/local/include  -fpic  -I/packages/zlib/1.2.8/include -I/packages/bzip2/1.0.6-shared/include -I/packages/xz/5.2.2/include -I/packages/pcre/8.39/include -I/packages/curl/7.65.0/include -I/packages/libtiff/4.0.9/include  -c binpack.c -o binpack.o
gcc -I"/packages/R/3.6.2/lib64/R/include" -DNDEBUG   -I/usr/local/include  -fpic  -I/packages/zlib/1.2.8/include -I/packages/bzip2/1.0.6-shared/include -I/packages/xz/5.2.2/include -I/packages/pcre/8.39/include -I/packages/curl/7.65.0/include -I/packages/libtiff/4.0.9/include  -c count_not_missing.c -o count_not_missing.o
gcc -I"/packages/R/3.6.2/lib64/R/include" -DNDEBUG   -I/usr/local/include  -fpic  -I/packages/zlib/1.2.8/include -I/packages/bzip2/1.0.6-shared/include -I/packages/xz/5.2.2/include -I/packages/pcre/8.39/include -I/packages/curl/7.65.0/include -I/packages/libtiff/4.0.9/include  -c fill_gaps.c -o fill_gaps.o
gcc -I"/packages/R/3.6.2/lib64/R/include" -DNDEBUG   -I/usr/local/include  -fpic  -I/packages/zlib/1.2.8/include -I/packages/bzip2/1.0.6-shared/include -I/packages/xz/5.2.2/include -I/packages/pcre/8.39/include -I/packages/curl/7.65.0/include -I/packages/libtiff/4.0.9/include  -c init.c -o init.o
gcc -I"/packages/R/3.6.2/lib64/R/include" -DNDEBUG   -I/usr/local/include  -fpic  -I/packages/zlib/1.2.8/include -I/packages/bzip2/1.0.6-shared/include -I/packages/xz/5.2.2/include -I/packages/pcre/8.39/include -I/packages/curl/7.65.0/include -I/packages/libtiff/4.0.9/include  -c lpt.c -o lpt.o
gcc -shared -L/packages/R/3.6.2/lib64/R/lib -L/packages/R/3.6.2/lib64/R/lib -L/packages/zlib/1.2.8/lib -L/packages/bzip2/1.0.6-shared/lib -L/packages/xz/5.2.2/lib -L/packages/pcre/8.39/lib -L/packages/curl/7.65.0/lib -L/packages/libtiff/4.0.9/lib -L/usr/lib/jvm/java-1.6.0-openjdk-1.6.0.41.x86_64/jre/lib/amd64/server -L/packages/R/3.6.2/lib64/R/lib -L/packages/zlib/1.2.8/lib -L/packages/bzip2/1.0.6-shared/lib -L/packages/xz/5.2.2/lib -L/packages/pcre/8.39/lib -L/packages/curl/7.65.0/lib -L/packages/libtiff/4.0.9/lib -L/usr/lib/jvm/java-1.6.0-openjdk-1.6.0.41.x86_64/jre/lib/amd64/server -L/packages/R/3.6.2/lib64/R/lib -L/packages/zlib/1.2.8/lib -L/packages/bzip2/1.0.6-shared/lib -L/packages/xz/5.2.2/lib -L/packages/pcre/8.39/lib -L/packages/curl/7.65.0/lib -L/packages/libtiff/4.0.9/lib -L/usr/lib/jvm/java-1.6.0-openjdk-1.6.0.41.x86_64/jre/lib/amd64/server -L/packages/python/anaconda/latest/pkgs/openssl-1.0.2p-h470a237_2/lib -L/packages/gcc/6.2.0/lib64 -L/packages/git/2.16.3/lib64 -o batchtools.so binpack.o count_not_missing.o fill_gaps.o init.o lpt.o -L/packages/R/3.6.2/lib64/R/lib -lR
installing to /projects/genomic-ml/R/3.6/00LOCK-batchtools/00new/batchtools/libs
** R
** inst
** byte-compile and prepare package for lazy loading
** help
*** installing help indices
** building package indices
** installing vignettes
** testing if installed package can be loaded from temporary location
** checking absolute paths in shared objects and dynamic libraries
** testing if installed package can be loaded from final location
** testing if installed package keeps a record of temporary installation path
* DONE (batchtools)

The downloaded source packages are in
	‘/tmp/th798/27797707/RtmpwMfGDh/downloaded_packages’
> 
```

## batchtools

To launch your jobs on the cluster using batchtools the first thing
you need to do is create a registry, which is a directory that
contains all the files (shell scripts for launching jobs, log files
for debugging, etc) related to running your job on the cluster system.

```
> unlink("registry-dir", recursive=TRUE)
> reg <- batchtools::makeRegistry("registry-dir")
Sourcing configuration file '~/.batchtools.conf.R' ...
Created registry in '/scratch/th798/DHS_WM_ENCODE/registry-dir' using cluster functions 'Slurm'
> 
```

Note that batchtools tells you that it is reading configuration from
the ~/.batchtools.conf.R file, which contains (you will need to copy
this to your ~/.batchtools.conf.R file):

```
(slurm.tmpl <- normalizePath(
  "~/slurm-afterok.tmpl",
  mustWork=TRUE))
cluster.functions = makeClusterFunctionsSlurm(slurm.tmpl)
## Uncomment for running jobs interactively rather than using SLURM:
##cluster.functions = makeClusterFunctionsInteractive()
```

The configuration file above tells batchtools to use [my custom
template](https://raw.githubusercontent.com/tdhock/PeakSegPipeline/master/inst/templates/slurm-afterok.tmpl)
(you will need to download that and save it to ~/slurm-afterok.tmpl),
which is basically the shell script that will be submitted to SLURM
via `sbatch` (with some parts that will be filled in using values you
specify via `resources` in R). With respect to the "simple" slurm template provided
[in
batchtools](https://github.com/mllg/batchtools/blob/master/inst/templates/slurm-simple.tmpl),
my template adds the following line, which adds support for
dependencies between jobs (see
[PeakSegPipeline](https://github.com/tdhock/PeakSegPipeline/blob/master/R/jobs.R#L210)
for an example of how to launch jobs that depend on other jobs):

```
<%= if (!is.null(resources$afterok)) paste0("#SBATCH --depend=afterok:", resources$afterok) %>
```

After having created a registry, you can declare the jobs you want to
run via:

```
> batchtools::batchMap(
+   MyFun, more.args=list(
+     all.seq.counts=all.seq.counts
+   ), args=data.table::CJ(
+     row.i=1:nrow(all.seq.counts),
+     EUCL=c("true", "false"),
+     DIST=c("min", "ave"),
+     N=c(0, 1, 10),
+     ALPHA=c(0, 1)
+   ), reg=reg)
Adding 4752 jobs ...
> 
```

Note that the 4752 jobs are not running yet -- they are just
declared. Let's analyze each argument of the call above:

* The first argument `MyFun` is an R function that runs your job. 
* The items in the `more.args` list are passed verbatim to each job.
* Each line of `args` defines a set of values, 
  only one of which is passed to each job
  (all possible combinations of `args` results in 4752 jobs = 
   2 ALPHA values x 3 N values x 2 DIST values, x 2 EUCL values x 
   198 row.i values).
* `reg` is the object returned by `batchtools::makeRegistry`.

The call above is relatively complicated, but it is a good template to
copy from, because it includes mostly everything you would
need. Typically to run one algo on a bunch of different data sets,
each in a different directory on disk, you could just pass the vector
of directories as a single  `args`. For more complex experiments with different
algos/parameters you can use more  `args` to indicate what
algo/parameter you want to use.  Also, if you don't want to use all
combinations of `args` you can pass a subset (or use other data table
operations like rbind), e.g.

```
> data.table::CJ(row.i=1:3, DIST=c("min", "ave"))[!(row.i>1 & DIST=="min")]
   row.i DIST
1:     1  ave
2:     1  min
3:     2  ave
4:     3  ave
> 
```

Note that the function `MyFun` to run in parallel must NOT include any
references to data outside of its body, but you can use as many things
in `more.args` as you need. It can include further parallelization if
you request more than one CPU per compute node, and to do this I
recommend using the excellent
[future](https://github.com/HenrikBengtsson/future) package (see the [future.apply vignette](https://cran.r-project.org/web/packages/future.apply/vignettes/future.apply-1-overview.html) for more info). You
should typically save the results to a file on disk (although
batchtools also supports getting the object which is returned by this
function). For example:

```r
OneFold <- function(row.i, EUCL, DIST, N, ALPHA, all.seq.counts){
  library(data.table)
  ## do something on the compute node.
  future::plan("multiprocess")
  future.apply::future_lapply(value.vec, function(value){
    ## do something multicore/in parallel over CPUs on that node.
  })
  ## save results to disk.
}
```

Having declared the jobs you want to run, you should then
interactively test one of them to see if it works:

```
batchtools::testJob(1, reg=reg)
```

Finally to launch your jobs on separate compute nodes you need to
first assign them to the same chunk ID=1, which means they will be
grouped together in the same job array. If you have LOTS of jobs (more
than 50000) then you will need to use more than one chunk ID here:

```
(emacs1) th798@cn68:~/R/PeakSegPipeline(temp-db)$ grep MaxArraySize /etc/slurm/slurm.conf
MaxArraySize=50001
```

```r
job.table <- batchtools::getJobTable(reg=reg)
chunks <- data.frame(job.table, chunk=1)
```

Finally you submit the jobs along with a description of resources that
should be allocated/request for each of them:

```
batchtools::submitJobs(chunks, resources=list(
  walltime = 24*60*60,#seconds
  memory = 2000,#megabytes per cpu
  ncpus=1,  #>1 for multicore/parallel jobs.
  ntasks=1, #>1 for MPI jobs.
  chunks.as.arrayjobs=TRUE), reg=reg)
```

Now you can grab a cup of coffee and wait for the jobs to
start/finish. If you have already launched some jobs in a previous R
session, you can load the registry via:

```
> reg <- batchtools::loadRegistry("registry-dir")
Reading registry in read-only mode.You can inspect results and errors, but cannot add, remove, submit or alter jobs in any way.If you need write-access, re-load the registry with `loadRegistry([...], writeable = TRUE)`.
Sourcing configuration file '~/.batchtools.conf.R' ...
> 
```

After that you can get a summary/count of job status:

```
> batchtools::getStatus(reg=reg)
Status for 25 jobs at 2020-02-20 13:13:23:
  Submitted    : 25 (100.0%)
  -- Queued    :  0 (  0.0%)
  -- Started   : 12 ( 48.0%)
  ---- Running :  0 (  0.0%)
  ---- Done    : 10 ( 40.0%)
  ---- Error   :  2 (  8.0%)
  ---- Expired : 13 ( 52.0%)
> 
```

Done means successfully completed, Error means the job stopped itself
with an error, Expired means that the scheduler stopped the job
because it went over the time/memory limits. To find out more details
about Error:

```
> jt <- batchtools::getJobTable(reg=reg)
> jt[!is.na(error)]
   job.id           submitted             started                done
1:      8 2019-12-17 17:03:30 2019-12-17 17:03:40 2019-12-17 18:31:08
2:     16 2019-12-17 17:03:30 2019-12-17 17:03:42 2019-12-17 18:49:37
                                                                                 error
1: Error in PeakSegJointFasterOne(profile.list, bin.factor) : \n  bin factor too large
2: Error in PeakSegJointFasterOne(profile.list, bin.factor) : \n  bin factor too large
   mem.used    batch.id                                   log.file
1:       NA  26886403_8  job375799139b7298651c26de7674f41373.log_8
2:       NA 26886403_16 job375799139b7298651c26de7674f41373.log_16
                              job.hash    job.name  time.queued  time.running
1: job375799139b7298651c26de7674f41373  Step3Task8 10.0070 secs 5247.919 secs
2: job375799139b7298651c26de7674f41373 Step3Task16 12.6115 secs 6354.548 secs
   job.pars resources tags
1:   <list>    <list> <NA>
2:   <list>    <list> <NA>
> 
```

The error message in the job table is usually sufficient to figure out
what happened and fix the problem. If you need more info the log files
are in
e.g. `registry-dir/logs/job375799139b7298651c26de7674f41373.log_16`. To
examine what happened in the expired jobs:

```
> exp.dt <- batchtools::findExpired(reg=reg)
> exp.id.vec <- exp.dt$job.id[1:2]
> log.list <- lapply(exp.id.vec, batchtools::getLog)
> lapply(log.list, tail)
[[1]]
[1] "20: try(execJob(job))"                                                                                                                                                                                                      
[2] "21: doJobCollection.JobCollection(obj, output = output)"                                                                                                                                                                    
[3] "22: doJobCollection.character(\"/scratch/th798/DHS_WM_ENCODE/registry/3/jobs/job375799139b7298651c26de7674f41373.rds\")"                                                                                                    
[4] "23: batchtools::doJobCollection(\"/scratch/th798/DHS_WM_ENCODE/registry/3/jobs/job375799139b7298651c26de7674f41373.rds\")"                                                                                                  
[5] "An irrecoverable exception occurred. R is aborting now ..."                                                                                                                                                                 
[6] "/var/spool/slurm/slurmd/job26886404/slurm_script: line 13: 12513 Segmentation fault      Rscript -e 'batchtools::doJobCollection(\"/scratch/th798/DHS_WM_ENCODE/registry/3/jobs/job375799139b7298651c26de7674f41373.rds\")'"

[[2]]
[1] "Models in csv=1 rds=13"                                                                                                
[2] "Writing /scratch/th798/DHS_WM_ENCODE/samples/Heart/DS20383/problems/chr12:37460128-132223362/peaks.bed with 902 peaks."
[3] "Predicting penalty=72175.2997312758 log(penalty)=11.1868531573632 based on 23 features."                               
[4] "Models in csv=0 rds=10"                                                                                                
[5] "Computing new penalty."                                                                                                
[6] "slurmstepd: error: *** JOB 26886405 ON cn69 CANCELLED AT 2019-12-18T01:03:38 DUE TO TIME LIMIT ***"                    

> 
```

So the first expired job had a segfault and the second was cancelled
because it went over the time limit.

For the successful jobs, you can get the return value of the function via e.g. :
```
job.id <- 5 # same as row number in job table.
batchtools::loadResult(job.id, reg=reg)
```

## Cluster etiquette

Different disks should be used for different purposes:

* TMPDIR=/tmp/user/pid e.g. TMPDIR=/tmp/th798/27758529 is a
  job-specific temporary directory, which is local to the compute
  node, and super fast. This is where you should write files that are
  really temporary (NOT result files) -- these files will not be
  used/accessible after the job is over. Note that this environment
  variable is the "standard" way for indicating the temporary
  directory, so most software should recognize it. For example R sees
  it and creates temporary files there:

```
th798@cn69:~/R/PeakSegPipeline(temp-db)$ R -e 'tempdir()'

R version 3.6.2 (2019-12-12) -- "Dark and Stormy Night"
Copyright (C) 2019 The R Foundation for Statistical Computing
Platform: x86_64-pc-linux-gnu (64-bit)

R is free software and comes with ABSOLUTELY NO WARRANTY.
You are welcome to redistribute it under certain conditions.
Type 'license()' or 'licence()' for distribution details.

  Natural language support but running in an English locale

R is a collaborative project with many contributors.
Type 'contributors()' for more information and
'citation()' on how to cite R or R packages in publications.

Type 'demo()' for some demos, 'help()' for on-line help, or
'help.start()' for an HTML browser interface to help.
Type 'q()' to quit R.

> tempdir()
[1] "/tmp/th798/27758529/Rtmpge6XWe"
> 
> 
th798@cn69:~/R/PeakSegPipeline(temp-db)$ 
```

* /scratch for medium-term storage (supposed to delete/move files
  after 1 month). You are supposed to copy all of your data files here
  and write your result files here during your compute jobs. You can
  check your quota via

```
th798@cn69:~/R/PeakSegPipeline(temp-db)$ lfs quota -u th798 /scratch
Disk quotas for usr th798 (uid 682419):
     Filesystem  kbytes   quota   limit   grace   files   quota   limit   grace
       /scratch 758144624  20000000000 20200000000       - 3928777  4000000 4001000       -
th798@cn69:~/R/PeakSegPipeline(temp-db)$ 
```

* /projects is for long-term storage (more than 1 month). If you are
  working in my lab you should ask me to add you to the group so you
  can write to my project directory, `/projects/genomic-ml`. After
  your jobs are done computing you are supposed to move your results
  from /scratch to /projects.

## Summary

In summary, batchtools is an R package that allows you to specify your
parallel/cluster compute jobs in R code rather than in a shell
script. The main advantage is that, if you already are using R, then
you don't have to write any shell script to launch your job on the
cluster, and you don't have to manage the conversion of data/parameter
values to job array id numbers (batchtools takes care of these details
for you).

Happy cluster computing!
