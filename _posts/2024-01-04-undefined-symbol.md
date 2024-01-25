---
layout: post
title: Unable to load shared object, Undefined symbol
description: Creating and explaining a linker error
---

This post is the third in a (helpful? boring?) series of very long,
detailed explanations of the steps I took to figure out how to install
apache arrow on old Mac laptops.

## Summary of previous posts

arrow is a C++ library which implements some basic data analysis
operations, similar to `data.table` in R. Since I am PI of a NSF POSE
funded project about expanding the open-source ecosystem around
`data.table`, I was interested to install arrow and compare its
functionality and performance. I ran into several installation issues,
which were mostly fixed by upgrading OS/compilers and telling them to
respect the constraints of my old Mac laptop CPU. One of the error
messages that I got is reproduced below:

```
** testing if installed package can be loaded from temporary location
libgcc_s.so.1 must be installed for pthread_cancel to work
Loading required package: grDevices
Error: package or namespace load failed for ‘arrow’ in dyn.load(file, DLLpath = DLLpath, ...):
 unable to load shared object '/home/tdhock/lib/R/library/00LOCK-r/00new/arrow/libs/arrow.so':
  /home/tdhock/lib/libarrow.so.1200: undefined symbol: ZSTD_minCLevel
Error: loading failed
```

The goal of this post is to explain where this "undefined symbol"
error message comes from, so we can understand it and fix the arrow
installation.

## Hypothesis

My hypothesis is that src/arrow.so in R package is linking to
/home/tdhock/lib/libarrow.so.1200, which links to
/lib/x86_64-linux-gnu/libzstd.so.1, which may be a different version
(with different symbols defined) than expected. How can we test that
hypothesis?

First of all, arrow.so is created using the following command,

```
g++ -std=gnu++17 -shared 
 -L/home/tdhock/lib/R/lib -L/home/tdhock/lib 
 -Wl,-rpath=/home/tdhock/lib 
 -o arrow.so 
 RTasks.o altrep.o array.o array_to_vector.o arraydata.o arrowExports.o bridge.o buffer.o chunkedarray.o compression.o compute-exec.o compute.o config.o csv.o dataset.o datatype.o expression.o extension-impl.o feather.o field.o filesystem.o io.o json.o memorypool.o message.o parquet.o r_to_arrow.o recordbatch.o recordbatchreader.o recordbatchwriter.o safe-call-into-r-impl.o scalar.o schema.o symbols.o table.o threadpool.o type_infer.o 
 -L/home/tdhock/lib 
 -larrow_acero -larrow_dataset -lparquet -larrow 
 -L/home/tdhock/lib/R/lib 
 -lR
```

The `-larrow` flag tells the linker to try to find a file named
`libarrow.so`.  I'm not sure what command was used to create
libarrow.so, but I suppose it had a `-lzstd` flag to tell the linker
to find `libzstd.so`. 

## Attempt to create the error using one shared library

First I put the code below in `my_prog.cpp`

```cpp
#include "tdh.h"
int main(void){
  return my_fun();
}
```

Then I put the code below in `my_fun_present.cpp`

```cpp
int my_fun(void){
  return 5;
}
```

Then I made the following Makefile

```
my_prog.out: my_prog_present my_prog_absent
	./my_prog_present ; echo present $? > my_prog.out
	./my_prog_absent ; echo absent $? >> my_prog.out
	cat my_prog.out
my_prog_present: my_fun_present/lib/libtdh.so my_prog.cpp
	g++ -Lmy_fun_present/lib -Wl,-rpath=my_fun_present/lib -ltdh my_prog.cpp -o my_prog_present
my_fun_present/lib/libtdh.so: my_fun_present.cpp
	g++ -shared -o my_fun_present/lib/libtdh.so my_fun_present.cpp

my_prog_absent: my_fun_absent/lib/libtdh.so my_prog.cpp
	g++ -Lmy_fun_absent/lib -Wl,-rpath=my_fun_absent/lib -ltdh my_prog.cpp -o my_prog_absent
my_fun_absent/lib/libtdh.so: my_fun_absent.cpp
	g++ -shared -o my_fun_absent/lib/libtdh.so my_fun_absent.cpp

```

Then I type make and I got:

```
(base) tdhock@tdhock-MacBook:~/projects/undefined-symbol$ make
g++ -Lmy_fun_absent/lib -Wl,-rpath=my_fun_absent/lib -ltdh my_prog.cpp -o my_prog_absent
/home/tdhock/lib/gcc/x86_64-pc-linux-gnu/12.3.0/../../../../x86_64-pc-linux-gnu/bin/ld: /tmp/ccPYM0rH.o : dans la fonction « main » :
my_prog.cpp:(.text+0x5): undefined reference to `my_fun()'
collect2: erreur: ld a retourné le statut de sortie 1
make: *** [Makefile:11 : my_prog_absent] Erreur 1
```

The output above indicates that the compilation of `my_prog_absent`
failed (undefined reference at compile time). This is a different
error than what I got for arrow (undefined symbol at run/link time).

## Reproducing using two levels of shared libraries

So to reproduce we may have to use a second level of shared libraries.
The shell output below indicates that both `arrow.so` (R) and
`libarrow.so` (C++) link to `libzstd.so.1`,

```
(base) tdhock@tdhock-MacBook:~/projects/undefined-symbol$ ldd ~/src/apache-arrow-12.0.0/r/src/arrow.so |grep zstd
	libzstd.so.1 => /lib/x86_64-linux-gnu/libzstd.so.1 (0x00007f4f47662000)
