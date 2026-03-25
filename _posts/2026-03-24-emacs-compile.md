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

## Debug test file

I created the following text file to debug the issue.

```
-*- mode: compilation -*-
  src/add.cpp:8:31: error: invalid operands of types ‘const double’ and ‘const double*’ to binary ‘operator+’
 src/add.cpp:8:31: error: invalid operands of types ‘const double’ and ‘const double*’ to binary ‘operator+’
src/add.cpp:8:31: error: invalid operands of types ‘const double’ and ‘const double*’ to binary ‘operator+’
  src/add.cpp(8): error C2059: syntax error: ';'
```

When I open this file in emacs with default configuration (on windows or on linux), I only see highlight on the last two lines, as shown below.

![two-hilite](/assets/img/2026-03-24-emacs-compile/two-hilite.png)

* the first and last lines are real output from pip, which includes two spaces at the start of each line.
* the second and third lines are artificial lines with 1 or 0 spaces at the start.
* we see that of the g++ errors (top three lines), only the third line is highlighted.

These data suggest that the source of the issue is that the emacs code that parses output of g++ does not allow leading spaces.
It only works on real g++ output, whin the file name occurs at the beginning of the line.
This g++ output is modified by pip, so emacs does not recognize it.
Yet.

## Emacs source code

The [emacs docs for compilation-mode](https://www.gnu.org/software/emacs/manual/html_node/emacs/Compilation-Mode.html) say that "Compilation mode uses the variable `compilation-error-regexp-alist` which lists various error message formats and tells Emacs how to extract the locus from each."
Doing `C-h v compilation-error-regexp-alist` shows

```
compilation-error-regexp-alist is a variable defined in ‘compile.el’.

Its value is
(absoft ada aix ant bash borland python-tracebacks-and-caml cmake cmake-info comma msft edg-1 edg-2 epc ftnchek gradle-kotlin gradle-android iar ibm irix java javac jikes-file maven jikes-line clang-include gcc-include ruby-Test::Unit gmake gnu cucumber lcc makepp mips-1 mips-2 omake oracle perl php rxp shellcheck sparc-pascal-file sparc-pascal-line sparc-pascal-example sun sun-ada watcom 4bsd gcov-file gcov-header gcov-nomark gcov-called-line gcov-never-called perl--Pod::Checker perl--Test perl--Test2 perl--Test::Harness weblint guile-file guile-line typescript-tsc-plain typescript-tsc-pretty)

Alist that specifies how to match errors in compiler output.
On GNU and Unix, any string is a valid filename, so these
matchers must make some common sense assumptions, which catch
normal cases.  A shorter list will be lighter on resource usage.

Instead of an alist element, you can use a symbol, which is
looked up in ‘compilation-error-regexp-alist-alist’.  You can see
the predefined symbols and their effects in the file
‘etc/compilation.txt’ (linked below if you are customizing this).
```

Following that link, `C-h v compilation-error-regexp-alist-alist` shows a bunch of regexes, including the one below which appears to be for GCC (GNU Compiler Collection).

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

Now that we have found the problematic piece of code, we can fix it.
A quick fix is to put the code below in `~/.emacs`.
It adds a new regex pattern to the Alist that emacs uses to parse compilation mode buffers.

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

With respect to the `gnu` regex supplied with emacs, the code above has a minor change: addition of ` *` (space star) after the initial `^` (caret) of the regex.
Using this configuration, emacs correctly highlights all four lines in my example, as shown below.

![four-hilite](/assets/img/2026-03-24-emacs-compile/four-hilite.png)

# Submitting a PR to emacs

In the previous section, we hacked a fix, and deployed it to the user-specific `~/.emacs` config file.
In this section, I discuss how this change could be submitted to the emacs source code, for the benefit of all users of a future version of emacs.

First we need to download the development version of emacs, and make sure its tests pass on my system.
Second, we should add a test that fails for the use case we want to fix (gcc error with two leading spaces).
Third, we can make the change to the source code, and run the tests again.
If all tests pass, then we are good to submit the new code and test. (and maybe updated documentation?)

## Installing emacs devel from source

This section shows how to install emacs devel from git.
First I read these articles

* [Compiling Emacs 30.1 from the source on Debian](https://www.rahuljuliato.com/posts/compiling_emacs_30_1)
  * not git version
* [Emacs: how I build from emacs.git on Debian stable](https://protesilaos.com/codelog/2025-03-22-emacs-build-source-debian/)
  * with git, runs `./autogen.sh`

Both articles are on debian, and I am on Ubuntu, but that did not seem to cause any problems.

First we clone from GNU git server. The following took ~10 minutes.
May be better to clone the [GitHub mirror](https://github.com/emacs-mirror/emacs.git) next time.

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

Next autogen creates the configure script.

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

Next configure creates the Makefile.

```
(base) hoct2726@dinf-thock-02i:~/emacs[master]$ ./configure --with-gif=ifavailable --with-gnutls=ifavailable
checking for xcrun... no
checking for GNU Make... make
…
config.status: executing doc/emacs/emacsver.texi commands
config.status: executing etc-refcards-emacsver.tex commands
```

Next make compiles emacs.

```
(base) hoct2726@dinf-thock-02i:~/emacs[master]$ make
make actual-all || make advice-on-failure make-target=all exit-status=$?
make[1]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs'
make -C lib all
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/lib'
  GEN      alloca.h
…
make -C lib-src maybe-blessmail
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/lib-src'
make[2]: Nothing to be done for 'maybe-blessmail'.
make[2]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/lib-src'
make[1]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs'
make sanity-check make-target=all
make[1]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs'
make[1]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs'
```

Output above indicates the build worked.

## Sending a patch

[Sending Patches for GNU Emacs](https://www.gnu.org/software/emacs/manual/html_node/emacs/Sending-Patches.html) explains the steps for sending a patch.

* If you are using the Emacs repository, make sure your copy is up-to-date (e.g., with `git pull`). You can commit your changes to a private branch and generate a patch from the master version by using `git format-patch master`.

How to run tests?

* [ert](https://www.gnu.org/software/emacs/manual/html_mono/ert.html) is a test framework for elisp.
* [README in test directory of emacs source code](https://github.com/emacs-mirror/emacs/tree/master/test) says to run `make check`.

```
(base) hoct2726@dinf-thock-02i:~/emacs/test[master]$ cd test
(base) hoct2726@dinf-thock-02i:~/emacs/test[master]$ make check
rm -f ./*.tmp
make[1]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/test'
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/test'
  ELC      lisp/net/tramp-tests.elc
  GEN      lisp/net/tramp-tests.log
Running 45 tests (2026-03-25 06:29:40-0400, selector `(not (or (tag :expensive-test) (tag :unstable) (tag :nativecomp)))')
Remote directory: `/mock::/tmp/'
   passed   1/45  tramp-test00-availability (0.178533 sec)
   passed   2/45  tramp-test01-file-name-syntax (0.023312 sec)
…
  ELC      src/xfaces-tests.elc
  GEN      src/xfaces-tests.log
  ELC      src/xml-tests.elc
  GEN      src/xml-tests.log
make[2]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/test'
make[1]: [Makefile:364: check-doit] Error 2 (ignored)

SUMMARY OF TEST RESULTS
-----------------------
Files examined: 554
Ran 8912 tests, 8565 results as expected, 8 unexpected, 339 skipped
5 files contained unexpected results:
  lisp/progmodes/eglot-tests.log
  lisp/erc/erc-stamp-tests.log
  lisp/erc/erc-scenarios-match.log
  lisp/erc/erc-button-tests.log
  lisp/net/tramp-tests.log
make[1]: *** [Makefile:365: check-doit] Error 1
make[1]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/test'
make: *** [Makefile:327: check] Error 2
```

Looking through the test failures, some seem to be normal.

* rust failure (my version is probably too old? 2024-09-25)
* date failure (my locale is French, mer. 25 mars 2026)

Where are tests related to `compilation-mode`?

* `tests/README` says to look in `manual/` but there does not seem to be anything related.
* it says

```
(Also, see etc/compilation.txt for compilation mode font lock tests
and etc/grep.txt for grep mode font lock tests.)
```

There is a section related to the part of the code I want to modify.
I added the last line below.

```
* GNU style

symbol: gnu

foo.c:8: message
../foo.c:8: W: message
/tmp/foo.c:8:warning message
foo/bar.py:8: FutureWarning message
foo.py:8: RuntimeWarning message
foo.c:8:I: message
foo.c:8.23: note: message
foo.c:8.23: info: message
foo.c:8:23:information: message
foo.c:8.23-45: Informational: message
foo.c:8-23: message
foo.c:8-45.3: message
foo.c:8.23-9.1: message
foo.el:3:1:Error: End of file during parsing
jade:dbcommon.dsl:133:17:E: missing argument for function call
G:/cygwin/dev/build-myproj.xml:54: Compiler Adapter 'javac' can't be found.
file:G:/cygwin/dev/build-myproj.xml:54: Compiler Adapter 'javac' can't be found.
{standard input}:27041: Warning: end of file not at end of a line; newline inserted
boost/container/detail/flat_tree.hpp:589:25:   [ skipping 5 instantiation contexts, use -ftemplate-backtrace-limit=0 to disable ]
   |
   |board.h:60:21:
   |   60 | #define I(b, C) ((C).y * (b)->width + (C).x)
  src/add.cpp:8:31: error: invalid operands of types ‘const double’ and ‘const double*’ to binary ‘operator+’
```

We can run the built emacs in `src/emacs`.
The version I used appears below.

```
(base) hoct2726@dinf-thock-02i:~/emacs[master*]$ src/emacs --version
GNU Emacs 31.0.50
Development version 7b8a38e05383 on master branch; build date 2026-03-24.
Copyright (C) 2026 Free Software Foundation, Inc.
GNU Emacs comes with ABSOLUTELY NO WARRANTY.
You may redistribute copies of GNU Emacs
under the terms of the GNU General Public License.
For more information about these matters, see the file named COPYING.
(base) hoct2726@dinf-thock-02i:~/emacs[master*]$ emacs --version
GNU Emacs 29.3
Copyright (C) 2024 Free Software Foundation, Inc.
GNU Emacs comes with ABSOLUTELY NO WARRANTY.
You may redistribute copies of GNU Emacs
under the terms of the GNU General Public License.
For more information about these matters, see the file named COPYING.
```

Before modification of the version of emacs that I built, my modified test file appears as below.

TODO

## Modifying the code

Next edit `lisp/progmodes/compile.el`.
Before re-compiling, I checked what modifications I made.

```
(base) hoct2726@dinf-thock-02i:~/emacs[master*]$ git diff
diff --git a/etc/compilation.txt b/etc/compilation.txt
index 801d262f5aa..ee0625e9517 100644
--- a/etc/compilation.txt
+++ b/etc/compilation.txt
@@ -331,7 +331,7 @@ boost/container/detail/flat_tree.hpp:589:25:   [ skipping 5 instantiation contex
    |
    |board.h:60:21:
    |   60 | #define I(b, C) ((C).y * (b)->width + (C).x)
+  src/add.cpp:8:31: error: invalid operands of types ‘const double’ and ‘const double*’ to binary ‘operator+’
 
 * Guile backtrace, 2.0.11
 
diff --git a/lisp/progmodes/compile.el b/lisp/progmodes/compile.el
index c0a734ae818..197db308105 100644
--- a/lisp/progmodes/compile.el
+++ b/lisp/progmodes/compile.el
@@ -456,6 +456,8 @@ compilation-error-regexp-alist-alist
      ;;   [PROGRAM:]FILE:LINE[.COL][-ENDLINE[.ENDCOL]]: MESSAGE
      ,(rx
        bol
+       ;; Allow leading spaces for running gcc from pip install.
+       (* " ")
        ;; Match an optional program name which is used for
        ;; non-interactive programs other than compilers (e.g. the
        ;; "jade:" entry in compilation.txt).
```

Remove files compiled in previous build.

```
(base) hoct2726@dinf-thock-02i:~/emacs[master*]$ make clean
make -C src clean
make[1]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/src'
rm -f android-emacs libemacs.so
...
make[1]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/admin/unidata'
rm -f ./*.tmp etc/*.tmp*
rm -rf info-dir.*
rm -rf native-lisp
```

Re-make

```
(base) hoct2726@dinf-thock-02i:~/emacs[master*]$ make
make -C lib all
make[1]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/lib'
  CC       fingerprint.o
…
```

Run tests

```
(base) hoct2726@dinf-thock-02i:~/emacs[master*]$ cd test/
(base) hoct2726@dinf-thock-02i:~/emacs/test[master*]$ make check
rm -f ./*.tmp
make[1]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/test'
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/test'
  GEN      lisp/net/tramp-tests.log
Running 45 tests (2026-03-25 07:21:43-0400, selector `(not (or (tag :expensive-test) (tag :unstable) (tag :nativecomp)))')
Remote directory: `/mock::/tmp/'
   passed   1/45  tramp-test00-availability (0.159644 sec)
...
SUMMARY OF TEST RESULTS
-----------------------
Files examined: 554
Ran 8912 tests, 8564 results as expected, 9 unexpected, 339 skipped
6 files contained unexpected results:
  lisp/progmodes/eglot-tests.log
  lisp/progmodes/compile-tests.log
  lisp/erc/erc-stamp-tests.log
  lisp/erc/erc-scenarios-match.log
  lisp/erc/erc-button-tests.log
  lisp/net/tramp-tests.log
make[1]: *** [Makefile:365: check-doit] Error 1
make[1]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/test'
make: *** [Makefile:327: check] Error 2
```

I have created a new test failure in compile-tests! The relevant part of `test/lisp/progmodes/compile-tests.log` is shown below:

```
Test compile-test-error-regexps backtrace:
  signal(ert-test-failed (((should (equal rule (compilation--message->
  ert-fail(((should (equal rule (compilation--message->rule msg))) :fo
  compile--test-error-line((cucumber "      /home/gusev/.rvm/foo/bar.r
  mapc(compile--test-error-line ((absoft "Error on line 3 of t.f: Exec
  #f(compiled-function () #<bytecode 0x4c4e57ab8d96774>)()
  #f(compiled-function () #<bytecode -0x11338214c1906369>)()
  handler-bind-1(#f(compiled-function () #<bytecode -0x11338214c190636
  ert--run-test-internal(#s(ert--test-execution-info :test #s(ert-test
  ert-run-test(#s(ert-test :name compile-test-error-regexps :documenta
  ert-run-or-rerun-test(#s(ert--stats :selector ... :tests ... :test-m
  ert-run-tests((not (or (tag :expensive-test) (tag :unstable) (tag :n
  ert-run-tests-batch((not (or (tag :expensive-test) (tag :unstable) (
  ert-run-tests-batch-and-exit((not (or (tag :expensive-test) (tag :un
  eval((ert-run-tests-batch-and-exit '(not (or (tag :expensive-test) (
  command-line-1(("-L" ":." "-l" "ert" "--eval" "(setq treesit-extra-l
  command-line()
  normal-top-level()
Test compile-test-error-regexps condition:
    testcase: (cucumber "      /home/gusev/.rvm/foo/bar.rb:500:in `_wrap_assertion'" 1 nil 500 "/home/gusev/.rvm/foo/bar.rb" error)
    (ert-test-failed
     ((should (equal rule (compilation--message->rule msg))) :form
      (equal cucumber gnu) :value nil :explanation
      (different-atoms cucumber gnu)))
   FAILED  1/3  compile-test-error-regexps (0.009982 sec) at lisp/progmodes/compile-tests.el:536
```

The relevant test case lines from `test/lisp/progmodes/compile-tests.el` are:

```
(defconst compile-tests--test-regexps-data
…
    (cucumber "      /home/gusev/.rvm/foo/bar.rb:500:in `_wrap_assertion'"
     1 nil 500 "/home/gusev/.rvm/foo/bar.rb" error)
…
	   "List of tests for `compilation-error-regexp-alist'.
Each element has the form (RULE STR POS COLUMN LINE FILENAME
[TYPE]), where RULE is the rule (as a symbol), STR is an error
string, POS is the position of the error in STR, COLUMN and LINE
are the reported column and line numbers (or nil) for that error,
FILENAME is the reported filename, and TYPE is `info', `warning' or `error'.

LINE can also be of the form (LINE . END-LINE) meaning a range of
lines.  COLUMN can also be of the form (COLUMN . END-COLUMN)
meaning a range of columns starting on LINE and ending on
END-LINE, if that matched.  TYPE can be left out, in which case
any message type is accepted.")
```

This test case means that 

* using `RULE=cucumber`
* to parse the error string ``" /home/gusev/.rvm/foo/bar.rb:500:in `_wrap_assertion'"``,
* we expect to match at `POS=1`,
* and return match data
  * `COLUMN=nil`
  * `LINE=500`
  * `FILENAME="/home/gusev/.rvm/foo/bar.rb"`
  * `TYPE=error`

The failing test case seems to be executed in this test helper function,

```elisp
(defun compile--test-error-line (test)
  (ert-info ((format "%S" test) :prefix "testcase: ")
    (erase-buffer)
    (setq compilation-locs (make-hash-table))
    (let ((rule (nth 0 test))
          (str (nth 1 test))
          (pos (nth 2 test))
          (col  (nth 3 test))
          (line (nth 4 test))
          (file (nth 5 test))
          (type (nth 6 test)))
      (insert str)
      (compilation-parse-errors (point-min) (point-max))
      (let ((msg (get-text-property pos 'compilation-message)))
        (should msg)
        (let ((loc (compilation--message->loc msg))
              end-col end-line)
          (if (consp col)
              (setq end-col (cdr col) col (car col)))
          (if (consp line)
              (setq end-line (cdr line) line (car line)))
          (should (equal (compilation--loc->col loc) col))
          (should (equal (compilation--loc->line loc) line))
          (when file
            (should (equal (caar (compilation--loc->file-struct loc)) file)))
          (when end-col
            ;; The computed END-COL is exclusive; subtract one to get the
            ;; number in the error message.
            (should (equal
                     (1- (car (cadr
                               (nth 2 (compilation--loc->file-struct loc)))))
                     end-col)))
          (should (equal (car (nth 2 (compilation--loc->file-struct loc)))
                         (or end-line line)))
          (when type
            (let ((type-code (pcase-exhaustive type
                               ('info 0) ('warning 1) ('error 2))))
              (should (equal type-code (compilation--message->type msg)))))
          (should (equal rule (compilation--message->rule msg))))
        msg))))
```

The expectation that failed is from this line of source code:

```elisp
(should (equal rule (compilation--message->rule msg)))
```

which produced this error output

```elisp
    (ert-test-failed
     ((should (equal rule (compilation--message->rule msg))) :form
      (equal cucumber gnu) :value nil :explanation
      (different-atoms cucumber gnu)))
```

which means

* this string was expected to be parsed by the cucumber pattern
* but it was actually parsed by the gnu pattern.

This seems like a test expected value that is ok to change, which I did on local branch `tdh`.

# Another solution

Instead of changing the expected value of the test from `cucumber` to `gnu`, can we move `gnu` down, so that `cucumber` takes priority?
It would result in a larger diff to review, but that may be preferred over changing the test result.
I get a test failure:

```
F compile-test-error-regexps
    Test the ‘compilation-error-regexp-alist’ regexps.
    testcase: (gnu "   |foo.c:8: message" 1 nil 8 "foo.c" error)
    (ert-test-failed
     ((should (equal (caar (compilation--loc->file-struct loc)) file))
      :form (equal "|foo.c" "foo.c") :value nil :explanation
      (arrays-of-different-length 6 5 "|foo.c" "foo.c" first-mismatch-at 0)))
```

This test failure means that the new gnu pattern matched a vertical bar that was not expected.
Where is this happening in the regex?
The source code defining the regex begins as below:

```elisp
     ,(rx
       bol
       ;; Match an optional program name which is used for
       ;; non-interactive programs other than compilers (e.g. the
       ;; "jade:" entry in compilation.txt).
       (? (| (: alpha (+ (in ?. ?- alnum)) ":" (? " "))
             ;; Skip indentation generated by GCC's -fanalyzer.
             (: (+ " ") "|")))
```

We see that the last line is a non-capturing group with one or more spaces followed by a vertical bar.
My additions were before that,

```
      ,(rx
        bol
+       ;; Allow leading spaces for running gcc from pip install.
+       (* " ")
        ;; Match an optional program name which is used for
```

so in the failing test case, the pattern I added consumes the white space, and there is no longer one or more spaces to match in the usual pattern, so the vertical does not match either, and is instead matched in the file name group (which is un-expected).

# optional vertical bar?

Another fix may be to make the vertical bar optional.

```elisp
             ;; Skip indentation generated by GCC's -fanalyzer.
             (: (+ " ") (? "|"))))
```

I get same error as before

```
    testcase: (cucumber "      /home/gusev/.rvm/foo/bar.rb:500:in `_wrap_assertion'" 1 nil 500 "/home/gusev/.rvm/foo/bar.rb" error)
    (ert-test-failed
     ((should (equal rule (compilation--message->rule msg))) :form
      (equal cucumber gnu) :value nil :explanation
      (different-atoms cucumber gnu)))
```

Move down too, so cucumber matches first? No, another failure.

```
    testcase: (gnu "      alpha.c:5:15: error: expected ';' after expression" 1 15 5 "alpha.c")
    (ert-test-failed
     ((should (equal (compilation--loc->col loc) col)) :form
      (equal nil 15) :value nil :explanation (different-types nil 15)))
```

This is strange. This test case has leading spaces, and is supposed to match gnu pattern!!
Then why doesn’t my subject match to the gnu pattern?
Because the subject needs six spaces (two is not enough in pip).

![four-hilite](/assets/img/2026-03-24-emacs-compile/six-spaces.png)

# Faster testing

```
(base) hoct2726@dinf-thock-02i:~/emacs[master]$ src/emacs -batch -Q -l test/lisp/progmodes/compile-tests.el -l ert -f ert-run-tests-batch-and-exit
Running 3 tests (2026-03-25 15:35:57-0400, selector ‘t’)
   passed  1/3  compile-test-error-regexps (0.065425 sec)
   passed  2/3  compile-test-functions (0.000248 sec)
   passed  3/3  compile-test-grep-regexps (0.002868 sec)

Ran 3 tests, 3 results as expected, 0 unexpected (2026-03-25 15:35:57-0400, 0.068860 sec)
(base) hoct2726@dinf-thock-02i:~/emacs[master*]$ rm lisp/progmodes/compile.elc 
(base) hoct2726@dinf-thock-02i:~/emacs[master*]$ src/emacs -batch -Q -l test/lisp/progmodes/compile-tests.el -l ert -f ert-run-tests-batch-and-exit
Running 3 tests (2026-03-25 15:37:23-0400, selector ‘t’)
Test compile-test-error-regexps backtrace:
  signal(ert-test-failed (((should (equal rule (compilation--message->
  ert-fail(((should (equal rule (compilation--message->rule msg))) :fo
  (if (unwind-protect (setq value-39 (apply fn-37 args-38)) (setq form
  (let (form-description-41) (if (unwind-protect (setq value-39 (apply
  (let ((value-39 'ert-form-evaluation-aborted-40)) (let (form-descrip
  (let* ((fn-37 #'equal) (args-38 (condition-case err (list rule (prog
  (let ((loc (progn (or (and (memq (type-of msg) cl-struct-compilation
  (let ((msg (get-text-property pos 'compilation-message))) (let ((val
  (let ((rule (nth 0 test)) (str (nth 1 test)) (pos (nth 2 test)) (col
  (let ((ert--infos (cons (cons "testcase: " (format "%S" test)) ert--
  compile--test-error-line((cucumber "      /home/gusev/.rvm/foo/bar.r
  mapc(compile--test-error-line ((absoft "Error on line 3 of t.f: Exec
  (let ((compilation-error-regexp-alist (remq 'omake all-rules))) (map
  (let ((compilation-num-errors-found 0) (compilation-num-warnings-fou
  (progn (font-lock-mode -1) (let ((compilation-num-errors-found 0) (c
  (unwind-protect (progn (font-lock-mode -1) (let ((compilation-num-er
  (save-current-buffer (set-buffer temp-buffer) (unwind-protect (progn
  (let ((temp-buffer (generate-new-buffer " *temp*" t))) (save-current
  #f(lambda () [t] (let ((temp-buffer (generate-new-buffer " *temp*" t
  #f(compiled-function () #<bytecode 0x928f4d22c3a9899>)()
  handler-bind-1(#f(compiled-function () #<bytecode 0x928f4d22c3a9899>
  ert--run-test-internal(#s(ert--test-execution-info :test ... :result
  ert-run-test(#s(ert-test :name compile-test-error-regexps :documenta
  ert-run-or-rerun-test(#s(ert--stats :selector t :tests ... :test-map
  ert-run-tests(t #f(compiled-function (event-type &rest event-args) #
  ert-run-tests-batch(nil)
  ert-run-tests-batch-and-exit()
  command-line-1(("-l" "test/lisp/progmodes/compile-tests.el" "-l" "er
  command-line()
  normal-top-level()
Test compile-test-error-regexps condition:
    testcase: (cucumber "      /home/gusev/.rvm/foo/bar.rb:500:in `_wrap_assertion'" 1 nil 500 "/home/gusev/.rvm/foo/bar.rb" error)
    (ert-test-failed
     ((should (equal rule (compilation--message->rule msg))) :form
      (equal cucumber gnu) :value nil :explanation
      (different-atoms cucumber gnu)))
   FAILED  1/3  compile-test-error-regexps (0.019711 sec) at test/lisp/progmodes/compile-tests.el:536
   passed  2/3  compile-test-functions (0.000433 sec)
   passed  3/3  compile-test-grep-regexps (0.003310 sec)

Ran 3 tests, 2 results as expected, 1 unexpected (2026-03-25 15:37:23-0400, 0.216830 sec)

1 unexpected results:
   FAILED  compile-test-error-regexps
```
