---
layout: post
title: Multi-threaded sorting
description: Thread safety of qsort variants
---

### C++ STL map versus sort

To support a new research paper I recently implemented efficient C and
C++ codes for computing Area Under the Minimum (AUM) of False
Positives and False Negatives.  The first function I coded was
[aum_map](https://github.com/tdhock/aum/blob/main/src/aum_map.cpp),
which uses the C++ Standard Template Library (STL) map object, which
keeps unique thresholds in sorted order. 

Is this a good use of the STL map object? In general I recommend using
the STL red-black tree objects (map, set, etc) when elements need to
be kept sorted in a particular order, and the most extreme element
needs to be found after every insert. Thus the AUM computation is an
example where the STL map is overkill -- in this case we only need to
query the sorted order of the data structure after all elements have
been inserted (not after intermediate inserts). The STL map would be
better suited to an application where the map needs to be queried
after every insert, such as in [binary
segmentation](https://github.com/tdhock/binsegRcpp/blob/master/src/binseg_normal.cpp).

In the case of AUM computation we could instead use simpler data
structures (arrays) and one call to a sort function. So to pursue this
idea, which I presumed should be faster, I coded another version,
[aum_sort](https://github.com/tdhock/aum/blob/main/src/aum_sort.cpp).
Originally I coded it using `std::sort` in C++ using an anonymous
function,

```c++
#include <algorithm>//std::sort
#include <vector>
double *out_thresh;
int err_N;
std::vector<int> out_indices(err_N);
std::sort(out_indices.begin(), out_indices.end(),
  [&out_thresh](int left, int right){
    return out_thresh[left] < out_thresh[right];
  }
);
```

Using `std::sort` in this way, we specify the begin/end as the first
two arguments, and then we specify a comparison function as the third
argument. The anonymous comparison function gets access to the
`out_thresh` variable by reference via the `[&out_thresh]` syntax,
which is very convenient! 

### From C++ to C, compiler/doc issues with qsort variants

Then I began to try to simplify so that the code could compile as
standard C -- the idea would be a more portable code (would not
require C++ compiler). Just use `qsort` from the C standard library
instead of `std::sort` from C++, simple, right? Actually it is a bit
more complicated.

On my Ubuntu laptop there was a linux man page for
[qsort_r](https://linux.die.net/man/3/qsort_r) -- the r is for
re-entrant, meaning that it should be thread safe. Its prototype is

```c
void qsort_r(void *base, size_t nmemb, size_t size,
           int (*compar)(const void *, const void *, void *),
           void *arg);
```

The first three arguments are analogous to the first two in
`std::sort` (specify begin/end of array along with size of each
element). The fourth argument is a comparison function, and the fifth
argument is a pointer to some data which is passed as the third
argument of the comparison function. For example in my code I used the
following comparison function and `qsort_r` call,

```c
int compare_indices(const void *left, const void *right, void *ptr){
  double *out_thresh = (double*)ptr;
  return out_thresh[* (int*)left] > out_thresh[* (int*)right];
}
int aum_sort(int err_N, int *out_indices, double *out_thresh){
  qsort_r(out_indices, err_N, sizeof(int), compare_indices, out_thresh);
}
```

The idea is that the `left` and `right` are actually pointers to `int`
(indices from 0 to N-1 used to select elements of several arrays of
size N, sorted by values of `out_thresh`). Note that the sign of the
inequality is reversed with respect to the anonymous C++ comparison
function we saw earlier.

All of this works fine on Ubuntu, but it did not compile when I tried
on windows, using `g++` in
[rtools40](https://cran.r-project.org/bin/windows/Rtools/). The
compiler told me:

```compilation
"C:/rtools40/mingw64/bin/"g++ -std=gnu++11  -I"C:/PROGRA~1/R/R-40~1.2/include" -DNDEBUG -fopenmp -I'C:/Program Files/R/R-4.0.2/library/Rcpp/include'        -O2 -Wall  -mfpmath=sse -msse2 -mstackrealign -c aum_sort.cpp -o aum_sort.o
aum_sort.cpp:65:3: error: 'qsort_r' was not declared in this scope
   qsort_r(out_indices, err_N, sizeof(int), compare_indices);
   ^~~~~~~
aum_sort.cpp:65:3: note: suggested alternative: 'qsort_s'
```

Hm, so `qsort_r` does not exist on windows, but `qsort_s` does? The s
is for safe, and it is documented on
[cppreference](https://en.cppreference.com/w/c/algorithm/qsort),

```c
errno_t qsort_s( void *ptr, rsize_t count, rsize_t size,
                 int (*comp)(const void *, const void *, void *),
                 void *context );
```

So I thought, that is basically the same prototype as `qsort_r` so I
can just use `qsort_s` instead, right?

```c
qsort_s(out_indices, err_N, sizeof(int), compare_indices, out_thresh);
```

Actually that gave me a compilation error as well,

```compilation
aum_sort.cpp:65:44: error: invalid conversion from 'int (*)(const void*, const void*)' to 'int (*)(void*, const void*, const void*)' [-fpermissive]
   qsort_s(out_indices, err_N, sizeof(int), compare_indices, out_thresh);
                                            ^~~~~~~~~~~~~~~
```

The error says that the comparison function I provided has prototype
`int (*)(const void*, const void*, void*)` but `qsort_s` requires a
comparison function with prototype `int (*)(void*, const void*, const
 void*)` (non-`const` pointer for first argument not third). Where
 does this come from? Why is it inconsistent with the docs?
 
Well it seems that the `qsort_s` standard shown on cppreference is not
obeyed by all compilers, but the [Microsoft
docs](https://docs.microsoft.com/en-us/cpp/c-runtime-library/reference/qsort-s?view=msvc-160)
seem to be consistent with my compiler,

```c
void qsort_s(
   void *base,
   size_t num,
   size_t width,
   int (__cdecl *compare )(void *, const void *, const void *),
   void * context
);
```

So I got it working on windows by changing the order of the arguments
in the comparison function. Then I went back to my Ubuntu laptop and I
tried to compile it, but again I got an error, this time saying that
`qsort_s` is not available, try `qsort_r` instead! So after doing a
few web searches, it seems that `qsort_r` is non-standard, with [Mac
OS](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/qsort_r.3.html)
and
[BSD](https://www.freebsd.org/cgi/man.cgi?query=qsort_r&apropos=0&sektion=3&manpath=FreeBSD+11-current&format=html)
providing prototypes that are consistent with `qsort_s` and
inconsistent with linux `qsort_r`:

```c
//Mac
void
qsort_r(void *base, size_t nel, size_t width, void *thunk,
  int (*compar)(void *, const void *, const void *));
//BSD
void
qsort_r(void *base, size_t nmemb, size_t size, void *thunk,
  int (*compar)(void *, const void *, const void *));
```

How confusing! I hope that a standard is adopted at some point.

### Thread-safe C qsort

So to get a portable C code that can be used in all common platforms
(mac, windows, linux) that R supports, I decided to use regular
`qsort` instead of the s/r variatnts. The easiest way to do that is by
creating a (file-local) static variable that can be written from my
`aum_sort` function, then read from my comparison function,

```c
#include <stdlib.h>//qsort
#include <stdio.h>//printf
#include <pthread.h>//pthread_self
static double *sort_thresh; 
int compare_indices(const void *left, const void *right){
  return sort_thresh[* (int*)left] > sort_thresh[* (int*)right];
}
int aum_sort(int err_N, int *out_indices, double *out_thresh){
  sort_thresh = out_thresh;
  printf("Thread=%d, ptr=%p\n", pthread_self(), &sort_thresh);
  qsort(out_indices, err_N, sizeof(int), compare_indices);
}
```

This works fine as well, but there is one potential issue: what
happens if `aum_sort` is called in several threads at the same time?
Since the `sort_thresh` variable is static, it would be shared between
threads. If the second thread writes to `sort_thresh` before the first
thread has finished the sort, then the results could be incorrect! How
to avoid this potential issue?

First, can we observe the issue? If we call `aum_sort` from R, it is
unlikely, since parallel programming in R usually involves forking
rather than threading. That is when you call `parallel::mclapply` in
R, there is no multi-threading, only forking. To observe the issue we
can create a new Rcpp interface function with multi-threading via
OpenMP,

```c++
#include <omp.h> 
// [[Rcpp::export]]
void multithread
(const Rcpp::DataFrame err_df,
 const Rcpp::NumericVector pred_vec,
 int threads){
#pragma omp parallel for
  for(int i=0; i<threads; i++){
    aum_sort_interface(err_df, pred_vec);
  }
}
```

Note that to compile this code we need to add the following to
src/Makevars in the R package:

```makefile
PKG_CPPFLAGS=-fopenmp
PKG_LIBS=-lgomp -lpthread
```

So if we call this function from R we get

```r
> aum:::multithread(models, predictions, 2)
Thread=2, ptr=0000000061c8b340
Thread=1, ptr=0000000061c8b340
```

That shows that the two threads access the same pointer, which is
dangerous! How to avoid this? We can use the `__thread` keyword, as
[explained in the gcc
docs](https://gcc.gnu.org/onlinedocs/gcc/Thread-Local.html),

```c++
static __thread double *sort_thresh;
```

Re-compiling and runnig the code then gives us:

```r
> aum:::multithread(models, predictions, 2)
Thread=1, ptr=00000000137536c8
Thread=2, ptr=0000000013753628
```

The problem has been fixed! Wow, C is complicated! C++ is much easier!
