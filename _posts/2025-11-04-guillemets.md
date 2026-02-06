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

Drawbacks of this layout:

* it takes two keystrokes to type a ç

Other French layouts on Windows:

* [bépo](https://bepo.fr/wiki/Pr%C3%A9sentation), the French version of [Dvorak](/assets/img/2025-11-04-guillemets/STedDVzine.pdf).
* Canadian Multilingual Standard: can type ç with one keystroke.

Other French layouts on Ubuntu:

* Français (Dvorak)
* Français (Canada, Dvorak)
* French (BEPO)
* French (BEPO, AFNOR)
* French (BEPO, Latin-9 only)
* Canadian (CSA)

Cette touche est la cent-cinquième du clavier. Elle n’existe pas sur les claviers à 104 touches. Si votre clavier ne possède cette touche, les caractères peuvent être obtenus différemment : « ê » et « Ê » grâce l’accent circonflexe mort ; la barre oblique « / » est en accès direct sur la touche 9 et le circonflexe non mort est en AltGr+6.

* [apprentissage de bépo par exercises dans un navigateur](http://dactylotest.free.fr/bepodactyl/)

[CSA keyboard](https://en.wikipedia.org/wiki/CSA_keyboard) wikipedia page explains that Windows Canadian Multilingual Standard = Ubuntu CSA, more or less: "Figure 1: The Windows version differs from the official standard in terms of the location of dead keys (middle dot ·, tilde ~) and the absence of a few characters, including đ, ⅛ and the dot above ˙. The euro sign € was not included in the Canadian standard in 1992 and is not officially included in the standard yet (R2021). Microsoft added this symbol in 1999 (4 and E keys), following the ISO 9995-3 standard."

* [wikipedia Description](https://en.wikipedia.org/wiki/CSA_keyboard#Description) says "It is possible to completely do without the dead key for the grave accent, as the only three French letters that use it (À, È, and Ù) are directly accessible in both lowercase and uppercase on this keyboard. However, the grave accent (dead key) remains in the primary group to type the characters ù/Ù on an ANSI keyboard, which lacks a key to the left of the Z key."

Comparing keyboards

* [interactive comparison of old vs new azerty](https://norme-azerty.fr/en/#explore)
* [Une des principales différences par rapport à la disposition proposée par Francis Leboutte est l’usage de la touche modificatrice Alt Gr au lieu de la touche morte accent grave « ` ».](https://fr.wikipedia.org/wiki/Disposition_Dvorak#B%C3%A9po), [more details](https://bepo.fr/wiki/Dvorak-fr).

* [qwerty-intl](https://en.wikipedia.org/wiki/QWERTY#US-International)
* [azerty](http://xahlee.info/kbd//french_new_keyboard_layout.html)
* [bépo](http://xahlee.info/kbd//bepo_layout.html)

| feature   | qwerty-intl      | CSA                      | Can-fr           | azerty           | bépo         |
|-----------|------------------|--------------------------|------------------|------------------|--------------|
| ê         | dead key + e     | dead key + e             | dead key + e     | dead key + e     | 1 touche     |
| é         | dead key + e     | 1 touche                 | 1 touche         | 1 touche         | 1 touche     |
| ç         | dead key + c     | 1 touche                 | dead key + c     | 1 touche         | 1 touche     |
| backtick  | dead key + space | AltGr + dead key + space | dead key + space | dead key + space | Shift touche |
| oe        | missing          | AltGr touch              | missing          | AltGr touche     | AltGr touche |
| ergonomic | no               | no                       | no               | no               | yes          |

|           | English     | French     |
|-----------|-------------|------------|
| old       | qwerty      | azerty     |
| new       | qwerty-intl | azerty-new |
| ergonomic | Dvorak      | bépo       |


## bépo tricks

* undo `C-_` impossible, `C-/` easier (/ is on 9).
* `M-<` start `M->` end impossible, `C-start` `C-end` instead.
* `C-k` kill less convenient, can use right Ctrl with left index.
* arithmetic `+-/*` on `7890`.
* if missing 105è key on bottom left, `y` is `^` dead key for typing êÊ.
* AltGr-i then i makes ï.
* vertical bar `|` on AltGr-b.
* and `&` on AltGr-e.
* question `?` is shift n.
* exclamation `!` is shift y.

```elisp
(global-set-key (kbd "C-«") 'beginning-of-buffer)
(global-set-key (kbd "C-»") 'end-of-buffer)
```

## French Canadian tricks

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
  
## what is the difference between usual hypen/minus and right Alt period?

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


## Update 8 jan 2026

I have been typing as a bépoète for over a month, and I am hooked!
Touch typing on the home row definitely feels more comfortable and natural.
I prepared [a slide](https://docs.google.com/presentation/d/1U7RgXtTttg8TxBRYs0aRApcJvQ5tUQrbIvMxKp7XlbA/edit?slide=id.g3b5767da9f3_0_4#slide=id.g3b5767da9f3_0_4) showing the differences between several keyboard layouts, in terms of how to input characters that are frequently used in programming.
The main advatages of bépo are:

* no dead keys required (other French keyboard layouts have `` `^~ `` as dead keys, which means to input the symbol, you first type the key, and then type space).
* no combinations of AltGr with right hand (other French keyboard layouts have 3–6 symbols on the right hand, which makes it difficult to type, because AltGr is on the right).
* 13 symbols directly accessible (no modifier required), which is not as many as azerty legacy (15), but actually more than qwerty US (11).

### even more optimization

There seems to be a lively community of developers working on new keyboard layouts :

* [Ergo-L](https://ergol.org/bepo/) has ergonomic benefits with respect to bépo, especially for English, and uses an all purpose dead key (to insert any accent — cool!), but no accented characters on direct access (bummer!).
* [Optimot](https://optimot.fr/presentation.html#avantages-d-optimot) has a crazy amount of symbols on dead keys.
* [Ergopti](https://ergopti.fr/informations#manque-de-caracteres-et-non-optimisation-pour-les-autres-langues) removed support for languages other than French and English, puts numbers on direct access, and uses a magic dead key.

## Update 5 fév 2026

There is some issue displaying the three kinds of spaces.

Bépo web site recommends [DejaVu](https://bepo.fr/wiki/Liens#Polices_d'%C3%A9criture_pour_b%C3%A9po).

Below we clearly see the difference but it is not a Mono spaced font (important for terminal table output from R `data.table` or python `pandas`).

![three different spaces using DejaVu Math TeX Gyre font in emacs](/assets/img/2025-11-04-guillemets/spaces-DejaVuMathTeXGyre.png)

Below we see no difference between the non-breaking spaces. (windows)

![three different spaces using DejaVu Sans Mono font in emacs on windows](/assets/img/2025-11-04-guillemets/spaces-DejaVuSansMono.png)

Below we see no difference between the non-breaking spaces. (ubuntu)
Curiously, Ubuntu shows two differences

* top line espaces fines (narrow non-breaking spaces) are displayed in Linux Libertine Display O (not as wide as all other text in DejaVu Sans Mono).
* table does not have different font (but is different from surrounding text on windows).

![three different spaces using DejaVu Sans Mono font in emacs on ubuntu](/assets/img/2025-11-04-guillemets/spaces-DejaVuSansMonoUbuntu.png)

Below the default emacs font shows a difference but 

![three different spaces using Courier New font in emacs](/assets/img/2025-11-04-guillemets/spaces-DejaVuCourierNew.png)

```elisp
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:family "DejaVu Math TeX Gyre" :foundry "outline" :slant normal :weight regular :height 113 :width normal)))))
```

Where do the rules come from?

* [aide-mémoire](https://gitlab.com/bepo/misc/-/raw/master/documents/aide-memoire/bepo_aide-memoire.pdf)
* [OQLF](https://vitrinelinguistique.oqlf.gouv.qc.ca/22039/la-typographie/espacement/espacement-avant-et-apres-les-signes-de-ponctuation-et-les-symboles)
* [Jacques André](https://jacques-andre.fr/faqtypo/lessons.pdf) copié ci-dessous

![André Table 1](/assets/img/2025-11-04-guillemets/AndréTable1.png)

| symbole                   | aide-mémoire    | André           | OQLF            |
|---------------------------|-----------------|-----------------|-----------------|
| `;` point-virgule         | foo ; bar       | foo ; bar       | foo ; bar       |
| `!` point d’exclamation   | foo ! bar       | foo ! bar       | foo ! bar       |
| `?` point d’interrogation | foo ? bar       | foo ? bar       | foo ? bar       |
| `«»` guillemets           | foo « bar » baz | foo « bar » baz | foo « bar » baz |

Tout les trois sources sont d’accord sur :

* le tiret incise : foo — bar — baz
* le deux-points : foo

Commentaires :

* André mentionne l’espace fine dans le texte, mais le Table 1 contient seulement espace normale et espace insécable.
* aide-mémoire n’est pas d’accord avec OQLF sur les espaces dans les guillemets.
* dans emacs la police des tableaux dans markdown s’affiche bien la différence entre les deux espaces insécables. Comment faire de cette police le defaut ?

![emacs table](/assets/img/2025-11-04-guillemets/differences.png)

OQLF says there are only four uses for espace fine :

| Barre oblique         | L’affiche ouvert / fermé |
| point d’exclamation   | Félicitations !          |
| point d’interrogation | Pourriez-vous ?          |
| point virgule         | foo ;                    |

