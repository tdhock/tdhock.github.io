---
layout: post
title: R-GSOC-2017
description: R project in Google Summer of Code 2017
---

This is a summary of my experience mentoring and administering the
[R project in Google Summer of Code 2017](https://github.com/rstats-gsoc/gsoc2017/wiki/table-of-proposed-coding-projects).

We had 35 projects funded at the beginning of summer. Two of these
projects failed; in one case the student disappeared, in another case
the student decided to work on another full-time job instead. This
year the pass rate for the R project is 33/35 = 94.3%, which is higher
than the overall average of
[85.6% from GSOC2016](https://developers.google.com/open-source/gsoc/resources/stats). I
mentored three of the projects that passed.

[Marlin Na](https://github.com/Marlin-Na) wrote the
[TnT](https://github.com/marlin-na/TnT) package for rendering
interactive genome browsers in R. This project was his idea, and he
was very self motivated. We did not have skype calls, but he provided
very detailed email updates all throughout GSOC. He wrote
[a blog post](http://weblog.marlin.pub/post/tnt/tnt-gsoc17/) about his
experience, and plans to submit the package to Bioconductor.

[Rover Van](https://github.com/RoverVan) implemented speed
optimizations for the [iregnet](https://github.com/anujkhare/iregnet)
package which provides a machine learning algorithm for regression
with censored outputs. His commits for GSOC2017 are summarized on
[PR59](https://github.com/anujkhare/iregnet/pull/59), and his
[blog post](http://rovervan.com/post/gsoc/gsoc-summary) provides a
nice description of his overall experience. Although the code is still
not as fast as glmnet, his benchmarks clearly show that the code is
now faster than it was before GSOC.

It was my second year working on the interactive grammar of graphics
with [Faizan Khan](https://github.com/faizan-khan-iit). As summarized
on his [blog post](https://faizan-khan-iit.github.io/gsoc17/), his GSOC
project was a very ambitious rewrite of the original
[animint](https://github.com/tdhock/animint) package. This resulted in
[animint2](https://github.com/tdhock/animint2), which supports an
simpler syntax for defining interactivity using parameters rather than
aesthetics. It also has dropped the dependency on ggplot2; we now
instead use the
[ggplot2Animint](https://github.com/faizan-khan-iit/ggplot2) fork,
which will be more stable and easier to maintain (no need to provide
updates every time the ggplot2 developers make backwards incompatible
changes).

Overall it was another very successful year for the R project in
Google Summer of Code, and I look forward to participating again next
year. In fact, I have already setup a
[wiki with a few project ideas for R in GSOC2018](https://github.com/rstats-gsoc/gsoc2018/wiki/table-of-proposed-coding-projects). 
