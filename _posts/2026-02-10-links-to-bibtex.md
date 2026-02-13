---
layout: post
title: Markdown links to bibtex
description: Regular expressions exercise
---



The purpose of this page is to convert markdown links to bibtex using regular expressions.

## Problem

I am using markdown (actually quarto) to write two online "books"

* [Animated interactive data visualization using animint2 in R](https://animint-manual-en.netlify.app/)
* [Visualisation interactive de données dans R avec animint2](https://animint-manual-fr.netlify.app/)

Including hyperlinks in markdown is via the syntax

```
[text that will appear](hyperlink)
```

This works fine for HTML output, where we can click the link.
But in PDF output we get blue text, and the link is lost when the document is printed.
An example is shown below.

![french and english links](/assets/img/2026-02-10-links-to-bibtex/links-diff.png)

* left we see the French version with bibtex references.
* right we see the English version with markdown hyperlinks.
* top we see the web page output.
* bottom we see the PDF output (and https URL in references section of French version).

I already wrote a CI script [test-references.R](https://github.com/animint/animint-manual-en/pull/19) that errors if it finds markdown links.


``` r
chapters <- "~/R/animint-manual-en/chapters"
qmd.files <- c(
  Sys.glob(file.path(chapters,"*qmd")),
  Sys.glob(file.path(chapters,"*/index.qmd")))
library(data.table)
```

```
## data.table 1.18.2.1 utilise 1 threads (voir ?getDTthreads).  Dernières actualités : r-datatable.com
## **********
## Exécution de data.table en anglais ; l'aide du package n'est disponible qu'en anglais. Lorsque vous recherchez de l'aide en ligne, veillez à vérifier également le message d'erreur en anglais. Pour ce faire, consultez les fichiers po/R-<locale>.po et po/<locale>.po dans le source du package, où les messages d'erreur en langue native et ceux en anglais figurent côte à côte. Vous pouvez aussi essayer d'appeler Sys.setLanguage('en') avant de reproduire le message d'erreur.
## **********
## 
## Attachement du package : 'data.table'
## 
## L'objet suivant est masqué depuis 'package:base':
## 
##     %notin%
```

``` r
get_violations <- function(qmd){
  nc::capture_all_str(
    qmd,
    "\\]\\(",
    url="http.*?",
    "\\)")$url
}
violations <- list()
for(qmd in qmd.files){
  bad <- get_violations(qmd)
  if(length(bad)){
    violations[[qmd]] <- bad
  }
}
print(violations)
```

```
## $`/home/local/USHERBROOKE/hoct2726/R/animint-manual-en/chapters/ch05/index.qmd`
## [1] "https://app.netlify.com/drop"                                                            
## [2] "https://github.com/tdhock/animint2/wiki/FAQ#web-browser-on-local-indexhtml-file-is-blank"
## [3] "https://github.com/join"                                                                 
## [4] "https://vimeo.com"                                                                       
## 
## $`/home/local/USHERBROOKE/hoct2726/R/animint-manual-en/chapters/ch07/index.qmd`
## [1] "https://github.com/tdhock/animint2/blob/master/tests/testthat/test-renderer4-update-axes-multiple-ss.R"
```

The goal of this post is to write a conversion to bibtex.
The source code to find is `please consult our [wiki FAQ](https://github.com/tdhock/animint2/wiki/FAQ#web-browser-on-local-indexhtml-file-is-blank)`.
We want to change it to

```
please consult our wiki FAQ [@animintFAQ]
```

```bib
@unpublished{animintFAQ,
  title={Animint FAQ},
  author={Toby Hocking},
  url={https://github.com/tdhock/animint2/wiki/FAQ#web-browser-on-local-indexhtml-file-is-blank},
  year={2025}
}
```

## find in one file

Here is an example with one file.


``` r
qmd <- "~/R/animint-manual-en/chapters/ch14/index.qmd"
```

Below we define a regular expression to match a markdown link.


``` r
link_pattern <- list(
  "\\[",
  title=".*?",
  "\\]\\(",
  url="http.*?",
  "\\)")
options(nc.engine="RE2")
nc::capture_all_str(qmd, link_pattern)
```

```
## data.table est vide (0 ligne et 2 colonne): title,url
```

The output above is a table with two lines, one for each markdown link in the `qmd` file.
This pattern is not sufficient for our purpose, which is to change each link to a citation.
To do that we need a pattern which will result in a set of matches that spans the whole file.
We do that below by adding

* a `before` group that captures anything before the link, even newlines, as indicated by `(?s)`.
* an alternative that matches the end of the file, `$`, instead of the link.


``` r
before_pattern <- list(
  before="(?s).+?",
  nc::alternatives(
    link=link_pattern,
    "$"))
match_dt <- nc::capture_all_str(qmd, before_pattern)
tibble::tibble(match_dt)
```

````
## # A tibble: 1 × 4
##   before                                                                          link  title url  
##   <chr>                                                                           <chr> <chr> <chr>
## 1 "# Named `clickSelects` and `showSelected`\n\n```{r setup, echo=FALSE}\nknitr:… ""    ""    ""
````

``` r
tibble::tibble(match_dt[, .(title, url)])
```

```
## # A tibble: 1 × 2
##   title url  
##   <chr> <chr>
## 1 ""    ""
```

The output above shows that there were three matches.

* The first two are links.
* The last one contains the rest of the file, after the last link.

Does this set of matches really span the whole file?
Below we paste together the matched data, write it to a reconstituted file, and then read it back into R, along with the original file.


``` r
same.qmd <- tempfile()
same_content <- match_dt[, paste(paste0(before, link), collapse="")]
writeLines(same_content, same.qmd)
qlist <- list(original=qmd, reconstituted=same.qmd)
q_data_list <- sapply(qlist, readLines, simplify=FALSE)
```

```
## Warning in FUN(X[[i]], ...): ligne finale incomplète trouvée dans
## '~/R/animint-manual-en/chapters/ch14/index.qmd'
```

``` r
with(q_data_list, identical(original, reconstituted))
```

```
## [1] TRUE
```

The output above indicates that we have indeed matched the whole file.

## replace in one file

Below we compute the replacement citation for each markdown link.


``` r
match_dt[
, key := gsub(" ", "_", title)
][
, replacement := ifelse(
  link=="", "",
  sprintf("%s [@%s]", title, key))
][, replacement]
```

```
## [1] ""
```

We see above that `title` has been used to create the bibtex citation `key` which appears in square brackets.
Next, we verify that there are no violations using this replacement.


``` r
new_content <- match_dt[, paste(paste0(before, replacement), collapse="")]
get_violations(new_content)
```

```
## character(0)
```

``` r
get_violations(same_content)
```

```
## character(0)
```

Above we see that there are no violations using the new content, but there were two violations using the old content.
Finally we create the entries for the bib file.


``` r
bib_vec <- match_dt[-.N, sprintf("@unpublished{ %s,
  title={ %s },
  author={ TODO },
  url={ %s },
  year={ 2026 }
}
", key, title, url)]
cat(paste(bib_vec, collapse="\n"))
```

The output above shows two entries for a bib file.

## find and replace in all files


``` r
chapters <- "~/R/animint-manual-en/chapters"
qmd.files <- c(
  Sys.glob(file.path(chapters,"*qmd")),
  Sys.glob(file.path(chapters,"*/index.qmd")))
bib_list <- list()
for(qmd in qmd.files){
  match_dt <- nc::capture_all_str(qmd, before_pattern)[
  , key := gsub(" ", "_", title)
  ][
  , replacement := ifelse(
    link=="", "",
    sprintf("%s [@%s]", title, key))
  ]
  new_content <- match_dt[, paste(paste0(before, replacement), collapse="")]
  cat(new_content, file=qmd)
  bib_list[[qmd]] <- match_dt[-.N, sprintf("@unpublished{ %s,
  title={ %s },
  author={ TODO },
  url={ %s },
  year={ 2026 }
}
", key, title, url)]
}

cat(paste(unlist(bib_list), collapse="\n"))
```

```
## @unpublished{ vimeo,
##   title={ vimeo },
##   author={ TODO },
##   url={ https://vimeo.com },
##   year={ 2026 }
## }
```

After running the code above, I copied the output to the end of the `refs.bib` file, then [manually corrected the TODOs](https://github.com/animint/animint-manual-en/pull/19/commits/84a60ddcd292ceaccd759c24be2a4645f50d54be) in [PR19](https://github.com/animint/animint-manual-en/pull/19/).

## Conclusion

We have seen how regex can be used for a non-trivial find and replace across multiple qmd files: changing markdown links to bib citations.
The `before_pattern` is generally useful for matching an entire file, so I created [an issue in nc](https://github.com/tdhock/nc/issues/35) about potentially creating a pattern-making function.

## Bonus: don’t use gsub etc.

You may be tempted to use `gsub()` or similar string replacement functions, but they actually do not work in this case.


``` r
gsub(
  "\\[(.*?)\\]\\((http.*?)\\)",
  "\\[@\\1\\]",
  "[foo and](http) [bar not](http)",
  perl=TRUE)
```

```
## [1] "[@foo and] [@bar not]"
```

The output above shows that the replacement works, but there are spaces in the bibtex citation keys, [which are not allowed](https://tex.stackexchange.com/questions/224674/can-i-have-a-reference-with-spacing-using-bibtex-like-citeauthor-year).
Note the `\1` in the code above (numbered reference to capture group) can be replaced by a named reference `${title}` using ICU in the code below.


``` r
subject <- "[foo](http) [bar](http)"
pattern <- "\\[(?<title>.*?)\\]\\((?<url>http.*?)\\)"
stringi::stri_replace_all_regex(subject, pattern, "\\[@${title}\\]")
```

```
## [1] "[@foo] [@bar]"
```

But surprisingly, this does not work with `gsub()` in the code below.


``` r
gsub(pattern, "\\[@${title}\\]", subject, perl=TRUE)
```

```
## [1] "[@${title}] [@${title}]"
```

``` r
gsub(pattern, "\\[@$<title>\\]", subject, perl=TRUE)
```

```
## [1] "[@$<title>] [@$<title>]"
```

``` r
gsub(pattern, "\\[@$1\\]",       subject, perl=TRUE)
```

```
## [1] "[@$1] [@$1]"
```

``` r
gsub(pattern, "\\[@\\1\\]",      subject, perl=TRUE)
```

```
## [1] "[@foo] [@bar]"
```

The only replacement syntax that works is `\1` (number not name).
Is this a bug in R or PCRE2?

* `man pcre2syntax` section [REPLACEMENT STRINGS](https://www.pcre.org/current/doc/html/pcre2syntax.html) says we should be able to use `$1` for first group, and `$<title>` for named group.
* R `?sub` argument `replacement` says to use backslash, not dollar: For ‘fixed = FALSE’ this can include backreferences ‘"\1"’ to ‘"\9"’ to parenthesized subexpressions of ‘pattern’.

So R is working as documented.
But it is not clear to me why the R documentation differs from `man pcre2syntax`.

## session info


``` r
sessionInfo()
```

```
## R Under development (unstable) (2026-02-07 r89380)
## Platform: x86_64-pc-linux-gnu
## Running under: Ubuntu 24.04.3 LTS
## 
## Matrix products: default
## BLAS:   /usr/lib/x86_64-linux-gnu/blas/libblas.so.3.12.0 
## LAPACK: /usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.12.0  LAPACK version 3.12.0
## 
## locale:
##  [1] LC_CTYPE=fr_FR.UTF-8       LC_NUMERIC=C               LC_TIME=fr_FR.UTF-8       
##  [4] LC_COLLATE=fr_FR.UTF-8     LC_MONETARY=fr_FR.UTF-8    LC_MESSAGES=fr_FR.UTF-8   
##  [7] LC_PAPER=fr_FR.UTF-8       LC_NAME=C                  LC_ADDRESS=C              
## [10] LC_TELEPHONE=C             LC_MEASUREMENT=fr_FR.UTF-8 LC_IDENTIFICATION=C       
## 
## time zone: America/Toronto
## tzcode source: system (glibc)
## 
## attached base packages:
## [1] stats     graphics  grDevices utils     datasets  methods   base     
## 
## other attached packages:
## [1] data.table_1.18.2.1
## 
## loaded via a namespace (and not attached):
##  [1] utf8_1.2.6      xfun_0.56       nc_2025.3.24    magrittr_2.0.4  glue_1.8.0     
##  [6] tibble_3.3.1    knitr_1.51      pkgconfig_2.0.3 re2_0.1.4       lifecycle_1.0.5
## [11] cli_3.6.5       vctrs_0.7.1     compiler_4.6.0  tools_4.6.0     evaluate_1.0.5 
## [16] pillar_1.11.1   Rcpp_1.1.1      otel_0.2.0      rlang_1.1.7     stringi_1.8.7
```
