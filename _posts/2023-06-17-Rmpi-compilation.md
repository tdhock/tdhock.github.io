---
layout: post
title: Installing Rmpi on the cluster
description: This package needs special treatment on compute nodes
---

For my upcoming NSF funded project about expanding the open-source
ecosystem around the R package data.table, I have created a reverse
dependency checking system that runs on NAU Monsoon every day. The
idea is that there are 1000+ packages which depend on functionality
from data.table, and so when data.table is updated, those packages
must be checked to make sure there are no new breakages as a result of
changes to data.table. 

For example, one of those package which depends on data.table is
batchtools, which also depends on Rmpi (indirectly by Suggesting
doMPI). So to check batchtools, we need to first install Rmpi. In our
reverse dependency checking system, we need to do this on a Monsoon
compute node, via the code below.

```
th798@rain:~$ sbatch --wrap="module load openmpi;/projects/genomic-ml/R/R-4.3.1/bin/R --no-save -e 'install.packages(\"Rmpi\",configure.args=\"--with-mpi=/packages/openmpi/4.1.4\")'"
Submitted batch job 66811907
th798@rain:~$ cat slurm-66811907.out 

R version 4.3.1 (2023-06-16) -- "Beagle Scouts"
Copyright (C) 2023 The R Foundation for Statistical Computing
Platform: x86_64-pc-linux-gnu (64-bit)

R is free software and comes with ABSOLUTELY NO WARRANTY.
You are welcome to redistribute it under certain conditions.
Type 'license()' or 'licence()' for distribution details.

R is a collaborative project with many contributors.
Type 'contributors()' for more information and
'citation()' on how to cite R or R packages in publications.

Type 'demo()' for some demos, 'help()' for on-line help, or
'help.start()' for an HTML browser interface to help.
Type 'q()' to quit R.

> install.packages("Rmpi",configure.args="--with-mpi=/packages/openmpi/4.1.4")
trying URL 'http://cloud.r-project.org/src/contrib/Rmpi_0.7-1.tar.gz'
Content type 'application/x-gzip' length 106286 bytes (103 KB)
==================================================
downloaded 103 KB

* installing *source* package 'Rmpi' ...
** package 'Rmpi' successfully unpacked and MD5 sums checked
** using staged installation
checking for gcc... gcc
checking whether the C compiler works... yes
checking for C compiler default output file name... a.out
checking for suffix of executables... 
checking whether we are cross compiling... no
checking for suffix of object files... o
checking whether we are using the GNU C compiler... yes
checking whether gcc accepts -g... yes
checking for gcc option to accept ISO C89... none needed
Trying to find mpi.h ...
Found in /packages/openmpi/4.1.4/include
Trying to find libmpi.so or libmpich.a ...
Found libmpi in /packages/openmpi/4.1.4/lib
checking for orted... yes
configure: creating ./config.status
config.status: creating src/Makevars
** libs
using C compiler: 'gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-15)'
gcc -I"/home/th798/R/R-4.3.1/include" -DNDEBUG -DPACKAGE_NAME=\"\" -DPACKAGE_TARNAME=\"\" -DPACKAGE_VERSION=\"\" -DPACKAGE_STRING=\"\" -DPACKAGE_BUGREPORT=\"\" -DPACKAGE_URL=\"\" -I/packages/openmpi/4.1.4/include  -DMPI2 -DOPENMPI  -I/home/th798/.conda/envs/emacs1/include -I/home/th798/include    -fpic  -g -O2  -c Rmpi.c -o Rmpi.o
gcc -I"/home/th798/R/R-4.3.1/include" -DNDEBUG -DPACKAGE_NAME=\"\" -DPACKAGE_TARNAME=\"\" -DPACKAGE_VERSION=\"\" -DPACKAGE_STRING=\"\" -DPACKAGE_BUGREPORT=\"\" -DPACKAGE_URL=\"\" -I/packages/openmpi/4.1.4/include  -DMPI2 -DOPENMPI  -I/home/th798/.conda/envs/emacs1/include -I/home/th798/include    -fpic  -g -O2  -c conversion.c -o conversion.o
gcc -I"/home/th798/R/R-4.3.1/include" -DNDEBUG -DPACKAGE_NAME=\"\" -DPACKAGE_TARNAME=\"\" -DPACKAGE_VERSION=\"\" -DPACKAGE_STRING=\"\" -DPACKAGE_BUGREPORT=\"\" -DPACKAGE_URL=\"\" -I/packages/openmpi/4.1.4/include  -DMPI2 -DOPENMPI  -I/home/th798/.conda/envs/emacs1/include -I/home/th798/include    -fpic  -g -O2  -c internal.c -o internal.o
gcc -shared -L/home/th798/.conda/envs/emacs1/lib -Wl,-rpath=/home/th798/.conda/envs/emacs1/lib -L/home/th798/lib -Wl,-rpath=/home/th798/lib -L/home/th798/lib64 -Wl,-rpath=/home/th798/lib64 -o Rmpi.so Rmpi.o conversion.o internal.o -L/packages/openmpi/4.1.4/lib -lmpi
installing to /projects/genomic-ml/R/R-4.3.1/library/00LOCK-Rmpi/00new/Rmpi/libs
** R
** demo
** inst
** byte-compile and prepare package for lazy loading
** help
*** installing help indices
** building package indices
** testing if installed package can be loaded from temporary location
** checking absolute paths in shared objects and dynamic libraries
** testing if installed package can be loaded from final location
** testing if installed package keeps a record of temporary installation path
* DONE (Rmpi)

The downloaded source packages are in
	'/tmp/th798/66811907/Rtmpn2BAVb/downloaded_packages'
> 
> 
```

