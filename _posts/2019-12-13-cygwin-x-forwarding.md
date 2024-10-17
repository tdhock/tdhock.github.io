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
Or on recent versions of windows, for some reason there is no Xwin server under start menu, but you can always open up cygwin terminal and then run `startxwin`.

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
ssh -Y th798@monsoon.hpc.nau.edu
```

and put in your password to get a shell on monsoon. 
Note that the -Y flag for ssh enables trusted X11 forwarding, which
are not subjected to the X11 SECURITY extension controls. (from man ssh)

You can then open
up any X windows program and see the windows on your own computer,
e.g.

```
emacs -fh &
```

Some references:

[Starting
cygwin/x](https://x.cygwin.com/docs/ug/using.html#using-starting)

[Displaying remote clients](https://x.cygwin.com/docs/ug/using-remote-apps.html)

[Cygwin
FAQ](https://x.cygwin.com/docs/faq/cygwin-x-faq.html#q-xserver-nolisten-tcp-default)

UPDATE 5 Apr 2021! Monsoon no longer supports running rstudio via X
forwarding. Instead you can run [RStudio on a compute node via the
OnDemand web
interface](https://ondemand.hpc.nau.edu/pun/sys/dashboard/batch_connect/sys/RStudio/session_contexts/new).

If you still want to use R inside emacs on the cluster, remember to
put the following in `~/.bashrc`

```shell-script
export R_LIBS_USER=$HOME/R/%v
module load R
```

UPDATE 4 Oct 2022! An easier method, after starting xwin server, which
does not involve lxterminal, is to just set the DISPLAY variable in
Start -> cygwin64 terminal -> then type

```shell-script
DISPLAY=:0.0 ssh -Y linux.ac.nau.edu
```
