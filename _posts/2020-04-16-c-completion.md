---
layout: post
title: C/C++ completion in emacs
description: Configuration details
---

I have been creating screencasts about [how to create R packages with
C++
code](https://www.youtube.com/playlist?list=PLwc48KSH3D1OkObQ22NHbFwEzof2CguJJ)
and one issue that I noticed was that there is no completion in C++
code by default in emacs. 

So I started reading about [how to set up a C IDE in
emacs](https://tuhdo.github.io/c-ide.html#orgheadline13). I got a
first pass working with

```elisp
(package-initialize)
;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/") t)

;; complete anything
(require 'company)
(add-hook 'after-init-hook 'global-company-mode)
(setq company-backends (delete 'company-semantic company-backends))
(with-eval-after-load "c-mode" 
  (define-key c-mode-map  [(tab)] 'company-complete)
  )
(with-eval-after-load "c++-mode" 
  (define-key c++-mode-map  [(tab)] 'company-complete)
  )
```

but I was not able to get it to work with C++ code, so I found
[irony-mode](https://github.com/Sarcasm/irony-mode)

I also found an excellent [C Programming Boot
Camp](https://gribblelab.org/CBootCamp/index.html) which is geared
toward scientific computing. An excellent read for an introduction to
C programming!

One of the links therein points to the [Modeling With
Data](https://modelingwithdata.org/about_the_book.html) book which
explains how to do statistical analysis (almost) entirely using the C
programming language. Some exceptions are using SQL for data
manipulation and gnuplot/graphviz for data/graph
visualization. Interesting idea to use C for mostly everything, but
data visualization is a big deal, and the power of ggplot2 still keeps
me using R.