It turns out that there are three important components to the above command.

### sbatch rather than srun

Above we used sbatch (asynchronous, works), below we use srun
(synchonous, fails).

```
th798@rain:~$ srun bash -c "module load openmpi;/projects/genomic-ml/R/R-4.3.1/bin/R --no-save -e 'install.packages(\"Rmpi\",configure.args=\"--with-mpi=/packages/openmpi/4.1.4\")'"

R version 4.3.1 (2023-06-16) -- "Beagle Scouts"
Copyright (C) 2023 The R Foundation for Statistical Computing
Platform: x86_64-pc-linux-gnu (64-bit)

R is free software and comes with ABSOLUTELY NO WARRANTY.
You are welcome to redistribute it under certain conditions.
Type 'license()' or 'licence()' for distribution details.

R is a collaborative project with many contributors.
Type 'contributors()' for more information and
'citation()' on how to cite R or R packages in publications.

Type 'demo()' for some demos, 'help()' for on-line help, or
'help.start()' for an HTML browser interface to help.
Type 'q()' to quit R.

> install.packages("Rmpi",configure.args="--with-mpi=/packages/openmpi/4.1.4")
trying URL 'http://cloud.r-project.org/src/contrib/Rmpi_0.7-1.tar.gz'
Content type 'application/x-gzip' length 106286 bytes (103 KB)
==================================================
downloaded 103 KB

* installing *source* package 'Rmpi' ...
** package 'Rmpi' successfully unpacked and MD5 sums checked
** using staged installation
checking for gcc... gcc
checking whether the C compiler works... yes
checking for C compiler default output file name... a.out
checking for suffix of executables... 
checking whether we are cross compiling... no
checking for suffix of object files... o
checking whether we are using the GNU C compiler... yes
checking whether gcc accepts -g... yes
checking for gcc option to accept ISO C89... none needed
Trying to find mpi.h ...
Found in /packages/openmpi/4.1.4/include
Trying to find libmpi.so or libmpich.a ...
Found libmpi in /packages/openmpi/4.1.4/lib
checking for orted... yes
configure: creating ./config.status
config.status: creating src/Makevars
** libs
using C compiler: 'gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-15)'
gcc -I"/home/th798/R/R-4.3.1/include" -DNDEBUG -DPACKAGE_NAME=\"\" -DPACKAGE_TARNAME=\"\" -DPACKAGE_VERSION=\"\" -DPACKAGE_STRING=\"\" -DPACKAGE_BUGREPORT=\"\" -DPACKAGE_URL=\"\" -I/packages/openmpi/4.1.4/include  -DMPI2 -DOPENMPI  -I/home/th798/.conda/envs/emacs1/include -I/home/th798/include    -fpic  -g -O2  -c Rmpi.c -o Rmpi.o
gcc -I"/home/th798/R/R-4.3.1/include" -DNDEBUG -DPACKAGE_NAME=\"\" -DPACKAGE_TARNAME=\"\" -DPACKAGE_VERSION=\"\" -DPACKAGE_STRING=\"\" -DPACKAGE_BUGREPORT=\"\" -DPACKAGE_URL=\"\" -I/packages/openmpi/4.1.4/include  -DMPI2 -DOPENMPI  -I/home/th798/.conda/envs/emacs1/include -I/home/th798/include    -fpic  -g -O2  -c conversion.c -o conversion.o
gcc -I"/home/th798/R/R-4.3.1/include" -DNDEBUG -DPACKAGE_NAME=\"\" -DPACKAGE_TARNAME=\"\" -DPACKAGE_VERSION=\"\" -DPACKAGE_STRING=\"\" -DPACKAGE_BUGREPORT=\"\" -DPACKAGE_URL=\"\" -I/packages/openmpi/4.1.4/include  -DMPI2 -DOPENMPI  -I/home/th798/.conda/envs/emacs1/include -I/home/th798/include    -fpic  -g -O2  -c internal.c -o internal.o
gcc -shared -L/home/th798/.conda/envs/emacs1/lib -Wl,-rpath=/home/th798/.conda/envs/emacs1/lib -L/home/th798/lib -Wl,-rpath=/home/th798/lib -L/home/th798/lib64 -Wl,-rpath=/home/th798/lib64 -o Rmpi.so Rmpi.o conversion.o internal.o -L/packages/openmpi/4.1.4/lib -lmpi
installing to /projects/genomic-ml/R/R-4.3.1/library/00LOCK-Rmpi/00new/Rmpi/libs
** R
** demo
** inst
** byte-compile and prepare package for lazy loading
** help
*** installing help indices
** building package indices
** testing if installed package can be loaded from temporary location
** checking absolute paths in shared objects and dynamic libraries
** testing if installed package can be loaded from final location
--------------------------------------------------------------------------
PMI2_Init failed to intialize.  Return code: 14
--------------------------------------------------------------------------
--------------------------------------------------------------------------
The application appears to have been direct launched using "srun",
but OMPI was not built with SLURM's PMI support and therefore cannot
execute. There are several options for building PMI support under
SLURM, depending upon the SLURM version you are using:

  version 16.05 or later: you can use SLURM's PMIx support. This
  requires that you configure and build SLURM --with-pmix.

  Versions earlier than 16.05: you must use either SLURM's PMI-1 or
  PMI-2 support. SLURM builds PMI-1 by default, or you can manually
  install PMI-2. You must then build Open MPI using --with-pmi pointing
  to the SLURM PMI library location.

Please configure as appropriate and try again.
--------------------------------------------------------------------------
*** An error occurred in MPI_Init
*** on a NULL communicator
*** MPI_ERRORS_ARE_FATAL (processes in this communicator will now abort,
***    and potentially your MPI job)
[cn69:2289703] Local abort before MPI_INIT completed completed successfully, but am not able to aggregate error messages, and not able to guarantee that all other processes were killed!
ERROR: loading failed
* removing '/projects/genomic-ml/R/R-4.3.1/library/Rmpi'
* restoring previous '/projects/genomic-ml/R/R-4.3.1/library/Rmpi'
> 
> 

The downloaded source packages are in
	'/tmp/th798/66811914/RtmpuUcHoi/downloaded_packages'
Warning message:
In install.packages("Rmpi", configure.args = "--with-mpi=/packages/openmpi/4.1.4") :
  installation of package 'Rmpi' had non-zero exit status
```

