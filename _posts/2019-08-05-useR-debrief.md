---
layout: post
title: useR 2019 debrief
description: Interesting talks I saw in Toulouse
---

Recently I went to the useR 2019 conference in Toulouse, which is the
yearly international meeting of R package developers. The [talk
schedule with links to slides](http://www.user2019.fr/talk_schedule/)
is already online.

I gave a talk about the fast algorithm for optimal peak
detection implemented in the
[PeakSegDisk](https://cloud.r-project.org/web/packages/PeakSegDisk/) R
package, [slides](http://www.user2019.fr/static/pres/t257847.pdf),
[video](https://www.youtube.com/watch?v=XlC4WCqsbuI).

Here is a summary of the most interesting talks I saw during the
conference:

* Torsten Hothorn, [Transformation
  models](http://ctm.r-forge.r-project.org/news/Toulouse/) tutorial on
  packages [tram](https://cloud.r-project.org/web/packages/tram/),
  [mlt](https://cloud.r-project.org/web/packages/mlt/index.html),
  [trtf](https://cloud.r-project.org/web/packages/trtf/index.html).
* Anqi Fu and Naras, [CVXR](https://cvxr.rbind.io/) is for disciplined
  convex optimization.
* Michela Battauz,
  [video](https://www.youtube.com/watch?v=UsIcI3-pXiE),
  [regIRT](https://github.com/micbtz/regIRT/) for L1-regularized Item
  Response Theory models. Fused lasso type penalty that forces
  coefficients for all choices to go together.
* Julie Josse, [video](https://www.youtube.com/watch?v=z8IuuDe5oXs),
  interesting paper about [supervised learning with missing
  values](https://arxiv.org/abs/1902.06931)
* Eric Lecoutre, [slides](http://www.welovedatascience.com/user2019)
  comparing machine learning packages.
* Erin LeDell, [video](https://www.youtube.com/watch?v=5EHHGBYaIqE),
  [benchmarking ML
  systems](http://www.user2019.fr/static/pres/t258053.pdf).
* Michel Lang, [video](https://www.youtube.com/watch?v=wsP2hiFnDQs),
  [mlr3](http://www.user2019.fr/static/pres/t258076.pdf) machine
  learning framework.
* Bernd Bischl, [video](https://www.youtube.com/watch?v=gEW5RxkbQuQ),
  [mlr3pipelines](http://www.user2019.fr/static/pres/t258139.pdf)
* Tomas Kalibera, [video](https://www.youtube.com/watch?v=lMQumNlOA24),
  [slides](http://www.user2019.fr/static/pres/t256727.pdf) on
  sustainable package development.
* Perry de Valpine, [video](https://www.youtube.com/watch?v=EPJT-6Nvre4),
  [slides](http://www.user2019.fr/static/pres/t257974.pdf) about
  nCompiler, write a subset of R code that is compiled to C++ (and
  supports auto-differentiation). Also
  [NIMBLE](https://r-nimble.org/) for Bayesian modeling.
* Robert Crouchley, [video](https://www.youtube.com/watch?v=9dcQLsYTH20),
  [slides](http://www.user2019.fr/static/pres/t256894.pptx) about
  RcppEigenAD for auto-differentiation.
* Radford Neal, pqR now has auto-differentiation as well,
  [blog](https://radfordneal.wordpress.com/2019/07/06/automatic-differentiation-in-pqr/).
* Zbynek Slajchrt, [video](https://www.youtube.com/watch?v=1fTTwf3ho50),
  [slides](http://www.user2019.fr/static/pres/t257850.pdf) about
  FastR.
* Arun Srinivasan, [video](https://www.youtube.com/watch?v=tWx1ooBSxFc),
  [slides](http://www.user2019.fr/static/pres/t258038.pdf) about
  improvements in
  [data.table](https://github.com/Rdatatable/data.table/wiki) and the
  .SDcols feature.
* Jim Hester, [video](https://www.youtube.com/watch?v=RA9AjqZXxMU),
  [slides](http://www.user2019.fr/static/pres/t257803.pdf) about fast
  [vroom](https://github.com/r-lib/vroom) CSV reader.
* Gabor Csardi, [video](https://www.youtube.com/watch?v=z751o_KVdJY),
  [slides](http://www.user2019.fr/static/pres/t257603.zip) about
  [pak](https://cloud.r-project.org/web/packages/pak/), parallel
  alternative to install.packages function.
* Henrik Bengtsson, [video](https://www.youtube.com/watch?v=4B3wPFL_Syo),
  [slides](https://www.jottr.org/2019/07/12/future-user2019-slides/)
  about [progressr](https://github.com/HenrikBengtsson/progressr) API
  for progress display and
  [future](https://github.com/HenrikBengtsson/future/) parallel
  computing framework.

