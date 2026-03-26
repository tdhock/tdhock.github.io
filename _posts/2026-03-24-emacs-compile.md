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

The example described below is from [this project](https://github.com/tdhock/2026-01-aa-grande-echelle/tree/main/demos/pybind11-numpy-interface).
Then I put the following in [`pypkg/src/.dir-locals.el`](https://github.com/tdhock/2026-01-aa-grande-echelle/blob/main/demos/pybind11-numpy-interface/interface-proj/src/.dir-locals.el) to compile a Python package with pybind11 binding to C++ code:

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

# Installing emacs devel from source

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

# Test run before modification

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

# Modifying the code

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

This seems like a test expected value that is ok to change (no change in parse, just a change of which pattern matched), which I did on local branch `tdh`.

# Faster testing

In previous sections we did a full re-compile and test suite run, which can slow down interactive experimentation.
Here are two faster alternatives.

## keep dev emacs open

First option would be to start `src/emacs`, open `test/lisp/progmodes/compile.el`, `M-x eval-buffer`, `M-x ert`.
After changing `lisp/progmodes/compile.el`, `M-x eval-buffer`, `M-x ert`.

## run emacs tests in batch mode

Another option is to run emacs as below

```
(base) hoct2726@dinf-thock-02i:~/emacs[master*]$ rm -f lisp/progmodes/compile.elc && src/emacs -batch -Q -l test/lisp/progmodes/compile-tests.el -l ert -f ert-run-tests-batch-and-exit
Running 3 tests (2026-03-25 21:43:16-0400, selector ‘t’)
   passed  1/3  compile-test-error-regexps (0.125380 sec)
   passed  2/3  compile-test-functions (0.000250 sec)
   passed  3/3  compile-test-grep-regexps (0.003032 sec)

Ran 3 tests, 3 results as expected, 0 unexpected (2026-03-25 21:43:16-0400, 0.128988 sec)
```

After changing `lisp/progmodes/compile.el`, we run the same command again to test.

```
(base) hoct2726@dinf-thock-02i:~/emacs[master*]$ rm -f lisp/progmodes/compile.elc && src/emacs -batch -Q -l test/lisp/progmodes/compile-tests.el -l ert -f ert-run-tests-batch-and-exit
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

I like this solution (I run it from `*shell*` in my release version of emacs).

# Another possible solution?

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

Move down too, so cucumber matches first? Yes, but another failure.

```
    testcase: (gnu "      alpha.c:5:15: error: expected ';' after expression" 1 15 5 "alpha.c")
    (ert-test-failed
     ((should (equal (compilation--loc->col loc) col)) :form
      (equal nil 15) :value nil :explanation (different-types nil 15)))
```

The output above indicates that the column 15 was not parsed (because it is not present in cucumber regexp, which took priority).
This is strange. This test case has leading spaces, and is supposed to match gnu pattern!!
Then why doesn’t my subject match to the gnu pattern?
Because the subject needs six spaces (two is not enough in pip).

![six spaces](/assets/img/2026-03-24-emacs-compile/six-spaces.png)

What part of the gnu pattern matches six spaces?
Below `regexp-builder` says that it does not match.
Then why does it get highlighted in the `compilation-mode` buffer, and why does the test pass?

![regexp builder](/assets/img/2026-03-24-emacs-compile/regexp-builder.png)

Not clear. The code which runs this test is

```elisp
      ;; Test all built-in rules except `omake' to avoid interference.
      (let ((compilation-error-regexp-alist (remq 'omake all-rules)))
        (mapc #'compile--test-error-line compile-tests--test-regexps-data))

      ;; Test the `omake' rule separately.
      ;; This doesn't actually test the `omake' rule itself but its
      ;; indirect effects.
      (let ((compilation-error-regexp-alist all-rules)
            (test
             '(gnu "      alpha.c:5:15: error: expected ';' after expression"
                   1 15 5 "alpha.c")))
        (compile--test-error-line test))
```

What is the `omake` rule?

```elisp
    (omake
     ;; "omake -P" reports "file foo changed"
     ;; (useful if you do "cvs up" and want to see what has changed)
     "^\\*\\*\\* omake: file \\(.*\\) changed" 1 nil nil nil nil
     ;; FIXME-omake: This tries to prevent reusing pre-existing markers
     ;; for subsequent messages, since those messages's line numbers
     ;; are about another version of the file.
     (0 (progn (compilation--flush-file-structure (match-string 1))
               nil)))
```

Above did not help. Below comments do.

```elisp
(defcustom compilation-error-regexp-alist
  ;; Omit `omake' by default: its mere presence here triggers special processing
  ;; and modifies regexps for other rules (see `compilation-parse-errors'),
  ;; which may slow down matching (or even cause mismatches).
```

There I see

```elisp
(defun compilation-parse-errors (start end &rest rules)
  "Parse errors between START and END.
The errors recognized are the ones specified in RULES which default
to `compilation-error-regexp-alist' if RULES is nil."
…
        ;; omake reports some error indented, so skip the indentation.
        ;; another solution is to modify (some?) regexps in
        ;; `compilation-error-regexp-alist'.
        ;; note that omake usage is not limited to ocaml and C (for stubs).
        ;; FIXME-omake: Doing it here seems wrong, at least it should depend on
        ;; whether or not omake's own error messages are recognized.
        (cond
         ((or (not omake-included) (not pat))
          nil)
         ((string-match "\\`\\([^^]\\|\\^\\( \\*\\|\\[\\)\\)" pat)
          nil) ;; Not anchored or anchored but already allows empty spaces.
         (t (setq pat (concat "^\\(?:      \\)?" (substring pat 1)))))
```

The last line says that after `substring` removes the leading `^` (caret which is regex meaning anchor to start of line), an optional 6 spaces is added to the start of the pattern. Why six?
Moving cucumber before gnu does not seem to be the right solution.
Instead, let’s try changing this line with 6 spaces to:

```elisp
         (t (setq pat (concat "^ *" (substring pat 1)))))
```

With the change above, the tests pass.

Now I add a new test for my case:

```elisp
(gnu "  src/add.cpp:8:31: error: invalid operands of types ‘const double’ and ‘const double*’ to binary ‘operator+’" 1 31 8 "src/add.cpp" error)
```

Putting this in `compile-tests--test-regexps-data` results in failure:

```
Test compile-test-error-regexps condition:
    testcase: (gnu "  src/add.cpp:8:31: error: invalid operands of types ‘const double’ and ‘const double*’ to binary ‘operator+’" 1 31 8 "src/add.cpp" error)
    (ert-test-failed ((should msg) :form msg :value nil))
   FAILED  1/3  compile-test-error-regexps (0.072361 sec) at test/lisp/progmodes/compile-tests.el:537
```

This is because the leading spaces are only added when `omake` is present in rules, and this test is run without.
The leading spaces are only tested in the code below (previous):

```elisp
      (let ((compilation-error-regexp-alist all-rules)
            (test
             '(gnu "      alpha.c:5:15: error: expected ';' after expression"
                   1 15 5 "alpha.c")))
        (compile--test-error-line test)
```

I propose simplifying this block to

```elisp
      (let ((compilation-error-regexp-alist all-rules))
        (mapc #'compile--test-error-line compile-tests--test-regexps-data-omake))
```

where `compile-tests--test-regexps-data-omake` is a list of test cases,

```elisp
(defconst compile-tests--test-regexps-data-omake
  '((gnu "  src/add.cpp:8:31: error: invalid operands of types ‘const double’ and ‘const double*’ to binary ‘operator+’" 1 31 8 "src/add.cpp" error);; two leading spaces output when running g++ to compile a python extension module using pip install -v
    (gnu "      alpha.c:5:15: error: expected ';' after expression"
         1 15 5 "alpha.c"))
  "Like `compile-tests--test-regexps-data' but tested with omake in rules,
which is emacs default, so more realistic tests, but slower.
These test cases are errors with leading spaces,
which do not match the regexps defined in
`compilation-error-regexp-alist'.
With omake in rules, those regexps are modified in
`compilation-parse-errors', including allowing matching of
errors with leading spaces.")
```

Re-running tests now gives the error below,

```
Test compile-test-error-regexps condition:
    (ert-test-failed
     ((should (eq compilation-num-errors-found 110)) :form (eq 111 110)
      :value nil))
   FAILED  1/3  compile-test-error-regexps (0.124068 sec) at test/lisp/progmodes/compile-tests.el:544
```

This means the number of parsed errors is one more than expected, because I added one test case.
The solution is to update the expected number,

```elisp
      (should (eq compilation-num-errors-found 111))
```

Re-running compilation tests ok. All tests show same output as before modification:

```
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

# Committing and submitting

[Sending Patches for GNU Emacs](https://www.gnu.org/software/emacs/manual/html_node/emacs/Sending-Patches.html) explains the steps for sending a patch.

* For the details about our style and requirements for good commit log messages, please see the “Commit messages” section of the file CONTRIBUTE in the Emacs source tree. Please also look at the commit log entries of recent commits to see what sorts of information to put in, and to learn the style that we use.
  * Lines in ChangeLog entries should preferably be not longer than 63
  characters, and must not exceed 78 characters, unless they consist
  of a single word of at most 140 characters; this 78/140 limit is
  enforced by a commit hook.  (The 63-character preference is to
  avoid too-long lines in the ChangeLog file generated from Git logs,
  where each entry line is indented by a TAB.)
* If you are using the Emacs repository, make sure your copy is up-to-date (e.g., with `git pull`). You can commit your changes to a private branch and generate a patch from the master version by using `git format-patch master`.

Based on the advice above, I wrote the commit message below.

```
Allow two spaces before errors in compilation-mode

* lisp/progmodes/compile.el (compilation-parse-errors):
Change optional leading spaces from six to any number.
* test/lisp/progmodes/compile-tests.el
(compile-test-error-regexps): New test case with
two leading spaces for gnu regexp.
(compile-tests--test-regexps-data-omake): New constant.
```

Before making the patch, a pull is advised.

```
(base) hoct2726@dinf-thock-02i:~/emacs[master]$ git pull
Updating 7b8a38e0538..f2b9b827c97
Fast-forward
 lib-src/seccomp-filter.c    |   5 ++
 lisp/dired.el               |  27 ++++++-----
 lisp/info.el                |  11 +++--
 lisp/language/korea-util.el |  13 +++++-
 lisp/menu-bar.el            |   6 +--
 lisp/minibuffer.el          |   4 +-
 lisp/progmodes/compile.el   |   1 +
 src/bidi.c                  |  10 ++++
 test/lisp/dired-tests.el    |  40 ++++++++++++++++
 test/lisp/ses-tests.el      | 109 ++++++++++++++++++++++++++++++--------------
 10 files changed, 168 insertions(+), 58 deletions(-)
```

Above I see somebody modified `compile.el` (the same file I am hacking).
The git log says:

```
commit 0048dd0da0fdce9a2687e19bfef0c0299051a067
Author: Basil L. Contovounesios <basil@contovou.net>
Date:   Wed Mar 25 16:06:16 2026 +0100

    Give compile-command a :group again
    
    Like the commit of 2022-07-31
    "Fix further package.el loaddefs byte-compile warnings"
    this pacifies the warning that compile-command fails to specify
    a containing group when byte-compiling loaddefs.el (bug#80648).
    
    * lisp/progmodes/compile.el (compile-command): Restore explicit
    custom :group on autoloaded user option.
```

Seems like the change above would not affect my patch.
And re-running tests using the new `compile.el` works fine.
Next we make a patch:

```
(base) hoct2726@dinf-thock-02i:~/emacs[leading-spaces]$ git format-patch master
0001-Allow-two-spaces-before-errors-in-compilation-mode.patch

(base) hoct2726@dinf-thock-02i:~/emacs[leading-spaces]$ cat 0001-Allow-two-spaces-before-errors-in-compilation-mode.patch 
From 90cf5ad4ca0016b1a7192ce7baf693e6f6680f0e Mon Sep 17 00:00:00 2001
From: Toby Dylan Hocking <toby.hocking@r-project.org>
Date: Wed, 25 Mar 2026 23:14:03 -0400
Subject: [PATCH] Allow two spaces before errors in compilation-mode

* lisp/progmodes/compile.el (compilation-parse-errors):
Change optional leading spaces from six to any number.
* test/lisp/progmodes/compile-tests.el
(compile-test-error-regexps): New test case with
two leading spaces for gnu regexp.
(compile-tests--test-regexps-data-omake): New constant.
---
 lisp/progmodes/compile.el            |  2 +-
 test/lisp/progmodes/compile-tests.el | 25 ++++++++++++++++++-------
 2 files changed, 19 insertions(+), 8 deletions(-)

diff --git a/lisp/progmodes/compile.el b/lisp/progmodes/compile.el
index c0a734ae818..a344c279571 100644
--- a/lisp/progmodes/compile.el
+++ b/lisp/progmodes/compile.el
@@ -1714,7 +1714,7 @@ compilation-parse-errors
           nil)
          ((string-match "\\`\\([^^]\\|\\^\\( \\*\\|\\[\\)\\)" pat)
           nil) ;; Not anchored or anchored but already allows empty spaces.
-         (t (setq pat (concat "^\\(?:      \\)?" (substring pat 1)))))
+         (t (setq pat (concat "^ *" (substring pat 1)))))
 
         (if (and (consp file) (not (functionp file)))
             (setq fmt (cdr file)
diff --git a/test/lisp/progmodes/compile-tests.el b/test/lisp/progmodes/compile-tests.el
index 67a713857e3..e3c79803ca0 100644
--- a/test/lisp/progmodes/compile-tests.el
+++ b/test/lisp/progmodes/compile-tests.el
@@ -464,6 +464,19 @@ compile-tests--test-regexps-data
 END-LINE, if that matched.  TYPE can be left out, in which case
 any message type is accepted.")
 
+(defconst compile-tests--test-regexps-data-omake
+  '((gnu "  src/add.cpp:8:31: error: invalid operands of types ‘const double’ and ‘const double*’ to binary ‘operator+’" 1 31 8 "src/add.cpp" error);; two leading spaces output when running g++ to compile a python extension module using pip install -v
+    (gnu "      alpha.c:5:15: error: expected ';' after expression"
+         1 15 5 "alpha.c"))
+  "Like `compile-tests--test-regexps-data' but tested with omake in rules,
+which is emacs default, so more realistic tests, but slower.
+These test cases are errors with leading spaces,
+which do not match the regexps defined in
+`compilation-error-regexp-alist'.
+With omake in rules, those regexps are modified in
+`compilation-parse-errors', including allowing matching of
+errors with leading spaces.")
+
 (defconst compile-tests--grep-regexp-testcases
   ;; Bug#32051.
   '((nil
@@ -549,14 +562,12 @@ compile-test-error-regexps
 
       ;; Test the `omake' rule separately.
       ;; This doesn't actually test the `omake' rule itself but its
-      ;; indirect effects.
-      (let ((compilation-error-regexp-alist all-rules)
-            (test
-             '(gnu "      alpha.c:5:15: error: expected ';' after expression"
-                   1 15 5 "alpha.c")))
-        (compile--test-error-line test))
+      ;; indirect effects, including adding optional match of leading
+      ;; spaces to the regexp.
+      (let ((compilation-error-regexp-alist all-rules))
+        (mapc #'compile--test-error-line compile-tests--test-regexps-data-omake))
 
-      (should (eq compilation-num-errors-found 110))
+      (should (eq compilation-num-errors-found 111))
       (should (eq compilation-num-warnings-found 37))
       (should (eq compilation-num-infos-found 36)))))
 
-- 
2.43.0
```

It seems this test was not good enough.
I got confused:

* `omake` is indeed part of `compilation-error-regexp-alist` in my release emacs (29.3).
* but `omake` is absent from that list in my dev emacs:

```
(absoft ada aix ant bash borland python-tracebacks-and-caml cmake
	cmake-info comma msft edg-1 edg-2 epc ftnchek gradle-kotlin
	gradle-kotlin-legacy gradle-android iar ibm irix java javac
	jikes-file maven jikes-line clang-include gcc-include
	ruby-Test::Unit rust-panic lua lua-stack gmake gnu cucumber
	lcc makepp mips-1 mips-2 oracle perl php rust rxp shellcheck
	sparc-pascal-file sparc-pascal-line sparc-pascal-example sun
	sun-ada watcom 4bsd gcov-file gcov-header gcov-nomark
	gcov-called-line gcov-never-called perl--Pod::Checker
	perl--Test perl--Test2 perl--Test::Harness weblint guile-file
	guile-line typescript-tsc-plain typescript-tsc-pretty)
```

Where is this defined?

![omake new](/assets/img/2026-03-24-emacs-compile/omake-new.png)

So in fact the extra leading spaces regex is not added.
And the two leading spaces still does not match.

# Back to the drawing board

Since the previous solution did not work (and test changes may be too complex for maintainers to accept),
let’s go back to trying an optional vertical bar with modified test.

Back to master, and tests pass.

```
(base) hoct2726@dinf-thock-02i:~/emacs[master]$ rm -f lisp/progmodes/compile.elc && src/emacs -batch -Q -l test/lisp/progmodes/compile-tests.el -l ert -f ert-run-tests-batch-and-exit
Running 3 tests (2026-03-26 00:07:52-0400, selector ‘t’)
   passed  1/3  compile-test-error-regexps (0.125272 sec)
   passed  2/3  compile-test-functions (0.000262 sec)
   passed  3/3  compile-test-grep-regexps (0.003000 sec)

Ran 3 tests, 3 results as expected, 0 unexpected (2026-03-26 00:07:52-0400, 0.128853 sec)
```

Make vertical bar optional, and tests fail.

```
(base) hoct2726@dinf-thock-02i:~/emacs[leading-spaces]$ rm -f lisp/progmodes/compile.elc && src/emacs -batch -Q -l test/lisp/progmodes/compile-tests.el -l ert -f ert-run-tests-batch-and-exit
Running 3 tests (2026-03-26 00:08:43-0400, selector ‘t’)
…
Test compile-test-error-regexps condition:
    testcase: (cucumber "      /home/gusev/.rvm/foo/bar.rb:500:in `_wrap_assertion'" 1 nil 500 "/home/gusev/.rvm/foo/bar.rb" error)
    (ert-test-failed
     ((should (equal rule (compilation--message->rule msg))) :form
      (equal cucumber gnu) :value nil :explanation
      (different-atoms cucumber gnu)))
   FAILED  1/3  compile-test-error-regexps (0.019534 sec) at test/lisp/progmodes/compile-tests.el:536
   passed  2/3  compile-test-functions (0.000833 sec)
   passed  3/3  compile-test-grep-regexps (0.003385 sec)

Ran 3 tests, 2 results as expected, 1 unexpected (2026-03-26 00:08:43-0400, 0.213527 sec)

1 unexpected results:
   FAILED  compile-test-error-regexps
```

Change cucumber to gnu, and tests pass.

```
(base) hoct2726@dinf-thock-02i:~/emacs[leading-spaces*]$ rm -f lisp/progmodes/compile.elc && src/emacs -batch -Q -l test/lisp/progmodes/compile-tests.el -l ert -f ert-run-tests-batch-and-exit
Running 3 tests (2026-03-26 00:09:21-0400, selector ‘t’)
   passed  1/3  compile-test-error-regexps (0.126230 sec)
   passed  2/3  compile-test-functions (0.000253 sec)
   passed  3/3  compile-test-grep-regexps (0.003022 sec)

Ran 3 tests, 3 results as expected, 0 unexpected (2026-03-26 00:09:21-0400, 0.129811 sec)
```

![all hilite](/assets/img/2026-03-24-emacs-compile/all-hilite.png)

Added a new test case, increased number of expected errors, tests pass.
New commit message:

```
Make | optional for gnu regexp in compilation-mode

* lisp/progmodes/compile.el
(compilation-error-regexp-alist-alist):
Make leading | optional with leading spaces.
* etc/compilation.txt
(gnu): added new error with two leading spaces.
* test/lisp/progmodes/compile-tests.el
(compile-test-error-regexps):
One new error found.
(compile-tests--test-regexps-data):
One new error test case for gnu with two leading spaces,
one expected match by cucumber changed to gnu.
```

New patch:

```
(base) hoct2726@dinf-thock-02i:~/emacs[leading-spaces]$ git format-patch master
0001-Make-optional-for-gnu-regexp-in-compilation-mode.patch
(base) hoct2726@dinf-thock-02i:~/emacs[leading-spaces]$ cat 0001-Make-optional-for-gnu-regexp-in-compilation-mode.patch
From 8fea3ecb1a1bd943c1d0b7658e10d0a0861cdcd6 Mon Sep 17 00:00:00 2001
From: Toby Dylan Hocking <toby.hocking@r-project.org>
Date: Thu, 26 Mar 2026 08:51:27 -0400
Subject: [PATCH] Make | optional for gnu regexp in compilation-mode

* lisp/progmodes/compile.el
(compilation-error-regexp-alist-alist):
Make leading | optional with leading spaces.
* etc/compilation.txt
(gnu): added new error with two leading spaces.
* test/lisp/progmodes/compile-tests.el
(compile-test-error-regexps):
One new error found.
(compile-tests--test-regexps-data):
One new error test case for gnu with two leading spaces,
one expected match by cucumber changed to gnu.
---
 etc/compilation.txt                  | 1 +
 lisp/progmodes/compile.el            | 5 +++--
 test/lisp/progmodes/compile-tests.el | 7 +++++--
 3 files changed, 9 insertions(+), 4 deletions(-)

diff --git a/etc/compilation.txt b/etc/compilation.txt
index 801d262f5aa..b97ba12fb9a 100644
--- a/etc/compilation.txt
+++ b/etc/compilation.txt
@@ -331,6 +331,7 @@ boost/container/detail/flat_tree.hpp:589:25:   [ skipping 5 instantiation contex
    |
    |board.h:60:21:
    |   60 | #define I(b, C) ((C).y * (b)->width + (C).x)
+  src/add.cpp:8:31: error: invalid operands of types ‘const double’ and ‘const double*’ to binary ‘operator+’
 
 
 * Guile backtrace, 2.0.11
diff --git a/lisp/progmodes/compile.el b/lisp/progmodes/compile.el
index c0a734ae818..c95497377f3 100644
--- a/lisp/progmodes/compile.el
+++ b/lisp/progmodes/compile.el
@@ -460,8 +460,9 @@ compilation-error-regexp-alist-alist
        ;; non-interactive programs other than compilers (e.g. the
        ;; "jade:" entry in compilation.txt).
        (? (| (: alpha (+ (in ?. ?- alnum)) ":" (? " "))
-             ;; Skip indentation generated by GCC's -fanalyzer.
-             (: (+ " ") "|")))
+             ;; Skip indentation generated by GCC's -fanalyzer (with |),
+             ;; or two spaces from pip install (without |).
+             (: (+ " ") (? "|"))))
 
        ;; File name group.
        (group-n 1
diff --git a/test/lisp/progmodes/compile-tests.el b/test/lisp/progmodes/compile-tests.el
index 67a713857e3..caf386b4950 100644
--- a/test/lisp/progmodes/compile-tests.el
+++ b/test/lisp/progmodes/compile-tests.el
@@ -121,7 +121,8 @@ compile-tests--test-regexps-data
     ;; cucumber
     (cucumber "Scenario: undefined step  # features/cucumber.feature:3"
      29 nil 3 "features/cucumber.feature" error)
-    (cucumber "      /home/gusev/.rvm/foo/bar.rb:500:in `_wrap_assertion'"
+    ;; Below is from cucumber but gnu regexp is consistent and matches first.
+    (gnu "      /home/gusev/.rvm/foo/bar.rb:500:in `_wrap_assertion'"
      1 nil 500 "/home/gusev/.rvm/foo/bar.rb" error)
     ;; edg-1 edg-2
     (edg-1 "build/intel/debug/../../../struct.cpp(42): error: identifier \"foo\" is undefined"
@@ -271,6 +272,8 @@ compile-tests--test-regexps-data
      1 nil 27041 "{standard input}" warning)
     (gnu "boost/container/detail/flat_tree.hpp:589:25:   [ skipping 5 instantiation contexts, use -ftemplate-backtrace-limit=0 to disable ]"
      1 25 589 "boost/container/detail/flat_tree.hpp" info)
+    ;; Below from pip install, running g++ to compile python extension module.
+    (gnu "  src/add.cpp:8:31: error: invalid operands of types ‘const double’ and ‘const double*’ to binary ‘operator+’" 1 31 8 "src/add.cpp" error)
     ;; Gradle/Kotlin
     (gradle-kotlin
      "e: file:///src/Test.kt:267:5 foo: bar" 4 5 267 "/src/Test.kt" error)
@@ -556,7 +559,7 @@ compile-test-error-regexps
                    1 15 5 "alpha.c")))
         (compile--test-error-line test))
 
-      (should (eq compilation-num-errors-found 110))
+      (should (eq compilation-num-errors-found 111))
       (should (eq compilation-num-warnings-found 37))
       (should (eq compilation-num-infos-found 36)))))
 