The above output indicates that compilation works, but loading fails,
due to some startup code that detects being in srun, but not using MPI
which was configured for that.

### `--with-mpi` is required

Above we used `configure.args` argument of `install.packages` to tell
R the path of the MPI library (works), whereas below we omit that
argument (fails).

```
th798@rain:~$ sbatch --wrap="module load openmpi;/projects/genomic-ml/R/R-4.3.1/bin/R --no-save -e 'install.packages(\"Rmpi\")'"
Submitted batch job 66811908
th798@rain:~$ cat slurm-66811908.out 

R version 4.3.1 (2023-06-16) -- "Beagle Scouts"
Copyright (C) 2023 The R Foundation for Statistical Computing
Platform: x86_64-pc-linux-gnu (64-bit)

R is free software and comes with ABSOLUTELY NO WARRANTY.
You are welcome to redistribute it under certain conditions.
Type 'license()' or 'licence()' for distribution details.

R is a collaborative project with many contributors.
Type 'contributors()' for more information and
'citation()' on how to cite R or R packages in publications.

Type 'demo()' for some demos, 'help()' for on-line help, or
'help.start()' for an HTML browser interface to help.
Type 'q()' to quit R.

> install.packages("Rmpi")
trying URL 'http://cloud.r-project.org/src/contrib/Rmpi_0.7-1.tar.gz'
Content type 'application/x-gzip' length 106286 bytes (103 KB)
==================================================
downloaded 103 KB

* installing *source* package 'Rmpi' ...
** package 'Rmpi' successfully unpacked and MD5 sums checked
** using staged installation
checking for gcc... gcc
checking whether the C compiler works... yes
checking for C compiler default output file name... a.out
checking for suffix of executables... 
checking whether we are cross compiling... no
checking for suffix of object files... o
checking whether we are using the GNU C compiler... yes
checking whether gcc accepts -g... yes
checking for gcc option to accept ISO C89... none needed
checking for pkg-config... /usr/bin/pkg-config
checking if pkg-config knows about OpenMPI... no
checking how to run the C preprocessor... gcc -E
checking for grep that handles long lines and -e... /usr/bin/grep
checking for egrep... /usr/bin/grep -E
checking for ANSI C header files... yes
checking for sys/types.h... yes
checking for sys/stat.h... yes
checking for stdlib.h... yes
checking for string.h... yes
checking for memory.h... yes
checking for strings.h... yes
checking for inttypes.h... yes
checking for stdint.h... yes
checking for unistd.h... yes
checking mpi.h usability... no
checking mpi.h presence... no
checking for mpi.h... no
configure: error: "Cannot find mpi.h header file"
ERROR: configuration failed for package 'Rmpi'
* removing '/projects/genomic-ml/R/R-4.3.1/library/Rmpi'
* restoring previous '/projects/genomic-ml/R/R-4.3.1/library/Rmpi'

The downloaded source packages are in
	'/tmp/th798/66811908/RtmpdtqGs6/downloaded_packages'
Warning message:
In install.packages("Rmpi") :
  installation of package 'Rmpi' had non-zero exit status
> 
> 
```

