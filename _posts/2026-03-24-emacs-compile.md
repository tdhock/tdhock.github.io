---
layout: post
title: Compilation in emacs
description: Fixing regex on linux
---

In class yesterday I presented [some slides](https://docs.google.com/presentation/d/1gt9H9uRcep5-O6M9Mkkv2jjouK9jEHBWAWjXflyuJ6c/edit?slide=id.g3d1d32ec1d3_0_0#slide=id.g3d1d32ec1d3_0_0) to explain how to create a python package with C++ code, and I ran into an issue on Linux, which is explained below.

# Background and issue

## Background on compilation in emacs

Python is a popular programming language for machine learning and data analysis, but it is not always efficient.
When you have a Python for loop over data rows, there is typically a lot of constant factor overhead which makes the code slow.
Sometimes such issues can be fixed by vectorizing, which means removing the Python for loop, and using a vector operation in torch or numpy.
These libraries are implemented in C++, in which doing a for loop has much less overhead.

In my class about large-scale machine learning, I teach students how to write Python distribution packages, which may include compiled C++ functions (in extension modules) that can be called from Python.
When you do a pip install of a Python package with a C++ extension module, a compiler is called to convert the source code to a binary file (so on linux or dll on windows).
If there are issues in the C++ source code, then the compiler will print errors or warnings, with line and column numbers that the user can follow to fix the problem.

I encourage my students to learn emacs, which has good support for compilation error messages.
By default, emacs has `M-x compile` which will run `make` to compile your project based on the commands in `Makefile` in the current directory.
The output of that command is shown in a new buffer in [compilation-mode](https://www.gnu.org/software/emacs/manual/html_node/emacs/Compilation-Mode.html), which has hyperlinks that you can click (or tab-enter) to open the corresponding file with the point set to the line and column indicated in the error.

## Emacs global configuration

I further configure my emacs to do one-touch compilation with F9, by putting the code below in `~/.emacs`.

```elisp
;; Compile with F9
(global-set-key [f9] 'compile)
(setq compilation-scroll-output t)
(setq compilation-auto-jump-to-first-error t)
(setq compile-command "make ")
(setq compilation-read-command nil)
;; for compiling R and Python packages.
(add-to-list 'safe-local-variable-values '(compile-command . "R -e \"Rcpp::compileAttributes('..')\" && R CMD INSTALL .. && R --vanilla < ../tests/testthat/test-CRAN.R"))
(add-to-list 'safe-local-variable-values '(compile-command . "R -e \"devtools::test()\""))
(add-to-list 'safe-local-variable-values '(compile-command . "cd .. && make"))
```

## Emacs configuration in R package

Then I put the following in `Rpkg/src/.dir-locals.el` to compile an R package with Rcpp binding to C++ code:

```elisp
((nil . ((compile-command . "R -e \"Rcpp::compileAttributes('..')\" && R CMD INSTALL .. && R --vanilla < ../tests/testthat/test-CRAN.R"))))
```

## Emacs configuration in Python package

Then I put the following in `pypkg/src/.dir-locals.el` to compile a Python package with pybind11 binding to C++ code:

```elisp
((nil . ((compile-command . "cd .. && make"))))
```

And `pypkg/Makefile` has

```makefile
install.out:
    "C:/Program Files/Git/bin/bash.exe" compile.sh
```

And `pypkg/compile.sh` has

```sh
if [ -f '/c/Users/hoct2726/AppData/Local/miniconda3/Scripts/conda.exe' ]; then
    eval "$('/c/Users/hoct2726/AppData/Local/miniconda3/Scripts/conda.exe' 'shell.bash' 'hook')"
fi
conda activate pypkg
pip install -v .
```

This is not the most portable config code (lots of local paths) but it works on windows:

* open `pypkg/src/code.cpp` in emacs.
* type F9 to compile.
* `*compilation*` buffer shows hilighted compiler errors, like

```
  building 'add_ext_module' extension
  "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Tools\MSVC\14.50.35717\bin\HostX86\x64\cl.exe" /c /nologo /O2 /W3 /GL /DNDEBUG /MD -IC:\Users\hoct2726\AppData\Local\Temp\pip-build-env-bi54j86a\overlay\Lib\site-packages\pybind11\include -IC:\Users\hoct2726\AppData\Local\miniconda3\envs\pypkg\include -IC:\Users\hoct2726\AppData\Local\miniconda3\envs\pypkg\Include "-IC:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Tools\MSVC\14.50.35717\include" "-IC:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\VS\include" "-IC:\Program Files (x86)\Windows Kits\10\include\10.0.26100.0\ucrt" "-IC:\Program Files (x86)\Windows Kits\10\\include\10.0.26100.0\\um" "-IC:\Program Files (x86)\Windows Kits\10\\include\10.0.26100.0\\shared" "-IC:\Program Files (x86)\Windows Kits\10\\include\10.0.26100.0\\winrt" "-IC:\Program Files (x86)\Windows Kits\10\\include\10.0.26100.0\\cppwinrt" /EHsc /Tpsrc/add.cpp /Fobuild\temp.win-amd64-cpython-314\Release\src\add.obj /std:c++latest /EHsc /bigobj
  add.cpp
  src/add.cpp(8): error C2111: '+': pointer addition requires integral operand
  error: command 'C:\\Program Files (x86)\\Microsoft Visual Studio\\18\\BuildTools\\VC\\Tools\\MSVC\\14.50.35717\\bin\\HostX86\\x64\\cl.exe' failed with exit code 2
  error: subprocess-exited-with-error
```

In emacs you can click the line with `src/add.cpp(8)` to open that file at that line.

## Issue

When I prepared my slides on my windows desktop, it worked fine.
But when I tried to demo that in class on my Ubuntu laptop, [I did not see the highlighting and hyperlink](https://github.com/tdhock/2026-01-aa-grande-echelle/issues/1).

```
  building 'add_ext_module' extension
  g++ -pthread -B /home/local/USHERBROOKE/hoct2726/miniconda3/envs/demo/compiler_compat -fno-strict-overflow -Wsign-compare -DNDEBUG -O2 -Wall -fPIC -O2 -isystem /home/local/USHERBROOKE/hoct2726/miniconda3/envs/demo/include -fPIC -O2 -isystem /home/local/USHERBROOKE/hoct2726/miniconda3/envs/demo/include -fPIC -I/tmp/pip-build-env-t7il6swx/overlay/lib/python3.13/site-packages/pybind11/include -I/home/local/USHERBROOKE/hoct2726/miniconda3/envs/demo/include/python3.13 -c src/add.cpp -o build/temp.linux-x86_64-cpython-313/src/add.o -std=c++17 -fvisibility=hidden -g0
  src/add.cpp: In function ‘int add_pointers(const double*, const double*, int, double*)’:
  src/add.cpp:8:31: error: invalid operands of types ‘const double’ and ‘const double*’ to binary ‘operator+’
      8 |     out_ptr[idx] = x_ptr[idx] + y_ptr;
        |                    ~~~~~~~~~~ ^ ~~~~~
        |                             |   |
        |                             |   const double*
        |                             const double
  error: command '/usr/bin/g++' failed with exit code 1
  error: subprocess-exited-with-error
```

Note the output above shows a slightly different error (g++ on linux, instead of Visual Studio on windows).
How can we get that highlighting and hyperlink to work?

# Finding the source

I created the following text file to debug the issue.

```
-*- mode: compilation -*-
  src/add.cpp:8:31: error: invalid operands of types ‘const double’ and ‘const double*’ to binary ‘operator+’
 src/add.cpp:8:31: error: invalid operands of types ‘const double’ and ‘const double*’ to binary ‘operator+’
src/add.cpp:8:31: error: invalid operands of types ‘const double’ and ‘const double*’ to binary ‘operator+’
  src/add.cpp(8): error C2059: syntax error: ';'
```

When I open this file in emacs with default configuration (on windows or on linux), I only see highlight on the last two lines, as shown below.

![two-hilite](/assets/img/2026-01-24-emacs-compile/two-hilite.png)

* the first and last lines are real output from pip, which includes two spaces at the start of each line.
* the second and third lines are artificial lines with 1 or 0 spaces at the start.
* we see that of the g++ errors (top three lines), only the third line is highlighted.

These data suggest that the source of the issue is that the emacs code that parses output of g++ does not allow leading spaces.
It only works if the file name occurs at the beginning of the line.
I checked the emacs source code, and this is true!
`C-h v compilation-error-regexp-alist-alist` shows 

```elisp
 (gnu "^\\(?:[[:alpha:]][.[:alnum:]-]+: ?\\| +|\\)?\\(?1:\\(?:[^	
 0-9]\\|[0-9]+[^
0-9]\\)\\(?:[^
 :]\\| [^
/-]\\|:[^
 ]\\)*?\\): ?\\(?2:[0-9]+\\)\\(?:-\\(?4:[0-9]+\\)\\(?:\\.\\(?5:[0-9]+\\)\\)?\\|[.:]\\(?3:[0-9]+\\)\\(?:-\\(?:\\(?4:[0-9]+\\)\\.\\)?\\(?5:[0-9]+\\)\\)?\\)?:\\(?: *\\(?6:\\(?:FutureWarning\\|RuntimeWarning\\|W\\(?::\\|arning\\)\\|warning\\)\\)\\| *\\(?7:\\(?:I\\(?::\\|nfo\\(?:rmation\\(?:al\\)?\\)?\\)\\|Note\\|in\\(?:fo\\(?:rmation\\(?:al\\)?\\)?\\|stantiated from\\)\\|note\\|required from\\)\\|\\[ skipping .+ ]\\)\\| *\\(?:[Ee]rror\\)\\|[0-9]?\\(?:[^
0-9]\\|$\\)\\|[0-9][0-9][0-9]\\)" 1
(2 . 4)
(3 . 5)
(6 . 7))
```

The regex code above starts with a caret `^` indicating the start of the line, and after that we have a non-capturing group, and an alpha character class, which will not match error lines with two leading spaces.

# Work-around

A temporary fix is to put the code below in `~/.emacs`.

```elisp
;; for gcc error messages when compiling C++ code in a python package via pip.
(add-to-list 'compilation-error-regexp-alist 'gnu-in-pip)
(add-to-list 'compilation-error-regexp-alist-alist '(gnu-in-pip "^ *\\(?:[[:alpha:]][.[:alnum:]-]+: ?\\| +|\\)?\\(?1:\\(?:[^	
 0-9]\\|[0-9]+[^
0-9]\\)\\(?:[^
 :]\\| [^
/-]\\|:[^
 ]\\)*?\\): ?\\(?2:[0-9]+\\)\\(?:-\\(?4:[0-9]+\\)\\(?:\\.\\(?5:[0-9]+\\)\\)?\\|[.:]\\(?3:[0-9]+\\)\\(?:-\\(?:\\(?4:[0-9]+\\)\\.\\)?\\(?5:[0-9]+\\)\\)?\\)?:\\(?: *\\(?6:\\(?:FutureWarning\\|RuntimeWarning\\|W\\(?::\\|arning\\)\\|warning\\)\\)\\| *\\(?7:\\(?:I\\(?::\\|nfo\\(?:rmation\\(?:al\\)?\\)?\\)\\|Note\\|in\\(?:fo\\(?:rmation\\(?:al\\)?\\)?\\|stantiated from\\)\\|note\\|required from\\)\\|\\[ skipping .+ ]\\)\\| *\\(?:[Ee]rror\\)\\|[0-9]?\\(?:[^
0-9]\\|$\\)\\|[0-9][0-9][0-9]\\)" 1
(2 . 4)
(3 . 5)
(6 . 7)))
```

The code above has a minor change, addition of ` *` after the initial `^` of the regex.
Using this configuration, emacs correctly highlights all four lines in my example, as shown below.

![four-hilite](/assets/img/2026-01-24-emacs-compile/four-hilite.png)

# Submitting a PR to emacs

TODO

tests?

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
