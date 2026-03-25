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
-
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
(base) hoct2726@dinf-thock-02i:~/emacs[master*]$ make install
make -C lib all
make[1]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/lib'
  CC       fingerprint.o
  CC       acl-errno-valid.o
  CC       acl-internal.o
  CC       get-permissions.o
  CC       set-permissions.o
  CC       allocator.o
  CC       binary-io.o
  CC       boot-time.o
  CC       c-ctype.o
  CC       c-strcasecmp.o
  CC       c-strncasecmp.o
  CC       careadlinkat.o
  CC       close-stream.o
  CC       copy-file-range.o
  CC       md5-stream.o
  CC       md5.o
  CC       sha1.o
  CC       sha256.o
  CC       sha3.o
  CC       sha512.o
  CC       dtoastr.o
  CC       dtotimespec.o
  CC       fcntl.o
  CC       file-has-acl.o
  CC       filemode.o
  CC       filevercmp.o
  CC       fseterr.o
  CC       fsusage.o
  CC       gettime.o
  CC       mini-gmp-gnulib.o
  CC       memeq.o
  CC       memset_explicit.o
  CC       nanosleep.o
  CC       nproc.o
  CC       nstrftime.o
  CC       pipe2.o
  CC       qcopy-acl.o
  CC       realloc.o
  CC       sig2str.o
  CC       stat-time.o
  CC       stdlib.o
  CC       streq.o
  CC       strnul.o
  CC       tempname.o
  CC       time_rz.o
  CC       timespec.o
  CC       timespec-add.o
  CC       timespec-sub.o
  CC       u64.o
  CC       unistd.o
  CC       openat-die.o
  CC       save-cwd.o
  AR       libgnu.a
make[1]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/lib'
make -C lib-src all
make[1]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/lib-src'
  CCLD     etags
  CCLD     emacsclient
  CCLD     ebrowse
  CCLD     hexl
  CCLD     make-docfile
  CCLD     make-fingerprint
make[1]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/lib-src'
make -C src BIN_DESTDIR='/usr/local/bin/' \
	 ELN_DESTDIR='/usr/local/lib/emacs/31.0.50/' all
make[1]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/src'
  GEN      globals.h
make -C ../lwlib/ liblw.a
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/lwlib'
  CC       lwlib.o
  CC       lwlib-Xlw.o
  CC       xlwmenu.o
  CC       lwlib-Xaw.o
  CC       lwlib-utils.o
  GEN      liblw.a
make[2]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/lwlib'
  CC       dispnew.o
  CC       frame.o
  CC       scroll.o
  CC       xdisp.o
  CC       menu.o
  CC       xmenu.o
  CC       window.o
  CC       charset.o
  CC       coding.o
  CC       category.o
  CC       ccl.o
  CC       character.o
  CC       chartab.o
  CC       bidi.o
  CC       cm.o
  CC       term.o
  CC       terminal.o
  CC       xfaces.o
  CC       xterm.o
  CC       xfns.o
  CC       xselect.o
  CC       xrdb.o
  CC       xsmfns.o
  CC       xsettings.o
  CC       emacs.o
  CC       keyboard.o
  CC       macros.o
  CC       keymap.o
  CC       sysdep.o
  CC       bignum.o
  CC       buffer.o
  CC       filelock.o
  CC       insdel.o
  CC       marker.o
  CC       minibuf.o
  CC       fileio.o
  CC       dired.o
  CC       cmds.o
  CC       casetab.o
  CC       casefiddle.o
  CC       indent.o
  CC       search.o
  CC       regex-emacs.o
  CC       undo.o
  CC       alloc.o
  CC       pdumper.o
  CC       data.o
  GEN      buildobj.h
  CC       doc.o
  CC       editfns.o
  CC       callint.o
  CC       eval.o
  CC       floatfns.o
  CC       fns.o
  CC       sort.o
  CC       font.o
  CC       print.o
  CC       lread.o
  CC       emacs-module.o
  CC       syntax.o
  CC       bytecode.o
  CC       comp.o
  CC       dynlib.o
  CC       process.o
  CC       gnutls.o
  CC       callproc.o
  CC       region-cache.o
  CC       sound.o
  CC       timefns.o
  CC       atimer.o
  CC       doprnt.o
  CC       intervals.o
  CC       textprop.o
  CC       composite.o
  CC       xml.o
  CC       lcms.o
  CC       inotify.o
  CC       profiler.o
  CC       decompress.o
  CC       thread.o
  CC       systhread.o
  CC       sqlite.o
  CC       treesit.o
  CC       itree.o
  CC       json.o
  CC       xfont.o
  CC       ftfont.o
  CC       ftcrfont.o
  CC       hbfont.o
  CC       fontset.o
  CC       fringe.o
  CC       image.o
  CC       textconv.o
  CC       xgselect.o
  CC       terminfo.o
  CC       widget.o
make -C ../admin/charsets all
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/admin/charsets'
make[2]: Nothing to be done for 'all'.
make[2]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/admin/charsets'
make -C ../admin/unidata charscript.el
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/admin/unidata'
make[2]: Nothing to be done for 'charscript.el'.
make[2]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/admin/unidata'
make -C ../admin/unidata emoji-zwj.el
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/admin/unidata'
make[2]: Nothing to be done for 'emoji-zwj.el'.
make[2]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/admin/unidata'
  CCLD     temacs
/usr/bin/mkdir -p ../etc
  GEN      ../etc/DOC
make -C ../lisp update-subdirs
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/lisp'
make[2]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/lisp'
cp -f temacs bootstrap-emacs
rm -f bootstrap-emacs.pdmp
./temacs --batch  -l loadup --temacs=pbootstrap \
	--bin-dest '/usr/local/bin/' --eln-dest '/usr/local/lib/emacs/31.0.50/'
Loading loadup.el (source)...
Dump mode: pbootstrap
Using load-path (/home/local/USHERBROOKE/hoct2726/emacs/lisp /home/local/USHERBROOKE/hoct2726/emacs/lisp/emacs-lisp /home/local/USHERBROOKE/hoct2726/emacs/lisp/progmodes /home/local/USHERBROOKE/hoct2726/emacs/lisp/language /home/local/USHERBROOKE/hoct2726/emacs/lisp/international /home/local/USHERBROOKE/hoct2726/emacs/lisp/textmodes /home/local/USHERBROOKE/hoct2726/emacs/lisp/vc)
Loading emacs-lisp/debug-early...
Loading emacs-lisp/byte-run...
Loading emacs-lisp/backquote...
Loading subr...
Loading keymap...
Loading version...
Loading widget...
Loading custom...
Loading emacs-lisp/map-ynp...
Loading international/mule...
Loading international/mule-conf...
Loading env...
Loading format...
Loading bindings...
Loading window...
Loading files...
Loading emacs-lisp/macroexp...
Loading cus-face...
Loading faces...
Loading loaddefs...
Loading /home/local/USHERBROOKE/hoct2726/emacs/lisp/theme-loaddefs.el (source)...
Loading button...
Loading emacs-lisp/cl-preloaded...
Loading emacs-lisp/oclosure...
Loading obarray...
Loading abbrev...
Loading help...
Loading jka-cmpr-hook...
Loading epa-hook...
Loading international/mule-cmds...
Loading case-table...
Loading /home/local/USHERBROOKE/hoct2726/emacs/lisp/international/charprop.el (source)...
Loading international/characters...
Loading international/charscript...
Loading international/emoji-zwj...
Loading composite...
Loading language/chinese...
Loading language/cyrillic...
Loading language/indian...
Loading language/sinhala...
Loading language/english...
Loading language/ethiopic...
Loading language/european...
Loading language/czech...
Loading language/slovak...
Loading language/romanian...
Loading language/greek...
Loading language/hebrew...
Loading international/cp51932...
Loading international/eucjp-ms...
Loading language/japanese...
Loading language/korean...
Loading language/lao...
Loading language/tai-viet...
Loading language/thai...
Loading language/tibetan...
Loading language/vietnamese...
Loading language/misc-lang...
Loading language/utf-8-lang...
Loading language/georgian...
Loading language/khmer...
Loading language/burmese...
Loading language/cham...
Loading language/philippine...
Loading language/indonesian...
Loading indent...
Loading emacs-lisp/cl-generic...
Loading simple...
Loading emacs-lisp/seq...
Loading emacs-lisp/nadvice...
Loading minibuffer...
Loading frame...
Loading startup...
Loading term/tty-colors...
Loading font-core...
Loading emacs-lisp/syntax...
Loading font-lock...
Loading jit-lock...
Loading mouse...
Loading scroll-bar...
Loading select...
Loading emacs-lisp/timer...
Loading emacs-lisp/easymenu...
Loading isearch...
Loading rfn-eshadow...
Loading menu-bar...
Loading tab-bar...
Loading emacs-lisp/lisp...
Loading textmodes/page...
Loading register...
Loading textmodes/paragraphs...
Loading progmodes/prog-mode...
Loading emacs-lisp/lisp-mode...
Loading textmodes/text-mode...
Loading textmodes/fill...
Loading newcomment...
Loading replace...
Loading emacs-lisp/tabulated-list...
Loading buff-menu...
Loading fringe...
Loading emacs-lisp/regexp-opt...
Loading image...
Loading international/fontset...
Loading dnd...
Loading tool-bar...
Loading dynamic-setting...
Loading touch-screen...
Loading x-dnd...
Loading term/common-win...
Loading term/x-win...
Loading mwheel...
Loading progmodes/elisp-mode...
Loading emacs-lisp/float-sup...
Loading vc/vc-hooks...
Loading vc/ediff-hook...
Loading uniquify...
Loading electric...
Loading paren...
Loading emacs-lisp/shorthands...
Loading emacs-lisp/eldoc...
Loading emacs-lisp/cconv...
Loading cus-start...
Loading tooltip...
Loading international/iso-transl...
Loading emacs-lisp/rmc...
Loading /home/local/USHERBROOKE/hoct2726/emacs/lisp/leim/leim-list.el (source)...
Finding pointers to doc strings...
Finding pointers to doc strings...done
Dumping under the name bootstrap-emacs.pdmp
Dumping fingerprint: 510825b1574160da91bb2e15cbd56681a22cb14b7012bfcee79cc1fc659feffd
Dump complete
Byte counts: header=100 hot=9221412 discardable=162904 cold=4142328
Reloc counts: hot=500713 discardable=5731
ANCIENT=yes make -C ../lisp compile-first EMACS="../src/bootstrap-emacs"
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/lisp'
make[2]: Nothing to be done for 'compile-first'.
make[2]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/lisp'
make -C ../lisp compile-first EMACS="../src/bootstrap-emacs"
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/lisp'
make[2]: Nothing to be done for 'compile-first'.
make[2]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/lisp'
make -C ../admin/unidata all EMACS="../../src/bootstrap-emacs"
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/admin/unidata'
  ELC      uvs.elc
  ELC      unidata-gen.elc
  GEN      unidata.txt
make[2]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/admin/unidata'
make -C ../admin/charsets cp51932.el
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/admin/charsets'
make[2]: Nothing to be done for 'cp51932.el'.
make[2]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/admin/charsets'
make -C ../admin/charsets eucjp-ms.el
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/admin/charsets'
make[2]: Nothing to be done for 'eucjp-ms.el'.
make[2]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/admin/charsets'
rm -f emacs && cp -f temacs emacs
LC_ALL=C ./temacs -batch  -l loadup --temacs=pdump \
	--bin-dest '/usr/local/bin/' --eln-dest '/usr/local/lib/emacs/31.0.50/'
