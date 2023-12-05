---
layout: post
title: Installing Ubuntu on an old Mac
description: Step by step instructions
---

Today I bought a 2008 MacBook from NAU property surplus for $5. Apple
no longer supports 15 year old computers like this, so I downloaded
Ubuntu 18.04 LTS, same as I have on my other MacBook Pro (from circa
2010). I tried using a more recent OS (22.04, 20.04) but both of those
require a USB drive with more than 4GB disk space, so I installed
18.04 which takes only about 2GB space on the USB drive (probably a
good idea too since I know it works on similar MacBook Pro
hardware). I used Startup Disk Creator on Ubuntu to create a bootable
USB drive from the iso file. Then I put the bootable USB drive into
the 2008 MacBook, and started up with option key held down, and it
shows a menu to select which disk to boot, followed by installation
menus, on which I took all the defaults. Installation finished after
about 15 minutes, after which it asks for a restart, take out USB
stick, type enter, I see login prompt.

After that I did two distribution upgrades, to 20.04 (brightness keys
did not work) and then 22.04 (seems to work best, and memory usage of
system is reasonable).

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
when I double click them. same with firefox. Try Additional Drivers,
NVIDIA Corporation: C79 [GeForce 9400M] (MacBook5, 1), change from
Using X.Org X server to Using NVIDIA binary driver.

firefox -> settings -> privacy and security -> do not track always,
logins and password uncheck. add-ons and themes -> ublock origin, add
to firefox.

Settings, trackpad, natural scrolling off.

```
sudo snap install emacs
sudo apt install git gnome-tweak-tool
```

