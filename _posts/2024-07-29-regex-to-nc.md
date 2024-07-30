---
layout: post
title: Porting base R regex code to nc
description: Case study with a complex regex
---

[nc](https://github.com/tdhock/nc) is an R package that I created for named capture regular expressions (regex).
The goal of this post is to explain how to port base R regex code to nc, for improved readability.



## Background

R is a programming language for statistics and graphics, which is implemented in C.
In R, there is special nomenclature for standard computer science / programming concepts

* A library (piece of code which offers extended functionality) in R is called a package, which can contain R and C code.
* The "standard library" in R, sometimes called base R, includes the Recommended packages, developed by R core, which is a group 10-20 people, listed in the [AUTHORS](https://github.com/r-devel/r-svn/blob/main/doc/AUTHORS) file.
* Other packages, developed by other people, are distributed on the CRAN, and these other packages may include custom C code, which can call some of the C library functions that are provided in the base R packages.

Up until this year, there has been only an informal definition of which base C library functions are public. That is, if the functions were described in [Writing R Extensions](https://cloud.r-project.org/doc/manuals/r-release/R-exts.html), then that means they are exported / allowed to be called by other packages. 

Earlier this year, R core has started to formally declare which base C library functions are public.
So there is now a programmatic method for determining which C library functions are public.
CRAN checks have started using this, and complaining about packages which call C library functions which are not public.
There is an interest in programming tools that can be used to determine which C library functions are public, based on the C source code.

## Ivan's code

Earlier this month, Ivan Krylov [posted the following on
R-devel](https://stat.ethz.ch/pipermail/r-devel/2024-July/083542.html).

A relatively compact (but still brittle) way to match function
declarations in C header files is shown at the end of this message. I
have confirmed that compared to `tools:::getFunsHdr`, the only extraneous
symbols that it finds in preprocessed headers are `R_SetWin32`,
`user_unif_rand`, `user_unif_init`, `user_unif_nseed`,
`user_unif_seedloc`, `user_norm_rand`, which are special-cased in
`tools:::getFunsHdr`, and the only symbols it doesn't find are `select`
and `delztg` in `R_ext/Lapack.h`, which we should not be finding.


```r
rx <- r"{
(?xs)
(?!typedef)(?<!\w) # please no typedefs
# return type with attributes
(?<rtype>
  # words followed by whitespace or stars
  (?: \w+ (?:\s+ | \*)+)+
)
# function name, assumes no extra whitespace
(?<fun_name>
  \w+\(\w+\) # macro call
  | \(\w+\)  # in parentheses
  | \w+      # a plain name
)
# arguments: non-greedy match inside parentheses
\s* \( (?<args>.*?) \) \s* # using dotall here
# will include R_PRINTF_FORMAT(1,2 but we don't care
# finally terminated by semicolon
;
}"
### "Bird's eye" view, gives unmapped names on non-preprocessed headers
getdecl <- function(file, lines = readLines(file)) {
  ## have to combine to perform multi-line matches
  lines <- paste(c(lines, ''), collapse = '\n')
  ## first eat the C comments, dotall but non-greedy match
  lines <- gsub('(?s)/\\*.*?\\*/', '', lines, perl = TRUE)
  ## C++-style comments too, multiline not dotall
  lines <- gsub('(?m)//.*$', '', lines, perl = TRUE)
  ## drop all preprocessor directives
  lines <- gsub('(?m)^\\s*#.*$', '', lines, perl = TRUE)
  regmatches(lines, gregexec(rx, lines, perl = TRUE))[[1]][3,]
}
### Preprocess then extract remapped function names like getFunsHdr
getdecl2 <- function(file) {
  file |>
    readLines() |>
    grep('^\\s*#\\s*error', x = _, value = TRUE, invert = TRUE) |>
    tools:::ccE() |>
    getdecl(lines = _)
}
local.r.svn <- "~/R/r-svn"
if(!file.exists(local.r.svn)){
  gert::git_clone("https://github.com/r-devel/r-svn", local.r.svn)
}
getdecl("~/R/r-svn/src/include/R.h")
```

```
## [1] "R_FlushConsole"  "R_ProcessEvents" "R_WaitEvent"
```

```r
##getdecl("~/R/r-svn/src/include/Rdefines.h")
getdecl("~/R/r-svn/src/include/R_ext/Altrep.h")
```

```
## [1] "R_new_altrep"            "R_make_altstring_class"  "R_make_altinteger_class" "R_make_altreal_class"   
## [5] "R_make_altlogical_class" "R_make_altraw_class"     "R_make_altcomplex_class" "R_make_altlist_class"   
## [9] "R_altrep_inherits"
```

What is going on in the base R regex code above? The one letter option
codes inside parentheses are documented on the pcre2pattern man page,
sections [INTERNAL OPTION
SETTING](https://www.pcre.org/current/doc/html/pcre2pattern.html#SEC13).

### multi-line

`(?m)` turns on multi-line matching, which is documented in section [CIRCUMFLEX AND DOLLAR](https://www.pcre.org/current/doc/html/pcre2pattern.html#SEC6):
"The meanings of the circumflex and dollar metacharacters are changed
if the `PCRE2_MULTILINE` option is set. When this is the case, a dollar
character matches before any newlines in the string, as well as at the
very end, and a circumflex matches immediately after internal newlines
as well as at the start of the subject string. It does not match after
a newline that ends the string, for compatibility with Perl. However,
this can be changed by setting the `PCRE2_ALT_CIRCUMFLEX` option."


```r
gsub("^", "_", "foo\nbar", perl=TRUE)
```

```
## [1] "_foo\nbar"
```

```r
gsub("(?m)^", "_", "foo\nbar", perl=TRUE)
```

```
## [1] "_foo\n_bar"
```

### DOTALL

`(?s)` turns on DOTALL matching, which is documented in [FULL STOP (PERIOD, DOT) AND \N](https://www.pcre.org/current/doc/html/pcre2pattern.html#SEC7): "Outside a character class, a dot in the pattern matches any one character in the subject string except (by default) a character that signifies the end of a line... The behaviour of dot with regard to newlines can be changed. If the `PCRE2_DOTALL` option is set, a dot matches any one character, without exception."


```r
sub(".*", "", "foo\nbar", perl=TRUE)
```

```
## [1] "\nbar"
```

```r
sub("(?s).*", "", "foo\nbar", perl=TRUE)
```

```
## [1] ""
```

### Extended matching

`(?x)` turns on extended matching, which is documented in

* [COMMENTS](https://www.pcre.org/current/doc/html/pcre2pattern.html#SEC24):
  "The sequence `(?#` marks the start of a comment that continues up
  to the next closing parenthesis. Nested parentheses are not
  permitted. If the `PCRE2_EXTENDED` or `PCRE2_EXTENDED_MORE` option
  is set, an unescaped `#` character also introduces a comment, which
  in this case continues to immediately after the next newline
  character or character sequence in the pattern."
* [CHARACTERS AND
  METACHARACTERS](https://www.pcre.org/current/doc/html/pcre2pattern.html#SEC4):
  "If a pattern is compiled with the `PCRE2_EXTENDED` option, most
  white space in the pattern, other than in a character class, and
  characters between a `#` outside a character class and the next
  newline, inclusive, are ignored. An escaping backslash can be used
  to include a white space or a `#` character as part of the pattern. If
  the `PCRE2_EXTENDED_MORE` option is set, the same applies, but in
  addition unescaped space and horizontal tab characters are ignored
  inside a character class."
  
In the code below, `#comment` is a part of the pattern, which does not match, so the output is the same as the input subject.


```r
sub("foo#comment", "", "foo\nbar", perl=TRUE)
```

```
## [1] "foo\nbar"
```

In the code below, `#comment` is ignored, so the pattern matches, and the output deletes foo:


```r
sub("(?x)foo#comment", "", "foo\nbar", perl=TRUE)
```

```
## [1] "\nbar"
```

In the pattern below, the newline is a part of the pattern, which does match, so the output deletes the newline.


```r
sub("foo
", "", "foo\nbar", perl=TRUE)
```

```
## [1] "bar"
```

In the pattern below, the newline is excluded from the pattern, which only matches `foo`, so the output includes a newline:


```r
sub("(?x)foo
", "", "foo\nbar", perl=TRUE)
```

```
## [1] "\nbar"
```

## analysis

A modified version of the base R regex code appears below,


```r
raw.lines <- readLines("~/R/r-svn/src/include/R_ext/Altrep.h")
one.string <- paste(c(raw.lines, ''), collapse = '\n')
no.c.comments <- gsub('(?s)/\\*.*?\\*/', '', one.string, perl = TRUE)
no.cpp.comments <- gsub('(?m)//.*$', '', no.c.comments, perl = TRUE)
no.pre.processor.directives <- gsub('(?m)^\\s*#.*$', '', no.cpp.comments, perl = TRUE)
(match.mat <- regmatches(
  no.pre.processor.directives, 
  gregexec(rx, no.pre.processor.directives, perl = TRUE)
)[[1]])
```

```
##          [,1]                                                                    
##          "\nSEXP\nR_new_altrep(R_altrep_class_t aclass, SEXP data1, SEXP data2);"
## rtype    "SEXP\n"                                                                
## fun_name "R_new_altrep"                                                          
## args     "R_altrep_class_t aclass, SEXP data1, SEXP data2"                       
##          [,2]                                                                                              
##          "\nR_altrep_class_t\nR_make_altstring_class(const char *cname, const char *pname, DllInfo *info);"
## rtype    "R_altrep_class_t\n"                                                                              
## fun_name "R_make_altstring_class"                                                                          
## args     "const char *cname, const char *pname, DllInfo *info"                                             
##          [,3]                                                                                               
##          "\nR_altrep_class_t\nR_make_altinteger_class(const char *cname, const char *pname, DllInfo *info);"
## rtype    "R_altrep_class_t\n"                                                                               
## fun_name "R_make_altinteger_class"                                                                          
## args     "const char *cname, const char *pname, DllInfo *info"                                              
##          [,4]                                                                                            
##          "\nR_altrep_class_t\nR_make_altreal_class(const char *cname, const char *pname, DllInfo *info);"
## rtype    "R_altrep_class_t\n"                                                                            
## fun_name "R_make_altreal_class"                                                                          
## args     "const char *cname, const char *pname, DllInfo *info"                                           
##          [,5]                                                                                               
##          "\nR_altrep_class_t\nR_make_altlogical_class(const char *cname, const char *pname, DllInfo *info);"
## rtype    "R_altrep_class_t\n"                                                                               
## fun_name "R_make_altlogical_class"                                                                          
## args     "const char *cname, const char *pname, DllInfo *info"                                              
##          [,6]                                                                                           
##          "\nR_altrep_class_t\nR_make_altraw_class(const char *cname, const char *pname, DllInfo *info);"
## rtype    "R_altrep_class_t\n"                                                                           
## fun_name "R_make_altraw_class"                                                                          
## args     "const char *cname, const char *pname, DllInfo *info"                                          
##          [,7]                                                                                               
##          "\nR_altrep_class_t\nR_make_altcomplex_class(const char *cname, const char *pname, DllInfo *info);"
## rtype    "R_altrep_class_t\n"                                                                               
## fun_name "R_make_altcomplex_class"                                                                          
## args     "const char *cname, const char *pname, DllInfo *info"                                              
##          [,8]                                                                                            
##          "\nR_altrep_class_t\nR_make_altlist_class(const char *cname, const char *pname, DllInfo *info);"
## rtype    "R_altrep_class_t\n"                                                                            
## fun_name "R_make_altlist_class"                                                                          
## args     "const char *cname, const char *pname, DllInfo *info"                                           
##          [,9]                                                     
##          "\nRboolean R_altrep_inherits(SEXP x, R_altrep_class_t);"
## rtype    "Rboolean "                                              
## fun_name "R_altrep_inherits"                                      
## args     "SEXP x, R_altrep_class_t"
```

```r
match.mat["fun_name",]
```

```
## [1] "R_new_altrep"            "R_make_altstring_class"  "R_make_altinteger_class" "R_make_altreal_class"   
## [5] "R_make_altlogical_class" "R_make_altraw_class"     "R_make_altcomplex_class" "R_make_altlist_class"   
## [9] "R_altrep_inherits"
```

The output above includes all of the capture groups.

### nc port

The code below is a port of the regex code to use my nc package,


```r
pattern.list <- list( 
  "(?xs)",
  "(?!typedef)(?<!\\w)", # please no typedefs
  rtype="\\w+ (?:\\s+ | \\*)+", # return type, words followed by whitespace or stars
  fun_name=nc::alternatives( # function name, assumes no extra whitespace
    "\\w+\\(\\w+\\)", # macro call
    "\\(\\w+\\)",  # in parentheses
    "\\w+"),      # a plain name
  "\\s* \\( ",
  args=".*?", # arguments: non-greedy match inside parentheses, using dotall here
  " \\) \\s*", 
  ## will include R_PRINTF_FORMAT(1,2 but we don't care
  ## finally terminated by semicolon
  ";")
```

The code above defines the regex using a list instead of a long string literal. 
Capture groups are defined using named arguments in R code, instead of parentheses in a long string literal. Some other differences:

* in nc code, there is less need for EXTENDED syntax, since comments can be made in R code instead of in the string literal.
* nc code above used double backslash in regular string literals `"\\"`, whereas base R code used single backslash in a raw string literal `r"{\}"` (which is also possible to use in nc code).
* nc code avoids some parentheses that are present in the base R regex string literal, because each named argument is converted into a capture group.
* `nc::alternatives` is used instead of string literal alternation via `"|"`.


```r
(match.dt <- nc::capture_all_str(
  no.pre.processor.directives,
  pattern.list))
```

```
##                 rtype                fun_name                                                args
##                <char>                  <char>                                              <char>
## 1:             SEXP\n            R_new_altrep     R_altrep_class_t aclass, SEXP data1, SEXP data2
## 2: R_altrep_class_t\n  R_make_altstring_class const char *cname, const char *pname, DllInfo *info
## 3: R_altrep_class_t\n R_make_altinteger_class const char *cname, const char *pname, DllInfo *info
## 4: R_altrep_class_t\n    R_make_altreal_class const char *cname, const char *pname, DllInfo *info
## 5: R_altrep_class_t\n R_make_altlogical_class const char *cname, const char *pname, DllInfo *info
## 6: R_altrep_class_t\n     R_make_altraw_class const char *cname, const char *pname, DllInfo *info
## 7: R_altrep_class_t\n R_make_altcomplex_class const char *cname, const char *pname, DllInfo *info
## 8: R_altrep_class_t\n    R_make_altlist_class const char *cname, const char *pname, DllInfo *info
## 9:          Rboolean        R_altrep_inherits                            SEXP x, R_altrep_class_t
```

```r
identical(match.dt, data.table(t(match.mat[-1,])))
```

```
## [1] TRUE
```

The output above shows that the output of both methods is identical. 

## Conclusion

We have shown how to convert base R regex code, which is defined using
a large string literal, into nc R code, which offers a different
syntax for defining regex.
