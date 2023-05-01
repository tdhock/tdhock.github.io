---
layout: post
title: Re-building vignettes on windows
description: Fixing mysterious error
---

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
