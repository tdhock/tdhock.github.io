---
layout: post
title: Compilation in emacs
description: Fixing regex on linux
---

https://github.com/tdhock/2026-01-aa-grande-echelle/issues/1

https://www.rahuljuliato.com/posts/compiling_emacs_30_1

https://protesilaos.com/codelog/2025-03-22-emacs-build-source-debian/

The following took ~10 minutes:

```
(base) hoct2726@dinf-thock-02i:~$  git clone https://git.savannah.gnu.org/git/emacs.git
Cloning into 'emacs'...
remote: Counting objects: 1235770, done.        
remote: Compressing objects: 100% (219733/219733), done.        
remote: Total 1235770 (delta 1005441), reused 1232395 (delta 1002317)        
Receiving objects: 100% (1235770/1235770), 454.48 MiB | 3.50 MiB/s, done.
Resolving deltas: 100% (1005441/1005441), done.
Updating files: 100% (5552/5552), done.
```

Next autogen

```
(base) hoct2726@dinf-thock-02i:~$ cd emacs/
(base) hoct2726@dinf-thock-02i:~/emacs[master]$ ./autogen.sh 
Checking whether you have the necessary tools...
(Read INSTALL.REPO for more details on building Emacs)
Checking for autoconf (need at least version 2.65) ... ok
Your system has the required tools.
Building aclocal.m4 ...
Running 'autoreconf -fi -I m4' ...
Building 'aclocal.m4' in exec ...
Running 'autoreconf -fi' in exec ...
Configuring local git repository...
'.git/config' -> '.git/config.~1~'
git config transfer.fsckObjects 'true'
git config diff.cpp.xfuncname '!^[ 	]*[A-Za-z_][A-Za-z_0-9]*:[[:space:]]*($|/[/*])
^((::[[:space:]]*)?[A-Za-z_][A-Za-z_0-9]*[[:space:]]*\(.*)$
^((#define[[:space:]]|DEFUN).*)$'
git config diff.elisp.xfuncname '^\([^[:space:]]*def[^[:space:]]+[[:space:]]+([^()[:space:]]+)'
git config diff.m4.xfuncname '^((m4_)?define|A._DEFUN(_ONCE)?)\([^),]*'
git config diff.make.xfuncname '^([$.[:alnum:]_].*:|[[:alnum:]_]+[[:space:]]*([*:+]?[:?]?|!?)=|define .*)'
git config diff.shell.xfuncname '^([[:space:]]*[[:alpha:]_][[:alnum:]_]*[[:space:]]*\(\)|[[:alpha:]_][[:alnum:]_]*=)'
git config diff.texinfo.xfuncname '^@node[[:space:]]+([^,[:space:]][^,]+)'
Installing git hooks...
'build-aux/git-hooks/commit-msg' -> '.git/hooks/commit-msg'
'build-aux/git-hooks/pre-commit' -> '.git/hooks/pre-commit'
'build-aux/git-hooks/prepare-commit-msg' -> '.git/hooks/prepare-commit-msg'
'build-aux/git-hooks/post-commit' -> '.git/hooks/post-commit'
'build-aux/git-hooks/pre-push' -> '.git/hooks/pre-push'
'build-aux/git-hooks/commit-msg-files.awk' -> '.git/hooks/commit-msg-files.awk'
'.git/hooks/applypatch-msg.sample' -> '.git/hooks/applypatch-msg'
'.git/hooks/pre-applypatch.sample' -> '.git/hooks/pre-applypatch'
You can now run './configure'.
```

Next configure

```
(base) hoct2726@dinf-thock-02i:~/emacs[master]$ ./configure --with-gif=ifavailable --with-gnutls=ifavailable
checking for xcrun... no
checking for GNU Make... make
…
config.status: executing doc/emacs/emacsver.texi commands
config.status: executing etc-refcards-emacsver.tex commands
```

Next make

```
(base) hoct2726@dinf-thock-02i:~/emacs[master]$ make
make actual-all || make advice-on-failure make-target=all exit-status=$?
make[1]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs'
make -C lib all
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/lib'
  GEN      alloca.h
…
```

We can run the built emacs in `src/emacs`.