-- 
2.43.0
```

# Submit patch

Finally I run `M-x submit-emacs-patch` from within `src/emacs` (so the dev version appears in the email).

```text
To: bug-gnu-emacs@gnu.org
Subject: [PATCH] Make | optional for gnu regexp in compilation-mode
From: Toby Dylan Hocking <hoct2726@dinf-thock-02i.mail-host-address-is-not-set>
X-Debbugs-Cc: Chong Yidong <cyd@stupidchicken.com>

Hi! First of all, thank you very much for maintaining emacs!
I have been using emacs for 20+ years, but this is my first patch.

This is a minor new feature (or bug fix?) for compilation-mode.
I run pip install -v to compile python extension modules,
which include C++ code compiled by g++ on Ubuntu.
I expect compilation-mode should highlight errors from g++,
but it does not, because pip adds two spaces in front:

  src/add.cpp:8:31: error: invalid operands of types ‘const double’ and ‘const double*’ to binary ‘operator+’

I tried the same on windows (pip uses visual studio instead of gcc),
and I observed that compilation-mode correctly highlights this:

  src/add.cpp(8): error C2111: '+': pointer addition requires integral operand

To double check this issue exists on your emacs,
try M-x compilation-mode in this buffer.

After some investigation, I found that the issue must be in
file lisp/progmodes/compile.el, compilation-error-regexp-alist-alist,
regexp gnu (used for parsing errors from g++).
To fix this, I modified this regexp to allow spaces before the file.
This regexp already allows leading spaces,
but only if there is a vertical bar just before the file.
I propose to fix this by making this vertical bar optional.
The attached patch also includes a new test case,
and a modification of an existing test case for the cucumber regexp,
which now gets matched by the gnu regexp
(but with no change to the resulting parse data).

