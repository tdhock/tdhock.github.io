---
layout: post
title: R torch installation
description: On Alliance Canada super-computers
---

The purpose of this post is to explain how to install the torch R package on Alliance Canada super-computers.

# Errors

## torch source package with cuda on rorqual

### my ticket

I am trying to install torch in R on rorqual.
I expected that the following should work

```
module load r cuda/12.6
R -e "torch::install_torch()"
```

but I got an erreur, unable to load lantern.
I did ldd on the lantern shared library, and I see

```
        libcudart.so.12 => not found
```

which I believe is the problem.
Is this installed on rorqual?
Where?

### Response from Charles Coulombe:

Concernant `libcudart.so.12 => not found`, il faut corriger les binaires qui proviennent de l'extérieur (des systèmes).
Ainsi, lorsque torch s'installe, il télécharge libtorch et lantern qui n'ont pas été compilés sur les systèmes et ils ne savent pas nécessairement où trouver les libraires.
Vous pouvez ainsi [patcher](https://docs.alliancecan.ca/wiki/Installing_software_in_your_home_directory#Installing_binary_packages) liblantern.so:

```
cd $R_LIBS
module load r/4.5 cuda/12.6 cudnn
setrpaths.sh --path ./torch/lib/liblantern.so --add_path $EBROOTCUDACORE/lib --any_interpreter
```

et ensuite, cela fonctionne pour mon installation de torch et lantern:

```
$ R -e 'library(torch); torch::torch_tensor(1);'
> library(torch); torch::torch_tensor(1);
torch_tensor
 1
[ CPUFloatType{1} ]
```

### My code

First install torch source R package and download binaries.

```r
install.packages("torch")
torch::install_torch()
```

Then we see below that libcudart is not found.

```
[thocking@rorqual2 4.5]$ ldd torch/lib/liblantern.so
ldd: warning: you do not have execution permission for `torch/lib/liblantern.so'
        linux-vdso.so.1 (0x00007ffd1492a000)
        libc10.so => /home/thocking/R/x86_64-pc-linux-gnu-library/4.5/torch/lib/libc10.so (0x00007faff402c000)
        libc10_cuda.so => /home/thocking/R/x86_64-pc-linux-gnu-library/4.5/torch/lib/libc10_cuda.so (0x00007faff3ecc000)
        libtorch_cpu.so => /home/thocking/R/x86_64-pc-linux-gnu-library/4.5/torch/lib/libtorch_cpu.so (0x00007fafdb3e5000)
        libtorch_cuda.so => /home/thocking/R/x86_64-pc-linux-gnu-library/4.5/torch/lib/libtorch_cuda.so (0x00007faf77101000)
        libcudart.so.12 => not found
        libtorch.so => /home/thocking/R/x86_64-pc-linux-gnu-library/4.5/torch/lib/libtorch.so (0x00007faf770cd000)
        libstdc++.so.6 => /cvmfs/soft.computecanada.ca/gentoo/2023/x86-64-v3/usr/lib/gcc/x86_64-pc-linux-gnu/14/libstdc++.so.6 (0x00007faf76e00000)
        libm.so.6 => /cvmfs/soft.computecanada.ca/gentoo/2023/x86-64-v3/usr/lib64/libm.so.6 (0x00007faf76d28000)
        libgcc_s.so.1 => /cvmfs/soft.computecanada.ca/gentoo/2023/x86-64-v3/usr/lib/gcc/x86_64-pc-linux-gnu/14/libgcc_s.so.1 (0x00007faf770a0000)
        libc.so.6 => /cvmfs/soft.computecanada.ca/gentoo/2023/x86-64-v3/usr/lib64/libc.so.6 (0x00007faf76b53000)
        /cvmfs/soft.computecanada.ca/gentoo/2023/x86-64-v3/lib64/ld-linux-x86-64.so.2 (0x00007faff5413000)
        libdl.so.2 => /cvmfs/soft.computecanada.ca/gentoo/2023/x86-64-v3/usr/lib64/libdl.so.2 (0x00007faf77099000)
        libpthread.so.0 => /cvmfs/soft.computecanada.ca/gentoo/2023/x86-64-v3/usr/lib64/libpthread.so.0 (0x00007faf77094000)
        librt.so.1 => /cvmfs/soft.computecanada.ca/gentoo/2023/x86-64-v3/usr/lib64/librt.so.1 (0x00007faf7708f000)
        libgomp-98b21ff3.so.1 => /home/thocking/R/x86_64-pc-linux-gnu-library/4.5/torch/lib/libgomp-98b21ff3.so.1 (0x00007faf76b0c000)
        libcudart-09529672.so.12 => /home/thocking/R/x86_64-pc-linux-gnu-library/4.5/torch/lib/libcudart-09529672.so.12 (0x00007faf76800000)
        libcublas-d9343511.so.12 => /home/thocking/R/x86_64-pc-linux-gnu-library/4.5/torch/lib/libcublas-d9343511.so.12 (0x00007faf6fe00000)
        libcublasLt-a4ddaed1.so.12 => /home/thocking/R/x86_64-pc-linux-gnu-library/4.5/torch/lib/libcublasLt-a4ddaed1.so.12 (0x00007faf4e400000)
        libcudnn.so.9 => /home/thocking/R/x86_64-pc-linux-gnu-library/4.5/torch/lib/libcudnn.so.9 (0x00007faf4e000000)
```

Then we fix it via the code below.

```
[thocking@rorqual2 4.5]$ setrpaths.sh --path ./torch/lib/liblantern.so --add_path $EBROOTCUDACORE/lib --any_interpreter
ldd: warning: you do not have execution permission for `./torch/lib/liblantern.so'
[thocking@rorqual2 4.5]$ R -e "torch::torch_tensor(pi)"

R version 4.5.0 (2025-04-11) -- "How About a Twenty-Six"
Copyright (C) 2025 The R Foundation for Statistical Computing
Platform: x86_64-pc-linux-gnu

R is free software and comes with ABSOLUTELY NO WARRANTY.
You are welcome to redistribute it under certain conditions.
Type 'license()' or 'licence()' for distribution details.

R is a collaborative project with many contributors.
Type 'contributors()' for more information and
'citation()' on how to cite R or R packages in publications.

Type 'demo()' for some demos, 'help()' for on-line help, or
'help.start()' for an HTML browser interface to help.
Type 'q()' to quit R.

Loading required namespace: data.table
> torch::torch_tensor(pi)
torch_tensor
 3.1416
[ CPUFloatType{1} ]
>
[thocking@rorqual2 4.5]$ ldd torch/lib/liblantern.so
ldd: warning: you do not have execution permission for `torch/lib/liblantern.so'
        linux-vdso.so.1 (0x00007f8747345000)
        libc10.so => /home/thocking/R/x86_64-pc-linux-gnu-library/4.5/torch/lib/libc10.so (0x00007f8745abf000)
        libc10_cuda.so => /home/thocking/R/x86_64-pc-linux-gnu-library/4.5/torch/lib/libc10_cuda.so (0x00007f874595f000)
        libtorch_cpu.so => /home/thocking/R/x86_64-pc-linux-gnu-library/4.5/torch/lib/libtorch_cpu.so (0x00007f872ce78000)
        libtorch_cuda.so => /home/thocking/R/x86_64-pc-linux-gnu-library/4.5/torch/lib/libtorch_cuda.so (0x00007f86c8b94000)
        libcudart.so.12 => /cvmfs/soft.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/cudacore/12.6.2/lib/libcudart.so.12 (0x00007f86c88000\
00)
        libtorch.so => /home/thocking/R/x86_64-pc-linux-gnu-library/4.5/torch/lib/libtorch.so (0x00007f86c8b8d000)
        libstdc++.so.6 => /cvmfs/soft.computecanada.ca/gentoo/2023/x86-64-v3/usr/lib/gcc/x86_64-pc-linux-gnu/14/libstdc++.so.6 (0x00007f86c8400000)
        libm.so.6 => /cvmfs/soft.computecanada.ca/gentoo/2023/x86-64-v3/usr/lib64/libm.so.6 (0x00007f86c8728000)
        libgcc_s.so.1 => /cvmfs/soft.computecanada.ca/gentoo/2023/x86-64-v3/usr/lib/gcc/x86_64-pc-linux-gnu/14/libgcc_s.so.1 (0x00007f86c8b33000)
        libc.so.6 => /cvmfs/soft.computecanada.ca/gentoo/2023/x86-64-v3/usr/lib64/libc.so.6 (0x00007f86c822b000)
        /cvmfs/soft.computecanada.ca/gentoo/2023/x86-64-v3/lib64/ld-linux-x86-64.so.2 (0x00007f8747347000)
        libdl.so.2 => /cvmfs/soft.computecanada.ca/gentoo/2023/x86-64-v3/usr/lib64/libdl.so.2 (0x00007f86c8b2c000)
        libpthread.so.0 => /cvmfs/soft.computecanada.ca/gentoo/2023/x86-64-v3/usr/lib64/libpthread.so.0 (0x00007f86c8b27000)
        librt.so.1 => /cvmfs/soft.computecanada.ca/gentoo/2023/x86-64-v3/usr/lib64/librt.so.1 (0x00007f86c8b22000)
        libgomp-98b21ff3.so.1 => /home/thocking/R/x86_64-pc-linux-gnu-library/4.5/torch/lib/libgomp-98b21ff3.so.1 (0x00007f86c8adb000)
        libcudart-09529672.so.12 => /home/thocking/R/x86_64-pc-linux-gnu-library/4.5/torch/lib/libcudart-09529672.so.12 (0x00007f86c7e00000)
        libcublas-d9343511.so.12 => /home/thocking/R/x86_64-pc-linux-gnu-library/4.5/torch/lib/libcublas-d9343511.so.12 (0x00007f86c1400000)
        libcublasLt-a4ddaed1.so.12 => /home/thocking/R/x86_64-pc-linux-gnu-library/4.5/torch/lib/libcublasLt-a4ddaed1.so.12 (0x00007f869fa00000)
        libcudnn.so.9 => /home/thocking/R/x86_64-pc-linux-gnu-library/4.5/torch/lib/libcudnn.so.9 (0x00007f869f600000)
```

### R 4.4, torch cuda on class cluster

My Large-Scale ML class will use a virtual cluster.
Installing torch on it works the same as on rorqual!

```
[tdhock@login1 ~]$ module load r/4.4 cuda/12.6 cudnn

The following have been reloaded with a version change:
  1) r/4.5.0 => r/4.4.0

