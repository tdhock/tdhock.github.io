---
layout: post
title: R in Docker on Mac
description: Reproducing valgrind messages using an R-hub image
---

Recently I have been preparing a reviewer response for my paper about
the Generalized Functional Pruning Optimal Partitioning (GFPOP)
algorithm. Pre-print is
[arXiv:1810.00117](https://arxiv.org/abs/1810.00117) and code is in R
package [PeakSegDisk](https://github.com/tdhock/PeakSegDisk).

I have addressed all the reviewer comments, but CRAN will not accept a
new submission unless I fix all the problems shown on the [check
page](https://cloud.r-project.org/web/checks/check_results_PeakSegDisk.html). That
is a sensible policy, but it has been extremely difficult for me to
figure out how to fix the problem, since I am unable to reproduce the
error message on my own computer. Here is what it looked like on CRAN:

```
> names.list <- PeakSegFPOP_disk(tmp, "10.5")
==3342== Syscall param write(buf) points to uninitialised byte(s)
==3342==    at 0x53FFB15: write (in /usr/lib64/libpthread-2.29.so)
==3342==    by 0x72451E5: ??? (in /usr/lib64/libstdc++.so.6.0.26)
==3342==    by 0x7284CC4: std::basic_filebuf<char, std::char_traits<char> >::_M_convert_to_external(char*, long) (in /usr/lib64/libstdc++.so.6.0.26)
==3342==    by 0x728514B: std::basic_filebuf<char, std::char_traits<char> >::overflow(int) (in /usr/lib64/libstdc++.so.6.0.26)
==3342==    by 0x7284E55: std::basic_filebuf<char, std::char_traits<char> >::_M_terminate_output() (in /usr/lib64/libstdc++.so.6.0.26)
==3342==    by 0x7284F9E: std::basic_filebuf<char, std::char_traits<char> >::_M_seek(long, std::_Ios_Seekdir, __mbstate_t) (in /usr/lib64/libstdc++.so.6.0.26)
==3342==    by 0x7285455: std::basic_filebuf<char, std::char_traits<char> >::seekoff(long, std::_Ios_Seekdir, std::_Ios_Openmode) (in /usr/lib64/libstdc++.so.6.0.26)
==3342==    by 0x72AD1FE: std::ostream::seekp(long, std::_Ios_Seekdir) (in /usr/lib64/libstdc++.so.6.0.26)
==3342==    by 0x48C38C8: seek_element (packages/tests-vg/PeakSegDisk/src/PeakSegFPOPLog.cpp:91)
==3342==    by 0x48C38C8: write (packages/tests-vg/PeakSegDisk/src/PeakSegFPOPLog.cpp:131)
==3342==    by 0x48C38C8: PeakSegFPOP_disk(char*, char*) (packages/tests-vg/PeakSegDisk/src/PeakSegFPOPLog.cpp:405)
==3342==    by 0x48C8507: PeakSegFPOP_interface(char**, char**) (packages/tests-vg/PeakSegDisk/src/interface.cpp:11)
==3342==    by 0x498FFD: do_dotCode (svn/R-devel/src/main/dotcode.c:1746)
==3342==    by 0x4CCC8F: bcEval (svn/R-devel/src/main/eval.c:6775)
==3342==  Address 0x100919a8 is 56 bytes inside a block of size 8,192 alloc'd
==3342==    at 0x4839593: operator new[](unsigned long) (/builddir/build/BUILD/valgrind-3.15.0/coregrind/m_replacemalloc/vg_replace_malloc.c:433)
==3342==    by 0x7284B23: std::basic_filebuf<char, std::char_traits<char> >::_M_allocate_internal_buffer() (in /usr/lib64/libstdc++.so.6.0.26)
==3342==    by 0x7288E36: std::basic_filebuf<char, std::char_traits<char> >::open(char const*, std::_Ios_Openmode) (in /usr/lib64/libstdc++.so.6.0.26)
==3342==    by 0x48C31CC: open (/usr/include/c++/9/fstream:1180)
==3342==    by 0x48C31CC: init (packages/tests-vg/PeakSegDisk/src/PeakSegFPOPLog.cpp:73)
==3342==    by 0x48C31CC: PeakSegFPOP_disk(char*, char*) (packages/tests-vg/PeakSegDisk/src/PeakSegFPOPLog.cpp:263)
==3342==    by 0x48C8507: PeakSegFPOP_interface(char**, char**) (packages/tests-vg/PeakSegDisk/src/interface.cpp:11)
==3342==    by 0x498FFD: do_dotCode (svn/R-devel/src/main/dotcode.c:1746)
==3342==    by 0x4CCC8F: bcEval (svn/R-devel/src/main/eval.c:6775)
==3342==    by 0x4E4DFF: Rf_eval (svn/R-devel/src/main/eval.c:620)
==3342==    by 0x4E694E: R_execClosure (svn/R-devel/src/main/eval.c:1780)
==3342==    by 0x4E7694: Rf_applyClosure (svn/R-devel/src/main/eval.c:1706)
==3342==    by 0x4E4EF4: Rf_eval (svn/R-devel/src/main/eval.c:743)
==3342==    by 0x4E908E: do_set (svn/R-devel/src/main/eval.c:2808)
==3342==  Uninitialised value was created by a heap allocation
==3342==    at 0x4838E86: operator new(unsigned long) (/builddir/build/BUILD/valgrind-3.15.0/coregrind/m_replacemalloc/vg_replace_malloc.c:344)
==3342==    by 0x48C3431: allocate (/usr/include/c++/9/ext/new_allocator.h:114)
==3342==    by 0x48C3431: allocate (/usr/include/c++/9/bits/alloc_traits.h:444)
==3342==    by 0x48C3431: _M_get_node (/usr/include/c++/9/bits/stl_list.h:438)
==3342==    by 0x48C3431: _M_create_node<double, int, double, double&, double&, int, bool> (/usr/include/c++/9/bits/stl_list.h:630)
==3342==    by 0x48C3431: _M_insert<double, int, double, double&, double&, int, bool> (/usr/include/c++/9/bits/stl_list.h:1907)
==3342==    by 0x48C3431: emplace_back<double, int, double, double&, double&, int, bool> (/usr/include/c++/9/bits/stl_list.h:1223)
==3342==    by 0x48C3431: PeakSegFPOP_disk(char*, char*) (packages/tests-vg/PeakSegDisk/src/PeakSegFPOPLog.cpp:284)
==3342==    by 0x48C8507: PeakSegFPOP_interface(char**, char**) (packages/tests-vg/PeakSegDisk/src/interface.cpp:11)
==3342==    by 0x498FFD: do_dotCode (svn/R-devel/src/main/dotcode.c:1746)
==3342==    by 0x4CCC8F: bcEval (svn/R-devel/src/main/eval.c:6775)
==3342==    by 0x4E4DFF: Rf_eval (svn/R-devel/src/main/eval.c:620)
==3342==    by 0x4E694E: R_execClosure (svn/R-devel/src/main/eval.c:1780)
==3342==    by 0x4E7694: Rf_applyClosure (svn/R-devel/src/main/eval.c:1706)
==3342==    by 0x4E4EF4: Rf_eval (svn/R-devel/src/main/eval.c:743)
==3342==    by 0x4E908E: do_set (svn/R-devel/src/main/eval.c:2808)
==3342==    by 0x4E5162: Rf_eval (svn/R-devel/src/main/eval.c:695)
==3342==    by 0x5137FC: Rf_ReplIteration (svn/R-devel/src/main/main.c:260)
==3342==    by 0x5137FC: Rf_ReplIteration (svn/R-devel/src/main/main.c:200)
==3342== 
> 
```

I talked to R-core member Tomas Kalibera at useR 2019 in Toulouse, and
he recommended I try reproducing the error using
[R-hub](https://builder.r-hub.io/). Luckily I was able to reproduce
the valgrind error using `rhub::check_with_valgrind`, which uses the
`rhub/debian-gcc-release` docker image.

My old mac does not support the new Docker Desktop, so I had to
install [Docker Toolbox](https://docs.docker.com/toolbox/overview/).

At first I had some problems because Docker was unable to access
files/folders on my Mac. The key thing to know about this setup is
that Docker will actually be run inside a Linux Virtualbox on the
mac. So we have to make sure the Virtualbox can access the
files/folders.

The Virtualbox [Guest additions
docs](https://www.virtualbox.org/manual/ch04.html#sharedfolders) says
that shared folders can be mounted on Linux guests using 

```
mount -t vboxsf [-o OPTIONS] sharename mountpoint
```

so I opened up the Virtualbox linux command line and ran

```
mount -t vboxsf Users /Users
```

which worked. I start a new docker container using

```
docker run \\
 --name test \\
 -d \\ detached
 -it \\ interactive
 -v /Users/maudelaperriere/toby:/home/toby \\ mount
 rhub/debian-gcc-release
```

Inside the docker image you can suspend using C-P C-Q.

Then you can resume using

```
docker attach test
```

Then I install the CRAN version of my package and its deps using

```
docker exec test R -e 'install.packages("PeakSegDisk")'
```

Then I test to make sure I get the same error as on CRAN:

```
docker exec test R -d 'valgrind --track-origins=yes' \\
 -e 'library(PeakSegDisk);example(PeakSegFPOP_disk)'
```

I did. I then created this `valgrind.sh` script in my R package directory:

```
#!/bin/bash
set -o errexit
R CMD INSTALL .
R -d 'valgrind --track-origins=yes' -e 'library(PeakSegDisk);example(PeakSegFPOP_file)'
```

Then I run it from the mac command line via

```
docker exec -w /home/toby/R/PeakSegDisk test bash valgrind.sh
```

It reproduces the valgrind output I saw on CRAN:

```
PSFPOP> PeakSegFPOP_file(tmp, pstr)
==279== Syscall param write(buf) points to uninitialised byte(s)
==279==    at 0x4D13471: write (write.c:26)
==279==    by 0x7849D65: ??? (in /usr/lib/x86_64-linux-gnu/libstdc++.so.6.0.25)
==279==    by 0x7882AC1: std::basic_filebuf<char, std::char_traits<char> >::_M_convert_to_external(char*, long) (in /usr/lib/x86_64-linux-gnu/libstdc++.so.6.0.25)
==279==    by 0x7882E83: std::basic_filebuf<char, std::char_traits<char> >::overflow(int) (in /usr/lib/x86_64-linux-gnu/libstdc++.so.6.0.25)
==279==    by 0x7882C0D: std::basic_filebuf<char, std::char_traits<char> >::_M_terminate_output() (in /usr/lib/x86_64-linux-gnu/libstdc++.so.6.0.25)
==279==    by 0x7882D0A: std::basic_filebuf<char, std::char_traits<char> >::_M_seek(long, std::_Ios_Seekdir, __mbstate_t) (in /usr/lib/x86_64-linux-gnu/libstdc++.so.6.0.25)
==279==    by 0x7883164: std::basic_filebuf<char, std::char_traits<char> >::seekoff(long, std::_Ios_Seekdir, std::_Ios_Openmode) (in /usr/lib/x86_64-linux-gnu/libstdc++.so.6.0.25)
==279==    by 0x78A3F55: std::ostream::seekp(long, std::_Ios_Seekdir) (in /usr/lib/x86_64-linux-gnu/libstdc++.so.6.0.25)
==279==    by 0xCC649DF: seek_element (PeakSegFPOPLog.cpp:86)
==279==    by 0xCC649DF: write (PeakSegFPOPLog.cpp:126)
==279==    by 0xCC649DF: PeakSegFPOP_disk(char*, char*) (PeakSegFPOPLog.cpp:379)
==279==    by 0xCC69586: PeakSegFPOP_interface(char**, char**) (interface.cpp:14)
==279==    by 0x4937C9B: ??? (in /usr/lib/R/lib/libR.so)
==279==    by 0x496C0C5: ??? (in /usr/lib/R/lib/libR.so)
==279==  Address 0x9248f58 is 56 bytes inside a block of size 8,192 alloc'd
==279==    at 0x483650F: operator new[](unsigned long) (in /usr/lib/x86_64-linux-gnu/valgrind/vgpreload_memcheck-amd64-linux.so)
==279==    by 0x7882987: std::basic_filebuf<char, std::char_traits<char> >::_M_allocate_internal_buffer() (in /usr/lib/x86_64-linux-gnu/libstdc++.so.6.0.25)
==279==    by 0x7886821: std::basic_filebuf<char, std::char_traits<char> >::open(char const*, std::_Ios_Openmode) (in /usr/lib/x86_64-linux-gnu/libstdc++.so.6.0.25)
==279==    by 0xCC644AA: open (fstream:1076)
==279==    by 0xCC644AA: init (PeakSegFPOPLog.cpp:71)
==279==    by 0xCC644AA: PeakSegFPOP_disk(char*, char*) (PeakSegFPOPLog.cpp:236)
==279==    by 0xCC69586: PeakSegFPOP_interface(char**, char**) (interface.cpp:14)
==279==    by 0x4937C9B: ??? (in /usr/lib/R/lib/libR.so)
==279==    by 0x496C0C5: ??? (in /usr/lib/R/lib/libR.so)
==279==    by 0x497C16F: Rf_eval (in /usr/lib/R/lib/libR.so)
==279==    by 0x497DD9E: ??? (in /usr/lib/R/lib/libR.so)
==279==    by 0x497C326: Rf_eval (in /usr/lib/R/lib/libR.so)
==279==    by 0x4981F69: ??? (in /usr/lib/R/lib/libR.so)
==279==    by 0x496C0C5: ??? (in /usr/lib/R/lib/libR.so)
==279==  Uninitialised value was created by a heap allocation
==279==    at 0x4835DEF: operator new(unsigned long) (in /usr/lib/x86_64-linux-gnu/valgrind/vgpreload_memcheck-amd64-linux.so)
==279==    by 0xCC64718: allocate (new_allocator.h:111)
==279==    by 0xCC64718: allocate (alloc_traits.h:436)
==279==    by 0xCC64718: _M_get_node (stl_list.h:450)
==279==    by 0xCC64718: _M_create_node<double, double, double, double&, double&, int, double> (stl_list.h:642)
==279==    by 0xCC64718: _M_insert<double, double, double, double&, double&, int, double> (stl_list.h:1903)
==279==    by 0xCC64718: emplace_back<double, double, double, double&, double&, int, double> (stl_list.h:1235)
==279==    by 0xCC64718: PeakSegFPOP_disk(char*, char*) (PeakSegFPOPLog.cpp:256)
==279==    by 0xCC69586: PeakSegFPOP_interface(char**, char**) (interface.cpp:14)
==279==    by 0x4937C9B: ??? (in /usr/lib/R/lib/libR.so)
==279==    by 0x496C0C5: ??? (in /usr/lib/R/lib/libR.so)
==279==    by 0x497C16F: Rf_eval (in /usr/lib/R/lib/libR.so)
==279==    by 0x497DD9E: ??? (in /usr/lib/R/lib/libR.so)
==279==    by 0x497C326: Rf_eval (in /usr/lib/R/lib/libR.so)
==279==    by 0x4981F69: ??? (in /usr/lib/R/lib/libR.so)
==279==    by 0x496C0C5: ??? (in /usr/lib/R/lib/libR.so)
==279==    by 0x497C16F: Rf_eval (in /usr/lib/R/lib/libR.so)
==279==    by 0x497DD9E: ??? (in /usr/lib/R/lib/libR.so)
==279== 
```

So after a bit of interactive debugging I found the fix, which is
explained [on this SO
post](https://stackoverflow.com/questions/19364942/points-to-uninitialised-bytes-valgrind-errors). Essentially
when we are dealing with structs in C or classes in C++, we need to
initialize the whole memory block in order to avoid errors in
valgrind, i.e. need to use memset in the constructor below

```
PoissonLossPieceLog::PoissonLossPieceLog
(double li, double lo, double co, double m, double M, int i, double prev){
  memset(this, 0, sizeof(PoissonLossPieceLog));
  Rprintf("double=%d int=%d this=%d\n", 
    sizeof(double), sizeof(int), sizeof(PoissonLossPieceLog));
  Linear = li;
  Log = lo;
  Constant = co;
  min_log_mean = m;
  max_log_mean = M;
  data_i = i;
  prev_log_mean = prev;
}
```

This is pretty strange but the idea is that sizeof(x) is not always
equal to sizeof(x.y) + sizeof(x.z), e.g. the code above produces the
following output:

```
double=8 int=4 this=56
```

which means that there are 52 bytes which are used to store data and 4
bytes which are not (padding). 

If we omit the call to `memset` above, then the constructor leaves 4
bytes un-initialized. Normally that is not an issue with valgrind
because we refer to all members by name. But since in this code I am
serializing instances of this class to disk, the error comes from

```
memcpy(p, &(*it), sizeof(PoissonLossPieceLog));
```

which copies all bytes associated with the struct (including the four
un-initialized bytes).

Therefore another fix would be to edit the serialization code, to
explicitly mention all members of the class that should be
serialized. On the one hand that would make the code more complicated
(the fix above is only one line) but on the other hand it would make
it more efficient.
