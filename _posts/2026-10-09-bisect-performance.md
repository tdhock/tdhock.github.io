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

![read old code old laptop](/assets/img/2024-06-20-directions/map-to-tobys-office.png)



The CSV writing function looked about the same, but the reading function was slower!
When was this slowdown introduced?

I wrote some new functions in [atime](https://github.com/tdhock/atime/pull/131) for answering this question.

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


## Example 2

[PR7912](https://github.com/Rdatatable/data.table/pull/7912)
