---
layout: post
title: Re-building vignettes on windows
description: Fixing mysterious error
---

## Fixing the error

CRAN says I need to update my R package nc, for named capture regular
expressions, because of the following error,

```
Check: re-building of vignette outputs
Result: ERROR
    Error(s) in re-building vignettes:
    --- re-building 'v1-capture-first.Rmd' using knitr
    Warning in file(con, "r") :
     cannot open file 'cript src="https://cdn.jsdelivr.net/npm/prismjs@1.29.0/components/prism-core.min.js" defer></script>
    <cript src="https://cdn.jsdelivr.net/npm/prismjs@1.29.0/components/prism-core.min.js" defer></script>
    <': No such file or directory
    Error: processing vignette 'v1-capture-first.Rmd' failed with diagnostics:
    cannot open the connection
    --- failed re-building 'v1-capture-first.Rmd'
```

I can reproduce this on my local windows machine, below,

```
th798@cmp2986 MINGW64 ~/R
$ R CMD build nc
* checking for file 'nc/DESCRIPTION' ... OK
* preparing 'nc':
* checking DESCRIPTION meta-information ... OK
* installing the package to build vignettes
* creating vignettes ... ERROR
--- re-building 'v0-overview.Rmd' using knitr
--- finished re-building 'v0-overview.Rmd'

--- re-building 'v1-capture-first.Rmd' using knitr
Warning in file(con, "r") :
  cannot open file 'cript src="https://cdn.jsdelivr.net/npm/prismjs@1.29.0/components/prism-core.min.js" defer></script>
<cript src="https://cdn.jsdelivr.net/npm/prismjs@1.29.0/components/prism-core.min.js" defer></script>
<': Invalid argument
	Error: processing vignette 'v1-capture-first.Rmd' failed with diagnostics:
cannot open the connection
--- failed re-building 'v1-capture-first.Rmd'
```

Does it still happen if there are other vignettes? Deleted others, yes.

Delete most content in v1-capture-first.Rmd, then I get

```
* creating vignettes ... OK
Warning: 'inst/doc' files
    'v1-capture-first.Rmd', 'v1-capture-first.html',  'v1-capture-first.R'
  ignored as vignettes have been rebuilt.
  Run R CMD build with --no-build-vignettes to prevent rebuilding.
```

The issue is with the following code,

```r
nc::capture_first_vec(u.subject, u.pattern)
nc::capture_first_vec(u.subject, u.pattern, engine="PCRE") 
nc::capture_first_vec(u.subject, u.pattern, engine="RE2")
```

Commenting the three lines above makes the error go away.