[tdhock@login1 ~]$ TORCH_INSTALL_DEBUG=1 R -e "install.packages('torch')"
> install.packages('torch')
Installing package into ‘/project/60004/tdhock/R/x86_64-pc-linux-gnu-library/4.4’
trying URL 'https://cloud.r-project.org/src/contrib/torch_0.16.3.tar.gz'
...
* installing *source* package ‘torch’ ...
** package ‘torch’ successfully unpacked and MD5 sums checked
** using staged installation
** libs
using C++ compiler: ‘g++ (Gentoo 12.3.1_p20230526 p2) 12.3.1 20230526’
*** Skip building lantern.
...
* DONE (torch)

[tdhock@login1 ~]$ TORCH_INSTALL_DEBUG=1 R -e "torch::install_torch()"
> torch::install_torch()
`CUDA_HOME`=/cvmfs/soft.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/cudacore/12.6.2 is specified.
Could not find a CUDA version in
/cvmfs/soft.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/cudacore/12.6.2/version.txt.
Found CUDA version 12.6.
Installation kind will be "cu126".
Architecture is "x86_64"
Could not find the SHA of the commit that installed the package.
Lantern will be downloaded from the following URL:
`CUDA_HOME`=/cvmfs/soft.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/cudacore/12.6.2 is specified.
Could not find a CUDA version in
/cvmfs/soft.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/cudacore/12.6.2/version.txt.
Found CUDA version 12.6.
Installation kind will be "cu126".
LibTorch will be downloaded from:
We are now proceeding to download and installing lantern and torch.
trying URL 'https://download.pytorch.org/libtorch/cu126/libtorch-cxx11-abi-shared-with-deps-2.7.1%2Bcu126.zip'
Content type 'application/zip' length 2688021042 bytes (2563.5 MB)
==================================================
downloaded 2563.5 MB

