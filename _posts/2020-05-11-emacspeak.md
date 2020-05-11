---
layout: post
title: emacspeak
description: Teaching my son to type in emacs
---

Over the past several months I have been doing some typing exercises
with my 2-year-old son Basil, in
[emacs](https://en.wikipedia.org/wiki/Emacs) of course. It has been
going rather well, and he seems to enjoy pressing the keys and seeing
them appear on screen.

Last week I had the idea that the typing exercises could be improved
via audio feedback. What if emacs could speak the letter / word /
sentence as it is typed?

Well, lucky for me,
[T. V. Raman](http://emacspeak.sourceforge.net/raman/) has been
working for the past 20 years on
[emacspeak](http://tvraman.github.io/emacspeak/manual/), which does
exactly what I wanted.

On Ubuntu the installation is super easy,

```
sudo apt install emacspeak
```

During installation for the first configuration question I chose
`espeak` as the default speech server, which supports both English and
French. Then I left `none` for the second configuration question
(Hardware port of the speech generation device). To change these
configurations without reinstalling you can do

```
sudo dpkg-reconfigure emacspeak
```

After that you can start it via the command `emacspeak` which pops up
an emacs GUI window with speech enabled. You can then do either M-x
dtk-set-language or C-e d S to change the language (fr for French, en
for English).

During typing emacs will pronouce each letter as it is typed, and then
each word after a space is typed. If you want to pronounce an existing
word/line/sentence you can use the movement commands:

* Move then speak word/sentence after point (M-f, M-b, M-e, M-a). 
* Move then speak entire line at point (C-a, C-e C-e, C-n, C-p, up/down arrows).

Note that to move to the end of the line you need two C-e rather
than one as in usual emacs, because emacspeak uses C-e to prefix all
its commands.

My son has the tendency to hold down a key for a long time, which
repeatedly inserts that character, and makes the voice act strangely
(it wants to speak each inserted character). So to turn off key
repeats in Ubuntu I did Settings -> Universal Access -> Repeat Keys ->
Off.

This setup is great for learning to type/read letters/numbers/words in
English or French, but it is not ideal if you really want to write a
French language text in emacs, but you want to hear emacs text such as
"buffer" etc pronouced in English. Since a lot of emacs user
interface text is fixed in English it may be useful to install
[multispeech](http://poretsky.homelinux.net/packages/) which can speak
in several languages without having to manually switch between them.