[Minimal Reproducible
Example](https://stackoverflow.com/help/minimal-reproducible-example):
`buggy.Rmd` has `{r}` code chunk with `"a\U0001F60E#"`, and `ok.Rmd`
has `#"a\U0001F60E#"`.

```r
> tools::vignetteEngine("knitr::knitr")$weave("~/Downloads/buggy.Rmd")


processing file: ~/Downloads/buggy.Rmd
                                                                                                            
output file: buggy.md

Error in file(con, "r") : cannot open the connection
In addition: Warning message:
In file(con, "r") :
  cannot open file 'script src="https://cdn.jsdelivr.net/npm/prismjs@1.29.0/components/prism-core.min.js" defer></script>
script src="https://cdn.jsdelivr.net/npm/prismjs@1.29.0/components/prism-core.min.js" defer></script>
': Invalid argument
> tools::vignetteEngine("knitr::knitr")$weave("~/Downloads/ok.Rmd")


processing file: ~/Downloads/ok.Rmd
                                                                                                            
output file: ok.md

> tools::vignetteEngine("knitr::rmarkdown")$weave("~/Downloads/buggy.Rmd")


processing file: buggy.Rmd
                                                                                                            
output file: buggy.knit.md

"C:/PROGRA~1/Pandoc/pandoc" +RTS -K512m -RTS buggy.knit.md --to html4 --from markdown+autolink_bare_uris+tex_math_single_backslash --output pandoc41b83ccf5ed.html --lua-filter "C:\Users\th798\AppData\Local\R\win-library\4.3\rmarkdown\rmarkdown\lua\pagebreak.lua" --lua-filter "C:\Users\th798\AppData\Local\R\win-library\4.3\rmarkdown\rmarkdown\lua\latex-div.lua" --self-contained --variable bs3=TRUE --section-divs --template "C:\Users\th798\AppData\Local\R\win-library\4.3\rmarkdown\rmd\h\default.html" --no-highlight --variable highlightjs=1 --variable theme=bootstrap --mathjax --variable "mathjax-url=https://mathjax.rstudio.com/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML" --include-in-header "C:\Users\th798\AppData\Local\Temp\Rtmpgzn07f\rmarkdown-str41b81a5520.html" 
[WARNING] This document format requires a nonempty <title> element.
  Defaulting to 'buggy.knit' as the title.
  To specify a title, use 'title' in metadata or --metadata title="...".

Output created: C:/Users/th798/Downloads/nc/vignettes/buggy.html
```

The fix above is to use `knitr::rmarkdown` instead of `knitr::knitr`.

The stack trace from the error above is shown below,

```r
> traceback()
22: file(con, "r")
21: readLines(con, encoding = "UTF-8", warn = FALSE)
20: xfun::read_utf8(x)
19: base64_url(x, xfun::read_utf8(x), ext)
18: resolve_external(x, is_web, ext)
17: unique.default(c("AsIs", oldClass(x)))
16: I(c(t2[1], resolve_external(x, is_web, ext), t2[2]))
15: one_string(I(c(t2[1], resolve_external(x, is_web, ext), t2[2])))
14: (function (x, ext = "", embed_https = FALSE, embed_local = FALSE) 
    {
        if (ext == "css") {
            t1 = "<link rel=\"stylesheet\" href=\"%s\">"
            t2 = c("<style type=\"text/css\">", "</style>")
        }
        else if (ext == "js") {
            t1 = "<script src=\"%s\" defer></script>"
            t2 = c("<script>", "</script>")
        }
        else stop("The file extension '", ext, "' is not supported.")
        is_web = is_https(x)
        is_rel = !is_web && xfun::is_rel_path(x)
        if (is_web && embed_https && xfun::url_filename(x) == "MathJax.js") {
            warning("MathJax.js cannot be embedded. Please use MathJax v3 instead.")
            embed_https = FALSE
        }
        if ((is_rel && !embed_local) || (is_web && !embed_https)) {
            sprintf(t1, x)
        }
        else {
            one_string(I(c(t2[1], resolve_external(x, is_web, ext), 
                t2[2])))
        }
    })(dots[[1L]][[1L]], dots[[2L]][[1L]], dots[[3L]][[1L]], dots[[4L]][[1L]])
13: mapply(gen_tag, ...)
12: gen_tags(z3[i1], ifelse(js[i1], "js", "css"), embed[1], embed[2])
11: replace(z)
10: FUN(X[[i]], ...)
9: lapply(regmatches(x, m), function(z) {
       if (length(z)) 
           replace(z)
       else z
   })
8: match_replace(x, r, function(z) {
       z1 = sub(r, "\\1", z)
       z2 = sub(r, "\\2", z)
       js = z2 != ""
       z3 = paste0(z1, z2)
       i1 = !grepl("^data:.+;base64,.+", z3)
       z3[i1] = gen_tags(z3[i1], ifelse(js[i1], "js", "css"), embed[1], 
           embed[2])
       i2 = grepl(" (defer|async)(>| )", z) & js
       x2 <<- c(x2, z3[i2])
       z3[i2] = ""
       z3
   })
7: embed_resources(ret, options[["embed_resources"]])
6: xfun::in_dir(if (is_file(file, TRUE)) dirname(file) else ".", 
       embed_resources(ret, options[["embed_resources"]]))
5: mark(..., format = "html", template = template)
4: markdown::mark_html(...)
3: mark_html(out, output, ...)
2: (if (grepl("\\.[Rr]md$", file)) knit2html else if (grepl("\\.[Rr]rst$", 
       file)) knit2pandoc else knit)(file, encoding = encoding, 
       quiet = quiet, envir = globalenv(), ...)
1: tools::vignetteEngine("knitr::knitr")$weave("~/Downloads/buggy.Rmd")
```

And I posted [an issue](https://github.com/yihui/knitr/issues/2254).

## Reducing vignette sizes

Below terminal shows that inst/doc is a reasonable size, using built
packages from CRAN, 

```
th798@cmp2986 MINGW64 ~/Downloads
$ du -ks data.table/inst/doc/*
8	data.table/inst/doc/datatable-benchmarking.Rmd
28	data.table/inst/doc/datatable-benchmarking.html
8	data.table/inst/doc/datatable-faq.R
52	data.table/inst/doc/datatable-faq.Rmd
124	data.table/inst/doc/datatable-faq.html
16	data.table/inst/doc/datatable-importing.Rmd
36	data.table/inst/doc/datatable-importing.html
8	data.table/inst/doc/datatable-intro.R
32	data.table/inst/doc/datatable-intro.Rmd
104	data.table/inst/doc/datatable-intro.html
8	data.table/inst/doc/datatable-keys-fast-subset.R
20	data.table/inst/doc/datatable-keys-fast-subset.Rmd
76	data.table/inst/doc/datatable-keys-fast-subset.html
8	data.table/inst/doc/datatable-reference-semantics.R
16	data.table/inst/doc/datatable-reference-semantics.Rmd
60	data.table/inst/doc/datatable-reference-semantics.html
4	data.table/inst/doc/datatable-reshape.R
12	data.table/inst/doc/datatable-reshape.Rmd
52	data.table/inst/doc/datatable-reshape.html
8	data.table/inst/doc/datatable-sd-usage.R
16	data.table/inst/doc/datatable-sd-usage.Rmd
152	data.table/inst/doc/datatable-sd-usage.html
8	data.table/inst/doc/datatable-secondary-indices-and-auto-indexing.R
16	data.table/inst/doc/datatable-secondary-indices-and-auto-indexing.Rmd
52	data.table/inst/doc/datatable-secondary-indices-and-auto-indexing.html
th798@cmp2986 MINGW64 ~/Downloads
$ du -ks nc/inst/doc/*
8	nc/inst/doc/v1-capture-first.R
12	nc/inst/doc/v1-capture-first.Rmd
40	nc/inst/doc/v1-capture-first.html
4	nc/inst/doc/v2-capture-all.R
8	nc/inst/doc/v2-capture-all.Rmd
36	nc/inst/doc/v2-capture-all.html
4	nc/inst/doc/v3-capture-melt.R
12	nc/inst/doc/v3-capture-melt.Rmd
48	nc/inst/doc/v3-capture-melt.html
16	nc/inst/doc/v4-comparisons.R
20	nc/inst/doc/v4-comparisons.Rmd
84	nc/inst/doc/v4-comparisons.html
```

A [SO
post](https://stackoverflow.com/questions/66181907/the-html-files-of-rendered-vignettes-are-too-big-for-cran)
says "there's nothing to be done." But I do not believe that. So I
tried building data.table from source,

```r
> devtools::build("~/R/data.table")
-- R CMD build -----------------------------------------------------------------
* checking for file 'C:\Users\th798\R\data.table/DESCRIPTION' ... OK
* preparing 'data.table':
* checking DESCRIPTION meta-information ... OK
* cleaning src
* installing the package to build vignettes
      -----------------------------------
* installing *source* package 'data.table' ...
** using staged installation

   **********************************************
   WARNING: this package has a configure script
         It probably needs manual configuration
   **********************************************


** libs
using C compiler: 'gcc.exe (MinGW.org GCC-6.3.0-1) 6.3.0'
gcc  -I"c:/PROGRA~1/R/R-43~1.0/include" -DNDEBUG     -I"c:/rtools43/x86_64-w64-mingw32.static.posix/include"  -fopenmp   -O2 -Wall  -mfpmath=sse -msse2 -mstackrealign  -Wall -pedantic -c assign.c -o assign.o
gcc  -I"c:/PROGRA~1/R/R-43~1.0/include" -DNDEBUG     -I"c:/rtools43/x86_64-w64-mingw32.static.posix/include"  -fopenmp   -O2 -Wall  -mfpmath=sse -msse2 -mstackrealign  -Wall -pedantic -c between.c -o between.o
gcc  -I"c:/PROGRA~1/R/R-43~1.0/include" -DNDEBUG     -I"c:/rtools43/x86_64-w64-mingw32.static.posix/include"  -fopenmp   -O2 -Wall  -mfpmath=sse -msse2 -mstackrealign  -Wall -pedantic -c bmerge.c -o bmerge.o
gcc  -I"c:/PROGRA~1/R/R-43~1.0/include" -DNDEBUG     -I"c:/rtools43/x86_64-w64-mingw32.static.posix/include"  -fopenmp   -O2 -Wall  -mfpmath=sse -msse2 -mstackrealign  -Wall -pedantic -c chmatch.c -o chmatch.o
gcc  -I"c:/PROGRA~1/R/R-43~1.0/include" -DNDEBUG     -I"c:/rtools43/x86_64-w64-mingw32.static.posix/include"  -fopenmp   -O2 -Wall  -mfpmath=sse -msse2 -mstackrealign  -Wall -pedantic -c cj.c -o cj.o
gcc  -I"c:/PROGRA~1/R/R-43~1.0/include" -DNDEBUG     -I"c:/rtools43/x86_64-w64-mingw32.static.posix/include"  -fopenmp   -O2 -Wall  -mfpmath=sse -msse2 -mstackrealign  -Wall -pedantic -c coalesce.c -o coalesce.o
gcc  -I"c:/PROGRA~1/R/R-43~1.0/include" -DNDEBUG     -I"c:/rtools43/x86_64-w64-mingw32.static.posix/include"  -fopenmp   -O2 -Wall  -mfpmath=sse -msse2 -mstackrealign  -Wall -pedantic -c dogroups.c -o dogroups.o
gcc  -I"c:/PROGRA~1/R/R-43~1.0/include" -DNDEBUG     -I"c:/rtools43/x86_64-w64-mingw32.static.posix/include"  -fopenmp   -O2 -Wall  -mfpmath=sse -msse2 -mstackrealign  -Wall -pedantic -c fastmean.c -o fastmean.o
gcc  -I"c:/PROGRA~1/R/R-43~1.0/include" -DNDEBUG     -I"c:/rtools43/x86_64-w64-mingw32.static.posix/include"  -fopenmp   -O2 -Wall  -mfpmath=sse -msse2 -mstackrealign  -Wall -pedantic -c fcast.c -o fcast.o
gcc  -I"c:/PROGRA~1/R/R-43~1.0/include" -DNDEBUG     -I"c:/rtools43/x86_64-w64-mingw32.static.posix/include"  -fopenmp   -O2 -Wall  -mfpmath=sse -msse2 -mstackrealign  -Wall -pedantic -c fifelse.c -o fifelse.o
gcc  -I"c:/PROGRA~1/R/R-43~1.0/include" -DNDEBUG     -I"c:/rtools43/x86_64-w64-mingw32.static.posix/include"  -fopenmp   -O2 -Wall  -mfpmath=sse -msse2 -mstackrealign  -Wall -pedantic -c fmelt.c -o fmelt.o
gcc  -I"c:/PROGRA~1/R/R-43~1.0/include" -DNDEBUG     -I"c:/rtools43/x86_64-w64-mingw32.static.posix/include"  -fopenmp   -O2 -Wall  -mfpmath=sse -msse2 -mstackrealign  -Wall -pedantic -c forder.c -o forder.o
gcc  -I"c:/PROGRA~1/R/R-43~1.0/include" -DNDEBUG     -I"c:/rtools43/x86_64-w64-mingw32.static.posix/include"  -fopenmp   -O2 -Wall  -mfpmath=sse -msse2 -mstackrealign  -Wall -pedantic -c frank.c -o frank.o
gcc  -I"c:/PROGRA~1/R/R-43~1.0/include" -DNDEBUG     -I"c:/rtools43/x86_64-w64-mingw32.static.posix/include"  -fopenmp   -O2 -Wall  -mfpmath=sse -msse2 -mstackrealign  -Wall -pedantic -c fread.c -o fread.o
fread.c: In function 'filesize_to_str':
fread.c:418:36: warning: unknown conversion type character 'l' in format [-Wformat=]
         snprintf(output, BUFFSIZE, "%"PRIu64"%cB (%"PRIu64" bytes)",
                                    ^~~
fread.c:418:36: warning: format '%c' expects argument of type 'int', but argument 4 has type 'long long unsigned int' [-Wformat=]
fread.c:418:36: warning: unknown conversion type character 'l' in format [-Wformat=]
fread.c:418:36: warning: too many arguments for format [-Wformat-extra-args]
fread.c:423:34: warning: unknown conversion type character 'l' in format [-Wformat=]
       snprintf(output, BUFFSIZE, "%.*f%cB (%"PRIu64" bytes)",
                                  ^~~~~~~~~~~~
fread.c:423:34: warning: too many arguments for format [-Wformat-extra-args]
fread.c:429:30: warning: unknown conversion type character 'l' in format [-Wformat=]
   snprintf(output, BUFFSIZE, "%"PRIu64" bytes", (uint64_t)lsize);
                              ^~~
fread.c:429:30: warning: too many arguments for format [-Wformat-extra-args]
fread.c: In function 'freadMain':
fread.c:1290:11: warning: implicit declaration of function 'isspace' [-Wimplicit-function-declaration]
       if (isspace(ch[0]) || isspace(ch[nchar-1]))
           ^~~~~~~
In file included from freadR.h:6:0,
                 from fread.h:12,
                 from fread.c:1:
fread.c:2385:23: warning: unknown conversion type character 'l' in format [-Wformat=]
                     _("Column %d%s%.*s%s bumped from '%s' to '%s' due to <<%.*s>> on row %"PRIu64"\n"),
                       ^
po.h:3:42: note: in definition of macro '_'
 #define _(String) dgettext("data.table", String)
                                          ^~~~~~
fread.c:2385:23: warning: too many arguments for format [-Wformat-extra-args]
                     _("Column %d%s%.*s%s bumped from '%s' to '%s' due to <<%.*s>> on row %"PRIu64"\n"),
                       ^
po.h:3:42: note: in definition of macro '_'
 #define _(String) dgettext("data.table", String)
                                          ^~~~~~
gcc  -I"c:/PROGRA~1/R/R-43~1.0/include" -DNDEBUG     -I"c:/rtools43/x86_64-w64-mingw32.static.posix/include"  -fopenmp   -O2 -Wall  -mfpmath=sse -msse2 -mstackrealign  -Wall -pedantic -c freadR.c -o freadR.o
gcc  -I"c:/PROGRA~1/R/R-43~1.0/include" -DNDEBUG     -I"c:/rtools43/x86_64-w64-mingw32.static.posix/include"  -fopenmp   -O2 -Wall  -mfpmath=sse -msse2 -mstackrealign  -Wall -pedantic -c froll.c -o froll.o
gcc  -I"c:/PROGRA~1/R/R-43~1.0/include" -DNDEBUG     -I"c:/rtools43/x86_64-w64-mingw32.static.posix/include"  -fopenmp   -O2 -Wall  -mfpmath=sse -msse2 -mstackrealign  -Wall -pedantic -c frollR.c -o frollR.o
gcc  -I"c:/PROGRA~1/R/R-43~1.0/include" -DNDEBUG     -I"c:/rtools43/x86_64-w64-mingw32.static.posix/include"  -fopenmp   -O2 -Wall  -mfpmath=sse -msse2 -mstackrealign  -Wall -pedantic -c frolladaptive.c -o frolladaptive.o
gcc  -I"c:/PROGRA~1/R/R-43~1.0/include" -DNDEBUG     -I"c:/rtools43/x86_64-w64-mingw32.static.posix/include"  -fopenmp   -O2 -Wall  -mfpmath=sse -msse2 -mstackrealign  -Wall -pedantic -c fsort.c -o fsort.o
gcc  -I"c:/PROGRA~1/R/R-43~1.0/include" -DNDEBUG     -I"c:/rtools43/x86_64-w64-mingw32.static.posix/include"  -fopenmp   -O2 -Wall  -mfpmath=sse -msse2 -mstackrealign  -Wall -pedantic -c fwrite.c -o fwrite.o
fwrite.c:11:49: fatal error: zlib.h: No such file or directory
 #include <zlib.h>      // for compression to .gz
                                                 ^
compilation terminated.
make: *** [c:/PROGRA~1/R/R-43~1.0/etc/x64/Makeconf:265: fwrite.o] Error 1
ERROR: compilation failed for package 'data.table'
* removing 'C:/Users/th798/AppData/Local/Temp/Rtmps1AH7I/Rinst1d38723f4d34/data.table'
      -----------------------------------
ERROR: package installation failed
Error in `(function (command = NULL, args = character(), error_on_status = TRUE, ...`:
! System command 'Rcmd.exe' failed
---
Exit status: 1
stdout & stderr: <printed>
---
Type .Last.error to see the more details.
```

The above output suggests I have an old version of gcc, so I tried to
install a newer version,
[rtools43](https://cloud.r-project.org/bin/windows/Rtools/rtools43/rtools.html),

After which I get

```
> devtools::build("~/R/data.table")
-- R CMD build -----------------------------------------------------------------
* checking for file 'C:\Users\th798\R\data.table/DESCRIPTION' ... OK
* preparing 'data.table':
* checking DESCRIPTION meta-information ... OK
* cleaning src
* installing the package to build vignettes
* creating vignettes ... OK
* cleaning src
* checking for LF line-endings in source and make files and shell scripts
* checking for empty or unneeded directories
* building 'data.table_1.14.9.tar.gz'
Warning: file 'data.table/cleanup' did not have execute permissions: corrected
Warning: file 'data.table/configure' did not have execute permissions: corrected

[1] "C:/Users/th798/R/data.table_1.14.9.tar.gz"
> Sys.which("gcc")
                                       gcc 
"C:\\rtools43\\X86_64~1.POS\\bin\\gcc.exe" 
> system("gcc --version")
gcc.exe (GCC) 12.2.0
Copyright (C) 2022 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

[1] 0
```

Re-building both data.table and nc, I see major differences in html
file sizes, below,

```
th798@cmp2986 MINGW64 ~/R/built
$ tar xf ../data.table_1.14.9.tar.gz 
th798@cmp2986 MINGW64 ~/R/built
$ tar xf ../nc_2023.5.1.tar.gz 
th798@cmp2986 MINGW64 ~/R/built
$ du -ks */inst/doc/*html
28	data.table/inst/doc/datatable-benchmarking.html
132	data.table/inst/doc/datatable-faq.html
40	data.table/inst/doc/datatable-importing.html
116	data.table/inst/doc/datatable-intro.html
88	data.table/inst/doc/datatable-keys-fast-subset.html
80	data.table/inst/doc/datatable-programming.html
52	data.table/inst/doc/datatable-reference-semantics.html
52	data.table/inst/doc/datatable-reshape.html
68	data.table/inst/doc/datatable-sd-usage.html
52	data.table/inst/doc/datatable-secondary-indices-and-auto-indexing.html
720	nc/inst/doc/v0-overview.html
748	nc/inst/doc/v1-capture-first.html
736	nc/inst/doc/v2-capture-all.html
844	nc/inst/doc/v3-capture-melt.html
180	nc/inst/doc/v4-comparisons.html
724	nc/inst/doc/v5-helpers.html
720	nc/inst/doc/v6-engines.html
```

At least the first one, v0-overview, should be small (there are only
about 100 lines in the Rmd file). Different headers

```
<!--
%\VignetteEngine{knitr::rmarkdown}
%\VignetteIndexEntry{vignette 0: Overview}
-->
```

and

```r
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
```

vs

```
---
title: "Efficient reshaping using data.tables"
date: "`r Sys.Date()`"
output:
  rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Efficient reshaping using data.tables}
  %\VignetteEngine{knitr::rmarkdown}
  \usepackage[utf8]{inputenc}
---
```

```r
require(data.table)
knitr::opts_chunk$set(
  comment = "#",
    error = FALSE,
     tidy = FALSE,
    cache = FALSE,
 collapse = TRUE)
```

First I tried to copy the chunk options to nc, which makes the code below,

```r
knitr::opts_chunk$set(
    error = FALSE,
     tidy = FALSE,
    cache = FALSE,
  collapse = TRUE,
  comment = "#>"
)
```

No, the code below says the vignette is still big:

```
th798@cmp2986 MINGW64 ~/R/built
$ rm -rf nc && tar xf ../nc_2023.5.1.tar.gz && du -ks */inst/doc/*html
28	data.table/inst/doc/datatable-benchmarking.html
132	data.table/inst/doc/datatable-faq.html
40	data.table/inst/doc/datatable-importing.html
116	data.table/inst/doc/datatable-intro.html
88	data.table/inst/doc/datatable-keys-fast-subset.html
80	data.table/inst/doc/datatable-programming.html
52	data.table/inst/doc/datatable-reference-semantics.html
52	data.table/inst/doc/datatable-reshape.html
68	data.table/inst/doc/datatable-sd-usage.html
52	data.table/inst/doc/datatable-secondary-indices-and-auto-indexing.html
720	nc/inst/doc/v0-overview.html
748	nc/inst/doc/v1-capture-first.html
736	nc/inst/doc/v2-capture-all.html
844	nc/inst/doc/v3-capture-melt.html
180	nc/inst/doc/v4-comparisons.html
724	nc/inst/doc/v5-helpers.html
720	nc/inst/doc/v6-engines.html
```

So I try the other part of the header, and I see the size is reduced below,

```
th798@cmp2986 MINGW64 ~/R/built
$ cd .. && R CMD build nc && cd built && rm -rf nc && tar xf ../nc_2023.5.1.tar.gz && du -ks */inst/doc/*html
* checking for file 'nc/DESCRIPTION' ... OK
* preparing 'nc':
* checking DESCRIPTION meta-information ... OK
* installing the package to build vignettes
* creating vignettes ... OK
* checking for LF line-endings in source and make files and shell scripts
* checking for empty or unneeded directories
* building 'nc_2023.5.1.tar.gz'

28	data.table/inst/doc/datatable-benchmarking.html
132	data.table/inst/doc/datatable-faq.html
40	data.table/inst/doc/datatable-importing.html
116	data.table/inst/doc/datatable-intro.html
88	data.table/inst/doc/datatable-keys-fast-subset.html
80	data.table/inst/doc/datatable-programming.html
52	data.table/inst/doc/datatable-reference-semantics.html
52	data.table/inst/doc/datatable-reshape.html
68	data.table/inst/doc/datatable-sd-usage.html
52	data.table/inst/doc/datatable-secondary-indices-and-auto-indexing.html
28	nc/inst/doc/v0-overview.html
748	nc/inst/doc/v1-capture-first.html
736	nc/inst/doc/v2-capture-all.html
844	nc/inst/doc/v3-capture-melt.html
180	nc/inst/doc/v4-comparisons.html
724	nc/inst/doc/v5-helpers.html
720	nc/inst/doc/v6-engines.html
```

The important part is `output: rmarkdown::html_vignette`
apparently. Using that in all of the vignettes gives the sizes below,

```
th798@cmp2986 MINGW64 ~/R/built
$ cd .. && R CMD build nc && cd built && rm -rf nc && tar xf ../nc_2023.5.1.tar.gz && du -ks */inst/doc/*html
* checking for file 'nc/DESCRIPTION' ... OK
* preparing 'nc':
* checking DESCRIPTION meta-information ... OK
* installing the package to build vignettes
* creating vignettes ... OK
* checking for LF line-endings in source and make files and shell scripts
* checking for empty or unneeded directories
* building 'nc_2023.5.1.tar.gz'

28	data.table/inst/doc/datatable-benchmarking.html
132	data.table/inst/doc/datatable-faq.html
40	data.table/inst/doc/datatable-importing.html
116	data.table/inst/doc/datatable-intro.html
88	data.table/inst/doc/datatable-keys-fast-subset.html
80	data.table/inst/doc/datatable-programming.html
52	data.table/inst/doc/datatable-reference-semantics.html
52	data.table/inst/doc/datatable-reshape.html
68	data.table/inst/doc/datatable-sd-usage.html
52	data.table/inst/doc/datatable-secondary-indices-and-auto-indexing.html
28	nc/inst/doc/v0-overview.html
100	nc/inst/doc/v1-capture-first.html
72	nc/inst/doc/v2-capture-all.html
100	nc/inst/doc/v3-capture-melt.html
180	nc/inst/doc/v4-comparisons.html
36	nc/inst/doc/v5-helpers.html
28	nc/inst/doc/v6-engines.html
```
