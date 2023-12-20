---
layout: post
title: Upgrading R arrow
description: More build debugging
---

This post is the second in a (boring? helpful?) series of very long,
detailed explanations of the steps I took to figure out how to install
R arrow on old Mac laptops.

### Summary of last post

In [the first
post](https://tdhock.github.io/blog/2023/arrow-segfault/), I began by
explaining that I got a segfault when I tried to use
`arrow::write_dataset` on my old Mac laptop (circa 2010). I wanted to
get arrow working, so I can run comparative benchmarks (time and
memory of various R packages related to big data analysis), in support
of my NSF POSE funded project about expanding the open-source
ecosystem around R `data.table`.

I finally got it working by following the steps below.

* Download release 12.0.0 from https://arrow.apache.org/release/ to
  ~/src
* cd ~/src, tar xf arrow.tar.gz, cd arrow-version/cpp, mkdir build, cd build, conda activate arrow, 
* `cmake .. --preset ninja-debug-basic -DCMAKE_INSTALL_PREFIX=$HOME -DARROW_CXXFLAGS=-march=core2 -DARROW_PARQUET=ON -DARROW_SIMD_LEVEL=NONE -DCMAKE_INSTALL_RPATH=$HOME/lib64:$HOME/lib:$CONDA_PREFIX/lib -DCMAKE_PREFIX_PATH=$HOME -DCMAKE_FIND_ROOT_PATH=$HOME`
* `cmake --build .`
* `cmake --install .`
* `ARROW_PARQUET=true ARROW_R_WITH_PARQUET=true ARROW_DEPENDENCY_SOURCE=SYSTEM ARROW_R_DEV=true LIBARROW_BINARY=false PKG_CONFIG_PATH=$HOME/lib/pkgconfig:$CONDA_PREFIX/lib/pkgconfig R CMD INSTALL ../../r`
* After doing the above, test the working installation by running
  `example(write_dataset,package="arrow")` in R.

### Problem 1

Above we used preset `ninja-debug-basic` but other presets like
`ninja-release-basic` do not work. C++ build works, but R package
install fails with error below:

```
(arrow) tdhock@maude-MacBookPro:~/src/apache-arrow-12.0.0/cpp/build$ ARROW_PARQUET=true ARROW_R_WITH_PARQUET=true ARROW_DEPENDENCY_SOURCE=SYSTEM ARROW_R_DEV=true LIBARROW_BINARY=false PKG_CONFIG_PATH=$HOME/lib/pkgconfig:$CONDA_PREFIX/lib/pkgconfig R CMD INSTALL ../../r
Loading required package: grDevices
* installing to library ‘/home/tdhock/lib/R/library’
* installing *source* package ‘arrow’ ...
** using staged installation
*** Generating code with data-raw/codegen.R
Loading required package: grDevices
Error in library(decor) : there is no package called ‘decor’
Calls: suppressPackageStartupMessages -> withCallingHandlers -> library
Execution halted
*** Arrow C++ libraries found via pkg-config at /home/tdhock/lib
PKG_CFLAGS=-I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_SUBSTRAIT -DARROW_R_WITH_JSON
PKG_LIBS=-L/home/tdhock/lib -larrow_substrait -larrow_acero -larrow_dataset -lparquet -larrow
** libs
using C++ compiler: ‘g++ (GCC) 10.1.0’
using C++17
make: Nothing to be done for 'all'.
installing to /home/tdhock/lib/R/library/00LOCK-r/00new/arrow/libs
** R
** inst
** byte-compile and prepare package for lazy loading
Loading required package: grDevices
** help
*** installing help indices
** building package indices
Loading required package: grDevices
** installing vignettes
** testing if installed package can be loaded from temporary location
libgcc_s.so.1 must be installed for pthread_cancel to work
Loading required package: grDevices
Error: package or namespace load failed for ‘arrow’ in dyn.load(file, DLLpath = DLLpath, ...):
 unable to load shared object '/home/tdhock/lib/R/library/00LOCK-r/00new/arrow/libs/arrow.so':
  /home/tdhock/lib/libarrow.so.1200: undefined symbol: ZSTD_minCLevel
Error: loading failed
Execution halted
Aborted (core dumped)
ERROR: loading failed
* removing ‘/home/tdhock/lib/R/library/arrow’
* restoring previous ‘/home/tdhock/lib/R/library/arrow’
```

Web search for the above error message "undefined symbol:
ZSTD_minCLevel" gave [this github issue
comment](https://github.com/facebook/wangle/issues/73#issuecomment-255445681)
in an unrelated project, that suggests my issue may be multiple
installation of libzstd. Is that true? Maybe one from ubuntu and one
from conda? Below is the ldd for `libarrow.so`, which indicates it is
linking to conda `zstd.so.1`.

```
(arrow) tdhock@maude-MacBookPro:~/src/apache-arrow-12.0.0/cpp/build$ ldd /home/tdhock/lib/libarrow.so
	linux-vdso.so.1 (0x00007ffc02cdc000)
	libbrotlienc.so.1 => /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libbrotlienc.so.1 (0x00007fe495f7e000)
	libbrotlidec.so.1 => /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libbrotlidec.so.1 (0x00007fe495f70000)
	libutf8proc.so.2 => /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libutf8proc.so.2 (0x00007fe495f1b000)
	libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007fe4941d0000)
	librt.so.1 => /lib/x86_64-linux-gnu/librt.so.1 (0x00007fe493fc8000)
	libbz2.so.1.0 => /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libbz2.so.1.0 (0x00007fe495ed9000)
	liblz4.so.1 => /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/liblz4.so.1 (0x00007fe495eab000)
	libsnappy.so.1 => /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libsnappy.so.1 (0x00007fe495e9f000)
	libz.so.1 => /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libz.so.1 (0x00007fe495e81000)
	libzstd.so.1 => /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libzstd.so.1 (0x00007fe493eb8000)
	libre2.so.9 => /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libre2.so.9 (0x00007fe493e42000)
	libstdc++.so.6 => /home/tdhock/lib64/libstdc++.so.6 (0x00007fe493a6f000)
	libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007fe4936d1000)
	libgcc_s.so.1 => /home/tdhock/lib64/libgcc_s.so.1 (0x00007fe4934b9000)
	libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007fe49329a000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fe492ea9000)
	/lib64/ld-linux-x86-64.so.2 (0x00007fe495df7000)
	libbrotlicommon.so.1 => /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/./libbrotlicommon.so.1 (0x00007fe495e5c000)
```

Above ldd output was for C++ `libarrow.so` TODO check below for maude-MacBookPro.

Below output is for `arrow.so` on tdhock-MacBook.

```
(arrow) tdhock@tdhock-MacBook:~/src/apache-arrow-12.0.0/cpp/build$ ldd ../../r/src/arrow.so |grep zstd
	libzstd.so.1 => /lib/x86_64-linux-gnu/libzstd.so.1 (0x00007f45045f5000)
```

Above ldd output indicates a different libzstd is used, but are they
really different versions? On one machine they are different
minor/patch versions, but same major version(1):

```
(arrow) tdhock@tdhock-MacBook:~/src/apache-arrow-12.0.0/cpp/build$ ls ~/miniconda3/envs/arrow/lib/libzstd.so*
/home/tdhock/miniconda3/envs/arrow/lib/libzstd.so
/home/tdhock/miniconda3/envs/arrow/lib/libzstd.so.1
/home/tdhock/miniconda3/envs/arrow/lib/libzstd.so.1.5.5

(arrow) tdhock@tdhock-MacBook:~/src/apache-arrow-12.0.0/cpp/build$ ls /lib/x86_64-linux-gnu/libzstd.so*
/lib/x86_64-linux-gnu/libzstd.so    /lib/x86_64-linux-gnu/libzstd.so.1.4.8
/lib/x86_64-linux-gnu/libzstd.so.1
```

Above does not make sense as the source of the issue, because same
major versions are supposed to be binary compatible.

### Problem 2: arrow C++ 13+ compilation errors

Below we show a compilation error that occurs when building arrow C++ 13+ (but not 12).

```
(arrow) tdhock@maude-MacBookPro:~/src/apache-arrow-14.0.1/cpp/build$ cmake --build .
[1/626] Creating directories for 'jemalloc_ep'
...
[140/626] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/integration/json_internal.cc.o
FAILED: src/arrow/CMakeFiles/arrow_objlib.dir/integration/json_internal.cc.o 
/usr/bin/c++ -DARROW_EXPORTING -DARROW_EXTRA_ERROR_CONTEXT -DARROW_HAVE_RUNTIME_AVX2 -DARROW_HAVE_RUNTIME_AVX512 -DARROW_HAVE_RUNTIME_BMI2 -DARROW_HAVE_RUNTIME_SSE4_2 -DARROW_WITH_BACKTRACE -DARROW_WITH_TIMING_TESTS -DBOOST_ALL_NO_LIB -DURI_STATIC_BUILD -I/home/tdhock/src/apache-arrow-14.0.1/cpp/build/src -I/home/tdhock/src/apache-arrow-14.0.1/cpp/src -I/home/tdhock/src/apache-arrow-14.0.1/cpp/src/generated -isystem /home/tdhock/src/apache-arrow-14.0.1/cpp/thirdparty/flatbuffers/include -isystem /home/tdhock/src/apache-arrow-14.0.1/cpp/thirdparty/hadoop/include -isystem /home/tdhock/.local/share/r-miniconda/envs/arrow/include -isystem /home/tdhock/src/apache-arrow-14.0.1/cpp/build/jemalloc_ep-prefix/src -Wno-noexcept-type  -fdiagnostics-color=always  -Wall -Wno-conversion -Wno-sign-conversion -Wunused-result -Wdate-time -fno-semantic-interposition -march=core2 -g -Werror -O0 -ggdb  -fPIC -pthread -std=c++1z -MD -MT src/arrow/CMakeFiles/arrow_objlib.dir/integration/json_internal.cc.o -MF src/arrow/CMakeFiles/arrow_objlib.dir/integration/json_internal.cc.o.d -o src/arrow/CMakeFiles/arrow_objlib.dir/integration/json_internal.cc.o -c /home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc
In file included from /home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc:50:0:
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/util/range.h: In instantiation of ‘constexpr const arrow::internal::<lambda()> [with I = int]::<unnamed struct> arrow::internal::Enumerate<int>’:
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc:122:50:   required from here
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/util/range.h:256:2: error: call to non-constexpr function ‘arrow::internal::<lambda()> [with I = int]’
 constexpr auto Enumerate = [] {
                            ~~~~
   struct {
   ~~~~~~~~
     struct sentinel {};
     ~~~~~~~~~~~~~~~~~~~
     constexpr sentinel end() const { return {}; }
     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
   
     struct iterator {
     ~~~~~~~~~~~~~~~~~
       I value{0};
       ~~~~~~~~~~~
 
   
       constexpr I operator*() { return value; }
       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
   
       constexpr iterator& operator++() {
       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
         ++value;
         ~~~~~~~~
         return *this;
         ~~~~~~~~~~~~~
       }
       ~
 
   
       constexpr std::true_type operator!=(sentinel) const { return {}; }
       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     };
     ~~
     constexpr iterator begin() const { return {}; }
     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   } out;
   ~~~~~~
 
   
   return out;
   ~~~~~~~~~~~
 }();
 ~^~
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/util/range.h:235:29: note: ‘arrow::internal::<lambda()> [with I = int]’ is not usable as a constexpr function because:
 constexpr auto Enumerate = [] {
                             ^
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/util/range.h:253:5: error: uninitialized variable ‘out’ in ‘constexpr’ function
   } out;
     ^~~
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc: In member function ‘arrow::enable_if_base_binary<T, arrow::Status> arrow::internal::integration::json::{anonymous}::ArrayReader::Visit(const T&)’:
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc:1308:59: error: no matching function for call to ‘quoted(std::string_view&)’
           return Status::Invalid("Value ", std::quoted(val),
                                                           ^
In file included from /home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc:22:0:
/usr/include/c++/7/iomanip:461:5: note: candidate: template<class _CharT> auto std::quoted(const _CharT*, _CharT, _CharT)
     quoted(const _CharT* __string,
     ^~~~~~
/usr/include/c++/7/iomanip:461:5: note:   template argument deduction/substitution failed:
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc:1308:59: note:   mismatched types ‘const _CharT*’ and ‘std::basic_string_view<char>’
           return Status::Invalid("Value ", std::quoted(val),
                                                           ^
In file included from /home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc:22:0:
/usr/include/c++/7/iomanip:470:5: note: candidate: template<class _CharT, class _Traits, class _Alloc> auto std::quoted(const std::__cxx11::basic_string<_CharT, _Traits, _Alloc>&, _CharT, _CharT)
     quoted(const basic_string<_CharT, _Traits, _Alloc>& __string,
     ^~~~~~
/usr/include/c++/7/iomanip:470:5: note:   template argument deduction/substitution failed:
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc:1308:59: note:   ‘std::string_view {aka std::basic_string_view<char>}’ is not derived from ‘const std::__cxx11::basic_string<_CharT, _Traits, _Alloc>’
           return Status::Invalid("Value ", std::quoted(val),
                                                           ^
In file included from /home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc:22:0:
/usr/include/c++/7/iomanip:480:5: note: candidate: template<class _CharT, class _Traits, class _Alloc> auto std::quoted(std::__cxx11::basic_string<_CharT, _Traits, _Alloc>&, _CharT, _CharT)
     quoted(basic_string<_CharT, _Traits, _Alloc>& __string,
     ^~~~~~
/usr/include/c++/7/iomanip:480:5: note:   template argument deduction/substitution failed:
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc:1308:59: note:   ‘std::string_view {aka std::basic_string_view<char>}’ is not derived from ‘std::__cxx11::basic_string<_CharT, _Traits, _Alloc>’
           return Status::Invalid("Value ", std::quoted(val),
                                                           ^
In file included from /home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc:50:0:
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/util/range.h: In instantiation of ‘constexpr const arrow::internal::<lambda()> [with I = unsigned int]::<unnamed struct> arrow::internal::Enumerate<unsigned int>’:
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc:1450:30:   required from ‘arrow::Status arrow::internal::integration::json::{anonymous}::ArrayReader::GetIntArray(const RjArray&, int32_t, std::shared_ptr<arrow::Buffer>*) [with T = unsigned char; RjArray = arrow::rapidjson::GenericArray<true, arrow::rapidjson::GenericValue<arrow::rapidjson::UTF8<> > >; int32_t = int]’
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc:1521:75:   required from here
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/util/range.h:256:2: error: call to non-constexpr function ‘arrow::internal::<lambda()> [with I = unsigned int]’
 constexpr auto Enumerate = [] {
                            ~~~~
   struct {
   ~~~~~~~~
     struct sentinel {};
     ~~~~~~~~~~~~~~~~~~~
     constexpr sentinel end() const { return {}; }
     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
   
     struct iterator {
     ~~~~~~~~~~~~~~~~~
       I value{0};
       ~~~~~~~~~~~
 
   
       constexpr I operator*() { return value; }
       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
   
       constexpr iterator& operator++() {
       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
         ++value;
         ~~~~~~~~
         return *this;
         ~~~~~~~~~~~~~
       }
       ~
 
   
       constexpr std::true_type operator!=(sentinel) const { return {}; }
       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     };
     ~~
     constexpr iterator begin() const { return {}; }
     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   } out;
   ~~~~~~
 
   
   return out;
   ~~~~~~~~~~~
 }();
 ~^~
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/util/range.h:235:29: note: ‘arrow::internal::<lambda()> [with I = unsigned int]’ is not usable as a constexpr function because:
 constexpr auto Enumerate = [] {
                             ^
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/util/range.h:253:5: error: uninitialized variable ‘out’ in ‘constexpr’ function
   } out;
     ^~~
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/util/range.h: At global scope:
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/util/range.h:196:12: error: ‘arrow::internal::Zip<std::tuple<_Tps ...>, std::integer_sequence<long unsigned int, __indices ...> >::Zip(Ranges ...) [with Ranges = {const arrow::internal::<lambda()> [with I = unsigned int]::<unnamed struct>&, const arrow::rapidjson::GenericArray<true, arrow::rapidjson::GenericValue<arrow::rapidjson::UTF8<char>, arrow::rapidjson::MemoryPoolAllocator<arrow::rapidjson::CrtAllocator> > >&}; long unsigned int ...I = {0, 1}]’, declared using unnamed type, is used but never defined [-fpermissive]
   explicit Zip(Ranges... ranges) : ranges_(std::forward<Ranges>(ranges)...) {}
            ^~~
[141/626] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/csv/column_builder.cc.o
[142/626] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/csv/converter.cc.o
ninja: build stopped: subcommand failed.
```

The distinctive parts of the error message are copied below,

```
range.h:256:2: error: call to non-constexpr function ‘arrow::internal::<lambda()> [with I = int]’

range.h:235:29: note: ‘arrow::internal::<lambda()> [with I = unsigned int]’ is not usable as a constexpr function because:
 constexpr auto Enumerate = [] {
                             ^
 
range.h:253:5: error: uninitialized variable ‘out’ in ‘constexpr’ function
   } out;
     ^~~
```

[Searching the arrow issue tracker for
non-constexpr](https://github.com/apache/arrow/issues?q=is%3Aissue++non-constexpr+),
I did not find any issues that match this one.
