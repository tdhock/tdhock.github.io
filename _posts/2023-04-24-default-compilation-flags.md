---
layout: post
title: Modifying default gcc compilation flags
description: When compiling R packages
---

CRAN recently sent me an email which said that I need to update
PeakSegJoint to silence the following compilation warnings

```
Version: 2022.4.6
Check: whether package can be installed
Result: WARN
    Found the following significant warnings:
     PeakSegJoint_interface.c:113:32: warning: a function declaration without a prototype is deprecated in all versions of C [-Wstrict-prototypes]
    See ‘/home/hornik/tmp/R.check/r-devel-clang/Work/PKGS/PeakSegJoint.Rcheck/00install.out’ for details.
    * used C compiler: ‘Debian clang version 15.0.6’
Flavor: r-devel-linux-x86_64-debian-clang

Version: 2022.4.6
Check: whether package can be installed
Result: WARN
    Found the following significant warnings:
     PeakSegJoint_interface.c:113:6: warning: function declaration isn’t a prototype [-Wstrict-prototypes]
    See ‘/home/hornik/tmp/R.check/r-devel-gcc/Work/PKGS/PeakSegJoint.Rcheck/00install.out’ for details.
    * used C compiler: ‘gcc-12 (Debian 12.2.0-14) 12.2.0’
Flavor: r-devel-linux-x86_64-debian-gcc
```

The first step to fixing the problem is to reproduce it locally. But I
am using a different version of gcc:

