---
layout: post
title: Parsing check logs using regular expressions
description: A demonstration of nc R package
---



The goal of this blog post is to explain how to use
[nc](https://github.com/tdhock/nc) to parse CRAN check log files, as
we did in [data.table-revdeps issue#7](
https://github.com/tdhock/data.table-revdeps/issues/7), to support our
NSF POSE funded project about expanding the open-source ecosystem
around R `data.table`.

## Example data to parse

For our project we want to create a system that automatically checks
reverse dependencies (revdeps) of `data.table`, meaning all the other
R packages which depend on it (or Import etc).  The system checks each
revdep, using two versions of `data.table` (GitHub master and CRAN
release), and then reports if there are any differences in check
results. If there is a failure in the revdep check using `data.table`
GitHub master, but not using CRAN release, then we know there is some
revdep issue which should be addressed before sending the current
GitHub version to CRAN.

However, if a revdep does not have its dependencies available at check
time, then the check will always fail with an ERROR, or skip some
checks (for both versions of `data.table`), thereby creating the
possibility of a false negative (there could be a significant
difference due to the new code on GitHub, but we will not be able to
detect it). So ideally the system should also detect and report these
dependencies which are not available, which appear in the check result
as below,


```r
some.check.out <- "
* this is package 'scoper' version '1.3.0'
* package encoding: UTF-8
* checking package namespace information ... OK
* checking package dependencies ... ERROR
Packages required but not available: 'alakazam', 'shazam'

See section 'The DESCRIPTION file' in the 'Writing R Extensions'
manual.
* DONE

Status: 1 ERROR

* this is package 'margins' version '0.3.26'
* checking package namespace information ... OK
* checking package dependencies ... NOTE
Packages which this enhances but not available for checking:
  'AER', 'betareg', 'ordinal', 'survey'
* checking if this is a source package ... OK

* checking package dependencies ... ERROR
Package required but not available: 'Rcmdr'

Package suggested but not available for checking: 'tkrplot'

See section 'The DESCRIPTION file' in the 'Writing R Extensions'
manual.

* checking package dependencies ... ERROR
Packages required but not available:
  'adjclust', 'BiocGenerics', 'csaw', 'InteractionSet', 'limma',
  'SummarizedExperiment', 'HiCDOC'

* checking package dependencies ... NOTE
Package suggested but not available for checking: 'gWidgets2tcltk'
* checking if this is a source package ... OK

* checking package dependencies ... ERROR
Packages required but not available: 'maftools', 'NMF'

Packages suggested but not available for checking:
  'Biobase', 'Biostrings', 'BSgenome', 'BSgenome.Hsapiens.UCSC.hg19',
  'GenomicRanges', 'GenSA', 'IRanges'

See section 'The DESCRIPTION file' in the 'Writing R Extensions'
manual.
* DONE
"
```

How to parse the wide variety of data in the text above? We would like to extract

* the type of dependency (required/suggested/enhances), which always
  appears before the phrase "but not available" and
* the names of the dependent packages, which always appear inside
  single quotes, after a colon (maybe on several lines).
  
Since the data are regularly structured text, we can parse them using
regular expressions (regex).

## Parsing using nc

[nc](https://cloud.r-project.org/web/packages/nc/) is my R package for
named capture regex, which we will use for this text parsing
task. First, the code below defines a regex to capture the dependency
type, 


```r
type.not.avail.pattern <- list(
  type='suggested|enhances|required',
  ' but not available')
```

When using the nc package, we define a regex as a list.

* Values in the list are concatenated to form the regex, and
* each named list element becomes a capture group, and the
  name used in R code becomes the column name in the resulting data table.

We use the regex in the code below to parse the dependency types, 


```r
nc::capture_all_str(some.check.out, type.not.avail.pattern)
```

```
##         type
##       <char>
## 1:  required
## 2:  enhances
## 3:  required
## 4: suggested
## 5:  required
## 6: suggested
## 7:  required
## 8: suggested
```

The output above is a data table with one row for every match, and one
column for every capture group (only one, `type`).
One advantage of the nc package is that it makes it easy to build complex regex from simple pieces.
For example consider the code below, which starts with the previous regex, 
then adds another group `before.colon`, and matches up to the colon:


```r
up.to.colon.pattern <- list(
  type.not.avail.pattern,
  before.colon='.*?',
  ':')
nc::capture_all_str(some.check.out, up.to.colon.pattern)
```

```
##         type  before.colon
##       <char>        <char>
## 1:  required              
## 2:  enhances  for checking
## 3:  required              
## 4: suggested  for checking
## 5:  required              
## 6: suggested  for checking
## 7:  required              
## 8: suggested  for checking
```

The output above contains a new column `before.colon` which contains
the text captured before the colon.
Below we define a new regex that captures the text after the colon,
one or more lines (non-greedy), up to the next line which starts with star or newline.


```r
one.or.more.lines.non.greedy <- '(?:.*\n)+?'
up.to.deps.pattern <- list(
  up.to.colon.pattern,
  deps=one.or.more.lines.non.greedy,
  "[*|\n]")
(some.check.dt <- nc::capture_all_str(some.check.out, up.to.deps.pattern))
```

```
##         type  before.colon
##       <char>        <char>
## 1:  required              
## 2:  enhances  for checking
## 3:  required              
## 4: suggested  for checking
## 5:  required              
## 6: suggested  for checking
## 7:  required              
## 8: suggested  for checking
##                                                                                                                deps
##                                                                                                              <char>
## 1:                                                                                           'alakazam', 'shazam'\n
## 2:                                                                      \n  'AER', 'betareg', 'ordinal', 'survey'\n
## 3:                                                                                                        'Rcmdr'\n
## 4:                                                                                                      'tkrplot'\n
## 5:         \n  'adjclust', 'BiocGenerics', 'csaw', 'InteractionSet', 'limma',\n  'SummarizedExperiment', 'HiCDOC'\n
## 6:                                                                                               'gWidgets2tcltk'\n
## 7:                                                                                              'maftools', 'NMF'\n
## 8: \n  'Biobase', 'Biostrings', 'BSgenome', 'BSgenome.Hsapiens.UCSC.hg19',\n  'GenomicRanges', 'GenSA', 'IRanges'\n
```

The output above contains a new column `deps` with all of the text
(over possibly several lines) that contains the dependent package
names. Another way to view the dependent packages is shown below as a
character string,


```r
some.check.dt[["deps"]]
```

```
## [1] " 'alakazam', 'shazam'\n"                                                                                         
## [2] "\n  'AER', 'betareg', 'ordinal', 'survey'\n"                                                                     
## [3] " 'Rcmdr'\n"                                                                                                      
## [4] " 'tkrplot'\n"                                                                                                    
## [5] "\n  'adjclust', 'BiocGenerics', 'csaw', 'InteractionSet', 'limma',\n  'SummarizedExperiment', 'HiCDOC'\n"        
## [6] " 'gWidgets2tcltk'\n"                                                                                             
## [7] " 'maftools', 'NMF'\n"                                                                                            
## [8] "\n  'Biobase', 'Biostrings', 'BSgenome', 'BSgenome.Hsapiens.UCSC.hg19',\n  'GenomicRanges', 'GenSA', 'IRanges'\n"
```

## Downloading log files

In this section, we download some log files which we can analyze using the approach in the previous section.
First in the code below, 
we define a local directory to save the log files,


```r
local.dir <- "~/teaching/regex-tutorial/cran-check-logs"
dir.create(local.dir, showWarnings = FALSE)
```

Note that the directory defined above is actually in a clone of my
[regex-tutorial](https://github.com/tdhock/regex-tutorial) repo (which
has a copy of these data).
Then in the code below, we download a CSV
summary of checks from the revdep check server:


```r
analyze.url <- "https://rcdata.nau.edu/genomic-ml/data.table-revdeps/analyze/"
remote.url.prefix <- paste0(
  analyze.url,
  "2024-01-22", #strftime(Sys.time(), "%Y-%m-%d"),
  "/")
remote.csv <- paste0(remote.url.prefix, "full_list_of_jobs.csv")
(jobs.dt <- data.table::fread(remote.csv))
```

```
##        task     time    MB     State        Package sig.diffs not.avail config.fail dl.fail
##       <int>   <char> <int>    <char>         <char>     <int>     <int>       <int>   <int>
##    1:     1 00:03:32   291 COMPLETED         Ac3net         0         0           0       0
##    2:     2 00:06:04   558 COMPLETED  accessibility         0         0           0       0
##    3:     3 00:10:47   443 COMPLETED          acdcR         0         0           0       0
##    4:     4 00:08:20   389 COMPLETED       Achilles         0         0           0       0
##    5:     5 00:11:11   478 COMPLETED          actel         0         1           1       0
##   ---                                                                                      
## 1463:  1463 00:02:28   207 COMPLETED  youngSwimmers         0         0           0       0
## 1464:  1464 00:05:08   549 COMPLETED           zebu         0         0           0       0
## 1465:  1465 00:07:37   586 COMPLETED       zeitgebr         0         0           0       0
## 1466:  1466 00:05:51   413 COMPLETED         ZIprop         0         0           0       0
## 1467:  1467 00:57:27  1283 COMPLETED zoomGroupStats         0         0           0       0
```

The table above contains one row for each revdep of `data.table`. 
The `not.avail` column indicates the number of "not available" 
messages which were output while checking the revdep.


```r
(not.avail.logs <- jobs.dt[not.avail>0])
```

```
##       task     time    MB     State       Package sig.diffs not.avail config.fail dl.fail
##      <int>   <char> <int>    <char>        <char>     <int>     <int>       <int>   <int>
##   1:     5 00:11:11   478 COMPLETED         actel         0         1           1       0
##   2:    16 00:11:27   489 COMPLETED agriutilities         0         1           0       0
##   3:    27 00:09:09   413 COMPLETED           AMR         0         4           0       0
##   4:    29 00:08:31   585 COMPLETED      Anaconda         0         1           0       0
##   5:    41 00:24:53  1280 COMPLETED         aPEAR         0         4           0       0
##  ---                                                                                     
## 149:  1434 00:03:33   354 COMPLETED        WGScan         0         1           0       0
## 150:  1437 00:13:18  1461 COMPLETED          wiad         0         1           0       0
## 151:  1439 00:10:54   598 COMPLETED        wilson         0         1           0       0
## 152:  1449 00:02:53   534 COMPLETED           wTO         0         1           0       0
## 153:  1461 00:05:31   577 COMPLETED      xplorerr         0         1           0       0
```

The table above has one row for every package that depends/imports/etc
`data.table`, and that has some dependencies which were not available
at checking.  The code block below is a for loop which downloads the
log for for each of those packages.


```r
for(pkg.i in 1:nrow(not.avail.logs)){
  pkg.row <- not.avail.logs[pkg.i]
  pkg.txt <- paste0(pkg.row$Package, ".txt")
  local.txt <- file.path(local.dir, pkg.txt)
  if(!file.exists(local.txt)){
    remote.txt <- paste0(remote.url.prefix, pkg.txt)
    download.file(remote.txt, local.txt)
  }
  if(file.size(local.txt)>1024*1024){
    unlink(local.txt)
  }
}
```

## Another regex to parse package list strings

Next, we use the previous regex to parse one 
representative log file using the code below.


```r
(one.log.txt <- file.path(local.dir, "CNVScope.txt"))
```

```
## [1] "~/teaching/regex-tutorial/cran-check-logs/CNVScope.txt"
```

```r
(one.not.avail.dt <- nc::capture_all_str(one.log.txt, up.to.deps.pattern))
```

```
##         type  before.colon
##       <char>        <char>
## 1:  required              
## 2: suggested  for checking
## 3:  required              
## 4: suggested  for checking
## 5:  required              
## 6: suggested  for checking
## 7:  required              
## 8: suggested  for checking
##                                                                                                            deps
##                                                                                                          <char>
## 1:                                                        \n  'GenomicInteractions', 'biomaRt', 'rtracklayer'\n
## 2: \n  'InteractionSet', 'GenomicRanges', 'GenomicFeatures', 'GenomeInfoDb',\n  'BSgenome.Hsapiens.UCSC.hg19'\n
## 3:                                                        \n  'GenomicInteractions', 'biomaRt', 'rtracklayer'\n
## 4: \n  'InteractionSet', 'GenomicRanges', 'GenomicFeatures', 'GenomeInfoDb',\n  'BSgenome.Hsapiens.UCSC.hg19'\n
## 5:                                                        \n  'GenomicInteractions', 'biomaRt', 'rtracklayer'\n
## 6: \n  'InteractionSet', 'GenomicRanges', 'GenomicFeatures', 'GenomeInfoDb',\n  'BSgenome.Hsapiens.UCSC.hg19'\n
## 7:                                                        \n  'GenomicInteractions', 'biomaRt', 'rtracklayer'\n
## 8: \n  'InteractionSet', 'GenomicRanges', 'GenomicFeatures', 'GenomeInfoDb',\n  'BSgenome.Hsapiens.UCSC.hg19'\n
```

The code above parses the log file using the same regex as in the
previous section. It returns a data table with one row per message
about dependent packages missing during checks. We can further parse
the `deps` column into a new column with one dependent package name on
each row, using the code below. Note we use a new regex
`quoted.pattern` which can be interpreted as follows:

* first match a single quote, 
* then match can capture zero or more (non-greedy) of anything except a newline, (this will capture the missing dependent package name)
* then match another single quote.


```r
quoted.pattern <- list("'", dep.pkg=".*?", "'")
```

In the code below, we use `by=.(deps,type)` so that the regex matching
of `quoted.pattern` happens for each unique value of `deps`.


```r
one.not.avail.dt[
, nc::capture_all_str(deps, quoted.pattern)
, by=.(deps,type)]
```

```
##                                                                                                            deps
##                                                                                                          <char>
## 1:                                                        \n  'GenomicInteractions', 'biomaRt', 'rtracklayer'\n
## 2:                                                        \n  'GenomicInteractions', 'biomaRt', 'rtracklayer'\n
## 3:                                                        \n  'GenomicInteractions', 'biomaRt', 'rtracklayer'\n
## 4: \n  'InteractionSet', 'GenomicRanges', 'GenomicFeatures', 'GenomeInfoDb',\n  'BSgenome.Hsapiens.UCSC.hg19'\n
## 5: \n  'InteractionSet', 'GenomicRanges', 'GenomicFeatures', 'GenomeInfoDb',\n  'BSgenome.Hsapiens.UCSC.hg19'\n
## 6: \n  'InteractionSet', 'GenomicRanges', 'GenomicFeatures', 'GenomeInfoDb',\n  'BSgenome.Hsapiens.UCSC.hg19'\n
## 7: \n  'InteractionSet', 'GenomicRanges', 'GenomicFeatures', 'GenomeInfoDb',\n  'BSgenome.Hsapiens.UCSC.hg19'\n
## 8: \n  'InteractionSet', 'GenomicRanges', 'GenomicFeatures', 'GenomeInfoDb',\n  'BSgenome.Hsapiens.UCSC.hg19'\n
##         type                     dep.pkg
##       <char>                      <char>
## 1:  required         GenomicInteractions
## 2:  required                     biomaRt
## 3:  required                 rtracklayer
## 4: suggested              InteractionSet
## 5: suggested               GenomicRanges
## 6: suggested             GenomicFeatures
## 7: suggested                GenomeInfoDb
## 8: suggested BSgenome.Hsapiens.UCSC.hg19
```

The output above is a table with one row per dependent package that
was missing during the check. This second regex has successfully
transformed the long character string with quoted package names, into
a data table with one row for each package name.

## Wrapping both regex operations in a function

To wrap the two regex operations above, we define the function below.
Note that since `nc::capture_all_str` returns a data table, 
and the data table square brackets also returns a data table,
we can use the square brackets to define a chain/pipeline of operations.

* First, use `up.to.deps.pattern` to get a table with one row for each
  message about dependent packages missing during the check,
* Second, use `quoted.pattern` on each value of `deps`, to get another
  table, with one row for each missing dependent package,
* Finally, return only the `type` and `dep.pkg` columns.


```r
read_log <- function(log.txt){
  nc::capture_all_str(
    log.txt, up.to.deps.pattern
  )[
  , nc::capture_all_str(deps, quoted.pattern)
  , by=.(type, deps)
  ][
  , .(type, dep.pkg)
  ]
}
read_log(one.log.txt)
```

```
##         type                     dep.pkg
##       <char>                      <char>
## 1:  required         GenomicInteractions
## 2:  required                     biomaRt
## 3:  required                 rtracklayer
## 4: suggested              InteractionSet
## 5: suggested               GenomicRanges
## 6: suggested             GenomicFeatures
## 7: suggested                GenomeInfoDb
## 8: suggested BSgenome.Hsapiens.UCSC.hg19
```

The output above includes one row for each dependent package which was
missing during the package check (same as before, but now in a
function, and omitting the `deps` column).

## Parsing several log files

In this section we use the function that we created in the previous
section, to parse several check log files.
The code below defines a glob, for defining a set of log
files to analyze,


```r
(log.glob <- file.path(local.dir, "*.txt"))
```

```
## [1] "~/teaching/regex-tutorial/cran-check-logs/*.txt"
```

The call to `nc:capture_first_glob` in the code below can be
interpreted as follows:

* the first argument is the glob specifying files to read,
* the argument named `READ` is a function that is used to read each file, (should return a data table)
* and the other arguments specify a regex which is matched to each file name: the `Package` name to capture is anything except slash, one or more (up to `.txt`).


```r
(log.dt <- nc::capture_first_glob(
  log.glob,
  Package="[^/]+", "[.]txt$",
  READ=read_log))
```

```
##       Package      type dep.pkg
##        <char>    <char>  <char>
##   1:      AMR  enhances cleaner
##   2:      AMR  enhances janitor
##   3:      AMR  enhances   skimr
##   4:      AMR  enhances tsibble
##   5: Anaconda  required  DESeq2
##  ---                           
## 244: vaersvax suggested vaersND
## 245:      wTO  required   Rfast
## 246:     wiad suggested   rgdal
## 247:   wilson  required  DESeq2
## 248: xplorerr suggested  rbokeh
```

The output above is a data table, which has one row for each missing
dependent package reported in each log file. The `Package` column
contains the name of the package which was checked, and the `dep.pkg`
column contains the name of the dependent package which was missing
during that check.

If we want to report only the first log which contains a reference to
a missing dependent package, we can use the code below. Note that
`.SD` is a data table that means "subset of data" corresponding to the
current `by` group. And `keyby` is used instead of `by` to ensure that
the output is sorted by `type`, then by `dep.pkg`.


```r
(first.missing <- log.dt[, .SD[1], keyby=.(type, dep.pkg)])
```

```
## Key: <type, dep.pkg>
##           type   dep.pkg    Package
##         <char>    <char>     <char>
##   1:  enhances       AER    margins
##   2:  enhances       MNP prediction
##   3:  enhances      VGAM prediction
##   4:  enhances     WGCNA dendextend
##   5:  enhances       aod prediction
##  ---                               
## 158: suggested toscaData      tosca
## 159: suggested     vaers vaersNDvax
## 160: suggested   vaersND vaersNDvax
## 161: suggested       wTO     CoDiNA
## 162: suggested      xcms     LCMSQA
```

The table above has one row for each unique combination of `type` and
`dep.pkg`, where the value of `Package` is the first log which
reported that missing dependency.

## Conclusion

We have seen how to use the `nc` R package to parse CRAN check log
files. More generally, `nc` is useful whenever you have regularly
structured text data/files, from which you would like to extract a
data table, with one column for each capture group in a regex.

* `nc::capture_all_str` matches a regex to a text string/file, and
  returns a data table with one row for each match.
* `nc::capture_first_glob` inputs a glob, gets a list of matching file
  names, then matches a regex to each file name, and combines the
  capture groups from that match, with whatever data table is returned
  by calling the `READ` function on each file name.

## Exercise for the reader

Imagine that the files were numbered (`12.txt`) instead of named
(`actel.txt`). In that case how could you create the `Package` column?
It is reported in the package check log, so try to modify the regex
code to parse that out of each log file. Hint: the relevant part of
the log is below. 


```r
partial.log <- "
* using session charset: ASCII
* checking for file 'actel/DESCRIPTION' ... OK
* this is package 'actel' version '1.3.0'
* package encoding: UTF-8
* checking package namespace information ... OK
* checking package dependencies ... NOTE
Package suggested but not available for checking: 'gWidgets2tcltk'
* checking if this is a source package ... OK
"
```

## Session info


```r
sessionInfo()
```

```
## R version 4.3.2 (2023-10-31 ucrt)
## Platform: x86_64-w64-mingw32/x64 (64-bit)
## Running under: Windows 10 x64 (build 19045)
## 
## Matrix products: default
## 
## 
## locale:
## [1] LC_COLLATE=English_United States.utf8  LC_CTYPE=English_United States.utf8    LC_MONETARY=English_United States.utf8
## [4] LC_NUMERIC=C                           LC_TIME=English_United States.utf8    
## 
## time zone: America/Phoenix
## tzcode source: internal
## 
## attached base packages:
## [1] stats     graphics  grDevices utils     datasets  methods   base     
## 
## loaded via a namespace (and not attached):
## [1] compiler_4.3.2     nc_2023.8.24       tools_4.3.2        data.table_1.14.99 knitr_1.45         xfun_0.41         
## [7] evaluate_0.23
```