[Caps lock is another control key](https://askubuntu.com/questions/33774/how-do-i-remap-the-caps-lock-and-ctrl-keys). gnome-tweaks -> Keyboard & Mouse -> Additional Layout Options, Ctrl position, Caps Lock as Ctrl.

Region and Language, Manage installed languages, install,
install/remove languages, French check mark, apply, logout,
login. Input sources, +, French, French.

```
ssh-keygen
```

firefox, github.com, settings, keys, new key, copy text from
~/.ssh/id_rsa.pub and paste it in github, save.

```
git clone git@github.com:tdhock/tdhock.github.io
git clone git@github.com:tdhock/dotfiles
cat dotfiles/.bashrc >> ~/.bashrc
mkdir bin
echo 'PATH=$HOME/bin:$PATH' >> ~/.bashrc
```

emacs, put
```elisp
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/") t)
```

M-x package-list-packages a for always

```
ess
poly-R
poly-markdown
poly-org
autocomplete
org
```

then put the whole .emacs

```elisp
;; font size in units of 1/10 point.
(set-face-attribute 'default nil :height 150)

;; set frame startup size in number of characters
(setq initial-frame-alist
      '((top . 1) (left . 1) (width . 80) (height . 30)))

;; Need to set style before loading ess.
(setq ess-default-style 'RStudio)
(load "ess-site.el")
(define-key ess-r-mode-map "_" #'ess-insert-assign)
(define-key inferior-ess-r-mode-map "_" #'ess-insert-assign)

;; Most important ESS options.
(setq ess-eval-visibly-p nil)
(setq ess-ask-for-ess-directory nil)
(setq ess-eldoc-show-on-symbol t)
(setq ess-default-style 'RStudio)
(setq ess-startup-directory 'default-directory);;https://github.com/emacs-ess/ESS/issues/1187#issuecomment-1038360149
(with-eval-after-load "ess-mode" 
  (define-key ess-mode-map ";" #'ess-insert-assign)
  (define-key inferior-ess-mode-map ";" #'ess-insert-assign)
  )
(setq tab-always-indent 'complete)

;; turn off pkg mode (eval bug TDH 16 Jan 2019)
(setq ess-r-package-auto-activate nil)
(setq ess-r-package-auto-set-evaluation-env nil)
;; from http://ygc.name/2014/12/07/auto-complete-in-ess/
(add-to-list 'load-path "~/auto-complete-1.3.1")
(setq ess-use-auto-complete t)
(require 'auto-complete)
(require 'auto-complete-config)
(add-to-list 'ac-dictionary-directories "~/auto-complete-1.3.1/dict")
(ac-config-default)
(auto-complete-mode)
(setq ac-auto-start nil)
;(setq ac-auto-start 5)
(setq ac-quick-help-delay 2)
(define-key ac-mode-map [C-tab] 'auto-complete);C-tab auto-complete
(setq ess-describe-at-point-method 'tooltip);C-c C-d C-e C-e help window
;; Emacs stuff.
(global-set-key "\M-s" 'isearch-forward-regexp)
(global-set-key "\M-r" 'isearch-backward-regexp)
(if (functionp 'tool-bar-mode) (tool-bar-mode 0))
(if (functionp 'scroll-bar-mode) (scroll-bar-mode -1))
(menu-bar-mode 0)
(setq inhibit-startup-screen t)
(show-paren-mode 1)
;; Org.
(setq org-src-fontify-natively t)
;; Compile with F9, view PDF with F10.
(setq compilation-scroll-output t)
(setq compile-command "make ")
(setq compilation-read-command nil)
(defun evince-pdf ()
  "homebrew view pdf, convenient from latex"
  (interactive)
  ;;(expand-file-name "~/foo")
  ;;(shell-quote-argument "some file with spaces")
  (shell-command
   (concat "evince " (file-name-sans-extension (buffer-file-name)) ".pdf &"))
  )
;; for compiling R packages.
(global-set-key [f9] 'compile)
(add-to-list 'safe-local-variable-values '(compile-command . "R -e \"Rcpp::compileAttributes('..')\" && R CMD INSTALL .. && R --vanilla < ../tests/testthat/test-CRAN.R"))
(add-to-list 'safe-local-variable-values '(compile-command . "R -e \"devtools::test()\""))
(global-set-key [f10] 'evince-pdf)
;; turn on font-lock mode
(when (fboundp 'global-font-lock-mode)
  (global-font-lock-mode t))
;; default to unified diffs
(setq diff-switches "-u")
;elisp
(add-hook 'emacs-lisp-mode-hook 'turn-on-eldoc-mode)
(put 'downcase-region 'disabled nil)
(put 'narrow-to-region 'disabled nil)
;; https://github.com/melpa/melpa#usage
(require 'package)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)
;;excute all code blocks in an Rmd.
(defun Rmd-execute-all-code-blocks ()
  "Run keyboard macro until bell rings"
  (interactive)
  (execute-kbd-macro "\C-s```{\C-n\C-a\C- \C-s```\C-p\C-e\C-c\C-r" 0)
  )
```

```
sudo snap install valgrind
# below for compiling base R.
sudo apt install r-cran-rgl xorg-dev aptitude libcairo-dev tk-dev libpango1.0-dev default-jre default-jdk libpcre2-dev libcurl4-gnutls-dev zlib1g-dev libtiff-dev texlive-latex-base fonts-inconsolata texlive-fonts-extra texlive-science texinfo qpdf
# below for compiling common packages (devtools etc)
sudo apt install libharfbuzz-dev libfribidi-dev libssl-dev libxml2-dev libssh2-1-dev libgit2-dev
mkdir R
cd R
wget https://cloud.r-project.org/src/base/R-4/R-4.3.0.tar.gz
tar xf R-4.3.0.tar.gz
cd R-4.3.0
./configure --prefix=$HOME --with-cairo --with-blas --with-lapack --enable-R-shlib --with-valgrind-instrumentation=2 --enable-memory-profiling
make
make install
```

NAU VPN

```
sudo apt install network-manager-openconnect-gnome
```

get private key

```
rsync -rvz monsoon.hpc.nau.edu:.gnupg/ ~/.gnupg/
```

Tell git to sign commits, [github docs](https://docs.github.com/en/authentication/managing-commit-signature-verification/telling-git-about-your-signing-key)

```
git config --global user.signingkey 680AA3B73AA19C4F
git config --global commit.gpgsign true
git config --global user.email "toby.hocking@r-project.org"
git config --global user.name "Toby Dylan Hocking"
```

maybe install python packages + miniconda.

```
sudo apt install python3-pip python3-flake8 python3-setuptools python3-venv # for elpy
conda create -n new-env
conda activate new-env
conda install python=3.10
pip install plotnine
```

## Some problems I have encountered in the past

### random gcc segfaults

These happen randomly when attempting to compile some R packages, fix
by [building a newer gcc](https://iamsorush.com/posts/build-gcc11/).

```
cd gcc-releases-gcc-13.1.0
./configure --prefix=$HOME --disable-multilib
make
make install
```

or below we additionally specify

* PATH not including $HOME
* CFLAGS/CXXFLAGS/CPPFLAGS with -march=core2
* --enable-ld to build and install ld (linker not installed by
  default, there may be problems using the $HOME/bin compilers with
  /usr/bin/ld)

```
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/snap/bin:/snap/emacs/current/usr/bin CFLAGS=-march=core2 CXXFLAGS=-march=core2 CPPFLAGS=-march=core2 ./configure --prefix=$HOME --disable-multilib --enable-ld
```

### no pango, R package vignette building fails, x11 font error

Note that if the above configure does not have pango we will see:

```
checking whether pkg-config knows about cairo and pango... no
```

Then when doing R CMD check, 

```
* creating vignettes ... ERROR
--- re-building ‘Custom_Plots.Rmd’ using knitr
Quitting from lines 22-80 (Custom_Plots.Rmd) 
Error: processing vignette 'Custom_Plots.Rmd' failed with diagnostics:
X11 font -adobe-helvetica-%s-%s-*-*-%d-*-*-*-*-*-*-*, face 1 at size 9 could not be loaded
--- failed re-building ‘Custom_Plots.Rmd’
```

Why is X11 graphics device being used instead of cairo? The following
help page says it should be the default.

```
> ?options
...
     ‘bitmapType’: (Unix only, incl. macOS) character.  The default
          type for the bitmap devices such as png.  Defaults to
          ‘"cairo"’ on systems where that is available, or to
          ‘"quartz"’ on macOS where that is available.
```

Below the help page says the default should be cairo if R was built using pangocairo:

```
> ?x11
...
    type: character string, one of ‘"Xlib"’, ‘"cairo"’, ‘"nbcairo"’ or
          ‘"dbcairo"’.  Only the first will be available if the system
          was compiled without support for cairographics.  The default
          is ‘"cairo"’ where R was built using ‘pangocairo’ (often not
          the case on macOS), otherwise ‘"Xlib"’.
```

So I think the problem was no pango dev pkg, fix by doing `apt install
libpango1.0-dev` after which configure says

```
checking whether pkg-config knows about cairo and pango... yes
checking whether cairo including pango is >= 1.2 and works... yes
```

At run-time it works:

```
> devtools::build_vignettes("~/R/atime")
ℹ Installing atime in temporary library
ℹ Building vignettes for atime
--- re-building ‘cum_median.Rmd’ using knitr
processing file: cum_median.Rmd
output file: cum_median.md
--- finished re-building ‘cum_median.Rmd’

--- re-building ‘Custom_Plots.Rmd’ using knitr
processing file: Custom_Plots.Rmd
output file: Custom_Plots.md
--- finished re-building ‘Custom_Plots.Rmd’
```

### tcltk does not work

Looks like below at configure time

```
~/R/R-4.3.0$ ./configure
...
checking for tclConfig.sh... no
checking for tclConfig.sh in library (sub)directories... no
checking for tkConfig.sh... no
checking for tkConfig.sh in library (sub)directories... no
checking for tcl.h... no
```

and like below at run time

```
> library(tcltk)
Error: package or namespace load failed for ‘tcltk’:
 .onLoad failed in loadNamespace() for 'tcltk', details:
  call: fun(libname, pkgname)
  error: Tcl/Tk support is not available on this system
In addition: Warning message:
S3 methods ‘as.character.tclObj’, ‘as.character.tclVar’, ‘as.double.tclObj’, ‘as.integer.tclObj’, ‘as.logical.tclObj’, ‘as.raw.tclObj’, ‘print.tclObj’, ‘[[.tclArray’, ‘[[<-.tclArray’, ‘$.tclArray’, ‘$<-.tclArray’, ‘names.tclArray’, ‘names<-.tclArray’, ‘length.tclArray’, ‘length<-.tclArray’, ‘tclObj.tclVar’, ‘tclObj<-.tclVar’, ‘tclvalue.default’, ‘tclvalue.tclObj’, ‘tclvalue.tclVar’, ‘tclvalue<-.default’, ‘tclvalue<-.tclVar’, ‘close.tkProgressBar’ were declared in NAMESPACE but not found 
```

fix by doing `apt install tk-dev` after which configure says

```
checking for tclConfig.sh... no
checking for tclConfig.sh in library (sub)directories... /usr/lib/tclConfig.sh
checking for tkConfig.sh... no
checking for tkConfig.sh in library (sub)directories... /usr/lib/tkConfig.sh
checking for tcl.h... yes
checking for tk.h... yes
checking whether compiling/linking Tcl/Tk code works... yes
```

At runtime it works:

```
> library(tcltk)
> 
```

### brightness buttons

screen brightness buttons do not respond on 20.04,
[method 2 on this page](https://www.debugpoint.com/2-ways-fix-laptop-brightness-problem-ubuntu-linux/) worked for changing the brightness

```
sudo add-apt-repository ppa:apandada1/brightness-controller
sudo apt update
sudo apt install brightness-controller
brightness-controller 
```

brightness keys do work on 22.04.

### update woes

Updating the kernel on 28 June 2023 resulted in a non-bootable
machine. I ran apt autoremove and I think it removed the old working
kernel before I actually tried the new kernel and found out it does
not work. I guess the solution should be reinstalling the older
kernel, but how?

[Hold down option to boot from live USB drive](https://askubuntu.com/questions/281119/how-do-you-run-update-grub).

```
sudo su
mount /dev/sda2 /mnt
for f in sys dev proc ; do mount --bind /$f /mnt/$f ; done
chroot /mnt
sudo nano /etc/default/grub
# uncomment GRUB_TERMINAL=console
update-grub
```

Found linux images: 5.15.0-75 and 76 generic.

Restart. boot menu now instead of black screen, select 75 generic,
Loading initial ramdisk ... freeze.

[This page](https://askubuntu.com/questions/1240152/boot-freezes-and-loading-initial-ramdisk) says to try the following but that did not work for me:

```
GRUB_CMDLINE_LINUX_DEFAULT="dis_ucode_ldr"
```

Try installing from usb after chroot? it works with:

```
cp /media/ubuntu/*.deb /mnt/home/tdhock
chroot /mnt
dpkg -i /home/tdhock/*.deb
```

where *.deb files were manually downloaded from Ubuntu web site,

* <https://launchpad.net/ubuntu/jammy/amd64/linux-image-generic/5.15.0.72.70>
* <https://launchpad.net/ubuntu/jammy/amd64/linux-headers-5.15.0-72-generic/5.15.0-72.79>
* <https://launchpad.net/ubuntu/jammy/amd64/bcmwl-kernel-source>

```
(base) tdhock@maude-MacBookPro:/media/tdhock/MA CL/2023-CSQ$ ls /media/tdhock/MA\ CL/ubuntu-jammy-old-linux-kernel-packages/
bcmwl-kernel-source_6.30.223.271+bdcom-0ubuntu8_amd64.deb
linux-headers-5.15.0-72_5.15.0-72.79_all.deb
linux-image-5.15.0-72-generic_5.15.0-72.79_amd64.deb
linux-image-generic_5.15.0.72.70_amd64.deb
linux-modules-5.15.0-72-generic_5.15.0-72.79_amd64.deb
linux-modules-extra-5.15.0-72-generic_5.15.0-72.79_amd64.deb
```

Phew! Moral of the story: never run `apt autoremove` unless you have
successfully restarted!

Wi-fi was not working right away: to fix, need to first install via `dpkg -i` 

* `linux-headers-5.15.0-72_5.15.0-72.79_all.deb`  then 
* `bcmwl-kernel-source_6.30.223.271+bdcom-0ubuntu8_amd64.deb`

(the machine will boot with the others but without these two, no wi-fi)

[Launchpad](https://launchpad.net/ubuntu/+source/linux-meta)
linux-meta package page says that there should be a version 25
available from the main jammy repo. Do I have access to that from my
current sources?

```
(base) tdhock@tdhock-MacBook:~$ apt-cache madison linux-generic
linux-generic | 5.15.0.76.74 | http://archive.ubuntu.com/ubuntu jammy-security/main amd64 Packages
linux-generic | 5.15.0.25.27 | http://archive.ubuntu.com/ubuntu jammy/main amd64 Packages
(base) tdhock@tdhock-MacBook:~$ apt list linux-generic
En train de lister... Fait
linux-generic/jammy-security,now 5.15.0.76.74 amd64  [installé, automatique]
N: Il y a une version supplémentaire 1. Veuillez utiliser l'opérande « -a » pour la voir.
(base) tdhock@tdhock-MacBook:~$ apt -a list linux-generic
En train de lister... Fait
linux-generic/jammy-security,now 5.15.0.76.74 amd64  [installé, automatique]
linux-generic/jammy 5.15.0.25.27 amd64

(base) tdhock@tdhock-MacBook:~$ apt-cache policy linux-generic
linux-generic:
  Installé : 5.15.0.76.74
  Candidat : 5.15.0.76.74
 Table de version :
 *** 5.15.0.76.74 500
        500 http://archive.ubuntu.com/ubuntu jammy-security/main amd64 Packages
        100 /var/lib/dpkg/status
     5.15.0.25.27 500
        500 http://archive.ubuntu.com/ubuntu jammy/main amd64 Packages
```

Yes the above output says the older `25.27` package is available from
`jammy/main`. Let's try to install that old version using the commands
below:

```
(base) tdhock@tdhock-MacBook:~$ sudo apt install linux-generic=5.15.0.25.27
[sudo] Mot de passe de tdhock : 
Désolé, essayez de nouveau.
[sudo] Mot de passe de tdhock : 
Lecture des listes de paquets... Fait
Construction de l'arbre des dépendances... Fait
Lecture des informations d'état... Fait      
Vous pouvez lancer « apt --fix-broken install » pour corriger ces problèmes.
Les paquets suivants contiennent des dépendances non satisfaites :
 linux-generic : Dépend: linux-image-generic (= 5.15.0.25.27) mais 5.15.0.72.70 devra être installé
                 Dépend: linux-headers-generic (= 5.15.0.25.27) mais 5.15.0.76.74 devra être installé
E: Dépendances non satisfaites. Essayez « apt --fix-broken install » sans paquet
   (ou indiquez une solution).
(base) tdhock@tdhock-MacBook:~$ apt --fix-broken install
E: Impossible d'ouvrir le fichier verrou /var/lib/dpkg/lock-frontend - open (13: Permission non accordée)
E: Impossible d'obtenir le verrou de dpkg (/var/lib/dpkg/lock-frontend). Avez-vous les droits du superutilisateur ?
(base) tdhock@tdhock-MacBook:~$ sudo apt --fix-broken install
Lecture des listes de paquets... Fait
Construction de l'arbre des dépendances... Fait
Lecture des informations d'état... Fait      
Correction des dépendances... Fait
Les paquets suivants ont été installés automatiquement et ne sont plus nécessaires :
  linux-headers-5.15.0-75 linux-headers-5.15.0-75-generic
  linux-image-5.15.0-75-generic linux-modules-5.15.0-75-generic
  linux-modules-extra-5.15.0-75-generic
Veuillez utiliser « sudo apt autoremove » pour les supprimer.
Les paquets supplémentaires suivants seront installés : 
  linux-image-generic
Les paquets suivants seront mis à jour :
  linux-image-generic
1 mis à jour, 0 nouvellement installés, 0 à enlever et 0 non mis à jour.
1 partiellement installés ou enlevés.
Il est nécessaire de prendre 2 494 o dans les archives.
Après cette opération, 0 o d'espace disque supplémentaires seront utilisés.
Souhaitez-vous continuer ? [O/n] 
Réception de :1 http://archive.ubuntu.com/ubuntu jammy-security/main amd64 linux-image-generic amd64 5.15.0.76.74 [2 494 B]
2 494 o réceptionnés en 0s (22,4 ko/s)              
(Lecture de la base de données... 461237 fichiers et répertoires déjà installés.
)
Préparation du dépaquetage de .../linux-image-generic_5.15.0.76.74_amd64.deb ...
Dépaquetage de linux-image-generic (5.15.0.76.74) sur (5.15.0.72.70) ...
Paramétrage de linux-image-generic (5.15.0.76.74) ...
Paramétrage de linux-headers-5.15.0-72-generic (5.15.0-72.79) ...
/etc/kernel/header_postinst.d/dkms:
 * dkms: running auto installation service for kernel 5.15.0-72-generic
   ...done.
(base) tdhock@tdhock-MacBook:~$ sudo apt install linux-generic=5.15.0.25.27
Lecture des listes de paquets... Fait
Construction de l'arbre des dépendances... Fait
Lecture des informations d'état... Fait      
Certains paquets ne peuvent être installés. Ceci peut signifier
que vous avez demandé l'impossible, ou bien, si vous utilisez
la distribution unstable, que certains paquets n'ont pas encore
été créés ou ne sont pas sortis d'Incoming.
L'information suivante devrait vous aider à résoudre la situation : 

Les paquets suivants contiennent des dépendances non satisfaites :
 linux-generic : Dépend: linux-image-generic (= 5.15.0.25.27) mais 5.15.0.76.74 devra être installé
                 Dépend: linux-headers-generic (= 5.15.0.25.27) mais 5.15.0.76.74 devra être installé
E: Impossible de corriger les problèmes, des paquets défectueux sont en mode « garder en l'état ».
(base) tdhock@tdhock-MacBook:~$ sudo apt install linux-generic=5.15.0.25.27 linux-image-generic=5.15.0.25.27 linux-headers-generic=5.15.0.25.27
Lecture des listes de paquets... Fait
Construction de l'arbre des dépendances... Fait
Lecture des informations d'état... Fait      
Les paquets suivants ont été installés automatiquement et ne sont plus nécessaires :
  linux-headers-5.15.0-75 linux-headers-5.15.0-75-generic
  linux-image-5.15.0-75-generic linux-modules-5.15.0-75-generic
  linux-modules-extra-5.15.0-75-generic
Veuillez utiliser « sudo apt autoremove » pour les supprimer.
Les paquets supplémentaires suivants seront installés : 
  linux-headers-5.15.0-25 linux-headers-5.15.0-25-generic
  linux-image-5.15.0-25-generic linux-modules-5.15.0-25-generic
  linux-modules-extra-5.15.0-25-generic
Paquets suggérés :
  fdutils linux-doc | linux-source-5.15.0 linux-tools
Les NOUVEAUX paquets suivants seront installés :
  linux-headers-5.15.0-25 linux-headers-5.15.0-25-generic
  linux-image-5.15.0-25-generic linux-modules-5.15.0-25-generic
  linux-modules-extra-5.15.0-25-generic
Les paquets suivants seront mis à une VERSION INFÉRIEURE :
  linux-generic linux-headers-generic linux-image-generic
0 mis à jour, 5 nouvellement installés, 3 remis à une version inférieure, 0 à enlever et 0 non mis à jour.
Il est nécessaire de prendre 110 Mo dans les archives.
Après cette opération, 560 Mo d'espace disque supplémentaires seront utilisés.
Souhaitez-vous continuer ? [O/n] 
Réception de :1 http://archive.ubuntu.com/ubuntu jammy/main amd64 linux-modules-5.15.0-25-generic amd64 5.15.0-25.25 [22,0 MB]
Réception de :2 http://archive.ubuntu.com/ubuntu jammy/main amd64 linux-image-5.15.0-25-generic amd64 5.15.0-25.25 [10,9 MB]
Réception de :3 http://archive.ubuntu.com/ubuntu jammy/main amd64 linux-modules-extra-5.15.0-25-generic amd64 5.15.0-25.25 [61,9 MB]
Réception de :4 http://archive.ubuntu.com/ubuntu jammy/main amd64 linux-generic amd64 5.15.0.25.27 [1 696 B]
Réception de :5 http://archive.ubuntu.com/ubuntu jammy/main amd64 linux-image-generic amd64 5.15.0.25.27 [2 564 B]
Réception de :6 http://archive.ubuntu.com/ubuntu jammy/main amd64 linux-headers-5.15.0-25 all 5.15.0-25.25 [12,3 MB]
Réception de :7 http://archive.ubuntu.com/ubuntu jammy/main amd64 linux-headers-5.15.0-25-generic amd64 5.15.0-25.25 [2 802 kB]
Réception de :8 http://archive.ubuntu.com/ubuntu jammy/main amd64 linux-headers-generic amd64 5.15.0.25.27 [2 444 B]
110 Mo réceptionnés en 8s (14,2 Mo/s)                                          
Sélection du paquet linux-modules-5.15.0-25-generic précédemment désélectionné.
(Lecture de la base de données... 461237 fichiers et répertoires déjà installés.
)
Préparation du dépaquetage de .../0-linux-modules-5.15.0-25-generic_5.15.0-25.25
_amd64.deb ...
Dépaquetage de linux-modules-5.15.0-25-generic (5.15.0-25.25) ...
Sélection du paquet linux-image-5.15.0-25-generic précédemment désélectionné.
Préparation du dépaquetage de .../1-linux-image-5.15.0-25-generic_5.15.0-25.25_a
md64.deb ...
Dépaquetage de linux-image-5.15.0-25-generic (5.15.0-25.25) ...
Sélection du paquet linux-modules-extra-5.15.0-25-generic précédemment désélecti
onné.
Préparation du dépaquetage de .../2-linux-modules-extra-5.15.0-25-generic_5.15.0
-25.25_amd64.deb ...
Dépaquetage de linux-modules-extra-5.15.0-25-generic (5.15.0-25.25) ...
dpkg: avertissement: dégradation (« downgrade ») de linux-generic depuis 5.15.0.
76.74 vers 5.15.0.25.27
Préparation du dépaquetage de .../3-linux-generic_5.15.0.25.27_amd64.deb ...
Dépaquetage de linux-generic (5.15.0.25.27) sur (5.15.0.76.74) ...
dpkg: avertissement: dégradation (« downgrade ») de linux-image-generic depuis 5
.15.0.76.74 vers 5.15.0.25.27
Préparation du dépaquetage de .../4-linux-image-generic_5.15.0.25.27_amd64.deb .
..
Dépaquetage de linux-image-generic (5.15.0.25.27) sur (5.15.0.76.74) ...
Sélection du paquet linux-headers-5.15.0-25 précédemment désélectionné.
Préparation du dépaquetage de .../5-linux-headers-5.15.0-25_5.15.0-25.25_all.deb
 ...
Dépaquetage de linux-headers-5.15.0-25 (5.15.0-25.25) ...
Sélection du paquet linux-headers-5.15.0-25-generic précédemment désélectionné.
Préparation du dépaquetage de .../6-linux-headers-5.15.0-25-generic_5.15.0-25.25
_amd64.deb ...
Dépaquetage de linux-headers-5.15.0-25-generic (5.15.0-25.25) ...
dpkg: avertissement: dégradation (« downgrade ») de linux-headers-generic depuis
 5.15.0.76.74 vers 5.15.0.25.27
Préparation du dépaquetage de .../7-linux-headers-generic_5.15.0.25.27_amd64.deb
 ...
Dépaquetage de linux-headers-generic (5.15.0.25.27) sur (5.15.0.76.74) ...
Paramétrage de linux-headers-5.15.0-25 (5.15.0-25.25) ...
Paramétrage de linux-headers-5.15.0-25-generic (5.15.0-25.25) ...
/etc/kernel/header_postinst.d/dkms:
 * dkms: running auto installation service for kernel 5.15.0-25-generic

Kernel preparation unnecessary for this kernel. Skipping...
applying patch 0002-Makefile.patch...patching file Makefile
Hunk #1 succeeded at 113 with fuzz 1.
Hunk #2 succeeded at 132 with fuzz 2 (offset 1 line).

applying patch 0003-Make-up-for-missing-init_MUTEX.patch...patching file src/wl/
sys/wl_linux.c
Hunk #1 succeeded at 111 with fuzz 2 (offset 12 lines).

applying patch 0010-change-the-network-interface-name-from-eth-to-wlan.patch...p
atching file src/wl/sys/wl_linux.c
Hunk #1 succeeded at 221 (offset -14 lines).

applying patch 0013-gcc.patch...patching file Makefile

applying patch 0019-broadcom-sta-6.30.223.248-3.18-null-pointer-fix.patch...patc
hing file src/wl/sys/wl_linux.c
Hunk #1 succeeded at 2169 (offset 12 lines).

applying patch 0020-add-support-for-linux-4.3.patch...patching file src/shared/l
inux_osl.c

applying patch 0021-add-support-for-Linux-4.7.patch...patching file src/wl/sys/w
l_cfg80211_hybrid.c

applying patch 0022-add-support-for-Linux-4.8.patch...patching file src/wl/sys/w
l_cfg80211_hybrid.c
Hunk #1 succeeded at 2391 (offset 3 lines).
Hunk #2 succeeded at 2501 (offset 3 lines).
Hunk #3 succeeded at 2933 (offset 9 lines).

applying patch 0023-add-support-for-Linux-4.11.patch...patching file src/include
/linuxver.h
patching file src/wl/sys/wl_linux.c
Hunk #1 succeeded at 2919 (offset 4 lines).

applying patch 0024-add-support-for-Linux-4.12.patch...patching file src/wl/sys/
wl_cfg80211_hybrid.c
Hunk #1 succeeded at 55 (offset 5 lines).
Hunk #2 succeeded at 472 (offset 5 lines).
Hunk #3 succeeded at 2371 (offset 5 lines).
Hunk #4 succeeded at 2388 (offset 5 lines).

applying patch 0025-add-support-for-Linux-4.14.patch...patching file src/shared/
linux_osl.c
Hunk #1 succeeded at 1080 (offset 4 lines).

applying patch 0026-add-support-for-Linux-4.15.patch...patching file src/wl/sys/
wl_linux.c
Hunk #2 succeeded at 2306 (offset 4 lines).
Hunk #3 succeeded at 2368 (offset 4 lines).

applying patch 0027-add-support-for-linux-5.1.patch...patching file src/include/
linuxver.h
Hunk #1 succeeded at 595 (offset 4 lines).

applying patch 0028-add-support-for-linux-5.6.patch...patching file src/shared/l
inux_osl.c
Hunk #1 succeeded at 946 (offset 4 lines).
patching file src/wl/sys/wl_linux.c
Hunk #1 succeeded at 590 (offset 8 lines).
Hunk #2 succeeded at 784 (offset 8 lines).
Hunk #3 succeeded at 3365 (offset 22 lines).

applying patch 0029-Update-for-set_fs-removal-in-Linux-5.10.patch...patching fil
e src/wl/sys/wl_cfg80211_hybrid.c
patching file src/wl/sys/wl_iw.c
patching file src/wl/sys/wl_linux.c
patching file src/wl/sys/wl_linux.h


Building module:
cleaning build area...
make -j2 KERNELRELEASE=5.15.0-25-generic -C /lib/modules/5.15.0-25-generic/build
 M=/var/lib/dkms/bcmwl/6.30.223.271+bdcom/build.....
Signing module:
 - /var/lib/dkms/bcmwl/6.30.223.271+bdcom/5.15.0-25-generic/x86_64/module/wl.ko
This system doesn't support Secure Boot
Secure Boot not enabled on this system.
cleaning build area...

wl.ko:
Running module version sanity check.
 - Original module
   - No original module exists within this kernel
 - Installation
   - Installing to /lib/modules/5.15.0-25-generic/updates/dkms/

depmod....
   ...done.
Paramétrage de linux-headers-generic (5.15.0.25.27) ...
Paramétrage de linux-image-5.15.0-25-generic (5.15.0-25.25) ...
I: /boot/vmlinuz.old is now a symlink to vmlinuz-5.15.0-76-generic
I: /boot/initrd.img.old is now a symlink to initrd.img-5.15.0-76-generic
I: /boot/vmlinuz is now a symlink to vmlinuz-5.15.0-25-generic
I: /boot/initrd.img is now a symlink to initrd.img-5.15.0-25-generic
Paramétrage de linux-modules-5.15.0-25-generic (5.15.0-25.25) ...
Paramétrage de linux-modules-extra-5.15.0-25-generic (5.15.0-25.25) ...
Paramétrage de linux-image-generic (5.15.0.25.27) ...
Paramétrage de linux-generic (5.15.0.25.27) ...
Traitement des actions différées (« triggers ») pour linux-image-5.15.0-25-gener
ic (5.15.0-25.25) ...
/etc/kernel/postinst.d/dkms:
 * dkms: running auto installation service for kernel 5.15.0-25-generic
   ...done.
/etc/kernel/postinst.d/initramfs-tools:
update-initramfs: Generating /boot/initrd.img-5.15.0-25-generic
/etc/kernel/postinst.d/zz-update-grub:
Sourcing file `/etc/default/grub'
Sourcing file `/etc/default/grub.d/init-select.cfg'
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-5.15.0-76-generic
Found initrd image: /boot/initrd.img-5.15.0-76-generic
Found linux image: /boot/vmlinuz-5.15.0-75-generic
Found initrd image: /boot/initrd.img-5.15.0-75-generic
Found linux image: /boot/vmlinuz-5.15.0-72-generic
Found initrd image: /boot/initrd.img-5.15.0-72-generic
Found linux image: /boot/vmlinuz-5.15.0-25-generic
Found initrd image: /boot/initrd.img-5.15.0-25-generic
Memtest86+ needs a 16-bit boot, that is not available on EFI, exiting
Warning: os-prober will not be executed to detect other bootable partitions.
Systems on them will not be added to the GRUB boot configuration.
Check GRUB_DISABLE_OS_PROBER documentation entry.
done
```

From the output above, looks like the older 25 kernel is installed
along with the 75/76 which do not work, and the 72 which does
work. Also headers were installed.

### can not install anything

Now apt complains about being broken, how to fix? 
The init package was broken? See below.

```
(base) tdhock@tdhock-MacBook:~$ sudo apt install zsnes
[sudo] Mot de passe de tdhock : 
Lecture des listes de paquets... Fait
Construction de l'arbre des dépendances... Fait
Lecture des informations d'état... Fait      
Certains paquets ne peuvent être installés. Ceci peut signifier
que vous avez demandé l'impossible, ou bien, si vous utilisez
la distribution unstable, que certains paquets n'ont pas encore
été créés ou ne sont pas sortis d'Incoming.
L'information suivante devrait vous aider à résoudre la situation : 

Les paquets suivants contiennent des dépendances non satisfaites :
 init : Pré-Dépend: systemd-sysv
E: Erreur, pkgProblem::Resolve a généré des ruptures, ce qui a pu être causé par les paquets devant être gardés en l'état.
```

The problem/solution was same as
[this](https://askubuntu.com/questions/1457843/i-somehow-messed-up-package-management-and-dependencies),
went into update manager, changed "only security updates" to "all
updates" which adds jammy-updates source/repo to
`/etc/apt/sources.list`.

### Nvidia binary driver

This is the graphics card I have:

```
(base) tdhock@tdhock-MacBook:~$ lspci|grep VGA
02:00.0 VGA compatible controller: NVIDIA Corporation C79 [GeForce 9400M] (rev b1)
```

This [NVIDIA web
page](https://www.nvidia.com/Download/driverResults.aspx/123709/en-us/)
says that GeForce 9400M is a supported product of the Version: 304.137
driver, Release Date: 2017.9.19.

Looks like it is no longer supported by Ubuntu but [this guy has a PPA](https://launchpad.net/~dokomix/+archive/ubuntu/legacygpu-jammy):

```
(base) tdhock@tdhock-MacBook:~/tdhock.github.io(master*)$ sudo apt install nvidia-304
Lecture des listes de paquets... Fait
Construction de l'arbre des dépendances... Fait
Lecture des informations d'état... Fait      
Les paquets suivants ont été installés automatiquement et ne sont plus nécessaires :
  amd64-microcode emacs-bin-common emacs-common emacs-el intel-microcode
  iucode-tool libm17n-0 libotf1 libwmf0.2-7 libxatracker2 m17n-db thermald
  xcvt xserver-xorg-video-vmware
Veuillez utiliser « sudo apt autoremove » pour les supprimer.
Les paquets supplémentaires suivants seront installés : 
  lib32gcc-s1 libcuda1-304 libxfont1 libxnvctrl0 nvidia-opencl-icd-304
  nvidia-settings screen-resolution-extra xserver-common xserver-xorg-core
  xserver-xorg-input-libinput xserver-xorg-video-vmware
Les paquets suivants seront ENLEVÉS :
  nvidia-340 xserver-xorg-input-wacom xserver-xorg-video-all
  xserver-xorg-video-amdgpu xserver-xorg-video-ati xserver-xorg-video-fbdev
  xserver-xorg-video-intel xserver-xorg-video-nouveau xserver-xorg-video-qxl
  xserver-xorg-video-radeon xserver-xorg-video-vesa
Les NOUVEAUX paquets suivants seront installés :
  lib32gcc-s1 libcuda1-304 libxfont1 libxnvctrl0 nvidia-304
  nvidia-opencl-icd-304 nvidia-settings screen-resolution-extra
Les paquets suivants seront mis à jour :
  xserver-common xserver-xorg-core xserver-xorg-input-libinput
  xserver-xorg-video-vmware
4 mis à jour, 8 nouvellement installés, 11 à enlever et 19 non mis à jour.
Il est nécessaire de prendre 57,6 Mo dans les archives.
Après cette opération, 214 Mo d'espace disque supplémentaires seront utilisés.
Souhaitez-vous continuer ? [O/n] 
Réception de :1 http://archive.ubuntu.com/ubuntu jammy-security/main amd64 lib32gcc-s1 amd64 12.3.0-1ubuntu1~22.04 [63,9 kB]
Réception de :2 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxnvctrl0 amd64 510.47.03-0ubuntu1 [11,5 kB]
Réception de :3 http://archive.ubuntu.com/ubuntu jammy/main amd64 screen-resolution-extra all 0.18.2 [4 396 B]
Réception de :4 http://archive.ubuntu.com/ubuntu jammy/main amd64 nvidia-settings amd64 510.47.03-0ubuntu1 [960 kB]
Réception de :5 https://ppa.launchpadcontent.net/dokomix/legacygpu-jammy/ubuntu jammy/main amd64 libcuda1-304 amd64 304.137-0ubuntu2+dokomix1 [6 945 kB]
Réception de :6 https://ppa.launchpadcontent.net/dokomix/legacygpu-jammy/ubuntu jammy/main amd64 libxfont1 amd64 1:1.5.2-4ubuntu2+dokomix1 [106 kB]
Réception de :7 https://ppa.launchpadcontent.net/dokomix/legacygpu-jammy/ubuntu jammy/main amd64 xserver-xorg-video-vmware amd64 2:13.3.0-3+dokomix1 [81,5 kB]
Réception de :8 https://ppa.launchpadcontent.net/dokomix/legacygpu-jammy/ubuntu jammy/main amd64 xserver-xorg-input-libinput amd64 1:0.30.0-1ubuntu1+dokomix1 [38,3 kB]
Réception de :9 https://ppa.launchpadcontent.net/dokomix/legacygpu-jammy/ubuntu jammy/main amd64 xserver-common all 3:1.17.3-2ubuntu4+dokomix1 [1 919 kB]
Réception de :10 https://ppa.launchpadcontent.net/dokomix/legacygpu-jammy/ubuntu jammy/main amd64 xserver-xorg-core amd64 3:1.17.3-2ubuntu4+dokomix1 [1 569 kB]
Réception de :11 https://ppa.launchpadcontent.net/dokomix/legacygpu-jammy/ubuntu jammy/main amd64 nvidia-304 amd64 304.137-0ubuntu2+dokomix1 [40,1 MB]
Réception de :12 https://ppa.launchpadcontent.net/dokomix/legacygpu-jammy/ubuntu jammy/main amd64 nvidia-opencl-icd-304 amd64 304.137-0ubuntu2+dokomix1 [5 829 kB]
57,6 Mo réceptionnés en 11s (5 142 ko/s)                                       
(Lecture de la base de données... 491408 fichiers et répertoires déjà installés.
)
Suppression de nvidia-340 (340.108-0ubuntu8) ...
Suppression de xserver-xorg-input-wacom (1:1.0.0-3ubuntu1) ...
Suppression de xserver-xorg-video-all (1:7.7+23ubuntu2) ...
Suppression de xserver-xorg-video-amdgpu (22.0.0-1ubuntu0.2) ...
Suppression de xserver-xorg-video-ati (1:19.1.0-2ubuntu1) ...
Suppression de xserver-xorg-video-fbdev (1:0.5.0-2build1) ...
Suppression de xserver-xorg-video-intel (2:2.99.917+git20210115-1) ...
Suppression de xserver-xorg-video-nouveau (1:1.0.17-2build1) ...
Suppression de xserver-xorg-video-qxl (0.1.5+git20200331-3) ...
Suppression de xserver-xorg-video-radeon (1:19.1.0-2ubuntu1) ...
Suppression de xserver-xorg-video-vesa (1:2.5.0-1build4) ...
Sélection du paquet lib32gcc-s1 précédemment désélectionné.
(Lecture de la base de données... 491310 fichiers et répertoires déjà installés.
)
Préparation du dépaquetage de .../00-lib32gcc-s1_12.3.0-1ubuntu1~22.04_amd64.deb
 ...
Dépaquetage de lib32gcc-s1 (12.3.0-1ubuntu1~22.04) ...
Sélection du paquet libcuda1-304 précédemment désélectionné.
Préparation du dépaquetage de .../01-libcuda1-304_304.137-0ubuntu2+dokomix1_amd6
4.deb ...
Dépaquetage de libcuda1-304 (304.137-0ubuntu2+dokomix1) ...
Sélection du paquet libxfont1:amd64 précédemment désélectionné.
Préparation du dépaquetage de .../02-libxfont1_1%3a1.5.2-4ubuntu2+dokomix1_amd64
.deb ...
Dépaquetage de libxfont1:amd64 (1:1.5.2-4ubuntu2+dokomix1) ...
Sélection du paquet libxnvctrl0:amd64 précédemment désélectionné.
Préparation du dépaquetage de .../03-libxnvctrl0_510.47.03-0ubuntu1_amd64.deb ..
.
Dépaquetage de libxnvctrl0:amd64 (510.47.03-0ubuntu1) ...
Préparation du dépaquetage de .../04-xserver-xorg-video-vmware_2%3a13.3.0-3+doko
mix1_amd64.deb ...
Dépaquetage de xserver-xorg-video-vmware (2:13.3.0-3+dokomix1) sur (1:13.3.0-3bu
ild1) ...
Préparation du dépaquetage de .../05-xserver-xorg-input-libinput_1%3a0.30.0-1ubu
ntu1+dokomix1_amd64.deb ...
Dépaquetage de xserver-xorg-input-libinput (1:0.30.0-1ubuntu1+dokomix1) sur (1.2
.1-1) ...
Préparation du dépaquetage de .../06-xserver-common_3%3a1.17.3-2ubuntu4+dokomix1
_all.deb ...
Dépaquetage de xserver-common (3:1.17.3-2ubuntu4+dokomix1) sur (2:21.1.4-2ubuntu
1.7~22.04.2) ...
Préparation du dépaquetage de .../07-xserver-xorg-core_3%3a1.17.3-2ubuntu4+dokom
ix1_amd64.deb ...
Dépaquetage de xserver-xorg-core (3:1.17.3-2ubuntu4+dokomix1) sur (2:21.1.4-2ubu
ntu1.7~22.04.2) ...
dpkg: erreur de traitement de l'archive /tmp/apt-dpkg-install-2ChVh4/07-xserver-
xorg-core_3%3a1.17.3-2ubuntu4+dokomix1_amd64.deb (--unpack) :
 tentative de remplacement de « /usr/bin/cvt », qui appartient aussi au paquet x
cvt 0.1.1-3
dpkg-deb: erreur: le sous-processus coller a été tué par le signal (Relais brisé
 (pipe))
Sélection du paquet nvidia-304 précédemment désélectionné.
Préparation du dépaquetage de .../08-nvidia-304_304.137-0ubuntu2+dokomix1_amd64.
deb ...
Dépaquetage de nvidia-304 (304.137-0ubuntu2+dokomix1) ...
Sélection du paquet nvidia-opencl-icd-304 précédemment désélectionné.
Préparation du dépaquetage de .../09-nvidia-opencl-icd-304_304.137-0ubuntu2+doko
mix1_amd64.deb ...
Dépaquetage de nvidia-opencl-icd-304 (304.137-0ubuntu2+dokomix1) ...
Sélection du paquet screen-resolution-extra précédemment désélectionné.
Préparation du dépaquetage de .../10-screen-resolution-extra_0.18.2_all.deb ...
Dépaquetage de screen-resolution-extra (0.18.2) ...
Sélection du paquet nvidia-settings précédemment désélectionné.
Préparation du dépaquetage de .../11-nvidia-settings_510.47.03-0ubuntu1_amd64.de
b ...
Dépaquetage de nvidia-settings (510.47.03-0ubuntu1) ...
Des erreurs ont été rencontrées pendant l'exécution :
 /tmp/apt-dpkg-install-2ChVh4/07-xserver-xorg-core_3%3a1.17.3-2ubuntu4+dokomix1_
amd64.deb
E: Sub-process /usr/bin/dpkg returned an error code (1)
```

To fix that, [this page](https://unix.stackexchange.com/questions/537546/e-unmet-dependencies-try-apt-fix-broken-install-with-no-packages-or-speci) says to try to force overwrite:

```
(base) tdhock@tdhock-MacBook:~/tdhock.github.io(master*)$ sudo dpkg --configure --force-overwrite -a
dpkg: des problèmes de dépendances empêchent la configuration de nvidia-304 :
 nvidia-304 dépend de xorg-video-abi-11 | xorg-video-abi-12 | xorg-video-abi-13 | xorg-video-abi-14 | xorg-video-abi-15 | xorg-video-abi-18 | xorg-video-abi-19 | xorg-video-abi-20 | xorg-video-abi-23 ; cependant :
  Le paquet xorg-video-abi-11 n'est pas installé.
  Le paquet xorg-video-abi-12 n'est pas installé.
  Le paquet xorg-video-abi-13 n'est pas installé.
  Le paquet xorg-video-abi-14 n'est pas installé.
  Le paquet xorg-video-abi-15 n'est pas installé.
  Le paquet xorg-video-abi-18 n'est pas installé.
  Le paquet xorg-video-abi-19 n'est pas installé.
  Le paquet xorg-video-abi-20 n'est pas installé.
  Le paquet xorg-video-abi-23 n'est pas installé.

dpkg: erreur de traitement du paquet nvidia-304 (--configure) :
 problèmes de dépendances - laissé non configuré
dpkg: des problèmes de dépendances empêchent la configuration de xserver-xorg-input-libinput :
 xserver-xorg-input-libinput dépend de xorg-input-abi-21 ; cependant :
  Le paquet xorg-input-abi-21 n'est pas installé.

dpkg: erreur de traitement du paquet xserver-xorg-input-libinput (--configure) :
 problèmes de dépendances - laissé non configuré
Paramétrage de libxnvctrl0:amd64 (510.47.03-0ubuntu1) ...
Paramétrage de lib32gcc-s1 (12.3.0-1ubuntu1~22.04) ...
dpkg: des problèmes de dépendances empêchent la configuration de xserver-xorg-video-vmware :
 xserver-xorg-video-vmware dépend de xorg-video-abi-19 ; cependant :
  Le paquet xorg-video-abi-19 n'est pas installé.

dpkg: erreur de traitement du paquet xserver-xorg-video-vmware (--configure) :
 problèmes de dépendances - laissé non configuré
Paramétrage de screen-resolution-extra (0.18.2) ...
Paramétrage de libxfont1:amd64 (1:1.5.2-4ubuntu2+dokomix1) ...
Paramétrage de nvidia-settings (510.47.03-0ubuntu1) ...
Paramétrage de libcuda1-304 (304.137-0ubuntu2+dokomix1) ...
Paramétrage de xserver-common (3:1.17.3-2ubuntu4+dokomix1) ...
Paramétrage de nvidia-opencl-icd-304 (304.137-0ubuntu2+dokomix1) ...
Traitement des actions différées (« triggers ») pour bamfdaemon (0.5.6+22.04.20220217-0ubuntu1) ...
Rebuilding /usr/share/applications/bamf-2.index...
Traitement des actions différées (« triggers ») pour desktop-file-utils (0.26-1ubuntu3) ...
Traitement des actions différées (« triggers ») pour gnome-menus (3.36.0-1ubuntu3) ...
Traitement des actions différées (« triggers ») pour libc-bin (2.35-0ubuntu3.4) ...
Traitement des actions différées (« triggers ») pour man-db (2.10.2-1) ...
Traitement des actions différées (« triggers ») pour mailcap (3.70+nmu1ubuntu1) ...
Des erreurs ont été rencontrées pendant l'exécution :
 nvidia-304
 xserver-xorg-input-libinput
 xserver-xorg-video-vmware
(base) tdhock@tdhock-MacBook:~/tdhock.github.io(master*)$ 
```

This is not working, let's try removing:

```
(base) tdhock@tdhock-MacBook:~/tdhock.github.io(master*)$ sudo add-apt-repository --remove ppa:dokomix/legacygpu-jammy
Dépôt : « deb https://ppa.launchpadcontent.net/dokomix/legacygpu-jammy/ubuntu/ jammy main »
Plus d'informations : https://launchpad.net/~dokomix/+archive/ubuntu/legacygpu-jammy
Suppression du dépôt.
Appuyez sur [ENTRÉE] pour continuer ou Ctrl-c pour annuler
Disabling deb entry in /etc/apt/sources.list.d/dokomix-ubuntu-legacygpu-jammy-jammy.list
Removing disabled deb entry from /etc/apt/sources.list.d/dokomix-ubuntu-legacygpu-jammy-jammy.list
Removing disabled deb-src entry from /etc/apt/sources.list.d/dokomix-ubuntu-legacygpu-jammy-jammy.list
Atteint :1 http://security.ubuntu.com/ubuntu jammy-security InRelease
Atteint :2 http://archive.ubuntu.com/ubuntu jammy InRelease
Atteint :3 http://archive.ubuntu.com/ubuntu jammy-security InRelease
Atteint :4 http://archive.ubuntu.com/ubuntu jammy-updates InRelease
Atteint :5 http://archive.ubuntu.com/ubuntu jammy-backports InRelease
Lecture des listes de paquets... Fait
(base) tdhock@tdhock-MacBook:~/tdhock.github.io(master*)$ sudo apt remove nvidia-304
Lecture des listes de paquets... Fait
Construction de l'arbre des dépendances... Fait
Lecture des informations d'état... Fait      
Vous pouvez lancer « apt --fix-broken install » pour corriger ces problèmes.
Les paquets suivants contiennent des dépendances non satisfaites :
 xserver-xorg-input-libinput : Dépend: xorg-input-abi-21 mais il n'est pas installable
 xserver-xorg-video-vmware : Dépend: xorg-video-abi-19 mais il n'est pas installable
E: Dépendances non satisfaites. Essayez « apt --fix-broken install » sans paquet
   (ou indiquez une solution).
(base) tdhock@tdhock-MacBook:~/tdhock.github.io(master*)$ sudo apt install --fix-broken
Lecture des listes de paquets... Fait
Construction de l'arbre des dépendances... Fait
Lecture des informations d'état... Fait      
Correction des dépendances... Fait
Les paquets suivants ont été installés automatiquement et ne sont plus nécessaires :
  amd64-microcode emacs-bin-common emacs-common emacs-el intel-microcode
  iucode-tool lib32gcc-s1 libcuda1-304 libm17n-0 libotf1 libwmf0.2-7
  libxatracker2 libxfont1 libxnvctrl0 m17n-db nvidia-settings
  screen-resolution-extra thermald x11-apps x11-session-utils xbitmaps xinit
  xinput
Veuillez utiliser « sudo apt autoremove » pour les supprimer.
Les paquets suivants seront ENLEVÉS :
  nvidia-304 ubuntu-desktop ubuntu-desktop-minimal xorg xserver-xorg
  xserver-xorg-input-all xserver-xorg-input-libinput xserver-xorg-video-vmware
0 mis à jour, 0 nouvellement installés, 8 à enlever et 4 non mis à jour.
3 partiellement installés ou enlevés.
Après cette opération, 177 Mo d'espace disque seront libérés.
Souhaitez-vous continuer ? [O/n] 
(Lecture de la base de données... 491563 fichiers et répertoires déjà installés.
)
Suppression de nvidia-304 (304.137-0ubuntu2+dokomix1) ...
update-initramfs: deferring update (trigger activated)
Suppression de ubuntu-desktop (1.481.1) ...
Suppression de ubuntu-desktop-minimal (1.481.1) ...
Suppression de xorg (1:7.7+23ubuntu2) ...
Suppression de xserver-xorg (1:7.7+23ubuntu2) ...
Suppression de xserver-xorg-input-all (1:7.7+23ubuntu2) ...
Suppression de xserver-xorg-input-libinput (1:0.30.0-1ubuntu1+dokomix1) ...
Suppression de xserver-xorg-video-vmware (2:13.3.0-3+dokomix1) ...
Traitement des actions différées (« triggers ») pour libc-bin (2.35-0ubuntu3.4) 
...
Traitement des actions différées (« triggers ») pour man-db (2.10.2-1) ...
Traitement des actions différées (« triggers ») pour initramfs-tools (0.140ubunt
u13.4) ...
update-initramfs: Generating /boot/initrd.img-5.15.0-79-generic
(base) tdhock@tdhock-MacBook:~/tdhock.github.io(master*)$
```

### TODOS

* [Pin
  tutorial](https://askubuntu.com/questions/178324/how-to-skip-kernel-update)
  to tell APT to use an old version of a package,
* [hold back](https://askubuntu.com/questions/51124/hold-packages-back-from-updates-without-apt-pin)