```
(base) tdhock@maude-MacBookPro:~/tdhock.github.io(master)$ gcc --version
gcc (GCC) 10.1.0
Copyright (C) 2020 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

GCC 10 has different/fewer default warnings than GCC 12. So by
default my GCC 10 tells me

```
(base) tdhock@maude-MacBookPro:~/R/PeakSegJoint(master*)$ rm -f src/PeakSegJoint_interface.o && R CMD INSTALL .
Loading required package: grDevices
* installing to library ‘/home/tdhock/lib/R/library’
* installing *source* package ‘PeakSegJoint’ ...
** using staged installation
** libs
gcc -I"/home/tdhock/lib/R/include" -DNDEBUG   -I/usr/local/include   -fpic  -g -O2  -c PeakSegJoint_interface.c -o PeakSegJoint_interface.o
gcc -shared -L/home/tdhock/lib/R/lib -L/usr/local/lib -o PeakSegJoint.so OptimalPoissonLoss.o PeakSegJoint.o PeakSegJointFaster.o PeakSegJoint_interface.o binSum.o clusterPeaks.o multiClusterPeaks.o profile.o -L/home/tdhock/lib/R/lib -lR
installing to /home/tdhock/lib/R/library/00LOCK-PeakSegJoint/00new/PeakSegJoint/libs
** R
** data
** byte-compile and prepare package for lazy loading
Loading required package: grDevices
** help
*** installing help indices
** building package indices
Loading required package: grDevices
** testing if installed package can be loaded from temporary location
Loading required package: grDevices
** checking absolute paths in shared objects and dynamic libraries
** testing if installed package can be loaded from final location
Loading required package: grDevices
** testing if installed package keeps a record of temporary installation path
* DONE (PeakSegJoint)
```

So the above output does not reproduce the warning I observed on
CRAN. One solution for reproducing that warning would be to install
GCC 12, but I do not want to do that, because I am using Ubuntu 18 LTS
(bionic), which does not provide an easy way to install GCC 12. I
could install GCC 12 by compiling it from source (like I did for GCC
10), but that takes a long time, so a quicker fix is to simply tell my
R/GCC 10 to use this warning, by putting the following in
`~/.R/Makevars`:

```
CFLAGS=-Wstrict-prototypes
```

After that, when re-compiling, I get the same warning as on CRAN:

```
(base) tdhock@maude-MacBookPro:~/R/PeakSegJoint(master*)$ rm -f src/PeakSegJoint_interface.o && R CMD INSTALL .
Loading required package: grDevices
* installing to library ‘/home/tdhock/lib/R/library’
* installing *source* package ‘PeakSegJoint’ ...
** using staged installation
** libs
gcc -I"/home/tdhock/lib/R/include" -DNDEBUG   -I/usr/local/include   -fpic  -Wstrict-prototypes -c PeakSegJoint_interface.c -o PeakSegJoint_interface.o
PeakSegJoint_interface.c:113:6: warning: function declaration isn’t a prototype [-Wstrict-prototypes]
  113 | SEXP allocPeakSegJointModelList(){
      |      ^~~~~~~~~~~~~~~~~~~~~~~~~~
gcc -shared -L/home/tdhock/lib/R/lib -L/usr/local/lib -o PeakSegJoint.so OptimalPoissonLoss.o PeakSegJoint.o PeakSegJointFaster.o PeakSegJoint_interface.o binSum.o clusterPeaks.o multiClusterPeaks.o profile.o -L/home/tdhock/lib/R/lib -lR
installing to /home/tdhock/lib/R/library/00LOCK-PeakSegJoint/00new/PeakSegJoint/libs
** R
** data
** byte-compile and prepare package for lazy loading
Loading required package: grDevices
** help
*** installing help indices
** building package indices
Loading required package: grDevices
** testing if installed package can be loaded from temporary location
Loading required package: grDevices
** checking absolute paths in shared objects and dynamic libraries
** testing if installed package can be loaded from final location
Loading required package: grDevices
** testing if installed package keeps a record of temporary installation path
* DONE (PeakSegJoint)
```

Finally I made the warning go away by [changing](https://github.com/tdhock/PeakSegJoint/commit/276c1b77e2bf965d34e539317c8e0101db117bb9) the code below 

```c
SEXP allocPeakSegJointModelList(){
  return allocVector(VECSXP, 11);
}
```

to the code below (notice the void argument instead of no argument),

```c
SEXP allocPeakSegJointModelList(void){
  return allocVector(VECSXP, 11);
}
```

After that, when re-compiling, the warning goes away,

```
(base) tdhock@maude-MacBookPro:~/R/PeakSegJoint(master*)$ rm -f src/PeakSegJoint_interface.o && R CMD INSTALL .
Loading required package: grDevices
* installing to library ‘/home/tdhock/lib/R/library’
* installing *source* package ‘PeakSegJoint’ ...
** using staged installation
** libs
gcc -I"/home/tdhock/lib/R/include" -DNDEBUG   -I/usr/local/include   -fpic  -Wstrict-prototypes -c PeakSegJoint_interface.c -o PeakSegJoint_interface.o
gcc -shared -L/home/tdhock/lib/R/lib -L/usr/local/lib -o PeakSegJoint.so OptimalPoissonLoss.o PeakSegJoint.o PeakSegJointFaster.o PeakSegJoint_interface.o binSum.o clusterPeaks.o multiClusterPeaks.o profile.o -L/home/tdhock/lib/R/lib -lR
installing to /home/tdhock/lib/R/library/00LOCK-PeakSegJoint/00new/PeakSegJoint/libs
** R
** data
** byte-compile and prepare package for lazy loading
Loading required package: grDevices
** help
*** installing help indices
** building package indices
Loading required package: grDevices
** testing if installed package can be loaded from temporary location
Loading required package: grDevices
** checking absolute paths in shared objects and dynamic libraries
** testing if installed package can be loaded from final location
Loading required package: grDevices
** testing if installed package keeps a record of temporary installation path
* DONE (PeakSegJoint)
```

Conclusion: you can use `~/.R/Makevars` to specify user-specific
compilation flags, which can help to reproduce and fix warnings that
are initially detected on CRAN.

Related: my [Compiling R post from
2017](https://tdhock.github.io/blog/2017/compiling-R/) explains how to
use `~/.R/Makevars` to tell R to look for non-standard directories
during compilation/linking steps.

## R CMD check vs INSTALL

Why is the check output below not consistent with what was shown on
CRAN? 

* Only the INSTALL output shows the warning (not the check output).
* The check output has a NOTE for Compilation used the following
  non-portable flag, so it is using the flag to turn on additional
  warnings, but it does not show "Found the following significant
  warnings" for the check "whether package PeakSegJoint can be
  installed" -- why?

```
(base) tdhock@maude-MacBookPro:~/R$ R CMD check --as-cran PeakSegJoint_2023.4.24.9000.tar.gz 
Loading required package: grDevices
* using log directory ‘/home/tdhock/R/PeakSegJoint.Rcheck’
* using R version 4.2.3 (2023-03-15)
* using platform: x86_64-pc-linux-gnu (64-bit)
* using session charset: UTF-8
* using option ‘--as-cran’
* checking for file ‘PeakSegJoint/DESCRIPTION’ ... OK
* this is package ‘PeakSegJoint’ version ‘2023.4.24’
* checking CRAN incoming feasibility ... Note_to_CRAN_maintainers
Maintainer: ‘Toby Dylan Hocking <toby.hocking@r-project.org>’
* checking package namespace information ... OK
* checking package dependencies ... OK
* checking if this is a source package ... OK
* checking if there is a namespace ... OK
* checking for executable files ... OK
* checking for hidden files and directories ... OK
* checking for portable file names ... OK
* checking for sufficient/correct file permissions ... OK
* checking serialization versions ... OK
* checking whether package ‘PeakSegJoint’ can be installed ... [9s/16s] OK
* checking installed package size ... OK
* checking package directory ... OK
* checking for future file timestamps ... OK
* checking DESCRIPTION meta-information ... OK
* checking top-level files ... OK
* checking for left-over files ... OK
* checking index information ... OK
* checking package subdirectories ... OK
* checking R files for non-ASCII characters ... OK
* checking R files for syntax errors ... OK
* checking whether the package can be loaded ... OK
* checking whether the package can be loaded with stated dependencies ... OK
* checking whether the package can be unloaded cleanly ... OK
* checking whether the namespace can be loaded with stated dependencies ... OK
* checking whether the namespace can be unloaded cleanly ... OK
* checking use of S3 registration ... OK
* checking dependencies in R code ... OK
* checking S3 generic/method consistency ... OK
* checking replacement functions ... OK
* checking foreign function calls ... OK
* checking R code for possible problems ... [11s/11s] OK
* checking Rd files ... OK
* checking Rd metadata ... OK
* checking Rd line widths ... OK
* checking Rd cross-references ... OK
* checking for missing documentation entries ... OK
* checking for code/documentation mismatches ... OK
* checking Rd \usage sections ... OK
* checking Rd contents ... OK
* checking for unstated dependencies in examples ... OK
* checking contents of ‘data’ directory ... OK
* checking data for non-ASCII characters ... OK
* checking data for ASCII and uncompressed saves ... OK
* checking line endings in C/C++/Fortran sources/headers ... OK
* checking pragmas in C/C++ headers and code ... OK
* checking compilation flags used ... NOTE
Compilation used the following non-portable flag(s):
  ‘-Wstrict-prototypes’
* checking compiled code ... OK
* checking examples ... OK
* checking for unstated dependencies in ‘tests’ ... OK
* checking tests ...
  Running ‘testthat.R’ [79s/82s]
 [80s/83s] OK
* checking PDF version of manual ... OK
* skipping checking HTML version of manual: no command ‘tidy’ found
* checking for non-standard things in the check directory ... OK
* checking for detritus in the temp directory ... OK
* DONE

Status: 1 NOTE
See
  ‘/home/tdhock/R/PeakSegJoint.Rcheck/00check.log’
for details.

(base) tdhock@maude-MacBookPro:~/R$ R CMD INSTALL PeakSegJoint_2023.4.24.9000.tar.gz 
Loading required package: grDevices
* installing to library ‘/home/tdhock/lib/R/library’
* installing *source* package ‘PeakSegJoint’ ...
** using staged installation
** libs
gcc -I"/home/tdhock/lib/R/include" -DNDEBUG   -I/usr/local/include   -fpic  -Wstrict-prototypes -c OptimalPoissonLoss.c -o OptimalPoissonLoss.o
gcc -I"/home/tdhock/lib/R/include" -DNDEBUG   -I/usr/local/include   -fpic  -Wstrict-prototypes -c PeakSegJoint.c -o PeakSegJoint.o
gcc -I"/home/tdhock/lib/R/include" -DNDEBUG   -I/usr/local/include   -fpic  -Wstrict-prototypes -c PeakSegJointFaster.c -o PeakSegJointFaster.o
gcc -I"/home/tdhock/lib/R/include" -DNDEBUG   -I/usr/local/include   -fpic  -Wstrict-prototypes -c PeakSegJoint_interface.c -o PeakSegJoint_interface.o
PeakSegJoint_interface.c:113:6: warning: function declaration isn’t a prototype [-Wstrict-prototypes]
  113 | SEXP allocPeakSegJointModelList(){
      |      ^~~~~~~~~~~~~~~~~~~~~~~~~~
gcc -I"/home/tdhock/lib/R/include" -DNDEBUG   -I/usr/local/include   -fpic  -Wstrict-prototypes -c binSum.c -o binSum.o
gcc -I"/home/tdhock/lib/R/include" -DNDEBUG   -I/usr/local/include   -fpic  -Wstrict-prototypes -c clusterPeaks.c -o clusterPeaks.o
gcc -I"/home/tdhock/lib/R/include" -DNDEBUG   -I/usr/local/include   -fpic  -Wstrict-prototypes -c multiClusterPeaks.c -o multiClusterPeaks.o
gcc -I"/home/tdhock/lib/R/include" -DNDEBUG   -I/usr/local/include   -fpic  -Wstrict-prototypes -c profile.c -o profile.o
gcc -shared -L/home/tdhock/lib/R/lib -L/usr/local/lib -o PeakSegJoint.so OptimalPoissonLoss.o PeakSegJoint.o PeakSegJointFaster.o PeakSegJoint_interface.o binSum.o clusterPeaks.o multiClusterPeaks.o profile.o -L/home/tdhock/lib/R/lib -lR
installing to /home/tdhock/lib/R/library/00LOCK-PeakSegJoint/00new/PeakSegJoint/libs
** R
** data
** byte-compile and prepare package for lazy loading
Loading required package: grDevices
** help
*** installing help indices
** building package indices
Loading required package: grDevices
** testing if installed package can be loaded from temporary location
Loading required package: grDevices
** checking absolute paths in shared objects and dynamic libraries
** testing if installed package can be loaded from final location
Loading required package: grDevices
** testing if installed package keeps a record of temporary installation path
* DONE (PeakSegJoint)
```
