---
layout: post
title: Installing Ubuntu on an old Mac
description: Step by step instructions
---

Today I bought a 2008 MacBook from NAU property surplus for $5. Apple
no longer support 15 year old computers like this, so I downloaded
Ubuntu 18.04 LTS, same as I have on my other MacBook Pro (from circa
2010). I tried using a more recent OS (22.04, 20.04) but both of those
require a USB drive with more than 4GB disk space, so I ended up with
18.04 which takes only about 2GB (probably a good idea too since I
know it works on similar MacBook Pro hardware). I used Startup Disk
Creator on Ubuntu to create a bootable USB drive from the iso
file. Then I put the bootable USB drive into the 2008 MacBook, and
started up with option key held down, and it shows a menu to select
which disk to boot, followed by installation menus, on which I took
all the defaults. Installation finished after about 15 minutes, after
which it asks for a restart, take out USB stick, type enter, I see
login prompt.

No wi-fi adapter found by default. I think it was like this with my
Pro as well, and [here is a
fix](https://askubuntu.com/questions/1076964/macbook-can-t-find-wifi-for-ubuntu-18-04). I
set mirror to university of Arizona (arizona.edu), in software &
updates, then it updates the package list, then I click Additional
Drivers tab, Using Broadcom radio button, apply, restart, it works!

Some more differences:
- Pro has firewire and SD card ports, which I never use (2008 does
  not).
- Pro CD drive no longer works, 2008 does!
- Storage: Pro has 250GB Hitachi, 240GB OWC Mercury Electra 3G SSD
  (seems faster).
- Both have 4GB RAM.
- Pro has Intel Core2 Duo CPU P8600 @ 2.40GHz, 2008 has P7350 @ 2.00GHz

I copied some photos into Pictures, and it crashes the whole computer
when I double click them. (update?)

sudo snap install emacs

sudo apt install git gnome-tweak-tool

Settings, trackpad, natural scrolling off.

[Caps lock is another control key](https://askubuntu.com/questions/33774/how-do-i-remap-the-caps-lock-and-ctrl-keys). gnome-tweaks -> Keyboard & Mouse -> Additional Layout Options, Ctrl position, Caps Lock as Ctrl.

Region and Language, Manage installed languages, install,
install/remove languages, French check mark, apply, logout,
login. Input sources, +, French, French.
