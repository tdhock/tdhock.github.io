---
layout: post
title: binsegRcpp inside a C++ program
description: Embedding Rcpp code into a main function
---

As a part of the RcppDeepState project we are creating an easy way to
use [DeepState](https://github.com/trailofbits/deepstate) to fuzz test
R packages with C++ code defined using
[Rcpp](http://www.rcpp.org/). DeepState requires the C++ programmer to
define a "test harness" which is C++ source code without a main
function, but with tests/expectations. The DeepState framework then
compiles that test harness to an executable (with a main function) to
which fuzz testing libraries can send input.

Usually R runs as main, so for RcppDeepState we need to instead
compile another program and link it to the R shared library. In [the
previous blog post](https://tdhock.github.io/blog/2020/embedded-R/) I
showed how to do this using the C interface provided with the R source
code. In this blog post I investigate how to go one step further with
[RInside](https://github.com/eddelbuettel/rinside). The goal will to
compile and run a simple C++ program with a main function that calls
one of the C++ functions from the
[binsegRcpp](https://github.com/tdhock/binsegRcpp) package.

The first thing to do is download the R source code,
[R-3.6.3.tar.gz](https://cloud.r-project.org/src/base/R-3/R-3.6.3.tar.gz),
which I saved to `~/R` and then I compiled it using the standard
commands:

```
cd ~/R
wget https://cloud.r-project.org/src/base/R-3/R-3.6.3.tar.gz
tar xf R-3.6.3.tar.gz
./configure --prefix=$HOME --enable-R-shlib
make
make install
```

Note in the above I used `--prefix=$HOME` to install R under my home
directory, and I used `--enable-R-shlib` to get `~/lib/R/lib/libR.so`
which is the shared object file for R (necessary for embedding R into
other programs). The next step is to download and install RInside,

```
> install.packages("RInside")
trying URL 'http://cloud.r-project.org/src/contrib/RInside_0.2.16.tar.gz'
Content type 'application/x-gzip' length 80576 bytes (78 KB)
==================================================
downloaded 78 KB

Loading required package: grDevices
* installing *source* package ‘RInside’ ...
** package ‘RInside’ successfully unpacked and MD5 sums checked
** using staged installation
** libs
/home/tdhock/lib/R/bin/Rscript tools/RInsideAutoloads.r > RInsideAutoloads.h
Loading required package: grDevices
/home/tdhock/lib/R/bin/Rscript tools/RInsideEnvVars.r   > RInsideEnvVars.h
Loading required package: grDevices
g++ -std=gnu++11 -I"/home/tdhock/lib/R/include" -DNDEBUG -I. -I../inst/include/ -I"/home/tdhock/lib/R/library/Rcpp/include" -I/usr/local/include  -fpic  -g -O2  -c MemBuf.cpp -o MemBuf.o
g++ -std=gnu++11 -I"/home/tdhock/lib/R/include" -DNDEBUG -I. -I../inst/include/ -I"/home/tdhock/lib/R/library/Rcpp/include" -I/usr/local/include  -fpic  -g -O2  -c RInside.cpp -o RInside.o
g++ -std=gnu++11 -I"/home/tdhock/lib/R/include" -DNDEBUG -I. -I../inst/include/ -I"/home/tdhock/lib/R/library/Rcpp/include" -I/usr/local/include  -fpic  -g -O2  -c RInside_C.cpp -o RInside_C.o
g++ -std=gnu++11 -I"/home/tdhock/lib/R/include" -DNDEBUG -I. -I../inst/include/ -I"/home/tdhock/lib/R/library/Rcpp/include" -I/usr/local/include  -fpic  -g -O2  -c RcppExports.cpp -o RcppExports.o
g++ -std=gnu++11 -I"/home/tdhock/lib/R/include" -DNDEBUG -I. -I../inst/include/ -I"/home/tdhock/lib/R/library/Rcpp/include" -I/usr/local/include  -fpic  -g -O2  -c compiler.cpp -o compiler.o
g++ -std=gnu++11 -shared -L/home/tdhock/lib/R/lib -L/usr/local/lib -o RInside.so MemBuf.o RInside.o RInside_C.o RcppExports.o compiler.o -L/home/tdhock/lib/R/lib -lR
g++ -std=gnu++11 -o libRInside.so MemBuf.o RInside.o RInside_C.o RcppExports.o compiler.o -shared -L/usr/local/lib   -L"/home/tdhock/lib/R/lib" -lR
ar qc libRInside.a MemBuf.o RInside.o RInside_C.o RcppExports.o compiler.o
cp libRInside.so ../inst/lib
cp libRInside.a ../inst/lib
rm libRInside.so libRInside.a
installing to /home/tdhock/lib/R/library/00LOCK-RInside/00new/RInside/libs
** R
** inst
** byte-compile and prepare package for lazy loading
Loading required package: grDevices
** help
*** installing help indices
** building package indices
** testing if installed package can be loaded from temporary location
Loading required package: grDevices
** checking absolute paths in shared objects and dynamic libraries
** testing if installed package can be loaded from final location
Loading required package: grDevices
** testing if installed package keeps a record of temporary installation path
* DONE (RInside)

The downloaded source packages are in
	‘/tmp/Rtmp4Tx4Nx/downloaded_packages’
Updating HTML index of packages in '.Library'
Making 'packages.html' ... done
> 
```

Then in the small C++ program below (saved in a file called
binsegRcppInside.cpp) I define a main function that calls
`rcpp_binseg_normal`, which is a function defined in [the C++ code of
the binsegRcpp R
package](https://github.com/tdhock/binsegRcpp/blob/master/src/rcpp_interface.cpp).

```
#include <RInside.h>
#include <iostream>

Rcpp::List rcpp_binseg_normal(const Rcpp::NumericVector data_vec, const Rcpp::IntegerVector max_segments);

void run_tests(Rcpp::List result, int n_data){
  // test 1: loss values must be decreasing.
  Rcpp::NumericVector loss = result["loss"];
  std::cout << loss << " loss\n";
  for(int i=1; i<n_data; i++){
    if(loss[i-1] < loss[i]){
      std::cout << "TEST FAILURE: loss increasing!\n";
    }
  }
  // test 2: vector of segment ends should start with n, n/2 when data
  // are 0, 1, ..., N
  Rcpp::IntegerVector end = result["end"];
  std::cout << end << " segment ends\n";
  if(end[0]+1 != n_data){
    std::cout << "TEST FAILURE: first end should be last data point!\n";
  }
  if(end[1]+1 != n_data/2){
    std::cout << "TEST FAILURE: second end should be middle data point!\n";
  }
}

int main(int argc, char *argv[]){
  RInside R(argc, argv);
  // Create a sample data set to pass to the binary segmentation
  // algorithm: 0, 1, ..., n_data.
  int n_data = 4;
  Rcpp::NumericVector data_vec(n_data);
  for(int i=0; i<n_data; i++){
    data_vec[i] = i;
  }
  // Set max segments to the number of data points.
  Rcpp::IntegerVector max_segments(1);
  max_segments[0] = n_data;
  // Run and test binary segmentation algorithm.
  Rcpp::List result = rcpp_binseg_normal(data_vec, max_segments);
  run_tests(result, n_data);
}
```

In the code above the main function begins by creating an instance of
the RInside class, which initializes the embedded R interpreter. That
is provided by the `#include <RInside>` which also includes functions
from the Rcpp namespace. The next part of the code creates a synthetic
`data_vec` which is a `NumericVector` of size `n_data=4`, and
initializes `max_segments` as an `IntegerVector` of length 1 with
value same as `n_data`. Finally we run the `rcpp_binseg_normal`
function and then call `run_tests` which prints and checks the
results. To get that code to compile we first need to get a copy of
binsegRcpp, using the shell commands:

```
cd ~/R
git clone https://github.com/tdhock/binsegRcpp.git
R CMD INSTALL binsegRcpp
```

which gives me the output:

```
tdhock@maude-MacBookPro:~/R$ git clone https://github.com/tdhock/binsegRcpp.git
Cloning into 'binsegRcpp'...
remote: Enumerating objects: 56, done.        
remote: Counting objects: 100% (56/56), done.        
remote: Compressing objects: 100% (31/31), done.        
remote: Total 56 (delta 25), reused 50 (delta 19), pack-reused 0        
Unpacking objects: 100% (56/56), done.
tdhock@maude-MacBookPro:~/R$ R CMD INSTALL binsegRcpp
Loading required package: grDevices
* installing to library ‘/home/tdhock/lib/R/library’
* installing *source* package ‘binsegRcpp’ ...
** using staged installation
** libs
g++ -std=gnu++11 -I"/home/tdhock/lib/R/include" -DNDEBUG  -I"/home/tdhock/lib/R/library/Rcpp/include" -I/usr/local/include  -fpic  -g -O2  -c RcppExports.cpp -o RcppExports.o
g++ -std=gnu++11 -I"/home/tdhock/lib/R/include" -DNDEBUG  -I"/home/tdhock/lib/R/library/Rcpp/include" -I/usr/local/include  -fpic  -g -O2  -c binseg_normal.cpp -o binseg_normal.o
g++ -std=gnu++11 -I"/home/tdhock/lib/R/include" -DNDEBUG  -I"/home/tdhock/lib/R/library/Rcpp/include" -I/usr/local/include  -fpic  -g -O2  -c binseg_normal_cost.cpp -o binseg_normal_cost.o
g++ -std=gnu++11 -I"/home/tdhock/lib/R/include" -DNDEBUG  -I"/home/tdhock/lib/R/library/Rcpp/include" -I/usr/local/include  -fpic  -g -O2  -c rcpp_interface.cpp -o rcpp_interface.o
g++ -std=gnu++11 -shared -L/home/tdhock/lib/R/lib -L/usr/local/lib -o binsegRcpp.so RcppExports.o binseg_normal.o binseg_normal_cost.o rcpp_interface.o -L/home/tdhock/lib/R/lib -lR
installing to /home/tdhock/lib/R/library/00LOCK-binsegRcpp/00new/binsegRcpp/libs
** R
** byte-compile and prepare package for lazy loading
Loading required package: grDevices
** help
*** installing help indices
** building package indices
** testing if installed package can be loaded from temporary location
Loading required package: grDevices
** checking absolute paths in shared objects and dynamic libraries
** testing if installed package can be loaded from final location
Loading required package: grDevices
** testing if installed package keeps a record of temporary installation path
* DONE (binsegRcpp)
tdhock@maude-MacBookPro:~/R$ 
```

After having done that installation, the `binsegRcpp/src` directory
now has compiled object files, which we can use to get the compilation to work:

```
tdhock@maude-MacBookPro:~/R$ ls binsegRcpp/src/
binseg_normal_cost.cpp  binseg_normal_cost.o  binseg_normal.h  binsegRcpp.so    RcppExports.o       rcpp_interface.o
binseg_normal_cost.h    binseg_normal.cpp     binseg_normal.o  RcppExports.cpp  rcpp_interface.cpp
tdhock@maude-MacBookPro:~/R$ 
```

My Makefile for compiling binsegRcppInside.cpp looks like

```
R_HOME=/home/tdhock/lib/R
COMMON_FLAGS=binsegRcppInside.o -L${R_HOME}/library/RInside/lib -Wl,-rpath=${R_HOME}/library/RInside/lib -L${R_HOME}/lib -Wl,-rpath=${R_HOME}/lib -lR -lRInside
binsegRcppInside: binsegRcppInside.o
	g++ -o binsegRcppInside ${COMMON_FLAGS} /home/tdhock/R/binsegRcpp/src/*.o
	./binsegRcppInside
binsegRcppLinked: binsegRcppInside.o
	g++ -o binsegRcppLinked ${COMMON_FLAGS} ${R_HOME}/library/binsegRcpp/libs/binsegRcpp.so
	./binsegRcppLinked
binsegRcppInside.o: binsegRcppInside.cpp
	g++ -I${R_HOME}/include -I${R_HOME}/library/Rcpp/include -I${R_HOME}/library/RInside/include binsegRcppInside.cpp -o binsegRcppInside.o -c
```

Note there are three recipes above. The last one is for creating the
binsegRcppInside.o object file. The first two are two different ways
to compile that object file into an executable (binsegRcppInside or
binsegRcppLinked). The first/Inside version uses the object files
(binsegRcpp/src/*.o) whereas the second/Linked version uses the shared
library (binsegRcpp.so). The first/Inside version compiles and runs
with output that looks like:

```
tdhock@maude-MacBookPro:~/R/R-3.6.3/tests/Embedding$ rm -f *.o && make -f binsegRcppInside.Makefile binsegRcppInside
g++ -I/home/tdhock/lib/R/include -I/home/tdhock/lib/R/library/Rcpp/include -I/home/tdhock/lib/R/library/RInside/include binsegRcppInside.cpp -o binsegRcppInside.o -c
g++ -o binsegRcppInside binsegRcppInside.o /home/tdhock/R/binsegRcpp/src/*.o -L/home/tdhock/lib/R/library/RInside/lib -Wl,-rpath=/home/tdhock/lib/R/library/RInside/lib -L/home/tdhock/lib/R/lib -Wl,-rpath=/home/tdhock/lib/R/lib -lR -lRInside
./binsegRcppInside
-9 -13 -13.5 -14 loss
3 1 0 2 segment ends
tdhock@maude-MacBookPro:~/R/R-3.6.3/tests/Embedding$ 
```

Note that doing the above makes a binary/executable binsegRcppInside
which contains copies of the machine code / objects defined in the
binsegRcpp C++ code. This only works if we can get access to the
binsegRcpp source code (which should be possible for all CRAN packages
as long as we have an internet connection).

Another way to achieve the same result is to link our compiled binary
to the binsegRcpp.so shared object file (second/Linked version in
Makefile recipes above), via:

```
tdhock@maude-MacBookPro:~/R/R-3.6.3/tests/Embedding$ rm -f *.o && make -f binsegRcppInside.Makefile binsegRcppLinked 
g++ -I/home/tdhock/lib/R/include -I/home/tdhock/lib/R/library/Rcpp/include -I/home/tdhock/lib/R/library/RInside/include binsegRcppInside.cpp -o binsegRcppInside.o -c
g++ -o binsegRcppLinked binsegRcppInside.o -L/home/tdhock/lib/R/library/RInside/lib -Wl,-rpath=/home/tdhock/lib/R/library/RInside/lib -L/home/tdhock/lib/R/lib -Wl,-rpath=/home/tdhock/lib/R/lib -lR -lRInside /home/tdhock/lib/R/library/binsegRcpp/libs/binsegRcpp.so
./binsegRcppLinked
-9 -13 -13.5 -14 loss
3 1 0 2 segment ends
tdhock@maude-MacBookPro:~/R/R-3.6.3/tests/Embedding$ 
```

The two methods clearly produce the same result. The difference is
only in HOW the result is computed (Linked version uses a shared
object whereas Inside version does not) and the size of the resulting
executables:

```
tdhock@maude-MacBookPro:~/R/R-3.6.3/tests/Embedding$ ldd binsegRcppInside|grep lib/R
	libR.so => /home/tdhock/lib/R/lib/libR.so (0x00007ffb2a2f1000)
	libRInside.so => /home/tdhock/lib/R/library/RInside/lib/libRInside.so (0x00007ffb2a0cd000)
tdhock@maude-MacBookPro:~/R/R-3.6.3/tests/Embedding$ ldd binsegRcppLinked|grep lib/R
	/home/tdhock/lib/R/library/binsegRcpp/libs/binsegRcpp.so (0x00007fd0e76af000)
	libR.so => /home/tdhock/lib/R/lib/libR.so (0x00007fd0e7026000)
	libRInside.so => /home/tdhock/lib/R/library/RInside/lib/libRInside.so (0x00007fd0e6e02000)
tdhock@maude-MacBookPro:~/R/R-3.6.3/tests/Embedding$ du binsegRcppLinked binsegRcppInside
92	binsegRcppLinked
1192	binsegRcppInside
```

In conclusion, we have showed how to use RInside to embed the R
interpreter into a C++ program with a main function. Our main function
called a C++ function `rcpp_binseg_normal` which was defined in an R
package, and then ran some tests on the result. For the RcppDeepState
project we will be doing something similar, but there are two key
differences. First, rather than explicitly defining a data set to use
as input (above we used the data set 0, 1, 2, 3), we will use
`DeepState_*` functions that ask fuzz testing libraries to generate
random/learned inputs. Second, rather than explicitly defining a main
function, as in the code above, we will define a DeepState test
harness (without a main function), and the DeepState tools will
automatically generate a main function to use with the fuzz testing
tools.
