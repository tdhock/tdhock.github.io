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

## Bonus: Canadian French keyboard

Unlike the AZERTY French keyboard, the QWERTY French Canadian keyboard makes it easy to type programming symbols. There are fewer differences with the USA English keyboard.

![three keyboard layouts](/assets/img/2025-11-04-guillemets/keyboards.png)

![keyboard photos](/assets/img/2025-11-04-guillemets/photos.png)

* `{}` accolades typed using right Alt (thumb) then left and above Enter key (right little finger).
* `[]` crochets typed using right Alt (thumb) then their typical keys (right little finger).
* `<>` chevrons typed using right little finger alone (key above Enter), or with left little finger on left shift key.
* `'` simple guillemet anglais typed using left little finger shift, then right middle finger comma key.
* `"` double guillemets anglais typed using right little finger shift, then left ring finger 2 key. This is [section B on this touch typing chart](https://opentextbc.ca/computerstudies/chapter/the-base-position/) which I don't believe is accurate, because it says little fingers are supposed to type the Alt keys (I use thumbs).
* `?` point d'interrogation typed using right little finger shift then left index on 6 key.
* `~` tilde typed using right Alt thumb then right little finger ; home position key.
* `#|\` dièse barre verticale antislash typed using old backtick key (upper left).
* `±` plus or minus typed using right Alt thumb then 1 key.
* `@` arobase ou A commercial typed using right Alt thumb then 2 key.
* `/` slash typed using shift then left middle finger 3 key.

### Accent marks

* `éÉ´` Accent aigu typed using old slash/question key.
* ``è`à`` Accent grave or backtick typed using key just left of Enter.
* `ô` Chapeau ou accent circonflex is just above that.
* `¸` cedilla is just to the right of that (type c after).
* `¨` tréma is the same key as cedilla but with shift.

### emacs

* in emacs `M-<` goes to start and `M->` goes to end of buffer, which both require shift key under USA English keyboard layout.
  * go to start no longer requires shift key: left Alt then old backslash key (above return).
  * go to end is same but with shift key.
  
### what is the difference between usual hypen/minus and right Alt period?

```
             position: 5000 of 5000 (100%), column: 11
            character: ­ (displayed as ­) (codepoint 173, #o255, #xad)
              charset: unicode (Unicode (ISO10646))
code point in charset: 0xAD
               script: latin
               syntax: _ 	which means: symbol
             category: b:Arabic, h:Korean, j:Japanese, l:Latin
             to input: type "C-x 8 RET ad" or "C-x 8 RET SOFT HYPHEN"
          buffer code: #xC2 #xAD
            file code: #xC2 #xAD (encoded by coding system utf-8-dos)
              display: by this font (glyph code):
    harfbuzz:-outline-Courier New-regular-normal-normal-mono-15-*-*-*-c-*-iso8859-1 (#x10)
       hardcoded face: escape-glyph

Character code properties: customize what to show
  name: SOFT HYPHEN
  general-category: Cf (Other, Format)
  decomposition: (173) ('­')
  
---------------------------------------

             position: 7602 of 7607 (100%), column: 0
            character: - (displayed as -) (codepoint 45, #o55, #x2d)
              charset: ascii (ASCII (ISO646 IRV))
code point in charset: 0x2D
               script: latin
               syntax: _ 	which means: symbol
             category: .:Base, a:ASCII, l:Latin, r:Roman
             to input: type "C-x 8 RET 2d" or "C-x 8 RET HYPHEN-MINUS"
          buffer code: #x2D
            file code: #x2D (encoded by coding system utf-8-dos)
              display: by this font (glyph code):
    gdi:-raster-Courier-regular-normal-normal-mono-16-*-*-*-c-*-iso8859-1 (#x2D)

Character code properties: customize what to show
  name: HYPHEN-MINUS
  general-category: Pd (Punctuation, Dash)
  decomposition: (45) ('-')
```