We are now proceeding to download and installing lantern and torch.
trying URL 'https://torch-cdn.mlverse.org/binaries/refs/heads/cran/v0.16.3/latest/lantern-0.16.3+cu126+x86_64-Linux.zip'
Content type 'application/zip' length 6082324 bytes (5.8 MB)
==================================================
downloaded 5.8 MB

[tdhock@login1 ~]$ R -e "torch::torch_tensor(1)"
> torch::torch_tensor(1)
Torch libraries are installed but loading them was unsuccessful.
Torch libraries are installed but loading them was unsuccessful.
Error: Lantern is not loaded. Please use `install_torch()` to install additional dependencies.
Execution halted

[tdhock@login1 ~]$ cd R/x86_64-pc-linux-gnu-library/4.4/

[tdhock@login1 4.4]$ ldd torch/lib/liblantern.so
ldd: warning: you do not have execution permission for `torch/lib/liblantern.so'
        libcudart.so.12 => not found

[tdhock@login1 4.4]$ setrpaths.sh --path ./torch/lib/liblantern.so --add_path $EBROOTCUDACORE/lib --any_interpreter
ldd: warning: you do not have execution permission for `./torch/lib/liblantern.so'
[tdhock@login1 4.4]$ ldd torch/lib/liblantern.so
ldd: warning: you do not have execution permission for `torch/lib/liblantern.so'
        libcudart.so.12 => /cvmfs/soft.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/cudacore/12.6.2/lib/libcudart.so.12 (0x00007f86a5400000)

[tdhock@login1 4.4]$ R -e "torch::torch_tensor(1)"
...
> torch::torch_tensor(1)
torch_tensor
 1
[ CPUFloatType{1} ]
```

