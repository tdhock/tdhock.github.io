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

R-hub is supposed to be able to check too. You can list the current
platforms which are available for checking via

```r
> rhub::platforms()
debian-clang-devel:
  Debian Linux, R-devel, clang, ISO-8859-15 locale
debian-gcc-devel:
  Debian Linux, R-devel, GCC
debian-gcc-devel-nold:
  Debian Linux, R-devel, GCC, no long double
debian-gcc-patched:
  Debian Linux, R-patched, GCC
debian-gcc-release:
  Debian Linux, R-release, GCC
fedora-clang-devel:
  Fedora Linux, R-devel, clang, gfortran
fedora-gcc-devel:
  Fedora Linux, R-devel, GCC
linux-x86_64-rocker-gcc-san:
  Debian Linux, R-devel, GCC ASAN/UBSAN
macos-highsierra-release:
  macOS 10.13.6 High Sierra, R-release, brew
macos-highsierra-release-cran:
  macOS 10.13.6 High Sierra, R-release, CRAN's setup
solaris-x86-patched:
  Oracle Solaris 10, x86, 32 bit, R-release
solaris-x86-patched-ods:
  Oracle Solaris 10, x86, 32 bit, R release, Oracle Developer Studio 12.6
ubuntu-gcc-devel:
  Ubuntu Linux 20.04.1 LTS, R-devel, GCC
ubuntu-gcc-release:
  Ubuntu Linux 20.04.1 LTS, R-release, GCC
ubuntu-rchk:
  Ubuntu Linux 20.04.1 LTS, R-devel with rchk
windows-x86_64-devel:
  Windows Server 2022, R-devel, 64 bit
windows-x86_64-oldrel:
  Windows Server 2022, R-oldrel, 32/64 bit
windows-x86_64-patched:
  Windows Server 2022, R-patched, 32/64 bit
windows-x86_64-release:
  Windows Server 2022, R-release, 32/64 bit
```

The platform/command that I hoped would work to reproduce is 

```r
> rhub::check("path/to/pkg_1.0.tar.gz", "macos-highsierra-release-cran")
...
* checking re-building of vignette outputs ...Build timed out (after 10 minutes). Marking the build as failed.
Build was aborted
Pinging https://builder.r-hub.io/build/FAILURE/aum_2023.4.3.tar.gz-c02bbd656bec4f15bb0c5fa8000dadde/2023-04-03T21:04:18Z
{"status":"ok"}
Finished: FAILURE
```

Strangely, I get ok status, even though the build failed, is this a
bug? In any case my "polygon edge not found" is not reproducible here,
either.
