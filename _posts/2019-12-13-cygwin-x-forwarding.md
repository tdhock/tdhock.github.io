---
layout: post
title: X forwarding on windows
description: Installing and configuring cygwin
---

Today I explained to one of my students the advantages of X forwarding
for interactive with the NAU Monsoon computer cluster.

To get it working first go to the [Installation
page](https://cygwin.com/install.html) for cygwin and download the
installer. When you get to "Select Packages" make sure to select
View "Full" and the Search for the following packages:

* openssh
* xinit
* cygutils-x11
* lxterminal

For each package, under the New column, click the arrow and then
choose the most recent version to install.

After installation, go to Start menu -> Xwin server.

Then in a Cygwin64 terminal:

```
DISPLAY=:0.0 lxterminal.exe
```

That will pull up another terminal. xterm could be used instead but
its default text is way too small. In lxterminal you can do Edit ->
Preferences -> Terminal font -> Size to adjust the font size
permanently, or use CTRL-SHIFT then plus or minus to adjust it
temporarily.

After that in lxterminal do

```
ssh -Y monsoon.hpc.nau.edu
```

and put in your password to get a shell on monsoon. You can then open
up any X windows program and see the windows on your own computer,
e.g.

```
emacs -fh &
```

or

```
module load rstudio
rstudio &
```

Note that the -Y flag for ssh enables trusted X11 forwarding, which
are not subjected to the X11 SECURITY extension controls. (from man ssh)

Some references:

[Starting
cygwin/x](https://x.cygwin.com/docs/ug/using.html#using-starting)

[Displaying remote clients](https://x.cygwin.com/docs/ug/using-remote-apps.html)

[Cygwin
FAQ](https://x.cygwin.com/docs/faq/cygwin-x-faq.html#q-xserver-nolisten-tcp-default)
