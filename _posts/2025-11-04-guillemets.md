---
layout: post
title: Typing guillemets
description: In emacs and other programs
---

After 15+ years typing in French, I still don't know how to type French quotation marks (guillemets).
This posts explain a few methods for doing that, which I discovered today.

## Long but robust method

### Method 1: web search

Whenever I need them, I get them by copying from web search results (works on any computer with internet).
I asked my colleagues over lunch today, and they said they do the same thing!
This method is very slow, since it requires at least 21 keystrokes.

* 2 keys: Alt-tab to switch to web browser.
* 2 keys: Ctrl-L to go to address bar.
* 11 keys: Typing « guillemets » then return.
* 2 keys: Ctrl-C to copy them from the web browser.
* 2 keys: Alt-tab to switch back to emacs.
* 2 keys: C-Y to yank into emacs (or Ctrl-V to paste anywhere else).

## Windows only

### Method 2: windows Canada keyboards

In windows settings, Language & region, Add a language, type Canada, select Français (Canada), click Install, click three dots next to French (Canada), click three dots Language options, Keyboards -> Add a keyboard, add one of these two:

* Canadian French (Legacy)
* Canadian Multilingual Standard

Then:

* 2 keys: Alt-z inserts «
* 2 keys: Alt-x inserts »

### Method 3: ASCII code entry on windows

A colleague told me that I could try typing it via ASCII codes on windows, [as documented on wikipedia](https://fr.wikipedia.org/wiki/Aide:Caract%C3%A8res_sp%C3%A9ciaux_probl%C3%A9matiques#Guillemets_fran%C3%A7ais_%C2%AB_et_%C2%BB).
This is faster than web search (4 keys each), but still annoying.

* 4 keys: Alt-1-7-4 (keypad digits, not top row digits) inserts « 
* 4 keys: Alt-1-7-5 inserts » 

That works for me on windows, as long as I am not in emacs.

## emacs only methods

## Method 4: emacs insert-char

The [emacs international chars man page](https://www.gnu.org/software/emacs/manual/html_node/emacs/International-Chars.html) says that « With a prefix argument (C-u C-x =), this command additionally calls the command describe-char, which displays a detailed description...[including] keys to type to input the character in the current input method (if it supports the character). » Doing that for the opening guillemets give me the following:

```
            character: « (displayed as «) (codepoint 171, #o253, #xab)
              charset: unicode (Unicode (ISO10646))
code point in charset: 0xAB
...
             to input: type "C-x 8 RET ab" or "C-x 8 RET LEFT-POINTING DOUBLE ANGLE QUOTATION MARK"
```

And for closing guillemets I see:

```
            character: » (displayed as ») (codepoint 187, #o273, #xbb)
              charset: unicode (Unicode (ISO10646))
code point in charset: 0xBB
...
             to input: type "C-x 8 RET bb" or "C-x 8 RET RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK"
```

* 7 keys: `C-X 8 RET ab RET` inserts «
* 7 keys: `C-X 8 RET bb RET` inserts »

So inserting in emacs requires almost twice as many keystrokes as windows.

### Method 5: emacs with auctex

[Tex stack exchange](https://tex.stackexchange.com/questions/177031/double-quote-produces-guillemets-in-emacs) says « when you do need to work a French document and want to have the double-quote key insert guillement, you can tell AUCTeX the document is in French by adding \usepackage[francais]{babel} to the preamble. » This does not work for me (double quote inserts either ``` `` ``` or `''`)  in a file called `foo.tex` with the following contents:

```tex
\documentclass{article}
\usepackage[francais]{babel}
\begin{document}
hi « guillemets » 
\end{document}
```

### Method 6: emacs function

This is my new favorite method.
After reading [this page](https://josephrjohnson.georgetown.domains/emacs/settings.html#org59fd2a3) I was inspired to write the following code in my `~/.emacs` config file,

```elisp
(defun insert-guillemets ()
  (interactive)
  (insert "«  » ")
  (backward-char)
  (backward-char)
  (backward-char))
(global-set-key (kbd "C-c g") 'insert-guillemets)
```

So then typing `C-c g` inserts opening and closing guillemets, with appropriate spacing, and the cursor ends up in the middle of the guillemets! (3 keys for all of that, very efficient)

## Bonus: how to type È or É on AZERTY keyboard

### Windows, not emacs

[Ouest France says](https://les-raccourcis-clavier.ouest-france.fr/e-accent-grave-majuscule/)

* Alt 0 2 0 0 or Alt 2 1 2 gives È.
* Alt 0 2 0 1 or Alt 1 4 4 gives É.

### emacs!

```elisp
(defun insert-E-grave ()
  (interactive)
  (insert "È"))
(global-set-key (kbd "C-c e") 'insert-E-grave)
(defun insert-E-aigu ()
  (interactive)
  (insert "É"))
(global-set-key (kbd "C-c E") 'insert-E-aigu)
```