(base) tdhock@tdhock-MacBook:~/projects/undefined-symbol$ ldd ~/lib/libarrow.so |grep zstd
	libzstd.so.1 => /home/tdhock/miniconda3/envs/arrow/lib/libzstd.so.1 (0x00007f451bb94000)
```

But the output below shows that there are two different versions
(1.5.5 vs 1.4.8), could this be the issue?

```
(base) tdhock@tdhock-MacBook:~/projects/undefined-symbol$ ls -l /lib/x86_64-linux-gnu/libzstd.so.1 /home/tdhock/miniconda3/envs/arrow/lib/libzstd.so.1
lrwxrwxrwx 1 tdhock tdhock 16 mai   14  2023 /home/tdhock/miniconda3/envs/arrow/lib/libzstd.so.1 -> libzstd.so.1.5.5
lrwxrwxrwx 1 root   root   16 mars  24  2022 /lib/x86_64-linux-gnu/libzstd.so.1 -> libzstd.so.1.4.8
```

So I created a new file "intermediate.cpp" as below,

```cpp
#include "tdh.h"
int intermediate(void){
  return my_fun();
}
```

Then I compiled that to a shared object:

```
(base) tdhock@tdhock-MacBook:~/projects/undefined-symbol$ g++ -shared -o my_fun_present/lib/libintermediate.so -Lmy_fun_absent/lib -Wl,-rpath=my_fun_absent/lib -ltdh intermediate.cpp
```

The command above creates `libintermediate.so` linked to
`my_fun_absent/lib/libtdh.so`:

```
(base) tdhock@tdhock-MacBook:~/projects/undefined-symbol$ ldd my_fun_present/lib/libintermediate.so|grep tdh
	libtdh.so => my_fun_absent/lib/libtdh.so (0x00007fa02bc2c000)
```

I guess the compilation above works (no error), even though `my_fun`
is not defined, because symbol resolution does not take place until
later.

Next command is to compile the executable `my_prog_present` with
linker flags pointing to `my_fun_present/lib`:

```
(base) tdhock@tdhock-MacBook:~/projects/undefined-symbol$ g++ -Lmy_fun_present/lib -Wl,-rpath=my_fun_present/lib my_prog.cpp -o my_prog_present -lintermediate
(base) tdhock@tdhock-MacBook:~/projects/undefined-symbol$ ldd my_prog_present|grep tdh
	libtdh.so => my_fun_absent/lib/libtdh.so (0x00007f78cb701000)
```

However the output above indicates the program is linked to
`my_fun_absent/lib/libtdh.so` which means when we run the program, we
get the error below:

```
(base) tdhock@tdhock-MacBook:~/projects/undefined-symbol$ ./my_prog_present 
./my_prog_present: symbol lookup error: my_fun_present/lib/libintermediate.so: undefined symbol: _Z6my_funv
```

How to fix the error? We need to recompile libintermediate.so with
links to the right libtdh.so:

```
(base) tdhock@tdhock-MacBook:~/projects/undefined-symbol$ g++ -shared -o my_fun_present/lib/libintermediate.so -Lmy_fun_present/lib -Wl,-rpath=my_fun_present/lib -ltdh intermediate.cpp
(base) tdhock@tdhock-MacBook:~/projects/undefined-symbol$ g++ -Lmy_fun_present/lib -Wl,-rpath=my_fun_present/lib my_prog.cpp -o my_prog_present -lintermediate
(base) tdhock@tdhock-MacBook:~/projects/undefined-symbol$ ./my_prog_present 
(base) tdhock@tdhock-MacBook:~/projects/undefined-symbol$ echo $?
5
```

The output above indicates that the program compiled, linked, and ran successfully.

## Conclusion

We have demonstrated the cause of the "undefined symbol" error from
g++, by creating two levels of shared libraries.

* we created two versions of `libtdh.so`, one with `my_fun`, one without.
* we created `libintermediate.so` which links to the version of
  `libtdh.so` without `my_fun`.
* we can compile an executable program that links to
  `libintermediate.so`, but running that program gives an "undefined
  symbol" error.
* That error can be fixed by linking `libintermediate.so` to the
  version of `libtdh.so` with `my_fun`.
* Bringing the example back to arrow, the root cause is most likely
  the two different versions of `libzstd.so`, so can most likely be
  fixed by picking one and sticking to it throughout the build process
  (during the C++ build, and during the R package build).
