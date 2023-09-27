---
layout: post
title: Debugging python code in emacs
description: Fixing a bug and building old emacs
---

NOTE: This is a work in progress!

This semester I am teaching students to use R and python inside of
emacs, and I recommended that they use C-RET to send one line of code
from a python script buffer, to the `*Python*` interactive
console. That usually works just fine, but it can fail in emacs>27
when a (Pdb) prompt is active.

TODO LINK AND DETAILS

*** Temporary fix: build emacs 27

TODO

*** Why is emacs text small?

I have the following as the first line of code in my ~/.emacs file,

```elisp
(set-face-attribute 'default nil :height 200)
```

The purpose of the above code is to make the default text size larger
(so students can easily read in class). When emacs starts up, the
window flashes large TODO LINK.

[Site-wide Initialization
Files](https://www.gnu.org/software/emacs/manual/html_node/eintr/Site_002dwide-Init.html)
says that "site-wide initialization files are loaded automatically
each time you start Emacs, if they exist. These are site-start.el,
which is loaded before your .emacs file, and default.el, and the
terminal type file, which are both loaded after your .emacs file."

term-file-prefix is "term/"

So we need to
