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
