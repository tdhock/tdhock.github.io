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
dt.vers <- list("1.18.6", "1.14.8")
```

Next we define a function which generates a list of R expressions to test (one element for each version of data table).


``` r
dt_exprs <- function(name, expr){
  dt.exprs <- do.call(atime::atime_versions_exprs, c(list(
    "~/R/data.table",
    pkg.edit.fun=edit.data.table,
    expr=substitute(expr),
    setNames(dt.vers, dt.vers))))
  names(dt.exprs) <- paste0(name, "\n", names(dt.exprs))
  dt.exprs
}
(dt.write.exprs <- dt_exprs(
  "data.table::fwrite",
  data.table::fwrite(input.df, tempfile(), showProgress = FALSE)))
```

```
## $`data.table::fwrite\n1.18.6`
## data.table.1.18.6::fwrite(input.df, tempfile(), showProgress = FALSE)
## 
## $`data.table::fwrite\n1.14.8`
## data.table.1.14.8::fwrite(input.df, tempfile(), showProgress = FALSE)
```

Now we compute timings of writing some random normal data to CSV.


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
  "data.table::fwrite"={
    data.table::fwrite(input.df, tempfile(), showProgress = FALSE)
  },
  "write_csv_arrow"={
    arrow::write_csv_arrow(input.df, tempfile())
  },
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
  "data.table::fwrite"="#F7604D",
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
## Scale for y is already present.
## Adding another scale for y, which will replace the existing scale.
```

``` r
gg.write
```

```
## Warning in scale_x_log10("N = number of columns to write"): log-10 transformation introduced infinite
## values.
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
  dt_exprs(
    "data.table::fread",
    data.table::fread(input.csv, showProgress = FALSE)),
  tfgrid(
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
## $`data.table::fread\n1.18.6`
## data.table.1.18.6::fread(input.csv, showProgress = FALSE)
## 
## $`data.table::fread\n1.14.8`
## data.table.1.14.8::fread(input.csv, showProgress = FALSE)
## 
## $`read_csv_arrow\nasDF=FALSE`
## {
##     arrow::read_csv_arrow(input.csv, as_data_frame = FALSE)
## }
## 
## $`read_csv_arrow\nasDF=TRUE`
## {
##     arrow::read_csv_arrow(input.csv, as_data_frame = TRUE)
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
    fwrite(input.df, input.csv)
  },
  "data.table::fread"={
    data.table::fread(input.csv, showProgress = FALSE)
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
  "data.table::fread"="#F7604D",
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
## Scale for y is already present.
## Adding another scale for y, which will replace the existing scale.
```

``` r
gg.read
```

```
## Warning in scale_x_log10("N = number of columns to read"): log-10 transformation introduced infinite
## values.
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
## $vendor_id
## [1] "GenuineIntel"
## 
## $model_name
## [1] "Intel(R) Core(TM) Ultra 5 125U"
## 
## $no_of_cores
## [1] 14
```

``` r
sessionInfo()
```

```
## R Under development (unstable) (2026-07-28 r90311)
## Platform: x86_64-pc-linux-gnu
## Running under: Ubuntu 24.04.5 LTS
## 
## Matrix products: default
## BLAS:   /usr/lib/x86_64-linux-gnu/blas/libblas.so.3.12.0 
## LAPACK: /usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.12.0  LAPACK version 3.12.0
## 
## locale:
##  [1] LC_CTYPE=en_US.UTF-8       LC_NUMERIC=C               LC_TIME=fr_FR.UTF-8       
##  [4] LC_COLLATE=en_US.UTF-8     LC_MONETARY=fr_FR.UTF-8    LC_MESSAGES=en_US.UTF-8   
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
## [1] atime_2026.10.7 testthat_3.3.2  ggplot2_4.0.3  
## 
## loaded via a namespace (and not attached):
##  [1] benchmarkmeData_2.0.0      gtable_0.3.6               xfun_0.61                 
##  [4] devtools_2.5.2             bench_1.1.4                lattice_0.23-1            
##  [7] tzdb_0.5.0                 vctrs_0.7.3                tools_4.7.0               
## [10] generics_0.1.4             parallel_4.7.0             tibble_3.3.1              
## [13] pkgconfig_2.0.3            data.table.1.14.8_1.14.8   Matrix_1.7-6              
## [16] data.table_1.18.6.1        RColorBrewer_1.1-3         S7_0.2.2                  
## [19] desc_1.4.3                 assertthat_0.2.1           lifecycle_1.0.5           
## [22] stringr_1.6.0              compiler_4.7.0             farver_2.1.2              
## [25] credentials_2.0.3          brio_1.1.5                 codetools_0.2-20          
## [28] sys_3.4.3                  usethis_3.2.2              profmem_0.7.0             
## [31] pillar_1.11.1              crayon_1.5.3               ellipsis_0.3.3            
## [34] openssl_2.4.2              cachem_1.1.0               sessioninfo_1.2.4         
## [37] iterators_1.0.14           foreach_1.5.2              tidyselect_1.2.1          
## [40] stringi_1.8.9              dplyr_1.2.1                purrr_1.2.2               
## [43] arrow_25.0.1               rprojroot_2.1.1            fastmap_1.2.0             
## [46] grid_4.7.0                 cli_3.6.6                  magrittr_2.0.5            
## [49] pkgbuild_1.4.8             readr_2.2.0                withr_3.0.3               
## [52] scales_1.4.0               bit64_4.8.6                httr_1.4.9                
## [55] data.table.1.18.6_1.18.6.1 bit_4.6.0                  otel_0.2.0                
## [58] benchmarkme_1.0.8          askpass_1.2.1              hms_1.1.4                 
## [61] evaluate_1.0.5             memoise_2.0.1              knitr_1.52                
## [64] doParallel_1.0.17          rlang_1.3.0                gert_2.4.1                
## [67] Rcpp_1.1.2                 glue_1.8.1                 directlabels_2026.8.28    
## [70] pkgload_1.5.3              rstudioapi_0.19.0          vroom_1.7.1               
## [73] R6_2.6.1                   fs_2.1.0
```
