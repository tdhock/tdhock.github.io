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

I recommend that my students use elpy, so I originally thought this
may be an issue with elpy, and I filed [an issue in that
repo](https://github.com/jorgenschaefer/elpy/issues/2029), which
contains information for reproducing, and screenshots of two different
versions of emacs! I got a helpful answer from one of the elpy devs,
who told me the issue is probably in the emacs function
`python-shell-send-string`, which is defined in `python.el`, which
ships with emacs. So my next step was to reproduce the issue in emacs
without elpy, which I did, using emacs 28 and 29 (but no issue in
emacs 27). 

The next step was to try to find out what was the issue. I found that
starting in emacs 28, `python-shell-send-string` calls a python
function `__PYTHON_EL_eval` (which is `defconst`
`python-shell-eval-setup-code` in `python.el`) to evaluate the python
code in the global environment, which I guess is not correct logic, in
the context of the (Pdb) prompt.

Next step is to file an issue with emacs. How to do that? I tried M-x
report-emacs-bug, but I don't think the email went through, why?

Maybe I can find a maintainer who is familiar with this code, to
contact personally? [python.el is in lisp/progmodes in the git repo
for
emacs](https://git.savannah.gnu.org/cgit/emacs.git/tree/lisp/progmodes/python.el). It
says the maintainer is emacs-devel@gnu.org, and [the log tab shows the
commit history, which shows there are several recent
committers](https://git.savannah.gnu.org/cgit/emacs.git/log/lisp/progmodes/python.el):
Stefan Kangas, Matthias Meulien, kobarity, Eli Zaretskii, Basil
L. Contocounesios, Mattias Engdegård.  There is a mirror of emacs on
github, [which shows the same commit history, along with github
usernames](https://github.com/emacs-mirror/emacs/commits/master/lisp/progmodes/python.el). Who
is the last one to have edited `__PYTHON_EL_eval`? [git
blame](https://github.com/emacs-mirror/emacs/blame/master/lisp/progmodes/python.el)
says the last people to edit that part of the file were Lars
Ingebrigtsen (github user larsmagne) and Augusto Stoffel (astoff).

### Temporary fix: build emacs 27

TODO

### Why is emacs text small?

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

So we need TODO
