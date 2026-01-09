---
layout: post
title: Keyboard remapping on windows
description: Changing caps lock to control on windows
---

I have been using a new work-provided Windows computer since last
week, and today I finally got tired of mistakenly hitting the caps
lock key, which I usually have changed to function as an additional
Control key.

I found
[a related article on superuser](https://superuser.com/questions/909527)
with a response from alexjj that helped me find a solution that uses
[AutoHotKey](https://autohotkey.com).

First I downloaded
[ahk2exe](https://autohotkey.com/download/1.1/Ahk2Exe112401.zip) which
my web browser (Firefox 61 on Windows) said was malware, but I can't
imagine how it could be, since it does not even require admin
privileges to execute (it runs in user-space).

Then I used Notepad to create a `cap2ctrl.ahk` file (an AutoHotKey
script) containing

``` 
Capslock::Control 
AppsKey::Alt
```

Then I used ahk2exe to convert the ahk file to an executable
`caps2ctrl.exe` file. Opening this file solves the problem -- caps
lock is now an additional Control key! It also creates a new item with
an H icon on the bottom menu bar -- it can be used to disable the
remapping.

Finally I opened the C:\Users\user\AppData folder by typing
`%appdata%` at the windows start menu. (the folder is hidden by
default) Then I copied the caps2ctrl.exe file to
`C:\Users\user\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup`
and it runs every time I log in.

### Update 9 jan 2026

Added `AppsKey::Alt` to change right menu key to another Alt (useful for some emacs commands).
