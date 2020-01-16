---
layout: post
title: Emacs local variables
description: Custom configurations for R
---

[Specifying File Variables in emacs
docs](https://www.gnu.org/software/emacs/manual/html_node/emacs/Specifying-File-Variables.html#Specifying-File-Variables)
explains how to define file-local variables, which are sometimes very
useful. For example to specify a custom compilation command for R
package development, I use the following at the top of each
R-pkg/src/* file,

```
/* -*- compile-command: "R CMD INSTALL .." -*- */
```

[Directory Variables in emacs
docs](https://www.gnu.org/software/emacs/manual/html_node/emacs/Directory-Variables.html)
explains how to use a single file to define file-local variables for
all files in a directory. So instead of repeating the line above in
each R-pkg/src/* file, we can use the following elisp code in
R-pkg/src/.dir-locals.el just once:

```
((nil . ((compile-command . "R CMD INSTALL .."))))
```

[Safe File Variables in emacs
docs](https://www.gnu.org/software/emacs/manual/html_node/emacs/Safe-File-Variables.html)
explains that the following in .emacs can be used to avoid the
annoying "do you really want to set the local variable values?"
message:

```
(add-to-list 'safe-local-variable-values '(compile-command . "R CMD INSTALL .."))
(add-to-list 'safe-local-variable-values '(compile-command . "make jss-paper.pdf"))
```