then in jupyter Rstudio (did not ask for GPU) I get

```r
> torch::torch_tensor(3)
torch_tensor
 3
[ CPUFloatType{1} ]
> ten=torch::torch_tensor(3)
> ten$cuda()
Error: CUDA error: CUDA driver version is insufficient for CUDA runtime version
CUDA kernel errors might be asynchronously reported at some other API call, so the stacktrace below might be incorrect.
For debugging consider passing CUDA_LAUNCH_BLOCKING=1
Device-side assertions were explicitly omitted for this error check; the error probably arose while initializing the DSA handlers.
Exception raised from c10_cuda_check_implementation at /pytorch/c10/cuda/CUDAException.cpp:43 (most recent call first):
frame #0: c10::Error::Error(c10::SourceLocation, std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >) + 0xb0 (0x14c63440dde0 in /project/60004/tdhock/R/x86_64-pc-linux-gnu-library/4.4/torch/lib/libc10.so)
frame #1: c10::detail::torchCheckFail(char const*, char const*, unsigned int, std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > const&) + 0xfa (0x14c63439b46e in /project/60004/tdhock/R/x86_64-pc-linux-gnu-library/4.4/torch/lib/libc
```

then in jupyter Rstudio (asked for GPU) I get

```
[tdhock@nodegpupool1 ~]$ R -e 'torch::torch_tensor(5)$cuda()'
> torch::torch_tensor(5)$cuda()

 *** caught illegal operation ***
address 0x1465c533eb1a, cause 'illegal operand'

Traceback:
 1: ps::ps_handle()
 2: fun(libname, pkgname)
 3: doTryCatch(return(expr), name, parentenv, handler)
 4: tryCatchOne(expr, names, parentenv, handlers[[1L]])
 5: tryCatchList(expr, classes, parentenv, handlers)
 6: tryCatch(fun(libname, pkgname), error = identity)
 7: runHook(".onLoad", env, package.lib, package)
 8: loadNamespace(j <- i[[1L]], c(lib.loc, .libPaths()), versionCheck = vI[[j]])
 9: asNamespace(ns)
10: namespaceImportFrom(ns, loadNamespace(j <- i[[1L]], c(lib.loc,     .libPaths()), versionCheck = vI[[j]]), i[[2L]], from = package)
11: loadNamespace(j <- i[[1L]], c(lib.loc, .libPaths()), versionCheck = vI[[j]])
12: asNamespace(ns)
13: namespaceImportFrom(ns, loadNamespace(j <- i[[1L]], c(lib.loc,     .libPaths()), versionCheck = vI[[j]]), i[[2L]], from = package)
14: loadNamespace(x)
An irrecoverable exception occurred. R is aborting now ...
Illegal instruction (core dumped)
```

