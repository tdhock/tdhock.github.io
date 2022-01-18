---
layout: post
title: Finding symbols in object files
description: Using objdump to find cerr
---

Today I submitted my R package
[plotHMM](https://github.com/tdhock/plotHMM) to
[win-builder](https://win-builder.r-project.org/) for the first time.
It came back with the following message,

```
* checking compiled code ... NOTE
File 'plotHMM/libs/x64/plotHMM.dll':
  Found '_ZSt4cerr', possibly from 'std::cerr' (C++)
    Objects: 'backward.o', 'forward.o', 'multiply.o', 'pairwise.o',
      'transition.o', 'viterbi.o'

Compiled code should not call entry points which might terminate R nor
write to stdout/stderr instead of to the console, nor use Fortran I/O
nor system RNGs.

See 'Writing portable packages' in the 'Writing R Extensions' manual.
```

It is best to avoid NOTEs whenever possible, because they require
manual review by a CRAN maintainer (no NOTEs means updates are
automatically published without manual review). 

The NOTE says that there are object files which are using the C++
standard error stream, which is not allowed in R. At first glance I
thought that was strange, as I had not used the standard error stream
myself. In fact the first few lines of those files look like,

```c++
#include <armadillo>
#include <math.h>//for INFINITY, 
#include "eln.h"
```

I suspected that the problem may be in armadillo. To see if cerr
appears after pre-processing, I used `g++ -E code.cpp | grep cerr`,

```
$ "C:/rtools40/mingw64/bin/"g++ -std=gnu++11 -I"C:/PROGRA~1/R/R-41~1.1/include" -DNDEBUG  -I'C:/Users/th798/R/win-library/4.1/Rcpp/include' -I'C:/Users/th798/R/win-library/4.1/RcppArmadillo/include' -O2 -Wall -mfpmath=sse -msse2 -mstackrealign -E pairwise.cpp | grep 'std::cerr'
using std::cerr;
  static std::ostream* cerr_stream = &(std::cerr);
```

So then I started looking at the armadillo docs, and [the logging
section](http://arma.sourceforge.net/docs.html#logging) says that "a
blunt method to disable printing of all warnings and errors is via
placing `#define ARMA_DONT_PRINT_ERRORS` before `#include <armadillo>`". 
Before doing that I verified that cerr is found in the
compiled object file, by using `objdump -t` to list all symbols,

```shell-script
$ c:/rtools40/mingw64/bin/objdump.exe -t plotHMM/src/backward.o |grep cerr
[  6](sec 22)(fl 0x00)(ty   0)(scl   3) (nx 1) 0x0000000000000000 .data$_ZZN4arma16arma_cerr_streamIcEERSoPSoE11cerr_stream
[ 56](sec 22)(fl 0x00)(ty   0)(scl   2) (nx 0) 0x0000000000000000 _ZZN4arma16arma_cerr_streamIcEERSoPSoE11cerr_stream
[ 69](sec  0)(fl 0x00)(ty   0)(scl   2) (nx 0) 0x0000000000000000 _ZSt4cerr
```

Then I updated the src/*.cpp files to have the following at the top,

```c++
#define ARMA_DONT_PRINT_ERRORS
#include <armadillo>
```

After making that change and re-compiling I observed no mention of `_ZSt4cerr`,

```shell-script
$ c:/rtools40/mingw64/bin/objdump.exe -t plotHMM/src/backward.o |grep cerr
```

Finally I then re-submitted to win-builder and observed that NOTE disappear.