The above output indicates that R could not find the MPI header files.

### module load openmpi is required

```
th798@rain:~$ sbatch --wrap="/projects/genomic-ml/R/R-4.3.1/bin/R --no-save -e 'install.packages(\"Rmpi\",configure.args=\"--with-mpi=/packages/openmpi/4.1.4\")'"
Submitted batch job 66811909
th798@rain:~$ cat slurm-66811909.out 

R version 4.3.1 (2023-06-16) -- "Beagle Scouts"
Copyright (C) 2023 The R Foundation for Statistical Computing
Platform: x86_64-pc-linux-gnu (64-bit)

R is free software and comes with ABSOLUTELY NO WARRANTY.
You are welcome to redistribute it under certain conditions.
Type 'license()' or 'licence()' for distribution details.

R is a collaborative project with many contributors.
Type 'contributors()' for more information and
'citation()' on how to cite R or R packages in publications.

Type 'demo()' for some demos, 'help()' for on-line help, or
'help.start()' for an HTML browser interface to help.
Type 'q()' to quit R.

> install.packages("Rmpi",configure.args="--with-mpi=/packages/openmpi/4.1.4")
trying URL 'http://cloud.r-project.org/src/contrib/Rmpi_0.7-1.tar.gz'
Content type 'application/x-gzip' length 106286 bytes (103 KB)
==================================================
downloaded 103 KB

* installing *source* package 'Rmpi' ...
** package 'Rmpi' successfully unpacked and MD5 sums checked
** using staged installation
checking for gcc... gcc
checking whether the C compiler works... yes
checking for C compiler default output file name... a.out
checking for suffix of executables... 
checking whether we are cross compiling... no
checking for suffix of object files... o
checking whether we are using the GNU C compiler... yes
checking whether gcc accepts -g... yes
checking for gcc option to accept ISO C89... none needed
Trying to find mpi.h ...
Found in /packages/openmpi/4.1.4/include
Trying to find libmpi.so or libmpich.a ...
Found libmpi in /packages/openmpi/4.1.4/lib
checking for orted... no
configure: error: Cannot find orted. Rmpi needs orted to run.
ERROR: configuration failed for package 'Rmpi'
* removing '/projects/genomic-ml/R/R-4.3.1/library/Rmpi'
* restoring previous '/projects/genomic-ml/R/R-4.3.1/library/Rmpi'

The downloaded source packages are in
	'/tmp/th798/66811909/Rtmpv78KGc/downloaded_packages'
Warning message:
In install.packages("Rmpi", configure.args = "--with-mpi=/packages/openmpi/4.1.4") :
  installation of package 'Rmpi' had non-zero exit status
> 
> 
```

The above output indicates that R could find MPI, but could not find
one of its dependencies (orted).

### Conclusion

To install Rmpi on a NAU Monsoon compute node, we must

* use sbatch rather than srun,
* use `configure.args` argument of `install.packages` to tell R the
  path of MPI,
* and use `module load openmpi` to edit the path so that other C
  libraries can be found.

Therefore we do this in
[params.R](https://github.com/tdhock/data.table-revdeps/blob/ad316777b20fad7bcea1d858d17763ca0804cac9/params.R#L142),
which should be run using sbatch.