On rorqual login node I get a different error below

```
[thocking@rorqual3 ~]$ R -e 'torch::torch_tensor(5)$cuda()'
> torch::torch_tensor(5)$cuda()
Error: CUDA error: no CUDA-capable device is detected
CUDA kernel errors might be asynchronously reported at some other API call, so the stacktrace below might be incorrect.
For debugging consider passing CUDA_LAUNCH_BLOCKING=1
Device-side assertions were explicitly omitted for this error check; the error probably arose while initializing the DSA handlers.
Exception raised from c10_cuda_check_implementation at /pytorch/c10/cuda/CUDAException.cpp:43 (most recent call first):
frame #0: c10::Error::Error(c10::SourceLocation, std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >) + 0xb0 (0x7f110edd6de0 in /home/thocking/R/x86_64-pc-linux-gnu-library/4.5/torch/lib/libc10.so)
frame #1: c10::detail::torchCheckFail(char const*, char const*, unsigned int, std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > const&) + 0xfa (0x7f110ed6446e in /home/thocking/R/x86_64-pc-linux-gnu-library/4.5/torch/lib/libc10.so)
frame #2: c10::cuda::c10_cuda_che
Execution halted
```

The error goes away on a GPU compute node below

```
[thocking@rorqual3 ~]$ srun -t 1:00:00 --mem=1GB --cpus-per-task=1 --gpus-per-node=h100_10gb:1 --pty bash
srun: NOTE: Your memory request of 1024.0M was likely submitted as 1.0G. Please note that Slurm interprets memory requests denominated in G as multiples of 1024M, not 1000M.
srun: job 5444141 queued and waiting for resources
srun: job 5444141 has been allocated resources

thocking@rg12502 ~ $  R -e 'torch::torch_tensor(5)$cuda()'
> torch::torch_tensor(5)$cuda()
torch_tensor
 5
[ CUDAFloatType{1} ]
```

on 

### torch pre-built binary package with cuda on rorqual

I tried [installing from pre-built binaries](https://torch.mlverse.org/docs/dev/articles/installation#pre-built).

[I posted an issue about lantern not loading](https://github.com/mlverse/torch/issues/1401).
lantern links to librt which links to libpthread, which seems to be an incompatible version, 

```
R/x86_64-pc-linux-gnu-library/4.5/torch/lib/librt.so.1: 
 /cvmfs/soft.computecanada.ca/gentoo/2023/x86-64-v3/usr/lib64/libpthread.so.0: 
 version `GLIBC_PRIVATE' not found 
 (required by R/x86_64-pc-linux-gnu-library/4.5/torch/lib/librt.so.1)
```

A comment said a work-around is to rename the `librt.so.1` file to `librt.so.1.bak`.
That did not work for me.
It gave me a new ldd warning,

```
[thocking@rorqual4 lib]$ ldd liblantern.so
./liblantern.so: 
 /home/thocking/R/x86_64-pc-linux-gnu-library/4.5/torch/lib/./libc.so.6: 
 version `GLIBC_ABI_DT_RELR' not found 
 (required by /cvmfs/soft.computecanada.ca/gentoo/2023/x86-64-v3/usr/lib64/librt.so.1)
```

