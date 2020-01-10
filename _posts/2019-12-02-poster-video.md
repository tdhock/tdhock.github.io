---
layout: post
title: Scientific poster suggestions
description: A helpful video
---

On Friday my students Joseph Vargovich and Atiyeh Fotoohinasab will
present at a local poster session for students of the School of
Informatics, Computing, and Cyber Systems. Crystal Hepp recommended
that they use the poster design described in
[How to create a better research poster in less
time](https://www.youtube.com/watch?v=1RwJbhkCA58), which is a 20
minute video describing the problems with current mainstream poster
designs/sessions, and some solutions. Overall I think the video has
some interesting ideas but there are a few points that I would like to
comment on.

* in the video the poster is thrown away after the session. Instead, I
  usually bring the poster home and put it up in my lab for discussion
  with colleagues/labmates.
* the video mentions that legible text is important -- I agree!
  Especially make sure that all figure/axis/legend text is readable.
* in the video the grad student gets a hand me down powerpoint
  template! PowerPoint is for presentations, not poster
  design. Instead, use [Scribus](https://www.scribus.net/) or
  [Inkscape](https://inkscape.org/). Scribus is preferable if you are
  still working on the figures, because it supports including linked
  figure files (which are automatically updated in the poster if you
  update the source figure file). Here is the [scribus sla
  file](https://raw.githubusercontent.com/tdhock/PeakSegDP-NIPS/master/HOCKING-RIGAILL-PeakSegDP-NIPS-poster.sla)
  that I used for my [NIPS'14 PeakSeg
  poster](https://github.com/tdhock/PeakSegDP-NIPS/raw/master/HOCKING-RIGAILL-PeakSegDP-NIPS-poster.pdf).
* make it easy/fast? I guess this is a good goal, but there is no
  substitute for hard work / dedicated time working on your poster.
* the video suggests color coded poster types, e.g. green for
  intervention, red for theory, etc. Conference organizers may suggest
  the color scheme they would like to encourage.
* displaying the main result as big text in middle seems to be
  effective. I would suggest adding one or two main result figures
  in the middle below that.
* the "ammo bar" on the right should have most of the other figures
  from the paper.
* the "silent presenter" bar on the left contains the main title,
  which is a more technical version of the main result. 
* qr code should be 5 inches! That seems pretty large to me. 
* No commentary in the video about how to display actual computer code
  / pseudocode for algorithms / equations, which are actually
  important in machine learning and statistical software.
* No mention about figure file formats. For figures with equations I
  use
  [tikzDevice](https://cloud.r-project.org/web/packages/tikzDevice/vignettes/tikzDevice.pdf)
  (`tikz` function in R) to generate a tex file which the `pdflatex`
  command line program then converts to PDF for final inclusion in the
  poster. For figures without equations you should use either vector
  graphics (`pdf`/`svg` functions in R) or high-resolution raster
  graphics, e.g.  `png("figure-1.png", width=5, height=5, units="in",
  res=1000)` in R. [GIMP](https://www.gimp.org/) can be used to create
  high-resolution raster graphics from vector graphics such as PDF
  (the desired resolution can be specified along with the page number
  when the PDF file is first opened/imported).
