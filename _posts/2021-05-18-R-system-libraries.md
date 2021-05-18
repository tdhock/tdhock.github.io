---
layout: post
title: R packages that depend on system libraries
description: How to pass CRAN checks
---

In a previous/old version of my PeakSegDisk R package, I used
BerkeleyDB STL to make it easy to write a large vector to
disk. Installation instructions are provided at the end of [my
previous blog post on compiling
R](https://tdhock.github.io/blog/2017/compiling-R/).
At the time I tried to get it working/accepted on CRAN, but did not
succeed, because the CRAN build machines did not have BerkeleyDB STL
installed, so they were unable to compile my C++ code.

In [a related thread on
R-package-devel](https://stat.ethz.ch/pipermail/r-package-devel/2021q2/006953.html),
Tomas Kalibera explained the proper way to deal with such packages.

```
I think the best way for maintenance and end users is when the libraries 
are part of common software distributions R is used with on each 
platforms, which are also installed on CRAN machines. For Linux these 
are popular distributions including Debian, Ubuntu, Fedora. For Windows 
this is customized msys2 (rtools) and customized mxe. For macOS this is 
a custom distribution ("recipes").

So, if your library is already present in those distributions, but not 
installed on some of the CRAN machines, I'd simply ask for it to be 
installed - the installation is trivial in that case, this is what the 
distributions are for.

If the library is not present in those distributions, the next best I 
think is to contribute it to them. In case of Windows, ideally 
contribute also to the upstream vanilla distributions, not just to the 
customized versions for R. This would allow most people to benefit from 
your contribution, and the additional burden on CRAN maintainers (who 
have to deal with many thousands of packages) would be minimized.

If all that failed, and the license allows, one can include the source 
code of the library into the package, but that creates burden on users 
as well as maintainers (of the package, but also the repository). It may 
create confusion about the configuration due to duplication between 
packages. It creates burden for repository maintainers. It takes 
additional time on installation (particularly some libraries heavily 
using C++ take forever to build, and repository maintainers do that very 
often).

Downloading pre-compiled binaries (static libraries) at installation 
time is the worst option in my view. It is non-transparent, 
non-repeatable, and the binaries may be incompatible (e.g. on Windows 
all object files have to be built for the same C runtime). It makes 
maintenance of R much harder, currently the transition from MSVCRT to 
UCRT on Windows.
```

After that, there was a response and a clarification:

```

> Based on Tomas' suggestion, it seems the best way forward would be to 
> first request CRAN maintainers to install libsbml on the CRAN 
> machines. It is quite straightforward to install the library from the 
> instructions provided online. If the installation fails on a 
> particular architecture, I should try bundling the source code and 
> creating the static libraries.

Please let me clarify, I am not suggesting that you ask CRAN team to 
create the distribution packages for you, but only to install an 
existing distribution package (in case they are not doing that already).

The distribution package is usually a script which automatically 
downloads the software, builds it, picks up the results, adds some 
meta-data about dependencies, and archives them in a supported format. 
Someone has to create the distribution package, and I am suggesting that 
you as R package maintainer should do that, possibly getting help from 
other volunteers e.g even on the R-devel mailing list. The CRAN team 
would only add that package name to their list of installed packages (in 
case it is not there implicitly, i.e. they possibly won't have to do 
anything).

So first, I would should check for existing distribution packages. Most 
distributions have their own indexing/search support, but you can also 
look online as follows.

For Linux distributions, there is e.g. pkgs.org for the first quick 
search (libsml-devel, libsbml-dev might be what you are looking for).

For Windows, msys2 packages are here 
https://github.com/msys2/MINGW-packages/, rtools packages are here 
https://github.com/r-windows/rtools-packages (so there is 
mingw-w64-libsbml). MXE packages are here 
https://github.com/mxe/mxe/tree/master/src and the customized version 
for R is here 
https://svn.r-project.org/R-dev-web/trunk/WindowsBuilds/winutf8/ucrt3/toolchain_libs/mxe/src/ 
(so upstream MXE doesn't have sbml, but the customized has libsbml).

For macOS, recipes for R are here 
https://github.com/R-macos/recipes/tree/master/recipes and it does not 
have sbml library as far as I can see.

So, if you wanted your package to use sbml, the best way would be to 
test it with the sbml package from all the distributions mentioned above 
(from Linux, at least the ones used by CRAN - Debian/Ubuntu, Fedora). 
Then, you would create a recipe (distribution package) for macOS, test 
it with your package, and contribute to the "recipes" above. When 
creating the recipe, look at other recipes to get the form, and look at 
sbml in the previously mentioned distributions to see how to 
download/build it (in addition to the online manual you mentioned).

Once that is in, you could submit your package to CRAN, following the 
usual checks you do when submitting packages. And then, in case it 
failed on some of the CRAN machines, you could contact the individual 
maintainer and ask for installing that distribution package of the given 
name. In some cases it won't be necessary (the machines would already 
have the package, they may be installing all available packages 
automatically).

This may sound like a bit of work, but that is the price for adding 
dependencies on native libraries, and someone has to do this work. 
Installing libraries manually on the check machines is not going to 
scale and may be too much burden for many end users, apart from 
difficulties with repeatability, maintenance, etc.
```

These are wise, useful words that should be added to the official
documentation about how to write R packages!
