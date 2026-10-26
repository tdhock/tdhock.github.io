---
layout: post
title: git bisecting performance differences
description: new atime code
---

Recently we published [Asymptotic Benchmarking Using the atime package](https://rjournal.github.io/articles/RJ-2026-013/), a paper about asymptotic performance analysis.
For a new research paper on this topic, I am working on a framework which uses git bisect to identify the commit responsible for a performance regression.

## Example 1: recent slowdown in `data.table::fread`

Three years ago, I was PI of the NSF POSE project about R `data.table`, a high-performance in-memory database system.
Recently [I re-ran some benchmarks](https://tdhock.github.io/blog/2026/dt-atime-update/), using updated software and hardware.

Below is the original from 2023, old code and old hardware:

![read old code old laptop](/assets/img/2026-10-09-bisect-performance/read-old-code-old-laptop.png)

Below is the new code and old hardware:

![read new code old laptop](/assets/img/2026-10-09-bisect-performance/read-new-code-old-laptop.png)

Below is the new code and new hardware:

![read new code new laptop](/assets/img/2026-10-09-bisect-performance/read-new-code-new-laptop.png)

We can see that the reading function is slower!
When was this slowdown introduced?

I wrote the new `atime::bisect()` function in [atime](https://github.com/tdhock/atime/pull/131) for answering this question.

I added a new test case in [PR7907](https://github.com/Rdatatable/data.table/pull/7907).

```r
"fread N=cols regression" = atime::atime_test(
    N = 2^seq(0, 20), # smaller N because disk can be slow.
    setup={
      set.seed(1)
      n.rows <- 100
      input.vec <- rnorm(n.rows*N)
      input.mat <- matrix(input.vec, n.rows, N)
      input.dt <- data.table(input.mat)
      input.csv <- tempfile()
      data.table::fwrite(input.dt, input.csv)
    },
    seconds.limit=0.1,
    Fast="1.14.8",
    # Fast="1685a3b47d48f323afeae589545f7cbb7717ec28", #not as fast as Fast, but using this as Fast in bisect with Slow=1.18.6 yields PR#7370.
    # Slow="67db7f7fb33b99da8cc5dc575714924b96d0f0fe", #not as slow as Slow, but using this as Slow in bisect with Fast=1.14.8 yields PR#7375.
    Slow="1.18.6",
    expr=data.table::fread(input.csv, showProgress = FALSE, nThread=1)),
```

The key parts of the code below which enable performance bisecting are the Fast/Slow commits.
We run `git bisect` with old=Fast and new=Slow, and we get [this interesting result](https://tdhock.github.io/2026-10-09-fread-git-bisect/):

![fread](/assets/img/2026-10-09-bisect-performance/fread-perf-bisect-overview.png)

We see in the first bisect on the left, that the bisect stopped with an intermediate performance, about halfway between Fast and Slow.
So we re-ran git bisect twice more, and we found two different PRs related to fread, which likely caused the slowdown, see below.

```
#Fast="1685a3b47d48f323afeae589545f7cbb7717ec28", #not as fast as Fast, but use as Fast in bisect with Slow.
#Slow="1.18.6",
df7fa8071c6b818d24e47cc1a84a6dc0491550d6 is the first bad commit
commit df7fa8071c6b818d24e47cc1a84a6dc0491550d6
Author: Benjamin Schwendinger <52290390+ben-schwen@users.noreply.github.com>
Date:   Mon Nov 3 22:03:18 2025 +0100

    fix sep detection for single column quoted file (#7370)
    
    * fix sep detection for single column quoted file
    
    * restore old comment
    
    * remove unnecessary check
    
    * simplify quote scan
    
    * Renumber NEWS

 NEWS.md               |  2 ++
 inst/tests/tests.Rraw |  3 +++
 src/fread.c           | 27 +++++++++++++++++++++------
 3 files changed, 26 insertions(+), 6 deletions(-)
bisect found first bad commit
```

Both the bisect above, and the bisect below, revealed PRs related to fread, which could be plausibly blamed for the performance degradation.

```
#Fast="1.14.8",
#Slow="67db7f7fb33b99da8cc5dc575714924b96d0f0fe", #not as slow as Slow, but use as Slow in bisect with Fast.
59f966cf6839a0494e42ed1ab98616eea03dcb36 is the first bad commit
commit 59f966cf6839a0494e42ed1ab98616eea03dcb36
Author: Benjamin Schwendinger <52290390+ben-schwen@users.noreply.github.com>
Date:   Mon Oct 20 19:20:52 2025 +0200

    implement comment.char argument for fread (#7375)
    
    * implement comment.char argument for fread
    
    * remove handling of comment.char=NULL
    
    * update NEWS
    
    * update tests
    
    * change wording for error
    
    * remove unreachable code
    
    * add helper function
    
    * extend tests
    
    * update tests
    
    * use skip_line helper
    
    * add comments for helpers
    
    * fix test numbering
    
    * add more tests
    
    * simplify read
    
    * Revert "simplify read"
    
    This reverts commit a0a9525cd4b862d08d4eba9942086a2fbc2a101b.
    
    * separate helpers
    
    * add comments
    
    * add coverage
    
    * simplify header handling
    
    * increase coverage
    
    * simplify code
    
    * control skipping white spaces before comments with strip.white
    
    * tighten helper
    
    * try improving readability with blank lines
    
    * include some line-end comments in the multi-line comment test
    
    * match read.table for na.strings and comment.char
    
    * add strip.white=FALSE header testcase
    
    * refactor end_of_field helper into more readable version
    
    * add example for strip.white
    
    * summarize line-skipping behavior
    
    * clean up tmp
    
    * don't introduce whitespace to string literal body
    
    ---------
    
    Co-authored-by: Michael Chirico <chiricom@google.com>

 NEWS.md               |   1 +
 R/fread.R             |   7 ++-
 inst/tests/tests.Rraw | 127 ++++++++++++++++++++++++++++++++++++++++++++++++++
 man/fread.Rd          |   3 +-
 src/data.table.h      |   2 +-
 src/fread.c           | 125 ++++++++++++++++++++++++++++++++++++++++++++-----
 src/fread.h           |   4 ++
 src/freadR.c          |   3 ++
 8 files changed, 257 insertions(+), 15 deletions(-)
bisect found first bad commit
```

## Example 2: previous known slowdown in min/max by group

The second example we discuss in the new paper is how `atime::bisect()` gets the same results as in [PR7912](https://github.com/Rdatatable/data.table/pull/7912).

![reg before](/assets/img/2026-10-09-bisect-performance/dt-by-reg-before.png)

![slow fast](/assets/img/2026-10-09-bisect-performance/dt-by-slow-fast.png)

We first got the two results above, but those are only two of five change-points in performance for that test case.
To understand which PRs affect performance, we created a [new gallery-atime with interactive graphics](https://tdhock.github.io/gallery-atime) created from git bisect data, including [this one](https://tdhock.github.io/2026-10-13-bisect-performance-pr7912/) which shows details for five change-points found using seven bisects.
Below we see a non-interactive timeline of throughput as a function of commits over time.

![slow timeline](/assets/img/2026-10-09-bisect-performance/viz-PR7912-timeline.png)

And below we see the amount of time it takes to compute the bisects for this test case.

![slow minutes](/assets/img/2026-10-09-bisect-performance/viz-PR7912-minutes.png)

### Comparison between machines

Two computers (2010 and 2025), 10x absolute throughput differences, same qualitative results, both reasonable wall time.

![reg before](/assets/img/2026-10-09-bisect-performance/dt-by-reg-before-compare.png)

![slow fast](/assets/img/2026-10-09-bisect-performance/dt-by-slow-fast-compare.png)

## Example 3: ponca

Ponca is a C++ library for point cloud analysis, created by Nicolas Mellado, visiting scholar in Sherbrooke last year.
We worked together to set up atime for testing ponca in the poncatime repo, and the [git bisect analysis](https://tdhock.github.io/2026-10-16-ponca-git-bisect-asoCurvatureEstimation/) revealed a bug fix commit that was responsible for a constant factor slowdown between ponca v1.0 and v1.4.

## New `bisect.commits` argument

At first I thought we should comment the commits used only in bisect analysis, because we don’t want to see too many commit curves on the regular CI performance test plot.
But it is a hassle to have to comment and uncomment when you want to run a git bisect analysis, so I created a new `bisect.commits` argument, that I proposed to use in test case definitions in PRs [#7912 min/max by group test](https://github.com/Rdatatable/data.table/pull/7912/files) and [#7907 fread test](https://github.com/Rdatatable/data.table/pull/7907/files). So we can use those commits as old/new in git bisect, but they will not show up to clutter the regular CI figure.

## Related papers and software

I invited my colleague Alex Groce to co-author the paper, and he added some very relevant citations to the software engineering literature.
For example [Goldsmith, Aiken, Wilkerson, Measuring empirical computational complexity, ESEC-FSE’07](https://dl.acm.org/doi/abs/10.1145/1287624.1287681) uses regression to estimate big-O complexity from iteration count data (our atime uses classification and wall time instead).

Another example is the GuessCompx R package, published only once on CRAN in 2019.

* like atime, it did empirical estimation of asymptotic (big-O) time/memory complexity.
* like atime, it used classification with reference curves (constant, linear, quadratic, cubic, squareroot, log, NlogN).

but there are numerous differences:

* atime only fits to large N, GuessCompx uses all N (unfortunately including N in constant overhead regime).
* atime fits by distance to second largest data point, GuessCompx fits by leave-one-out CV.
* atime can fit asymptotic reference curves to arbitrary units, GuessCompx is limited to time and memory.
* atime runs several expressions, GuessCompx runs one function.
* atime plots use log-log scales, GuessCompx plot use linear scales (which hide details because N is varied on a log scale).

## Conclusions

In preparing a paper submission about atime, I ended up writing some new code to make bisect performance analysis easy.
The basic workflow is:

* identify a use case for which performance is important
* identify a pair of old/new commits with different performance
* use that information to write a test case in `pkg/.ci/atime/tests.R`
* run `atime::bisect("pkg","test_name","old_commit","new_commit")` as in [#7912 min/max by group test](https://github.com/Rdatatable/data.table/pull/7912/files)
* use animint2 to visualize the performance over the commit history, and the detailed asymptotic timings obtained to decide each commit tested. For example, see [viz.R](https://github.com/tdhock/data.table-pr7912-bisect-viz/blob/main/viz.R) for the animint2 viz code used to make [this viz](https://tdhock.github.io/2026-10-13-bisect-performance-pr7912).

I intend to use this framework in the future to bisect other performance issues in R data.table.
