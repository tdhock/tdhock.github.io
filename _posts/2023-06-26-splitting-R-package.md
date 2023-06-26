---
layout: post
title: Splitting an R package
description: Recommendations from experience with spatstat
---

Today I read a post on
[R-package-devel](https://stat.ethz.ch/pipermail/r-package-devel/2023q2/009249.html)
which gives recommendations about how to split an R package into
several smaller packages. This can be useful if you have a large R
package that fails CRAN checks (which limit the amount of time used
per package).