Loading loadup.el (source)...
Dump mode: pdump
Using load-path (/home/local/USHERBROOKE/hoct2726/emacs/lisp)
Loading emacs-lisp/debug-early...
Loading emacs-lisp/byte-run...
Loading emacs-lisp/backquote...
Loading subr...
Loading keymap...
Loading version...
Loading widget...
Loading custom...
Loading emacs-lisp/map-ynp...
Loading international/mule...
Loading international/mule-conf...
Loading env...
Loading format...
Loading bindings...
Loading window...
Loading files...
Loading emacs-lisp/macroexp...
Loading cus-face...
Loading faces...
Loading loaddefs...
Loading theme-loaddefs.el (source)...
Loading button...
Loading emacs-lisp/cl-preloaded...
Loading emacs-lisp/oclosure...
Loading obarray...
Loading abbrev...
Loading help...
Loading jka-cmpr-hook...
Loading epa-hook...
Loading international/mule-cmds...
Loading case-table...
Loading international/charprop.el (source)...
Loading international/characters...
Loading international/charscript...
Loading international/emoji-zwj...
Loading composite...
Loading language/chinese...
Loading language/cyrillic...
Loading language/indian...
Loading language/sinhala...
Loading language/english...
Loading language/ethiopic...
Loading language/european...
Loading language/czech...
Loading language/slovak...
Loading language/romanian...
Loading language/greek...
Loading language/hebrew...
Loading international/cp51932...
Loading international/eucjp-ms...
Loading language/japanese...
Loading language/korean...
Loading language/lao...
Loading language/tai-viet...
Loading language/thai...
Loading language/tibetan...
Loading language/vietnamese...
Loading language/misc-lang...
Loading language/utf-8-lang...
Loading language/georgian...
Loading language/khmer...
Loading language/burmese...
Loading language/cham...
Loading language/philippine...
Loading language/indonesian...
Loading indent...
Loading emacs-lisp/cl-generic...
Loading simple...
Loading emacs-lisp/seq...
Loading emacs-lisp/nadvice...
Loading minibuffer...
Loading frame...
Loading startup...
Loading term/tty-colors...
Loading font-core...
Loading emacs-lisp/syntax...
Loading font-lock...
Loading jit-lock...
Loading mouse...
Loading scroll-bar...
Loading select...
Loading emacs-lisp/timer...
Loading emacs-lisp/easymenu...
Loading isearch...
Loading rfn-eshadow...
Loading menu-bar...
Loading tab-bar...
Loading emacs-lisp/lisp...
Loading textmodes/page...
Loading register...
Loading textmodes/paragraphs...
Loading progmodes/prog-mode...
Loading emacs-lisp/lisp-mode...
Loading textmodes/text-mode...
Loading textmodes/fill...
Loading newcomment...
Loading replace...
Loading emacs-lisp/tabulated-list...
Loading buff-menu...
Loading fringe...
Loading emacs-lisp/regexp-opt...
Loading image...
Loading international/fontset...
Loading dnd...
Loading tool-bar...
Loading dynamic-setting...
Loading touch-screen...
Loading x-dnd...
Loading term/common-win...
Loading term/x-win...
Loading mwheel...
Loading progmodes/elisp-mode...
Loading emacs-lisp/float-sup...
Loading vc/vc-hooks...
Loading vc/ediff-hook...
Loading uniquify...
Loading electric...
Loading paren...
Loading emacs-lisp/shorthands...
Loading emacs-lisp/eldoc...
Loading emacs-lisp/cconv...
Loading cus-start...
Loading tooltip...
Loading international/iso-transl...
Loading emacs-lisp/rmc...
Loading leim/leim-list.el (source)...
Waiting for git...
Waiting for git...
Finding pointers to doc strings...
Finding pointers to doc strings...done
Dumping under the name emacs.pdmp
Dumping fingerprint: 510825b1574160da91bb2e15cbd56681a22cb14b7012bfcee79cc1fc659feffd
Dump complete
Byte counts: header=100 hot=9227300 discardable=162904 cold=4140024
Reloc counts: hot=501094 discardable=5731
Adding name emacs-31.0.50.1
Adding name emacs-31.0.50.1.pdmp
cp -f emacs.pdmp bootstrap-emacs.pdmp 
make[1]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/src'
make -C lisp all
make[1]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/lisp'
make -C ../leim all EMACS="../src/emacs"
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/leim'
make[2]: Nothing to be done for 'all'.
make[2]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/leim'
make -C ../admin/grammars all EMACS="../../src/emacs"
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/admin/grammars'
make[2]: Nothing to be done for 'all'.
make[2]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/admin/grammars'
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/lisp'
make[2]: Nothing to be done for 'compile-targets'.
make[2]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/lisp'
  GEN      autoloads
  INFO     Scraping 1577 files for loaddefs...
  INFO     Scraping 1577 files for loaddefs...done
  GEN      loaddefs.el
  INFO     Scraping 25 files for loaddefs...
  INFO     Scraping 25 files for loaddefs...done
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/lisp'
  ELC      loaddefs.elc

In toplevel form:
loaddefs.el:5139:2: Warning: in defcustom for ‘compile-command’: fails to specify containing group
  ELC      progmodes/compile.elc
make[2]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/lisp'
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/leim'
make[2]: Nothing to be done for 'generate-ja-dic'.
make[2]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/leim'
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/lisp'
make[2]: Nothing to be done for 'compile-targets'.
make[2]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/lisp'
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/doc/misc'
make[2]: 'org.texi' is up to date.
make[2]: 'modus-themes.texi' is up to date.
make[2]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/doc/misc'
make[1]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/lisp'
make -C doc/lispref info
make[1]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/doc/lispref'
make[1]: Nothing to be done for 'info'.
make[1]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/doc/lispref'
make -C doc/lispintro info
make[1]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/doc/lispintro'
make[1]: Nothing to be done for 'info'.
make[1]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/doc/lispintro'
make -C doc/emacs info
make[1]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/doc/emacs'
make[1]: Nothing to be done for 'info'.
make[1]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/doc/emacs'
make -C doc/misc info
make[1]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/doc/misc'
make[1]: Nothing to be done for 'info'.
make[1]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/doc/misc'
make -C src BIN_DESTDIR='/usr/local/bin/' ELN_DESTDIR='/usr/local/lib/emacs/31.0.50/'
make[1]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/src'
make -C ../lwlib/ liblw.a
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/lwlib'
make[2]: 'liblw.a' is up to date.
make[2]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/lwlib'
make -C ../admin/charsets all
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/admin/charsets'
make[2]: Nothing to be done for 'all'.
make[2]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/admin/charsets'
make -C ../admin/unidata charscript.el
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/admin/unidata'
make[2]: Nothing to be done for 'charscript.el'.
make[2]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/admin/unidata'
make -C ../admin/unidata emoji-zwj.el
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/admin/unidata'
make[2]: Nothing to be done for 'emoji-zwj.el'.
make[2]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/admin/unidata'
make -C ../admin/unidata all EMACS="../../src/bootstrap-emacs"
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/admin/unidata'
make[2]: Nothing to be done for 'all'.
make[2]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/admin/unidata'
make -C ../admin/charsets cp51932.el
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/admin/charsets'
make[2]: Nothing to be done for 'cp51932.el'.
make[2]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/admin/charsets'
make -C ../admin/charsets eucjp-ms.el
make[2]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/admin/charsets'
make[2]: Nothing to be done for 'eucjp-ms.el'.
make[2]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/admin/charsets'
rm -f emacs && cp -f temacs emacs
LC_ALL=C ./temacs -batch  -l loadup --temacs=pdump \
	--bin-dest '/usr/local/bin/' --eln-dest '/usr/local/lib/emacs/31.0.50/'
