---
layout: post
title: Emacs local variables
description: Custom configurations for R
---

[Safe File Variables in emacs
docs](https://www.gnu.org/software/emacs/manual/html_node/emacs/Safe-File-Variables.html)

```
(add-to-list 'safe-local-variable-values '(compile-command . "R CMD INSTALL .."))
(add-to-list 'safe-local-variable-values '(compile-command . "make jss-paper.pdf"))
```

[Directory Variables in emacs docs](https://www.gnu.org/software/emacs/manual/html_node/emacs/Directory-Variables.html)

```
((nil . (compile-command . "R CMD INSTALL ..")))
```
