---
layout: post
title: Setting default web browser in LXDE
description: Need to create a .desktop file
---

My work-provided Windows computer died last week, and so I have been
using my Dell Inspiron 1525 with LXDE/Lubuntu 18.04 with the
lightweight Falkon web browser which I launch from the Application
Launch Bar at the bottom of the screen. However sometimes the chromium
web browser was being opened, for example when I click a link in
emacs. Here is how I set Falkon to be used instead.

I found
[a related article on stackoverflow](https://stackoverflow.com/questions/41172692/xdg-open-not-open-default-browser)
with a response from Lawful Lazy that helped me find a solution that uses
xdg-settings.

First I created the file `~/.local/share/applications/falkon.desktop`
with the following contents:

```
[Desktop Entry]
Type=Application
Name=falkon
Comment=Falkon minimal web browser
Terminal=false
Exec=falkon
Categories=Network;WebBrowser
```

Then I ran the command line

```
xdg-settings set default-web-browser falkon.desktop
```

Test it works via

```
xdg-open http://mcgill.ca
```
