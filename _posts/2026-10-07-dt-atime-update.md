---
layout: post
title: data.table asymptotic timings
description: Motivational figures
---



The purpose of this vignette is to update the figures which show the
efficiency of `data.table`, relative to other R packages which provide
similar functionality.
[The previous post](https://tdhock.github.io/blog/2023/dt-atime-figures/)
which compared R functions was run 3 years ago, so we would like to see if there are consistent results using updated software packages.

## package edit fun

To install several old versions of data table in a single modern R session, we need this code, taken from [data.table/.ci/atime/tests.R](https://github.com/Rdatatable/data.table/blob/master/.ci/atime/tests.R).


``` r
edit.data.table = function(old.Package, new.Package, sha, new.pkg.path) {
  pkg_find_replace <- function(glob, FIND, REPLACE) {
    atime::glob_find_replace(file.path(new.pkg.path, glob), FIND, REPLACE)
  }
  Package_regex <- gsub(".", "([_.]?)", old.Package, fixed = TRUE)
  Package_ <- gsub(".", "\\1", old.Package, fixed = TRUE)
  new.Package_ <- paste0(Package_, "\\1", sha)
  pkg_find_replace(
    "DESCRIPTION",
    paste0("Package:\\s+", old.Package),
    paste("Package:", new.Package))
  pkg_find_replace(
    file.path("src", "Makevars.*in"),
    Package_regex,
    new.Package_)
  pkg_find_replace(
    file.path("R", "onLoad.R"),
    Package_regex,
    new.Package_)
  pkg_find_replace(
    file.path("src", "init.c"),
    paste0("R_init_", Package_regex),
    paste0("R_init_", gsub("[.]", "_", new.Package_)))
  # require C<23 for empty prototype declarations to work, #7689
  descfile = file.path(new.pkg.path, "DESCRIPTION")
  desc = as.data.frame(read.dcf(descfile))
  desc$SystemRequirements = paste(
    c(desc$SystemRequirements, "USE_C99"),
    collapse = "; ")
  write.dcf(desc, descfile)
  # allow compilation on new R versions where 'Calloc' is not defined
  pkg_find_replace(
    file.path("src", "*.c"),
    "\\b(Calloc|Free|Realloc)\\b",
    "R_\\1")
  pkg_find_replace(
    "NAMESPACE",
    sprintf('useDynLib\\("?%s"?', Package_regex),
    paste0('useDynLib(', new.Package_))
  pkg_find_replace(
    file.path("src", "Makevars.*in"),
    "@PKG_CFLAGS@", "@PKG_CFLAGS@ -DSTRING_PTR_RO=STRING_PTR_RO")
  backports = c(
    "src/data.table.h" = '
        #include <Rversion.h>
        #if R_VERSION >= R_Version(4, 6, 0)
        // backports.c
        void SETLENGTH(SEXP x, R_xlen_t n);
        R_xlen_t TRUELENGTH(SEXP x);
        void SET_TRUELENGTH(SEXP x, R_xlen_t n);
        void SET_GROWABLE_BIT(SEXP);
        int LEVELS(SEXP);
        int NAMED(SEXP);
        #define REFCNT(x) NAMED(x)
        SEXP ATTRIB(SEXP);
        void SET_ATTRIB(SEXP, SEXP);
        int OBJECT(SEXP);
        void SET_OBJECT(SEXP, int);
        #define isFrame(x) isDataFrame(x)
        #define GetOption(x, none) GetOption1(x)
        #undef findVar // Rf_ mapping remains
        #define findVar(sym, env) R_getVar(sym, env, FALSE)
        #define STRING_PTR(x) ((SEXP *)STRING_PTR_RO(x))
        int IS_S4_OBJECT(SEXP);
        void SET_S4_OBJECT(SEXP);
        void UNSET_S4_OBJECT(SEXP);
        void SET_TYPEOF(SEXP, int);
        #define VECTOR_ELT(x, i) VECTOR_ELT_(x, i)
        SEXP VECTOR_ELT_(SEXP, R_xlen_t);
        #define VECTOR_PTR(x) ((SEXP*)DATAPTR_RO(x))
        #define DATAPTR(x) ((void*)DATAPTR_RO(x))
        #endif
      ',
    "src/backports.c" = '
        #include "data.table.h"
        #if R_VERSION >= R_Version(4, 6, 0)
        #define NAMED_BITS 16
        struct sxpinfo_struct {
          SEXPTYPE type      :  TYPE_BITS; // in Rinternals.h
          unsigned int scalar:  1;
          unsigned int obj   :  1;
          unsigned int alt   :  1;
          unsigned int gp    : 16;
          unsigned int mark  :  1;
          unsigned int debug :  1;
          unsigned int trace :  1;
          unsigned int spare :  1;
          unsigned int gcgen :  1;
          unsigned int gccls :  3;
          unsigned int named : NAMED_BITS;
          unsigned int extra : 32 - NAMED_BITS;
        };
        struct vecsxp_struct {
          R_xlen_t length;
          R_xlen_t truelength;
        };
        typedef struct VECTOR_SEXPREC {
          struct sxpinfo_struct sxpinfo;
          SEXP attrib;
          SEXP gengc_next_node, gengc_prev_node;
          struct vecsxp_struct vecsxp;
        } *VECSEXP;
        void SETLENGTH(SEXP x, R_xlen_t n) {
          ((VECSEXP)x)->vecsxp.length = n;
        }
        R_xlen_t TRUELENGTH(SEXP x) {
          return ((VECSEXP)x)->vecsxp.truelength;
        }
        void SET_TRUELENGTH(SEXP x, R_xlen_t n) {
          ((VECSEXP)x)->vecsxp.truelength = n;
        }
        void SET_GROWABLE_BIT(SEXP x) {
          ((VECSEXP)x)->sxpinfo.gp |= 0x20;
        }
        int LEVELS(SEXP x) {
          return ((VECSEXP)x)->sxpinfo.gp;
        }
        int NAMED(SEXP x) {
          return ((VECSEXP)x)->sxpinfo.named;
        }
        int OBJECT(SEXP x) {
          return ((VECSEXP)x)->sxpinfo.obj;
        }
        void SET_OBJECT(SEXP x, int o) {
          ((VECSEXP)x)->sxpinfo.obj = o;
        }
        SEXP ATTRIB(SEXP x) {
          return ((VECSEXP)x)->attrib;
        }
        void SET_ATTRIB(SEXP x, SEXP att) {
          ((VECSEXP)x)->attrib = att;
        }
        #define S4_OBJECT (1<<4)
        int IS_S4_OBJECT(SEXP x) {
          return ((VECSEXP)x)->sxpinfo.gp & S4_OBJECT;
        }
        void SET_S4_OBJECT(SEXP x) {
          ((VECSEXP)x)->sxpinfo.gp |= S4_OBJECT;
        }
        void UNSET_S4_OBJECT(SEXP x) {
          ((VECSEXP)x)->sxpinfo.gp &= ~S4_OBJECT;
        }
        void SET_TYPEOF(SEXP x, int type) {
          ((VECSEXP)x)->sxpinfo.type = type;
        }
        SEXP VECTOR_ELT_(SEXP x, R_xlen_t i) {
          return ALTREP(x) ? (VECTOR_ELT)(x, i) : ((SEXP*)DATAPTR_RO(x))[i];
        }
        #endif
      ')
  for (n in names(backports)) {
    f = file(file.path(new.pkg.path, n), "a")
    writeLines(backports[[n]], f)
    close(f)
  }
}
```

## fwrite: fast CSV writer

First we set and check multi-threading options, for a fair comparison between all functions (including base R which uses only one thread).


``` r
data.table::setDTthreads(1)
data.table::getDTthreads()
```

```
## [1] 1
```

``` r
options(readr.num_threads=1)
readr::readr_threads()
```

```
## [1] 1
```

``` r
library(ggplot2)
n.rows <- 100
seconds.limit <- 0.1
```

Below we define two versions of data table to test: current release is 1.18.6, and version tested in my previous 2023 post is 1.14.8.


``` r
dt.vers <- c("1.18.6", "1.14.8", installed="")
names(dt.vers) <- ifelse(names(dt.vers)=="", dt.vers, names(dt.vers))
```

Next we define a function which generates a list of R expressions to test (one element for each version of data table).


``` r
dt_exprs <- function(e){
  expr <- substitute(e)
  names(dt.vers) <- paste0(
    format(expr[[2]][[1]]),
    "\n",
    names(dt.vers))
  atime::atime_versions_exprs(
    "~/R/data.table",
    pkg.edit.fun=edit.data.table,
    expr=expr,
    sha.vec=dt.vers)
}
(dt.write.exprs <- dt_exprs({
  data.table::fwrite(input.df, tempfile(), showProgress = FALSE)
}))
```

```
## $`data.table::fwrite\n1.18.6`
## {
##     data.table.1.18.6::fwrite(input.df, tempfile(), showProgress = FALSE)
## }
## 
## $`data.table::fwrite\n1.14.8`
## {
##     data.table.1.14.8::fwrite(input.df, tempfile(), showProgress = FALSE)
## }
## 
## $`data.table::fwrite\ninstalled`
## {
##     data.table::fwrite(input.df, tempfile(), showProgress = FALSE)
## }
```

Now we compute timings of writing some random normal data to CSV.


``` r
if(requireNamespace("arrow")){
  dt.write.exprs$write_csv_arrow <-quote(
    arrow::write_csv_arrow(input.df, tempfile())
  )
}
```

```
## Le chargement a nécessité le package : arrow
```

``` r
atime.write.vary.cols <- atime::atime(
  setup={
    set.seed(1)
    input.vec <- rnorm(n.rows*N)
    input.mat <- matrix(input.vec, n.rows, N)
    input.df <- data.frame(input.mat)
  },
  seconds.limit = seconds.limit,
  expr.list=dt.write.exprs,
  "readr::write_csv"={
    readr::write_csv(input.df, tempfile(), progress = FALSE)
  },
  "utils::write.csv"=utils::write.csv(input.df, tempfile()))
refs.write.vary.cols <- atime::references_best(atime.write.vary.cols)
pred.write.vary.cols <- predict(refs.write.vary.cols)

write.colors <- c(
  "readr::write_csv"="#9970AB",
  "data.table::fwrite\n1.14.8"="#D6604D",
  "data.table::fwrite\n1.18.6"="#E7604D",
  "data.table::fwrite\ninstalled"="#F7604D",
  "write_csv_arrow"="#BF812D", 
  "utils::write.csv"="deepskyblue")
gg.write <- plot(pred.write.vary.cols)+
  theme(text=element_text(size=20))+
  ggtitle(sprintf("Write real numbers to CSV, %d x N", n.rows))+
  scale_x_log10("N = number of columns to write")+
  scale_y_log10("Computation time (seconds)
median line, min/max band
over 10 timings")+
  facet_null()+
  scale_fill_manual(values=write.colors)+
  scale_color_manual(values=write.colors)
```

```
## Scale for x is already present.
## Adding another scale for x, which will replace the existing scale.
```

```
## Scale for y is already present.
## Adding another scale for y, which will replace the existing scale.
```

``` r
gg.write
```

```
## Warning in scale_x_log10("N = number of columns to write"): log-10
## transformation introduced infinite values.
```

![plot of chunk write](/assets/img/2026-10-07-dt-atime-update/write-1.png)

The results above show that fwrite versions 1.18.6 and 1.14.8 are about the same speed.
Not sure why fwrite with no version is slower?

## fread: fast CSV reader


``` r
tfgrid <- function(param, ...)atime::atime_grid(
  setNames(list(c(TRUE,FALSE)), param),
  ..., expr.param.sep="\n")
(expr.list <- c(
  dt_exprs({
    data.table::fread(input.csv, showProgress = FALSE)
  }),
  if(requireNamespace("arrow"))tfgrid(
    "asDF",
    read_csv_arrow={
      ## https://francoismichonneau.net/2022/10/import-big-csv/
      arrow::read_csv_arrow(input.csv, as_data_frame=asDF)
    }),
  tfgrid(
    "lazy",
    "readr::read_csv"={
      readr::read_csv(input.csv, progress = FALSE, show_col_types = FALSE, lazy=lazy)
    })))
```

```
## Le chargement a nécessité le package : arrow
```

```
## $`data.table::fread\n1.18.6`
## {
##     data.table.1.18.6::fread(input.csv, showProgress = FALSE)
## }
## 
## $`data.table::fread\n1.14.8`
## {
##     data.table.1.14.8::fread(input.csv, showProgress = FALSE)
## }
## 
## $`data.table::fread\ninstalled`
## {
##     data.table::fread(input.csv, showProgress = FALSE)
## }
## 
## $`readr::read_csv\nlazy=FALSE`
## {
##     readr::read_csv(input.csv, progress = FALSE, show_col_types = FALSE, 
##         lazy = FALSE)
## }
## 
## $`readr::read_csv\nlazy=TRUE`
## {
##     readr::read_csv(input.csv, progress = FALSE, show_col_types = FALSE, 
##         lazy = TRUE)
## }
```

``` r
atime.read.vary.cols <- atime::atime(
  setup={
    set.seed(1)
    input.vec <- rnorm(n.rows*N)
    input.mat <- matrix(input.vec, n.rows, N)
    input.df <- data.frame(input.mat)
    input.csv <- tempfile()
    data.table::fwrite(input.df, input.csv)
  },
  seconds.limit = seconds.limit,
  expr.list = expr.list,
  "utils::read.csv"=utils::read.csv(input.csv))
refs.read.vary.cols <- atime::references_best(atime.read.vary.cols)
pred.read.vary.cols <- predict(refs.read.vary.cols)

read.colors <- c(
  "readr::read_csv\nlazy=TRUE"="#9970AB",
  "readr::read_csv\nlazy=FALSE"="#99909B",
  "data.table::fread\n1.14.8"="#D6604D",
  "data.table::fread\n1.18.6"="#E7604D",
  "data.table::fread\ninstalled"="#F7604D",
  "read_csv_arrow\nasDF=TRUE"="#BF812D", 
  "read_csv_arrow\nasDF=FALSE"="#9F912D", 
  "utils::read.csv"="deepskyblue")
gg.read <- plot(pred.read.vary.cols)+
  theme(text=element_text(size=20))+
  ggtitle(sprintf("Read real numbers from CSV, %d x N", n.rows))+
  scale_x_log10("N = number of columns to read")+
  scale_y_log10("Computation time (seconds)
median line, min/max band
over 10 timings")+
  facet_null()+
  scale_fill_manual(values=read.colors)+
  scale_color_manual(values=read.colors)
```

```
## Scale for x is already present.
## Adding another scale for x, which will replace the existing scale.
```

```
## Scale for y is already present.
## Adding another scale for y, which will replace the existing scale.
```

``` r
gg.read
```

```
## Warning in scale_x_log10("N = number of columns to read"): log-10
## transformation introduced infinite values.
```

![plot of chunk read](/assets/img/2026-10-07-dt-atime-update/read-1.png)

The result above shows that fread version 1.14.8 is substantially faster than version 1.18.6: I suspect this is a real regression that we should investigate with git bisect and then fix.
Why was this not caught in CI?

Again both are much faster than the un-versioned fread, why?
Looking at the current atime test code, there are two tests for fread:

* `fread(%s) improved in #6107` reads a Date column, N=rows.
* `fread disk overhead improved in #6925` reads 1 row, N times.

There are no test cases with N=columns, we should add this as one!

## cpu and version info


``` r
benchmarkme::get_cpu()
```

```
## Error in `loadNamespace()`:
## ! aucun package nommé 'benchmarkme' n'est trouvé
```

``` r
sessionInfo()
```

```
## R Under development (unstable) (2026-09-16 r90549)
## Platform: x86_64-pc-linux-gnu
## Running under: Ubuntu 22.04.5 LTS
## 
## Matrix products: default
## BLAS:   /usr/lib/x86_64-linux-gnu/blas/libblas.so.3.10.0 
## LAPACK: /usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.10.0  LAPACK version 3.10.0
## 
## locale:
##  [1] LC_CTYPE=fr_FR.UTF-8       LC_NUMERIC=C              
##  [3] LC_TIME=fr_FR.UTF-8        LC_COLLATE=fr_FR.UTF-8    
##  [5] LC_MONETARY=fr_FR.UTF-8    LC_MESSAGES=fr_FR.UTF-8   
##  [7] LC_PAPER=fr_FR.UTF-8       LC_NAME=C                 
##  [9] LC_ADDRESS=C               LC_TELEPHONE=C            
## [11] LC_MEASUREMENT=fr_FR.UTF-8 LC_IDENTIFICATION=C       
## 
## time zone: America/Toronto
## tzcode source: system (glibc)
## 
## attached base packages:
## [1] stats     graphics  utils     datasets  grDevices methods   base     
## 
## other attached packages:
## [1] atime_2026.9.17 ggplot2_4.0.3  
## 
## loaded via a namespace (and not attached):
##  [1] bit_4.6.0                  gtable_0.3.6              
##  [3] dplyr_1.2.1                compiler_4.7.0            
##  [5] crayon_1.5.3               Rcpp_1.1.2                
##  [7] tidyselect_1.2.1           scales_1.4.0              
##  [9] directlabels_2026.8.27     lattice_0.23-1            
## [11] readr_2.2.0                R6_2.6.1                  
## [13] generics_0.1.4             knitr_1.52                
## [15] tibble_3.3.1               pillar_1.11.1             
## [17] RColorBrewer_1.1-3         tzdb_0.5.0                
## [19] rlang_1.3.0                xfun_0.61                 
## [21] S7_0.2.2                   otel_0.2.0                
## [23] bit64_4.8.6                cli_3.6.6                 
## [25] withr_3.0.3                magrittr_2.0.5            
## [27] grid_4.7.0                 vroom_1.7.1               
## [29] hms_1.1.4                  lifecycle_1.0.5           
## [31] data.table.1.18.6_1.18.6.1 vctrs_0.7.3               
## [33] bench_1.1.4                evaluate_1.0.5            
## [35] glue_1.8.1                 data.table_1.18.6.1       
## [37] farver_2.1.2               data.table.1.14.8_1.14.8  
## [39] profmem_0.7.0              tools_4.7.0               
## [41] pkgconfig_2.0.3
```
