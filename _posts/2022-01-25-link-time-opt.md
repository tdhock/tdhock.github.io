---
layout: post
title: Link-time optimization
description: Fixing warnings from CRAN checks
---

Last week I submitted my R package
[plotHMM](https://github.com/tdhock/plotHMM) to CRAN for the first
time. It was accepted but then a few days later I got an email from
Brian Ripley explaining that there are compilation warnings that need
to be fixed,

```
* installing *source* package ‘plotHMM’ ...
** package ‘plotHMM’ successfully unpacked and MD5 sums checked
** using staged installation
** libs
make[2]: Entering directory '/data/gannet/ripley/R/packages/tests-LTO/plotHMM/src'
g++ -std=gnu++14 -shared -L/usr/local/lib64 -o plotHMM.so RcppExports.o backward.o eln.o forward.o interface.o multiply.o pairwise.o transition.o viterbi.o
/data/gannet/ripley/R/test-4.2/RcppArmadillo/include/armadillo_bits/glue_solve_bones.hpp:84:10: warning: type ‘struct opts’ violates the C++ One Definition Rule [-Wodr]
   84 |   struct opts
      |          ^
/data/gannet/ripley/R/test-4.2/RcppArmadillo/include/armadillo_bits/glue_solve_bones.hpp:84:10: note: a different type is defined in another translation unit
   84 |   struct opts
      |          ^
/data/gannet/ripley/R/test-4.2/RcppArmadillo/include/armadillo_bits/glue_solve_bones.hpp:86:17: note: the first difference of corresponding definitions is field ‘flags’
   86 |     const uword flags;
      |                 ^
/data/gannet/ripley/R/test-4.2/RcppArmadillo/include/armadillo_bits/glue_solve_bones.hpp:86:17: note: a field of same name but different type is defined in another translation unit
   86 |     const uword flags;
      |                 ^
/data/gannet/ripley/R/test-4.2/RcppArmadillo/include/armadillo_bits/glue_solve_bones.hpp:124:10: warning: type ‘struct opts_none’ violates the C++ One Definition Rule [-Wodr]
  124 |   struct opts_none         : public opts { inline opts_none()         : opts(flag_none        ) {} };
      |          ^
/data/gannet/ripley/R/test-4.2/RcppArmadillo/include/armadillo_bits/glue_solve_bones.hpp:124:10: note: a type with different bases is defined in another translation unit
  124 |   struct opts_none         : public opts { inline opts_none()         : opts(flag_none        ) {} };
      |          ^
/data/gannet/ripley/R/test-4.2/RcppArmadillo/include/armadillo_bits/glue_solve_bones.hpp:125:10: warning: type ‘struct opts_fast’ violates the C++ One Definition Rule [-Wodr]
  125 |   struct opts_fast         : public opts { inline opts_fast()         : opts(flag_fast        ) {} };
      |          ^
/data/gannet/ripley/R/test-4.2/RcppArmadillo/include/armadillo_bits/glue_solve_bones.hpp:125:10: note: a type with different bases is defined in another translation unit
  125 |   struct opts_fast         : public opts { inline opts_fast()         : opts(flag_fast        ) {} };
      |          ^
```

To fix, the first thing to do is try to reproduce the warning on my
own computer (then later we can try to make it go away). 

Apparently, the `-Wodr` flag was introduced in
[gcc-5](https://gcc.gnu.org/gcc-5/changes.html): A new One Definition
Rule violation warning (controlled by -Wodr) detects mismatches in
type definitions and virtual table contents during link-time
optimization.

But when I ran R CMD INSTALL with gcc 7, I did not observe those
warnings at first. So I went back to [Brian's description of the
required
toolchain](https://www.stats.ox.ac.uk/pub/bdr/LTO/README.txt):

```
Compilation logs for CRAN packages using x86_64 Fedora 32 Linux 
(currently using GCC 10.1) built with configure --enable-lto and config.site:

CFLAGS="-g -O2 -Wall -pedantic -mtune=native"
FFLAGS="-g -O2 -mtune=native -Wall -pedantic"
CXXFLAGS="-g -O2 -Wall -pedantic -mtune=native -Wno-ignored-attributes -Wno-deprecated-declarations -Wno-parentheses"
AR=gcc-ar
RANLIB=gcc-ranlib

Look for [-Wlto-type-mismatch] warnings.  In some cases these involve
Fortran CHARACTER arguments where the length is passed as a 'hidden'
argument at the end, giving mismatches such as

sblas.f:3951:14: note: type ‘long int’ should match type ‘void’

To work around these, define USE_FC_LEN_T and include Rconfig.h
(perhaps via R.h) before including BLAS.h or Lapack.h or your own
C proptypes for Fortran functions.  Then amend the actual calls to include
character length arguments: see the example of src/library/stats/src/rWishart.c
in the R sources.
```

The instructions seem to indicate that gcc-10 is required, so I
downloaded gcc-10 source code to my home directory and built it using
the standard configure --prefix=$HOME && make && make install. Then I
re-built R-4.1.2 from source using the following config.site:

```sh
RANLIB=gcc-ranlib 
AR=gcc-ar 
CXXFLAGS="-g -O2 -Wall -pedantic -mtune=native -Wno-ignored-attributes -Wno-deprecated-declarations -Wno-parentheses" 
FFLAGS="-g -O2 -mtune=native -Wall -pedantic" 
CFLAGS="-g -O2 -Wall -pedantic -mtune=native"
LDFLAGS="-L$HOME/lib64"
```

Note the LDFLAGS at the end was required to avoid the following error:

```
./configure --prefix=$HOME --enable-lto
...
checking whether mixed C/Fortran code can be run... configure: WARNING: cannot run mixed C/Fortran code
configure: error: Maybe check LDFLAGS for paths to Fortran libraries?
```

So with that setup (GCC-10) I was able to reproduce the warning:

```
(base) tdhock@maude-MacBookPro:~/R$ R CMD INSTALL plotHMM
Loading required package: grDevices
* installing to library ‘/home/tdhock/lib/R/library’
* installing *source* package ‘plotHMM’ ...
** using staged installation
** libs
g++ -std=gnu++14 -I"/home/tdhock/lib/R/include" -DNDEBUG  -I'/home/tdhock/lib/R/library/Rcpp/include' -I'/home/tdhock/lib/R/library/RcppArmadillo/include' -I/usr/local/include   -fpic  -g -O2 -Wall -pedantic -mtune=native -Wno-ignored-attributes -Wno-deprecated-declarations -Wno-parentheses -flto -c RcppExports.cpp -o RcppExports.o
g++ -std=gnu++14 -I"/home/tdhock/lib/R/include" -DNDEBUG  -I'/home/tdhock/lib/R/library/Rcpp/include' -I'/home/tdhock/lib/R/library/RcppArmadillo/include' -I/usr/local/include   -fpic  -g -O2 -Wall -pedantic -mtune=native -Wno-ignored-attributes -Wno-deprecated-declarations -Wno-parentheses -flto -c backward.cpp -o backward.o
g++ -std=gnu++14 -I"/home/tdhock/lib/R/include" -DNDEBUG  -I'/home/tdhock/lib/R/library/Rcpp/include' -I'/home/tdhock/lib/R/library/RcppArmadillo/include' -I/usr/local/include   -fpic  -g -O2 -Wall -pedantic -mtune=native -Wno-ignored-attributes -Wno-deprecated-declarations -Wno-parentheses -flto -c eln.cpp -o eln.o
g++ -std=gnu++14 -I"/home/tdhock/lib/R/include" -DNDEBUG  -I'/home/tdhock/lib/R/library/Rcpp/include' -I'/home/tdhock/lib/R/library/RcppArmadillo/include' -I/usr/local/include   -fpic  -g -O2 -Wall -pedantic -mtune=native -Wno-ignored-attributes -Wno-deprecated-declarations -Wno-parentheses -flto -c forward.cpp -o forward.o
g++ -std=gnu++14 -I"/home/tdhock/lib/R/include" -DNDEBUG  -I'/home/tdhock/lib/R/library/Rcpp/include' -I'/home/tdhock/lib/R/library/RcppArmadillo/include' -I/usr/local/include   -fpic  -g -O2 -Wall -pedantic -mtune=native -Wno-ignored-attributes -Wno-deprecated-declarations -Wno-parentheses -flto -c interface.cpp -o interface.o
g++ -std=gnu++14 -I"/home/tdhock/lib/R/include" -DNDEBUG  -I'/home/tdhock/lib/R/library/Rcpp/include' -I'/home/tdhock/lib/R/library/RcppArmadillo/include' -I/usr/local/include   -fpic  -g -O2 -Wall -pedantic -mtune=native -Wno-ignored-attributes -Wno-deprecated-declarations -Wno-parentheses -flto -c multiply.cpp -o multiply.o
g++ -std=gnu++14 -I"/home/tdhock/lib/R/include" -DNDEBUG  -I'/home/tdhock/lib/R/library/Rcpp/include' -I'/home/tdhock/lib/R/library/RcppArmadillo/include' -I/usr/local/include   -fpic  -g -O2 -Wall -pedantic -mtune=native -Wno-ignored-attributes -Wno-deprecated-declarations -Wno-parentheses -flto -c pairwise.cpp -o pairwise.o
g++ -std=gnu++14 -I"/home/tdhock/lib/R/include" -DNDEBUG  -I'/home/tdhock/lib/R/library/Rcpp/include' -I'/home/tdhock/lib/R/library/RcppArmadillo/include' -I/usr/local/include   -fpic  -g -O2 -Wall -pedantic -mtune=native -Wno-ignored-attributes -Wno-deprecated-declarations -Wno-parentheses -flto -c transition.cpp -o transition.o
g++ -std=gnu++14 -I"/home/tdhock/lib/R/include" -DNDEBUG  -I'/home/tdhock/lib/R/library/Rcpp/include' -I'/home/tdhock/lib/R/library/RcppArmadillo/include' -I/usr/local/include   -fpic  -g -O2 -Wall -pedantic -mtune=native -Wno-ignored-attributes -Wno-deprecated-declarations -Wno-parentheses -flto -c viterbi.cpp -o viterbi.o
g++ -std=gnu++14 -shared -g -O2 -Wall -pedantic -mtune=native -Wno-ignored-attributes -Wno-deprecated-declarations -Wno-parentheses -flto -fpic -L/home/tdhock/lib/R/lib -L/home/tdhock/lib64 -o plotHMM.so RcppExports.o backward.o eln.o forward.o interface.o multiply.o pairwise.o transition.o viterbi.o -L/home/tdhock/lib/R/lib -lR
/home/tdhock/lib/R/library/RcppArmadillo/include/armadillo_bits/glue_solve_bones.hpp:82:10: warning: type ‘struct opts’ violates the C++ One Definition Rule [-Wodr]
   82 |   struct opts
      |          ^
...
installing to /home/tdhock/lib/R/library/00LOCK-plotHMM/00new/plotHMM/libs
** R
** data
** byte-compile and prepare package for lazy loading
Loading required package: grDevices
** help
*** installing help indices
** building package indices
Loading required package: grDevices
** installing vignettes
** testing if installed package can be loaded from temporary location
Loading required package: grDevices
** checking absolute paths in shared objects and dynamic libraries
** testing if installed package can be loaded from final location
Loading required package: grDevices
** testing if installed package keeps a record of temporary installation path
* DONE (plotHMM)
```

Last week I added some `#define ARMA_DONT_PRINT_ERRORS` so I tried
commenting that but the warning did not go away.

I asked on rcpp-devel and Dirk suggested to use `#include <RcppArmadillo.h>` instead of `#include <armadillo>` -- that works to suppress those warnings:

```
(base) tdhock@maude-MacBookPro:~/R$ R CMD INSTALL plotHMM
Loading required package: grDevices
* installing to library ‘/home/tdhock/lib/R/library’
* installing *source* package ‘plotHMM’ ...
** using staged installation
** libs
g++ -std=gnu++14 -I"/home/tdhock/lib/R/include" -DNDEBUG  -I'/home/tdhock/lib/R/library/Rcpp/include' -I'/home/tdhock/lib/R/library/RcppArmadillo/include' -I/usr/local/include   -fpic  -g -O2 -Wall -pedantic -mtune=native -Wno-ignored-attributes -Wno-deprecated-declarations -Wno-parentheses -flto -c backward.cpp -o backward.o
g++ -std=gnu++14 -I"/home/tdhock/lib/R/include" -DNDEBUG  -I'/home/tdhock/lib/R/library/Rcpp/include' -I'/home/tdhock/lib/R/library/RcppArmadillo/include' -I/usr/local/include   -fpic  -g -O2 -Wall -pedantic -mtune=native -Wno-ignored-attributes -Wno-deprecated-declarations -Wno-parentheses -flto -c forward.cpp -o forward.o
g++ -std=gnu++14 -I"/home/tdhock/lib/R/include" -DNDEBUG  -I'/home/tdhock/lib/R/library/Rcpp/include' -I'/home/tdhock/lib/R/library/RcppArmadillo/include' -I/usr/local/include   -fpic  -g -O2 -Wall -pedantic -mtune=native -Wno-ignored-attributes -Wno-deprecated-declarations -Wno-parentheses -flto -c multiply.cpp -o multiply.o
g++ -std=gnu++14 -I"/home/tdhock/lib/R/include" -DNDEBUG  -I'/home/tdhock/lib/R/library/Rcpp/include' -I'/home/tdhock/lib/R/library/RcppArmadillo/include' -I/usr/local/include   -fpic  -g -O2 -Wall -pedantic -mtune=native -Wno-ignored-attributes -Wno-deprecated-declarations -Wno-parentheses -flto -c pairwise.cpp -o pairwise.o
g++ -std=gnu++14 -I"/home/tdhock/lib/R/include" -DNDEBUG  -I'/home/tdhock/lib/R/library/Rcpp/include' -I'/home/tdhock/lib/R/library/RcppArmadillo/include' -I/usr/local/include   -fpic  -g -O2 -Wall -pedantic -mtune=native -Wno-ignored-attributes -Wno-deprecated-declarations -Wno-parentheses -flto -c transition.cpp -o transition.o
g++ -std=gnu++14 -I"/home/tdhock/lib/R/include" -DNDEBUG  -I'/home/tdhock/lib/R/library/Rcpp/include' -I'/home/tdhock/lib/R/library/RcppArmadillo/include' -I/usr/local/include   -fpic  -g -O2 -Wall -pedantic -mtune=native -Wno-ignored-attributes -Wno-deprecated-declarations -Wno-parentheses -flto -c viterbi.cpp -o viterbi.o
g++ -std=gnu++14 -shared -g -O2 -Wall -pedantic -mtune=native -Wno-ignored-attributes -Wno-deprecated-declarations -Wno-parentheses -flto -fpic -L/home/tdhock/lib/R/lib -L/home/tdhock/lib64 -o plotHMM.so RcppExports.o backward.o eln.o forward.o interface.o multiply.o pairwise.o transition.o viterbi.o -L/home/tdhock/lib/R/lib -lR
installing to /home/tdhock/lib/R/library/00LOCK-plotHMM/00new/plotHMM/libs
** R
** data
** byte-compile and prepare package for lazy loading
Loading required package: grDevices
** help
*** installing help indices
** building package indices
Loading required package: grDevices
** installing vignettes
** testing if installed package can be loaded from temporary location
Loading required package: grDevices
** checking absolute paths in shared objects and dynamic libraries
** testing if installed package can be loaded from final location
Loading required package: grDevices
** testing if installed package keeps a record of temporary installation path
* DONE (plotHMM)
```

UPDATE: Actually I was able to reproduce the warning using GCC-7 as
well (see below). I'm not sure why I did not get that initially.

```
(base) tdhock@maude-MacBookPro:~/R/plotHMM/src(main)$ g++-7 -std=gnu++14 -shared -g -O2 -Wall -pedantic -mtune=native -Wno-ignored-attributes -Wno-deprecated-declarations -Wno-parentheses -flto -fpic -L/home/tdhock/lib/R/lib -L/home/tdhock/lib64 -o plotHMM.so RcppExports.o backward.o eln.o forward.o interface.o multiply.o pairwise.o transition.o viterbi.o -L/home/tdhock/lib/R/lib -lR
/home/tdhock/lib/R/library/RcppArmadillo/include/armadillo_bits/glue_solve_bones.hpp:82:10: warning: type ‘struct opts’ violates the C++ One Definition Rule [-Wodr]
   struct opts
          ^
...
```

