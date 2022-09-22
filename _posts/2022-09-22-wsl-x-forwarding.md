---
layout: post
title: GUI for WSL on Windows 10
description: use cygwin instead of vcxsrv 
---

Recent versions of Windows now can install Ubuntu via WSL (Windows
Subsystem for Linux), but by default in Windows 10 you just get a
terminal, so no GUI apps. This tutorial explains how to run WSL GUI
apps using cygwin on Windows 10.

https://techcommunity.microsoft.com/t5/windows-dev-appconsult/running-wsl-gui-apps-on-windows-10/ba-p/1493242
says to use https://sourceforge.net/projects/vcxsrv/ but I already
have cygwin installed, so this tutorial explains how to use that instead.

In wsl, first run `apt install x11-apps` to get xclock for testing.

```
root@cmp2986:/mnt/c/WINDOWS/system32# xclock
Error: Can't open display:
```

Start -> xwin server. X icon should appear in task bar next to date.

At that point running `DISPLAY=:0.0 lxterminal.exe` in cygwin terminal
should pop up a new lxterminal. But

```
cygwin$ DISPLAY=localhost:0.0 lxterminal.exe

(lxterminal:1739): Gtk-WARNING **: cannot open display: localhost:0.0
```

That is because cygwin's xwin server turns off network connections by
default. The
[FAQ](https://x.cygwin.com/docs/faq/cygwin-x-faq.html#q-xserver-nolisten-tcp-default)
explains that we can allow xwin server to listen for network
connections by starting it via

```
cygwin$ startxwin -- -listen tcp

Welcome to the XWin X Server
Vendor: The Cygwin/X Project
Release: 1.21.1.4
OS: CYGWIN_NT-10.0-19042 cmp2986 3.3.6-341.x86_64 2022-09-05 11:15 UTC x86_64
OS: Windows 10  [Windows NT 10.0 build 19042] x64
Package: version 21.1.4-2 built 2022-09-21
...
winInitMultiWindowWM - DISPLAY=:1.0
winMultiWindowXMsgProc - DISPLAY=:1.0
winMultiWindowXMsgProc - xcb_connect() returned and successfully opened the display.
winProcEstablishConnection - winInitClipboard returned.
winClipboardThreadProc - DISPLAY=:1.0
winInitMultiWindowWM - xcb_connect () returned and successfully opened the display.
winClipboardProc - xcb_connect () returned and successfully opened the display.
Using Composite redirection
```

Then running `DISPLAY=localhost:1.0 lxterminal.exe` in a different
cygwin terminal should pop up a new lxterminal. But in wsl terminal we get:

```
root@cmp2986:/mnt/c/WINDOWS/system32# DISPLAY=localhost:1.0 xclock
Authorization required, but no authorization protocol specified
Error: Can't open display: localhost:1.0
```

To fix that we can use xhost, [as explained on
superuser](https://superuser.com/questions/1174563/when-trying-to-connect-remote-clients-to-cygwin-x-i-get-authorization-required).

```
cygwin$ DISPLAY=:1.0 xhost localhost
localhost being added to access control list
```

After that you should be able to run GNU/Linux X11 GUI apps, 

```
root@cmp2986:/mnt/c/WINDOWS/system32# DISPLAY=localhost:1.0 xclock
root@cmp2986:/mnt/c/WINDOWS/system32# DISPLAY=localhost:1.0 emacs
```