In emacs from git, these changes do not introduce any new errors from
make check, on my Ubuntu system. I read
https://www.gnu.org/software/emacs/manual/html_node/emacs/Sending-Patches.html
and CONTRIBUTE, and consulted recent commit messages,
to try to create a patch that would be easy to review.
Thanks for your consideration and time!

Toby Hocking
Professor
Department d’Informatique
Université de Sherbrooke

PS for even more details (tl;dr) and screenshots see:
https://tdhock.github.io/blog/2026/emacs-compile/

In GNU Emacs 31.0.50 (build 1, x86_64-pc-linux-gnu, X toolkit, cairo
 version 1.18.0, Xaw scroll bars) of 2026-03-25 built on dinf-thock-02i
Repository revision: f2b9b827c977dee0031e44901cbf3e1111e1cc09
Repository branch: master
Windowing system distributor 'The X.Org Foundation', version 11.0.12101011
System Description: Ubuntu 24.04.4 LTS

Configured using:
 'configure --with-gif=ifavailable --with-gnutls=ifavailable'
```

Before sending that, do I need to [configure sending mail from emacs](https://thedroidguy.com/how-to-use-email-within-emacs-step-by-step-guide-for-beginners-1263534)?
Using [my university instructions](https://www.usherbrooke.ca/services-informatiques/repertoire/collaboration/courriel/configuration#acc-4289-1348), there is a MS server, which [seems complicated](https://emacs.stackexchange.com/questions/61060/how-to-make-email-in-emacs-work-with-an-oauth2-requirement) to setup with emacs.
Instead I will try to do web mail.
