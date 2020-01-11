---
layout: post
title: Ubuntu setup and LaTeX debugging
description: Installing and configuring a 10 year old Mac
---

The I key on the keyboard of my 12 year old Dell laptop has become
very difficult to use (need to press VERY HARD to produce an I), so I
am considering upgrading to my 10 year old Macbook Pro. I had
installed dual boot Ubuntu 14.04 on it several years ago, so I fired
that up, then ran `update-manager`, clicked to upgrade to ubuntu
16.04, did that, restart, click to upgrade to ubuntu 18.04, restart,
then I have my fresh Ubuntu LTS system. Now what? Let's get emacs +
ess + R working.

First some APT packages:

```
sudo aptitude install emacs ess aptitude \ #basics
     r-recommended libcairo-dev libtiff-dev \ #R
     default-jre default-jdk \ #for java
     libbz2-dev liblzma-dev zlib1g-dev libcurl4-gnutls-dev xorg-dev \ #r
     texlive ghostscript texlive-fonts-extra texinfo \ #r manuals
     libxml2-dev libssl-dev \ #some packages
     texlive-science \ #for algorithm.sty
     r-cran-rgl \ #for 3dviz
     tcl-dev tk-dev #for library(tcltk), library(loon)
```

Then I downloaded the R-3.6.2 source code and compiled it, similar to
[install-r-devel.sh](https://github.com/tdhock/dotfiles/blob/master/install-r-devel.sh). Also
installed parts of those startup files (.emacs, .Rprofile, .bashrc).

I had some troubles redoing the tikz figures in
https://github.com/tdhock/PeakSegFPOP-paper with the most recent
version of the tikzDevice R package. It seems that the tikzDevice
package now calculates font metrics (width/height) using a file in a
temporary directory (rather than the current directory). This is an
issue in this project because I told tikzDevice to calculate metrics
using the same jss document class as the final latex file:

```r
options(tikzDocumentDeclaration="\\documentclass{jss}")
```

but I put the `jss.cls` file in the project directory. So when
tikzDevice tries to compute font metrics (from a temporary directory)
it stops me with an error, can't find jsslogo.jpg:

```
tdhock@maude-MacBookPro:~/projects/PeakSegFPOP-paper$ R --vanilla -e 'options(tikzDocumentDeclaration="\\documentclass{jss}");tikzDevice::tikzTest()'
...
TeX was unable to calculate metrics for:

	A ...
(/tmp/Rtmp12xHO8/tikzDevice25013d1aafd5/tikzStringWidthCalc.tex ...
(/usr/share/texmf/tex/latex/R/tex/latex/jss.cls ...  ! LaTeX Error:
File `jsslogo' not found.  ``` The output above shows that (1) the
test tried to compute font metrics for A via a temporary file then (2)
found jss.cls under /usr but (3) could not find jsslogo graphics file.

There are a number of [fixes for this
issue](https://github.com/daqana/tikzDevice/issues/197):

- put jsslogo.jpg in ~/texmf/tex which is the user-specific directory
  which pdflatex searches for input tex and image files (see
  kpsewhich, kpsepath, kpsewhere).
- use `\documentclass{article}` or `\documentclass[nojss]{jss}`
  which does not require the jsslogo.jpg image.
- set TEXINPUTS environment variable to add project directory
  containing the jsslogo.jpg image.
- add jsslogo.jpg under the /usr/share/texmf/tex/latex/R directory
  which the debian pacakge copies from the R-src/share/texmf directory.
  [R-core doesn't want to include jsslogo.jpg though](https://bugs.r-project.org/bugzilla/show_bug.cgi?id=17687), so this won't be a general solution any time soon. You can do it on your own system using e.g. `sudo cp jsslogo.jpg /usr/share/texmf/tex/latex/R/tex/latex` but you need to run `sudo mktexlsr` after in order to rebuild the tex path search data files.
  

