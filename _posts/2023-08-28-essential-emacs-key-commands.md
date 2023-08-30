---
layout: post
title: Essential emacs key commands
description: Cheat sheet for my students
---

This semester I am teaching students to use R and python inside of
emacs, and I recommended that they do the emacs tutorial to
familiarize themselves with the old school keyboard shortcuts. Here is
a cheat sheet of common commands.

* C-g: keyboard-quit. 
* C-x C-c: save-buffers-kill-terminal (quit emacs). 

### Help

* C-h: help.
* C-h t: tutorial. 
* C-h k: describe key (type a keyboard shortcut and emacs will tell you what it does).
* C-h v: describe variable (see values which are used to configure emacs).
* C-h f: describe function (see help about emacs functions).

### interactive execution

* C-RET: send line.
* C-c C-z: activate python.
* C-c C-r: send region.
* C-c C-s: switch R process (attach R console to this script).

### file and buffer manipulation

* C-x 2: split vertical.
* C-x 1: delete-other-windows (remove split).
* C-x o: move cursor to next window.
* C-x k: kill buffer.
* C-x b: switch to buffer.
* C-x C-f: find/open file.
* C-x C-s: save buffer.
* C-x C-w: write file (save as).

### navigation

* C-s: isearch, find next.
* C-r: isearch, find previous.
* C-n, C-p, C-f, C-b: next, previous, forward, back (character).
* M-n, M-p, M-f, M-b: next, previous, forward, back (word).
* C-a, C-e: start, end of line.
* C-v, M-v: down, up one page.
* M-<, M->: beginning/end of buffer.
* C-d, M-d: delete character, word after.

### editing

* C-k: kill/cut to end of line.
* C-y: yank/paste to end of line.
* C-SPC: set mark.
* C-w: kill region. (cut)
* M-w: kill ring save. (copy)
* C-_: undo.

### Extended commands

Any command can be entered in "extended" form rather than via a
keyboard shortcut, which means you can type M-x then the
command/function name.

* increase-left-margin, decrease-left-margin
* goto-line (number)
* replace-string, query-replace (M-%)
* regexp-builder
* replace-regexp, query-replace-regexp (C-M-%)

