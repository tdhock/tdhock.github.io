---
layout: post
title: Checking R package on M1 Mac
description: Web services for R package developers
---

For a research project about supervised changepoint detection, we are
developing the [aum](https://github.com/tdhock/aum) R package. With my
student Jadon Fowler, we recently merged [a big
PR](https://github.com/tdhock/aum/pull/3) that included a solid C++
implementation of line search (which can handle ties, paper with
details in progress). I would like to submit the updated R package to
CRAN, the Comprehensive R Archive Network. Before submission, they
require you to fix outstanding issues, which are currently listed as:

```
Check Details

Version: 2022.2.7
Check: re-building of vignette outputs
Result: ERROR
    Error(s) in re-building vignettes:
    --- re-building 'accuracy-comparison.Rmd' using knitr
    Data sets in package 'mlbench':
    
    BostonHousing Boston Housing Data
    BostonHousing2 Boston Housing Data
    BreastCancer Wisconsin Breast Cancer Database
    DNA Primate splice-junction gene sequences (DNA)
    Glass Glass Identification Database
    HouseVotes84 United States Congressional Voting Records 1984
    Ionosphere Johns Hopkins University Ionosphere database
    LetterRecognition Letter Image Recognition Data
    Ozone Los Angeles ozone pollution data, 1976
    PimaIndiansDiabetes Pima Indians Diabetes Database
    PimaIndiansDiabetes2 Pima Indians Diabetes Database
    Satellite Landsat Multi-Spectral Scanner Image Data
    Servo Servo Data
    Shuttle Shuttle Dataset (Statlog version)
    Sonar Sonar, Mines vs. Rocks
    Soybean Soybean Database
    Vehicle Vehicle Silhouettes
    Vowel Vowel Recognition (Deterding data)
    Zoo Zoo Data
    
    Quitting from lines 117-226 (accuracy-comparison.Rmd)
    Error: processing vignette 'accuracy-comparison.Rmd' failed with diagnostics:
    polygon edge not found
    --- failed re-building 'accuracy-comparison.Rmd'
    
    --- re-building 'speed-comparison.Rmd' using knitr
    Quitting from lines 49-67 (speed-comparison.Rmd)
    Error: processing vignette 'speed-comparison.Rmd' failed with diagnostics:
    polygon edge not found
    --- failed re-building 'speed-comparison.Rmd'
    
    SUMMARY: processing the following files failed:
     'accuracy-comparison.Rmd' 'speed-comparison.Rmd'
    
    Error: Vignette re-building failed.
    Execution halted
Flavor: r-release-macos-arm64 
```

To fix the error, the first step is to try to reproduce it. This
`polygon edge not found` error is not something I have ever seen on my
Ubuntu and windows machines. I do not have access to an M1 (arm64)
mac, so how can I reproduce this?

There are two web services that provide mac R package checks:
- [Mac Builder](https://mac.r-project.org/macbuilder/submit.html)
- [R-Hub Builder](https://builder.r-hub.io/)


To use Mac Builder I just upload the tar.gz file from my built
package, and then I get a web page with results, which says

```
* checking re-building of vignette outputs ... [196s/200s] OK
```

So Mac Builder says my updated package does not have the problem, that
is good right? But when I upload the current CRAN version it also says
no problem,

```
* checking re-building of vignette outputs ... [27s/27s] OK
```

So that means Mac Builder is not doing the same thing as CRAN Flavor
r-release-macos-arm64.

R-hub is supposed to be able to check too, but I got some errors which
seem to indicate that it is out of disk space, so I filed an
[issue](https://github.com/r-hub/rhub/issues/554).

