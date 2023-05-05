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

firefox -> settings, 
- privacy and security, 
  - do not track always, 
  - logins and password uncheck,
add-ons and themes, ublock origin, add to firefox.
- 

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

maybe install miniconda.

```
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
https://www.debugpoint.com/2-ways-fix-laptop-brightness-problem-ubuntu-linux/
method 2 worked for changing the brightness

```
sudo add-apt-repository ppa:apandada1/brightness-controller
sudo apt update
sudo apt install brightness-controller
brightness-controller 
```

brightness keys do work on 22.04.