Loading loadup.el (source)...
Dump mode: pdump
Using load-path (/home/local/USHERBROOKE/hoct2726/emacs/lisp)
Loading emacs-lisp/debug-early...
Loading emacs-lisp/byte-run...
Loading emacs-lisp/backquote...
Loading subr...
Loading keymap...
Loading version...
Loading widget...
Loading custom...
Loading emacs-lisp/map-ynp...
Loading international/mule...
Loading international/mule-conf...
Loading env...
Loading format...
Loading bindings...
Loading window...
Loading files...
Loading emacs-lisp/macroexp...
Loading cus-face...
Loading faces...
Loading loaddefs...
Loading theme-loaddefs.el (source)...
Loading button...
Loading emacs-lisp/cl-preloaded...
Loading emacs-lisp/oclosure...
Loading obarray...
Loading abbrev...
Loading help...
Loading jka-cmpr-hook...
Loading epa-hook...
Loading international/mule-cmds...
Loading case-table...
Loading international/charprop.el (source)...
Loading international/characters...
Loading international/charscript...
Loading international/emoji-zwj...
Loading composite...
Loading language/chinese...
Loading language/cyrillic...
Loading language/indian...
Loading language/sinhala...
Loading language/english...
Loading language/ethiopic...
Loading language/european...
Loading language/czech...
Loading language/slovak...
Loading language/romanian...
Loading language/greek...
Loading language/hebrew...
Loading international/cp51932...
Loading international/eucjp-ms...
Loading language/japanese...
Loading language/korean...
Loading language/lao...
Loading language/tai-viet...
Loading language/thai...
Loading language/tibetan...
Loading language/vietnamese...
Loading language/misc-lang...
Loading language/utf-8-lang...
Loading language/georgian...
Loading language/khmer...
Loading language/burmese...
Loading language/cham...
Loading language/philippine...
Loading language/indonesian...
Loading indent...
Loading emacs-lisp/cl-generic...
Loading simple...
Loading emacs-lisp/seq...
Loading emacs-lisp/nadvice...
Loading minibuffer...
Loading frame...
Loading startup...
Loading term/tty-colors...
Loading font-core...
Loading emacs-lisp/syntax...
Loading font-lock...
Loading jit-lock...
Loading mouse...
Loading scroll-bar...
Loading select...
Loading emacs-lisp/timer...
Loading emacs-lisp/easymenu...
Loading isearch...
Loading rfn-eshadow...
Loading menu-bar...
Loading tab-bar...
Loading emacs-lisp/lisp...
Loading textmodes/page...
Loading register...
Loading textmodes/paragraphs...
Loading progmodes/prog-mode...
Loading emacs-lisp/lisp-mode...
Loading textmodes/text-mode...
Loading textmodes/fill...
Loading newcomment...
Loading replace...
Loading emacs-lisp/tabulated-list...
Loading buff-menu...
Loading fringe...
Loading emacs-lisp/regexp-opt...
Loading image...
Loading international/fontset...
Loading dnd...
Loading tool-bar...
Loading dynamic-setting...
Loading touch-screen...
Loading x-dnd...
Loading term/common-win...
Loading term/x-win...
Loading mwheel...
Loading progmodes/elisp-mode...
Loading emacs-lisp/float-sup...
Loading vc/vc-hooks...
Loading vc/ediff-hook...
Loading uniquify...
Loading electric...
Loading paren...
Loading emacs-lisp/shorthands...
Loading emacs-lisp/eldoc...
Loading emacs-lisp/cconv...
Loading cus-start...
Loading tooltip...
Loading international/iso-transl...
Loading emacs-lisp/rmc...
Loading leim/leim-list.el (source)...
Waiting for git...
Waiting for git...
Finding pointers to doc strings...
Finding pointers to doc strings...done
Dumping under the name emacs.pdmp
Dumping fingerprint: 510825b1574160da91bb2e15cbd56681a22cb14b7012bfcee79cc1fc659feffd
Dump complete
Byte counts: header=100 hot=9227300 discardable=162904 cold=4140024
Reloc counts: hot=501094 discardable=5731
Adding name emacs-31.0.50.2
Adding name emacs-31.0.50.2.pdmp
cp -f emacs.pdmp bootstrap-emacs.pdmp 
make[1]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/src'
make -C lib-src maybe-blessmail
make[1]: Entering directory '/home/local/USHERBROOKE/hoct2726/emacs/lib-src'
make[1]: Nothing to be done for 'maybe-blessmail'.
make[1]: Leaving directory '/home/local/USHERBROOKE/hoct2726/emacs/lib-src'
umask 022; /usr/bin/mkdir -p "/usr/local/share/info"
/usr/bin/mkdir: cannot create directory ‘/usr/local/share/info’: Permission denied
make: *** [Makefile:787: install-info] Error 1
```

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
   passed   2/45  tramp-test01-file-name-syntax (0.022029 sec)
   passed   3/45  tramp-test02-file-name-dissect (0.019551 sec)
   passed   4/45  tramp-test03-file-error (0.034770 sec)
   passed   5/45  tramp-test03-file-name-host-rules (0.058815 sec)
   passed   6/45  tramp-test04-substitute-in-file-name (0.011083 sec)
   passed   7/45  tramp-test05-expand-file-name (0.001039 sec)
   passed   8/45  tramp-test05-expand-file-name-relative (0.139562 sec)
   passed   9/45  tramp-test05-expand-file-name-tilde (0.210556 sec)
   passed  10/45  tramp-test05-expand-file-name-top (0.044943 sec)
   passed  11/45  tramp-test06-directory-file-name (0.125550 sec)
   passed  12/45  tramp-test07-abbreviate-file-name (0.310284 sec)
   passed  13/45  tramp-test07-file-exists-p (0.445096 sec)
   passed  14/45  tramp-test08-file-local-copy (0.355839 sec)
   passed  15/45  tramp-test09-insert-file-contents (0.529786 sec)
Wrote /mock:dinf-thock-02i:/tmp/tramp-testONsgeI
Wrote /mock:dinf-thock-02i:/tmp/tramp-testONsgeI
Wrote /mock:dinf-thock-02i:/tmp/tramp-testONsgeI
   passed  16/45  tramp-test10-write-region (1.143719 sec)
   passed  17/45  tramp-test11-copy-file (1.734735 sec)
   passed  18/45  tramp-test12-rename-file (1.863929 sec)
   passed  19/45  tramp-test13-make-directory (0.309353 sec)
   passed  20/45  tramp-test14-delete-directory (0.741113 sec)
   passed  21/45  tramp-test15-copy-directory (0.889404 sec)
   passed  22/45  tramp-test16-directory-files (0.348642 sec)
   passed  23/45  tramp-test17-insert-directory (0.438394 sec)
Test tramp-test18-file-attributes backtrace:
  signal(ert-test-failed (((should (file-ownership-preserved-p tmp-name1 'group)) :form (file-ownership-preserved-p "/mock:dinf-thock-02i:/tmp/tramp-testFLwvbb" group) :value nil)))
  ert-fail(((should (file-ownership-preserved-p tmp-name1 'group)) :form (file-ownership-preserved-p "/mock:dinf-thock-02i:/tmp/tramp-testFLwvbb" group) :value nil))
  #f(compiled-function () #<bytecode -0x1f7de5bca9a1bc>)()
  #f(compiled-function () #<bytecode 0x196bb7a271c9b47a>)()
  handler-bind-1(#f(compiled-function () #<bytecode 0x196bb7a271c9b47a>) (t) #f(compiled-function (err) #<bytecode 0xc4c41af3b23fdc1>))
  ert--run-test-internal(#s(ert--test-execution-info :test #s(ert-test :name tramp-test18-file-attributes :documentation "Check `file-attributes'.\nThis tests also `access-file', `file-readable-p',\n`file-regular-p' and `file-ownership-preserved-p'." :body #f(compiled-function () #<bytecode -0x1f7de5bca9a1bc>) :most-recent-result #s(ert-test-failed :messages "" :should-forms (... ... ... ... ... ... ... ... ... ... ... ... ... ...) :duration 1.463918762 :condition (ert-test-failed ...) :backtrace (... ... ... ... ... ... ... ... ... ... ... ... ... ... ...) :infos nil) :expected-result-type :passed :tags nil :file-name "/home/local/USHERBROOKE/hoct2726/emacs/test/lisp/net/tramp-tests.el") :result #s(ert-test-failed :messages "" :should-forms ((... :form ... :value t) (... :form ... :value nil) (... :form ...) (... :form ...) (... :form ...) (... :form ... :value nil) (... :form ... :value nil) (... :form ... :value nil) (... :form ... :value t) (... :form ... :value t) (... :form ... :value t) (... :form ... :value t) (... :form ... :value nil) (... :form ... :value nil)) :duration 1.463918762 :condition (ert-test-failed (... :form ... :value nil)) :backtrace (#s(backtrace-frame :evald t :fun signal :args ... :flags nil :locals nil :buffer nil :pos nil) #s(backtrace-frame :evald t :fun ert-fail :args ... :flags nil :locals nil :buffer nil :pos nil) #s(backtrace-frame :evald t :fun #f(compiled-function () #<bytecode -0x1f7de5bca9a1bc>) :args nil :flags nil :locals ... :buffer nil :pos nil) #s(backtrace-frame :evald t :fun #f(compiled-function () #<bytecode 0x196bb7a271c9b47a>) :args nil :flags nil :locals nil :buffer nil :pos nil) #s(backtrace-frame :evald t :fun handler-bind-1 :args ... :flags nil :locals nil :buffer nil :pos nil) #s(backtrace-frame :evald t :fun ert--run-test-internal :args #0 :flags nil :locals ... :buffer nil :pos nil) #s(backtrace-frame :evald t :fun ert-run-test :args ... :flags nil :locals ... :buffer nil :pos nil) #s(backtrace-frame :evald t :fun ert-run-or-rerun-test :args ... :flags nil :locals ... :buffer nil :pos nil) #s(backtrace-frame :evald t :fun ert-run-tests :args ... :flags nil :locals ... :buffer nil :pos nil) #s(backtrace-frame :evald t :fun ert-run-tests-batch :args ... :flags nil :locals nil :buffer nil :pos nil) #s(backtrace-frame :evald t :fun ert-run-tests-batch-and-exit :args ... :flags nil :locals nil :buffer nil :pos nil) #s(backtrace-frame :evald t :fun eval :args ... :flags nil :locals nil :buffer nil :pos nil) #s(backtrace-frame :evald t :fun command-line-1 :args ... :flags nil :locals ... :buffer nil :pos nil) #s(backtrace-frame :evald t :fun command-line :args nil :flags nil :locals nil :buffer nil :pos nil) #s(backtrace-frame :evald t :fun normal-top-level :args nil :flags nil :locals nil :buffer nil :pos nil)) :infos nil) :exit-continuation #f(compiled-function () #<bytecode 0x76f73b7d184c3>) :ert-debug-on-error nil))
  ert-run-test(#s(ert-test :name tramp-test18-file-attributes :documentation "Check `file-attributes'.\nThis tests also `access-file', `file-readable-p',\n`file-regular-p' and `file-ownership-preserved-p'." :body #f(compiled-function () #<bytecode -0x1f7de5bca9a1bc>) :most-recent-result #s(ert-test-failed :messages "" :should-forms (((skip-unless ...) :form (tramp--test-enabled) :value t) ((should-not ...) :form (access-file "/mock:dinf-thock-02i:/tmp/tramp-testFLwvbb" "error") :value nil) ((should-error ... :type ...) :form (access-file "/mock:dinf-thock-02i:/tmp/tramp-testFLwvbb" "error")) ((should-error ... :type tramp-permission-denied) :form (access-file "/mock:dinf-thock-02i:/tmp/tramp-testFLwvbb" "error")) ((should-error ... :type ...) :form (access-file "/mock:dinf-thock-02i:/tmp/tramp-testFLwvbb" "error")) ((should-not ...) :form (file-exists-p "/mock:dinf-thock-02i:/tmp/tramp-testFLwvbb") :value nil) ((should-not ...) :form (file-readable-p "/mock:dinf-thock-02i:/tmp/tramp-testFLwvbb") :value nil) ((should-not ...) :form (file-regular-p "/mock:dinf-thock-02i:/tmp/tramp-testFLwvbb") :value nil) ((should ...) :form (file-ownership-preserved-p "/mock:dinf-thock-02i:/tmp/tramp-testFLwvbb" group) :value t) ((should ...) :form (file-exists-p "/mock:dinf-thock-02i:/tmp/tramp-testFLwvbb") :value t) ((should ...) :form (file-readable-p "/mock:dinf-thock-02i:/tmp/tramp-testFLwvbb") :value t) ((should ...) :form (file-regular-p "/mock:dinf-thock-02i:/tmp/tramp-testFLwvbb") :value t) ((should-not ...) :form (access-file "/mock:dinf-thock-02i:/tmp/tramp-testFLwvbb" "error") :value nil) ((should ...) :form (file-ownership-preserved-p "/mock:dinf-thock-02i:/tmp/tramp-testFLwvbb" group) :value nil)) :duration 1.463918762 :condition (ert-test-failed ((should ...) :form (file-ownership-preserved-p "/mock:dinf-thock-02i:/tmp/tramp-testFLwvbb" group) :value nil)) :backtrace (#s(backtrace-frame :evald t :fun signal :args (ert-test-failed ...) :flags nil :locals nil :buffer nil :pos nil) #s(backtrace-frame :evald t :fun ert-fail :args (...) :flags nil :locals nil :buffer nil :pos nil) #s(backtrace-frame :evald t :fun #f(compiled-function () #<bytecode -0x1f7de5bca9a1bc>) :args nil :flags nil :locals (...) :buffer nil :pos nil) #s(backtrace-frame :evald t :fun #f(compiled-function () #<bytecode 0x196bb7a271c9b47a>) :args nil :flags nil :locals nil :buffer nil :pos nil) #s(backtrace-frame :evald t :fun handler-bind-1 :args (#f(compiled-function () #<bytecode 0x196bb7a271c9b47a>) ... #f(compiled-function (err) #<bytecode 0xc4c41af3b23fdc1>)) :flags nil :locals nil :buffer nil :pos nil) #s(backtrace-frame :evald t :fun ert--run-test-internal :args (...) :flags nil :locals (... ...) :buffer nil :pos nil) #s(backtrace-frame :evald t :fun ert-run-test :args #0 :flags nil :locals (... ... ...) :buffer nil :pos nil) #s(backtrace-frame :evald t :fun ert-run-or-rerun-test :args (... #1 #f(compiled-function (event-type &rest event-args) #<bytecode 0x7468cbaaf245164>)) :flags nil :locals (...) :buffer nil :pos nil) #s(backtrace-frame :evald t :fun ert-run-tests :args (... #f(compiled-function (event-type &rest event-args) #<bytecode 0x7468cbaaf245164>) nil) :flags nil :locals (...) :buffer nil :pos nil) #s(backtrace-frame :evald t :fun ert-run-tests-batch :args (...) :flags nil :locals nil :buffer nil :pos nil) #s(backtrace-frame :evald t :fun ert-run-tests-batch-and-exit :args (...) :flags nil :locals nil :buffer nil :pos nil) #s(backtrace-frame :evald t :fun eval :args (... t) :flags nil :locals nil :buffer nil :pos nil) #s(backtrace-frame :evald t :fun command-line-1 :args (...) :flags nil :locals (... ...) :buffer nil :pos nil) #s(backtrace-frame :evald t :fun command-line :args nil :flags nil :locals nil :buffer nil :pos nil) #s(backtrace-frame :evald t :fun normal-top-level :args nil :flags nil :locals nil :buffer nil :pos nil)) :infos nil) :expected-result-type :passed :tags nil :file-name "/home/local/USHERBROOKE/hoct2726/emacs/test/lisp/net/tramp-tests.el"))
  ert-run-or-rerun-test(#s(ert--stats :selector ... :tests ... :test-map #<hash-table eql 45/45 0x1e5875d2cfaf ...> :test-results ... :test-start-times ... :test-end-times ... :passed-expected 23 :passed-unexpected 0 :failed-expected 0 :failed-unexpected 1 :skipped 0 :start-time ... :end-time nil :aborted-p nil ...) #s(ert-test :name tramp-test18-file-attributes :documentation "Check `file-attributes'.\nThis tests also `access-file', `file-readable-p',\n`file-regular-p' and `file-ownership-preserved-p'." :body #f(compiled-function () #<bytecode -0x1f7de5bca9a1bc>) :most-recent-result ... :expected-result-type :passed :tags nil :file-name "/home/local/USHERBROOKE/hoct2726/emacs/test/lisp/net/tramp-tests.el") #f(compiled-function (event-type &rest event-args) #<bytecode 0x7468cbaaf245164>))
  ert-run-tests((not (or (tag :expensive-test) (tag :unstable) (tag :nativecomp))) #f(compiled-function (event-type &rest event-args) #<bytecode 0x7468cbaaf245164>) nil)
  ert-run-tests-batch((not (or (tag :expensive-test) (tag :unstable) (tag :nativecomp))))
  ert-run-tests-batch-and-exit((not (or (tag :expensive-test) (tag :unstable) (tag :nativecomp))))
  eval((ert-run-tests-batch-and-exit '(not (or (tag :expensive-test) (tag :unstable) (tag :nativecomp)))) t)
  command-line-1(("-L" ":." "-l" "ert" "--eval" "(setq treesit-extra-load-path '(\"/home/local/USHERBROOKE/hoct2726/.emacs.d/tree-sitter\"))" "-l" "lisp/net/tramp-tests" "--eval" "(ert-run-tests-batch-and-exit (quote (not (or (tag :expensive-test) (tag :unstable) (tag :nativecomp)))))"))
  command-line()
  normal-top-level()

Test tramp-test18-file-attributes condition:
    (ert-test-failed
     ((should (file-ownership-preserved-p tmp-name1 'group)) :form
      (file-ownership-preserved-p
       "/mock:dinf-thock-02i:/tmp/tramp-testFLwvbb" group)
      :value nil))
   FAILED  24/45  tramp-test18-file-attributes (1.463919 sec) at lisp/net/tramp-tests.el:3866
   passed  25/45  tramp-test19-directory-files-and-attributes (0.433324 sec)
   passed  26/45  tramp-test20-file-modes (0.384796 sec)
   passed  27/45  tramp-test21-file-links (1.116251 sec)
   passed  28/45  tramp-test22-file-times (0.426098 sec)
   passed  29/45  tramp-test23-visited-file-modtime (0.364305 sec)
  skipped  30/45  tramp-test24-file-acl (0.047813 sec)
  skipped  31/45  tramp-test25-file-selinux (0.271207 sec)
   passed  32/45  tramp-test26-file-name-completion (0.717971 sec)
   passed  33/45  tramp-test26-file-name-completion-boundaries (0.003569 sec)
   passed  34/45  tramp-test27-load (0.331137 sec)
   passed  35/45  tramp-test35-exec-path (0.329114 sec)
   passed  36/45  tramp-test37-make-auto-save-file-name (0.367755 sec)
   passed  37/45  tramp-test38-find-backup-file-name (0.517586 sec)
   passed  38/45  tramp-test40-make-nearby-temp-file (0.324409 sec)
   passed  39/45  tramp-test41-special-characters (0.801783 sec)
  skipped  40/45  tramp-test46-dired-compress-dir (0.016300 sec)
  skipped  41/45  tramp-test46-dired-compress-file (0.126677 sec)
   passed  42/45  tramp-test50-auto-load (0.322271 sec)
   passed  43/45  tramp-test50-delay-load (0.192760 sec)
   passed  44/45  tramp-test50-remote-load-path (0.168514 sec)
   passed  45/45  tramp-test51-without-remote-files (0.126789 sec)

Ran 45 tests, 40 results as expected, 1 unexpected, 4 skipped (2026-03-25 07:22:01-0400, 18.919371 sec)

1 unexpected results:
   FAILED  tramp-test18-file-attributes

4 skipped results:
  SKIPPED  tramp-test24-file-acl
  SKIPPED  tramp-test25-file-selinux
  SKIPPED  tramp-test46-dired-compress-dir
  SKIPPED  tramp-test46-dired-compress-file

make[2]: *** [Makefile:185: lisp/net/tramp-tests.log] Error 1
  GEN      lisp/emacs-lisp/package-vc-tests.log
  GEN      lib-src/emacsclient-tests.log
  GEN      lisp/abbrev-tests.log
  GEN      lisp/align-tests.log
  GEN      lisp/allout-tests.log
  GEN      lisp/allout-widgets-tests.log
  GEN      lisp/ansi-color-tests.log
  GEN      lisp/ansi-osc-tests.log
  GEN      lisp/apropos-tests.log
  GEN      lisp/arc-mode-tests.log
  GEN      lisp/auth-source-pass-tests.log
  GEN      lisp/auth-source-tests.log
  GEN      lisp/autoinsert-tests.log
  GEN      lisp/autorevert-tests.log
  GEN      lisp/battery-tests.log
  GEN      lisp/bookmark-tests.log
  GEN      lisp/buff-menu-tests.log
  GEN      lisp/button-tests.log
  GEN      lisp/calc/calc-tests.log
  GEN      lisp/calculator-tests.log
  GEN      lisp/calendar/cal-bahai-tests.log
  GEN      lisp/calendar/cal-french-tests.log
  GEN      lisp/calendar/cal-julian-tests.log
  GEN      lisp/calendar/calendar-tests.log
  GEN      lisp/calendar/diary-icalendar-tests.log
  GEN      lisp/calendar/holidays-tests.log
  GEN      lisp/calendar/icalendar-ast-tests.log
  GEN      lisp/calendar/icalendar-parser-tests.log
  GEN      lisp/calendar/icalendar-recur-tests.log
  GEN      lisp/calendar/icalendar-tests.log
  GEN      lisp/calendar/iso8601-tests.log
  GEN      lisp/calendar/lunar-tests.log
  GEN      lisp/calendar/parse-time-tests.log
  GEN      lisp/calendar/solar-tests.log
  GEN      lisp/calendar/time-date-tests.log
  GEN      lisp/calendar/todo-mode-tests.log
  GEN      lisp/cedet/cedet-files-tests.log
  GEN      lisp/cedet/semantic-utest-c.log
  GEN      lisp/cedet/semantic-utest-ia.log
  GEN      lisp/cedet/semantic-utest.log
  GEN      lisp/cedet/semantic/bovine/gcc-tests.log
  GEN      lisp/cedet/semantic/format-tests.log
  GEN      lisp/cedet/semantic/fw-tests.log
  GEN      lisp/cedet/srecode-utest-getset.log
  GEN      lisp/cedet/srecode-utest-template.log
  GEN      lisp/cedet/srecode/document-tests.log
  GEN      lisp/cedet/srecode/fields-tests.log
  GEN      lisp/char-fold-tests.log
  GEN      lisp/color-tests.log
  GEN      lisp/comint-tests.log
  GEN      lisp/completion-preview-tests.log
  GEN      lisp/completion-tests.log
  GEN      lisp/cus-edit-tests.log
  GEN      lisp/custom-tests.log
  GEN      lisp/dabbrev-tests.log
  GEN      lisp/delim-col-tests.log
  GEN      lisp/descr-text-tests.log
  GEN      lisp/desktop-tests.log
  GEN      lisp/dired-aux-tests.log
  GEN      lisp/dired-tests.log
  GEN      lisp/dired-x-tests.log
  GEN      lisp/dnd-tests.log
  GEN      lisp/dom-tests.log
  GEN      lisp/edmacro-tests.log
  GEN      lisp/electric-tests.log
  GEN      lisp/elide-head-tests.log
  GEN      lisp/emacs-lisp/backquote-tests.log
  GEN      lisp/emacs-lisp/backtrace-tests.log
  GEN      lisp/emacs-lisp/benchmark-tests.log
  GEN      lisp/emacs-lisp/bindat-tests.log
  GEN      lisp/emacs-lisp/byte-run-tests.log
  ELC      lisp/emacs-lisp/bytecomp-tests.elc
  GEN      lisp/emacs-lisp/bytecomp-tests.log
  GEN      lisp/emacs-lisp/cconv-tests.log
  GEN      lisp/emacs-lisp/check-declare-tests.log
  GEN      lisp/emacs-lisp/checkdoc-tests.log
  GEN      lisp/emacs-lisp/cl-extra-tests.log
  GEN      lisp/emacs-lisp/cl-generic-tests.log
  GEN      lisp/emacs-lisp/cl-lib-tests.log
  GEN      lisp/emacs-lisp/cl-macs-tests.log
  GEN      lisp/emacs-lisp/cl-preloaded-tests.log
  GEN      lisp/emacs-lisp/cl-print-tests.log
  GEN      lisp/emacs-lisp/cl-seq-tests.log
  GEN      lisp/emacs-lisp/comp-cstr-tests.log
  GEN      lisp/emacs-lisp/comp-tests.log
  GEN      lisp/emacs-lisp/cond-star-tests.log
  GEN      lisp/emacs-lisp/copyright-tests.log
  GEN      lisp/emacs-lisp/derived-tests.log
  GEN      lisp/emacs-lisp/easy-mmode-tests.log
  GEN      lisp/emacs-lisp/edebug-tests.log
  GEN      lisp/emacs-lisp/eieio-tests/eieio-test-methodinvoke.log
  GEN      lisp/emacs-lisp/eieio-tests/eieio-test-persist.log
  GEN      lisp/emacs-lisp/eieio-tests/eieio-tests.log
  GEN      lisp/emacs-lisp/ert-font-lock-tests.log
  GEN      lisp/emacs-lisp/ert-tests.log
  GEN      lisp/emacs-lisp/ert-x-tests.log
  GEN      lisp/emacs-lisp/faceup-tests/faceup-test-basics.log
  GEN      lisp/emacs-lisp/faceup-tests/faceup-test-files.log
  GEN      lisp/emacs-lisp/find-func-tests.log
  GEN      lisp/emacs-lisp/float-sup-tests.log
  GEN      lisp/emacs-lisp/generator-tests.log
  GEN      lisp/emacs-lisp/gv-tests.log
  GEN      lisp/emacs-lisp/hierarchy-tests.log
  GEN      lisp/emacs-lisp/icons-tests.log
  GEN      lisp/emacs-lisp/let-alist-tests.log
  GEN      lisp/emacs-lisp/lisp-mnt-tests.log
  GEN      lisp/emacs-lisp/lisp-mode-tests.log
  GEN      lisp/emacs-lisp/lisp-tests.log
  GEN      lisp/emacs-lisp/macroexp-tests.log
  GEN      lisp/emacs-lisp/map-tests.log
  GEN      lisp/emacs-lisp/map-ynp-tests.log
  GEN      lisp/emacs-lisp/memory-report-tests.log
  GEN      lisp/emacs-lisp/multisession-tests.log
  GEN      lisp/emacs-lisp/nadvice-tests.log
  GEN      lisp/emacs-lisp/oclosure-tests.log
  GEN      lisp/emacs-lisp/package-tests.log
  GEN      lisp/emacs-lisp/pcase-tests.log
  GEN      lisp/emacs-lisp/pp-tests.log
  GEN      lisp/emacs-lisp/range-tests.log
  GEN      lisp/emacs-lisp/regexp-opt-tests.log
  GEN      lisp/emacs-lisp/ring-tests.log
  GEN      lisp/emacs-lisp/rmc-tests.log
  GEN      lisp/emacs-lisp/rx-tests.log
  GEN      lisp/emacs-lisp/seq-tests.log
  GEN      lisp/emacs-lisp/shadow-tests.log
  GEN      lisp/emacs-lisp/shortdoc-tests.log
  GEN      lisp/emacs-lisp/subr-x-tests.log
  GEN      lisp/emacs-lisp/syntax-tests.log
  GEN      lisp/emacs-lisp/tabulated-list-tests.log
  GEN      lisp/emacs-lisp/testcover-tests.log
  GEN      lisp/emacs-lisp/text-property-search-tests.log
  GEN      lisp/emacs-lisp/thunk-tests.log
  GEN      lisp/emacs-lisp/timer-tests.log
  GEN      lisp/emacs-lisp/track-changes-tests.log
  GEN      lisp/emacs-lisp/unsafep-tests.log
  GEN      lisp/emacs-lisp/vtable-tests.log
  GEN      lisp/emacs-lisp/warnings-tests.log
  GEN      lisp/emulation/viper-tests.log
  GEN      lisp/env-tests.log
  GEN      lisp/epg-config-tests.log
  GEN      lisp/epg-tests.log
  GEN      lisp/erc/erc-button-tests.log
Running 5 tests (2026-03-25 07:23:49-0400, selector `(not (or (tag :expensive-test) (tag :unstable) (tag :nativecomp)))')
   passed  1/5  erc-button--display-error-notice-with-keys (0.172377 sec)
Test erc-button-alist--function-as-form backtrace:
  signal(ert-test-failed (((should (equal (pop erc-button-tests--form)
  ert-fail(((should (equal (pop erc-button-tests--form) '(53 55 ignore
  erc-button-tests--erc-button-alist--function-as-form(erc-button-test
  #f(compiled-function () #<bytecode -0xa0f4d146ec93dde>)()
  #f(compiled-function () #<bytecode 0x5da799f4dc45437>)()
  handler-bind-1(#f(compiled-function () #<bytecode 0x5da799f4dc45437>
  ert--run-test-internal(#s(ert--test-execution-info :test #s(ert-test
  ert-run-test(#s(ert-test :name erc-button-alist--function-as-form :d
  ert-run-or-rerun-test(#s(ert--stats :selector (not (or ... ... ...))
  ert-run-tests((not (or (tag :expensive-test) (tag :unstable) (tag :n
  ert-run-tests-batch((not (or (tag :expensive-test) (tag :unstable) (
  ert-run-tests-batch-and-exit((not (or (tag :expensive-test) (tag :un
  eval((ert-run-tests-batch-and-exit '(not (or (tag :expensive-test) (
  command-line-1(("-L" ":." "-l" "ert" "--eval" "(setq treesit-extra-l
  command-line()
  normal-top-level()
Test erc-button-alist--function-as-form condition:
    (ert-test-failed
     ((should
       (equal (pop erc-button-tests--form) '(53 55 ignore nil ... "\\+1")))
      :form
      (equal (55 57 ignore nil ("+1") "\\+1")
	     (53 55 ignore nil ("+1") "\\+1"))
      :value nil :explanation
      (list-elt 0 (different-atoms (55 "#x37" "?7") (53 "#x35" "?5")))))
   FAILED  2/5  erc-button-alist--function-as-form (0.032756 sec) at lisp/erc/erc-button-tests.el:95
   passed  3/5  erc-button-alist--nil-form (0.009307 sec)
   passed  4/5  erc-button-alist--url (0.003744 sec)
   passed  5/5  erc-button-next (0.009141 sec)

Ran 5 tests, 4 results as expected, 1 unexpected (2026-03-25 07:23:50-0400, 0.333040 sec)

1 unexpected results:
   FAILED  erc-button-alist--function-as-form

make[2]: *** [Makefile:185: lisp/erc/erc-button-tests.log] Error 1
  GEN      lisp/erc/erc-dcc-tests.log
  GEN      lisp/erc/erc-fill-tests.log
  GEN      lisp/erc/erc-goodies-tests.log
  GEN      lisp/erc/erc-join-tests.log
  GEN      lisp/erc/erc-match-tests.log
  GEN      lisp/erc/erc-networks-tests.log
  GEN      lisp/erc/erc-nicks-tests.log
  GEN      lisp/erc/erc-notify-tests.log
  GEN      lisp/erc/erc-sasl-tests.log
  GEN      lisp/erc/erc-scenarios-auth-source.log
  GEN      lisp/erc/erc-scenarios-base-association-nick.log
  GEN      lisp/erc/erc-scenarios-base-association-query.log
  GEN      lisp/erc/erc-scenarios-base-association-samenet.log
  GEN      lisp/erc/erc-scenarios-base-association.log
  GEN      lisp/erc/erc-scenarios-base-attach.log
  GEN      lisp/erc/erc-scenarios-base-auto-recon.log
  GEN      lisp/erc/erc-scenarios-base-buffer-display.log
  GEN      lisp/erc/erc-scenarios-base-chan-modes.log
  GEN      lisp/erc/erc-scenarios-base-compat-rename-bouncer.log
  GEN      lisp/erc/erc-scenarios-base-kill-on-part.log
  GEN      lisp/erc/erc-scenarios-base-local-module-modes.log
  GEN      lisp/erc/erc-scenarios-base-local-modules.log
  GEN      lisp/erc/erc-scenarios-base-misc-regressions.log
  GEN      lisp/erc/erc-scenarios-base-netid-bouncer-id.log
  GEN      lisp/erc/erc-scenarios-base-netid-bouncer-recon-base.log
  GEN      lisp/erc/erc-scenarios-base-netid-bouncer-recon-both.log
  GEN      lisp/erc/erc-scenarios-base-netid-bouncer-recon-id.log
  GEN      lisp/erc/erc-scenarios-base-netid-bouncer.log
  GEN      lisp/erc/erc-scenarios-base-netid-samenet.log
  GEN      lisp/erc/erc-scenarios-base-query-participants.log
  GEN      lisp/erc/erc-scenarios-base-reconnect.log
  GEN      lisp/erc/erc-scenarios-base-renick.log
  GEN      lisp/erc/erc-scenarios-base-reuse-buffers.log
  GEN      lisp/erc/erc-scenarios-base-send-message.log
  GEN      lisp/erc/erc-scenarios-base-split-line.log
  GEN      lisp/erc/erc-scenarios-base-statusmsg.log
  GEN      lisp/erc/erc-scenarios-base-unstable.log
  GEN      lisp/erc/erc-scenarios-base-upstream-recon-soju.log
  GEN      lisp/erc/erc-scenarios-base-upstream-recon-znc.log
  GEN      lisp/erc/erc-scenarios-display-message.log
  GEN      lisp/erc/erc-scenarios-fill-wrap.log
  GEN      lisp/erc/erc-scenarios-ignore.log
  GEN      lisp/erc/erc-scenarios-internal.log
  GEN      lisp/erc/erc-scenarios-join-auth-source.log
  GEN      lisp/erc/erc-scenarios-join-display-context.log
  GEN      lisp/erc/erc-scenarios-join-netid-newcmd-id.log
  GEN      lisp/erc/erc-scenarios-join-netid-newcmd.log
  GEN      lisp/erc/erc-scenarios-join-netid-recon-id.log
  GEN      lisp/erc/erc-scenarios-join-netid-recon.log
  GEN      lisp/erc/erc-scenarios-join-timing.log
  GEN      lisp/erc/erc-scenarios-keep-place-indicator-trunc.log
  GEN      lisp/erc/erc-scenarios-keep-place-indicator.log
  GEN      lisp/erc/erc-scenarios-log.log
  GEN      lisp/erc/erc-scenarios-match.log
Running 2 tests (2026-03-25 07:24:11-0400, selector `(not (or (tag :expensive-test) (tag :unstable) (tag :nativecomp)))')
Test erc-scenarios-match--hide-fools/stamp-both/fill-wrap backtrace:
  search-forward("[Wed Apr 29 1992]")
  #f(compiled-function () #<bytecode 0x23cfd25e6da4b97>)()
  erc-scenarios-match--invisible-stamp(#f(compiled-function () #<bytec
  #f(compiled-function () #<bytecode 0xbfe3cc4cef2c5bb>)()
  #f(compiled-function () #<bytecode -0x48310ba74c2c3aa>)()
  handler-bind-1(#f(compiled-function () #<bytecode -0x48310ba74c2c3aa
  ert--run-test-internal(#s(ert--test-execution-info :test #s(ert-test
  ert-run-test(#s(ert-test :name erc-scenarios-match--hide-fools/stamp
  ert-run-or-rerun-test(#s(ert--stats :selector (not (or ... ... ...))
  ert-run-tests((not (or (tag :expensive-test) (tag :unstable) (tag :n
  ert-run-tests-batch((not (or (tag :expensive-test) (tag :unstable) (
  ert-run-tests-batch-and-exit((not (or (tag :expensive-test) (tag :un
  eval((ert-run-tests-batch-and-exit '(not (or (tag :expensive-test) (
  command-line-1(("-L" ":." "-l" "ert" "--eval" "(setq treesit-extra-l
  command-line()
  normal-top-level()
Test erc-scenarios-match--hide-fools/stamp-both/fill-wrap condition:
    Info: Ensure lines featuring "bob" are invisible
    Info: <bob> tester, welcome!
    Info: Baseline check
    (search-failed "[Wed Apr 29 1992]")
   FAILED  1/2  erc-scenarios-match--hide-fools/stamp-both/fill-wrap (0.453795 sec) at lisp/erc/erc-scenarios-match.el:268
   passed  2/2  erc-scenarios-match--hide-fools/stamp-both/fill-wrap/speak (0.449493 sec)

Ran 2 tests, 1 results as expected, 1 unexpected (2026-03-25 07:24:12-0400, 1.016042 sec)

1 unexpected results:
   FAILED  erc-scenarios-match--hide-fools/stamp-both/fill-wrap

make[2]: *** [Makefile:185: lisp/erc/erc-scenarios-match.log] Error 1
  GEN      lisp/erc/erc-scenarios-misc-commands.log
  GEN      lisp/erc/erc-scenarios-misc.log
  GEN      lisp/erc/erc-scenarios-nicks-track.log
  GEN      lisp/erc/erc-scenarios-prompt-format.log
  GEN      lisp/erc/erc-scenarios-sasl.log
  GEN      lisp/erc/erc-scenarios-scrolltobottom-relaxed.log
  GEN      lisp/erc/erc-scenarios-scrolltobottom.log
  GEN      lisp/erc/erc-scenarios-services-misc.log
  GEN      lisp/erc/erc-scenarios-spelling.log
  GEN      lisp/erc/erc-scenarios-stamp.log
  GEN      lisp/erc/erc-scenarios-status-sidebar.log
  GEN      lisp/erc/erc-services-tests.log
  GEN      lisp/erc/erc-stamp-tests.log
Running 12 tests (2026-03-25 07:24:17-0400, selector `(not (or (tag :expensive-test) (tag :unstable) (tag :nativecomp)))')
   passed   1/12  erc--get-inserted-msg-beg/readonly/stamp (0.000493 sec)
   passed   2/12  erc--get-inserted-msg-beg/stamp (0.000313 sec)
   passed   3/12  erc--get-inserted-msg-bounds/readonly/stamp (0.000348 sec)
   passed   4/12  erc--get-inserted-msg-bounds/stamp (0.000294 sec)
   passed   5/12  erc--get-inserted-msg-end/readonly/stamp (0.000291 sec)
   passed   6/12  erc--get-inserted-msg-end/stamp (0.000264 sec)
Test erc-stamp--dedupe-date-stamps-from-target-buffer backtrace:
  signal(ert-test-failed (((should (looking-at (rx "\n[Mon Jul 31 2023
  ert-fail(((should (looking-at (rx "\n[Mon Jul 31 2023]"))) :form (lo
  #f(compiled-function () #<bytecode 0xd906eabeb17c5e4>)()
  #f(compiled-function () #<bytecode -0x103861665bd663f7>)()
  handler-bind-1(#f(compiled-function () #<bytecode -0x103861665bd663f
  ert--run-test-internal(#s(ert--test-execution-info :test #s(ert-test
  ert-run-test(#s(ert-test :name erc-stamp--dedupe-date-stamps-from-ta
  ert-run-or-rerun-test(#s(ert--stats :selector ... :tests ... :test-m
  ert-run-tests((not (or (tag :expensive-test) (tag :unstable) (tag :n
  ert-run-tests-batch((not (or (tag :expensive-test) (tag :unstable) (
  ert-run-tests-batch-and-exit((not (or (tag :expensive-test) (tag :un
  eval((ert-run-tests-batch-and-exit '(not (or (tag :expensive-test) (
  command-line-1(("-L" ":." "-l" "ert" "--eval" "(setq treesit-extra-l
  command-line()
  normal-top-level()
Test erc-stamp--dedupe-date-stamps-from-target-buffer condition:
    (ert-test-failed
     ((should (looking-at (rx "\n[Mon Jul 31 2023]"))) :form
      (looking-at "\n\\[Mon Jul 31 2023]") :value nil))
   FAILED   7/12  erc-stamp--dedupe-date-stamps-from-target-buffer (0.077988 sec) at lisp/erc/erc-stamp-tests.el:354
   passed   8/12  erc-stamp--display-margin-mode--right (0.001561 sec)
   passed   9/12  erc-timestamp-intangible--left (0.004706 sec)
   passed  10/12  erc-timestamp-use-align-to--integer (0.001300 sec)
   passed  11/12  erc-timestamp-use-align-to--nil (0.003306 sec)
   passed  12/12  erc-timestamp-use-align-to--t (0.003019 sec)

Ran 12 tests, 11 results as expected, 1 unexpected (2026-03-25 07:24:17-0400, 0.223640 sec)

1 unexpected results:
   FAILED  erc-stamp--dedupe-date-stamps-from-target-buffer

make[2]: *** [Makefile:185: lisp/erc/erc-stamp-tests.log] Error 1
  GEN      lisp/erc/erc-tests.log
  GEN      lisp/erc/erc-track-tests.log
  GEN      lisp/eshell/em-alias-tests.log
  GEN      lisp/eshell/em-basic-tests.log
  GEN      lisp/eshell/em-cmpl-tests.log
  GEN      lisp/eshell/em-dirs-tests.log
  GEN      lisp/eshell/em-extpipe-tests.log
  GEN      lisp/eshell/em-glob-tests.log
  GEN      lisp/eshell/em-hist-tests.log
  GEN      lisp/eshell/em-ls-tests.log
  GEN      lisp/eshell/em-pred-tests.log
  GEN      lisp/eshell/em-prompt-tests.log
  GEN      lisp/eshell/em-script-tests.log
  GEN      lisp/eshell/em-tramp-tests.log
  GEN      lisp/eshell/em-unix-tests.log
  GEN      lisp/eshell/esh-arg-tests.log
  GEN      lisp/eshell/esh-cmd-tests.log
  GEN      lisp/eshell/esh-ext-tests.log
  GEN      lisp/eshell/esh-io-tests.log
  GEN      lisp/eshell/esh-mode-tests.log
  GEN      lisp/eshell/esh-opt-tests.log
  GEN      lisp/eshell/esh-proc-tests.log
  GEN      lisp/eshell/esh-util-tests.log
  GEN      lisp/eshell/esh-var-tests.log
  GEN      lisp/eshell/eshell-tests-unload.log
  GEN      lisp/eshell/eshell-tests.log
  GEN      lisp/faces-tests.log
  GEN      lisp/ffap-tests.log
  GEN      lisp/filenotify-tests.log
  GEN      lisp/files-tests.log
  GEN      lisp/files-x-tests.log
  GEN      lisp/find-cmd-tests.log
  GEN      lisp/follow-tests.log
  GEN      lisp/font-lock-tests.log
  GEN      lisp/format-spec-tests.log
  GEN      lisp/gnus/gnus-group-tests.log
  GEN      lisp/gnus/gnus-icalendar-tests.log
  GEN      lisp/gnus/gnus-search-tests.log
  GEN      lisp/gnus/gnus-test-headers.log
  GEN      lisp/gnus/gnus-tests.log
  GEN      lisp/gnus/gnus-util-tests.log
  GEN      lisp/gnus/message-tests.log
  GEN      lisp/gnus/mm-decode-tests.log
  GEN      lisp/gnus/mml-sec-tests.log
  GEN      lisp/gnus/nnrss-tests.log
  GEN      lisp/help-fns-tests.log
  GEN      lisp/help-mode-tests.log
  GEN      lisp/help-tests.log
  GEN      lisp/hfy-cmap-tests.log
  GEN      lisp/hi-lock-tests.log
  GEN      lisp/hl-line-tests.log
  GEN      lisp/htmlfontify-tests.log
  GEN      lisp/ibuffer-tests.log
  GEN      lisp/ido-tests.log
  GEN      lisp/image-file-tests.log
  GEN      lisp/image-tests.log
  GEN      lisp/image/exif-tests.log
  GEN      lisp/image/gravatar-tests.log
  GEN      lisp/image/image-dired-tests.log
  GEN      lisp/image/image-dired-util-tests.log
  GEN      lisp/image/wallpaper-tests.log
  GEN      lisp/imenu-tests.log
  GEN      lisp/info-tests.log
  GEN      lisp/info-xref-tests.log
  GEN      lisp/international/ccl-tests.log
  GEN      lisp/international/mule-tests.log
  GEN      lisp/international/mule-util-tests.log
  GEN      lisp/international/textsec-tests.log
  GEN      lisp/international/ucs-normalize-tests.log
  GEN      lisp/isearch-tests.log
  GEN      lisp/jit-lock-tests.log
  GEN      lisp/json-tests.log
  GEN      lisp/jsonrpc-tests.log
  GEN      lisp/kmacro-tests.log
  GEN      lisp/language/viet-util-tests.log
  GEN      lisp/loadhist-tests.log
  GEN      lisp/lpr-tests.log
  GEN      lisp/ls-lisp-tests.log
  GEN      lisp/mail/flow-fill-tests.log
  GEN      lisp/mail/footnote-tests.log
  GEN      lisp/mail/ietf-drums-date-tests.log
  GEN      lisp/mail/ietf-drums-tests.log
  GEN      lisp/mail/mail-extr-tests.log
  GEN      lisp/mail/mail-parse-tests.log
  GEN      lisp/mail/mail-utils-tests.log
  GEN      lisp/mail/qp-tests.log
  GEN      lisp/mail/rfc2045-tests.log
  GEN      lisp/mail/rfc2047-tests.log
  GEN      lisp/mail/rfc6068-tests.log
  GEN      lisp/mail/rfc822-tests.log
  GEN      lisp/mail/rmail-tests.log
  GEN      lisp/mail/rmailmm-tests.log
  GEN      lisp/mail/rmailsum-tests.log
  GEN      lisp/mail/undigest-tests.log
  GEN      lisp/mail/uudecode-tests.log
  GEN      lisp/man-tests.log
  GEN      lisp/md4-tests.log
  GEN      lisp/mh-e/mh-limit-tests.log
  GEN      lisp/mh-e/mh-thread-tests.log
  GEN      lisp/mh-e/mh-utils-tests.log
  GEN      lisp/mh-e/mh-xface-tests.log
  GEN      lisp/minibuffer-tests.log
  GEN      lisp/misc-tests.log
  GEN      lisp/mouse-tests.log
  GEN      lisp/mwheel-tests.log
  GEN      lisp/net/browse-url-tests.log
  GEN      lisp/net/dbus-tests.log
  GEN      lisp/net/dig-tests.log
  GEN      lisp/net/eudc-tests.log
  GEN      lisp/net/eww-tests.log
  GEN      lisp/net/gnutls-tests.log
  GEN      lisp/net/hmac-md5-tests.log
  GEN      lisp/net/mailcap-tests.log
  GEN      lisp/net/network-stream-tests.log
  GEN      lisp/net/newsticker-tests.log
  GEN      lisp/net/nsm-tests.log
  GEN      lisp/net/ntlm-tests.log
  GEN      lisp/net/puny-tests.log
  GEN      lisp/net/rcirc-tests.log
  GEN      lisp/net/rfc2104-tests.log
  GEN      lisp/net/sasl-cram-tests.log
  GEN      lisp/net/sasl-scram-rfc-tests.log
  GEN      lisp/net/sasl-tests.log
  GEN      lisp/net/secrets-tests.log
  GEN      lisp/net/shr-tests.log
  GEN      lisp/net/socks-tests.log
  GEN      lisp/net/tramp-archive-tests.log
  GEN      lisp/net/webjump-tests.log
  GEN      lisp/newcomment-tests.log
  GEN      lisp/nxml/nxml-mode-tests.log
  GEN      lisp/nxml/xsd-regexp-tests.log
  GEN      lisp/obarray-tests.log
  GEN      lisp/obsolete/cl-tests.log
  GEN      lisp/obsolete/inversion-tests.log
  GEN      lisp/obsolete/makesum-tests.log
  GEN      lisp/obsolete/rfc2368-tests.log
  GEN      lisp/obsolete/thumbs-tests.log
  GEN      lisp/org/org-tests.log
  GEN      lisp/paren-tests.log
  GEN      lisp/password-cache-tests.log
  GEN      lisp/pcmpl-linux-tests.log
  GEN      lisp/pcomplete-tests.log
  GEN      lisp/play/animate-tests.log
  GEN      lisp/play/cookie1-tests.log
  GEN      lisp/play/dissociate-tests.log
  GEN      lisp/play/fortune-tests.log
  GEN      lisp/play/life-tests.log
  GEN      lisp/play/morse-tests.log
  GEN      lisp/play/studly-tests.log
  GEN      lisp/proced-tests.log
  GEN      lisp/progmodes/asm-mode-tests.log
  GEN      lisp/progmodes/autoconf-tests.log
  GEN      lisp/progmodes/bat-mode-tests.log
  GEN      lisp/progmodes/bug-reference-tests.log
  GEN      lisp/progmodes/c-ts-mode-tests.log
  GEN      lisp/progmodes/cc-mode-tests.log
  GEN      lisp/progmodes/compile-tests.log
Running 3 tests (2026-03-25 07:25:30-0400, selector `(not (or (tag :expensive-test) (tag :unstable) (tag :nativecomp)))')
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
   passed  2/3  compile-test-functions (0.000304 sec)
   passed  3/3  compile-test-grep-regexps (0.003733 sec)

Ran 3 tests, 2 results as expected, 1 unexpected (2026-03-25 07:25:30-0400, 0.155392 sec)

1 unexpected results:
   FAILED  compile-test-error-regexps

make[2]: *** [Makefile:185: lisp/progmodes/compile-tests.log] Error 1
  GEN      lisp/progmodes/cperl-mode-tests.log
  GEN      lisp/progmodes/csharp-mode-tests.log
  GEN      lisp/progmodes/eglot-tests.log
Running 56 tests (2026-03-25 07:25:31-0400, selector `(not (or (tag :expensive-test) (tag :unstable) (tag :nativecomp)))')
  skipped   1/56  eglot-test-auto-detect-running-server (0.000358 sec)
  skipped   2/56  eglot-test-auto-reconnect (0.000243 sec)
  skipped   3/56  eglot-test-auto-shutdown (0.000245 sec)
  skipped   4/56  eglot-test-basic-completions (0.000236 sec)
  skipped   5/56  eglot-test-basic-diagnostics (0.000236 sec)
  skipped   6/56  eglot-test-basic-pull-diagnostics (0.000233 sec)
  skipped   7/56  eglot-test-basic-stream-diagnostics (0.000324 sec)
  skipped   8/56  eglot-test-basic-symlink (0.000238 sec)
  skipped   9/56  eglot-test-basic-xref (0.000237 sec)
   passed  10/56  eglot-test-capabilities (0.000063 sec)
   passed  11/56  eglot-test-dcase (0.000079 sec)
   passed  12/56  eglot-test-dcase-issue-452 (0.000058 sec)
  skipped  13/56  eglot-test-diagnostic-tags-unnecessary-code (0.000243 sec)
  skipped  14/56  eglot-test-eclipse-connect (0.000277 sec)
  skipped  15/56  eglot-test-eldoc-after-completions (0.000233 sec)
  skipped  16/56  eglot-test-ensure (0.000255 sec)
  skipped  17/56  eglot-test-formatting (0.000256 sec)
   passed  18/56  eglot-test-glob-test (0.097454 sec)
  skipped  19/56  eglot-test-json-basic (0.000373 sec)
  skipped  20/56  eglot-test-lsp-abiding-column (0.000478 sec)
  skipped  21/56  eglot-test-multiline-eldoc (0.000241 sec)
  skipped  22/56  eglot-test-non-unique-completions (0.000229 sec)
   passed  23/56  eglot-test-path-to-uri-escape (0.000150 sec)
  skipped  24/56  eglot-test-path-to-uri-windows (0.000079 sec)
[eglot-tests] [eglot-test-project-wide-diagnostics-rust-analyzer]: test start
Initialized empty Git repository in /tmp/eglot--fixture-yumZ4v/project/.git/
    Creating binary (application) package
note: see more `Cargo.toml` keys and their definitions at https://doc.rust-lang.org/cargo/reference/manifest.html
[jsonrpc] Server exited with status 1
[eglot-tests] [eglot-test-project-wide-diagnostics-rust-analyzer]: FAILED
[eglot-tests] contents of ` *EGLOT (project/(rust-mode)) output*' #<buffer  *EGLOT (project/(rust-mode)) output*>:
[eglot-tests] contents of ` *EGLOT (project/(rust-mode)) stderr*' #<buffer  *EGLOT (project/(rust-mode)) stderr*>:
error: Unknown binary 'rust-analyzer' in official toolchain 'nightly-x86_64-unknown-linux-gnu'.
[eglot-tests] contents of `*EGLOT (project/(rust-mode)) events*' #<buffer *EGLOT (project/(rust-mode)) events*>:
[jsonrpc] D[07:25:31.379] Running language server: rust-analyzer
[jsonrpc] e[07:25:31.379] --> initialize[1] {"jsonrpc":"2.0","id":1,"method":"initialize","params":{"processId":1050768,"clientInfo":{"name":"Eglot","version":"1.21"},"rootPath":"/tmp/eglot--fixture-yumZ4v/project/","rootUri":"file:///tmp/eglot--fixture-yumZ4v/project","initializationOptions":{},"capabilities":{"workspace":{"applyEdit":true,"executeCommand":{"dynamicRegistration":false},"workspaceEdit":{"documentChanges":true,"resourceOperations":["create","delete","rename"],"failureHandling":"abort"},"didChangeWatchedFiles":{"dynamicRegistration":true,"relativePatternSupport":true},"symbol":{"dynamicRegistration":false},"semanticTokens":{"refreshSupport":true},"configuration":true,"workspaceFolders":true},"textDocument":{"synchronization":{"dynamicRegistration":false,"willSave":true,"willSaveWaitUntil":true,"didSave":true},"completion":{"dynamicRegistration":false,"completionItem":{"snippetSupport":false,"deprecatedSupport":true,"resolveSupport":{"properties":["documentation","details","additionalTextEdits"]},"tagSupport":{"valueSet":[1]},"insertReplaceSupport":true},"contextSupport":true},"hover":{"dynamicRegistration":false,"contentFormat":["plaintext"]},"signatureHelp":{"dynamicRegistration":false,"signatureInformation":{"parameterInformation":{"labelOffsetSupport":true},"documentationFormat":["plaintext"],"activeParameterSupport":true}},"references":{"dynamicRegistration":false},"definition":{"dynamicRegistration":false,"linkSupport":true},"declaration":{"dynamicRegistration":false,"linkSupport":true},"implementation":{"dynamicRegistration":false,"linkSupport":true},"typeDefinition":{"dynamicRegistration":false,"linkSupport":true},"documentSymbol":{"dynamicRegistration":false,"hierarchicalDocumentSymbolSupport":true,"symbolKind":{"valueSet":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26]}},"documentHighlight":{"dynamicRegistration":false},"codeAction":{"dynamicRegistration":false,"resolveSupport":{"properties":["edit","command"]},"dataSupport":true,"codeActionLiteralSupport":{"codeActionKind":{"valueSet":["quickfix","refactor","refactor.extract","refactor.inline","refactor.rewrite","source","source.organizeImports"]}},"isPreferredSupport":true},"formatting":{"dynamicRegistration":false},"rangeFormatting":{"dynamicRegistration":false},"rename":{"dynamicRegistration":false,"prepareSupport":true},"semanticTokens":{"dynamicRegistration":false,"requests":{"full":{"delta":true}},"overlappingTokenSupport":true,"multilineTokenSupport":true,"tokenTypes":["namespace","type","class","enum","interface","struct","typeParameter","parameter","variable","property","enumMember","event","function","method","macro","keyword","modifier","comment","string","number","regexp","operator","decorator"],"tokenModifiers":["declaration","definition","readonly","static","deprecated","abstract","async","modification","documentation","defaultLibrary"],"formats":["relative"]},"inlayHint":{"dynamicRegistration":false},"callHierarchy":{"dynamicRegistration":false},"typeHierarchy":{"dynamicRegistration":false},"diagnostic":{"dynamicRegistration":false},"publishDiagnostics":{"relatedInformation":false,"versionSupport":true,"codeDescriptionSupport":false,"tagSupport":{"valueSet":[1,2]}},"$streamingDiagnostics":{"dynamicRegistration":false}},"window":{"showDocument":{"support":true},"showMessage":{"messageActionItem":{"additionalPropertiesSupport":true}},"workDoneProgress":true},"general":{"positionEncodings":["utf-32","utf-8","utf-16"]},"experimental":{}},"workspaceFolders":[{"uri":"file:///tmp/eglot--fixture-yumZ4v/project","name":"/tmp/eglot--fixture-yumZ4v/project/"}]}}
[stderr]  error: Unknown binary 'rust-analyzer' in official toolchain 'nightly-x86_64-unknown-linux-gnu'.
[jsonrpc] D[07:25:32.397] Connection state change: `exited abnormally with code 1
'

----------b---y---e---b---y---e----------
[eglot-tests] Killing (other-file.rs), wiping /tmp/eglot--fixture-yumZ4v
Test eglot-test-project-wide-diagnostics-rust-analyzer backtrace:
  signal(error ("[eglot] -1: Server died"))
  error("[eglot] %s" "-1: Server died")
  eglot--error("-1: Server died")
  eglot--connect((rust-mode) (vc Git "/tmp/eglot--fixture-yumZ4v/proje
  apply(eglot--connect ((rust-mode) (vc Git "/tmp/eglot--fixture-yumZ4
  eglot--tests-connect()
  #f(compiled-function () #<bytecode -0x1dcb724653f16f84>)()
  eglot--call-with-fixture((("project" ("main.rs" . "fn main() -> i32 
  #f(compiled-function () #<bytecode -0x11e13eff7daea254>)()
  #f(compiled-function () #<bytecode 0x1506d2dddd95dca5>)()
  handler-bind-1(#f(compiled-function () #<bytecode 0x1506d2dddd95dca5
  ert--run-test-internal(#s(ert--test-execution-info :test #s(ert-test
  ert-run-test(#s(ert-test :name eglot-test-project-wide-diagnostics-r
  ert-run-or-rerun-test(#s(ert--stats :selector ... :tests ... :test-m
  ert-run-tests((not (or (tag :expensive-test) (tag :unstable) (tag :n
  ert-run-tests-batch((not (or (tag :expensive-test) (tag :unstable) (
  ert-run-tests-batch-and-exit((not (or (tag :expensive-test) (tag :un
  eval((ert-run-tests-batch-and-exit '(not (or (tag :expensive-test) (
  command-line-1(("-L" ":." "-l" "ert" "--eval" "(setq treesit-extra-l
  command-line()
  normal-top-level()
Test eglot-test-project-wide-diagnostics-rust-analyzer condition:
    (error "[eglot] -1: Server died")
   FAILED  25/56  eglot-test-project-wide-diagnostics-rust-analyzer (1.144970 sec) at lisp/progmodes/eglot-tests.el:1010
  skipped  26/56  eglot-test-project-wide-diagnostics-typescript (0.000441 sec)
  skipped  27/56  eglot-test-rename-a-symbol (0.000259 sec)
[eglot-tests] [eglot-test-rust-analyzer-hover-after-edit]: test start
    Creating binary (application) package
note: see more `Cargo.toml` keys and their definitions at https://doc.rust-lang.org/cargo/reference/manifest.html
[jsonrpc] Server exited with status 1
[eglot-tests] [eglot-test-rust-analyzer-hover-after-edit]: FAILED
[eglot-tests] contents of ` *EGLOT (hover-project/(rust-ts-mode rust-mode)) output*' #<buffer  *EGLOT (hover-project/(rust-ts-mode rust-mode)) output*>:
[eglot-tests] contents of ` *EGLOT (hover-project/(rust-ts-mode rust-mode)) stderr*' #<buffer  *EGLOT (hover-project/(rust-ts-mode rust-mode)) stderr*>:
error: Unknown binary 'rust-analyzer' in official toolchain 'nightly-x86_64-unknown-linux-gnu'.
[eglot-tests] contents of `*EGLOT (hover-project/(rust-ts-mode rust-mode)) events*' #<buffer *EGLOT (hover-project/(rust-ts-mode rust-mode)) events*>:
[jsonrpc] D[07:25:32.652] Running language server: rust-analyzer
[jsonrpc] e[07:25:32.653] --> initialize[1] {"jsonrpc":"2.0","id":1,"method":"initialize","params":{"processId":1050768,"clientInfo":{"name":"Eglot","version":"1.21"},"rootPath":"/tmp/eglot--fixture-StLZAw/hover-project/","rootUri":"file:///tmp/eglot--fixture-StLZAw/hover-project","initializationOptions":{},"capabilities":{"workspace":{"applyEdit":true,"executeCommand":{"dynamicRegistration":false},"workspaceEdit":{"documentChanges":true,"resourceOperations":["create","delete","rename"],"failureHandling":"abort"},"didChangeWatchedFiles":{"dynamicRegistration":true,"relativePatternSupport":true},"symbol":{"dynamicRegistration":false},"semanticTokens":{"refreshSupport":true},"configuration":true,"workspaceFolders":true},"textDocument":{"synchronization":{"dynamicRegistration":false,"willSave":true,"willSaveWaitUntil":true,"didSave":true},"completion":{"dynamicRegistration":false,"completionItem":{"snippetSupport":false,"deprecatedSupport":true,"resolveSupport":{"properties":["documentation","details","additionalTextEdits"]},"tagSupport":{"valueSet":[1]},"insertReplaceSupport":true},"contextSupport":true},"hover":{"dynamicRegistration":false,"contentFormat":["plaintext"]},"signatureHelp":{"dynamicRegistration":false,"signatureInformation":{"parameterInformation":{"labelOffsetSupport":true},"documentationFormat":["plaintext"],"activeParameterSupport":true}},"references":{"dynamicRegistration":false},"definition":{"dynamicRegistration":false,"linkSupport":true},"declaration":{"dynamicRegistration":false,"linkSupport":true},"implementation":{"dynamicRegistration":false,"linkSupport":true},"typeDefinition":{"dynamicRegistration":false,"linkSupport":true},"documentSymbol":{"dynamicRegistration":false,"hierarchicalDocumentSymbolSupport":true,"symbolKind":{"valueSet":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26]}},"documentHighlight":{"dynamicRegistration":false},"codeAction":{"dynamicRegistration":false,"resolveSupport":{"properties":["edit","command"]},"dataSupport":true,"codeActionLiteralSupport":{"codeActionKind":{"valueSet":["quickfix","refactor","refactor.extract","refactor.inline","refactor.rewrite","source","source.organizeImports"]}},"isPreferredSupport":true},"formatting":{"dynamicRegistration":false},"rangeFormatting":{"dynamicRegistration":false},"rename":{"dynamicRegistration":false,"prepareSupport":true},"semanticTokens":{"dynamicRegistration":false,"requests":{"full":{"delta":true}},"overlappingTokenSupport":true,"multilineTokenSupport":true,"tokenTypes":["namespace","type","class","enum","interface","struct","typeParameter","parameter","variable","property","enumMember","event","function","method","macro","keyword","modifier","comment","string","number","regexp","operator","decorator"],"tokenModifiers":["declaration","definition","readonly","static","deprecated","abstract","async","modification","documentation","defaultLibrary"],"formats":["relative"]},"inlayHint":{"dynamicRegistration":false},"callHierarchy":{"dynamicRegistration":false},"typeHierarchy":{"dynamicRegistration":false},"diagnostic":{"dynamicRegistration":false},"publishDiagnostics":{"relatedInformation":false,"versionSupport":true,"codeDescriptionSupport":false,"tagSupport":{"valueSet":[1,2]}},"$streamingDiagnostics":{"dynamicRegistration":false}},"window":{"showDocument":{"support":true},"showMessage":{"messageActionItem":{"additionalPropertiesSupport":true}},"workDoneProgress":true},"general":{"positionEncodings":["utf-32","utf-8","utf-16"]},"experimental":{}},"workspaceFolders":[{"uri":"file:///tmp/eglot--fixture-StLZAw/hover-project","name":"/tmp/eglot--fixture-StLZAw/hover-project/"}]}}
[stderr]  error: Unknown binary 'rust-analyzer' in official toolchain 'nightly-x86_64-unknown-linux-gnu'.
[jsonrpc] D[07:25:33.733] Connection state change: `exited abnormally with code 1
'

----------b---y---e---b---y---e----------
[eglot-tests] Killing (main.rs), wiping /tmp/eglot--fixture-StLZAw
Test eglot-test-rust-analyzer-hover-after-edit backtrace:
  signal(error ("[eglot] -1: Server died"))
  error("[eglot] %s" "-1: Server died")
  eglot--error("-1: Server died")
  eglot--connect((rust-ts-mode rust-mode) (transient . "/tmp/eglot--fi
  apply(eglot--connect ((rust-ts-mode rust-mode) (transient . "/tmp/eg
  eglot--tests-connect()
  #f(compiled-function () #<bytecode -0xc8b3f977d9a4061>)()
  eglot--call-with-fixture((("hover-project" ("main.rs" . "fn test() -
  #f(compiled-function () #<bytecode 0x1543f51e1735d690>)()
  #f(compiled-function () #<bytecode 0x1506d2dddd95dca5>)()
  handler-bind-1(#f(compiled-function () #<bytecode 0x1506d2dddd95dca5
  ert--run-test-internal(#s(ert--test-execution-info :test #s(ert-test
  ert-run-test(#s(ert-test :name eglot-test-rust-analyzer-hover-after-
  ert-run-or-rerun-test(#s(ert--stats :selector ... :tests ... :test-m
  ert-run-tests((not (or (tag :expensive-test) (tag :unstable) (tag :n
  ert-run-tests-batch((not (or (tag :expensive-test) (tag :unstable) (
  ert-run-tests-batch-and-exit((not (or (tag :expensive-test) (tag :un
  eval((ert-run-tests-batch-and-exit '(not (or (tag :expensive-test) (
  command-line-1(("-L" ":." "-l" "ert" "--eval" "(setq treesit-extra-l
  command-line()
  normal-top-level()
Test eglot-test-rust-analyzer-hover-after-edit condition:
    (error "[eglot] -1: Server died")
   FAILED  28/56  eglot-test-rust-analyzer-hover-after-edit (1.185999 sec) at lisp/progmodes/eglot-tests.el:606
[eglot-tests] [eglot-test-rust-analyzer-watches-files]: test start
    Creating binary (application) package
note: see more `Cargo.toml` keys and their definitions at https://doc.rust-lang.org/cargo/reference/manifest.html
[jsonrpc] Server exited with status 1
[eglot-tests] [eglot-test-rust-analyzer-watches-files]: FAILED
[eglot-tests] contents of ` *EGLOT (watch-project/(rust-ts-mode rust-mode)) output*' #<buffer  *EGLOT (watch-project/(rust-ts-mode rust-mode)) output*>:
[eglot-tests] contents of ` *EGLOT (watch-project/(rust-ts-mode rust-mode)) stderr*' #<buffer  *EGLOT (watch-project/(rust-ts-mode rust-mode)) stderr*>:
error: Unknown binary 'rust-analyzer' in official toolchain 'nightly-x86_64-unknown-linux-gnu'.
[eglot-tests] contents of `*EGLOT (watch-project/(rust-ts-mode rust-mode)) events*' #<buffer *EGLOT (watch-project/(rust-ts-mode rust-mode)) events*>:
[jsonrpc] D[07:25:34.071] Running language server: rust-analyzer
[jsonrpc] e[07:25:34.072] --> initialize[1] {"jsonrpc":"2.0","id":1,"method":"initialize","params":{"processId":1050768,"clientInfo":{"name":"Eglot","version":"1.21"},"rootPath":"/tmp/eglot--fixture-39bVhX/watch-project/","rootUri":"file:///tmp/eglot--fixture-39bVhX/watch-project","initializationOptions":{},"capabilities":{"workspace":{"applyEdit":true,"executeCommand":{"dynamicRegistration":false},"workspaceEdit":{"documentChanges":true,"resourceOperations":["create","delete","rename"],"failureHandling":"abort"},"didChangeWatchedFiles":{"dynamicRegistration":true,"relativePatternSupport":true},"symbol":{"dynamicRegistration":false},"semanticTokens":{"refreshSupport":true},"configuration":true,"workspaceFolders":true},"textDocument":{"synchronization":{"dynamicRegistration":false,"willSave":true,"willSaveWaitUntil":true,"didSave":true},"completion":{"dynamicRegistration":false,"completionItem":{"snippetSupport":false,"deprecatedSupport":true,"resolveSupport":{"properties":["documentation","details","additionalTextEdits"]},"tagSupport":{"valueSet":[1]},"insertReplaceSupport":true},"contextSupport":true},"hover":{"dynamicRegistration":false,"contentFormat":["plaintext"]},"signatureHelp":{"dynamicRegistration":false,"signatureInformation":{"parameterInformation":{"labelOffsetSupport":true},"documentationFormat":["plaintext"],"activeParameterSupport":true}},"references":{"dynamicRegistration":false},"definition":{"dynamicRegistration":false,"linkSupport":true},"declaration":{"dynamicRegistration":false,"linkSupport":true},"implementation":{"dynamicRegistration":false,"linkSupport":true},"typeDefinition":{"dynamicRegistration":false,"linkSupport":true},"documentSymbol":{"dynamicRegistration":false,"hierarchicalDocumentSymbolSupport":true,"symbolKind":{"valueSet":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26]}},"documentHighlight":{"dynamicRegistration":false},"codeAction":{"dynamicRegistration":false,"resolveSupport":{"properties":["edit","command"]},"dataSupport":true,"codeActionLiteralSupport":{"codeActionKind":{"valueSet":["quickfix","refactor","refactor.extract","refactor.inline","refactor.rewrite","source","source.organizeImports"]}},"isPreferredSupport":true},"formatting":{"dynamicRegistration":false},"rangeFormatting":{"dynamicRegistration":false},"rename":{"dynamicRegistration":false,"prepareSupport":true},"semanticTokens":{"dynamicRegistration":false,"requests":{"full":{"delta":true}},"overlappingTokenSupport":true,"multilineTokenSupport":true,"tokenTypes":["namespace","type","class","enum","interface","struct","typeParameter","parameter","variable","property","enumMember","event","function","method","macro","keyword","modifier","comment","string","number","regexp","operator","decorator"],"tokenModifiers":["declaration","definition","readonly","static","deprecated","abstract","async","modification","documentation","defaultLibrary"],"formats":["relative"]},"inlayHint":{"dynamicRegistration":false},"callHierarchy":{"dynamicRegistration":false},"typeHierarchy":{"dynamicRegistration":false},"diagnostic":{"dynamicRegistration":false},"publishDiagnostics":{"relatedInformation":false,"versionSupport":true,"codeDescriptionSupport":false,"tagSupport":{"valueSet":[1,2]}},"$streamingDiagnostics":{"dynamicRegistration":false}},"window":{"showDocument":{"support":true},"showMessage":{"messageActionItem":{"additionalPropertiesSupport":true}},"workDoneProgress":true},"general":{"positionEncodings":["utf-32","utf-8","utf-16"]},"experimental":{}},"workspaceFolders":[{"uri":"file:///tmp/eglot--fixture-39bVhX/watch-project","name":"/tmp/eglot--fixture-39bVhX/watch-project/"}]}}
[stderr]  error: Unknown binary 'rust-analyzer' in official toolchain 'nightly-x86_64-unknown-linux-gnu'.
[jsonrpc] D[07:25:35.162] Connection state change: `exited abnormally with code 1
'

----------b---y---e---b---y---e----------
[eglot-tests] Killing (coiso.rs), wiping /tmp/eglot--fixture-39bVhX
Test eglot-test-rust-analyzer-watches-files backtrace:
  signal(error ("[eglot] -1: Server died"))
  error("[eglot] %s" "-1: Server died")
  eglot--error("-1: Server died")
  eglot--connect((rust-ts-mode rust-mode) (transient . "/tmp/eglot--fi
  apply(eglot--connect ((rust-ts-mode rust-mode) (transient . "/tmp/eg
  eglot--tests-connect()
  apply(eglot--tests-connect nil)
  #f(compiled-function () #<bytecode 0xdb55de5938fdeb8>)()
  eglot--call-with-fixture((("watch-project" ("coiso.rs" . "bla") ("me
  #f(compiled-function () #<bytecode 0x619d4a0f9e96836>)()
  #f(compiled-function () #<bytecode 0x1506d2dddd95dca5>)()
  handler-bind-1(#f(compiled-function () #<bytecode 0x1506d2dddd95dca5
  ert--run-test-internal(#s(ert--test-execution-info :test #s(ert-test
  ert-run-test(#s(ert-test :name eglot-test-rust-analyzer-watches-file
  ert-run-or-rerun-test(#s(ert--stats :selector ... :tests ... :test-m
  ert-run-tests((not (or (tag :expensive-test) (tag :unstable) (tag :n
  ert-run-tests-batch((not (or (tag :expensive-test) (tag :unstable) (
  ert-run-tests-batch-and-exit((not (or (tag :expensive-test) (tag :un
  eval((ert-run-tests-batch-and-exit '(not (or (tag :expensive-test) (
  command-line-1(("-L" ":." "-l" "ert" "--eval" "(setq treesit-extra-l
  command-line()
  normal-top-level()
Test eglot-test-rust-analyzer-watches-files condition:
    (error "[eglot] -1: Server died")
   FAILED  29/56  eglot-test-rust-analyzer-watches-files (1.277218 sec) at lisp/progmodes/eglot-tests.el:402
[eglot-tests] [eglot-test-rust-on-type-formatting]: test start
    Creating binary (application) package
note: see more `Cargo.toml` keys and their definitions at https://doc.rust-lang.org/cargo/reference/manifest.html
[jsonrpc] Server exited with status 1
[eglot-tests] [eglot-test-rust-on-type-formatting]: FAILED
[eglot-tests] contents of ` *EGLOT (on-type-formatting-project/(rust-mode)) output*' #<buffer  *EGLOT (on-type-formatting-project/(rust-mode)) output*>:
[eglot-tests] contents of ` *EGLOT (on-type-formatting-project/(rust-mode)) stderr*' #<buffer  *EGLOT (on-type-formatting-project/(rust-mode)) stderr*>:
error: Unknown binary 'rust-analyzer' in official toolchain 'nightly-x86_64-unknown-linux-gnu'.
[eglot-tests] contents of `*EGLOT (on-type-formatting-project/(rust-mode)) events*' #<buffer *EGLOT (on-type-formatting-project/(rust-mode)) events*>:
[jsonrpc] D[07:25:35.402] Running language server: rust-analyzer
[jsonrpc] e[07:25:35.403] --> initialize[1] {"jsonrpc":"2.0","id":1,"method":"initialize","params":{"processId":1050768,"clientInfo":{"name":"Eglot","version":"1.21"},"rootPath":"/tmp/eglot--fixture-NAp89g/on-type-formatting-project/","rootUri":"file:///tmp/eglot--fixture-NAp89g/on-type-formatting-project","initializationOptions":{},"capabilities":{"workspace":{"applyEdit":true,"executeCommand":{"dynamicRegistration":false},"workspaceEdit":{"documentChanges":true,"resourceOperations":["create","delete","rename"],"failureHandling":"abort"},"didChangeWatchedFiles":{"dynamicRegistration":true,"relativePatternSupport":true},"symbol":{"dynamicRegistration":false},"semanticTokens":{"refreshSupport":true},"configuration":true,"workspaceFolders":true},"textDocument":{"synchronization":{"dynamicRegistration":false,"willSave":true,"willSaveWaitUntil":true,"didSave":true},"completion":{"dynamicRegistration":false,"completionItem":{"snippetSupport":false,"deprecatedSupport":true,"resolveSupport":{"properties":["documentation","details","additionalTextEdits"]},"tagSupport":{"valueSet":[1]},"insertReplaceSupport":true},"contextSupport":true},"hover":{"dynamicRegistration":false,"contentFormat":["plaintext"]},"signatureHelp":{"dynamicRegistration":false,"signatureInformation":{"parameterInformation":{"labelOffsetSupport":true},"documentationFormat":["plaintext"],"activeParameterSupport":true}},"references":{"dynamicRegistration":false},"definition":{"dynamicRegistration":false,"linkSupport":true},"declaration":{"dynamicRegistration":false,"linkSupport":true},"implementation":{"dynamicRegistration":false,"linkSupport":true},"typeDefinition":{"dynamicRegistration":false,"linkSupport":true},"documentSymbol":{"dynamicRegistration":false,"hierarchicalDocumentSymbolSupport":true,"symbolKind":{"valueSet":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26]}},"documentHighlight":{"dynamicRegistration":false},"codeAction":{"dynamicRegistration":false,"resolveSupport":{"properties":["edit","command"]},"dataSupport":true,"codeActionLiteralSupport":{"codeActionKind":{"valueSet":["quickfix","refactor","refactor.extract","refactor.inline","refactor.rewrite","source","source.organizeImports"]}},"isPreferredSupport":true},"formatting":{"dynamicRegistration":false},"rangeFormatting":{"dynamicRegistration":false},"rename":{"dynamicRegistration":false,"prepareSupport":true},"semanticTokens":{"dynamicRegistration":false,"requests":{"full":{"delta":true}},"overlappingTokenSupport":true,"multilineTokenSupport":true,"tokenTypes":["namespace","type","class","enum","interface","struct","typeParameter","parameter","variable","property","enumMember","event","function","method","macro","keyword","modifier","comment","string","number","regexp","operator","decorator"],"tokenModifiers":["declaration","definition","readonly","static","deprecated","abstract","async","modification","documentation","defaultLibrary"],"formats":["relative"]},"inlayHint":{"dynamicRegistration":false},"callHierarchy":{"dynamicRegistration":false},"typeHierarchy":{"dynamicRegistration":false},"diagnostic":{"dynamicRegistration":false},"publishDiagnostics":{"relatedInformation":false,"versionSupport":true,"codeDescriptionSupport":false,"tagSupport":{"valueSet":[1,2]}},"$streamingDiagnostics":{"dynamicRegistration":false}},"window":{"showDocument":{"support":true},"showMessage":{"messageActionItem":{"additionalPropertiesSupport":true}},"workDoneProgress":true},"general":{"positionEncodings":["utf-32","utf-8","utf-16"]},"experimental":{}},"workspaceFolders":[{"uri":"file:///tmp/eglot--fixture-NAp89g/on-type-formatting-project","name":"/tmp/eglot--fixture-NAp89g/on-type-formatting-project/"}]}}
[stderr]  error: Unknown binary 'rust-analyzer' in official toolchain 'nightly-x86_64-unknown-linux-gnu'.
[jsonrpc] D[07:25:36.493] Connection state change: `exited abnormally with code 1
'

----------b---y---e---b---y---e----------
[eglot-tests] Killing (main.rs), wiping /tmp/eglot--fixture-NAp89g
Test eglot-test-rust-on-type-formatting backtrace:
  signal(error ("[eglot] -1: Server died"))
  error("[eglot] %s" "-1: Server died")
  eglot--error("-1: Server died")
  eglot--connect((rust-mode) (transient . "/tmp/eglot--fixture-NAp89g/
  apply(eglot--connect ((rust-mode) (transient . "/tmp/eglot--fixture-
  eglot--tests-connect()
  apply(eglot--tests-connect nil)
  #f(compiled-function () #<bytecode -0xec7a846ae723471>)()
  eglot--call-with-fixture((("on-type-formatting-project" ("main.rs" .
  #f(compiled-function () #<bytecode 0x1543f51e19eef690>)()
  #f(compiled-function () #<bytecode 0x1506d2dddd95dca5>)()
  handler-bind-1(#f(compiled-function () #<bytecode 0x1506d2dddd95dca5
  ert--run-test-internal(#s(ert--test-execution-info :test #s(ert-test
  ert-run-test(#s(ert-test :name eglot-test-rust-on-type-formatting :d
  ert-run-or-rerun-test(#s(ert--stats :selector ... :tests ... :test-m
  ert-run-tests((not (or (tag :expensive-test) (tag :unstable) (tag :n
  ert-run-tests-batch((not (or (tag :expensive-test) (tag :unstable) (
  ert-run-tests-batch-and-exit((not (or (tag :expensive-test) (tag :un
  eval((ert-run-tests-batch-and-exit '(not (or (tag :expensive-test) (
  command-line-1(("-L" ":." "-l" "ert" "--eval" "(setq treesit-extra-l
  command-line()
  normal-top-level()
Test eglot-test-rust-on-type-formatting condition:
    (error "[eglot] -1: Server died")
   FAILED  30/56  eglot-test-rust-on-type-formatting (1.190386 sec) at lisp/progmodes/eglot-tests.el:930
  skipped  31/56  eglot-test-same-server-multi-mode (0.000352 sec)
  skipped  32/56  eglot-test-semtok-basic (0.000267 sec)
  skipped  33/56  eglot-test-semtok-refontify (0.000236 sec)
   passed  34/56  eglot-test-server-programs-class-name-and-contact-spec (0.000685 sec)
   passed  35/56  eglot-test-server-programs-class-name-and-plist (0.000104 sec)
   passed  36/56  eglot-test-server-programs-executable-multiple-major-modes (0.000118 sec)
   passed  37/56  eglot-test-server-programs-executable-with-arg (0.000111 sec)
   passed  38/56  eglot-test-server-programs-executable-with-args-and-autoport (0.000103 sec)
   passed  39/56  eglot-test-server-programs-function (0.000119 sec)
   passed  40/56  eglot-test-server-programs-guess-lang (0.000185 sec)
   passed  41/56  eglot-test-server-programs-host-and-port (0.000100 sec)
   passed  42/56  eglot-test-server-programs-host-and-port-and-tcp-args (0.000101 sec)
   passed  43/56  eglot-test-server-programs-simple-executable (0.000108 sec)
   passed  44/56  eglot-test-server-programs-simple-missing-executable (0.000127 sec)
  skipped  45/56  eglot-test-slow-async-connection (0.000243 sec)
  skipped  46/56  eglot-test-slow-sync-connection-intime (0.000230 sec)
  skipped  47/56  eglot-test-slow-sync-connection-wait (0.000258 sec)
  skipped  48/56  eglot-test-slow-sync-timeout (0.000237 sec)
  skipped  49/56  eglot-test-snippet-completions (0.000234 sec)
  skipped  50/56  eglot-test-snippet-completions-with-company (0.000242 sec)
  skipped  51/56  eglot-test-stop-completion-on-nonprefix (0.000249 sec)
   passed  52/56  eglot-test-strict-interfaces (0.000113 sec)
  skipped  53/56  eglot-test-try-completion-inside-symbol (0.000235 sec)
  skipped  54/56  eglot-test-try-completion-inside-symbol-2 (0.000241 sec)
  skipped  55/56  eglot-test-try-completion-nomatch (0.000236 sec)
  skipped  56/56  eglot-test-zig-insert-replace-completion (0.000143 sec)

Ran 56 tests, 17 results as expected, 4 unexpected, 35 skipped (2026-03-25 07:25:36-0400, 5.515763 sec)

4 unexpected results:
   FAILED  eglot-test-project-wide-diagnostics-rust-analyzer
   FAILED  eglot-test-rust-analyzer-hover-after-edit
   FAILED  eglot-test-rust-analyzer-watches-files
   FAILED  eglot-test-rust-on-type-formatting

35 skipped results:
  SKIPPED  eglot-test-auto-detect-running-server
  SKIPPED  eglot-test-auto-reconnect
  SKIPPED  eglot-test-auto-shutdown
  SKIPPED  eglot-test-basic-completions
  SKIPPED  eglot-test-basic-diagnostics
  SKIPPED  eglot-test-basic-pull-diagnostics
  SKIPPED  eglot-test-basic-stream-diagnostics
  SKIPPED  eglot-test-basic-symlink
  SKIPPED  eglot-test-basic-xref
  SKIPPED  eglot-test-diagnostic-tags-unnecessary-code
  SKIPPED  eglot-test-eclipse-connect
  SKIPPED  eglot-test-eldoc-after-completions
  SKIPPED  eglot-test-ensure
  SKIPPED  eglot-test-formatting
  SKIPPED  eglot-test-json-basic
  SKIPPED  eglot-test-lsp-abiding-column
  SKIPPED  eglot-test-multiline-eldoc
  SKIPPED  eglot-test-non-unique-completions
  SKIPPED  eglot-test-path-to-uri-windows
  SKIPPED  eglot-test-project-wide-diagnostics-typescript
  SKIPPED  eglot-test-rename-a-symbol
  SKIPPED  eglot-test-same-server-multi-mode
  SKIPPED  eglot-test-semtok-basic
  SKIPPED  eglot-test-semtok-refontify
  SKIPPED  eglot-test-slow-async-connection
  SKIPPED  eglot-test-slow-sync-connection-intime
  SKIPPED  eglot-test-slow-sync-connection-wait
  SKIPPED  eglot-test-slow-sync-timeout
  SKIPPED  eglot-test-snippet-completions
  SKIPPED  eglot-test-snippet-completions-with-company
  SKIPPED  eglot-test-stop-completion-on-nonprefix
  SKIPPED  eglot-test-try-completion-inside-symbol
  SKIPPED  eglot-test-try-completion-inside-symbol-2
  SKIPPED  eglot-test-try-completion-nomatch
  SKIPPED  eglot-test-zig-insert-replace-completion

make[2]: *** [Makefile:185: lisp/progmodes/eglot-tests.log] Error 1
  GEN      lisp/progmodes/elisp-mode-tests.log
  GEN      lisp/progmodes/elixir-ts-mode-tests.log
  GEN      lisp/progmodes/etags-tests.log
  GEN      lisp/progmodes/executable-tests.log
  GEN      lisp/progmodes/f90-tests.log
  GEN      lisp/progmodes/flymake-tests.log
  GEN      lisp/progmodes/gdb-mi-tests.log
  GEN      lisp/progmodes/glasses-tests.log
  GEN      lisp/progmodes/go-ts-mode-tests.log
  GEN      lisp/progmodes/grep-tests.log
  GEN      lisp/progmodes/heex-ts-mode-tests.log
  GEN      lisp/progmodes/hideshow-tests.log
  GEN      lisp/progmodes/java-ts-mode-tests.log
  GEN      lisp/progmodes/js-tests.log
  GEN      lisp/progmodes/json-ts-mode-tests.log
  GEN      lisp/progmodes/lua-mode-tests.log
  GEN      lisp/progmodes/lua-ts-mode-tests.log
  GEN      lisp/progmodes/m4-mode-tests.log
  GEN      lisp/progmodes/make-mode-tests.log
  GEN      lisp/progmodes/octave-tests.log
  GEN      lisp/progmodes/opascal-tests.log
  GEN      lisp/progmodes/pascal-tests.log
  GEN      lisp/progmodes/peg-tests.log
  GEN      lisp/progmodes/perl-mode-tests.log
  GEN      lisp/progmodes/project-tests.log
  GEN      lisp/progmodes/ps-mode-tests.log
  GEN      lisp/progmodes/python-tests.log
  GEN      lisp/progmodes/ruby-mode-tests.log
  GEN      lisp/progmodes/ruby-ts-mode-tests.log
  GEN      lisp/progmodes/rust-ts-mode-tests.log
  GEN      lisp/progmodes/scheme-tests.log
  GEN      lisp/progmodes/sh-script-tests.log
  GEN      lisp/progmodes/sql-tests.log
  GEN      lisp/progmodes/subword-tests.log
  GEN      lisp/progmodes/tcl-tests.log
  GEN      lisp/progmodes/typescript-ts-mode-tests.log
  GEN      lisp/progmodes/which-func-tests.log
  GEN      lisp/progmodes/xref-tests.log
  GEN      lisp/ps-print-tests.log
  GEN      lisp/register-tests.log
  GEN      lisp/repeat-tests.log
  GEN      lisp/replace-tests.log
  GEN      lisp/rot13-tests.log
  GEN      lisp/savehist-tests.log
  GEN      lisp/saveplace-tests.log
  GEN      lisp/scroll-lock-tests.log
  GEN      lisp/server-tests.log
  GEN      lisp/ses-tests.log
  GEN      lisp/shadowfile-tests.log
  GEN      lisp/shell-tests.log
  GEN      lisp/simple-tests.log
  GEN      lisp/so-long-tests/autoload-longlines-mode-tests.log
  GEN      lisp/so-long-tests/autoload-major-mode-tests.log
  GEN      lisp/so-long-tests/autoload-minor-mode-tests.log
  GEN      lisp/so-long-tests/so-long-tests-helpers.log
  GEN      lisp/so-long-tests/so-long-tests.log
  GEN      lisp/so-long-tests/spelling-tests.log
  GEN      lisp/sort-tests.log
  GEN      lisp/soundex-tests.log
  GEN      lisp/speedbar-tests.log
  GEN      lisp/sqlite-tests.log
  GEN      lisp/startup-tests.log
  GEN      lisp/subr-tests.log
  GEN      lisp/tab-bar-tests.log
  GEN      lisp/tabify-tests.log
  GEN      lisp/tar-mode-tests.log
  GEN      lisp/tempo-tests.log
  GEN      lisp/term-tests.log
  GEN      lisp/term/tty-colors-tests.log
  GEN      lisp/textmodes/bibtex-tests.log
  GEN      lisp/textmodes/conf-mode-tests.log
  GEN      lisp/textmodes/css-mode-tests.log
  GEN      lisp/textmodes/dns-mode-tests.log
  GEN      lisp/textmodes/emacs-news-mode-tests.log
  GEN      lisp/textmodes/fill-tests.log
  GEN      lisp/textmodes/ispell-tests/ispell-aspell-tests.log
  GEN      lisp/textmodes/ispell-tests/ispell-hunspell-tests.log
  GEN      lisp/textmodes/ispell-tests/ispell-international-ispell-tests.log
  GEN      lisp/textmodes/ispell-tests/ispell-tests-common.log
  GEN      lisp/textmodes/ispell-tests/ispell-tests.log
  GEN      lisp/textmodes/mhtml-mode-tests.log
  GEN      lisp/textmodes/page-tests.log
  GEN      lisp/textmodes/paragraphs-tests.log
  GEN      lisp/textmodes/po-tests.log
  GEN      lisp/textmodes/reftex-tests.log
  GEN      lisp/textmodes/sgml-mode-tests.log
  GEN      lisp/textmodes/texinfo-tests.log
  GEN      lisp/textmodes/tildify-tests.log
  GEN      lisp/textmodes/underline-tests.log
  GEN      lisp/thingatpt-tests.log
  GEN      lisp/thread-tests.log
  GEN      lisp/time-stamp-tests.log
  GEN      lisp/time-tests.log
  GEN      lisp/timezone-tests.log
  GEN      lisp/uniquify-tests.log
  GEN      lisp/url/url-auth-tests.log
  GEN      lisp/url/url-domsuf-tests.log
  GEN      lisp/url/url-expand-tests.log
```
