---
layout: post
title: Embedding R 
description: Compiling a program that links to R
---

As a part of the RcppDeepState project we are creating an easy way to
use [DeepState](https://github.com/trailofbits/deepstate) to fuzz test
R packages with C++ code defined using
[Rcpp](http://www.rcpp.org/). DeepState requires the C++ programmer to
define a "test harness" which is C++ source code without a main
function, but with tests/expectations. The DeepState framework then
compiles that test harness to an executable (with a main function) to
which fuzz testing libraries can send input.

Usually R runs as main, so we need to instead compile another program
and link it to the R shared library, [as documented in Writing R
Extensions, section Embedding R under
Unix-alikes](https://cloud.r-project.org/doc/manuals/r-release/R-exts.html#Embedding-R-under-Unix_002dalikes).

So I downloaded the R source code,
[R-3.6.3.tar.gz](https://cloud.r-project.org/src/base/R-3/R-3.6.3.tar.gz),
and I looked for examples in the
[R-3.6.3/tests/Embedding](https://github.com/wch/r-source/tree/trunk/tests/Embedding)
directory:

```
tdhock@maude-MacBookPro:~/R/R-3.6.3/tests/Embedding$ ls *.c
embeddedRCall.c  Rerror.c      Rpackage.c    Rplot.c        Rshutdown.c  tryEval.c
Rcpp.c           RNamedCall.c  RParseEval.c  Rpostscript.c  Rtest.c
tdhock@maude-MacBookPro:~/R/R-3.6.3/tests/Embedding$ 
```

There is also a Makefile that can be used to compile the simplest test program:

```
tdhock@maude-MacBookPro:~/R/R-3.6.3/tests/Embedding$ rm -f Rtest *.o && make Rtest 
gcc -I"../../include" -DNDEBUG   -I/usr/local/include  -fpic  -g -O2  -c Rtest.c -o Rtest.o
gcc -I"../../include" -DNDEBUG   -I/usr/local/include  -fpic  -g -O2  -c embeddedRCall.c -o embeddedRCall.o
../../bin/R CMD gcc -Wl,--export-dynamic -fopenmp -L/usr/local/lib -o Rtest Rtest.o embeddedRCall.o -L"../../lib" -lR
```

However when I ran that program as usual it seems there is some problem with the environment:

```
tdhock@maude-MacBookPro:~/R/R-3.6.3/tests/Embedding$ ./Rtest 
Fatal error: R home directory is not defined
```

The error message suggests that the problem may be fixed by setting R_HOME, but:

```
tdhock@maude-MacBookPro:~/R/R-3.6.3/tests/Embedding$ R_HOME=~/lib/R ./Rtest 
Error in readRDS(mapfile) : 
  cannot read workspace version 3 written by R 3.6.3; need R 3.5.0 or newer
Error in attach(NULL, name = "Autoloads") : 
  could not find function "attach"

R version 3.4.4 (2018-03-15) -- "Someone to Lean On"
Copyright (C) 2018 The R Foundation for Statistical Computing
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

Error in options(repos = "http://cloud.r-project.org") : 
  could not find function "options"
Error: object '.ArgsEnv' not found
Fatal error: unable to initialize the JIT

tdhock@maude-MacBookPro:~/R/R-3.6.3/tests/Embedding$ 
```

There still seems to be some problem above. It is definitely a problem
with the environment, because running it via the code below (as found
in the Makefile) works fine:

```
tdhock@maude-MacBookPro:~/R/R-3.6.3/tests/Embedding$ R CMD ./Rtest

R version 3.6.3 (2020-02-29) -- "Holding the Windsock"
Copyright (C) 2020 The R Foundation for Statistical Computing
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

Loading required package: grDevices
 [1]  1  2  3  4  5  6  7  8  9 10
tdhock@maude-MacBookPro:~/R/R-3.6.3/tests/Embedding$ 
```

Looking at the ldd output below, it is clear that the problem is that
the system/ubuntu/apt R is being used, rather than the more recent
R-3.6.3,

```
tdhock@maude-MacBookPro:~/R/R-3.6.3/tests/Embedding$ ldd Rtest|grep libR
	libR.so => /usr/lib/libR.so (0x00007fca1e951000)
tdhock@maude-MacBookPro:~/R/R-3.6.3/tests/Embedding$
```

So I wrote my own Makefile (code below). First I start by defining
some paths/flags to tell the compiler/linker where to find my R (under my
home directory).

```
R_HOME=${HOME}/lib/R
R_LIB=${R_HOME}/lib
R_INCLUDE=${R_HOME}/include
CPPFLAGS=-I${R_INCLUDE}
```

After that, the key to getting it to work is to specify the
non-standard library directory using two command line arguments, [as
explained in a previous blog
post](https://tdhock.github.io/blog/2017/compiling-R/).

```
# R_LIB must be specified both using -L and via -Wl,-rpath=
Rtest: Rtest.o embeddedRCall.o
	gcc -o Rtest Rtest.o embeddedRCall.o -L${R_LIB} -Wl,-rpath=${R_LIB} -lR
	R_HOME=${R_HOME} ./Rtest
```

Finally the recipes below compile the two C source code files to
object files.

```
# -c option means to not link.
Rtest.o: Rtest.c
	gcc ${CPPFLAGS} Rtest.c -o Rtest.o -c
embeddedRCall.o: embeddedRCall.c
	gcc ${CPPFLAGS} embeddedRCall.c -o embeddedRCall.o -c
```

I saved this code to Makefile.mine and I get the following output when running it:

```
tdhock@maude-MacBookPro:~/R/R-3.6.3/tests/Embedding$ rm -f *.o Rtest && make -f Makefile.mine 
gcc -I/home/tdhock/lib/R/include Rtest.c -o Rtest.o -c
gcc -I/home/tdhock/lib/R/include embeddedRCall.c -o embeddedRCall.o -c
gcc -o Rtest Rtest.o embeddedRCall.o -L/home/tdhock/lib/R/lib -Wl,-rpath=/home/tdhock/lib/R/lib -lR
R_HOME=/home/tdhock/lib/R ./Rtest

R version 3.6.3 (2020-02-29) -- "Holding the Windsock"
Copyright (C) 2020 The R Foundation for Statistical Computing
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

Loading required package: grDevices
 [1]  1  2  3  4  5  6  7  8  9 10
tdhock@maude-MacBookPro:~/R/R-3.6.3/tests/Embedding$ 
```

Note that the `R_HOME` environment variable must be specified, as in
the code above. If not, we get an error, as in the code below:

```
tdhock@maude-MacBookPro:~/R/R-3.6.3/tests/Embedding$ ./Rtest 
Fatal error: R home directory is not defined
tdhock@maude-MacBookPro:~/R/R-3.6.3/tests/Embedding$ 
```

The next step will be to compile a non-trivial program that links to
package code using Rcpp.
