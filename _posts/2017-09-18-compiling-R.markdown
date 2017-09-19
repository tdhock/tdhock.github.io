Recently I needed to install a recent version of R on a system where I
have a non-root account. It does not provide any of the development
libraries that R requires, so I had to compile them all myself. Here I
document a few things that I learned in the process. The command lines
that I used are documented
[in my dotfiles repo](https://github.com/tdhock/dotfiles/blob/master/install-r-devel.sh).

Basically for each of the libraries that R needs (zlib, curl, bzip2,
xz, pcre) I had to download the source code and install it to my home
directory. In most cases this means doing something pretty standard
like

```
cd ~/R
wget https://tukaani.org/xz/xz-5.2.3.tar.gz
tar xf xz-5.2.3.tar.gz
cd xz-5.2.3
./configure --prefix=$HOME
make
make install
```

However in two cases there was something non-standard that I had to
do. The first case is bzip2 which does not have a configure
script. Instead it just provides a Makefile. So I compiled it using
make and make install, and that was fine. But then when I compiled R I
got the following error:

```
/usr/bin/ld: /home/thocking/lib/libbz2.a(bzlib.o): relocation R_X86_64_32S against `.text' can not be used when making a shared object; recompile with -fPIC
```

To fix that error I had to add -fPIC to CFLAGS in the Makefile before
compiling and installing bzip2:

```
cd ~/R
wget http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz
tar xf bzip2-1.0.6.tar.gz
cd bzip2-1.0.6
sed -i 's/^CFLAGS=-Wall/CFLAGS=-fPIC -Wall/' Makefile
make
make install PREFIX=$HOME
```

The other issue is that installing PCRE with default options yields
the following error when compiling R:

```
checking whether PCRE support suffices... configure: error: pcre >= 8.20 library and headers are required
```

To fix that PCRE needs to be compiled with the --enable-utf8 flag, as
below.

```
cd ~/R
wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.41.tar.bz2
tar xf pcre-8.41.tar.bz2
cd pcre-8.41
./configure --enable-utf8 --prefix=$HOME 
make 
make install
```

Finally to compile R we need to specify the non-standard installation
directory in both CPPFLAGS and LDFLAGS:

```
cd ~/R
wget ftp://ftp.stat.math.ethz.ch/CRAN/src/base/R-3/R-3.4.1.tar.gz
tar xf R-3.4.1.tar.gz
cd R-3.4.1
CPPFLAGS=-I$HOME/include LDFLAGS="-L$HOME/lib -Wl,-rpath=$HOME/lib" ./configure --prefix=$HOME --with-cairo --with-blas --with-lapack --enable-R-shlib
make
make install
```

On a related note, I recently had to figure out how to do the same
thing for R packages. For example my
[PeakSegPipeline](https://github.com/tdhock/PeakSegPipeline) package
needs BerkeleyDB STL to compile. On one system I have BerkeleyDB STL
installed in a non-standard directory, $HOME. To tell R to look there
when installing PeakSegPipeline, I needed to put the following in
~/.R/Makevars

```
CPPFLAGS=-I${HOME}/include
LDFLAGS=-L${HOME}/lib -Wl,-rpath=${HOME}/lib
```

The CPPFLAGS are added to the command lines used to compile the object
files (*.o), and the LDFLAGS are used in the final command used to
create the shared object file (PeakSegPipeline.so). Note that the
above is Makefile syntax so curly braces are required for environment
variables. Also it is very important that there are no quotation marks
in LDFLAGS above! (otherwise the second argument is actually treated
as a part of the lib directory of first argument)
