---
layout: post
title: Segfault using R arrow
description: Reproducing and fixing an error
---

This post is a very long, detailed explanation of the steps I took to
figure out how to install R arrow on an old Mac laptop.

In `example(capture_first_glob,package="nc")` there is some code which
uses `arrow::write_dataset`, that gives a segmentation fault using
R-4.3.0 built using GCC 13.1,

```
(base) tdhock@tdhock-MacBook:~$ bin/gcc --version
gcc (GCC) 13.1.0
Copyright © 2023 Free Software Foundation, Inc.
Ce logiciel est un logiciel libre; voir les sources pour les conditions de copie.  Il n'y a
AUCUNE GARANTIE, pas même pour la COMMERCIALISATION ni L'ADÉQUATION À UNE TÂCHE PARTICULIÈRE.

(base) tdhock@tdhock-MacBook:~$ bin/R --version
R version 4.3.0 (2023-04-21) -- "Already Tomorrow"
Copyright (C) 2023 The R Foundation for Statistical Computing
Platform: x86_64-pc-linux-gnu (64-bit)

R is free software and comes with ABSOLUTELY NO WARRANTY.
You are welcome to redistribute it under the terms of the
GNU General Public License versions 2 or 3.
For more information about these matters see
https://www.gnu.org/licenses/.

(base) tdhock@tdhock-MacBook:~$ bin/R --vanilla < R/arrow-crash.R

R version 4.3.0 (2023-04-21) -- "Already Tomorrow"
Copyright (C) 2023 The R Foundation for Statistical Computing
Platform: x86_64-pc-linux-gnu (64-bit)

R est un logiciel libre livré sans AUCUNE GARANTIE.
Vous pouvez le redistribuer sous certaines conditions.
Tapez 'license()' ou 'licence()' pour plus de détails.

R est un projet collaboratif avec de nombreux contributeurs.
Tapez 'contributors()' pour plus d'information et
'citation()' pour la façon de le citer dans les publications.

Tapez 'demo()' pour des démonstrations, 'help()' pour l'aide
en ligne ou 'help.start()' pour obtenir l'aide au format HTML.
Tapez 'q()' pour quitter R.

> library(arrow)

Attachement du package : ‘arrow’

L'objet suivant est masqué depuis ‘package:utils’:

    timestamp

> sessionInfo()
R version 4.3.0 (2023-04-21)
Platform: x86_64-pc-linux-gnu (64-bit)
Running under: Ubuntu 22.04.2 LTS

Matrix products: default
BLAS:   /usr/lib/x86_64-linux-gnu/blas/libblas.so.3.10.0 
LAPACK: /usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.10.0

locale:
 [1] LC_CTYPE=fr_FR.UTF-8       LC_NUMERIC=C              
 [3] LC_TIME=fr_FR.UTF-8        LC_COLLATE=fr_FR.UTF-8    
 [5] LC_MONETARY=fr_FR.UTF-8    LC_MESSAGES=fr_FR.UTF-8   
 [7] LC_PAPER=fr_FR.UTF-8       LC_NAME=C                 
 [9] LC_ADDRESS=C               LC_TELEPHONE=C            
[11] LC_MEASUREMENT=fr_FR.UTF-8 LC_IDENTIFICATION=C       

time zone: America/Phoenix
tzcode source: system (glibc)

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
[1] arrow_11.0.0.3

loaded via a namespace (and not attached):
 [1] tidyselect_1.2.0 bit_4.0.5        compiler_4.3.0   magrittr_2.0.3  
 [5] assertthat_0.2.1 R6_2.5.1         cli_3.6.1        glue_1.6.2      
 [9] bit64_4.0.5      vctrs_0.6.2      lifecycle_1.0.3  rlang_1.1.1     
[13] purrr_1.0.1     
> one_level_tree <- tempfile()
> write_dataset(mtcars, one_level_tree, partitioning = "cyl")

 *** caught illegal operation ***
address 0x7f976687f2c7, cause 'illegal operand'

Traceback:
 1: ExecPlan_Write(self, node, prepare_key_value_metadata(node$final_metadata()),     ...)
 2: plan$Write(final_node, options, path_and_fs$fs, path_and_fs$path,     partitioning, basename_template, existing_data_behavior,     max_partitions, max_open_files, max_rows_per_file, min_rows_per_group,     max_rows_per_group)
 3: write_dataset(mtcars, one_level_tree, partitioning = "cyl")
An irrecoverable exception occurred. R is aborting now ...
Instruction non permise (core dumped)
```

Below we see that running the same code under valgrind works fine,

```
(base) tdhock@tdhock-MacBook:~$ bin/R -d valgrind --vanilla < R/arrow-crash.R
==95898== Memcheck, a memory error detector
==95898== Copyright (C) 2002-2022, and GNU GPL'd, by Julian Seward et al.
==95898== Using Valgrind-3.20.0 and LibVEX; rerun with -h for copyright info
==95898== Command: /home/tdhock/lib/R/bin/exec/R --vanilla
==95898== 

R version 4.3.0 (2023-04-21) -- "Already Tomorrow"
Copyright (C) 2023 The R Foundation for Statistical Computing
Platform: x86_64-pc-linux-gnu (64-bit)

R est un logiciel libre livré sans AUCUNE GARANTIE.
Vous pouvez le redistribuer sous certaines conditions.
Tapez 'license()' ou 'licence()' pour plus de détails.

R est un projet collaboratif avec de nombreux contributeurs.
Tapez 'contributors()' pour plus d'information et
'citation()' pour la façon de le citer dans les publications.

Tapez 'demo()' pour des démonstrations, 'help()' pour l'aide
en ligne ou 'help.start()' pour obtenir l'aide au format HTML.
Tapez 'q()' pour quitter R.

> library(arrow)

Attachement du package : ‘arrow’

L'objet suivant est masqué depuis ‘package:utils’:

    timestamp

> sessionInfo()
R version 4.3.0 (2023-04-21)
Platform: x86_64-pc-linux-gnu (64-bit)
Running under: Ubuntu 22.04.2 LTS

Matrix products: default
BLAS:   /usr/lib/x86_64-linux-gnu/blas/libblas.so.3.10.0 
LAPACK: /usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.10.0

locale:
 [1] LC_CTYPE=fr_FR.UTF-8       LC_NUMERIC=C              
 [3] LC_TIME=fr_FR.UTF-8        LC_COLLATE=fr_FR.UTF-8    
 [5] LC_MONETARY=fr_FR.UTF-8    LC_MESSAGES=fr_FR.UTF-8   
 [7] LC_PAPER=fr_FR.UTF-8       LC_NAME=C                 
 [9] LC_ADDRESS=C               LC_TELEPHONE=C            
[11] LC_MEASUREMENT=fr_FR.UTF-8 LC_IDENTIFICATION=C       

time zone: America/Phoenix
tzcode source: system (glibc)

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
[1] arrow_11.0.0.3

loaded via a namespace (and not attached):
 [1] tidyselect_1.2.0 bit_4.0.5        compiler_4.3.0   magrittr_2.0.3  
 [5] assertthat_0.2.1 R6_2.5.1         cli_3.6.1        glue_1.6.2      
 [9] bit64_4.0.5      vctrs_0.6.2      lifecycle_1.0.3  rlang_1.1.1     
[13] purrr_1.0.1     
> one_level_tree <- tempfile()
> write_dataset(mtcars, one_level_tree, partitioning = "cyl")
> 
==95898== 
==95898== HEAP SUMMARY:
==95898==     in use at exit: 125,892,927 bytes in 25,752 blocks
==95898==   total heap usage: 124,469 allocs, 98,717 frees, 241,576,498 bytes allocated
==95898== 
==95898== LEAK SUMMARY:
==95898==    definitely lost: 0 bytes in 0 blocks
==95898==    indirectly lost: 0 bytes in 0 blocks
==95898==      possibly lost: 12,768 bytes in 8 blocks
==95898==    still reachable: 125,880,159 bytes in 25,744 blocks
==95898==                       of which reachable via heuristic:
==95898==                         newarray           : 4,264 bytes in 1 blocks
==95898==         suppressed: 0 bytes in 0 blocks
==95898== Rerun with --leak-check=full to see details of leaked memory
==95898== 
==95898== For lists of detected and suppressed errors, rerun with: -s
==95898== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)
```

To get the above, both R and gcc were compiled and installed under my
home directory. Does the same happen using system R and gcc?


```

R version 4.1.2 (2021-11-01) -- "Bird Hippie"
Copyright (C) 2021 The R Foundation for Statistical Computing
Platform: x86_64-pc-linux-gnu (64-bit)

R est un logiciel libre livré sans AUCUNE GARANTIE.
Vous pouvez le redistribuer sous certaines conditions.
Tapez 'license()' ou 'licence()' pour plus de détails.

R est un projet collaboratif avec de nombreux contributeurs.
Tapez 'contributors()' pour plus d'information et
'citation()' pour la façon de le citer dans les publications.

Tapez 'demo()' pour des démonstrations, 'help()' pour l'aide
en ligne ou 'help.start()' pour obtenir l'aide au format HTML.
Tapez 'q()' pour quitter R.

Le chargement a nécessité le package : grDevices
> setwd('~')
> install.packages("arrow")
Installation du package dans ‘/usr/local/lib/R/site-library’
(car ‘lib’ n'est pas spécifié)
Avis dans install.packages("arrow") :
  'lib = "/usr/local/lib/R/site-library"' is not writable
Voulez-vous plutôt utiliser une bibliothèque personnelle ? (oui/Non/annuler) oui
Would you like to create a personal library
‘~/R/x86_64-pc-linux-gnu-library/4.1’
to install packages into? (oui/Non/annuler) oui
essai de l'URL 'http://cloud.r-project.org/src/contrib/arrow_11.0.0.3.tar.gz'
Content type 'application/x-gzip' length 3921484 bytes (3.7 MB)
==================================================
downloaded 3.7 MB

Le chargement a nécessité le package : grDevices
* installing *source* package ‘arrow’ ...
** package ‘arrow’ successfully unpacked and MD5 sums checked
** using staged installation
Le chargement a nécessité le package : grDevices
*** Found libcurl and openssl >= 3.0.0
PKG_CFLAGS=-DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS
PKG_LIBS=-L/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/lib -L/usr/lib/lib/x86_64-linux-gnu -larrow_dataset -lparquet -larrow -larrow_bundled_dependencies -lcurl -lssl -lcrypto  
** libs
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c RTasks.cpp -o RTasks.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c altrep.cpp -o altrep.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c array.cpp -o array.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c array_to_vector.cpp -o array_to_vector.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c arraydata.cpp -o arraydata.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c arrowExports.cpp -o arrowExports.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c bridge.cpp -o bridge.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c buffer.cpp -o buffer.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c chunkedarray.cpp -o chunkedarray.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c compression.cpp -o compression.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c compute-exec.cpp -o compute-exec.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c compute.cpp -o compute.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c config.cpp -o config.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c csv.cpp -o csv.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c dataset.cpp -o dataset.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c datatype.cpp -o datatype.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c expression.cpp -o expression.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c extension-impl.cpp -o extension-impl.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c feather.cpp -o feather.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c field.cpp -o field.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c filesystem.cpp -o filesystem.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c io.cpp -o io.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c json.cpp -o json.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c memorypool.cpp -o memorypool.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c message.cpp -o message.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c parquet.cpp -o parquet.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c r_to_arrow.cpp -o r_to_arrow.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c recordbatch.cpp -o recordbatch.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c recordbatchreader.cpp -o recordbatchreader.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c recordbatchwriter.cpp -o recordbatchwriter.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c safe-call-into-r-impl.cpp -o safe-call-into-r-impl.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c scalar.cpp -o scalar.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c schema.cpp -o schema.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c symbols.cpp -o symbols.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c table.cpp -o table.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c threadpool.cpp -o threadpool.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c type_infer.cpp -o type_infer.o
g++ -std=gnu++17 -shared -L/usr/lib/R/lib -Wl,-Bsymbolic-functions -flto=auto -ffat-lto-objects -flto=auto -Wl,-z,relro -o arrow.so RTasks.o altrep.o array.o array_to_vector.o arraydata.o arrowExports.o bridge.o buffer.o chunkedarray.o compression.o compute-exec.o compute.o config.o csv.o dataset.o datatype.o expression.o extension-impl.o feather.o field.o filesystem.o io.o json.o memorypool.o message.o parquet.o r_to_arrow.o recordbatch.o recordbatchreader.o recordbatchwriter.o safe-call-into-r-impl.o scalar.o schema.o symbols.o table.o threadpool.o type_infer.o -L/tmp/RtmpmFXUDr/R.INSTALL174c3623ea39d/arrow/libarrow/arrow-11.0.0.3/lib -L/usr/lib/lib/x86_64-linux-gnu -larrow_dataset -lparquet -larrow -larrow_bundled_dependencies -lcurl -lssl -lcrypto -L/usr/lib/R/lib -lR
installing to /home/tdhock/R/x86_64-pc-linux-gnu-library/4.1/00LOCK-arrow/00new/arrow/libs
** R
** inst
** byte-compile and prepare package for lazy loading
Le chargement a nécessité le package : grDevices
** help
*** installing help indices
** building package indices
Le chargement a nécessité le package : grDevices
** testing if installed package can be loaded from temporary location
Le chargement a nécessité le package : grDevices
** checking absolute paths in shared objects and dynamic libraries
** testing if installed package can be loaded from final location
Le chargement a nécessité le package : grDevices
** testing if installed package keeps a record of temporary installation path
* DONE (arrow)

The downloaded source packages are in
	‘/tmp/RtmpWUYA5p/downloaded_packages’
> example("write_dataset",package="arrow")

Attachement du package : ‘arrow’

L'objet suivant est masqué depuis ‘package:utils’:

    timestamp


wrt_dt> ## Don't show: 
wrt_dt> if (arrow_with_dataset() & arrow_with_parquet() & requireNamespace("dplyr", quietly = TRUE)) (if (getRversion() >= "3.4") withAutoprint else force)({ # examplesIf
wrt_dt+ ## End(Don't show)
wrt_dt+ # You can write datasets partitioned by the values in a column (here: "cyl").
wrt_dt+ # This creates a structure of the form cyl=X/part-Z.parquet.
wrt_dt+ one_level_tree <- tempfile()
wrt_dt+ write_dataset(mtcars, one_level_tree, partitioning = "cyl")
wrt_dt+ list.files(one_level_tree, recursive = TRUE)
wrt_dt+ 
wrt_dt+ # You can also partition by the values in multiple columns
wrt_dt+ # (here: "cyl" and "gear").
wrt_dt+ # This creates a structure of the form cyl=X/gear=Y/part-Z.parquet.
wrt_dt+ two_levels_tree <- tempfile()
wrt_dt+ write_dataset(mtcars, two_levels_tree, partitioning = c("cyl", "gear"))
wrt_dt+ list.files(two_levels_tree, recursive = TRUE)
wrt_dt+ 
wrt_dt+ # In the two previous examples we would have:
wrt_dt+ # X = {4,6,8}, the number of cylinders.
wrt_dt+ # Y = {3,4,5}, the number of forward gears.
wrt_dt+ # Z = {0,1,2}, the number of saved parts, starting from 0.
wrt_dt+ 
wrt_dt+ # You can obtain the same result as as the previous examples using arrow with
wrt_dt+ # a dplyr pipeline. This will be the same as two_levels_tree above, but the
wrt_dt+ # output directory will be different.
wrt_dt+ library(dplyr)
wrt_dt+ two_levels_tree_2 <- tempfile()
wrt_dt+ mtcars %>%
wrt_dt+   group_by(cyl, gear) %>%
wrt_dt+   write_dataset(two_levels_tree_2)
wrt_dt+ list.files(two_levels_tree_2, recursive = TRUE)
wrt_dt+ 
wrt_dt+ # And you can also turn off the Hive-style directory naming where the column
wrt_dt+ # name is included with the values by using `hive_style = FALSE`.
wrt_dt+ 
wrt_dt+ # Write a structure X/Y/part-Z.parquet.
wrt_dt+ two_levels_tree_no_hive <- tempfile()
wrt_dt+ mtcars %>%
wrt_dt+   group_by(cyl, gear) %>%
wrt_dt+   write_dataset(two_levels_tree_no_hive, hive_style = FALSE)
wrt_dt+ list.files(two_levels_tree_no_hive, recursive = TRUE)
wrt_dt+ ## Don't show: 
wrt_dt+ }) # examplesIf
> one_level_tree <- tempfile()
> write_dataset(mtcars, one_level_tree, partitioning = "cyl")

 *** caught illegal operation ***
address 0x7f163eef4027, cause 'illegal operand'

Traceback:
 1: ExecPlan_Write(self, node, prepare_key_value_metadata(node$final_metadata()),     ...)
 2: plan$Write(final_node, options, path_and_fs$fs, path_and_fs$path,     partitioning, basename_template, existing_data_behavior,     max_partitions, max_open_files, max_rows_per_file, min_rows_per_group,     max_rows_per_group)
 3: write_dataset(mtcars, one_level_tree, partitioning = "cyl")
 4: eval(ei, envir)
 5: eval(ei, envir)
 6: withVisible(eval(ei, envir))
 7: source(exprs = exprs, local = local, print.eval = print., echo = echo,     max.deparse.length = max.deparse.length, width.cutoff = width.cutoff,     deparseCtrl = deparseCtrl, ...)
 8: (if (getRversion() >= "3.4") withAutoprint else force)({    one_level_tree <- tempfile()    write_dataset(mtcars, one_level_tree, partitioning = "cyl")    list.files(one_level_tree, recursive = TRUE)    two_levels_tree <- tempfile()    write_dataset(mtcars, two_levels_tree, partitioning = c("cyl",         "gear"))    list.files(two_levels_tree, recursive = TRUE)    library(dplyr)    two_levels_tree_2 <- tempfile()    mtcars %>% group_by(cyl, gear) %>% write_dataset(two_levels_tree_2)    list.files(two_levels_tree_2, recursive = TRUE)    two_levels_tree_no_hive <- tempfile()    mtcars %>% group_by(cyl, gear) %>% write_dataset(two_levels_tree_no_hive,         hive_style = FALSE)    list.files(two_levels_tree_no_hive, recursive = TRUE)})
 9: eval(ei, envir)
10: eval(ei, envir)
11: withVisible(eval(ei, envir))
12: source(tf, local, echo = echo, prompt.echo = paste0(prompt.prefix,     getOption("prompt")), continue.echo = paste0(prompt.prefix,     getOption("continue")), verbose = verbose, max.deparse.length = Inf,     encoding = "UTF-8", skip.echo = skips, keep.source = TRUE)
13: example("write_dataset", package = "arrow")

Possible actions:
1: abort (with core dump, if enabled)
2: normal R exit
3: exit R without saving workspace
4: exit R saving workspace
Selection: 1
R is aborting now ...

Process R instruction non permise (core dumped) at Mon May  1 21:26:50 2023
```

Somehow the code above got past the first `write_dataset`, without a
segfault, how?

Below we see the same result (segfault without valgrind, ok with
valgrind) using the system version of R,

```
(base) tdhock@tdhock-MacBook:~$ R --vanilla < R/arrow-crash.R

R version 4.1.2 (2021-11-01) -- "Bird Hippie"
Copyright (C) 2021 The R Foundation for Statistical Computing
Platform: x86_64-pc-linux-gnu (64-bit)

R est un logiciel libre livré sans AUCUNE GARANTIE.
Vous pouvez le redistribuer sous certaines conditions.
Tapez 'license()' ou 'licence()' pour plus de détails.

R est un projet collaboratif avec de nombreux contributeurs.
Tapez 'contributors()' pour plus d'information et
'citation()' pour la façon de le citer dans les publications.

Tapez 'demo()' pour des démonstrations, 'help()' pour l'aide
en ligne ou 'help.start()' pour obtenir l'aide au format HTML.
Tapez 'q()' pour quitter R.

> library(arrow)

Attachement du package : ‘arrow’

L'objet suivant est masqué depuis ‘package:utils’:

    timestamp

> sessionInfo()
R version 4.1.2 (2021-11-01)
Platform: x86_64-pc-linux-gnu (64-bit)
Running under: Ubuntu 22.04.2 LTS

Matrix products: default
BLAS:   /usr/lib/x86_64-linux-gnu/blas/libblas.so.3.10.0
LAPACK: /usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.10.0

locale:
 [1] LC_CTYPE=fr_FR.UTF-8       LC_NUMERIC=C              
 [3] LC_TIME=fr_FR.UTF-8        LC_COLLATE=fr_FR.UTF-8    
 [5] LC_MONETARY=fr_FR.UTF-8    LC_MESSAGES=fr_FR.UTF-8   
 [7] LC_PAPER=fr_FR.UTF-8       LC_NAME=C                 
 [9] LC_ADDRESS=C               LC_TELEPHONE=C            
[11] LC_MEASUREMENT=fr_FR.UTF-8 LC_IDENTIFICATION=C       

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
[1] arrow_11.0.0.3

loaded via a namespace (and not attached):
 [1] tidyselect_1.1.2 bit_4.0.4        compiler_4.1.2   magrittr_2.0.2  
 [5] assertthat_0.2.1 R6_2.5.1         cli_3.2.0        glue_1.6.1      
 [9] bit64_4.0.5      vctrs_0.3.8      rlang_1.0.1      purrr_0.3.4     
> one_level_tree <- tempfile()
> write_dataset(mtcars, one_level_tree, partitioning = "cyl")

 *** caught illegal operation ***
address 0x7fb67b3ea027, cause 'illegal operand'

Traceback:
 1: ExecPlan_Write(self, node, prepare_key_value_metadata(node$final_metadata()),     ...)
 2: plan$Write(final_node, options, path_and_fs$fs, path_and_fs$path,     partitioning, basename_template, existing_data_behavior,     max_partitions, max_open_files, max_rows_per_file, min_rows_per_group,     max_rows_per_group)
 3: write_dataset(mtcars, one_level_tree, partitioning = "cyl")
An irrecoverable exception occurred. R is aborting now ...
Instruction non permise (core dumped)
(base) tdhock@tdhock-MacBook:~$ R -d valgrind --vanilla < R/arrow-crash.R
==97829== Memcheck, a memory error detector
==97829== Copyright (C) 2002-2022, and GNU GPL'd, by Julian Seward et al.
==97829== Using Valgrind-3.20.0 and LibVEX; rerun with -h for copyright info
==97829== Command: /usr/lib/R/bin/exec/R --vanilla
==97829== 

R version 4.1.2 (2021-11-01) -- "Bird Hippie"
Copyright (C) 2021 The R Foundation for Statistical Computing
Platform: x86_64-pc-linux-gnu (64-bit)

R est un logiciel libre livré sans AUCUNE GARANTIE.
Vous pouvez le redistribuer sous certaines conditions.
Tapez 'license()' ou 'licence()' pour plus de détails.

R est un projet collaboratif avec de nombreux contributeurs.
Tapez 'contributors()' pour plus d'information et
'citation()' pour la façon de le citer dans les publications.

Tapez 'demo()' pour des démonstrations, 'help()' pour l'aide
en ligne ou 'help.start()' pour obtenir l'aide au format HTML.
Tapez 'q()' pour quitter R.

> library(arrow)

Attachement du package : ‘arrow’

L'objet suivant est masqué depuis ‘package:utils’:

    timestamp

> sessionInfo()
R version 4.1.2 (2021-11-01)
Platform: x86_64-pc-linux-gnu (64-bit)
Running under: Ubuntu 22.04.2 LTS

Matrix products: default
BLAS:   /usr/lib/x86_64-linux-gnu/blas/libblas.so.3.10.0
LAPACK: /usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.10.0

locale:
 [1] LC_CTYPE=fr_FR.UTF-8       LC_NUMERIC=C              
 [3] LC_TIME=fr_FR.UTF-8        LC_COLLATE=fr_FR.UTF-8    
 [5] LC_MONETARY=fr_FR.UTF-8    LC_MESSAGES=fr_FR.UTF-8   
 [7] LC_PAPER=fr_FR.UTF-8       LC_NAME=C                 
 [9] LC_ADDRESS=C               LC_TELEPHONE=C            
[11] LC_MEASUREMENT=fr_FR.UTF-8 LC_IDENTIFICATION=C       

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
[1] arrow_11.0.0.3

loaded via a namespace (and not attached):
 [1] tidyselect_1.1.2 bit_4.0.4        compiler_4.1.2   magrittr_2.0.2  
 [5] assertthat_0.2.1 R6_2.5.1         cli_3.2.0        glue_1.6.1      
 [9] bit64_4.0.5      vctrs_0.3.8      rlang_1.0.1      purrr_0.3.4     
> one_level_tree <- tempfile()
> write_dataset(mtcars, one_level_tree, partitioning = "cyl")
> 
==97829== 
==97829== HEAP SUMMARY:
==97829==     in use at exit: 112,522,453 bytes in 23,761 blocks
==97829==   total heap usage: 135,614 allocs, 111,853 frees, 259,936,158 bytes allocated
==97829== 
==97829== LEAK SUMMARY:
==97829==    definitely lost: 0 bytes in 0 blocks
==97829==    indirectly lost: 0 bytes in 0 blocks
==97829==      possibly lost: 12,752 bytes in 8 blocks
==97829==    still reachable: 112,509,701 bytes in 23,753 blocks
==97829==                       of which reachable via heuristic:
==97829==                         newarray           : 4,264 bytes in 1 blocks
==97829==         suppressed: 0 bytes in 0 blocks
==97829== Rerun with --leak-check=full to see details of leaked memory
==97829== 
==97829== For lists of detected and suppressed errors, rerun with: -s
==97829== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)
```

I found an [issue](https://github.com/apache/arrow/issues/34689)
similar to what I describe above. They have the same version of arrow
(11.0.0.3), which suggests this may only happen with a specific
version. Below we try with version 10, and get the same result.

```
(base) tdhock@tdhock-MacBook:~$ R CMD INSTALL ~/Downloads/arrow_10.0.0.tar.gz 
Le chargement a nécessité le package : grDevices
* installing to library ‘/home/tdhock/R/x86_64-pc-linux-gnu-library/4.1’
* installing *source* package ‘arrow’ ...
** package ‘arrow’ successfully unpacked and MD5 sums checked
** using staged installation
Le chargement a nécessité le package : grDevices
*** Found libcurl and openssl >= 3.0.0
PKG_CFLAGS=-I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS
PKG_LIBS=-L/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/lib -larrow_dataset -lparquet -L/arrow/r/libarrow/dist/lib -larrow -larrow_bundled_dependencies -larrow -larrow_bundled_dependencies -larrow_dataset -lparquet -lssl -lcrypto -lcurl -lssl -lcrypto -lcurl
** libs
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c RTasks.cpp -o RTasks.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c altrep.cpp -o altrep.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c array.cpp -o array.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c array_to_vector.cpp -o array_to_vector.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c arraydata.cpp -o arraydata.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c arrowExports.cpp -o arrowExports.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c bridge.cpp -o bridge.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c buffer.cpp -o buffer.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c chunkedarray.cpp -o chunkedarray.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c compression.cpp -o compression.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c compute-exec.cpp -o compute-exec.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c compute.cpp -o compute.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c config.cpp -o config.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c csv.cpp -o csv.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c dataset.cpp -o dataset.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c datatype.cpp -o datatype.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c expression.cpp -o expression.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c extension-impl.cpp -o extension-impl.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c feather.cpp -o feather.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c field.cpp -o field.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c filesystem.cpp -o filesystem.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c imports.cpp -o imports.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c io.cpp -o io.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c json.cpp -o json.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c memorypool.cpp -o memorypool.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c message.cpp -o message.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c parquet.cpp -o parquet.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c r_to_arrow.cpp -o r_to_arrow.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c recordbatch.cpp -o recordbatch.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c recordbatchreader.cpp -o recordbatchreader.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c recordbatchwriter.cpp -o recordbatchwriter.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c safe-call-into-r-impl.cpp -o safe-call-into-r-impl.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c scalar.cpp -o scalar.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c schema.cpp -o schema.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c symbols.cpp -o symbols.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c table.cpp -o table.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c threadpool.cpp -o threadpool.o
g++ -std=gnu++17 -I"/usr/share/R/include" -DNDEBUG -I/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c type_infer.cpp -o type_infer.o
g++ -std=gnu++17 -shared -L/usr/lib/R/lib -Wl,-Bsymbolic-functions -flto=auto -ffat-lto-objects -flto=auto -Wl,-z,relro -o arrow.so RTasks.o altrep.o array.o array_to_vector.o arraydata.o arrowExports.o bridge.o buffer.o chunkedarray.o compression.o compute-exec.o compute.o config.o csv.o dataset.o datatype.o expression.o extension-impl.o feather.o field.o filesystem.o imports.o io.o json.o memorypool.o message.o parquet.o r_to_arrow.o recordbatch.o recordbatchreader.o recordbatchwriter.o safe-call-into-r-impl.o scalar.o schema.o symbols.o table.o threadpool.o type_infer.o -L/tmp/Rtmp3363P8/R.INSTALL184d46c388317/arrow/libarrow/arrow-10.0.0/lib -larrow_dataset -lparquet -L/arrow/r/libarrow/dist/lib -larrow -larrow_bundled_dependencies -larrow -larrow_bundled_dependencies -larrow_dataset -lparquet -lssl -lcrypto -lcurl -lssl -lcrypto -lcurl -L/usr/lib/R/lib -lR
installing to /home/tdhock/R/x86_64-pc-linux-gnu-library/4.1/00LOCK-arrow/00new/arrow/libs
** R
** inst
** byte-compile and prepare package for lazy loading
Le chargement a nécessité le package : grDevices
** help
*** installing help indices
** building package indices
Le chargement a nécessité le package : grDevices
** installing vignettes
** testing if installed package can be loaded from temporary location
Le chargement a nécessité le package : grDevices
** checking absolute paths in shared objects and dynamic libraries
** testing if installed package can be loaded from final location
Le chargement a nécessité le package : grDevices
** testing if installed package keeps a record of temporary installation path
* DONE (arrow)
(base) tdhock@tdhock-MacBook:~$ R --vanilla < R/arrow-crash.R

R version 4.1.2 (2021-11-01) -- "Bird Hippie"
Copyright (C) 2021 The R Foundation for Statistical Computing
Platform: x86_64-pc-linux-gnu (64-bit)

R est un logiciel libre livré sans AUCUNE GARANTIE.
Vous pouvez le redistribuer sous certaines conditions.
Tapez 'license()' ou 'licence()' pour plus de détails.

R est un projet collaboratif avec de nombreux contributeurs.
Tapez 'contributors()' pour plus d'information et
'citation()' pour la façon de le citer dans les publications.

Tapez 'demo()' pour des démonstrations, 'help()' pour l'aide
en ligne ou 'help.start()' pour obtenir l'aide au format HTML.
Tapez 'q()' pour quitter R.

> library(arrow)

Attachement du package : ‘arrow’

L'objet suivant est masqué depuis ‘package:utils’:

    timestamp

> sessionInfo()
R version 4.1.2 (2021-11-01)
Platform: x86_64-pc-linux-gnu (64-bit)
Running under: Ubuntu 22.04.2 LTS

Matrix products: default
BLAS:   /usr/lib/x86_64-linux-gnu/blas/libblas.so.3.10.0
LAPACK: /usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.10.0

locale:
 [1] LC_CTYPE=fr_FR.UTF-8       LC_NUMERIC=C              
 [3] LC_TIME=fr_FR.UTF-8        LC_COLLATE=fr_FR.UTF-8    
 [5] LC_MONETARY=fr_FR.UTF-8    LC_MESSAGES=fr_FR.UTF-8   
 [7] LC_PAPER=fr_FR.UTF-8       LC_NAME=C                 
 [9] LC_ADDRESS=C               LC_TELEPHONE=C            
[11] LC_MEASUREMENT=fr_FR.UTF-8 LC_IDENTIFICATION=C       

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
[1] arrow_10.0.0

loaded via a namespace (and not attached):
 [1] tidyselect_1.1.2 bit_4.0.4        compiler_4.1.2   magrittr_2.0.2  
 [5] assertthat_0.2.1 R6_2.5.1         cli_3.2.0        glue_1.6.1      
 [9] bit64_4.0.5      vctrs_0.3.8      rlang_1.0.1      purrr_0.3.4     
> one_level_tree <- tempfile()
> write_dataset(mtcars, one_level_tree, partitioning = "cyl")

 *** caught illegal operation ***
address 0x7f44b08be647, cause 'illegal operand'

Traceback:
 1: ExecPlan_Write(self, node, prepare_key_value_metadata(node$final_metadata()),     ...)
 2: plan$Write(final_node, options, path_and_fs$fs, path_and_fs$path,     partitioning, basename_template, existing_data_behavior,     max_partitions, max_open_files, max_rows_per_file, min_rows_per_group,     max_rows_per_group)
 3: write_dataset(mtcars, one_level_tree, partitioning = "cyl")
An irrecoverable exception occurred. R is aborting now ...
Instruction non permise (core dumped)
```

Below we try with version 7, which fails to compile:

```
(base) tdhock@tdhock-MacBook:~$ R CMD INSTALL ~/Downloads/arrow_7.0.0.tar.gz 
Le chargement a nécessité le package : grDevices
* installing to library ‘/home/tdhock/R/x86_64-pc-linux-gnu-library/4.1’
* installing *source* package ‘arrow’ ...
** package ‘arrow’ successfully unpacked and MD5 sums checked
** using staged installation
Le chargement a nécessité le package : grDevices
*** Found local C++ source: 'tools/cpp'
*** Building libarrow from source
    For a faster, more complete installation, set the environment variable NOT_CRAN=true before installing
    See install vignette for details:
    https://cran.r-project.org/web/packages/arrow/vignettes/install.html
**** cmake
**** arrow  
**** Error building Arrow C++. Re-run with ARROW_R_DEV=true for debug information. 
------------------------- NOTE ---------------------------
There was an issue preparing the Arrow C++ libraries.
See https://arrow.apache.org/docs/r/articles/install.html
---------------------------------------------------------
ERROR: configuration failed for package ‘arrow’
* removing ‘/home/tdhock/R/x86_64-pc-linux-gnu-library/4.1/arrow’
* restoring previous ‘/home/tdhock/R/x86_64-pc-linux-gnu-library/4.1/arrow’
```

version 8 does not install below

```
(base) tdhock@tdhock-MacBook:~$ R CMD INSTALL ~/Downloads/arrow_8.0.0.tar.gz 
Le chargement a nécessité le package : grDevices
* installing to library ‘/home/tdhock/R/x86_64-pc-linux-gnu-library/4.1’
* installing *source* package ‘arrow’ ...
** package ‘arrow’ successfully unpacked and MD5 sums checked
** using staged installation
Le chargement a nécessité le package : grDevices
*** Successfully retrieved C++ binaries for ubuntu-22.04
**** Binary package requires libcurl and openssl
**** If installation fails, retry after installing those system requirements
PKG_CFLAGS=-I/tmp/RtmpYqPwAx/R.INSTALL197d1638f4f3a/arrow/libarrow/arrow-8.0.0/include  -DARROW_R_WITH_ARROW -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_S3 -DARROW_R_WITH_JSON
PKG_LIBS=-L/tmp/RtmpYqPwAx/R.INSTALL197d1638f4f3a/arrow/libarrow/arrow-8.0.0/lib -larrow_dataset -lparquet -larrow -larrow -larrow_bundled_dependencies -larrow -larrow_bundled_dependencies -larrow_dataset -lparquet -lssl -lcrypto -lcurl
** libs
g++ -std=gnu++11 -I"/usr/share/R/include" -DNDEBUG -I/tmp/RtmpYqPwAx/R.INSTALL197d1638f4f3a/arrow/libarrow/arrow-8.0.0/include  -DARROW_R_WITH_ARROW -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_S3 -DARROW_R_WITH_JSON -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c RTasks.cpp -o RTasks.o
g++ -std=gnu++11 -I"/usr/share/R/include" -DNDEBUG -I/tmp/RtmpYqPwAx/R.INSTALL197d1638f4f3a/arrow/libarrow/arrow-8.0.0/include  -DARROW_R_WITH_ARROW -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_S3 -DARROW_R_WITH_JSON -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c altrep.cpp -o altrep.o
g++ -std=gnu++11 -I"/usr/share/R/include" -DNDEBUG -I/tmp/RtmpYqPwAx/R.INSTALL197d1638f4f3a/arrow/libarrow/arrow-8.0.0/include  -DARROW_R_WITH_ARROW -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_S3 -DARROW_R_WITH_JSON -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c array.cpp -o array.o
g++ -std=gnu++11 -I"/usr/share/R/include" -DNDEBUG -I/tmp/RtmpYqPwAx/R.INSTALL197d1638f4f3a/arrow/libarrow/arrow-8.0.0/include  -DARROW_R_WITH_ARROW -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_S3 -DARROW_R_WITH_JSON -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c array_to_vector.cpp -o array_to_vector.o
g++ -std=gnu++11 -I"/usr/share/R/include" -DNDEBUG -I/tmp/RtmpYqPwAx/R.INSTALL197d1638f4f3a/arrow/libarrow/arrow-8.0.0/include  -DARROW_R_WITH_ARROW -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_S3 -DARROW_R_WITH_JSON -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c arraydata.cpp -o arraydata.o
g++ -std=gnu++11 -I"/usr/share/R/include" -DNDEBUG -I/tmp/RtmpYqPwAx/R.INSTALL197d1638f4f3a/arrow/libarrow/arrow-8.0.0/include  -DARROW_R_WITH_ARROW -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_S3 -DARROW_R_WITH_JSON -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c arrowExports.cpp -o arrowExports.o
g++ -std=gnu++11 -I"/usr/share/R/include" -DNDEBUG -I/tmp/RtmpYqPwAx/R.INSTALL197d1638f4f3a/arrow/libarrow/arrow-8.0.0/include  -DARROW_R_WITH_ARROW -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_S3 -DARROW_R_WITH_JSON -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c bridge.cpp -o bridge.o
g++ -std=gnu++11 -I"/usr/share/R/include" -DNDEBUG -I/tmp/RtmpYqPwAx/R.INSTALL197d1638f4f3a/arrow/libarrow/arrow-8.0.0/include  -DARROW_R_WITH_ARROW -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_S3 -DARROW_R_WITH_JSON -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c buffer.cpp -o buffer.o
g++ -std=gnu++11 -I"/usr/share/R/include" -DNDEBUG -I/tmp/RtmpYqPwAx/R.INSTALL197d1638f4f3a/arrow/libarrow/arrow-8.0.0/include  -DARROW_R_WITH_ARROW -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_S3 -DARROW_R_WITH_JSON -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c chunkedarray.cpp -o chunkedarray.o
g++ -std=gnu++11 -I"/usr/share/R/include" -DNDEBUG -I/tmp/RtmpYqPwAx/R.INSTALL197d1638f4f3a/arrow/libarrow/arrow-8.0.0/include  -DARROW_R_WITH_ARROW -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_S3 -DARROW_R_WITH_JSON -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c compression.cpp -o compression.o
g++ -std=gnu++11 -I"/usr/share/R/include" -DNDEBUG -I/tmp/RtmpYqPwAx/R.INSTALL197d1638f4f3a/arrow/libarrow/arrow-8.0.0/include  -DARROW_R_WITH_ARROW -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_S3 -DARROW_R_WITH_JSON -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c compute-exec.cpp -o compute-exec.o
g++ -std=gnu++11 -I"/usr/share/R/include" -DNDEBUG -I/tmp/RtmpYqPwAx/R.INSTALL197d1638f4f3a/arrow/libarrow/arrow-8.0.0/include  -DARROW_R_WITH_ARROW -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_S3 -DARROW_R_WITH_JSON -I'/usr/lib/R/site-library/cpp11/include'    -fpic  -g -O2 -ffile-prefix-map=/build/r-base-4A2Reg/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c compute.cpp -o compute.o
compute.cpp:578:1: internal compiler error: in value_format, at dwarf2out.c:10030
  578 | }
      | ^
0x7f96ec02ed8f __libc_start_call_main
	../sysdeps/nptl/libc_start_call_main.h:58
0x7f96ec02ee3f __libc_start_main_impl
	../csu/libc-start.c:392
Please submit a full bug report,
with preprocessed source if appropriate.
Please include the complete backtrace with any bug report.
See <file:///usr/share/doc/gcc-11/README.Bugs> for instructions.
make: *** [/usr/lib/R/etc/Makeconf:177 : compute.o] Erreur 1
ERROR: compilation failed for package ‘arrow’
* removing ‘/home/tdhock/R/x86_64-pc-linux-gnu-library/4.1/arrow’
* restoring previous ‘/home/tdhock/R/x86_64-pc-linux-gnu-library/4.1/arrow’
```

What about with pre-compiled binaries? 

```r
options(
  HTTPUserAgent =
    sprintf(
      "R/%s R (%s)",
      getRversion(),
      paste(getRversion(), R.version["platform"], R.version["arch"], R.version["os"])
    )
)
install.packages("arrow", repos = "https://packagemanager.rstudio.com/all/__linux__/jammy/latest")
```

Code above installs from RStudio's pre-built binaries, same segfault.

Code below installed via conda 

```
(arrow) tdhock@tdhock-MacBook:~$ which R
/home/tdhock/miniconda3/envs/arrow/bin/R
(arrow) tdhock@tdhock-MacBook:~$ R --vanilla < R/arrow-crash.R

R version 4.2.3 (2023-03-15) -- "Shortstop Beagle"
Copyright (C) 2023 The R Foundation for Statistical Computing
Platform: x86_64-conda-linux-gnu (64-bit)

R est un logiciel libre livré sans AUCUNE GARANTIE.
Vous pouvez le redistribuer sous certaines conditions.
Tapez 'license()' ou 'licence()' pour plus de détails.

R est un projet collaboratif avec de nombreux contributeurs.
Tapez 'contributors()' pour plus d'information et
'citation()' pour la façon de le citer dans les publications.

Tapez 'demo()' pour des démonstrations, 'help()' pour l'aide
en ligne ou 'help.start()' pour obtenir l'aide au format HTML.
Tapez 'q()' pour quitter R.

> library(arrow)

Attachement du package : ‘arrow’

L'objet suivant est masqué depuis ‘package:utils’:

    timestamp

> sessionInfo()
R version 4.2.3 (2023-03-15)
Platform: x86_64-conda-linux-gnu (64-bit)
Running under: Ubuntu 22.04.2 LTS

Matrix products: default
BLAS/LAPACK: /home/tdhock/miniconda3/envs/arrow/lib/libopenblasp-r0.3.21.so

locale:
 [1] LC_CTYPE=fr_FR.UTF-8       LC_NUMERIC=C              
 [3] LC_TIME=fr_FR.UTF-8        LC_COLLATE=fr_FR.UTF-8    
 [5] LC_MONETARY=fr_FR.UTF-8    LC_MESSAGES=fr_FR.UTF-8   
 [7] LC_PAPER=fr_FR.UTF-8       LC_NAME=C                 
 [9] LC_ADDRESS=C               LC_TELEPHONE=C            
[11] LC_MEASUREMENT=fr_FR.UTF-8 LC_IDENTIFICATION=C       

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
[1] arrow_11.0.0

loaded via a namespace (and not attached):
 [1] tidyselect_1.2.0 bit_4.0.5        compiler_4.2.3   magrittr_2.0.3  
 [5] assertthat_0.2.1 R6_2.5.1         cli_3.6.1        glue_1.6.2      
 [9] bit64_4.0.5      vctrs_0.6.2      lifecycle_1.0.3  rlang_1.1.1     
[13] purrr_1.0.1     
> one_level_tree <- tempfile()
> write_dataset(mtcars, one_level_tree, partitioning = "cyl")
Erreur dans loadNamespace(x) : aucun package nommé ‘dplyr’ n'est trouvé
Appels : write_dataset ... loadNamespace -> withRestarts -> withOneRestart -> doWithOneRestart
Exécution arrêtée
```

Progress above! At least no segfault. Below after installing dplyr from conda, arrow works:

```
(arrow) tdhock@tdhock-MacBook:~$ R --vanilla < R/arrow-crash.R

R version 4.2.3 (2023-03-15) -- "Shortstop Beagle"
Copyright (C) 2023 The R Foundation for Statistical Computing
Platform: x86_64-conda-linux-gnu (64-bit)

R est un logiciel libre livré sans AUCUNE GARANTIE.
Vous pouvez le redistribuer sous certaines conditions.
Tapez 'license()' ou 'licence()' pour plus de détails.

R est un projet collaboratif avec de nombreux contributeurs.
Tapez 'contributors()' pour plus d'information et
'citation()' pour la façon de le citer dans les publications.

Tapez 'demo()' pour des démonstrations, 'help()' pour l'aide
en ligne ou 'help.start()' pour obtenir l'aide au format HTML.
Tapez 'q()' pour quitter R.

> library(arrow)

Attachement du package : ‘arrow’

L'objet suivant est masqué depuis ‘package:utils’:

    timestamp

> sessionInfo()
R version 4.2.3 (2023-03-15)
Platform: x86_64-conda-linux-gnu (64-bit)
Running under: Ubuntu 22.04.2 LTS

Matrix products: default
BLAS/LAPACK: /home/tdhock/miniconda3/envs/arrow/lib/libopenblasp-r0.3.21.so

locale:
 [1] LC_CTYPE=fr_FR.UTF-8       LC_NUMERIC=C              
 [3] LC_TIME=fr_FR.UTF-8        LC_COLLATE=fr_FR.UTF-8    
 [5] LC_MONETARY=fr_FR.UTF-8    LC_MESSAGES=fr_FR.UTF-8   
 [7] LC_PAPER=fr_FR.UTF-8       LC_NAME=C                 
 [9] LC_ADDRESS=C               LC_TELEPHONE=C            
[11] LC_MEASUREMENT=fr_FR.UTF-8 LC_IDENTIFICATION=C       

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
[1] arrow_11.0.0

loaded via a namespace (and not attached):
 [1] tidyselect_1.2.0 bit_4.0.5        compiler_4.2.3   magrittr_2.0.3  
 [5] assertthat_0.2.1 R6_2.5.1         cli_3.6.1        glue_1.6.2      
 [9] bit64_4.0.5      vctrs_0.6.2      lifecycle_1.0.3  rlang_1.1.1     
[13] purrr_1.0.1     
> one_level_tree <- tempfile()
> write_dataset(mtcars, one_level_tree, partitioning = "cyl")
> 
```

So there are three versions of R,

```
(arrow) tdhock@tdhock-MacBook:~$ /usr/bin/R --version
R version 4.1.2 (2021-11-01) -- "Bird Hippie"
Copyright (C) 2021 The R Foundation for Statistical Computing
Platform: x86_64-pc-linux-gnu (64-bit)

R is free software and comes with ABSOLUTELY NO WARRANTY.
You are welcome to redistribute it under the terms of the
GNU General Public License versions 2 or 3.
For more information about these matters see
https://www.gnu.org/licenses/.

(arrow) tdhock@tdhock-MacBook:~$ R --version
R version 4.2.3 (2023-03-15) -- "Shortstop Beagle"
Copyright (C) 2023 The R Foundation for Statistical Computing
Platform: x86_64-conda-linux-gnu (64-bit)

R is free software and comes with ABSOLUTELY NO WARRANTY.
You are welcome to redistribute it under the terms of the
GNU General Public License versions 2 or 3.
For more information about these matters see
https://www.gnu.org/licenses/.

(arrow) tdhock@tdhock-MacBook:~$ ~/bin/R --version
R version 4.3.0 (2023-04-21) -- "Already Tomorrow"
Copyright (C) 2023 The R Foundation for Statistical Computing
Platform: x86_64-pc-linux-gnu (64-bit)

R is free software and comes with ABSOLUTELY NO WARRANTY.
You are welcome to redistribute it under the terms of the
GNU General Public License versions 2 or 3.
For more information about these matters see
https://www.gnu.org/licenses/.

```

https://cran.r-project.org/src/contrib/Archive/arrow/ does not have
`arrow_11.0.0` (conda version that works), so we can't easily try
installing that on non-conda R to see if it will work, and anyways
that is not likely, since larger and smaller versions of arrow
segfault on non-conda R.

Can we make arrow segfault in conda? Installation from source fails below,

```

R version 4.2.3 (2023-03-15) -- "Shortstop Beagle"
Copyright (C) 2023 The R Foundation for Statistical Computing
Platform: x86_64-conda-linux-gnu (64-bit)

R est un logiciel libre livré sans AUCUNE GARANTIE.
Vous pouvez le redistribuer sous certaines conditions.
Tapez 'license()' ou 'licence()' pour plus de détails.

R est un projet collaboratif avec de nombreux contributeurs.
Tapez 'contributors()' pour plus d'information et
'citation()' pour la façon de le citer dans les publications.

Tapez 'demo()' pour des démonstrations, 'help()' pour l'aide
en ligne ou 'help.start()' pour obtenir l'aide au format HTML.
Tapez 'q()' pour quitter R.

Le chargement a nécessité le package : grDevices
> setwd('~')
> install.packages("arrow")
installation de la dépendance ‘cpp11’

essai de l'URL 'http://cloud.r-project.org/src/contrib/cpp11_0.4.3.tar.gz'
Content type 'application/x-gzip' length 304530 bytes (297 KB)
==================================================
downloaded 297 KB

essai de l'URL 'http://cloud.r-project.org/src/contrib/arrow_11.0.0.3.tar.gz'
Content type 'application/x-gzip' length 3921484 bytes (3.7 MB)
==================================================
downloaded 3.7 MB

Le chargement a nécessité le package : grDevices
* installing *source* package ‘cpp11’ ...
** package ‘cpp11’ correctement décompressé et sommes MD5 vérifiées
** using staged installation
** R
** inst
** byte-compile and prepare package for lazy loading
Le chargement a nécessité le package : grDevices
** help
*** installing help indices
** building package indices
Le chargement a nécessité le package : grDevices
** installing vignettes
** testing if installed package can be loaded from temporary location
Le chargement a nécessité le package : grDevices
** testing if installed package can be loaded from final location
Le chargement a nécessité le package : grDevices
** testing if installed package keeps a record of temporary installation path
* DONE (cpp11)
Le chargement a nécessité le package : grDevices
* installing *source* package ‘arrow’ ...
** package ‘arrow’ correctement décompressé et sommes MD5 vérifiées
** using staged installation
Le chargement a nécessité le package : grDevices
*** Checking glibc version
PKG_CFLAGS=-DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS
PKG_LIBS=-L/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/lib -L/usr/lib/lib/x86_64-linux-gnu -larrow_dataset -lparquet -larrow -pthread -larrow_bundled_dependencies -lcurl -lssl -lcrypto  
** libs
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c RTasks.cpp -o RTasks.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c altrep.cpp -o altrep.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c array.cpp -o array.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c array_to_vector.cpp -o array_to_vector.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c arraydata.cpp -o arraydata.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c arrowExports.cpp -o arrowExports.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c bridge.cpp -o bridge.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c buffer.cpp -o buffer.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c chunkedarray.cpp -o chunkedarray.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c compression.cpp -o compression.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c compute-exec.cpp -o compute-exec.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c compute.cpp -o compute.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c config.cpp -o config.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c csv.cpp -o csv.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c dataset.cpp -o dataset.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c datatype.cpp -o datatype.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c expression.cpp -o expression.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c extension-impl.cpp -o extension-impl.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c feather.cpp -o feather.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c field.cpp -o field.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c filesystem.cpp -o filesystem.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c io.cpp -o io.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c json.cpp -o json.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c memorypool.cpp -o memorypool.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c message.cpp -o message.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c parquet.cpp -o parquet.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c r_to_arrow.cpp -o r_to_arrow.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c recordbatch.cpp -o recordbatch.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c recordbatchreader.cpp -o recordbatchreader.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c recordbatchwriter.cpp -o recordbatchwriter.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c safe-call-into-r-impl.cpp -o safe-call-into-r-impl.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c scalar.cpp -o scalar.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c schema.cpp -o schema.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c symbols.cpp -o symbols.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c table.cpp -o table.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c threadpool.cpp -o threadpool.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -I"/home/tdhock/miniconda3/envs/arrow/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/miniconda3/envs/arrow/lib/R/library/cpp11/include' -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -isystem /home/tdhock/miniconda3/envs/arrow/include -I/home/tdhock/miniconda3/envs/arrow/include -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib   -fpic  -fvisibility-inlines-hidden -fmessage-length=0 -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem /home/tdhock/miniconda3/envs/arrow/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/r-base-split_1679996176288/work=/usr/local/src/conda/r-base-4.2.3 -fdebug-prefix-map=/home/tdhock/miniconda3/envs/arrow=/usr/local/src/conda-prefix  -c type_infer.cpp -o type_infer.o
x86_64-conda-linux-gnu-c++ -std=gnu++17 -shared -L/home/tdhock/miniconda3/envs/arrow/lib/R/lib -Wl,-O2 -Wl,--sort-common -Wl,--as-needed -Wl,-z,relro -Wl,-z,now -Wl,--disable-new-dtags -Wl,--gc-sections -Wl,--allow-shlib-undefined -Wl,-rpath,/home/tdhock/miniconda3/envs/arrow/lib -Wl,-rpath-link,/home/tdhock/miniconda3/envs/arrow/lib -L/home/tdhock/miniconda3/envs/arrow/lib -o arrow.so RTasks.o altrep.o array.o array_to_vector.o arraydata.o arrowExports.o bridge.o buffer.o chunkedarray.o compression.o compute-exec.o compute.o config.o csv.o dataset.o datatype.o expression.o extension-impl.o feather.o field.o filesystem.o io.o json.o memorypool.o message.o parquet.o r_to_arrow.o recordbatch.o recordbatchreader.o recordbatchwriter.o safe-call-into-r-impl.o scalar.o schema.o symbols.o table.o threadpool.o type_infer.o -L/tmp/RtmpHifxMB/R.INSTALL1b28d64def4a7/arrow/libarrow/arrow-11.0.0.3/lib -L/usr/lib/lib/x86_64-linux-gnu -larrow_dataset -lparquet -larrow -pthread -larrow_bundled_dependencies -lcurl -lssl -lcrypto -L/home/tdhock/miniconda3/envs/arrow/lib/R/lib -lR
installing to /home/tdhock/miniconda3/envs/arrow/lib/R/library/00LOCK-arrow/00new/arrow/libs
** R
** inst
** byte-compile and prepare package for lazy loading
Le chargement a nécessité le package : grDevices
** help
*** installing help indices
** building package indices
Le chargement a nécessité le package : grDevices
** testing if installed package can be loaded from temporary location
Le chargement a nécessité le package : grDevices
Error: le chargement du package ou de l'espace de noms a échoué pour ‘arrow’ in dyn.load(file, DLLpath = DLLpath, ...) :
impossible de charger l'objet partagé '/home/tdhock/miniconda3/envs/arrow/lib/R/library/00LOCK-arrow/00new/arrow/libs/arrow.so':
  /home/tdhock/miniconda3/envs/arrow/lib/R/library/00LOCK-arrow/00new/arrow/libs/arrow.so: undefined symbol: HMAC_CTX_cleanup
Erreur : le chargement a échoué
Exécution arrêtée
ERROR: loading failed
* removing ‘/home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow’
* restoring previous ‘/home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow’

Les packages source téléchargés sont dans
	‘/tmp/RtmpLc9zFF/downloaded_packages’
Mise à jour de la liste HTML des packages dans '.Library'
Making 'packages.html' ... terminé
Message d'avis :
Dans install.packages("arrow") :
  l'installation du package ‘arrow’ a eu un statut de sortie non nul
> 
```

ldd output below

```
(base) tdhock@tdhock-MacBook:~$ ldd /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/arrow.so 
	linux-vdso.so.1 (0x00007ffdb99f0000)
	libarrow_substrait.so.1100 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../libarrow_substrait.so.1100 (0x00007f8ce9667000)
	libarrow_dataset.so.1100 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../libarrow_dataset.so.1100 (0x00007f8ce94f7000)
	libparquet.so.1100 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../libparquet.so.1100 (0x00007f8ce91d0000)
	libarrow.so.1100 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../libarrow.so.1100 (0x00007f8ce7a02000)
	libR.so => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../lib/libR.so (0x00007f8ce752e000)
	libstdc++.so.6 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../libstdc++.so.6 (0x00007f8ce7378000)
	libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007f8ce727c000)
	libgcc_s.so.1 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../libgcc_s.so.1 (0x00007f8ce7263000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f8ce703b000)
	libprotobuf.so.32 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././libprotobuf.so.32 (0x00007f8ce6d87000)
	/lib64/ld-linux-x86-64.so.2 (0x00007f8ce9a7c000)
	libthrift.so.0.18.1 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././libthrift.so.0.18.1 (0x00007f8ce6cde000)
	libcrypto.so.3 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././libcrypto.so.3 (0x00007f8ce67d5000)
	libbrotlienc.so.1 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././libbrotlienc.so.1 (0x00007f8ce6737000)
	libbrotlidec.so.1 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././libbrotlidec.so.1 (0x00007f8ce6729000)
	liborc.so => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././liborc.so (0x00007f8ce65e5000)
	libglog.so.1 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././libglog.so.1 (0x00007f8ce65a8000)
	libutf8proc.so.2 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././libutf8proc.so.2 (0x00007f8ce6550000)
	libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007f8ce654b000)
	librt.so.1 => /lib/x86_64-linux-gnu/librt.so.1 (0x00007f8ce6546000)
	libbz2.so.1.0 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././libbz2.so.1.0 (0x00007f8ce6532000)
	liblz4.so.1 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././liblz4.so.1 (0x00007f8ce6507000)
	libsnappy.so.1 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././libsnappy.so.1 (0x00007f8ce64f8000)
	libz.so.1 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././libz.so.1 (0x00007f8ce64de000)
	libzstd.so.1 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././libzstd.so.1 (0x00007f8ce641b000)
	libgoogle_cloud_cpp_storage.so.2 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././libgoogle_cloud_cpp_storage.so.2 (0x00007f8ce6177000)
	libaws-cpp-sdk-identity-management.so => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././libaws-cpp-sdk-identity-management.so (0x00007f8ce614b000)
	libaws-cpp-sdk-s3.so => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././libaws-cpp-sdk-s3.so (0x00007f8ce5e73000)
	libaws-cpp-sdk-core.so => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././libaws-cpp-sdk-core.so (0x00007f8ce5d1c000)
	libre2.so.10 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././libre2.so.10 (0x00007f8ce5cb7000)
	libgoogle_cloud_cpp_common.so.2 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././libgoogle_cloud_cpp_common.so.2 (0x00007f8ce5c4f000)
	libabsl_time.so.2301.0.0 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././libabsl_time.so.2301.0.0 (0x00007f8ce5c38000)
	libabsl_time_zone.so.2301.0.0 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././libabsl_time_zone.so.2301.0.0 (0x00007f8ce5c17000)
	libaws-crt-cpp.so => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././libaws-crt-cpp.so (0x00007f8ce5b89000)
	libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007f8ce5b84000)
	libblas.so.3 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../lib/../../libblas.so.3 (0x00007f8ce38dc000)
	libreadline.so.8 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../lib/../../libreadline.so.8 (0x00007f8ce3883000)
	libpcre2-8.so.0 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../lib/../../libpcre2-8.so.0 (0x00007f8ce37e1000)
	liblzma.so.5 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../lib/../../liblzma.so.5 (0x00007f8ce37b8000)
	libiconv.so.2 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../lib/../../libiconv.so.2 (0x00007f8ce36d1000)
	libicuuc.so.72 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../lib/../../libicuuc.so.72 (0x00007f8ce34ca000)
	libicui18n.so.72 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../lib/../../libicui18n.so.72 (0x00007f8ce319a000)
	libgomp.so.1 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../lib/../../libgomp.so.1 (0x00007f8ce315f000)
	libssl.so.3 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././libssl.so.3 (0x00007f8ce30bd000)
	libbrotlicommon.so.1 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././libbrotlicommon.so.1 (0x00007f8ce309a000)
	libgflags.so.2.2 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././libgflags.so.2.2 (0x00007f8ce3075000)
	libgoogle_cloud_cpp_rest_internal.so.2 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././libgoogle_cloud_cpp_rest_internal.so.2 (0x00007f8ce2fa5000)
	libcrc32c.so.1 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././libcrc32c.so.1 (0x00007f8ce2f9f000)
	libcurl.so.4 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././libcurl.so.4 (0x00007f8ce2ef3000)
	libabsl_crc32c.so.2301.0.0 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././libabsl_crc32c.so.2301.0.0 (0x00007f8ce2eed000)
	libabsl_str_format_internal.so.2301.0.0 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././libabsl_str_format_internal.so.2301.0.0 (0x00007f8ce2ed2000)
	libabsl_strings.so.2301.0.0 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././libabsl_strings.so.2301.0.0 (0x00007f8ce2eb0000)
	libabsl_strings_internal.so.2301.0.0 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././libabsl_strings_internal.so.2301.0.0 (0x00007f8ce2eaa000)
	libaws-cpp-sdk-cognito-identity.so => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././libaws-cpp-sdk-cognito-identity.so (0x00007f8ce2e08000)
	libaws-cpp-sdk-sts.so => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././libaws-cpp-sdk-sts.so (0x00007f8ce2dbb000)
	libaws-c-event-stream.so.1.0.0 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././libaws-c-event-stream.so.1.0.0 (0x00007f8ce2da2000)
	libaws-checksums.so.1.0.0 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././libaws-checksums.so.1.0.0 (0x00007f8ce2d92000)
	libaws-c-common.so.1 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././libaws-c-common.so.1 (0x00007f8ce2d55000)
	libabsl_int128.so.2301.0.0 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././libabsl_int128.so.2301.0.0 (0x00007f8ce2d4e000)
	libabsl_base.so.2301.0.0 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././libabsl_base.so.2301.0.0 (0x00007f8ce2d48000)
	libabsl_raw_logging_internal.so.2301.0.0 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././libabsl_raw_logging_internal.so.2301.0.0 (0x00007f8ce2d43000)
	libaws-c-mqtt.so.1.0.0 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././libaws-c-mqtt.so.1.0.0 (0x00007f8ce2cff000)
	libaws-c-s3.so.0unstable => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././libaws-c-s3.so.0unstable (0x00007f8ce2cd9000)
	libaws-c-auth.so.1.0.0 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././libaws-c-auth.so.1.0.0 (0x00007f8ce2ca9000)
	libaws-c-http.so.1.0.0 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././libaws-c-http.so.1.0.0 (0x00007f8ce2c45000)
	libaws-c-io.so.1.0.0 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././libaws-c-io.so.1.0.0 (0x00007f8ce2bfe000)
	libaws-c-cal.so.1.0.0 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././libaws-c-cal.so.1.0.0 (0x00007f8ce2bea000)
	libaws-c-sdkutils.so.1.0.0 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././libaws-c-sdkutils.so.1.0.0 (0x00007f8ce2bd1000)
	libgfortran.so.5 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../lib/../.././libgfortran.so.5 (0x00007f8ce2a26000)
	libtinfo.so.6 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../lib/../.././libtinfo.so.6 (0x00007f8ce29e6000)
	libicudata.so.72 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../lib/../.././libicudata.so.72 (0x00007f8ce0c15000)
	libnghttp2.so.14 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././././libnghttp2.so.14 (0x00007f8ce0be6000)
	libssh2.so.1 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././././libssh2.so.1 (0x00007f8ce0ba2000)
	libgssapi_krb5.so.2 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././././libgssapi_krb5.so.2 (0x00007f8ce0b50000)
	libabsl_crc_internal.so.2301.0.0 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././././libabsl_crc_internal.so.2301.0.0 (0x00007f8ce0b49000)
	libabsl_spinlock_wait.so.2301.0.0 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././././libabsl_spinlock_wait.so.2301.0.0 (0x00007f8ce0b42000)
	libaws-c-compression.so.1.0.0 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././././libaws-c-compression.so.1.0.0 (0x00007f8ce0b3d000)
	libs2n.so.1 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../.././././libs2n.so.1 (0x00007f8ce09fc000)
	libquadmath.so.0 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../lib/../../././libquadmath.so.0 (0x00007f8ce09c2000)
	libkrb5.so.3 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././././libkrb5.so.3 (0x00007f8ce08e9000)
	libk5crypto.so.3 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././././libk5crypto.so.3 (0x00007f8ce08d0000)
	libcom_err.so.3 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././././libcom_err.so.3 (0x00007f8ce08ca000)
	libkrb5support.so.0 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././././libkrb5support.so.0 (0x00007f8ce08bb000)
	libkeyutils.so.1 => /home/tdhock/miniconda3/envs/arrow/lib/R/library/arrow/libs/../../../../././././libkeyutils.so.1 (0x00007f8ce08b4000)
	libresolv.so.2 => /lib/x86_64-linux-gnu/libresolv.so.2 (0x00007f8ce089e000)
	
(base) tdhock@tdhock-MacBook:~$ ldd /home/tdhock/R/x86_64-pc-linux-gnu-library/4.1/arrow/libs/arrow.so 
	linux-vdso.so.1 (0x00007ffe711fb000)
	libcurl.so.4 => /lib/x86_64-linux-gnu/libcurl.so.4 (0x00007fa9ce0c7000)
	libcrypto.so.3 => /lib/x86_64-linux-gnu/libcrypto.so.3 (0x00007fa9cdc84000)
	libR.so => /lib/libR.so (0x00007fa9cd7cb000)
	libstdc++.so.6 => /lib/x86_64-linux-gnu/libstdc++.so.6 (0x00007fa9cd5a1000)
	libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007fa9cd4ba000)
	libgcc_s.so.1 => /lib/x86_64-linux-gnu/libgcc_s.so.1 (0x00007fa9cd49a000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fa9cd270000)
	/lib64/ld-linux-x86-64.so.2 (0x00007fa9d0ad1000)
	libnghttp2.so.14 => /lib/x86_64-linux-gnu/libnghttp2.so.14 (0x00007fa9cd246000)
	libidn2.so.0 => /lib/x86_64-linux-gnu/libidn2.so.0 (0x00007fa9cd225000)
	librtmp.so.1 => /lib/x86_64-linux-gnu/librtmp.so.1 (0x00007fa9cd206000)
	libssh.so.4 => /lib/x86_64-linux-gnu/libssh.so.4 (0x00007fa9cd199000)
	libpsl.so.5 => /lib/x86_64-linux-gnu/libpsl.so.5 (0x00007fa9cd185000)
	libssl.so.3 => /lib/x86_64-linux-gnu/libssl.so.3 (0x00007fa9cd0df000)
	libgssapi_krb5.so.2 => /lib/x86_64-linux-gnu/libgssapi_krb5.so.2 (0x00007fa9cd08b000)
	libldap-2.5.so.0 => /lib/x86_64-linux-gnu/libldap-2.5.so.0 (0x00007fa9cd02c000)
	liblber-2.5.so.0 => /lib/x86_64-linux-gnu/liblber-2.5.so.0 (0x00007fa9cd01b000)
	libzstd.so.1 => /lib/x86_64-linux-gnu/libzstd.so.1 (0x00007fa9ccf4c000)
	libbrotlidec.so.1 => /lib/x86_64-linux-gnu/libbrotlidec.so.1 (0x00007fa9ccf3e000)
	libz.so.1 => /lib/x86_64-linux-gnu/libz.so.1 (0x00007fa9ccf20000)
	libblas.so.3 => /lib/x86_64-linux-gnu/libblas.so.3 (0x00007fa9cce7a000)
	libreadline.so.8 => /lib/x86_64-linux-gnu/libreadline.so.8 (0x00007fa9cce26000)
	libpcre2-8.so.0 => /lib/x86_64-linux-gnu/libpcre2-8.so.0 (0x00007fa9ccd8f000)
	liblzma.so.5 => /lib/x86_64-linux-gnu/liblzma.so.5 (0x00007fa9ccd64000)
	libbz2.so.1.0 => /lib/x86_64-linux-gnu/libbz2.so.1.0 (0x00007fa9ccd51000)
	libtirpc.so.3 => /lib/x86_64-linux-gnu/libtirpc.so.3 (0x00007fa9ccd21000)
	libicuuc.so.70 => /lib/x86_64-linux-gnu/libicuuc.so.70 (0x00007fa9ccb26000)
	libicui18n.so.70 => /lib/x86_64-linux-gnu/libicui18n.so.70 (0x00007fa9cc7f7000)
	libgomp.so.1 => /lib/x86_64-linux-gnu/libgomp.so.1 (0x00007fa9cc7ad000)
	libunistring.so.2 => /lib/x86_64-linux-gnu/libunistring.so.2 (0x00007fa9cc603000)
	libgnutls.so.30 => /lib/x86_64-linux-gnu/libgnutls.so.30 (0x00007fa9cc416000)
	libhogweed.so.6 => /lib/x86_64-linux-gnu/libhogweed.so.6 (0x00007fa9cc3ce000)
	libnettle.so.8 => /lib/x86_64-linux-gnu/libnettle.so.8 (0x00007fa9cc388000)
	libgmp.so.10 => /lib/x86_64-linux-gnu/libgmp.so.10 (0x00007fa9cc306000)
	libkrb5.so.3 => /lib/x86_64-linux-gnu/libkrb5.so.3 (0x00007fa9cc23b000)
	libk5crypto.so.3 => /lib/x86_64-linux-gnu/libk5crypto.so.3 (0x00007fa9cc20a000)
	libcom_err.so.2 => /lib/x86_64-linux-gnu/libcom_err.so.2 (0x00007fa9cc204000)
	libkrb5support.so.0 => /lib/x86_64-linux-gnu/libkrb5support.so.0 (0x00007fa9cc1f6000)
	libsasl2.so.2 => /lib/x86_64-linux-gnu/libsasl2.so.2 (0x00007fa9cc1db000)
	libbrotlicommon.so.1 => /lib/x86_64-linux-gnu/libbrotlicommon.so.1 (0x00007fa9cc1b8000)
	libtinfo.so.6 => /lib/x86_64-linux-gnu/libtinfo.so.6 (0x00007fa9cc186000)
	libicudata.so.70 => /lib/x86_64-linux-gnu/libicudata.so.70 (0x00007fa9ca566000)
	libp11-kit.so.0 => /lib/x86_64-linux-gnu/libp11-kit.so.0 (0x00007fa9ca42b000)
	libtasn1.so.6 => /lib/x86_64-linux-gnu/libtasn1.so.6 (0x00007fa9ca413000)
	libkeyutils.so.1 => /lib/x86_64-linux-gnu/libkeyutils.so.1 (0x00007fa9ca40c000)
	libresolv.so.2 => /lib/x86_64-linux-gnu/libresolv.so.2 (0x00007fa9ca3f8000)
	libffi.so.8 => /lib/x86_64-linux-gnu/libffi.so.8 (0x00007fa9ca3e9000)
```

Apparently I have an old CPU which is not supported by arrow. I have

```
(base) tdhock@tdhock-MacBook:~/tdhock.github.io(master)$ lscpu
Architecture :                              x86_64
  Mode(s) opératoire(s) des processeurs :   32-bit, 64-bit
  Address sizes:                            36 bits physical, 48 bits virtual
  Boutisme :                                Little Endian
Processeur(s) :                             2
  Liste de processeur(s) en ligne :         0,1
Identifiant constructeur :                  GenuineIntel
  Nom de modèle :                           Intel(R) Core(TM)2 Duo CPU     P7350
                                              @ 2.00GHz
    Famille de processeur :                 6
    Modèle :                                23
    Thread(s) par cœur :                    1
    Cœur(s) par socket :                    2
    Socket(s) :                             1
    Révision :                              6
    Vitesse maximale du processeur en MHz : 1995,0000
    Vitesse minimale du processeur en MHz : 1596,0000
    BogoMIPS :                              3979.70
    Drapaux :                               fpu vme de pse tsc msr pae mce cx8 a
                                            pic sep mtrr pge mca cmov pat pse36 
                                            clflush dts acpi mmx fxsr sse sse2 h
                                            t tm pbe syscall nx lm constant_tsc 
                                            arch_perfmon pebs bts rep_good nopl 
                                            cpuid aperfmperf pni dtes64 monitor 
                                            ds_cpl vmx est tm2 ssse3 cx16 xtpr p
                                            dcm sse4_1 lahf_lm pti tpr_shadow vn
                                            mi flexpriority vpid dtherm
Virtualization features:                    
  Virtualisation :                          VT-x
Caches (sum of all):                        
  L1d:                                      64 KiB (2 instances)
  L1i:                                      64 KiB (2 instances)
  L2:                                       3 MiB (1 instance)
NUMA:                                       
  Nœud(s) NUMA :                            1
  Nœud NUMA 0 de processeur(s) :            0,1
Vulnerabilities:                            
  Itlb multihit:                            KVM: Mitigation: VMX disabled
  L1tf:                                     Mitigation; PTE Inversion; VMX EPT d
                                            isabled
  Mds:                                      Vulnerable: Clear CPU buffers attemp
                                            ted, no microcode; SMT disabled
  Meltdown:                                 Mitigation; PTI
  Mmio stale data:                          Unknown: No mitigations
  Retbleed:                                 Not affected
  Spec store bypass:                        Vulnerable
  Spectre v1:                               Mitigation; usercopy/swapgs barriers
                                             and __user pointer sanitization
  Spectre v2:                               Mitigation; Retpolines, STIBP disabl
                                            ed, RSB filling, PBRSB-eIBRS Not aff
                                            ected
  Srbds:                                    Not affected
  Tsx async abort:                          Not affected
(base) tdhock@tdhock-MacBook:~/tdhock.github.io(master*)$ 
```

There is an instruction `popcnt` which is present on newer CPUs, but
not on mine, so I get a segfault when that instruction is attempted:

```
(base) tdhock@maude-MacBookPro:~/projects/max-generalized-auc(master)$ R -d gdb
GNU gdb (Ubuntu 10.2-0ubuntu1~18.04~2) 10.2
Copyright (C) 2021 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
Type "show copying" and "show warranty" for details.
This GDB was configured as "x86_64-linux-gnu".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<https://www.gnu.org/software/gdb/bugs/>.
Find the GDB manual and other documentation resources online at:
    <http://www.gnu.org/software/gdb/documentation/>.

For help, type "help".
Type "apropos word" to search for commands related to "word"...
Reading symbols from /home/tdhock/lib/R/bin/exec/R...
(gdb) run
Starting program: /home/tdhock/lib/R/bin/exec/R 
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/lib/x86_64-linux-gnu/libthread_db.so.1".

R version 4.3.0 (2023-04-21) -- "Already Tomorrow"
Copyright (C) 2023 The R Foundation for Statistical Computing
Platform: x86_64-pc-linux-gnu (64-bit)

R is free software and comes with ABSOLUTELY NO WARRANTY.
You are welcome to redistribute it under certain conditions.
Type 'license()' or 'licence()' for distribution details.

  Natural language support but running in an English locale

R is a collaborative project with many contributors.
Type 'contributors()' for more information and
'citation()' on how to cite R or R packages in publications.

Type 'demo()' for some demos, 'help()' for on-line help, or
'help.start()' for an HTML browser interface to help.
Type 'q()' to quit R.

Loading required package: grDevices
[Detaching after fork from child process 6431]
[Detaching after fork from child process 6433]
> example("write_dataset",package="arrow")
[New Thread 0x7fffe6aa3700 (LWP 6435)]
[New Thread 0x7fffdc7ff700 (LWP 6436)]

Attaching package: ‘arrow’

The following object is masked from ‘package:utils’:

    timestamp


wrt_dt> ## Don't show: 
wrt_dt> if (arrow_with_dataset() & arrow_with_parquet() & requireNamespace("dplyr", quietly = TRUE)) (if (getRversion() >= "3.4") withAutoprint else force)({ # examplesIf
wrt_dt+ ## End(Don't show)
wrt_dt+ # You can write datasets partitioned by the values in a column (here: "cyl").
wrt_dt+ # This creates a structure of the form cyl=X/part-Z.parquet.
wrt_dt+ one_level_tree <- tempfile()
wrt_dt+ write_dataset(mtcars, one_level_tree, partitioning = "cyl")
wrt_dt+ list.files(one_level_tree, recursive = TRUE)
wrt_dt+ 
wrt_dt+ # You can also partition by the values in multiple columns
wrt_dt+ # (here: "cyl" and "gear").
wrt_dt+ # This creates a structure of the form cyl=X/gear=Y/part-Z.parquet.
wrt_dt+ two_levels_tree <- tempfile()
wrt_dt+ write_dataset(mtcars, two_levels_tree, partitioning = c("cyl", "gear"))
wrt_dt+ list.files(two_levels_tree, recursive = TRUE)
wrt_dt+ 
wrt_dt+ # In the two previous examples we would have:
wrt_dt+ # X = {4,6,8}, the number of cylinders.
wrt_dt+ # Y = {3,4,5}, the number of forward gears.
wrt_dt+ # Z = {0,1,2}, the number of saved parts, starting from 0.
wrt_dt+ 
wrt_dt+ # You can obtain the same result as as the previous examples using arrow with
wrt_dt+ # a dplyr pipeline. This will be the same as two_levels_tree above, but the
wrt_dt+ # output directory will be different.
wrt_dt+ library(dplyr)
wrt_dt+ two_levels_tree_2 <- tempfile()
wrt_dt+ mtcars %>%
wrt_dt+   group_by(cyl, gear) %>%
wrt_dt+   write_dataset(two_levels_tree_2)
wrt_dt+ list.files(two_levels_tree_2, recursive = TRUE)
wrt_dt+ 
wrt_dt+ # And you can also turn off the Hive-style directory naming where the column
wrt_dt+ # name is included with the values by using `hive_style = FALSE`.
wrt_dt+ 
wrt_dt+ # Write a structure X/Y/part-Z.parquet.
wrt_dt+ two_levels_tree_no_hive <- tempfile()
wrt_dt+ mtcars %>%
wrt_dt+   group_by(cyl, gear) %>%
wrt_dt+   write_dataset(two_levels_tree_no_hive, hive_style = FALSE)
wrt_dt+ list.files(two_levels_tree_no_hive, recursive = TRUE)
wrt_dt+ ## Don't show: 
wrt_dt+ }) # examplesIf
> one_level_tree <- tempfile()
> write_dataset(mtcars, one_level_tree, partitioning = "cyl")
[New Thread 0x7fffdb789700 (LWP 6437)]
[New Thread 0x7fffdaf88700 (LWP 6438)]
[New Thread 0x7fffda787700 (LWP 6439)]
[New Thread 0x7fffd9f86700 (LWP 6440)]

Thread 5 "R" received signal SIGILL, Illegal instruction.
[Switching to Thread 0x7fffdaf88700 (LWP 6438)]
0x00007fffe3a45367 in arrow::compute::RowTableMetadata::FromColumnMetadataVector(std::vector<arrow::compute::KeyColumnMetadata, std::allocator<arrow::compute::KeyColumnMetadata> > const&, int, int) ()
   from /home/tdhock/lib/R/library/arrow/libs/arrow.so
(gdb) disassemble
Dump of assembler code for function _ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii:
   0x00007fffe3a45120 <+0>:	push   %r15
   0x00007fffe3a45122 <+2>:	mov    %rsi,%r15
   0x00007fffe3a45125 <+5>:	push   %r14
   0x00007fffe3a45127 <+7>:	push   %r13
   0x00007fffe3a45129 <+9>:	push   %r12
   0x00007fffe3a4512b <+11>:	push   %rbp
   0x00007fffe3a4512c <+12>:	push   %rbx
   0x00007fffe3a4512d <+13>:	mov    %rdi,%rbx
   0x00007fffe3a45130 <+16>:	sub    $0x18,%rsp
   0x00007fffe3a45134 <+20>:	mov    0x8(%rsi),%rax
   0x00007fffe3a45138 <+24>:	mov    0x20(%rbx),%r8
   0x00007fffe3a4513c <+28>:	mov    %ecx,0x4(%rsp)
   0x00007fffe3a45140 <+32>:	mov    (%rsi),%rcx
   0x00007fffe3a45143 <+35>:	mov    0x18(%rdi),%rdi
   0x00007fffe3a45147 <+39>:	mov    %edx,(%rsp)
   0x00007fffe3a4514a <+42>:	mov    %r8,%rdx
   0x00007fffe3a4514d <+45>:	sub    %rcx,%rax
   0x00007fffe3a45150 <+48>:	mov    %rax,%rsi
   0x00007fffe3a45153 <+51>:	sub    %rdi,%rdx
   0x00007fffe3a45156 <+54>:	sar    $0x3,%rsi
   0x00007fffe3a4515a <+58>:	sar    $0x3,%rdx
--Type <RET> for more, q to quit, c to continue without paging--c
   0x00007fffe3a4515e <+62>:	cmp    %rdx,%rsi
   0x00007fffe3a45161 <+65>:	ja     0x7fffe3a45508 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+1000>
   0x00007fffe3a45167 <+71>:	mov    %rsi,%r14
   0x00007fffe3a4516a <+74>:	jae    0x7fffe3a45189 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+105>
   0x00007fffe3a4516c <+76>:	add    %rdi,%rax
   0x00007fffe3a4516f <+79>:	cmp    %rax,%r8
   0x00007fffe3a45172 <+82>:	je     0x7fffe3a45189 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+105>
   0x00007fffe3a45174 <+84>:	mov    %rax,0x20(%rbx)
   0x00007fffe3a45178 <+88>:	mov    (%r15),%rcx
   0x00007fffe3a4517b <+91>:	mov    0x8(%r15),%rsi
   0x00007fffe3a4517f <+95>:	sub    %rcx,%rsi
   0x00007fffe3a45182 <+98>:	sar    $0x3,%rsi
   0x00007fffe3a45186 <+102>:	mov    %rsi,%r14
   0x00007fffe3a45189 <+105>:	mov    0x38(%rbx),%rbp
   0x00007fffe3a4518d <+109>:	mov    0x30(%rbx),%r8
   0x00007fffe3a45191 <+113>:	mov    %rbp,%r10
   0x00007fffe3a45194 <+116>:	sub    %r8,%r10
   0x00007fffe3a45197 <+119>:	sar    $0x2,%r10
   0x00007fffe3a4519b <+123>:	test   %r14,%r14
   0x00007fffe3a4519e <+126>:	je     0x7fffe3a45490 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+880>
   0x00007fffe3a451a4 <+132>:	mov    0x18(%rbx),%rdi
   0x00007fffe3a451a8 <+136>:	xor    %eax,%eax
   0x00007fffe3a451aa <+138>:	nopw   0x0(%rax,%rax,1)
   0x00007fffe3a451b0 <+144>:	mov    (%rcx,%rax,8),%rdx
   0x00007fffe3a451b4 <+148>:	mov    %rdx,(%rdi,%rax,8)
   0x00007fffe3a451b8 <+152>:	add    $0x1,%rax
   0x00007fffe3a451bc <+156>:	cmp    %r14,%rax
   0x00007fffe3a451bf <+159>:	jne    0x7fffe3a451b0 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+144>
   0x00007fffe3a451c1 <+161>:	mov    %esi,%r14d
   0x00007fffe3a451c4 <+164>:	mov    %esi,%r13d
   0x00007fffe3a451c7 <+167>:	cmp    %r10,%r14
   0x00007fffe3a451ca <+170>:	ja     0x7fffe3a45520 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+1024>
   0x00007fffe3a451d0 <+176>:	jb     0x7fffe3a454a0 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+896>
   0x00007fffe3a451d6 <+182>:	test   %r13d,%r13d
   0x00007fffe3a451d9 <+185>:	je     0x7fffe3a4523e <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+286>
   0x00007fffe3a451db <+187>:	lea    -0x1(%r13),%eax
   0x00007fffe3a451df <+191>:	cmp    $0x2,%eax
   0x00007fffe3a451e2 <+194>:	jbe    0x7fffe3a4553c <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+1052>
   0x00007fffe3a451e8 <+200>:	mov    %r13d,%edx
   0x00007fffe3a451eb <+203>:	movdqa 0xff39cd(%rip),%xmm0        # 0x7fffe4a38bc0
   0x00007fffe3a451f3 <+211>:	movdqa 0xff39d5(%rip),%xmm1        # 0x7fffe4a38bd0
   0x00007fffe3a451fb <+219>:	mov    %r8,%rax
   0x00007fffe3a451fe <+222>:	shr    $0x2,%edx
   0x00007fffe3a45201 <+225>:	sub    $0x1,%edx
   0x00007fffe3a45204 <+228>:	shl    $0x4,%rdx
   0x00007fffe3a45208 <+232>:	lea    0x10(%r8,%rdx,1),%rdx
   0x00007fffe3a4520d <+237>:	nopl   (%rax)
   0x00007fffe3a45210 <+240>:	movups %xmm0,(%rax)
   0x00007fffe3a45213 <+243>:	add    $0x10,%rax
   0x00007fffe3a45217 <+247>:	paddd  %xmm1,%xmm0
   0x00007fffe3a4521b <+251>:	cmp    %rax,%rdx
   0x00007fffe3a4521e <+254>:	jne    0x7fffe3a45210 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+240>
   0x00007fffe3a45220 <+256>:	mov    %r13d,%eax
   0x00007fffe3a45223 <+259>:	and    $0xfffffffc,%eax
   0x00007fffe3a45226 <+262>:	cmp    %eax,%r13d
   0x00007fffe3a45229 <+265>:	je     0x7fffe3a4523e <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+286>
   0x00007fffe3a4522b <+267>:	nopl   0x0(%rax,%rax,1)
   0x00007fffe3a45230 <+272>:	mov    %eax,%edx
   0x00007fffe3a45232 <+274>:	mov    %eax,(%r8,%rdx,4)
   0x00007fffe3a45236 <+278>:	add    $0x1,%eax
   0x00007fffe3a45239 <+281>:	cmp    %eax,%r13d
   0x00007fffe3a4523c <+284>:	ja     0x7fffe3a45230 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+272>
   0x00007fffe3a4523e <+286>:	cmp    %r8,%rbp
   0x00007fffe3a45241 <+289>:	je     0x7fffe3a452b4 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+404>
   0x00007fffe3a45243 <+291>:	mov    %rbp,%r12
   0x00007fffe3a45246 <+294>:	mov    $0x3f,%edx
   0x00007fffe3a4524b <+299>:	mov    %r8,%rdi
   0x00007fffe3a4524e <+302>:	mov    %r15,%rcx
   0x00007fffe3a45251 <+305>:	sub    %r8,%r12
   0x00007fffe3a45254 <+308>:	mov    %rbp,%rsi
   0x00007fffe3a45257 <+311>:	mov    %r8,0x8(%rsp)
   0x00007fffe3a4525c <+316>:	mov    %r12,%rax
   0x00007fffe3a4525f <+319>:	sar    $0x2,%rax
   0x00007fffe3a45263 <+323>:	bsr    %rax,%rax
   0x00007fffe3a45267 <+327>:	xor    $0x3f,%rax
   0x00007fffe3a4526b <+331>:	cltq   
   0x00007fffe3a4526d <+333>:	sub    %rax,%rdx
   0x00007fffe3a45270 <+336>:	add    %rdx,%rdx
   0x00007fffe3a45273 <+339>:	call   0x7fffe3a43cd0 <_ZSt16__introsort_loopIN9__gnu_cxx17__normal_iteratorIPjSt6vectorIjSaIjEEEElNS0_5__ops15_Iter_comp_iterIZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKS3_INSA_17KeyColumnMetadataESaISC_EEiiEUljjE_EEEvT_SJ_T0_T1_>
   0x00007fffe3a45278 <+344>:	cmp    $0x40,%r12
   0x00007fffe3a4527c <+348>:	mov    0x8(%rsp),%r8
   0x00007fffe3a45281 <+353>:	jle    0x7fffe3a454c0 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+928>
   0x00007fffe3a45287 <+359>:	lea    0x40(%r8),%r12
   0x00007fffe3a4528b <+363>:	mov    %r15,%rdx
   0x00007fffe3a4528e <+366>:	mov    %r8,%rdi
   0x00007fffe3a45291 <+369>:	mov    %r12,%rsi
   0x00007fffe3a45294 <+372>:	call   0x7fffe3a43850 <_ZSt16__insertion_sortIN9__gnu_cxx17__normal_iteratorIPjSt6vectorIjSaIjEEEENS0_5__ops15_Iter_comp_iterIZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKS3_INSA_17KeyColumnMetadataESaISC_EEiiEUljjE_EEEvT_SJ_T0_>
   0x00007fffe3a45299 <+377>:	cmp    %rbp,%r12
   0x00007fffe3a4529c <+380>:	je     0x7fffe3a452b4 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+404>
   0x00007fffe3a4529e <+382>:	xchg   %ax,%ax
   0x00007fffe3a452a0 <+384>:	mov    %r12,%rdi
   0x00007fffe3a452a3 <+387>:	mov    %r15,%rsi
   0x00007fffe3a452a6 <+390>:	add    $0x4,%r12
   0x00007fffe3a452aa <+394>:	call   0x7fffe3a43760 <_ZSt25__unguarded_linear_insertIN9__gnu_cxx17__normal_iteratorIPjSt6vectorIjSaIjEEEENS0_5__ops14_Val_comp_iterIZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKS3_INSA_17KeyColumnMetadataESaISC_EEiiEUljjE_EEEvT_T0_>
   0x00007fffe3a452af <+399>:	cmp    %r12,%rbp
   0x00007fffe3a452b2 <+402>:	jne    0x7fffe3a452a0 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+384>
   0x00007fffe3a452b4 <+404>:	mov    0x50(%rbx),%rdx
   0x00007fffe3a452b8 <+408>:	mov    0x48(%rbx),%rcx
   0x00007fffe3a452bc <+412>:	mov    %rdx,%rax
   0x00007fffe3a452bf <+415>:	sub    %rcx,%rax
   0x00007fffe3a452c2 <+418>:	sar    $0x2,%rax
   0x00007fffe3a452c6 <+422>:	cmp    %rax,%r14
   0x00007fffe3a452c9 <+425>:	ja     0x7fffe3a454f0 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+976>
   0x00007fffe3a452cf <+431>:	jb     0x7fffe3a45470 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+848>
   0x00007fffe3a452d5 <+437>:	test   %r13d,%r13d
   0x00007fffe3a452d8 <+440>:	je     0x7fffe3a45302 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+482>
   0x00007fffe3a452da <+442>:	mov    0x30(%rbx),%rdi
   0x00007fffe3a452de <+446>:	mov    0x48(%rbx),%rsi
   0x00007fffe3a452e2 <+450>:	lea    -0x1(%r13),%ecx
   0x00007fffe3a452e6 <+454>:	xor    %eax,%eax
   0x00007fffe3a452e8 <+456>:	jmp    0x7fffe3a452f3 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+467>
   0x00007fffe3a452ea <+458>:	nopw   0x0(%rax,%rax,1)
   0x00007fffe3a452f0 <+464>:	mov    %rdx,%rax
   0x00007fffe3a452f3 <+467>:	mov    (%rdi,%rax,4),%edx
   0x00007fffe3a452f6 <+470>:	mov    %eax,(%rsi,%rdx,4)
   0x00007fffe3a452f9 <+473>:	lea    0x1(%rax),%rdx
   0x00007fffe3a452fd <+477>:	cmp    %rax,%rcx
   0x00007fffe3a45300 <+480>:	jne    0x7fffe3a452f0 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+464>
   0x00007fffe3a45302 <+482>:	mov    (%rsp),%eax
   0x00007fffe3a45305 <+485>:	mov    0x68(%rbx),%rdx
   0x00007fffe3a45309 <+489>:	movl   $0x0,0x8(%rbx)
   0x00007fffe3a45310 <+496>:	mov    0x60(%rbx),%rcx
   0x00007fffe3a45314 <+500>:	mov    %eax,0x10(%rbx)
   0x00007fffe3a45317 <+503>:	mov    0x4(%rsp),%eax
   0x00007fffe3a4531b <+507>:	mov    %eax,0x14(%rbx)
   0x00007fffe3a4531e <+510>:	mov    %rdx,%rax
   0x00007fffe3a45321 <+513>:	sub    %rcx,%rax
   0x00007fffe3a45324 <+516>:	sar    $0x2,%rax
   0x00007fffe3a45328 <+520>:	cmp    %rax,%r14
   0x00007fffe3a4532b <+523>:	ja     0x7fffe3a454d8 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+952>
   0x00007fffe3a45331 <+529>:	jb     0x7fffe3a45430 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+784>
   0x00007fffe3a45337 <+535>:	test   %r13d,%r13d
   0x00007fffe3a4533a <+538>:	je     0x7fffe3a4544a <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+810>
   0x00007fffe3a45340 <+544>:	lea    -0x1(%r13),%eax
   0x00007fffe3a45344 <+548>:	mov    0x30(%rbx),%r11
   0x00007fffe3a45348 <+552>:	mov    (%r15),%rbp
   0x00007fffe3a4534b <+555>:	xor    %edx,%edx
   0x00007fffe3a4534d <+557>:	lea    0x4(,%rax,4),%r10
   0x00007fffe3a45355 <+565>:	mov    0x60(%rbx),%r9
   0x00007fffe3a45359 <+569>:	xor    %eax,%eax
   0x00007fffe3a4535b <+571>:	xor    %r8d,%r8d
   0x00007fffe3a4535e <+574>:	jmp    0x7fffe3a4539b <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+635>
   0x00007fffe3a45360 <+576>:	mov    0x4(%rcx),%esi
   0x00007fffe3a45363 <+579>:	test   %esi,%esi
   0x00007fffe3a45365 <+581>:	je     0x7fffe3a45382 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+610>
=> 0x00007fffe3a45367 <+583>:	popcnt %rsi,%rsi
   0x00007fffe3a4536c <+588>:	cmp    $0x1,%esi
   0x00007fffe3a4536f <+591>:	je     0x7fffe3a45382 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+610>
   0x00007fffe3a45371 <+593>:	mov    0x14(%rbx),%esi
   0x00007fffe3a45374 <+596>:	mov    %eax,%r12d
   0x00007fffe3a45377 <+599>:	neg    %r12d
   0x00007fffe3a4537a <+602>:	sub    $0x1,%esi
   0x00007fffe3a4537d <+605>:	and    %r12d,%esi
   0x00007fffe3a45380 <+608>:	add    %esi,%eax
   0x00007fffe3a45382 <+610>:	mov    %eax,(%rdi)
   0x00007fffe3a45384 <+612>:	mov    0x4(%rcx),%ecx
   0x00007fffe3a45387 <+615>:	lea    (%rax,%rcx,1),%esi
   0x00007fffe3a4538a <+618>:	add    $0x1,%eax
   0x00007fffe3a4538d <+621>:	test   %ecx,%ecx
   0x00007fffe3a4538f <+623>:	cmovne %esi,%eax
   0x00007fffe3a45392 <+626>:	add    $0x4,%rdx
   0x00007fffe3a45396 <+630>:	cmp    %rdx,%r10
   0x00007fffe3a45399 <+633>:	je     0x7fffe3a453c7 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+679>
   0x00007fffe3a4539b <+635>:	mov    (%r11,%rdx,1),%ecx
   0x00007fffe3a4539f <+639>:	lea    (%r9,%rdx,1),%rdi
   0x00007fffe3a453a3 <+643>:	lea    0x0(%rbp,%rcx,8),%rcx
   0x00007fffe3a453a8 <+648>:	cmpb   $0x0,(%rcx)
   0x00007fffe3a453ab <+651>:	jne    0x7fffe3a45360 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+576>
   0x00007fffe3a453ad <+653>:	mov    %eax,(%rdi)
   0x00007fffe3a453af <+655>:	test   %r8d,%r8d
   0x00007fffe3a453b2 <+658>:	jne    0x7fffe3a453b7 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+663>
   0x00007fffe3a453b4 <+660>:	mov    %eax,0x8(%rbx)
   0x00007fffe3a453b7 <+663>:	add    $0x4,%rdx
   0x00007fffe3a453bb <+667>:	add    $0x1,%r8d
   0x00007fffe3a453bf <+671>:	add    $0x4,%eax
   0x00007fffe3a453c2 <+674>:	cmp    %rdx,%r10
   0x00007fffe3a453c5 <+677>:	jne    0x7fffe3a4539b <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+635>
   0x00007fffe3a453c7 <+679>:	test   %r8d,%r8d
   0x00007fffe3a453ca <+682>:	mov    %eax,%ecx
   0x00007fffe3a453cc <+684>:	sete   (%rbx)
   0x00007fffe3a453cf <+687>:	neg    %ecx
   0x00007fffe3a453d1 <+689>:	test   %r8d,%r8d
   0x00007fffe3a453d4 <+692>:	je     0x7fffe3a45420 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+768>
   0x00007fffe3a453d6 <+694>:	mov    0x14(%rbx),%edi
   0x00007fffe3a453d9 <+697>:	lea    -0x1(%rdi),%edx
   0x00007fffe3a453dc <+700>:	and    %ecx,%edx
   0x00007fffe3a453de <+702>:	add    %edx,%eax
   0x00007fffe3a453e0 <+704>:	mov    %eax,0x4(%rbx)
   0x00007fffe3a453e3 <+707>:	movl   $0x1,0xc(%rbx)
   0x00007fffe3a453ea <+714>:	cmp    $0x8,%r13d
   0x00007fffe3a453ee <+718>:	jbe    0x7fffe3a45407 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+743>
   0x00007fffe3a453f0 <+720>:	mov    $0x1,%eax
   0x00007fffe3a453f5 <+725>:	nopl   (%rax)
   0x00007fffe3a453f8 <+728>:	mov    %eax,%edx
   0x00007fffe3a453fa <+730>:	add    %eax,%eax
   0x00007fffe3a453fc <+732>:	shl    $0x4,%edx
   0x00007fffe3a453ff <+735>:	cmp    %r13d,%edx
   0x00007fffe3a45402 <+738>:	jb     0x7fffe3a453f8 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+728>
   0x00007fffe3a45404 <+740>:	mov    %eax,0xc(%rbx)
   0x00007fffe3a45407 <+743>:	add    $0x18,%rsp
   0x00007fffe3a4540b <+747>:	pop    %rbx
   0x00007fffe3a4540c <+748>:	pop    %rbp
   0x00007fffe3a4540d <+749>:	pop    %r12
   0x00007fffe3a4540f <+751>:	pop    %r13
   0x00007fffe3a45411 <+753>:	pop    %r14
   0x00007fffe3a45413 <+755>:	pop    %r15
   0x00007fffe3a45415 <+757>:	ret    
   0x00007fffe3a45416 <+758>:	nopw   %cs:0x0(%rax,%rax,1)
   0x00007fffe3a45420 <+768>:	mov    0x10(%rbx),%edi
   0x00007fffe3a45423 <+771>:	lea    -0x1(%rdi),%edx
   0x00007fffe3a45426 <+774>:	and    %ecx,%edx
   0x00007fffe3a45428 <+776>:	add    %edx,%eax
   0x00007fffe3a4542a <+778>:	jmp    0x7fffe3a453e0 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+704>
   0x00007fffe3a4542c <+780>:	nopl   0x0(%rax)
   0x00007fffe3a45430 <+784>:	lea    (%rcx,%r14,4),%rax
   0x00007fffe3a45434 <+788>:	cmp    %rax,%rdx
   0x00007fffe3a45437 <+791>:	je     0x7fffe3a45337 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+535>
   0x00007fffe3a4543d <+797>:	mov    %rax,0x68(%rbx)
   0x00007fffe3a45441 <+801>:	test   %r13d,%r13d
   0x00007fffe3a45444 <+804>:	jne    0x7fffe3a45340 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+544>
   0x00007fffe3a4544a <+810>:	movb   $0x1,(%rbx)
   0x00007fffe3a4544d <+813>:	movl   $0x0,0x4(%rbx)
   0x00007fffe3a45454 <+820>:	movl   $0x1,0xc(%rbx)
   0x00007fffe3a4545b <+827>:	add    $0x18,%rsp
   0x00007fffe3a4545f <+831>:	pop    %rbx
   0x00007fffe3a45460 <+832>:	pop    %rbp
   0x00007fffe3a45461 <+833>:	pop    %r12
   0x00007fffe3a45463 <+835>:	pop    %r13
   0x00007fffe3a45465 <+837>:	pop    %r14
   0x00007fffe3a45467 <+839>:	pop    %r15
   0x00007fffe3a45469 <+841>:	ret    
   0x00007fffe3a4546a <+842>:	nopw   0x0(%rax,%rax,1)
   0x00007fffe3a45470 <+848>:	lea    (%rcx,%r14,4),%rax
   0x00007fffe3a45474 <+852>:	cmp    %rax,%rdx
   0x00007fffe3a45477 <+855>:	je     0x7fffe3a452d5 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+437>
   0x00007fffe3a4547d <+861>:	mov    %rax,0x50(%rbx)
   0x00007fffe3a45481 <+865>:	jmp    0x7fffe3a452d5 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+437>
   0x00007fffe3a45486 <+870>:	nopw   %cs:0x0(%rax,%rax,1)
   0x00007fffe3a45490 <+880>:	xor    %r13d,%r13d
   0x00007fffe3a45493 <+883>:	test   %r10,%r10
   0x00007fffe3a45496 <+886>:	je     0x7fffe3a4523e <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+286>
   0x00007fffe3a4549c <+892>:	nopl   0x0(%rax)
   0x00007fffe3a454a0 <+896>:	lea    (%r8,%r14,4),%rax
   0x00007fffe3a454a4 <+900>:	cmp    %rbp,%rax
   0x00007fffe3a454a7 <+903>:	je     0x7fffe3a451d6 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+182>
   0x00007fffe3a454ad <+909>:	mov    %rax,0x38(%rbx)
   0x00007fffe3a454b1 <+913>:	mov    %rax,%rbp
   0x00007fffe3a454b4 <+916>:	jmp    0x7fffe3a451d6 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+182>
   0x00007fffe3a454b9 <+921>:	nopl   0x0(%rax)
   0x00007fffe3a454c0 <+928>:	mov    %r15,%rdx
   0x00007fffe3a454c3 <+931>:	mov    %rbp,%rsi
   0x00007fffe3a454c6 <+934>:	mov    %r8,%rdi
   0x00007fffe3a454c9 <+937>:	call   0x7fffe3a43850 <_ZSt16__insertion_sortIN9__gnu_cxx17__normal_iteratorIPjSt6vectorIjSaIjEEEENS0_5__ops15_Iter_comp_iterIZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKS3_INSA_17KeyColumnMetadataESaISC_EEiiEUljjE_EEEvT_SJ_T0_>
   0x00007fffe3a454ce <+942>:	jmp    0x7fffe3a452b4 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+404>
   0x00007fffe3a454d3 <+947>:	nopl   0x0(%rax,%rax,1)
   0x00007fffe3a454d8 <+952>:	mov    %r14,%rsi
   0x00007fffe3a454db <+955>:	lea    0x60(%rbx),%rdi
   0x00007fffe3a454df <+959>:	sub    %rax,%rsi
   0x00007fffe3a454e2 <+962>:	call   0x7fffe30d2060 <_ZNSt6vectorIjSaIjEE17_M_default_appendEm@plt>
   0x00007fffe3a454e7 <+967>:	jmp    0x7fffe3a45337 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+535>
   0x00007fffe3a454ec <+972>:	nopl   0x0(%rax)
   0x00007fffe3a454f0 <+976>:	mov    %r14,%rsi
   0x00007fffe3a454f3 <+979>:	lea    0x48(%rbx),%rdi
   0x00007fffe3a454f7 <+983>:	sub    %rax,%rsi
   0x00007fffe3a454fa <+986>:	call   0x7fffe30d2060 <_ZNSt6vectorIjSaIjEE17_M_default_appendEm@plt>
   0x00007fffe3a454ff <+991>:	jmp    0x7fffe3a452d5 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+437>
   0x00007fffe3a45504 <+996>:	nopl   0x0(%rax)
   0x00007fffe3a45508 <+1000>:	sub    %rdx,%rsi
   0x00007fffe3a4550b <+1003>:	lea    0x18(%rbx),%rdi
   0x00007fffe3a4550f <+1007>:	call   0x7fffe30d1570 <_ZNSt6vectorIN5arrow7compute17KeyColumnMetadataESaIS2_EE17_M_default_appendEm@plt>
   0x00007fffe3a45514 <+1012>:	jmp    0x7fffe3a45178 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+88>
   0x00007fffe3a45519 <+1017>:	nopl   0x0(%rax)
   0x00007fffe3a45520 <+1024>:	mov    %r14,%rsi
   0x00007fffe3a45523 <+1027>:	lea    0x30(%rbx),%rdi
   0x00007fffe3a45527 <+1031>:	sub    %r10,%rsi
   0x00007fffe3a4552a <+1034>:	call   0x7fffe30d2060 <_ZNSt6vectorIjSaIjEE17_M_default_appendEm@plt>
   0x00007fffe3a4552f <+1039>:	mov    0x30(%rbx),%r8
   0x00007fffe3a45533 <+1043>:	mov    0x38(%rbx),%rbp
   0x00007fffe3a45537 <+1047>:	jmp    0x7fffe3a451d6 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+182>
   0x00007fffe3a4553c <+1052>:	xor    %eax,%eax
   0x00007fffe3a4553e <+1054>:	jmp    0x7fffe3a45230 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+272>
End of assembler dump.
(gdb) q
A debugging session is active.

	Inferior 1 [process 6427] will be killed.

Quit anyway? (y or n) y
(base) tdhock@maude-MacBookPro:~/projects/max-generalized-auc(master*)$ 
```

Is this a bug in GCC? Shouldn't GCC know that my CPU does not support
that instruction? How does GCC know what instructions can be used?
The [x86 options](https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html)
man page explains that the `-march=cpu-type` flag tells GCC to use
certain instructions as a function of the specified CPU type.  When I
compiled arrow, I used the default GCC flags, 

```
(base) tdhock@tdhock-MacBook:~/R/binsegRcpp/src(master)$   gcc -Q --help=target |grep arch
  -march=                     		x86-64
  Arguments valides connus pour l’option -march=:
```

The above implies that on my GCC the default is `-march=x86-64` which
means "A generic CPU with 64-bit extensions." But I have "Intel(R)
Core(TM)2 Duo CPU P7350" which seems to map to `-march=core2` meaning
"Intel Core 2 CPU with 64-bit extensions, MMX, SSE, SSE2, SSE3, SSSE3,
CX16, SAHF and FXSR instruction set support." Is that consistent with
what the kernel knows about my CPU? I don't see SSE3 nor SAHF below.

```
(base) tdhock@tdhock-MacBook:~/tdhock.github.io(master*)$ grep mmx /proc/cpuinfo |head -1
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ht tm pbe syscall nx lm constant_tsc arch_perfmon pebs bts rep_good nopl cpuid aperfmperf pni dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm sse4_1 lahf_lm pti tpr_shadow vnmi flexpriority vpid dtherm
```

I tried compiling with `-march=core2`, by putting
`CPPFLAGS=-march=core2` in `~/.R/Makevars` but that still gives me a
segfault:

```
(base) tdhock@tdhock-MacBook:/tmp/Rtmp8icqQo/downloaded_packages$ ARROW_R_DEV=true R CMD INSTALL arrow_12.0.0.100000037.tar.gz 
Le chargement a nécessité le package : grDevices
* installing to library ‘/home/tdhock/lib/R/library’
* installing *source* package ‘arrow’ ...
** using staged installation
Le chargement a nécessité le package : grDevices
*** Found libcurl and OpenSSL >= 3.0.0
essai de l'URL 'https://nightlies.apache.org/arrow/r/libarrow/bin/linux-openssl-3.0/arrow-12.0.0.100000037.zip'
Content type 'application/zip' length 39699427 bytes (37.9 MB)
==================================================
downloaded 37.9 MB

*** Successfully retrieved C++ binaries (linux-openssl-3.0)
PKG_CFLAGS=-DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS
PKG_LIBS=-L/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/lib -L/usr/lib/lib/x86_64-linux-gnu -larrow_acero -larrow_dataset -lparquet -larrow -larrow_bundled_dependencies -lcurl -lssl -lcrypto  
** libs
using C++ compiler: ‘g++ (GCC) 13.1.0’
using C++17
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c RTasks.cpp -o RTasks.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c altrep.cpp -o altrep.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c array.cpp -o array.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c array_to_vector.cpp -o array_to_vector.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c arraydata.cpp -o arraydata.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c arrowExports.cpp -o arrowExports.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c bridge.cpp -o bridge.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c buffer.cpp -o buffer.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c chunkedarray.cpp -o chunkedarray.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c compression.cpp -o compression.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c compute-exec.cpp -o compute-exec.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c compute.cpp -o compute.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c config.cpp -o config.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c csv.cpp -o csv.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c dataset.cpp -o dataset.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c datatype.cpp -o datatype.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c expression.cpp -o expression.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c extension-impl.cpp -o extension-impl.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c feather.cpp -o feather.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c field.cpp -o field.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c filesystem.cpp -o filesystem.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c io.cpp -o io.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c json.cpp -o json.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c memorypool.cpp -o memorypool.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c message.cpp -o message.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c parquet.cpp -o parquet.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c r_to_arrow.cpp -o r_to_arrow.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c recordbatch.cpp -o recordbatch.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c recordbatchreader.cpp -o recordbatchreader.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c recordbatchwriter.cpp -o recordbatchwriter.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c safe-call-into-r-impl.cpp -o safe-call-into-r-impl.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c scalar.cpp -o scalar.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c schema.cpp -o schema.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c symbols.cpp -o symbols.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c table.cpp -o table.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c threadpool.cpp -o threadpool.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c type_infer.cpp -o type_infer.o
g++ -std=gnu++17 -shared -L/home/tdhock/lib/R/lib -L/usr/local/lib -o arrow.so RTasks.o altrep.o array.o array_to_vector.o arraydata.o arrowExports.o bridge.o buffer.o chunkedarray.o compression.o compute-exec.o compute.o config.o csv.o dataset.o datatype.o expression.o extension-impl.o feather.o field.o filesystem.o io.o json.o memorypool.o message.o parquet.o r_to_arrow.o recordbatch.o recordbatchreader.o recordbatchwriter.o safe-call-into-r-impl.o scalar.o schema.o symbols.o table.o threadpool.o type_infer.o -L/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/lib -L/usr/lib/lib/x86_64-linux-gnu -larrow_acero -larrow_dataset -lparquet -larrow -larrow_bundled_dependencies -lcurl -lssl -lcrypto -L/home/tdhock/lib/R/lib -lR
installing to /home/tdhock/lib/R/library/00LOCK-arrow/00new/arrow/libs
** R
** inst
** byte-compile and prepare package for lazy loading
Le chargement a nécessité le package : grDevices
** help
*** installing help indices
** building package indices
Le chargement a nécessité le package : grDevices
** testing if installed package can be loaded from temporary location
Le chargement a nécessité le package : grDevices
** checking absolute paths in shared objects and dynamic libraries
** testing if installed package can be loaded from final location
Le chargement a nécessité le package : grDevices
** testing if installed package keeps a record of temporary installation path
* DONE (arrow)
(base) tdhock@tdhock-MacBook:/tmp/Rtmp8icqQo/downloaded_packages$ R --vanilla -e 'example("write_dataset",package="arrow")'

R version 4.3.0 (2023-04-21) -- "Already Tomorrow"
Copyright (C) 2023 The R Foundation for Statistical Computing
Platform: x86_64-pc-linux-gnu (64-bit)

R est un logiciel libre livré sans AUCUNE GARANTIE.
Vous pouvez le redistribuer sous certaines conditions.
Tapez 'license()' ou 'licence()' pour plus de détails.

R est un projet collaboratif avec de nombreux contributeurs.
Tapez 'contributors()' pour plus d'information et
'citation()' pour la façon de le citer dans les publications.

Tapez 'demo()' pour des démonstrations, 'help()' pour l'aide
en ligne ou 'help.start()' pour obtenir l'aide au format HTML.
Tapez 'q()' pour quitter R.

> example("write_dataset",package="arrow")

Attachement du package : ‘arrow’

L'objet suivant est masqué depuis ‘package:utils’:

    timestamp


wrt_dt> ## Don't show: 
wrt_dt> if (arrow_with_dataset() & arrow_with_parquet() & requireNamespace("dplyr", quietly = TRUE)) (if (getRversion() >= "3.4") withAutoprint else force)({ # examplesIf
wrt_dt+ ## End(Don't show)
wrt_dt+ # You can write datasets partitioned by the values in a column (here: "cyl").
wrt_dt+ # This creates a structure of the form cyl=X/part-Z.parquet.
wrt_dt+ one_level_tree <- tempfile()
wrt_dt+ write_dataset(mtcars, one_level_tree, partitioning = "cyl")
wrt_dt+ list.files(one_level_tree, recursive = TRUE)
wrt_dt+ 
wrt_dt+ # You can also partition by the values in multiple columns
wrt_dt+ # (here: "cyl" and "gear").
wrt_dt+ # This creates a structure of the form cyl=X/gear=Y/part-Z.parquet.
wrt_dt+ two_levels_tree <- tempfile()
wrt_dt+ write_dataset(mtcars, two_levels_tree, partitioning = c("cyl", "gear"))
wrt_dt+ list.files(two_levels_tree, recursive = TRUE)
wrt_dt+ 
wrt_dt+ # In the two previous examples we would have:
wrt_dt+ # X = {4,6,8}, the number of cylinders.
wrt_dt+ # Y = {3,4,5}, the number of forward gears.
wrt_dt+ # Z = {0,1,2}, the number of saved parts, starting from 0.
wrt_dt+ 
wrt_dt+ # You can obtain the same result as as the previous examples using arrow with
wrt_dt+ # a dplyr pipeline. This will be the same as two_levels_tree above, but the
wrt_dt+ # output directory will be different.
wrt_dt+ library(dplyr)
wrt_dt+ two_levels_tree_2 <- tempfile()
wrt_dt+ mtcars %>%
wrt_dt+   group_by(cyl, gear) %>%
wrt_dt+   write_dataset(two_levels_tree_2)
wrt_dt+ list.files(two_levels_tree_2, recursive = TRUE)
wrt_dt+ 
wrt_dt+ # And you can also turn off the Hive-style directory naming where the column
wrt_dt+ # name is included with the values by using `hive_style = FALSE`.
wrt_dt+ 
wrt_dt+ # Write a structure X/Y/part-Z.parquet.
wrt_dt+ two_levels_tree_no_hive <- tempfile()
wrt_dt+ mtcars %>%
wrt_dt+   group_by(cyl, gear) %>%
wrt_dt+   write_dataset(two_levels_tree_no_hive, hive_style = FALSE)
wrt_dt+ list.files(two_levels_tree_no_hive, recursive = TRUE)
wrt_dt+ ## Don't show: 
wrt_dt+ }) # examplesIf
> one_level_tree <- tempfile()
> write_dataset(mtcars, one_level_tree, partitioning = "cyl")

 *** caught illegal operation ***
address 0x7f8cb6c1faa7, cause 'illegal operand'

Traceback:
 1: ExecPlan_Write(self, node, prepare_key_value_metadata(node$final_metadata()),     ...)
 2: plan$Write(final_node, options, path_and_fs$fs, path_and_fs$path,     partitioning, basename_template, existing_data_behavior,     max_partitions, max_open_files, max_rows_per_file, min_rows_per_group,     max_rows_per_group)
 3: write_dataset(mtcars, one_level_tree, partitioning = "cyl")
 4: eval(ei, envir)
 5: eval(ei, envir)
 6: withVisible(eval(ei, envir))
 7: source(exprs = exprs, local = local, print.eval = print., echo = echo,     max.deparse.length = max.deparse.length, width.cutoff = width.cutoff,     deparseCtrl = deparseCtrl, ...)
 8: (if (getRversion() >= "3.4") withAutoprint else force)({    one_level_tree <- tempfile()    write_dataset(mtcars, one_level_tree, partitioning = "cyl")    list.files(one_level_tree, recursive = TRUE)    two_levels_tree <- tempfile()    write_dataset(mtcars, two_levels_tree, partitioning = c("cyl",         "gear"))    list.files(two_levels_tree, recursive = TRUE)    library(dplyr)    two_levels_tree_2 <- tempfile()    mtcars %>% group_by(cyl, gear) %>% write_dataset(two_levels_tree_2)    list.files(two_levels_tree_2, recursive = TRUE)    two_levels_tree_no_hive <- tempfile()    mtcars %>% group_by(cyl, gear) %>% write_dataset(two_levels_tree_no_hive,         hive_style = FALSE)    list.files(two_levels_tree_no_hive, recursive = TRUE)})
 9: eval(ei, envir)
10: eval(ei, envir)
11: withVisible(eval(ei, envir))
12: source(tf, local, echo = echo, prompt.echo = paste0(prompt.prefix,     getOption("prompt")), continue.echo = paste0(prompt.prefix,     getOption("continue")), verbose = verbose, max.deparse.length = Inf,     encoding = "UTF-8", skip.echo = skips, keep.source = TRUE)
13: example("write_dataset", package = "arrow")
An irrecoverable exception occurred. R is aborting now ...
Instruction non permise (core dumped)
(base) tdhock@tdhock-MacBook:/tmp/Rtmp8icqQo/downloaded_packages$ R -d gdb
GNU gdb (Ubuntu 12.1-0ubuntu1~22.04) 12.1
Copyright (C) 2022 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
Type "show copying" and "show warranty" for details.
This GDB was configured as "x86_64-linux-gnu".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<https://www.gnu.org/software/gdb/bugs/>.
Find the GDB manual and other documentation resources online at:
    <http://www.gnu.org/software/gdb/documentation/>.

For help, type "help".
Type "apropos word" to search for commands related to "word"...
Reading symbols from /home/tdhock/lib/R/bin/exec/R...
(gdb) run
Starting program: /home/tdhock/lib/R/bin/exec/R 
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/usr/lib/x86_64-linux-gnu/libthread_db.so.1".

R version 4.3.0 (2023-04-21) -- "Already Tomorrow"
Copyright (C) 2023 The R Foundation for Statistical Computing
Platform: x86_64-pc-linux-gnu (64-bit)

R est un logiciel libre livré sans AUCUNE GARANTIE.
Vous pouvez le redistribuer sous certaines conditions.
Tapez 'license()' ou 'licence()' pour plus de détails.

R est un projet collaboratif avec de nombreux contributeurs.
Tapez 'contributors()' pour plus d'information et
'citation()' pour la façon de le citer dans les publications.

Tapez 'demo()' pour des démonstrations, 'help()' pour l'aide
en ligne ou 'help.start()' pour obtenir l'aide au format HTML.
Tapez 'q()' pour quitter R.

Le chargement a nécessité le package : grDevices
[Detaching after vfork from child process 30368]
[Detaching after vfork from child process 30370]
> example("write_dataset",package="arrow")
[New Thread 0x7fffee041640 (LWP 30373)]
[New Thread 0x7fffe8bff640 (LWP 30374)]

Attachement du package : ‘arrow’

L'objet suivant est masqué depuis ‘package:utils’:

    timestamp


wrt_dt> ## Don't show: 
wrt_dt> if (arrow_with_dataset() & arrow_with_parquet() & requireNamespace("dplyr", quietly = TRUE)) (if (getRversion() >= "3.4") withAutoprint else force)({ # examplesIf
wrt_dt+ ## End(Don't show)
wrt_dt+ # You can write datasets partitioned by the values in a column (here: "cyl").
wrt_dt+ # This creates a structure of the form cyl=X/part-Z.parquet.
wrt_dt+ one_level_tree <- tempfile()
wrt_dt+ write_dataset(mtcars, one_level_tree, partitioning = "cyl")
wrt_dt+ list.files(one_level_tree, recursive = TRUE)
wrt_dt+ 
wrt_dt+ # You can also partition by the values in multiple columns
wrt_dt+ # (here: "cyl" and "gear").
wrt_dt+ # This creates a structure of the form cyl=X/gear=Y/part-Z.parquet.
wrt_dt+ two_levels_tree <- tempfile()
wrt_dt+ write_dataset(mtcars, two_levels_tree, partitioning = c("cyl", "gear"))
wrt_dt+ list.files(two_levels_tree, recursive = TRUE)
wrt_dt+ 
wrt_dt+ # In the two previous examples we would have:
wrt_dt+ # X = {4,6,8}, the number of cylinders.
wrt_dt+ # Y = {3,4,5}, the number of forward gears.
wrt_dt+ # Z = {0,1,2}, the number of saved parts, starting from 0.
wrt_dt+ 
wrt_dt+ # You can obtain the same result as as the previous examples using arrow with
wrt_dt+ # a dplyr pipeline. This will be the same as two_levels_tree above, but the
wrt_dt+ # output directory will be different.
wrt_dt+ library(dplyr)
wrt_dt+ two_levels_tree_2 <- tempfile()
wrt_dt+ mtcars %>%
wrt_dt+   group_by(cyl, gear) %>%
wrt_dt+   write_dataset(two_levels_tree_2)
wrt_dt+ list.files(two_levels_tree_2, recursive = TRUE)
wrt_dt+ 
wrt_dt+ # And you can also turn off the Hive-style directory naming where the column
wrt_dt+ # name is included with the values by using `hive_style = FALSE`.
wrt_dt+ 
wrt_dt+ # Write a structure X/Y/part-Z.parquet.
wrt_dt+ two_levels_tree_no_hive <- tempfile()
wrt_dt+ mtcars %>%
wrt_dt+   group_by(cyl, gear) %>%
wrt_dt+   write_dataset(two_levels_tree_no_hive, hive_style = FALSE)
wrt_dt+ list.files(two_levels_tree_no_hive, recursive = TRUE)
wrt_dt+ ## Don't show: 
wrt_dt+ }) # examplesIf
> one_level_tree <- tempfile()
> write_dataset(mtcars, one_level_tree, partitioning = "cyl")
[New Thread 0x7fffe3fff640 (LWP 30375)]
[New Thread 0x7fffe366f640 (LWP 30376)]
[New Thread 0x7fffe2cdf640 (LWP 30377)]
[New Thread 0x7fffe234f640 (LWP 30378)]

Thread 4 "R" received signal SIGILL, Illegal instruction.
[Switching to Thread 0x7fffe3fff640 (LWP 30375)]
0x00007fffeb5aeaa7 in arrow::compute::RowTableMetadata::FromColumnMetadataVector(std::vector<arrow::compute::KeyColumnMetadata, std::allocator<arrow::compute::KeyColumnMetadata> > const&, int, int) () from /home/tdhock/lib/R/library/arrow/libs/arrow.so
(gdb) disassemble
Dump of assembler code for function _ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii:
   0x00007fffeb5ae780 <+0>:	endbr64 
   0x00007fffeb5ae784 <+4>:	push   %r15
   0x00007fffeb5ae786 <+6>:	movd   %edx,%xmm3
   0x00007fffeb5ae78a <+10>:	push   %r14
   0x00007fffeb5ae78c <+12>:	pinsrd $0x1,%ecx,%xmm3
   0x00007fffeb5ae792 <+18>:	push   %r13
   0x00007fffeb5ae794 <+20>:	push   %r12
   0x00007fffeb5ae796 <+22>:	push   %rbp
   0x00007fffeb5ae797 <+23>:	push   %rbx
   0x00007fffeb5ae798 <+24>:	mov    %rdi,%rbx
   0x00007fffeb5ae79b <+27>:	sub    $0x28,%rsp
   0x00007fffeb5ae79f <+31>:	mov    0x8(%rsi),%rax
   0x00007fffeb5ae7a3 <+35>:	mov    (%rsi),%rcx
   0x00007fffeb5ae7a6 <+38>:	mov    0x20(%rbx),%r8
   0x00007fffeb5ae7aa <+42>:	mov    0x18(%rbx),%rdx
   0x00007fffeb5ae7ae <+46>:	mov    %rsi,0x8(%rsp)
   0x00007fffeb5ae7b3 <+51>:	mov    %rax,0x18(%rsp)
   0x00007fffeb5ae7b8 <+56>:	sub    %rcx,%rax
   0x00007fffeb5ae7bb <+59>:	mov    %r8,%rsi
   0x00007fffeb5ae7be <+62>:	mov    %rax,%rdi
   0x00007fffeb5ae7c1 <+65>:	movq   %xmm3,0x10(%rsp)
   0x00007fffeb5ae7c7 <+71>:	sub    %rdx,%rsi
   0x00007fffeb5ae7ca <+74>:	sar    $0x3,%rdi
   0x00007fffeb5ae7ce <+78>:	cmp    %rsi,%rax
   0x00007fffeb5ae7d1 <+81>:	ja     0x7fffeb5aec90 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+1296>
   0x00007fffeb5ae7d7 <+87>:	mov    %rdi,%r12
   0x00007fffeb5ae7da <+90>:	jae    0x7fffeb5ae803 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+131>
   0x00007fffeb5ae7dc <+92>:	add    %rax,%rdx
   0x00007fffeb5ae7df <+95>:	cmp    %rdx,%r8
   0x00007fffeb5ae7e2 <+98>:	je     0x7fffeb5ae803 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+131>
   0x00007fffeb5ae7e4 <+100>:	mov    %rdx,0x20(%rbx)
   0x00007fffeb5ae7e8 <+104>:	mov    0x8(%rsp),%rax
   0x00007fffeb5ae7ed <+109>:	mov    0x8(%rax),%rax
   0x00007fffeb5ae7f1 <+113>:	mov    %rax,%rdi
   0x00007fffeb5ae7f4 <+116>:	mov    %rax,0x18(%rsp)
   0x00007fffeb5ae7f9 <+121>:	sub    %rcx,%rdi
   0x00007fffeb5ae7fc <+124>:	sar    $0x3,%rdi
   0x00007fffeb5ae800 <+128>:	mov    %rdi,%r12
   0x00007fffeb5ae803 <+131>:	mov    0x38(%rbx),%rax
   0x00007fffeb5ae807 <+135>:	mov    0x30(%rbx),%r13
   0x00007fffeb5ae80b <+139>:	mov    %rax,%r8
   0x00007fffeb5ae80e <+142>:	mov    %rax,%r15
   0x00007fffeb5ae811 <+145>:	sub    %r13,%r8
   0x00007fffeb5ae814 <+148>:	sar    $0x2,%r8
   0x00007fffeb5ae818 <+152>:	test   %r12,%r12
   0x00007fffeb5ae81b <+155>:	je     0x7fffeb5aebb6 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+1078>
   0x00007fffeb5ae821 <+161>:	mov    0x18(%rbx),%rsi
   0x00007fffeb5ae825 <+165>:	xor    %eax,%eax
   0x00007fffeb5ae827 <+167>:	nopw   0x0(%rax,%rax,1)
   0x00007fffeb5ae830 <+176>:	mov    (%rcx,%rax,8),%rdx
   0x00007fffeb5ae834 <+180>:	mov    %rdx,(%rsi,%rax,8)
   0x00007fffeb5ae838 <+184>:	add    $0x1,%rax
   0x00007fffeb5ae83c <+188>:	cmp    %r12,%rax
   0x00007fffeb5ae83f <+191>:	jne    0x7fffeb5ae830 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+176>
   0x00007fffeb5ae841 <+193>:	mov    %edi,%r12d
   0x00007fffeb5ae844 <+196>:	mov    %edi,%ebp
   0x00007fffeb5ae846 <+198>:	cmp    %r8,%r12
   0x00007fffeb5ae849 <+201>:	ja     0x7fffeb5aecb8 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+1336>
   0x00007fffeb5ae84f <+207>:	jb     0x7fffeb5aebc8 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+1096>
   0x00007fffeb5ae855 <+213>:	test   %ebp,%ebp
   0x00007fffeb5ae857 <+215>:	je     0x7fffeb5ae8be <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+318>
   0x00007fffeb5ae859 <+217>:	lea    -0x1(%rbp),%eax
   0x00007fffeb5ae85c <+220>:	cmp    $0x2,%eax
   0x00007fffeb5ae85f <+223>:	jbe    0x7fffeb5aecd4 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+1364>
   0x00007fffeb5ae865 <+229>:	mov    %ebp,%edx
   0x00007fffeb5ae867 <+231>:	movdqa 0x11b97d1(%rip),%xmm0        # 0x7fffec768040
   0x00007fffeb5ae86f <+239>:	movdqa 0x11b97d9(%rip),%xmm2        # 0x7fffec768050
   0x00007fffeb5ae877 <+247>:	mov    %r13,%rax
   0x00007fffeb5ae87a <+250>:	shr    $0x2,%edx
   0x00007fffeb5ae87d <+253>:	sub    $0x1,%edx
   0x00007fffeb5ae880 <+256>:	shl    $0x4,%rdx
   0x00007fffeb5ae884 <+260>:	lea    0x10(%r13,%rdx,1),%rdx
   0x00007fffeb5ae889 <+265>:	nopl   0x0(%rax)
   0x00007fffeb5ae890 <+272>:	movdqa %xmm0,%xmm1
   0x00007fffeb5ae894 <+276>:	add    $0x10,%rax
   0x00007fffeb5ae898 <+280>:	paddd  %xmm2,%xmm0
   0x00007fffeb5ae89c <+284>:	movups %xmm1,-0x10(%rax)
   0x00007fffeb5ae8a0 <+288>:	cmp    %rdx,%rax
   0x00007fffeb5ae8a3 <+291>:	jne    0x7fffeb5ae890 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+272>
   0x00007fffeb5ae8a5 <+293>:	mov    %ebp,%eax
   0x00007fffeb5ae8a7 <+295>:	and    $0xfffffffc,%eax
   0x00007fffeb5ae8aa <+298>:	test   $0x3,%bpl
   0x00007fffeb5ae8ae <+302>:	je     0x7fffeb5ae8be <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+318>
   0x00007fffeb5ae8b0 <+304>:	mov    %eax,%edx
   0x00007fffeb5ae8b2 <+306>:	mov    %eax,0x0(%r13,%rdx,4)
   0x00007fffeb5ae8b7 <+311>:	add    $0x1,%eax
   0x00007fffeb5ae8ba <+314>:	cmp    %eax,%ebp
   0x00007fffeb5ae8bc <+316>:	ja     0x7fffeb5ae8b0 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+304>
   0x00007fffeb5ae8be <+318>:	cmp    %r13,%r15
   0x00007fffeb5ae8c1 <+321>:	je     0x7fffeb5aea00 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+640>
   0x00007fffeb5ae8c7 <+327>:	mov    %r15,%r14
   0x00007fffeb5ae8ca <+330>:	mov    $0x3f,%edx
   0x00007fffeb5ae8cf <+335>:	mov    0x8(%rsp),%rcx
   0x00007fffeb5ae8d4 <+340>:	mov    %r15,%rsi
   0x00007fffeb5ae8d7 <+343>:	sub    %r13,%r14
   0x00007fffeb5ae8da <+346>:	mov    %r13,%rdi
   0x00007fffeb5ae8dd <+349>:	mov    %r14,%rax
   0x00007fffeb5ae8e0 <+352>:	sar    $0x2,%rax
   0x00007fffeb5ae8e4 <+356>:	bsr    %rax,%rax
   0x00007fffeb5ae8e8 <+360>:	xor    $0x3f,%rax
   0x00007fffeb5ae8ec <+364>:	sub    %eax,%edx
   0x00007fffeb5ae8ee <+366>:	movslq %edx,%rdx
   0x00007fffeb5ae8f1 <+369>:	add    %rdx,%rdx
   0x00007fffeb5ae8f4 <+372>:	call   0x7fffeb5ac490 <_ZSt16__introsort_loopIN9__gnu_cxx17__normal_iteratorIPjSt6vectorIjSaIjEEEElNS0_5__ops15_Iter_comp_iterIZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKS3_INSA_17KeyColumnMetadataESaISC_EEiiEUljjE_EEEvT_SJ_T0_T1_>
   0x00007fffeb5ae8f9 <+377>:	cmp    $0x40,%r14
   0x00007fffeb5ae8fd <+381>:	jle    0x7fffeb5ae9f0 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+624>
   0x00007fffeb5ae903 <+387>:	lea    0x40(%r13),%r14
   0x00007fffeb5ae907 <+391>:	mov    0x8(%rsp),%rdx
   0x00007fffeb5ae90c <+396>:	mov    %r13,%rdi
   0x00007fffeb5ae90f <+399>:	mov    %r14,%rsi
   0x00007fffeb5ae912 <+402>:	call   0x7fffeb5ac200 <_ZSt16__insertion_sortIN9__gnu_cxx17__normal_iteratorIPjSt6vectorIjSaIjEEEENS0_5__ops15_Iter_comp_iterIZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKS3_INSA_17KeyColumnMetadataESaISC_EEiiEUljjE_EEEvT_SJ_T0_>
   0x00007fffeb5ae917 <+407>:	cmp    %r15,%r14
   0x00007fffeb5ae91a <+410>:	je     0x7fffeb5aea00 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+640>
   0x00007fffeb5ae920 <+416>:	mov    0x8(%rsp),%rax
   0x00007fffeb5ae925 <+421>:	mov    %ebp,0x18(%rsp)
   0x00007fffeb5ae929 <+425>:	mov    (%rax),%r13
   0x00007fffeb5ae92c <+428>:	nopl   0x0(%rax)
   0x00007fffeb5ae930 <+432>:	mov    (%r14),%eax
   0x00007fffeb5ae933 <+435>:	lea    0x0(%r13,%rax,8),%r11
   0x00007fffeb5ae938 <+440>:	mov    %rax,%rbp
   0x00007fffeb5ae93b <+443>:	mov    %r14,%rax
   0x00007fffeb5ae93e <+446>:	movzbl (%r11),%r8d
   0x00007fffeb5ae942 <+450>:	mov    -0x4(%rax),%ecx
   0x00007fffeb5ae945 <+453>:	test   %r8b,%r8b
   0x00007fffeb5ae948 <+456>:	je     0x7fffeb5ae9c5 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+581>
   0x00007fffeb5ae94a <+458>:	nopw   0x0(%rax,%rax,1)
   0x00007fffeb5ae950 <+464>:	mov    %ecx,%esi
   0x00007fffeb5ae952 <+466>:	mov    0x4(%r11),%edx
   0x00007fffeb5ae956 <+470>:	lea    0x0(%r13,%rsi,8),%r9
   0x00007fffeb5ae95b <+475>:	movzbl (%r9),%esi
   0x00007fffeb5ae95f <+479>:	popcnt %rdx,%rdx
   0x00007fffeb5ae964 <+484>:	cmp    $0x1,%edx
   0x00007fffeb5ae967 <+487>:	setle  %dl
   0x00007fffeb5ae96a <+490>:	test   %sil,%sil
   0x00007fffeb5ae96d <+493>:	je     0x7fffeb5aec10 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+1168>
   0x00007fffeb5ae973 <+499>:	mov    0x4(%r9),%esi
   0x00007fffeb5ae977 <+503>:	mov    0x4(%r11),%r10d
   0x00007fffeb5ae97b <+507>:	mov    0x4(%r9),%r9d
   0x00007fffeb5ae97f <+511>:	popcnt %rsi,%rsi
   0x00007fffeb5ae984 <+516>:	cmp    $0x1,%esi
   0x00007fffeb5ae987 <+519>:	setle  %dil
   0x00007fffeb5ae98b <+523>:	mov    $0x1,%esi
   0x00007fffeb5ae990 <+528>:	cmp    %dil,%dl
   0x00007fffeb5ae993 <+531>:	jne    0x7fffeb5ae9af <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+559>
   0x00007fffeb5ae995 <+533>:	test   %dl,%dl
   0x00007fffeb5ae997 <+535>:	je     0x7fffeb5aebe8 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+1128>
   0x00007fffeb5ae99d <+541>:	cmp    %r10d,%r9d
   0x00007fffeb5ae9a0 <+544>:	jne    0x7fffeb5ae9ac <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+556>
   0x00007fffeb5ae9a2 <+546>:	mov    %r8d,%edx
   0x00007fffeb5ae9a5 <+549>:	cmp    %r8b,%sil
   0x00007fffeb5ae9a8 <+552>:	jne    0x7fffeb5ae9af <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+559>
   0x00007fffeb5ae9aa <+554>:	cmp    %ecx,%ebp
   0x00007fffeb5ae9ac <+556>:	setb   %dl
   0x00007fffeb5ae9af <+559>:	test   %dl,%dl
   0x00007fffeb5ae9b1 <+561>:	je     0x7fffeb5aebf0 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+1136>
   0x00007fffeb5ae9b7 <+567>:	mov    %ecx,(%rax)
   0x00007fffeb5ae9b9 <+569>:	sub    $0x4,%rax
   0x00007fffeb5ae9bd <+573>:	mov    -0x4(%rax),%ecx
   0x00007fffeb5ae9c0 <+576>:	test   %r8b,%r8b
   0x00007fffeb5ae9c3 <+579>:	jne    0x7fffeb5ae950 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+464>
   0x00007fffeb5ae9c5 <+581>:	mov    %ecx,%edx
   0x00007fffeb5ae9c7 <+583>:	lea    0x0(%r13,%rdx,8),%rdx
   0x00007fffeb5ae9cc <+588>:	movzbl (%rdx),%esi
   0x00007fffeb5ae9cf <+591>:	test   %sil,%sil
   0x00007fffeb5ae9d2 <+594>:	jne    0x7fffeb5aec28 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+1192>
   0x00007fffeb5ae9d8 <+600>:	mov    $0x1,%edx
   0x00007fffeb5ae9dd <+605>:	mov    $0x4,%r10d
   0x00007fffeb5ae9e3 <+611>:	mov    $0x1,%edi
   0x00007fffeb5ae9e8 <+616>:	mov    $0x4,%r9d
   0x00007fffeb5ae9ee <+622>:	jmp    0x7fffeb5ae990 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+528>
   0x00007fffeb5ae9f0 <+624>:	mov    0x8(%rsp),%rdx
   0x00007fffeb5ae9f5 <+629>:	mov    %r15,%rsi
   0x00007fffeb5ae9f8 <+632>:	mov    %r13,%rdi
   0x00007fffeb5ae9fb <+635>:	call   0x7fffeb5ac200 <_ZSt16__insertion_sortIN9__gnu_cxx17__normal_iteratorIPjSt6vectorIjSaIjEEEENS0_5__ops15_Iter_comp_iterIZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKS3_INSA_17KeyColumnMetadataESaISC_EEiiEUljjE_EEEvT_SJ_T0_>
   0x00007fffeb5aea00 <+640>:	mov    0x50(%rbx),%rdx
   0x00007fffeb5aea04 <+644>:	mov    0x48(%rbx),%rcx
   0x00007fffeb5aea08 <+648>:	mov    %rdx,%rax
   0x00007fffeb5aea0b <+651>:	sub    %rcx,%rax
   0x00007fffeb5aea0e <+654>:	sar    $0x2,%rax
   0x00007fffeb5aea12 <+658>:	cmp    %r12,%rax
   0x00007fffeb5aea15 <+661>:	jb     0x7fffeb5aec78 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+1272>
   0x00007fffeb5aea1b <+667>:	ja     0x7fffeb5aeba0 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+1056>
   0x00007fffeb5aea21 <+673>:	test   %ebp,%ebp
   0x00007fffeb5aea23 <+675>:	je     0x7fffeb5aea47 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+711>
   0x00007fffeb5aea25 <+677>:	mov    0x30(%rbx),%rdi
   0x00007fffeb5aea29 <+681>:	mov    0x48(%rbx),%rsi
   0x00007fffeb5aea2d <+685>:	mov    %ebp,%ecx
   0x00007fffeb5aea2f <+687>:	xor    %eax,%eax
   0x00007fffeb5aea31 <+689>:	nopl   0x0(%rax)
   0x00007fffeb5aea38 <+696>:	mov    (%rdi,%rax,4),%edx
   0x00007fffeb5aea3b <+699>:	mov    %eax,(%rsi,%rdx,4)
   0x00007fffeb5aea3e <+702>:	add    $0x1,%rax
   0x00007fffeb5aea42 <+706>:	cmp    %rcx,%rax
   0x00007fffeb5aea45 <+709>:	jne    0x7fffeb5aea38 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+696>
   0x00007fffeb5aea47 <+711>:	mov    0x10(%rsp),%rax
   0x00007fffeb5aea4c <+716>:	mov    0x68(%rbx),%rdx
   0x00007fffeb5aea50 <+720>:	movl   $0x0,0x8(%rbx)
   0x00007fffeb5aea57 <+727>:	mov    0x60(%rbx),%rcx
   0x00007fffeb5aea5b <+731>:	mov    %rax,0x10(%rbx)
   0x00007fffeb5aea5f <+735>:	mov    %rdx,%rax
   0x00007fffeb5aea62 <+738>:	sub    %rcx,%rax
   0x00007fffeb5aea65 <+741>:	sar    $0x2,%rax
   0x00007fffeb5aea69 <+745>:	cmp    %r12,%rax
   0x00007fffeb5aea6c <+748>:	jb     0x7fffeb5aec60 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+1248>
   0x00007fffeb5aea72 <+754>:	ja     0x7fffeb5aeb60 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+992>
   0x00007fffeb5aea78 <+760>:	test   %ebp,%ebp
   0x00007fffeb5aea7a <+762>:	je     0x7fffeb5aeb79 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+1017>
   0x00007fffeb5aea80 <+768>:	mov    0x8(%rsp),%rax
   0x00007fffeb5aea85 <+773>:	mov    %ebp,%r9d
   0x00007fffeb5aea88 <+776>:	mov    0x30(%rbx),%r11
   0x00007fffeb5aea8c <+780>:	xor    %edx,%edx
   0x00007fffeb5aea8e <+782>:	mov    0x60(%rbx),%r10
   0x00007fffeb5aea92 <+786>:	shl    $0x2,%r9
   0x00007fffeb5aea96 <+790>:	xor    %r8d,%r8d
   0x00007fffeb5aea99 <+793>:	mov    (%rax),%r12
   0x00007fffeb5aea9c <+796>:	xor    %eax,%eax
   0x00007fffeb5aea9e <+798>:	jmp    0x7fffeb5aeadb <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+859>
   0x00007fffeb5aeaa0 <+800>:	mov    0x4(%rcx),%esi
   0x00007fffeb5aeaa3 <+803>:	test   %esi,%esi
   0x00007fffeb5aeaa5 <+805>:	je     0x7fffeb5aeac2 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+834>
=> 0x00007fffeb5aeaa7 <+807>:	popcnt %rsi,%rsi
   0x00007fffeb5aeaac <+812>:	cmp    $0x1,%esi
   0x00007fffeb5aeaaf <+815>:	je     0x7fffeb5aeac2 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+834>
   0x00007fffeb5aeab1 <+817>:	mov    0x14(%rbx),%esi
   0x00007fffeb5aeab4 <+820>:	mov    %eax,%r13d
   0x00007fffeb5aeab7 <+823>:	neg    %r13d
   0x00007fffeb5aeaba <+826>:	sub    $0x1,%esi
   0x00007fffeb5aeabd <+829>:	and    %r13d,%esi
   0x00007fffeb5aeac0 <+832>:	add    %esi,%eax
   0x00007fffeb5aeac2 <+834>:	mov    %eax,(%rdi)
   0x00007fffeb5aeac4 <+836>:	mov    0x4(%rcx),%ecx
   0x00007fffeb5aeac7 <+839>:	lea    (%rax,%rcx,1),%esi
   0x00007fffeb5aeaca <+842>:	add    $0x1,%eax
   0x00007fffeb5aeacd <+845>:	test   %ecx,%ecx
   0x00007fffeb5aeacf <+847>:	cmovne %esi,%eax
   0x00007fffeb5aead2 <+850>:	add    $0x4,%rdx
   0x00007fffeb5aead6 <+854>:	cmp    %r9,%rdx
   0x00007fffeb5aead9 <+857>:	je     0x7fffeb5aeb06 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+902>
   0x00007fffeb5aeadb <+859>:	mov    (%r11,%rdx,1),%ecx
   0x00007fffeb5aeadf <+863>:	lea    (%r10,%rdx,1),%rdi
   0x00007fffeb5aeae3 <+867>:	lea    (%r12,%rcx,8),%rcx
   0x00007fffeb5aeae7 <+871>:	cmpb   $0x0,(%rcx)
   0x00007fffeb5aeaea <+874>:	jne    0x7fffeb5aeaa0 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+800>
   0x00007fffeb5aeaec <+876>:	mov    %eax,(%rdi)
   0x00007fffeb5aeaee <+878>:	test   %r8d,%r8d
   0x00007fffeb5aeaf1 <+881>:	jne    0x7fffeb5aeaf6 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+886>
   0x00007fffeb5aeaf3 <+883>:	mov    %eax,0x8(%rbx)
   0x00007fffeb5aeaf6 <+886>:	add    $0x4,%rdx
   0x00007fffeb5aeafa <+890>:	add    $0x1,%r8d
   0x00007fffeb5aeafe <+894>:	add    $0x4,%eax
   0x00007fffeb5aeb01 <+897>:	cmp    %r9,%rdx
   0x00007fffeb5aeb04 <+900>:	jne    0x7fffeb5aeadb <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+859>
   0x00007fffeb5aeb06 <+902>:	test   %r8d,%r8d
   0x00007fffeb5aeb09 <+905>:	mov    %eax,%ecx
   0x00007fffeb5aeb0b <+907>:	sete   (%rbx)
   0x00007fffeb5aeb0e <+910>:	neg    %ecx
   0x00007fffeb5aeb10 <+912>:	test   %r8d,%r8d
   0x00007fffeb5aeb13 <+915>:	je     0x7fffeb5aec50 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+1232>
   0x00007fffeb5aeb19 <+921>:	mov    0x14(%rbx),%edi
   0x00007fffeb5aeb1c <+924>:	lea    -0x1(%rdi),%edx
   0x00007fffeb5aeb1f <+927>:	and    %ecx,%edx
   0x00007fffeb5aeb21 <+929>:	add    %edx,%eax
   0x00007fffeb5aeb23 <+931>:	mov    %eax,0x4(%rbx)
   0x00007fffeb5aeb26 <+934>:	movl   $0x1,0xc(%rbx)
   0x00007fffeb5aeb2d <+941>:	cmp    $0x8,%ebp
   0x00007fffeb5aeb30 <+944>:	jbe    0x7fffeb5aeb4e <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+974>
   0x00007fffeb5aeb32 <+946>:	mov    $0x1,%edx
   0x00007fffeb5aeb37 <+951>:	nopw   0x0(%rax,%rax,1)
   0x00007fffeb5aeb40 <+960>:	mov    %edx,%eax
   0x00007fffeb5aeb42 <+962>:	add    %edx,%edx
   0x00007fffeb5aeb44 <+964>:	shl    $0x4,%eax
   0x00007fffeb5aeb47 <+967>:	cmp    %ebp,%eax
   0x00007fffeb5aeb49 <+969>:	jb     0x7fffeb5aeb40 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+960>
   0x00007fffeb5aeb4b <+971>:	mov    %edx,0xc(%rbx)
   0x00007fffeb5aeb4e <+974>:	add    $0x28,%rsp
   0x00007fffeb5aeb52 <+978>:	pop    %rbx
   0x00007fffeb5aeb53 <+979>:	pop    %rbp
   0x00007fffeb5aeb54 <+980>:	pop    %r12
   0x00007fffeb5aeb56 <+982>:	pop    %r13
   0x00007fffeb5aeb58 <+984>:	pop    %r14
   0x00007fffeb5aeb5a <+986>:	pop    %r15
   0x00007fffeb5aeb5c <+988>:	ret    
   0x00007fffeb5aeb5d <+989>:	nopl   (%rax)
   0x00007fffeb5aeb60 <+992>:	lea    (%rcx,%r12,4),%rax
   0x00007fffeb5aeb64 <+996>:	cmp    %rax,%rdx
   0x00007fffeb5aeb67 <+999>:	je     0x7fffeb5aea78 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+760>
   0x00007fffeb5aeb6d <+1005>:	mov    %rax,0x68(%rbx)
   0x00007fffeb5aeb71 <+1009>:	test   %ebp,%ebp
   0x00007fffeb5aeb73 <+1011>:	jne    0x7fffeb5aea80 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+768>
   0x00007fffeb5aeb79 <+1017>:	movb   $0x1,(%rbx)
   0x00007fffeb5aeb7c <+1020>:	movl   $0x0,0x4(%rbx)
   0x00007fffeb5aeb83 <+1027>:	movl   $0x1,0xc(%rbx)
   0x00007fffeb5aeb8a <+1034>:	add    $0x28,%rsp
   0x00007fffeb5aeb8e <+1038>:	pop    %rbx
   0x00007fffeb5aeb8f <+1039>:	pop    %rbp
   0x00007fffeb5aeb90 <+1040>:	pop    %r12
   0x00007fffeb5aeb92 <+1042>:	pop    %r13
   0x00007fffeb5aeb94 <+1044>:	pop    %r14
   0x00007fffeb5aeb96 <+1046>:	pop    %r15
   0x00007fffeb5aeb98 <+1048>:	ret    
   0x00007fffeb5aeb99 <+1049>:	nopl   0x0(%rax)
   0x00007fffeb5aeba0 <+1056>:	lea    (%rcx,%r12,4),%rax
   0x00007fffeb5aeba4 <+1060>:	cmp    %rax,%rdx
   0x00007fffeb5aeba7 <+1063>:	je     0x7fffeb5aea21 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+673>
   0x00007fffeb5aebad <+1069>:	mov    %rax,0x50(%rbx)
   0x00007fffeb5aebb1 <+1073>:	jmp    0x7fffeb5aea21 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+673>
   0x00007fffeb5aebb6 <+1078>:	xor    %ebp,%ebp
   0x00007fffeb5aebb8 <+1080>:	test   %r8,%r8
   0x00007fffeb5aebbb <+1083>:	je     0x7fffeb5ae8be <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+318>
   0x00007fffeb5aebc1 <+1089>:	nopl   0x0(%rax)
   0x00007fffeb5aebc8 <+1096>:	lea    0x0(%r13,%r12,4),%rax
   0x00007fffeb5aebcd <+1101>:	cmp    %r15,%rax
   0x00007fffeb5aebd0 <+1104>:	je     0x7fffeb5ae855 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+213>
   0x00007fffeb5aebd6 <+1110>:	mov    %rax,0x38(%rbx)
   0x00007fffeb5aebda <+1114>:	mov    %rax,%r15
   0x00007fffeb5aebdd <+1117>:	jmp    0x7fffeb5ae855 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+213>
   0x00007fffeb5aebe2 <+1122>:	nopw   0x0(%rax,%rax,1)
   0x00007fffeb5aebe8 <+1128>:	cmp    %ecx,%ebp
   0x00007fffeb5aebea <+1130>:	jb     0x7fffeb5ae9b7 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+567>
   0x00007fffeb5aebf0 <+1136>:	add    $0x4,%r14
   0x00007fffeb5aebf4 <+1140>:	mov    %ebp,(%rax)
   0x00007fffeb5aebf6 <+1142>:	cmp    %r15,%r14
   0x00007fffeb5aebf9 <+1145>:	jne    0x7fffeb5ae930 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+432>
   0x00007fffeb5aebff <+1151>:	mov    0x18(%rsp),%ebp
   0x00007fffeb5aec03 <+1155>:	jmp    0x7fffeb5aea00 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+640>
   0x00007fffeb5aec08 <+1160>:	nopl   0x0(%rax,%rax,1)
   0x00007fffeb5aec10 <+1168>:	mov    0x4(%r11),%r10d
   0x00007fffeb5aec14 <+1172>:	mov    %r8d,%edi
   0x00007fffeb5aec17 <+1175>:	mov    $0x4,%r9d
   0x00007fffeb5aec1d <+1181>:	jmp    0x7fffeb5ae990 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+528>
   0x00007fffeb5aec22 <+1186>:	nopw   0x0(%rax,%rax,1)
   0x00007fffeb5aec28 <+1192>:	mov    0x4(%rdx),%edx
   0x00007fffeb5aec2b <+1195>:	mov    $0x4,%r10d
   0x00007fffeb5aec31 <+1201>:	mov    %rdx,%r9
   0x00007fffeb5aec34 <+1204>:	popcnt %rdx,%rdx
   0x00007fffeb5aec39 <+1209>:	cmp    $0x1,%edx
   0x00007fffeb5aec3c <+1212>:	mov    %esi,%edx
   0x00007fffeb5aec3e <+1214>:	setle  %dil
   0x00007fffeb5aec42 <+1218>:	jmp    0x7fffeb5ae98b <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+523>
   0x00007fffeb5aec47 <+1223>:	nopw   0x0(%rax,%rax,1)
   0x00007fffeb5aec50 <+1232>:	mov    0x10(%rbx),%edi
   0x00007fffeb5aec53 <+1235>:	lea    -0x1(%rdi),%edx
   0x00007fffeb5aec56 <+1238>:	and    %ecx,%edx
   0x00007fffeb5aec58 <+1240>:	add    %edx,%eax
   0x00007fffeb5aec5a <+1242>:	jmp    0x7fffeb5aeb23 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+931>
   0x00007fffeb5aec5f <+1247>:	nop
   0x00007fffeb5aec60 <+1248>:	mov    %r12,%rsi
   0x00007fffeb5aec63 <+1251>:	lea    0x60(%rbx),%rdi
   0x00007fffeb5aec67 <+1255>:	sub    %rax,%rsi
   0x00007fffeb5aec6a <+1258>:	call   0x7fffeab039e0 <_ZNSt6vectorIjSaIjEE17_M_default_appendEm@plt>
   0x00007fffeb5aec6f <+1263>:	jmp    0x7fffeb5aea78 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+760>
   0x00007fffeb5aec74 <+1268>:	nopl   0x0(%rax)
   0x00007fffeb5aec78 <+1272>:	mov    %r12,%rsi
   0x00007fffeb5aec7b <+1275>:	lea    0x48(%rbx),%rdi
   0x00007fffeb5aec7f <+1279>:	sub    %rax,%rsi
   0x00007fffeb5aec82 <+1282>:	call   0x7fffeab039e0 <_ZNSt6vectorIjSaIjEE17_M_default_appendEm@plt>
   0x00007fffeb5aec87 <+1287>:	jmp    0x7fffeb5aea21 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+673>
   0x00007fffeb5aec8c <+1292>:	nopl   0x0(%rax)
   0x00007fffeb5aec90 <+1296>:	sar    $0x3,%rsi
   0x00007fffeb5aec94 <+1300>:	sub    %rsi,%rdi
   0x00007fffeb5aec97 <+1303>:	mov    %rdi,%r8
   0x00007fffeb5aec9a <+1306>:	lea    0x18(%rbx),%rdi
   0x00007fffeb5aec9e <+1310>:	mov    %r8,%rsi
   0x00007fffeb5aeca1 <+1313>:	call   0x7fffeab03080 <_ZNSt6vectorIN5arrow7compute17KeyColumnMetadataESaIS2_EE17_M_default_appendEm@plt>
   0x00007fffeb5aeca6 <+1318>:	mov    0x8(%rsp),%rax
   0x00007fffeb5aecab <+1323>:	mov    (%rax),%rcx
   0x00007fffeb5aecae <+1326>:	jmp    0x7fffeb5ae7ed <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+109>
   0x00007fffeb5aecb3 <+1331>:	nopl   0x0(%rax,%rax,1)
   0x00007fffeb5aecb8 <+1336>:	mov    %r12,%rsi
   0x00007fffeb5aecbb <+1339>:	lea    0x30(%rbx),%rdi
   0x00007fffeb5aecbf <+1343>:	sub    %r8,%rsi
   0x00007fffeb5aecc2 <+1346>:	call   0x7fffeab039e0 <_ZNSt6vectorIjSaIjEE17_M_default_appendEm@plt>
   0x00007fffeb5aecc7 <+1351>:	mov    0x30(%rbx),%r13
   0x00007fffeb5aeccb <+1355>:	mov    0x38(%rbx),%r15
   0x00007fffeb5aeccf <+1359>:	jmp    0x7fffeb5ae855 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+213>
   0x00007fffeb5aecd4 <+1364>:	xor    %eax,%eax
   0x00007fffeb5aecd6 <+1366>:	jmp    0x7fffeb5ae8b0 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+304>
End of assembler dump.
(gdb) q
A debugging session is active.

	Inferior 1 [process 30365] will be killed.

Quit anyway? (y or n) y
(base) tdhock@tdhock-MacBook:/tmp/Rtmp8icqQo/downloaded_packages$ 
```

Is this a bug in GCC? I told it to use core2 instructions, which do
not include popcnt, but it generated a popcnt instruction anyway.

Does it occur in libarrow C++ without R? Let's try to build it from
source, [based on these
instructions](https://arrow.apache.org/docs/developers/cpp/building.html).

```
(base) tdhock@tdhock-MacBook:/tmp/Rtmp8icqQo/downloaded_packages$ cd  && git clone https://github.com/apache/arrow.git
Clonage dans 'arrow'...
remote: Enumerating objects: 205778, done.        
remote: Total 205778 (delta 0), reused 0 (delta 0), pack-reused 205778        
Réception d'objets: 100% (205778/205778), 155.98 Mio | 5.86 Mio/s, fait.
Résolution des deltas: 100% (143268/143268), fait.
Mise à jour des fichiers: 100% (6887/6887), fait.

(base) tdhock@tdhock-MacBook:~/tdhock.github.io(master*)$ sudo apt install cmake
Lecture des listes de paquets... Fait
Construction de l'arbre des dépendances... Fait
Lecture des informations d'état... Fait      
Les paquets supplémentaires suivants seront installés : 
  cmake-data dh-elpa-helper libjsoncpp25 librhash0
Paquets suggérés :
  cmake-doc ninja-build cmake-format
Les NOUVEAUX paquets suivants seront installés :
  cmake cmake-data dh-elpa-helper libjsoncpp25 librhash0
0 mis à jour, 5 nouvellement installés, 0 à enlever et 0 non mis à jour.
Il est nécessaire de prendre 7 136 ko dans les archives.
Après cette opération, 31,8 Mo d'espace disque supplémentaires seront utilisés.
Souhaitez-vous continuer ? [O/n] 
Réception de :1 http://mirror.arizona.edu/ubuntu jammy/main amd64 libjsoncpp25 amd64 1.9.5-3 [80,0 kB]
Réception de :2 http://mirror.arizona.edu/ubuntu jammy/main amd64 librhash0 amd64 1.4.2-1ubuntu1 [125 kB]
Réception de :3 http://mirror.arizona.edu/ubuntu jammy/main amd64 dh-elpa-helper all 2.0.9ubuntu1 [7 610 B]
Réception de :4 http://mirror.arizona.edu/ubuntu jammy/main amd64 cmake-data all 3.22.1-1ubuntu1 [1 912 kB]
Réception de :5 http://mirror.arizona.edu/ubuntu jammy/main amd64 cmake amd64 3.22.1-1ubuntu1 [5 012 kB]
7 136 ko réceptionnés en 1s (5 182 ko/s)
Sélection du paquet libjsoncpp25:amd64 précédemment désélectionné.
(Lecture de la base de données... 399420 fichiers et répertoires déjà installés.
)
Préparation du dépaquetage de .../libjsoncpp25_1.9.5-3_amd64.deb ...
Dépaquetage de libjsoncpp25:amd64 (1.9.5-3) ...
Sélection du paquet librhash0:amd64 précédemment désélectionné.
Préparation du dépaquetage de .../librhash0_1.4.2-1ubuntu1_amd64.deb ...
Dépaquetage de librhash0:amd64 (1.4.2-1ubuntu1) ...
Sélection du paquet dh-elpa-helper précédemment désélectionné.
Préparation du dépaquetage de .../dh-elpa-helper_2.0.9ubuntu1_all.deb ...
Dépaquetage de dh-elpa-helper (2.0.9ubuntu1) ...
Sélection du paquet cmake-data précédemment désélectionné.
Préparation du dépaquetage de .../cmake-data_3.22.1-1ubuntu1_all.deb ...
Dépaquetage de cmake-data (3.22.1-1ubuntu1) ...
Sélection du paquet cmake précédemment désélectionné.
Préparation du dépaquetage de .../cmake_3.22.1-1ubuntu1_amd64.deb ...
Dépaquetage de cmake (3.22.1-1ubuntu1) ...
Paramétrage de dh-elpa-helper (2.0.9ubuntu1) ...
Paramétrage de libjsoncpp25:amd64 (1.9.5-3) ...
Paramétrage de librhash0:amd64 (1.4.2-1ubuntu1) ...
Paramétrage de cmake-data (3.22.1-1ubuntu1) ...
Paramétrage de cmake (3.22.1-1ubuntu1) ...
Traitement des actions différées (« triggers ») pour man-db (2.10.2-1) ...
Traitement des actions différées (« triggers ») pour libc-bin (2.35-0ubuntu3.1) 
...
(base) tdhock@tdhock-MacBook:~/tdhock.github.io(master*)$ sudo apt install ninja-build
Lecture des listes de paquets... Fait
Construction de l'arbre des dépendances... Fait
Lecture des informations d'état... Fait      
Les NOUVEAUX paquets suivants seront installés :
  ninja-build
0 mis à jour, 1 nouvellement installés, 0 à enlever et 0 non mis à jour.
Il est nécessaire de prendre 111 ko dans les archives.
Après cette opération, 358 ko d'espace disque supplémentaires seront utilisés.
Réception de :1 http://mirror.arizona.edu/ubuntu jammy/universe amd64 ninja-build amd64 1.10.1-1 [111 kB]
111 ko réceptionnés en 2s (60,4 ko/s) 
Sélection du paquet ninja-build précédemment désélectionné.
(Lecture de la base de données... 402504 fichiers et répertoires déjà installés.
)
Préparation du dépaquetage de .../ninja-build_1.10.1-1_amd64.deb ...
Dépaquetage de ninja-build (1.10.1-1) ...
Paramétrage de ninja-build (1.10.1-1) ...
Traitement des actions différées (« triggers ») pour man-db (2.10.2-1) ...
(base) tdhock@tdhock-MacBook:~/arrow/cpp(main)$ cmake --preset -N ninja-debug-minimal
Preset CMake variables:

  ARROW_BUILD_INTEGRATION="OFF"
  ARROW_BUILD_STATIC="OFF"
  ARROW_BUILD_TESTS="OFF"
  ARROW_EXTRA_ERROR_CONTEXT="ON"
  ARROW_WITH_RE2="OFF"
  ARROW_WITH_UTF8PROC="OFF"
  CMAKE_BUILD_TYPE="Debug"

(base) tdhock@tdhock-MacBook:~/arrow/cpp(main)$ mkdir build
(base) tdhock@tdhock-MacBook:~/arrow/cpp(main)$ cd build
(base) tdhock@tdhock-MacBook:~/arrow/cpp/build(main)$ cmake .. --preset ninja-debug-minimal
Preset CMake variables:

  ARROW_BUILD_INTEGRATION="OFF"
  ARROW_BUILD_STATIC="OFF"
  ARROW_BUILD_TESTS="OFF"
  ARROW_EXTRA_ERROR_CONTEXT="ON"
  ARROW_WITH_RE2="OFF"
  ARROW_WITH_UTF8PROC="OFF"
  CMAKE_BUILD_TYPE="Debug"

-- Building using CMake version: 3.22.1
-- The C compiler identification is GNU 11.3.0
-- The CXX compiler identification is GNU 11.3.0
-- Detecting C compiler ABI info
-- Detecting C compiler ABI info - done
-- Check for working C compiler: /usr/bin/cc - skipped
-- Detecting C compile features
-- Detecting C compile features - done
-- Detecting CXX compiler ABI info
-- Detecting CXX compiler ABI info - done
-- Check for working CXX compiler: /usr/bin/c++ - skipped
-- Detecting CXX compile features
-- Detecting CXX compile features - done
-- Arrow version: 13.0.0 (full: '13.0.0-SNAPSHOT')
-- Arrow SO version: 1300 (full: 1300.0.0)
-- clang-tidy 14 not found
-- clang-format 14 not found
-- Could NOT find ClangTools (missing: CLANG_FORMAT_BIN CLANG_TIDY_BIN) 
-- infer not found
-- Found Python3: /home/tdhock/miniconda3/bin/python3.10 (found version "3.10.10") found components: Interpreter 
-- Found cpplint executable at /home/tdhock/arrow/cpp/build-support/cpplint.py
-- System processor: x86_64
-- Performing Test CXX_SUPPORTS_SSE4_2
-- Performing Test CXX_SUPPORTS_SSE4_2 - Success
-- Performing Test CXX_SUPPORTS_AVX2
-- Performing Test CXX_SUPPORTS_AVX2 - Success
-- Performing Test CXX_SUPPORTS_AVX512
-- Performing Test CXX_SUPPORTS_AVX512 - Success
-- Arrow build warning level: CHECKIN
-- Using ld linker
-- Build Type: DEBUG
-- Performing Test CXX_LINKER_SUPPORTS_VERSION_SCRIPT
-- Performing Test CXX_LINKER_SUPPORTS_VERSION_SCRIPT - Success
-- Using CONDA approach to find dependencies
-- Using CONDA_PREFIX for ARROW_PACKAGE_PREFIX: /home/tdhock/miniconda3
-- Setting (unset) dependency *_ROOT variables: /home/tdhock/miniconda3
-- ARROW_ABSL_BUILD_VERSION: 20211102.0
-- ARROW_ABSL_BUILD_SHA256_CHECKSUM: dcf71b9cba8dc0ca9940c4b316a0c796be8fab42b070bb6b7cab62b48f0e66c4
-- ARROW_AWS_C_AUTH_BUILD_VERSION: v0.6.22
-- ARROW_AWS_C_AUTH_BUILD_SHA256_CHECKSUM: 691a6b4418afcd3dc141351b6ad33fccd8e3ff84df0e9e045b42295d284ee14c
-- ARROW_AWS_C_CAL_BUILD_VERSION: v0.5.20
-- ARROW_AWS_C_CAL_BUILD_SHA256_CHECKSUM: acc352359bd06f8597415c366cf4ec4f00d0b0da92d637039a73323dd55b6cd0
-- ARROW_AWS_C_COMMON_BUILD_VERSION: v0.8.9
-- ARROW_AWS_C_COMMON_BUILD_SHA256_CHECKSUM: 2f3fbaf7c38eae5a00e2a816d09b81177f93529ae8ba1b82dc8f31407565327a
-- ARROW_AWS_C_COMPRESSION_BUILD_VERSION: v0.2.16
-- ARROW_AWS_C_COMPRESSION_BUILD_SHA256_CHECKSUM: 044b1dbbca431a07bde8255ef9ec443c300fc60d4c9408d4b862f65e496687f4
-- ARROW_AWS_C_EVENT_STREAM_BUILD_VERSION: v0.2.18
-- ARROW_AWS_C_EVENT_STREAM_BUILD_SHA256_CHECKSUM: 310ca617f713bf664e4c7485a3d42c1fb57813abd0107e49790d107def7cde4f
-- ARROW_AWS_C_HTTP_BUILD_VERSION: v0.7.3
-- ARROW_AWS_C_HTTP_BUILD_SHA256_CHECKSUM: 07e16c6bf5eba6f0dea96b6f55eae312a7c95b736f4d2e4a210000f45d8265ae
-- ARROW_AWS_C_IO_BUILD_VERSION: v0.13.14
-- ARROW_AWS_C_IO_BUILD_SHA256_CHECKSUM: 12b66510c3d9a4f7e9b714e9cfab2a5bf835f8b9ce2f909d20ae2a2128608c71
-- ARROW_AWS_C_MQTT_BUILD_VERSION: v0.8.4
-- ARROW_AWS_C_MQTT_BUILD_SHA256_CHECKSUM: 232eeac63e72883d460c686a09b98cdd811d24579affac47c5c3f696f956773f
-- ARROW_AWS_C_S3_BUILD_VERSION: v0.2.3
-- ARROW_AWS_C_S3_BUILD_SHA256_CHECKSUM: a00b3c9f319cd1c9aa2c3fa15098864df94b066dcba0deaccbb3caa952d902fe
-- ARROW_AWS_C_SDKUTILS_BUILD_VERSION: v0.1.6
-- ARROW_AWS_C_SDKUTILS_BUILD_SHA256_CHECKSUM: 8a2951344b2fb541eab1e9ca17c18a7fcbfd2aaff4cdd31d362d1fad96111b91
-- ARROW_AWS_CHECKSUMS_BUILD_VERSION: v0.1.13
-- ARROW_AWS_CHECKSUMS_BUILD_SHA256_CHECKSUM: 0f897686f1963253c5069a0e495b85c31635ba146cd3ac38cc2ea31eaf54694d
-- ARROW_AWS_CRT_CPP_BUILD_VERSION: v0.18.16
-- ARROW_AWS_CRT_CPP_BUILD_SHA256_CHECKSUM: 9e69bc1dc4b50871d1038aa9ff6ddeb4c9b28f7d6b5e5b1b69041ccf50a13483
-- ARROW_AWS_LC_BUILD_VERSION: v1.3.0
-- ARROW_AWS_LC_BUILD_SHA256_CHECKSUM: ae96a3567161552744fc0cae8b4d68ed88b1ec0f3d3c98700070115356da5a37
-- ARROW_AWSSDK_BUILD_VERSION: 1.10.55
-- ARROW_AWSSDK_BUILD_SHA256_CHECKSUM: 2d552fb1a84bef4a9b65e34aa7031851ed2aef5319e02cc6e4cb735c48aa30de
-- ARROW_BOOST_BUILD_VERSION: 1.81.0
-- ARROW_BOOST_BUILD_SHA256_CHECKSUM: 9e0ffae35528c35f90468997bc8d99500bf179cbae355415a89a600c38e13574
-- ARROW_BROTLI_BUILD_VERSION: v1.0.9
-- ARROW_BROTLI_BUILD_SHA256_CHECKSUM: f9e8d81d0405ba66d181529af42a3354f838c939095ff99930da6aa9cdf6fe46
-- ARROW_BZIP2_BUILD_VERSION: 1.0.8
-- ARROW_BZIP2_BUILD_SHA256_CHECKSUM: ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269
-- ARROW_CARES_BUILD_VERSION: 1.17.2
-- ARROW_CARES_BUILD_SHA256_CHECKSUM: 4803c844ce20ce510ef0eb83f8ea41fa24ecaae9d280c468c582d2bb25b3913d
-- ARROW_CRC32C_BUILD_VERSION: 1.1.2
-- ARROW_CRC32C_BUILD_SHA256_CHECKSUM: ac07840513072b7fcebda6e821068aa04889018f24e10e46181068fb214d7e56
-- ARROW_GBENCHMARK_BUILD_VERSION: v1.7.1
-- ARROW_GBENCHMARK_BUILD_SHA256_CHECKSUM: 6430e4092653380d9dc4ccb45a1e2dc9259d581f4866dc0759713126056bc1d7
-- ARROW_GFLAGS_BUILD_VERSION: v2.2.2
-- ARROW_GFLAGS_BUILD_SHA256_CHECKSUM: 34af2f15cf7367513b352bdcd2493ab14ce43692d2dcd9dfc499492966c64dcf
-- ARROW_GLOG_BUILD_VERSION: v0.5.0
-- ARROW_GLOG_BUILD_SHA256_CHECKSUM: eede71f28371bf39aa69b45de23b329d37214016e2055269b3b5e7cfd40b59f5
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_VERSION: v2.8.0
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_SHA256_CHECKSUM: 21fb441b5a670a18bb16b6826be8e0530888d0b94320847c538d46f5a54dddbc
-- ARROW_GRPC_BUILD_VERSION: v1.46.3
-- ARROW_GRPC_BUILD_SHA256_CHECKSUM: d6cbf22cb5007af71b61c6be316a79397469c58c82a942552a62e708bce60964
-- ARROW_GTEST_BUILD_VERSION: 1.11.0
-- ARROW_GTEST_BUILD_SHA256_CHECKSUM: b4870bf121ff7795ba20d20bcdd8627b8e088f2d1dab299a031c1034eddc93d5
-- ARROW_JEMALLOC_BUILD_VERSION: 5.3.0
-- ARROW_JEMALLOC_BUILD_SHA256_CHECKSUM: 2db82d1e7119df3e71b7640219b6dfe84789bc0537983c3b7ac4f7189aecfeaa
-- ARROW_LZ4_BUILD_VERSION: v1.9.4
-- ARROW_LZ4_BUILD_SHA256_CHECKSUM: 0b0e3aa07c8c063ddf40b082bdf7e37a1562bda40a0ff5272957f3e987e0e54b
-- ARROW_MIMALLOC_BUILD_VERSION: v2.0.6
-- ARROW_MIMALLOC_BUILD_SHA256_CHECKSUM: 9f05c94cc2b017ed13698834ac2a3567b6339a8bde27640df5a1581d49d05ce5
-- ARROW_NLOHMANN_JSON_BUILD_VERSION: v3.10.5
-- ARROW_NLOHMANN_JSON_BUILD_SHA256_CHECKSUM: 5daca6ca216495edf89d167f808d1d03c4a4d929cef7da5e10f135ae1540c7e4
-- ARROW_OPENTELEMETRY_BUILD_VERSION: v1.8.1
-- ARROW_OPENTELEMETRY_BUILD_SHA256_CHECKSUM: 3d640201594b07f08dade9cd1017bd0b59674daca26223b560b9bb6bf56264c2
-- ARROW_OPENTELEMETRY_PROTO_BUILD_VERSION: v0.17.0
-- ARROW_OPENTELEMETRY_PROTO_BUILD_SHA256_CHECKSUM: f269fbcb30e17b03caa1decd231ce826e59d7651c0f71c3b28eb5140b4bb5412
-- ARROW_ORC_BUILD_VERSION: 1.8.3
-- ARROW_ORC_BUILD_SHA256_CHECKSUM: a78678ec425c8129d63370cb8a9bacb54186aa66af1e2bec01ce92e7eaf72e20
-- ARROW_PROTOBUF_BUILD_VERSION: v21.3
-- ARROW_PROTOBUF_BUILD_SHA256_CHECKSUM: 2f723218f6cb709ae4cdc4fb5ed56a5951fc5d466f0128ce4c946b8c78c8c49f
-- ARROW_RAPIDJSON_BUILD_VERSION: 232389d4f1012dddec4ef84861face2d2ba85709
-- ARROW_RAPIDJSON_BUILD_SHA256_CHECKSUM: b9290a9a6d444c8e049bd589ab804e0ccf2b05dc5984a19ed5ae75d090064806
-- ARROW_RE2_BUILD_VERSION: 2022-06-01
-- ARROW_RE2_BUILD_SHA256_CHECKSUM: f89c61410a072e5cbcf8c27e3a778da7d6fd2f2b5b1445cd4f4508bee946ab0f
-- ARROW_SNAPPY_BUILD_VERSION: 1.1.9
-- ARROW_SNAPPY_BUILD_SHA256_CHECKSUM: 75c1fbb3d618dd3a0483bff0e26d0a92b495bbe5059c8b4f1c962b478b6e06e7
-- ARROW_SUBSTRAIT_BUILD_VERSION: v0.20.0
-- ARROW_SUBSTRAIT_BUILD_SHA256_CHECKSUM: 5ceaa559ccef29a7825b5e5d4b5e7eed384830294f08bec913feecdd903a94cf
-- ARROW_S2N_TLS_BUILD_VERSION: v1.3.35
-- ARROW_S2N_TLS_BUILD_SHA256_CHECKSUM: 9d32b26e6bfcc058d98248bf8fc231537e347395dd89cf62bb432b55c5da990d
-- ARROW_THRIFT_BUILD_VERSION: 0.16.0
-- ARROW_THRIFT_BUILD_SHA256_CHECKSUM: f460b5c1ca30d8918ff95ea3eb6291b3951cf518553566088f3f2be8981f6209
-- ARROW_UCX_BUILD_VERSION: 1.12.1
-- ARROW_UCX_BUILD_SHA256_CHECKSUM: 9bef31aed0e28bf1973d28d74d9ac4f8926c43ca3b7010bd22a084e164e31b71
-- ARROW_UTF8PROC_BUILD_VERSION: v2.7.0
-- ARROW_UTF8PROC_BUILD_SHA256_CHECKSUM: 4bb121e297293c0fd55f08f83afab6d35d48f0af4ecc07523ad8ec99aa2b12a1
-- ARROW_XSIMD_BUILD_VERSION: 9.0.1
-- ARROW_XSIMD_BUILD_SHA256_CHECKSUM: b1bb5f92167fd3a4f25749db0be7e61ed37e0a5d943490f3accdcd2cd2918cc0
-- ARROW_ZLIB_BUILD_VERSION: 1.2.13
-- ARROW_ZLIB_BUILD_SHA256_CHECKSUM: b3a24de97a8fdbc835b9833169501030b8977031bcb54b3b3ac13740f846ab30
-- ARROW_ZSTD_BUILD_VERSION: 1.5.5
-- ARROW_ZSTD_BUILD_SHA256_CHECKSUM: 9c4396cc829cfae319a6e2615202e82aad41372073482fce286fac78646d3ee4
-- Looking for pthread.h
-- Looking for pthread.h - found
-- Performing Test CMAKE_HAVE_LIBC_PTHREAD
-- Performing Test CMAKE_HAVE_LIBC_PTHREAD - Success
-- Found Threads: TRUE  
-- Looking for _M_ARM64
-- Looking for _M_ARM64 - not found
-- Looking for __SIZEOF_INT128__
-- Looking for __SIZEOF_INT128__ - found
-- Building without OpenSSL support. Minimum OpenSSL version 1.0.2 required.
-- Building jemalloc from source
CMake Error at cmake_modules/ThirdpartyToolchain.cmake:286 (find_package):
  By not providing "Findxsimd.cmake" in CMAKE_MODULE_PATH this project has
  asked CMake to find a package configuration file provided by "xsimd", but
  CMake did not find one.

  Could not find a package configuration file provided by "xsimd" with any of
  the following names:

    xsimdConfig.cmake
    xsimd-config.cmake

  Add the installation prefix of "xsimd" to CMAKE_PREFIX_PATH or set
  "xsimd_DIR" to a directory containing one of the above files.  If "xsimd"
  provides a separate development package or SDK, be sure it has been
  installed.
Call Stack (most recent call first):
  cmake_modules/ThirdpartyToolchain.cmake:2424 (resolve_dependency)
  CMakeLists.txt:506 (include)


-- Configuring incomplete, errors occurred!
See also "/home/tdhock/arrow/cpp/build/CMakeFiles/CMakeOutput.log".
See also "/home/tdhock/arrow/cpp/build/CMakeFiles/CMakeError.log".
```

What is [xsimd](https://xsimd.readthedocs.io/en/latest/)?  Single
instruction, multiple data, a microprocessor instruction. "xsimd
provides a unified means for using these features for library
authors. Namely, it enables manipulation of batches of scalar and
complex numbers with the same arithmetic operators and common
mathematical functions as for single values. xsimd makes it easy to
write a single algorithm, generate one version of the algorithm per
micro-architecture and pick the best one at runtime, based on the
running processor capability."

Tried installing from APT, but it is too old, as shown below,

```
(base) tdhock@tdhock-MacBook:~/arrow/cpp/build(main)$ aptitude search xsimd
p   libxsimd-dev                    - C++ wrappers for SIMD intrinsics          
p   libxsimd-doc                    - Documentation for xsimd                   
(base) tdhock@tdhock-MacBook:~/arrow/cpp/build(main)$ sudo aptitude install libxsimd-dev
[sudo] Mot de passe de tdhock : 
Les NOUVEAUX paquets suivants vont être installés : 
  libxsimd-dev 
0 paquets mis à jour, 1 nouvellement installés, 0 à enlever et 0 non mis à jour.
Il est nécessaire de télécharger 108 ko d'archives. Après dépaquetage, 1 386 ko seront utilisés.
Prendre :  1 http://mirror.arizona.edu/ubuntu jammy/universe amd64 libxsimd-dev amd64 7.6.0-2 [108 kB]
 108 ko téléchargés en 0s (759 ko/s)
debconf: Impossible d'initialiser l'interface : Dialog
debconf: (L'interface dialog ne fonctionnera pas avec un terminal rustique (« dumb »), un tampon shell d'Emacs ou sans terminal de contrôle.)
debconf: Utilisation de l'interface Readline en remplacement
Sélection du paquet libxsimd-dev:amd64 précédemment désélectionné.
(Lecture de la base de données... 402515 fichiers et répertoires déjà installés.)
Préparation du dépaquetage de .../libxsimd-dev_7.6.0-2_amd64.deb ...
Dépaquetage de libxsimd-dev:amd64 (7.6.0-2) ...
Paramétrage de libxsimd-dev:amd64 (7.6.0-2) ...
                                                        
(base) tdhock@tdhock-MacBook:~/arrow/cpp/build(main)$ cmake .. --preset ninja-debug-minimal
Preset CMake variables:

  ARROW_BUILD_INTEGRATION="OFF"
  ARROW_BUILD_STATIC="OFF"
  ARROW_BUILD_TESTS="OFF"
  ARROW_EXTRA_ERROR_CONTEXT="ON"
  ARROW_WITH_RE2="OFF"
  ARROW_WITH_UTF8PROC="OFF"
  CMAKE_BUILD_TYPE="Debug"

-- Building using CMake version: 3.22.1
-- Arrow version: 13.0.0 (full: '13.0.0-SNAPSHOT')
-- Arrow SO version: 1300 (full: 1300.0.0)
-- clang-tidy 14 not found
-- clang-format 14 not found
-- Could NOT find ClangTools (missing: CLANG_FORMAT_BIN CLANG_TIDY_BIN) 
-- infer not found
-- Found cpplint executable at /home/tdhock/arrow/cpp/build-support/cpplint.py
-- System processor: x86_64
-- Arrow build warning level: CHECKIN
-- Using ld linker
-- Build Type: DEBUG
-- Using CONDA approach to find dependencies
-- Using CONDA_PREFIX for ARROW_PACKAGE_PREFIX: /home/tdhock/miniconda3
-- Setting (unset) dependency *_ROOT variables: /home/tdhock/miniconda3
-- ARROW_ABSL_BUILD_VERSION: 20211102.0
-- ARROW_ABSL_BUILD_SHA256_CHECKSUM: dcf71b9cba8dc0ca9940c4b316a0c796be8fab42b070bb6b7cab62b48f0e66c4
-- ARROW_AWS_C_AUTH_BUILD_VERSION: v0.6.22
-- ARROW_AWS_C_AUTH_BUILD_SHA256_CHECKSUM: 691a6b4418afcd3dc141351b6ad33fccd8e3ff84df0e9e045b42295d284ee14c
-- ARROW_AWS_C_CAL_BUILD_VERSION: v0.5.20
-- ARROW_AWS_C_CAL_BUILD_SHA256_CHECKSUM: acc352359bd06f8597415c366cf4ec4f00d0b0da92d637039a73323dd55b6cd0
-- ARROW_AWS_C_COMMON_BUILD_VERSION: v0.8.9
-- ARROW_AWS_C_COMMON_BUILD_SHA256_CHECKSUM: 2f3fbaf7c38eae5a00e2a816d09b81177f93529ae8ba1b82dc8f31407565327a
-- ARROW_AWS_C_COMPRESSION_BUILD_VERSION: v0.2.16
-- ARROW_AWS_C_COMPRESSION_BUILD_SHA256_CHECKSUM: 044b1dbbca431a07bde8255ef9ec443c300fc60d4c9408d4b862f65e496687f4
-- ARROW_AWS_C_EVENT_STREAM_BUILD_VERSION: v0.2.18
-- ARROW_AWS_C_EVENT_STREAM_BUILD_SHA256_CHECKSUM: 310ca617f713bf664e4c7485a3d42c1fb57813abd0107e49790d107def7cde4f
-- ARROW_AWS_C_HTTP_BUILD_VERSION: v0.7.3
-- ARROW_AWS_C_HTTP_BUILD_SHA256_CHECKSUM: 07e16c6bf5eba6f0dea96b6f55eae312a7c95b736f4d2e4a210000f45d8265ae
-- ARROW_AWS_C_IO_BUILD_VERSION: v0.13.14
-- ARROW_AWS_C_IO_BUILD_SHA256_CHECKSUM: 12b66510c3d9a4f7e9b714e9cfab2a5bf835f8b9ce2f909d20ae2a2128608c71
-- ARROW_AWS_C_MQTT_BUILD_VERSION: v0.8.4
-- ARROW_AWS_C_MQTT_BUILD_SHA256_CHECKSUM: 232eeac63e72883d460c686a09b98cdd811d24579affac47c5c3f696f956773f
-- ARROW_AWS_C_S3_BUILD_VERSION: v0.2.3
-- ARROW_AWS_C_S3_BUILD_SHA256_CHECKSUM: a00b3c9f319cd1c9aa2c3fa15098864df94b066dcba0deaccbb3caa952d902fe
-- ARROW_AWS_C_SDKUTILS_BUILD_VERSION: v0.1.6
-- ARROW_AWS_C_SDKUTILS_BUILD_SHA256_CHECKSUM: 8a2951344b2fb541eab1e9ca17c18a7fcbfd2aaff4cdd31d362d1fad96111b91
-- ARROW_AWS_CHECKSUMS_BUILD_VERSION: v0.1.13
-- ARROW_AWS_CHECKSUMS_BUILD_SHA256_CHECKSUM: 0f897686f1963253c5069a0e495b85c31635ba146cd3ac38cc2ea31eaf54694d
-- ARROW_AWS_CRT_CPP_BUILD_VERSION: v0.18.16
-- ARROW_AWS_CRT_CPP_BUILD_SHA256_CHECKSUM: 9e69bc1dc4b50871d1038aa9ff6ddeb4c9b28f7d6b5e5b1b69041ccf50a13483
-- ARROW_AWS_LC_BUILD_VERSION: v1.3.0
-- ARROW_AWS_LC_BUILD_SHA256_CHECKSUM: ae96a3567161552744fc0cae8b4d68ed88b1ec0f3d3c98700070115356da5a37
-- ARROW_AWSSDK_BUILD_VERSION: 1.10.55
-- ARROW_AWSSDK_BUILD_SHA256_CHECKSUM: 2d552fb1a84bef4a9b65e34aa7031851ed2aef5319e02cc6e4cb735c48aa30de
-- ARROW_BOOST_BUILD_VERSION: 1.81.0
-- ARROW_BOOST_BUILD_SHA256_CHECKSUM: 9e0ffae35528c35f90468997bc8d99500bf179cbae355415a89a600c38e13574
-- ARROW_BROTLI_BUILD_VERSION: v1.0.9
-- ARROW_BROTLI_BUILD_SHA256_CHECKSUM: f9e8d81d0405ba66d181529af42a3354f838c939095ff99930da6aa9cdf6fe46
-- ARROW_BZIP2_BUILD_VERSION: 1.0.8
-- ARROW_BZIP2_BUILD_SHA256_CHECKSUM: ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269
-- ARROW_CARES_BUILD_VERSION: 1.17.2
-- ARROW_CARES_BUILD_SHA256_CHECKSUM: 4803c844ce20ce510ef0eb83f8ea41fa24ecaae9d280c468c582d2bb25b3913d
-- ARROW_CRC32C_BUILD_VERSION: 1.1.2
-- ARROW_CRC32C_BUILD_SHA256_CHECKSUM: ac07840513072b7fcebda6e821068aa04889018f24e10e46181068fb214d7e56
-- ARROW_GBENCHMARK_BUILD_VERSION: v1.7.1
-- ARROW_GBENCHMARK_BUILD_SHA256_CHECKSUM: 6430e4092653380d9dc4ccb45a1e2dc9259d581f4866dc0759713126056bc1d7
-- ARROW_GFLAGS_BUILD_VERSION: v2.2.2
-- ARROW_GFLAGS_BUILD_SHA256_CHECKSUM: 34af2f15cf7367513b352bdcd2493ab14ce43692d2dcd9dfc499492966c64dcf
-- ARROW_GLOG_BUILD_VERSION: v0.5.0
-- ARROW_GLOG_BUILD_SHA256_CHECKSUM: eede71f28371bf39aa69b45de23b329d37214016e2055269b3b5e7cfd40b59f5
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_VERSION: v2.8.0
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_SHA256_CHECKSUM: 21fb441b5a670a18bb16b6826be8e0530888d0b94320847c538d46f5a54dddbc
-- ARROW_GRPC_BUILD_VERSION: v1.46.3
-- ARROW_GRPC_BUILD_SHA256_CHECKSUM: d6cbf22cb5007af71b61c6be316a79397469c58c82a942552a62e708bce60964
-- ARROW_GTEST_BUILD_VERSION: 1.11.0
-- ARROW_GTEST_BUILD_SHA256_CHECKSUM: b4870bf121ff7795ba20d20bcdd8627b8e088f2d1dab299a031c1034eddc93d5
-- ARROW_JEMALLOC_BUILD_VERSION: 5.3.0
-- ARROW_JEMALLOC_BUILD_SHA256_CHECKSUM: 2db82d1e7119df3e71b7640219b6dfe84789bc0537983c3b7ac4f7189aecfeaa
-- ARROW_LZ4_BUILD_VERSION: v1.9.4
-- ARROW_LZ4_BUILD_SHA256_CHECKSUM: 0b0e3aa07c8c063ddf40b082bdf7e37a1562bda40a0ff5272957f3e987e0e54b
-- ARROW_MIMALLOC_BUILD_VERSION: v2.0.6
-- ARROW_MIMALLOC_BUILD_SHA256_CHECKSUM: 9f05c94cc2b017ed13698834ac2a3567b6339a8bde27640df5a1581d49d05ce5
-- ARROW_NLOHMANN_JSON_BUILD_VERSION: v3.10.5
-- ARROW_NLOHMANN_JSON_BUILD_SHA256_CHECKSUM: 5daca6ca216495edf89d167f808d1d03c4a4d929cef7da5e10f135ae1540c7e4
-- ARROW_OPENTELEMETRY_BUILD_VERSION: v1.8.1
-- ARROW_OPENTELEMETRY_BUILD_SHA256_CHECKSUM: 3d640201594b07f08dade9cd1017bd0b59674daca26223b560b9bb6bf56264c2
-- ARROW_OPENTELEMETRY_PROTO_BUILD_VERSION: v0.17.0
-- ARROW_OPENTELEMETRY_PROTO_BUILD_SHA256_CHECKSUM: f269fbcb30e17b03caa1decd231ce826e59d7651c0f71c3b28eb5140b4bb5412
-- ARROW_ORC_BUILD_VERSION: 1.8.3
-- ARROW_ORC_BUILD_SHA256_CHECKSUM: a78678ec425c8129d63370cb8a9bacb54186aa66af1e2bec01ce92e7eaf72e20
-- ARROW_PROTOBUF_BUILD_VERSION: v21.3
-- ARROW_PROTOBUF_BUILD_SHA256_CHECKSUM: 2f723218f6cb709ae4cdc4fb5ed56a5951fc5d466f0128ce4c946b8c78c8c49f
-- ARROW_RAPIDJSON_BUILD_VERSION: 232389d4f1012dddec4ef84861face2d2ba85709
-- ARROW_RAPIDJSON_BUILD_SHA256_CHECKSUM: b9290a9a6d444c8e049bd589ab804e0ccf2b05dc5984a19ed5ae75d090064806
-- ARROW_RE2_BUILD_VERSION: 2022-06-01
-- ARROW_RE2_BUILD_SHA256_CHECKSUM: f89c61410a072e5cbcf8c27e3a778da7d6fd2f2b5b1445cd4f4508bee946ab0f
-- ARROW_SNAPPY_BUILD_VERSION: 1.1.9
-- ARROW_SNAPPY_BUILD_SHA256_CHECKSUM: 75c1fbb3d618dd3a0483bff0e26d0a92b495bbe5059c8b4f1c962b478b6e06e7
-- ARROW_SUBSTRAIT_BUILD_VERSION: v0.20.0
-- ARROW_SUBSTRAIT_BUILD_SHA256_CHECKSUM: 5ceaa559ccef29a7825b5e5d4b5e7eed384830294f08bec913feecdd903a94cf
-- ARROW_S2N_TLS_BUILD_VERSION: v1.3.35
-- ARROW_S2N_TLS_BUILD_SHA256_CHECKSUM: 9d32b26e6bfcc058d98248bf8fc231537e347395dd89cf62bb432b55c5da990d
-- ARROW_THRIFT_BUILD_VERSION: 0.16.0
-- ARROW_THRIFT_BUILD_SHA256_CHECKSUM: f460b5c1ca30d8918ff95ea3eb6291b3951cf518553566088f3f2be8981f6209
-- ARROW_UCX_BUILD_VERSION: 1.12.1
-- ARROW_UCX_BUILD_SHA256_CHECKSUM: 9bef31aed0e28bf1973d28d74d9ac4f8926c43ca3b7010bd22a084e164e31b71
-- ARROW_UTF8PROC_BUILD_VERSION: v2.7.0
-- ARROW_UTF8PROC_BUILD_SHA256_CHECKSUM: 4bb121e297293c0fd55f08f83afab6d35d48f0af4ecc07523ad8ec99aa2b12a1
-- ARROW_XSIMD_BUILD_VERSION: 9.0.1
-- ARROW_XSIMD_BUILD_SHA256_CHECKSUM: b1bb5f92167fd3a4f25749db0be7e61ed37e0a5d943490f3accdcd2cd2918cc0
-- ARROW_ZLIB_BUILD_VERSION: 1.2.13
-- ARROW_ZLIB_BUILD_SHA256_CHECKSUM: b3a24de97a8fdbc835b9833169501030b8977031bcb54b3b3ac13740f846ab30
-- ARROW_ZSTD_BUILD_VERSION: 1.5.5
-- ARROW_ZSTD_BUILD_SHA256_CHECKSUM: 9c4396cc829cfae319a6e2615202e82aad41372073482fce286fac78646d3ee4
-- Building without OpenSSL support. Minimum OpenSSL version 1.0.2 required.
-- Building jemalloc from source
CMake Error at cmake_modules/ThirdpartyToolchain.cmake:289 (message):
  Couldn't find xsimd >= 8.1.0
Call Stack (most recent call first):
  cmake_modules/ThirdpartyToolchain.cmake:2424 (resolve_dependency)
  CMakeLists.txt:506 (include)


-- Configuring incomplete, errors occurred!
See also "/home/tdhock/arrow/cpp/build/CMakeFiles/CMakeOutput.log".
See also "/home/tdhock/arrow/cpp/build/CMakeFiles/CMakeError.log".
```

[Conda-forge has xsimd version
11](https://anaconda.org/conda-forge/xsimd), and regular conda has
version 10 as shown below,

```
(base) tdhock@tdhock-MacBook:~/arrow/cpp/build(main)$ conda activate arrow
(arrow) tdhock@tdhock-MacBook:~/arrow/cpp/build(main)$ conda install xsimd
Collecting package metadata (current_repodata.json): done
Solving environment: done

## Package Plan ##

  environment location: /home/tdhock/miniconda3/envs/arrow

  added / updated specs:
    - xsimd


The following packages will be downloaded:

    package                    |            build
    ---------------------------|-----------------
    xsimd-10.0.0               |       hdb19cb5_0         113 KB
    ------------------------------------------------------------
                                           Total:         113 KB

The following NEW packages will be INSTALLED:

  xsimd              pkgs/main/linux-64::xsimd-10.0.0-hdb19cb5_0 

The following packages will be UPDATED:

  ca-certificates    conda-forge::ca-certificates-2022.12.~ --> pkgs/main::ca-certificates-2023.01.10-h06a4308_0 


Proceed ([y]/n)? 


Downloading and Extracting Packages
                                                                                
Preparing transaction: done
Verifying transaction: done
Executing transaction: done
(arrow) tdhock@tdhock-MacBook:~/arrow/cpp/build(main)$ cmake .. --preset ninja-debug-minimal
Preset CMake variables:

  ARROW_BUILD_INTEGRATION="OFF"
  ARROW_BUILD_STATIC="OFF"
  ARROW_BUILD_TESTS="OFF"
  ARROW_EXTRA_ERROR_CONTEXT="ON"
  ARROW_WITH_RE2="OFF"
  ARROW_WITH_UTF8PROC="OFF"
  CMAKE_BUILD_TYPE="Debug"

-- Building using CMake version: 3.22.1
-- Arrow version: 13.0.0 (full: '13.0.0-SNAPSHOT')
-- Arrow SO version: 1300 (full: 1300.0.0)
-- clang-tidy 14 not found
-- clang-format 14 not found
-- Could NOT find ClangTools (missing: CLANG_FORMAT_BIN CLANG_TIDY_BIN) 
-- infer not found
-- Found cpplint executable at /home/tdhock/arrow/cpp/build-support/cpplint.py
-- System processor: x86_64
-- Arrow build warning level: CHECKIN
-- Using ld linker
-- Build Type: DEBUG
-- Using CONDA approach to find dependencies
-- Using CONDA_PREFIX for ARROW_PACKAGE_PREFIX: /home/tdhock/miniconda3/envs/arrow
-- Setting (unset) dependency *_ROOT variables: /home/tdhock/miniconda3/envs/arrow
-- ARROW_ABSL_BUILD_VERSION: 20211102.0
-- ARROW_ABSL_BUILD_SHA256_CHECKSUM: dcf71b9cba8dc0ca9940c4b316a0c796be8fab42b070bb6b7cab62b48f0e66c4
-- ARROW_AWS_C_AUTH_BUILD_VERSION: v0.6.22
-- ARROW_AWS_C_AUTH_BUILD_SHA256_CHECKSUM: 691a6b4418afcd3dc141351b6ad33fccd8e3ff84df0e9e045b42295d284ee14c
-- ARROW_AWS_C_CAL_BUILD_VERSION: v0.5.20
-- ARROW_AWS_C_CAL_BUILD_SHA256_CHECKSUM: acc352359bd06f8597415c366cf4ec4f00d0b0da92d637039a73323dd55b6cd0
-- ARROW_AWS_C_COMMON_BUILD_VERSION: v0.8.9
-- ARROW_AWS_C_COMMON_BUILD_SHA256_CHECKSUM: 2f3fbaf7c38eae5a00e2a816d09b81177f93529ae8ba1b82dc8f31407565327a
-- ARROW_AWS_C_COMPRESSION_BUILD_VERSION: v0.2.16
-- ARROW_AWS_C_COMPRESSION_BUILD_SHA256_CHECKSUM: 044b1dbbca431a07bde8255ef9ec443c300fc60d4c9408d4b862f65e496687f4
-- ARROW_AWS_C_EVENT_STREAM_BUILD_VERSION: v0.2.18
-- ARROW_AWS_C_EVENT_STREAM_BUILD_SHA256_CHECKSUM: 310ca617f713bf664e4c7485a3d42c1fb57813abd0107e49790d107def7cde4f
-- ARROW_AWS_C_HTTP_BUILD_VERSION: v0.7.3
-- ARROW_AWS_C_HTTP_BUILD_SHA256_CHECKSUM: 07e16c6bf5eba6f0dea96b6f55eae312a7c95b736f4d2e4a210000f45d8265ae
-- ARROW_AWS_C_IO_BUILD_VERSION: v0.13.14
-- ARROW_AWS_C_IO_BUILD_SHA256_CHECKSUM: 12b66510c3d9a4f7e9b714e9cfab2a5bf835f8b9ce2f909d20ae2a2128608c71
-- ARROW_AWS_C_MQTT_BUILD_VERSION: v0.8.4
-- ARROW_AWS_C_MQTT_BUILD_SHA256_CHECKSUM: 232eeac63e72883d460c686a09b98cdd811d24579affac47c5c3f696f956773f
-- ARROW_AWS_C_S3_BUILD_VERSION: v0.2.3
-- ARROW_AWS_C_S3_BUILD_SHA256_CHECKSUM: a00b3c9f319cd1c9aa2c3fa15098864df94b066dcba0deaccbb3caa952d902fe
-- ARROW_AWS_C_SDKUTILS_BUILD_VERSION: v0.1.6
-- ARROW_AWS_C_SDKUTILS_BUILD_SHA256_CHECKSUM: 8a2951344b2fb541eab1e9ca17c18a7fcbfd2aaff4cdd31d362d1fad96111b91
-- ARROW_AWS_CHECKSUMS_BUILD_VERSION: v0.1.13
-- ARROW_AWS_CHECKSUMS_BUILD_SHA256_CHECKSUM: 0f897686f1963253c5069a0e495b85c31635ba146cd3ac38cc2ea31eaf54694d
-- ARROW_AWS_CRT_CPP_BUILD_VERSION: v0.18.16
-- ARROW_AWS_CRT_CPP_BUILD_SHA256_CHECKSUM: 9e69bc1dc4b50871d1038aa9ff6ddeb4c9b28f7d6b5e5b1b69041ccf50a13483
-- ARROW_AWS_LC_BUILD_VERSION: v1.3.0
-- ARROW_AWS_LC_BUILD_SHA256_CHECKSUM: ae96a3567161552744fc0cae8b4d68ed88b1ec0f3d3c98700070115356da5a37
-- ARROW_AWSSDK_BUILD_VERSION: 1.10.55
-- ARROW_AWSSDK_BUILD_SHA256_CHECKSUM: 2d552fb1a84bef4a9b65e34aa7031851ed2aef5319e02cc6e4cb735c48aa30de
-- ARROW_BOOST_BUILD_VERSION: 1.81.0
-- ARROW_BOOST_BUILD_SHA256_CHECKSUM: 9e0ffae35528c35f90468997bc8d99500bf179cbae355415a89a600c38e13574
-- ARROW_BROTLI_BUILD_VERSION: v1.0.9
-- ARROW_BROTLI_BUILD_SHA256_CHECKSUM: f9e8d81d0405ba66d181529af42a3354f838c939095ff99930da6aa9cdf6fe46
-- ARROW_BZIP2_BUILD_VERSION: 1.0.8
-- ARROW_BZIP2_BUILD_SHA256_CHECKSUM: ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269
-- ARROW_CARES_BUILD_VERSION: 1.17.2
-- ARROW_CARES_BUILD_SHA256_CHECKSUM: 4803c844ce20ce510ef0eb83f8ea41fa24ecaae9d280c468c582d2bb25b3913d
-- ARROW_CRC32C_BUILD_VERSION: 1.1.2
-- ARROW_CRC32C_BUILD_SHA256_CHECKSUM: ac07840513072b7fcebda6e821068aa04889018f24e10e46181068fb214d7e56
-- ARROW_GBENCHMARK_BUILD_VERSION: v1.7.1
-- ARROW_GBENCHMARK_BUILD_SHA256_CHECKSUM: 6430e4092653380d9dc4ccb45a1e2dc9259d581f4866dc0759713126056bc1d7
-- ARROW_GFLAGS_BUILD_VERSION: v2.2.2
-- ARROW_GFLAGS_BUILD_SHA256_CHECKSUM: 34af2f15cf7367513b352bdcd2493ab14ce43692d2dcd9dfc499492966c64dcf
-- ARROW_GLOG_BUILD_VERSION: v0.5.0
-- ARROW_GLOG_BUILD_SHA256_CHECKSUM: eede71f28371bf39aa69b45de23b329d37214016e2055269b3b5e7cfd40b59f5
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_VERSION: v2.8.0
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_SHA256_CHECKSUM: 21fb441b5a670a18bb16b6826be8e0530888d0b94320847c538d46f5a54dddbc
-- ARROW_GRPC_BUILD_VERSION: v1.46.3
-- ARROW_GRPC_BUILD_SHA256_CHECKSUM: d6cbf22cb5007af71b61c6be316a79397469c58c82a942552a62e708bce60964
-- ARROW_GTEST_BUILD_VERSION: 1.11.0
-- ARROW_GTEST_BUILD_SHA256_CHECKSUM: b4870bf121ff7795ba20d20bcdd8627b8e088f2d1dab299a031c1034eddc93d5
-- ARROW_JEMALLOC_BUILD_VERSION: 5.3.0
-- ARROW_JEMALLOC_BUILD_SHA256_CHECKSUM: 2db82d1e7119df3e71b7640219b6dfe84789bc0537983c3b7ac4f7189aecfeaa
-- ARROW_LZ4_BUILD_VERSION: v1.9.4
-- ARROW_LZ4_BUILD_SHA256_CHECKSUM: 0b0e3aa07c8c063ddf40b082bdf7e37a1562bda40a0ff5272957f3e987e0e54b
-- ARROW_MIMALLOC_BUILD_VERSION: v2.0.6
-- ARROW_MIMALLOC_BUILD_SHA256_CHECKSUM: 9f05c94cc2b017ed13698834ac2a3567b6339a8bde27640df5a1581d49d05ce5
-- ARROW_NLOHMANN_JSON_BUILD_VERSION: v3.10.5
-- ARROW_NLOHMANN_JSON_BUILD_SHA256_CHECKSUM: 5daca6ca216495edf89d167f808d1d03c4a4d929cef7da5e10f135ae1540c7e4
-- ARROW_OPENTELEMETRY_BUILD_VERSION: v1.8.1
-- ARROW_OPENTELEMETRY_BUILD_SHA256_CHECKSUM: 3d640201594b07f08dade9cd1017bd0b59674daca26223b560b9bb6bf56264c2
-- ARROW_OPENTELEMETRY_PROTO_BUILD_VERSION: v0.17.0
-- ARROW_OPENTELEMETRY_PROTO_BUILD_SHA256_CHECKSUM: f269fbcb30e17b03caa1decd231ce826e59d7651c0f71c3b28eb5140b4bb5412
-- ARROW_ORC_BUILD_VERSION: 1.8.3
-- ARROW_ORC_BUILD_SHA256_CHECKSUM: a78678ec425c8129d63370cb8a9bacb54186aa66af1e2bec01ce92e7eaf72e20
-- ARROW_PROTOBUF_BUILD_VERSION: v21.3
-- ARROW_PROTOBUF_BUILD_SHA256_CHECKSUM: 2f723218f6cb709ae4cdc4fb5ed56a5951fc5d466f0128ce4c946b8c78c8c49f
-- ARROW_RAPIDJSON_BUILD_VERSION: 232389d4f1012dddec4ef84861face2d2ba85709
-- ARROW_RAPIDJSON_BUILD_SHA256_CHECKSUM: b9290a9a6d444c8e049bd589ab804e0ccf2b05dc5984a19ed5ae75d090064806
-- ARROW_RE2_BUILD_VERSION: 2022-06-01
-- ARROW_RE2_BUILD_SHA256_CHECKSUM: f89c61410a072e5cbcf8c27e3a778da7d6fd2f2b5b1445cd4f4508bee946ab0f
-- ARROW_SNAPPY_BUILD_VERSION: 1.1.9
-- ARROW_SNAPPY_BUILD_SHA256_CHECKSUM: 75c1fbb3d618dd3a0483bff0e26d0a92b495bbe5059c8b4f1c962b478b6e06e7
-- ARROW_SUBSTRAIT_BUILD_VERSION: v0.20.0
-- ARROW_SUBSTRAIT_BUILD_SHA256_CHECKSUM: 5ceaa559ccef29a7825b5e5d4b5e7eed384830294f08bec913feecdd903a94cf
-- ARROW_S2N_TLS_BUILD_VERSION: v1.3.35
-- ARROW_S2N_TLS_BUILD_SHA256_CHECKSUM: 9d32b26e6bfcc058d98248bf8fc231537e347395dd89cf62bb432b55c5da990d
-- ARROW_THRIFT_BUILD_VERSION: 0.16.0
-- ARROW_THRIFT_BUILD_SHA256_CHECKSUM: f460b5c1ca30d8918ff95ea3eb6291b3951cf518553566088f3f2be8981f6209
-- ARROW_UCX_BUILD_VERSION: 1.12.1
-- ARROW_UCX_BUILD_SHA256_CHECKSUM: 9bef31aed0e28bf1973d28d74d9ac4f8926c43ca3b7010bd22a084e164e31b71
-- ARROW_UTF8PROC_BUILD_VERSION: v2.7.0
-- ARROW_UTF8PROC_BUILD_SHA256_CHECKSUM: 4bb121e297293c0fd55f08f83afab6d35d48f0af4ecc07523ad8ec99aa2b12a1
-- ARROW_XSIMD_BUILD_VERSION: 9.0.1
-- ARROW_XSIMD_BUILD_SHA256_CHECKSUM: b1bb5f92167fd3a4f25749db0be7e61ed37e0a5d943490f3accdcd2cd2918cc0
-- ARROW_ZLIB_BUILD_VERSION: 1.2.13
-- ARROW_ZLIB_BUILD_SHA256_CHECKSUM: b3a24de97a8fdbc835b9833169501030b8977031bcb54b3b3ac13740f846ab30
-- ARROW_ZSTD_BUILD_VERSION: 1.5.5
-- ARROW_ZSTD_BUILD_SHA256_CHECKSUM: 9c4396cc829cfae319a6e2615202e82aad41372073482fce286fac78646d3ee4
-- Building without OpenSSL support. Minimum OpenSSL version 1.0.2 required.
-- Building jemalloc from source
CMake Error at cmake_modules/ThirdpartyToolchain.cmake:289 (message):
  Couldn't find xsimd >= 8.1.0
Call Stack (most recent call first):
  cmake_modules/ThirdpartyToolchain.cmake:2424 (resolve_dependency)
  CMakeLists.txt:506 (include)


-- Configuring incomplete, errors occurred!
See also "/home/tdhock/arrow/cpp/build/CMakeFiles/CMakeOutput.log".
See also "/home/tdhock/arrow/cpp/build/CMakeFiles/CMakeError.log".
```

Seems like when CMAKE sees the APT xsimd, which is too old, it fails,
without looking for the conda one, so we have to remove the APT
version:

```
(arrow) tdhock@tdhock-MacBook:~/arrow/cpp/build(main)$ sudo aptitude remove libxsimd-dev
Les paquets suivants seront ENLEVÉS : 
  libxsimd-dev 
0 paquets mis à jour, 0 nouvellement installés, 1 à enlever et 0 non mis à jour.
Il est nécessaire de télécharger 0 o d'archives. Après dépaquetage, 1 386 ko seront libérés.
(Lecture de la base de données... 402613 fichiers et répertoires déjà installés.)
Suppression de libxsimd-dev:amd64 (7.6.0-2) ...
                                                        
(arrow) tdhock@tdhock-MacBook:~/arrow/cpp/build(main)$ cmake .. --preset ninja-debug-minimal
Preset CMake variables:

  ARROW_BUILD_INTEGRATION="OFF"
  ARROW_BUILD_STATIC="OFF"
  ARROW_BUILD_TESTS="OFF"
  ARROW_EXTRA_ERROR_CONTEXT="ON"
  ARROW_WITH_RE2="OFF"
  ARROW_WITH_UTF8PROC="OFF"
  CMAKE_BUILD_TYPE="Debug"

-- Building using CMake version: 3.22.1
-- Arrow version: 13.0.0 (full: '13.0.0-SNAPSHOT')
-- Arrow SO version: 1300 (full: 1300.0.0)
-- clang-tidy 14 not found
-- clang-format 14 not found
-- Could NOT find ClangTools (missing: CLANG_FORMAT_BIN CLANG_TIDY_BIN) 
-- infer not found
-- Found cpplint executable at /home/tdhock/arrow/cpp/build-support/cpplint.py
-- System processor: x86_64
-- Arrow build warning level: CHECKIN
-- Using ld linker
-- Build Type: DEBUG
-- Using CONDA approach to find dependencies
-- Using CONDA_PREFIX for ARROW_PACKAGE_PREFIX: /home/tdhock/miniconda3/envs/arrow
-- Setting (unset) dependency *_ROOT variables: /home/tdhock/miniconda3/envs/arrow
-- ARROW_ABSL_BUILD_VERSION: 20211102.0
-- ARROW_ABSL_BUILD_SHA256_CHECKSUM: dcf71b9cba8dc0ca9940c4b316a0c796be8fab42b070bb6b7cab62b48f0e66c4
-- ARROW_AWS_C_AUTH_BUILD_VERSION: v0.6.22
-- ARROW_AWS_C_AUTH_BUILD_SHA256_CHECKSUM: 691a6b4418afcd3dc141351b6ad33fccd8e3ff84df0e9e045b42295d284ee14c
-- ARROW_AWS_C_CAL_BUILD_VERSION: v0.5.20
-- ARROW_AWS_C_CAL_BUILD_SHA256_CHECKSUM: acc352359bd06f8597415c366cf4ec4f00d0b0da92d637039a73323dd55b6cd0
-- ARROW_AWS_C_COMMON_BUILD_VERSION: v0.8.9
-- ARROW_AWS_C_COMMON_BUILD_SHA256_CHECKSUM: 2f3fbaf7c38eae5a00e2a816d09b81177f93529ae8ba1b82dc8f31407565327a
-- ARROW_AWS_C_COMPRESSION_BUILD_VERSION: v0.2.16
-- ARROW_AWS_C_COMPRESSION_BUILD_SHA256_CHECKSUM: 044b1dbbca431a07bde8255ef9ec443c300fc60d4c9408d4b862f65e496687f4
-- ARROW_AWS_C_EVENT_STREAM_BUILD_VERSION: v0.2.18
-- ARROW_AWS_C_EVENT_STREAM_BUILD_SHA256_CHECKSUM: 310ca617f713bf664e4c7485a3d42c1fb57813abd0107e49790d107def7cde4f
-- ARROW_AWS_C_HTTP_BUILD_VERSION: v0.7.3
-- ARROW_AWS_C_HTTP_BUILD_SHA256_CHECKSUM: 07e16c6bf5eba6f0dea96b6f55eae312a7c95b736f4d2e4a210000f45d8265ae
-- ARROW_AWS_C_IO_BUILD_VERSION: v0.13.14
-- ARROW_AWS_C_IO_BUILD_SHA256_CHECKSUM: 12b66510c3d9a4f7e9b714e9cfab2a5bf835f8b9ce2f909d20ae2a2128608c71
-- ARROW_AWS_C_MQTT_BUILD_VERSION: v0.8.4
-- ARROW_AWS_C_MQTT_BUILD_SHA256_CHECKSUM: 232eeac63e72883d460c686a09b98cdd811d24579affac47c5c3f696f956773f
-- ARROW_AWS_C_S3_BUILD_VERSION: v0.2.3
-- ARROW_AWS_C_S3_BUILD_SHA256_CHECKSUM: a00b3c9f319cd1c9aa2c3fa15098864df94b066dcba0deaccbb3caa952d902fe
-- ARROW_AWS_C_SDKUTILS_BUILD_VERSION: v0.1.6
-- ARROW_AWS_C_SDKUTILS_BUILD_SHA256_CHECKSUM: 8a2951344b2fb541eab1e9ca17c18a7fcbfd2aaff4cdd31d362d1fad96111b91
-- ARROW_AWS_CHECKSUMS_BUILD_VERSION: v0.1.13
-- ARROW_AWS_CHECKSUMS_BUILD_SHA256_CHECKSUM: 0f897686f1963253c5069a0e495b85c31635ba146cd3ac38cc2ea31eaf54694d
-- ARROW_AWS_CRT_CPP_BUILD_VERSION: v0.18.16
-- ARROW_AWS_CRT_CPP_BUILD_SHA256_CHECKSUM: 9e69bc1dc4b50871d1038aa9ff6ddeb4c9b28f7d6b5e5b1b69041ccf50a13483
-- ARROW_AWS_LC_BUILD_VERSION: v1.3.0
-- ARROW_AWS_LC_BUILD_SHA256_CHECKSUM: ae96a3567161552744fc0cae8b4d68ed88b1ec0f3d3c98700070115356da5a37
-- ARROW_AWSSDK_BUILD_VERSION: 1.10.55
-- ARROW_AWSSDK_BUILD_SHA256_CHECKSUM: 2d552fb1a84bef4a9b65e34aa7031851ed2aef5319e02cc6e4cb735c48aa30de
-- ARROW_BOOST_BUILD_VERSION: 1.81.0
-- ARROW_BOOST_BUILD_SHA256_CHECKSUM: 9e0ffae35528c35f90468997bc8d99500bf179cbae355415a89a600c38e13574
-- ARROW_BROTLI_BUILD_VERSION: v1.0.9
-- ARROW_BROTLI_BUILD_SHA256_CHECKSUM: f9e8d81d0405ba66d181529af42a3354f838c939095ff99930da6aa9cdf6fe46
-- ARROW_BZIP2_BUILD_VERSION: 1.0.8
-- ARROW_BZIP2_BUILD_SHA256_CHECKSUM: ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269
-- ARROW_CARES_BUILD_VERSION: 1.17.2
-- ARROW_CARES_BUILD_SHA256_CHECKSUM: 4803c844ce20ce510ef0eb83f8ea41fa24ecaae9d280c468c582d2bb25b3913d
-- ARROW_CRC32C_BUILD_VERSION: 1.1.2
-- ARROW_CRC32C_BUILD_SHA256_CHECKSUM: ac07840513072b7fcebda6e821068aa04889018f24e10e46181068fb214d7e56
-- ARROW_GBENCHMARK_BUILD_VERSION: v1.7.1
-- ARROW_GBENCHMARK_BUILD_SHA256_CHECKSUM: 6430e4092653380d9dc4ccb45a1e2dc9259d581f4866dc0759713126056bc1d7
-- ARROW_GFLAGS_BUILD_VERSION: v2.2.2
-- ARROW_GFLAGS_BUILD_SHA256_CHECKSUM: 34af2f15cf7367513b352bdcd2493ab14ce43692d2dcd9dfc499492966c64dcf
-- ARROW_GLOG_BUILD_VERSION: v0.5.0
-- ARROW_GLOG_BUILD_SHA256_CHECKSUM: eede71f28371bf39aa69b45de23b329d37214016e2055269b3b5e7cfd40b59f5
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_VERSION: v2.8.0
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_SHA256_CHECKSUM: 21fb441b5a670a18bb16b6826be8e0530888d0b94320847c538d46f5a54dddbc
-- ARROW_GRPC_BUILD_VERSION: v1.46.3
-- ARROW_GRPC_BUILD_SHA256_CHECKSUM: d6cbf22cb5007af71b61c6be316a79397469c58c82a942552a62e708bce60964
-- ARROW_GTEST_BUILD_VERSION: 1.11.0
-- ARROW_GTEST_BUILD_SHA256_CHECKSUM: b4870bf121ff7795ba20d20bcdd8627b8e088f2d1dab299a031c1034eddc93d5
-- ARROW_JEMALLOC_BUILD_VERSION: 5.3.0
-- ARROW_JEMALLOC_BUILD_SHA256_CHECKSUM: 2db82d1e7119df3e71b7640219b6dfe84789bc0537983c3b7ac4f7189aecfeaa
-- ARROW_LZ4_BUILD_VERSION: v1.9.4
-- ARROW_LZ4_BUILD_SHA256_CHECKSUM: 0b0e3aa07c8c063ddf40b082bdf7e37a1562bda40a0ff5272957f3e987e0e54b
-- ARROW_MIMALLOC_BUILD_VERSION: v2.0.6
-- ARROW_MIMALLOC_BUILD_SHA256_CHECKSUM: 9f05c94cc2b017ed13698834ac2a3567b6339a8bde27640df5a1581d49d05ce5
-- ARROW_NLOHMANN_JSON_BUILD_VERSION: v3.10.5
-- ARROW_NLOHMANN_JSON_BUILD_SHA256_CHECKSUM: 5daca6ca216495edf89d167f808d1d03c4a4d929cef7da5e10f135ae1540c7e4
-- ARROW_OPENTELEMETRY_BUILD_VERSION: v1.8.1
-- ARROW_OPENTELEMETRY_BUILD_SHA256_CHECKSUM: 3d640201594b07f08dade9cd1017bd0b59674daca26223b560b9bb6bf56264c2
-- ARROW_OPENTELEMETRY_PROTO_BUILD_VERSION: v0.17.0
-- ARROW_OPENTELEMETRY_PROTO_BUILD_SHA256_CHECKSUM: f269fbcb30e17b03caa1decd231ce826e59d7651c0f71c3b28eb5140b4bb5412
-- ARROW_ORC_BUILD_VERSION: 1.8.3
-- ARROW_ORC_BUILD_SHA256_CHECKSUM: a78678ec425c8129d63370cb8a9bacb54186aa66af1e2bec01ce92e7eaf72e20
-- ARROW_PROTOBUF_BUILD_VERSION: v21.3
-- ARROW_PROTOBUF_BUILD_SHA256_CHECKSUM: 2f723218f6cb709ae4cdc4fb5ed56a5951fc5d466f0128ce4c946b8c78c8c49f
-- ARROW_RAPIDJSON_BUILD_VERSION: 232389d4f1012dddec4ef84861face2d2ba85709
-- ARROW_RAPIDJSON_BUILD_SHA256_CHECKSUM: b9290a9a6d444c8e049bd589ab804e0ccf2b05dc5984a19ed5ae75d090064806
-- ARROW_RE2_BUILD_VERSION: 2022-06-01
-- ARROW_RE2_BUILD_SHA256_CHECKSUM: f89c61410a072e5cbcf8c27e3a778da7d6fd2f2b5b1445cd4f4508bee946ab0f
-- ARROW_SNAPPY_BUILD_VERSION: 1.1.9
-- ARROW_SNAPPY_BUILD_SHA256_CHECKSUM: 75c1fbb3d618dd3a0483bff0e26d0a92b495bbe5059c8b4f1c962b478b6e06e7
-- ARROW_SUBSTRAIT_BUILD_VERSION: v0.20.0
-- ARROW_SUBSTRAIT_BUILD_SHA256_CHECKSUM: 5ceaa559ccef29a7825b5e5d4b5e7eed384830294f08bec913feecdd903a94cf
-- ARROW_S2N_TLS_BUILD_VERSION: v1.3.35
-- ARROW_S2N_TLS_BUILD_SHA256_CHECKSUM: 9d32b26e6bfcc058d98248bf8fc231537e347395dd89cf62bb432b55c5da990d
-- ARROW_THRIFT_BUILD_VERSION: 0.16.0
-- ARROW_THRIFT_BUILD_SHA256_CHECKSUM: f460b5c1ca30d8918ff95ea3eb6291b3951cf518553566088f3f2be8981f6209
-- ARROW_UCX_BUILD_VERSION: 1.12.1
-- ARROW_UCX_BUILD_SHA256_CHECKSUM: 9bef31aed0e28bf1973d28d74d9ac4f8926c43ca3b7010bd22a084e164e31b71
-- ARROW_UTF8PROC_BUILD_VERSION: v2.7.0
-- ARROW_UTF8PROC_BUILD_SHA256_CHECKSUM: 4bb121e297293c0fd55f08f83afab6d35d48f0af4ecc07523ad8ec99aa2b12a1
-- ARROW_XSIMD_BUILD_VERSION: 9.0.1
-- ARROW_XSIMD_BUILD_SHA256_CHECKSUM: b1bb5f92167fd3a4f25749db0be7e61ed37e0a5d943490f3accdcd2cd2918cc0
-- ARROW_ZLIB_BUILD_VERSION: 1.2.13
-- ARROW_ZLIB_BUILD_SHA256_CHECKSUM: b3a24de97a8fdbc835b9833169501030b8977031bcb54b3b3ac13740f846ab30
-- ARROW_ZSTD_BUILD_VERSION: 1.5.5
-- ARROW_ZSTD_BUILD_SHA256_CHECKSUM: 9c4396cc829cfae319a6e2615202e82aad41372073482fce286fac78646d3ee4
-- Building without OpenSSL support. Minimum OpenSSL version 1.0.2 required.
-- Building jemalloc from source
-- xsimd found. Headers: /home/tdhock/miniconda3/envs/arrow/include
-- Found hdfs.h at: /home/tdhock/arrow/cpp/thirdparty/hadoop/include/hdfs.h
-- All bundled static libraries: jemalloc::jemalloc
-- CMAKE_C_FLAGS:   -Wall -Wno-conversion -Wno-sign-conversion -Wunused-result -fno-semantic-interposition -msse4.2 
-- CMAKE_CXX_FLAGS:  -Wno-noexcept-type  -fdiagnostics-color=always  -Wall -Wno-conversion -Wno-sign-conversion -Wunused-result -fno-semantic-interposition -msse4.2 
-- CMAKE_C_FLAGS_DEBUG: -g -Werror -O0 -ggdb
-- CMAKE_CXX_FLAGS_DEBUG: -g -Werror -O0 -ggdb
-- Looking for backtrace
-- Looking for backtrace - found
-- backtrace facility detected in default set of libraries
-- Found Backtrace: /usr/include  
-- ---------------------------------------------------------------------
-- Arrow version:                                 13.0.0-SNAPSHOT
-- 
-- Build configuration summary:
--   Generator: Ninja
--   Build type: DEBUG
--   Source directory: /home/tdhock/arrow/cpp
--   Install prefix: /usr/local
-- 
-- Compile and link options:
-- 
--   ARROW_CXXFLAGS="" [default=""]
--       Compiler flags to append when compiling Arrow
--   ARROW_BUILD_STATIC=OFF [default=ON]
--       Build static libraries
--   ARROW_BUILD_SHARED=ON [default=ON]
--       Build shared libraries
--   ARROW_PACKAGE_KIND="" [default=""]
--       Arbitrary string that identifies the kind of package
--       (for informational purposes)
--   ARROW_GIT_ID=3948c426927514ab6d3165255b4717af9446e949 [default=""]
--       The Arrow git commit id (if any)
--   ARROW_GIT_DESCRIPTION=apache-arrow-13.0.0.dev-40-g3948c4269 [default=""]
--       The Arrow git commit description (if any)
--   ARROW_NO_DEPRECATED_API=OFF [default=OFF]
--       Exclude deprecated APIs from build
--   ARROW_POSITION_INDEPENDENT_CODE=ON [default=ON]
--       Whether to create position-independent target
--   ARROW_USE_CCACHE=ON [default=ON]
--       Use ccache when compiling (if available)
--   ARROW_USE_SCCACHE=ON [default=ON]
--       Use sccache when compiling (if available),
--       takes precedence over ccache if a storage backend is configured
--   ARROW_USE_LD_GOLD=OFF [default=OFF]
--       Use ld.gold for linking on Linux (if available)
--   ARROW_USE_PRECOMPILED_HEADERS=OFF [default=OFF]
--       Use precompiled headers when compiling
--   ARROW_SIMD_LEVEL=SSE4_2 [default=NONE|SSE4_2|AVX2|AVX512|NEON|SVE|SVE128|SVE256|SVE512|DEFAULT]
--       Compile-time SIMD optimization level
--   ARROW_RUNTIME_SIMD_LEVEL=MAX [default=NONE|SSE4_2|AVX2|AVX512|MAX]
--       Max runtime SIMD optimization level
--   ARROW_ALTIVEC=ON [default=ON]
--       Build with Altivec if compiler has support
--   ARROW_RPATH_ORIGIN=OFF [default=OFF]
--       Build Arrow libraries with RATH set to $ORIGIN
--   ARROW_INSTALL_NAME_RPATH=ON [default=ON]
--       Build Arrow libraries with install_name set to @rpath
--   ARROW_GGDB_DEBUG=ON [default=ON]
--       Pass -ggdb flag to debug builds
--   ARROW_WITH_MUSL=OFF [default=OFF]
--       Whether the system libc is musl or not
-- 
-- Test and benchmark options:
-- 
--   ARROW_BUILD_EXAMPLES=OFF [default=OFF]
--       Build the Arrow examples
--   ARROW_BUILD_TESTS=OFF [default=OFF]
--       Build the Arrow googletest unit tests
--   ARROW_ENABLE_TIMING_TESTS=ON [default=ON]
--       Enable timing-sensitive tests
--   ARROW_BUILD_INTEGRATION=OFF [default=OFF]
--       Build the Arrow integration test executables
--   ARROW_BUILD_BENCHMARKS=OFF [default=OFF]
--       Build the Arrow micro benchmarks
--   ARROW_BUILD_BENCHMARKS_REFERENCE=OFF [default=OFF]
--       Build the Arrow micro reference benchmarks
--   ARROW_BUILD_OPENMP_BENCHMARKS=OFF [default=OFF]
--       Build the Arrow benchmarks that rely on OpenMP
--   ARROW_BUILD_DETAILED_BENCHMARKS=OFF [default=OFF]
--       Build benchmarks that do a longer exploration of performance
--   ARROW_TEST_LINKAGE=shared [default=shared|static]
--       Linkage of Arrow libraries with unit tests executables.
--   ARROW_FUZZING=OFF [default=OFF]
--       Build Arrow Fuzzing executables
--   ARROW_LARGE_MEMORY_TESTS=OFF [default=OFF]
--       Enable unit tests which use large memory
-- 
-- Lint options:
-- 
--   ARROW_ONLY_LINT=OFF [default=OFF]
--       Only define the lint and check-format targets
--   ARROW_VERBOSE_LINT=OFF [default=OFF]
--       If off, 'quiet' flags will be passed to linting tools
--   ARROW_GENERATE_COVERAGE=OFF [default=OFF]
--       Build with C++ code coverage enabled
-- 
-- Checks options:
-- 
--   ARROW_TEST_MEMCHECK=OFF [default=OFF]
--       Run the test suite using valgrind --tool=memcheck
--   ARROW_USE_ASAN=OFF [default=OFF]
--       Enable Address Sanitizer checks
--   ARROW_USE_TSAN=OFF [default=OFF]
--       Enable Thread Sanitizer checks
--   ARROW_USE_UBSAN=OFF [default=OFF]
--       Enable Undefined Behavior sanitizer checks
-- 
-- Project component options:
-- 
--   ARROW_BUILD_UTILITIES=OFF [default=OFF]
--       Build Arrow commandline utilities
--   ARROW_COMPUTE=OFF [default=OFF]
--       Build all Arrow Compute kernels
--   ARROW_CSV=OFF [default=OFF]
--       Build the Arrow CSV Parser Module
--   ARROW_CUDA=OFF [default=OFF]
--       Build the Arrow CUDA extensions (requires CUDA toolkit)
--   ARROW_DATASET=OFF [default=OFF]
--       Build the Arrow Dataset Modules
--   ARROW_FILESYSTEM=OFF [default=OFF]
--       Build the Arrow Filesystem Layer
--   ARROW_FLIGHT=OFF [default=OFF]
--       Build the Arrow Flight RPC System (requires GRPC, Protocol Buffers)
--   ARROW_FLIGHT_SQL=OFF [default=OFF]
--       Build the Arrow Flight SQL extension
--   ARROW_GANDIVA=OFF [default=OFF]
--       Build the Gandiva libraries
--   ARROW_GCS=OFF [default=OFF]
--       Build Arrow with GCS support (requires the GCloud SDK for C++)
--   ARROW_HDFS=OFF [default=OFF]
--       Build the Arrow HDFS bridge
--   ARROW_IPC=ON [default=ON]
--       Build the Arrow IPC extensions
--   ARROW_JEMALLOC=ON [default=ON]
--       Build the Arrow jemalloc-based allocator
--   ARROW_JSON=OFF [default=OFF]
--       Build Arrow with JSON support (requires RapidJSON)
--   ARROW_MIMALLOC=OFF [default=OFF]
--       Build the Arrow mimalloc-based allocator
--   ARROW_PARQUET=OFF [default=OFF]
--       Build the Parquet libraries
--   ARROW_ORC=OFF [default=OFF]
--       Build the Arrow ORC adapter
--   ARROW_PYTHON=OFF [default=OFF]
--       Build some components needed by PyArrow.
--       (This is a deprecated option. Use CMake presets instead.)
--   ARROW_S3=OFF [default=OFF]
--       Build Arrow with S3 support (requires the AWS SDK for C++)
--   ARROW_SKYHOOK=OFF [default=OFF]
--       Build the Skyhook libraries
--   ARROW_SUBSTRAIT=OFF [default=OFF]
--       Build the Arrow Substrait Consumer Module
--   ARROW_ACERO=OFF [default=OFF]
--       Build the Arrow Acero Engine Module
--   ARROW_TENSORFLOW=OFF [default=OFF]
--       Build Arrow with TensorFlow support enabled
--   ARROW_TESTING=OFF [default=OFF]
--       Build the Arrow testing libraries
-- 
-- Thirdparty toolchain options:
-- 
--   ARROW_DEPENDENCY_SOURCE=CONDA [default=AUTO|BUNDLED|SYSTEM|CONDA|VCPKG|BREW]
--       Method to use for acquiring arrow's build dependencies
--   ARROW_VERBOSE_THIRDPARTY_BUILD=OFF [default=OFF]
--       Show output from ExternalProjects rather than just logging to files
--   ARROW_DEPENDENCY_USE_SHARED=ON [default=ON]
--       Link to shared libraries
--   ARROW_BOOST_USE_SHARED=ON [default=ON]
--       Rely on Boost shared libraries where relevant
--   ARROW_BROTLI_USE_SHARED=ON [default=ON]
--       Rely on Brotli shared libraries where relevant
--   ARROW_BZ2_USE_SHARED=ON [default=ON]
--       Rely on Bz2 shared libraries where relevant
--   ARROW_GFLAGS_USE_SHARED=ON [default=ON]
--       Rely on GFlags shared libraries where relevant
--   ARROW_GRPC_USE_SHARED=ON [default=ON]
--       Rely on gRPC shared libraries where relevant
--   ARROW_JEMALLOC_USE_SHARED=OFF [default=ON]
--       Rely on jemalloc shared libraries where relevant
--   ARROW_LZ4_USE_SHARED=ON [default=ON]
--       Rely on lz4 shared libraries where relevant
--   ARROW_OPENSSL_USE_SHARED=ON [default=ON]
--       Rely on OpenSSL shared libraries where relevant
--   ARROW_PROTOBUF_USE_SHARED=ON [default=ON]
--       Rely on Protocol Buffers shared libraries where relevant
--   ARROW_SNAPPY_USE_SHARED=ON [default=ON]
--       Rely on snappy shared libraries where relevant
--   ARROW_THRIFT_USE_SHARED=ON [default=ON]
--       Rely on thrift shared libraries where relevant
--   ARROW_UTF8PROC_USE_SHARED=ON [default=ON]
--       Rely on utf8proc shared libraries where relevant
--   ARROW_ZSTD_USE_SHARED=ON [default=ON]
--       Rely on zstd shared libraries where relevant
--   ARROW_USE_GLOG=OFF [default=OFF]
--       Build libraries with glog support for pluggable logging
--   ARROW_WITH_BACKTRACE=ON [default=ON]
--       Build with backtrace support
--   ARROW_WITH_OPENTELEMETRY=OFF [default=OFF]
--       Build libraries with OpenTelemetry support for distributed tracing
--   ARROW_WITH_BROTLI=OFF [default=OFF]
--       Build with Brotli compression
--   ARROW_WITH_BZ2=OFF [default=OFF]
--       Build with BZ2 compression
--   ARROW_WITH_LZ4=OFF [default=OFF]
--       Build with lz4 compression
--   ARROW_WITH_SNAPPY=OFF [default=OFF]
--       Build with Snappy compression
--   ARROW_WITH_ZLIB=OFF [default=OFF]
--       Build with zlib compression
--   ARROW_WITH_ZSTD=OFF [default=OFF]
--       Build with zstd compression
--   ARROW_WITH_UCX=OFF [default=OFF]
--       Build with UCX transport for Arrow Flight
--       (only used if ARROW_FLIGHT is ON)
--   ARROW_WITH_UTF8PROC=OFF [default=ON]
--       Build with support for Unicode properties using the utf8proc library
--       (only used if ARROW_COMPUTE is ON or ARROW_GANDIVA is ON)
--   ARROW_WITH_RE2=OFF [default=ON]
--       Build with support for regular expressions using the re2 library
--       (only used if ARROW_COMPUTE or ARROW_GANDIVA is ON)
-- 
-- Parquet options:
-- 
--   PARQUET_MINIMAL_DEPENDENCY=OFF [default=OFF]
--       Depend only on Thirdparty headers to build libparquet.
--       Always OFF if building binaries
--   PARQUET_BUILD_EXECUTABLES=OFF [default=OFF]
--       Build the Parquet executable CLI tools. Requires static libraries to be built.
--   PARQUET_BUILD_EXAMPLES=OFF [default=OFF]
--       Build the Parquet examples. Requires static libraries to be built.
--   PARQUET_REQUIRE_ENCRYPTION=OFF [default=OFF]
--       Build support for encryption. Fail if OpenSSL is not found
-- 
-- Gandiva options:
-- 
--   ARROW_GANDIVA_STATIC_LIBSTDCPP=OFF [default=OFF]
--       Include -static-libstdc++ -static-libgcc when linking with
--       Gandiva static libraries
--   ARROW_GANDIVA_PC_CXX_FLAGS="" [default=""]
--       Compiler flags to append when pre-compiling Gandiva operations
-- 
-- Advanced developer options:
-- 
--   ARROW_EXTRA_ERROR_CONTEXT=ON [default=OFF]
--       Compile with extra error context (line numbers, code)
--   ARROW_OPTIONAL_INSTALL=OFF [default=OFF]
--       If enabled install ONLY targets that have already been built. Please be
--       advised that if this is enabled 'install' will fail silently on components
--       that have not been built
--   ARROW_GDB_INSTALL_DIR="" [default=""]
--       Use a custom install directory for GDB plugin.
--       In general, you don't need to specify this because the default
--       (CMAKE_INSTALL_FULL_BINDIR on Windows, CMAKE_INSTALL_FULL_LIBDIR otherwise)
--       is reasonable.
--   Outputting build configuration summary to /home/tdhock/arrow/cpp/build/cmake_summary.json
-- Configuring done
-- Generating done
-- Build files have been written to: /home/tdhock/arrow/cpp/build
(arrow) tdhock@tdhock-MacBook:~/arrow/cpp/build(main)$ cmake --build .
[1/183] Creating directories for 'jemalloc_ep'
[2/183] Performing download step (download, verify and extract) for 'jemalloc_ep'
[3/183] No update step for 'jemalloc_ep'
[4/183] Performing patch step for 'jemalloc_ep'
[5/183] Performing configure step for 'jemalloc_ep'
[6/183] Performing build step for 'jemalloc_ep'
[7/183] Performing install step for 'jemalloc_ep'
[8/183] Completed 'jemalloc_ep'
[9/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/array_decimal.cc.o
[10/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/array_binary.cc.o
[11/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/array_nested.cc.o
[12/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/array_primitive.cc.o
[13/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/array_base.cc.o
[14/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/array_dict.cc.o
[15/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/builder_adaptive.cc.o
[16/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/array_run_end.cc.o
[17/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/builder_decimal.cc.o
[18/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/builder_binary.cc.o
[19/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/builder_base.cc.o
[20/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/builder_run_end.cc.o
[21/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/builder_nested.cc.o
[22/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/builder_primitive.cc.o
[23/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/builder_dict.cc.o
[24/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/builder_union.cc.o
[25/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/data.cc.o
[26/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/concatenate.cc.o
[27/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/validate.cc.o
[28/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/diff.cc.o
[29/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/util.cc.o
[30/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/buffer.cc.o
[31/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/chunked_array.cc.o
[32/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/chunk_resolver.cc.o
[33/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/config.cc.o
[34/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compare.cc.o
[35/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/device.cc.o
[36/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/datum.cc.o
[37/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/extension_type.cc.o
[38/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/memory_pool.cc.o
[39/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/record_batch.cc.o
[40/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/pretty_print.cc.o
[41/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/result.cc.o
[42/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/builder.cc.o
[43/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/status.cc.o
[44/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/sparse_tensor.cc.o
[45/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/table_builder.cc.o
[46/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/table.cc.o
[47/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/tensor.cc.o
[48/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/tensor/coo_converter.cc.o
[49/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/tensor/csf_converter.cc.o
[50/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/tensor/csx_converter.cc.o
[51/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/visitor.cc.o
[52/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/scalar.cc.o
[53/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/buffered.cc.o
[54/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/c/bridge.cc.o
[55/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/caching.cc.o
[56/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/type.cc.o
[57/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/compressed.cc.o
[58/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/hdfs_internal.cc.o
[59/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/file.cc.o
[60/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/hdfs.cc.o
[61/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/memory.cc.o
[62/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/slow.cc.o
[63/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/interfaces.cc.o
[64/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/stdio.cc.o
[65/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/transform.cc.o
[66/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/align_util.cc.o
[67/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/atfork_internal.cc.o
[68/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/basic_decimal.cc.o
[69/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/bit_block_counter.cc.o
[70/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/async_util.cc.o
[71/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/bit_run_reader.cc.o
[72/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/bit_util.cc.o
[73/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/bitmap_builders.cc.o
[74/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/bitmap.cc.o
[75/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/bitmap_ops.cc.o
[76/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/bpacking.cc.o
[77/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/cancel.cc.o
[78/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/compression.cc.o
[79/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/counting_semaphore.cc.o
[80/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/byte_size.cc.o
[81/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/debug.cc.o
[82/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/crc32.cc.o
[83/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/cpu_info.cc.o
[84/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/delimiting.cc.o
[85/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/formatting.cc.o
[86/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/decimal.cc.o
[87/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/future.cc.o
[88/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/logging.cc.o
[89/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/int_util.cc.o
[90/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/io_util.cc.o
[91/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/key_value_metadata.cc.o
[92/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/mutex.cc.o
[93/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/memory.cc.o
[94/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/string.cc.o
[95/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/string_builder.cc.o
[96/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/ree_util.cc.o
[97/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/task_group.cc.o
[98/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/tdigest.cc.o
[99/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/time.cc.o
[100/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/tracing.cc.o
[101/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/trie.cc.o
[102/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/thread_pool.cc.o
[103/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/unreachable.cc.o
[104/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/union_util.cc.o
[105/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/utf8.cc.o
[106/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/uri.cc.o
[107/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/base64.cpp.o
[108/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/double-conversion/bignum.cc.o
[109/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/value_parsing.cc.o
[110/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/double-conversion/double-conversion.cc.o
[111/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/double-conversion/bignum-dtoa.cc.o
[112/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/double-conversion/fast-dtoa.cc.o
[113/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/double-conversion/cached-powers.cc.o
[114/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/double-conversion/diy-fp.cc.o
[115/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/double-conversion/fixed-dtoa.cc.o
[116/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/double-conversion/strtod.cc.o
[117/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/memory_pool_jemalloc.cc.o
[118/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/datetime/tz.cpp.o
[119/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/bpacking_avx2.cc.o
[120/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/bpacking_avx512.cc.o
[121/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/api_aggregate.cc.o
[122/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/api_vector.cc.o
[123/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/cast.cc.o
[124/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/api_scalar.cc.o
[125/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/exec.cc.o
[126/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/function.cc.o
[127/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/expression.cc.o
[128/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/function_internal.cc.o
[129/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernel.cc.o
[130/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/key_map.cc.o
[131/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/key_hash.cc.o
[132/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/ordering.cc.o
[133/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/light_array.cc.o
[134/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/codegen_internal.cc.o
[135/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/registry.cc.o
[136/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/ree_util_internal.cc.o
[137/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/row_encoder.cc.o
[138/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/scalar_cast_boolean.cc.o
[139/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/scalar_cast_dictionary.cc.o
[140/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/scalar_cast_extension.cc.o
[141/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/scalar_cast_internal.cc.o
[142/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/scalar_cast_nested.cc.o
[143/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/scalar_cast_numeric.cc.o
[144/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/scalar_cast_temporal.cc.o
[145/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/util_internal.cc.o
[146/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/scalar_cast_string.cc.o
[147/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/row/encode_internal.cc.o
[148/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/row/compare_internal.cc.o
[149/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/vector_selection.cc.o
[150/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/vector_hash.cc.o
[151/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/util.cc.o
[152/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/row/row_internal.cc.o
[153/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/row/grouper.cc.o
[154/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/key_map_avx2.cc.o
[155/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/key_hash_avx2.cc.o
[156/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/row/compare_internal_avx2.cc.o
[157/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/row/encode_internal_avx2.cc.o
[158/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/util_avx2.cc.o
[159/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/ipc/dictionary.cc.o
[160/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/ipc/feather.cc.o
[161/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/ipc/message.cc.o
[162/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/ipc/options.cc.o
[163/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/ipc/metadata_internal.cc.o
[164/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/musl/strptime.c.o
[165/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriCommon.c.o
[166/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriCompare.c.o
[167/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriEscape.c.o
[168/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriFile.c.o
[169/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriIp4Base.c.o
[170/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriIp4.c.o
[171/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriMemory.c.o
[172/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriNormalizeBase.c.o
[173/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriNormalize.c.o
[174/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriParseBase.c.o
[175/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriParse.c.o
[176/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriQuery.c.o
[177/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriRecompose.c.o
[178/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriResolve.c.o
[179/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriShorten.c.o
[180/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/ipc/writer.cc.o
[181/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/ipc/reader.cc.o
[182/183] Linking CXX shared library debug/libarrow.so.1300.0.0
[183/183] Creating library symlink debug/libarrow.so.1300 debug/libarrow.so
(arrow) tdhock@tdhock-MacBook:~/arrow/cpp/build(main)$ ls debug
libarrow.so  libarrow.so.1300  libarrow.so.1300.0.0
(arrow) tdhock@tdhock-MacBook:~/arrow/cpp/build(main)$ 
```

Cookbook page about how to read/write data sets in C++
https://arrow.apache.org/cookbook/cpp/datasets.html

Maybe there is a simpler way to test GCC? What is a simple C program
that will generate the popcnt instruction?

I tried the program below, [from
here](https://iq.opengenus.org/__builtin_popcount-in-c/),

```c
#include <stdio.h>

int main(){
    int num = 22; // 22 in binary = 00000000 00000000 00000000 00010110
    printf("Number of 1's is = %d\n", __builtin_popcount(num));
    return 0;
}
```

but I observed that the program above runs fine (no segfault), and does not
produce the popcnt instruction, see below.

```
(arrow) tdhock@tdhock-MacBook:~/arrow-bug$ gcc builtin_popcount.c -o builtin_popcount && ./builtin_popcount 
Number of 1's is = 3
(arrow) tdhock@tdhock-MacBook:~/arrow-bug$ gcc builtin_popcount.c -S && cat builtin_popcount.s 
	.file	"builtin_popcount.c"
	.text
	.globl	__popcountdi2
	.section	.rodata
.LC0:
	.string	"Number of 1's is = %d\n"
	.text
	.globl	main
	.type	main, @function
main:
.LFB0:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movl	$22, -4(%rbp)
	movl	-4(%rbp), %eax
	movl	%eax, %eax
	movq	%rax, %rdi
	call	__popcountdi2
	movl	%eax, %esi
	movl	$.LC0, %edi
	movl	$0, %eax
	call	printf
	movl	$0, %eax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE0:
	.size	main, .-main
	.ident	"GCC: (GNU) 13.1.0"
	.section	.note.GNU-stack,"",@progbits
```

Where was that popcnt instruction produced?

```
(gdb) bt
#0  0x00007fffeb5aeaa7 in arrow::compute::RowTableMetadata::FromColumnMetadataVector(std::vector<arrow::compute::KeyColumnMetadata, std::allocator<arrow::compute::KeyColumnMetadata> > const&, int, int) ()
    at /home/tdhock/lib/R/library/arrow/libs/arrow.so
#1  0x00007fffeb59e720 in arrow::compute::RowTableEncoder::Init(std::vector<arrow::compute::KeyColumnMetadata, std::allocator<arrow::compute::KeyColumnMetadata> > const&, int, int) () at /home/tdhock/lib/R/library/arrow/libs/arrow.so
#2  0x00007fffeb5a6441 in arrow::compute::Grouper::Make(std::vector<arrow::TypeHolder, std::allocator<arrow::TypeHolder> > const&, arrow::compute::ExecContext*) () at /home/tdhock/lib/R/library/arrow/libs/arrow.so
#3  0x00007fffeae9dc42 in arrow::dataset::KeyValuePartitioning::Partition(std::shared_ptr<arrow::RecordBatch> const&) const ()
    at /home/tdhock/lib/R/library/arrow/libs/arrow.so
#4  0x00007fffeae7b4fb in arrow::dataset::(anonymous namespace)::WriteBatch(std::shared_ptr<arrow::RecordBatch>, arrow::compute::Expression, arrow::dataset::FileSystemDatasetWriteOptions, std::function<arrow::Status (std::shared_ptr<arrow::RecordBatch>, arrow::dataset::PartitionPathFormat const&)>) ()
    at /home/tdhock/lib/R/library/arrow/libs/arrow.so
#5  0x00007fffeae7c138 in arrow::dataset::(anonymous namespace)::DatasetWritingSinkNodeConsumer::Consume(arrow::compute::ExecBatch) ()
    at /home/tdhock/lib/R/library/arrow/libs/arrow.so
#6  0x00007fffeadea60f in non-virtual thunk to arrow::acero::(anonymous namespace)::ConsumingSinkNode::Process(arrow::compute::ExecBatch) ()
    at /home/tdhock/lib/R/library/arrow/libs/arrow.so
#7  0x00007fffeae17e8c in arrow::acero::util::(anonymous namespace)::SerialSequencingQueueImpl::DoProcess(std::unique_lock<std::mutex>&&) [clone .constprop.0] () at /home/tdhock/lib/R/library/arrow/libs/arrow.so
#8  0x00007fffeae1918c in arrow::acero::util::(anonymous namespace)::SerialSequencingQueueImpl::InsertBatch(arrow::compute::ExecBatch) ()
    at /home/tdhock/lib/R/library/arrow/libs/arrow.so
#9  0x00007fffeadec27e in arrow::acero::(anonymous namespace)::ConsumingSinkNode::InputReceived(arrow::acero::ExecNode*, arrow::compute::ExecBatch) ()
    at /home/tdhock/lib/R/library/arrow/libs/arrow.so
#10 0x00007fffeadf356a in arrow::acero::(anonymous namespace)::SourceNode::SliceAndDeliverMorsel(arrow::compute::ExecBatch const&)::{lambda()#1}::operator()() const () at /home/tdhock/lib/R/library/arrow/libs/arrow.so
#11 0x00007fffeadf37a5 in std::_Function_handler<arrow::Status (), arrow::acero::(anonymous namespace)::SourceNode::SliceAndDeliverMorsel(arrow::compute::ExecBatch const&)::{lambda()#1}>::_M_invoke(std::_Any_data const&) ()
    at /home/tdhock/lib/R/library/arrow/libs/arrow.so
#12 0x00007fffeade6dae in arrow::internal::FnOnce<void ()>::FnImpl<std::_Bind<arrow::detail::ContinueFuture (arrow::Future<arrow::internal::Empty>, std::function<arrow::Status ()>)> >::invoke() ()
    at /home/tdhock/lib/R/library/arrow/libs/arrow.so
#13 0x00007fffeb378bfd in std::thread::_State_impl<std::thread::_Invoker<std::tuple<arrow::internal::ThreadPool::LaunchWorkersUnlocked(int)::{lambda()#1}> > >::_M_run() () at /home/tdhock/lib/R/library/arrow/libs/arrow.so
#14 0x00007ffff4f7d2b3 in  () at /usr/lib/x86_64-linux-gnu/libstdc++.so.6
#15 0x00007ffff7976b43 in start_thread (arg=<optimized out>)
    at ./nptl/pthread_create.c:442
#16 0x00007ffff7a08a00 in clone3 ()
    at ../sysdeps/unix/sysv/linux/x86_64/clone3.S:81
```

github search in arrow repo says `FromColumnMetadataVector` is defined
in
[row_internal.cc](https://github.com/apache/arrow/blob/3948c426927514ab6d3165255b4717af9446e949/cpp/src/arrow/compute/row/row_internal.cc#L55). This
is included in the R package distribution:

```
(arrow) tdhock@tdhock-MacBook:~/arrow_12$ find . -name row_internal.cc
./tools/cpp/src/arrow/compute/row/row_internal.cc
```

It is not mentioned in the R compilation output, but it is in the C++
arrow output:

```
[152/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/row/row_internal.cc.o
~/arrow/cpp/build/src/arrow/CMakeFiles/arrow_objlib.dir/compute/row/row_internal.cc.o
```

There are static libraries in the R source package below?

```
~/R/R-4.3.0 $ ls ~/arrow_12/libarrow/arrow-12.0.0/lib
cmake       libarrow_acero.a                 libarrow_dataset.a  pkgconfig
libarrow.a  libarrow_bundled_dependencies.a  libparquet.a        
```

This seems to suggest that these static libraries are the cause of the
segfault, is there a way to compile them from source instead?

Usually installing arrow gives

```
(base) tdhock@tdhock-MacBook:/tmp/Rtmp8icqQo/downloaded_packages$ ARROW_R_DEV=true R CMD INSTALL arrow_12.0.0.100000037.tar.gz 
Le chargement a nécessité le package : grDevices
* installing to library ‘/home/tdhock/lib/R/library’
* installing *source* package ‘arrow’ ...
** using staged installation
Le chargement a nécessité le package : grDevices
*** Found libcurl and OpenSSL >= 3.0.0
essai de l'URL 'https://nightlies.apache.org/arrow/r/libarrow/bin/linux-openssl-3.0/arrow-12.0.0.100000037.zip'
Content type 'application/zip' length 39699427 bytes (37.9 MB)
==================================================
downloaded 37.9 MB

*** Successfully retrieved C++ binaries (linux-openssl-3.0)
PKG_CFLAGS=-DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS
PKG_LIBS=-L/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/lib -L/usr/lib/lib/x86_64-linux-gnu -larrow_acero -larrow_dataset -lparquet -larrow -larrow_bundled_dependencies -lcurl -lssl -lcrypto  
** libs
using C++ compiler: ‘g++ (GCC) 13.1.0’
using C++17
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c RTasks.cpp -o RTasks.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c altrep.cpp -o altrep.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c array.cpp -o array.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c array_to_vector.cpp -o array_to_vector.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c arraydata.cpp -o arraydata.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c arrowExports.cpp -o arrowExports.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c bridge.cpp -o bridge.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c buffer.cpp -o buffer.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c chunkedarray.cpp -o chunkedarray.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c compression.cpp -o compression.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c compute-exec.cpp -o compute-exec.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c compute.cpp -o compute.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c config.cpp -o config.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c csv.cpp -o csv.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c dataset.cpp -o dataset.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c datatype.cpp -o datatype.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c expression.cpp -o expression.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c extension-impl.cpp -o extension-impl.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c feather.cpp -o feather.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c field.cpp -o field.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c filesystem.cpp -o filesystem.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c io.cpp -o io.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c json.cpp -o json.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c memorypool.cpp -o memorypool.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c message.cpp -o message.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c parquet.cpp -o parquet.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c r_to_arrow.cpp -o r_to_arrow.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c recordbatch.cpp -o recordbatch.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c recordbatchreader.cpp -o recordbatchreader.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c recordbatchwriter.cpp -o recordbatchwriter.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c safe-call-into-r-impl.cpp -o safe-call-into-r-impl.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c scalar.cpp -o scalar.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c schema.cpp -o schema.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c symbols.cpp -o symbols.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c table.cpp -o table.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c threadpool.cpp -o threadpool.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -DARROW_STATIC -I/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/include -I/usr/lib/include/x86_64-linux-gnu -I/usr/lib/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -DARROW_R_WITH_S3 -DARROW_R_WITH_GCS -I'/home/tdhock/lib/R/library/cpp11/include' -march=core2    -fpic  -g -O2  -c type_infer.cpp -o type_infer.o
g++ -std=gnu++17 -shared -L/home/tdhock/lib/R/lib -L/usr/local/lib -o arrow.so RTasks.o altrep.o array.o array_to_vector.o arraydata.o arrowExports.o bridge.o buffer.o chunkedarray.o compression.o compute-exec.o compute.o config.o csv.o dataset.o datatype.o expression.o extension-impl.o feather.o field.o filesystem.o io.o json.o memorypool.o message.o parquet.o r_to_arrow.o recordbatch.o recordbatchreader.o recordbatchwriter.o safe-call-into-r-impl.o scalar.o schema.o symbols.o table.o threadpool.o type_infer.o -L/tmp/RtmpKjpWUw/R.INSTALL7256197605d7/arrow/libarrow/arrow-12.0.0.100000037/lib -L/usr/lib/lib/x86_64-linux-gnu -larrow_acero -larrow_dataset -lparquet -larrow -larrow_bundled_dependencies -lcurl -lssl -lcrypto -L/home/tdhock/lib/R/lib -lR
installing to /home/tdhock/lib/R/library/00LOCK-arrow/00new/arrow/libs
** R
** inst
** byte-compile and prepare package for lazy loading
Le chargement a nécessité le package : grDevices
** help
*** installing help indices
** building package indices
Le chargement a nécessité le package : grDevices
** testing if installed package can be loaded from temporary location
Le chargement a nécessité le package : grDevices
** checking absolute paths in shared objects and dynamic libraries
** testing if installed package can be loaded from final location
Le chargement a nécessité le package : grDevices
** testing if installed package keeps a record of temporary installation path
* DONE (arrow)
```

[R arrow installation page](https://arrow.apache.org/docs/r/articles/install.html#basic-configuration) says to try below to build libarrow from
source (in addition to R bindings).

```
> Sys.setenv("LIBARROW_BINARY"=FALSE)
> install.packages("~/arrow_12/",repos=NULL)
Le chargement a nécessité le package : grDevices
* installing *source* package ‘arrow’ ...
** package ‘arrow’ correctement décompressé et sommes MD5 vérifiées
** using staged installation
Le chargement a nécessité le package : grDevices
*** Found local C++ source: 'tools/cpp'
*** Building libarrow from source
    For build options and troubleshooting, see the install guide:
    https://arrow.apache.org/docs/r/articles/install.html
**** cmake: /usr/bin/cmake
**** arrow  
**** Error building Arrow C++. Re-run with ARROW_R_DEV=true for debug information. 
------------------------- NOTE ---------------------------
There was an issue preparing the Arrow C++ libraries.
See https://arrow.apache.org/docs/r/articles/install.html
---------------------------------------------------------
ERROR: configuration failed for package ‘arrow’
* removing ‘/home/tdhock/lib/R/library/arrow’
* restoring previous ‘/home/tdhock/lib/R/library/arrow’
Message d'avis :
Dans install.packages("~/arrow_12/", repos = NULL) :
  l'installation du package ‘/home/tdhock/arrow_12/’ a eu un statut de sortie non nul
[ 49%] Built target parse_test

-- stderr output is:
/usr/bin/ld: BFD (GNU Binutils for Ubuntu) 2.38 internal error, aborting at ../../bfd/merge.c:939 in _bfd_merged_section_offset

/usr/bin/ld: Merci de rapporter cette anomalie.

collect2: erreur: ld a retourné le statut de sortie 1
make[5]: *** [CMakeFiles/filtered_re2_test.dir/build.make:115 : filtered_re2_test] Erreur 1
make[5]: *** Suppression du fichier « filtered_re2_test »
make[4]: *** [CMakeFiles/Makefile2:234 : CMakeFiles/filtered_re2_test.dir/all] Erreur 2
make[4]: *** Attente des tâches non terminées....
make[3]: *** [Makefile:136 : all] Erreur 2

CMake Error at /tmp/Rtmp5tTRmH/filedab020a0561d/re2_ep-prefix/src/re2_ep-stamp/re2_ep-build-RELEASE.cmake:47 (message):
  Stopping after outputting logs.


make[2]: *** [CMakeFiles/re2_ep.dir/build.make:86 : re2_ep-prefix/src/re2_ep-stamp/re2_ep-build] Erreur 1
make[1]: *** [CMakeFiles/Makefile2:1099 : CMakeFiles/re2_ep.dir/all] Erreur 2
gmake: *** [Makefile:146 : all] Erreur 2
**** Error building Arrow C++.  
------------------------- NOTE ---------------------------
There was an issue preparing the Arrow C++ libraries.
See https://arrow.apache.org/docs/r/articles/install.html
---------------------------------------------------------
ERROR: configuration failed for package ‘arrow’
* removing ‘/home/tdhock/lib/R/library/arrow’
* restoring previous ‘/home/tdhock/lib/R/library/arrow’
Message d'avis :
Dans install.packages("~/arrow_12/", repos = NULL) :
  l'installation du package ‘/home/tdhock/arrow_12/’ a eu un statut de sortie non nul
> install.packages("~/arrow_12/",repos=NULL)
Le chargement a nécessité le package : grDevices
* installing *source* package ‘arrow’ ...
** package ‘arrow’ correctement décompressé et sommes MD5 vérifiées
** using staged installation
Le chargement a nécessité le package : grDevices
*** Found local C++ source: 'tools/cpp'
*** Building libarrow from source
    For build options and troubleshooting, see the install guide:
    https://arrow.apache.org/docs/r/articles/install.html
*** Building with MAKEFLAGS= -j2 
**** cmake: /usr/bin/cmake
**** arrow with SOURCE_DIR='tools/cpp' BUILD_DIR='/tmp/Rtmp5tTRmH/filedab020a0561d' DEST_DIR='libarrow/arrow-12.0.0' CMAKE='/usr/bin/cmake' EXTRA_CMAKE_FLAGS='' CC='gcc' CXX='g++ -std=gnu++17' LDFLAGS='-L/usr/local/lib' ARROW_S3='ON' ARROW_GCS='ON' 
++ pwd
+ > : /home/tdhock/arrow_12
+ > : tools/cpp
+ > : /tmp/Rtmp5tTRmH/filedab020a0561d
+ > : libarrow/arrow-12.0.0
+ > : /usr/bin/cmake
++ cd tools/cpp
++ pwd
+ > SOURCE_DIR=/home/tdhock/arrow_12/tools/cpp
++ mkdir -p libarrow/arrow-12.0.0
++ cd libarrow/arrow-12.0.0
++ pwd
+ > DEST_DIR=/home/tdhock/arrow_12/libarrow/arrow-12.0.0
++ nproc
+ > : 2
+ > '[' false '!=' '' ']'
++ echo false
++ tr '[:upper:]' '[:lower:]'
+ > LIBARROW_MINIMAL=false
+ > '[' false = false ']'
+ > ARROW_DEFAULT_PARAM=ON
+ > mkdir -p /tmp/Rtmp5tTRmH/filedab020a0561d
+ > pushd /tmp/Rtmp5tTRmH/filedab020a0561d
/tmp/Rtmp5tTRmH/filedab020a0561d ~/arrow_12
+ > /usr/bin/cmake -DARROW_BOOST_USE_SHARED=OFF -DARROW_BUILD_TESTS=OFF -DARROW_BUILD_SHARED=OFF -DARROW_BUILD_STATIC=ON -DARROW_ACERO=ON -DARROW_COMPUTE=ON -DARROW_CSV=ON -DARROW_DATASET=ON -DARROW_DEPENDENCY_SOURCE=AUTO -DAWSSDK_SOURCE= -DARROW_FILESYSTEM=ON -DARROW_GCS=ON -DARROW_JEMALLOC=ON -DARROW_MIMALLOC=ON -DARROW_JSON=ON -DARROW_PARQUET=ON -DARROW_S3=ON -DARROW_WITH_BROTLI=ON -DARROW_WITH_BZ2=ON -DARROW_WITH_LZ4=ON -DARROW_WITH_RE2=ON -DARROW_WITH_SNAPPY=ON -DARROW_WITH_UTF8PROC=ON -DARROW_WITH_ZLIB=ON -DARROW_WITH_ZSTD=ON -DARROW_VERBOSE_THIRDPARTY_BUILD=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_FIND_DEBUG_MODE=OFF -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_PREFIX=/home/tdhock/arrow_12/libarrow/arrow-12.0.0 -DCMAKE_EXPORT_NO_PACKAGE_REGISTRY=ON -DCMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY=ON -DCMAKE_UNITY_BUILD=OFF -Dxsimd_SOURCE= -Dzstd_SOURCE= -G 'Unix Makefiles' /home/tdhock/arrow_12/tools/cpp
-- Building using CMake version: 3.22.1
-- The C compiler identification is GNU 13.1.0
-- The CXX compiler identification is GNU 13.1.0
-- Detecting C compiler ABI info
-- Detecting C compiler ABI info - done
-- Check for working C compiler: /home/tdhock/bin/gcc - skipped
-- Detecting C compile features
-- Detecting C compile features - done
-- Detecting CXX compiler ABI info
-- Detecting CXX compiler ABI info - done
-- Check for working CXX compiler: /home/tdhock/bin/g++ - skipped
-- Detecting CXX compile features
-- Detecting CXX compile features - done
-- Arrow version: 12.0.0 (full: '12.0.0')
-- Arrow SO version: 1200 (full: 1200.0.0)
-- clang-tidy 14 not found
-- clang-format 14 not found
-- Could NOT find ClangTools (missing: CLANG_FORMAT_BIN CLANG_TIDY_BIN) 
-- infer not found
-- Found Python3: /usr/bin/python3.10 (found version "3.10.6") found components: Interpreter 
fatal: ni ceci ni aucun de ses répertoires parents n'est un dépôt git : .git
-- Found cpplint executable at /home/tdhock/arrow_12/tools/cpp/build-support/cpplint.py
-- System processor: x86_64
-- Performing Test CXX_SUPPORTS_SSE4_2
-- Performing Test CXX_SUPPORTS_SSE4_2 - Success
-- Performing Test CXX_SUPPORTS_AVX2
-- Performing Test CXX_SUPPORTS_AVX2 - Success
-- Performing Test CXX_SUPPORTS_AVX512
-- Performing Test CXX_SUPPORTS_AVX512 - Success
-- Arrow build warning level: PRODUCTION
-- Using ld linker
-- Build Type: RELEASE
-- Performing Test CXX_LINKER_SUPPORTS_VERSION_SCRIPT
-- Performing Test CXX_LINKER_SUPPORTS_VERSION_SCRIPT - Success
-- Using AUTO approach to find dependencies
-- ARROW_ABSL_BUILD_VERSION: 20211102.0
-- ARROW_ABSL_BUILD_SHA256_CHECKSUM: dcf71b9cba8dc0ca9940c4b316a0c796be8fab42b070bb6b7cab62b48f0e66c4
-- ARROW_AWS_C_AUTH_BUILD_VERSION: v0.6.22
-- ARROW_AWS_C_AUTH_BUILD_SHA256_CHECKSUM: 691a6b4418afcd3dc141351b6ad33fccd8e3ff84df0e9e045b42295d284ee14c
-- ARROW_AWS_C_CAL_BUILD_VERSION: v0.5.20
-- ARROW_AWS_C_CAL_BUILD_SHA256_CHECKSUM: acc352359bd06f8597415c366cf4ec4f00d0b0da92d637039a73323dd55b6cd0
-- ARROW_AWS_C_COMMON_BUILD_VERSION: v0.8.9
-- ARROW_AWS_C_COMMON_BUILD_SHA256_CHECKSUM: 2f3fbaf7c38eae5a00e2a816d09b81177f93529ae8ba1b82dc8f31407565327a
-- ARROW_AWS_C_COMPRESSION_BUILD_VERSION: v0.2.16
-- ARROW_AWS_C_COMPRESSION_BUILD_SHA256_CHECKSUM: 044b1dbbca431a07bde8255ef9ec443c300fc60d4c9408d4b862f65e496687f4
-- ARROW_AWS_C_EVENT_STREAM_BUILD_VERSION: v0.2.18
-- ARROW_AWS_C_EVENT_STREAM_BUILD_SHA256_CHECKSUM: 310ca617f713bf664e4c7485a3d42c1fb57813abd0107e49790d107def7cde4f
-- ARROW_AWS_C_HTTP_BUILD_VERSION: v0.7.3
-- ARROW_AWS_C_HTTP_BUILD_SHA256_CHECKSUM: 07e16c6bf5eba6f0dea96b6f55eae312a7c95b736f4d2e4a210000f45d8265ae
-- ARROW_AWS_C_IO_BUILD_VERSION: v0.13.14
-- ARROW_AWS_C_IO_BUILD_SHA256_CHECKSUM: 12b66510c3d9a4f7e9b714e9cfab2a5bf835f8b9ce2f909d20ae2a2128608c71
-- ARROW_AWS_C_MQTT_BUILD_VERSION: v0.8.4
-- ARROW_AWS_C_MQTT_BUILD_SHA256_CHECKSUM: 232eeac63e72883d460c686a09b98cdd811d24579affac47c5c3f696f956773f
-- ARROW_AWS_C_S3_BUILD_VERSION: v0.2.3
-- ARROW_AWS_C_S3_BUILD_SHA256_CHECKSUM: a00b3c9f319cd1c9aa2c3fa15098864df94b066dcba0deaccbb3caa952d902fe
-- ARROW_AWS_C_SDKUTILS_BUILD_VERSION: v0.1.6
-- ARROW_AWS_C_SDKUTILS_BUILD_SHA256_CHECKSUM: 8a2951344b2fb541eab1e9ca17c18a7fcbfd2aaff4cdd31d362d1fad96111b91
-- ARROW_AWS_CHECKSUMS_BUILD_VERSION: v0.1.13
-- ARROW_AWS_CHECKSUMS_BUILD_SHA256_CHECKSUM: 0f897686f1963253c5069a0e495b85c31635ba146cd3ac38cc2ea31eaf54694d
-- ARROW_AWS_CRT_CPP_BUILD_VERSION: v0.18.16
-- ARROW_AWS_CRT_CPP_BUILD_SHA256_CHECKSUM: 9e69bc1dc4b50871d1038aa9ff6ddeb4c9b28f7d6b5e5b1b69041ccf50a13483
-- ARROW_AWS_LC_BUILD_VERSION: v1.3.0
-- ARROW_AWS_LC_BUILD_SHA256_CHECKSUM: ae96a3567161552744fc0cae8b4d68ed88b1ec0f3d3c98700070115356da5a37
-- ARROW_AWSSDK_BUILD_VERSION: 1.10.55
-- ARROW_AWSSDK_BUILD_SHA256_CHECKSUM: 2d552fb1a84bef4a9b65e34aa7031851ed2aef5319e02cc6e4cb735c48aa30de
-- ARROW_BOOST_BUILD_VERSION: 1.81.0
-- ARROW_BOOST_BUILD_SHA256_CHECKSUM: 9e0ffae35528c35f90468997bc8d99500bf179cbae355415a89a600c38e13574
-- ARROW_BROTLI_BUILD_VERSION: v1.0.9
-- ARROW_BROTLI_BUILD_SHA256_CHECKSUM: f9e8d81d0405ba66d181529af42a3354f838c939095ff99930da6aa9cdf6fe46
-- ARROW_BZIP2_BUILD_VERSION: 1.0.8
-- ARROW_BZIP2_BUILD_SHA256_CHECKSUM: ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269
-- ARROW_CARES_BUILD_VERSION: 1.17.2
-- ARROW_CARES_BUILD_SHA256_CHECKSUM: 4803c844ce20ce510ef0eb83f8ea41fa24ecaae9d280c468c582d2bb25b3913d
-- ARROW_CRC32C_BUILD_VERSION: 1.1.2
-- ARROW_CRC32C_BUILD_SHA256_CHECKSUM: ac07840513072b7fcebda6e821068aa04889018f24e10e46181068fb214d7e56
-- ARROW_GBENCHMARK_BUILD_VERSION: v1.7.1
-- ARROW_GBENCHMARK_BUILD_SHA256_CHECKSUM: 6430e4092653380d9dc4ccb45a1e2dc9259d581f4866dc0759713126056bc1d7
-- ARROW_GFLAGS_BUILD_VERSION: v2.2.2
-- ARROW_GFLAGS_BUILD_SHA256_CHECKSUM: 34af2f15cf7367513b352bdcd2493ab14ce43692d2dcd9dfc499492966c64dcf
-- ARROW_GLOG_BUILD_VERSION: v0.5.0
-- ARROW_GLOG_BUILD_SHA256_CHECKSUM: eede71f28371bf39aa69b45de23b329d37214016e2055269b3b5e7cfd40b59f5
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_VERSION: v2.8.0
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_SHA256_CHECKSUM: 21fb441b5a670a18bb16b6826be8e0530888d0b94320847c538d46f5a54dddbc
-- ARROW_GRPC_BUILD_VERSION: v1.46.3
-- ARROW_GRPC_BUILD_SHA256_CHECKSUM: d6cbf22cb5007af71b61c6be316a79397469c58c82a942552a62e708bce60964
-- ARROW_GTEST_BUILD_VERSION: 1.11.0
-- ARROW_GTEST_BUILD_SHA256_CHECKSUM: b4870bf121ff7795ba20d20bcdd8627b8e088f2d1dab299a031c1034eddc93d5
-- ARROW_JEMALLOC_BUILD_VERSION: 5.3.0
-- ARROW_JEMALLOC_BUILD_SHA256_CHECKSUM: 2db82d1e7119df3e71b7640219b6dfe84789bc0537983c3b7ac4f7189aecfeaa
-- ARROW_LZ4_BUILD_VERSION: v1.9.4
-- ARROW_LZ4_BUILD_SHA256_CHECKSUM: 0b0e3aa07c8c063ddf40b082bdf7e37a1562bda40a0ff5272957f3e987e0e54b
-- ARROW_MIMALLOC_BUILD_VERSION: v2.0.6
-- ARROW_MIMALLOC_BUILD_SHA256_CHECKSUM: 9f05c94cc2b017ed13698834ac2a3567b6339a8bde27640df5a1581d49d05ce5
-- ARROW_NLOHMANN_JSON_BUILD_VERSION: v3.10.5
-- ARROW_NLOHMANN_JSON_BUILD_SHA256_CHECKSUM: 5daca6ca216495edf89d167f808d1d03c4a4d929cef7da5e10f135ae1540c7e4
-- ARROW_OPENTELEMETRY_BUILD_VERSION: v1.8.1
-- ARROW_OPENTELEMETRY_BUILD_SHA256_CHECKSUM: 3d640201594b07f08dade9cd1017bd0b59674daca26223b560b9bb6bf56264c2
-- ARROW_OPENTELEMETRY_PROTO_BUILD_VERSION: v0.17.0
-- ARROW_OPENTELEMETRY_PROTO_BUILD_SHA256_CHECKSUM: f269fbcb30e17b03caa1decd231ce826e59d7651c0f71c3b28eb5140b4bb5412
-- ARROW_ORC_BUILD_VERSION: 1.8.3
-- ARROW_ORC_BUILD_SHA256_CHECKSUM: a78678ec425c8129d63370cb8a9bacb54186aa66af1e2bec01ce92e7eaf72e20
-- ARROW_PROTOBUF_BUILD_VERSION: v21.3
-- ARROW_PROTOBUF_BUILD_SHA256_CHECKSUM: 2f723218f6cb709ae4cdc4fb5ed56a5951fc5d466f0128ce4c946b8c78c8c49f
-- ARROW_RAPIDJSON_BUILD_VERSION: 232389d4f1012dddec4ef84861face2d2ba85709
-- ARROW_RAPIDJSON_BUILD_SHA256_CHECKSUM: b9290a9a6d444c8e049bd589ab804e0ccf2b05dc5984a19ed5ae75d090064806
-- ARROW_RE2_BUILD_VERSION: 2022-06-01
-- ARROW_RE2_BUILD_SHA256_CHECKSUM: f89c61410a072e5cbcf8c27e3a778da7d6fd2f2b5b1445cd4f4508bee946ab0f
-- ARROW_SNAPPY_BUILD_VERSION: 1.1.9
-- ARROW_SNAPPY_BUILD_SHA256_CHECKSUM: 75c1fbb3d618dd3a0483bff0e26d0a92b495bbe5059c8b4f1c962b478b6e06e7
-- ARROW_SUBSTRAIT_BUILD_VERSION: v0.20.0
-- ARROW_SUBSTRAIT_BUILD_SHA256_CHECKSUM: 5ceaa559ccef29a7825b5e5d4b5e7eed384830294f08bec913feecdd903a94cf
-- ARROW_S2N_TLS_BUILD_VERSION: v1.3.35
-- ARROW_S2N_TLS_BUILD_SHA256_CHECKSUM: 9d32b26e6bfcc058d98248bf8fc231537e347395dd89cf62bb432b55c5da990d
-- ARROW_THRIFT_BUILD_VERSION: 0.16.0
-- ARROW_THRIFT_BUILD_SHA256_CHECKSUM: f460b5c1ca30d8918ff95ea3eb6291b3951cf518553566088f3f2be8981f6209
-- ARROW_UCX_BUILD_VERSION: 1.12.1
-- ARROW_UCX_BUILD_SHA256_CHECKSUM: 9bef31aed0e28bf1973d28d74d9ac4f8926c43ca3b7010bd22a084e164e31b71
-- ARROW_UTF8PROC_BUILD_VERSION: v2.7.0
-- ARROW_UTF8PROC_BUILD_SHA256_CHECKSUM: 4bb121e297293c0fd55f08f83afab6d35d48f0af4ecc07523ad8ec99aa2b12a1
-- ARROW_XSIMD_BUILD_VERSION: 9.0.1
-- ARROW_XSIMD_BUILD_SHA256_CHECKSUM: b1bb5f92167fd3a4f25749db0be7e61ed37e0a5d943490f3accdcd2cd2918cc0
-- ARROW_ZLIB_BUILD_VERSION: 1.2.13
-- ARROW_ZLIB_BUILD_SHA256_CHECKSUM: b3a24de97a8fdbc835b9833169501030b8977031bcb54b3b3ac13740f846ab30
-- ARROW_ZSTD_BUILD_VERSION: 1.5.5
-- ARROW_ZSTD_BUILD_SHA256_CHECKSUM: 9c4396cc829cfae319a6e2615202e82aad41372073482fce286fac78646d3ee4
-- Looking for pthread.h
-- Looking for pthread.h - found
-- Performing Test CMAKE_HAVE_LIBC_PTHREAD
-- Performing Test CMAKE_HAVE_LIBC_PTHREAD - Success
-- Found Threads: TRUE  
-- Looking for _M_ARM64
-- Looking for _M_ARM64 - not found
-- Looking for __SIZEOF_INT128__
-- Looking for __SIZEOF_INT128__ - found
-- Found Boost: /usr/lib/x86_64-linux-gnu/cmake/Boost-1.74.0/BoostConfig.cmake (found suitable version "1.74.0", minimum required is "1.58")  
-- Boost include dir: /usr/include
CMake Warning at cmake_modules/FindSnappyAlt.cmake:29 (find_package):
  By not providing "FindSnappy.cmake" in CMAKE_MODULE_PATH this project has
  asked CMake to find a package configuration file provided by "Snappy", but
  CMake did not find one.

  Could not find a package configuration file provided by "Snappy" with any
  of the following names:

    SnappyConfig.cmake
    snappy-config.cmake

  Add the installation prefix of "Snappy" to CMAKE_PREFIX_PATH or set
  "Snappy_DIR" to a directory containing one of the above files.  If "Snappy"
  provides a separate development package or SDK, be sure it has been
  installed.
Call Stack (most recent call first):
  cmake_modules/ThirdpartyToolchain.cmake:267 (find_package)
  cmake_modules/ThirdpartyToolchain.cmake:1305 (resolve_dependency)
  CMakeLists.txt:506 (include)


-- Could NOT find SnappyAlt (missing: Snappy_LIB Snappy_INCLUDE_DIR) 
-- Building snappy from source
-- Checking for modules 'libbrotlicommon;libbrotlienc;libbrotlidec'
--   Found libbrotlicommon, version 1.0.9
--   Found libbrotlienc, version 1.0.9
--   Found libbrotlidec, version 1.0.9
-- Found BrotliAlt: /usr/lib/x86_64-linux-gnu/libbrotlicommon.so  
-- Providing CMake module for BrotliAlt as part of Arrow CMake package
-- Using pkg-config package for libbrotlidec for static link
-- Using pkg-config package for libbrotlienc for static link
-- Found OpenSSL: /usr/lib/x86_64-linux-gnu/libcrypto.so (found suitable version "3.0.2", minimum required is "1.0.2")  
-- Providing CMake module for OpenSSLAlt as part of Arrow CMake package
-- Found OpenSSL Crypto Library: /usr/lib/x86_64-linux-gnu/libcrypto.so
-- Building with OpenSSL (Version: 3.0.2) support
CMake Warning at cmake_modules/FindThriftAlt.cmake:56 (find_package):
  By not providing "FindThrift.cmake" in CMAKE_MODULE_PATH this project has
  asked CMake to find a package configuration file provided by "Thrift", but
  CMake did not find one.

  Could not find a package configuration file provided by "Thrift" (requested
  version 0.11.0) with any of the following names:

    ThriftConfig.cmake
    thrift-config.cmake

  Add the installation prefix of "Thrift" to CMAKE_PREFIX_PATH or set
  "Thrift_DIR" to a directory containing one of the above files.  If "Thrift"
  provides a separate development package or SDK, be sure it has been
  installed.
Call Stack (most recent call first):
  cmake_modules/ThirdpartyToolchain.cmake:267 (find_package)
  cmake_modules/ThirdpartyToolchain.cmake:1646 (resolve_dependency)
  CMakeLists.txt:506 (include)


-- Checking for module 'thrift'
--   No package 'thrift' found
-- Could NOT find ThriftAlt: Found unsuitable version "", but required is at least "0.11.0" (found ThriftAlt_LIB-NOTFOUND)
-- Building Apache Thrift from source
-- Building jemalloc from source
-- Building (vendored) mimalloc from source
CMake Warning at cmake_modules/FindRapidJSONAlt.cmake:29 (find_package):
  By not providing "FindRapidJSON.cmake" in CMAKE_MODULE_PATH this project
  has asked CMake to find a package configuration file provided by
  "RapidJSON", but CMake did not find one.

  Could not find a package configuration file provided by "RapidJSON"
  (requested version 1.1.0) with any of the following names:

    RapidJSONConfig.cmake
    rapidjson-config.cmake

  Add the installation prefix of "RapidJSON" to CMAKE_PREFIX_PATH or set
  "RapidJSON_DIR" to a directory containing one of the above files.  If
  "RapidJSON" provides a separate development package or SDK, be sure it has
  been installed.
Call Stack (most recent call first):
  cmake_modules/ThirdpartyToolchain.cmake:267 (find_package)
  cmake_modules/ThirdpartyToolchain.cmake:2367 (resolve_dependency)
  CMakeLists.txt:506 (include)


-- Could NOT find RapidJSONAlt (missing: RAPIDJSON_INCLUDE_DIR) (Required is at least version "1.1.0")
-- Building RapidJSON from source
CMake Warning at cmake_modules/ThirdpartyToolchain.cmake:267 (find_package):
  By not providing "Findxsimd.cmake" in CMAKE_MODULE_PATH this project has
  asked CMake to find a package configuration file provided by "xsimd", but
  CMake did not find one.

  Could not find a package configuration file provided by "xsimd" with any of
  the following names:

    xsimdConfig.cmake
    xsimd-config.cmake

  Add the installation prefix of "xsimd" to CMAKE_PREFIX_PATH or set
  "xsimd_DIR" to a directory containing one of the above files.  If "xsimd"
  provides a separate development package or SDK, be sure it has been
  installed.
Call Stack (most recent call first):
  cmake_modules/ThirdpartyToolchain.cmake:2424 (resolve_dependency)
  CMakeLists.txt:506 (include)


-- Building xsimd from source
-- Found ZLIB: /usr/lib/x86_64-linux-gnu/libz.so (found version "1.2.11") 
-- Using pkg-config package for zlib for static link
CMake Warning at cmake_modules/Findlz4Alt.cmake:29 (find_package):
  By not providing "Findlz4.cmake" in CMAKE_MODULE_PATH this project has
  asked CMake to find a package configuration file provided by "lz4", but
  CMake did not find one.

  Could not find a package configuration file provided by "lz4" with any of
  the following names:

    lz4Config.cmake
    lz4-config.cmake

  Add the installation prefix of "lz4" to CMAKE_PREFIX_PATH or set "lz4_DIR"
  to a directory containing one of the above files.  If "lz4" provides a
  separate development package or SDK, be sure it has been installed.
Call Stack (most recent call first):
  cmake_modules/ThirdpartyToolchain.cmake:267 (find_package)
  cmake_modules/ThirdpartyToolchain.cmake:2523 (resolve_dependency)
  CMakeLists.txt:506 (include)


-- Checking for module 'liblz4'
--   No package 'liblz4' found
-- Could NOT find lz4Alt (missing: LZ4_LIB LZ4_INCLUDE_DIR) 
-- Building LZ4 from source
CMake Warning at cmake_modules/FindzstdAlt.cmake:29 (find_package):
  By not providing "Findzstd.cmake" in CMAKE_MODULE_PATH this project has
  asked CMake to find a package configuration file provided by "zstd", but
  CMake did not find one.

  Could not find a package configuration file provided by "zstd" (requested
  version 1.4.0) with any of the following names:

    zstdConfig.cmake
    zstd-config.cmake

  Add the installation prefix of "zstd" to CMAKE_PREFIX_PATH or set
  "zstd_DIR" to a directory containing one of the above files.  If "zstd"
  provides a separate development package or SDK, be sure it has been
  installed.
Call Stack (most recent call first):
  cmake_modules/ThirdpartyToolchain.cmake:267 (find_package)
  cmake_modules/ThirdpartyToolchain.cmake:2582 (resolve_dependency)
  CMakeLists.txt:506 (include)


-- Checking for module 'libzstd'
--   No package 'libzstd' found
-- Could NOT find zstdAlt (missing: ZSTD_LIB ZSTD_INCLUDE_DIR) (Required is at least version "1.4.0")
-- Building Zstandard from source
CMake Warning at cmake_modules/Findre2Alt.cmake:29 (find_package):
  By not providing "Findre2.cmake" in CMAKE_MODULE_PATH this project has
  asked CMake to find a package configuration file provided by "re2", but
  CMake did not find one.

  Could not find a package configuration file provided by "re2" with any of
  the following names:

    re2Config.cmake
    re2-config.cmake

  Add the installation prefix of "re2" to CMAKE_PREFIX_PATH or set "re2_DIR"
  to a directory containing one of the above files.  If "re2" provides a
  separate development package or SDK, be sure it has been installed.
Call Stack (most recent call first):
  cmake_modules/ThirdpartyToolchain.cmake:267 (find_package)
  cmake_modules/ThirdpartyToolchain.cmake:2644 (resolve_dependency)
  CMakeLists.txt:506 (include)


-- Checking for module 're2'
--   No package 're2' found
-- Could NOT find re2Alt (missing: RE2_LIB RE2_INCLUDE_DIR) 
-- Building RE2 from source
-- Found BZip2: /usr/lib/x86_64-linux-gnu/libbz2.so (found version "1.0.8") 
-- Looking for BZ2_bzCompressInit
-- Looking for BZ2_bzCompressInit - found
-- pkg-config package for bzip2 for static link isn't found
-- Could NOT find utf8proc: Found unsuitable version "", but required is at least "2.2.0" (found utf8proc_LIB-NOTFOUND)
-- Building utf8proc from source
CMake Warning at cmake_modules/ThirdpartyToolchain.cmake:267 (find_package):
  By not providing "Findnlohmann_json.cmake" in CMAKE_MODULE_PATH this
  project has asked CMake to find a package configuration file provided by
  "nlohmann_json", but CMake did not find one.

  Could not find a package configuration file provided by "nlohmann_json"
  with any of the following names:

    nlohmann_jsonConfig.cmake
    nlohmann_json-config.cmake

  Add the installation prefix of "nlohmann_json" to CMAKE_PREFIX_PATH or set
  "nlohmann_json_DIR" to a directory containing one of the above files.  If
  "nlohmann_json" provides a separate development package or SDK, be sure it
  has been installed.
Call Stack (most recent call first):
  cmake_modules/ThirdpartyToolchain.cmake:4187 (resolve_dependency)
  CMakeLists.txt:506 (include)


-- Building nlohmann-json from source
-- Found nlohmann_json headers: /tmp/Rtmp5tTRmH/filedab020a0561d/nlohmann_json_ep-install/include
CMake Warning at cmake_modules/ThirdpartyToolchain.cmake:267 (find_package):
  By not providing "Findgoogle_cloud_cpp_storage.cmake" in CMAKE_MODULE_PATH
  this project has asked CMake to find a package configuration file provided
  by "google_cloud_cpp_storage", but CMake did not find one.

  Could not find a package configuration file provided by
  "google_cloud_cpp_storage" with any of the following names:

    google_cloud_cpp_storageConfig.cmake
    google_cloud_cpp_storage-config.cmake

  Add the installation prefix of "google_cloud_cpp_storage" to
  CMAKE_PREFIX_PATH or set "google_cloud_cpp_storage_DIR" to a directory
  containing one of the above files.  If "google_cloud_cpp_storage" provides
  a separate development package or SDK, be sure it has been installed.
Call Stack (most recent call first):
  cmake_modules/ThirdpartyToolchain.cmake:4376 (resolve_dependency)
  CMakeLists.txt:506 (include)


-- Building google-cloud-cpp from source
-- Only building the google-cloud-cpp::storage component
CMake Warning at cmake_modules/ThirdpartyToolchain.cmake:2828 (find_package):
  By not providing "Findabsl.cmake" in CMAKE_MODULE_PATH this project has
  asked CMake to find a package configuration file provided by "absl", but
  CMake did not find one.

  Could not find a package configuration file provided by "absl" (requested
  version 20211102) with any of the following names:

    abslConfig.cmake
    absl-config.cmake

  Add the installation prefix of "absl" to CMAKE_PREFIX_PATH or set
  "absl_DIR" to a directory containing one of the above files.  If "absl"
  provides a separate development package or SDK, be sure it has been
  installed.
Call Stack (most recent call first):
  cmake_modules/ThirdpartyToolchain.cmake:4198 (ensure_absl)
  cmake_modules/ThirdpartyToolchain.cmake:174 (build_google_cloud_cpp_storage)
  cmake_modules/ThirdpartyToolchain.cmake:280 (build_dependency)
  cmake_modules/ThirdpartyToolchain.cmake:4376 (resolve_dependency)
  CMakeLists.txt:506 (include)


CMake Warning at cmake_modules/ThirdpartyToolchain.cmake:2828 (find_package):
  By not providing "Findabsl.cmake" in CMAKE_MODULE_PATH this project has
  asked CMake to find a package configuration file provided by "absl", but
  CMake did not find one.

  Could not find a package configuration file provided by "absl" (requested
  version 20220623) with any of the following names:

    abslConfig.cmake
    absl-config.cmake

  Add the installation prefix of "absl" to CMAKE_PREFIX_PATH or set
  "absl_DIR" to a directory containing one of the above files.  If "absl"
  provides a separate development package or SDK, be sure it has been
  installed.
Call Stack (most recent call first):
  cmake_modules/ThirdpartyToolchain.cmake:4198 (ensure_absl)
  cmake_modules/ThirdpartyToolchain.cmake:174 (build_google_cloud_cpp_storage)
  cmake_modules/ThirdpartyToolchain.cmake:280 (build_dependency)
  cmake_modules/ThirdpartyToolchain.cmake:4376 (resolve_dependency)
  CMakeLists.txt:506 (include)


-- Building Abseil-cpp from source
-- Building crc32c from source
-- Found CURL: /usr/lib/x86_64-linux-gnu/libcurl.so (found version "7.81.0")  
-- Found google-cloud-cpp::storage headers: /tmp/Rtmp5tTRmH/filedab020a0561d/google_cloud_cpp_ep-install/include
-- Found hdfs.h at: /home/tdhock/arrow_12/tools/cpp/thirdparty/hadoop/include/hdfs.h
CMake Warning at cmake_modules/FindAWSSDKAlt.cmake:36 (find_package):
  By not providing "FindAWSSDK.cmake" in CMAKE_MODULE_PATH this project has
  asked CMake to find a package configuration file provided by "AWSSDK", but
  CMake did not find one.

  Could not find a package configuration file provided by "AWSSDK" with any
  of the following names:

    AWSSDKConfig.cmake
    awssdk-config.cmake

  Add the installation prefix of "AWSSDK" to CMAKE_PREFIX_PATH or set
  "AWSSDK_DIR" to a directory containing one of the above files.  If "AWSSDK"
  provides a separate development package or SDK, be sure it has been
  installed.
Call Stack (most recent call first):
  cmake_modules/ThirdpartyToolchain.cmake:267 (find_package)
  cmake_modules/ThirdpartyToolchain.cmake:5075 (resolve_dependency)
  CMakeLists.txt:506 (include)


-- Building AWS C++ SDK from source
-- Found AWS SDK headers: /tmp/Rtmp5tTRmH/filedab020a0561d/awssdk_ep-install/include
-- Found AWS SDK libraries: aws-cpp-sdk-identity-management;aws-cpp-sdk-sts;aws-cpp-sdk-cognito-identity;aws-cpp-sdk-s3;aws-cpp-sdk-core;AWS::aws-crt-cpp;AWS::aws-c-s3;AWS::aws-c-auth;AWS::aws-c-mqtt;AWS::aws-c-http;AWS::aws-c-compression;AWS::aws-c-sdkutils;AWS::aws-c-event-stream;AWS::aws-c-io;AWS::aws-c-cal;AWS::aws-checksums;AWS::aws-c-common;AWS::s2n-tls
-- All bundled static libraries: Snappy::snappy-static;thrift::thrift;jemalloc::jemalloc;mimalloc::mimalloc;LZ4::lz4;zstd::libzstd_static;re2::re2;utf8proc::utf8proc;google-cloud-cpp::storage;google-cloud-cpp::rest-internal;google-cloud-cpp::common;absl::bad_optional_access;absl::bad_variant_access;absl::base;absl::civil_time;absl::int128;absl::log_severity;absl::raw_logging_internal;absl::spinlock_wait;absl::strings;absl::strings_internal;absl::str_format_internal;absl::throw_delegate;absl::time;absl::time_zone;Crc32c::crc32c;aws-cpp-sdk-identity-management;aws-cpp-sdk-sts;aws-cpp-sdk-cognito-identity;aws-cpp-sdk-s3;aws-cpp-sdk-core;AWS::aws-crt-cpp;AWS::aws-c-s3;AWS::aws-c-auth;AWS::aws-c-mqtt;AWS::aws-c-http;AWS::aws-c-compression;AWS::aws-c-sdkutils;AWS::aws-c-event-stream;AWS::aws-c-io;AWS::aws-c-cal;AWS::aws-checksums;AWS::aws-c-common;AWS::s2n-tls
-- CMAKE_C_FLAGS: -g -O2  -Wall -fno-semantic-interposition -msse4.2 
-- CMAKE_CXX_FLAGS:  -Wno-noexcept-type -g -O2 -fdiagnostics-color=always  -Wall -fno-semantic-interposition -msse4.2 
-- CMAKE_C_FLAGS_RELEASE: -O3 -DNDEBUG -O2 -ftree-vectorize
-- CMAKE_CXX_FLAGS_RELEASE: -O3 -DNDEBUG -O2 -ftree-vectorize
-- Creating bundled static library target arrow_bundled_dependencies at /tmp/Rtmp5tTRmH/filedab020a0561d/release/libarrow_bundled_dependencies.a
-- Looking for backtrace
-- Looking for backtrace - found
-- backtrace facility detected in default set of libraries
-- Found Backtrace: /usr/include  
-- ---------------------------------------------------------------------
-- Arrow version:                                 12.0.0
-- 
-- Build configuration summary:
--   Generator: Unix Makefiles
--   Build type: RELEASE
--   Source directory: /home/tdhock/arrow_12/tools/cpp
--   Install prefix: /home/tdhock/arrow_12/libarrow/arrow-12.0.0
-- 
-- Compile and link options:
-- 
--   ARROW_CXXFLAGS="" [default=""]
--       Compiler flags to append when compiling Arrow
--   ARROW_BUILD_STATIC=ON [default=ON]
--       Build static libraries
--   ARROW_BUILD_SHARED=OFF [default=ON]
--       Build shared libraries
--   ARROW_PACKAGE_KIND="" [default=""]
--       Arbitrary string that identifies the kind of package
--       (for informational purposes)
--   ARROW_GIT_ID="" [default=""]
--       The Arrow git commit id (if any)
--   ARROW_GIT_DESCRIPTION="" [default=""]
--       The Arrow git commit description (if any)
--   ARROW_NO_DEPRECATED_API=OFF [default=OFF]
--       Exclude deprecated APIs from build
--   ARROW_POSITION_INDEPENDENT_CODE=ON [default=ON]
--       Whether to create position-independent target
--   ARROW_USE_CCACHE=ON [default=ON]
--       Use ccache when compiling (if available)
--   ARROW_USE_SCCACHE=ON [default=ON]
--       Use sccache when compiling (if available),
--       takes precedence over ccache if a storage backend is configured
--   ARROW_USE_LD_GOLD=OFF [default=OFF]
--       Use ld.gold for linking on Linux (if available)
--   ARROW_USE_PRECOMPILED_HEADERS=OFF [default=OFF]
--       Use precompiled headers when compiling
--   ARROW_SIMD_LEVEL=SSE4_2 [default=NONE|SSE4_2|AVX2|AVX512|NEON|SVE|SVE128|SVE256|SVE512|DEFAULT]
--       Compile-time SIMD optimization level
--   ARROW_RUNTIME_SIMD_LEVEL=MAX [default=NONE|SSE4_2|AVX2|AVX512|MAX]
--       Max runtime SIMD optimization level
--   ARROW_ALTIVEC=ON [default=ON]
--       Build with Altivec if compiler has support
--   ARROW_RPATH_ORIGIN=OFF [default=OFF]
--       Build Arrow libraries with RATH set to $ORIGIN
--   ARROW_INSTALL_NAME_RPATH=ON [default=ON]
--       Build Arrow libraries with install_name set to @rpath
--   ARROW_GGDB_DEBUG=ON [default=ON]
--       Pass -ggdb flag to debug builds
--   ARROW_WITH_MUSL=OFF [default=OFF]
--       Whether the system libc is musl or not
-- 
-- Test and benchmark options:
-- 
--   ARROW_BUILD_EXAMPLES=OFF [default=OFF]
--       Build the Arrow examples
--   ARROW_BUILD_TESTS=OFF [default=OFF]
--       Build the Arrow googletest unit tests
--   ARROW_ENABLE_TIMING_TESTS=ON [default=ON]
--       Enable timing-sensitive tests
--   ARROW_BUILD_INTEGRATION=OFF [default=OFF]
--       Build the Arrow integration test executables
--   ARROW_BUILD_BENCHMARKS=OFF [default=OFF]
--       Build the Arrow micro benchmarks
--   ARROW_BUILD_BENCHMARKS_REFERENCE=OFF [default=OFF]
--       Build the Arrow micro reference benchmarks
--   ARROW_BUILD_OPENMP_BENCHMARKS=OFF [default=OFF]
--       Build the Arrow benchmarks that rely on OpenMP
--   ARROW_BUILD_DETAILED_BENCHMARKS=OFF [default=OFF]
--       Build benchmarks that do a longer exploration of performance
--   ARROW_TEST_LINKAGE=static [default=shared|static]
--       Linkage of Arrow libraries with unit tests executables.
--   ARROW_FUZZING=OFF [default=OFF]
--       Build Arrow Fuzzing executables
--   ARROW_LARGE_MEMORY_TESTS=OFF [default=OFF]
--       Enable unit tests which use large memory
-- 
-- Lint options:
-- 
--   ARROW_ONLY_LINT=OFF [default=OFF]
--       Only define the lint and check-format targets
--   ARROW_VERBOSE_LINT=OFF [default=OFF]
--       If off, 'quiet' flags will be passed to linting tools
--   ARROW_GENERATE_COVERAGE=OFF [default=OFF]
--       Build with C++ code coverage enabled
-- 
-- Checks options:
-- 
--   ARROW_TEST_MEMCHECK=OFF [default=OFF]
--       Run the test suite using valgrind --tool=memcheck
--   ARROW_USE_ASAN=OFF [default=OFF]
--       Enable Address Sanitizer checks
--   ARROW_USE_TSAN=OFF [default=OFF]
--       Enable Thread Sanitizer checks
--   ARROW_USE_UBSAN=OFF [default=OFF]
--       Enable Undefined Behavior sanitizer checks
-- 
-- Project component options:
-- 
--   ARROW_BUILD_UTILITIES=OFF [default=OFF]
--       Build Arrow commandline utilities
--   ARROW_COMPUTE=ON [default=OFF]
--       Build all Arrow Compute kernels
--   ARROW_CSV=ON [default=OFF]
--       Build the Arrow CSV Parser Module
--   ARROW_CUDA=OFF [default=OFF]
--       Build the Arrow CUDA extensions (requires CUDA toolkit)
--   ARROW_DATASET=ON [default=OFF]
--       Build the Arrow Dataset Modules
--   ARROW_FILESYSTEM=ON [default=OFF]
--       Build the Arrow Filesystem Layer
--   ARROW_FLIGHT=OFF [default=OFF]
--       Build the Arrow Flight RPC System (requires GRPC, Protocol Buffers)
--   ARROW_FLIGHT_SQL=OFF [default=OFF]
--       Build the Arrow Flight SQL extension
--   ARROW_GANDIVA=OFF [default=OFF]
--       Build the Gandiva libraries
--   ARROW_GCS=ON [default=OFF]
--       Build Arrow with GCS support (requires the GCloud SDK for C++)
--   ARROW_HDFS=OFF [default=OFF]
--       Build the Arrow HDFS bridge
--   ARROW_IPC=ON [default=ON]
--       Build the Arrow IPC extensions
--   ARROW_JEMALLOC=ON [default=ON]
--       Build the Arrow jemalloc-based allocator
--   ARROW_JSON=ON [default=OFF]
--       Build Arrow with JSON support (requires RapidJSON)
--   ARROW_MIMALLOC=ON [default=OFF]
--       Build the Arrow mimalloc-based allocator
--   ARROW_PARQUET=ON [default=OFF]
--       Build the Parquet libraries
--   ARROW_ORC=OFF [default=OFF]
--       Build the Arrow ORC adapter
--   ARROW_PYTHON=OFF [default=OFF]
--       Build some components needed by PyArrow.
--       (This is a deprecated option. Use CMake presets instead.)
--   ARROW_S3=ON [default=OFF]
--       Build Arrow with S3 support (requires the AWS SDK for C++)
--   ARROW_SKYHOOK=OFF [default=OFF]
--       Build the Skyhook libraries
--   ARROW_SUBSTRAIT=OFF [default=OFF]
--       Build the Arrow Substrait Consumer Module
--   ARROW_ACERO=ON [default=OFF]
--       Build the Arrow Acero Engine Module
--   ARROW_TENSORFLOW=OFF [default=OFF]
--       Build Arrow with TensorFlow support enabled
--   ARROW_TESTING=OFF [default=OFF]
--       Build the Arrow testing libraries
-- 
-- Thirdparty toolchain options:
-- 
--   ARROW_DEPENDENCY_SOURCE=AUTO [default=AUTO|BUNDLED|SYSTEM|CONDA|VCPKG|BREW]
--       Method to use for acquiring arrow's build dependencies
--   ARROW_VERBOSE_THIRDPARTY_BUILD=OFF [default=OFF]
--       Show output from ExternalProjects rather than just logging to files
--   ARROW_DEPENDENCY_USE_SHARED=ON [default=ON]
--       Link to shared libraries
--   ARROW_BOOST_USE_SHARED=OFF [default=ON]
--       Rely on Boost shared libraries where relevant
--   ARROW_BROTLI_USE_SHARED=ON [default=ON]
--       Rely on Brotli shared libraries where relevant
--   ARROW_BZ2_USE_SHARED=ON [default=ON]
--       Rely on Bz2 shared libraries where relevant
--   ARROW_GFLAGS_USE_SHARED=ON [default=ON]
--       Rely on GFlags shared libraries where relevant
--   ARROW_GRPC_USE_SHARED=ON [default=ON]
--       Rely on gRPC shared libraries where relevant
--   ARROW_JEMALLOC_USE_SHARED=OFF [default=ON]
--       Rely on jemalloc shared libraries where relevant
--   ARROW_LZ4_USE_SHARED=ON [default=ON]
--       Rely on lz4 shared libraries where relevant
--   ARROW_OPENSSL_USE_SHARED=ON [default=ON]
--       Rely on OpenSSL shared libraries where relevant
--   ARROW_PROTOBUF_USE_SHARED=ON [default=ON]
--       Rely on Protocol Buffers shared libraries where relevant
--   ARROW_SNAPPY_USE_SHARED=ON [default=ON]
--       Rely on snappy shared libraries where relevant
--   ARROW_THRIFT_USE_SHARED=ON [default=ON]
--       Rely on thrift shared libraries where relevant
--   ARROW_UTF8PROC_USE_SHARED=ON [default=ON]
--       Rely on utf8proc shared libraries where relevant
--   ARROW_ZSTD_USE_SHARED=ON [default=ON]
--       Rely on zstd shared libraries where relevant
--   ARROW_USE_GLOG=OFF [default=OFF]
--       Build libraries with glog support for pluggable logging
--   ARROW_WITH_BACKTRACE=ON [default=ON]
--       Build with backtrace support
--   ARROW_WITH_OPENTELEMETRY=OFF [default=OFF]
--       Build libraries with OpenTelemetry support for distributed tracing
--   ARROW_WITH_BROTLI=ON [default=OFF]
--       Build with Brotli compression
--   ARROW_WITH_BZ2=ON [default=OFF]
--       Build with BZ2 compression
--   ARROW_WITH_LZ4=ON [default=OFF]
--       Build with lz4 compression
--   ARROW_WITH_SNAPPY=ON [default=OFF]
--       Build with Snappy compression
--   ARROW_WITH_ZLIB=ON [default=OFF]
--       Build with zlib compression
--   ARROW_WITH_ZSTD=ON [default=OFF]
--       Build with zstd compression
--   ARROW_WITH_UCX=OFF [default=OFF]
--       Build with UCX transport for Arrow Flight
--       (only used if ARROW_FLIGHT is ON)
--   ARROW_WITH_UTF8PROC=ON [default=ON]
--       Build with support for Unicode properties using the utf8proc library
--       (only used if ARROW_COMPUTE is ON or ARROW_GANDIVA is ON)
--   ARROW_WITH_RE2=ON [default=ON]
--       Build with support for regular expressions using the re2 library
--       (only used if ARROW_COMPUTE or ARROW_GANDIVA is ON)
-- 
-- Parquet options:
-- 
--   PARQUET_MINIMAL_DEPENDENCY=OFF [default=OFF]
--       Depend only on Thirdparty headers to build libparquet.
--       Always OFF if building binaries
--   PARQUET_BUILD_EXECUTABLES=OFF [default=OFF]
--       Build the Parquet executable CLI tools. Requires static libraries to be built.
--   PARQUET_BUILD_EXAMPLES=OFF [default=OFF]
--       Build the Parquet examples. Requires static libraries to be built.
--   PARQUET_REQUIRE_ENCRYPTION=OFF [default=OFF]
--       Build support for encryption. Fail if OpenSSL is not found
-- 
-- Gandiva options:
-- 
--   ARROW_GANDIVA_STATIC_LIBSTDCPP=OFF [default=OFF]
--       Include -static-libstdc++ -static-libgcc when linking with
--       Gandiva static libraries
--   ARROW_GANDIVA_PC_CXX_FLAGS="" [default=""]
--       Compiler flags to append when pre-compiling Gandiva operations
-- 
-- Advanced developer options:
-- 
--   ARROW_EXTRA_ERROR_CONTEXT=OFF [default=OFF]
--       Compile with extra error context (line numbers, code)
--   ARROW_OPTIONAL_INSTALL=OFF [default=OFF]
--       If enabled install ONLY targets that have already been built. Please be
--       advised that if this is enabled 'install' will fail silently on components
--       that have not been built
--   ARROW_GDB_INSTALL_DIR="" [default=""]
--       Use a custom install directory for GDB plugin.
--       In general, you don't need to specify this because the default
--       (CMAKE_INSTALL_FULL_BINDIR on Windows, CMAKE_INSTALL_FULL_LIBDIR otherwise)
--       is reasonable.
--   Outputting build configuration summary to /tmp/Rtmp5tTRmH/filedab020a0561d/cmake_summary.json
-- Configuring done
-- Generating done
-- Build files have been written to: /tmp/Rtmp5tTRmH/filedab020a0561d
+ > /usr/bin/cmake --build . --target install -- -j 2
[  0%] Creating directories for 'snappy_ep'
[  0%] Creating directories for 'thrift_ep'
[  0%] Performing download step (download, verify and extract) for 'snappy_ep'
[  0%] Performing download step (download, verify and extract) for 'thrift_ep'
-- snappy_ep download command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/snappy_ep-prefix/src/snappy_ep-stamp/snappy_ep-download-*.log
[  1%] No update step for 'snappy_ep'
[  1%] No patch step for 'snappy_ep'
[  1%] Performing configure step for 'snappy_ep'
-- thrift_ep download command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/thrift_ep-prefix/src/thrift_ep-stamp/thrift_ep-download-*.log
[  1%] No update step for 'thrift_ep'
[  1%] No patch step for 'thrift_ep'
[  1%] Performing configure step for 'thrift_ep'
-- snappy_ep configure command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/snappy_ep-prefix/src/snappy_ep-stamp/snappy_ep-configure-*.log
[  2%] Performing build step for 'snappy_ep'
-- thrift_ep configure command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/thrift_ep-prefix/src/thrift_ep-stamp/thrift_ep-configure-*.log
[  2%] Performing build step for 'thrift_ep'
-- snappy_ep build command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/snappy_ep-prefix/src/snappy_ep-stamp/snappy_ep-build-*.log
[  2%] Performing install step for 'snappy_ep'
-- snappy_ep install command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/snappy_ep-prefix/src/snappy_ep-stamp/snappy_ep-install-*.log
[  2%] Completed 'snappy_ep'
[  2%] Built target snappy_ep
[  2%] Creating directories for 'jemalloc_ep'
[  2%] Performing download step (download, verify and extract) for 'jemalloc_ep'
-- jemalloc_ep download command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/jemalloc_ep-prefix/src/jemalloc_ep-stamp/jemalloc_ep-download-*.log
[  3%] No update step for 'jemalloc_ep'
[  3%] Performing patch step for 'jemalloc_ep'
[  3%] Performing configure step for 'jemalloc_ep'
-- jemalloc_ep configure command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/jemalloc_ep-prefix/src/jemalloc_ep-stamp/jemalloc_ep-configure-*.log
[  4%] Performing build step for 'jemalloc_ep'
-- thrift_ep build command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/thrift_ep-prefix/src/thrift_ep-stamp/thrift_ep-build-*.log
[  5%] Performing install step for 'thrift_ep'
-- thrift_ep install command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/thrift_ep-prefix/src/thrift_ep-stamp/thrift_ep-install-*.log
[  5%] Completed 'thrift_ep'
[  5%] Built target thrift_ep
[  5%] Creating directories for 'mimalloc_ep'
[  5%] Performing download step (download, verify and extract) for 'mimalloc_ep'
-- mimalloc_ep download command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/mimalloc_ep-prefix/src/mimalloc_ep-stamp/mimalloc_ep-download-*.log
[  6%] No update step for 'mimalloc_ep'
[  6%] No patch step for 'mimalloc_ep'
[  7%] Performing configure step for 'mimalloc_ep'
-- mimalloc_ep configure command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/mimalloc_ep-prefix/src/mimalloc_ep-stamp/mimalloc_ep-configure-*.log
[  7%] Performing build step for 'mimalloc_ep'
-- mimalloc_ep build command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/mimalloc_ep-prefix/src/mimalloc_ep-stamp/mimalloc_ep-build-*.log
[  7%] Performing install step for 'mimalloc_ep'
-- mimalloc_ep install command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/mimalloc_ep-prefix/src/mimalloc_ep-stamp/mimalloc_ep-install-*.log
[  7%] Completed 'mimalloc_ep'
[  7%] Built target mimalloc_ep
[  7%] Creating directories for 'rapidjson_ep'
[  8%] Performing download step (download, verify and extract) for 'rapidjson_ep'
-- rapidjson_ep download command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/src/rapidjson_ep-stamp/rapidjson_ep-download-*.log
[  8%] No update step for 'rapidjson_ep'
[  8%] No patch step for 'rapidjson_ep'
[  8%] Performing configure step for 'rapidjson_ep'
-- rapidjson_ep configure command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/src/rapidjson_ep-stamp/rapidjson_ep-configure-*.log
[  8%] Performing build step for 'rapidjson_ep'
-- rapidjson_ep build command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/src/rapidjson_ep-stamp/rapidjson_ep-build-*.log
[  8%] Performing install step for 'rapidjson_ep'
-- rapidjson_ep install command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/src/rapidjson_ep-stamp/rapidjson_ep-install-*.log
[  8%] Completed 'rapidjson_ep'
[  8%] Built target rapidjson_ep
[  9%] Creating directories for 'xsimd_ep'
[  9%] Performing download step (download, verify and extract) for 'xsimd_ep'
-- xsimd_ep download command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/src/xsimd_ep-stamp/xsimd_ep-download-*.log
[  9%] No update step for 'xsimd_ep'
[  9%] No patch step for 'xsimd_ep'
[  9%] Performing configure step for 'xsimd_ep'
-- xsimd_ep configure command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/src/xsimd_ep-stamp/xsimd_ep-configure-*.log
[  9%] Performing build step for 'xsimd_ep'
-- xsimd_ep build command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/src/xsimd_ep-stamp/xsimd_ep-build-*.log
[  9%] Performing install step for 'xsimd_ep'
-- xsimd_ep install command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/src/xsimd_ep-stamp/xsimd_ep-install-*.log
[  9%] Completed 'xsimd_ep'
[  9%] Built target xsimd_ep
[  9%] Creating directories for 'lz4_ep'
[  9%] Performing download step (download, verify and extract) for 'lz4_ep'
-- lz4_ep download command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/lz4_ep-prefix/src/lz4_ep-stamp/lz4_ep-download-*.log
[  9%] No update step for 'lz4_ep'
[  9%] No patch step for 'lz4_ep'
[  9%] Performing configure step for 'lz4_ep'
-- lz4_ep configure command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/lz4_ep-prefix/src/lz4_ep-stamp/lz4_ep-configure-*.log
[  9%] Performing build step for 'lz4_ep'
-- lz4_ep build command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/lz4_ep-prefix/src/lz4_ep-stamp/lz4_ep-build-*.log
[ 10%] Performing install step for 'lz4_ep'
-- lz4_ep install command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/lz4_ep-prefix/src/lz4_ep-stamp/lz4_ep-install-*.log
[ 10%] Completed 'lz4_ep'
[ 10%] Built target lz4_ep
[ 10%] Creating directories for 'zstd_ep'
[ 10%] Performing download step (download, verify and extract) for 'zstd_ep'
-- zstd_ep download command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/zstd_ep-prefix/src/zstd_ep-stamp/zstd_ep-download-*.log
[ 11%] No update step for 'zstd_ep'
[ 11%] No patch step for 'zstd_ep'
[ 12%] Performing configure step for 'zstd_ep'
-- zstd_ep configure command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/zstd_ep-prefix/src/zstd_ep-stamp/zstd_ep-configure-*.log
[ 12%] Performing build step for 'zstd_ep'
-- jemalloc_ep build command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/jemalloc_ep-prefix/src/jemalloc_ep-stamp/jemalloc_ep-build-*.log
[ 12%] Performing install step for 'jemalloc_ep'
-- jemalloc_ep install command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/jemalloc_ep-prefix/src/jemalloc_ep-stamp/jemalloc_ep-install-*.log
[ 12%] Completed 'jemalloc_ep'
[ 12%] Built target jemalloc_ep
[ 12%] Creating directories for 're2_ep'
[ 12%] Performing download step (download, verify and extract) for 're2_ep'
-- re2_ep download command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/re2_ep-prefix/src/re2_ep-stamp/re2_ep-download-*.log
[ 12%] No update step for 're2_ep'
[ 13%] No patch step for 're2_ep'
[ 13%] Performing configure step for 're2_ep'
-- re2_ep configure command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/re2_ep-prefix/src/re2_ep-stamp/re2_ep-configure-*.log
[ 14%] Performing build step for 're2_ep'
-- zstd_ep build command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/zstd_ep-prefix/src/zstd_ep-stamp/zstd_ep-build-*.log
[ 14%] Performing install step for 'zstd_ep'
-- zstd_ep install command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/zstd_ep-prefix/src/zstd_ep-stamp/zstd_ep-install-*.log
[ 14%] Completed 'zstd_ep'
[ 14%] Built target zstd_ep
[ 14%] Creating directories for 'utf8proc_ep'
[ 14%] Performing download step (download, verify and extract) for 'utf8proc_ep'
-- utf8proc_ep download command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/utf8proc_ep-prefix/src/utf8proc_ep-stamp/utf8proc_ep-download-*.log
[ 15%] No update step for 'utf8proc_ep'
[ 15%] No patch step for 'utf8proc_ep'
[ 16%] Performing configure step for 'utf8proc_ep'
-- utf8proc_ep configure command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/utf8proc_ep-prefix/src/utf8proc_ep-stamp/utf8proc_ep-configure-*.log
[ 16%] Performing build step for 'utf8proc_ep'
-- utf8proc_ep build command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/utf8proc_ep-prefix/src/utf8proc_ep-stamp/utf8proc_ep-build-*.log
[ 16%] Performing install step for 'utf8proc_ep'
-- utf8proc_ep install command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/utf8proc_ep-prefix/src/utf8proc_ep-stamp/utf8proc_ep-install-*.log
[ 16%] Completed 'utf8proc_ep'
[ 16%] Built target utf8proc_ep
[ 17%] Creating directories for 'nlohmann_json_ep'
[ 17%] Performing download step (download, verify and extract) for 'nlohmann_json_ep'
-- nlohmann_json_ep download command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/nlohmann_json_ep-prefix/src/nlohmann_json_ep-stamp/nlohmann_json_ep-download-*.log
[ 17%] No update step for 'nlohmann_json_ep'
[ 17%] No patch step for 'nlohmann_json_ep'
[ 17%] Performing configure step for 'nlohmann_json_ep'
-- nlohmann_json_ep configure command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/nlohmann_json_ep-prefix/src/nlohmann_json_ep-stamp/nlohmann_json_ep-configure-*.log
[ 17%] Performing build step for 'nlohmann_json_ep'
-- nlohmann_json_ep build command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/nlohmann_json_ep-prefix/src/nlohmann_json_ep-stamp/nlohmann_json_ep-build-*.log
[ 17%] Performing install step for 'nlohmann_json_ep'
-- nlohmann_json_ep install command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/nlohmann_json_ep-prefix/src/nlohmann_json_ep-stamp/nlohmann_json_ep-install-*.log
[ 17%] Completed 'nlohmann_json_ep'
[ 17%] Built target nlohmann_json_ep
[ 18%] Creating directories for 'absl_ep'
[ 18%] Performing download step (download, verify and extract) for 'absl_ep'
-- absl_ep download command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/absl_ep-prefix/src/absl_ep-stamp/absl_ep-download-*.log
[ 18%] No update step for 'absl_ep'
[ 18%] No patch step for 'absl_ep'
[ 18%] Performing configure step for 'absl_ep'
-- absl_ep configure command succeeded.  See also /tmp/Rtmp5tTRmH/filedab020a0561d/absl_ep-prefix/src/absl_ep-stamp/absl_ep-configure-*.log
[ 18%] Performing build step for 'absl_ep'
CMake Error at /tmp/Rtmp5tTRmH/filedab020a0561d/absl_ep-prefix/src/absl_ep-stamp/absl_ep-build-RELEASE.cmake:37 (message):
  Command failed: 2

   'make'

  See also

    /tmp/Rtmp5tTRmH/filedab020a0561d/absl_ep-prefix/src/absl_ep-stamp/absl_ep-build-*.log


-- stdout output is:
[  1%] Building CXX object absl/base/CMakeFiles/log_severity.dir/log_severity.cc.o
[  1%] Linking CXX static library libabsl_log_severity.a
[  1%] Built target log_severity
[  1%] Building CXX object absl/base/CMakeFiles/spinlock_wait.dir/internal/spinlock_wait.cc.o
[  2%] Linking CXX static library libabsl_spinlock_wait.a
[  2%] Built target spinlock_wait
[  3%] Building CXX object absl/base/CMakeFiles/strerror.dir/internal/strerror.cc.o
[  4%] Linking CXX static library libabsl_strerror.a
[  4%] Built target strerror
[  5%] Building CXX object absl/time/CMakeFiles/time_zone.dir/internal/cctz/src/time_zone_fixed.cc.o
[  5%] Building CXX object absl/time/CMakeFiles/time_zone.dir/internal/cctz/src/time_zone_format.cc.o
[  6%] Building CXX object absl/time/CMakeFiles/time_zone.dir/internal/cctz/src/time_zone_if.cc.o
[  6%] Building CXX object absl/time/CMakeFiles/time_zone.dir/internal/cctz/src/time_zone_impl.cc.o
[  7%] Building CXX object absl/time/CMakeFiles/time_zone.dir/internal/cctz/src/time_zone_info.cc.o
[  7%] Building CXX object absl/time/CMakeFiles/time_zone.dir/internal/cctz/src/time_zone_libc.cc.o

-- stderr output is:
/home/tdhock/include/c++/13.1.0/ratio: Dans l'instanciation de « struct std::__safe_multiply<1, 1> » :
/home/tdhock/include/c++/13.1.0/ratio:306:54:   requis par « struct std::__ratio_multiply<std::ratio<1, 1000000000>, std::ratio<1> > »
/home/tdhock/include/c++/13.1.0/ratio:335:42:   requis par « struct std::__ratio_divide<std::ratio<1, 1000000000>, std::ratio<1> > »
/home/tdhock/include/c++/13.1.0/ratio:353:11:   requis par la substitution de « template<class _R1, class _R2> using std::ratio_divide = typename std::__ratio_divide::type [with _R1 = std::ratio<1, 1000000000>; _R2 = std::ratio<1>] »
/home/tdhock/include/c++/13.1.0/bits/chrono.h:283:10:   requis par « constexpr std::chrono::__enable_if_is_duration<_ToDur> std::chrono::duration_cast(const duration<_Rep, _Period>&) [with _ToDur = duration<long int>; _Rep = long int; _Period = std::ratio<1, 1000000000>; __enable_if_is_duration<_ToDur> = duration<long int>] »
/home/tdhock/include/c++/13.1.0/bits/chrono.h:1257:7:   requis depuis ici
/home/tdhock/include/c++/13.1.0/ratio:102:36: erreur interne du compilateur: Erreur de segmentation
  102 |       static_assert(__b0 * __a0 <= __INTMAX_MAX__,
      |                                    ^~~~~~~~~~~~~~
0xe67aff crash_signal
	../.././gcc/toplev.cc:314
0x7fc25701951f ???
	./signal/../sysdeps/unix/sysv/linux/x86_64/libc_sigaction.c:0
0x93f9f5 cp_expr_location(tree_node const*)
	../.././gcc/cp/tree.cc:6261
0x8ecc12 tsubst_copy_and_build(tree_node*, tree_node*, int, tree_node*)
	../.././gcc/cp/pt.cc:20364
0x8ed6be tsubst_copy_and_build(tree_node*, tree_node*, int, tree_node*)
	../.././gcc/cp/pt.cc:21762
0x8ece22 tsubst_copy_and_build(tree_node*, tree_node*, int, tree_node*)
	../.././gcc/cp/pt.cc:20691
0x8fdd70 tsubst_expr(tree_node*, tree_node*, int, tree_node*)
	../.././gcc/cp/pt.cc:19889
0x8fe687 tsubst_expr(tree_node*, tree_node*, int, tree_node*)
	../.././gcc/cp/pt.cc:18827
0x8fe687 tsubst_expr(tree_node*, tree_node*, int, tree_node*)
	../.././gcc/cp/pt.cc:19394
0x910295 tsubst_expr(tree_node*, tree_node*, int, tree_node*)
	../.././gcc/cp/pt.cc:18827
0x910295 instantiate_class_template(tree_node*)
	../.././gcc/cp/pt.cc:12359
0x94a37b complete_type(tree_node*)
	../.././gcc/cp/typeck.cc:138
0x91ad1f lookup_member(tree_node*, tree_node*, int, bool, int, access_failure_info*)
	../.././gcc/cp/search.cc:1168
0x87eca1 lookup_qualified_name(tree_node*, tree_node*, LOOK_want, bool)
	../.././gcc/cp/name-lookup.cc:6894
0x8ec7b2 tsubst_qualified_id
	../.././gcc/cp/pt.cc:17047
0x8ee293 tsubst_copy_and_build(tree_node*, tree_node*, int, tree_node*)
	../.././gcc/cp/pt.cc:20730
0x8fdd70 tsubst_expr(tree_node*, tree_node*, int, tree_node*)
	../.././gcc/cp/pt.cc:19889
0x901ced tsubst_template_args(tree_node*, tree_node*, int, tree_node*)
	../.././gcc/cp/pt.cc:13764
0x906a49 tsubst_aggr_type_1
	../.././gcc/cp/pt.cc:14038
0x906a49 tsubst_aggr_type_1
	../.././gcc/cp/pt.cc:14019
Veuillez soumettre un rapport d’anomalies complet, avec la sortie du préprocesseur (en utilisant -freport-bug).
Veuillez inclure la trace de débogage complète dans tout rapport d'anomalie.
Voir <https://gcc.gnu.org/bugs/> pour les instructions.
make[5]: *** [absl/time/CMakeFiles/time_zone.dir/build.make:146 : absl/time/CMakeFiles/time_zone.dir/internal/cctz/src/time_zone_libc.cc.o] Erreur 1
make[4]: *** [CMakeFiles/Makefile2:2789 : absl/time/CMakeFiles/time_zone.dir/all] Erreur 2
make[3]: *** [Makefile:136 : all] Erreur 2

CMake Error at /tmp/Rtmp5tTRmH/filedab020a0561d/absl_ep-prefix/src/absl_ep-stamp/absl_ep-build-RELEASE.cmake:47 (message):
  Stopping after outputting logs.


make[2]: *** [CMakeFiles/absl_ep.dir/build.make:86 : absl_ep-prefix/src/absl_ep-stamp/absl_ep-build] Erreur 1
make[1]: *** [CMakeFiles/Makefile2:1177 : CMakeFiles/absl_ep.dir/all] Erreur 2
make[1]: *** Attente des tâches non terminées....
CMake Error at /tmp/Rtmp5tTRmH/filedab020a0561d/re2_ep-prefix/src/re2_ep-stamp/re2_ep-build-RELEASE.cmake:37 (message):
  Command failed: 2

   'make'

  See also

    /tmp/Rtmp5tTRmH/filedab020a0561d/re2_ep-prefix/src/re2_ep-stamp/re2_ep-build-*.log


-- stdout output is:
[  1%] Building CXX object CMakeFiles/re2.dir/re2/bitstate.cc.o
[  2%] Building CXX object CMakeFiles/re2.dir/re2/compile.cc.o
[  3%] Building CXX object CMakeFiles/re2.dir/re2/dfa.cc.o
[  4%] Building CXX object CMakeFiles/re2.dir/re2/filtered_re2.cc.o
[  5%] Building CXX object CMakeFiles/re2.dir/re2/mimics_pcre.cc.o
[  6%] Building CXX object CMakeFiles/re2.dir/re2/nfa.cc.o
[  7%] Building CXX object CMakeFiles/re2.dir/re2/onepass.cc.o
[  8%] Building CXX object CMakeFiles/re2.dir/re2/parse.cc.o
[  9%] Building CXX object CMakeFiles/re2.dir/re2/perl_groups.cc.o
[ 10%] Building CXX object CMakeFiles/re2.dir/re2/prefilter.cc.o
[ 11%] Building CXX object CMakeFiles/re2.dir/re2/prefilter_tree.cc.o
[ 12%] Building CXX object CMakeFiles/re2.dir/re2/prog.cc.o
[ 13%] Building CXX object CMakeFiles/re2.dir/re2/re2.cc.o
[ 14%] Building CXX object CMakeFiles/re2.dir/re2/regexp.cc.o
[ 15%] Building CXX object CMakeFiles/re2.dir/re2/set.cc.o
[ 16%] Building CXX object CMakeFiles/re2.dir/re2/simplify.cc.o
[ 17%] Building CXX object CMakeFiles/re2.dir/re2/stringpiece.cc.o
[ 18%] Building CXX object CMakeFiles/re2.dir/re2/tostring.cc.o
[ 20%] Building CXX object CMakeFiles/re2.dir/re2/unicode_casefold.cc.o
[ 21%] Building CXX object CMakeFiles/re2.dir/re2/unicode_groups.cc.o
[ 22%] Building CXX object CMakeFiles/re2.dir/util/rune.cc.o
[ 23%] Building CXX object CMakeFiles/re2.dir/util/strutil.cc.o
[ 24%] Linking CXX static library libre2.a
[ 24%] Built target re2
[ 25%] Building CXX object CMakeFiles/testing.dir/re2/testing/backtrack.cc.o
[ 26%] Building CXX object CMakeFiles/testing.dir/re2/testing/dump.cc.o
[ 27%] Building CXX object CMakeFiles/testing.dir/re2/testing/exhaustive_tester.cc.o
[ 28%] Building CXX object CMakeFiles/testing.dir/re2/testing/null_walker.cc.o
[ 29%] Building CXX object CMakeFiles/testing.dir/re2/testing/regexp_generator.cc.o
[ 30%] Building CXX object CMakeFiles/testing.dir/re2/testing/string_generator.cc.o
[ 31%] Building CXX object CMakeFiles/testing.dir/re2/testing/tester.cc.o
[ 32%] Building CXX object CMakeFiles/testing.dir/util/pcre.cc.o
[ 33%] Linking CXX static library libtesting.a
[ 33%] Built target testing
[ 35%] Building CXX object CMakeFiles/compile_test.dir/re2/testing/compile_test.cc.o
[ 35%] Building CXX object CMakeFiles/charclass_test.dir/re2/testing/charclass_test.cc.o
[ 36%] Building CXX object CMakeFiles/charclass_test.dir/util/test.cc.o
[ 37%] Linking CXX executable charclass_test
[ 37%] Built target charclass_test
[ 38%] Building CXX object CMakeFiles/filtered_re2_test.dir/re2/testing/filtered_re2_test.cc.o
[ 40%] Building CXX object CMakeFiles/compile_test.dir/util/test.cc.o
[ 41%] Linking CXX executable compile_test
[ 41%] Built target compile_test
[ 42%] Building CXX object CMakeFiles/mimics_pcre_test.dir/re2/testing/mimics_pcre_test.cc.o
[ 43%] Building CXX object CMakeFiles/mimics_pcre_test.dir/util/test.cc.o
[ 44%] Linking CXX executable mimics_pcre_test
[ 45%] Building CXX object CMakeFiles/filtered_re2_test.dir/util/test.cc.o
[ 45%] Built target mimics_pcre_test
[ 46%] Building CXX object CMakeFiles/parse_test.dir/re2/testing/parse_test.cc.o
[ 47%] Linking CXX executable filtered_re2_test
[ 48%] Building CXX object CMakeFiles/parse_test.dir/util/test.cc.o
[ 49%] Linking CXX executable parse_test
[ 49%] Built target parse_test

-- stderr output is:
/usr/bin/ld: BFD (GNU Binutils for Ubuntu) 2.38 internal error, aborting at ../../bfd/merge.c:939 in _bfd_merged_section_offset

/usr/bin/ld: Merci de rapporter cette anomalie.

collect2: erreur: ld a retourné le statut de sortie 1
make[5]: *** [CMakeFiles/filtered_re2_test.dir/build.make:115 : filtered_re2_test] Erreur 1
make[5]: *** Suppression du fichier « filtered_re2_test »
make[4]: *** [CMakeFiles/Makefile2:234 : CMakeFiles/filtered_re2_test.dir/all] Erreur 2
make[4]: *** Attente des tâches non terminées....
make[3]: *** [Makefile:136 : all] Erreur 2

CMake Error at /tmp/Rtmp5tTRmH/filedab020a0561d/re2_ep-prefix/src/re2_ep-stamp/re2_ep-build-RELEASE.cmake:47 (message):
  Stopping after outputting logs.


make[2]: *** [CMakeFiles/re2_ep.dir/build.make:86 : re2_ep-prefix/src/re2_ep-stamp/re2_ep-build] Erreur 1
make[1]: *** [CMakeFiles/Makefile2:1099 : CMakeFiles/re2_ep.dir/all] Erreur 2
gmake: *** [Makefile:146 : all] Erreur 2
**** Error building Arrow C++.  
------------------------- NOTE ---------------------------
There was an issue preparing the Arrow C++ libraries.
See https://arrow.apache.org/docs/r/articles/install.html
---------------------------------------------------------
ERROR: configuration failed for package ‘arrow’
* removing ‘/home/tdhock/lib/R/library/arrow’
* restoring previous ‘/home/tdhock/lib/R/library/arrow’
Message d'avis :
Dans install.packages("~/arrow_12/", repos = NULL) :
  l'installation du package ‘/home/tdhock/arrow_12/’ a eu un statut de sortie non nul
> Sys.which("ld")
           ld 
"/usr/bin/ld" 
```

The above failed, but it seems like even if it does compile something,
it will probably not have the `-march=core2` flag that I want, how to
tell cmake to use that? I tried looking for instructions about how to
add that flag to the g++ command lines used for building libarrow C++
but I was not able to find
instructions. https://arrow.apache.org/docs/developers/cpp/building.html
and https://arrow.apache.org/docs/r/articles/install.html

Below we try to install libarrow from source.

```
(base) tdhock@tdhock-MacBook:~/arrow/cpp/build(main)$ cmake .. --preset ninja-debug-minimal -DCMAKE_INSTALL_PREFIX=/usr/local
Preset CMake variables:

  ARROW_BUILD_INTEGRATION="OFF"
  ARROW_BUILD_STATIC="OFF"
  ARROW_BUILD_TESTS="OFF"
  ARROW_EXTRA_ERROR_CONTEXT="ON"
  ARROW_WITH_RE2="OFF"
  ARROW_WITH_UTF8PROC="OFF"
  CMAKE_BUILD_TYPE="Debug"

-- Building using CMake version: 3.22.1
-- Arrow version: 13.0.0 (full: '13.0.0-SNAPSHOT')
-- Arrow SO version: 1300 (full: 1300.0.0)
-- clang-tidy 14 not found
-- clang-format 14 not found
-- Could NOT find ClangTools (missing: CLANG_FORMAT_BIN CLANG_TIDY_BIN) 
-- infer not found
-- Found cpplint executable at /home/tdhock/arrow/cpp/build-support/cpplint.py
-- System processor: x86_64
-- Arrow build warning level: CHECKIN
-- Using ld linker
-- Build Type: DEBUG
-- Using CONDA approach to find dependencies
-- Using CONDA_PREFIX for ARROW_PACKAGE_PREFIX: /home/tdhock/miniconda3
-- Setting (unset) dependency *_ROOT variables: /home/tdhock/miniconda3
-- ARROW_ABSL_BUILD_VERSION: 20211102.0
-- ARROW_ABSL_BUILD_SHA256_CHECKSUM: dcf71b9cba8dc0ca9940c4b316a0c796be8fab42b070bb6b7cab62b48f0e66c4
-- ARROW_AWS_C_AUTH_BUILD_VERSION: v0.6.22
-- ARROW_AWS_C_AUTH_BUILD_SHA256_CHECKSUM: 691a6b4418afcd3dc141351b6ad33fccd8e3ff84df0e9e045b42295d284ee14c
-- ARROW_AWS_C_CAL_BUILD_VERSION: v0.5.20
-- ARROW_AWS_C_CAL_BUILD_SHA256_CHECKSUM: acc352359bd06f8597415c366cf4ec4f00d0b0da92d637039a73323dd55b6cd0
-- ARROW_AWS_C_COMMON_BUILD_VERSION: v0.8.9
-- ARROW_AWS_C_COMMON_BUILD_SHA256_CHECKSUM: 2f3fbaf7c38eae5a00e2a816d09b81177f93529ae8ba1b82dc8f31407565327a
-- ARROW_AWS_C_COMPRESSION_BUILD_VERSION: v0.2.16
-- ARROW_AWS_C_COMPRESSION_BUILD_SHA256_CHECKSUM: 044b1dbbca431a07bde8255ef9ec443c300fc60d4c9408d4b862f65e496687f4
-- ARROW_AWS_C_EVENT_STREAM_BUILD_VERSION: v0.2.18
-- ARROW_AWS_C_EVENT_STREAM_BUILD_SHA256_CHECKSUM: 310ca617f713bf664e4c7485a3d42c1fb57813abd0107e49790d107def7cde4f
-- ARROW_AWS_C_HTTP_BUILD_VERSION: v0.7.3
-- ARROW_AWS_C_HTTP_BUILD_SHA256_CHECKSUM: 07e16c6bf5eba6f0dea96b6f55eae312a7c95b736f4d2e4a210000f45d8265ae
-- ARROW_AWS_C_IO_BUILD_VERSION: v0.13.14
-- ARROW_AWS_C_IO_BUILD_SHA256_CHECKSUM: 12b66510c3d9a4f7e9b714e9cfab2a5bf835f8b9ce2f909d20ae2a2128608c71
-- ARROW_AWS_C_MQTT_BUILD_VERSION: v0.8.4
-- ARROW_AWS_C_MQTT_BUILD_SHA256_CHECKSUM: 232eeac63e72883d460c686a09b98cdd811d24579affac47c5c3f696f956773f
-- ARROW_AWS_C_S3_BUILD_VERSION: v0.2.3
-- ARROW_AWS_C_S3_BUILD_SHA256_CHECKSUM: a00b3c9f319cd1c9aa2c3fa15098864df94b066dcba0deaccbb3caa952d902fe
-- ARROW_AWS_C_SDKUTILS_BUILD_VERSION: v0.1.6
-- ARROW_AWS_C_SDKUTILS_BUILD_SHA256_CHECKSUM: 8a2951344b2fb541eab1e9ca17c18a7fcbfd2aaff4cdd31d362d1fad96111b91
-- ARROW_AWS_CHECKSUMS_BUILD_VERSION: v0.1.13
-- ARROW_AWS_CHECKSUMS_BUILD_SHA256_CHECKSUM: 0f897686f1963253c5069a0e495b85c31635ba146cd3ac38cc2ea31eaf54694d
-- ARROW_AWS_CRT_CPP_BUILD_VERSION: v0.18.16
-- ARROW_AWS_CRT_CPP_BUILD_SHA256_CHECKSUM: 9e69bc1dc4b50871d1038aa9ff6ddeb4c9b28f7d6b5e5b1b69041ccf50a13483
-- ARROW_AWS_LC_BUILD_VERSION: v1.3.0
-- ARROW_AWS_LC_BUILD_SHA256_CHECKSUM: ae96a3567161552744fc0cae8b4d68ed88b1ec0f3d3c98700070115356da5a37
-- ARROW_AWSSDK_BUILD_VERSION: 1.10.55
-- ARROW_AWSSDK_BUILD_SHA256_CHECKSUM: 2d552fb1a84bef4a9b65e34aa7031851ed2aef5319e02cc6e4cb735c48aa30de
-- ARROW_BOOST_BUILD_VERSION: 1.81.0
-- ARROW_BOOST_BUILD_SHA256_CHECKSUM: 9e0ffae35528c35f90468997bc8d99500bf179cbae355415a89a600c38e13574
-- ARROW_BROTLI_BUILD_VERSION: v1.0.9
-- ARROW_BROTLI_BUILD_SHA256_CHECKSUM: f9e8d81d0405ba66d181529af42a3354f838c939095ff99930da6aa9cdf6fe46
-- ARROW_BZIP2_BUILD_VERSION: 1.0.8
-- ARROW_BZIP2_BUILD_SHA256_CHECKSUM: ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269
-- ARROW_CARES_BUILD_VERSION: 1.17.2
-- ARROW_CARES_BUILD_SHA256_CHECKSUM: 4803c844ce20ce510ef0eb83f8ea41fa24ecaae9d280c468c582d2bb25b3913d
-- ARROW_CRC32C_BUILD_VERSION: 1.1.2
-- ARROW_CRC32C_BUILD_SHA256_CHECKSUM: ac07840513072b7fcebda6e821068aa04889018f24e10e46181068fb214d7e56
-- ARROW_GBENCHMARK_BUILD_VERSION: v1.7.1
-- ARROW_GBENCHMARK_BUILD_SHA256_CHECKSUM: 6430e4092653380d9dc4ccb45a1e2dc9259d581f4866dc0759713126056bc1d7
-- ARROW_GFLAGS_BUILD_VERSION: v2.2.2
-- ARROW_GFLAGS_BUILD_SHA256_CHECKSUM: 34af2f15cf7367513b352bdcd2493ab14ce43692d2dcd9dfc499492966c64dcf
-- ARROW_GLOG_BUILD_VERSION: v0.5.0
-- ARROW_GLOG_BUILD_SHA256_CHECKSUM: eede71f28371bf39aa69b45de23b329d37214016e2055269b3b5e7cfd40b59f5
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_VERSION: v2.8.0
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_SHA256_CHECKSUM: 21fb441b5a670a18bb16b6826be8e0530888d0b94320847c538d46f5a54dddbc
-- ARROW_GRPC_BUILD_VERSION: v1.46.3
-- ARROW_GRPC_BUILD_SHA256_CHECKSUM: d6cbf22cb5007af71b61c6be316a79397469c58c82a942552a62e708bce60964
-- ARROW_GTEST_BUILD_VERSION: 1.11.0
-- ARROW_GTEST_BUILD_SHA256_CHECKSUM: b4870bf121ff7795ba20d20bcdd8627b8e088f2d1dab299a031c1034eddc93d5
-- ARROW_JEMALLOC_BUILD_VERSION: 5.3.0
-- ARROW_JEMALLOC_BUILD_SHA256_CHECKSUM: 2db82d1e7119df3e71b7640219b6dfe84789bc0537983c3b7ac4f7189aecfeaa
-- ARROW_LZ4_BUILD_VERSION: v1.9.4
-- ARROW_LZ4_BUILD_SHA256_CHECKSUM: 0b0e3aa07c8c063ddf40b082bdf7e37a1562bda40a0ff5272957f3e987e0e54b
-- ARROW_MIMALLOC_BUILD_VERSION: v2.0.6
-- ARROW_MIMALLOC_BUILD_SHA256_CHECKSUM: 9f05c94cc2b017ed13698834ac2a3567b6339a8bde27640df5a1581d49d05ce5
-- ARROW_NLOHMANN_JSON_BUILD_VERSION: v3.10.5
-- ARROW_NLOHMANN_JSON_BUILD_SHA256_CHECKSUM: 5daca6ca216495edf89d167f808d1d03c4a4d929cef7da5e10f135ae1540c7e4
-- ARROW_OPENTELEMETRY_BUILD_VERSION: v1.8.1
-- ARROW_OPENTELEMETRY_BUILD_SHA256_CHECKSUM: 3d640201594b07f08dade9cd1017bd0b59674daca26223b560b9bb6bf56264c2
-- ARROW_OPENTELEMETRY_PROTO_BUILD_VERSION: v0.17.0
-- ARROW_OPENTELEMETRY_PROTO_BUILD_SHA256_CHECKSUM: f269fbcb30e17b03caa1decd231ce826e59d7651c0f71c3b28eb5140b4bb5412
-- ARROW_ORC_BUILD_VERSION: 1.8.3
-- ARROW_ORC_BUILD_SHA256_CHECKSUM: a78678ec425c8129d63370cb8a9bacb54186aa66af1e2bec01ce92e7eaf72e20
-- ARROW_PROTOBUF_BUILD_VERSION: v21.3
-- ARROW_PROTOBUF_BUILD_SHA256_CHECKSUM: 2f723218f6cb709ae4cdc4fb5ed56a5951fc5d466f0128ce4c946b8c78c8c49f
-- ARROW_RAPIDJSON_BUILD_VERSION: 232389d4f1012dddec4ef84861face2d2ba85709
-- ARROW_RAPIDJSON_BUILD_SHA256_CHECKSUM: b9290a9a6d444c8e049bd589ab804e0ccf2b05dc5984a19ed5ae75d090064806
-- ARROW_RE2_BUILD_VERSION: 2022-06-01
-- ARROW_RE2_BUILD_SHA256_CHECKSUM: f89c61410a072e5cbcf8c27e3a778da7d6fd2f2b5b1445cd4f4508bee946ab0f
-- ARROW_SNAPPY_BUILD_VERSION: 1.1.9
-- ARROW_SNAPPY_BUILD_SHA256_CHECKSUM: 75c1fbb3d618dd3a0483bff0e26d0a92b495bbe5059c8b4f1c962b478b6e06e7
-- ARROW_SUBSTRAIT_BUILD_VERSION: v0.20.0
-- ARROW_SUBSTRAIT_BUILD_SHA256_CHECKSUM: 5ceaa559ccef29a7825b5e5d4b5e7eed384830294f08bec913feecdd903a94cf
-- ARROW_S2N_TLS_BUILD_VERSION: v1.3.35
-- ARROW_S2N_TLS_BUILD_SHA256_CHECKSUM: 9d32b26e6bfcc058d98248bf8fc231537e347395dd89cf62bb432b55c5da990d
-- ARROW_THRIFT_BUILD_VERSION: 0.16.0
-- ARROW_THRIFT_BUILD_SHA256_CHECKSUM: f460b5c1ca30d8918ff95ea3eb6291b3951cf518553566088f3f2be8981f6209
-- ARROW_UCX_BUILD_VERSION: 1.12.1
-- ARROW_UCX_BUILD_SHA256_CHECKSUM: 9bef31aed0e28bf1973d28d74d9ac4f8926c43ca3b7010bd22a084e164e31b71
-- ARROW_UTF8PROC_BUILD_VERSION: v2.7.0
-- ARROW_UTF8PROC_BUILD_SHA256_CHECKSUM: 4bb121e297293c0fd55f08f83afab6d35d48f0af4ecc07523ad8ec99aa2b12a1
-- ARROW_XSIMD_BUILD_VERSION: 9.0.1
-- ARROW_XSIMD_BUILD_SHA256_CHECKSUM: b1bb5f92167fd3a4f25749db0be7e61ed37e0a5d943490f3accdcd2cd2918cc0
-- ARROW_ZLIB_BUILD_VERSION: 1.2.13
-- ARROW_ZLIB_BUILD_SHA256_CHECKSUM: b3a24de97a8fdbc835b9833169501030b8977031bcb54b3b3ac13740f846ab30
-- ARROW_ZSTD_BUILD_VERSION: 1.5.5
-- ARROW_ZSTD_BUILD_SHA256_CHECKSUM: 9c4396cc829cfae319a6e2615202e82aad41372073482fce286fac78646d3ee4
-- Building without OpenSSL support. Minimum OpenSSL version 1.0.2 required.
-- Building jemalloc from source
-- xsimd found. Headers: /home/tdhock/miniconda3/envs/arrow/include
-- Found hdfs.h at: /home/tdhock/arrow/cpp/thirdparty/hadoop/include/hdfs.h
-- All bundled static libraries: jemalloc::jemalloc
-- CMAKE_C_FLAGS:   -Wall -Wno-conversion -Wno-sign-conversion -Wunused-result -fno-semantic-interposition -msse4.2 
-- CMAKE_CXX_FLAGS:  -Wno-noexcept-type  -fdiagnostics-color=always  -Wall -Wno-conversion -Wno-sign-conversion -Wunused-result -fno-semantic-interposition -msse4.2 
-- CMAKE_C_FLAGS_DEBUG: -g -Werror -O0 -ggdb
-- CMAKE_CXX_FLAGS_DEBUG: -g -Werror -O0 -ggdb
-- ---------------------------------------------------------------------
-- Arrow version:                                 13.0.0-SNAPSHOT
-- 
-- Build configuration summary:
--   Generator: Ninja
--   Build type: DEBUG
--   Source directory: /home/tdhock/arrow/cpp
--   Install prefix: /usr/local
-- 
-- Compile and link options:
-- 
--   ARROW_CXXFLAGS="" [default=""]
--       Compiler flags to append when compiling Arrow
--   ARROW_BUILD_STATIC=OFF [default=ON]
--       Build static libraries
--   ARROW_BUILD_SHARED=ON [default=ON]
--       Build shared libraries
--   ARROW_PACKAGE_KIND="" [default=""]
--       Arbitrary string that identifies the kind of package
--       (for informational purposes)
--   ARROW_GIT_ID=3948c426927514ab6d3165255b4717af9446e949 [default=""]
--       The Arrow git commit id (if any)
--   ARROW_GIT_DESCRIPTION=apache-arrow-13.0.0.dev-40-g3948c4269 [default=""]
--       The Arrow git commit description (if any)
--   ARROW_NO_DEPRECATED_API=OFF [default=OFF]
--       Exclude deprecated APIs from build
--   ARROW_POSITION_INDEPENDENT_CODE=ON [default=ON]
--       Whether to create position-independent target
--   ARROW_USE_CCACHE=ON [default=ON]
--       Use ccache when compiling (if available)
--   ARROW_USE_SCCACHE=ON [default=ON]
--       Use sccache when compiling (if available),
--       takes precedence over ccache if a storage backend is configured
--   ARROW_USE_LD_GOLD=OFF [default=OFF]
--       Use ld.gold for linking on Linux (if available)
--   ARROW_USE_PRECOMPILED_HEADERS=OFF [default=OFF]
--       Use precompiled headers when compiling
--   ARROW_SIMD_LEVEL=SSE4_2 [default=NONE|SSE4_2|AVX2|AVX512|NEON|SVE|SVE128|SVE256|SVE512|DEFAULT]
--       Compile-time SIMD optimization level
--   ARROW_RUNTIME_SIMD_LEVEL=MAX [default=NONE|SSE4_2|AVX2|AVX512|MAX]
--       Max runtime SIMD optimization level
--   ARROW_ALTIVEC=ON [default=ON]
--       Build with Altivec if compiler has support
--   ARROW_RPATH_ORIGIN=OFF [default=OFF]
--       Build Arrow libraries with RATH set to $ORIGIN
--   ARROW_INSTALL_NAME_RPATH=ON [default=ON]
--       Build Arrow libraries with install_name set to @rpath
--   ARROW_GGDB_DEBUG=ON [default=ON]
--       Pass -ggdb flag to debug builds
--   ARROW_WITH_MUSL=OFF [default=OFF]
--       Whether the system libc is musl or not
-- 
-- Test and benchmark options:
-- 
--   ARROW_BUILD_EXAMPLES=OFF [default=OFF]
--       Build the Arrow examples
--   ARROW_BUILD_TESTS=OFF [default=OFF]
--       Build the Arrow googletest unit tests
--   ARROW_ENABLE_TIMING_TESTS=ON [default=ON]
--       Enable timing-sensitive tests
--   ARROW_BUILD_INTEGRATION=OFF [default=OFF]
--       Build the Arrow integration test executables
--   ARROW_BUILD_BENCHMARKS=OFF [default=OFF]
--       Build the Arrow micro benchmarks
--   ARROW_BUILD_BENCHMARKS_REFERENCE=OFF [default=OFF]
--       Build the Arrow micro reference benchmarks
--   ARROW_BUILD_OPENMP_BENCHMARKS=OFF [default=OFF]
--       Build the Arrow benchmarks that rely on OpenMP
--   ARROW_BUILD_DETAILED_BENCHMARKS=OFF [default=OFF]
--       Build benchmarks that do a longer exploration of performance
--   ARROW_TEST_LINKAGE=shared [default=shared|static]
--       Linkage of Arrow libraries with unit tests executables.
--   ARROW_FUZZING=OFF [default=OFF]
--       Build Arrow Fuzzing executables
--   ARROW_LARGE_MEMORY_TESTS=OFF [default=OFF]
--       Enable unit tests which use large memory
-- 
-- Lint options:
-- 
--   ARROW_ONLY_LINT=OFF [default=OFF]
--       Only define the lint and check-format targets
--   ARROW_VERBOSE_LINT=OFF [default=OFF]
--       If off, 'quiet' flags will be passed to linting tools
--   ARROW_GENERATE_COVERAGE=OFF [default=OFF]
--       Build with C++ code coverage enabled
-- 
-- Checks options:
-- 
--   ARROW_TEST_MEMCHECK=OFF [default=OFF]
--       Run the test suite using valgrind --tool=memcheck
--   ARROW_USE_ASAN=OFF [default=OFF]
--       Enable Address Sanitizer checks
--   ARROW_USE_TSAN=OFF [default=OFF]
--       Enable Thread Sanitizer checks
--   ARROW_USE_UBSAN=OFF [default=OFF]
--       Enable Undefined Behavior sanitizer checks
-- 
-- Project component options:
-- 
--   ARROW_BUILD_UTILITIES=OFF [default=OFF]
--       Build Arrow commandline utilities
--   ARROW_COMPUTE=OFF [default=OFF]
--       Build all Arrow Compute kernels
--   ARROW_CSV=OFF [default=OFF]
--       Build the Arrow CSV Parser Module
--   ARROW_CUDA=OFF [default=OFF]
--       Build the Arrow CUDA extensions (requires CUDA toolkit)
--   ARROW_DATASET=OFF [default=OFF]
--       Build the Arrow Dataset Modules
--   ARROW_FILESYSTEM=OFF [default=OFF]
--       Build the Arrow Filesystem Layer
--   ARROW_FLIGHT=OFF [default=OFF]
--       Build the Arrow Flight RPC System (requires GRPC, Protocol Buffers)
--   ARROW_FLIGHT_SQL=OFF [default=OFF]
--       Build the Arrow Flight SQL extension
--   ARROW_GANDIVA=OFF [default=OFF]
--       Build the Gandiva libraries
--   ARROW_GCS=OFF [default=OFF]
--       Build Arrow with GCS support (requires the GCloud SDK for C++)
--   ARROW_HDFS=OFF [default=OFF]
--       Build the Arrow HDFS bridge
--   ARROW_IPC=ON [default=ON]
--       Build the Arrow IPC extensions
--   ARROW_JEMALLOC=ON [default=ON]
--       Build the Arrow jemalloc-based allocator
--   ARROW_JSON=OFF [default=OFF]
--       Build Arrow with JSON support (requires RapidJSON)
--   ARROW_MIMALLOC=OFF [default=OFF]
--       Build the Arrow mimalloc-based allocator
--   ARROW_PARQUET=OFF [default=OFF]
--       Build the Parquet libraries
--   ARROW_ORC=OFF [default=OFF]
--       Build the Arrow ORC adapter
--   ARROW_PYTHON=OFF [default=OFF]
--       Build some components needed by PyArrow.
--       (This is a deprecated option. Use CMake presets instead.)
--   ARROW_S3=OFF [default=OFF]
--       Build Arrow with S3 support (requires the AWS SDK for C++)
--   ARROW_SKYHOOK=OFF [default=OFF]
--       Build the Skyhook libraries
--   ARROW_SUBSTRAIT=OFF [default=OFF]
--       Build the Arrow Substrait Consumer Module
--   ARROW_ACERO=OFF [default=OFF]
--       Build the Arrow Acero Engine Module
--   ARROW_TENSORFLOW=OFF [default=OFF]
--       Build Arrow with TensorFlow support enabled
--   ARROW_TESTING=OFF [default=OFF]
--       Build the Arrow testing libraries
-- 
-- Thirdparty toolchain options:
-- 
--   ARROW_DEPENDENCY_SOURCE=CONDA [default=AUTO|BUNDLED|SYSTEM|CONDA|VCPKG|BREW]
--       Method to use for acquiring arrow's build dependencies
--   ARROW_VERBOSE_THIRDPARTY_BUILD=OFF [default=OFF]
--       Show output from ExternalProjects rather than just logging to files
--   ARROW_DEPENDENCY_USE_SHARED=ON [default=ON]
--       Link to shared libraries
--   ARROW_BOOST_USE_SHARED=ON [default=ON]
--       Rely on Boost shared libraries where relevant
--   ARROW_BROTLI_USE_SHARED=ON [default=ON]
--       Rely on Brotli shared libraries where relevant
--   ARROW_BZ2_USE_SHARED=ON [default=ON]
--       Rely on Bz2 shared libraries where relevant
--   ARROW_GFLAGS_USE_SHARED=ON [default=ON]
--       Rely on GFlags shared libraries where relevant
--   ARROW_GRPC_USE_SHARED=ON [default=ON]
--       Rely on gRPC shared libraries where relevant
--   ARROW_JEMALLOC_USE_SHARED=OFF [default=ON]
--       Rely on jemalloc shared libraries where relevant
--   ARROW_LZ4_USE_SHARED=ON [default=ON]
--       Rely on lz4 shared libraries where relevant
--   ARROW_OPENSSL_USE_SHARED=ON [default=ON]
--       Rely on OpenSSL shared libraries where relevant
--   ARROW_PROTOBUF_USE_SHARED=ON [default=ON]
--       Rely on Protocol Buffers shared libraries where relevant
--   ARROW_SNAPPY_USE_SHARED=ON [default=ON]
--       Rely on snappy shared libraries where relevant
--   ARROW_THRIFT_USE_SHARED=ON [default=ON]
--       Rely on thrift shared libraries where relevant
--   ARROW_UTF8PROC_USE_SHARED=ON [default=ON]
--       Rely on utf8proc shared libraries where relevant
--   ARROW_ZSTD_USE_SHARED=ON [default=ON]
--       Rely on zstd shared libraries where relevant
--   ARROW_USE_GLOG=OFF [default=OFF]
--       Build libraries with glog support for pluggable logging
--   ARROW_WITH_BACKTRACE=ON [default=ON]
--       Build with backtrace support
--   ARROW_WITH_OPENTELEMETRY=OFF [default=OFF]
--       Build libraries with OpenTelemetry support for distributed tracing
--   ARROW_WITH_BROTLI=OFF [default=OFF]
--       Build with Brotli compression
--   ARROW_WITH_BZ2=OFF [default=OFF]
--       Build with BZ2 compression
--   ARROW_WITH_LZ4=OFF [default=OFF]
--       Build with lz4 compression
--   ARROW_WITH_SNAPPY=OFF [default=OFF]
--       Build with Snappy compression
--   ARROW_WITH_ZLIB=OFF [default=OFF]
--       Build with zlib compression
--   ARROW_WITH_ZSTD=OFF [default=OFF]
--       Build with zstd compression
--   ARROW_WITH_UCX=OFF [default=OFF]
--       Build with UCX transport for Arrow Flight
--       (only used if ARROW_FLIGHT is ON)
--   ARROW_WITH_UTF8PROC=OFF [default=ON]
--       Build with support for Unicode properties using the utf8proc library
--       (only used if ARROW_COMPUTE is ON or ARROW_GANDIVA is ON)
--   ARROW_WITH_RE2=OFF [default=ON]
--       Build with support for regular expressions using the re2 library
--       (only used if ARROW_COMPUTE or ARROW_GANDIVA is ON)
-- 
-- Parquet options:
-- 
--   PARQUET_MINIMAL_DEPENDENCY=OFF [default=OFF]
--       Depend only on Thirdparty headers to build libparquet.
--       Always OFF if building binaries
--   PARQUET_BUILD_EXECUTABLES=OFF [default=OFF]
--       Build the Parquet executable CLI tools. Requires static libraries to be built.
--   PARQUET_BUILD_EXAMPLES=OFF [default=OFF]
--       Build the Parquet examples. Requires static libraries to be built.
--   PARQUET_REQUIRE_ENCRYPTION=OFF [default=OFF]
--       Build support for encryption. Fail if OpenSSL is not found
-- 
-- Gandiva options:
-- 
--   ARROW_GANDIVA_STATIC_LIBSTDCPP=OFF [default=OFF]
--       Include -static-libstdc++ -static-libgcc when linking with
--       Gandiva static libraries
--   ARROW_GANDIVA_PC_CXX_FLAGS="" [default=""]
--       Compiler flags to append when pre-compiling Gandiva operations
-- 
-- Advanced developer options:
-- 
--   ARROW_EXTRA_ERROR_CONTEXT=ON [default=OFF]
--       Compile with extra error context (line numbers, code)
--   ARROW_OPTIONAL_INSTALL=OFF [default=OFF]
--       If enabled install ONLY targets that have already been built. Please be
--       advised that if this is enabled 'install' will fail silently on components
--       that have not been built
--   ARROW_GDB_INSTALL_DIR="" [default=""]
--       Use a custom install directory for GDB plugin.
--       In general, you don't need to specify this because the default
--       (CMAKE_INSTALL_FULL_BINDIR on Windows, CMAKE_INSTALL_FULL_LIBDIR otherwise)
--       is reasonable.
--   Outputting build configuration summary to /home/tdhock/arrow/cpp/build/cmake_summary.json
-- Configuring done
-- Generating done
-- Build files have been written to: /home/tdhock/arrow/cpp/build
(base) tdhock@tdhock-MacBook:~/arrow/cpp/build(main)$ cmake --build .
ninja: no work to do.
(base) tdhock@tdhock-MacBook:~/arrow/cpp/build(main)$ cmake --install .
-- Install configuration: "DEBUG"
CMake Error at cmake_install.cmake:46 (file):
  file cannot create directory: /usr/local/include/arrow/util.  Maybe need
  administrative privileges.


(base) tdhock@tdhock-MacBook:~/arrow/cpp/build(main)$ ninja clean
[1/1] Cleaning all built files...
Cleaning... 186 files.
(base) tdhock@tdhock-MacBook:~/arrow/cpp/build(main)$ cmake --build .
[1/183] Creating directories for 'jemalloc_ep'
[2/183] Performing download step (download, verify and extract) for 'jemalloc_ep'
[3/183] No update step for 'jemalloc_ep'
[4/183] Performing patch step for 'jemalloc_ep'
[5/183] Performing configure step for 'jemalloc_ep'
...
[39/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/builder.cc.o
FAILED: src/arrow/CMakeFiles/arrow_objlib.dir/builder.cc.o 
/usr/bin/c++ -DARROW_EXPORTING -DARROW_EXTRA_ERROR_CONTEXT -DARROW_HAVE_RUNTIME_AVX2 -DARROW_HAVE_RUNTIME_AVX512 -DARROW_HAVE_RUNTIME_BMI2 -DARROW_HAVE_RUNTIME_SSE4_2 -DARROW_HAVE_SSE4_2 -DARROW_WITH_BACKTRACE -DARROW_WITH_TIMING_TESTS -DURI_STATIC_BUILD -I/home/tdhock/arrow/cpp/build/src -I/home/tdhock/arrow/cpp/src -I/home/tdhock/arrow/cpp/src/generated -isystem /home/tdhock/arrow/cpp/thirdparty/flatbuffers/include -isystem /home/tdhock/arrow/cpp/thirdparty/hadoop/include -isystem /home/tdhock/miniconda3/envs/arrow/include -isystem /home/tdhock/arrow/cpp/build/jemalloc_ep-prefix/src -Wno-noexcept-type  -fdiagnostics-color=always  -Wall -Wno-conversion -Wno-sign-conversion -Wunused-result -fno-semantic-interposition -msse4.2  -g -Werror -O0 -ggdb -fPIC -std=c++17 -MD -MT src/arrow/CMakeFiles/arrow_objlib.dir/builder.cc.o -MF src/arrow/CMakeFiles/arrow_objlib.dir/builder.cc.o.d -o src/arrow/CMakeFiles/arrow_objlib.dir/builder.cc.o -c /home/tdhock/arrow/cpp/src/arrow/builder.cc
during RTL pass: expand
In file included from /home/tdhock/arrow/cpp/src/arrow/array/builder_dict.h:36,
                 from /home/tdhock/arrow/cpp/src/arrow/builder.h:26,
                 from /home/tdhock/arrow/cpp/src/arrow/builder.cc:18:
/home/tdhock/arrow/cpp/src/arrow/util/bit_block_counter.h: In function ‘arrow::Status arrow::internal::VisitBitBlocks(const uint8_t*, int64_t, int64_t, VisitNotNull&&, VisitNull&&) [with VisitNotNull = arrow::internal::DictionaryBuilderBase<arrow::AdaptiveIntBuilder, arrow::Date32Type>::AppendArraySliceImpl<long unsigned int>(const ArrayType&, const arrow::ArraySpan&, int64_t, int64_t)::<lambda(int64_t)>; VisitNull = arrow::internal::DictionaryBuilderBase<arrow::AdaptiveIntBuilder, arrow::Date32Type>::AppendArraySliceImpl<long unsigned int>(const ArrayType&, const arrow::ArraySpan&, int64_t, int64_t)::<lambda()>]’:
/home/tdhock/arrow/cpp/src/arrow/util/bit_block_counter.h:428:15: internal compiler error: Erreur de segmentation
  428 | static Status VisitBitBlocks(const uint8_t* bitmap, int64_t offset, int64_t length,
      |               ^~~~~~~~~~~~~~
0x7f3715a0951f ???
	./signal/../sysdeps/unix/sysv/linux/x86_64/libc_sigaction.c:0
0x7f37159f0d8f __libc_start_call_main
	../sysdeps/nptl/libc_start_call_main.h:58
0x7f37159f0e3f __libc_start_main_impl
	../csu/libc-start.c:392
Please submit a full bug report,
with preprocessed source if appropriate.
Please include the complete backtrace with any bug report.
See <file:///usr/share/doc/gcc-11/README.Bugs> for instructions.
[40/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/record_batch.cc.o
[41/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/pretty_print.cc.o
ninja: build stopped: subcommand failed.
(base) tdhock@tdhock-MacBook:~/arrow/cpp/build(main)$ ninja clean
[1/1] Cleaning all built files...
Cleaning... 42 files.
(base) tdhock@tdhock-MacBook:~/arrow/cpp/build(main)$ conda activate arrow
(arrow) tdhock@tdhock-MacBook:~/arrow/cpp/build(main)$ cmake --build .
[1/183] Creating directories for 'jemalloc_ep'
[2/183] Performing download step (download, verify and extract) for 'jemalloc_ep'
[3/183] No update step for 'jemalloc_ep'
[4/183] Performing patch step for 'jemalloc_ep'
...
[11/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/array_base.cc.o
FAILED: src/arrow/CMakeFiles/arrow_objlib.dir/array/array_base.cc.o 
/usr/bin/c++ -DARROW_EXPORTING -DARROW_EXTRA_ERROR_CONTEXT -DARROW_HAVE_RUNTIME_AVX2 -DARROW_HAVE_RUNTIME_AVX512 -DARROW_HAVE_RUNTIME_BMI2 -DARROW_HAVE_RUNTIME_SSE4_2 -DARROW_HAVE_SSE4_2 -DARROW_WITH_BACKTRACE -DARROW_WITH_TIMING_TESTS -DURI_STATIC_BUILD -I/home/tdhock/arrow/cpp/build/src -I/home/tdhock/arrow/cpp/src -I/home/tdhock/arrow/cpp/src/generated -isystem /home/tdhock/arrow/cpp/thirdparty/flatbuffers/include -isystem /home/tdhock/arrow/cpp/thirdparty/hadoop/include -isystem /home/tdhock/miniconda3/envs/arrow/include -isystem /home/tdhock/arrow/cpp/build/jemalloc_ep-prefix/src -Wno-noexcept-type  -fdiagnostics-color=always  -Wall -Wno-conversion -Wno-sign-conversion -Wunused-result -fno-semantic-interposition -msse4.2  -g -Werror -O0 -ggdb -fPIC -std=c++17 -MD -MT src/arrow/CMakeFiles/arrow_objlib.dir/array/array_base.cc.o -MF src/arrow/CMakeFiles/arrow_objlib.dir/array/array_base.cc.o.d -o src/arrow/CMakeFiles/arrow_objlib.dir/array/array_base.cc.o -c /home/tdhock/arrow/cpp/src/arrow/array/array_base.cc
In file included from /home/tdhock/arrow/cpp/src/arrow/array/array_base.cc:36:
/home/tdhock/arrow/cpp/src/arrow/scalar.h: In member function ‘arrow::Status arrow::MakeScalarImpl<ValueRef>::Visit(const T&) [with T = arrow::HalfFloatType; ScalarType = arrow::HalfFloatScalar; ValueType = short unsigned int; Enable = void; ValueRef = int&&]’:
/home/tdhock/arrow/cpp/src/arrow/scalar.h:706:10: internal compiler error: Erreur de segmentation
  706 |   Status Visit(const T& t) {
      |          ^~~~~
0x7efc69ff151f ???
	./signal/../sysdeps/unix/sysv/linux/x86_64/libc_sigaction.c:0
0x7efc69fd8d8f __libc_start_call_main
	../sysdeps/nptl/libc_start_call_main.h:58
0x7efc69fd8e3f __libc_start_main_impl
	../csu/libc-start.c:392
Please submit a full bug report,
with preprocessed source if appropriate.
Please include the complete backtrace with any bug report.
See <file:///usr/share/doc/gcc-11/README.Bugs> for instructions.
[12/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/array_nested.cc.o
[13/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/array_dict.cc.o
ninja: build stopped: subcommand failed.
```

Need to tell cmake to use `$HOME/bin/c++` instead of `/usr/bin/c++` how?

```
(arrow) tdhock@tdhock-MacBook:~/arrow/cpp/build(main)$ CC=$HOME/bin/gcc CXX=$HOME/bin/g++ cmake .. --preset ninja-debug-minimal -DCMAKE_INSTALL_PREFIX=$HOME -DARROW_CXXFLAGS=-march=core2
Preset CMake variables:

  ARROW_BUILD_INTEGRATION="OFF"
  ARROW_BUILD_STATIC="OFF"
  ARROW_BUILD_TESTS="OFF"
  ARROW_EXTRA_ERROR_CONTEXT="ON"
  ARROW_WITH_RE2="OFF"
  ARROW_WITH_UTF8PROC="OFF"
  CMAKE_BUILD_TYPE="Debug"

-- Building using CMake version: 3.22.1
-- Arrow version: 13.0.0 (full: '13.0.0-SNAPSHOT')
-- Arrow SO version: 1300 (full: 1300.0.0)
-- clang-tidy 14 not found
-- clang-format 14 not found
-- Could NOT find ClangTools (missing: CLANG_FORMAT_BIN CLANG_TIDY_BIN) 
-- infer not found
-- Found cpplint executable at /home/tdhock/arrow/cpp/build-support/cpplint.py
-- System processor: x86_64
-- Arrow build warning level: CHECKIN
-- Using ld linker
-- Build Type: DEBUG
-- Using CONDA approach to find dependencies
-- Using CONDA_PREFIX for ARROW_PACKAGE_PREFIX: /home/tdhock/miniconda3/envs/arrow
-- Setting (unset) dependency *_ROOT variables: /home/tdhock/miniconda3/envs/arrow
-- ARROW_ABSL_BUILD_VERSION: 20211102.0
-- ARROW_ABSL_BUILD_SHA256_CHECKSUM: dcf71b9cba8dc0ca9940c4b316a0c796be8fab42b070bb6b7cab62b48f0e66c4
-- ARROW_AWS_C_AUTH_BUILD_VERSION: v0.6.22
-- ARROW_AWS_C_AUTH_BUILD_SHA256_CHECKSUM: 691a6b4418afcd3dc141351b6ad33fccd8e3ff84df0e9e045b42295d284ee14c
-- ARROW_AWS_C_CAL_BUILD_VERSION: v0.5.20
-- ARROW_AWS_C_CAL_BUILD_SHA256_CHECKSUM: acc352359bd06f8597415c366cf4ec4f00d0b0da92d637039a73323dd55b6cd0
-- ARROW_AWS_C_COMMON_BUILD_VERSION: v0.8.9
-- ARROW_AWS_C_COMMON_BUILD_SHA256_CHECKSUM: 2f3fbaf7c38eae5a00e2a816d09b81177f93529ae8ba1b82dc8f31407565327a
-- ARROW_AWS_C_COMPRESSION_BUILD_VERSION: v0.2.16
-- ARROW_AWS_C_COMPRESSION_BUILD_SHA256_CHECKSUM: 044b1dbbca431a07bde8255ef9ec443c300fc60d4c9408d4b862f65e496687f4
-- ARROW_AWS_C_EVENT_STREAM_BUILD_VERSION: v0.2.18
-- ARROW_AWS_C_EVENT_STREAM_BUILD_SHA256_CHECKSUM: 310ca617f713bf664e4c7485a3d42c1fb57813abd0107e49790d107def7cde4f
-- ARROW_AWS_C_HTTP_BUILD_VERSION: v0.7.3
-- ARROW_AWS_C_HTTP_BUILD_SHA256_CHECKSUM: 07e16c6bf5eba6f0dea96b6f55eae312a7c95b736f4d2e4a210000f45d8265ae
-- ARROW_AWS_C_IO_BUILD_VERSION: v0.13.14
-- ARROW_AWS_C_IO_BUILD_SHA256_CHECKSUM: 12b66510c3d9a4f7e9b714e9cfab2a5bf835f8b9ce2f909d20ae2a2128608c71
-- ARROW_AWS_C_MQTT_BUILD_VERSION: v0.8.4
-- ARROW_AWS_C_MQTT_BUILD_SHA256_CHECKSUM: 232eeac63e72883d460c686a09b98cdd811d24579affac47c5c3f696f956773f
-- ARROW_AWS_C_S3_BUILD_VERSION: v0.2.3
-- ARROW_AWS_C_S3_BUILD_SHA256_CHECKSUM: a00b3c9f319cd1c9aa2c3fa15098864df94b066dcba0deaccbb3caa952d902fe
-- ARROW_AWS_C_SDKUTILS_BUILD_VERSION: v0.1.6
-- ARROW_AWS_C_SDKUTILS_BUILD_SHA256_CHECKSUM: 8a2951344b2fb541eab1e9ca17c18a7fcbfd2aaff4cdd31d362d1fad96111b91
-- ARROW_AWS_CHECKSUMS_BUILD_VERSION: v0.1.13
-- ARROW_AWS_CHECKSUMS_BUILD_SHA256_CHECKSUM: 0f897686f1963253c5069a0e495b85c31635ba146cd3ac38cc2ea31eaf54694d
-- ARROW_AWS_CRT_CPP_BUILD_VERSION: v0.18.16
-- ARROW_AWS_CRT_CPP_BUILD_SHA256_CHECKSUM: 9e69bc1dc4b50871d1038aa9ff6ddeb4c9b28f7d6b5e5b1b69041ccf50a13483
-- ARROW_AWS_LC_BUILD_VERSION: v1.3.0
-- ARROW_AWS_LC_BUILD_SHA256_CHECKSUM: ae96a3567161552744fc0cae8b4d68ed88b1ec0f3d3c98700070115356da5a37
-- ARROW_AWSSDK_BUILD_VERSION: 1.10.55
-- ARROW_AWSSDK_BUILD_SHA256_CHECKSUM: 2d552fb1a84bef4a9b65e34aa7031851ed2aef5319e02cc6e4cb735c48aa30de
-- ARROW_BOOST_BUILD_VERSION: 1.81.0
-- ARROW_BOOST_BUILD_SHA256_CHECKSUM: 9e0ffae35528c35f90468997bc8d99500bf179cbae355415a89a600c38e13574
-- ARROW_BROTLI_BUILD_VERSION: v1.0.9
-- ARROW_BROTLI_BUILD_SHA256_CHECKSUM: f9e8d81d0405ba66d181529af42a3354f838c939095ff99930da6aa9cdf6fe46
-- ARROW_BZIP2_BUILD_VERSION: 1.0.8
-- ARROW_BZIP2_BUILD_SHA256_CHECKSUM: ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269
-- ARROW_CARES_BUILD_VERSION: 1.17.2
-- ARROW_CARES_BUILD_SHA256_CHECKSUM: 4803c844ce20ce510ef0eb83f8ea41fa24ecaae9d280c468c582d2bb25b3913d
-- ARROW_CRC32C_BUILD_VERSION: 1.1.2
-- ARROW_CRC32C_BUILD_SHA256_CHECKSUM: ac07840513072b7fcebda6e821068aa04889018f24e10e46181068fb214d7e56
-- ARROW_GBENCHMARK_BUILD_VERSION: v1.7.1
-- ARROW_GBENCHMARK_BUILD_SHA256_CHECKSUM: 6430e4092653380d9dc4ccb45a1e2dc9259d581f4866dc0759713126056bc1d7
-- ARROW_GFLAGS_BUILD_VERSION: v2.2.2
-- ARROW_GFLAGS_BUILD_SHA256_CHECKSUM: 34af2f15cf7367513b352bdcd2493ab14ce43692d2dcd9dfc499492966c64dcf
-- ARROW_GLOG_BUILD_VERSION: v0.5.0
-- ARROW_GLOG_BUILD_SHA256_CHECKSUM: eede71f28371bf39aa69b45de23b329d37214016e2055269b3b5e7cfd40b59f5
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_VERSION: v2.8.0
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_SHA256_CHECKSUM: 21fb441b5a670a18bb16b6826be8e0530888d0b94320847c538d46f5a54dddbc
-- ARROW_GRPC_BUILD_VERSION: v1.46.3
-- ARROW_GRPC_BUILD_SHA256_CHECKSUM: d6cbf22cb5007af71b61c6be316a79397469c58c82a942552a62e708bce60964
-- ARROW_GTEST_BUILD_VERSION: 1.11.0
-- ARROW_GTEST_BUILD_SHA256_CHECKSUM: b4870bf121ff7795ba20d20bcdd8627b8e088f2d1dab299a031c1034eddc93d5
-- ARROW_JEMALLOC_BUILD_VERSION: 5.3.0
-- ARROW_JEMALLOC_BUILD_SHA256_CHECKSUM: 2db82d1e7119df3e71b7640219b6dfe84789bc0537983c3b7ac4f7189aecfeaa
-- ARROW_LZ4_BUILD_VERSION: v1.9.4
-- ARROW_LZ4_BUILD_SHA256_CHECKSUM: 0b0e3aa07c8c063ddf40b082bdf7e37a1562bda40a0ff5272957f3e987e0e54b
-- ARROW_MIMALLOC_BUILD_VERSION: v2.0.6
-- ARROW_MIMALLOC_BUILD_SHA256_CHECKSUM: 9f05c94cc2b017ed13698834ac2a3567b6339a8bde27640df5a1581d49d05ce5
-- ARROW_NLOHMANN_JSON_BUILD_VERSION: v3.10.5
-- ARROW_NLOHMANN_JSON_BUILD_SHA256_CHECKSUM: 5daca6ca216495edf89d167f808d1d03c4a4d929cef7da5e10f135ae1540c7e4
-- ARROW_OPENTELEMETRY_BUILD_VERSION: v1.8.1
-- ARROW_OPENTELEMETRY_BUILD_SHA256_CHECKSUM: 3d640201594b07f08dade9cd1017bd0b59674daca26223b560b9bb6bf56264c2
-- ARROW_OPENTELEMETRY_PROTO_BUILD_VERSION: v0.17.0
-- ARROW_OPENTELEMETRY_PROTO_BUILD_SHA256_CHECKSUM: f269fbcb30e17b03caa1decd231ce826e59d7651c0f71c3b28eb5140b4bb5412
-- ARROW_ORC_BUILD_VERSION: 1.8.3
-- ARROW_ORC_BUILD_SHA256_CHECKSUM: a78678ec425c8129d63370cb8a9bacb54186aa66af1e2bec01ce92e7eaf72e20
-- ARROW_PROTOBUF_BUILD_VERSION: v21.3
-- ARROW_PROTOBUF_BUILD_SHA256_CHECKSUM: 2f723218f6cb709ae4cdc4fb5ed56a5951fc5d466f0128ce4c946b8c78c8c49f
-- ARROW_RAPIDJSON_BUILD_VERSION: 232389d4f1012dddec4ef84861face2d2ba85709
-- ARROW_RAPIDJSON_BUILD_SHA256_CHECKSUM: b9290a9a6d444c8e049bd589ab804e0ccf2b05dc5984a19ed5ae75d090064806
-- ARROW_RE2_BUILD_VERSION: 2022-06-01
-- ARROW_RE2_BUILD_SHA256_CHECKSUM: f89c61410a072e5cbcf8c27e3a778da7d6fd2f2b5b1445cd4f4508bee946ab0f
-- ARROW_SNAPPY_BUILD_VERSION: 1.1.9
-- ARROW_SNAPPY_BUILD_SHA256_CHECKSUM: 75c1fbb3d618dd3a0483bff0e26d0a92b495bbe5059c8b4f1c962b478b6e06e7
-- ARROW_SUBSTRAIT_BUILD_VERSION: v0.20.0
-- ARROW_SUBSTRAIT_BUILD_SHA256_CHECKSUM: 5ceaa559ccef29a7825b5e5d4b5e7eed384830294f08bec913feecdd903a94cf
-- ARROW_S2N_TLS_BUILD_VERSION: v1.3.35
-- ARROW_S2N_TLS_BUILD_SHA256_CHECKSUM: 9d32b26e6bfcc058d98248bf8fc231537e347395dd89cf62bb432b55c5da990d
-- ARROW_THRIFT_BUILD_VERSION: 0.16.0
-- ARROW_THRIFT_BUILD_SHA256_CHECKSUM: f460b5c1ca30d8918ff95ea3eb6291b3951cf518553566088f3f2be8981f6209
-- ARROW_UCX_BUILD_VERSION: 1.12.1
-- ARROW_UCX_BUILD_SHA256_CHECKSUM: 9bef31aed0e28bf1973d28d74d9ac4f8926c43ca3b7010bd22a084e164e31b71
-- ARROW_UTF8PROC_BUILD_VERSION: v2.7.0
-- ARROW_UTF8PROC_BUILD_SHA256_CHECKSUM: 4bb121e297293c0fd55f08f83afab6d35d48f0af4ecc07523ad8ec99aa2b12a1
-- ARROW_XSIMD_BUILD_VERSION: 9.0.1
-- ARROW_XSIMD_BUILD_SHA256_CHECKSUM: b1bb5f92167fd3a4f25749db0be7e61ed37e0a5d943490f3accdcd2cd2918cc0
-- ARROW_ZLIB_BUILD_VERSION: 1.2.13
-- ARROW_ZLIB_BUILD_SHA256_CHECKSUM: b3a24de97a8fdbc835b9833169501030b8977031bcb54b3b3ac13740f846ab30
-- ARROW_ZSTD_BUILD_VERSION: 1.5.5
-- ARROW_ZSTD_BUILD_SHA256_CHECKSUM: 9c4396cc829cfae319a6e2615202e82aad41372073482fce286fac78646d3ee4
-- Building without OpenSSL support. Minimum OpenSSL version 1.0.2 required.
-- Building jemalloc from source
-- xsimd found. Headers: /home/tdhock/miniconda3/envs/arrow/include
-- Found hdfs.h at: /home/tdhock/arrow/cpp/thirdparty/hadoop/include/hdfs.h
-- All bundled static libraries: jemalloc::jemalloc
-- CMAKE_C_FLAGS:   -Wall -Wno-conversion -Wno-sign-conversion -Wunused-result -fno-semantic-interposition -msse4.2 -march=core2
-- CMAKE_CXX_FLAGS:  -Wno-noexcept-type  -fdiagnostics-color=always  -Wall -Wno-conversion -Wno-sign-conversion -Wunused-result -fno-semantic-interposition -msse4.2 -march=core2
-- CMAKE_C_FLAGS_DEBUG: -g -Werror -O0 -ggdb
-- CMAKE_CXX_FLAGS_DEBUG: -g -Werror -O0 -ggdb
-- ---------------------------------------------------------------------
-- Arrow version:                                 13.0.0-SNAPSHOT
-- 
-- Build configuration summary:
--   Generator: Ninja
--   Build type: DEBUG
--   Source directory: /home/tdhock/arrow/cpp
--   Install prefix: /home/tdhock
-- 
-- Compile and link options:
-- 
--   ARROW_CXXFLAGS=-march=core2 [default=""]
--       Compiler flags to append when compiling Arrow
--   ARROW_BUILD_STATIC=OFF [default=ON]
--       Build static libraries
--   ARROW_BUILD_SHARED=ON [default=ON]
--       Build shared libraries
--   ARROW_PACKAGE_KIND="" [default=""]
--       Arbitrary string that identifies the kind of package
--       (for informational purposes)
--   ARROW_GIT_ID=3948c426927514ab6d3165255b4717af9446e949 [default=""]
--       The Arrow git commit id (if any)
--   ARROW_GIT_DESCRIPTION=apache-arrow-13.0.0.dev-40-g3948c4269 [default=""]
--       The Arrow git commit description (if any)
--   ARROW_NO_DEPRECATED_API=OFF [default=OFF]
--       Exclude deprecated APIs from build
--   ARROW_POSITION_INDEPENDENT_CODE=ON [default=ON]
--       Whether to create position-independent target
--   ARROW_USE_CCACHE=ON [default=ON]
--       Use ccache when compiling (if available)
--   ARROW_USE_SCCACHE=ON [default=ON]
--       Use sccache when compiling (if available),
--       takes precedence over ccache if a storage backend is configured
--   ARROW_USE_LD_GOLD=OFF [default=OFF]
--       Use ld.gold for linking on Linux (if available)
--   ARROW_USE_PRECOMPILED_HEADERS=OFF [default=OFF]
--       Use precompiled headers when compiling
--   ARROW_SIMD_LEVEL=SSE4_2 [default=NONE|SSE4_2|AVX2|AVX512|NEON|SVE|SVE128|SVE256|SVE512|DEFAULT]
--       Compile-time SIMD optimization level
--   ARROW_RUNTIME_SIMD_LEVEL=MAX [default=NONE|SSE4_2|AVX2|AVX512|MAX]
--       Max runtime SIMD optimization level
--   ARROW_ALTIVEC=ON [default=ON]
--       Build with Altivec if compiler has support
--   ARROW_RPATH_ORIGIN=OFF [default=OFF]
--       Build Arrow libraries with RATH set to $ORIGIN
--   ARROW_INSTALL_NAME_RPATH=ON [default=ON]
--       Build Arrow libraries with install_name set to @rpath
--   ARROW_GGDB_DEBUG=ON [default=ON]
--       Pass -ggdb flag to debug builds
--   ARROW_WITH_MUSL=OFF [default=OFF]
--       Whether the system libc is musl or not
-- 
-- Test and benchmark options:
-- 
--   ARROW_BUILD_EXAMPLES=OFF [default=OFF]
--       Build the Arrow examples
--   ARROW_BUILD_TESTS=OFF [default=OFF]
--       Build the Arrow googletest unit tests
--   ARROW_ENABLE_TIMING_TESTS=ON [default=ON]
--       Enable timing-sensitive tests
--   ARROW_BUILD_INTEGRATION=OFF [default=OFF]
--       Build the Arrow integration test executables
--   ARROW_BUILD_BENCHMARKS=OFF [default=OFF]
--       Build the Arrow micro benchmarks
--   ARROW_BUILD_BENCHMARKS_REFERENCE=OFF [default=OFF]
--       Build the Arrow micro reference benchmarks
--   ARROW_BUILD_OPENMP_BENCHMARKS=OFF [default=OFF]
--       Build the Arrow benchmarks that rely on OpenMP
--   ARROW_BUILD_DETAILED_BENCHMARKS=OFF [default=OFF]
--       Build benchmarks that do a longer exploration of performance
--   ARROW_TEST_LINKAGE=shared [default=shared|static]
--       Linkage of Arrow libraries with unit tests executables.
--   ARROW_FUZZING=OFF [default=OFF]
--       Build Arrow Fuzzing executables
--   ARROW_LARGE_MEMORY_TESTS=OFF [default=OFF]
--       Enable unit tests which use large memory
-- 
-- Lint options:
-- 
--   ARROW_ONLY_LINT=OFF [default=OFF]
--       Only define the lint and check-format targets
--   ARROW_VERBOSE_LINT=OFF [default=OFF]
--       If off, 'quiet' flags will be passed to linting tools
--   ARROW_GENERATE_COVERAGE=OFF [default=OFF]
--       Build with C++ code coverage enabled
-- 
-- Checks options:
-- 
--   ARROW_TEST_MEMCHECK=OFF [default=OFF]
--       Run the test suite using valgrind --tool=memcheck
--   ARROW_USE_ASAN=OFF [default=OFF]
--       Enable Address Sanitizer checks
--   ARROW_USE_TSAN=OFF [default=OFF]
--       Enable Thread Sanitizer checks
--   ARROW_USE_UBSAN=OFF [default=OFF]
--       Enable Undefined Behavior sanitizer checks
-- 
-- Project component options:
-- 
--   ARROW_BUILD_UTILITIES=OFF [default=OFF]
--       Build Arrow commandline utilities
--   ARROW_COMPUTE=OFF [default=OFF]
--       Build all Arrow Compute kernels
--   ARROW_CSV=OFF [default=OFF]
--       Build the Arrow CSV Parser Module
--   ARROW_CUDA=OFF [default=OFF]
--       Build the Arrow CUDA extensions (requires CUDA toolkit)
--   ARROW_DATASET=OFF [default=OFF]
--       Build the Arrow Dataset Modules
--   ARROW_FILESYSTEM=OFF [default=OFF]
--       Build the Arrow Filesystem Layer
--   ARROW_FLIGHT=OFF [default=OFF]
--       Build the Arrow Flight RPC System (requires GRPC, Protocol Buffers)
--   ARROW_FLIGHT_SQL=OFF [default=OFF]
--       Build the Arrow Flight SQL extension
--   ARROW_GANDIVA=OFF [default=OFF]
--       Build the Gandiva libraries
--   ARROW_GCS=OFF [default=OFF]
--       Build Arrow with GCS support (requires the GCloud SDK for C++)
--   ARROW_HDFS=OFF [default=OFF]
--       Build the Arrow HDFS bridge
--   ARROW_IPC=ON [default=ON]
--       Build the Arrow IPC extensions
--   ARROW_JEMALLOC=ON [default=ON]
--       Build the Arrow jemalloc-based allocator
--   ARROW_JSON=OFF [default=OFF]
--       Build Arrow with JSON support (requires RapidJSON)
--   ARROW_MIMALLOC=OFF [default=OFF]
--       Build the Arrow mimalloc-based allocator
--   ARROW_PARQUET=OFF [default=OFF]
--       Build the Parquet libraries
--   ARROW_ORC=OFF [default=OFF]
--       Build the Arrow ORC adapter
--   ARROW_PYTHON=OFF [default=OFF]
--       Build some components needed by PyArrow.
--       (This is a deprecated option. Use CMake presets instead.)
--   ARROW_S3=OFF [default=OFF]
--       Build Arrow with S3 support (requires the AWS SDK for C++)
--   ARROW_SKYHOOK=OFF [default=OFF]
--       Build the Skyhook libraries
--   ARROW_SUBSTRAIT=OFF [default=OFF]
--       Build the Arrow Substrait Consumer Module
--   ARROW_ACERO=OFF [default=OFF]
--       Build the Arrow Acero Engine Module
--   ARROW_TENSORFLOW=OFF [default=OFF]
--       Build Arrow with TensorFlow support enabled
--   ARROW_TESTING=OFF [default=OFF]
--       Build the Arrow testing libraries
-- 
-- Thirdparty toolchain options:
-- 
--   ARROW_DEPENDENCY_SOURCE=CONDA [default=AUTO|BUNDLED|SYSTEM|CONDA|VCPKG|BREW]
--       Method to use for acquiring arrow's build dependencies
--   ARROW_VERBOSE_THIRDPARTY_BUILD=OFF [default=OFF]
--       Show output from ExternalProjects rather than just logging to files
--   ARROW_DEPENDENCY_USE_SHARED=ON [default=ON]
--       Link to shared libraries
--   ARROW_BOOST_USE_SHARED=ON [default=ON]
--       Rely on Boost shared libraries where relevant
--   ARROW_BROTLI_USE_SHARED=ON [default=ON]
--       Rely on Brotli shared libraries where relevant
--   ARROW_BZ2_USE_SHARED=ON [default=ON]
--       Rely on Bz2 shared libraries where relevant
--   ARROW_GFLAGS_USE_SHARED=ON [default=ON]
--       Rely on GFlags shared libraries where relevant
--   ARROW_GRPC_USE_SHARED=ON [default=ON]
--       Rely on gRPC shared libraries where relevant
--   ARROW_JEMALLOC_USE_SHARED=OFF [default=ON]
--       Rely on jemalloc shared libraries where relevant
--   ARROW_LZ4_USE_SHARED=ON [default=ON]
--       Rely on lz4 shared libraries where relevant
--   ARROW_OPENSSL_USE_SHARED=ON [default=ON]
--       Rely on OpenSSL shared libraries where relevant
--   ARROW_PROTOBUF_USE_SHARED=ON [default=ON]
--       Rely on Protocol Buffers shared libraries where relevant
--   ARROW_SNAPPY_USE_SHARED=ON [default=ON]
--       Rely on snappy shared libraries where relevant
--   ARROW_THRIFT_USE_SHARED=ON [default=ON]
--       Rely on thrift shared libraries where relevant
--   ARROW_UTF8PROC_USE_SHARED=ON [default=ON]
--       Rely on utf8proc shared libraries where relevant
--   ARROW_ZSTD_USE_SHARED=ON [default=ON]
--       Rely on zstd shared libraries where relevant
--   ARROW_USE_GLOG=OFF [default=OFF]
--       Build libraries with glog support for pluggable logging
--   ARROW_WITH_BACKTRACE=ON [default=ON]
--       Build with backtrace support
--   ARROW_WITH_OPENTELEMETRY=OFF [default=OFF]
--       Build libraries with OpenTelemetry support for distributed tracing
--   ARROW_WITH_BROTLI=OFF [default=OFF]
--       Build with Brotli compression
--   ARROW_WITH_BZ2=OFF [default=OFF]
--       Build with BZ2 compression
--   ARROW_WITH_LZ4=OFF [default=OFF]
--       Build with lz4 compression
--   ARROW_WITH_SNAPPY=OFF [default=OFF]
--       Build with Snappy compression
--   ARROW_WITH_ZLIB=OFF [default=OFF]
--       Build with zlib compression
--   ARROW_WITH_ZSTD=OFF [default=OFF]
--       Build with zstd compression
--   ARROW_WITH_UCX=OFF [default=OFF]
--       Build with UCX transport for Arrow Flight
--       (only used if ARROW_FLIGHT is ON)
--   ARROW_WITH_UTF8PROC=OFF [default=ON]
--       Build with support for Unicode properties using the utf8proc library
--       (only used if ARROW_COMPUTE is ON or ARROW_GANDIVA is ON)
--   ARROW_WITH_RE2=OFF [default=ON]
--       Build with support for regular expressions using the re2 library
--       (only used if ARROW_COMPUTE or ARROW_GANDIVA is ON)
-- 
-- Parquet options:
-- 
--   PARQUET_MINIMAL_DEPENDENCY=OFF [default=OFF]
--       Depend only on Thirdparty headers to build libparquet.
--       Always OFF if building binaries
--   PARQUET_BUILD_EXECUTABLES=OFF [default=OFF]
--       Build the Parquet executable CLI tools. Requires static libraries to be built.
--   PARQUET_BUILD_EXAMPLES=OFF [default=OFF]
--       Build the Parquet examples. Requires static libraries to be built.
--   PARQUET_REQUIRE_ENCRYPTION=OFF [default=OFF]
--       Build support for encryption. Fail if OpenSSL is not found
-- 
-- Gandiva options:
-- 
--   ARROW_GANDIVA_STATIC_LIBSTDCPP=OFF [default=OFF]
--       Include -static-libstdc++ -static-libgcc when linking with
--       Gandiva static libraries
--   ARROW_GANDIVA_PC_CXX_FLAGS="" [default=""]
--       Compiler flags to append when pre-compiling Gandiva operations
-- 
-- Advanced developer options:
-- 
--   ARROW_EXTRA_ERROR_CONTEXT=ON [default=OFF]
--       Compile with extra error context (line numbers, code)
--   ARROW_OPTIONAL_INSTALL=OFF [default=OFF]
--       If enabled install ONLY targets that have already been built. Please be
--       advised that if this is enabled 'install' will fail silently on components
--       that have not been built
--   ARROW_GDB_INSTALL_DIR="" [default=""]
--       Use a custom install directory for GDB plugin.
--       In general, you don't need to specify this because the default
--       (CMAKE_INSTALL_FULL_BINDIR on Windows, CMAKE_INSTALL_FULL_LIBDIR otherwise)
--       is reasonable.
--   Outputting build configuration summary to /home/tdhock/arrow/cpp/build/cmake_summary.json
-- Configuring done
-- Generating done
-- Build files have been written to: /home/tdhock/arrow/cpp/build
(arrow) tdhock@tdhock-MacBook:~/arrow/cpp/build(main)$ cmake --build .
ninja: no work to do.
(arrow) tdhock@tdhock-MacBook:~/arrow/cpp/build(main)$ ninja clean
[1/1] Cleaning all built files...
Cleaning... 186 files.
(arrow) tdhock@tdhock-MacBook:~/arrow/cpp/build(main)$ cmake --build .
[1/183] Creating directories for 'jemalloc_ep'
[2/183] Performing download step (download, verify and extract) for 'jemalloc_ep'
[3/183] No update step for 'jemalloc_ep'
[4/183] Performing patch step for 'jemalloc_ep'
[5/183] Performing configure step for 'jemalloc_ep'
[6/183] Performing build step for 'jemalloc_ep'
[7/183] Performing install step for 'jemalloc_ep'
[8/183] Completed 'jemalloc_ep'
[9/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/array_decimal.cc.o
[10/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/array_binary.cc.o
[11/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/array_nested.cc.o
[12/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/array_primitive.cc.o
[13/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/array_base.cc.o
[14/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/array_dict.cc.o
[15/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/array_run_end.cc.o
[16/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/builder_adaptive.cc.o
[17/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/builder_decimal.cc.o
[18/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/builder_binary.cc.o
[19/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/builder_base.cc.o
[20/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/builder_run_end.cc.o
[21/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/builder_nested.cc.o
[22/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/builder_primitive.cc.o
[23/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/builder_dict.cc.o
[24/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/builder_union.cc.o
[25/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/concatenate.cc.o
[26/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/data.cc.o
[27/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/validate.cc.o
[28/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/diff.cc.o
[29/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/util.cc.o
[30/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/buffer.cc.o
[31/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/chunk_resolver.cc.o
[32/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/chunked_array.cc.o
[33/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/config.cc.o
[34/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compare.cc.o
[35/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/device.cc.o
[36/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/datum.cc.o
[37/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/extension_type.cc.o
[38/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/memory_pool.cc.o
[39/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/record_batch.cc.o
[40/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/pretty_print.cc.o
[41/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/result.cc.o
[42/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/builder.cc.o
[43/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/status.cc.o
[44/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/sparse_tensor.cc.o
[45/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/table_builder.cc.o
[46/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/table.cc.o
[47/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/tensor.cc.o
[48/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/tensor/coo_converter.cc.o
[49/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/tensor/csf_converter.cc.o
[50/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/tensor/csx_converter.cc.o
[51/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/visitor.cc.o
[52/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/scalar.cc.o
[53/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/buffered.cc.o
[54/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/c/bridge.cc.o
[55/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/type.cc.o
[56/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/caching.cc.o
[57/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/compressed.cc.o
[58/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/hdfs.cc.o
[59/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/hdfs_internal.cc.o
[60/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/file.cc.o
[61/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/slow.cc.o
[62/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/memory.cc.o
[63/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/interfaces.cc.o
[64/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/stdio.cc.o
[65/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/transform.cc.o
[66/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/align_util.cc.o
[67/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/atfork_internal.cc.o
[68/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/basic_decimal.cc.o
[69/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/async_util.cc.o
[70/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/bit_block_counter.cc.o
[71/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/bit_run_reader.cc.o
[72/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/bit_util.cc.o
[73/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/bitmap_builders.cc.o
[74/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/bitmap_ops.cc.o
[75/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/bitmap.cc.o
[76/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/bpacking.cc.o
[77/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/cancel.cc.o
[78/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/compression.cc.o
[79/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/counting_semaphore.cc.o
[80/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/byte_size.cc.o
[81/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/debug.cc.o
[82/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/crc32.cc.o
[83/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/cpu_info.cc.o
[84/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/delimiting.cc.o
[85/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/formatting.cc.o
[86/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/decimal.cc.o
[87/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/future.cc.o
[88/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/logging.cc.o
[89/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/int_util.cc.o
[90/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/io_util.cc.o
[91/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/key_value_metadata.cc.o
[92/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/mutex.cc.o
[93/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/memory.cc.o
[94/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/string.cc.o
[95/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/string_builder.cc.o
[96/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/ree_util.cc.o
[97/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/tdigest.cc.o
[98/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/task_group.cc.o
[99/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/time.cc.o
[100/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/tracing.cc.o
[101/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/trie.cc.o
[102/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/thread_pool.cc.o
[103/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/unreachable.cc.o
[104/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/union_util.cc.o
[105/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/utf8.cc.o
[106/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/base64.cpp.o
[107/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/uri.cc.o
[108/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/double-conversion/bignum.cc.o
[109/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/double-conversion/double-conversion.cc.o
[110/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/value_parsing.cc.o
[111/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/double-conversion/fast-dtoa.cc.o
[112/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/double-conversion/bignum-dtoa.cc.o
[113/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/double-conversion/cached-powers.cc.o
[114/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/double-conversion/diy-fp.cc.o
[115/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/double-conversion/fixed-dtoa.cc.o
[116/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/double-conversion/strtod.cc.o
[117/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/datetime/tz.cpp.o
[118/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/memory_pool_jemalloc.cc.o
[119/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/bpacking_avx2.cc.o
[120/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/bpacking_avx512.cc.o
[121/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/api_aggregate.cc.o
[122/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/api_vector.cc.o
[123/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/cast.cc.o
[124/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/api_scalar.cc.o
[125/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/exec.cc.o
[126/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/function.cc.o
[127/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/expression.cc.o
[128/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/function_internal.cc.o
[129/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernel.cc.o
[130/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/key_hash.cc.o
[131/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/key_map.cc.o
[132/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/ordering.cc.o
[133/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/light_array.cc.o
[134/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/registry.cc.o
[135/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/codegen_internal.cc.o
[136/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/ree_util_internal.cc.o
[137/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/row_encoder.cc.o
[138/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/scalar_cast_boolean.cc.o
[139/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/scalar_cast_dictionary.cc.o
[140/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/scalar_cast_extension.cc.o
[141/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/scalar_cast_internal.cc.o
[142/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/scalar_cast_nested.cc.o
[143/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/scalar_cast_numeric.cc.o
[144/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/scalar_cast_temporal.cc.o
[145/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/scalar_cast_string.cc.o
[146/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/util_internal.cc.o
[147/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/row/encode_internal.cc.o
[148/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/row/compare_internal.cc.o
[149/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/vector_selection.cc.o
[150/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/vector_hash.cc.o
[151/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/util.cc.o
[152/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/row/row_internal.cc.o
[153/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/row/grouper.cc.o
[154/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/key_map_avx2.cc.o
[155/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/key_hash_avx2.cc.o
[156/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/row/compare_internal_avx2.cc.o
[157/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/row/encode_internal_avx2.cc.o
[158/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/util_avx2.cc.o
[159/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/ipc/dictionary.cc.o
[160/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/ipc/feather.cc.o
[161/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/ipc/message.cc.o
[162/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/ipc/options.cc.o
[163/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/ipc/metadata_internal.cc.o
[164/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/musl/strptime.c.o
[165/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriCommon.c.o
[166/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriCompare.c.o
[167/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriEscape.c.o
[168/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriFile.c.o
[169/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriIp4Base.c.o
[170/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriIp4.c.o
[171/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriMemory.c.o
[172/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriNormalizeBase.c.o
[173/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriNormalize.c.o
[174/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriParseBase.c.o
[175/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriParse.c.o
[176/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriQuery.c.o
[177/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriRecompose.c.o
[178/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriResolve.c.o
[179/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriShorten.c.o
[180/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/ipc/writer.cc.o
[181/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/ipc/reader.cc.o
[182/183] Linking CXX shared library debug/libarrow.so.1300.0.0
[183/183] Creating library symlink debug/libarrow.so.1300 debug/libarrow.so
(arrow) tdhock@tdhock-MacBook:~/arrow/cpp/build(main)$ cmake --install .
-- Install configuration: "DEBUG"
-- Installing: /home/tdhock/include/arrow/util/config.h
-- Installing: /home/tdhock/share/doc/arrow/LICENSE.txt
-- Installing: /home/tdhock/share/doc/arrow/NOTICE.txt
-- Installing: /home/tdhock/share/doc/arrow/README.md
-- Installing: /home/tdhock/share/arrow/gdb/gdb_arrow.py
-- Installing: /home/tdhock/lib/libarrow.so.1300.0.0
-- Installing: /home/tdhock/lib/libarrow.so.1300
-- Installing: /home/tdhock/lib/libarrow.so
-- Installing: /home/tdhock/lib/cmake/Arrow/ArrowConfig.cmake
-- Installing: /home/tdhock/lib/cmake/Arrow/ArrowConfigVersion.cmake
-- Installing: /home/tdhock/lib/cmake/Arrow/ArrowTargets.cmake
-- Installing: /home/tdhock/lib/cmake/Arrow/ArrowTargets-debug.cmake
-- Installing: /home/tdhock/lib/pkgconfig/arrow.pc
-- Installing: /home/tdhock/share/gdb/auto-load/home/tdhock/lib/libarrow.so.1300.0.0-gdb.py
-- Installing: /home/tdhock/include/arrow/api.h
-- Installing: /home/tdhock/include/arrow/array.h
-- Installing: /home/tdhock/include/arrow/buffer.h
-- Installing: /home/tdhock/include/arrow/buffer_builder.h
-- Installing: /home/tdhock/include/arrow/builder.h
-- Installing: /home/tdhock/include/arrow/chunk_resolver.h
-- Installing: /home/tdhock/include/arrow/chunked_array.h
-- Installing: /home/tdhock/include/arrow/compare.h
-- Installing: /home/tdhock/include/arrow/config.h
-- Installing: /home/tdhock/include/arrow/datum.h
-- Installing: /home/tdhock/include/arrow/device.h
-- Installing: /home/tdhock/include/arrow/extension_type.h
-- Installing: /home/tdhock/include/arrow/memory_pool.h
-- Installing: /home/tdhock/include/arrow/memory_pool_test.h
-- Installing: /home/tdhock/include/arrow/pch.h
-- Installing: /home/tdhock/include/arrow/pretty_print.h
-- Installing: /home/tdhock/include/arrow/record_batch.h
-- Installing: /home/tdhock/include/arrow/result.h
-- Installing: /home/tdhock/include/arrow/scalar.h
-- Installing: /home/tdhock/include/arrow/sparse_tensor.h
-- Installing: /home/tdhock/include/arrow/status.h
-- Installing: /home/tdhock/include/arrow/stl.h
-- Installing: /home/tdhock/include/arrow/stl_allocator.h
-- Installing: /home/tdhock/include/arrow/stl_iterator.h
-- Installing: /home/tdhock/include/arrow/table.h
-- Installing: /home/tdhock/include/arrow/table_builder.h
-- Installing: /home/tdhock/include/arrow/tensor.h
-- Installing: /home/tdhock/include/arrow/type.h
-- Installing: /home/tdhock/include/arrow/type_fwd.h
-- Installing: /home/tdhock/include/arrow/type_traits.h
-- Installing: /home/tdhock/include/arrow/visit_array_inline.h
-- Installing: /home/tdhock/include/arrow/visit_data_inline.h
-- Installing: /home/tdhock/include/arrow/visit_scalar_inline.h
-- Installing: /home/tdhock/include/arrow/visit_type_inline.h
-- Installing: /home/tdhock/include/arrow/visitor.h
-- Installing: /home/tdhock/include/arrow/visitor_generate.h
-- Installing: /home/tdhock/lib/cmake/Arrow/ArrowOptions.cmake
-- Installing: /home/tdhock/lib/cmake/Arrow/arrow-config.cmake
-- Installing: /home/tdhock/include/arrow/testing/async_test_util.h
-- Installing: /home/tdhock/include/arrow/testing/builder.h
-- Installing: /home/tdhock/include/arrow/testing/executor_util.h
-- Installing: /home/tdhock/include/arrow/testing/extension_type.h
-- Installing: /home/tdhock/include/arrow/testing/future_util.h
-- Installing: /home/tdhock/include/arrow/testing/generator.h
-- Installing: /home/tdhock/include/arrow/testing/gtest_compat.h
-- Installing: /home/tdhock/include/arrow/testing/gtest_util.h
-- Installing: /home/tdhock/include/arrow/testing/json_integration.h
-- Installing: /home/tdhock/include/arrow/testing/matchers.h
-- Installing: /home/tdhock/include/arrow/testing/pch.h
-- Installing: /home/tdhock/include/arrow/testing/random.h
-- Installing: /home/tdhock/include/arrow/testing/uniform_real.h
-- Installing: /home/tdhock/include/arrow/testing/util.h
-- Installing: /home/tdhock/include/arrow/testing/visibility.h
-- Installing: /home/tdhock/include/arrow/array/array_base.h
-- Installing: /home/tdhock/include/arrow/array/array_binary.h
-- Installing: /home/tdhock/include/arrow/array/array_decimal.h
-- Installing: /home/tdhock/include/arrow/array/array_dict.h
-- Installing: /home/tdhock/include/arrow/array/array_nested.h
-- Installing: /home/tdhock/include/arrow/array/array_primitive.h
-- Installing: /home/tdhock/include/arrow/array/array_run_end.h
-- Installing: /home/tdhock/include/arrow/array/builder_adaptive.h
-- Installing: /home/tdhock/include/arrow/array/builder_base.h
-- Installing: /home/tdhock/include/arrow/array/builder_binary.h
-- Installing: /home/tdhock/include/arrow/array/builder_decimal.h
-- Installing: /home/tdhock/include/arrow/array/builder_dict.h
-- Installing: /home/tdhock/include/arrow/array/builder_nested.h
-- Installing: /home/tdhock/include/arrow/array/builder_primitive.h
-- Installing: /home/tdhock/include/arrow/array/builder_run_end.h
-- Installing: /home/tdhock/include/arrow/array/builder_time.h
-- Installing: /home/tdhock/include/arrow/array/builder_union.h
-- Installing: /home/tdhock/include/arrow/array/concatenate.h
-- Installing: /home/tdhock/include/arrow/array/data.h
-- Installing: /home/tdhock/include/arrow/array/diff.h
-- Installing: /home/tdhock/include/arrow/array/util.h
-- Installing: /home/tdhock/include/arrow/array/validate.h
-- Installing: /home/tdhock/include/arrow/c/abi.h
-- Installing: /home/tdhock/include/arrow/c/bridge.h
-- Installing: /home/tdhock/include/arrow/c/helpers.h
-- Installing: /home/tdhock/include/arrow/compute/api.h
-- Installing: /home/tdhock/include/arrow/compute/api_aggregate.h
-- Installing: /home/tdhock/include/arrow/compute/api_scalar.h
-- Installing: /home/tdhock/include/arrow/compute/api_vector.h
-- Installing: /home/tdhock/include/arrow/compute/cast.h
-- Installing: /home/tdhock/include/arrow/compute/exec.h
-- Installing: /home/tdhock/include/arrow/compute/expression.h
-- Installing: /home/tdhock/include/arrow/compute/function.h
-- Installing: /home/tdhock/include/arrow/compute/kernel.h
-- Installing: /home/tdhock/include/arrow/compute/key_hash.h
-- Installing: /home/tdhock/include/arrow/compute/key_map.h
-- Installing: /home/tdhock/include/arrow/compute/light_array.h
-- Installing: /home/tdhock/include/arrow/compute/ordering.h
-- Installing: /home/tdhock/include/arrow/compute/registry.h
-- Installing: /home/tdhock/include/arrow/compute/type_fwd.h
-- Installing: /home/tdhock/include/arrow/compute/util.h
-- Installing: /home/tdhock/lib/pkgconfig/arrow-compute.pc
-- Installing: /home/tdhock/include/arrow/compute/row/grouper.h
-- Installing: /home/tdhock/include/arrow/io/api.h
-- Installing: /home/tdhock/include/arrow/io/buffered.h
-- Installing: /home/tdhock/include/arrow/io/caching.h
-- Installing: /home/tdhock/include/arrow/io/compressed.h
-- Installing: /home/tdhock/include/arrow/io/concurrency.h
-- Installing: /home/tdhock/include/arrow/io/file.h
-- Installing: /home/tdhock/include/arrow/io/hdfs.h
-- Installing: /home/tdhock/include/arrow/io/interfaces.h
-- Installing: /home/tdhock/include/arrow/io/memory.h
-- Installing: /home/tdhock/include/arrow/io/mman.h
-- Installing: /home/tdhock/include/arrow/io/slow.h
-- Installing: /home/tdhock/include/arrow/io/stdio.h
-- Installing: /home/tdhock/include/arrow/io/test_common.h
-- Installing: /home/tdhock/include/arrow/io/transform.h
-- Installing: /home/tdhock/include/arrow/io/type_fwd.h
-- Installing: /home/tdhock/include/arrow/tensor/converter.h
-- Installing: /home/tdhock/include/arrow/util/algorithm.h
-- Installing: /home/tdhock/include/arrow/util/align_util.h
-- Installing: /home/tdhock/include/arrow/util/aligned_storage.h
-- Installing: /home/tdhock/include/arrow/util/async_generator.h
-- Installing: /home/tdhock/include/arrow/util/async_generator_fwd.h
-- Installing: /home/tdhock/include/arrow/util/async_util.h
-- Installing: /home/tdhock/include/arrow/util/base64.h
-- Installing: /home/tdhock/include/arrow/util/basic_decimal.h
-- Installing: /home/tdhock/include/arrow/util/benchmark_util.h
-- Installing: /home/tdhock/include/arrow/util/bit_block_counter.h
-- Installing: /home/tdhock/include/arrow/util/bit_run_reader.h
-- Installing: /home/tdhock/include/arrow/util/bit_stream_utils.h
-- Installing: /home/tdhock/include/arrow/util/bit_util.h
-- Installing: /home/tdhock/include/arrow/util/bitmap.h
-- Installing: /home/tdhock/include/arrow/util/bitmap_builders.h
-- Installing: /home/tdhock/include/arrow/util/bitmap_generate.h
-- Installing: /home/tdhock/include/arrow/util/bitmap_ops.h
-- Installing: /home/tdhock/include/arrow/util/bitmap_reader.h
-- Installing: /home/tdhock/include/arrow/util/bitmap_visit.h
-- Installing: /home/tdhock/include/arrow/util/bitmap_writer.h
-- Installing: /home/tdhock/include/arrow/util/bitset_stack.h
-- Installing: /home/tdhock/include/arrow/util/bpacking.h
-- Installing: /home/tdhock/include/arrow/util/bpacking64_default.h
-- Installing: /home/tdhock/include/arrow/util/bpacking_avx2.h
-- Installing: /home/tdhock/include/arrow/util/bpacking_avx512.h
-- Installing: /home/tdhock/include/arrow/util/bpacking_default.h
-- Installing: /home/tdhock/include/arrow/util/bpacking_neon.h
-- Installing: /home/tdhock/include/arrow/util/bpacking_simd128_generated.h
-- Installing: /home/tdhock/include/arrow/util/bpacking_simd256_generated.h
-- Installing: /home/tdhock/include/arrow/util/bpacking_simd512_generated.h
-- Installing: /home/tdhock/include/arrow/util/byte_size.h
-- Installing: /home/tdhock/include/arrow/util/byte_stream_split.h
-- Installing: /home/tdhock/include/arrow/util/bytes_view.h
-- Installing: /home/tdhock/include/arrow/util/cancel.h
-- Installing: /home/tdhock/include/arrow/util/checked_cast.h
-- Installing: /home/tdhock/include/arrow/util/compare.h
-- Installing: /home/tdhock/include/arrow/util/compression.h
-- Installing: /home/tdhock/include/arrow/util/concurrent_map.h
-- Installing: /home/tdhock/include/arrow/util/converter.h
-- Installing: /home/tdhock/include/arrow/util/counting_semaphore.h
-- Installing: /home/tdhock/include/arrow/util/cpu_info.h
-- Installing: /home/tdhock/include/arrow/util/crc32.h
-- Installing: /home/tdhock/include/arrow/util/debug.h
-- Installing: /home/tdhock/include/arrow/util/decimal.h
-- Installing: /home/tdhock/include/arrow/util/delimiting.h
-- Installing: /home/tdhock/include/arrow/util/dispatch.h
-- Installing: /home/tdhock/include/arrow/util/double_conversion.h
-- Installing: /home/tdhock/include/arrow/util/endian.h
-- Installing: /home/tdhock/include/arrow/util/formatting.h
-- Installing: /home/tdhock/include/arrow/util/functional.h
-- Installing: /home/tdhock/include/arrow/util/future.h
-- Installing: /home/tdhock/include/arrow/util/hash_util.h
-- Installing: /home/tdhock/include/arrow/util/hashing.h
-- Installing: /home/tdhock/include/arrow/util/int_util.h
-- Installing: /home/tdhock/include/arrow/util/int_util_overflow.h
-- Installing: /home/tdhock/include/arrow/util/io_util.h
-- Installing: /home/tdhock/include/arrow/util/iterator.h
-- Installing: /home/tdhock/include/arrow/util/key_value_metadata.h
-- Installing: /home/tdhock/include/arrow/util/launder.h
-- Installing: /home/tdhock/include/arrow/util/logging.h
-- Installing: /home/tdhock/include/arrow/util/macros.h
-- Installing: /home/tdhock/include/arrow/util/map.h
-- Installing: /home/tdhock/include/arrow/util/math_constants.h
-- Installing: /home/tdhock/include/arrow/util/memory.h
-- Installing: /home/tdhock/include/arrow/util/mutex.h
-- Installing: /home/tdhock/include/arrow/util/parallel.h
-- Installing: /home/tdhock/include/arrow/util/pcg_random.h
-- Installing: /home/tdhock/include/arrow/util/print.h
-- Installing: /home/tdhock/include/arrow/util/queue.h
-- Installing: /home/tdhock/include/arrow/util/range.h
-- Installing: /home/tdhock/include/arrow/util/ree_util.h
-- Installing: /home/tdhock/include/arrow/util/regex.h
-- Installing: /home/tdhock/include/arrow/util/rle_encoding.h
-- Installing: /home/tdhock/include/arrow/util/rows_to_batches.h
-- Installing: /home/tdhock/include/arrow/util/simd.h
-- Installing: /home/tdhock/include/arrow/util/small_vector.h
-- Installing: /home/tdhock/include/arrow/util/sort.h
-- Installing: /home/tdhock/include/arrow/util/spaced.h
-- Installing: /home/tdhock/include/arrow/util/stopwatch.h
-- Installing: /home/tdhock/include/arrow/util/string.h
-- Installing: /home/tdhock/include/arrow/util/string_builder.h
-- Installing: /home/tdhock/include/arrow/util/task_group.h
-- Installing: /home/tdhock/include/arrow/util/tdigest.h
-- Installing: /home/tdhock/include/arrow/util/test_common.h
-- Installing: /home/tdhock/include/arrow/util/thread_pool.h
-- Installing: /home/tdhock/include/arrow/util/time.h
-- Installing: /home/tdhock/include/arrow/util/tracing.h
-- Installing: /home/tdhock/include/arrow/util/trie.h
-- Installing: /home/tdhock/include/arrow/util/type_fwd.h
-- Installing: /home/tdhock/include/arrow/util/type_traits.h
-- Installing: /home/tdhock/include/arrow/util/ubsan.h
-- Installing: /home/tdhock/include/arrow/util/union_util.h
-- Installing: /home/tdhock/include/arrow/util/unreachable.h
-- Installing: /home/tdhock/include/arrow/util/uri.h
-- Installing: /home/tdhock/include/arrow/util/utf8.h
-- Installing: /home/tdhock/include/arrow/util/value_parsing.h
-- Installing: /home/tdhock/include/arrow/util/vector.h
-- Installing: /home/tdhock/include/arrow/util/visibility.h
-- Installing: /home/tdhock/include/arrow/util/windows_compatibility.h
-- Installing: /home/tdhock/include/arrow/util/windows_fixup.h
-- Installing: /home/tdhock/include/arrow/vendored/ProducerConsumerQueue.h
-- Installing: /home/tdhock/include/arrow/vendored/datetime.h
-- Installing: /home/tdhock/include/arrow/vendored/strptime.h
-- Installing: /home/tdhock/include/arrow/vendored/xxhash.h
-- Installing: /home/tdhock/include/arrow/vendored/datetime/date.h
-- Installing: /home/tdhock/include/arrow/vendored/datetime/ios.h
-- Installing: /home/tdhock/include/arrow/vendored/datetime/tz.h
-- Installing: /home/tdhock/include/arrow/vendored/datetime/tz_private.h
-- Installing: /home/tdhock/include/arrow/vendored/datetime/visibility.h
-- Installing: /home/tdhock/include/arrow/vendored/double-conversion/bignum-dtoa.h
-- Installing: /home/tdhock/include/arrow/vendored/double-conversion/bignum.h
-- Installing: /home/tdhock/include/arrow/vendored/double-conversion/cached-powers.h
-- Installing: /home/tdhock/include/arrow/vendored/double-conversion/diy-fp.h
-- Installing: /home/tdhock/include/arrow/vendored/double-conversion/double-conversion.h
-- Installing: /home/tdhock/include/arrow/vendored/double-conversion/fast-dtoa.h
-- Installing: /home/tdhock/include/arrow/vendored/double-conversion/fixed-dtoa.h
-- Installing: /home/tdhock/include/arrow/vendored/double-conversion/ieee.h
-- Installing: /home/tdhock/include/arrow/vendored/double-conversion/strtod.h
-- Installing: /home/tdhock/include/arrow/vendored/double-conversion/utils.h
-- Installing: /home/tdhock/include/arrow/vendored/pcg/pcg_extras.hpp
-- Installing: /home/tdhock/include/arrow/vendored/pcg/pcg_random.hpp
-- Installing: /home/tdhock/include/arrow/vendored/pcg/pcg_uint128.hpp
-- Installing: /home/tdhock/include/arrow/vendored/portable-snippets/debug-trap.h
-- Installing: /home/tdhock/include/arrow/vendored/portable-snippets/safe-math.h
-- Installing: /home/tdhock/include/arrow/vendored/xxhash/xxhash.h
-- Installing: /home/tdhock/include/arrow/ipc/api.h
-- Installing: /home/tdhock/include/arrow/ipc/dictionary.h
-- Installing: /home/tdhock/include/arrow/ipc/feather.h
-- Installing: /home/tdhock/include/arrow/ipc/json_simple.h
-- Installing: /home/tdhock/include/arrow/ipc/message.h
-- Installing: /home/tdhock/include/arrow/ipc/options.h
-- Installing: /home/tdhock/include/arrow/ipc/reader.h
-- Installing: /home/tdhock/include/arrow/ipc/test_common.h
-- Installing: /home/tdhock/include/arrow/ipc/type_fwd.h
-- Installing: /home/tdhock/include/arrow/ipc/util.h
-- Installing: /home/tdhock/include/arrow/ipc/writer.h
```

Now need to [tell R pkg arrow to use this
arrow](https://arrow.apache.org/docs/r/articles/install.html)
instead of downloading binaries.

The C++ arrow I built above is the development version from their git
repo, so it would be good to install their R package from git as well,
rather than `~/R/arrow_12` which is the source code for R package
arrow release 12.

I could test a MRE for GCC or proposed error message for arrow using
monsoon which runs linux and has a CPU that supports the popcnt
instruction, see flags below:

```
th798@wind:~$ lscpu 
Architecture:        x86_64
CPU op-mode(s):      32-bit, 64-bit
Byte Order:          Little Endian
CPU(s):              24
On-line CPU(s) list: 0-23
Thread(s) per core:  2
Core(s) per socket:  6
Socket(s):           2
NUMA node(s):        2
Vendor ID:           GenuineIntel
CPU family:          6
Model:               62
Model name:          Intel(R) Xeon(R) CPU E5-2620 v2 @ 2.10GHz
Stepping:            4
CPU MHz:             2600.000
CPU max MHz:         2600.0000
CPU min MHz:         1200.0000
BogoMIPS:            4200.19
Virtualization:      VT-x
L1d cache:           32K
L1i cache:           32K
L2 cache:            256K
L3 cache:            15360K
NUMA node0 CPU(s):   0,2,4,6,8,10,12,14,16,18,20,22
NUMA node1 CPU(s):   1,3,5,7,9,11,13,15,17,19,21,23
Flags:               fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc cpuid aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 cx16 xtpr pdcm pcid dca sse4_1 sse4_2 x2apic popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm cpuid_fault pti ssbd ibrs ibpb stibp tpr_shadow vnmi flexpriority ept vpid fsgsbase smep erms xsaveopt dtherm ida arat pln pts md_clear flush_l1d
```

Trying on another computer,

```
(arrow) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main)$ CC=$HOME/bin/gcc CXX=$HOME/bin/g++ cmake .. -DCMAKE_INSTALL_PREFIX=$HOME -DARROW_CXXFLAGS=-march=core2
-- Building using CMake version: 3.10.2
-- Arrow version: 13.0.0 (full: '13.0.0-SNAPSHOT')
-- Arrow SO version: 1300 (full: 1300.0.0)
-- clang-tidy 14 not found
-- clang-format 14 not found
-- Could NOT find ClangTools (missing: CLANG_FORMAT_BIN CLANG_TIDY_BIN) 
-- infer not found
-- Found cpplint executable at /home/tdhock/arrow-git/cpp/build-support/cpplint.py
-- System processor: x86_64
-- Arrow build warning level: PRODUCTION
-- Using ld linker
-- Build Type: RELEASE
-- Using CONDA approach to find dependencies
-- Using CONDA_PREFIX for ARROW_PACKAGE_PREFIX: /home/tdhock/.local/share/r-miniconda/envs/arrow
-- Setting (unset) dependency *_ROOT variables: /home/tdhock/.local/share/r-miniconda/envs/arrow
-- ARROW_ABSL_BUILD_VERSION: 20211102.0
-- ARROW_ABSL_BUILD_SHA256_CHECKSUM: dcf71b9cba8dc0ca9940c4b316a0c796be8fab42b070bb6b7cab62b48f0e66c4
-- ARROW_AWS_C_AUTH_BUILD_VERSION: v0.6.22
-- ARROW_AWS_C_AUTH_BUILD_SHA256_CHECKSUM: 691a6b4418afcd3dc141351b6ad33fccd8e3ff84df0e9e045b42295d284ee14c
-- ARROW_AWS_C_CAL_BUILD_VERSION: v0.5.20
-- ARROW_AWS_C_CAL_BUILD_SHA256_CHECKSUM: acc352359bd06f8597415c366cf4ec4f00d0b0da92d637039a73323dd55b6cd0
-- ARROW_AWS_C_COMMON_BUILD_VERSION: v0.8.9
-- ARROW_AWS_C_COMMON_BUILD_SHA256_CHECKSUM: 2f3fbaf7c38eae5a00e2a816d09b81177f93529ae8ba1b82dc8f31407565327a
-- ARROW_AWS_C_COMPRESSION_BUILD_VERSION: v0.2.16
-- ARROW_AWS_C_COMPRESSION_BUILD_SHA256_CHECKSUM: 044b1dbbca431a07bde8255ef9ec443c300fc60d4c9408d4b862f65e496687f4
-- ARROW_AWS_C_EVENT_STREAM_BUILD_VERSION: v0.2.18
-- ARROW_AWS_C_EVENT_STREAM_BUILD_SHA256_CHECKSUM: 310ca617f713bf664e4c7485a3d42c1fb57813abd0107e49790d107def7cde4f
-- ARROW_AWS_C_HTTP_BUILD_VERSION: v0.7.3
-- ARROW_AWS_C_HTTP_BUILD_SHA256_CHECKSUM: 07e16c6bf5eba6f0dea96b6f55eae312a7c95b736f4d2e4a210000f45d8265ae
-- ARROW_AWS_C_IO_BUILD_VERSION: v0.13.14
-- ARROW_AWS_C_IO_BUILD_SHA256_CHECKSUM: 12b66510c3d9a4f7e9b714e9cfab2a5bf835f8b9ce2f909d20ae2a2128608c71
-- ARROW_AWS_C_MQTT_BUILD_VERSION: v0.8.4
-- ARROW_AWS_C_MQTT_BUILD_SHA256_CHECKSUM: 232eeac63e72883d460c686a09b98cdd811d24579affac47c5c3f696f956773f
-- ARROW_AWS_C_S3_BUILD_VERSION: v0.2.3
-- ARROW_AWS_C_S3_BUILD_SHA256_CHECKSUM: a00b3c9f319cd1c9aa2c3fa15098864df94b066dcba0deaccbb3caa952d902fe
-- ARROW_AWS_C_SDKUTILS_BUILD_VERSION: v0.1.6
-- ARROW_AWS_C_SDKUTILS_BUILD_SHA256_CHECKSUM: 8a2951344b2fb541eab1e9ca17c18a7fcbfd2aaff4cdd31d362d1fad96111b91
-- ARROW_AWS_CHECKSUMS_BUILD_VERSION: v0.1.13
-- ARROW_AWS_CHECKSUMS_BUILD_SHA256_CHECKSUM: 0f897686f1963253c5069a0e495b85c31635ba146cd3ac38cc2ea31eaf54694d
-- ARROW_AWS_CRT_CPP_BUILD_VERSION: v0.18.16
-- ARROW_AWS_CRT_CPP_BUILD_SHA256_CHECKSUM: 9e69bc1dc4b50871d1038aa9ff6ddeb4c9b28f7d6b5e5b1b69041ccf50a13483
-- ARROW_AWS_LC_BUILD_VERSION: v1.3.0
-- ARROW_AWS_LC_BUILD_SHA256_CHECKSUM: ae96a3567161552744fc0cae8b4d68ed88b1ec0f3d3c98700070115356da5a37
-- ARROW_AWSSDK_BUILD_VERSION: 1.10.55
-- ARROW_AWSSDK_BUILD_SHA256_CHECKSUM: 2d552fb1a84bef4a9b65e34aa7031851ed2aef5319e02cc6e4cb735c48aa30de
-- ARROW_BOOST_BUILD_VERSION: 1.81.0
-- ARROW_BOOST_BUILD_SHA256_CHECKSUM: 9e0ffae35528c35f90468997bc8d99500bf179cbae355415a89a600c38e13574
-- ARROW_BROTLI_BUILD_VERSION: v1.0.9
-- ARROW_BROTLI_BUILD_SHA256_CHECKSUM: f9e8d81d0405ba66d181529af42a3354f838c939095ff99930da6aa9cdf6fe46
-- ARROW_BZIP2_BUILD_VERSION: 1.0.8
-- ARROW_BZIP2_BUILD_SHA256_CHECKSUM: ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269
-- ARROW_CARES_BUILD_VERSION: 1.17.2
-- ARROW_CARES_BUILD_SHA256_CHECKSUM: 4803c844ce20ce510ef0eb83f8ea41fa24ecaae9d280c468c582d2bb25b3913d
-- ARROW_CRC32C_BUILD_VERSION: 1.1.2
-- ARROW_CRC32C_BUILD_SHA256_CHECKSUM: ac07840513072b7fcebda6e821068aa04889018f24e10e46181068fb214d7e56
-- ARROW_GBENCHMARK_BUILD_VERSION: v1.7.1
-- ARROW_GBENCHMARK_BUILD_SHA256_CHECKSUM: 6430e4092653380d9dc4ccb45a1e2dc9259d581f4866dc0759713126056bc1d7
-- ARROW_GFLAGS_BUILD_VERSION: v2.2.2
-- ARROW_GFLAGS_BUILD_SHA256_CHECKSUM: 34af2f15cf7367513b352bdcd2493ab14ce43692d2dcd9dfc499492966c64dcf
-- ARROW_GLOG_BUILD_VERSION: v0.5.0
-- ARROW_GLOG_BUILD_SHA256_CHECKSUM: eede71f28371bf39aa69b45de23b329d37214016e2055269b3b5e7cfd40b59f5
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_VERSION: v2.8.0
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_SHA256_CHECKSUM: 21fb441b5a670a18bb16b6826be8e0530888d0b94320847c538d46f5a54dddbc
-- ARROW_GRPC_BUILD_VERSION: v1.46.3
-- ARROW_GRPC_BUILD_SHA256_CHECKSUM: d6cbf22cb5007af71b61c6be316a79397469c58c82a942552a62e708bce60964
-- ARROW_GTEST_BUILD_VERSION: 1.11.0
-- ARROW_GTEST_BUILD_SHA256_CHECKSUM: b4870bf121ff7795ba20d20bcdd8627b8e088f2d1dab299a031c1034eddc93d5
-- ARROW_JEMALLOC_BUILD_VERSION: 5.3.0
-- ARROW_JEMALLOC_BUILD_SHA256_CHECKSUM: 2db82d1e7119df3e71b7640219b6dfe84789bc0537983c3b7ac4f7189aecfeaa
-- ARROW_LZ4_BUILD_VERSION: v1.9.4
-- ARROW_LZ4_BUILD_SHA256_CHECKSUM: 0b0e3aa07c8c063ddf40b082bdf7e37a1562bda40a0ff5272957f3e987e0e54b
-- ARROW_MIMALLOC_BUILD_VERSION: v2.0.6
-- ARROW_MIMALLOC_BUILD_SHA256_CHECKSUM: 9f05c94cc2b017ed13698834ac2a3567b6339a8bde27640df5a1581d49d05ce5
-- ARROW_NLOHMANN_JSON_BUILD_VERSION: v3.10.5
-- ARROW_NLOHMANN_JSON_BUILD_SHA256_CHECKSUM: 5daca6ca216495edf89d167f808d1d03c4a4d929cef7da5e10f135ae1540c7e4
-- ARROW_OPENTELEMETRY_BUILD_VERSION: v1.8.1
-- ARROW_OPENTELEMETRY_BUILD_SHA256_CHECKSUM: 3d640201594b07f08dade9cd1017bd0b59674daca26223b560b9bb6bf56264c2
-- ARROW_OPENTELEMETRY_PROTO_BUILD_VERSION: v0.17.0
-- ARROW_OPENTELEMETRY_PROTO_BUILD_SHA256_CHECKSUM: f269fbcb30e17b03caa1decd231ce826e59d7651c0f71c3b28eb5140b4bb5412
-- ARROW_ORC_BUILD_VERSION: 1.8.3
-- ARROW_ORC_BUILD_SHA256_CHECKSUM: a78678ec425c8129d63370cb8a9bacb54186aa66af1e2bec01ce92e7eaf72e20
-- ARROW_PROTOBUF_BUILD_VERSION: v21.3
-- ARROW_PROTOBUF_BUILD_SHA256_CHECKSUM: 2f723218f6cb709ae4cdc4fb5ed56a5951fc5d466f0128ce4c946b8c78c8c49f
-- ARROW_RAPIDJSON_BUILD_VERSION: 232389d4f1012dddec4ef84861face2d2ba85709
-- ARROW_RAPIDJSON_BUILD_SHA256_CHECKSUM: b9290a9a6d444c8e049bd589ab804e0ccf2b05dc5984a19ed5ae75d090064806
-- ARROW_RE2_BUILD_VERSION: 2022-06-01
-- ARROW_RE2_BUILD_SHA256_CHECKSUM: f89c61410a072e5cbcf8c27e3a778da7d6fd2f2b5b1445cd4f4508bee946ab0f
-- ARROW_SNAPPY_BUILD_VERSION: 1.1.9
-- ARROW_SNAPPY_BUILD_SHA256_CHECKSUM: 75c1fbb3d618dd3a0483bff0e26d0a92b495bbe5059c8b4f1c962b478b6e06e7
-- ARROW_SUBSTRAIT_BUILD_VERSION: v0.20.0
-- ARROW_SUBSTRAIT_BUILD_SHA256_CHECKSUM: 5ceaa559ccef29a7825b5e5d4b5e7eed384830294f08bec913feecdd903a94cf
-- ARROW_S2N_TLS_BUILD_VERSION: v1.3.35
-- ARROW_S2N_TLS_BUILD_SHA256_CHECKSUM: 9d32b26e6bfcc058d98248bf8fc231537e347395dd89cf62bb432b55c5da990d
-- ARROW_THRIFT_BUILD_VERSION: 0.16.0
-- ARROW_THRIFT_BUILD_SHA256_CHECKSUM: f460b5c1ca30d8918ff95ea3eb6291b3951cf518553566088f3f2be8981f6209
-- ARROW_UCX_BUILD_VERSION: 1.12.1
-- ARROW_UCX_BUILD_SHA256_CHECKSUM: 9bef31aed0e28bf1973d28d74d9ac4f8926c43ca3b7010bd22a084e164e31b71
-- ARROW_UTF8PROC_BUILD_VERSION: v2.7.0
-- ARROW_UTF8PROC_BUILD_SHA256_CHECKSUM: 4bb121e297293c0fd55f08f83afab6d35d48f0af4ecc07523ad8ec99aa2b12a1
-- ARROW_XSIMD_BUILD_VERSION: 9.0.1
-- ARROW_XSIMD_BUILD_SHA256_CHECKSUM: b1bb5f92167fd3a4f25749db0be7e61ed37e0a5d943490f3accdcd2cd2918cc0
-- ARROW_ZLIB_BUILD_VERSION: 1.2.13
-- ARROW_ZLIB_BUILD_SHA256_CHECKSUM: b3a24de97a8fdbc835b9833169501030b8977031bcb54b3b3ac13740f846ab30
-- ARROW_ZSTD_BUILD_VERSION: 1.5.5
-- ARROW_ZSTD_BUILD_SHA256_CHECKSUM: 9c4396cc829cfae319a6e2615202e82aad41372073482fce286fac78646d3ee4
-- Building without OpenSSL support. Minimum OpenSSL version 1.0.2 required.
-- Building jemalloc from source
-- xsimd found. Headers: /home/tdhock/.local/share/r-miniconda/envs/arrow/include
-- Found hdfs.h at: /home/tdhock/arrow-git/cpp/thirdparty/hadoop/include/hdfs.h
-- All bundled static libraries: jemalloc::jemalloc
-- CMAKE_C_FLAGS:   -Wall -fno-semantic-interposition -msse4.2 -march=core2
-- CMAKE_CXX_FLAGS:  -Wno-noexcept-type  -fdiagnostics-color=always  -Wall -fno-semantic-interposition -msse4.2 -march=core2
-- CMAKE_C_FLAGS_RELEASE: -O3 -DNDEBUG -O2 -ftree-vectorize
-- CMAKE_CXX_FLAGS_RELEASE: -O3 -DNDEBUG -O2 -ftree-vectorize
-- Creating bundled static library target arrow_bundled_dependencies at /home/tdhock/arrow-git/cpp/build/release/libarrow_bundled_dependencies.a
-- Looking for backtrace
-- Looking for backtrace - found
-- backtrace facility detected in default set of libraries
-- Found Backtrace: /usr/include  
-- ---------------------------------------------------------------------
-- Arrow version:                                 13.0.0-SNAPSHOT
-- 
-- Build configuration summary:
--   Generator: Unix Makefiles
--   Build type: RELEASE
--   Source directory: /home/tdhock/arrow-git/cpp
--   Install prefix: /home/tdhock
-- 
-- Compile and link options:
-- 
--   ARROW_CXXFLAGS=-march=core2 [default=""]
--       Compiler flags to append when compiling Arrow
--   ARROW_BUILD_STATIC=ON [default=ON]
--       Build static libraries
--   ARROW_BUILD_SHARED=ON [default=ON]
--       Build shared libraries
--   ARROW_PACKAGE_KIND="" [default=""]
--       Arbitrary string that identifies the kind of package
--       (for informational purposes)
--   ARROW_GIT_ID=6d3fe6bda1c3b67b683ada2327194adeed09e9ca [default=""]
--       The Arrow git commit id (if any)
--   ARROW_GIT_DESCRIPTION=apache-arrow-13.0.0.dev-46-g6d3fe6bda [default=""]
--       The Arrow git commit description (if any)
--   ARROW_NO_DEPRECATED_API=OFF [default=OFF]
--       Exclude deprecated APIs from build
--   ARROW_POSITION_INDEPENDENT_CODE=ON [default=ON]
--       Whether to create position-independent target
--   ARROW_USE_CCACHE=ON [default=ON]
--       Use ccache when compiling (if available)
--   ARROW_USE_SCCACHE=ON [default=ON]
--       Use sccache when compiling (if available),
--       takes precedence over ccache if a storage backend is configured
--   ARROW_USE_LD_GOLD=OFF [default=OFF]
--       Use ld.gold for linking on Linux (if available)
--   ARROW_USE_PRECOMPILED_HEADERS=OFF [default=OFF]
--       Use precompiled headers when compiling
--   ARROW_SIMD_LEVEL=SSE4_2 [default=NONE|SSE4_2|AVX2|AVX512|NEON|SVE|SVE128|SVE256|SVE512|DEFAULT]
--       Compile-time SIMD optimization level
--   ARROW_RUNTIME_SIMD_LEVEL=MAX [default=NONE|SSE4_2|AVX2|AVX512|MAX]
--       Max runtime SIMD optimization level
--   ARROW_ALTIVEC=ON [default=ON]
--       Build with Altivec if compiler has support
--   ARROW_RPATH_ORIGIN=OFF [default=OFF]
--       Build Arrow libraries with RATH set to $ORIGIN
--   ARROW_INSTALL_NAME_RPATH=ON [default=ON]
--       Build Arrow libraries with install_name set to @rpath
--   ARROW_GGDB_DEBUG=ON [default=ON]
--       Pass -ggdb flag to debug builds
--   ARROW_WITH_MUSL=OFF [default=OFF]
--       Whether the system libc is musl or not
-- 
-- Test and benchmark options:
-- 
--   ARROW_BUILD_EXAMPLES=OFF [default=OFF]
--       Build the Arrow examples
--   ARROW_BUILD_TESTS=OFF [default=OFF]
--       Build the Arrow googletest unit tests
--   ARROW_ENABLE_TIMING_TESTS=ON [default=ON]
--       Enable timing-sensitive tests
--   ARROW_BUILD_INTEGRATION=OFF [default=OFF]
--       Build the Arrow integration test executables
--   ARROW_BUILD_BENCHMARKS=OFF [default=OFF]
--       Build the Arrow micro benchmarks
--   ARROW_BUILD_BENCHMARKS_REFERENCE=OFF [default=OFF]
--       Build the Arrow micro reference benchmarks
--   ARROW_BUILD_OPENMP_BENCHMARKS=OFF [default=OFF]
--       Build the Arrow benchmarks that rely on OpenMP
--   ARROW_BUILD_DETAILED_BENCHMARKS=OFF [default=OFF]
--       Build benchmarks that do a longer exploration of performance
--   ARROW_TEST_LINKAGE=shared [default=shared|static]
--       Linkage of Arrow libraries with unit tests executables.
--   ARROW_FUZZING=OFF [default=OFF]
--       Build Arrow Fuzzing executables
--   ARROW_LARGE_MEMORY_TESTS=OFF [default=OFF]
--       Enable unit tests which use large memory
-- 
-- Lint options:
-- 
--   ARROW_ONLY_LINT=OFF [default=OFF]
--       Only define the lint and check-format targets
--   ARROW_VERBOSE_LINT=OFF [default=OFF]
--       If off, 'quiet' flags will be passed to linting tools
--   ARROW_GENERATE_COVERAGE=OFF [default=OFF]
--       Build with C++ code coverage enabled
-- 
-- Checks options:
-- 
--   ARROW_TEST_MEMCHECK=OFF [default=OFF]
--       Run the test suite using valgrind --tool=memcheck
--   ARROW_USE_ASAN=OFF [default=OFF]
--       Enable Address Sanitizer checks
--   ARROW_USE_TSAN=OFF [default=OFF]
--       Enable Thread Sanitizer checks
--   ARROW_USE_UBSAN=OFF [default=OFF]
--       Enable Undefined Behavior sanitizer checks
-- 
-- Project component options:
-- 
--   ARROW_BUILD_UTILITIES=OFF [default=OFF]
--       Build Arrow commandline utilities
--   ARROW_COMPUTE=OFF [default=OFF]
--       Build all Arrow Compute kernels
--   ARROW_CSV=OFF [default=OFF]
--       Build the Arrow CSV Parser Module
--   ARROW_CUDA=OFF [default=OFF]
--       Build the Arrow CUDA extensions (requires CUDA toolkit)
--   ARROW_DATASET=OFF [default=OFF]
--       Build the Arrow Dataset Modules
--   ARROW_FILESYSTEM=OFF [default=OFF]
--       Build the Arrow Filesystem Layer
--   ARROW_FLIGHT=OFF [default=OFF]
--       Build the Arrow Flight RPC System (requires GRPC, Protocol Buffers)
--   ARROW_FLIGHT_SQL=OFF [default=OFF]
--       Build the Arrow Flight SQL extension
--   ARROW_GANDIVA=OFF [default=OFF]
--       Build the Gandiva libraries
--   ARROW_GCS=OFF [default=OFF]
--       Build Arrow with GCS support (requires the GCloud SDK for C++)
--   ARROW_HDFS=OFF [default=OFF]
--       Build the Arrow HDFS bridge
--   ARROW_IPC=ON [default=ON]
--       Build the Arrow IPC extensions
--   ARROW_JEMALLOC=ON [default=ON]
--       Build the Arrow jemalloc-based allocator
--   ARROW_JSON=OFF [default=OFF]
--       Build Arrow with JSON support (requires RapidJSON)
--   ARROW_MIMALLOC=OFF [default=OFF]
--       Build the Arrow mimalloc-based allocator
--   ARROW_PARQUET=OFF [default=OFF]
--       Build the Parquet libraries
--   ARROW_ORC=OFF [default=OFF]
--       Build the Arrow ORC adapter
--   ARROW_PYTHON=OFF [default=OFF]
--       Build some components needed by PyArrow.
--       (This is a deprecated option. Use CMake presets instead.)
--   ARROW_S3=OFF [default=OFF]
--       Build Arrow with S3 support (requires the AWS SDK for C++)
--   ARROW_SKYHOOK=OFF [default=OFF]
--       Build the Skyhook libraries
--   ARROW_SUBSTRAIT=OFF [default=OFF]
--       Build the Arrow Substrait Consumer Module
--   ARROW_ACERO=OFF [default=OFF]
--       Build the Arrow Acero Engine Module
--   ARROW_TENSORFLOW=OFF [default=OFF]
--       Build Arrow with TensorFlow support enabled
--   ARROW_TESTING=OFF [default=OFF]
--       Build the Arrow testing libraries
-- 
-- Thirdparty toolchain options:
-- 
--   ARROW_DEPENDENCY_SOURCE=CONDA [default=AUTO|BUNDLED|SYSTEM|CONDA|VCPKG|BREW]
--       Method to use for acquiring arrow's build dependencies
--   ARROW_VERBOSE_THIRDPARTY_BUILD=OFF [default=OFF]
--       Show output from ExternalProjects rather than just logging to files
--   ARROW_DEPENDENCY_USE_SHARED=ON [default=ON]
--       Link to shared libraries
--   ARROW_BOOST_USE_SHARED=ON [default=ON]
--       Rely on Boost shared libraries where relevant
--   ARROW_BROTLI_USE_SHARED=ON [default=ON]
--       Rely on Brotli shared libraries where relevant
--   ARROW_BZ2_USE_SHARED=ON [default=ON]
--       Rely on Bz2 shared libraries where relevant
--   ARROW_GFLAGS_USE_SHARED=ON [default=ON]
--       Rely on GFlags shared libraries where relevant
--   ARROW_GRPC_USE_SHARED=ON [default=ON]
--       Rely on gRPC shared libraries where relevant
--   ARROW_JEMALLOC_USE_SHARED=OFF [default=ON]
--       Rely on jemalloc shared libraries where relevant
--   ARROW_LZ4_USE_SHARED=ON [default=ON]
--       Rely on lz4 shared libraries where relevant
--   ARROW_OPENSSL_USE_SHARED=ON [default=ON]
--       Rely on OpenSSL shared libraries where relevant
--   ARROW_PROTOBUF_USE_SHARED=ON [default=ON]
--       Rely on Protocol Buffers shared libraries where relevant
--   ARROW_SNAPPY_USE_SHARED=ON [default=ON]
--       Rely on snappy shared libraries where relevant
--   ARROW_THRIFT_USE_SHARED=ON [default=ON]
--       Rely on thrift shared libraries where relevant
--   ARROW_UTF8PROC_USE_SHARED=ON [default=ON]
--       Rely on utf8proc shared libraries where relevant
--   ARROW_ZSTD_USE_SHARED=ON [default=ON]
--       Rely on zstd shared libraries where relevant
--   ARROW_USE_GLOG=OFF [default=OFF]
--       Build libraries with glog support for pluggable logging
--   ARROW_WITH_BACKTRACE=ON [default=ON]
--       Build with backtrace support
--   ARROW_WITH_OPENTELEMETRY=OFF [default=OFF]
--       Build libraries with OpenTelemetry support for distributed tracing
--   ARROW_WITH_BROTLI=OFF [default=OFF]
--       Build with Brotli compression
--   ARROW_WITH_BZ2=OFF [default=OFF]
--       Build with BZ2 compression
--   ARROW_WITH_LZ4=OFF [default=OFF]
--       Build with lz4 compression
--   ARROW_WITH_SNAPPY=OFF [default=OFF]
--       Build with Snappy compression
--   ARROW_WITH_ZLIB=OFF [default=OFF]
--       Build with zlib compression
--   ARROW_WITH_ZSTD=OFF [default=OFF]
--       Build with zstd compression
--   ARROW_WITH_UCX=OFF [default=OFF]
--       Build with UCX transport for Arrow Flight
--       (only used if ARROW_FLIGHT is ON)
--   ARROW_WITH_UTF8PROC=OFF [default=ON]
--       Build with support for Unicode properties using the utf8proc library
--       (only used if ARROW_COMPUTE is ON or ARROW_GANDIVA is ON)
--   ARROW_WITH_RE2=OFF [default=ON]
--       Build with support for regular expressions using the re2 library
--       (only used if ARROW_COMPUTE or ARROW_GANDIVA is ON)
-- 
-- Parquet options:
-- 
--   PARQUET_MINIMAL_DEPENDENCY=OFF [default=OFF]
--       Depend only on Thirdparty headers to build libparquet.
--       Always OFF if building binaries
--   PARQUET_BUILD_EXECUTABLES=OFF [default=OFF]
--       Build the Parquet executable CLI tools. Requires static libraries to be built.
--   PARQUET_BUILD_EXAMPLES=OFF [default=OFF]
--       Build the Parquet examples. Requires static libraries to be built.
--   PARQUET_REQUIRE_ENCRYPTION=OFF [default=OFF]
--       Build support for encryption. Fail if OpenSSL is not found
-- 
-- Gandiva options:
-- 
--   ARROW_GANDIVA_STATIC_LIBSTDCPP=OFF [default=OFF]
--       Include -static-libstdc++ -static-libgcc when linking with
--       Gandiva static libraries
--   ARROW_GANDIVA_PC_CXX_FLAGS="" [default=""]
--       Compiler flags to append when pre-compiling Gandiva operations
-- 
-- Advanced developer options:
-- 
--   ARROW_EXTRA_ERROR_CONTEXT=OFF [default=OFF]
--       Compile with extra error context (line numbers, code)
--   ARROW_OPTIONAL_INSTALL=OFF [default=OFF]
--       If enabled install ONLY targets that have already been built. Please be
--       advised that if this is enabled 'install' will fail silently on components
--       that have not been built
--   ARROW_GDB_INSTALL_DIR="" [default=""]
--       Use a custom install directory for GDB plugin.
--       In general, you don't need to specify this because the default
--       (CMAKE_INSTALL_FULL_BINDIR on Windows, CMAKE_INSTALL_FULL_LIBDIR otherwise)
--       is reasonable.
--   Outputting build configuration summary to /home/tdhock/arrow-git/cpp/cmake_summary.json
-- Configuring done
-- Generating done
-- Build files have been written to: /home/tdhock/arrow-git/cpp
(base) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main)$ cmake --build .
Error: could not load cache
(base) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main)$ ls
(base) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main)$ CC=$HOME/bin/gcc CXX=$HOME/bin/g++ cmake .. --preset -N ninja-debug-minimal -DCMAKE_INSTALL_PREFIX=$HOME -DARROW_CXXFLAGS=-march=core2
(base) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main)$  cmake .. --preset -N ninja-debug-minimal 
(base) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main)$  cmake .. --preset ninja-debug-minimal 
CMake Error: The source directory "/home/tdhock/arrow-git/cpp/build/ninja-debug-minimal" does not exist.
Specify --help for usage, or press the help button on the CMake GUI.
```

Problems seem to be related to old cmake, fixed by installing new
cmake from conda, versions shown below. The [arrow C++ building
docs](https://arrow.apache.org/docs/developers/cpp/building.html)
currently say it should work with cmake 3.5 or higher, but it does not
work with my cmake 3.10.2, so I think this is a bug in their docs.

```
(arrow) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main)$ /home/tdhock/.local/share/r-miniconda/envs/arrow/bin/cmake --version
cmake version 3.22.1

CMake suite maintained and supported by Kitware (kitware.com/cmake).
(arrow) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main)$ /usr/bin/cmake --version
cmake version 3.10.2

CMake suite maintained and supported by Kitware (kitware.com/cmake).
```

install works with cmake from conda below.

```
(arrow) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main)$ cmake --version
cmake version 3.22.1

CMake suite maintained and supported by Kitware (kitware.com/cmake).
(arrow) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main)$ CC=$HOME/bin/gcc CXX=$HOME/bin/g++ cmake .. --preset ninja-debug-minimal -DCMAKE_INSTALL_PREFIX=$HOME -DARROW_CXXFLAGS=-march=core2
Preset CMake variables:

  ARROW_BUILD_INTEGRATION="OFF"
  ARROW_BUILD_STATIC="OFF"
  ARROW_BUILD_TESTS="OFF"
  ARROW_EXTRA_ERROR_CONTEXT="ON"
  ARROW_WITH_RE2="OFF"
  ARROW_WITH_UTF8PROC="OFF"
  CMAKE_BUILD_TYPE="Debug"

-- Building using CMake version: 3.22.1
-- The C compiler identification is GNU 10.1.0
-- The CXX compiler identification is GNU 10.1.0
-- Detecting C compiler ABI info
-- Detecting C compiler ABI info - done
-- Check for working C compiler: /home/tdhock/bin/gcc - skipped
-- Detecting C compile features
-- Detecting C compile features - done
-- Detecting CXX compiler ABI info
-- Detecting CXX compiler ABI info - done
-- Check for working CXX compiler: /home/tdhock/bin/g++ - skipped
-- Detecting CXX compile features
-- Detecting CXX compile features - done
-- Arrow version: 13.0.0 (full: '13.0.0-SNAPSHOT')
-- Arrow SO version: 1300 (full: 1300.0.0)
-- clang-tidy 14 not found
-- clang-format 14 not found
-- Could NOT find ClangTools (missing: CLANG_FORMAT_BIN CLANG_TIDY_BIN) 
-- infer not found
-- Found Python3: /usr/bin/python3.8 (found version "3.8.0") found components: Interpreter 
-- Found cpplint executable at /home/tdhock/arrow-git/cpp/build-support/cpplint.py
-- System processor: x86_64
-- Performing Test CXX_SUPPORTS_SSE4_2
-- Performing Test CXX_SUPPORTS_SSE4_2 - Success
-- Performing Test CXX_SUPPORTS_AVX2
-- Performing Test CXX_SUPPORTS_AVX2 - Success
-- Performing Test CXX_SUPPORTS_AVX512
-- Performing Test CXX_SUPPORTS_AVX512 - Success
-- Arrow build warning level: CHECKIN
-- Using ld linker
-- Build Type: DEBUG
-- Performing Test CXX_LINKER_SUPPORTS_VERSION_SCRIPT
-- Performing Test CXX_LINKER_SUPPORTS_VERSION_SCRIPT - Success
-- Using CONDA approach to find dependencies
-- Using CONDA_PREFIX for ARROW_PACKAGE_PREFIX: /home/tdhock/.local/share/r-miniconda/envs/arrow
-- Setting (unset) dependency *_ROOT variables: /home/tdhock/.local/share/r-miniconda/envs/arrow
-- ARROW_ABSL_BUILD_VERSION: 20211102.0
-- ARROW_ABSL_BUILD_SHA256_CHECKSUM: dcf71b9cba8dc0ca9940c4b316a0c796be8fab42b070bb6b7cab62b48f0e66c4
-- ARROW_AWS_C_AUTH_BUILD_VERSION: v0.6.22
-- ARROW_AWS_C_AUTH_BUILD_SHA256_CHECKSUM: 691a6b4418afcd3dc141351b6ad33fccd8e3ff84df0e9e045b42295d284ee14c
-- ARROW_AWS_C_CAL_BUILD_VERSION: v0.5.20
-- ARROW_AWS_C_CAL_BUILD_SHA256_CHECKSUM: acc352359bd06f8597415c366cf4ec4f00d0b0da92d637039a73323dd55b6cd0
-- ARROW_AWS_C_COMMON_BUILD_VERSION: v0.8.9
-- ARROW_AWS_C_COMMON_BUILD_SHA256_CHECKSUM: 2f3fbaf7c38eae5a00e2a816d09b81177f93529ae8ba1b82dc8f31407565327a
-- ARROW_AWS_C_COMPRESSION_BUILD_VERSION: v0.2.16
-- ARROW_AWS_C_COMPRESSION_BUILD_SHA256_CHECKSUM: 044b1dbbca431a07bde8255ef9ec443c300fc60d4c9408d4b862f65e496687f4
-- ARROW_AWS_C_EVENT_STREAM_BUILD_VERSION: v0.2.18
-- ARROW_AWS_C_EVENT_STREAM_BUILD_SHA256_CHECKSUM: 310ca617f713bf664e4c7485a3d42c1fb57813abd0107e49790d107def7cde4f
-- ARROW_AWS_C_HTTP_BUILD_VERSION: v0.7.3
-- ARROW_AWS_C_HTTP_BUILD_SHA256_CHECKSUM: 07e16c6bf5eba6f0dea96b6f55eae312a7c95b736f4d2e4a210000f45d8265ae
-- ARROW_AWS_C_IO_BUILD_VERSION: v0.13.14
-- ARROW_AWS_C_IO_BUILD_SHA256_CHECKSUM: 12b66510c3d9a4f7e9b714e9cfab2a5bf835f8b9ce2f909d20ae2a2128608c71
-- ARROW_AWS_C_MQTT_BUILD_VERSION: v0.8.4
-- ARROW_AWS_C_MQTT_BUILD_SHA256_CHECKSUM: 232eeac63e72883d460c686a09b98cdd811d24579affac47c5c3f696f956773f
-- ARROW_AWS_C_S3_BUILD_VERSION: v0.2.3
-- ARROW_AWS_C_S3_BUILD_SHA256_CHECKSUM: a00b3c9f319cd1c9aa2c3fa15098864df94b066dcba0deaccbb3caa952d902fe
-- ARROW_AWS_C_SDKUTILS_BUILD_VERSION: v0.1.6
-- ARROW_AWS_C_SDKUTILS_BUILD_SHA256_CHECKSUM: 8a2951344b2fb541eab1e9ca17c18a7fcbfd2aaff4cdd31d362d1fad96111b91
-- ARROW_AWS_CHECKSUMS_BUILD_VERSION: v0.1.13
-- ARROW_AWS_CHECKSUMS_BUILD_SHA256_CHECKSUM: 0f897686f1963253c5069a0e495b85c31635ba146cd3ac38cc2ea31eaf54694d
-- ARROW_AWS_CRT_CPP_BUILD_VERSION: v0.18.16
-- ARROW_AWS_CRT_CPP_BUILD_SHA256_CHECKSUM: 9e69bc1dc4b50871d1038aa9ff6ddeb4c9b28f7d6b5e5b1b69041ccf50a13483
-- ARROW_AWS_LC_BUILD_VERSION: v1.3.0
-- ARROW_AWS_LC_BUILD_SHA256_CHECKSUM: ae96a3567161552744fc0cae8b4d68ed88b1ec0f3d3c98700070115356da5a37
-- ARROW_AWSSDK_BUILD_VERSION: 1.10.55
-- ARROW_AWSSDK_BUILD_SHA256_CHECKSUM: 2d552fb1a84bef4a9b65e34aa7031851ed2aef5319e02cc6e4cb735c48aa30de
-- ARROW_BOOST_BUILD_VERSION: 1.81.0
-- ARROW_BOOST_BUILD_SHA256_CHECKSUM: 9e0ffae35528c35f90468997bc8d99500bf179cbae355415a89a600c38e13574
-- ARROW_BROTLI_BUILD_VERSION: v1.0.9
-- ARROW_BROTLI_BUILD_SHA256_CHECKSUM: f9e8d81d0405ba66d181529af42a3354f838c939095ff99930da6aa9cdf6fe46
-- ARROW_BZIP2_BUILD_VERSION: 1.0.8
-- ARROW_BZIP2_BUILD_SHA256_CHECKSUM: ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269
-- ARROW_CARES_BUILD_VERSION: 1.17.2
-- ARROW_CARES_BUILD_SHA256_CHECKSUM: 4803c844ce20ce510ef0eb83f8ea41fa24ecaae9d280c468c582d2bb25b3913d
-- ARROW_CRC32C_BUILD_VERSION: 1.1.2
-- ARROW_CRC32C_BUILD_SHA256_CHECKSUM: ac07840513072b7fcebda6e821068aa04889018f24e10e46181068fb214d7e56
-- ARROW_GBENCHMARK_BUILD_VERSION: v1.7.1
-- ARROW_GBENCHMARK_BUILD_SHA256_CHECKSUM: 6430e4092653380d9dc4ccb45a1e2dc9259d581f4866dc0759713126056bc1d7
-- ARROW_GFLAGS_BUILD_VERSION: v2.2.2
-- ARROW_GFLAGS_BUILD_SHA256_CHECKSUM: 34af2f15cf7367513b352bdcd2493ab14ce43692d2dcd9dfc499492966c64dcf
-- ARROW_GLOG_BUILD_VERSION: v0.5.0
-- ARROW_GLOG_BUILD_SHA256_CHECKSUM: eede71f28371bf39aa69b45de23b329d37214016e2055269b3b5e7cfd40b59f5
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_VERSION: v2.8.0
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_SHA256_CHECKSUM: 21fb441b5a670a18bb16b6826be8e0530888d0b94320847c538d46f5a54dddbc
-- ARROW_GRPC_BUILD_VERSION: v1.46.3
-- ARROW_GRPC_BUILD_SHA256_CHECKSUM: d6cbf22cb5007af71b61c6be316a79397469c58c82a942552a62e708bce60964
-- ARROW_GTEST_BUILD_VERSION: 1.11.0
-- ARROW_GTEST_BUILD_SHA256_CHECKSUM: b4870bf121ff7795ba20d20bcdd8627b8e088f2d1dab299a031c1034eddc93d5
-- ARROW_JEMALLOC_BUILD_VERSION: 5.3.0
-- ARROW_JEMALLOC_BUILD_SHA256_CHECKSUM: 2db82d1e7119df3e71b7640219b6dfe84789bc0537983c3b7ac4f7189aecfeaa
-- ARROW_LZ4_BUILD_VERSION: v1.9.4
-- ARROW_LZ4_BUILD_SHA256_CHECKSUM: 0b0e3aa07c8c063ddf40b082bdf7e37a1562bda40a0ff5272957f3e987e0e54b
-- ARROW_MIMALLOC_BUILD_VERSION: v2.0.6
-- ARROW_MIMALLOC_BUILD_SHA256_CHECKSUM: 9f05c94cc2b017ed13698834ac2a3567b6339a8bde27640df5a1581d49d05ce5
-- ARROW_NLOHMANN_JSON_BUILD_VERSION: v3.10.5
-- ARROW_NLOHMANN_JSON_BUILD_SHA256_CHECKSUM: 5daca6ca216495edf89d167f808d1d03c4a4d929cef7da5e10f135ae1540c7e4
-- ARROW_OPENTELEMETRY_BUILD_VERSION: v1.8.1
-- ARROW_OPENTELEMETRY_BUILD_SHA256_CHECKSUM: 3d640201594b07f08dade9cd1017bd0b59674daca26223b560b9bb6bf56264c2
-- ARROW_OPENTELEMETRY_PROTO_BUILD_VERSION: v0.17.0
-- ARROW_OPENTELEMETRY_PROTO_BUILD_SHA256_CHECKSUM: f269fbcb30e17b03caa1decd231ce826e59d7651c0f71c3b28eb5140b4bb5412
-- ARROW_ORC_BUILD_VERSION: 1.8.3
-- ARROW_ORC_BUILD_SHA256_CHECKSUM: a78678ec425c8129d63370cb8a9bacb54186aa66af1e2bec01ce92e7eaf72e20
-- ARROW_PROTOBUF_BUILD_VERSION: v21.3
-- ARROW_PROTOBUF_BUILD_SHA256_CHECKSUM: 2f723218f6cb709ae4cdc4fb5ed56a5951fc5d466f0128ce4c946b8c78c8c49f
-- ARROW_RAPIDJSON_BUILD_VERSION: 232389d4f1012dddec4ef84861face2d2ba85709
-- ARROW_RAPIDJSON_BUILD_SHA256_CHECKSUM: b9290a9a6d444c8e049bd589ab804e0ccf2b05dc5984a19ed5ae75d090064806
-- ARROW_RE2_BUILD_VERSION: 2022-06-01
-- ARROW_RE2_BUILD_SHA256_CHECKSUM: f89c61410a072e5cbcf8c27e3a778da7d6fd2f2b5b1445cd4f4508bee946ab0f
-- ARROW_SNAPPY_BUILD_VERSION: 1.1.9
-- ARROW_SNAPPY_BUILD_SHA256_CHECKSUM: 75c1fbb3d618dd3a0483bff0e26d0a92b495bbe5059c8b4f1c962b478b6e06e7
-- ARROW_SUBSTRAIT_BUILD_VERSION: v0.20.0
-- ARROW_SUBSTRAIT_BUILD_SHA256_CHECKSUM: 5ceaa559ccef29a7825b5e5d4b5e7eed384830294f08bec913feecdd903a94cf
-- ARROW_S2N_TLS_BUILD_VERSION: v1.3.35
-- ARROW_S2N_TLS_BUILD_SHA256_CHECKSUM: 9d32b26e6bfcc058d98248bf8fc231537e347395dd89cf62bb432b55c5da990d
-- ARROW_THRIFT_BUILD_VERSION: 0.16.0
-- ARROW_THRIFT_BUILD_SHA256_CHECKSUM: f460b5c1ca30d8918ff95ea3eb6291b3951cf518553566088f3f2be8981f6209
-- ARROW_UCX_BUILD_VERSION: 1.12.1
-- ARROW_UCX_BUILD_SHA256_CHECKSUM: 9bef31aed0e28bf1973d28d74d9ac4f8926c43ca3b7010bd22a084e164e31b71
-- ARROW_UTF8PROC_BUILD_VERSION: v2.7.0
-- ARROW_UTF8PROC_BUILD_SHA256_CHECKSUM: 4bb121e297293c0fd55f08f83afab6d35d48f0af4ecc07523ad8ec99aa2b12a1
-- ARROW_XSIMD_BUILD_VERSION: 9.0.1
-- ARROW_XSIMD_BUILD_SHA256_CHECKSUM: b1bb5f92167fd3a4f25749db0be7e61ed37e0a5d943490f3accdcd2cd2918cc0
-- ARROW_ZLIB_BUILD_VERSION: 1.2.13
-- ARROW_ZLIB_BUILD_SHA256_CHECKSUM: b3a24de97a8fdbc835b9833169501030b8977031bcb54b3b3ac13740f846ab30
-- ARROW_ZSTD_BUILD_VERSION: 1.5.5
-- ARROW_ZSTD_BUILD_SHA256_CHECKSUM: 9c4396cc829cfae319a6e2615202e82aad41372073482fce286fac78646d3ee4
-- Looking for pthread.h
-- Looking for pthread.h - found
-- Performing Test CMAKE_HAVE_LIBC_PTHREAD
-- Performing Test CMAKE_HAVE_LIBC_PTHREAD - Failed
-- Check if compiler accepts -pthread
-- Check if compiler accepts -pthread - yes
-- Found Threads: TRUE  
-- Looking for _M_ARM64
-- Looking for _M_ARM64 - not found
-- Looking for __SIZEOF_INT128__
-- Looking for __SIZEOF_INT128__ - found
-- Building without OpenSSL support. Minimum OpenSSL version 1.0.2 required.
-- Building jemalloc from source
-- xsimd found. Headers: /home/tdhock/.local/share/r-miniconda/envs/arrow/include
-- Found hdfs.h at: /home/tdhock/arrow-git/cpp/thirdparty/hadoop/include/hdfs.h
-- All bundled static libraries: jemalloc::jemalloc
-- CMAKE_C_FLAGS:   -Wall -Wno-conversion -Wno-sign-conversion -Wunused-result -fno-semantic-interposition -msse4.2 -march=core2
-- CMAKE_CXX_FLAGS:  -Wno-noexcept-type  -fdiagnostics-color=always  -Wall -Wno-conversion -Wno-sign-conversion -Wunused-result -fno-semantic-interposition -msse4.2 -march=core2
-- CMAKE_C_FLAGS_DEBUG: -g -Werror -O0 -ggdb
-- CMAKE_CXX_FLAGS_DEBUG: -g -Werror -O0 -ggdb
-- Looking for backtrace
-- Looking for backtrace - found
-- backtrace facility detected in default set of libraries
-- Found Backtrace: /usr/include  
-- ---------------------------------------------------------------------
-- Arrow version:                                 13.0.0-SNAPSHOT
-- 
-- Build configuration summary:
--   Generator: Ninja
--   Build type: DEBUG
--   Source directory: /home/tdhock/arrow-git/cpp
--   Install prefix: /home/tdhock
-- 
-- Compile and link options:
-- 
--   ARROW_CXXFLAGS=-march=core2 [default=""]
--       Compiler flags to append when compiling Arrow
--   ARROW_BUILD_STATIC=OFF [default=ON]
--       Build static libraries
--   ARROW_BUILD_SHARED=ON [default=ON]
--       Build shared libraries
--   ARROW_PACKAGE_KIND="" [default=""]
--       Arbitrary string that identifies the kind of package
--       (for informational purposes)
--   ARROW_GIT_ID=6d3fe6bda1c3b67b683ada2327194adeed09e9ca [default=""]
--       The Arrow git commit id (if any)
--   ARROW_GIT_DESCRIPTION=apache-arrow-13.0.0.dev-46-g6d3fe6bda [default=""]
--       The Arrow git commit description (if any)
--   ARROW_NO_DEPRECATED_API=OFF [default=OFF]
--       Exclude deprecated APIs from build
--   ARROW_POSITION_INDEPENDENT_CODE=ON [default=ON]
--       Whether to create position-independent target
--   ARROW_USE_CCACHE=ON [default=ON]
--       Use ccache when compiling (if available)
--   ARROW_USE_SCCACHE=ON [default=ON]
--       Use sccache when compiling (if available),
--       takes precedence over ccache if a storage backend is configured
--   ARROW_USE_LD_GOLD=OFF [default=OFF]
--       Use ld.gold for linking on Linux (if available)
--   ARROW_USE_PRECOMPILED_HEADERS=OFF [default=OFF]
--       Use precompiled headers when compiling
--   ARROW_SIMD_LEVEL=SSE4_2 [default=NONE|SSE4_2|AVX2|AVX512|NEON|SVE|SVE128|SVE256|SVE512|DEFAULT]
--       Compile-time SIMD optimization level
--   ARROW_RUNTIME_SIMD_LEVEL=MAX [default=NONE|SSE4_2|AVX2|AVX512|MAX]
--       Max runtime SIMD optimization level
--   ARROW_ALTIVEC=ON [default=ON]
--       Build with Altivec if compiler has support
--   ARROW_RPATH_ORIGIN=OFF [default=OFF]
--       Build Arrow libraries with RATH set to $ORIGIN
--   ARROW_INSTALL_NAME_RPATH=ON [default=ON]
--       Build Arrow libraries with install_name set to @rpath
--   ARROW_GGDB_DEBUG=ON [default=ON]
--       Pass -ggdb flag to debug builds
--   ARROW_WITH_MUSL=OFF [default=OFF]
--       Whether the system libc is musl or not
-- 
-- Test and benchmark options:
-- 
--   ARROW_BUILD_EXAMPLES=OFF [default=OFF]
--       Build the Arrow examples
--   ARROW_BUILD_TESTS=OFF [default=OFF]
--       Build the Arrow googletest unit tests
--   ARROW_ENABLE_TIMING_TESTS=ON [default=ON]
--       Enable timing-sensitive tests
--   ARROW_BUILD_INTEGRATION=OFF [default=OFF]
--       Build the Arrow integration test executables
--   ARROW_BUILD_BENCHMARKS=OFF [default=OFF]
--       Build the Arrow micro benchmarks
--   ARROW_BUILD_BENCHMARKS_REFERENCE=OFF [default=OFF]
--       Build the Arrow micro reference benchmarks
--   ARROW_BUILD_OPENMP_BENCHMARKS=OFF [default=OFF]
--       Build the Arrow benchmarks that rely on OpenMP
--   ARROW_BUILD_DETAILED_BENCHMARKS=OFF [default=OFF]
--       Build benchmarks that do a longer exploration of performance
--   ARROW_TEST_LINKAGE=shared [default=shared|static]
--       Linkage of Arrow libraries with unit tests executables.
--   ARROW_FUZZING=OFF [default=OFF]
--       Build Arrow Fuzzing executables
--   ARROW_LARGE_MEMORY_TESTS=OFF [default=OFF]
--       Enable unit tests which use large memory
-- 
-- Lint options:
-- 
--   ARROW_ONLY_LINT=OFF [default=OFF]
--       Only define the lint and check-format targets
--   ARROW_VERBOSE_LINT=OFF [default=OFF]
--       If off, 'quiet' flags will be passed to linting tools
--   ARROW_GENERATE_COVERAGE=OFF [default=OFF]
--       Build with C++ code coverage enabled
-- 
-- Checks options:
-- 
--   ARROW_TEST_MEMCHECK=OFF [default=OFF]
--       Run the test suite using valgrind --tool=memcheck
--   ARROW_USE_ASAN=OFF [default=OFF]
--       Enable Address Sanitizer checks
--   ARROW_USE_TSAN=OFF [default=OFF]
--       Enable Thread Sanitizer checks
--   ARROW_USE_UBSAN=OFF [default=OFF]
--       Enable Undefined Behavior sanitizer checks
-- 
-- Project component options:
-- 
--   ARROW_BUILD_UTILITIES=OFF [default=OFF]
--       Build Arrow commandline utilities
--   ARROW_COMPUTE=OFF [default=OFF]
--       Build all Arrow Compute kernels
--   ARROW_CSV=OFF [default=OFF]
--       Build the Arrow CSV Parser Module
--   ARROW_CUDA=OFF [default=OFF]
--       Build the Arrow CUDA extensions (requires CUDA toolkit)
--   ARROW_DATASET=OFF [default=OFF]
--       Build the Arrow Dataset Modules
--   ARROW_FILESYSTEM=OFF [default=OFF]
--       Build the Arrow Filesystem Layer
--   ARROW_FLIGHT=OFF [default=OFF]
--       Build the Arrow Flight RPC System (requires GRPC, Protocol Buffers)
--   ARROW_FLIGHT_SQL=OFF [default=OFF]
--       Build the Arrow Flight SQL extension
--   ARROW_GANDIVA=OFF [default=OFF]
--       Build the Gandiva libraries
--   ARROW_GCS=OFF [default=OFF]
--       Build Arrow with GCS support (requires the GCloud SDK for C++)
--   ARROW_HDFS=OFF [default=OFF]
--       Build the Arrow HDFS bridge
--   ARROW_IPC=ON [default=ON]
--       Build the Arrow IPC extensions
--   ARROW_JEMALLOC=ON [default=ON]
--       Build the Arrow jemalloc-based allocator
--   ARROW_JSON=OFF [default=OFF]
--       Build Arrow with JSON support (requires RapidJSON)
--   ARROW_MIMALLOC=OFF [default=OFF]
--       Build the Arrow mimalloc-based allocator
--   ARROW_PARQUET=OFF [default=OFF]
--       Build the Parquet libraries
--   ARROW_ORC=OFF [default=OFF]
--       Build the Arrow ORC adapter
--   ARROW_PYTHON=OFF [default=OFF]
--       Build some components needed by PyArrow.
--       (This is a deprecated option. Use CMake presets instead.)
--   ARROW_S3=OFF [default=OFF]
--       Build Arrow with S3 support (requires the AWS SDK for C++)
--   ARROW_SKYHOOK=OFF [default=OFF]
--       Build the Skyhook libraries
--   ARROW_SUBSTRAIT=OFF [default=OFF]
--       Build the Arrow Substrait Consumer Module
--   ARROW_ACERO=OFF [default=OFF]
--       Build the Arrow Acero Engine Module
--   ARROW_TENSORFLOW=OFF [default=OFF]
--       Build Arrow with TensorFlow support enabled
--   ARROW_TESTING=OFF [default=OFF]
--       Build the Arrow testing libraries
-- 
-- Thirdparty toolchain options:
-- 
--   ARROW_DEPENDENCY_SOURCE=CONDA [default=AUTO|BUNDLED|SYSTEM|CONDA|VCPKG|BREW]
--       Method to use for acquiring arrow's build dependencies
--   ARROW_VERBOSE_THIRDPARTY_BUILD=OFF [default=OFF]
--       Show output from ExternalProjects rather than just logging to files
--   ARROW_DEPENDENCY_USE_SHARED=ON [default=ON]
--       Link to shared libraries
--   ARROW_BOOST_USE_SHARED=ON [default=ON]
--       Rely on Boost shared libraries where relevant
--   ARROW_BROTLI_USE_SHARED=ON [default=ON]
--       Rely on Brotli shared libraries where relevant
--   ARROW_BZ2_USE_SHARED=ON [default=ON]
--       Rely on Bz2 shared libraries where relevant
--   ARROW_GFLAGS_USE_SHARED=ON [default=ON]
--       Rely on GFlags shared libraries where relevant
--   ARROW_GRPC_USE_SHARED=ON [default=ON]
--       Rely on gRPC shared libraries where relevant
--   ARROW_JEMALLOC_USE_SHARED=OFF [default=ON]
--       Rely on jemalloc shared libraries where relevant
--   ARROW_LZ4_USE_SHARED=ON [default=ON]
--       Rely on lz4 shared libraries where relevant
--   ARROW_OPENSSL_USE_SHARED=ON [default=ON]
--       Rely on OpenSSL shared libraries where relevant
--   ARROW_PROTOBUF_USE_SHARED=ON [default=ON]
--       Rely on Protocol Buffers shared libraries where relevant
--   ARROW_SNAPPY_USE_SHARED=ON [default=ON]
--       Rely on snappy shared libraries where relevant
--   ARROW_THRIFT_USE_SHARED=ON [default=ON]
--       Rely on thrift shared libraries where relevant
--   ARROW_UTF8PROC_USE_SHARED=ON [default=ON]
--       Rely on utf8proc shared libraries where relevant
--   ARROW_ZSTD_USE_SHARED=ON [default=ON]
--       Rely on zstd shared libraries where relevant
--   ARROW_USE_GLOG=OFF [default=OFF]
--       Build libraries with glog support for pluggable logging
--   ARROW_WITH_BACKTRACE=ON [default=ON]
--       Build with backtrace support
--   ARROW_WITH_OPENTELEMETRY=OFF [default=OFF]
--       Build libraries with OpenTelemetry support for distributed tracing
--   ARROW_WITH_BROTLI=OFF [default=OFF]
--       Build with Brotli compression
--   ARROW_WITH_BZ2=OFF [default=OFF]
--       Build with BZ2 compression
--   ARROW_WITH_LZ4=OFF [default=OFF]
--       Build with lz4 compression
--   ARROW_WITH_SNAPPY=OFF [default=OFF]
--       Build with Snappy compression
--   ARROW_WITH_ZLIB=OFF [default=OFF]
--       Build with zlib compression
--   ARROW_WITH_ZSTD=OFF [default=OFF]
--       Build with zstd compression
--   ARROW_WITH_UCX=OFF [default=OFF]
--       Build with UCX transport for Arrow Flight
--       (only used if ARROW_FLIGHT is ON)
--   ARROW_WITH_UTF8PROC=OFF [default=ON]
--       Build with support for Unicode properties using the utf8proc library
--       (only used if ARROW_COMPUTE is ON or ARROW_GANDIVA is ON)
--   ARROW_WITH_RE2=OFF [default=ON]
--       Build with support for regular expressions using the re2 library
--       (only used if ARROW_COMPUTE or ARROW_GANDIVA is ON)
-- 
-- Parquet options:
-- 
--   PARQUET_MINIMAL_DEPENDENCY=OFF [default=OFF]
--       Depend only on Thirdparty headers to build libparquet.
--       Always OFF if building binaries
--   PARQUET_BUILD_EXECUTABLES=OFF [default=OFF]
--       Build the Parquet executable CLI tools. Requires static libraries to be built.
--   PARQUET_BUILD_EXAMPLES=OFF [default=OFF]
--       Build the Parquet examples. Requires static libraries to be built.
--   PARQUET_REQUIRE_ENCRYPTION=OFF [default=OFF]
--       Build support for encryption. Fail if OpenSSL is not found
-- 
-- Gandiva options:
-- 
--   ARROW_GANDIVA_STATIC_LIBSTDCPP=OFF [default=OFF]
--       Include -static-libstdc++ -static-libgcc when linking with
--       Gandiva static libraries
--   ARROW_GANDIVA_PC_CXX_FLAGS="" [default=""]
--       Compiler flags to append when pre-compiling Gandiva operations
-- 
-- Advanced developer options:
-- 
--   ARROW_EXTRA_ERROR_CONTEXT=ON [default=OFF]
--       Compile with extra error context (line numbers, code)
--   ARROW_OPTIONAL_INSTALL=OFF [default=OFF]
--       If enabled install ONLY targets that have already been built. Please be
--       advised that if this is enabled 'install' will fail silently on components
--       that have not been built
--   ARROW_GDB_INSTALL_DIR="" [default=""]
--       Use a custom install directory for GDB plugin.
--       In general, you don't need to specify this because the default
--       (CMAKE_INSTALL_FULL_BINDIR on Windows, CMAKE_INSTALL_FULL_LIBDIR otherwise)
--       is reasonable.
--   Outputting build configuration summary to /home/tdhock/arrow-git/cpp/build/cmake_summary.json
-- Configuring done
-- Generating done
-- Build files have been written to: /home/tdhock/arrow-git/cpp/build
(arrow) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main)$ /home/tdhock/.local/share/r-miniconda/envs/arrow/bin/cmake --version
cmake version 3.22.1

CMake suite maintained and supported by Kitware (kitware.com/cmake).
(arrow) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main)$ /usr/bin/cmake --version
cmake version 3.10.2

CMake suite maintained and supported by Kitware (kitware.com/cmake).
(arrow) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main)$ cmake --build .
[1/183] Creating directories for 'jemalloc_ep'
[2/183] Performing download step (download, verify and extract) for 'jemalloc_ep'
[3/183] No update step for 'jemalloc_ep'
[4/183] Performing patch step for 'jemalloc_ep'
[5/183] Performing configure step for 'jemalloc_ep'
[6/183] Performing build step for 'jemalloc_ep'
[7/183] Performing install step for 'jemalloc_ep'
[8/183] Completed 'jemalloc_ep'
[9/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/array_decimal.cc.o
[10/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/array_binary.cc.o
[11/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/array_nested.cc.o
[12/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/array_primitive.cc.o
[13/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/array_base.cc.o
[14/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/array_dict.cc.o
[15/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/array_run_end.cc.o
[16/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/builder_adaptive.cc.o
[17/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/builder_decimal.cc.o
[18/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/builder_binary.cc.o
[19/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/builder_base.cc.o
[20/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/builder_run_end.cc.o
[21/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/builder_nested.cc.o
[22/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/builder_dict.cc.o
[23/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/builder_primitive.cc.o
[24/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/builder_union.cc.o
[25/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/data.cc.o
[26/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/concatenate.cc.o
[27/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/validate.cc.o
[28/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/diff.cc.o
[29/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/buffer.cc.o
[30/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/util.cc.o
[31/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/chunk_resolver.cc.o
[32/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/chunked_array.cc.o
[33/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/config.cc.o
[34/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compare.cc.o
[35/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/device.cc.o
[36/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/datum.cc.o
[37/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/extension_type.cc.o
[38/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/memory_pool.cc.o
[39/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/builder.cc.o
[40/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/record_batch.cc.o
[41/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/pretty_print.cc.o
[42/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/result.cc.o
[43/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/status.cc.o
[44/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/sparse_tensor.cc.o
[45/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/table.cc.o
[46/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/table_builder.cc.o
[47/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/tensor.cc.o
[48/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/tensor/coo_converter.cc.o
[49/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/tensor/csf_converter.cc.o
[50/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/tensor/csx_converter.cc.o
[51/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/visitor.cc.o
[52/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/scalar.cc.o
[53/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/buffered.cc.o
[54/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/c/bridge.cc.o
[55/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/type.cc.o
[56/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/caching.cc.o
[57/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/hdfs.cc.o
[58/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/compressed.cc.o
[59/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/file.cc.o
[60/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/hdfs_internal.cc.o
[61/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/memory.cc.o
[62/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/interfaces.cc.o
[63/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/slow.cc.o
[64/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/stdio.cc.o
[65/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/transform.cc.o
[66/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/align_util.cc.o
[67/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/atfork_internal.cc.o
[68/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/basic_decimal.cc.o
[69/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/async_util.cc.o
[70/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/bit_block_counter.cc.o
[71/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/bit_run_reader.cc.o
[72/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/bit_util.cc.o
[73/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/bitmap_builders.cc.o
[74/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/bitmap.cc.o
[75/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/bitmap_ops.cc.o
[76/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/bpacking.cc.o
[77/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/cancel.cc.o
[78/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/compression.cc.o
[79/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/counting_semaphore.cc.o
[80/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/byte_size.cc.o
[81/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/debug.cc.o
[82/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/crc32.cc.o
[83/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/cpu_info.cc.o
[84/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/delimiting.cc.o
[85/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/formatting.cc.o
[86/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/decimal.cc.o
[87/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/future.cc.o
[88/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/logging.cc.o
[89/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/int_util.cc.o
[90/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/io_util.cc.o
[91/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/key_value_metadata.cc.o
[92/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/mutex.cc.o
[93/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/memory.cc.o
[94/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/string.cc.o
[95/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/string_builder.cc.o
[96/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/ree_util.cc.o
[97/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/tdigest.cc.o
[98/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/task_group.cc.o
[99/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/time.cc.o
[100/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/tracing.cc.o
[101/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/trie.cc.o
[102/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/thread_pool.cc.o
[103/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/unreachable.cc.o
[104/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/union_util.cc.o
[105/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/utf8.cc.o
[106/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/uri.cc.o
[107/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/base64.cpp.o
[108/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/double-conversion/bignum.cc.o
[109/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/value_parsing.cc.o
[110/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/double-conversion/double-conversion.cc.o
[111/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/double-conversion/fast-dtoa.cc.o
[112/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/double-conversion/bignum-dtoa.cc.o
[113/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/double-conversion/fixed-dtoa.cc.o
[114/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/double-conversion/cached-powers.cc.o
[115/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/double-conversion/diy-fp.cc.o
[116/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/double-conversion/strtod.cc.o
[117/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/datetime/tz.cpp.o
[118/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/memory_pool_jemalloc.cc.o
[119/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/bpacking_avx2.cc.o
[120/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/bpacking_avx512.cc.o
[121/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/api_aggregate.cc.o
[122/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/api_vector.cc.o
[123/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/cast.cc.o
[124/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/api_scalar.cc.o
[125/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/exec.cc.o
[126/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/function.cc.o
[127/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/function_internal.cc.o
[128/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/expression.cc.o
[129/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernel.cc.o
[130/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/key_hash.cc.o
[131/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/key_map.cc.o
[132/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/ordering.cc.o
[133/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/light_array.cc.o
[134/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/registry.cc.o
[135/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/codegen_internal.cc.o
[136/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/ree_util_internal.cc.o
[137/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/row_encoder.cc.o
[138/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/scalar_cast_boolean.cc.o
[139/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/scalar_cast_extension.cc.o
[140/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/scalar_cast_dictionary.cc.o
[141/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/scalar_cast_internal.cc.o
[142/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/scalar_cast_nested.cc.o
[143/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/scalar_cast_numeric.cc.o
[144/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/scalar_cast_temporal.cc.o
[145/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/util_internal.cc.o
[146/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/scalar_cast_string.cc.o
[147/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/row/encode_internal.cc.o
[148/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/row/compare_internal.cc.o
[149/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/vector_selection.cc.o
[150/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/kernels/vector_hash.cc.o
[151/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/row/row_internal.cc.o
[152/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/util.cc.o
[153/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/row/grouper.cc.o
[154/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/key_map_avx2.cc.o
[155/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/key_hash_avx2.cc.o
[156/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/row/compare_internal_avx2.cc.o
[157/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/row/encode_internal_avx2.cc.o
[158/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/compute/util_avx2.cc.o
[159/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/ipc/dictionary.cc.o
[160/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/ipc/feather.cc.o
[161/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/ipc/message.cc.o
[162/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/ipc/options.cc.o
[163/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/ipc/metadata_internal.cc.o
[164/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/musl/strptime.c.o
[165/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriCommon.c.o
[166/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriCompare.c.o
[167/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriEscape.c.o
[168/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriFile.c.o
[169/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriIp4Base.c.o
[170/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriIp4.c.o
[171/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriMemory.c.o
[172/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriNormalizeBase.c.o
[173/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriNormalize.c.o
[174/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriParseBase.c.o
[175/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriParse.c.o
[176/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriQuery.c.o
[177/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriRecompose.c.o
[178/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriResolve.c.o
[179/183] Building C object src/arrow/CMakeFiles/arrow_objlib.dir/vendored/uriparser/UriShorten.c.o
[180/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/ipc/writer.cc.o
[181/183] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/ipc/reader.cc.o
[182/183] Linking CXX shared library debug/libarrow.so.1300.0.0
[183/183] Creating library symlink debug/libarrow.so.1300 debug/libarrow.so
(arrow) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main)$ cmake --install .
-- Install configuration: "DEBUG"
-- Installing: /home/tdhock/include/arrow/util/config.h
-- Installing: /home/tdhock/share/doc/arrow/LICENSE.txt
-- Installing: /home/tdhock/share/doc/arrow/NOTICE.txt
-- Installing: /home/tdhock/share/doc/arrow/README.md
-- Installing: /home/tdhock/share/arrow/gdb/gdb_arrow.py
-- Installing: /home/tdhock/lib/libarrow.so.1300.0.0
-- Installing: /home/tdhock/lib/libarrow.so.1300
-- Installing: /home/tdhock/lib/libarrow.so
-- Installing: /home/tdhock/lib/cmake/Arrow/ArrowConfig.cmake
-- Installing: /home/tdhock/lib/cmake/Arrow/ArrowConfigVersion.cmake
-- Installing: /home/tdhock/lib/cmake/Arrow/ArrowTargets.cmake
-- Installing: /home/tdhock/lib/cmake/Arrow/ArrowTargets-debug.cmake
-- Installing: /home/tdhock/lib/pkgconfig/arrow.pc
-- Installing: /home/tdhock/share/gdb/auto-load/home/tdhock/lib/libarrow.so.1300.0.0-gdb.py
-- Installing: /home/tdhock/include/arrow/api.h
-- Installing: /home/tdhock/include/arrow/array.h
-- Installing: /home/tdhock/include/arrow/buffer.h
-- Installing: /home/tdhock/include/arrow/buffer_builder.h
-- Installing: /home/tdhock/include/arrow/builder.h
-- Installing: /home/tdhock/include/arrow/chunk_resolver.h
-- Installing: /home/tdhock/include/arrow/chunked_array.h
-- Installing: /home/tdhock/include/arrow/compare.h
-- Installing: /home/tdhock/include/arrow/config.h
-- Installing: /home/tdhock/include/arrow/datum.h
-- Installing: /home/tdhock/include/arrow/device.h
-- Installing: /home/tdhock/include/arrow/extension_type.h
-- Installing: /home/tdhock/include/arrow/memory_pool.h
-- Installing: /home/tdhock/include/arrow/memory_pool_test.h
-- Installing: /home/tdhock/include/arrow/pch.h
-- Installing: /home/tdhock/include/arrow/pretty_print.h
-- Installing: /home/tdhock/include/arrow/record_batch.h
-- Installing: /home/tdhock/include/arrow/result.h
-- Installing: /home/tdhock/include/arrow/scalar.h
-- Installing: /home/tdhock/include/arrow/sparse_tensor.h
-- Installing: /home/tdhock/include/arrow/status.h
-- Installing: /home/tdhock/include/arrow/stl.h
-- Installing: /home/tdhock/include/arrow/stl_allocator.h
-- Installing: /home/tdhock/include/arrow/stl_iterator.h
-- Installing: /home/tdhock/include/arrow/table.h
-- Installing: /home/tdhock/include/arrow/table_builder.h
-- Installing: /home/tdhock/include/arrow/tensor.h
-- Installing: /home/tdhock/include/arrow/type.h
-- Installing: /home/tdhock/include/arrow/type_fwd.h
-- Installing: /home/tdhock/include/arrow/type_traits.h
-- Installing: /home/tdhock/include/arrow/visit_array_inline.h
-- Installing: /home/tdhock/include/arrow/visit_data_inline.h
-- Installing: /home/tdhock/include/arrow/visit_scalar_inline.h
-- Installing: /home/tdhock/include/arrow/visit_type_inline.h
-- Installing: /home/tdhock/include/arrow/visitor.h
-- Installing: /home/tdhock/include/arrow/visitor_generate.h
-- Installing: /home/tdhock/lib/cmake/Arrow/ArrowOptions.cmake
-- Installing: /home/tdhock/lib/cmake/Arrow/arrow-config.cmake
-- Installing: /home/tdhock/include/arrow/testing/async_test_util.h
-- Installing: /home/tdhock/include/arrow/testing/builder.h
-- Installing: /home/tdhock/include/arrow/testing/executor_util.h
-- Installing: /home/tdhock/include/arrow/testing/extension_type.h
-- Installing: /home/tdhock/include/arrow/testing/future_util.h
-- Installing: /home/tdhock/include/arrow/testing/generator.h
-- Installing: /home/tdhock/include/arrow/testing/gtest_compat.h
-- Installing: /home/tdhock/include/arrow/testing/gtest_util.h
-- Installing: /home/tdhock/include/arrow/testing/json_integration.h
-- Installing: /home/tdhock/include/arrow/testing/matchers.h
-- Installing: /home/tdhock/include/arrow/testing/pch.h
-- Installing: /home/tdhock/include/arrow/testing/random.h
-- Installing: /home/tdhock/include/arrow/testing/uniform_real.h
-- Installing: /home/tdhock/include/arrow/testing/util.h
-- Installing: /home/tdhock/include/arrow/testing/visibility.h
-- Installing: /home/tdhock/include/arrow/array/array_base.h
-- Installing: /home/tdhock/include/arrow/array/array_binary.h
-- Installing: /home/tdhock/include/arrow/array/array_decimal.h
-- Installing: /home/tdhock/include/arrow/array/array_dict.h
-- Installing: /home/tdhock/include/arrow/array/array_nested.h
-- Installing: /home/tdhock/include/arrow/array/array_primitive.h
-- Installing: /home/tdhock/include/arrow/array/array_run_end.h
-- Installing: /home/tdhock/include/arrow/array/builder_adaptive.h
-- Installing: /home/tdhock/include/arrow/array/builder_base.h
-- Installing: /home/tdhock/include/arrow/array/builder_binary.h
-- Installing: /home/tdhock/include/arrow/array/builder_decimal.h
-- Installing: /home/tdhock/include/arrow/array/builder_dict.h
-- Installing: /home/tdhock/include/arrow/array/builder_nested.h
-- Installing: /home/tdhock/include/arrow/array/builder_primitive.h
-- Installing: /home/tdhock/include/arrow/array/builder_run_end.h
-- Installing: /home/tdhock/include/arrow/array/builder_time.h
-- Installing: /home/tdhock/include/arrow/array/builder_union.h
-- Installing: /home/tdhock/include/arrow/array/concatenate.h
-- Installing: /home/tdhock/include/arrow/array/data.h
-- Installing: /home/tdhock/include/arrow/array/diff.h
-- Installing: /home/tdhock/include/arrow/array/util.h
-- Installing: /home/tdhock/include/arrow/array/validate.h
-- Installing: /home/tdhock/include/arrow/c/abi.h
-- Installing: /home/tdhock/include/arrow/c/bridge.h
-- Installing: /home/tdhock/include/arrow/c/helpers.h
-- Installing: /home/tdhock/include/arrow/compute/api.h
-- Installing: /home/tdhock/include/arrow/compute/api_aggregate.h
-- Installing: /home/tdhock/include/arrow/compute/api_scalar.h
-- Installing: /home/tdhock/include/arrow/compute/api_vector.h
-- Installing: /home/tdhock/include/arrow/compute/cast.h
-- Installing: /home/tdhock/include/arrow/compute/exec.h
-- Installing: /home/tdhock/include/arrow/compute/expression.h
-- Installing: /home/tdhock/include/arrow/compute/function.h
-- Installing: /home/tdhock/include/arrow/compute/kernel.h
-- Installing: /home/tdhock/include/arrow/compute/key_hash.h
-- Installing: /home/tdhock/include/arrow/compute/key_map.h
-- Installing: /home/tdhock/include/arrow/compute/light_array.h
-- Installing: /home/tdhock/include/arrow/compute/ordering.h
-- Installing: /home/tdhock/include/arrow/compute/registry.h
-- Installing: /home/tdhock/include/arrow/compute/type_fwd.h
-- Installing: /home/tdhock/include/arrow/compute/util.h
-- Installing: /home/tdhock/lib/pkgconfig/arrow-compute.pc
-- Installing: /home/tdhock/include/arrow/compute/row/grouper.h
-- Installing: /home/tdhock/include/arrow/io/api.h
-- Installing: /home/tdhock/include/arrow/io/buffered.h
-- Installing: /home/tdhock/include/arrow/io/caching.h
-- Installing: /home/tdhock/include/arrow/io/compressed.h
-- Installing: /home/tdhock/include/arrow/io/concurrency.h
-- Installing: /home/tdhock/include/arrow/io/file.h
-- Installing: /home/tdhock/include/arrow/io/hdfs.h
-- Installing: /home/tdhock/include/arrow/io/interfaces.h
-- Installing: /home/tdhock/include/arrow/io/memory.h
-- Installing: /home/tdhock/include/arrow/io/mman.h
-- Installing: /home/tdhock/include/arrow/io/slow.h
-- Installing: /home/tdhock/include/arrow/io/stdio.h
-- Installing: /home/tdhock/include/arrow/io/test_common.h
-- Installing: /home/tdhock/include/arrow/io/transform.h
-- Installing: /home/tdhock/include/arrow/io/type_fwd.h
-- Installing: /home/tdhock/include/arrow/tensor/converter.h
-- Installing: /home/tdhock/include/arrow/util/algorithm.h
-- Installing: /home/tdhock/include/arrow/util/align_util.h
-- Installing: /home/tdhock/include/arrow/util/aligned_storage.h
-- Installing: /home/tdhock/include/arrow/util/async_generator.h
-- Installing: /home/tdhock/include/arrow/util/async_generator_fwd.h
-- Installing: /home/tdhock/include/arrow/util/async_util.h
-- Installing: /home/tdhock/include/arrow/util/base64.h
-- Installing: /home/tdhock/include/arrow/util/basic_decimal.h
-- Installing: /home/tdhock/include/arrow/util/benchmark_util.h
-- Installing: /home/tdhock/include/arrow/util/bit_block_counter.h
-- Installing: /home/tdhock/include/arrow/util/bit_run_reader.h
-- Installing: /home/tdhock/include/arrow/util/bit_stream_utils.h
-- Installing: /home/tdhock/include/arrow/util/bit_util.h
-- Installing: /home/tdhock/include/arrow/util/bitmap.h
-- Installing: /home/tdhock/include/arrow/util/bitmap_builders.h
-- Installing: /home/tdhock/include/arrow/util/bitmap_generate.h
-- Installing: /home/tdhock/include/arrow/util/bitmap_ops.h
-- Installing: /home/tdhock/include/arrow/util/bitmap_reader.h
-- Installing: /home/tdhock/include/arrow/util/bitmap_visit.h
-- Installing: /home/tdhock/include/arrow/util/bitmap_writer.h
-- Installing: /home/tdhock/include/arrow/util/bitset_stack.h
-- Installing: /home/tdhock/include/arrow/util/bpacking.h
-- Installing: /home/tdhock/include/arrow/util/bpacking64_default.h
-- Installing: /home/tdhock/include/arrow/util/bpacking_avx2.h
-- Installing: /home/tdhock/include/arrow/util/bpacking_avx512.h
-- Installing: /home/tdhock/include/arrow/util/bpacking_default.h
-- Installing: /home/tdhock/include/arrow/util/bpacking_neon.h
-- Installing: /home/tdhock/include/arrow/util/bpacking_simd128_generated.h
-- Installing: /home/tdhock/include/arrow/util/bpacking_simd256_generated.h
-- Installing: /home/tdhock/include/arrow/util/bpacking_simd512_generated.h
-- Installing: /home/tdhock/include/arrow/util/byte_size.h
-- Installing: /home/tdhock/include/arrow/util/byte_stream_split.h
-- Installing: /home/tdhock/include/arrow/util/bytes_view.h
-- Installing: /home/tdhock/include/arrow/util/cancel.h
-- Installing: /home/tdhock/include/arrow/util/checked_cast.h
-- Installing: /home/tdhock/include/arrow/util/compare.h
-- Installing: /home/tdhock/include/arrow/util/compression.h
-- Installing: /home/tdhock/include/arrow/util/concurrent_map.h
-- Installing: /home/tdhock/include/arrow/util/config.h
-- Installing: /home/tdhock/include/arrow/util/converter.h
-- Installing: /home/tdhock/include/arrow/util/counting_semaphore.h
-- Installing: /home/tdhock/include/arrow/util/cpu_info.h
-- Installing: /home/tdhock/include/arrow/util/crc32.h
-- Installing: /home/tdhock/include/arrow/util/debug.h
-- Installing: /home/tdhock/include/arrow/util/decimal.h
-- Installing: /home/tdhock/include/arrow/util/delimiting.h
-- Installing: /home/tdhock/include/arrow/util/dispatch.h
-- Installing: /home/tdhock/include/arrow/util/double_conversion.h
-- Installing: /home/tdhock/include/arrow/util/endian.h
-- Installing: /home/tdhock/include/arrow/util/formatting.h
-- Installing: /home/tdhock/include/arrow/util/functional.h
-- Installing: /home/tdhock/include/arrow/util/future.h
-- Installing: /home/tdhock/include/arrow/util/hash_util.h
-- Installing: /home/tdhock/include/arrow/util/hashing.h
-- Installing: /home/tdhock/include/arrow/util/int_util.h
-- Installing: /home/tdhock/include/arrow/util/int_util_overflow.h
-- Installing: /home/tdhock/include/arrow/util/io_util.h
-- Installing: /home/tdhock/include/arrow/util/iterator.h
-- Installing: /home/tdhock/include/arrow/util/key_value_metadata.h
-- Installing: /home/tdhock/include/arrow/util/launder.h
-- Installing: /home/tdhock/include/arrow/util/logging.h
-- Installing: /home/tdhock/include/arrow/util/macros.h
-- Installing: /home/tdhock/include/arrow/util/map.h
-- Installing: /home/tdhock/include/arrow/util/math_constants.h
-- Installing: /home/tdhock/include/arrow/util/memory.h
-- Installing: /home/tdhock/include/arrow/util/mutex.h
-- Installing: /home/tdhock/include/arrow/util/parallel.h
-- Installing: /home/tdhock/include/arrow/util/pcg_random.h
-- Installing: /home/tdhock/include/arrow/util/print.h
-- Installing: /home/tdhock/include/arrow/util/queue.h
-- Installing: /home/tdhock/include/arrow/util/range.h
-- Installing: /home/tdhock/include/arrow/util/ree_util.h
-- Installing: /home/tdhock/include/arrow/util/regex.h
-- Installing: /home/tdhock/include/arrow/util/rle_encoding.h
-- Installing: /home/tdhock/include/arrow/util/rows_to_batches.h
-- Installing: /home/tdhock/include/arrow/util/simd.h
-- Installing: /home/tdhock/include/arrow/util/small_vector.h
-- Installing: /home/tdhock/include/arrow/util/sort.h
-- Installing: /home/tdhock/include/arrow/util/spaced.h
-- Installing: /home/tdhock/include/arrow/util/stopwatch.h
-- Installing: /home/tdhock/include/arrow/util/string.h
-- Installing: /home/tdhock/include/arrow/util/string_builder.h
-- Installing: /home/tdhock/include/arrow/util/task_group.h
-- Installing: /home/tdhock/include/arrow/util/tdigest.h
-- Installing: /home/tdhock/include/arrow/util/test_common.h
-- Installing: /home/tdhock/include/arrow/util/thread_pool.h
-- Installing: /home/tdhock/include/arrow/util/time.h
-- Installing: /home/tdhock/include/arrow/util/tracing.h
-- Installing: /home/tdhock/include/arrow/util/trie.h
-- Installing: /home/tdhock/include/arrow/util/type_fwd.h
-- Installing: /home/tdhock/include/arrow/util/type_traits.h
-- Installing: /home/tdhock/include/arrow/util/ubsan.h
-- Installing: /home/tdhock/include/arrow/util/union_util.h
-- Installing: /home/tdhock/include/arrow/util/unreachable.h
-- Installing: /home/tdhock/include/arrow/util/uri.h
-- Installing: /home/tdhock/include/arrow/util/utf8.h
-- Installing: /home/tdhock/include/arrow/util/value_parsing.h
-- Installing: /home/tdhock/include/arrow/util/vector.h
-- Installing: /home/tdhock/include/arrow/util/visibility.h
-- Installing: /home/tdhock/include/arrow/util/windows_compatibility.h
-- Installing: /home/tdhock/include/arrow/util/windows_fixup.h
-- Installing: /home/tdhock/include/arrow/vendored/ProducerConsumerQueue.h
-- Installing: /home/tdhock/include/arrow/vendored/datetime.h
-- Installing: /home/tdhock/include/arrow/vendored/strptime.h
-- Installing: /home/tdhock/include/arrow/vendored/xxhash.h
-- Installing: /home/tdhock/include/arrow/vendored/datetime/date.h
-- Installing: /home/tdhock/include/arrow/vendored/datetime/ios.h
-- Installing: /home/tdhock/include/arrow/vendored/datetime/tz.h
-- Installing: /home/tdhock/include/arrow/vendored/datetime/tz_private.h
-- Installing: /home/tdhock/include/arrow/vendored/datetime/visibility.h
-- Installing: /home/tdhock/include/arrow/vendored/double-conversion/bignum-dtoa.h
-- Installing: /home/tdhock/include/arrow/vendored/double-conversion/bignum.h
-- Installing: /home/tdhock/include/arrow/vendored/double-conversion/cached-powers.h
-- Installing: /home/tdhock/include/arrow/vendored/double-conversion/diy-fp.h
-- Installing: /home/tdhock/include/arrow/vendored/double-conversion/double-conversion.h
-- Installing: /home/tdhock/include/arrow/vendored/double-conversion/fast-dtoa.h
-- Installing: /home/tdhock/include/arrow/vendored/double-conversion/fixed-dtoa.h
-- Installing: /home/tdhock/include/arrow/vendored/double-conversion/ieee.h
-- Installing: /home/tdhock/include/arrow/vendored/double-conversion/strtod.h
-- Installing: /home/tdhock/include/arrow/vendored/double-conversion/utils.h
-- Installing: /home/tdhock/include/arrow/vendored/pcg/pcg_extras.hpp
-- Installing: /home/tdhock/include/arrow/vendored/pcg/pcg_random.hpp
-- Installing: /home/tdhock/include/arrow/vendored/pcg/pcg_uint128.hpp
-- Installing: /home/tdhock/include/arrow/vendored/portable-snippets/debug-trap.h
-- Installing: /home/tdhock/include/arrow/vendored/portable-snippets/safe-math.h
-- Installing: /home/tdhock/include/arrow/vendored/xxhash/xxhash.h
-- Installing: /home/tdhock/include/arrow/ipc/api.h
-- Installing: /home/tdhock/include/arrow/ipc/dictionary.h
-- Installing: /home/tdhock/include/arrow/ipc/feather.h
-- Installing: /home/tdhock/include/arrow/ipc/json_simple.h
-- Installing: /home/tdhock/include/arrow/ipc/message.h
-- Installing: /home/tdhock/include/arrow/ipc/options.h
-- Installing: /home/tdhock/include/arrow/ipc/reader.h
-- Installing: /home/tdhock/include/arrow/ipc/test_common.h
-- Installing: /home/tdhock/include/arrow/ipc/type_fwd.h
-- Installing: /home/tdhock/include/arrow/ipc/util.h
-- Installing: /home/tdhock/include/arrow/ipc/writer.h
(arrow) tdhock@maude-MacBookPro:~/arrow-git/r(main)$ ARROW_DEPENDENCY_SOURCE=SYSTEM ARROW_R_DEV=true LIBARROW_BINARY=false PKG_CONFIG_PATH=$HOME/lib/pkgconfig R CMD INSTALL .
Loading required package: grDevices
* installing to library ‘/home/tdhock/lib/R/library’
* installing *source* package ‘arrow’ ...
** using staged installation
*** Generating code with data-raw/codegen.R
Loading required package: grDevices
Error in library(decor) : there is no package called ‘decor’
Calls: suppressPackageStartupMessages -> withCallingHandlers -> library
Execution halted
*** Trying Arrow C++ found by pkg-config: /home/tdhock
*** > Packages are both on development versions (13.0.0-SNAPSHOT, 12.0.0.9000)
*** > If installation fails, rebuild the C++ library to match the R version
*** > or retry with FORCE_BUNDLED_BUILD=true
PKG_CFLAGS=-I/home/tdhock/include 
PKG_LIBS=-L/home/tdhock/lib -larrow
** libs
using C++ compiler: ‘g++ (GCC) 10.1.0’
using C++17
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -I'/home/tdhock/lib/R/library/cpp11/include' -I/usr/local/include    -fpic  -g -O2  -c RTasks.cpp -o RTasks.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -I'/home/tdhock/lib/R/library/cpp11/include' -I/usr/local/include    -fpic  -g -O2  -c altrep.cpp -o altrep.o
In file included from altrep.cpp:18:
./arrow_types.h:35:10: fatal error: arrow/csv/type_fwd.h: No such file or directory
   35 | #include <arrow/csv/type_fwd.h>
      |          ^~~~~~~~~~~~~~~~~~~~~~
compilation terminated.
/home/tdhock/lib/R/etc/Makeconf:198: recipe for target 'altrep.o' failed
make: *** [altrep.o] Error 1
ERROR: compilation failed for package ‘arrow’
* removing ‘/home/tdhock/lib/R/library/arrow’
* restoring previous ‘/home/tdhock/lib/R/library/arrow’
```

The installation of the R package above fails. I guess this is because
we used the minimal preset, which I suppose does not include
`arrow/csv/*` files (they were not reported when running the install
command). So below we try a non-minimal installation. 
Need to do conda install xsimd boost gflags openssl rapidjson thrift-cpp cmake (not thrift).

```
(arrow) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main)$ CC=$HOME/bin/gcc CXX=$HOME/bin/g++ cmake .. --preset ninja-debug-basic -DCMAKE_INSTALL_PREFIX=$HOME -DARROW_CXXFLAGS=-march=core2
Preset CMake variables:

  ARROW_BUILD_INTEGRATION="ON"
  ARROW_BUILD_STATIC="OFF"
  ARROW_BUILD_TESTS="ON"
  ARROW_COMPUTE="ON"
  ARROW_CSV="ON"
  ARROW_DATASET="ON"
  ARROW_EXTRA_ERROR_CONTEXT="ON"
  ARROW_FILESYSTEM="ON"
  ARROW_JSON="ON"
  ARROW_WITH_RE2="OFF"
  ARROW_WITH_UTF8PROC="OFF"
  CMAKE_BUILD_TYPE="Debug"

-- Building using CMake version: 3.22.1
-- Arrow version: 13.0.0 (full: '13.0.0-SNAPSHOT')
-- Arrow SO version: 1300 (full: 1300.0.0)
-- clang-tidy 14 not found
-- clang-format 14 not found
-- Could NOT find ClangTools (missing: CLANG_FORMAT_BIN CLANG_TIDY_BIN) 
-- infer not found
-- Found cpplint executable at /home/tdhock/arrow-git/cpp/build-support/cpplint.py
-- System processor: x86_64
-- Arrow build warning level: CHECKIN
-- Using ld linker
-- Build Type: DEBUG
-- Using CONDA approach to find dependencies
-- Using CONDA_PREFIX for ARROW_PACKAGE_PREFIX: /home/tdhock/.local/share/r-miniconda/envs/arrow
-- Setting (unset) dependency *_ROOT variables: /home/tdhock/.local/share/r-miniconda/envs/arrow
-- ARROW_ABSL_BUILD_VERSION: 20211102.0
-- ARROW_ABSL_BUILD_SHA256_CHECKSUM: dcf71b9cba8dc0ca9940c4b316a0c796be8fab42b070bb6b7cab62b48f0e66c4
-- ARROW_AWS_C_AUTH_BUILD_VERSION: v0.6.22
-- ARROW_AWS_C_AUTH_BUILD_SHA256_CHECKSUM: 691a6b4418afcd3dc141351b6ad33fccd8e3ff84df0e9e045b42295d284ee14c
-- ARROW_AWS_C_CAL_BUILD_VERSION: v0.5.20
-- ARROW_AWS_C_CAL_BUILD_SHA256_CHECKSUM: acc352359bd06f8597415c366cf4ec4f00d0b0da92d637039a73323dd55b6cd0
-- ARROW_AWS_C_COMMON_BUILD_VERSION: v0.8.9
-- ARROW_AWS_C_COMMON_BUILD_SHA256_CHECKSUM: 2f3fbaf7c38eae5a00e2a816d09b81177f93529ae8ba1b82dc8f31407565327a
-- ARROW_AWS_C_COMPRESSION_BUILD_VERSION: v0.2.16
-- ARROW_AWS_C_COMPRESSION_BUILD_SHA256_CHECKSUM: 044b1dbbca431a07bde8255ef9ec443c300fc60d4c9408d4b862f65e496687f4
-- ARROW_AWS_C_EVENT_STREAM_BUILD_VERSION: v0.2.18
-- ARROW_AWS_C_EVENT_STREAM_BUILD_SHA256_CHECKSUM: 310ca617f713bf664e4c7485a3d42c1fb57813abd0107e49790d107def7cde4f
-- ARROW_AWS_C_HTTP_BUILD_VERSION: v0.7.3
-- ARROW_AWS_C_HTTP_BUILD_SHA256_CHECKSUM: 07e16c6bf5eba6f0dea96b6f55eae312a7c95b736f4d2e4a210000f45d8265ae
-- ARROW_AWS_C_IO_BUILD_VERSION: v0.13.14
-- ARROW_AWS_C_IO_BUILD_SHA256_CHECKSUM: 12b66510c3d9a4f7e9b714e9cfab2a5bf835f8b9ce2f909d20ae2a2128608c71
-- ARROW_AWS_C_MQTT_BUILD_VERSION: v0.8.4
-- ARROW_AWS_C_MQTT_BUILD_SHA256_CHECKSUM: 232eeac63e72883d460c686a09b98cdd811d24579affac47c5c3f696f956773f
-- ARROW_AWS_C_S3_BUILD_VERSION: v0.2.3
-- ARROW_AWS_C_S3_BUILD_SHA256_CHECKSUM: a00b3c9f319cd1c9aa2c3fa15098864df94b066dcba0deaccbb3caa952d902fe
-- ARROW_AWS_C_SDKUTILS_BUILD_VERSION: v0.1.6
-- ARROW_AWS_C_SDKUTILS_BUILD_SHA256_CHECKSUM: 8a2951344b2fb541eab1e9ca17c18a7fcbfd2aaff4cdd31d362d1fad96111b91
-- ARROW_AWS_CHECKSUMS_BUILD_VERSION: v0.1.13
-- ARROW_AWS_CHECKSUMS_BUILD_SHA256_CHECKSUM: 0f897686f1963253c5069a0e495b85c31635ba146cd3ac38cc2ea31eaf54694d
-- ARROW_AWS_CRT_CPP_BUILD_VERSION: v0.18.16
-- ARROW_AWS_CRT_CPP_BUILD_SHA256_CHECKSUM: 9e69bc1dc4b50871d1038aa9ff6ddeb4c9b28f7d6b5e5b1b69041ccf50a13483
-- ARROW_AWS_LC_BUILD_VERSION: v1.3.0
-- ARROW_AWS_LC_BUILD_SHA256_CHECKSUM: ae96a3567161552744fc0cae8b4d68ed88b1ec0f3d3c98700070115356da5a37
-- ARROW_AWSSDK_BUILD_VERSION: 1.10.55
-- ARROW_AWSSDK_BUILD_SHA256_CHECKSUM: 2d552fb1a84bef4a9b65e34aa7031851ed2aef5319e02cc6e4cb735c48aa30de
-- ARROW_BOOST_BUILD_VERSION: 1.81.0
-- ARROW_BOOST_BUILD_SHA256_CHECKSUM: 9e0ffae35528c35f90468997bc8d99500bf179cbae355415a89a600c38e13574
-- ARROW_BROTLI_BUILD_VERSION: v1.0.9
-- ARROW_BROTLI_BUILD_SHA256_CHECKSUM: f9e8d81d0405ba66d181529af42a3354f838c939095ff99930da6aa9cdf6fe46
-- ARROW_BZIP2_BUILD_VERSION: 1.0.8
-- ARROW_BZIP2_BUILD_SHA256_CHECKSUM: ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269
-- ARROW_CARES_BUILD_VERSION: 1.17.2
-- ARROW_CARES_BUILD_SHA256_CHECKSUM: 4803c844ce20ce510ef0eb83f8ea41fa24ecaae9d280c468c582d2bb25b3913d
-- ARROW_CRC32C_BUILD_VERSION: 1.1.2
-- ARROW_CRC32C_BUILD_SHA256_CHECKSUM: ac07840513072b7fcebda6e821068aa04889018f24e10e46181068fb214d7e56
-- ARROW_GBENCHMARK_BUILD_VERSION: v1.7.1
-- ARROW_GBENCHMARK_BUILD_SHA256_CHECKSUM: 6430e4092653380d9dc4ccb45a1e2dc9259d581f4866dc0759713126056bc1d7
-- ARROW_GFLAGS_BUILD_VERSION: v2.2.2
-- ARROW_GFLAGS_BUILD_SHA256_CHECKSUM: 34af2f15cf7367513b352bdcd2493ab14ce43692d2dcd9dfc499492966c64dcf
-- ARROW_GLOG_BUILD_VERSION: v0.5.0
-- ARROW_GLOG_BUILD_SHA256_CHECKSUM: eede71f28371bf39aa69b45de23b329d37214016e2055269b3b5e7cfd40b59f5
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_VERSION: v2.8.0
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_SHA256_CHECKSUM: 21fb441b5a670a18bb16b6826be8e0530888d0b94320847c538d46f5a54dddbc
-- ARROW_GRPC_BUILD_VERSION: v1.46.3
-- ARROW_GRPC_BUILD_SHA256_CHECKSUM: d6cbf22cb5007af71b61c6be316a79397469c58c82a942552a62e708bce60964
-- ARROW_GTEST_BUILD_VERSION: 1.11.0
-- ARROW_GTEST_BUILD_SHA256_CHECKSUM: b4870bf121ff7795ba20d20bcdd8627b8e088f2d1dab299a031c1034eddc93d5
-- ARROW_JEMALLOC_BUILD_VERSION: 5.3.0
-- ARROW_JEMALLOC_BUILD_SHA256_CHECKSUM: 2db82d1e7119df3e71b7640219b6dfe84789bc0537983c3b7ac4f7189aecfeaa
-- ARROW_LZ4_BUILD_VERSION: v1.9.4
-- ARROW_LZ4_BUILD_SHA256_CHECKSUM: 0b0e3aa07c8c063ddf40b082bdf7e37a1562bda40a0ff5272957f3e987e0e54b
-- ARROW_MIMALLOC_BUILD_VERSION: v2.0.6
-- ARROW_MIMALLOC_BUILD_SHA256_CHECKSUM: 9f05c94cc2b017ed13698834ac2a3567b6339a8bde27640df5a1581d49d05ce5
-- ARROW_NLOHMANN_JSON_BUILD_VERSION: v3.10.5
-- ARROW_NLOHMANN_JSON_BUILD_SHA256_CHECKSUM: 5daca6ca216495edf89d167f808d1d03c4a4d929cef7da5e10f135ae1540c7e4
-- ARROW_OPENTELEMETRY_BUILD_VERSION: v1.8.1
-- ARROW_OPENTELEMETRY_BUILD_SHA256_CHECKSUM: 3d640201594b07f08dade9cd1017bd0b59674daca26223b560b9bb6bf56264c2
-- ARROW_OPENTELEMETRY_PROTO_BUILD_VERSION: v0.17.0
-- ARROW_OPENTELEMETRY_PROTO_BUILD_SHA256_CHECKSUM: f269fbcb30e17b03caa1decd231ce826e59d7651c0f71c3b28eb5140b4bb5412
-- ARROW_ORC_BUILD_VERSION: 1.8.3
-- ARROW_ORC_BUILD_SHA256_CHECKSUM: a78678ec425c8129d63370cb8a9bacb54186aa66af1e2bec01ce92e7eaf72e20
-- ARROW_PROTOBUF_BUILD_VERSION: v21.3
-- ARROW_PROTOBUF_BUILD_SHA256_CHECKSUM: 2f723218f6cb709ae4cdc4fb5ed56a5951fc5d466f0128ce4c946b8c78c8c49f
-- ARROW_RAPIDJSON_BUILD_VERSION: 232389d4f1012dddec4ef84861face2d2ba85709
-- ARROW_RAPIDJSON_BUILD_SHA256_CHECKSUM: b9290a9a6d444c8e049bd589ab804e0ccf2b05dc5984a19ed5ae75d090064806
-- ARROW_RE2_BUILD_VERSION: 2022-06-01
-- ARROW_RE2_BUILD_SHA256_CHECKSUM: f89c61410a072e5cbcf8c27e3a778da7d6fd2f2b5b1445cd4f4508bee946ab0f
-- ARROW_SNAPPY_BUILD_VERSION: 1.1.9
-- ARROW_SNAPPY_BUILD_SHA256_CHECKSUM: 75c1fbb3d618dd3a0483bff0e26d0a92b495bbe5059c8b4f1c962b478b6e06e7
-- ARROW_SUBSTRAIT_BUILD_VERSION: v0.20.0
-- ARROW_SUBSTRAIT_BUILD_SHA256_CHECKSUM: 5ceaa559ccef29a7825b5e5d4b5e7eed384830294f08bec913feecdd903a94cf
-- ARROW_S2N_TLS_BUILD_VERSION: v1.3.35
-- ARROW_S2N_TLS_BUILD_SHA256_CHECKSUM: 9d32b26e6bfcc058d98248bf8fc231537e347395dd89cf62bb432b55c5da990d
-- ARROW_THRIFT_BUILD_VERSION: 0.16.0
-- ARROW_THRIFT_BUILD_SHA256_CHECKSUM: f460b5c1ca30d8918ff95ea3eb6291b3951cf518553566088f3f2be8981f6209
-- ARROW_UCX_BUILD_VERSION: 1.12.1
-- ARROW_UCX_BUILD_SHA256_CHECKSUM: 9bef31aed0e28bf1973d28d74d9ac4f8926c43ca3b7010bd22a084e164e31b71
-- ARROW_UTF8PROC_BUILD_VERSION: v2.7.0
-- ARROW_UTF8PROC_BUILD_SHA256_CHECKSUM: 4bb121e297293c0fd55f08f83afab6d35d48f0af4ecc07523ad8ec99aa2b12a1
-- ARROW_XSIMD_BUILD_VERSION: 9.0.1
-- ARROW_XSIMD_BUILD_SHA256_CHECKSUM: b1bb5f92167fd3a4f25749db0be7e61ed37e0a5d943490f3accdcd2cd2918cc0
-- ARROW_ZLIB_BUILD_VERSION: 1.2.13
-- ARROW_ZLIB_BUILD_SHA256_CHECKSUM: b3a24de97a8fdbc835b9833169501030b8977031bcb54b3b3ac13740f846ab30
-- ARROW_ZSTD_BUILD_VERSION: 1.5.5
-- ARROW_ZSTD_BUILD_SHA256_CHECKSUM: 9c4396cc829cfae319a6e2615202e82aad41372073482fce286fac78646d3ee4
-- Boost include dir: /usr/include
-- Building without OpenSSL support. Minimum OpenSSL version 1.0.2 required.
-- Building jemalloc from source
-- Could NOT find GTest (missing: GTest_DIR)
-- Building gtest from source
-- RapidJSON found. Headers: /home/tdhock/.local/share/r-miniconda/envs/arrow/include
-- xsimd found. Headers: /home/tdhock/.local/share/r-miniconda/envs/arrow/include
-- Found hdfs.h at: /home/tdhock/arrow-git/cpp/thirdparty/hadoop/include/hdfs.h
-- All bundled static libraries: jemalloc::jemalloc
-- CMAKE_C_FLAGS:   -Wall -Wno-conversion -Wno-sign-conversion -Wunused-result -fno-semantic-interposition -msse4.2 -march=core2
-- CMAKE_CXX_FLAGS:  -Wno-noexcept-type  -fdiagnostics-color=always  -Wall -Wno-conversion -Wno-sign-conversion -Wunused-result -fno-semantic-interposition -msse4.2 -march=core2
-- CMAKE_C_FLAGS_DEBUG: -g -Werror -O0 -ggdb
-- CMAKE_CXX_FLAGS_DEBUG: -g -Werror -O0 -ggdb
-- ---------------------------------------------------------------------
-- Arrow version:                                 13.0.0-SNAPSHOT
-- 
-- Build configuration summary:
--   Generator: Ninja
--   Build type: DEBUG
--   Source directory: /home/tdhock/arrow-git/cpp
--   Install prefix: /home/tdhock
-- 
-- Compile and link options:
-- 
--   ARROW_CXXFLAGS=-march=core2 [default=""]
--       Compiler flags to append when compiling Arrow
--   ARROW_BUILD_STATIC=OFF [default=ON]
--       Build static libraries
--   ARROW_BUILD_SHARED=ON [default=ON]
--       Build shared libraries
--   ARROW_PACKAGE_KIND="" [default=""]
--       Arbitrary string that identifies the kind of package
--       (for informational purposes)
--   ARROW_GIT_ID=6d3fe6bda1c3b67b683ada2327194adeed09e9ca [default=""]
--       The Arrow git commit id (if any)
--   ARROW_GIT_DESCRIPTION=apache-arrow-13.0.0.dev-46-g6d3fe6bda [default=""]
--       The Arrow git commit description (if any)
--   ARROW_NO_DEPRECATED_API=OFF [default=OFF]
--       Exclude deprecated APIs from build
--   ARROW_POSITION_INDEPENDENT_CODE=ON [default=ON]
--       Whether to create position-independent target
--   ARROW_USE_CCACHE=ON [default=ON]
--       Use ccache when compiling (if available)
--   ARROW_USE_SCCACHE=ON [default=ON]
--       Use sccache when compiling (if available),
--       takes precedence over ccache if a storage backend is configured
--   ARROW_USE_LD_GOLD=OFF [default=OFF]
--       Use ld.gold for linking on Linux (if available)
--   ARROW_USE_PRECOMPILED_HEADERS=OFF [default=OFF]
--       Use precompiled headers when compiling
--   ARROW_SIMD_LEVEL=SSE4_2 [default=NONE|SSE4_2|AVX2|AVX512|NEON|SVE|SVE128|SVE256|SVE512|DEFAULT]
--       Compile-time SIMD optimization level
--   ARROW_RUNTIME_SIMD_LEVEL=MAX [default=NONE|SSE4_2|AVX2|AVX512|MAX]
--       Max runtime SIMD optimization level
--   ARROW_ALTIVEC=ON [default=ON]
--       Build with Altivec if compiler has support
--   ARROW_RPATH_ORIGIN=OFF [default=OFF]
--       Build Arrow libraries with RATH set to $ORIGIN
--   ARROW_INSTALL_NAME_RPATH=ON [default=ON]
--       Build Arrow libraries with install_name set to @rpath
--   ARROW_GGDB_DEBUG=ON [default=ON]
--       Pass -ggdb flag to debug builds
--   ARROW_WITH_MUSL=OFF [default=OFF]
--       Whether the system libc is musl or not
-- 
-- Test and benchmark options:
-- 
--   ARROW_BUILD_EXAMPLES=OFF [default=OFF]
--       Build the Arrow examples
--   ARROW_BUILD_TESTS=ON [default=OFF]
--       Build the Arrow googletest unit tests
--   ARROW_ENABLE_TIMING_TESTS=ON [default=ON]
--       Enable timing-sensitive tests
--   ARROW_BUILD_INTEGRATION=ON [default=OFF]
--       Build the Arrow integration test executables
--   ARROW_BUILD_BENCHMARKS=OFF [default=OFF]
--       Build the Arrow micro benchmarks
--   ARROW_BUILD_BENCHMARKS_REFERENCE=OFF [default=OFF]
--       Build the Arrow micro reference benchmarks
--   ARROW_BUILD_OPENMP_BENCHMARKS=OFF [default=OFF]
--       Build the Arrow benchmarks that rely on OpenMP
--   ARROW_BUILD_DETAILED_BENCHMARKS=OFF [default=OFF]
--       Build benchmarks that do a longer exploration of performance
--   ARROW_TEST_LINKAGE=shared [default=shared|static]
--       Linkage of Arrow libraries with unit tests executables.
--   ARROW_FUZZING=OFF [default=OFF]
--       Build Arrow Fuzzing executables
--   ARROW_LARGE_MEMORY_TESTS=OFF [default=OFF]
--       Enable unit tests which use large memory
-- 
-- Lint options:
-- 
--   ARROW_ONLY_LINT=OFF [default=OFF]
--       Only define the lint and check-format targets
--   ARROW_VERBOSE_LINT=OFF [default=OFF]
--       If off, 'quiet' flags will be passed to linting tools
--   ARROW_GENERATE_COVERAGE=OFF [default=OFF]
--       Build with C++ code coverage enabled
-- 
-- Checks options:
-- 
--   ARROW_TEST_MEMCHECK=OFF [default=OFF]
--       Run the test suite using valgrind --tool=memcheck
--   ARROW_USE_ASAN=OFF [default=OFF]
--       Enable Address Sanitizer checks
--   ARROW_USE_TSAN=OFF [default=OFF]
--       Enable Thread Sanitizer checks
--   ARROW_USE_UBSAN=OFF [default=OFF]
--       Enable Undefined Behavior sanitizer checks
-- 
-- Project component options:
-- 
--   ARROW_BUILD_UTILITIES=OFF [default=OFF]
--       Build Arrow commandline utilities
--   ARROW_COMPUTE=ON [default=OFF]
--       Build all Arrow Compute kernels
--   ARROW_CSV=ON [default=OFF]
--       Build the Arrow CSV Parser Module
--   ARROW_CUDA=OFF [default=OFF]
--       Build the Arrow CUDA extensions (requires CUDA toolkit)
--   ARROW_DATASET=ON [default=OFF]
--       Build the Arrow Dataset Modules
--   ARROW_FILESYSTEM=ON [default=OFF]
--       Build the Arrow Filesystem Layer
--   ARROW_FLIGHT=OFF [default=OFF]
--       Build the Arrow Flight RPC System (requires GRPC, Protocol Buffers)
--   ARROW_FLIGHT_SQL=OFF [default=OFF]
--       Build the Arrow Flight SQL extension
--   ARROW_GANDIVA=OFF [default=OFF]
--       Build the Gandiva libraries
--   ARROW_GCS=OFF [default=OFF]
--       Build Arrow with GCS support (requires the GCloud SDK for C++)
--   ARROW_HDFS=OFF [default=OFF]
--       Build the Arrow HDFS bridge
--   ARROW_IPC=ON [default=ON]
--       Build the Arrow IPC extensions
--   ARROW_JEMALLOC=ON [default=ON]
--       Build the Arrow jemalloc-based allocator
--   ARROW_JSON=ON [default=OFF]
--       Build Arrow with JSON support (requires RapidJSON)
--   ARROW_MIMALLOC=OFF [default=OFF]
--       Build the Arrow mimalloc-based allocator
--   ARROW_PARQUET=OFF [default=OFF]
--       Build the Parquet libraries
--   ARROW_ORC=OFF [default=OFF]
--       Build the Arrow ORC adapter
--   ARROW_PYTHON=OFF [default=OFF]
--       Build some components needed by PyArrow.
--       (This is a deprecated option. Use CMake presets instead.)
--   ARROW_S3=OFF [default=OFF]
--       Build Arrow with S3 support (requires the AWS SDK for C++)
--   ARROW_SKYHOOK=OFF [default=OFF]
--       Build the Skyhook libraries
--   ARROW_SUBSTRAIT=OFF [default=OFF]
--       Build the Arrow Substrait Consumer Module
--   ARROW_ACERO=ON [default=OFF]
--       Build the Arrow Acero Engine Module
--   ARROW_TENSORFLOW=OFF [default=OFF]
--       Build Arrow with TensorFlow support enabled
--   ARROW_TESTING=ON [default=OFF]
--       Build the Arrow testing libraries
-- 
-- Thirdparty toolchain options:
-- 
--   ARROW_DEPENDENCY_SOURCE=CONDA [default=AUTO|BUNDLED|SYSTEM|CONDA|VCPKG|BREW]
--       Method to use for acquiring arrow's build dependencies
--   ARROW_VERBOSE_THIRDPARTY_BUILD=OFF [default=OFF]
--       Show output from ExternalProjects rather than just logging to files
--   ARROW_DEPENDENCY_USE_SHARED=ON [default=ON]
--       Link to shared libraries
--   ARROW_BOOST_USE_SHARED=ON [default=ON]
--       Rely on Boost shared libraries where relevant
--   ARROW_BROTLI_USE_SHARED=ON [default=ON]
--       Rely on Brotli shared libraries where relevant
--   ARROW_BZ2_USE_SHARED=ON [default=ON]
--       Rely on Bz2 shared libraries where relevant
--   ARROW_GFLAGS_USE_SHARED=ON [default=ON]
--       Rely on GFlags shared libraries where relevant
--   ARROW_GRPC_USE_SHARED=ON [default=ON]
--       Rely on gRPC shared libraries where relevant
--   ARROW_JEMALLOC_USE_SHARED=OFF [default=ON]
--       Rely on jemalloc shared libraries where relevant
--   ARROW_LZ4_USE_SHARED=ON [default=ON]
--       Rely on lz4 shared libraries where relevant
--   ARROW_OPENSSL_USE_SHARED=ON [default=ON]
--       Rely on OpenSSL shared libraries where relevant
--   ARROW_PROTOBUF_USE_SHARED=ON [default=ON]
--       Rely on Protocol Buffers shared libraries where relevant
--   ARROW_SNAPPY_USE_SHARED=ON [default=ON]
--       Rely on snappy shared libraries where relevant
--   ARROW_THRIFT_USE_SHARED=ON [default=ON]
--       Rely on thrift shared libraries where relevant
--   ARROW_UTF8PROC_USE_SHARED=ON [default=ON]
--       Rely on utf8proc shared libraries where relevant
--   ARROW_ZSTD_USE_SHARED=ON [default=ON]
--       Rely on zstd shared libraries where relevant
--   ARROW_USE_GLOG=OFF [default=OFF]
--       Build libraries with glog support for pluggable logging
--   ARROW_WITH_BACKTRACE=ON [default=ON]
--       Build with backtrace support
--   ARROW_WITH_OPENTELEMETRY=OFF [default=OFF]
--       Build libraries with OpenTelemetry support for distributed tracing
--   ARROW_WITH_BROTLI=OFF [default=OFF]
--       Build with Brotli compression
--   ARROW_WITH_BZ2=OFF [default=OFF]
--       Build with BZ2 compression
--   ARROW_WITH_LZ4=OFF [default=OFF]
--       Build with lz4 compression
--   ARROW_WITH_SNAPPY=OFF [default=OFF]
--       Build with Snappy compression
--   ARROW_WITH_ZLIB=OFF [default=OFF]
--       Build with zlib compression
--   ARROW_WITH_ZSTD=OFF [default=OFF]
--       Build with zstd compression
--   ARROW_WITH_UCX=OFF [default=OFF]
--       Build with UCX transport for Arrow Flight
--       (only used if ARROW_FLIGHT is ON)
--   ARROW_WITH_UTF8PROC=OFF [default=ON]
--       Build with support for Unicode properties using the utf8proc library
--       (only used if ARROW_COMPUTE is ON or ARROW_GANDIVA is ON)
--   ARROW_WITH_RE2=OFF [default=ON]
--       Build with support for regular expressions using the re2 library
--       (only used if ARROW_COMPUTE or ARROW_GANDIVA is ON)
-- 
-- Parquet options:
-- 
--   PARQUET_MINIMAL_DEPENDENCY=OFF [default=OFF]
--       Depend only on Thirdparty headers to build libparquet.
--       Always OFF if building binaries
--   PARQUET_BUILD_EXECUTABLES=OFF [default=OFF]
--       Build the Parquet executable CLI tools. Requires static libraries to be built.
--   PARQUET_BUILD_EXAMPLES=OFF [default=OFF]
--       Build the Parquet examples. Requires static libraries to be built.
--   PARQUET_REQUIRE_ENCRYPTION=OFF [default=OFF]
--       Build support for encryption. Fail if OpenSSL is not found
-- 
-- Gandiva options:
-- 
--   ARROW_GANDIVA_STATIC_LIBSTDCPP=OFF [default=OFF]
--       Include -static-libstdc++ -static-libgcc when linking with
--       Gandiva static libraries
--   ARROW_GANDIVA_PC_CXX_FLAGS="" [default=""]
--       Compiler flags to append when pre-compiling Gandiva operations
-- 
-- Advanced developer options:
-- 
--   ARROW_EXTRA_ERROR_CONTEXT=ON [default=OFF]
--       Compile with extra error context (line numbers, code)
--   ARROW_OPTIONAL_INSTALL=OFF [default=OFF]
--       If enabled install ONLY targets that have already been built. Please be
--       advised that if this is enabled 'install' will fail silently on components
--       that have not been built
--   ARROW_GDB_INSTALL_DIR="" [default=""]
--       Use a custom install directory for GDB plugin.
--       In general, you don't need to specify this because the default
--       (CMAKE_INSTALL_FULL_BINDIR on Windows, CMAKE_INSTALL_FULL_LIBDIR otherwise)
--       is reasonable.
--   Outputting build configuration summary to /home/tdhock/arrow-git/cpp/build/cmake_summary.json
-- Configuring done
-- Generating done
-- Build files have been written to: /home/tdhock/arrow-git/cpp/build
(arrow) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main)$ cmake --build .
[0/1] Re-running CMake...
-- Building using CMake version: 3.22.1
-- Arrow version: 13.0.0 (full: '13.0.0-SNAPSHOT')
-- Arrow SO version: 1300 (full: 1300.0.0)
-- clang-tidy 14 not found
-- clang-format 14 not found
-- Could NOT find ClangTools (missing: CLANG_FORMAT_BIN CLANG_TIDY_BIN) 
-- infer not found
-- Found cpplint executable at /home/tdhock/arrow-git/cpp/build-support/cpplint.py
-- System processor: x86_64
-- Arrow build warning level: CHECKIN
-- Using ld linker
-- Build Type: DEBUG
-- Using CONDA approach to find dependencies
-- Using CONDA_PREFIX for ARROW_PACKAGE_PREFIX: /home/tdhock/.local/share/r-miniconda/envs/arrow
-- Setting (unset) dependency *_ROOT variables: /home/tdhock/.local/share/r-miniconda/envs/arrow
-- ARROW_ABSL_BUILD_VERSION: 20211102.0
-- ARROW_ABSL_BUILD_SHA256_CHECKSUM: dcf71b9cba8dc0ca9940c4b316a0c796be8fab42b070bb6b7cab62b48f0e66c4
-- ARROW_AWS_C_AUTH_BUILD_VERSION: v0.6.22
-- ARROW_AWS_C_AUTH_BUILD_SHA256_CHECKSUM: 691a6b4418afcd3dc141351b6ad33fccd8e3ff84df0e9e045b42295d284ee14c
-- ARROW_AWS_C_CAL_BUILD_VERSION: v0.5.20
-- ARROW_AWS_C_CAL_BUILD_SHA256_CHECKSUM: acc352359bd06f8597415c366cf4ec4f00d0b0da92d637039a73323dd55b6cd0
-- ARROW_AWS_C_COMMON_BUILD_VERSION: v0.8.9
-- ARROW_AWS_C_COMMON_BUILD_SHA256_CHECKSUM: 2f3fbaf7c38eae5a00e2a816d09b81177f93529ae8ba1b82dc8f31407565327a
-- ARROW_AWS_C_COMPRESSION_BUILD_VERSION: v0.2.16
-- ARROW_AWS_C_COMPRESSION_BUILD_SHA256_CHECKSUM: 044b1dbbca431a07bde8255ef9ec443c300fc60d4c9408d4b862f65e496687f4
-- ARROW_AWS_C_EVENT_STREAM_BUILD_VERSION: v0.2.18
-- ARROW_AWS_C_EVENT_STREAM_BUILD_SHA256_CHECKSUM: 310ca617f713bf664e4c7485a3d42c1fb57813abd0107e49790d107def7cde4f
-- ARROW_AWS_C_HTTP_BUILD_VERSION: v0.7.3
-- ARROW_AWS_C_HTTP_BUILD_SHA256_CHECKSUM: 07e16c6bf5eba6f0dea96b6f55eae312a7c95b736f4d2e4a210000f45d8265ae
-- ARROW_AWS_C_IO_BUILD_VERSION: v0.13.14
-- ARROW_AWS_C_IO_BUILD_SHA256_CHECKSUM: 12b66510c3d9a4f7e9b714e9cfab2a5bf835f8b9ce2f909d20ae2a2128608c71
-- ARROW_AWS_C_MQTT_BUILD_VERSION: v0.8.4
-- ARROW_AWS_C_MQTT_BUILD_SHA256_CHECKSUM: 232eeac63e72883d460c686a09b98cdd811d24579affac47c5c3f696f956773f
-- ARROW_AWS_C_S3_BUILD_VERSION: v0.2.3
-- ARROW_AWS_C_S3_BUILD_SHA256_CHECKSUM: a00b3c9f319cd1c9aa2c3fa15098864df94b066dcba0deaccbb3caa952d902fe
-- ARROW_AWS_C_SDKUTILS_BUILD_VERSION: v0.1.6
-- ARROW_AWS_C_SDKUTILS_BUILD_SHA256_CHECKSUM: 8a2951344b2fb541eab1e9ca17c18a7fcbfd2aaff4cdd31d362d1fad96111b91
-- ARROW_AWS_CHECKSUMS_BUILD_VERSION: v0.1.13
-- ARROW_AWS_CHECKSUMS_BUILD_SHA256_CHECKSUM: 0f897686f1963253c5069a0e495b85c31635ba146cd3ac38cc2ea31eaf54694d
-- ARROW_AWS_CRT_CPP_BUILD_VERSION: v0.18.16
-- ARROW_AWS_CRT_CPP_BUILD_SHA256_CHECKSUM: 9e69bc1dc4b50871d1038aa9ff6ddeb4c9b28f7d6b5e5b1b69041ccf50a13483
-- ARROW_AWS_LC_BUILD_VERSION: v1.3.0
-- ARROW_AWS_LC_BUILD_SHA256_CHECKSUM: ae96a3567161552744fc0cae8b4d68ed88b1ec0f3d3c98700070115356da5a37
-- ARROW_AWSSDK_BUILD_VERSION: 1.10.55
-- ARROW_AWSSDK_BUILD_SHA256_CHECKSUM: 2d552fb1a84bef4a9b65e34aa7031851ed2aef5319e02cc6e4cb735c48aa30de
-- ARROW_BOOST_BUILD_VERSION: 1.81.0
-- ARROW_BOOST_BUILD_SHA256_CHECKSUM: 9e0ffae35528c35f90468997bc8d99500bf179cbae355415a89a600c38e13574
-- ARROW_BROTLI_BUILD_VERSION: v1.0.9
-- ARROW_BROTLI_BUILD_SHA256_CHECKSUM: f9e8d81d0405ba66d181529af42a3354f838c939095ff99930da6aa9cdf6fe46
-- ARROW_BZIP2_BUILD_VERSION: 1.0.8
-- ARROW_BZIP2_BUILD_SHA256_CHECKSUM: ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269
-- ARROW_CARES_BUILD_VERSION: 1.17.2
-- ARROW_CARES_BUILD_SHA256_CHECKSUM: 4803c844ce20ce510ef0eb83f8ea41fa24ecaae9d280c468c582d2bb25b3913d
-- ARROW_CRC32C_BUILD_VERSION: 1.1.2
-- ARROW_CRC32C_BUILD_SHA256_CHECKSUM: ac07840513072b7fcebda6e821068aa04889018f24e10e46181068fb214d7e56
-- ARROW_GBENCHMARK_BUILD_VERSION: v1.7.1
-- ARROW_GBENCHMARK_BUILD_SHA256_CHECKSUM: 6430e4092653380d9dc4ccb45a1e2dc9259d581f4866dc0759713126056bc1d7
-- ARROW_GFLAGS_BUILD_VERSION: v2.2.2
-- ARROW_GFLAGS_BUILD_SHA256_CHECKSUM: 34af2f15cf7367513b352bdcd2493ab14ce43692d2dcd9dfc499492966c64dcf
-- ARROW_GLOG_BUILD_VERSION: v0.5.0
-- ARROW_GLOG_BUILD_SHA256_CHECKSUM: eede71f28371bf39aa69b45de23b329d37214016e2055269b3b5e7cfd40b59f5
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_VERSION: v2.8.0
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_SHA256_CHECKSUM: 21fb441b5a670a18bb16b6826be8e0530888d0b94320847c538d46f5a54dddbc
-- ARROW_GRPC_BUILD_VERSION: v1.46.3
-- ARROW_GRPC_BUILD_SHA256_CHECKSUM: d6cbf22cb5007af71b61c6be316a79397469c58c82a942552a62e708bce60964
-- ARROW_GTEST_BUILD_VERSION: 1.11.0
-- ARROW_GTEST_BUILD_SHA256_CHECKSUM: b4870bf121ff7795ba20d20bcdd8627b8e088f2d1dab299a031c1034eddc93d5
-- ARROW_JEMALLOC_BUILD_VERSION: 5.3.0
-- ARROW_JEMALLOC_BUILD_SHA256_CHECKSUM: 2db82d1e7119df3e71b7640219b6dfe84789bc0537983c3b7ac4f7189aecfeaa
-- ARROW_LZ4_BUILD_VERSION: v1.9.4
-- ARROW_LZ4_BUILD_SHA256_CHECKSUM: 0b0e3aa07c8c063ddf40b082bdf7e37a1562bda40a0ff5272957f3e987e0e54b
-- ARROW_MIMALLOC_BUILD_VERSION: v2.0.6
-- ARROW_MIMALLOC_BUILD_SHA256_CHECKSUM: 9f05c94cc2b017ed13698834ac2a3567b6339a8bde27640df5a1581d49d05ce5
-- ARROW_NLOHMANN_JSON_BUILD_VERSION: v3.10.5
-- ARROW_NLOHMANN_JSON_BUILD_SHA256_CHECKSUM: 5daca6ca216495edf89d167f808d1d03c4a4d929cef7da5e10f135ae1540c7e4
-- ARROW_OPENTELEMETRY_BUILD_VERSION: v1.8.1
-- ARROW_OPENTELEMETRY_BUILD_SHA256_CHECKSUM: 3d640201594b07f08dade9cd1017bd0b59674daca26223b560b9bb6bf56264c2
-- ARROW_OPENTELEMETRY_PROTO_BUILD_VERSION: v0.17.0
-- ARROW_OPENTELEMETRY_PROTO_BUILD_SHA256_CHECKSUM: f269fbcb30e17b03caa1decd231ce826e59d7651c0f71c3b28eb5140b4bb5412
-- ARROW_ORC_BUILD_VERSION: 1.8.3
-- ARROW_ORC_BUILD_SHA256_CHECKSUM: a78678ec425c8129d63370cb8a9bacb54186aa66af1e2bec01ce92e7eaf72e20
-- ARROW_PROTOBUF_BUILD_VERSION: v21.3
-- ARROW_PROTOBUF_BUILD_SHA256_CHECKSUM: 2f723218f6cb709ae4cdc4fb5ed56a5951fc5d466f0128ce4c946b8c78c8c49f
-- ARROW_RAPIDJSON_BUILD_VERSION: 232389d4f1012dddec4ef84861face2d2ba85709
-- ARROW_RAPIDJSON_BUILD_SHA256_CHECKSUM: b9290a9a6d444c8e049bd589ab804e0ccf2b05dc5984a19ed5ae75d090064806
-- ARROW_RE2_BUILD_VERSION: 2022-06-01
-- ARROW_RE2_BUILD_SHA256_CHECKSUM: f89c61410a072e5cbcf8c27e3a778da7d6fd2f2b5b1445cd4f4508bee946ab0f
-- ARROW_SNAPPY_BUILD_VERSION: 1.1.9
-- ARROW_SNAPPY_BUILD_SHA256_CHECKSUM: 75c1fbb3d618dd3a0483bff0e26d0a92b495bbe5059c8b4f1c962b478b6e06e7
-- ARROW_SUBSTRAIT_BUILD_VERSION: v0.20.0
-- ARROW_SUBSTRAIT_BUILD_SHA256_CHECKSUM: 5ceaa559ccef29a7825b5e5d4b5e7eed384830294f08bec913feecdd903a94cf
-- ARROW_S2N_TLS_BUILD_VERSION: v1.3.35
-- ARROW_S2N_TLS_BUILD_SHA256_CHECKSUM: 9d32b26e6bfcc058d98248bf8fc231537e347395dd89cf62bb432b55c5da990d
-- ARROW_THRIFT_BUILD_VERSION: 0.16.0
-- ARROW_THRIFT_BUILD_SHA256_CHECKSUM: f460b5c1ca30d8918ff95ea3eb6291b3951cf518553566088f3f2be8981f6209
-- ARROW_UCX_BUILD_VERSION: 1.12.1
-- ARROW_UCX_BUILD_SHA256_CHECKSUM: 9bef31aed0e28bf1973d28d74d9ac4f8926c43ca3b7010bd22a084e164e31b71
-- ARROW_UTF8PROC_BUILD_VERSION: v2.7.0
-- ARROW_UTF8PROC_BUILD_SHA256_CHECKSUM: 4bb121e297293c0fd55f08f83afab6d35d48f0af4ecc07523ad8ec99aa2b12a1
-- ARROW_XSIMD_BUILD_VERSION: 9.0.1
-- ARROW_XSIMD_BUILD_SHA256_CHECKSUM: b1bb5f92167fd3a4f25749db0be7e61ed37e0a5d943490f3accdcd2cd2918cc0
-- ARROW_ZLIB_BUILD_VERSION: 1.2.13
-- ARROW_ZLIB_BUILD_SHA256_CHECKSUM: b3a24de97a8fdbc835b9833169501030b8977031bcb54b3b3ac13740f846ab30
-- ARROW_ZSTD_BUILD_VERSION: 1.5.5
-- ARROW_ZSTD_BUILD_SHA256_CHECKSUM: 9c4396cc829cfae319a6e2615202e82aad41372073482fce286fac78646d3ee4
-- Boost include dir: /usr/include
-- Building without OpenSSL support. Minimum OpenSSL version 1.0.2 required.
-- Building jemalloc from source
-- Could NOT find GTest (missing: GTest_DIR)
-- Building gtest from source
-- RapidJSON found. Headers: /home/tdhock/.local/share/r-miniconda/envs/arrow/include
-- xsimd found. Headers: /home/tdhock/.local/share/r-miniconda/envs/arrow/include
-- Found hdfs.h at: /home/tdhock/arrow-git/cpp/thirdparty/hadoop/include/hdfs.h
-- All bundled static libraries: jemalloc::jemalloc
-- CMAKE_C_FLAGS:   -Wall -Wno-conversion -Wno-sign-conversion -Wunused-result -fno-semantic-interposition -msse4.2 -march=core2
-- CMAKE_CXX_FLAGS:  -Wno-noexcept-type  -fdiagnostics-color=always  -Wall -Wno-conversion -Wno-sign-conversion -Wunused-result -fno-semantic-interposition -msse4.2 -march=core2
-- CMAKE_C_FLAGS_DEBUG: -g -Werror -O0 -ggdb
-- CMAKE_CXX_FLAGS_DEBUG: -g -Werror -O0 -ggdb
-- ---------------------------------------------------------------------
-- Arrow version:                                 13.0.0-SNAPSHOT
-- 
-- Build configuration summary:
--   Generator: Ninja
--   Build type: DEBUG
--   Source directory: /home/tdhock/arrow-git/cpp
--   Install prefix: /home/tdhock
-- 
-- Compile and link options:
-- 
--   ARROW_CXXFLAGS=-march=core2 [default=""]
--       Compiler flags to append when compiling Arrow
--   ARROW_BUILD_STATIC=OFF [default=ON]
--       Build static libraries
--   ARROW_BUILD_SHARED=ON [default=ON]
--       Build shared libraries
--   ARROW_PACKAGE_KIND="" [default=""]
--       Arbitrary string that identifies the kind of package
--       (for informational purposes)
--   ARROW_GIT_ID=6d3fe6bda1c3b67b683ada2327194adeed09e9ca [default=""]
--       The Arrow git commit id (if any)
--   ARROW_GIT_DESCRIPTION=apache-arrow-13.0.0.dev-46-g6d3fe6bda [default=""]
--       The Arrow git commit description (if any)
--   ARROW_NO_DEPRECATED_API=OFF [default=OFF]
--       Exclude deprecated APIs from build
--   ARROW_POSITION_INDEPENDENT_CODE=ON [default=ON]
--       Whether to create position-independent target
--   ARROW_USE_CCACHE=ON [default=ON]
--       Use ccache when compiling (if available)
--   ARROW_USE_SCCACHE=ON [default=ON]
--       Use sccache when compiling (if available),
--       takes precedence over ccache if a storage backend is configured
--   ARROW_USE_LD_GOLD=OFF [default=OFF]
--       Use ld.gold for linking on Linux (if available)
--   ARROW_USE_PRECOMPILED_HEADERS=OFF [default=OFF]
--       Use precompiled headers when compiling
--   ARROW_SIMD_LEVEL=SSE4_2 [default=NONE|SSE4_2|AVX2|AVX512|NEON|SVE|SVE128|SVE256|SVE512|DEFAULT]
--       Compile-time SIMD optimization level
--   ARROW_RUNTIME_SIMD_LEVEL=MAX [default=NONE|SSE4_2|AVX2|AVX512|MAX]
--       Max runtime SIMD optimization level
--   ARROW_ALTIVEC=ON [default=ON]
--       Build with Altivec if compiler has support
--   ARROW_RPATH_ORIGIN=OFF [default=OFF]
--       Build Arrow libraries with RATH set to $ORIGIN
--   ARROW_INSTALL_NAME_RPATH=ON [default=ON]
--       Build Arrow libraries with install_name set to @rpath
--   ARROW_GGDB_DEBUG=ON [default=ON]
--       Pass -ggdb flag to debug builds
--   ARROW_WITH_MUSL=OFF [default=OFF]
--       Whether the system libc is musl or not
-- 
-- Test and benchmark options:
-- 
--   ARROW_BUILD_EXAMPLES=OFF [default=OFF]
--       Build the Arrow examples
--   ARROW_BUILD_TESTS=ON [default=OFF]
--       Build the Arrow googletest unit tests
--   ARROW_ENABLE_TIMING_TESTS=ON [default=ON]
--       Enable timing-sensitive tests
--   ARROW_BUILD_INTEGRATION=ON [default=OFF]
--       Build the Arrow integration test executables
--   ARROW_BUILD_BENCHMARKS=OFF [default=OFF]
--       Build the Arrow micro benchmarks
--   ARROW_BUILD_BENCHMARKS_REFERENCE=OFF [default=OFF]
--       Build the Arrow micro reference benchmarks
--   ARROW_BUILD_OPENMP_BENCHMARKS=OFF [default=OFF]
--       Build the Arrow benchmarks that rely on OpenMP
--   ARROW_BUILD_DETAILED_BENCHMARKS=OFF [default=OFF]
--       Build benchmarks that do a longer exploration of performance
--   ARROW_TEST_LINKAGE=shared [default=shared|static]
--       Linkage of Arrow libraries with unit tests executables.
--   ARROW_FUZZING=OFF [default=OFF]
--       Build Arrow Fuzzing executables
--   ARROW_LARGE_MEMORY_TESTS=OFF [default=OFF]
--       Enable unit tests which use large memory
-- 
-- Lint options:
-- 
--   ARROW_ONLY_LINT=OFF [default=OFF]
--       Only define the lint and check-format targets
--   ARROW_VERBOSE_LINT=OFF [default=OFF]
--       If off, 'quiet' flags will be passed to linting tools
--   ARROW_GENERATE_COVERAGE=OFF [default=OFF]
--       Build with C++ code coverage enabled
-- 
-- Checks options:
-- 
--   ARROW_TEST_MEMCHECK=OFF [default=OFF]
--       Run the test suite using valgrind --tool=memcheck
--   ARROW_USE_ASAN=OFF [default=OFF]
--       Enable Address Sanitizer checks
--   ARROW_USE_TSAN=OFF [default=OFF]
--       Enable Thread Sanitizer checks
--   ARROW_USE_UBSAN=OFF [default=OFF]
--       Enable Undefined Behavior sanitizer checks
-- 
-- Project component options:
-- 
--   ARROW_BUILD_UTILITIES=OFF [default=OFF]
--       Build Arrow commandline utilities
--   ARROW_COMPUTE=ON [default=OFF]
--       Build all Arrow Compute kernels
--   ARROW_CSV=ON [default=OFF]
--       Build the Arrow CSV Parser Module
--   ARROW_CUDA=OFF [default=OFF]
--       Build the Arrow CUDA extensions (requires CUDA toolkit)
--   ARROW_DATASET=ON [default=OFF]
--       Build the Arrow Dataset Modules
--   ARROW_FILESYSTEM=ON [default=OFF]
--       Build the Arrow Filesystem Layer
--   ARROW_FLIGHT=OFF [default=OFF]
--       Build the Arrow Flight RPC System (requires GRPC, Protocol Buffers)
--   ARROW_FLIGHT_SQL=OFF [default=OFF]
--       Build the Arrow Flight SQL extension
--   ARROW_GANDIVA=OFF [default=OFF]
--       Build the Gandiva libraries
--   ARROW_GCS=OFF [default=OFF]
--       Build Arrow with GCS support (requires the GCloud SDK for C++)
--   ARROW_HDFS=OFF [default=OFF]
--       Build the Arrow HDFS bridge
--   ARROW_IPC=ON [default=ON]
--       Build the Arrow IPC extensions
--   ARROW_JEMALLOC=ON [default=ON]
--       Build the Arrow jemalloc-based allocator
--   ARROW_JSON=ON [default=OFF]
--       Build Arrow with JSON support (requires RapidJSON)
--   ARROW_MIMALLOC=OFF [default=OFF]
--       Build the Arrow mimalloc-based allocator
--   ARROW_PARQUET=OFF [default=OFF]
--       Build the Parquet libraries
--   ARROW_ORC=OFF [default=OFF]
--       Build the Arrow ORC adapter
--   ARROW_PYTHON=OFF [default=OFF]
--       Build some components needed by PyArrow.
--       (This is a deprecated option. Use CMake presets instead.)
--   ARROW_S3=OFF [default=OFF]
--       Build Arrow with S3 support (requires the AWS SDK for C++)
--   ARROW_SKYHOOK=OFF [default=OFF]
--       Build the Skyhook libraries
--   ARROW_SUBSTRAIT=OFF [default=OFF]
--       Build the Arrow Substrait Consumer Module
--   ARROW_ACERO=ON [default=OFF]
--       Build the Arrow Acero Engine Module
--   ARROW_TENSORFLOW=OFF [default=OFF]
--       Build Arrow with TensorFlow support enabled
--   ARROW_TESTING=ON [default=OFF]
--       Build the Arrow testing libraries
-- 
-- Thirdparty toolchain options:
-- 
--   ARROW_DEPENDENCY_SOURCE=CONDA [default=AUTO|BUNDLED|SYSTEM|CONDA|VCPKG|BREW]
--       Method to use for acquiring arrow's build dependencies
--   ARROW_VERBOSE_THIRDPARTY_BUILD=OFF [default=OFF]
--       Show output from ExternalProjects rather than just logging to files
--   ARROW_DEPENDENCY_USE_SHARED=ON [default=ON]
--       Link to shared libraries
--   ARROW_BOOST_USE_SHARED=ON [default=ON]
--       Rely on Boost shared libraries where relevant
--   ARROW_BROTLI_USE_SHARED=ON [default=ON]
--       Rely on Brotli shared libraries where relevant
--   ARROW_BZ2_USE_SHARED=ON [default=ON]
--       Rely on Bz2 shared libraries where relevant
--   ARROW_GFLAGS_USE_SHARED=ON [default=ON]
--       Rely on GFlags shared libraries where relevant
--   ARROW_GRPC_USE_SHARED=ON [default=ON]
--       Rely on gRPC shared libraries where relevant
--   ARROW_JEMALLOC_USE_SHARED=OFF [default=ON]
--       Rely on jemalloc shared libraries where relevant
--   ARROW_LZ4_USE_SHARED=ON [default=ON]
--       Rely on lz4 shared libraries where relevant
--   ARROW_OPENSSL_USE_SHARED=ON [default=ON]
--       Rely on OpenSSL shared libraries where relevant
--   ARROW_PROTOBUF_USE_SHARED=ON [default=ON]
--       Rely on Protocol Buffers shared libraries where relevant
--   ARROW_SNAPPY_USE_SHARED=ON [default=ON]
--       Rely on snappy shared libraries where relevant
--   ARROW_THRIFT_USE_SHARED=ON [default=ON]
--       Rely on thrift shared libraries where relevant
--   ARROW_UTF8PROC_USE_SHARED=ON [default=ON]
--       Rely on utf8proc shared libraries where relevant
--   ARROW_ZSTD_USE_SHARED=ON [default=ON]
--       Rely on zstd shared libraries where relevant
--   ARROW_USE_GLOG=OFF [default=OFF]
--       Build libraries with glog support for pluggable logging
--   ARROW_WITH_BACKTRACE=ON [default=ON]
--       Build with backtrace support
--   ARROW_WITH_OPENTELEMETRY=OFF [default=OFF]
--       Build libraries with OpenTelemetry support for distributed tracing
--   ARROW_WITH_BROTLI=OFF [default=OFF]
--       Build with Brotli compression
--   ARROW_WITH_BZ2=OFF [default=OFF]
--       Build with BZ2 compression
--   ARROW_WITH_LZ4=OFF [default=OFF]
--       Build with lz4 compression
--   ARROW_WITH_SNAPPY=OFF [default=OFF]
--       Build with Snappy compression
--   ARROW_WITH_ZLIB=OFF [default=OFF]
--       Build with zlib compression
--   ARROW_WITH_ZSTD=OFF [default=OFF]
--       Build with zstd compression
--   ARROW_WITH_UCX=OFF [default=OFF]
--       Build with UCX transport for Arrow Flight
--       (only used if ARROW_FLIGHT is ON)
--   ARROW_WITH_UTF8PROC=OFF [default=ON]
--       Build with support for Unicode properties using the utf8proc library
--       (only used if ARROW_COMPUTE is ON or ARROW_GANDIVA is ON)
--   ARROW_WITH_RE2=OFF [default=ON]
--       Build with support for regular expressions using the re2 library
--       (only used if ARROW_COMPUTE or ARROW_GANDIVA is ON)
-- 
-- Parquet options:
-- 
--   PARQUET_MINIMAL_DEPENDENCY=OFF [default=OFF]
--       Depend only on Thirdparty headers to build libparquet.
--       Always OFF if building binaries
--   PARQUET_BUILD_EXECUTABLES=OFF [default=OFF]
--       Build the Parquet executable CLI tools. Requires static libraries to be built.
--   PARQUET_BUILD_EXAMPLES=OFF [default=OFF]
--       Build the Parquet examples. Requires static libraries to be built.
--   PARQUET_REQUIRE_ENCRYPTION=OFF [default=OFF]
--       Build support for encryption. Fail if OpenSSL is not found
-- 
-- Gandiva options:
-- 
--   ARROW_GANDIVA_STATIC_LIBSTDCPP=OFF [default=OFF]
--       Include -static-libstdc++ -static-libgcc when linking with
--       Gandiva static libraries
--   ARROW_GANDIVA_PC_CXX_FLAGS="" [default=""]
--       Compiler flags to append when pre-compiling Gandiva operations
-- 
-- Advanced developer options:
-- 
--   ARROW_EXTRA_ERROR_CONTEXT=ON [default=OFF]
--       Compile with extra error context (line numbers, code)
--   ARROW_OPTIONAL_INSTALL=OFF [default=OFF]
--       If enabled install ONLY targets that have already been built. Please be
--       advised that if this is enabled 'install' will fail silently on components
--       that have not been built
--   ARROW_GDB_INSTALL_DIR="" [default=""]
--       Use a custom install directory for GDB plugin.
--       In general, you don't need to specify this because the default
--       (CMAKE_INSTALL_FULL_BINDIR on Windows, CMAKE_INSTALL_FULL_LIBDIR otherwise)
--       is reasonable.
--   Outputting build configuration summary to /home/tdhock/arrow-git/cpp/build/cmake_summary.json
-- Configuring done
-- Generating done
-- Build files have been written to: /home/tdhock/arrow-git/cpp/build
[1/562] Creating directories for 'jemalloc_ep'
[2/562] Creating directories for 'googletest_ep'
[3/562] Performing download step (download, verify and extract) for 'jemalloc_ep'
[4/562] No update step for 'jemalloc_ep'
[5/562] Performing patch step for 'jemalloc_ep'
[6/562] Performing download step (download, verify and extract) for 'googletest_ep'
[7/562] No update step for 'googletest_ep'
[8/562] No patch step for 'googletest_ep'
...
out of memory/freeze
(arrow) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main)$ cmake --build .

[1/310] Building CXX object src/arrow/CMakeFiles/arrow-extension-type-test.dir/extension_type_test.cc.o
[2/310] Building CXX object src/arrow/CMakeFiles/arrow-array-test.dir/array/array_binary_test.cc.o
...
[309/310] Linking CXX executable debug/arrow-fixed-shape-tensor-test
[310/310] Linking CXX executable debug/arrow-json-test
(arrow) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main)$ (arrow) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main)$ cmake --install .
-- Install configuration: "DEBUG"
-- Installing: /home/tdhock/include/arrow/util/config.h
-- Up-to-date: /home/tdhock/share/doc/arrow/LICENSE.txt
-- Up-to-date: /home/tdhock/share/doc/arrow/NOTICE.txt
-- Up-to-date: /home/tdhock/share/doc/arrow/README.md
-- Up-to-date: /home/tdhock/share/arrow/gdb/gdb_arrow.py
-- Installing: /home/tdhock/lib/libarrow.so.1300.0.0
-- Up-to-date: /home/tdhock/lib/libarrow.so.1300
-- Up-to-date: /home/tdhock/lib/libarrow.so
-- Up-to-date: /home/tdhock/lib/cmake/Arrow/ArrowConfig.cmake
-- Up-to-date: /home/tdhock/lib/cmake/Arrow/ArrowConfigVersion.cmake
-- Up-to-date: /home/tdhock/lib/cmake/Arrow/ArrowTargets.cmake
-- Up-to-date: /home/tdhock/lib/cmake/Arrow/ArrowTargets-debug.cmake
-- Up-to-date: /home/tdhock/lib/pkgconfig/arrow.pc
-- Up-to-date: /home/tdhock/share/gdb/auto-load/home/tdhock/lib/libarrow.so.1300.0.0-gdb.py
-- Installing: /home/tdhock/lib/libarrow_testing.so.1300.0.0
-- Installing: /home/tdhock/lib/libarrow_testing.so.1300
-- Set runtime path of "/home/tdhock/lib/libarrow_testing.so.1300.0.0" to ""
-- Installing: /home/tdhock/lib/libarrow_testing.so
-- Installing: /home/tdhock/lib/cmake/ArrowTesting/ArrowTestingConfig.cmake
-- Installing: /home/tdhock/lib/cmake/ArrowTesting/ArrowTestingConfigVersion.cmake
-- Installing: /home/tdhock/lib/cmake/ArrowTesting/ArrowTestingTargets.cmake
-- Installing: /home/tdhock/lib/cmake/ArrowTesting/ArrowTestingTargets-debug.cmake
-- Installing: /home/tdhock/lib/pkgconfig/arrow-testing.pc
-- Up-to-date: /home/tdhock/include/arrow/api.h
-- Up-to-date: /home/tdhock/include/arrow/array.h
-- Up-to-date: /home/tdhock/include/arrow/buffer.h
-- Up-to-date: /home/tdhock/include/arrow/buffer_builder.h
-- Up-to-date: /home/tdhock/include/arrow/builder.h
-- Up-to-date: /home/tdhock/include/arrow/chunk_resolver.h
-- Up-to-date: /home/tdhock/include/arrow/chunked_array.h
-- Up-to-date: /home/tdhock/include/arrow/compare.h
-- Up-to-date: /home/tdhock/include/arrow/config.h
-- Up-to-date: /home/tdhock/include/arrow/datum.h
-- Up-to-date: /home/tdhock/include/arrow/device.h
-- Up-to-date: /home/tdhock/include/arrow/extension_type.h
-- Up-to-date: /home/tdhock/include/arrow/memory_pool.h
-- Up-to-date: /home/tdhock/include/arrow/memory_pool_test.h
-- Up-to-date: /home/tdhock/include/arrow/pch.h
-- Up-to-date: /home/tdhock/include/arrow/pretty_print.h
-- Up-to-date: /home/tdhock/include/arrow/record_batch.h
-- Up-to-date: /home/tdhock/include/arrow/result.h
-- Up-to-date: /home/tdhock/include/arrow/scalar.h
-- Up-to-date: /home/tdhock/include/arrow/sparse_tensor.h
-- Up-to-date: /home/tdhock/include/arrow/status.h
-- Up-to-date: /home/tdhock/include/arrow/stl.h
-- Up-to-date: /home/tdhock/include/arrow/stl_allocator.h
-- Up-to-date: /home/tdhock/include/arrow/stl_iterator.h
-- Up-to-date: /home/tdhock/include/arrow/table.h
-- Up-to-date: /home/tdhock/include/arrow/table_builder.h
-- Up-to-date: /home/tdhock/include/arrow/tensor.h
-- Up-to-date: /home/tdhock/include/arrow/type.h
-- Up-to-date: /home/tdhock/include/arrow/type_fwd.h
-- Up-to-date: /home/tdhock/include/arrow/type_traits.h
-- Up-to-date: /home/tdhock/include/arrow/visit_array_inline.h
-- Up-to-date: /home/tdhock/include/arrow/visit_data_inline.h
-- Up-to-date: /home/tdhock/include/arrow/visit_scalar_inline.h
-- Up-to-date: /home/tdhock/include/arrow/visit_type_inline.h
-- Up-to-date: /home/tdhock/include/arrow/visitor.h
-- Up-to-date: /home/tdhock/include/arrow/visitor_generate.h
-- Installing: /home/tdhock/lib/cmake/Arrow/ArrowOptions.cmake
-- Up-to-date: /home/tdhock/lib/cmake/Arrow/arrow-config.cmake
-- Up-to-date: /home/tdhock/include/arrow/testing/async_test_util.h
-- Up-to-date: /home/tdhock/include/arrow/testing/builder.h
-- Up-to-date: /home/tdhock/include/arrow/testing/executor_util.h
-- Up-to-date: /home/tdhock/include/arrow/testing/extension_type.h
-- Up-to-date: /home/tdhock/include/arrow/testing/future_util.h
-- Up-to-date: /home/tdhock/include/arrow/testing/generator.h
-- Up-to-date: /home/tdhock/include/arrow/testing/gtest_compat.h
-- Up-to-date: /home/tdhock/include/arrow/testing/gtest_util.h
-- Up-to-date: /home/tdhock/include/arrow/testing/json_integration.h
-- Up-to-date: /home/tdhock/include/arrow/testing/matchers.h
-- Up-to-date: /home/tdhock/include/arrow/testing/pch.h
-- Up-to-date: /home/tdhock/include/arrow/testing/random.h
-- Up-to-date: /home/tdhock/include/arrow/testing/uniform_real.h
-- Up-to-date: /home/tdhock/include/arrow/testing/util.h
-- Up-to-date: /home/tdhock/include/arrow/testing/visibility.h
-- Up-to-date: /home/tdhock/include/arrow/array/array_base.h
-- Up-to-date: /home/tdhock/include/arrow/array/array_binary.h
-- Up-to-date: /home/tdhock/include/arrow/array/array_decimal.h
-- Up-to-date: /home/tdhock/include/arrow/array/array_dict.h
-- Up-to-date: /home/tdhock/include/arrow/array/array_nested.h
-- Up-to-date: /home/tdhock/include/arrow/array/array_primitive.h
-- Up-to-date: /home/tdhock/include/arrow/array/array_run_end.h
-- Up-to-date: /home/tdhock/include/arrow/array/builder_adaptive.h
-- Up-to-date: /home/tdhock/include/arrow/array/builder_base.h
-- Up-to-date: /home/tdhock/include/arrow/array/builder_binary.h
-- Up-to-date: /home/tdhock/include/arrow/array/builder_decimal.h
-- Up-to-date: /home/tdhock/include/arrow/array/builder_dict.h
-- Up-to-date: /home/tdhock/include/arrow/array/builder_nested.h
-- Up-to-date: /home/tdhock/include/arrow/array/builder_primitive.h
-- Up-to-date: /home/tdhock/include/arrow/array/builder_run_end.h
-- Up-to-date: /home/tdhock/include/arrow/array/builder_time.h
-- Up-to-date: /home/tdhock/include/arrow/array/builder_union.h
-- Up-to-date: /home/tdhock/include/arrow/array/concatenate.h
-- Up-to-date: /home/tdhock/include/arrow/array/data.h
-- Up-to-date: /home/tdhock/include/arrow/array/diff.h
-- Up-to-date: /home/tdhock/include/arrow/array/util.h
-- Up-to-date: /home/tdhock/include/arrow/array/validate.h
-- Up-to-date: /home/tdhock/include/arrow/c/abi.h
-- Up-to-date: /home/tdhock/include/arrow/c/bridge.h
-- Up-to-date: /home/tdhock/include/arrow/c/helpers.h
-- Up-to-date: /home/tdhock/include/arrow/compute/api.h
-- Up-to-date: /home/tdhock/include/arrow/compute/api_aggregate.h
-- Up-to-date: /home/tdhock/include/arrow/compute/api_scalar.h
-- Up-to-date: /home/tdhock/include/arrow/compute/api_vector.h
-- Up-to-date: /home/tdhock/include/arrow/compute/cast.h
-- Up-to-date: /home/tdhock/include/arrow/compute/exec.h
-- Up-to-date: /home/tdhock/include/arrow/compute/expression.h
-- Up-to-date: /home/tdhock/include/arrow/compute/function.h
-- Up-to-date: /home/tdhock/include/arrow/compute/kernel.h
-- Up-to-date: /home/tdhock/include/arrow/compute/key_hash.h
-- Up-to-date: /home/tdhock/include/arrow/compute/key_map.h
-- Up-to-date: /home/tdhock/include/arrow/compute/light_array.h
-- Up-to-date: /home/tdhock/include/arrow/compute/ordering.h
-- Up-to-date: /home/tdhock/include/arrow/compute/registry.h
-- Up-to-date: /home/tdhock/include/arrow/compute/type_fwd.h
-- Up-to-date: /home/tdhock/include/arrow/compute/util.h
-- Up-to-date: /home/tdhock/lib/pkgconfig/arrow-compute.pc
-- Up-to-date: /home/tdhock/include/arrow/compute/row/grouper.h
-- Up-to-date: /home/tdhock/include/arrow/io/api.h
-- Up-to-date: /home/tdhock/include/arrow/io/buffered.h
-- Up-to-date: /home/tdhock/include/arrow/io/caching.h
-- Up-to-date: /home/tdhock/include/arrow/io/compressed.h
-- Up-to-date: /home/tdhock/include/arrow/io/concurrency.h
-- Up-to-date: /home/tdhock/include/arrow/io/file.h
-- Up-to-date: /home/tdhock/include/arrow/io/hdfs.h
-- Up-to-date: /home/tdhock/include/arrow/io/interfaces.h
-- Up-to-date: /home/tdhock/include/arrow/io/memory.h
-- Up-to-date: /home/tdhock/include/arrow/io/mman.h
-- Up-to-date: /home/tdhock/include/arrow/io/slow.h
-- Up-to-date: /home/tdhock/include/arrow/io/stdio.h
-- Up-to-date: /home/tdhock/include/arrow/io/test_common.h
-- Up-to-date: /home/tdhock/include/arrow/io/transform.h
-- Up-to-date: /home/tdhock/include/arrow/io/type_fwd.h
-- Up-to-date: /home/tdhock/include/arrow/tensor/converter.h
-- Up-to-date: /home/tdhock/include/arrow/util/algorithm.h
-- Up-to-date: /home/tdhock/include/arrow/util/align_util.h
-- Up-to-date: /home/tdhock/include/arrow/util/aligned_storage.h
-- Up-to-date: /home/tdhock/include/arrow/util/async_generator.h
-- Up-to-date: /home/tdhock/include/arrow/util/async_generator_fwd.h
-- Up-to-date: /home/tdhock/include/arrow/util/async_util.h
-- Up-to-date: /home/tdhock/include/arrow/util/base64.h
-- Up-to-date: /home/tdhock/include/arrow/util/basic_decimal.h
-- Up-to-date: /home/tdhock/include/arrow/util/benchmark_util.h
-- Up-to-date: /home/tdhock/include/arrow/util/bit_block_counter.h
-- Up-to-date: /home/tdhock/include/arrow/util/bit_run_reader.h
-- Up-to-date: /home/tdhock/include/arrow/util/bit_stream_utils.h
-- Up-to-date: /home/tdhock/include/arrow/util/bit_util.h
-- Up-to-date: /home/tdhock/include/arrow/util/bitmap.h
-- Up-to-date: /home/tdhock/include/arrow/util/bitmap_builders.h
-- Up-to-date: /home/tdhock/include/arrow/util/bitmap_generate.h
-- Up-to-date: /home/tdhock/include/arrow/util/bitmap_ops.h
-- Up-to-date: /home/tdhock/include/arrow/util/bitmap_reader.h
-- Up-to-date: /home/tdhock/include/arrow/util/bitmap_visit.h
-- Up-to-date: /home/tdhock/include/arrow/util/bitmap_writer.h
-- Up-to-date: /home/tdhock/include/arrow/util/bitset_stack.h
-- Up-to-date: /home/tdhock/include/arrow/util/bpacking.h
-- Up-to-date: /home/tdhock/include/arrow/util/bpacking64_default.h
-- Up-to-date: /home/tdhock/include/arrow/util/bpacking_avx2.h
-- Up-to-date: /home/tdhock/include/arrow/util/bpacking_avx512.h
-- Up-to-date: /home/tdhock/include/arrow/util/bpacking_default.h
-- Up-to-date: /home/tdhock/include/arrow/util/bpacking_neon.h
-- Up-to-date: /home/tdhock/include/arrow/util/bpacking_simd128_generated.h
-- Up-to-date: /home/tdhock/include/arrow/util/bpacking_simd256_generated.h
-- Up-to-date: /home/tdhock/include/arrow/util/bpacking_simd512_generated.h
-- Up-to-date: /home/tdhock/include/arrow/util/byte_size.h
-- Up-to-date: /home/tdhock/include/arrow/util/byte_stream_split.h
-- Up-to-date: /home/tdhock/include/arrow/util/bytes_view.h
-- Up-to-date: /home/tdhock/include/arrow/util/cancel.h
-- Up-to-date: /home/tdhock/include/arrow/util/checked_cast.h
-- Up-to-date: /home/tdhock/include/arrow/util/compare.h
-- Up-to-date: /home/tdhock/include/arrow/util/compression.h
-- Up-to-date: /home/tdhock/include/arrow/util/concurrent_map.h
-- Installing: /home/tdhock/include/arrow/util/config.h
-- Up-to-date: /home/tdhock/include/arrow/util/converter.h
-- Up-to-date: /home/tdhock/include/arrow/util/counting_semaphore.h
-- Up-to-date: /home/tdhock/include/arrow/util/cpu_info.h
-- Up-to-date: /home/tdhock/include/arrow/util/crc32.h
-- Up-to-date: /home/tdhock/include/arrow/util/debug.h
-- Up-to-date: /home/tdhock/include/arrow/util/decimal.h
-- Up-to-date: /home/tdhock/include/arrow/util/delimiting.h
-- Up-to-date: /home/tdhock/include/arrow/util/dispatch.h
-- Up-to-date: /home/tdhock/include/arrow/util/double_conversion.h
-- Up-to-date: /home/tdhock/include/arrow/util/endian.h
-- Up-to-date: /home/tdhock/include/arrow/util/formatting.h
-- Up-to-date: /home/tdhock/include/arrow/util/functional.h
-- Up-to-date: /home/tdhock/include/arrow/util/future.h
-- Up-to-date: /home/tdhock/include/arrow/util/hash_util.h
-- Up-to-date: /home/tdhock/include/arrow/util/hashing.h
-- Up-to-date: /home/tdhock/include/arrow/util/int_util.h
-- Up-to-date: /home/tdhock/include/arrow/util/int_util_overflow.h
-- Up-to-date: /home/tdhock/include/arrow/util/io_util.h
-- Up-to-date: /home/tdhock/include/arrow/util/iterator.h
-- Up-to-date: /home/tdhock/include/arrow/util/key_value_metadata.h
-- Up-to-date: /home/tdhock/include/arrow/util/launder.h
-- Up-to-date: /home/tdhock/include/arrow/util/logging.h
-- Up-to-date: /home/tdhock/include/arrow/util/macros.h
-- Up-to-date: /home/tdhock/include/arrow/util/map.h
-- Up-to-date: /home/tdhock/include/arrow/util/math_constants.h
-- Up-to-date: /home/tdhock/include/arrow/util/memory.h
-- Up-to-date: /home/tdhock/include/arrow/util/mutex.h
-- Up-to-date: /home/tdhock/include/arrow/util/parallel.h
-- Up-to-date: /home/tdhock/include/arrow/util/pcg_random.h
-- Up-to-date: /home/tdhock/include/arrow/util/print.h
-- Up-to-date: /home/tdhock/include/arrow/util/queue.h
-- Up-to-date: /home/tdhock/include/arrow/util/range.h
-- Up-to-date: /home/tdhock/include/arrow/util/ree_util.h
-- Up-to-date: /home/tdhock/include/arrow/util/regex.h
-- Up-to-date: /home/tdhock/include/arrow/util/rle_encoding.h
-- Up-to-date: /home/tdhock/include/arrow/util/rows_to_batches.h
-- Up-to-date: /home/tdhock/include/arrow/util/simd.h
-- Up-to-date: /home/tdhock/include/arrow/util/small_vector.h
-- Up-to-date: /home/tdhock/include/arrow/util/sort.h
-- Up-to-date: /home/tdhock/include/arrow/util/spaced.h
-- Up-to-date: /home/tdhock/include/arrow/util/stopwatch.h
-- Up-to-date: /home/tdhock/include/arrow/util/string.h
-- Up-to-date: /home/tdhock/include/arrow/util/string_builder.h
-- Up-to-date: /home/tdhock/include/arrow/util/task_group.h
-- Up-to-date: /home/tdhock/include/arrow/util/tdigest.h
-- Up-to-date: /home/tdhock/include/arrow/util/test_common.h
-- Up-to-date: /home/tdhock/include/arrow/util/thread_pool.h
-- Up-to-date: /home/tdhock/include/arrow/util/time.h
-- Up-to-date: /home/tdhock/include/arrow/util/tracing.h
-- Up-to-date: /home/tdhock/include/arrow/util/trie.h
-- Up-to-date: /home/tdhock/include/arrow/util/type_fwd.h
-- Up-to-date: /home/tdhock/include/arrow/util/type_traits.h
-- Up-to-date: /home/tdhock/include/arrow/util/ubsan.h
-- Up-to-date: /home/tdhock/include/arrow/util/union_util.h
-- Up-to-date: /home/tdhock/include/arrow/util/unreachable.h
-- Up-to-date: /home/tdhock/include/arrow/util/uri.h
-- Up-to-date: /home/tdhock/include/arrow/util/utf8.h
-- Up-to-date: /home/tdhock/include/arrow/util/value_parsing.h
-- Up-to-date: /home/tdhock/include/arrow/util/vector.h
-- Up-to-date: /home/tdhock/include/arrow/util/visibility.h
-- Up-to-date: /home/tdhock/include/arrow/util/windows_compatibility.h
-- Up-to-date: /home/tdhock/include/arrow/util/windows_fixup.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/ProducerConsumerQueue.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/datetime.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/strptime.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/xxhash.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/datetime/date.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/datetime/ios.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/datetime/tz.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/datetime/tz_private.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/datetime/visibility.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/double-conversion/bignum-dtoa.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/double-conversion/bignum.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/double-conversion/cached-powers.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/double-conversion/diy-fp.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/double-conversion/double-conversion.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/double-conversion/fast-dtoa.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/double-conversion/fixed-dtoa.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/double-conversion/ieee.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/double-conversion/strtod.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/double-conversion/utils.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/pcg/pcg_extras.hpp
-- Up-to-date: /home/tdhock/include/arrow/vendored/pcg/pcg_random.hpp
-- Up-to-date: /home/tdhock/include/arrow/vendored/pcg/pcg_uint128.hpp
-- Up-to-date: /home/tdhock/include/arrow/vendored/portable-snippets/debug-trap.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/portable-snippets/safe-math.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/xxhash/xxhash.h
-- Installing: /home/tdhock/include/arrow/csv/api.h
-- Installing: /home/tdhock/include/arrow/csv/chunker.h
-- Installing: /home/tdhock/include/arrow/csv/column_builder.h
-- Installing: /home/tdhock/include/arrow/csv/column_decoder.h
-- Installing: /home/tdhock/include/arrow/csv/converter.h
-- Installing: /home/tdhock/include/arrow/csv/invalid_row.h
-- Installing: /home/tdhock/include/arrow/csv/options.h
-- Installing: /home/tdhock/include/arrow/csv/parser.h
-- Installing: /home/tdhock/include/arrow/csv/reader.h
-- Installing: /home/tdhock/include/arrow/csv/test_common.h
-- Installing: /home/tdhock/include/arrow/csv/type_fwd.h
-- Installing: /home/tdhock/include/arrow/csv/writer.h
-- Installing: /home/tdhock/lib/pkgconfig/arrow-csv.pc
-- Installing: /home/tdhock/include/arrow/acero/accumulation_queue.h
-- Installing: /home/tdhock/include/arrow/acero/aggregate_node.h
-- Installing: /home/tdhock/include/arrow/acero/asof_join_node.h
-- Installing: /home/tdhock/include/arrow/acero/benchmark_util.h
-- Installing: /home/tdhock/include/arrow/acero/bloom_filter.h
-- Installing: /home/tdhock/include/arrow/acero/exec_plan.h
-- Installing: /home/tdhock/include/arrow/acero/groupby.h
-- Installing: /home/tdhock/include/arrow/acero/hash_join.h
-- Installing: /home/tdhock/include/arrow/acero/hash_join_dict.h
-- Installing: /home/tdhock/include/arrow/acero/hash_join_node.h
-- Installing: /home/tdhock/include/arrow/acero/map_node.h
-- Installing: /home/tdhock/include/arrow/acero/options.h
-- Installing: /home/tdhock/include/arrow/acero/order_by_impl.h
-- Installing: /home/tdhock/include/arrow/acero/partition_util.h
-- Installing: /home/tdhock/include/arrow/acero/pch.h
-- Installing: /home/tdhock/include/arrow/acero/query_context.h
-- Installing: /home/tdhock/include/arrow/acero/schema_util.h
-- Installing: /home/tdhock/include/arrow/acero/task_util.h
-- Installing: /home/tdhock/include/arrow/acero/test_nodes.h
-- Installing: /home/tdhock/include/arrow/acero/tpch_node.h
-- Installing: /home/tdhock/include/arrow/acero/type_fwd.h
-- Installing: /home/tdhock/include/arrow/acero/util.h
-- Installing: /home/tdhock/include/arrow/acero/visibility.h
-- Installing: /home/tdhock/lib/libarrow_acero.so.1300.0.0
-- Installing: /home/tdhock/lib/libarrow_acero.so.1300
-- Set runtime path of "/home/tdhock/lib/libarrow_acero.so.1300.0.0" to ""
-- Installing: /home/tdhock/lib/libarrow_acero.so
-- Installing: /home/tdhock/lib/cmake/ArrowAcero/ArrowAceroConfig.cmake
-- Installing: /home/tdhock/lib/cmake/ArrowAcero/ArrowAceroConfigVersion.cmake
-- Installing: /home/tdhock/lib/cmake/ArrowAcero/ArrowAceroTargets.cmake
-- Installing: /home/tdhock/lib/cmake/ArrowAcero/ArrowAceroTargets-debug.cmake
-- Installing: /home/tdhock/lib/pkgconfig/arrow-acero.pc
-- Installing: /home/tdhock/include/arrow/dataset/api.h
-- Installing: /home/tdhock/include/arrow/dataset/dataset.h
-- Installing: /home/tdhock/include/arrow/dataset/dataset_writer.h
-- Installing: /home/tdhock/include/arrow/dataset/discovery.h
-- Installing: /home/tdhock/include/arrow/dataset/file_base.h
-- Installing: /home/tdhock/include/arrow/dataset/file_csv.h
-- Installing: /home/tdhock/include/arrow/dataset/file_ipc.h
-- Installing: /home/tdhock/include/arrow/dataset/file_json.h
-- Installing: /home/tdhock/include/arrow/dataset/file_orc.h
-- Installing: /home/tdhock/include/arrow/dataset/file_parquet.h
-- Installing: /home/tdhock/include/arrow/dataset/partition.h
-- Installing: /home/tdhock/include/arrow/dataset/pch.h
-- Installing: /home/tdhock/include/arrow/dataset/plan.h
-- Installing: /home/tdhock/include/arrow/dataset/projector.h
-- Installing: /home/tdhock/include/arrow/dataset/scanner.h
-- Installing: /home/tdhock/include/arrow/dataset/type_fwd.h
-- Installing: /home/tdhock/include/arrow/dataset/visibility.h
-- Installing: /home/tdhock/lib/libarrow_dataset.so.1300.0.0
-- Installing: /home/tdhock/lib/libarrow_dataset.so.1300
-- Set runtime path of "/home/tdhock/lib/libarrow_dataset.so.1300.0.0" to ""
-- Installing: /home/tdhock/lib/libarrow_dataset.so
-- Installing: /home/tdhock/lib/cmake/ArrowDataset/ArrowDatasetConfig.cmake
-- Installing: /home/tdhock/lib/cmake/ArrowDataset/ArrowDatasetConfigVersion.cmake
-- Installing: /home/tdhock/lib/cmake/ArrowDataset/ArrowDatasetTargets.cmake
-- Installing: /home/tdhock/lib/cmake/ArrowDataset/ArrowDatasetTargets-debug.cmake
-- Installing: /home/tdhock/lib/pkgconfig/arrow-dataset.pc
-- Installing: /home/tdhock/include/arrow/filesystem/api.h
-- Installing: /home/tdhock/include/arrow/filesystem/filesystem.h
-- Installing: /home/tdhock/include/arrow/filesystem/gcsfs.h
-- Installing: /home/tdhock/include/arrow/filesystem/hdfs.h
-- Installing: /home/tdhock/include/arrow/filesystem/localfs.h
-- Installing: /home/tdhock/include/arrow/filesystem/mockfs.h
-- Installing: /home/tdhock/include/arrow/filesystem/path_util.h
-- Installing: /home/tdhock/include/arrow/filesystem/s3_test_util.h
-- Installing: /home/tdhock/include/arrow/filesystem/s3fs.h
-- Installing: /home/tdhock/include/arrow/filesystem/test_util.h
-- Installing: /home/tdhock/include/arrow/filesystem/type_fwd.h
-- Installing: /home/tdhock/lib/pkgconfig/arrow-filesystem.pc
-- Up-to-date: /home/tdhock/include/arrow/ipc/api.h
-- Up-to-date: /home/tdhock/include/arrow/ipc/dictionary.h
-- Up-to-date: /home/tdhock/include/arrow/ipc/feather.h
-- Up-to-date: /home/tdhock/include/arrow/ipc/json_simple.h
-- Up-to-date: /home/tdhock/include/arrow/ipc/message.h
-- Up-to-date: /home/tdhock/include/arrow/ipc/options.h
-- Up-to-date: /home/tdhock/include/arrow/ipc/reader.h
-- Up-to-date: /home/tdhock/include/arrow/ipc/test_common.h
-- Up-to-date: /home/tdhock/include/arrow/ipc/type_fwd.h
-- Up-to-date: /home/tdhock/include/arrow/ipc/util.h
-- Up-to-date: /home/tdhock/include/arrow/ipc/writer.h
-- Installing: /home/tdhock/include/arrow/json/api.h
-- Installing: /home/tdhock/include/arrow/json/chunked_builder.h
-- Installing: /home/tdhock/include/arrow/json/chunker.h
-- Installing: /home/tdhock/include/arrow/json/converter.h
-- Installing: /home/tdhock/include/arrow/json/object_parser.h
-- Installing: /home/tdhock/include/arrow/json/object_writer.h
-- Installing: /home/tdhock/include/arrow/json/options.h
-- Installing: /home/tdhock/include/arrow/json/parser.h
-- Installing: /home/tdhock/include/arrow/json/rapidjson_defs.h
-- Installing: /home/tdhock/include/arrow/json/reader.h
-- Installing: /home/tdhock/include/arrow/json/test_common.h
-- Installing: /home/tdhock/include/arrow/json/type_fwd.h
-- Installing: /home/tdhock/lib/pkgconfig/arrow-json.pc
-- Installing: /home/tdhock/include/arrow/extension/fixed_shape_tensor.h
(arrow) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main)$ cd ../../r/
(arrow) tdhock@maude-MacBookPro:~/arrow-git/r(main)$ ARROW_DEPENDENCY_SOURCE=SYSTEM ARROW_R_DEV=true LIBARROW_BINARY=false PKG_CONFIG_PATH=$HOME/lib/pkgconfig R CMD INSTALL .
Loading required package: grDevices
* installing to library ‘/home/tdhock/lib/R/library’
* installing *source* package ‘arrow’ ...
** using staged installation
*** Generating code with data-raw/codegen.R
Loading required package: grDevices
Error in library(decor) : there is no package called ‘decor’
Calls: suppressPackageStartupMessages -> withCallingHandlers -> library
Execution halted
*** Trying Arrow C++ found by pkg-config: /home/tdhock
*** > Packages are both on development versions (13.0.0-SNAPSHOT, 12.0.0.9000)
*** > If installation fails, rebuild the C++ library to match the R version
*** > or retry with FORCE_BUNDLED_BUILD=true
PKG_CFLAGS=-I/home/tdhock/include  -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON
PKG_LIBS=-L/home/tdhock/lib -larrow_acero -larrow_dataset -larrow
** libs
using C++ compiler: ‘g++ (GCC) 10.1.0’
using C++17
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -I/usr/local/include    -fpic  -g -O2  -c altrep.cpp -o altrep.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -I/usr/local/include    -fpic  -g -O2  -c array.cpp -o array.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -I/usr/local/include    -fpic  -g -O2  -c array_to_vector.cpp -o array_to_vector.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -I/usr/local/include    -fpic  -g -O2  -c arraydata.cpp -o arraydata.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -I/usr/local/include    -fpic  -g -O2  -c arrowExports.cpp -o arrowExports.o
arrowExports.cpp:1821:131: error: ‘parquet’ was not declared in this scope
 1821 | s::ParquetFileWriteOptions>& options, const std::shared_ptr<parquet::WriterProperties>& writer_props, const std::shared_ptr<parquet::ArrowWriterProperties>& arrow_writer_props);
      |                                                             ^~~~~~~

arrowExports.cpp:1821:156: error: template argument 1 is invalid
 1821 | s>& options, const std::shared_ptr<parquet::WriterProperties>& writer_props, const std::shared_ptr<parquet::ArrowWriterProperties>& arrow_writer_props);
      |                                                             ^

arrowExports.cpp:1821:131: error: ‘parquet’ was not declared in this scope
 1821 | s::ParquetFileWriteOptions>& options, const std::shared_ptr<parquet::WriterProperties>& writer_props, const std::shared_ptr<parquet::ArrowWriterProperties>& arrow_writer_props);
      |                                                             ^~~~~~~

arrowExports.cpp:1821:156: error: template argument 1 is invalid
 1821 | s>& options, const std::shared_ptr<parquet::WriterProperties>& writer_props, const std::shared_ptr<parquet::ArrowWriterProperties>& arrow_writer_props);
      |                                                             ^

arrowExports.cpp:1821:131: error: ‘parquet’ was not declared in this scope
 1821 | s::ParquetFileWriteOptions>& options, const std::shared_ptr<parquet::WriterProperties>& writer_props, const std::shared_ptr<parquet::ArrowWriterProperties>& arrow_writer_props);
      |                                                             ^~~~~~~

arrowExports.cpp:1821:156: error: template argument 1 is invalid
 1821 | s>& options, const std::shared_ptr<parquet::WriterProperties>& writer_props, const std::shared_ptr<parquet::ArrowWriterProperties>& arrow_writer_props);
      |                                                             ^

arrowExports.cpp:1821:115: error: invalid template-id
 1821 | td::shared_ptr<ds::ParquetFileWriteOptions>& options, const std::shared_ptr<parquet::WriterProperties>& writer_props, const std::shared_ptr<parquet::ArrowWriterProperties>& arrow_writer_props);
      |                                                             ^~~

arrowExports.cpp:1821:131: error: ‘parquet’ has not been declared
 1821 | s::ParquetFileWriteOptions>& options, const std::shared_ptr<parquet::WriterProperties>& writer_props, const std::shared_ptr<parquet::ArrowWriterProperties>& arrow_writer_props);
      |                                                             ^~~~~~~

arrowExports.cpp:1821:109: error: template placeholder type ‘const shared_ptr<...auto...>’ must be followed by a simple declarator-id
 1821 | onst std::shared_ptr<ds::ParquetFileWriteOptions>& options, const std::shared_ptr<parquet::WriterProperties>& writer_props, const std::shared_ptr<parquet::ArrowWriterProperties>& arrow_writer_props);
      |                                                             ^~~~~

In file included from /home/tdhock/include/c++/10.1.0/bits/shared_ptr.h:52,
                 from /home/tdhock/include/c++/10.1.0/memory:84,
                 from /home/tdhock/lib/R/library/cpp11/include/cpp11/as.hpp:5,
                 from /home/tdhock/lib/R/library/cpp11/include/cpp11.hpp:5,
                 from arrowExports.cpp:2:
/home/tdhock/include/c++/10.1.0/bits/shared_ptr_base.h:351:11: note: ‘template<class _Tp> class std::shared_ptr’ declared here
  351 |     class shared_ptr;
      |           ^~~~~~~~~~
arrowExports.cpp:1821:171: error: expected ‘)’ before ‘,’ token
 1821 | nst std::shared_ptr<parquet::WriterProperties>& writer_props, const std::shared_ptr<parquet::ArrowWriterProperties>& arrow_writer_props);
      |                                                             ^
      |                                                             )
arrowExports.cpp:1821:173: error: expected unqualified-id before ‘const’
 1821 | t std::shared_ptr<parquet::WriterProperties>& writer_props, const std::shared_ptr<parquet::ArrowWriterProperties>& arrow_writer_props);
      |                                                             ^~~~~

arrowExports.cpp: In function ‘SEXPREC* _arrow_dataset___ParquetFileWriteOptions__update(SEXP, SEXP, SEXP)’:
arrowExports.cpp:1825:40: error: ‘parquet’ was not declared in this scope
 1825 |  arrow::r::Input<const std::shared_ptr<parquet::WriterProperties>&>::type writer_props(writer_props_sexp);
      |                                        ^~~~~~~
arrowExports.cpp:1825:65: error: template argument 1 is invalid
 1825 | ow::r::Input<const std::shared_ptr<parquet::WriterProperties>&>::type writer_props(writer_props_sexp);
      |                                                             ^

arrowExports.cpp:1825:67: error: template argument 1 is invalid
 1825 | ::r::Input<const std::shared_ptr<parquet::WriterProperties>&>::type writer_props(writer_props_sexp);
      |                                                             ^

arrowExports.cpp:1825:75: error: qualified-id in declaration before ‘writer_props’
 1825 | ut<const std::shared_ptr<parquet::WriterProperties>&>::type writer_props(writer_props_sexp);
      |                                                             ^~~~~~~~~~~~

arrowExports.cpp:1826:72: error: template argument 1 is invalid
 1826 | Input<const std::shared_ptr<parquet::ArrowWriterProperties>&>::type arrow_writer_props(arrow_writer_props_sexp);
      |                                                             ^

arrowExports.cpp:1826:80: error: qualified-id in declaration before ‘arrow_writer_props’
 1826 | nst std::shared_ptr<parquet::ArrowWriterProperties>&>::type arrow_writer_props(arrow_writer_props_sexp);
      |                                                             ^~~~~~~~~~~~~~~~~~

arrowExports.cpp:1827:53: error: ‘writer_props’ was not declared in this scope; did you mean ‘writer_props_sexp’?
 1827 |  dataset___ParquetFileWriteOptions__update(options, writer_props, arrow_writer_props);
      |                                                     ^~~~~~~~~~~~
      |                                                     writer_props_sexp
arrowExports.cpp:1827:67: error: ‘arrow_writer_props’ was not declared in this scope; did you mean ‘arrow_writer_props_sexp’?
 1827 | et___ParquetFileWriteOptions__update(options, writer_props, arrow_writer_props);
      |                                                             ^~~~~~~~~~~~~~~~~~
      |                                                             arrow_writer_props_sexp
/home/tdhock/lib/R/etc/Makeconf:198: recipe for target 'arrowExports.o' failed
make: *** [arrowExports.o] Error 1
ERROR: compilation failed for package ‘arrow’
* removing ‘/home/tdhock/lib/R/library/arrow’
* restoring previous ‘/home/tdhock/lib/R/library/arrow’
```

Above suggests parquet is required. Looks like two processors are
being used for compilation. If freeze again, we can maybe try using
only one?

```
(arrow) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main)$ CC=$HOME/bin/gcc CXX=$HOME/bin/g++ cmake .. --preset ninja-debug-basic -DCMAKE_INSTALL_PREFIX=$HOME -DARROW_CXXFLAGS=-march=core2 -DARROW_PARQUET=ON 
Preset CMake variables:

  ARROW_BUILD_INTEGRATION="ON"
  ARROW_BUILD_STATIC="OFF"
  ARROW_BUILD_TESTS="ON"
  ARROW_COMPUTE="ON"
  ARROW_CSV="ON"
  ARROW_DATASET="ON"
  ARROW_EXTRA_ERROR_CONTEXT="ON"
  ARROW_FILESYSTEM="ON"
  ARROW_JSON="ON"
  ARROW_WITH_RE2="OFF"
  ARROW_WITH_UTF8PROC="OFF"
  CMAKE_BUILD_TYPE="Debug"

-- Building using CMake version: 3.22.1
-- Arrow version: 13.0.0 (full: '13.0.0-SNAPSHOT')
-- Arrow SO version: 1300 (full: 1300.0.0)
-- clang-tidy 14 not found
-- clang-format 14 not found
-- Could NOT find ClangTools (missing: CLANG_FORMAT_BIN CLANG_TIDY_BIN) 
-- infer not found
-- Found cpplint executable at /home/tdhock/arrow-git/cpp/build-support/cpplint.py
-- System processor: x86_64
-- Arrow build warning level: CHECKIN
-- Using ld linker
-- Build Type: DEBUG
-- Using CONDA approach to find dependencies
-- Using CONDA_PREFIX for ARROW_PACKAGE_PREFIX: /home/tdhock/.local/share/r-miniconda/envs/arrow
-- Setting (unset) dependency *_ROOT variables: /home/tdhock/.local/share/r-miniconda/envs/arrow
-- ARROW_ABSL_BUILD_VERSION: 20211102.0
-- ARROW_ABSL_BUILD_SHA256_CHECKSUM: dcf71b9cba8dc0ca9940c4b316a0c796be8fab42b070bb6b7cab62b48f0e66c4
-- ARROW_AWS_C_AUTH_BUILD_VERSION: v0.6.22
-- ARROW_AWS_C_AUTH_BUILD_SHA256_CHECKSUM: 691a6b4418afcd3dc141351b6ad33fccd8e3ff84df0e9e045b42295d284ee14c
-- ARROW_AWS_C_CAL_BUILD_VERSION: v0.5.20
-- ARROW_AWS_C_CAL_BUILD_SHA256_CHECKSUM: acc352359bd06f8597415c366cf4ec4f00d0b0da92d637039a73323dd55b6cd0
-- ARROW_AWS_C_COMMON_BUILD_VERSION: v0.8.9
-- ARROW_AWS_C_COMMON_BUILD_SHA256_CHECKSUM: 2f3fbaf7c38eae5a00e2a816d09b81177f93529ae8ba1b82dc8f31407565327a
-- ARROW_AWS_C_COMPRESSION_BUILD_VERSION: v0.2.16
-- ARROW_AWS_C_COMPRESSION_BUILD_SHA256_CHECKSUM: 044b1dbbca431a07bde8255ef9ec443c300fc60d4c9408d4b862f65e496687f4
-- ARROW_AWS_C_EVENT_STREAM_BUILD_VERSION: v0.2.18
-- ARROW_AWS_C_EVENT_STREAM_BUILD_SHA256_CHECKSUM: 310ca617f713bf664e4c7485a3d42c1fb57813abd0107e49790d107def7cde4f
-- ARROW_AWS_C_HTTP_BUILD_VERSION: v0.7.3
-- ARROW_AWS_C_HTTP_BUILD_SHA256_CHECKSUM: 07e16c6bf5eba6f0dea96b6f55eae312a7c95b736f4d2e4a210000f45d8265ae
-- ARROW_AWS_C_IO_BUILD_VERSION: v0.13.14
-- ARROW_AWS_C_IO_BUILD_SHA256_CHECKSUM: 12b66510c3d9a4f7e9b714e9cfab2a5bf835f8b9ce2f909d20ae2a2128608c71
-- ARROW_AWS_C_MQTT_BUILD_VERSION: v0.8.4
-- ARROW_AWS_C_MQTT_BUILD_SHA256_CHECKSUM: 232eeac63e72883d460c686a09b98cdd811d24579affac47c5c3f696f956773f
-- ARROW_AWS_C_S3_BUILD_VERSION: v0.2.3
-- ARROW_AWS_C_S3_BUILD_SHA256_CHECKSUM: a00b3c9f319cd1c9aa2c3fa15098864df94b066dcba0deaccbb3caa952d902fe
-- ARROW_AWS_C_SDKUTILS_BUILD_VERSION: v0.1.6
-- ARROW_AWS_C_SDKUTILS_BUILD_SHA256_CHECKSUM: 8a2951344b2fb541eab1e9ca17c18a7fcbfd2aaff4cdd31d362d1fad96111b91
-- ARROW_AWS_CHECKSUMS_BUILD_VERSION: v0.1.13
-- ARROW_AWS_CHECKSUMS_BUILD_SHA256_CHECKSUM: 0f897686f1963253c5069a0e495b85c31635ba146cd3ac38cc2ea31eaf54694d
-- ARROW_AWS_CRT_CPP_BUILD_VERSION: v0.18.16
-- ARROW_AWS_CRT_CPP_BUILD_SHA256_CHECKSUM: 9e69bc1dc4b50871d1038aa9ff6ddeb4c9b28f7d6b5e5b1b69041ccf50a13483
-- ARROW_AWS_LC_BUILD_VERSION: v1.3.0
-- ARROW_AWS_LC_BUILD_SHA256_CHECKSUM: ae96a3567161552744fc0cae8b4d68ed88b1ec0f3d3c98700070115356da5a37
-- ARROW_AWSSDK_BUILD_VERSION: 1.10.55
-- ARROW_AWSSDK_BUILD_SHA256_CHECKSUM: 2d552fb1a84bef4a9b65e34aa7031851ed2aef5319e02cc6e4cb735c48aa30de
-- ARROW_BOOST_BUILD_VERSION: 1.81.0
-- ARROW_BOOST_BUILD_SHA256_CHECKSUM: 9e0ffae35528c35f90468997bc8d99500bf179cbae355415a89a600c38e13574
-- ARROW_BROTLI_BUILD_VERSION: v1.0.9
-- ARROW_BROTLI_BUILD_SHA256_CHECKSUM: f9e8d81d0405ba66d181529af42a3354f838c939095ff99930da6aa9cdf6fe46
-- ARROW_BZIP2_BUILD_VERSION: 1.0.8
-- ARROW_BZIP2_BUILD_SHA256_CHECKSUM: ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269
-- ARROW_CARES_BUILD_VERSION: 1.17.2
-- ARROW_CARES_BUILD_SHA256_CHECKSUM: 4803c844ce20ce510ef0eb83f8ea41fa24ecaae9d280c468c582d2bb25b3913d
-- ARROW_CRC32C_BUILD_VERSION: 1.1.2
-- ARROW_CRC32C_BUILD_SHA256_CHECKSUM: ac07840513072b7fcebda6e821068aa04889018f24e10e46181068fb214d7e56
-- ARROW_GBENCHMARK_BUILD_VERSION: v1.7.1
-- ARROW_GBENCHMARK_BUILD_SHA256_CHECKSUM: 6430e4092653380d9dc4ccb45a1e2dc9259d581f4866dc0759713126056bc1d7
-- ARROW_GFLAGS_BUILD_VERSION: v2.2.2
-- ARROW_GFLAGS_BUILD_SHA256_CHECKSUM: 34af2f15cf7367513b352bdcd2493ab14ce43692d2dcd9dfc499492966c64dcf
-- ARROW_GLOG_BUILD_VERSION: v0.5.0
-- ARROW_GLOG_BUILD_SHA256_CHECKSUM: eede71f28371bf39aa69b45de23b329d37214016e2055269b3b5e7cfd40b59f5
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_VERSION: v2.8.0
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_SHA256_CHECKSUM: 21fb441b5a670a18bb16b6826be8e0530888d0b94320847c538d46f5a54dddbc
-- ARROW_GRPC_BUILD_VERSION: v1.46.3
-- ARROW_GRPC_BUILD_SHA256_CHECKSUM: d6cbf22cb5007af71b61c6be316a79397469c58c82a942552a62e708bce60964
-- ARROW_GTEST_BUILD_VERSION: 1.11.0
-- ARROW_GTEST_BUILD_SHA256_CHECKSUM: b4870bf121ff7795ba20d20bcdd8627b8e088f2d1dab299a031c1034eddc93d5
-- ARROW_JEMALLOC_BUILD_VERSION: 5.3.0
-- ARROW_JEMALLOC_BUILD_SHA256_CHECKSUM: 2db82d1e7119df3e71b7640219b6dfe84789bc0537983c3b7ac4f7189aecfeaa
-- ARROW_LZ4_BUILD_VERSION: v1.9.4
-- ARROW_LZ4_BUILD_SHA256_CHECKSUM: 0b0e3aa07c8c063ddf40b082bdf7e37a1562bda40a0ff5272957f3e987e0e54b
-- ARROW_MIMALLOC_BUILD_VERSION: v2.0.6
-- ARROW_MIMALLOC_BUILD_SHA256_CHECKSUM: 9f05c94cc2b017ed13698834ac2a3567b6339a8bde27640df5a1581d49d05ce5
-- ARROW_NLOHMANN_JSON_BUILD_VERSION: v3.10.5
-- ARROW_NLOHMANN_JSON_BUILD_SHA256_CHECKSUM: 5daca6ca216495edf89d167f808d1d03c4a4d929cef7da5e10f135ae1540c7e4
-- ARROW_OPENTELEMETRY_BUILD_VERSION: v1.8.1
-- ARROW_OPENTELEMETRY_BUILD_SHA256_CHECKSUM: 3d640201594b07f08dade9cd1017bd0b59674daca26223b560b9bb6bf56264c2
-- ARROW_OPENTELEMETRY_PROTO_BUILD_VERSION: v0.17.0
-- ARROW_OPENTELEMETRY_PROTO_BUILD_SHA256_CHECKSUM: f269fbcb30e17b03caa1decd231ce826e59d7651c0f71c3b28eb5140b4bb5412
-- ARROW_ORC_BUILD_VERSION: 1.8.3
-- ARROW_ORC_BUILD_SHA256_CHECKSUM: a78678ec425c8129d63370cb8a9bacb54186aa66af1e2bec01ce92e7eaf72e20
-- ARROW_PROTOBUF_BUILD_VERSION: v21.3
-- ARROW_PROTOBUF_BUILD_SHA256_CHECKSUM: 2f723218f6cb709ae4cdc4fb5ed56a5951fc5d466f0128ce4c946b8c78c8c49f
-- ARROW_RAPIDJSON_BUILD_VERSION: 232389d4f1012dddec4ef84861face2d2ba85709
-- ARROW_RAPIDJSON_BUILD_SHA256_CHECKSUM: b9290a9a6d444c8e049bd589ab804e0ccf2b05dc5984a19ed5ae75d090064806
-- ARROW_RE2_BUILD_VERSION: 2022-06-01
-- ARROW_RE2_BUILD_SHA256_CHECKSUM: f89c61410a072e5cbcf8c27e3a778da7d6fd2f2b5b1445cd4f4508bee946ab0f
-- ARROW_SNAPPY_BUILD_VERSION: 1.1.9
-- ARROW_SNAPPY_BUILD_SHA256_CHECKSUM: 75c1fbb3d618dd3a0483bff0e26d0a92b495bbe5059c8b4f1c962b478b6e06e7
-- ARROW_SUBSTRAIT_BUILD_VERSION: v0.20.0
-- ARROW_SUBSTRAIT_BUILD_SHA256_CHECKSUM: 5ceaa559ccef29a7825b5e5d4b5e7eed384830294f08bec913feecdd903a94cf
-- ARROW_S2N_TLS_BUILD_VERSION: v1.3.35
-- ARROW_S2N_TLS_BUILD_SHA256_CHECKSUM: 9d32b26e6bfcc058d98248bf8fc231537e347395dd89cf62bb432b55c5da990d
-- ARROW_THRIFT_BUILD_VERSION: 0.16.0
-- ARROW_THRIFT_BUILD_SHA256_CHECKSUM: f460b5c1ca30d8918ff95ea3eb6291b3951cf518553566088f3f2be8981f6209
-- ARROW_UCX_BUILD_VERSION: 1.12.1
-- ARROW_UCX_BUILD_SHA256_CHECKSUM: 9bef31aed0e28bf1973d28d74d9ac4f8926c43ca3b7010bd22a084e164e31b71
-- ARROW_UTF8PROC_BUILD_VERSION: v2.7.0
-- ARROW_UTF8PROC_BUILD_SHA256_CHECKSUM: 4bb121e297293c0fd55f08f83afab6d35d48f0af4ecc07523ad8ec99aa2b12a1
-- ARROW_XSIMD_BUILD_VERSION: 9.0.1
-- ARROW_XSIMD_BUILD_SHA256_CHECKSUM: b1bb5f92167fd3a4f25749db0be7e61ed37e0a5d943490f3accdcd2cd2918cc0
-- ARROW_ZLIB_BUILD_VERSION: 1.2.13
-- ARROW_ZLIB_BUILD_SHA256_CHECKSUM: b3a24de97a8fdbc835b9833169501030b8977031bcb54b3b3ac13740f846ab30
-- ARROW_ZSTD_BUILD_VERSION: 1.5.5
-- ARROW_ZSTD_BUILD_SHA256_CHECKSUM: 9c4396cc829cfae319a6e2615202e82aad41372073482fce286fac78646d3ee4
-- Boost include dir: /usr/include
-- Building without OpenSSL support. Minimum OpenSSL version 1.0.2 required.
-- Found thrift: /home/tdhock/.local/share/r-miniconda/envs/arrow
-- Found libevent include directory: /home/tdhock/.local/share/r-miniconda/envs/arrow/include
-- Found libevent component: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libevent_core.so
-- Found libevent component: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libevent_extra.so
-- Found libevent component: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libevent_openssl.so
-- Found libevent component: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libevent_pthreads.so
-- Found libevent 2.1.12 in /home/tdhock/.local/share/r-miniconda/envs/arrow
-- Providing CMake module for ThriftAlt as part of Arrow CMake package
-- Building jemalloc from source
-- Could NOT find GTest (missing: GTest_DIR)
-- Building gtest from source
-- RapidJSON found. Headers: /home/tdhock/.local/share/r-miniconda/envs/arrow/include
-- xsimd found. Headers: /home/tdhock/.local/share/r-miniconda/envs/arrow/include
-- Found hdfs.h at: /home/tdhock/arrow-git/cpp/thirdparty/hadoop/include/hdfs.h
-- All bundled static libraries: jemalloc::jemalloc
-- CMAKE_C_FLAGS:   -Wall -Wno-conversion -Wno-sign-conversion -Wunused-result -fno-semantic-interposition -msse4.2 -march=core2
-- CMAKE_CXX_FLAGS:  -Wno-noexcept-type  -fdiagnostics-color=always  -Wall -Wno-conversion -Wno-sign-conversion -Wunused-result -fno-semantic-interposition -msse4.2 -march=core2
-- CMAKE_C_FLAGS_DEBUG: -g -Werror -O0 -ggdb
-- CMAKE_CXX_FLAGS_DEBUG: -g -Werror -O0 -ggdb
-- ---------------------------------------------------------------------
-- Arrow version:                                 13.0.0-SNAPSHOT
-- 
-- Build configuration summary:
--   Generator: Ninja
--   Build type: DEBUG
--   Source directory: /home/tdhock/arrow-git/cpp
--   Install prefix: /home/tdhock
-- 
-- Compile and link options:
-- 
--   ARROW_CXXFLAGS=-march=core2 [default=""]
--       Compiler flags to append when compiling Arrow
--   ARROW_BUILD_STATIC=OFF [default=ON]
--       Build static libraries
--   ARROW_BUILD_SHARED=ON [default=ON]
--       Build shared libraries
--   ARROW_PACKAGE_KIND="" [default=""]
--       Arbitrary string that identifies the kind of package
--       (for informational purposes)
--   ARROW_GIT_ID=6d3fe6bda1c3b67b683ada2327194adeed09e9ca [default=""]
--       The Arrow git commit id (if any)
--   ARROW_GIT_DESCRIPTION=apache-arrow-13.0.0.dev-46-g6d3fe6bda [default=""]
--       The Arrow git commit description (if any)
--   ARROW_NO_DEPRECATED_API=OFF [default=OFF]
--       Exclude deprecated APIs from build
--   ARROW_POSITION_INDEPENDENT_CODE=ON [default=ON]
--       Whether to create position-independent target
--   ARROW_USE_CCACHE=ON [default=ON]
--       Use ccache when compiling (if available)
--   ARROW_USE_SCCACHE=ON [default=ON]
--       Use sccache when compiling (if available),
--       takes precedence over ccache if a storage backend is configured
--   ARROW_USE_LD_GOLD=OFF [default=OFF]
--       Use ld.gold for linking on Linux (if available)
--   ARROW_USE_PRECOMPILED_HEADERS=OFF [default=OFF]
--       Use precompiled headers when compiling
--   ARROW_SIMD_LEVEL=SSE4_2 [default=NONE|SSE4_2|AVX2|AVX512|NEON|SVE|SVE128|SVE256|SVE512|DEFAULT]
--       Compile-time SIMD optimization level
--   ARROW_RUNTIME_SIMD_LEVEL=MAX [default=NONE|SSE4_2|AVX2|AVX512|MAX]
--       Max runtime SIMD optimization level
--   ARROW_ALTIVEC=ON [default=ON]
--       Build with Altivec if compiler has support
--   ARROW_RPATH_ORIGIN=OFF [default=OFF]
--       Build Arrow libraries with RATH set to $ORIGIN
--   ARROW_INSTALL_NAME_RPATH=ON [default=ON]
--       Build Arrow libraries with install_name set to @rpath
--   ARROW_GGDB_DEBUG=ON [default=ON]
--       Pass -ggdb flag to debug builds
--   ARROW_WITH_MUSL=OFF [default=OFF]
--       Whether the system libc is musl or not
-- 
-- Test and benchmark options:
-- 
--   ARROW_BUILD_EXAMPLES=OFF [default=OFF]
--       Build the Arrow examples
--   ARROW_BUILD_TESTS=ON [default=OFF]
--       Build the Arrow googletest unit tests
--   ARROW_ENABLE_TIMING_TESTS=ON [default=ON]
--       Enable timing-sensitive tests
--   ARROW_BUILD_INTEGRATION=ON [default=OFF]
--       Build the Arrow integration test executables
--   ARROW_BUILD_BENCHMARKS=OFF [default=OFF]
--       Build the Arrow micro benchmarks
--   ARROW_BUILD_BENCHMARKS_REFERENCE=OFF [default=OFF]
--       Build the Arrow micro reference benchmarks
--   ARROW_BUILD_OPENMP_BENCHMARKS=OFF [default=OFF]
--       Build the Arrow benchmarks that rely on OpenMP
--   ARROW_BUILD_DETAILED_BENCHMARKS=OFF [default=OFF]
--       Build benchmarks that do a longer exploration of performance
--   ARROW_TEST_LINKAGE=shared [default=shared|static]
--       Linkage of Arrow libraries with unit tests executables.
--   ARROW_FUZZING=OFF [default=OFF]
--       Build Arrow Fuzzing executables
--   ARROW_LARGE_MEMORY_TESTS=OFF [default=OFF]
--       Enable unit tests which use large memory
-- 
-- Lint options:
-- 
--   ARROW_ONLY_LINT=OFF [default=OFF]
--       Only define the lint and check-format targets
--   ARROW_VERBOSE_LINT=OFF [default=OFF]
--       If off, 'quiet' flags will be passed to linting tools
--   ARROW_GENERATE_COVERAGE=OFF [default=OFF]
--       Build with C++ code coverage enabled
-- 
-- Checks options:
-- 
--   ARROW_TEST_MEMCHECK=OFF [default=OFF]
--       Run the test suite using valgrind --tool=memcheck
--   ARROW_USE_ASAN=OFF [default=OFF]
--       Enable Address Sanitizer checks
--   ARROW_USE_TSAN=OFF [default=OFF]
--       Enable Thread Sanitizer checks
--   ARROW_USE_UBSAN=OFF [default=OFF]
--       Enable Undefined Behavior sanitizer checks
-- 
-- Project component options:
-- 
--   ARROW_BUILD_UTILITIES=OFF [default=OFF]
--       Build Arrow commandline utilities
--   ARROW_COMPUTE=ON [default=OFF]
--       Build all Arrow Compute kernels
--   ARROW_CSV=ON [default=OFF]
--       Build the Arrow CSV Parser Module
--   ARROW_CUDA=OFF [default=OFF]
--       Build the Arrow CUDA extensions (requires CUDA toolkit)
--   ARROW_DATASET=ON [default=OFF]
--       Build the Arrow Dataset Modules
--   ARROW_FILESYSTEM=ON [default=OFF]
--       Build the Arrow Filesystem Layer
--   ARROW_FLIGHT=OFF [default=OFF]
--       Build the Arrow Flight RPC System (requires GRPC, Protocol Buffers)
--   ARROW_FLIGHT_SQL=OFF [default=OFF]
--       Build the Arrow Flight SQL extension
--   ARROW_GANDIVA=OFF [default=OFF]
--       Build the Gandiva libraries
--   ARROW_GCS=OFF [default=OFF]
--       Build Arrow with GCS support (requires the GCloud SDK for C++)
--   ARROW_HDFS=OFF [default=OFF]
--       Build the Arrow HDFS bridge
--   ARROW_IPC=ON [default=ON]
--       Build the Arrow IPC extensions
--   ARROW_JEMALLOC=ON [default=ON]
--       Build the Arrow jemalloc-based allocator
--   ARROW_JSON=ON [default=OFF]
--       Build Arrow with JSON support (requires RapidJSON)
--   ARROW_MIMALLOC=OFF [default=OFF]
--       Build the Arrow mimalloc-based allocator
--   ARROW_PARQUET=ON [default=OFF]
--       Build the Parquet libraries
--   ARROW_ORC=OFF [default=OFF]
--       Build the Arrow ORC adapter
--   ARROW_PYTHON=OFF [default=OFF]
--       Build some components needed by PyArrow.
--       (This is a deprecated option. Use CMake presets instead.)
--   ARROW_S3=OFF [default=OFF]
--       Build Arrow with S3 support (requires the AWS SDK for C++)
--   ARROW_SKYHOOK=OFF [default=OFF]
--       Build the Skyhook libraries
--   ARROW_SUBSTRAIT=OFF [default=OFF]
--       Build the Arrow Substrait Consumer Module
--   ARROW_ACERO=ON [default=OFF]
--       Build the Arrow Acero Engine Module
--   ARROW_TENSORFLOW=OFF [default=OFF]
--       Build Arrow with TensorFlow support enabled
--   ARROW_TESTING=ON [default=OFF]
--       Build the Arrow testing libraries
-- 
-- Thirdparty toolchain options:
-- 
--   ARROW_DEPENDENCY_SOURCE=CONDA [default=AUTO|BUNDLED|SYSTEM|CONDA|VCPKG|BREW]
--       Method to use for acquiring arrow's build dependencies
--   ARROW_VERBOSE_THIRDPARTY_BUILD=OFF [default=OFF]
--       Show output from ExternalProjects rather than just logging to files
--   ARROW_DEPENDENCY_USE_SHARED=ON [default=ON]
--       Link to shared libraries
--   ARROW_BOOST_USE_SHARED=ON [default=ON]
--       Rely on Boost shared libraries where relevant
--   ARROW_BROTLI_USE_SHARED=ON [default=ON]
--       Rely on Brotli shared libraries where relevant
--   ARROW_BZ2_USE_SHARED=ON [default=ON]
--       Rely on Bz2 shared libraries where relevant
--   ARROW_GFLAGS_USE_SHARED=ON [default=ON]
--       Rely on GFlags shared libraries where relevant
--   ARROW_GRPC_USE_SHARED=ON [default=ON]
--       Rely on gRPC shared libraries where relevant
--   ARROW_JEMALLOC_USE_SHARED=OFF [default=ON]
--       Rely on jemalloc shared libraries where relevant
--   ARROW_LZ4_USE_SHARED=ON [default=ON]
--       Rely on lz4 shared libraries where relevant
--   ARROW_OPENSSL_USE_SHARED=ON [default=ON]
--       Rely on OpenSSL shared libraries where relevant
--   ARROW_PROTOBUF_USE_SHARED=ON [default=ON]
--       Rely on Protocol Buffers shared libraries where relevant
--   ARROW_SNAPPY_USE_SHARED=ON [default=ON]
--       Rely on snappy shared libraries where relevant
--   ARROW_THRIFT_USE_SHARED=OFF [default=ON]
--       Rely on thrift shared libraries where relevant
--   ARROW_UTF8PROC_USE_SHARED=ON [default=ON]
--       Rely on utf8proc shared libraries where relevant
--   ARROW_ZSTD_USE_SHARED=ON [default=ON]
--       Rely on zstd shared libraries where relevant
--   ARROW_USE_GLOG=OFF [default=OFF]
--       Build libraries with glog support for pluggable logging
--   ARROW_WITH_BACKTRACE=ON [default=ON]
--       Build with backtrace support
--   ARROW_WITH_OPENTELEMETRY=OFF [default=OFF]
--       Build libraries with OpenTelemetry support for distributed tracing
--   ARROW_WITH_BROTLI=OFF [default=OFF]
--       Build with Brotli compression
--   ARROW_WITH_BZ2=OFF [default=OFF]
--       Build with BZ2 compression
--   ARROW_WITH_LZ4=OFF [default=OFF]
--       Build with lz4 compression
--   ARROW_WITH_SNAPPY=OFF [default=OFF]
--       Build with Snappy compression
--   ARROW_WITH_ZLIB=OFF [default=OFF]
--       Build with zlib compression
--   ARROW_WITH_ZSTD=OFF [default=OFF]
--       Build with zstd compression
--   ARROW_WITH_UCX=OFF [default=OFF]
--       Build with UCX transport for Arrow Flight
--       (only used if ARROW_FLIGHT is ON)
--   ARROW_WITH_UTF8PROC=OFF [default=ON]
--       Build with support for Unicode properties using the utf8proc library
--       (only used if ARROW_COMPUTE is ON or ARROW_GANDIVA is ON)
--   ARROW_WITH_RE2=OFF [default=ON]
--       Build with support for regular expressions using the re2 library
--       (only used if ARROW_COMPUTE or ARROW_GANDIVA is ON)
-- 
-- Parquet options:
-- 
--   PARQUET_MINIMAL_DEPENDENCY=OFF [default=OFF]
--       Depend only on Thirdparty headers to build libparquet.
--       Always OFF if building binaries
--   PARQUET_BUILD_EXECUTABLES=OFF [default=OFF]
--       Build the Parquet executable CLI tools. Requires static libraries to be built.
--   PARQUET_BUILD_EXAMPLES=OFF [default=OFF]
--       Build the Parquet examples. Requires static libraries to be built.
--   PARQUET_REQUIRE_ENCRYPTION=OFF [default=OFF]
--       Build support for encryption. Fail if OpenSSL is not found
-- 
-- Gandiva options:
-- 
--   ARROW_GANDIVA_STATIC_LIBSTDCPP=OFF [default=OFF]
--       Include -static-libstdc++ -static-libgcc when linking with
--       Gandiva static libraries
--   ARROW_GANDIVA_PC_CXX_FLAGS="" [default=""]
--       Compiler flags to append when pre-compiling Gandiva operations
-- 
-- Advanced developer options:
-- 
--   ARROW_EXTRA_ERROR_CONTEXT=ON [default=OFF]
--       Compile with extra error context (line numbers, code)
--   ARROW_OPTIONAL_INSTALL=OFF [default=OFF]
--       If enabled install ONLY targets that have already been built. Please be
--       advised that if this is enabled 'install' will fail silently on components
--       that have not been built
--   ARROW_GDB_INSTALL_DIR="" [default=""]
--       Use a custom install directory for GDB plugin.
--       In general, you don't need to specify this because the default
--       (CMAKE_INSTALL_FULL_BINDIR on Windows, CMAKE_INSTALL_FULL_LIBDIR otherwise)
--       is reasonable.
--   Outputting build configuration summary to /home/tdhock/arrow-git/cpp/build/cmake_summary.json
-- Configuring done
-- Generating done
-- Build files have been written to: /home/tdhock/arrow-git/cpp/build
(arrow) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main)$ cmake --build .
[0/1] Re-running CMake...
-- Building using CMake version: 3.22.1
-- Arrow version: 13.0.0 (full: '13.0.0-SNAPSHOT')
-- Arrow SO version: 1300 (full: 1300.0.0)
-- clang-tidy 14 not found
-- clang-format 14 not found
-- Could NOT find ClangTools (missing: CLANG_FORMAT_BIN CLANG_TIDY_BIN) 
-- infer not found
-- Found cpplint executable at /home/tdhock/arrow-git/cpp/build-support/cpplint.py
-- System processor: x86_64
-- Arrow build warning level: CHECKIN
-- Using ld linker
-- Build Type: DEBUG
-- Using CONDA approach to find dependencies
-- Using CONDA_PREFIX for ARROW_PACKAGE_PREFIX: /home/tdhock/.local/share/r-miniconda/envs/arrow
-- Setting (unset) dependency *_ROOT variables: /home/tdhock/.local/share/r-miniconda/envs/arrow
-- ARROW_ABSL_BUILD_VERSION: 20211102.0
-- ARROW_ABSL_BUILD_SHA256_CHECKSUM: dcf71b9cba8dc0ca9940c4b316a0c796be8fab42b070bb6b7cab62b48f0e66c4
-- ARROW_AWS_C_AUTH_BUILD_VERSION: v0.6.22
-- ARROW_AWS_C_AUTH_BUILD_SHA256_CHECKSUM: 691a6b4418afcd3dc141351b6ad33fccd8e3ff84df0e9e045b42295d284ee14c
-- ARROW_AWS_C_CAL_BUILD_VERSION: v0.5.20
-- ARROW_AWS_C_CAL_BUILD_SHA256_CHECKSUM: acc352359bd06f8597415c366cf4ec4f00d0b0da92d637039a73323dd55b6cd0
-- ARROW_AWS_C_COMMON_BUILD_VERSION: v0.8.9
-- ARROW_AWS_C_COMMON_BUILD_SHA256_CHECKSUM: 2f3fbaf7c38eae5a00e2a816d09b81177f93529ae8ba1b82dc8f31407565327a
-- ARROW_AWS_C_COMPRESSION_BUILD_VERSION: v0.2.16
-- ARROW_AWS_C_COMPRESSION_BUILD_SHA256_CHECKSUM: 044b1dbbca431a07bde8255ef9ec443c300fc60d4c9408d4b862f65e496687f4
-- ARROW_AWS_C_EVENT_STREAM_BUILD_VERSION: v0.2.18
-- ARROW_AWS_C_EVENT_STREAM_BUILD_SHA256_CHECKSUM: 310ca617f713bf664e4c7485a3d42c1fb57813abd0107e49790d107def7cde4f
-- ARROW_AWS_C_HTTP_BUILD_VERSION: v0.7.3
-- ARROW_AWS_C_HTTP_BUILD_SHA256_CHECKSUM: 07e16c6bf5eba6f0dea96b6f55eae312a7c95b736f4d2e4a210000f45d8265ae
-- ARROW_AWS_C_IO_BUILD_VERSION: v0.13.14
-- ARROW_AWS_C_IO_BUILD_SHA256_CHECKSUM: 12b66510c3d9a4f7e9b714e9cfab2a5bf835f8b9ce2f909d20ae2a2128608c71
-- ARROW_AWS_C_MQTT_BUILD_VERSION: v0.8.4
-- ARROW_AWS_C_MQTT_BUILD_SHA256_CHECKSUM: 232eeac63e72883d460c686a09b98cdd811d24579affac47c5c3f696f956773f
-- ARROW_AWS_C_S3_BUILD_VERSION: v0.2.3
-- ARROW_AWS_C_S3_BUILD_SHA256_CHECKSUM: a00b3c9f319cd1c9aa2c3fa15098864df94b066dcba0deaccbb3caa952d902fe
-- ARROW_AWS_C_SDKUTILS_BUILD_VERSION: v0.1.6
-- ARROW_AWS_C_SDKUTILS_BUILD_SHA256_CHECKSUM: 8a2951344b2fb541eab1e9ca17c18a7fcbfd2aaff4cdd31d362d1fad96111b91
-- ARROW_AWS_CHECKSUMS_BUILD_VERSION: v0.1.13
-- ARROW_AWS_CHECKSUMS_BUILD_SHA256_CHECKSUM: 0f897686f1963253c5069a0e495b85c31635ba146cd3ac38cc2ea31eaf54694d
-- ARROW_AWS_CRT_CPP_BUILD_VERSION: v0.18.16
-- ARROW_AWS_CRT_CPP_BUILD_SHA256_CHECKSUM: 9e69bc1dc4b50871d1038aa9ff6ddeb4c9b28f7d6b5e5b1b69041ccf50a13483
-- ARROW_AWS_LC_BUILD_VERSION: v1.3.0
-- ARROW_AWS_LC_BUILD_SHA256_CHECKSUM: ae96a3567161552744fc0cae8b4d68ed88b1ec0f3d3c98700070115356da5a37
-- ARROW_AWSSDK_BUILD_VERSION: 1.10.55
-- ARROW_AWSSDK_BUILD_SHA256_CHECKSUM: 2d552fb1a84bef4a9b65e34aa7031851ed2aef5319e02cc6e4cb735c48aa30de
-- ARROW_BOOST_BUILD_VERSION: 1.81.0
-- ARROW_BOOST_BUILD_SHA256_CHECKSUM: 9e0ffae35528c35f90468997bc8d99500bf179cbae355415a89a600c38e13574
-- ARROW_BROTLI_BUILD_VERSION: v1.0.9
-- ARROW_BROTLI_BUILD_SHA256_CHECKSUM: f9e8d81d0405ba66d181529af42a3354f838c939095ff99930da6aa9cdf6fe46
-- ARROW_BZIP2_BUILD_VERSION: 1.0.8
-- ARROW_BZIP2_BUILD_SHA256_CHECKSUM: ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269
-- ARROW_CARES_BUILD_VERSION: 1.17.2
-- ARROW_CARES_BUILD_SHA256_CHECKSUM: 4803c844ce20ce510ef0eb83f8ea41fa24ecaae9d280c468c582d2bb25b3913d
-- ARROW_CRC32C_BUILD_VERSION: 1.1.2
-- ARROW_CRC32C_BUILD_SHA256_CHECKSUM: ac07840513072b7fcebda6e821068aa04889018f24e10e46181068fb214d7e56
-- ARROW_GBENCHMARK_BUILD_VERSION: v1.7.1
-- ARROW_GBENCHMARK_BUILD_SHA256_CHECKSUM: 6430e4092653380d9dc4ccb45a1e2dc9259d581f4866dc0759713126056bc1d7
-- ARROW_GFLAGS_BUILD_VERSION: v2.2.2
-- ARROW_GFLAGS_BUILD_SHA256_CHECKSUM: 34af2f15cf7367513b352bdcd2493ab14ce43692d2dcd9dfc499492966c64dcf
-- ARROW_GLOG_BUILD_VERSION: v0.5.0
-- ARROW_GLOG_BUILD_SHA256_CHECKSUM: eede71f28371bf39aa69b45de23b329d37214016e2055269b3b5e7cfd40b59f5
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_VERSION: v2.8.0
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_SHA256_CHECKSUM: 21fb441b5a670a18bb16b6826be8e0530888d0b94320847c538d46f5a54dddbc
-- ARROW_GRPC_BUILD_VERSION: v1.46.3
-- ARROW_GRPC_BUILD_SHA256_CHECKSUM: d6cbf22cb5007af71b61c6be316a79397469c58c82a942552a62e708bce60964
-- ARROW_GTEST_BUILD_VERSION: 1.11.0
-- ARROW_GTEST_BUILD_SHA256_CHECKSUM: b4870bf121ff7795ba20d20bcdd8627b8e088f2d1dab299a031c1034eddc93d5
-- ARROW_JEMALLOC_BUILD_VERSION: 5.3.0
-- ARROW_JEMALLOC_BUILD_SHA256_CHECKSUM: 2db82d1e7119df3e71b7640219b6dfe84789bc0537983c3b7ac4f7189aecfeaa
-- ARROW_LZ4_BUILD_VERSION: v1.9.4
-- ARROW_LZ4_BUILD_SHA256_CHECKSUM: 0b0e3aa07c8c063ddf40b082bdf7e37a1562bda40a0ff5272957f3e987e0e54b
-- ARROW_MIMALLOC_BUILD_VERSION: v2.0.6
-- ARROW_MIMALLOC_BUILD_SHA256_CHECKSUM: 9f05c94cc2b017ed13698834ac2a3567b6339a8bde27640df5a1581d49d05ce5
-- ARROW_NLOHMANN_JSON_BUILD_VERSION: v3.10.5
-- ARROW_NLOHMANN_JSON_BUILD_SHA256_CHECKSUM: 5daca6ca216495edf89d167f808d1d03c4a4d929cef7da5e10f135ae1540c7e4
-- ARROW_OPENTELEMETRY_BUILD_VERSION: v1.8.1
-- ARROW_OPENTELEMETRY_BUILD_SHA256_CHECKSUM: 3d640201594b07f08dade9cd1017bd0b59674daca26223b560b9bb6bf56264c2
-- ARROW_OPENTELEMETRY_PROTO_BUILD_VERSION: v0.17.0
-- ARROW_OPENTELEMETRY_PROTO_BUILD_SHA256_CHECKSUM: f269fbcb30e17b03caa1decd231ce826e59d7651c0f71c3b28eb5140b4bb5412
-- ARROW_ORC_BUILD_VERSION: 1.8.3
-- ARROW_ORC_BUILD_SHA256_CHECKSUM: a78678ec425c8129d63370cb8a9bacb54186aa66af1e2bec01ce92e7eaf72e20
-- ARROW_PROTOBUF_BUILD_VERSION: v21.3
-- ARROW_PROTOBUF_BUILD_SHA256_CHECKSUM: 2f723218f6cb709ae4cdc4fb5ed56a5951fc5d466f0128ce4c946b8c78c8c49f
-- ARROW_RAPIDJSON_BUILD_VERSION: 232389d4f1012dddec4ef84861face2d2ba85709
-- ARROW_RAPIDJSON_BUILD_SHA256_CHECKSUM: b9290a9a6d444c8e049bd589ab804e0ccf2b05dc5984a19ed5ae75d090064806
-- ARROW_RE2_BUILD_VERSION: 2022-06-01
-- ARROW_RE2_BUILD_SHA256_CHECKSUM: f89c61410a072e5cbcf8c27e3a778da7d6fd2f2b5b1445cd4f4508bee946ab0f
-- ARROW_SNAPPY_BUILD_VERSION: 1.1.9
-- ARROW_SNAPPY_BUILD_SHA256_CHECKSUM: 75c1fbb3d618dd3a0483bff0e26d0a92b495bbe5059c8b4f1c962b478b6e06e7
-- ARROW_SUBSTRAIT_BUILD_VERSION: v0.20.0
-- ARROW_SUBSTRAIT_BUILD_SHA256_CHECKSUM: 5ceaa559ccef29a7825b5e5d4b5e7eed384830294f08bec913feecdd903a94cf
-- ARROW_S2N_TLS_BUILD_VERSION: v1.3.35
-- ARROW_S2N_TLS_BUILD_SHA256_CHECKSUM: 9d32b26e6bfcc058d98248bf8fc231537e347395dd89cf62bb432b55c5da990d
-- ARROW_THRIFT_BUILD_VERSION: 0.16.0
-- ARROW_THRIFT_BUILD_SHA256_CHECKSUM: f460b5c1ca30d8918ff95ea3eb6291b3951cf518553566088f3f2be8981f6209
-- ARROW_UCX_BUILD_VERSION: 1.12.1
-- ARROW_UCX_BUILD_SHA256_CHECKSUM: 9bef31aed0e28bf1973d28d74d9ac4f8926c43ca3b7010bd22a084e164e31b71
-- ARROW_UTF8PROC_BUILD_VERSION: v2.7.0
-- ARROW_UTF8PROC_BUILD_SHA256_CHECKSUM: 4bb121e297293c0fd55f08f83afab6d35d48f0af4ecc07523ad8ec99aa2b12a1
-- ARROW_XSIMD_BUILD_VERSION: 9.0.1
-- ARROW_XSIMD_BUILD_SHA256_CHECKSUM: b1bb5f92167fd3a4f25749db0be7e61ed37e0a5d943490f3accdcd2cd2918cc0
-- ARROW_ZLIB_BUILD_VERSION: 1.2.13
-- ARROW_ZLIB_BUILD_SHA256_CHECKSUM: b3a24de97a8fdbc835b9833169501030b8977031bcb54b3b3ac13740f846ab30
-- ARROW_ZSTD_BUILD_VERSION: 1.5.5
-- ARROW_ZSTD_BUILD_SHA256_CHECKSUM: 9c4396cc829cfae319a6e2615202e82aad41372073482fce286fac78646d3ee4
-- Boost include dir: /usr/include
-- Building without OpenSSL support. Minimum OpenSSL version 1.0.2 required.
-- Found thrift: /home/tdhock/.local/share/r-miniconda/envs/arrow
-- Found libevent include directory: /home/tdhock/.local/share/r-miniconda/envs/arrow/include
-- Found libevent component: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libevent_core.so
-- Found libevent component: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libevent_extra.so
-- Found libevent component: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libevent_openssl.so
-- Found libevent component: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libevent_pthreads.so
-- Found libevent 2.1.12 in /home/tdhock/.local/share/r-miniconda/envs/arrow
-- Providing CMake module for ThriftAlt as part of Arrow CMake package
-- Building jemalloc from source
-- Could NOT find GTest (missing: GTest_DIR)
-- Building gtest from source
-- RapidJSON found. Headers: /home/tdhock/.local/share/r-miniconda/envs/arrow/include
-- xsimd found. Headers: /home/tdhock/.local/share/r-miniconda/envs/arrow/include
-- Found hdfs.h at: /home/tdhock/arrow-git/cpp/thirdparty/hadoop/include/hdfs.h
-- All bundled static libraries: jemalloc::jemalloc
-- CMAKE_C_FLAGS:   -Wall -Wno-conversion -Wno-sign-conversion -Wunused-result -fno-semantic-interposition -msse4.2 -march=core2
-- CMAKE_CXX_FLAGS:  -Wno-noexcept-type  -fdiagnostics-color=always  -Wall -Wno-conversion -Wno-sign-conversion -Wunused-result -fno-semantic-interposition -msse4.2 -march=core2
-- CMAKE_C_FLAGS_DEBUG: -g -Werror -O0 -ggdb
-- CMAKE_CXX_FLAGS_DEBUG: -g -Werror -O0 -ggdb
-- ---------------------------------------------------------------------
-- Arrow version:                                 13.0.0-SNAPSHOT
-- 
-- Build configuration summary:
--   Generator: Ninja
--   Build type: DEBUG
--   Source directory: /home/tdhock/arrow-git/cpp
--   Install prefix: /home/tdhock
-- 
-- Compile and link options:
-- 
--   ARROW_CXXFLAGS=-march=core2 [default=""]
--       Compiler flags to append when compiling Arrow
--   ARROW_BUILD_STATIC=OFF [default=ON]
--       Build static libraries
--   ARROW_BUILD_SHARED=ON [default=ON]
--       Build shared libraries
--   ARROW_PACKAGE_KIND="" [default=""]
--       Arbitrary string that identifies the kind of package
--       (for informational purposes)
--   ARROW_GIT_ID=6d3fe6bda1c3b67b683ada2327194adeed09e9ca [default=""]
--       The Arrow git commit id (if any)
--   ARROW_GIT_DESCRIPTION=apache-arrow-13.0.0.dev-46-g6d3fe6bda [default=""]
--       The Arrow git commit description (if any)
--   ARROW_NO_DEPRECATED_API=OFF [default=OFF]
--       Exclude deprecated APIs from build
--   ARROW_POSITION_INDEPENDENT_CODE=ON [default=ON]
--       Whether to create position-independent target
--   ARROW_USE_CCACHE=ON [default=ON]
--       Use ccache when compiling (if available)
--   ARROW_USE_SCCACHE=ON [default=ON]
--       Use sccache when compiling (if available),
--       takes precedence over ccache if a storage backend is configured
--   ARROW_USE_LD_GOLD=OFF [default=OFF]
--       Use ld.gold for linking on Linux (if available)
--   ARROW_USE_PRECOMPILED_HEADERS=OFF [default=OFF]
--       Use precompiled headers when compiling
--   ARROW_SIMD_LEVEL=SSE4_2 [default=NONE|SSE4_2|AVX2|AVX512|NEON|SVE|SVE128|SVE256|SVE512|DEFAULT]
--       Compile-time SIMD optimization level
--   ARROW_RUNTIME_SIMD_LEVEL=MAX [default=NONE|SSE4_2|AVX2|AVX512|MAX]
--       Max runtime SIMD optimization level
--   ARROW_ALTIVEC=ON [default=ON]
--       Build with Altivec if compiler has support
--   ARROW_RPATH_ORIGIN=OFF [default=OFF]
--       Build Arrow libraries with RATH set to $ORIGIN
--   ARROW_INSTALL_NAME_RPATH=ON [default=ON]
--       Build Arrow libraries with install_name set to @rpath
--   ARROW_GGDB_DEBUG=ON [default=ON]
--       Pass -ggdb flag to debug builds
--   ARROW_WITH_MUSL=OFF [default=OFF]
--       Whether the system libc is musl or not
-- 
-- Test and benchmark options:
-- 
--   ARROW_BUILD_EXAMPLES=OFF [default=OFF]
--       Build the Arrow examples
--   ARROW_BUILD_TESTS=ON [default=OFF]
--       Build the Arrow googletest unit tests
--   ARROW_ENABLE_TIMING_TESTS=ON [default=ON]
--       Enable timing-sensitive tests
--   ARROW_BUILD_INTEGRATION=ON [default=OFF]
--       Build the Arrow integration test executables
--   ARROW_BUILD_BENCHMARKS=OFF [default=OFF]
--       Build the Arrow micro benchmarks
--   ARROW_BUILD_BENCHMARKS_REFERENCE=OFF [default=OFF]
--       Build the Arrow micro reference benchmarks
--   ARROW_BUILD_OPENMP_BENCHMARKS=OFF [default=OFF]
--       Build the Arrow benchmarks that rely on OpenMP
--   ARROW_BUILD_DETAILED_BENCHMARKS=OFF [default=OFF]
--       Build benchmarks that do a longer exploration of performance
--   ARROW_TEST_LINKAGE=shared [default=shared|static]
--       Linkage of Arrow libraries with unit tests executables.
--   ARROW_FUZZING=OFF [default=OFF]
--       Build Arrow Fuzzing executables
--   ARROW_LARGE_MEMORY_TESTS=OFF [default=OFF]
--       Enable unit tests which use large memory
-- 
-- Lint options:
-- 
--   ARROW_ONLY_LINT=OFF [default=OFF]
--       Only define the lint and check-format targets
--   ARROW_VERBOSE_LINT=OFF [default=OFF]
--       If off, 'quiet' flags will be passed to linting tools
--   ARROW_GENERATE_COVERAGE=OFF [default=OFF]
--       Build with C++ code coverage enabled
-- 
-- Checks options:
-- 
--   ARROW_TEST_MEMCHECK=OFF [default=OFF]
--       Run the test suite using valgrind --tool=memcheck
--   ARROW_USE_ASAN=OFF [default=OFF]
--       Enable Address Sanitizer checks
--   ARROW_USE_TSAN=OFF [default=OFF]
--       Enable Thread Sanitizer checks
--   ARROW_USE_UBSAN=OFF [default=OFF]
--       Enable Undefined Behavior sanitizer checks
-- 
-- Project component options:
-- 
--   ARROW_BUILD_UTILITIES=OFF [default=OFF]
--       Build Arrow commandline utilities
--   ARROW_COMPUTE=ON [default=OFF]
--       Build all Arrow Compute kernels
--   ARROW_CSV=ON [default=OFF]
--       Build the Arrow CSV Parser Module
--   ARROW_CUDA=OFF [default=OFF]
--       Build the Arrow CUDA extensions (requires CUDA toolkit)
--   ARROW_DATASET=ON [default=OFF]
--       Build the Arrow Dataset Modules
--   ARROW_FILESYSTEM=ON [default=OFF]
--       Build the Arrow Filesystem Layer
--   ARROW_FLIGHT=OFF [default=OFF]
--       Build the Arrow Flight RPC System (requires GRPC, Protocol Buffers)
--   ARROW_FLIGHT_SQL=OFF [default=OFF]
--       Build the Arrow Flight SQL extension
--   ARROW_GANDIVA=OFF [default=OFF]
--       Build the Gandiva libraries
--   ARROW_GCS=OFF [default=OFF]
--       Build Arrow with GCS support (requires the GCloud SDK for C++)
--   ARROW_HDFS=OFF [default=OFF]
--       Build the Arrow HDFS bridge
--   ARROW_IPC=ON [default=ON]
--       Build the Arrow IPC extensions
--   ARROW_JEMALLOC=ON [default=ON]
--       Build the Arrow jemalloc-based allocator
--   ARROW_JSON=ON [default=OFF]
--       Build Arrow with JSON support (requires RapidJSON)
--   ARROW_MIMALLOC=OFF [default=OFF]
--       Build the Arrow mimalloc-based allocator
--   ARROW_PARQUET=ON [default=OFF]
--       Build the Parquet libraries
--   ARROW_ORC=OFF [default=OFF]
--       Build the Arrow ORC adapter
--   ARROW_PYTHON=OFF [default=OFF]
--       Build some components needed by PyArrow.
--       (This is a deprecated option. Use CMake presets instead.)
--   ARROW_S3=OFF [default=OFF]
--       Build Arrow with S3 support (requires the AWS SDK for C++)
--   ARROW_SKYHOOK=OFF [default=OFF]
--       Build the Skyhook libraries
--   ARROW_SUBSTRAIT=OFF [default=OFF]
--       Build the Arrow Substrait Consumer Module
--   ARROW_ACERO=ON [default=OFF]
--       Build the Arrow Acero Engine Module
--   ARROW_TENSORFLOW=OFF [default=OFF]
--       Build Arrow with TensorFlow support enabled
--   ARROW_TESTING=ON [default=OFF]
--       Build the Arrow testing libraries
-- 
-- Thirdparty toolchain options:
-- 
--   ARROW_DEPENDENCY_SOURCE=CONDA [default=AUTO|BUNDLED|SYSTEM|CONDA|VCPKG|BREW]
--       Method to use for acquiring arrow's build dependencies
--   ARROW_VERBOSE_THIRDPARTY_BUILD=OFF [default=OFF]
--       Show output from ExternalProjects rather than just logging to files
--   ARROW_DEPENDENCY_USE_SHARED=ON [default=ON]
--       Link to shared libraries
--   ARROW_BOOST_USE_SHARED=ON [default=ON]
--       Rely on Boost shared libraries where relevant
--   ARROW_BROTLI_USE_SHARED=ON [default=ON]
--       Rely on Brotli shared libraries where relevant
--   ARROW_BZ2_USE_SHARED=ON [default=ON]
--       Rely on Bz2 shared libraries where relevant
--   ARROW_GFLAGS_USE_SHARED=ON [default=ON]
--       Rely on GFlags shared libraries where relevant
--   ARROW_GRPC_USE_SHARED=ON [default=ON]
--       Rely on gRPC shared libraries where relevant
--   ARROW_JEMALLOC_USE_SHARED=OFF [default=ON]
--       Rely on jemalloc shared libraries where relevant
--   ARROW_LZ4_USE_SHARED=ON [default=ON]
--       Rely on lz4 shared libraries where relevant
--   ARROW_OPENSSL_USE_SHARED=ON [default=ON]
--       Rely on OpenSSL shared libraries where relevant
--   ARROW_PROTOBUF_USE_SHARED=ON [default=ON]
--       Rely on Protocol Buffers shared libraries where relevant
--   ARROW_SNAPPY_USE_SHARED=ON [default=ON]
--       Rely on snappy shared libraries where relevant
--   ARROW_THRIFT_USE_SHARED=OFF [default=ON]
--       Rely on thrift shared libraries where relevant
--   ARROW_UTF8PROC_USE_SHARED=ON [default=ON]
--       Rely on utf8proc shared libraries where relevant
--   ARROW_ZSTD_USE_SHARED=ON [default=ON]
--       Rely on zstd shared libraries where relevant
--   ARROW_USE_GLOG=OFF [default=OFF]
--       Build libraries with glog support for pluggable logging
--   ARROW_WITH_BACKTRACE=ON [default=ON]
--       Build with backtrace support
--   ARROW_WITH_OPENTELEMETRY=OFF [default=OFF]
--       Build libraries with OpenTelemetry support for distributed tracing
--   ARROW_WITH_BROTLI=OFF [default=OFF]
--       Build with Brotli compression
--   ARROW_WITH_BZ2=OFF [default=OFF]
--       Build with BZ2 compression
--   ARROW_WITH_LZ4=OFF [default=OFF]
--       Build with lz4 compression
--   ARROW_WITH_SNAPPY=OFF [default=OFF]
--       Build with Snappy compression
--   ARROW_WITH_ZLIB=OFF [default=OFF]
--       Build with zlib compression
--   ARROW_WITH_ZSTD=OFF [default=OFF]
--       Build with zstd compression
--   ARROW_WITH_UCX=OFF [default=OFF]
--       Build with UCX transport for Arrow Flight
--       (only used if ARROW_FLIGHT is ON)
--   ARROW_WITH_UTF8PROC=OFF [default=ON]
--       Build with support for Unicode properties using the utf8proc library
--       (only used if ARROW_COMPUTE is ON or ARROW_GANDIVA is ON)
--   ARROW_WITH_RE2=OFF [default=ON]
--       Build with support for regular expressions using the re2 library
--       (only used if ARROW_COMPUTE or ARROW_GANDIVA is ON)
-- 
-- Parquet options:
-- 
--   PARQUET_MINIMAL_DEPENDENCY=OFF [default=OFF]
--       Depend only on Thirdparty headers to build libparquet.
--       Always OFF if building binaries
--   PARQUET_BUILD_EXECUTABLES=OFF [default=OFF]
--       Build the Parquet executable CLI tools. Requires static libraries to be built.
--   PARQUET_BUILD_EXAMPLES=OFF [default=OFF]
--       Build the Parquet examples. Requires static libraries to be built.
--   PARQUET_REQUIRE_ENCRYPTION=OFF [default=OFF]
--       Build support for encryption. Fail if OpenSSL is not found
-- 
-- Gandiva options:
-- 
--   ARROW_GANDIVA_STATIC_LIBSTDCPP=OFF [default=OFF]
--       Include -static-libstdc++ -static-libgcc when linking with
--       Gandiva static libraries
--   ARROW_GANDIVA_PC_CXX_FLAGS="" [default=""]
--       Compiler flags to append when pre-compiling Gandiva operations
-- 
-- Advanced developer options:
-- 
--   ARROW_EXTRA_ERROR_CONTEXT=ON [default=OFF]
--       Compile with extra error context (line numbers, code)
--   ARROW_OPTIONAL_INSTALL=OFF [default=OFF]
--       If enabled install ONLY targets that have already been built. Please be
--       advised that if this is enabled 'install' will fail silently on components
--       that have not been built
--   ARROW_GDB_INSTALL_DIR="" [default=""]
--       Use a custom install directory for GDB plugin.
--       In general, you don't need to specify this because the default
--       (CMAKE_INSTALL_FULL_BINDIR on Windows, CMAKE_INSTALL_FULL_LIBDIR otherwise)
--       is reasonable.
--   Outputting build configuration summary to /home/tdhock/arrow-git/cpp/build/cmake_summary.json
-- Configuring done
-- Generating done
-- Build files have been written to: /home/tdhock/arrow-git/cpp/build
[1/365] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/buffered.cc.o
[2/365] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/caching.cc.o
[3/365] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/c/bridge.cc.o
[4/365] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/compressed.cc.o
[5/365] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/file.cc.o
[6/365] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/interfaces.cc.o
[7/365] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/memory.cc.o
[8/365] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/scalar.cc.o
[9/365] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/slow.cc.o
[10/365] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/io/transform.cc.o
[11/365] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/basic_decimal.cc.o
[12/365] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/async_util.cc.o
[13/365] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/formatting.cc.o
[14/365] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/util/decimal.cc.o
...
[364/365] Building CXX object src/parquet/CMakeFiles/parquet-arrow-test.dir/arrow/arrow_reader_writer_test.cc.o
[365/365] Linking CXX executable debug/parquet-arrow-test
(arrow) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main)$ cmake --install .
-- Install configuration: "DEBUG"
-- Installing: /home/tdhock/lib/cmake/Arrow/FindThriftAlt.cmake
-- Installing: /home/tdhock/include/arrow/util/config.h
-- Up-to-date: /home/tdhock/share/doc/arrow/LICENSE.txt
-- Up-to-date: /home/tdhock/share/doc/arrow/NOTICE.txt
-- Up-to-date: /home/tdhock/share/doc/arrow/README.md
-- Up-to-date: /home/tdhock/share/arrow/gdb/gdb_arrow.py
-- Installing: /home/tdhock/lib/libarrow.so.1300.0.0
-- Up-to-date: /home/tdhock/lib/pkgconfig/arrow.pc
-- Up-to-date: /home/tdhock/share/gdb/auto-load/home/tdhock/lib/libarrow.so.1300.0.0-gdb.py
-- Installing: /home/tdhock/lib/libarrow_testing.so.1300.0.0
-- Up-to-date: /home/tdhock/lib/libarrow_testing.so.1300
-- Set runtime path of "/home/tdhock/lib/libarrow_testing.so.1300.0.0" to ""
-- Up-to-date: /home/tdhock/lib/libarrow_testing.so
-- Up-to-date: /home/tdhock/lib/cmake/ArrowTesting/ArrowTestingConfig.cmake
-- Up-to-date: /home/tdhock/lib/cmake/ArrowTesting/ArrowTestingConfigVersion.cmake
-- Up-to-date: /home/tdhock/lib/cmake/ArrowTesting/ArrowTestingTargets.cmake
-- Up-to-date: /home/tdhock/lib/cmake/ArrowTesting/ArrowTestingTargets-debug.cmake
-- Up-to-date: /home/tdhock/lib/pkgconfig/arrow-testing.pc
-- Up-to-date: /home/tdhock/include/arrow/api.h
-- Up-to-date: /home/tdhock/include/arrow/array.h
-- Up-to-date: /home/tdhock/include/arrow/buffer.h
-- Up-to-date: /home/tdhock/include/arrow/buffer_builder.h
-- Up-to-date: /home/tdhock/include/arrow/builder.h
-- Up-to-date: /home/tdhock/include/arrow/chunk_resolver.h
-- Up-to-date: /home/tdhock/include/arrow/chunked_array.h
-- Up-to-date: /home/tdhock/include/arrow/compare.h
-- Up-to-date: /home/tdhock/include/arrow/config.h
-- Up-to-date: /home/tdhock/include/arrow/datum.h
-- Up-to-date: /home/tdhock/include/arrow/device.h
-- Up-to-date: /home/tdhock/include/arrow/extension_type.h
-- Up-to-date: /home/tdhock/include/arrow/memory_pool.h
-- Up-to-date: /home/tdhock/include/arrow/memory_pool_test.h
-- Up-to-date: /home/tdhock/include/arrow/pch.h
-- Up-to-date: /home/tdhock/include/arrow/pretty_print.h
-- Up-to-date: /home/tdhock/include/arrow/record_batch.h
-- Up-to-date: /home/tdhock/include/arrow/result.h
-- Up-to-date: /home/tdhock/include/arrow/scalar.h
-- Up-to-date: /home/tdhock/include/arrow/sparse_tensor.h
-- Up-to-date: /home/tdhock/include/arrow/status.h
-- Up-to-date: /home/tdhock/include/arrow/stl.h
-- Up-to-date: /home/tdhock/include/arrow/stl_allocator.h
-- Up-to-date: /home/tdhock/include/arrow/stl_iterator.h
-- Up-to-date: /home/tdhock/include/arrow/table.h
-- Up-to-date: /home/tdhock/include/arrow/table_builder.h
-- Up-to-date: /home/tdhock/include/arrow/tensor.h
-- Up-to-date: /home/tdhock/include/arrow/type.h
-- Up-to-date: /home/tdhock/include/arrow/type_fwd.h
-- Up-to-date: /home/tdhock/include/arrow/type_traits.h
-- Up-to-date: /home/tdhock/include/arrow/visit_array_inline.h
-- Up-to-date: /home/tdhock/include/arrow/visit_data_inline.h
-- Up-to-date: /home/tdhock/include/arrow/visit_scalar_inline.h
-- Up-to-date: /home/tdhock/include/arrow/visit_type_inline.h
-- Up-to-date: /home/tdhock/include/arrow/visitor.h
-- Up-to-date: /home/tdhock/include/arrow/visitor_generate.h
-- Installing: /home/tdhock/lib/cmake/Arrow/ArrowOptions.cmake
-- Up-to-date: /home/tdhock/lib/cmake/Arrow/arrow-config.cmake
-- Up-to-date: /home/tdhock/include/arrow/testing/async_test_util.h
-- Up-to-date: /home/tdhock/include/arrow/testing/builder.h
-- Up-to-date: /home/tdhock/include/arrow/testing/executor_util.h
-- Up-to-date: /home/tdhock/include/arrow/testing/extension_type.h
-- Up-to-date: /home/tdhock/include/arrow/testing/future_util.h
-- Up-to-date: /home/tdhock/include/arrow/testing/generator.h
-- Up-to-date: /home/tdhock/include/arrow/testing/gtest_compat.h
-- Up-to-date: /home/tdhock/include/arrow/testing/gtest_util.h
-- Up-to-date: /home/tdhock/include/arrow/testing/json_integration.h
-- Up-to-date: /home/tdhock/include/arrow/testing/matchers.h
-- Up-to-date: /home/tdhock/include/arrow/testing/pch.h
-- Up-to-date: /home/tdhock/include/arrow/testing/random.h
-- Up-to-date: /home/tdhock/include/arrow/testing/uniform_real.h
-- Up-to-date: /home/tdhock/include/arrow/testing/util.h
-- Up-to-date: /home/tdhock/include/arrow/testing/visibility.h
-- Up-to-date: /home/tdhock/include/arrow/array/array_base.h
-- Up-to-date: /home/tdhock/include/arrow/array/array_binary.h
-- Up-to-date: /home/tdhock/include/arrow/array/array_decimal.h
-- Up-to-date: /home/tdhock/include/arrow/array/array_dict.h
-- Up-to-date: /home/tdhock/include/arrow/array/array_nested.h
-- Up-to-date: /home/tdhock/include/arrow/array/array_primitive.h
-- Up-to-date: /home/tdhock/include/arrow/array/array_run_end.h
-- Up-to-date: /home/tdhock/include/arrow/array/builder_adaptive.h
-- Up-to-date: /home/tdhock/include/arrow/array/builder_base.h
-- Up-to-date: /home/tdhock/include/arrow/array/builder_binary.h
-- Up-to-date: /home/tdhock/include/arrow/array/builder_decimal.h
-- Up-to-date: /home/tdhock/include/arrow/array/builder_dict.h
-- Up-to-date: /home/tdhock/include/arrow/array/builder_nested.h
-- Up-to-date: /home/tdhock/include/arrow/array/builder_primitive.h
-- Up-to-date: /home/tdhock/include/arrow/array/builder_run_end.h
-- Up-to-date: /home/tdhock/include/arrow/array/builder_time.h
-- Up-to-date: /home/tdhock/include/arrow/array/builder_union.h
-- Up-to-date: /home/tdhock/include/arrow/array/concatenate.h
-- Up-to-date: /home/tdhock/include/arrow/array/data.h
-- Up-to-date: /home/tdhock/include/arrow/array/diff.h
-- Up-to-date: /home/tdhock/include/arrow/array/util.h
-- Up-to-date: /home/tdhock/include/arrow/array/validate.h
-- Up-to-date: /home/tdhock/include/arrow/c/abi.h
-- Up-to-date: /home/tdhock/include/arrow/c/bridge.h
-- Up-to-date: /home/tdhock/include/arrow/c/helpers.h
-- Up-to-date: /home/tdhock/include/arrow/compute/api.h
-- Up-to-date: /home/tdhock/include/arrow/compute/api_aggregate.h
-- Up-to-date: /home/tdhock/include/arrow/compute/api_scalar.h
-- Up-to-date: /home/tdhock/include/arrow/compute/api_vector.h
-- Up-to-date: /home/tdhock/include/arrow/compute/cast.h
-- Up-to-date: /home/tdhock/include/arrow/compute/exec.h
-- Up-to-date: /home/tdhock/include/arrow/compute/expression.h
-- Up-to-date: /home/tdhock/include/arrow/compute/function.h
-- Up-to-date: /home/tdhock/include/arrow/compute/kernel.h
-- Up-to-date: /home/tdhock/include/arrow/compute/key_hash.h
-- Up-to-date: /home/tdhock/include/arrow/compute/key_map.h
-- Up-to-date: /home/tdhock/include/arrow/compute/light_array.h
-- Up-to-date: /home/tdhock/include/arrow/compute/ordering.h
-- Up-to-date: /home/tdhock/include/arrow/compute/registry.h
-- Up-to-date: /home/tdhock/include/arrow/compute/type_fwd.h
-- Up-to-date: /home/tdhock/include/arrow/compute/util.h
-- Up-to-date: /home/tdhock/lib/pkgconfig/arrow-compute.pc
-- Up-to-date: /home/tdhock/include/arrow/compute/row/grouper.h
-- Up-to-date: /home/tdhock/include/arrow/io/api.h
-- Up-to-date: /home/tdhock/include/arrow/io/buffered.h
-- Up-to-date: /home/tdhock/include/arrow/io/caching.h
-- Up-to-date: /home/tdhock/include/arrow/io/compressed.h
-- Up-to-date: /home/tdhock/include/arrow/io/concurrency.h
-- Up-to-date: /home/tdhock/include/arrow/io/file.h
-- Up-to-date: /home/tdhock/include/arrow/io/hdfs.h
-- Up-to-date: /home/tdhock/include/arrow/io/interfaces.h
-- Up-to-date: /home/tdhock/include/arrow/io/memory.h
-- Up-to-date: /home/tdhock/include/arrow/io/mman.h
-- Up-to-date: /home/tdhock/include/arrow/io/slow.h
-- Up-to-date: /home/tdhock/include/arrow/io/stdio.h
-- Up-to-date: /home/tdhock/include/arrow/io/test_common.h
-- Up-to-date: /home/tdhock/include/arrow/io/transform.h
-- Up-to-date: /home/tdhock/include/arrow/io/type_fwd.h
-- Up-to-date: /home/tdhock/include/arrow/tensor/converter.h
-- Up-to-date: /home/tdhock/include/arrow/util/algorithm.h
-- Up-to-date: /home/tdhock/include/arrow/util/align_util.h
-- Up-to-date: /home/tdhock/include/arrow/util/aligned_storage.h
-- Up-to-date: /home/tdhock/include/arrow/util/async_generator.h
-- Up-to-date: /home/tdhock/include/arrow/util/async_generator_fwd.h
-- Up-to-date: /home/tdhock/include/arrow/util/async_util.h
-- Up-to-date: /home/tdhock/include/arrow/util/base64.h
-- Up-to-date: /home/tdhock/include/arrow/util/basic_decimal.h
-- Up-to-date: /home/tdhock/include/arrow/util/benchmark_util.h
-- Up-to-date: /home/tdhock/include/arrow/util/bit_block_counter.h
-- Up-to-date: /home/tdhock/include/arrow/util/bit_run_reader.h
-- Up-to-date: /home/tdhock/include/arrow/util/bit_stream_utils.h
-- Up-to-date: /home/tdhock/include/arrow/util/bit_util.h
-- Up-to-date: /home/tdhock/include/arrow/util/bitmap.h
-- Up-to-date: /home/tdhock/include/arrow/util/bitmap_builders.h
-- Up-to-date: /home/tdhock/include/arrow/util/bitmap_generate.h
-- Up-to-date: /home/tdhock/include/arrow/util/bitmap_ops.h
-- Up-to-date: /home/tdhock/include/arrow/util/bitmap_reader.h
-- Up-to-date: /home/tdhock/include/arrow/util/bitmap_visit.h
-- Up-to-date: /home/tdhock/include/arrow/util/bitmap_writer.h
-- Up-to-date: /home/tdhock/include/arrow/util/bitset_stack.h
-- Up-to-date: /home/tdhock/include/arrow/util/bpacking.h
-- Up-to-date: /home/tdhock/include/arrow/util/bpacking64_default.h
-- Up-to-date: /home/tdhock/include/arrow/util/bpacking_avx2.h
-- Up-to-date: /home/tdhock/include/arrow/util/bpacking_avx512.h
-- Up-to-date: /home/tdhock/include/arrow/util/bpacking_default.h
-- Up-to-date: /home/tdhock/include/arrow/util/bpacking_neon.h
-- Up-to-date: /home/tdhock/include/arrow/util/bpacking_simd128_generated.h
-- Up-to-date: /home/tdhock/include/arrow/util/bpacking_simd256_generated.h
-- Up-to-date: /home/tdhock/include/arrow/util/bpacking_simd512_generated.h
-- Up-to-date: /home/tdhock/include/arrow/util/byte_size.h
-- Up-to-date: /home/tdhock/include/arrow/util/byte_stream_split.h
-- Up-to-date: /home/tdhock/include/arrow/util/bytes_view.h
-- Up-to-date: /home/tdhock/include/arrow/util/cancel.h
-- Up-to-date: /home/tdhock/include/arrow/util/checked_cast.h
-- Up-to-date: /home/tdhock/include/arrow/util/compare.h
-- Up-to-date: /home/tdhock/include/arrow/util/compression.h
-- Up-to-date: /home/tdhock/include/arrow/util/concurrent_map.h
-- Installing: /home/tdhock/include/arrow/util/config.h
-- Up-to-date: /home/tdhock/include/arrow/util/converter.h
-- Up-to-date: /home/tdhock/include/arrow/util/counting_semaphore.h
-- Up-to-date: /home/tdhock/include/arrow/util/cpu_info.h
-- Up-to-date: /home/tdhock/include/arrow/util/crc32.h
-- Up-to-date: /home/tdhock/include/arrow/util/debug.h
-- Up-to-date: /home/tdhock/include/arrow/util/decimal.h
-- Up-to-date: /home/tdhock/include/arrow/util/delimiting.h
-- Up-to-date: /home/tdhock/include/arrow/util/dispatch.h
-- Up-to-date: /home/tdhock/include/arrow/util/double_conversion.h
-- Up-to-date: /home/tdhock/include/arrow/util/endian.h
-- Up-to-date: /home/tdhock/include/arrow/util/formatting.h
-- Up-to-date: /home/tdhock/include/arrow/util/functional.h
-- Up-to-date: /home/tdhock/include/arrow/util/future.h
-- Up-to-date: /home/tdhock/include/arrow/util/hash_util.h
-- Up-to-date: /home/tdhock/include/arrow/util/hashing.h
-- Up-to-date: /home/tdhock/include/arrow/util/int_util.h
-- Up-to-date: /home/tdhock/include/arrow/util/int_util_overflow.h
-- Up-to-date: /home/tdhock/include/arrow/util/io_util.h
-- Up-to-date: /home/tdhock/include/arrow/util/iterator.h
-- Up-to-date: /home/tdhock/include/arrow/util/key_value_metadata.h
-- Up-to-date: /home/tdhock/include/arrow/util/launder.h
-- Up-to-date: /home/tdhock/include/arrow/util/logging.h
-- Up-to-date: /home/tdhock/include/arrow/util/macros.h
-- Up-to-date: /home/tdhock/include/arrow/util/map.h
-- Up-to-date: /home/tdhock/include/arrow/util/math_constants.h
-- Up-to-date: /home/tdhock/include/arrow/util/memory.h
-- Up-to-date: /home/tdhock/include/arrow/util/mutex.h
-- Up-to-date: /home/tdhock/include/arrow/util/parallel.h
-- Up-to-date: /home/tdhock/include/arrow/util/pcg_random.h
-- Up-to-date: /home/tdhock/include/arrow/util/print.h
-- Up-to-date: /home/tdhock/include/arrow/util/queue.h
-- Up-to-date: /home/tdhock/include/arrow/util/range.h
-- Up-to-date: /home/tdhock/include/arrow/util/ree_util.h
-- Up-to-date: /home/tdhock/include/arrow/util/regex.h
-- Up-to-date: /home/tdhock/include/arrow/util/rle_encoding.h
-- Up-to-date: /home/tdhock/include/arrow/util/rows_to_batches.h
-- Up-to-date: /home/tdhock/include/arrow/util/simd.h
-- Up-to-date: /home/tdhock/include/arrow/util/small_vector.h
-- Up-to-date: /home/tdhock/include/arrow/util/sort.h
-- Up-to-date: /home/tdhock/include/arrow/util/spaced.h
-- Up-to-date: /home/tdhock/include/arrow/util/stopwatch.h
-- Up-to-date: /home/tdhock/include/arrow/util/string.h
-- Up-to-date: /home/tdhock/include/arrow/util/string_builder.h
-- Up-to-date: /home/tdhock/include/arrow/util/task_group.h
-- Up-to-date: /home/tdhock/include/arrow/util/tdigest.h
-- Up-to-date: /home/tdhock/include/arrow/util/test_common.h
-- Up-to-date: /home/tdhock/include/arrow/util/thread_pool.h
-- Up-to-date: /home/tdhock/include/arrow/util/time.h
-- Up-to-date: /home/tdhock/include/arrow/util/tracing.h
-- Up-to-date: /home/tdhock/include/arrow/util/trie.h
-- Up-to-date: /home/tdhock/include/arrow/util/type_fwd.h
-- Up-to-date: /home/tdhock/include/arrow/util/type_traits.h
-- Up-to-date: /home/tdhock/include/arrow/util/ubsan.h
-- Up-to-date: /home/tdhock/include/arrow/util/union_util.h
-- Up-to-date: /home/tdhock/include/arrow/util/unreachable.h
-- Up-to-date: /home/tdhock/include/arrow/util/uri.h
-- Up-to-date: /home/tdhock/include/arrow/util/utf8.h
-- Up-to-date: /home/tdhock/include/arrow/util/value_parsing.h
-- Up-to-date: /home/tdhock/include/arrow/util/vector.h
-- Up-to-date: /home/tdhock/include/arrow/util/visibility.h
-- Up-to-date: /home/tdhock/include/arrow/util/windows_compatibility.h
-- Up-to-date: /home/tdhock/include/arrow/util/windows_fixup.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/ProducerConsumerQueue.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/datetime.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/strptime.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/xxhash.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/datetime/date.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/datetime/ios.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/datetime/tz.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/datetime/tz_private.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/datetime/visibility.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/double-conversion/bignum-dtoa.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/double-conversion/bignum.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/double-conversion/cached-powers.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/double-conversion/diy-fp.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/double-conversion/double-conversion.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/double-conversion/fast-dtoa.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/double-conversion/fixed-dtoa.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/double-conversion/ieee.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/double-conversion/strtod.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/double-conversion/utils.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/pcg/pcg_extras.hpp
-- Up-to-date: /home/tdhock/include/arrow/vendored/pcg/pcg_random.hpp
-- Up-to-date: /home/tdhock/include/arrow/vendored/pcg/pcg_uint128.hpp
-- Up-to-date: /home/tdhock/include/arrow/vendored/portable-snippets/debug-trap.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/portable-snippets/safe-math.h
-- Up-to-date: /home/tdhock/include/arrow/vendored/xxhash/xxhash.h
-- Up-to-date: /home/tdhock/include/arrow/csv/api.h
-- Up-to-date: /home/tdhock/include/arrow/csv/chunker.h
-- Up-to-date: /home/tdhock/include/arrow/csv/column_builder.h
-- Up-to-date: /home/tdhock/include/arrow/csv/column_decoder.h
-- Up-to-date: /home/tdhock/include/arrow/csv/converter.h
-- Up-to-date: /home/tdhock/include/arrow/csv/invalid_row.h
-- Up-to-date: /home/tdhock/include/arrow/csv/options.h
-- Up-to-date: /home/tdhock/include/arrow/csv/parser.h
-- Up-to-date: /home/tdhock/include/arrow/csv/reader.h
-- Up-to-date: /home/tdhock/include/arrow/csv/test_common.h
-- Up-to-date: /home/tdhock/include/arrow/csv/type_fwd.h
-- Up-to-date: /home/tdhock/include/arrow/csv/writer.h
-- Up-to-date: /home/tdhock/lib/pkgconfig/arrow-csv.pc
-- Up-to-date: /home/tdhock/include/arrow/acero/accumulation_queue.h
-- Up-to-date: /home/tdhock/include/arrow/acero/aggregate_node.h
-- Up-to-date: /home/tdhock/include/arrow/acero/asof_join_node.h
-- Up-to-date: /home/tdhock/include/arrow/acero/benchmark_util.h
-- Up-to-date: /home/tdhock/include/arrow/acero/bloom_filter.h
-- Up-to-date: /home/tdhock/include/arrow/acero/exec_plan.h
-- Up-to-date: /home/tdhock/include/arrow/acero/groupby.h
-- Up-to-date: /home/tdhock/include/arrow/acero/hash_join.h
-- Up-to-date: /home/tdhock/include/arrow/acero/hash_join_dict.h
-- Up-to-date: /home/tdhock/include/arrow/acero/hash_join_node.h
-- Up-to-date: /home/tdhock/include/arrow/acero/map_node.h
-- Up-to-date: /home/tdhock/include/arrow/acero/options.h
-- Up-to-date: /home/tdhock/include/arrow/acero/order_by_impl.h
-- Up-to-date: /home/tdhock/include/arrow/acero/partition_util.h
-- Up-to-date: /home/tdhock/include/arrow/acero/pch.h
-- Up-to-date: /home/tdhock/include/arrow/acero/query_context.h
-- Up-to-date: /home/tdhock/include/arrow/acero/schema_util.h
-- Up-to-date: /home/tdhock/include/arrow/acero/task_util.h
-- Up-to-date: /home/tdhock/include/arrow/acero/test_nodes.h
-- Up-to-date: /home/tdhock/include/arrow/acero/tpch_node.h
-- Up-to-date: /home/tdhock/include/arrow/acero/type_fwd.h
-- Up-to-date: /home/tdhock/include/arrow/acero/util.h
-- Up-to-date: /home/tdhock/include/arrow/acero/visibility.h
-- Installing: /home/tdhock/lib/libarrow_acero.so.1300.0.0
-- Up-to-date: /home/tdhock/lib/libarrow_acero.so.1300
-- Set runtime path of "/home/tdhock/lib/libarrow_acero.so.1300.0.0" to ""
-- Up-to-date: /home/tdhock/lib/libarrow_acero.so
-- Up-to-date: /home/tdhock/lib/cmake/ArrowAcero/ArrowAceroConfig.cmake
-- Up-to-date: /home/tdhock/lib/cmake/ArrowAcero/ArrowAceroConfigVersion.cmake
-- Up-to-date: /home/tdhock/lib/cmake/ArrowAcero/ArrowAceroTargets.cmake
-- Up-to-date: /home/tdhock/lib/cmake/ArrowAcero/ArrowAceroTargets-debug.cmake
-- Up-to-date: /home/tdhock/lib/pkgconfig/arrow-acero.pc
-- Up-to-date: /home/tdhock/include/arrow/dataset/api.h
-- Up-to-date: /home/tdhock/include/arrow/dataset/dataset.h
-- Up-to-date: /home/tdhock/include/arrow/dataset/dataset_writer.h
-- Up-to-date: /home/tdhock/include/arrow/dataset/discovery.h
-- Up-to-date: /home/tdhock/include/arrow/dataset/file_base.h
-- Up-to-date: /home/tdhock/include/arrow/dataset/file_csv.h
-- Up-to-date: /home/tdhock/include/arrow/dataset/file_ipc.h
-- Up-to-date: /home/tdhock/include/arrow/dataset/file_json.h
-- Up-to-date: /home/tdhock/include/arrow/dataset/file_orc.h
-- Up-to-date: /home/tdhock/include/arrow/dataset/file_parquet.h
-- Up-to-date: /home/tdhock/include/arrow/dataset/partition.h
-- Up-to-date: /home/tdhock/include/arrow/dataset/pch.h
-- Up-to-date: /home/tdhock/include/arrow/dataset/plan.h
-- Up-to-date: /home/tdhock/include/arrow/dataset/projector.h
-- Up-to-date: /home/tdhock/include/arrow/dataset/scanner.h
-- Up-to-date: /home/tdhock/include/arrow/dataset/type_fwd.h
-- Up-to-date: /home/tdhock/include/arrow/dataset/visibility.h
-- Installing: /home/tdhock/lib/libarrow_dataset.so.1300.0.0
-- Up-to-date: /home/tdhock/lib/libarrow_dataset.so.1300
-- Set runtime path of "/home/tdhock/lib/libarrow_dataset.so.1300.0.0" to ""
-- Up-to-date: /home/tdhock/lib/libarrow_dataset.so
-- Up-to-date: /home/tdhock/lib/cmake/ArrowDataset/ArrowDatasetConfig.cmake
-- Up-to-date: /home/tdhock/lib/cmake/ArrowDataset/ArrowDatasetConfigVersion.cmake
-- Old export file "/home/tdhock/lib/cmake/ArrowDataset/ArrowDatasetTargets.cmake" will be replaced.  Removing files [/home/tdhock/lib/cmake/ArrowDataset/ArrowDatasetTargets-debug.cmake].
-- Installing: /home/tdhock/lib/cmake/ArrowDataset/ArrowDatasetTargets.cmake
-- Installing: /home/tdhock/lib/cmake/ArrowDataset/ArrowDatasetTargets-debug.cmake
-- Installing: /home/tdhock/lib/pkgconfig/arrow-dataset.pc
-- Up-to-date: /home/tdhock/include/arrow/filesystem/api.h
-- Up-to-date: /home/tdhock/include/arrow/filesystem/filesystem.h
-- Up-to-date: /home/tdhock/include/arrow/filesystem/gcsfs.h
-- Up-to-date: /home/tdhock/include/arrow/filesystem/hdfs.h
-- Up-to-date: /home/tdhock/include/arrow/filesystem/localfs.h
-- Up-to-date: /home/tdhock/include/arrow/filesystem/mockfs.h
-- Up-to-date: /home/tdhock/include/arrow/filesystem/path_util.h
-- Up-to-date: /home/tdhock/include/arrow/filesystem/s3_test_util.h
-- Up-to-date: /home/tdhock/include/arrow/filesystem/s3fs.h
-- Up-to-date: /home/tdhock/include/arrow/filesystem/test_util.h
-- Up-to-date: /home/tdhock/include/arrow/filesystem/type_fwd.h
-- Up-to-date: /home/tdhock/lib/pkgconfig/arrow-filesystem.pc
-- Up-to-date: /home/tdhock/include/arrow/ipc/api.h
-- Up-to-date: /home/tdhock/include/arrow/ipc/dictionary.h
-- Up-to-date: /home/tdhock/include/arrow/ipc/feather.h
-- Up-to-date: /home/tdhock/include/arrow/ipc/json_simple.h
-- Up-to-date: /home/tdhock/include/arrow/ipc/message.h
-- Up-to-date: /home/tdhock/include/arrow/ipc/options.h
-- Up-to-date: /home/tdhock/include/arrow/ipc/reader.h
-- Up-to-date: /home/tdhock/include/arrow/ipc/test_common.h
-- Up-to-date: /home/tdhock/include/arrow/ipc/type_fwd.h
-- Up-to-date: /home/tdhock/include/arrow/ipc/util.h
-- Up-to-date: /home/tdhock/include/arrow/ipc/writer.h
-- Up-to-date: /home/tdhock/include/arrow/json/api.h
-- Up-to-date: /home/tdhock/include/arrow/json/chunked_builder.h
-- Up-to-date: /home/tdhock/include/arrow/json/chunker.h
-- Up-to-date: /home/tdhock/include/arrow/json/converter.h
-- Up-to-date: /home/tdhock/include/arrow/json/object_parser.h
-- Up-to-date: /home/tdhock/include/arrow/json/object_writer.h
-- Up-to-date: /home/tdhock/include/arrow/json/options.h
-- Up-to-date: /home/tdhock/include/arrow/json/parser.h
-- Up-to-date: /home/tdhock/include/arrow/json/rapidjson_defs.h
-- Up-to-date: /home/tdhock/include/arrow/json/reader.h
-- Up-to-date: /home/tdhock/include/arrow/json/test_common.h
-- Up-to-date: /home/tdhock/include/arrow/json/type_fwd.h
-- Up-to-date: /home/tdhock/lib/pkgconfig/arrow-json.pc
-- Up-to-date: /home/tdhock/include/arrow/extension/fixed_shape_tensor.h
-- Installing: /home/tdhock/lib/libparquet.so.1300.0.0
-- Installing: /home/tdhock/lib/libparquet.so.1300
-- Set runtime path of "/home/tdhock/lib/libparquet.so.1300.0.0" to ""
-- Installing: /home/tdhock/lib/libparquet.so
-- Installing: /home/tdhock/lib/cmake/Parquet/ParquetConfig.cmake
-- Installing: /home/tdhock/lib/cmake/Parquet/ParquetConfigVersion.cmake
-- Installing: /home/tdhock/lib/cmake/Parquet/ParquetTargets.cmake
-- Installing: /home/tdhock/lib/cmake/Parquet/ParquetTargets-debug.cmake
-- Installing: /home/tdhock/lib/pkgconfig/parquet.pc
-- Installing: /home/tdhock/include/parquet/bloom_filter.h
-- Installing: /home/tdhock/include/parquet/bloom_filter_reader.h
-- Installing: /home/tdhock/include/parquet/column_page.h
-- Installing: /home/tdhock/include/parquet/column_reader.h
-- Installing: /home/tdhock/include/parquet/column_scanner.h
-- Installing: /home/tdhock/include/parquet/column_writer.h
-- Installing: /home/tdhock/include/parquet/encoding.h
-- Installing: /home/tdhock/include/parquet/exception.h
-- Installing: /home/tdhock/include/parquet/file_reader.h
-- Installing: /home/tdhock/include/parquet/file_writer.h
-- Installing: /home/tdhock/include/parquet/hasher.h
-- Installing: /home/tdhock/include/parquet/level_comparison.h
-- Installing: /home/tdhock/include/parquet/level_comparison_inc.h
-- Installing: /home/tdhock/include/parquet/level_conversion.h
-- Installing: /home/tdhock/include/parquet/level_conversion_inc.h
-- Installing: /home/tdhock/include/parquet/metadata.h
-- Installing: /home/tdhock/include/parquet/page_index.h
-- Installing: /home/tdhock/include/parquet/pch.h
-- Installing: /home/tdhock/include/parquet/platform.h
-- Installing: /home/tdhock/include/parquet/printer.h
-- Installing: /home/tdhock/include/parquet/properties.h
-- Installing: /home/tdhock/include/parquet/schema.h
-- Installing: /home/tdhock/include/parquet/statistics.h
-- Installing: /home/tdhock/include/parquet/stream_reader.h
-- Installing: /home/tdhock/include/parquet/stream_writer.h
-- Installing: /home/tdhock/include/parquet/test_util.h
-- Installing: /home/tdhock/include/parquet/type_fwd.h
-- Installing: /home/tdhock/include/parquet/types.h
-- Installing: /home/tdhock/include/parquet/windows_compatibility.h
-- Installing: /home/tdhock/include/parquet/windows_fixup.h
-- Installing: /home/tdhock/include/parquet/xxhasher.h
-- Installing: /home/tdhock/include/parquet/parquet_version.h
-- Installing: /home/tdhock/include/parquet/api/io.h
-- Installing: /home/tdhock/include/parquet/api/reader.h
-- Installing: /home/tdhock/include/parquet/api/schema.h
-- Installing: /home/tdhock/include/parquet/api/writer.h
-- Installing: /home/tdhock/include/parquet/arrow/reader.h
-- Installing: /home/tdhock/include/parquet/arrow/schema.h
-- Installing: /home/tdhock/include/parquet/arrow/test_util.h
-- Installing: /home/tdhock/include/parquet/arrow/writer.h
-- Installing: /home/tdhock/include/parquet/encryption/crypto_factory.h
-- Installing: /home/tdhock/include/parquet/encryption/encryption.h
-- Installing: /home/tdhock/include/parquet/encryption/file_key_material_store.h
-- Installing: /home/tdhock/include/parquet/encryption/file_key_unwrapper.h
-- Installing: /home/tdhock/include/parquet/encryption/file_key_wrapper.h
-- Installing: /home/tdhock/include/parquet/encryption/file_system_key_material_store.h
-- Installing: /home/tdhock/include/parquet/encryption/key_encryption_key.h
-- Installing: /home/tdhock/include/parquet/encryption/key_material.h
-- Installing: /home/tdhock/include/parquet/encryption/key_metadata.h
-- Installing: /home/tdhock/include/parquet/encryption/key_toolkit.h
-- Installing: /home/tdhock/include/parquet/encryption/kms_client.h
-- Installing: /home/tdhock/include/parquet/encryption/kms_client_factory.h
-- Installing: /home/tdhock/include/parquet/encryption/local_wrap_kms_client.h
-- Installing: /home/tdhock/include/parquet/encryption/test_encryption_util.h
-- Installing: /home/tdhock/include/parquet/encryption/test_in_memory_kms.h
-- Installing: /home/tdhock/include/parquet/encryption/two_level_cache_with_expiration.h
(arrow) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main)$ ARROW_DEPENDENCY_SOURCE=SYSTEM ARROW_R_DEV=true LIBARROW_BINARY=false PKG_CONFIG_PATH=$HOME/lib/pkgconfig R CMD INSTALL ../../r
Loading required package: grDevices
* installing to library ‘/home/tdhock/lib/R/library’
* installing *source* package ‘arrow’ ...
** using staged installation
*** Generating code with data-raw/codegen.R
Loading required package: grDevices
Error in library(decor) : there is no package called ‘decor’
Calls: suppressPackageStartupMessages -> withCallingHandlers -> library
Execution halted
*** Trying Arrow C++ found by pkg-config: /home/tdhock
*** > Packages are both on development versions (13.0.0-SNAPSHOT, 12.0.0.9000)
*** > If installation fails, rebuild the C++ library to match the R version
*** > or retry with FORCE_BUNDLED_BUILD=true
PKG_CFLAGS=-I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON
PKG_LIBS=-L/home/tdhock/lib -larrow_acero -larrow_dataset -lparquet -larrow
** libs
using C++ compiler: ‘g++ (GCC) 10.1.0’
using C++17
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -I/usr/local/include    -fpic  -g -O2  -c arrowExports.cpp -o arrowExports.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -I/usr/local/include    -fpic  -g -O2  -c bridge.cpp -o bridge.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -I/usr/local/include    -fpic  -g -O2  -c buffer.cpp -o buffer.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -I/usr/local/include    -fpic  -g -O2  -c chunkedarray.cpp -o chunkedarray.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -I/usr/local/include    -fpic  -g -O2  -c compression.cpp -o compression.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -I/usr/local/include    -fpic  -g -O2  -c compute-exec.cpp -o compute-exec.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -I/usr/local/include    -fpic  -g -O2  -c compute.cpp -o compute.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -I/usr/local/include    -fpic  -g -O2  -c config.cpp -o config.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -I/usr/local/include    -fpic  -g -O2  -c csv.cpp -o csv.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -I/usr/local/include    -fpic  -g -O2  -c dataset.cpp -o dataset.o
dataset.cpp: In function ‘std::shared_ptr<arrow::dataset::ParquetFileFormat> dataset___ParquetFileFormat__Make(const std::shared_ptr<arrow::dataset::ParquetFragmentScanOptions>&, cpp11::strings)’:
dataset.cpp:229:6: error: invalid use of incomplete type ‘using element_type = class arrow::dataset::ParquetFileFormat’ {aka ‘class arrow::dataset::ParquetFileFormat’}
  229 |   fmt->default_fragment_scan_options = std::move(options);
      |      ^~
In file included from ./arrow_types.h:44,
                 from dataset.cpp:18:
/home/tdhock/include/arrow/dataset/type_fwd.h:80:7: note: forward declaration of ‘using element_type = class arrow::dataset::ParquetFileFormat’ {aka ‘class arrow::dataset::ParquetFileFormat’}
   80 | class ParquetFileFormat;
      |       ^~~~~~~~~~~~~~~~~
dataset.cpp:232:16: error: invalid use of incomplete type ‘using element_type = class arrow::dataset::ParquetFileFormat’ {aka ‘class arrow::dataset::ParquetFileFormat’}
  232 |   auto& d = fmt->reader_options.dict_columns;
      |                ^~
In file included from ./arrow_types.h:44,
                 from dataset.cpp:18:
/home/tdhock/include/arrow/dataset/type_fwd.h:80:7: note: forward declaration of ‘using element_type = class arrow::dataset::ParquetFileFormat’ {aka ‘class arrow::dataset::ParquetFileFormat’}
   80 | class ParquetFileFormat;
      |       ^~~~~~~~~~~~~~~~~
dataset.cpp: In function ‘void dataset___ParquetFileWriteOptions__update(const std::shared_ptr<arrow::dataset::ParquetFileWriteOptions>&, const std::shared_ptr<parquet::WriterProperties>&, const std::shared_ptr<parquet::ArrowWriterProperties>&)’:
dataset.cpp:251:10: error: invalid use of incomplete type ‘using element_type = class arrow::dataset::ParquetFileWriteOptions’ {aka ‘class arrow::dataset::ParquetFileWriteOptions’}
  251 |   options->writer_properties = writer_props;
      |          ^~
In file included from ./arrow_types.h:44,
                 from dataset.cpp:18:
/home/tdhock/include/arrow/dataset/type_fwd.h:84:7: note: forward declaration of ‘using element_type = class arrow::dataset::ParquetFileWriteOptions’ {aka ‘class arrow::dataset::ParquetFileWriteOptions’}
   84 | class ParquetFileWriteOptions;
      |       ^~~~~~~~~~~~~~~~~~~~~~~
dataset.cpp:252:10: error: invalid use of incomplete type ‘using element_type = class arrow::dataset::ParquetFileWriteOptions’ {aka ‘class arrow::dataset::ParquetFileWriteOptions’}
  252 |   options->arrow_writer_properties = arrow_writer_props;
      |          ^~
In file included from ./arrow_types.h:44,
                 from dataset.cpp:18:
/home/tdhock/include/arrow/dataset/type_fwd.h:84:7: note: forward declaration of ‘using element_type = class arrow::dataset::ParquetFileWriteOptions’ {aka ‘class arrow::dataset::ParquetFileWriteOptions’}
   84 | class ParquetFileWriteOptions;
      |       ^~~~~~~~~~~~~~~~~~~~~~~
dataset.cpp: In function ‘void dataset___CsvFileWriteOptions__update(const std::shared_ptr<arrow::dataset::CsvFileWriteOptions>&, const std::shared_ptr<arrow::csv::WriteOptions>&)’:
dataset.cpp:278:15: error: invalid use of incomplete type ‘using element_type = class arrow::dataset::CsvFileWriteOptions’ {aka ‘class arrow::dataset::CsvFileWriteOptions’}
  278 |   *csv_options->write_options = *write_options;
      |               ^~
In file included from ./arrow_types.h:44,
                 from dataset.cpp:18:
/home/tdhock/include/arrow/dataset/type_fwd.h:72:7: note: forward declaration of ‘using element_type = class arrow::dataset::CsvFileWriteOptions’ {aka ‘class arrow::dataset::CsvFileWriteOptions’}
   72 | class CsvFileWriteOptions;
      |       ^~~~~~~~~~~~~~~~~~~
dataset.cpp: In function ‘std::shared_ptr<arrow::dataset::CsvFileFormat> dataset___CsvFileFormat__Make(const std::shared_ptr<arrow::csv::ParseOptions>&, const std::shared_ptr<arrow::csv::ConvertOptions>&, const std::shared_ptr<arrow::csv::ReadOptions>&)’:
dataset.cpp:292:9: error: invalid use of incomplete type ‘using element_type = class arrow::dataset::CsvFileFormat’ {aka ‘class arrow::dataset::CsvFileFormat’}
  292 |   format->parse_options = *parse_options;
      |         ^~
In file included from ./arrow_types.h:44,
                 from dataset.cpp:18:
/home/tdhock/include/arrow/dataset/type_fwd.h:70:7: note: forward declaration of ‘using element_type = class arrow::dataset::CsvFileFormat’ {aka ‘class arrow::dataset::CsvFileFormat’}
   70 | class CsvFileFormat;
      |       ^~~~~~~~~~~~~
dataset.cpp:294:36: error: invalid use of incomplete type ‘using element_type = struct arrow::dataset::CsvFragmentScanOptions’ {aka ‘struct arrow::dataset::CsvFragmentScanOptions’}
  294 |   if (convert_options) scan_options->convert_options = *convert_options;
      |                                    ^~
In file included from ./arrow_types.h:44,
                 from dataset.cpp:18:
/home/tdhock/include/arrow/dataset/type_fwd.h:73:8: note: forward declaration of ‘using element_type = struct arrow::dataset::CsvFragmentScanOptions’ {aka ‘struct arrow::dataset::CsvFragmentScanOptions’}
   73 | struct CsvFragmentScanOptions;
      |        ^~~~~~~~~~~~~~~~~~~~~~
dataset.cpp:295:33: error: invalid use of incomplete type ‘using element_type = struct arrow::dataset::CsvFragmentScanOptions’ {aka ‘struct arrow::dataset::CsvFragmentScanOptions’}
  295 |   if (read_options) scan_options->read_options = *read_options;
      |                                 ^~
In file included from ./arrow_types.h:44,
                 from dataset.cpp:18:
/home/tdhock/include/arrow/dataset/type_fwd.h:73:8: note: forward declaration of ‘using element_type = struct arrow::dataset::CsvFragmentScanOptions’ {aka ‘struct arrow::dataset::CsvFragmentScanOptions’}
   73 | struct CsvFragmentScanOptions;
      |        ^~~~~~~~~~~~~~~~~~~~~~
dataset.cpp:296:9: error: invalid use of incomplete type ‘using element_type = class arrow::dataset::CsvFileFormat’ {aka ‘class arrow::dataset::CsvFileFormat’}
  296 |   format->default_fragment_scan_options = std::move(scan_options);
      |         ^~
In file included from ./arrow_types.h:44,
                 from dataset.cpp:18:
/home/tdhock/include/arrow/dataset/type_fwd.h:70:7: note: forward declaration of ‘using element_type = class arrow::dataset::CsvFileFormat’ {aka ‘class arrow::dataset::CsvFileFormat’}
   70 | class CsvFileFormat;
      |       ^~~~~~~~~~~~~
dataset.cpp: In function ‘std::shared_ptr<arrow::dataset::CsvFragmentScanOptions> dataset___CsvFragmentScanOptions__Make(const std::shared_ptr<arrow::csv::ConvertOptions>&, const std::shared_ptr<arrow::csv::ReadOptions>&)’:
dataset.cpp:313:10: error: invalid use of incomplete type ‘using element_type = struct arrow::dataset::CsvFragmentScanOptions’ {aka ‘struct arrow::dataset::CsvFragmentScanOptions’}
  313 |   options->convert_options = *convert_options;
      |          ^~
In file included from ./arrow_types.h:44,
                 from dataset.cpp:18:
/home/tdhock/include/arrow/dataset/type_fwd.h:73:8: note: forward declaration of ‘using element_type = struct arrow::dataset::CsvFragmentScanOptions’ {aka ‘struct arrow::dataset::CsvFragmentScanOptions’}
   73 | struct CsvFragmentScanOptions;
      |        ^~~~~~~~~~~~~~~~~~~~~~
dataset.cpp:314:10: error: invalid use of incomplete type ‘using element_type = struct arrow::dataset::CsvFragmentScanOptions’ {aka ‘struct arrow::dataset::CsvFragmentScanOptions’}
  314 |   options->read_options = *read_options;
      |          ^~
In file included from ./arrow_types.h:44,
                 from dataset.cpp:18:
/home/tdhock/include/arrow/dataset/type_fwd.h:73:8: note: forward declaration of ‘using element_type = struct arrow::dataset::CsvFragmentScanOptions’ {aka ‘struct arrow::dataset::CsvFragmentScanOptions’}
   73 | struct CsvFragmentScanOptions;
      |        ^~~~~~~~~~~~~~~~~~~~~~
dataset.cpp: In function ‘std::shared_ptr<arrow::dataset::ParquetFragmentScanOptions> dataset___ParquetFragmentScanOptions__Make(bool, int64_t, bool)’:
dataset.cpp:324:12: error: invalid use of incomplete type ‘using element_type = class arrow::dataset::ParquetFragmentScanOptions’ {aka ‘class arrow::dataset::ParquetFragmentScanOptions’}
  324 |     options->reader_properties->enable_buffered_stream();
      |            ^~
In file included from ./arrow_types.h:44,
                 from dataset.cpp:18:
/home/tdhock/include/arrow/dataset/type_fwd.h:82:7: note: forward declaration of ‘using element_type = class arrow::dataset::ParquetFragmentScanOptions’ {aka ‘class arrow::dataset::ParquetFragmentScanOptions’}
   82 | class ParquetFragmentScanOptions;
      |       ^~~~~~~~~~~~~~~~~~~~~~~~~~
dataset.cpp:326:12: error: invalid use of incomplete type ‘using element_type = class arrow::dataset::ParquetFragmentScanOptions’ {aka ‘class arrow::dataset::ParquetFragmentScanOptions’}
  326 |     options->reader_properties->disable_buffered_stream();
      |            ^~
In file included from ./arrow_types.h:44,
                 from dataset.cpp:18:
/home/tdhock/include/arrow/dataset/type_fwd.h:82:7: note: forward declaration of ‘using element_type = class arrow::dataset::ParquetFragmentScanOptions’ {aka ‘class arrow::dataset::ParquetFragmentScanOptions’}
   82 | class ParquetFragmentScanOptions;
      |       ^~~~~~~~~~~~~~~~~~~~~~~~~~
dataset.cpp:328:10: error: invalid use of incomplete type ‘using element_type = class arrow::dataset::ParquetFragmentScanOptions’ {aka ‘class arrow::dataset::ParquetFragmentScanOptions’}
  328 |   options->reader_properties->set_buffer_size(buffer_size);
      |          ^~
In file included from ./arrow_types.h:44,
                 from dataset.cpp:18:
/home/tdhock/include/arrow/dataset/type_fwd.h:82:7: note: forward declaration of ‘using element_type = class arrow::dataset::ParquetFragmentScanOptions’ {aka ‘class arrow::dataset::ParquetFragmentScanOptions’}
   82 | class ParquetFragmentScanOptions;
      |       ^~~~~~~~~~~~~~~~~~~~~~~~~~
dataset.cpp:329:10: error: invalid use of incomplete type ‘using element_type = class arrow::dataset::ParquetFragmentScanOptions’ {aka ‘class arrow::dataset::ParquetFragmentScanOptions’}
  329 |   options->arrow_reader_properties->set_pre_buffer(pre_buffer);
      |          ^~
In file included from ./arrow_types.h:44,
                 from dataset.cpp:18:
/home/tdhock/include/arrow/dataset/type_fwd.h:82:7: note: forward declaration of ‘using element_type = class arrow::dataset::ParquetFragmentScanOptions’ {aka ‘class arrow::dataset::ParquetFragmentScanOptions’}
   82 | class ParquetFragmentScanOptions;
      |       ^~~~~~~~~~~~~~~~~~~~~~~~~~
dataset.cpp:331:12: error: invalid use of incomplete type ‘using element_type = class arrow::dataset::ParquetFragmentScanOptions’ {aka ‘class arrow::dataset::ParquetFragmentScanOptions’}
  331 |     options->arrow_reader_properties->set_cache_options(
      |            ^~
In file included from ./arrow_types.h:44,
                 from dataset.cpp:18:
/home/tdhock/include/arrow/dataset/type_fwd.h:82:7: note: forward declaration of ‘using element_type = class arrow::dataset::ParquetFragmentScanOptions’ {aka ‘class arrow::dataset::ParquetFragmentScanOptions’}
   82 | class ParquetFragmentScanOptions;
      |       ^~~~~~~~~~~~~~~~~~~~~~~~~~
In file included from /home/tdhock/include/c++/10.1.0/bits/shared_ptr_base.h:56,
                 from /home/tdhock/include/c++/10.1.0/bits/shared_ptr.h:52,
                 from /home/tdhock/include/c++/10.1.0/memory:84,
                 from ././arrow_cpp11.h:20,
                 from ./arrow_types.h:22,
                 from dataset.cpp:18:
/home/tdhock/include/c++/10.1.0/ext/aligned_buffer.h: In instantiation of ‘struct __gnu_cxx::__aligned_buffer<arrow::dataset::ParquetFileFormat>’:
/home/tdhock/include/c++/10.1.0/bits/shared_ptr_base.h:538:35:   required from ‘class std::_Sp_counted_ptr_inplace<arrow::dataset::ParquetFileFormat, std::allocator<arrow::dataset::ParquetFileFormat>, __gnu_cxx::_S_atomic>::_Impl’
/home/tdhock/include/c++/10.1.0/bits/shared_ptr_base.h:599:13:   required from ‘class std::_Sp_counted_ptr_inplace<arrow::dataset::ParquetFileFormat, std::allocator<arrow::dataset::ParquetFileFormat>, __gnu_cxx::_S_atomic>’
/home/tdhock/include/c++/10.1.0/bits/shared_ptr_base.h:679:43:   required from ‘std::__shared_count<_Lp>::__shared_count(_Tp*&, std::_Sp_alloc_shared_tag<_Alloc>, _Args&& ...) [with _Tp = arrow::dataset::ParquetFileFormat; _Alloc = std::allocator<arrow::dataset::ParquetFileFormat>; _Args = {}; __gnu_cxx::_Lock_policy _Lp = __gnu_cxx::_S_atomic]’
/home/tdhock/include/c++/10.1.0/bits/shared_ptr_base.h:1371:71:   required from ‘std::__shared_ptr<_Tp, _Lp>::__shared_ptr(std::_Sp_alloc_shared_tag<_Tp>, _Args&& ...) [with _Alloc = std::allocator<arrow::dataset::ParquetFileFormat>; _Args = {}; _Tp = arrow::dataset::ParquetFileFormat; __gnu_cxx::_Lock_policy _Lp = __gnu_cxx::_S_atomic]’
/home/tdhock/include/c++/10.1.0/bits/shared_ptr.h:408:59:   required from ‘std::shared_ptr<_Tp>::shared_ptr(std::_Sp_alloc_shared_tag<_Tp>, _Args&& ...) [with _Alloc = std::allocator<arrow::dataset::ParquetFileFormat>; _Args = {}; _Tp = arrow::dataset::ParquetFileFormat]’
/home/tdhock/include/c++/10.1.0/bits/shared_ptr.h:859:14:   required from ‘std::shared_ptr<_Tp> std::allocate_shared(const _Alloc&, _Args&& ...) [with _Tp = arrow::dataset::ParquetFileFormat; _Alloc = std::allocator<arrow::dataset::ParquetFileFormat>; _Args = {}]’
/home/tdhock/include/c++/10.1.0/bits/shared_ptr.h:875:39:   required from ‘std::shared_ptr<_Tp> std::make_shared(_Args&& ...) [with _Tp = arrow::dataset::ParquetFileFormat; _Args = {}]’
dataset.cpp:228:54:   required from here
/home/tdhock/include/c++/10.1.0/ext/aligned_buffer.h:91:28: error: invalid application of ‘sizeof’ to incomplete type ‘arrow::dataset::ParquetFileFormat’
   91 |     : std::aligned_storage<sizeof(_Tp), __alignof__(_Tp)>
      |                            ^~~~~~~~~~~
/home/tdhock/include/c++/10.1.0/ext/aligned_buffer.h:91:28: error: invalid application of ‘sizeof’ to incomplete type ‘arrow::dataset::ParquetFileFormat’
/home/tdhock/include/c++/10.1.0/ext/aligned_buffer.h: In instantiation of ‘struct __gnu_cxx::__aligned_buffer<arrow::dataset::CsvFileFormat>’:
/home/tdhock/include/c++/10.1.0/bits/shared_ptr_base.h:538:35:   required from ‘class std::_Sp_counted_ptr_inplace<arrow::dataset::CsvFileFormat, std::allocator<arrow::dataset::CsvFileFormat>, __gnu_cxx::_S_atomic>::_Impl’
/home/tdhock/include/c++/10.1.0/bits/shared_ptr_base.h:599:13:   required from ‘class std::_Sp_counted_ptr_inplace<arrow::dataset::CsvFileFormat, std::allocator<arrow::dataset::CsvFileFormat>, __gnu_cxx::_S_atomic>’
/home/tdhock/include/c++/10.1.0/bits/shared_ptr_base.h:679:43:   required from ‘std::__shared_count<_Lp>::__shared_count(_Tp*&, std::_Sp_alloc_shared_tag<_Alloc>, _Args&& ...) [with _Tp = arrow::dataset::CsvFileFormat; _Alloc = std::allocator<arrow::dataset::CsvFileFormat>; _Args = {}; __gnu_cxx::_Lock_policy _Lp = __gnu_cxx::_S_atomic]’
/home/tdhock/include/c++/10.1.0/bits/shared_ptr_base.h:1371:71:   required from ‘std::__shared_ptr<_Tp, _Lp>::__shared_ptr(std::_Sp_alloc_shared_tag<_Tp>, _Args&& ...) [with _Alloc = std::allocator<arrow::dataset::CsvFileFormat>; _Args = {}; _Tp = arrow::dataset::CsvFileFormat; __gnu_cxx::_Lock_policy _Lp = __gnu_cxx::_S_atomic]’
/home/tdhock/include/c++/10.1.0/bits/shared_ptr.h:408:59:   required from ‘std::shared_ptr<_Tp>::shared_ptr(std::_Sp_alloc_shared_tag<_Tp>, _Args&& ...) [with _Alloc = std::allocator<arrow::dataset::CsvFileFormat>; _Args = {}; _Tp = arrow::dataset::CsvFileFormat]’
/home/tdhock/include/c++/10.1.0/bits/shared_ptr.h:859:14:   required from ‘std::shared_ptr<_Tp> std::allocate_shared(const _Alloc&, _Args&& ...) [with _Tp = arrow::dataset::CsvFileFormat; _Alloc = std::allocator<arrow::dataset::CsvFileFormat>; _Args = {}]’
/home/tdhock/include/c++/10.1.0/bits/shared_ptr.h:875:39:   required from ‘std::shared_ptr<_Tp> std::make_shared(_Args&& ...) [with _Tp = arrow::dataset::CsvFileFormat; _Args = {}]’
dataset.cpp:291:53:   required from here
/home/tdhock/include/c++/10.1.0/ext/aligned_buffer.h:91:28: error: invalid application of ‘sizeof’ to incomplete type ‘arrow::dataset::CsvFileFormat’
/home/tdhock/include/c++/10.1.0/ext/aligned_buffer.h:91:28: error: invalid application of ‘sizeof’ to incomplete type ‘arrow::dataset::CsvFileFormat’
/home/tdhock/include/c++/10.1.0/ext/aligned_buffer.h: In instantiation of ‘struct __gnu_cxx::__aligned_buffer<arrow::dataset::CsvFragmentScanOptions>’:
/home/tdhock/include/c++/10.1.0/bits/shared_ptr_base.h:538:35:   required from ‘class std::_Sp_counted_ptr_inplace<arrow::dataset::CsvFragmentScanOptions, std::allocator<arrow::dataset::CsvFragmentScanOptions>, __gnu_cxx::_S_atomic>::_Impl’
/home/tdhock/include/c++/10.1.0/bits/shared_ptr_base.h:599:13:   required from ‘class std::_Sp_counted_ptr_inplace<arrow::dataset::CsvFragmentScanOptions, std::allocator<arrow::dataset::CsvFragmentScanOptions>, __gnu_cxx::_S_atomic>’
/home/tdhock/include/c++/10.1.0/bits/shared_ptr_base.h:679:43:   required from ‘std::__shared_count<_Lp>::__shared_count(_Tp*&, std::_Sp_alloc_shared_tag<_Alloc>, _Args&& ...) [with _Tp = arrow::dataset::CsvFragmentScanOptions; _Alloc = std::allocator<arrow::dataset::CsvFragmentScanOptions>; _Args = {}; __gnu_cxx::_Lock_policy _Lp = __gnu_cxx::_S_atomic]’
/home/tdhock/include/c++/10.1.0/bits/shared_ptr_base.h:1371:71:   required from ‘std::__shared_ptr<_Tp, _Lp>::__shared_ptr(std::_Sp_alloc_shared_tag<_Tp>, _Args&& ...) [with _Alloc = std::allocator<arrow::dataset::CsvFragmentScanOptions>; _Args = {}; _Tp = arrow::dataset::CsvFragmentScanOptions; __gnu_cxx::_Lock_policy _Lp = __gnu_cxx::_S_atomic]’
/home/tdhock/include/c++/10.1.0/bits/shared_ptr.h:408:59:   required from ‘std::shared_ptr<_Tp>::shared_ptr(std::_Sp_alloc_shared_tag<_Tp>, _Args&& ...) [with _Alloc = std::allocator<arrow::dataset::CsvFragmentScanOptions>; _Args = {}; _Tp = arrow::dataset::CsvFragmentScanOptions]’
/home/tdhock/include/c++/10.1.0/bits/shared_ptr.h:859:14:   required from ‘std::shared_ptr<_Tp> std::allocate_shared(const _Alloc&, _Args&& ...) [with _Tp = arrow::dataset::CsvFragmentScanOptions; _Alloc = std::allocator<arrow::dataset::CsvFragmentScanOptions>; _Args = {}]’
/home/tdhock/include/c++/10.1.0/bits/shared_ptr.h:875:39:   required from ‘std::shared_ptr<_Tp> std::make_shared(_Args&& ...) [with _Tp = arrow::dataset::CsvFragmentScanOptions; _Args = {}]’
dataset.cpp:293:68:   required from here
/home/tdhock/include/c++/10.1.0/ext/aligned_buffer.h:91:28: error: invalid application of ‘sizeof’ to incomplete type ‘arrow::dataset::CsvFragmentScanOptions’
/home/tdhock/include/c++/10.1.0/ext/aligned_buffer.h:91:28: error: invalid application of ‘sizeof’ to incomplete type ‘arrow::dataset::CsvFragmentScanOptions’
/home/tdhock/include/c++/10.1.0/ext/aligned_buffer.h: In instantiation of ‘struct __gnu_cxx::__aligned_buffer<arrow::dataset::ParquetFragmentScanOptions>’:
/home/tdhock/include/c++/10.1.0/bits/shared_ptr_base.h:538:35:   required from ‘class std::_Sp_counted_ptr_inplace<arrow::dataset::ParquetFragmentScanOptions, std::allocator<arrow::dataset::ParquetFragmentScanOptions>, __gnu_cxx::_S_atomic>::_Impl’
/home/tdhock/include/c++/10.1.0/bits/shared_ptr_base.h:599:13:   required from ‘class std::_Sp_counted_ptr_inplace<arrow::dataset::ParquetFragmentScanOptions, std::allocator<arrow::dataset::ParquetFragmentScanOptions>, __gnu_cxx::_S_atomic>’
/home/tdhock/include/c++/10.1.0/bits/shared_ptr_base.h:679:43:   required from ‘std::__shared_count<_Lp>::__shared_count(_Tp*&, std::_Sp_alloc_shared_tag<_Alloc>, _Args&& ...) [with _Tp = arrow::dataset::ParquetFragmentScanOptions; _Alloc = std::allocator<arrow::dataset::ParquetFragmentScanOptions>; _Args = {}; __gnu_cxx::_Lock_policy _Lp = __gnu_cxx::_S_atomic]’
/home/tdhock/include/c++/10.1.0/bits/shared_ptr_base.h:1371:71:   required from ‘std::__shared_ptr<_Tp, _Lp>::__shared_ptr(std::_Sp_alloc_shared_tag<_Tp>, _Args&& ...) [with _Alloc = std::allocator<arrow::dataset::ParquetFragmentScanOptions>; _Args = {}; _Tp = arrow::dataset::ParquetFragmentScanOptions; __gnu_cxx::_Lock_policy _Lp = __gnu_cxx::_S_atomic]’
/home/tdhock/include/c++/10.1.0/bits/shared_ptr.h:408:59:   required from ‘std::shared_ptr<_Tp>::shared_ptr(std::_Sp_alloc_shared_tag<_Tp>, _Args&& ...) [with _Alloc = std::allocator<arrow::dataset::ParquetFragmentScanOptions>; _Args = {}; _Tp = arrow::dataset::ParquetFragmentScanOptions]’
/home/tdhock/include/c++/10.1.0/bits/shared_ptr.h:859:14:   required from ‘std::shared_ptr<_Tp> std::allocate_shared(const _Alloc&, _Args&& ...) [with _Tp = arrow::dataset::ParquetFragmentScanOptions; _Alloc = std::allocator<arrow::dataset::ParquetFragmentScanOptions>; _Args = {}]’
/home/tdhock/include/c++/10.1.0/bits/shared_ptr.h:875:39:   required from ‘std::shared_ptr<_Tp> std::make_shared(_Args&& ...) [with _Tp = arrow::dataset::ParquetFragmentScanOptions; _Args = {}]’
dataset.cpp:322:67:   required from here
/home/tdhock/include/c++/10.1.0/ext/aligned_buffer.h:91:28: error: invalid application of ‘sizeof’ to incomplete type ‘arrow::dataset::ParquetFragmentScanOptions’
/home/tdhock/include/c++/10.1.0/ext/aligned_buffer.h:91:28: error: invalid application of ‘sizeof’ to incomplete type ‘arrow::dataset::ParquetFragmentScanOptions’
/home/tdhock/lib/R/etc/Makeconf:198: recipe for target 'dataset.o' failed
make: *** [dataset.o] Error 1
ERROR: compilation failed for package ‘arrow’
* removing ‘/home/tdhock/lib/R/library/arrow’
* restoring previous ‘/home/tdhock/lib/R/library/arrow’
```

Above shows that progress has been made but there is still some
parquet functionality missing. Or is it? github search says that
ParquetFragmentScanOptions is defined in
arrow/dataset/file_parquet.cc, and that is included from
arrow/dataset/api.h if `ARROW_PARQUET` env var is defined, so the
command line below works, is this a bug with the arrow build system?

```
(arrow) tdhock@maude-MacBookPro:~/arrow-git/r/src(main)$ g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_PARQUET -DARROW_CSV -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -I/usr/local/include    -fpic  -g -O2  -c dataset.cpp -o dataset.o
```

At least I can work-around by putting the following in `~/.R/Makevars`:

```
CPPFLAGS=-DARROW_PARQUET -DARROW_CSV
```

Then to get the linking to work properly I had to add some flags:

```
(arrow) tdhock@maude-MacBookPro:~/arrow-git/r/src(main)$ g++ -std=gnu++17 -shared -L/home/tdhock/lib/R/lib -L/usr/local/lib -o arrow.so RTasks.o altrep.o array.o array_to_vector.o arraydata.o arrowExports.o bridge.o buffer.o chunkedarray.o compression.o compute-exec.o compute.o config.o csv.o dataset.o datatype.o expression.o extension-impl.o feather.o field.o filesystem.o io.o json.o memorypool.o message.o parquet.o r_to_arrow.o recordbatch.o recordbatchreader.o recordbatchwriter.o safe-call-into-r-impl.o scalar.o schema.o symbols.o table.o threadpool.o type_infer.o -L/home/tdhock/lib -Wl,-rpath=$HOME/lib -L$CONDA_PREFIX/lib -Wl,-rpath=$CONDA_PREFIX/lib -larrow_acero -larrow_dataset -lparquet -larrow -L/home/tdhock/lib/R/lib -lR -lthrift && ldd arrow.so |grep not 
/usr/bin/ld: warning: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libstdc++.so: unsupported GNU_PROPERTY_TYPE (5) type: 0xc0010001
/usr/bin/ld: warning: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libstdc++.so: unsupported GNU_PROPERTY_TYPE (5) type: 0xc0010002
/usr/bin/ld: warning: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libgcc_s.so.1: unsupported GNU_PROPERTY_TYPE (5) type: 0xc0010001
/usr/bin/ld: warning: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libgcc_s.so.1: unsupported GNU_PROPERTY_TYPE (5) type: 0xc0010002
/usr/bin/ld: warning: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libgcc_s.so.1: unsupported GNU_PROPERTY_TYPE (5) type: 0xc0010001
/usr/bin/ld: warning: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libgcc_s.so.1: unsupported GNU_PROPERTY_TYPE (5) type: 0xc0010002
```

This builds, links, and running still gives segfault:

```
(arrow) tdhock@maude-MacBookPro:~/arrow-git/r/src(main)$ ARROW_PARQUET=true ARROW_R_WITH_PARQUET=true ARROW_DEPENDENCY_SOURCE=SYSTEM ARROW_R_DEV=true LIBARROW_BINARY=false PKG_CONFIG_PATH=$HOME/lib/pkgconfig:$CONDA_PREFIX/lib/pkgconfig R CMD INSTALL ..
Loading required package: grDevices
* installing to library ‘/home/tdhock/lib/R/library’
* installing *source* package ‘arrow’ ...
** using staged installation
*** Generating code with data-raw/codegen.R
Loading required package: grDevices
Error in library(decor) : there is no package called ‘decor’
Calls: suppressPackageStartupMessages -> withCallingHandlers -> library
Execution halted
*** Trying Arrow C++ found by pkg-config: /home/tdhock
*** > Packages are both on development versions (13.0.0-SNAPSHOT, 12.0.0.9000)
*** > If installation fails, rebuild the C++ library to match the R version
*** > or retry with FORCE_BUNDLED_BUILD=true
PKG_CFLAGS=-I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON
PKG_LIBS=-L/home/tdhock/lib -larrow_acero -larrow_dataset -lparquet -larrow
** libs
using C++ compiler: ‘g++ (GCC) 10.1.0’
using C++17
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c RTasks.cpp -o RTasks.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c altrep.cpp -o altrep.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c array.cpp -o array.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c array_to_vector.cpp -o array_to_vector.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c arraydata.cpp -o arraydata.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c arrowExports.cpp -o arrowExports.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c bridge.cpp -o bridge.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c buffer.cpp -o buffer.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c chunkedarray.cpp -o chunkedarray.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c compression.cpp -o compression.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c compute-exec.cpp -o compute-exec.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c compute.cpp -o compute.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c config.cpp -o config.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c csv.cpp -o csv.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c dataset.cpp -o dataset.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c datatype.cpp -o datatype.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c expression.cpp -o expression.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c extension-impl.cpp -o extension-impl.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c feather.cpp -o feather.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c field.cpp -o field.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c filesystem.cpp -o filesystem.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c io.cpp -o io.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c json.cpp -o json.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c memorypool.cpp -o memorypool.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c message.cpp -o message.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c parquet.cpp -o parquet.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c r_to_arrow.cpp -o r_to_arrow.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c recordbatch.cpp -o recordbatch.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c recordbatchreader.cpp -o recordbatchreader.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c recordbatchwriter.cpp -o recordbatchwriter.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c safe-call-into-r-impl.cpp -o safe-call-into-r-impl.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c scalar.cpp -o scalar.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c schema.cpp -o schema.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c symbols.cpp -o symbols.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c table.cpp -o table.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c threadpool.cpp -o threadpool.o
g++ -std=gnu++17 -I"/home/tdhock/lib/R/include" -DNDEBUG -I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON -I'/home/tdhock/lib/R/library/cpp11/include' -DARROW_PARQUET -DARROW_CSV    -fpic  -g -O2  -c type_infer.cpp -o type_infer.o
g++ -std=gnu++17 -shared -L/home/tdhock/lib/R/lib -L/usr/local/lib -o arrow.so RTasks.o altrep.o array.o array_to_vector.o arraydata.o arrowExports.o bridge.o buffer.o chunkedarray.o compression.o compute-exec.o compute.o config.o csv.o dataset.o datatype.o expression.o extension-impl.o feather.o field.o filesystem.o io.o json.o memorypool.o message.o parquet.o r_to_arrow.o recordbatch.o recordbatchreader.o recordbatchwriter.o safe-call-into-r-impl.o scalar.o schema.o symbols.o table.o threadpool.o type_infer.o -L/home/tdhock/lib -larrow_acero -larrow_dataset -lparquet -larrow -L/home/tdhock/lib/R/lib -lR
installing to /home/tdhock/lib/R/library/00LOCK-r/00new/arrow/libs
** R
** inst
** byte-compile and prepare package for lazy loading
Loading required package: grDevices
** help
*** installing help indices
** building package indices
Loading required package: grDevices
** installing vignettes
** testing if installed package can be loaded from temporary location
Loading required package: grDevices
Error: package or namespace load failed for ‘arrow’ in dyn.load(file, DLLpath = DLLpath, ...):
 unable to load shared object '/home/tdhock/lib/R/library/00LOCK-r/00new/arrow/libs/arrow.so':
  libarrow_acero.so.1300: cannot open shared object file: No such file or directory
Error: loading failed
Execution halted
ERROR: loading failed
* removing ‘/home/tdhock/lib/R/library/arrow’
* restoring previous ‘/home/tdhock/lib/R/library/arrow’
(arrow) tdhock@maude-MacBookPro:~/arrow-git/r/src(main)$ g++ -std=gnu++17 -shared -L/home/tdhock/lib/R/lib -L/usr/local/lib -o arrow.so RTasks.o altrep.o array.o array_to_vector.o arraydata.o arrowExports.o bridge.o buffer.o chunkedarray.o compression.o compute-exec.o compute.o config.o csv.o dataset.o datatype.o expression.o extension-impl.o feather.o field.o filesystem.o io.o json.o memorypool.o message.o parquet.o r_to_arrow.o recordbatch.o recordbatchreader.o recordbatchwriter.o safe-call-into-r-impl.o scalar.o schema.o symbols.o table.o threadpool.o type_infer.o -L/home/tdhock/lib -Wl,-rpath=$HOME/lib -L$CONDA_PREFIX/lib -Wl,-rpath=$CONDA_PREFIX/lib -larrow_acero -larrow_dataset -lparquet -larrow -L/home/tdhock/lib/R/lib -lR -lthrift && ldd arrow.so |grep not 
/usr/bin/ld: warning: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libstdc++.so: unsupported GNU_PROPERTY_TYPE (5) type: 0xc0010001
/usr/bin/ld: warning: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libstdc++.so: unsupported GNU_PROPERTY_TYPE (5) type: 0xc0010002
/usr/bin/ld: warning: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libgcc_s.so.1: unsupported GNU_PROPERTY_TYPE (5) type: 0xc0010001
/usr/bin/ld: warning: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libgcc_s.so.1: unsupported GNU_PROPERTY_TYPE (5) type: 0xc0010002
/usr/bin/ld: warning: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libgcc_s.so.1: unsupported GNU_PROPERTY_TYPE (5) type: 0xc0010001
/usr/bin/ld: warning: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libgcc_s.so.1: unsupported GNU_PROPERTY_TYPE (5) type: 0xc0010002
(arrow) tdhock@maude-MacBookPro:~/arrow-git/r/src(main)$ ARROW_PARQUET=true ARROW_R_WITH_PARQUET=true ARROW_DEPENDENCY_SOURCE=SYSTEM ARROW_R_DEV=true LIBARROW_BINARY=false PKG_CONFIG_PATH=$HOME/lib/pkgconfig:$CONDA_PREFIX/lib/pkgconfig R CMD INSTALL ..
Loading required package: grDevices
* installing to library ‘/home/tdhock/lib/R/library’
* installing *source* package ‘arrow’ ...
** using staged installation
*** Generating code with data-raw/codegen.R
Loading required package: grDevices
Error in library(decor) : there is no package called ‘decor’
Calls: suppressPackageStartupMessages -> withCallingHandlers -> library
Execution halted
*** Trying Arrow C++ found by pkg-config: /home/tdhock
*** > Packages are both on development versions (13.0.0-SNAPSHOT, 12.0.0.9000)
*** > If installation fails, rebuild the C++ library to match the R version
*** > or retry with FORCE_BUNDLED_BUILD=true
PKG_CFLAGS=-I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON
PKG_LIBS=-L/home/tdhock/lib -larrow_acero -larrow_dataset -lparquet -larrow
** libs
using C++ compiler: ‘g++ (GCC) 10.1.0’
using C++17
make: Nothing to be done for 'all'.
installing to /home/tdhock/lib/R/library/00LOCK-r/00new/arrow/libs
** R
** inst
** byte-compile and prepare package for lazy loading
Loading required package: grDevices
** help
*** installing help indices
** building package indices
Loading required package: grDevices
** installing vignettes
** testing if installed package can be loaded from temporary location
Loading required package: grDevices
** checking absolute paths in shared objects and dynamic libraries
** testing if installed package can be loaded from final location
Loading required package: grDevices
** testing if installed package keeps a record of temporary installation path
* DONE (arrow)
(arrow) tdhock@maude-MacBookPro:~/arrow-git/r/src(main)$ R -d gdb
GNU gdb (Ubuntu 10.2-0ubuntu1~18.04~2) 10.2
Copyright (C) 2021 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
Type "show copying" and "show warranty" for details.
This GDB was configured as "x86_64-linux-gnu".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<https://www.gnu.org/software/gdb/bugs/>.
Find the GDB manual and other documentation resources online at:
    <http://www.gnu.org/software/gdb/documentation/>.

For help, type "help".
Type "apropos word" to search for commands related to "word"...
Reading symbols from /home/tdhock/lib/R/bin/exec/R...
(gdb) run
Starting program: /home/tdhock/lib/R/bin/exec/R 
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/lib/x86_64-linux-gnu/libthread_db.so.1".

R version 4.3.0 (2023-04-21) -- "Already Tomorrow"
Copyright (C) 2023 The R Foundation for Statistical Computing
Platform: x86_64-pc-linux-gnu (64-bit)

R is free software and comes with ABSOLUTELY NO WARRANTY.
You are welcome to redistribute it under certain conditions.
Type 'license()' or 'licence()' for distribution details.

  Natural language support but running in an English locale

R is a collaborative project with many contributors.
Type 'contributors()' for more information and
'citation()' on how to cite R or R packages in publications.

Type 'demo()' for some demos, 'help()' for on-line help, or
'help.start()' for an HTML browser interface to help.
Type 'q()' to quit R.

Loading required package: grDevices
[Detaching after fork from child process 27646]
[Detaching after fork from child process 27648]
> system.file("arrow/lib/libarrow.so")
[1] ""
> system.file("arrow/libs/libarrow.so")
[1] ""
> system.file("libs/libarrow.so",package="arrow")
[1] ""
> system.file("libs/",package="arrow")
[1] "/home/tdhock/lib/R/library/arrow/libs/"
> dir(system.file("libs/",package="arrow"))
[1] "arrow.so"
> system.file("libs/arrow.so",package="arrow")
[1] "/home/tdhock/lib/R/library/arrow/libs/arrow.so"
> system(paste("ldd", system.file("libs/arrow.so",package="arrow")))
[Detaching after fork from child process 27650]
	linux-vdso.so.1 (0x00007ffff7ffa000)
	libgtk3-nocsd.so.0 => /usr/lib/x86_64-linux-gnu/libgtk3-nocsd.so.0 (0x00007ffff76a6000)
	libarrow_acero.so.1300 => /home/tdhock/lib/libarrow_acero.so.1300 (0x00007ffff6e1a000)
	libarrow_dataset.so.1300 => /home/tdhock/lib/libarrow_dataset.so.1300 (0x00007ffff63a3000)
	libparquet.so.1300 => /home/tdhock/lib/libparquet.so.1300 (0x00007ffff599b000)
	libarrow.so.1300 => /home/tdhock/lib/libarrow.so.1300 (0x00007ffff1d75000)
	libR.so => /home/tdhock/lib/R/lib/libR.so (0x00007ffff16ff000)
	libthrift.so.0.15.0 => /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libthrift.so.0.15.0 (0x00007ffff7f44000)
	libstdc++.so.6 => /usr/lib/x86_64-linux-gnu/libstdc++.so.6 (0x00007ffff12f2000)
	libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007ffff0f54000)
	libgcc_s.so.1 => /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libgcc_s.so.1 (0x00007ffff7efc000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007ffff0b63000)
	libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007ffff095f000)
	libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007ffff0740000)
	librt.so.1 => /lib/x86_64-linux-gnu/librt.so.1 (0x00007ffff0538000)
	/lib64/ld-linux-x86-64.so.2 (0x00007ffff7dd3000)
	libssl.so.1.1 => /usr/lib/x86_64-linux-gnu/libssl.so.1.1 (0x00007ffff02ab000)
	libcrypto.so.1.1 => /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1 (0x00007fffefddf000)
	libblas.so.3 => /usr/lib/x86_64-linux-gnu/libblas.so.3 (0x00007fffefb72000)
	libgfortran.so.5 => /usr/lib/x86_64-linux-gnu/libgfortran.so.5 (0x00007fffef6bc000)
	libquadmath.so.0 => /usr/lib/x86_64-linux-gnu/libquadmath.so.0 (0x00007fffef475000)
	libreadline.so.7 => /lib/x86_64-linux-gnu/libreadline.so.7 (0x00007fffef22c000)
	libpcre2-8.so.0 => /usr/lib/x86_64-linux-gnu/libpcre2-8.so.0 (0x00007fffeefaa000)
	liblzma.so.5 => /lib/x86_64-linux-gnu/liblzma.so.5 (0x00007fffeed84000)
	libbz2.so.1.0 => /lib/x86_64-linux-gnu/libbz2.so.1.0 (0x00007fffeeb74000)
	libz.so.1 => /lib/x86_64-linux-gnu/libz.so.1 (0x00007fffee957000)
	libicuuc.so.60 => /usr/lib/x86_64-linux-gnu/libicuuc.so.60 (0x00007fffee59f000)
	libicui18n.so.60 => /usr/lib/x86_64-linux-gnu/libicui18n.so.60 (0x00007fffee0fe000)
	libgomp.so.1 => /usr/lib/x86_64-linux-gnu/libgomp.so.1 (0x00007fffedebb000)
	libtinfo.so.5 => /lib/x86_64-linux-gnu/libtinfo.so.5 (0x00007fffedc91000)
	libicudata.so.60 => /usr/lib/x86_64-linux-gnu/libicudata.so.60 (0x00007fffec0e8000)
> example("write_dataset",package="arrow")
[New Thread 0x7fffe6897700 (LWP 27664)]
[New Thread 0x7fffde3ff700 (LWP 27667)]
Some features are not enabled in this build of Arrow. Run `arrow_info()` for more information.

Attaching package: ‘arrow’

The following object is masked from ‘package:utils’:

    timestamp


wrt_dt> ## Don't show: 
wrt_dt> if (arrow_with_dataset() & arrow_with_parquet() & requireNamespace("dplyr", quietly = TRUE)) (if (getRversion() >= "3.4") withAutoprint else force)({ # examplesIf
wrt_dt+ ## End(Don't show)
wrt_dt+ # You can write datasets partitioned by the values in a column (here: "cyl").
wrt_dt+ # This creates a structure of the form cyl=X/part-Z.parquet.
wrt_dt+ one_level_tree <- tempfile()
wrt_dt+ write_dataset(mtcars, one_level_tree, partitioning = "cyl")
wrt_dt+ list.files(one_level_tree, recursive = TRUE)
wrt_dt+ 
wrt_dt+ # You can also partition by the values in multiple columns
wrt_dt+ # (here: "cyl" and "gear").
wrt_dt+ # This creates a structure of the form cyl=X/gear=Y/part-Z.parquet.
wrt_dt+ two_levels_tree <- tempfile()
wrt_dt+ write_dataset(mtcars, two_levels_tree, partitioning = c("cyl", "gear"))
wrt_dt+ list.files(two_levels_tree, recursive = TRUE)
wrt_dt+ 
wrt_dt+ # In the two previous examples we would have:
wrt_dt+ # X = {4,6,8}, the number of cylinders.
wrt_dt+ # Y = {3,4,5}, the number of forward gears.
wrt_dt+ # Z = {0,1,2}, the number of saved parts, starting from 0.
wrt_dt+ 
wrt_dt+ # You can obtain the same result as as the previous examples using arrow with
wrt_dt+ # a dplyr pipeline. This will be the same as two_levels_tree above, but the
wrt_dt+ # output directory will be different.
wrt_dt+ library(dplyr)
wrt_dt+ two_levels_tree_2 <- tempfile()
wrt_dt+ mtcars %>%
wrt_dt+   group_by(cyl, gear) %>%
wrt_dt+   write_dataset(two_levels_tree_2)
wrt_dt+ list.files(two_levels_tree_2, recursive = TRUE)
wrt_dt+ 
wrt_dt+ # And you can also turn off the Hive-style directory naming where the column
wrt_dt+ # name is included with the values by using `hive_style = FALSE`.
wrt_dt+ 
wrt_dt+ # Write a structure X/Y/part-Z.parquet.
wrt_dt+ two_levels_tree_no_hive <- tempfile()
wrt_dt+ mtcars %>%
wrt_dt+   group_by(cyl, gear) %>%
wrt_dt+   write_dataset(two_levels_tree_no_hive, hive_style = FALSE)
wrt_dt+ list.files(two_levels_tree_no_hive, recursive = TRUE)
wrt_dt+ ## Don't show: 
wrt_dt+ }) # examplesIf
> one_level_tree <- tempfile()
> write_dataset(mtcars, one_level_tree, partitioning = "cyl")
[New Thread 0x7fffdd1f9700 (LWP 27668)]
[New Thread 0x7fffd7fff700 (LWP 27669)]
[New Thread 0x7fffd766e700 (LWP 27670)]
[New Thread 0x7fffd6cdd700 (LWP 27671)]

Thread 5 "R" received signal SIGILL, Illegal instruction.
[Switching to Thread 0x7fffd7fff700 (LWP 27669)]
0x00007fffe137eaa2 in arrow::compute::RowTableMetadata::FromColumnMetadataVector (this=0x7fffc80032e0, cols=std::vector of length 1, capacity 1 = {...}, 
    in_row_alignment=8, in_string_alignment=8)
    at /home/tdhock/arrow-git/cpp/src/arrow/compute/row/row_internal.cc:128
128	        ARROW_POPCOUNT64(col.fixed_length) != 1) {
(gdb) bt
#0  0x00007fffe137eaa2 in arrow::compute::RowTableMetadata::FromColumnMetadataVector (this=0x7fffc80032e0, 
    cols=std::vector of length 1, capacity 1 = {...}, in_row_alignment=8, 
    in_string_alignment=8)
    at /home/tdhock/arrow-git/cpp/src/arrow/compute/row/row_internal.cc:128
#1  0x00007fffe13572b2 in arrow::compute::RowTableEncoder::Init (
    this=0x7fffc80032e0, cols=std::vector of length 1, capacity 1 = {...}, 
    row_alignment=8, string_alignment=8)
    at /home/tdhock/arrow-git/cpp/src/arrow/compute/row/encode_internal.cc:26
#2  0x00007fffe136be5d in arrow::compute::(anonymous namespace)::GrouperFastImpl::Make (keys=std::vector of length 1, capacity 1 = {...}, 
    ctx=0x7fffe2f293e0 <arrow::compute::default_exec_context()::default_ctx>)
    at /home/tdhock/arrow-git/cpp/src/arrow/compute/row/grouper.cc:566
#3  0x00007fffe136f4bb in arrow::compute::Grouper::Make (
    key_types=std::vector of length 1, capacity 1 = {...}, 
    ctx=0x7fffe2f293e0 <arrow::compute::default_exec_context()::default_ctx>)
    at /home/tdhock/arrow-git/cpp/src/arrow/compute/row/grouper.cc:870
#4  0x00007fffe413df46 in arrow::dataset::KeyValuePartitioning::Partition (
    this=0x1132f00, batch=
    std::shared_ptr<arrow::RecordBatch> (use count 2, weak count 0) = {...})
    at /home/tdhock/arrow-git/cpp/src/arrow/dataset/partition.cc:144
#5  0x00007fffe40f4e81 in arrow::dataset::(anonymous namespace)::WriteBatch(std::shared_ptr<arrow::RecordBatch>, arrow::compute::Expression, arrow::dataset::FileSystemDatasetWriteOptions, std::function<arrow::Status(std::shared_ptr<arrow::RecordBatch>, const arrow::dataset::PartitionPathFormat&)>) (
    batch=std::shared_ptr<arrow::RecordBatch> (use count 2, weak count 0) = {...}, guarantee=..., write_options=..., write=...)
    at /home/tdhock/arrow-git/cpp/src/arrow/dataset/file_base.cc:363
#6  0x00007fffe40f5d7c in arrow::dataset::(anonymous namespace)::DatasetWritingSinkNodeConsumer::WriteNextBatch (this=0x1efb2e0, 
    batch=std::shared_ptr<arrow::RecordBatch> (use count 2, weak count 0) = {...}, guarantee=...)
    at /home/tdhock/arrow-git/cpp/src/arrow/dataset/file_base.cc:434
#7  0x00007fffe40f5ae7 in arrow::dataset::(anonymous namespace)::DatasetWritingSinkNodeConsumer::Consume (this=0x1efb2e0, batch=...)
    at /home/tdhock/arrow-git/cpp/src/arrow/dataset/file_base.cc:415
#8  0x00007fffe4a81b82 in arrow::acero::(anonymous namespace)::ConsumingSinkNode::Process (this=0x311c340, batch=...)
    at /home/tdhock/arrow-git/cpp/src/arrow/acero/sink_node.cc:399
#9  0x00007fffe49557a8 in arrow::acero::util::(anonymous namespace)::SerialSequencingQueueImpl::DoProcess (this=0xde3ac0, lk=...)
    at /home/tdhock/arrow-git/cpp/src/arrow/acero/accumulation_queue.cc:148
#10 0x00007fffe495561f in arrow::acero::util::(anonymous namespace)::SerialSequencingQueueImpl::InsertBatch (this=0xde3ac0, batch=...)
    at /home/tdhock/arrow-git/cpp/src/arrow/acero/accumulation_queue.cc:133
#11 0x00007fffe4a819f8 in arrow::acero::(anonymous namespace)::ConsumingSinkNode::InputReceived (this=0x311c340, input=0x68bca50, batch=...)
    at /home/tdhock/arrow-git/cpp/src/arrow/acero/sink_node.cc:387
#12 0x00007fffe4a8ca70 in operator() (__closure=0x7fffc8001690)
    at /home/tdhock/arrow-git/cpp/src/arrow/acero/source_node.cc:119
#13 0x00007fffe4a95292 in std::__invoke_impl<arrow::Status, arrow::acero::(anonymous namespace)::SourceNode::SliceAndDeliverMorsel(const arrow::compute::ExecBatch&)::<lambda()>&>(std::__invoke_other, struct {...} &) (__f=...)
    at /home/tdhock/include/c++/10.1.0/bits/invoke.h:60
#14 0x00007fffe4a93efa in std::__invoke_r<arrow::Status, arrow::acero::(anonymous namespace)::SourceNode::SliceAndDeliverMorsel(const arrow::compute::ExecBatch&)::<lambda()>&>(struct {...} &) (__fn=...)
    at /home/tdhock/include/c++/10.1.0/bits/invoke.h:115
#15 0x00007fffe4a924fb in std::_Function_handler<arrow::Status(), arrow::acero::(anonymous namespace)::SourceNode::SliceAndDeliverMorsel(const arrow::compute::ExecBatch&)::<lambda()> >::_M_invoke(const std::_Any_data &) (
    __functor=...) at /home/tdhock/include/c++/10.1.0/bits/std_function.h:292
#16 0x00007fffe495839b in std::function<arrow::Status ()>::operator()() const
    (this=0x7fffc8001990)
    at /home/tdhock/include/c++/10.1.0/bits/std_function.h:622
#17 0x00007fffe4a7f289 in arrow::detail::ContinueFuture::operator()<std::function<arrow::Status ()>&, , arrow::Status, arrow::Future<arrow::internal::Empty> >(arrow::Future<arrow::internal::Empty>, std::function<arrow::Status ()>&) const (this=0x7fffc8001988, next=..., f=...)
    at /home/tdhock/arrow-git/cpp/src/arrow/util/future.h:150
#18 0x00007fffe4a7f224 in std::__invoke_impl<void, arrow::detail::ContinueFuture&, arrow::Future<arrow::internal::Empty>&, std::function<arrow::Status ()>&>(std::__invoke_other, arrow::detail::ContinueFuture&, arrow::Future<arrow::internal::Empty>&, std::function<arrow::Status ()>&) (__f=...)
    at /home/tdhock/include/c++/10.1.0/bits/invoke.h:60
#19 0x00007fffe4a7f165 in std::__invoke<arrow::detail::ContinueFuture&, arrow::Future<arrow::internal::Empty>&, std::function<arrow::Status ()>&>(arrow::detail::ContinueFuture&, arrow::Future<arrow::internal::Empty>&, std::function<arrow::Status ()>&) (__fn=...)
    at /home/tdhock/include/c++/10.1.0/bits/invoke.h:95
#20 0x00007fffe4a7f097 in std::_Bind<arrow::detail::ContinueFuture (arrow::Future<arrow::internal::Empty>, std::function<arrow::Status ()>)>::__call<void, , 0ul, 1ul>(std::tuple<>&&, std::_Index_tuple<0ul, 1ul>) (
    this=0x7fffc8001988, __args=...)
    at /home/tdhock/include/c++/10.1.0/functional:416
#21 0x00007fffe4a7f018 in std::_Bind<arrow::detail::ContinueFuture (arrow::Future<arrow::internal::Empty>, std::function<arrow::Status ()>)>::operator()<, void>() (this=0x7fffc8001988)
    at /home/tdhock/include/c++/10.1.0/functional:499
#22 0x00007fffe4a7eff0 in arrow::internal::FnOnce<void ()>::FnImpl<std::_Bind<arrow::detail::ContinueFuture (arrow::Future<arrow::internal::Empty>, std::function<arrow::Status ()>)> >::invoke() (this=0x7fffc8001980)
    at /home/tdhock/arrow-git/cpp/src/arrow/util/functional.h:152
#23 0x00007fffe0f0fc3c in arrow::internal::FnOnce<void ()>::operator()() && (
    this=0x7fffd7ffec80)
    at /home/tdhock/arrow-git/cpp/src/arrow/util/functional.h:140
#24 0x00007fffe0f0acfb in arrow::internal::WorkerLoop (
    state=std::shared_ptr<arrow::internal::ThreadPool::State> (use count 5, weak count 1) = {...}, it={_M_id = {_M_thread = 140736817264384}})
    at /home/tdhock/arrow-git/cpp/src/arrow/util/thread_pool.cc:269
#25 0x00007fffe0f0b9e5 in operator() (__closure=0x36a17c8)
    at /home/tdhock/arrow-git/cpp/src/arrow/util/thread_pool.cc:430
#26 0x00007fffe0f0f402 in std::__invoke_impl<void, arrow::internal::ThreadPool::LaunchWorkersUnlocked(int)::<lambda()> >(std::__invoke_other, struct {...} &&) (__f=...) at /home/tdhock/include/c++/10.1.0/bits/invoke.h:60
#27 0x00007fffe0f0f3b7 in std::__invoke<arrow::internal::ThreadPool::LaunchWorkersUnlocked(int)::<lambda()> >(struct {...} &&) (__fn=...)
    at /home/tdhock/include/c++/10.1.0/bits/invoke.h:95
#28 0x00007fffe0f0f364 in std::thread::_Invoker<std::tuple<arrow::internal::ThreadPool::LaunchWorkersUnlocked(int)::<lambda()> > >::_M_invoke<0>(std::_Index_tuple<0>) (this=0x36a17c8) at /home/tdhock/include/c++/10.1.0/thread:264
#29 0x00007fffe0f0f338 in std::thread::_Invoker<std::tuple<arrow::internal::ThreadPool::LaunchWorkersUnlocked(int)::<lambda()> > >::operator()(void) (
    this=0x36a17c8) at /home/tdhock/include/c++/10.1.0/thread:271
#30 0x00007fffe0f0f31c in std::thread::_State_impl<std::thread::_Invoker<std::tuple<arrow::internal::ThreadPool::LaunchWorkersUnlocked(int)::<lambda()> > > >::_M_run(void) (this=0x36a17c0)
    at /home/tdhock/include/c++/10.1.0/thread:215
#31 0x00007ffff25544c0 in ?? () from /usr/lib/x86_64-linux-gnu/libstdc++.so.6
#32 0x00007ffff70fb6db in start_thread (arg=0x7fffd7fff700)
    at pthread_create.c:463
#33 0x00007ffff6e2461f in clone ()
    at ../sysdeps/unix/sysv/linux/x86_64/clone.S:95
(gdb) disassemble
Dump of assembler code for function _ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii:
   0x00007fffe137e886 <+0>:	push   %rbp
   0x00007fffe137e887 <+1>:	mov    %rsp,%rbp
   0x00007fffe137e88a <+4>:	push   %r12
   0x00007fffe137e88c <+6>:	push   %rbx
   0x00007fffe137e88d <+7>:	sub    $0x70,%rsp
   0x00007fffe137e891 <+11>:	mov    %rdi,-0x68(%rbp)
   0x00007fffe137e895 <+15>:	mov    %rsi,-0x70(%rbp)
   0x00007fffe137e899 <+19>:	mov    %edx,-0x74(%rbp)
   0x00007fffe137e89c <+22>:	mov    %ecx,-0x78(%rbp)
   0x00007fffe137e89f <+25>:	mov    -0x68(%rbp),%rax
   0x00007fffe137e8a3 <+29>:	lea    0x18(%rax),%rbx
   0x00007fffe137e8a7 <+33>:	mov    -0x70(%rbp),%rax
   0x00007fffe137e8ab <+37>:	mov    %rax,%rdi
   0x00007fffe137e8ae <+40>:	call   0x7fffe0845e70 <_ZNKSt6vectorIN5arrow7compute17KeyColumnMetadataESaIS2_EE4sizeEv@plt>
   0x00007fffe137e8b3 <+45>:	mov    %rax,%rsi
   0x00007fffe137e8b6 <+48>:	mov    %rbx,%rdi
   0x00007fffe137e8b9 <+51>:	call   0x7fffe07fd950 <_ZNSt6vectorIN5arrow7compute17KeyColumnMetadataESaIS2_EE6resizeEm@plt>
   0x00007fffe137e8be <+56>:	movq   $0x0,-0x18(%rbp)
   0x00007fffe137e8c6 <+64>:	mov    -0x70(%rbp),%rax
   0x00007fffe137e8ca <+68>:	mov    %rax,%rdi
   0x00007fffe137e8cd <+71>:	call   0x7fffe0845e70 <_ZNKSt6vectorIN5arrow7compute17KeyColumnMetadataESaIS2_EE4sizeEv@plt>
   0x00007fffe137e8d2 <+76>:	cmp    %rax,-0x18(%rbp)
   0x00007fffe137e8d6 <+80>:	setb   %al
   0x00007fffe137e8d9 <+83>:	test   %al,%al
   0x00007fffe137e8db <+85>:	je     0x7fffe137e917 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+145>
   0x00007fffe137e8dd <+87>:	mov    -0x18(%rbp),%rdx
   0x00007fffe137e8e1 <+91>:	mov    -0x70(%rbp),%rax
   0x00007fffe137e8e5 <+95>:	mov    %rdx,%rsi
   0x00007fffe137e8e8 <+98>:	mov    %rax,%rdi
   0x00007fffe137e8eb <+101>:	call   0x7fffe07d4240 <_ZNKSt6vectorIN5arrow7compute17KeyColumnMetadataESaIS2_EEixEm@plt>
   0x00007fffe137e8f0 <+106>:	mov    %rax,%rbx
   0x00007fffe137e8f3 <+109>:	mov    -0x68(%rbp),%rax
   0x00007fffe137e8f7 <+113>:	add    $0x18,%rax
   0x00007fffe137e8fb <+117>:	mov    -0x18(%rbp),%rdx
   0x00007fffe137e8ff <+121>:	mov    %rdx,%rsi
   0x00007fffe137e902 <+124>:	mov    %rax,%rdi
   0x00007fffe137e905 <+127>:	call   0x7fffe0862c10 <_ZNSt6vectorIN5arrow7compute17KeyColumnMetadataESaIS2_EEixEm@plt>
   0x00007fffe137e90a <+132>:	mov    (%rbx),%rdx
   0x00007fffe137e90d <+135>:	mov    %rdx,(%rax)
   0x00007fffe137e910 <+138>:	addq   $0x1,-0x18(%rbp)
   0x00007fffe137e915 <+143>:	jmp    0x7fffe137e8c6 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+64>
   0x00007fffe137e917 <+145>:	mov    -0x70(%rbp),%rax
   0x00007fffe137e91b <+149>:	mov    %rax,%rdi
   0x00007fffe137e91e <+152>:	call   0x7fffe0845e70 <_ZNKSt6vectorIN5arrow7compute17KeyColumnMetadataESaIS2_EE4sizeEv@plt>
   0x00007fffe137e923 <+157>:	mov    %eax,-0x30(%rbp)
   0x00007fffe137e926 <+160>:	mov    -0x68(%rbp),%rax
   0x00007fffe137e92a <+164>:	lea    0x30(%rax),%rdx
   0x00007fffe137e92e <+168>:	mov    -0x30(%rbp),%eax
   0x00007fffe137e931 <+171>:	mov    %rax,%rsi
   0x00007fffe137e934 <+174>:	mov    %rdx,%rdi
   0x00007fffe137e937 <+177>:	call   0x7fffe135cd18 <_ZNSt6vectorIjSaIjEE6resizeEm>
   0x00007fffe137e93c <+182>:	movl   $0x0,-0x1c(%rbp)
   0x00007fffe137e943 <+189>:	mov    -0x1c(%rbp),%eax
   0x00007fffe137e946 <+192>:	cmp    -0x30(%rbp),%eax
   0x00007fffe137e949 <+195>:	jae    0x7fffe137e96c <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+230>
   0x00007fffe137e94b <+197>:	mov    -0x1c(%rbp),%ebx
   0x00007fffe137e94e <+200>:	mov    -0x68(%rbp),%rax
   0x00007fffe137e952 <+204>:	lea    0x30(%rax),%rdx
   0x00007fffe137e956 <+208>:	mov    -0x1c(%rbp),%eax
   0x00007fffe137e959 <+211>:	mov    %rax,%rsi
   0x00007fffe137e95c <+214>:	mov    %rdx,%rdi
   0x00007fffe137e95f <+217>:	
    call   0x7fffe0d657fe <_ZNSt6vectorIjSaIjEEixEm>
   0x00007fffe137e964 <+222>:	mov    %ebx,(%rax)
   0x00007fffe137e966 <+224>:	addl   $0x1,-0x1c(%rbp)
   0x00007fffe137e96a <+228>:	jmp    0x7fffe137e943 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+189>
   0x00007fffe137e96c <+230>:	mov    -0x70(%rbp),%rbx
   0x00007fffe137e970 <+234>:	mov    -0x68(%rbp),%rax
   0x00007fffe137e974 <+238>:	add    $0x30,%rax
   0x00007fffe137e978 <+242>:	mov    %rax,%rdi
   0x00007fffe137e97b <+245>:	call   0x7fffe0d6548c <_ZNSt6vectorIjSaIjEE3endEv>
   0x00007fffe137e980 <+250>:	mov    %rax,%r12
   0x00007fffe137e983 <+253>:	mov    -0x68(%rbp),%rax
   0x00007fffe137e987 <+257>:	add    $0x30,%rax
   0x00007fffe137e98b <+261>:	mov    %rax,%rdi
   0x00007fffe137e98e <+264>:	call   0x7fffe0d65466 <_ZNSt6vectorIjSaIjEE5beginEv>
   0x00007fffe137e993 <+269>:	mov    %rbx,%rdx
   0x00007fffe137e996 <+272>:	mov    %r12,%rsi
   0x00007fffe137e999 <+275>:	mov    %rax,%rdi
   0x00007fffe137e99c <+278>:	call   0x7fffe1380c87 <std::sort<__gnu_cxx::__normal_iterator<unsigned int*, std::vector<unsigned int> >, arrow::compute::RowTableMetadata::FromColumnMetadataVector(const std::vector<arrow::compute::KeyColumnMetadata>&, int, int)::<lambda(uint32_t, uint32_t)> >(__gnu_cxx::__normal_iterator<unsigned int*, std::vector<unsigned int, std::allocator<unsigned int> > >, __gnu_cxx::__normal_iterator<unsigned int*, std::vector<unsigned int, std::allocator<unsigned int> > >, struct {...})>
   0x00007fffe137e9a1 <+283>:	mov    -0x68(%rbp),%rax
   0x00007fffe137e9a5 <+287>:	lea    0x48(%rax),%rdx
   0x00007fffe137e9a9 <+291>:	mov    -0x30(%rbp),%eax
   0x00007fffe137e9ac <+294>:	mov    %rax,%rsi
   0x00007fffe137e9af <+297>:	mov    %rdx,%rdi
   0x00007fffe137e9b2 <+300>:	call   0x7fffe135cd18 <_ZNSt6vectorIjSaIjEE6resizeEm>
   0x00007fffe137e9b7 <+305>:	movl   $0x0,-0x20(%rbp)
   0x00007fffe137e9be <+312>:	mov    -0x20(%rbp),%eax
   0x00007fffe137e9c1 <+315>:	cmp    -0x30(%rbp),%eax
   0x00007fffe137e9c4 <+318>:	jae    0x7fffe137ea00 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+378>
   0x00007fffe137e9c6 <+320>:	mov    -0x20(%rbp),%r12d
   0x00007fffe137e9ca <+324>:	mov    -0x68(%rbp),%rax
   0x00007fffe137e9ce <+328>:	lea    0x48(%rax),%rbx
   0x00007fffe137e9d2 <+332>:	mov    -0x68(%rbp),%rax
   0x00007fffe137e9d6 <+336>:	lea    0x30(%rax),%rdx
   0x00007fffe137e9da <+340>:	mov    -0x20(%rbp),%eax
   0x00007fffe137e9dd <+343>:	mov    %rax,%rsi
   0x00007fffe137e9e0 <+346>:	mov    %rdx,%rdi
   0x00007fffe137e9e3 <+349>:	call   0x7fffe0d657fe <_ZNSt6vectorIjSaIjEEixEm>
   0x00007fffe137e9e8 <+354>:	mov    (%rax),%eax
   0x00007fffe137e9ea <+356>:	mov    %eax,%eax
   0x00007fffe137e9ec <+358>:	mov    %rax,%rsi
   0x00007fffe137e9ef <+361>:	mov    %rbx,%rdi
   0x00007fffe137e9f2 <+364>:	call   0x7fffe0d657fe <_ZNSt6vectorIjSaIjEEixEm>
   0x00007fffe137e9f7 <+369>:	mov    %r12d,(%rax)
   0x00007fffe137e9fa <+372>:	addl   $0x1,-0x20(%rbp)
   0x00007fffe137e9fe <+376>:	jmp    0x7fffe137e9be <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+312>
   0x00007fffe137ea00 <+378>:	mov    -0x68(%rbp),%rax
   0x00007fffe137ea04 <+382>:	mov    -0x74(%rbp),%edx
   0x00007fffe137ea07 <+385>:	mov    %edx,0x10(%rax)
   0x00007fffe137ea0a <+388>:	mov    -0x68(%rbp),%rax
   0x00007fffe137ea0e <+392>:	mov    -0x78(%rbp),%edx
   0x00007fffe137ea11 <+395>:	mov    %edx,0x14(%rax)
   0x00007fffe137ea14 <+398>:	mov    -0x68(%rbp),%rax
   0x00007fffe137ea18 <+402>:	movl   $0x0,0x8(%rax)
   0x00007fffe137ea1f <+409>:	mov    -0x68(%rbp),%rax
   0x00007fffe137ea23 <+413>:	lea    0x60(%rax),%rdx
   0x00007fffe137ea27 <+417>:	mov    -0x30(%rbp),%eax
   0x00007fffe137ea2a <+420>:	mov    %rax,%rsi
   0x00007fffe137ea2d <+423>:	mov    %rdx,%rdi
   0x00007fffe137ea30 <+426>:	call   0x7fffe135cd18 <_ZNSt6vectorIjSaIjEE6resizeEm>
   0x00007fffe137ea35 <+431>:	movl   $0x0,-0x24(%rbp)
   0x00007fffe137ea3c <+438>:	movl   $0x0,-0x28(%rbp)
   0x00007fffe137ea43 <+445>:	movl   $0x0,-0x2c(%rbp)
   0x00007fffe137ea4a <+452>:	mov    -0x2c(%rbp),%eax
   0x00007fffe137ea4d <+455>:	cmp    -0x30(%rbp),%eax
   0x00007fffe137ea50 <+458>:	jae    0x7fffe137ebd3 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+845>
   0x00007fffe137ea56 <+464>:	mov    -0x68(%rbp),%rax
   0x00007fffe137ea5a <+468>:	lea    0x30(%rax),%rdx
   0x00007fffe137ea5e <+472>:	mov    -0x2c(%rbp),%eax
   0x00007fffe137ea61 <+475>:	mov    %rax,%rsi
   0x00007fffe137ea64 <+478>:	mov    %rdx,%rdi
   0x00007fffe137ea67 <+481>:	call   0x7fffe0d657fe <_ZNSt6vectorIjSaIjEEixEm>
   0x00007fffe137ea6c <+486>:	mov    (%rax),%eax
   0x00007fffe137ea6e <+488>:	mov    %eax,%edx
   0x00007fffe137ea70 <+490>:	mov    -0x70(%rbp),%rax
   0x00007fffe137ea74 <+494>:	mov    %rdx,%rsi
   0x00007fffe137ea77 <+497>:	mov    %rax,%rdi
   0x00007fffe137ea7a <+500>:	call   0x7fffe07d4240 <_ZNKSt6vectorIN5arrow7compute17KeyColumnMetadataESaIS2_EEixEm@plt>
   0x00007fffe137ea7f <+505>:	mov    %rax,-0x38(%rbp)
   0x00007fffe137ea83 <+509>:	mov    -0x38(%rbp),%rax
   0x00007fffe137ea87 <+513>:	movzbl (%rax),%eax
   0x00007fffe137ea8a <+516>:	test   %al,%al
   0x00007fffe137ea8c <+518>:	je     0x7fffe137eac6 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+576>
   0x00007fffe137ea8e <+520>:	mov    -0x38(%rbp),%rax
   0x00007fffe137ea92 <+524>:	mov    0x4(%rax),%eax
   0x00007fffe137ea95 <+527>:	test   %eax,%eax
   0x00007fffe137ea97 <+529>:	je     0x7fffe137eac6 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+576>
   0x00007fffe137ea99 <+531>:	mov    -0x38(%rbp),%rax
   0x00007fffe137ea9d <+535>:	mov    0x4(%rax),%eax
   0x00007fffe137eaa0 <+538>:	mov    %eax,%eax
=> 0x00007fffe137eaa2 <+540>:	popcnt %rax,%rax
   0x00007fffe137eaa7 <+545>:	cmp    $0x1,%eax
   0x00007fffe137eaaa <+548>:	je     0x7fffe137eac6 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+576>
   0x00007fffe137eaac <+550>:	mov    -0x68(%rbp),%rax
   0x00007fffe137eab0 <+554>:	mov    0x14(%rax),%ecx
   0x00007fffe137eab3 <+557>:	mov    -0x38(%rbp),%rdx
   0x00007fffe137eab7 <+561>:	mov    -0x28(%rbp),%eax
   0x00007fffe137eaba <+564>:	mov    %ecx,%esi
   0x00007fffe137eabc <+566>:	mov    %eax,%edi
   0x00007fffe137eabe <+568>:	call   0x7fffe08343d0 <_ZN5arrow7compute16RowTableMetadata21padding_for_alignmentEjiRKNS0_17KeyColumnMetadataE@plt>
   0x00007fffe137eac3 <+573>:	add    %eax,-0x28(%rbp)
   0x00007fffe137eac6 <+576>:	mov    -0x28(%rbp),%ebx
   0x00007fffe137eac9 <+579>:	mov    -0x68(%rbp),%rax
   0x00007fffe137eacd <+583>:	lea    0x60(%rax),%rdx
   0x00007fffe137ead1 <+587>:	mov    -0x2c(%rbp),%eax
   0x00007fffe137ead4 <+590>:	mov    %rax,%rsi
   0x00007fffe137ead7 <+593>:	mov    %rdx,%rdi
   0x00007fffe137eada <+596>:	call   0x7fffe0d657fe <_ZNSt6vectorIjSaIjEEixEm>
   0x00007fffe137eadf <+601>:	mov    %ebx,(%rax)
   0x00007fffe137eae1 <+603>:	mov    -0x38(%rbp),%rax
   0x00007fffe137eae5 <+607>:	movzbl (%rax),%eax
   0x00007fffe137eae8 <+610>:	xor    $0x1,%eax
   0x00007fffe137eaeb <+613>:	test   %al,%al
   0x00007fffe137eaed <+615>:	je     0x7fffe137ebaf <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+809>
   0x00007fffe137eaf3 <+621>:	cmpl   $0x0,-0x24(%rbp)
   0x00007fffe137eaf7 <+625>:	jne    0x7fffe137eb03 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+637>
   0x00007fffe137eaf9 <+627>:	mov    -0x68(%rbp),%rax
   0x00007fffe137eafd <+631>:	mov    -0x28(%rbp),%edx
   0x00007fffe137eb00 <+634>:	mov    %edx,0x8(%rax)
   0x00007fffe137eb03 <+637>:	mov    -0x68(%rbp),%rax
   0x00007fffe137eb07 <+641>:	lea    0x60(%rax),%rdx
   0x00007fffe137eb0b <+645>:	mov    -0x2c(%rbp),%eax
   0x00007fffe137eb0e <+648>:	mov    %rax,%rsi
   0x00007fffe137eb11 <+651>:	mov    %rdx,%rdi
   0x00007fffe137eb14 <+654>:	call   0x7fffe0d657fe <_ZNSt6vectorIjSaIjEEixEm>
   0x00007fffe137eb19 <+659>:	mov    (%rax),%edx
   0x00007fffe137eb1b <+661>:	mov    -0x68(%rbp),%rax
   0x00007fffe137eb1f <+665>:	mov    0x8(%rax),%ecx
   0x00007fffe137eb22 <+668>:	mov    %edx,%eax
   0x00007fffe137eb24 <+670>:	sub    %ecx,%eax
   0x00007fffe137eb26 <+672>:	mov    %eax,%edx
   0x00007fffe137eb28 <+674>:	mov    -0x24(%rbp),%eax
   0x00007fffe137eb2b <+677>:	shl    $0x2,%rax
   0x00007fffe137eb2f <+681>:	cmp    %rax,%rdx
   0x00007fffe137eb32 <+684>:	sete   %al
   0x00007fffe137eb35 <+687>:	movzbl %al,%eax
   0x00007fffe137eb38 <+690>:	mov    $0x0,%ebx
   0x00007fffe137eb3d <+695>:	test   %rax,%rax
   0x00007fffe137eb40 <+698>:	jne    0x7fffe137eb95 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+783>
   0x00007fffe137eb42 <+700>:	lea    -0x60(%rbp),%rax
   0x00007fffe137eb46 <+704>:	mov    $0x3,%ecx
   0x00007fffe137eb4b <+709>:	mov    $0x89,%edx
   0x00007fffe137eb50 <+714>:	lea    0xfaa6c1(%rip),%rsi        # 0x7fffe2329218
   0x00007fffe137eb57 <+721>:	mov    %rax,%rdi
   0x00007fffe137eb5a <+724>:	call   0x7fffe0884430 <_ZN5arrow4util8ArrowLogC1EPKciNS0_13ArrowLogLevelE@plt>
   0x00007fffe137eb5f <+729>:	mov    $0x1,%ebx
   0x00007fffe137eb64 <+734>:	lea    -0x60(%rbp),%rax
   0x00007fffe137eb68 <+738>:	lea    0xfaa6f1(%rip),%rsi        # 0x7fffe2329260
   0x00007fffe137eb6f <+745>:	mov    %rax,%rdi
   0x00007fffe137eb72 <+748>:	call   0x7fffe0837d40 <_ZN5arrow4util12ArrowLogBaselsIA104_cEERS1_RKT_@plt>
   0x00007fffe137eb77 <+753>:	mov    %rax,%r12
   0x00007fffe137eb7a <+756>:	lea    -0x39(%rbp),%rax
   0x00007fffe137eb7e <+760>:	mov    %rax,%rdi
   0x00007fffe137eb81 <+763>:	call   0x7fffe0850a70 <_ZN5arrow4util7VoidifyC1Ev@plt>
   0x00007fffe137eb86 <+768>:	lea    -0x39(%rbp),%rax
   0x00007fffe137eb8a <+772>:	mov    %r12,%rsi
   0x00007fffe137eb8d <+775>:	mov    %rax,%rdi
   0x00007fffe137eb90 <+778>:	call   0x7fffe08a07f0 <_ZN5arrow4util7VoidifyanERNS0_12ArrowLogBaseE@plt>
   0x00007fffe137eb95 <+783>:	test   %bl,%bl
   0x00007fffe137eb97 <+785>:	je     0x7fffe137eba5 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+799>
   0x00007fffe137eb99 <+787>:	lea    -0x60(%rbp),%rax
   0x00007fffe137eb9d <+791>:	mov    %rax,%rdi
   0x00007fffe137eba0 <+794>:	call   0x7fffe0907be0 <_ZN5arrow4util8ArrowLogD1Ev@plt>
   0x00007fffe137eba5 <+799>:	addl   $0x1,-0x24(%rbp)
   0x00007fffe137eba9 <+803>:	addl   $0x4,-0x28(%rbp)
   0x00007fffe137ebad <+807>:	jmp    0x7fffe137ebca <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+836>
   0x00007fffe137ebaf <+809>:	mov    -0x38(%rbp),%rax
   0x00007fffe137ebb3 <+813>:	mov    0x4(%rax),%eax
   0x00007fffe137ebb6 <+816>:	test   %eax,%eax
   0x00007fffe137ebb8 <+818>:	jne    0x7fffe137ebc0 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+826>
   0x00007fffe137ebba <+820>:	addl   $0x1,-0x28(%rbp)
   0x00007fffe137ebbe <+824>:	jmp    0x7fffe137ebca <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+836>
   0x00007fffe137ebc0 <+826>:	mov    -0x38(%rbp),%rax
   0x00007fffe137ebc4 <+830>:	mov    0x4(%rax),%eax
   0x00007fffe137ebc7 <+833>:	add    %eax,-0x28(%rbp)
   0x00007fffe137ebca <+836>:	addl   $0x1,-0x2c(%rbp)
   0x00007fffe137ebce <+840>:	jmp    0x7fffe137ea4a <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+452>
   0x00007fffe137ebd3 <+845>:	cmpl   $0x0,-0x24(%rbp)
   0x00007fffe137ebd7 <+849>:	sete   %al
   0x00007fffe137ebda <+852>:	mov    -0x68(%rbp),%rdx
   0x00007fffe137ebde <+856>:	mov    %al,(%rdx)
   0x00007fffe137ebe0 <+858>:	cmpl   $0x0,-0x24(%rbp)
   0x00007fffe137ebe4 <+862>:	jne    0x7fffe137ebef <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+873>
   0x00007fffe137ebe6 <+864>:	mov    -0x68(%rbp),%rax
   0x00007fffe137ebea <+868>:	mov    0x10(%rax),%eax
   0x00007fffe137ebed <+871>:	jmp    0x7fffe137ebf6 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+880>
   0x00007fffe137ebef <+873>:	mov    -0x68(%rbp),%rax
   0x00007fffe137ebf3 <+877>:	mov    0x14(%rax),%eax
   0x00007fffe137ebf6 <+880>:	mov    -0x28(%rbp),%edx
   0x00007fffe137ebf9 <+883>:	mov    %eax,%esi
   0x00007fffe137ebfb <+885>:	mov    %edx,%edi
   0x00007fffe137ebfd <+887>:	call   0x7fffe081e520 <_ZN5arrow7compute16RowTableMetadata21padding_for_alignmentEji@plt>
   0x00007fffe137ec02 <+892>:	mov    -0x28(%rbp),%edx
   0x00007fffe137ec05 <+895>:	add    %eax,%edx
   0x00007fffe137ec07 <+897>:	mov    -0x68(%rbp),%rax
   0x00007fffe137ec0b <+901>:	mov    %edx,0x4(%rax)
   0x00007fffe137ec0e <+904>:	mov    -0x68(%rbp),%rax
   0x00007fffe137ec12 <+908>:	movl   $0x1,0xc(%rax)
   0x00007fffe137ec19 <+915>:	mov    -0x68(%rbp),%rax
   0x00007fffe137ec1d <+919>:	mov    0xc(%rax),%eax
   0x00007fffe137ec20 <+922>:	shl    $0x3,%eax
   0x00007fffe137ec23 <+925>:	cmp    %eax,-0x30(%rbp)
   0x00007fffe137ec26 <+928>:	jbe    0x7fffe137ec59 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+979>
   0x00007fffe137ec28 <+930>:	mov    -0x68(%rbp),%rax
   0x00007fffe137ec2c <+934>:	mov    0xc(%rax),%eax
   0x00007fffe137ec2f <+937>:	lea    (%rax,%rax,1),%edx
   0x00007fffe137ec32 <+940>:	mov    -0x68(%rbp),%rax
   0x00007fffe137ec36 <+944>:	mov    %edx,0xc(%rax)
   0x00007fffe137ec39 <+947>:	jmp    0x7fffe137ec19 <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+915>
   0x00007fffe137ec3b <+949>:	mov    %rax,%r12
   0x00007fffe137ec3e <+952>:	test   %bl,%bl
   0x00007fffe137ec40 <+954>:	je     0x7fffe137ec4e <_ZN5arrow7compute16RowTableMetadata24FromColumnMetadataVectorERKSt6vectorINS0_17KeyColumnMetadataESaIS3_EEii+968>
   0x00007fffe137ec42 <+956>:	lea    -0x60(%rbp),%rax
   0x00007fffe137ec46 <+960>:	mov    %rax,%rdi
   0x00007fffe137ec49 <+963>:	call   0x7fffe0907be0 <_ZN5arrow4util8ArrowLogD1Ev@plt>
   0x00007fffe137ec4e <+968>:	mov    %r12,%rax
   0x00007fffe137ec51 <+971>:	mov    %rax,%rdi
   0x00007fffe137ec54 <+974>:	call   0x7fffe0823860 <_Unwind_Resume@plt>
   0x00007fffe137ec59 <+979>:	nop
   0x00007fffe137ec5a <+980>:	add    $0x70,%rsp
   0x00007fffe137ec5e <+984>:	pop    %rbx
   0x00007fffe137ec5f <+985>:	pop    %r12
   0x00007fffe137ec61 <+987>:	pop    %rbp
   0x00007fffe137ec62 <+988>:	ret    
End of assembler dump.
(gdb) q
A debugging session is active.

	Inferior 1 [process 27642] will be killed.

Quit anyway? (y or n) y
```

Could it be that the `-march=core2` flag is needed? TODO re-build
libarrow with the core2 flag. Before that we need to figure out:

* Negative control: How to get a minimal C program that creates a
  popcnt assembly instruction? Does gcc know to not use it on my
  system? Can we tell it not to? 
* How can we locate what line of (arrow?) C/C++ code is reponsible for
  the popcnt instruction?
* How can we inspect what command lines cmake is using to compile
  libarrow? It says above that `-msse4.2` (enables the use of
  instructions in the SSE4.2 extended instruction set) and
  `-march=core2` (I put that) flags were used.  [wikipedia page for
  Intel Core 2](https://en.wikipedia.org/wiki/Intel_Core_2) says that
  "Core 2-branded processors feature Virtualization Technology without
  EPT (with some exceptions), the NX bit and SSE3." and [SSE4
  page](https://en.wikipedia.org/wiki/SSE4) says "What is now known as
  SSSE3 (Supplemental Streaming SIMD Extensions 3), introduced in the
  Intel Core 2 processor line, was referred to as SSE4 by some media
  until Intel came up with the SSSE3 moniker. Internally dubbed Merom
  New Instructions, Intel originally did not plan to assign a special
  name to them, which was criticized by some journalists.[6] Intel
  eventually cleared up the confusion and reserved the SSE4 name for
  their next instruction set extension." and "Intel implements POPCNT
  beginning with the Nehalem microarchitecture" and [Nehalem
  page](https://en.wikipedia.org/wiki/Nehalem_(microarchitecture))
  says that "Nehalem is the codename for Intel's 45 nm
  microarchitecture released in November 2008.[2] It was used in the
  first-generation of the Intel Core i5 and i7 processors, and
  succeeds the older Core microarchitecture used on Core 2
  processors." All of this info suggests that
  * SSE4.2 includes popcnt.
  * my Core 2 Duo is older and does not support popcnt.
  * we need to turn off the `-msse4.2` flag, why is it present?
  * this interpretation is consistent with the gcc man page:
  
```
-march=cpu-type
...
core2
   Intel Core 2 CPU with 64-bit extensions, MMX, SSE, SSE2, SSE3,
   SSSE3, CX16, SAHF and FXSR instruction set support.

nehalem
   Intel Nehalem CPU with 64-bit extensions, MMX, SSE, SSE2, SSE3,
   SSSE3, SSE4.1, SSE4.2, POPCNT, CX16, SAHF and FXSR instruction
   set support.
```

[List of Core processor info sheets](https://ark.intel.com/content/www/us/en/ark/products/series/79666/legacy-intel-core-processors.html),
[Intel(R) Core(TM)2 Duo CPU P7350 info sheet](https://ark.intel.com/content/www/us/en/ark/products/36750/intel-core2-duo-processor-p7350-3m-cache-2-00-ghz-1066-mhz-fsb.html).

Why does lscpu say my Core 2 CPU supports `sse4_1` but the GCC man
page says that core2 does not?

There are [arrow
docs](https://github.com/apache/arrow/blob/1624d5aaf4f524487079066dc730176d82b986f5/docs/source/cpp/env_vars.rst)
about how to remove the `-msse4.2` flag, need to do `cmake
-DARROW_SIMD_LEVEL=NONE`.

Finally, it works!!! see below.

```
(arrow) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main*)$ CC=$HOME/bin/gcc CXX=$HOME/bin/g++ cmake .. --preset ninja-debug-basic -DCMAKE_INSTALL_PREFIX=$HOME -DARROW_CXXFLAGS=-march=core2 -DARROW_PARQUET=ON -DARROW_SIMD_LEVEL=NONE
Preset CMake variables:

  ARROW_BUILD_INTEGRATION="ON"
  ARROW_BUILD_STATIC="OFF"
  ARROW_BUILD_TESTS="ON"
  ARROW_COMPUTE="ON"
  ARROW_CSV="ON"
  ARROW_DATASET="ON"
  ARROW_EXTRA_ERROR_CONTEXT="ON"
  ARROW_FILESYSTEM="ON"
  ARROW_JSON="ON"
  ARROW_WITH_RE2="OFF"
  ARROW_WITH_UTF8PROC="OFF"
  CMAKE_BUILD_TYPE="Debug"

-- Building using CMake version: 3.22.1
-- Arrow version: 13.0.0 (full: '13.0.0-SNAPSHOT')
-- Arrow SO version: 1300 (full: 1300.0.0)
...
-- CMAKE_C_FLAGS:   -Wall -Wno-conversion -Wno-sign-conversion -Wunused-result -fno-semantic-interposition -march=core2
-- CMAKE_CXX_FLAGS:  -Wno-noexcept-type  -fdiagnostics-color=always  -Wall -Wno-conversion -Wno-sign-conversion -Wunused-result -fno-semantic-interposition -march=core2
...
-- Compile and link options:
-- 
--   ARROW_CXXFLAGS=-march=core2 [default=""]
--       Compiler flags to append when compiling Arrow
...
--   ARROW_SIMD_LEVEL=NONE [default=NONE|SSE4_2|AVX2|AVX512|NEON|SVE|SVE128|SVE256|SVE512|DEFAULT]
--       Compile-time SIMD optimization level
...
-- Build files have been written to: /home/tdhock/arrow-git/cpp/build
(arrow) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main*)$ cmake --build . --target clean 
[0/1] Re-running CMake...
-- Building using CMake version: 3.22.1
-- Arrow version: 13.0.0 (full: '13.0.0-SNAPSHOT')
-- Arrow SO version: 1300 (full: 1300.0.0)
...
-- Build files have been written to: /home/tdhock/arrow-git/cpp/build
[1/1] Cleaning all built files...
Cleaning... 653 files.
(arrow) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main*)$ cmake --build . 
[1/642] Creating directories for 'jemalloc_ep'
[2/642] Creating directories for 'googletest_ep'
[3/642] Performing download step (download, verify and extract) for 'googletest_ep'
[4/642] No update step for 'googletest_ep'
[5/642] No patch step for 'googletest_ep'
[6/642] Performing download step (download, verify and extract) for 'jemalloc_ep'
[7/642] No update step for 'jemalloc_ep'
[8/642] Performing patch step for 'jemalloc_ep'
[9/642] Performing configure step for 'googletest_ep'
[10/642] Performing build step for 'googletest_ep'
[11/642] Performing install step for 'googletest_ep'
[12/642] Completed 'googletest_ep'
[13/642] Performing configure step for 'jemalloc_ep'
[14/642] Performing build step for 'jemalloc_ep'
[15/642] Performing install step for 'jemalloc_ep'
[16/642] Completed 'jemalloc_ep'
[17/642] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/array/array_binary.cc.o
...
[641/642] Building CXX object src/parquet/CMakeFiles/parquet-arrow-test.dir/arrow/arrow_reader_writer_test.cc.o
[642/642] Linking CXX executable debug/parquet-arrow-test
(arrow) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main*)$ cmake --install . 
-- Install configuration: "DEBUG"
-- Up-to-date: /home/tdhock/lib/cmake/Arrow/FindThriftAlt.cmake
-- Installing: /home/tdhock/include/arrow/util/config.h
...
-- Installing: /home/tdhock/lib/libparquet.so.1300.0.0
-- Up-to-date: /home/tdhock/lib/libparquet.so.1300
...
-- Up-to-date: /home/tdhock/include/parquet/encryption/two_level_cache_with_expiration.h
(arrow) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main*)$ ARROW_PARQUET=true ARROW_R_WITH_PARQUET=true ARROW_DEPENDENCY_SOURCE=SYSTEM ARROW_R_DEV=true LIBARROW_BINARY=false PKG_CONFIG_PATH=$HOME/lib/pkgconfig:$CONDA_PREFIX/lib/pkgconfig R CMD INSTALL ../../r
Loading required package: grDevices
* installing to library ‘/home/tdhock/lib/R/library’
* installing *source* package ‘arrow’ ...
...
** testing if installed package can be loaded from final location
Loading required package: grDevices
** testing if installed package keeps a record of temporary installation path
* DONE (arrow)
(arrow) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main*)$ R --vanilla -e 'example("write_dataset",package="arrow")'

R version 4.3.0 (2023-04-21) -- "Already Tomorrow"
Copyright (C) 2023 The R Foundation for Statistical Computing
Platform: x86_64-pc-linux-gnu (64-bit)

R is free software and comes with ABSOLUTELY NO WARRANTY.
You are welcome to redistribute it under certain conditions.
Type 'license()' or 'licence()' for distribution details.

  Natural language support but running in an English locale

R is a collaborative project with many contributors.
Type 'contributors()' for more information and
'citation()' on how to cite R or R packages in publications.

Type 'demo()' for some demos, 'help()' for on-line help, or
'help.start()' for an HTML browser interface to help.
Type 'q()' to quit R.

> example("write_dataset",package="arrow")
Some features are not enabled in this build of Arrow. Run `arrow_info()` for more information.

Attaching package: ‘arrow’

The following object is masked from ‘package:utils’:

    timestamp


wrt_dt> ## Don't show: 
wrt_dt> if (arrow_with_dataset() & arrow_with_parquet() & requireNamespace("dplyr", quietly = TRUE)) (if (getRversion() >= "3.4") withAutoprint else force)({ # examplesIf
wrt_dt+ ## End(Don't show)
wrt_dt+ # You can write datasets partitioned by the values in a column (here: "cyl").
wrt_dt+ # This creates a structure of the form cyl=X/part-Z.parquet.
wrt_dt+ one_level_tree <- tempfile()
wrt_dt+ write_dataset(mtcars, one_level_tree, partitioning = "cyl")
wrt_dt+ list.files(one_level_tree, recursive = TRUE)
wrt_dt+ 
wrt_dt+ # You can also partition by the values in multiple columns
wrt_dt+ # (here: "cyl" and "gear").
wrt_dt+ # This creates a structure of the form cyl=X/gear=Y/part-Z.parquet.
wrt_dt+ two_levels_tree <- tempfile()
wrt_dt+ write_dataset(mtcars, two_levels_tree, partitioning = c("cyl", "gear"))
wrt_dt+ list.files(two_levels_tree, recursive = TRUE)
wrt_dt+ 
wrt_dt+ # In the two previous examples we would have:
wrt_dt+ # X = {4,6,8}, the number of cylinders.
wrt_dt+ # Y = {3,4,5}, the number of forward gears.
wrt_dt+ # Z = {0,1,2}, the number of saved parts, starting from 0.
wrt_dt+ 
wrt_dt+ # You can obtain the same result as as the previous examples using arrow with
wrt_dt+ # a dplyr pipeline. This will be the same as two_levels_tree above, but the
wrt_dt+ # output directory will be different.
wrt_dt+ library(dplyr)
wrt_dt+ two_levels_tree_2 <- tempfile()
wrt_dt+ mtcars %>%
wrt_dt+   group_by(cyl, gear) %>%
wrt_dt+   write_dataset(two_levels_tree_2)
wrt_dt+ list.files(two_levels_tree_2, recursive = TRUE)
wrt_dt+ 
wrt_dt+ # And you can also turn off the Hive-style directory naming where the column
wrt_dt+ # name is included with the values by using `hive_style = FALSE`.
wrt_dt+ 
wrt_dt+ # Write a structure X/Y/part-Z.parquet.
wrt_dt+ two_levels_tree_no_hive <- tempfile()
wrt_dt+ mtcars %>%
wrt_dt+   group_by(cyl, gear) %>%
wrt_dt+   write_dataset(two_levels_tree_no_hive, hive_style = FALSE)
wrt_dt+ list.files(two_levels_tree_no_hive, recursive = TRUE)
wrt_dt+ ## Don't show: 
wrt_dt+ }) # examplesIf
> one_level_tree <- tempfile()
> write_dataset(mtcars, one_level_tree, partitioning = "cyl")
> list.files(one_level_tree, recursive = TRUE)
[1] "cyl=4/part-0.parquet" "cyl=6/part-0.parquet" "cyl=8/part-0.parquet"
> two_levels_tree <- tempfile()
> write_dataset(mtcars, two_levels_tree, partitioning = c("cyl", "gear"))
> list.files(two_levels_tree, recursive = TRUE)
[1] "cyl=4/gear=3/part-0.parquet" "cyl=4/gear=4/part-0.parquet"
[3] "cyl=4/gear=5/part-0.parquet" "cyl=6/gear=3/part-0.parquet"
[5] "cyl=6/gear=4/part-0.parquet" "cyl=6/gear=5/part-0.parquet"
[7] "cyl=8/gear=3/part-0.parquet" "cyl=8/gear=5/part-0.parquet"
> library(dplyr)

Attaching package: ‘dplyr’

The following objects are masked from ‘package:stats’:

    filter, lag

The following objects are masked from ‘package:base’:

    intersect, setdiff, setequal, union

> two_levels_tree_2 <- tempfile()
> mtcars %>% group_by(cyl, gear) %>% write_dataset(two_levels_tree_2)
> list.files(two_levels_tree_2, recursive = TRUE)
[1] "cyl=4/gear=3/part-0.parquet" "cyl=4/gear=4/part-0.parquet"
[3] "cyl=4/gear=5/part-0.parquet" "cyl=6/gear=3/part-0.parquet"
[5] "cyl=6/gear=4/part-0.parquet" "cyl=6/gear=5/part-0.parquet"
[7] "cyl=8/gear=3/part-0.parquet" "cyl=8/gear=5/part-0.parquet"
> two_levels_tree_no_hive <- tempfile()
> mtcars %>% group_by(cyl, gear) %>% write_dataset(two_levels_tree_no_hive, 
+     hive_style = FALSE)
> list.files(two_levels_tree_no_hive, recursive = TRUE)
[1] "4/3/part-0.parquet" "4/4/part-0.parquet" "4/5/part-0.parquet"
[4] "6/3/part-0.parquet" "6/4/part-0.parquet" "6/5/part-0.parquet"
[7] "8/3/part-0.parquet" "8/5/part-0.parquet"

wrt_dt> ## End(Don't show)
wrt_dt> 
wrt_dt> 
wrt_dt> 
> 
> 
(arrow) tdhock@maude-MacBookPro:~/arrow-git/cpp/build(main*)$ 
```

## Problem with links

I posted an issue about the R package arrow.so having a broken link to
libthrift.so, as shown by ldd below,

```
(base) tdhock@maude-MacBookPro:~/R$ ldd /home/tdhock/arrow-git/r/src/arrow.so 
	linux-vdso.so.1 (0x00007ffd6cbe9000)
	libarrow_acero.so.1300 => /home/tdhock/lib/libarrow_acero.so.1300 (0x00007f8c4f323000)
	libarrow_dataset.so.1300 => /home/tdhock/lib/libarrow_dataset.so.1300 (0x00007f8c4e8ac000)
	libparquet.so.1300 => /home/tdhock/lib/libparquet.so.1300 (0x00007f8c4dea6000)
	libarrow.so.1300 => /home/tdhock/lib/libarrow.so.1300 (0x00007f8c4a281000)
	libR.so => /usr/lib/libR.so (0x00007f8c49c58000)
	libstdc++.so.6 => /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libstdc++.so.6 (0x00007f8c49a44000)
	libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007f8c496a6000)
	libgcc_s.so.1 => /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libgcc_s.so.1 (0x00007f8c502b2000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f8c492b5000)
	libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007f8c490b1000)
	librt.so.1 => /lib/x86_64-linux-gnu/librt.so.1 (0x00007f8c48ea9000)
	libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007f8c48c8a000)
	/lib64/ld-linux-x86-64.so.2 (0x00007f8c500d5000)
	libthrift.so.0.15.0 => not found
	libssl.so.1.1 => /usr/lib/x86_64-linux-gnu/libssl.so.1.1 (0x00007f8c489fd000)
	libcrypto.so.1.1 => /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1 (0x00007f8c48531000)
	libblas.so.3 => /usr/lib/x86_64-linux-gnu/libblas.so.3 (0x00007f8c482c4000)
	libreadline.so.7 => /lib/x86_64-linux-gnu/libreadline.so.7 (0x00007f8c4807b000)
	libpcre.so.3 => /lib/x86_64-linux-gnu/libpcre.so.3 (0x00007f8c47e0a000)
	liblzma.so.5 => /lib/x86_64-linux-gnu/liblzma.so.5 (0x00007f8c47be4000)
	libbz2.so.1.0 => /lib/x86_64-linux-gnu/libbz2.so.1.0 (0x00007f8c479d4000)
	libz.so.1 => /lib/x86_64-linux-gnu/libz.so.1 (0x00007f8c477b7000)
	libicuuc.so.60 => /usr/lib/x86_64-linux-gnu/libicuuc.so.60 (0x00007f8c473ff000)
	libicui18n.so.60 => /usr/lib/x86_64-linux-gnu/libicui18n.so.60 (0x00007f8c46f5e000)
	libgomp.so.1 => /usr/lib/x86_64-linux-gnu/libgomp.so.1 (0x00007f8c46d1b000)
	libtinfo.so.5 => /lib/x86_64-linux-gnu/libtinfo.so.5 (0x00007f8c46af1000)
	libicudata.so.60 => /usr/lib/x86_64-linux-gnu/libicudata.so.60 (0x00007f8c44f48000)
```

I also saw a broken link in libparquet.so, but so broken links in
libarrow.so, shown below.

```
(base) tdhock@maude-MacBookPro:~/lib$ for so in *.so;do echo $so;ldd $so|grep found;done
libarrow_acero.so
	libarrow.so.1300 => not found
libarrow_dataset.so
	libparquet.so.1300 => not found
	libarrow_acero.so.1300 => not found
	libarrow.so.1300 => not found
libarrow.so
ldd: ./libarrow.so: No such file or directory
libarrow_testing.so
	libarrow.so.1300 => not found
	libgtestd.so.1.11.0 => not found
libparquet.so
	libarrow.so.1300 => not found
	libthrift.so.0.15.0 => not found
```

So these shared objects are linked to each other, and to libthrift,
and to libgtestd. libthrift is installed in my conda env (see below),
but where is libgtestd?

```
(base) tdhock@maude-MacBookPro:~/lib$ ls ~/.local/share/r-miniconda/envs/arrow/lib/libthrift.so
/home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libthrift.so
(base) tdhock@maude-MacBookPro:~/lib$ ls ~/.local/share/r-miniconda/envs/arrow/lib/libgtestd.so
ls: cannot access '/home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libgtestd.so': No such file or directory
```


I tried to re-compile using conda lib as rpath,
`-DCMAKE_INSTALL_RPATH=${CONDA_PREFIX}/lib` added below:

```
CC=$HOME/bin/gcc CXX=$HOME/bin/g++ cmake .. --preset ninja-debug-basic -DCMAKE_INSTALL_PREFIX=$HOME -DARROW_CXXFLAGS=-march=core2 -DARROW_PARQUET=ON -DARROW_SIMD_LEVEL=NONE -DCMAKE_INSTALL_RPATH=${CONDA_PREFIX}/lib
...
-- Could NOT find GTest (missing: GTest_DIR)
-- Building gtest from source
...
cmake --build . --target clean
cmake --build . 
cmake --install .
```

Running the above made the thrift broken link go away, but links to
libraries installed under $HOME/lib are still broken. Trying again
with $HOME/lib under rpath below,

```
CC=$HOME/bin/gcc CXX=$HOME/bin/g++ cmake .. --preset ninja-debug-basic -DCMAKE_INSTALL_PREFIX=$HOME -DARROW_CXXFLAGS=-march=core2 -DARROW_PARQUET=ON -DARROW_SIMD_LEVEL=NONE -DCMAKE_INSTALL_RPATH=$HOME/lib:$CONDA_PREFIX/lib
...
CMake Error at /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/cmake/GTest/GTestTargets.cmake:115 (message):
  The imported target "GTest::gmock" references the file

     "/home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libgmock.so.1.11.0"

  but this file does not exist.  Possible reasons include:
```

above similar to [a conda
issue](https://github.com/conda-forge/gtest-feedstock/issues/55), I
tried solving using conda install gmock then another error from conda
gtest, but looks like build system caught it and just used same gtest
from source,

```
-- GTest can't be used with C++17.
-- Use -DGTest_SOURCE=BUNDLED.
-- Output:
Change Dir: /home/tdhock/arrow-git/cpp/build/CMakeFiles/CMakeTmp

Run Build Command(s):/usr/bin/ninja cmTC_7c7ce && [1/2] Building CXX object CMakeFiles/cmTC_7c7ce.dir/gtest_cxx_standard_test.cc.o
[2/2] Linking CXX executable cmTC_7c7ce
FAILED: cmTC_7c7ce 
: && /home/tdhock/bin/g++ -fdiagnostics-color=always  CMakeFiles/cmTC_7c7ce.dir/gtest_cxx_standard_test.cc.o -o cmTC_7c7ce  -Wl,-rpath,/home/tdhock/.local/share/r-miniconda/envs/arrow/lib  /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libgtest_main.so.1.11.0  /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libgtest.so.1.11.0  -pthread && :
/home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libgtest.so.1.11.0: undefined reference to `std::__throw_bad_array_new_length()@GLIBCXX_3.4.29'
collect2: error: ld returned 1 exit status
ninja: build stopped: subcommand failed.


-- Could NOT find GTestAlt (missing: GTestAlt_CXX_STANDARD_AVAILABLE) (Required is at least version "1.10.0")
-- Building gtest from source
```

But then re-building and installing, without -lthrift in LDFLAGS in
Makevars, works fine! If the link in a dependent library like
libparquet.so is broken, then it is passed onto the arrow.so R package
shared library. If the link works, then no -lthrift is needed (that
dependency was already resolved in the previous linking step for
libparquet.so).

### problems on new macbook

```
(arrow) path/to/gcc-12$ CFLAGS=-march=core2 CXXFLAGS=-march=core2 CPPFLAGS=-march=core2 ./configure --prefix=$HOME --disable-multilib
----------------------------------------------------------------------
Libraries have been installed in:
   /home/tdhock/libexec/gcc/x86_64-pc-linux-gnu/12.3.0

If you ever happen to want to link against installed libraries
in a given directory, LIBDIR, you must either use libtool, and
specify the full pathname of the library, or use the `-LLIBDIR'
flag during linking and do at least one of the following:
   - add LIBDIR to the `LD_LIBRARY_PATH' environment variable
     during execution
   - add LIBDIR to the `LD_RUN_PATH' environment variable
     during linking
   - use the `-Wl,-rpath -Wl,LIBDIR' linker flag
   - have your system administrator add LIBDIR to `/etc/ld.so.conf'

See any operating system documentation about shared libraries for
more information, such as the ld(1) and ld.so(8) manual pages.
----------------------------------------------------------------------
```

Also in...

```
   /home/tdhock/lib/../lib64
```

So I tried adding `$HOME/lib64` to the `CMAKE_INSTALL_RPATH` below and
that seems to work:

```
cmake .. --preset ninja-debug-basic -DCMAKE_INSTALL_PREFIX=$HOME -DARROW_CXXFLAGS=-march=core2 -DARROW_PARQUET=ON -DARROW_SIMD_LEVEL=NONE -DCMAKE_INSTALL_RPATH=$HOME/lib64:$HOME/lib:$CONDA_PREFIX/lib -DCMAKE_PREFIX_PATH=$HOME -DCMAKE_FIND_ROOT_PATH=$HOME
...
[443/443] Linking CXX executable debug/parquet-arrow-test
```

but then when building the R package I get a linker issue,
libarrow_acero not found, below:

```
(arrow) tdhock@tdhock-MacBook:~/src/apache-arrow-13.0.0$ ARROW_PARQUET=true ARROW_R_WITH_PARQUET=true ARROW_DEPENDENCY_SOURCE=SYSTEM ARROW_R_DEV=true LIBARROW_BINARY=false PKG_CONFIG_PATH=$HOME/lib/pkgconfig:$CONDA_PREFIX/lib/pkgconfig R CMD INSTALL r
...
g++ -std=gnu++17 -shared -L/home/tdhock/lib/R/lib -L/usr/local/lib -o arrow.so RTasks.o altrep.o array.o array_to_vector.o arraydata.o arrowExports.o bridge.o buffer.o chunkedarray.o compression.o compute-exec.o compute.o config.o csv.o dataset.o datatype.o expression.o extension-impl.o feather.o field.o filesystem.o io.o json.o memorypool.o message.o parquet.o r_to_arrow.o recordbatch.o recordbatchreader.o recordbatchwriter.o safe-call-into-r-impl.o scalar.o schema.o symbols.o table.o threadpool.o type_infer.o -L/home/tdhock/lib -larrow_acero -larrow_dataset -lparquet -larrow -L/home/tdhock/lib/R/lib -lR...
** testing if installed package can be loaded from temporary location
Le chargement a nécessité le package : grDevices
Error: le chargement du package ou de l'espace de noms a échoué pour ‘arrow’ in dyn.load(file, DLLpath = DLLpath, ...) :
impossible de charger l'objet partagé '/home/tdhock/lib/R/library/00LOCK-r/00new/arrow/libs/arrow.so' :
  libarrow_acero.so.1300: Ne peut ouvrir le fichier d'objet partagé: Aucun fichier ou dossier de ce type
Erreur : le chargement a échoué
Exécution arrêtée
ERROR: loading failed
* removing ‘/home/tdhock/lib/R/library/arrow’
* restoring previous ‘/home/tdhock/lib/R/library/arrow’
```

fixed by telling gcc/ld to look in `~/lib`, and not `~/lib64` nor
`$CONDA_PREFIX/lib`, 

```
(arrow) tdhock@tdhock-MacBook:~/src/apache-arrow-13.0.0/r/src$ rm -f arrow.so && g++ -std=gnu++17 -shared -L/home/tdhock/lib/R/lib -L/home/tdhock/lib -Wl,-rpath=/home/tdhock/lib -o arrow.so RTasks.o altrep.o array.o array_to_vector.o arraydata.o arrowExports.o bridge.o buffer.o chunkedarray.o compression.o compute-exec.o compute.o config.o csv.o dataset.o datatype.o expression.o extension-impl.o feather.o field.o filesystem.o io.o json.o memorypool.o message.o parquet.o r_to_arrow.o recordbatch.o recordbatchreader.o recordbatchwriter.o safe-call-into-r-impl.o scalar.o schema.o symbols.o table.o threadpool.o type_infer.o -L/home/tdhock/lib -larrow_acero -larrow_dataset -lparquet -larrow -L/home/tdhock/lib/R/lib -lR && ldd arrow.so |grep acero
	libarrow_acero.so.1300 => /home/tdhock/lib/libarrow_acero.so.1300 (0x00007fcc3fd5f000)
(arrow) tdhock@tdhock-MacBook:~/src/apache-arrow-13.0.0/r/src$ ldd arrow.so |grep not
```

to get R to do that without having to hack the gcc line myself, I put
the code below in `~/.R/Makevars`

```
LDFLAGS=-L${HOME}/lib -Wl,-rpath=${HOME}/lib
```

then it works, see below.

```
(arrow) tdhock@tdhock-MacBook:~/src/apache-arrow-13.0.0/r/src$ ARROW_PARQUET=true ARROW_R_WITH_PARQUET=true ARROW_DEPENDENCY_SOURCE=SYSTEM ARROW_R_DEV=true LIBARROW_BINARY=false PKG_CONFIG_PATH=$HOME/lib/pkgconfig:$CONDA_PREFIX/lib/pkgconfig R CMD INSTALL ..
Le chargement a nécessité le package : grDevices
* installing to library ‘/home/tdhock/lib/R/library’
* installing *source* package ‘arrow’ ...
** using staged installation
*** Generating code with data-raw/codegen.R
Le chargement a nécessité le package : grDevices
Erreur dans library(decor) : aucun package nommé ‘decor’ n'est trouvé
Appels : suppressPackageStartupMessages -> withCallingHandlers -> library
Exécution arrêtée
*** Trying Arrow C++ found by pkg-config: /home/tdhock
**** C++ and R library versions match: 13.0.0
PKG_CFLAGS=-I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON
PKG_LIBS=-L/home/tdhock/lib -larrow_acero -larrow_dataset -lparquet -larrow
** libs
using C++ compiler: ‘g++ (GCC) 12.3.0’
using C++17
g++ -std=gnu++17 -shared -L/home/tdhock/lib/R/lib -L/home/tdhock/lib -Wl,-rpath=/home/tdhock/lib -o arrow.so RTasks.o altrep.o array.o array_to_vector.o arraydata.o arrowExports.o bridge.o buffer.o chunkedarray.o compression.o compute-exec.o compute.o config.o csv.o dataset.o datatype.o expression.o extension-impl.o feather.o field.o filesystem.o io.o json.o memorypool.o message.o parquet.o r_to_arrow.o recordbatch.o recordbatchreader.o recordbatchwriter.o safe-call-into-r-impl.o scalar.o schema.o symbols.o table.o threadpool.o type_infer.o -L/home/tdhock/lib -larrow_acero -larrow_dataset -lparquet -larrow -L/home/tdhock/lib/R/lib -lR
installing to /home/tdhock/lib/R/library/00LOCK-r/00new/arrow/libs
** R
** inst
** byte-compile and prepare package for lazy loading
Le chargement a nécessité le package : grDevices
** help
*** installing help indices
** building package indices
Le chargement a nécessité le package : grDevices
** installing vignettes
** testing if installed package can be loaded from temporary location
Le chargement a nécessité le package : grDevices
** checking absolute paths in shared objects and dynamic libraries
** testing if installed package can be loaded from final location
Le chargement a nécessité le package : grDevices
** testing if installed package keeps a record of temporary installation path
* DONE (arrow)
```

### Do we need `~/.R/Makevars`?

Seems that if R is built with knowledge of the gcc flags, we should
not need to put them in `~/.R/Makevars`, let's try that.

```
(base) tdhock@tdhock-MacBook:~/R/R-4.3.1$ CFLAGS="-march=core2 -I$HOME/include" CPPFLAGS="-march=core2 -I$HOME/include" LDFLAGS="-L$HOME/lib -Wl,-rpath=$HOME/lib" ./configure --prefix=$HOME --with-cairo --with-blas --with-lapack --enable-R-shlib --with-valgrind-instrumentation=2 --enable-memory-profiling
...
R is now configured for x86_64-pc-linux-gnu

  Source directory:            .
  Installation directory:      /home/tdhock

  C compiler:                  gcc  -march=core2 -I/home/tdhock/include
  Fortran fixed-form compiler: gfortran  -g -O2

  Default C++ compiler:        g++ -std=gnu++17  -g -O2
  C++11 compiler:              g++ -std=gnu++11  -g -O2
  C++14 compiler:              g++ -std=gnu++14  -g -O2
  C++17 compiler:              g++ -std=gnu++17  -g -O2
  C++20 compiler:              g++ -std=gnu++20  -g -O2
  C++23 compiler:              g++ -std=gnu++23  -g -O2
  Fortran free-form compiler:  gfortran  -g -O2
  Obj-C compiler:	       gcc -g -O2 -fobjc-exceptions

  Interfaces supported:        X11, tcltk
  External libraries:          pcre2, readline, BLAS(generic), LAPACK(generic), curl
  Additional capabilities:     PNG, JPEG, TIFF, NLS, cairo, ICU
  Options enabled:             shared R library, R profiling, memory profiling

  Capabilities skipped:        
  Options not enabled:         shared BLAS

  Recommended packages:        yes
  
...
gcc -I. -I. -I../../../src/include -I../../../src/include -march=core2 -I/home/tdhock/include -DHAVE_CONFIG_H   -fopenmp -fpic  -march=core2 -I/home/tdhock/include  -fvisibility=hidden -c regcomp.c -o regcomp.o
```

Note double `-march=core2` above. Do we need that on R configure? Yes, because
without env vars in R configure we get below:

```
gcc -I. -I. -I../../../src/include -I../../../src/include -I/usr/local/include -DHAVE_CONFIG_H   -fopenmp -fpic  -g -O2  -fvisibility=hidden -c regcomp.c -o regcomp.o
```

Below we remove `~/.R/Makevars` after re-compiling R using new flags,
to show that R arrow installation still works:

```
(base) tdhock@tdhock-MacBook:~/.R$ mv Makevars Makevars.old
(base) tdhock@tdhock-MacBook:~/.R$ cd
(base) tdhock@tdhock-MacBook:~$ cd src/apache-arrow-13.0.0/r/src/
(base) tdhock@tdhock-MacBook:~/src/apache-arrow-13.0.0/r/src$ rm arrow.so 
(base) tdhock@tdhock-MacBook:~/src/apache-arrow-13.0.0/r/src$ ARROW_PARQUET=true ARROW_R_WITH_PARQUET=true ARROW_DEPENDENCY_SOURCE=SYSTEM ARROW_R_DEV=true LIBARROW_BINARY=false PKG_CONFIG_PATH=$HOME/lib/pkgconfig:$CONDA_PREFIX/lib/pkgconfig R CMD INSTALL ..
Le chargement a nécessité le package : grDevices
* installing to library ‘/home/tdhock/lib/R/library’
* installing *source* package ‘arrow’ ...
** using staged installation
*** Generating code with data-raw/codegen.R
Le chargement a nécessité le package : grDevices
Erreur dans library(decor) : aucun package nommé ‘decor’ n'est trouvé
Appels : suppressPackageStartupMessages -> withCallingHandlers -> library
Exécution arrêtée
*** Trying Arrow C++ found by pkg-config: /home/tdhock
**** C++ and R library versions match: 13.0.0
PKG_CFLAGS=-I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_JSON
PKG_LIBS=-L/home/tdhock/lib -larrow_acero -larrow_dataset -lparquet -larrow
** libs
using C++ compiler: ‘g++ (GCC) 12.3.0’
using C++17
g++ -std=gnu++17 -shared -L/home/tdhock/lib/R/lib -L/home/tdhock/lib -Wl,-rpath=/home/tdhock/lib -o arrow.so RTasks.o altrep.o array.o array_to_vector.o arraydata.o arrowExports.o bridge.o buffer.o chunkedarray.o compression.o compute-exec.o compute.o config.o csv.o dataset.o datatype.o expression.o extension-impl.o feather.o field.o filesystem.o io.o json.o memorypool.o message.o parquet.o r_to_arrow.o recordbatch.o recordbatchreader.o recordbatchwriter.o safe-call-into-r-impl.o scalar.o schema.o symbols.o table.o threadpool.o type_infer.o -L/home/tdhock/lib -larrow_acero -larrow_dataset -lparquet -larrow -L/home/tdhock/lib/R/lib -lR
installing to /home/tdhock/lib/R/library/00LOCK-r/00new/arrow/libs
** R
** inst
** byte-compile and prepare package for lazy loading
Le chargement a nécessité le package : grDevices
** help
*** installing help indices
** building package indices
Le chargement a nécessité le package : grDevices
** installing vignettes
** testing if installed package can be loaded from temporary location
Le chargement a nécessité le package : grDevices
** checking absolute paths in shared objects and dynamic libraries
** testing if installed package can be loaded from final location
Le chargement a nécessité le package : grDevices
** testing if installed package keeps a record of temporary installation path
* DONE (arrow)
(base) tdhock@tdhock-MacBook:~/src/apache-arrow-13.0.0/r/src$ R -e 'library(arrow);example(write_dataset)'

R version 4.3.1 (2023-06-16) -- "Beagle Scouts"
Copyright (C) 2023 The R Foundation for Statistical Computing
Platform: x86_64-pc-linux-gnu (64-bit)

R est un logiciel libre livré sans AUCUNE GARANTIE.
Vous pouvez le redistribuer sous certaines conditions.
Tapez 'license()' ou 'licence()' pour plus de détails.

R est un projet collaboratif avec de nombreux contributeurs.
Tapez 'contributors()' pour plus d'information et
'citation()' pour la façon de le citer dans les publications.

Tapez 'demo()' pour des démonstrations, 'help()' pour l'aide
en ligne ou 'help.start()' pour obtenir l'aide au format HTML.
Tapez 'q()' pour quitter R.

Le chargement a nécessité le package : grDevices
> library(arrow);example(write_dataset)
Some features are not enabled in this build of Arrow. Run `arrow_info()` for more information.

Attachement du package : ‘arrow’

L'objet suivant est masqué depuis ‘package:utils’:

    timestamp


wrt_dt> ## Don't show: 
wrt_dt> if (arrow_with_dataset() & arrow_with_parquet() & requireNamespace("dplyr", quietly = TRUE)) (if (getRversion() >= "3.4") withAutoprint else force)({ # examplesIf
wrt_dt+ ## End(Don't show)
wrt_dt+ # You can write datasets partitioned by the values in a column (here: "cyl").
wrt_dt+ # This creates a structure of the form cyl=X/part-Z.parquet.
wrt_dt+ one_level_tree <- tempfile()
wrt_dt+ write_dataset(mtcars, one_level_tree, partitioning = "cyl")
wrt_dt+ list.files(one_level_tree, recursive = TRUE)
wrt_dt+ 
wrt_dt+ # You can also partition by the values in multiple columns
wrt_dt+ # (here: "cyl" and "gear").
wrt_dt+ # This creates a structure of the form cyl=X/gear=Y/part-Z.parquet.
wrt_dt+ two_levels_tree <- tempfile()
wrt_dt+ write_dataset(mtcars, two_levels_tree, partitioning = c("cyl", "gear"))
wrt_dt+ list.files(two_levels_tree, recursive = TRUE)
wrt_dt+ 
wrt_dt+ # In the two previous examples we would have:
wrt_dt+ # X = {4,6,8}, the number of cylinders.
wrt_dt+ # Y = {3,4,5}, the number of forward gears.
wrt_dt+ # Z = {0,1,2}, the number of saved parts, starting from 0.
wrt_dt+ 
wrt_dt+ # You can obtain the same result as as the previous examples using arrow with
wrt_dt+ # a dplyr pipeline. This will be the same as two_levels_tree above, but the
wrt_dt+ # output directory will be different.
wrt_dt+ library(dplyr)
wrt_dt+ two_levels_tree_2 <- tempfile()
wrt_dt+ mtcars %>%
wrt_dt+   group_by(cyl, gear) %>%
wrt_dt+   write_dataset(two_levels_tree_2)
wrt_dt+ list.files(two_levels_tree_2, recursive = TRUE)
wrt_dt+ 
wrt_dt+ # And you can also turn off the Hive-style directory naming where the column
wrt_dt+ # name is included with the values by using `hive_style = FALSE`.
wrt_dt+ 
wrt_dt+ # Write a structure X/Y/part-Z.parquet.
wrt_dt+ two_levels_tree_no_hive <- tempfile()
wrt_dt+ mtcars %>%
wrt_dt+   group_by(cyl, gear) %>%
wrt_dt+   write_dataset(two_levels_tree_no_hive, hive_style = FALSE)
wrt_dt+ list.files(two_levels_tree_no_hive, recursive = TRUE)
wrt_dt+ ## Don't show: 
wrt_dt+ }) # examplesIf
> one_level_tree <- tempfile()
> write_dataset(mtcars, one_level_tree, partitioning = "cyl")
> list.files(one_level_tree, recursive = TRUE)
[1] "cyl=4/part-0.parquet" "cyl=6/part-0.parquet" "cyl=8/part-0.parquet"
> two_levels_tree <- tempfile()
> write_dataset(mtcars, two_levels_tree, partitioning = c("cyl", "gear"))
> list.files(two_levels_tree, recursive = TRUE)
[1] "cyl=4/gear=3/part-0.parquet" "cyl=4/gear=4/part-0.parquet"
[3] "cyl=4/gear=5/part-0.parquet" "cyl=6/gear=3/part-0.parquet"
[5] "cyl=6/gear=4/part-0.parquet" "cyl=6/gear=5/part-0.parquet"
[7] "cyl=8/gear=3/part-0.parquet" "cyl=8/gear=5/part-0.parquet"
> library(dplyr)

Attachement du package : ‘dplyr’

Les objets suivants sont masqués depuis ‘package:stats’:

    filter, lag

Les objets suivants sont masqués depuis ‘package:base’:

    intersect, setdiff, setequal, union

> two_levels_tree_2 <- tempfile()
> mtcars %>% group_by(cyl, gear) %>% write_dataset(two_levels_tree_2)
> list.files(two_levels_tree_2, recursive = TRUE)
[1] "cyl=4/gear=3/part-0.parquet" "cyl=4/gear=4/part-0.parquet"
[3] "cyl=4/gear=5/part-0.parquet" "cyl=6/gear=3/part-0.parquet"
[5] "cyl=6/gear=4/part-0.parquet" "cyl=6/gear=5/part-0.parquet"
[7] "cyl=8/gear=3/part-0.parquet" "cyl=8/gear=5/part-0.parquet"
> two_levels_tree_no_hive <- tempfile()
> mtcars %>% group_by(cyl, gear) %>% write_dataset(two_levels_tree_no_hive, 
+     hive_style = FALSE)
> list.files(two_levels_tree_no_hive, recursive = TRUE)
[1] "4/3/part-0.parquet" "4/4/part-0.parquet" "4/5/part-0.parquet"
[4] "6/3/part-0.parquet" "6/4/part-0.parquet" "6/5/part-0.parquet"
[7] "8/3/part-0.parquet" "8/5/part-0.parquet"

wrt_dt> ## End(Don't show)
wrt_dt> 
wrt_dt> 
wrt_dt> 
> 
> 
```

## New compilation failure for 14.0.1

```
(arrow) tdhock@maude-MacBookPro:~/src/apache-arrow-14.0.1/cpp/build$ cmake --build .
[1/626] Creating directories for 'jemalloc_ep'
...
[140/626] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/integration/json_internal.cc.o
FAILED: src/arrow/CMakeFiles/arrow_objlib.dir/integration/json_internal.cc.o 
/usr/bin/c++ -DARROW_EXPORTING -DARROW_EXTRA_ERROR_CONTEXT -DARROW_HAVE_RUNTIME_AVX2 -DARROW_HAVE_RUNTIME_AVX512 -DARROW_HAVE_RUNTIME_BMI2 -DARROW_HAVE_RUNTIME_SSE4_2 -DARROW_WITH_BACKTRACE -DARROW_WITH_TIMING_TESTS -DBOOST_ALL_NO_LIB -DURI_STATIC_BUILD -I/home/tdhock/src/apache-arrow-14.0.1/cpp/build/src -I/home/tdhock/src/apache-arrow-14.0.1/cpp/src -I/home/tdhock/src/apache-arrow-14.0.1/cpp/src/generated -isystem /home/tdhock/src/apache-arrow-14.0.1/cpp/thirdparty/flatbuffers/include -isystem /home/tdhock/src/apache-arrow-14.0.1/cpp/thirdparty/hadoop/include -isystem /home/tdhock/.local/share/r-miniconda/envs/arrow/include -isystem /home/tdhock/src/apache-arrow-14.0.1/cpp/build/jemalloc_ep-prefix/src -Wno-noexcept-type  -fdiagnostics-color=always  -Wall -Wno-conversion -Wno-sign-conversion -Wunused-result -Wdate-time -fno-semantic-interposition -march=core2 -g -Werror -O0 -ggdb  -fPIC -pthread -std=c++1z -MD -MT src/arrow/CMakeFiles/arrow_objlib.dir/integration/json_internal.cc.o -MF src/arrow/CMakeFiles/arrow_objlib.dir/integration/json_internal.cc.o.d -o src/arrow/CMakeFiles/arrow_objlib.dir/integration/json_internal.cc.o -c /home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc
In file included from /home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc:50:0:
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/util/range.h: In instantiation of ‘constexpr const arrow::internal::<lambda()> [with I = int]::<unnamed struct> arrow::internal::Enumerate<int>’:
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc:122:50:   required from here
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/util/range.h:256:2: error: call to non-constexpr function ‘arrow::internal::<lambda()> [with I = int]’
 constexpr auto Enumerate = [] {
                            ~~~~
   struct {
   ~~~~~~~~
     struct sentinel {};
     ~~~~~~~~~~~~~~~~~~~
     constexpr sentinel end() const { return {}; }
     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
   
     struct iterator {
     ~~~~~~~~~~~~~~~~~
       I value{0};
       ~~~~~~~~~~~
 
   
       constexpr I operator*() { return value; }
       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
   
       constexpr iterator& operator++() {
       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
         ++value;
         ~~~~~~~~
         return *this;
         ~~~~~~~~~~~~~
       }
       ~
 
   
       constexpr std::true_type operator!=(sentinel) const { return {}; }
       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     };
     ~~
     constexpr iterator begin() const { return {}; }
     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   } out;
   ~~~~~~
 
   
   return out;
   ~~~~~~~~~~~
 }();
 ~^~
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/util/range.h:235:29: note: ‘arrow::internal::<lambda()> [with I = int]’ is not usable as a constexpr function because:
 constexpr auto Enumerate = [] {
                             ^
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/util/range.h:253:5: error: uninitialized variable ‘out’ in ‘constexpr’ function
   } out;
     ^~~
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc: In member function ‘arrow::enable_if_base_binary<T, arrow::Status> arrow::internal::integration::json::{anonymous}::ArrayReader::Visit(const T&)’:
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc:1308:59: error: no matching function for call to ‘quoted(std::string_view&)’
           return Status::Invalid("Value ", std::quoted(val),
                                                           ^
In file included from /home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc:22:0:
/usr/include/c++/7/iomanip:461:5: note: candidate: template<class _CharT> auto std::quoted(const _CharT*, _CharT, _CharT)
     quoted(const _CharT* __string,
     ^~~~~~
/usr/include/c++/7/iomanip:461:5: note:   template argument deduction/substitution failed:
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc:1308:59: note:   mismatched types ‘const _CharT*’ and ‘std::basic_string_view<char>’
           return Status::Invalid("Value ", std::quoted(val),
                                                           ^
In file included from /home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc:22:0:
/usr/include/c++/7/iomanip:470:5: note: candidate: template<class _CharT, class _Traits, class _Alloc> auto std::quoted(const std::__cxx11::basic_string<_CharT, _Traits, _Alloc>&, _CharT, _CharT)
     quoted(const basic_string<_CharT, _Traits, _Alloc>& __string,
     ^~~~~~
/usr/include/c++/7/iomanip:470:5: note:   template argument deduction/substitution failed:
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc:1308:59: note:   ‘std::string_view {aka std::basic_string_view<char>}’ is not derived from ‘const std::__cxx11::basic_string<_CharT, _Traits, _Alloc>’
           return Status::Invalid("Value ", std::quoted(val),
                                                           ^
In file included from /home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc:22:0:
/usr/include/c++/7/iomanip:480:5: note: candidate: template<class _CharT, class _Traits, class _Alloc> auto std::quoted(std::__cxx11::basic_string<_CharT, _Traits, _Alloc>&, _CharT, _CharT)
     quoted(basic_string<_CharT, _Traits, _Alloc>& __string,
     ^~~~~~
/usr/include/c++/7/iomanip:480:5: note:   template argument deduction/substitution failed:
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc:1308:59: note:   ‘std::string_view {aka std::basic_string_view<char>}’ is not derived from ‘std::__cxx11::basic_string<_CharT, _Traits, _Alloc>’
           return Status::Invalid("Value ", std::quoted(val),
                                                           ^
In file included from /home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc:50:0:
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/util/range.h: In instantiation of ‘constexpr const arrow::internal::<lambda()> [with I = unsigned int]::<unnamed struct> arrow::internal::Enumerate<unsigned int>’:
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc:1450:30:   required from ‘arrow::Status arrow::internal::integration::json::{anonymous}::ArrayReader::GetIntArray(const RjArray&, int32_t, std::shared_ptr<arrow::Buffer>*) [with T = unsigned char; RjArray = arrow::rapidjson::GenericArray<true, arrow::rapidjson::GenericValue<arrow::rapidjson::UTF8<> > >; int32_t = int]’
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/integration/json_internal.cc:1521:75:   required from here
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/util/range.h:256:2: error: call to non-constexpr function ‘arrow::internal::<lambda()> [with I = unsigned int]’
 constexpr auto Enumerate = [] {
                            ~~~~
   struct {
   ~~~~~~~~
     struct sentinel {};
     ~~~~~~~~~~~~~~~~~~~
     constexpr sentinel end() const { return {}; }
     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
   
     struct iterator {
     ~~~~~~~~~~~~~~~~~
       I value{0};
       ~~~~~~~~~~~
 
   
       constexpr I operator*() { return value; }
       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
   
       constexpr iterator& operator++() {
       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
         ++value;
         ~~~~~~~~
         return *this;
         ~~~~~~~~~~~~~
       }
       ~
 
   
       constexpr std::true_type operator!=(sentinel) const { return {}; }
       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     };
     ~~
     constexpr iterator begin() const { return {}; }
     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   } out;
   ~~~~~~
 
   
   return out;
   ~~~~~~~~~~~
 }();
 ~^~
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/util/range.h:235:29: note: ‘arrow::internal::<lambda()> [with I = unsigned int]’ is not usable as a constexpr function because:
 constexpr auto Enumerate = [] {
                             ^
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/util/range.h:253:5: error: uninitialized variable ‘out’ in ‘constexpr’ function
   } out;
     ^~~
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/util/range.h: At global scope:
/home/tdhock/src/apache-arrow-14.0.1/cpp/src/arrow/util/range.h:196:12: error: ‘arrow::internal::Zip<std::tuple<_Tps ...>, std::integer_sequence<long unsigned int, __indices ...> >::Zip(Ranges ...) [with Ranges = {const arrow::internal::<lambda()> [with I = unsigned int]::<unnamed struct>&, const arrow::rapidjson::GenericArray<true, arrow::rapidjson::GenericValue<arrow::rapidjson::UTF8<char>, arrow::rapidjson::MemoryPoolAllocator<arrow::rapidjson::CrtAllocator> > >&}; long unsigned int ...I = {0, 1}]’, declared using unnamed type, is used but never defined [-fpermissive]
   explicit Zip(Ranges... ranges) : ranges_(std::forward<Ranges>(ranges)...) {}
            ^~~
[141/626] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/csv/column_builder.cc.o
[142/626] Building CXX object src/arrow/CMakeFiles/arrow_objlib.dir/csv/converter.cc.o
ninja: build stopped: subcommand failed.
```

Looks like cmake is using an old c++ compiler is used above, is that
the reason why the build fails?

```
(arrow) tdhock@maude-MacBookPro:~/src/apache-arrow-13.0.0/cpp/build$ /usr/bin/c++ --version
c++ (Ubuntu 7.5.0-3ubuntu1~18.04) 7.5.0
Copyright (C) 2017 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

(arrow) tdhock@maude-MacBookPro:~/src/apache-arrow-13.0.0/cpp/build$ c++ --version
c++ (GCC) 10.1.0
Copyright (C) 2020 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

(arrow) tdhock@maude-MacBookPro:~/src/apache-arrow-13.0.0/cpp/build$ cmake --version
cmake version 3.22.1

CMake suite maintained and supported by Kitware (kitware.com/cmake).
```

[Building Arrow C++
page](https://arrow.apache.org/docs/developers/cpp/building.html) says
"Building requires: A C++17-enabled compiler. On Linux, gcc 7.1 and
higher should be sufficient...CMake 3.16 or higher" so my setup
satisfies these requirements, which means something about arrow is
incorrect (either the docs or the build code).

Below we see the same problem with arrow 13.0.0:

```
(arrow) tdhock@maude-MacBookPro:~/src/apache-arrow-13.0.0/cpp/build$ cmake --build .
[1/629] Creating directories for 'jemalloc_ep'
...
[254/629] Building CXX object src/arrow/CMakeFiles/arrow_testing_objlib.dir/testing/json_internal.cc.o
FAILED: src/arrow/CMakeFiles/arrow_testing_objlib.dir/testing/json_internal.cc.o 
/usr/bin/c++ -DARROW_EXTRA_ERROR_CONTEXT -DARROW_HAVE_RUNTIME_AVX2 -DARROW_HAVE_RUNTIME_AVX512 -DARROW_HAVE_RUNTIME_BMI2 -DARROW_HAVE_RUNTIME_SSE4_2 -DARROW_TESTING_EXPORTING -DARROW_WITH_TIMING_TESTS -DBOOST_ALL_NO_LIB -DGTEST_LINKED_AS_SHARED_LIBRARY=1 -DURI_STATIC_BUILD -I/home/tdhock/src/apache-arrow-13.0.0/cpp/build/src -I/home/tdhock/src/apache-arrow-13.0.0/cpp/src -I/home/tdhock/src/apache-arrow-13.0.0/cpp/src/generated -isystem /home/tdhock/src/apache-arrow-13.0.0/cpp/thirdparty/flatbuffers/include -isystem /home/tdhock/.local/share/r-miniconda/envs/arrow/include -isystem /home/tdhock/src/apache-arrow-13.0.0/cpp/thirdparty/hadoop/include -isystem /home/tdhock/src/apache-arrow-13.0.0/cpp/build/jemalloc_ep-prefix/src -isystem /home/tdhock/src/apache-arrow-13.0.0/cpp/build/googletest_ep-prefix/include -Wno-noexcept-type  -fdiagnostics-color=always  -Wall -Wno-conversion -Wno-sign-conversion -Wunused-result -Wdate-time -fno-semantic-interposition -march=core2 -g -Werror -O0 -ggdb  -fPIC -pthread -std=c++1z -MD -MT src/arrow/CMakeFiles/arrow_testing_objlib.dir/testing/json_internal.cc.o -MF src/arrow/CMakeFiles/arrow_testing_objlib.dir/testing/json_internal.cc.o.d -o src/arrow/CMakeFiles/arrow_testing_objlib.dir/testing/json_internal.cc.o -c /home/tdhock/src/apache-arrow-13.0.0/cpp/src/arrow/testing/json_internal.cc
In file included from /home/tdhock/src/apache-arrow-13.0.0/cpp/src/arrow/testing/json_internal.cc:50:0:
/home/tdhock/src/apache-arrow-13.0.0/cpp/src/arrow/util/range.h: In instantiation of ‘constexpr const arrow::internal::<lambda()> [with I = int]::<unnamed struct> arrow::internal::Enumerate<int>’:
/home/tdhock/src/apache-arrow-13.0.0/cpp/src/arrow/testing/json_internal.cc:125:50:   required from here
/home/tdhock/src/apache-arrow-13.0.0/cpp/src/arrow/util/range.h:256:2: error: call to non-constexpr function ‘arrow::internal::<lambda()> [with I = int]’
 constexpr auto Enumerate = [] {
                            ~~~~
   struct {
   ~~~~~~~~
     struct sentinel {};
     ~~~~~~~~~~~~~~~~~~~
     constexpr sentinel end() const { return {}; }
     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
   
     struct iterator {
     ~~~~~~~~~~~~~~~~~
       I value{0};
       ~~~~~~~~~~~
 
   
       constexpr I operator*() { return value; }
       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
   
       constexpr iterator& operator++() {
       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
         ++value;
         ~~~~~~~~
         return *this;
         ~~~~~~~~~~~~~
       }
       ~
 
   
       constexpr std::true_type operator!=(sentinel) const { return {}; }
       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     };
     ~~
     constexpr iterator begin() const { return {}; }
     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   } out;
   ~~~~~~
 
   
   return out;
   ~~~~~~~~~~~
 }();
 ~^~
/home/tdhock/src/apache-arrow-13.0.0/cpp/src/arrow/util/range.h:235:29: note: ‘arrow::internal::<lambda()> [with I = int]’ is not usable as a constexpr function because:
 constexpr auto Enumerate = [] {
                             ^
/home/tdhock/src/apache-arrow-13.0.0/cpp/src/arrow/util/range.h:253:5: error: uninitialized variable ‘out’ in ‘constexpr’ function
   } out;
     ^~~
/home/tdhock/src/apache-arrow-13.0.0/cpp/src/arrow/testing/json_internal.cc: In member function ‘arrow::enable_if_base_binary<T, arrow::Status> arrow::testing::json::{anonymous}::ArrayReader::Visit(const T&)’:
/home/tdhock/src/apache-arrow-13.0.0/cpp/src/arrow/testing/json_internal.cc:1343:59: error: no matching function for call to ‘quoted(std::string_view&)’
           return Status::Invalid("Value ", std::quoted(val),
                                                           ^
In file included from /home/tdhock/src/apache-arrow-13.0.0/cpp/src/arrow/testing/json_internal.cc:22:0:
/usr/include/c++/7/iomanip:461:5: note: candidate: template<class _CharT> auto std::quoted(const _CharT*, _CharT, _CharT)
     quoted(const _CharT* __string,
     ^~~~~~
/usr/include/c++/7/iomanip:461:5: note:   template argument deduction/substitution failed:
/home/tdhock/src/apache-arrow-13.0.0/cpp/src/arrow/testing/json_internal.cc:1343:59: note:   mismatched types ‘const _CharT*’ and ‘std::basic_string_view<char>’
           return Status::Invalid("Value ", std::quoted(val),
                                                           ^
In file included from /home/tdhock/src/apache-arrow-13.0.0/cpp/src/arrow/testing/json_internal.cc:22:0:
/usr/include/c++/7/iomanip:470:5: note: candidate: template<class _CharT, class _Traits, class _Alloc> auto std::quoted(const std::__cxx11::basic_string<_CharT, _Traits, _Alloc>&, _CharT, _CharT)
     quoted(const basic_string<_CharT, _Traits, _Alloc>& __string,
     ^~~~~~
/usr/include/c++/7/iomanip:470:5: note:   template argument deduction/substitution failed:
/home/tdhock/src/apache-arrow-13.0.0/cpp/src/arrow/testing/json_internal.cc:1343:59: note:   ‘std::string_view {aka std::basic_string_view<char>}’ is not derived from ‘const std::__cxx11::basic_string<_CharT, _Traits, _Alloc>’
           return Status::Invalid("Value ", std::quoted(val),
                                                           ^
In file included from /home/tdhock/src/apache-arrow-13.0.0/cpp/src/arrow/testing/json_internal.cc:22:0:
/usr/include/c++/7/iomanip:480:5: note: candidate: template<class _CharT, class _Traits, class _Alloc> auto std::quoted(std::__cxx11::basic_string<_CharT, _Traits, _Alloc>&, _CharT, _CharT)
     quoted(basic_string<_CharT, _Traits, _Alloc>& __string,
     ^~~~~~
/usr/include/c++/7/iomanip:480:5: note:   template argument deduction/substitution failed:
/home/tdhock/src/apache-arrow-13.0.0/cpp/src/arrow/testing/json_internal.cc:1343:59: note:   ‘std::string_view {aka std::basic_string_view<char>}’ is not derived from ‘std::__cxx11::basic_string<_CharT, _Traits, _Alloc>’
           return Status::Invalid("Value ", std::quoted(val),
                                                           ^
In file included from /home/tdhock/src/apache-arrow-13.0.0/cpp/src/arrow/testing/json_internal.cc:50:0:
/home/tdhock/src/apache-arrow-13.0.0/cpp/src/arrow/util/range.h: In instantiation of ‘constexpr const arrow::internal::<lambda()> [with I = unsigned int]::<unnamed struct> arrow::internal::Enumerate<unsigned int>’:
/home/tdhock/src/apache-arrow-13.0.0/cpp/src/arrow/testing/json_internal.cc:1485:30:   required from ‘arrow::Status arrow::testing::json::{anonymous}::ArrayReader::GetIntArray(const RjArray&, int32_t, std::shared_ptr<arrow::Buffer>*) [with T = unsigned char; RjArray = arrow::rapidjson::GenericArray<true, arrow::rapidjson::GenericValue<arrow::rapidjson::UTF8<> > >; int32_t = int]’
/home/tdhock/src/apache-arrow-13.0.0/cpp/src/arrow/testing/json_internal.cc:1556:75:   required from here
/home/tdhock/src/apache-arrow-13.0.0/cpp/src/arrow/util/range.h:256:2: error: call to non-constexpr function ‘arrow::internal::<lambda()> [with I = unsigned int]’
 constexpr auto Enumerate = [] {
                            ~~~~
   struct {
   ~~~~~~~~
     struct sentinel {};
     ~~~~~~~~~~~~~~~~~~~
     constexpr sentinel end() const { return {}; }
     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
   
     struct iterator {
     ~~~~~~~~~~~~~~~~~
       I value{0};
       ~~~~~~~~~~~
 
   
       constexpr I operator*() { return value; }
       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
   
       constexpr iterator& operator++() {
       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
         ++value;
         ~~~~~~~~
         return *this;
         ~~~~~~~~~~~~~
       }
       ~
 
   
       constexpr std::true_type operator!=(sentinel) const { return {}; }
       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     };
     ~~
     constexpr iterator begin() const { return {}; }
     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   } out;
   ~~~~~~
 
   
   return out;
   ~~~~~~~~~~~
 }();
 ~^~
/home/tdhock/src/apache-arrow-13.0.0/cpp/src/arrow/util/range.h:235:29: note: ‘arrow::internal::<lambda()> [with I = unsigned int]’ is not usable as a constexpr function because:
 constexpr auto Enumerate = [] {
                             ^
/home/tdhock/src/apache-arrow-13.0.0/cpp/src/arrow/util/range.h:253:5: error: uninitialized variable ‘out’ in ‘constexpr’ function
   } out;
     ^~~
/home/tdhock/src/apache-arrow-13.0.0/cpp/src/arrow/util/range.h: At global scope:
/home/tdhock/src/apache-arrow-13.0.0/cpp/src/arrow/util/range.h:196:12: error: ‘arrow::internal::Zip<std::tuple<_Tps ...>, std::integer_sequence<long unsigned int, __indices ...> >::Zip(Ranges ...) [with Ranges = {const arrow::internal::<lambda()> [with I = unsigned int]::<unnamed struct>&, const arrow::rapidjson::GenericArray<true, arrow::rapidjson::GenericValue<arrow::rapidjson::UTF8<char>, arrow::rapidjson::MemoryPoolAllocator<arrow::rapidjson::CrtAllocator> > >&}; long unsigned int ...I = {0, 1}]’, declared using unnamed type, is used but never defined [-fpermissive]
   explicit Zip(Ranges... ranges) : ranges_(std::forward<Ranges>(ranges)...) {}
            ^~~
[255/629] Building CXX object src/arrow/CMakeFiles/arrow_testing_objlib.dir/testing/gtest_util.cc.o
[256/629] Linking CXX shared library debug/libarrow.so.1300.0.0
ninja: build stopped: subcommand failed.
```

## Comparing build versions?

Above we used ninja-debug-minimal but we may consider using
ninja-release or other,

```
(arrow) tdhock@maude-MacBookPro:~/src/apache-arrow-13.0.0/cpp/build$ cmake .. --list-presets
Available configure presets:

  "ninja-debug-minimal"          - Debug build without anything enabled
  "ninja-debug-basic"            - Debug build with tests and reduced dependencies
...
  "ninja-release-minimal"        - Release build without anything enabled
  "ninja-release-basic"          - Release build with reduced dependencies
  "ninja-release"                - Release build with more optional components
```

ninja-release gives snappy not found error below:

```
(arrow) tdhock@maude-MacBookPro:~/src/apache-arrow-12.0.0/cpp/build$ cmake .. --preset ninja-release -DCMAKE_INSTALL_PREFIX=$HOME -DARROW_CXXFLAGS=-march=core2 -DARROW_PARQUET=ON -DARROW_SIMD_LEVEL=NONE -DCMAKE_INSTALL_RPATH=$HOME/lib64:$HOME/lib:$CONDA_PREFIX/lib -DCMAKE_PREFIX_PATH=$HOME -DCMAKE_FIND_ROOT_PATH=$HOME
Preset CMake variables:

  ARROW_ACERO="ON"
...
-- Found Boost: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/cmake/Boost-1.73.0/BoostConfig.cmake (found suitable version "1.73.0", minimum required is "1.58")  
-- Boost include dir: /home/tdhock/.local/share/r-miniconda/envs/arrow/include
CMake Warning at cmake_modules/FindSnappyAlt.cmake:29 (find_package):
  By not providing "FindSnappy.cmake" in CMAKE_MODULE_PATH this project has
  asked CMake to find a package configuration file provided by "Snappy", but
  CMake did not find one.

  Could not find a package configuration file provided by "Snappy" with any
  of the following names:

    SnappyConfig.cmake
    snappy-config.cmake

  Add the installation prefix of "Snappy" to CMAKE_PREFIX_PATH or set
  "Snappy_DIR" to a directory containing one of the above files.  If "Snappy"
  provides a separate development package or SDK, be sure it has been
  installed.
Call Stack (most recent call first):
  cmake_modules/ThirdpartyToolchain.cmake:286 (find_package)
  cmake_modules/ThirdpartyToolchain.cmake:1305 (resolve_dependency)
  CMakeLists.txt:506 (include)


CMake Error at /home/tdhock/.local/share/r-miniconda/envs/arrow/share/cmake-3.22/Modules/FindPackageHandleStandardArgs.cmake:230 (message):
  Could NOT find SnappyAlt (missing: Snappy_LIB Snappy_INCLUDE_DIR)
Call Stack (most recent call first):
  /home/tdhock/.local/share/r-miniconda/envs/arrow/share/cmake-3.22/Modules/FindPackageHandleStandardArgs.cmake:594 (_FPHSA_FAILURE_MESSAGE)
  cmake_modules/FindSnappyAlt.cmake:93 (find_package_handle_standard_args)
  cmake_modules/ThirdpartyToolchain.cmake:286 (find_package)
  cmake_modules/ThirdpartyToolchain.cmake:1305 (resolve_dependency)
  CMakeLists.txt:506 (include)


-- Configuring incomplete, errors occurred!
```

after that conda install snappy fixed above, we get brotli not found below:

```
(arrow) tdhock@maude-MacBookPro:~/src/apache-arrow-12.0.0/cpp/build$ cmake .. --preset ninja-release -DCMAKE_INSTALL_PREFIX=$HOME -DARROW_CXXFLAGS=-march=core2 -DARROW_PARQUET=ON -DARROW_SIMD_LEVEL=NONE -DCMAKE_INSTALL_RPATH=$HOME/lib64:$HOME/lib:$CONDA_PREFIX/lib -DCMAKE_PREFIX_PATH=$HOME -DCMAKE_FIND_ROOT_PATH=$HOME
...
-- Boost include dir: /home/tdhock/.local/share/r-miniconda/envs/arrow/include
-- Providing CMake module for SnappyAlt as part of Arrow CMake package
-- Checking for modules 'libbrotlicommon;libbrotlienc;libbrotlidec'
--   No package 'libbrotlicommon' found
--   No package 'libbrotlienc' found
--   No package 'libbrotlidec' found
CMake Error at /home/tdhock/.local/share/r-miniconda/envs/arrow/share/cmake-3.22/Modules/FindPackageHandleStandardArgs.cmake:230 (message):
  Could NOT find BrotliAlt (missing: BROTLI_COMMON_LIBRARY BROTLI_ENC_LIBRARY
  BROTLI_DEC_LIBRARY BROTLI_INCLUDE_DIR)
Call Stack (most recent call first):
  /home/tdhock/.local/share/r-miniconda/envs/arrow/share/cmake-3.22/Modules/FindPackageHandleStandardArgs.cmake:594 (_FPHSA_FAILURE_MESSAGE)
  cmake_modules/FindBrotliAlt.cmake:148 (find_package_handle_standard_args)
  cmake_modules/ThirdpartyToolchain.cmake:286 (find_package)
  cmake_modules/ThirdpartyToolchain.cmake:1378 (resolve_dependency)
  CMakeLists.txt:506 (include)


-- Configuring incomplete, errors occurred!
```

conda install brotli fixed above, then we get protobuf not found below

```
(arrow) tdhock@maude-MacBookPro:~/src/apache-arrow-12.0.0/cpp/build$ cmake .. --preset ninja-release -DCMAKE_INSTALL_PREFIX=$HOME -DARROW_CXXFLAGS=-march=core2 -DARROW_PARQUET=ON -DARROW_SIMD_LEVEL=NONE -DCMAKE_INSTALL_RPATH=$HOME/lib64:$HOME/lib:$CONDA_PREFIX/lib -DCMAKE_PREFIX_PATH=$HOME -DCMAKE_FIND_ROOT_PATH=$HOME
...
-- Boost include dir: /home/tdhock/.local/share/r-miniconda/envs/arrow/include
-- Providing CMake module for SnappyAlt as part of Arrow CMake package
-- Checking for modules 'libbrotlicommon;libbrotlienc;libbrotlidec'
--   Found libbrotlicommon, version 1.0.9
--   Found libbrotlienc, version 1.0.9
--   Found libbrotlidec, version 1.0.9
-- Found BrotliAlt: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libbrotlicommon.so  
-- Providing CMake module for BrotliAlt as part of Arrow CMake package
-- Building without OpenSSL support. Minimum OpenSSL version 1.0.2 required.
-- Found thrift: /home/tdhock/.local/share/r-miniconda/envs/arrow
-- Found ZLIB: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libz.so (found version "1.2.13") 
-- Found OpenSSL: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libcrypto.so (found version "1.1.1w")  
-- Found libevent include directory: /home/tdhock/.local/share/r-miniconda/envs/arrow/include
-- Found libevent component: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libevent_core.so
-- Found libevent component: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libevent_extra.so
-- Found libevent component: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libevent_openssl.so
-- Found libevent component: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libevent_pthreads.so
-- Found libevent 2.1.12 in /home/tdhock/.local/share/r-miniconda/envs/arrow
-- Providing CMake module for ThriftAlt as part of Arrow CMake package
-- Found Protobuf: /usr/lib/x86_64-linux-gnu/libprotobuf.so;-pthread (found suitable version "3.0.0", minimum required is "3.0.0") 
-- Providing CMake module for ProtobufAlt as part of Arrow CMake package
CMake Error at cmake_modules/ThirdpartyToolchain.cmake:1804 (message):
  libprotoc was set to Protobuf_PROTOC_LIBRARY-NOTFOUND
Call Stack (most recent call first):
  CMakeLists.txt:506 (include)


-- Configuring incomplete, errors occurred!
```

fix above via [conda install libprotobuf](https://anaconda.org/anaconda/libprotobuf) then got error below:

```
...
-- Found libevent 2.1.12 in /home/tdhock/.local/share/r-miniconda/envs/arrow
-- Providing CMake module for ThriftAlt as part of Arrow CMake package
CMake Warning at /home/tdhock/.local/share/r-miniconda/envs/arrow/share/cmake-3.22/Modules/FindProtobuf.cmake:524 (message):
  Protobuf compiler version 3.20.3 doesn't match library version 3.0.0
Call Stack (most recent call first):
  cmake_modules/FindProtobufAlt.cmake:31 (find_package)
  cmake_modules/ThirdpartyToolchain.cmake:286 (find_package)
  cmake_modules/ThirdpartyToolchain.cmake:1769 (resolve_dependency)
  CMakeLists.txt:506 (include)


-- Providing CMake module for ProtobufAlt as part of Arrow CMake package
-- Found protoc: /home/tdhock/.local/share/r-miniconda/envs/arrow/bin/protoc
-- Building Substrait from source
-- Building jemalloc from source
-- Building (vendored) mimalloc from source
-- RapidJSON found. Headers: /home/tdhock/.local/share/r-miniconda/envs/arrow/include
-- xsimd found. Headers: /home/tdhock/.local/share/r-miniconda/envs/arrow/include
CMake Warning at cmake_modules/Findlz4Alt.cmake:29 (find_package):
  By not providing "Findlz4.cmake" in CMAKE_MODULE_PATH this project has
  asked CMake to find a package configuration file provided by "lz4", but
  CMake did not find one.

  Could not find a package configuration file provided by "lz4" with any of
  the following names:

    lz4Config.cmake
    lz4-config.cmake

  Add the installation prefix of "lz4" to CMAKE_PREFIX_PATH or set "lz4_DIR"
  to a directory containing one of the above files.  If "lz4" provides a
  separate development package or SDK, be sure it has been installed.
Call Stack (most recent call first):
  cmake_modules/ThirdpartyToolchain.cmake:286 (find_package)
  cmake_modules/ThirdpartyToolchain.cmake:2523 (resolve_dependency)
  CMakeLists.txt:506 (include)


-- Checking for module 'liblz4'
--   Found liblz4, version 1.9.4
-- Found lz4Alt: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/liblz4.so  
-- Providing CMake module for lz4Alt as part of Arrow CMake package
-- Providing CMake module for zstdAlt as part of Arrow CMake package
-- Found Zstandard: zstd::libzstd_shared
CMake Warning at cmake_modules/Findre2Alt.cmake:29 (find_package):
  By not providing "Findre2.cmake" in CMAKE_MODULE_PATH this project has
  asked CMake to find a package configuration file provided by "re2", but
  CMake did not find one.

  Could not find a package configuration file provided by "re2" with any of
  the following names:

    re2Config.cmake
    re2-config.cmake

  Add the installation prefix of "re2" to CMAKE_PREFIX_PATH or set "re2_DIR"
  to a directory containing one of the above files.  If "re2" provides a
  separate development package or SDK, be sure it has been installed.
Call Stack (most recent call first):
  cmake_modules/ThirdpartyToolchain.cmake:286 (find_package)
  cmake_modules/ThirdpartyToolchain.cmake:2644 (resolve_dependency)
  CMakeLists.txt:506 (include)


CMake Error at /home/tdhock/.local/share/r-miniconda/envs/arrow/share/cmake-3.22/Modules/FindPackageHandleStandardArgs.cmake:230 (message):
  Could NOT find re2Alt (missing: RE2_LIB RE2_INCLUDE_DIR)
Call Stack (most recent call first):
  /home/tdhock/.local/share/r-miniconda/envs/arrow/share/cmake-3.22/Modules/FindPackageHandleStandardArgs.cmake:594 (_FPHSA_FAILURE_MESSAGE)
  cmake_modules/Findre2Alt.cmake:84 (find_package_handle_standard_args)
  cmake_modules/ThirdpartyToolchain.cmake:286 (find_package)
  cmake_modules/ThirdpartyToolchain.cmake:2644 (resolve_dependency)
  CMakeLists.txt:506 (include)


-- Configuring incomplete, errors occurred!
```

fix above via conda install [lz4](https://anaconda.org/anaconda/lz4) [re2](https://anaconda.org/anaconda/re2), then got error below:

```
(arrow) tdhock@maude-MacBookPro:~/src/apache-arrow-12.0.0/cpp/build$ conda install re2 lz4
Collecting package metadata (current_repodata.json): done
Solving environment: done


==> WARNING: A newer version of conda exists. <==
  current version: 22.9.0
  latest version: 23.11.0

Please update conda by running

    $ conda update -n base -c defaults conda



## Package Plan ##

  environment location: /home/tdhock/.local/share/r-miniconda/envs/arrow

  added / updated specs:
    - lz4
    - re2


The following packages will be downloaded:

    package                    |            build
    ---------------------------|-----------------
    lz4-4.3.2                  |  py310h5eee18b_0          35 KB
    re2-2022.04.01             |       h295c915_0         210 KB
    ------------------------------------------------------------
                                           Total:         245 KB

The following NEW packages will be INSTALLED:

  lz4                pkgs/main/linux-64::lz4-4.3.2-py310h5eee18b_0 None
  re2                pkgs/main/linux-64::re2-2022.04.01-h295c915_0 None


Proceed ([y]/n)? 


Downloading and Extracting Packages
lz4-4.3.2            | 35 KB     | ##################################### | 100% 
re2-2022.04.01       | 210 KB    | ##################################### | 100% 
Preparing transaction: done
Verifying transaction: done
Executing transaction: done
Retrieving notices: ...working... done

(arrow) tdhock@maude-MacBookPro:~/src/apache-arrow-12.0.0/cpp/build$ cmake .. --preset ninja-release -DCMAKE_INSTALL_PREFIX=$HOME -DARROW_CXXFLAGS=-march=core2 -DARROW_PARQUET=ON -DARROW_SIMD_LEVEL=NONE -DCMAKE_INSTALL_RPATH=$HOME/lib64:$HOME/lib:$CONDA_PREFIX/lib -DCMAKE_PREFIX_PATH=$HOME -DCMAKE_FIND_ROOT_PATH=$HOME
...
-- Found protoc: /home/tdhock/.local/share/r-miniconda/envs/arrow/bin/protoc
-- Building Substrait from source
-- Building jemalloc from source
-- Building (vendored) mimalloc from source
-- RapidJSON found. Headers: /home/tdhock/.local/share/r-miniconda/envs/arrow/include
-- xsimd found. Headers: /home/tdhock/.local/share/r-miniconda/envs/arrow/include
CMake Warning at cmake_modules/Findlz4Alt.cmake:29 (find_package):
  By not providing "Findlz4.cmake" in CMAKE_MODULE_PATH this project has
  asked CMake to find a package configuration file provided by "lz4", but
  CMake did not find one.

  Could not find a package configuration file provided by "lz4" with any of
  the following names:

    lz4Config.cmake
    lz4-config.cmake

  Add the installation prefix of "lz4" to CMAKE_PREFIX_PATH or set "lz4_DIR"
  to a directory containing one of the above files.  If "lz4" provides a
  separate development package or SDK, be sure it has been installed.
Call Stack (most recent call first):
  cmake_modules/ThirdpartyToolchain.cmake:286 (find_package)
  cmake_modules/ThirdpartyToolchain.cmake:2523 (resolve_dependency)
  CMakeLists.txt:506 (include)


-- Providing CMake module for lz4Alt as part of Arrow CMake package
-- Providing CMake module for zstdAlt as part of Arrow CMake package
-- Found Zstandard: zstd::libzstd_shared
-- Providing CMake module for re2Alt as part of Arrow CMake package
-- Found BZip2: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libbz2.so (found version "1.0.8") 
-- Looking for BZ2_bzCompressInit
-- Looking for BZ2_bzCompressInit - found
CMake Error at /home/tdhock/.local/share/r-miniconda/envs/arrow/share/cmake-3.22/Modules/FindPackageHandleStandardArgs.cmake:230 (message):
  Could NOT find utf8proc: Found unsuitable version "", but required is at
  least "2.2.0" (found utf8proc_LIB-NOTFOUND)
Call Stack (most recent call first):
  /home/tdhock/.local/share/r-miniconda/envs/arrow/share/cmake-3.22/Modules/FindPackageHandleStandardArgs.cmake:592 (_FPHSA_FAILURE_MESSAGE)
  cmake_modules/Findutf8proc.cmake:107 (find_package_handle_standard_args)
  cmake_modules/ThirdpartyToolchain.cmake:286 (find_package)
  cmake_modules/ThirdpartyToolchain.cmake:2763 (resolve_dependency)
  CMakeLists.txt:506 (include)


-- Configuring incomplete, errors occurred!
```

fix above via [conda install -c conda-forge lz4-c](https://anaconda.org/conda-forge/lz4-c) and [conda install utf8proc](https://anaconda.org/anaconda/utf8proc), then got config success below!

```
(arrow) tdhock@maude-MacBookPro:~/src/apache-arrow-12.0.0/cpp/build$ cmake .. --preset ninja-release -DCMAKE_INSTALL_PREFIX=$HOME -DARROW_CXXFLAGS=-march=core2 -DARROW_PARQUET=ON -DARROW_SIMD_LEVEL=NONE -DCMAKE_INSTALL_RPATH=$HOME/lib64:$HOME/lib:$CONDA_PREFIX/lib -DCMAKE_PREFIX_PATH=$HOME -DCMAKE_FIND_ROOT_PATH=$HOME
Preset CMake variables:

  ARROW_ACERO="ON"
  ARROW_BUILD_STATIC="OFF"
  ARROW_COMPUTE="ON"
  ARROW_CSV="ON"
  ARROW_DATASET="ON"
  ARROW_FILESYSTEM="ON"
  ARROW_JSON="ON"
  ARROW_MIMALLOC="ON"
  ARROW_SUBSTRAIT="ON"
  ARROW_WITH_BROTLI="ON"
  ARROW_WITH_BZ2="ON"
  ARROW_WITH_LZ4="ON"
  ARROW_WITH_RE2="ON"
  ARROW_WITH_SNAPPY="ON"
  ARROW_WITH_UTF8PROC="ON"
  ARROW_WITH_ZLIB="ON"
  ARROW_WITH_ZSTD="ON"
  CMAKE_BUILD_TYPE="Release"

-- Building using CMake version: 3.22.1
-- Arrow version: 12.0.0 (full: '12.0.0')
-- Arrow SO version: 1200 (full: 1200.0.0)
-- clang-tidy 14 not found
-- clang-format 14 not found
-- Could NOT find ClangTools (missing: CLANG_FORMAT_BIN CLANG_TIDY_BIN) 
-- infer not found
fatal: not a git repository (or any parent up to mount point /)
Stopping at filesystem boundary (GIT_DISCOVERY_ACROSS_FILESYSTEM not set).
-- Found cpplint executable at /home/tdhock/src/apache-arrow-12.0.0/cpp/build-support/cpplint.py
-- System processor: x86_64
-- Arrow build warning level: PRODUCTION
-- Using ld linker
-- Build Type: RELEASE
-- Using CONDA approach to find dependencies
-- Using CONDA_PREFIX for ARROW_PACKAGE_PREFIX: /home/tdhock/.local/share/r-miniconda/envs/arrow
-- Setting (unset) dependency *_ROOT variables: /home/tdhock/.local/share/r-miniconda/envs/arrow
-- ARROW_ABSL_BUILD_VERSION: 20211102.0
-- ARROW_ABSL_BUILD_SHA256_CHECKSUM: dcf71b9cba8dc0ca9940c4b316a0c796be8fab42b070bb6b7cab62b48f0e66c4
-- ARROW_AWS_C_AUTH_BUILD_VERSION: v0.6.22
-- ARROW_AWS_C_AUTH_BUILD_SHA256_CHECKSUM: 691a6b4418afcd3dc141351b6ad33fccd8e3ff84df0e9e045b42295d284ee14c
-- ARROW_AWS_C_CAL_BUILD_VERSION: v0.5.20
-- ARROW_AWS_C_CAL_BUILD_SHA256_CHECKSUM: acc352359bd06f8597415c366cf4ec4f00d0b0da92d637039a73323dd55b6cd0
-- ARROW_AWS_C_COMMON_BUILD_VERSION: v0.8.9
-- ARROW_AWS_C_COMMON_BUILD_SHA256_CHECKSUM: 2f3fbaf7c38eae5a00e2a816d09b81177f93529ae8ba1b82dc8f31407565327a
-- ARROW_AWS_C_COMPRESSION_BUILD_VERSION: v0.2.16
-- ARROW_AWS_C_COMPRESSION_BUILD_SHA256_CHECKSUM: 044b1dbbca431a07bde8255ef9ec443c300fc60d4c9408d4b862f65e496687f4
-- ARROW_AWS_C_EVENT_STREAM_BUILD_VERSION: v0.2.18
-- ARROW_AWS_C_EVENT_STREAM_BUILD_SHA256_CHECKSUM: 310ca617f713bf664e4c7485a3d42c1fb57813abd0107e49790d107def7cde4f
-- ARROW_AWS_C_HTTP_BUILD_VERSION: v0.7.3
-- ARROW_AWS_C_HTTP_BUILD_SHA256_CHECKSUM: 07e16c6bf5eba6f0dea96b6f55eae312a7c95b736f4d2e4a210000f45d8265ae
-- ARROW_AWS_C_IO_BUILD_VERSION: v0.13.14
-- ARROW_AWS_C_IO_BUILD_SHA256_CHECKSUM: 12b66510c3d9a4f7e9b714e9cfab2a5bf835f8b9ce2f909d20ae2a2128608c71
-- ARROW_AWS_C_MQTT_BUILD_VERSION: v0.8.4
-- ARROW_AWS_C_MQTT_BUILD_SHA256_CHECKSUM: 232eeac63e72883d460c686a09b98cdd811d24579affac47c5c3f696f956773f
-- ARROW_AWS_C_S3_BUILD_VERSION: v0.2.3
-- ARROW_AWS_C_S3_BUILD_SHA256_CHECKSUM: a00b3c9f319cd1c9aa2c3fa15098864df94b066dcba0deaccbb3caa952d902fe
-- ARROW_AWS_C_SDKUTILS_BUILD_VERSION: v0.1.6
-- ARROW_AWS_C_SDKUTILS_BUILD_SHA256_CHECKSUM: 8a2951344b2fb541eab1e9ca17c18a7fcbfd2aaff4cdd31d362d1fad96111b91
-- ARROW_AWS_CHECKSUMS_BUILD_VERSION: v0.1.13
-- ARROW_AWS_CHECKSUMS_BUILD_SHA256_CHECKSUM: 0f897686f1963253c5069a0e495b85c31635ba146cd3ac38cc2ea31eaf54694d
-- ARROW_AWS_CRT_CPP_BUILD_VERSION: v0.18.16
-- ARROW_AWS_CRT_CPP_BUILD_SHA256_CHECKSUM: 9e69bc1dc4b50871d1038aa9ff6ddeb4c9b28f7d6b5e5b1b69041ccf50a13483
-- ARROW_AWS_LC_BUILD_VERSION: v1.3.0
-- ARROW_AWS_LC_BUILD_SHA256_CHECKSUM: ae96a3567161552744fc0cae8b4d68ed88b1ec0f3d3c98700070115356da5a37
-- ARROW_AWSSDK_BUILD_VERSION: 1.10.55
-- ARROW_AWSSDK_BUILD_SHA256_CHECKSUM: 2d552fb1a84bef4a9b65e34aa7031851ed2aef5319e02cc6e4cb735c48aa30de
-- ARROW_BOOST_BUILD_VERSION: 1.81.0
-- ARROW_BOOST_BUILD_SHA256_CHECKSUM: 9e0ffae35528c35f90468997bc8d99500bf179cbae355415a89a600c38e13574
-- ARROW_BROTLI_BUILD_VERSION: v1.0.9
-- ARROW_BROTLI_BUILD_SHA256_CHECKSUM: f9e8d81d0405ba66d181529af42a3354f838c939095ff99930da6aa9cdf6fe46
-- ARROW_BZIP2_BUILD_VERSION: 1.0.8
-- ARROW_BZIP2_BUILD_SHA256_CHECKSUM: ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269
-- ARROW_CARES_BUILD_VERSION: 1.17.2
-- ARROW_CARES_BUILD_SHA256_CHECKSUM: 4803c844ce20ce510ef0eb83f8ea41fa24ecaae9d280c468c582d2bb25b3913d
-- ARROW_CRC32C_BUILD_VERSION: 1.1.2
-- ARROW_CRC32C_BUILD_SHA256_CHECKSUM: ac07840513072b7fcebda6e821068aa04889018f24e10e46181068fb214d7e56
-- ARROW_GBENCHMARK_BUILD_VERSION: v1.7.1
-- ARROW_GBENCHMARK_BUILD_SHA256_CHECKSUM: 6430e4092653380d9dc4ccb45a1e2dc9259d581f4866dc0759713126056bc1d7
-- ARROW_GFLAGS_BUILD_VERSION: v2.2.2
-- ARROW_GFLAGS_BUILD_SHA256_CHECKSUM: 34af2f15cf7367513b352bdcd2493ab14ce43692d2dcd9dfc499492966c64dcf
-- ARROW_GLOG_BUILD_VERSION: v0.5.0
-- ARROW_GLOG_BUILD_SHA256_CHECKSUM: eede71f28371bf39aa69b45de23b329d37214016e2055269b3b5e7cfd40b59f5
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_VERSION: v2.8.0
-- ARROW_GOOGLE_CLOUD_CPP_BUILD_SHA256_CHECKSUM: 21fb441b5a670a18bb16b6826be8e0530888d0b94320847c538d46f5a54dddbc
-- ARROW_GRPC_BUILD_VERSION: v1.46.3
-- ARROW_GRPC_BUILD_SHA256_CHECKSUM: d6cbf22cb5007af71b61c6be316a79397469c58c82a942552a62e708bce60964
-- ARROW_GTEST_BUILD_VERSION: 1.11.0
-- ARROW_GTEST_BUILD_SHA256_CHECKSUM: b4870bf121ff7795ba20d20bcdd8627b8e088f2d1dab299a031c1034eddc93d5
-- ARROW_JEMALLOC_BUILD_VERSION: 5.3.0
-- ARROW_JEMALLOC_BUILD_SHA256_CHECKSUM: 2db82d1e7119df3e71b7640219b6dfe84789bc0537983c3b7ac4f7189aecfeaa
-- ARROW_LZ4_BUILD_VERSION: v1.9.4
-- ARROW_LZ4_BUILD_SHA256_CHECKSUM: 0b0e3aa07c8c063ddf40b082bdf7e37a1562bda40a0ff5272957f3e987e0e54b
-- ARROW_MIMALLOC_BUILD_VERSION: v2.0.6
-- ARROW_MIMALLOC_BUILD_SHA256_CHECKSUM: 9f05c94cc2b017ed13698834ac2a3567b6339a8bde27640df5a1581d49d05ce5
-- ARROW_NLOHMANN_JSON_BUILD_VERSION: v3.10.5
-- ARROW_NLOHMANN_JSON_BUILD_SHA256_CHECKSUM: 5daca6ca216495edf89d167f808d1d03c4a4d929cef7da5e10f135ae1540c7e4
-- ARROW_OPENTELEMETRY_BUILD_VERSION: v1.8.1
-- ARROW_OPENTELEMETRY_BUILD_SHA256_CHECKSUM: 3d640201594b07f08dade9cd1017bd0b59674daca26223b560b9bb6bf56264c2
-- ARROW_OPENTELEMETRY_PROTO_BUILD_VERSION: v0.17.0
-- ARROW_OPENTELEMETRY_PROTO_BUILD_SHA256_CHECKSUM: f269fbcb30e17b03caa1decd231ce826e59d7651c0f71c3b28eb5140b4bb5412
-- ARROW_ORC_BUILD_VERSION: 1.8.3
-- ARROW_ORC_BUILD_SHA256_CHECKSUM: a78678ec425c8129d63370cb8a9bacb54186aa66af1e2bec01ce92e7eaf72e20
-- ARROW_PROTOBUF_BUILD_VERSION: v21.3
-- ARROW_PROTOBUF_BUILD_SHA256_CHECKSUM: 2f723218f6cb709ae4cdc4fb5ed56a5951fc5d466f0128ce4c946b8c78c8c49f
-- ARROW_RAPIDJSON_BUILD_VERSION: 232389d4f1012dddec4ef84861face2d2ba85709
-- ARROW_RAPIDJSON_BUILD_SHA256_CHECKSUM: b9290a9a6d444c8e049bd589ab804e0ccf2b05dc5984a19ed5ae75d090064806
-- ARROW_RE2_BUILD_VERSION: 2022-06-01
-- ARROW_RE2_BUILD_SHA256_CHECKSUM: f89c61410a072e5cbcf8c27e3a778da7d6fd2f2b5b1445cd4f4508bee946ab0f
-- ARROW_SNAPPY_BUILD_VERSION: 1.1.9
-- ARROW_SNAPPY_BUILD_SHA256_CHECKSUM: 75c1fbb3d618dd3a0483bff0e26d0a92b495bbe5059c8b4f1c962b478b6e06e7
-- ARROW_SUBSTRAIT_BUILD_VERSION: v0.20.0
-- ARROW_SUBSTRAIT_BUILD_SHA256_CHECKSUM: 5ceaa559ccef29a7825b5e5d4b5e7eed384830294f08bec913feecdd903a94cf
-- ARROW_S2N_TLS_BUILD_VERSION: v1.3.35
-- ARROW_S2N_TLS_BUILD_SHA256_CHECKSUM: 9d32b26e6bfcc058d98248bf8fc231537e347395dd89cf62bb432b55c5da990d
-- ARROW_THRIFT_BUILD_VERSION: 0.16.0
-- ARROW_THRIFT_BUILD_SHA256_CHECKSUM: f460b5c1ca30d8918ff95ea3eb6291b3951cf518553566088f3f2be8981f6209
-- ARROW_UCX_BUILD_VERSION: 1.12.1
-- ARROW_UCX_BUILD_SHA256_CHECKSUM: 9bef31aed0e28bf1973d28d74d9ac4f8926c43ca3b7010bd22a084e164e31b71
-- ARROW_UTF8PROC_BUILD_VERSION: v2.7.0
-- ARROW_UTF8PROC_BUILD_SHA256_CHECKSUM: 4bb121e297293c0fd55f08f83afab6d35d48f0af4ecc07523ad8ec99aa2b12a1
-- ARROW_XSIMD_BUILD_VERSION: 9.0.1
-- ARROW_XSIMD_BUILD_SHA256_CHECKSUM: b1bb5f92167fd3a4f25749db0be7e61ed37e0a5d943490f3accdcd2cd2918cc0
-- ARROW_ZLIB_BUILD_VERSION: 1.2.13
-- ARROW_ZLIB_BUILD_SHA256_CHECKSUM: b3a24de97a8fdbc835b9833169501030b8977031bcb54b3b3ac13740f846ab30
-- ARROW_ZSTD_BUILD_VERSION: 1.5.5
-- ARROW_ZSTD_BUILD_SHA256_CHECKSUM: 9c4396cc829cfae319a6e2615202e82aad41372073482fce286fac78646d3ee4
-- Boost include dir: /home/tdhock/.local/share/r-miniconda/envs/arrow/include
-- Providing CMake module for SnappyAlt as part of Arrow CMake package
-- Providing CMake module for BrotliAlt as part of Arrow CMake package
-- Building without OpenSSL support. Minimum OpenSSL version 1.0.2 required.
-- Found thrift: /home/tdhock/.local/share/r-miniconda/envs/arrow
-- Found libevent include directory: /home/tdhock/.local/share/r-miniconda/envs/arrow/include
-- Found libevent component: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libevent_core.so
-- Found libevent component: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libevent_extra.so
-- Found libevent component: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libevent_openssl.so
-- Found libevent component: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libevent_pthreads.so
-- Found libevent 2.1.12 in /home/tdhock/.local/share/r-miniconda/envs/arrow
-- Providing CMake module for ThriftAlt as part of Arrow CMake package
CMake Warning at /home/tdhock/.local/share/r-miniconda/envs/arrow/share/cmake-3.22/Modules/FindProtobuf.cmake:524 (message):
  Protobuf compiler version 3.20.3 doesn't match library version 3.0.0
Call Stack (most recent call first):
  cmake_modules/FindProtobufAlt.cmake:31 (find_package)
  cmake_modules/ThirdpartyToolchain.cmake:286 (find_package)
  cmake_modules/ThirdpartyToolchain.cmake:1769 (resolve_dependency)
  CMakeLists.txt:506 (include)


-- Providing CMake module for ProtobufAlt as part of Arrow CMake package
-- Found protoc: /home/tdhock/.local/share/r-miniconda/envs/arrow/bin/protoc
-- Building Substrait from source
-- Building jemalloc from source
-- Building (vendored) mimalloc from source
-- RapidJSON found. Headers: /home/tdhock/.local/share/r-miniconda/envs/arrow/include
-- xsimd found. Headers: /home/tdhock/.local/share/r-miniconda/envs/arrow/include
CMake Warning at cmake_modules/Findlz4Alt.cmake:29 (find_package):
  By not providing "Findlz4.cmake" in CMAKE_MODULE_PATH this project has
  asked CMake to find a package configuration file provided by "lz4", but
  CMake did not find one.

  Could not find a package configuration file provided by "lz4" with any of
  the following names:

    lz4Config.cmake
    lz4-config.cmake

  Add the installation prefix of "lz4" to CMAKE_PREFIX_PATH or set "lz4_DIR"
  to a directory containing one of the above files.  If "lz4" provides a
  separate development package or SDK, be sure it has been installed.
Call Stack (most recent call first):
  cmake_modules/ThirdpartyToolchain.cmake:286 (find_package)
  cmake_modules/ThirdpartyToolchain.cmake:2523 (resolve_dependency)
  CMakeLists.txt:506 (include)


-- Providing CMake module for lz4Alt as part of Arrow CMake package
-- Providing CMake module for zstdAlt as part of Arrow CMake package
-- Found Zstandard: zstd::libzstd_shared
-- Providing CMake module for re2Alt as part of Arrow CMake package
-- Found utf8proc: /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libutf8proc.so (found suitable version "2.6.1", minimum required is "2.2.0") 
-- Providing CMake module for utf8proc as part of Arrow CMake package
-- Found hdfs.h at: /home/tdhock/src/apache-arrow-12.0.0/cpp/thirdparty/hadoop/include/hdfs.h
-- All bundled static libraries: substrait;jemalloc::jemalloc;mimalloc::mimalloc
-- CMAKE_C_FLAGS:   -Wall -fno-semantic-interposition -march=core2
-- CMAKE_CXX_FLAGS:  -Wno-noexcept-type  -fdiagnostics-color=always  -Wall -fno-semantic-interposition -march=core2
-- CMAKE_C_FLAGS_RELEASE: -O3 -DNDEBUG -O2 -ftree-vectorize
-- CMAKE_CXX_FLAGS_RELEASE: -O3 -DNDEBUG -O2 -ftree-vectorize
-- Looking for backtrace
-- Looking for backtrace - found
-- backtrace facility detected in default set of libraries
-- Found Backtrace: /usr/include  
-- ---------------------------------------------------------------------
-- Arrow version:                                 12.0.0
-- 
-- Build configuration summary:
--   Generator: Ninja
--   Build type: RELEASE
--   Source directory: /home/tdhock/src/apache-arrow-12.0.0/cpp
--   Install prefix: /home/tdhock
-- 
-- Compile and link options:
-- 
--   ARROW_CXXFLAGS=-march=core2 [default=""]
--       Compiler flags to append when compiling Arrow
--   ARROW_BUILD_STATIC=OFF [default=ON]
--       Build static libraries
--   ARROW_BUILD_SHARED=ON [default=ON]
--       Build shared libraries
--   ARROW_PACKAGE_KIND="" [default=""]
--       Arbitrary string that identifies the kind of package
--       (for informational purposes)
--   ARROW_GIT_ID="" [default=""]
--       The Arrow git commit id (if any)
--   ARROW_GIT_DESCRIPTION="" [default=""]
--       The Arrow git commit description (if any)
--   ARROW_NO_DEPRECATED_API=OFF [default=OFF]
--       Exclude deprecated APIs from build
--   ARROW_POSITION_INDEPENDENT_CODE=ON [default=ON]
--       Whether to create position-independent target
--   ARROW_USE_CCACHE=ON [default=ON]
--       Use ccache when compiling (if available)
--   ARROW_USE_SCCACHE=ON [default=ON]
--       Use sccache when compiling (if available),
--       takes precedence over ccache if a storage backend is configured
--   ARROW_USE_LD_GOLD=OFF [default=OFF]
--       Use ld.gold for linking on Linux (if available)
--   ARROW_USE_PRECOMPILED_HEADERS=OFF [default=OFF]
--       Use precompiled headers when compiling
--   ARROW_SIMD_LEVEL=NONE [default=NONE|SSE4_2|AVX2|AVX512|NEON|SVE|SVE128|SVE256|SVE512|DEFAULT]
--       Compile-time SIMD optimization level
--   ARROW_RUNTIME_SIMD_LEVEL=MAX [default=NONE|SSE4_2|AVX2|AVX512|MAX]
--       Max runtime SIMD optimization level
--   ARROW_ALTIVEC=ON [default=ON]
--       Build with Altivec if compiler has support
--   ARROW_RPATH_ORIGIN=OFF [default=OFF]
--       Build Arrow libraries with RATH set to $ORIGIN
--   ARROW_INSTALL_NAME_RPATH=ON [default=ON]
--       Build Arrow libraries with install_name set to @rpath
--   ARROW_GGDB_DEBUG=ON [default=ON]
--       Pass -ggdb flag to debug builds
--   ARROW_WITH_MUSL=OFF [default=OFF]
--       Whether the system libc is musl or not
-- 
-- Test and benchmark options:
-- 
--   ARROW_BUILD_EXAMPLES=OFF [default=OFF]
--       Build the Arrow examples
--   ARROW_BUILD_TESTS=OFF [default=OFF]
--       Build the Arrow googletest unit tests
--   ARROW_ENABLE_TIMING_TESTS=ON [default=ON]
--       Enable timing-sensitive tests
--   ARROW_BUILD_INTEGRATION=OFF [default=OFF]
--       Build the Arrow integration test executables
--   ARROW_BUILD_BENCHMARKS=OFF [default=OFF]
--       Build the Arrow micro benchmarks
--   ARROW_BUILD_BENCHMARKS_REFERENCE=OFF [default=OFF]
--       Build the Arrow micro reference benchmarks
--   ARROW_BUILD_OPENMP_BENCHMARKS=OFF [default=OFF]
--       Build the Arrow benchmarks that rely on OpenMP
--   ARROW_BUILD_DETAILED_BENCHMARKS=OFF [default=OFF]
--       Build benchmarks that do a longer exploration of performance
--   ARROW_TEST_LINKAGE=shared [default=shared|static]
--       Linkage of Arrow libraries with unit tests executables.
--   ARROW_FUZZING=OFF [default=OFF]
--       Build Arrow Fuzzing executables
--   ARROW_LARGE_MEMORY_TESTS=OFF [default=OFF]
--       Enable unit tests which use large memory
-- 
-- Lint options:
-- 
--   ARROW_ONLY_LINT=OFF [default=OFF]
--       Only define the lint and check-format targets
--   ARROW_VERBOSE_LINT=OFF [default=OFF]
--       If off, 'quiet' flags will be passed to linting tools
--   ARROW_GENERATE_COVERAGE=OFF [default=OFF]
--       Build with C++ code coverage enabled
-- 
-- Checks options:
-- 
--   ARROW_TEST_MEMCHECK=OFF [default=OFF]
--       Run the test suite using valgrind --tool=memcheck
--   ARROW_USE_ASAN=OFF [default=OFF]
--       Enable Address Sanitizer checks
--   ARROW_USE_TSAN=OFF [default=OFF]
--       Enable Thread Sanitizer checks
--   ARROW_USE_UBSAN=OFF [default=OFF]
--       Enable Undefined Behavior sanitizer checks
-- 
-- Project component options:
-- 
--   ARROW_BUILD_UTILITIES=OFF [default=OFF]
--       Build Arrow commandline utilities
--   ARROW_COMPUTE=ON [default=OFF]
--       Build all Arrow Compute kernels
--   ARROW_CSV=ON [default=OFF]
--       Build the Arrow CSV Parser Module
--   ARROW_CUDA=OFF [default=OFF]
--       Build the Arrow CUDA extensions (requires CUDA toolkit)
--   ARROW_DATASET=ON [default=OFF]
--       Build the Arrow Dataset Modules
--   ARROW_FILESYSTEM=ON [default=OFF]
--       Build the Arrow Filesystem Layer
--   ARROW_FLIGHT=OFF [default=OFF]
--       Build the Arrow Flight RPC System (requires GRPC, Protocol Buffers)
--   ARROW_FLIGHT_SQL=OFF [default=OFF]
--       Build the Arrow Flight SQL extension
--   ARROW_GANDIVA=OFF [default=OFF]
--       Build the Gandiva libraries
--   ARROW_GCS=OFF [default=OFF]
--       Build Arrow with GCS support (requires the GCloud SDK for C++)
--   ARROW_HDFS=OFF [default=OFF]
--       Build the Arrow HDFS bridge
--   ARROW_IPC=ON [default=ON]
--       Build the Arrow IPC extensions
--   ARROW_JEMALLOC=ON [default=ON]
--       Build the Arrow jemalloc-based allocator
--   ARROW_JSON=ON [default=OFF]
--       Build Arrow with JSON support (requires RapidJSON)
--   ARROW_MIMALLOC=ON [default=OFF]
--       Build the Arrow mimalloc-based allocator
--   ARROW_PARQUET=ON [default=OFF]
--       Build the Parquet libraries
--   ARROW_ORC=OFF [default=OFF]
--       Build the Arrow ORC adapter
--   ARROW_PYTHON=OFF [default=OFF]
--       Build some components needed by PyArrow.
--       (This is a deprecated option. Use CMake presets instead.)
--   ARROW_S3=OFF [default=OFF]
--       Build Arrow with S3 support (requires the AWS SDK for C++)
--   ARROW_SKYHOOK=OFF [default=OFF]
--       Build the Skyhook libraries
--   ARROW_SUBSTRAIT=ON [default=OFF]
--       Build the Arrow Substrait Consumer Module
--   ARROW_ACERO=ON [default=OFF]
--       Build the Arrow Acero Engine Module
--   ARROW_TENSORFLOW=OFF [default=OFF]
--       Build Arrow with TensorFlow support enabled
--   ARROW_TESTING=OFF [default=OFF]
--       Build the Arrow testing libraries
-- 
-- Thirdparty toolchain options:
-- 
--   ARROW_DEPENDENCY_SOURCE=CONDA [default=AUTO|BUNDLED|SYSTEM|CONDA|VCPKG|BREW]
--       Method to use for acquiring arrow's build dependencies
--   ARROW_VERBOSE_THIRDPARTY_BUILD=OFF [default=OFF]
--       Show output from ExternalProjects rather than just logging to files
--   ARROW_DEPENDENCY_USE_SHARED=ON [default=ON]
--       Link to shared libraries
--   ARROW_BOOST_USE_SHARED=ON [default=ON]
--       Rely on Boost shared libraries where relevant
--   ARROW_BROTLI_USE_SHARED=ON [default=ON]
--       Rely on Brotli shared libraries where relevant
--   ARROW_BZ2_USE_SHARED=ON [default=ON]
--       Rely on Bz2 shared libraries where relevant
--   ARROW_GFLAGS_USE_SHARED=ON [default=ON]
--       Rely on GFlags shared libraries where relevant
--   ARROW_GRPC_USE_SHARED=ON [default=ON]
--       Rely on gRPC shared libraries where relevant
--   ARROW_JEMALLOC_USE_SHARED=OFF [default=ON]
--       Rely on jemalloc shared libraries where relevant
--   ARROW_LZ4_USE_SHARED=ON [default=ON]
--       Rely on lz4 shared libraries where relevant
--   ARROW_OPENSSL_USE_SHARED=ON [default=ON]
--       Rely on OpenSSL shared libraries where relevant
--   ARROW_PROTOBUF_USE_SHARED=ON [default=ON]
--       Rely on Protocol Buffers shared libraries where relevant
--   ARROW_SNAPPY_USE_SHARED=ON [default=ON]
--       Rely on snappy shared libraries where relevant
--   ARROW_THRIFT_USE_SHARED=ON [default=ON]
--       Rely on thrift shared libraries where relevant
--   ARROW_UTF8PROC_USE_SHARED=ON [default=ON]
--       Rely on utf8proc shared libraries where relevant
--   ARROW_ZSTD_USE_SHARED=ON [default=ON]
--       Rely on zstd shared libraries where relevant
--   ARROW_USE_GLOG=OFF [default=OFF]
--       Build libraries with glog support for pluggable logging
--   ARROW_WITH_BACKTRACE=ON [default=ON]
--       Build with backtrace support
--   ARROW_WITH_OPENTELEMETRY=OFF [default=OFF]
--       Build libraries with OpenTelemetry support for distributed tracing
--   ARROW_WITH_BROTLI=ON [default=OFF]
--       Build with Brotli compression
--   ARROW_WITH_BZ2=ON [default=OFF]
--       Build with BZ2 compression
--   ARROW_WITH_LZ4=ON [default=OFF]
--       Build with lz4 compression
--   ARROW_WITH_SNAPPY=ON [default=OFF]
--       Build with Snappy compression
--   ARROW_WITH_ZLIB=ON [default=OFF]
--       Build with zlib compression
--   ARROW_WITH_ZSTD=ON [default=OFF]
--       Build with zstd compression
--   ARROW_WITH_UCX=OFF [default=OFF]
--       Build with UCX transport for Arrow Flight
--       (only used if ARROW_FLIGHT is ON)
--   ARROW_WITH_UTF8PROC=ON [default=ON]
--       Build with support for Unicode properties using the utf8proc library
--       (only used if ARROW_COMPUTE is ON or ARROW_GANDIVA is ON)
--   ARROW_WITH_RE2=ON [default=ON]
--       Build with support for regular expressions using the re2 library
--       (only used if ARROW_COMPUTE or ARROW_GANDIVA is ON)
-- 
-- Parquet options:
-- 
--   PARQUET_MINIMAL_DEPENDENCY=OFF [default=OFF]
--       Depend only on Thirdparty headers to build libparquet.
--       Always OFF if building binaries
--   PARQUET_BUILD_EXECUTABLES=OFF [default=OFF]
--       Build the Parquet executable CLI tools. Requires static libraries to be built.
--   PARQUET_BUILD_EXAMPLES=OFF [default=OFF]
--       Build the Parquet examples. Requires static libraries to be built.
--   PARQUET_REQUIRE_ENCRYPTION=OFF [default=OFF]
--       Build support for encryption. Fail if OpenSSL is not found
-- 
-- Gandiva options:
-- 
--   ARROW_GANDIVA_STATIC_LIBSTDCPP=OFF [default=OFF]
--       Include -static-libstdc++ -static-libgcc when linking with
--       Gandiva static libraries
--   ARROW_GANDIVA_PC_CXX_FLAGS="" [default=""]
--       Compiler flags to append when pre-compiling Gandiva operations
-- 
-- Advanced developer options:
-- 
--   ARROW_EXTRA_ERROR_CONTEXT=OFF [default=OFF]
--       Compile with extra error context (line numbers, code)
--   ARROW_OPTIONAL_INSTALL=OFF [default=OFF]
--       If enabled install ONLY targets that have already been built. Please be
--       advised that if this is enabled 'install' will fail silently on components
--       that have not been built
--   ARROW_GDB_INSTALL_DIR="" [default=""]
--       Use a custom install directory for GDB plugin.
--       In general, you don't need to specify this because the default
--       (CMAKE_INSTALL_FULL_BINDIR on Windows, CMAKE_INSTALL_FULL_LIBDIR otherwise)
--       is reasonable.
--   Outputting build configuration summary to /home/tdhock/src/apache-arrow-12.0.0/cpp/build/cmake_summary.json
-- Configuring done
-- Generating done
-- Build files have been written to: /home/tdhock/src/apache-arrow-12.0.0/cpp/build
```

Strangely I get a header not found when building below,

```
(arrow) tdhock@maude-MacBookPro:~/src/apache-arrow-12.0.0/cpp/build$ cmake --build .
[1/363] Creating directories for 'mimalloc_ep'
[2/363] Creating directories for 'substrait_ep'
[3/363] Creating directories for 'jemalloc_ep'
[4/363] Performing download step (download, verify and extract) for 'substrait_ep'
[5/363] No update step for 'substrait_ep'
[6/363] No patch step for 'substrait_ep'
[7/363] No configure step for 'substrait_ep'
[8/363] No build step for 'substrait_ep'
[9/363] No install step for 'substrait_ep'
[10/363] Completed 'substrait_ep'
[11/363] Performing download step (download, verify and extract) for 'mimalloc_ep'
[12/363] Performing download step (download, verify and extract) for 'jemalloc_ep'
[13/363] Generating substrait_ep-generated/substrait/extensions/extensions.pb.cc, substrait_ep-generated/substrait/extensions/extensions.pb.h
[14/363] Generating substrait_ep-generated/substrait/plan.pb.cc, substrait_ep-generated/substrait/plan.pb.h
[15/363] Generating substrait_ep-generated/substrait/extension_rels.pb.cc, substrait_ep-generated/substrait/extension_rels.pb.h
[16/363] No update step for 'jemalloc_ep'
[17/363] Generating substrait_ep-generated/substrait/type.pb.cc, substrait_ep-generated/substrait/type.pb.h
[18/363] No update step for 'mimalloc_ep'
[19/363] No patch step for 'mimalloc_ep'
[20/363] Generating substrait_ep-generated/substrait/algebra.pb.cc, substrait_ep-generated/substrait/algebra.pb.h
[21/363] Performing patch step for 'jemalloc_ep'
[22/363] Building CXX object CMakeFiles/substrait.dir/substrait_ep-generated/substrait/extensions/extensions.pb.cc.o
FAILED: CMakeFiles/substrait.dir/substrait_ep-generated/substrait/extensions/extensions.pb.cc.o 
/usr/bin/c++ -DARROW_HAVE_RUNTIME_AVX2 -DARROW_HAVE_RUNTIME_AVX512 -DARROW_HAVE_RUNTIME_BMI2 -DARROW_HAVE_RUNTIME_SSE4_2 -DARROW_MIMALLOC -DARROW_WITH_RE2 -DARROW_WITH_TIMING_TESTS -DARROW_WITH_UTF8PROC -I/home/tdhock/src/apache-arrow-12.0.0/cpp/build/substrait_ep-generated -I/home/tdhock/src/apache-arrow-12.0.0/cpp/build/src -I/home/tdhock/src/apache-arrow-12.0.0/cpp/src -I/home/tdhock/src/apache-arrow-12.0.0/cpp/src/generated -Wno-noexcept-type  -fdiagnostics-color=always  -Wall -fno-semantic-interposition -march=core2 -O3 -DNDEBUG -O2 -ftree-vectorize -fPIC -std=c++1z -MD -MT CMakeFiles/substrait.dir/substrait_ep-generated/substrait/extensions/extensions.pb.cc.o -MF CMakeFiles/substrait.dir/substrait_ep-generated/substrait/extensions/extensions.pb.cc.o.d -o CMakeFiles/substrait.dir/substrait_ep-generated/substrait/extensions/extensions.pb.cc.o -c /home/tdhock/src/apache-arrow-12.0.0/cpp/build/substrait_ep-generated/substrait/extensions/extensions.pb.cc
In file included from /home/tdhock/src/apache-arrow-12.0.0/cpp/build/substrait_ep-generated/substrait/extensions/extensions.pb.cc:4:0:
/home/tdhock/src/apache-arrow-12.0.0/cpp/build/substrait_ep-generated/substrait/extensions/extensions.pb.h:10:10: fatal error: google/protobuf/port_def.inc: No such file or directory
 #include <google/protobuf/port_def.inc>
          ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
compilation terminated.
[23/363] Building CXX object CMakeFiles/substrait.dir/substrait_ep-generated/substrait/algebra.pb.cc.o
FAILED: CMakeFiles/substrait.dir/substrait_ep-generated/substrait/algebra.pb.cc.o 
/usr/bin/c++ -DARROW_HAVE_RUNTIME_AVX2 -DARROW_HAVE_RUNTIME_AVX512 -DARROW_HAVE_RUNTIME_BMI2 -DARROW_HAVE_RUNTIME_SSE4_2 -DARROW_MIMALLOC -DARROW_WITH_RE2 -DARROW_WITH_TIMING_TESTS -DARROW_WITH_UTF8PROC -I/home/tdhock/src/apache-arrow-12.0.0/cpp/build/substrait_ep-generated -I/home/tdhock/src/apache-arrow-12.0.0/cpp/build/src -I/home/tdhock/src/apache-arrow-12.0.0/cpp/src -I/home/tdhock/src/apache-arrow-12.0.0/cpp/src/generated -Wno-noexcept-type  -fdiagnostics-color=always  -Wall -fno-semantic-interposition -march=core2 -O3 -DNDEBUG -O2 -ftree-vectorize -fPIC -std=c++1z -MD -MT CMakeFiles/substrait.dir/substrait_ep-generated/substrait/algebra.pb.cc.o -MF CMakeFiles/substrait.dir/substrait_ep-generated/substrait/algebra.pb.cc.o.d -o CMakeFiles/substrait.dir/substrait_ep-generated/substrait/algebra.pb.cc.o -c /home/tdhock/src/apache-arrow-12.0.0/cpp/build/substrait_ep-generated/substrait/algebra.pb.cc
In file included from /home/tdhock/src/apache-arrow-12.0.0/cpp/build/substrait_ep-generated/substrait/algebra.pb.cc:4:0:
/home/tdhock/src/apache-arrow-12.0.0/cpp/build/substrait_ep-generated/substrait/algebra.pb.h:10:10: fatal error: google/protobuf/port_def.inc: No such file or directory
 #include <google/protobuf/port_def.inc>
          ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
compilation terminated.
[24/363] Performing configure step for 'mimalloc_ep'
ninja: build stopped: subcommand failed.
```

Try to fix via [conda install protobuf](https://anaconda.org/anaconda/protobuf) then remove build dir, re-configure, re-build below:

```
(arrow) tdhock@maude-MacBookPro:~/src/apache-arrow-12.0.0/cpp/build$ cmake --build .
[1/363] Creating directories for 'jemalloc_ep'
[2/363] Creating directories for 'mimalloc_ep'
[3/363] Creating directories for 'substrait_ep'
[4/363] Performing download step (download, verify and extract) for 'substrait_ep'
[5/363] No update step for 'substrait_ep'
[6/363] No patch step for 'substrait_ep'
[7/363] No configure step for 'substrait_ep'
[8/363] No build step for 'substrait_ep'
[9/363] No install step for 'substrait_ep'
[10/363] Completed 'substrait_ep'
[11/363] Performing download step (download, verify and extract) for 'jemalloc_ep'
[12/363] Generating substrait_ep-generated/substrait/extension_rels.pb.cc, substrait_ep-generated/substrait/extension_rels.pb.h
[13/363] Generating substrait_ep-generated/substrait/extensions/extensions.pb.cc, substrait_ep-generated/substrait/extensions/extensions.pb.h
[14/363] Performing download step (download, verify and extract) for 'mimalloc_ep'
[15/363] Generating substrait_ep-generated/substrait/plan.pb.cc, substrait_ep-generated/substrait/plan.pb.h
[16/363] No update step for 'jemalloc_ep'
[17/363] Performing patch step for 'jemalloc_ep'
[18/363] Generating substrait_ep-generated/substrait/type.pb.cc, substrait_ep-generated/substrait/type.pb.h
[19/363] No update step for 'mimalloc_ep'
[20/363] No patch step for 'mimalloc_ep'
[21/363] Generating substrait_ep-generated/substrait/algebra.pb.cc, substrait_ep-generated/substrait/algebra.pb.h
[22/363] Performing configure step for 'mimalloc_ep'
[23/363] Building CXX object CMakeFiles/substrait.dir/substrait_ep-generated/substrait/extensions/extensions.pb.cc.o
[24/363] Building CXX object CMakeFiles/substrait.dir/substrait_ep-generated/substrait/plan.pb.cc.o
[25/363] Building CXX object CMakeFiles/substrait.dir/substrait_ep-generated/substrait/type.pb.cc.o
[26/363] Building CXX object CMakeFiles/substrait.dir/substrait_ep-generated/substrait/extension_rels.pb.cc.o
[27/363] Performing build step for 'mimalloc_ep'
[28/363] Performing install step for 'mimalloc_ep'
[29/363] Completed 'mimalloc_ep'
[30/363] Building CXX object CMakeFiles/substrait.dir/substrait_ep-generated/substrait/algebra.pb.cc.o
[31/363] Linking CXX static library release/libsubstrait.a
[32/363] Performing configure step for 'jemalloc_ep'
...
```

However building R package says there is an undefined symbol (but ldd
does not say anything is not found), maybe this is because a different
compiler was used for R and for arrow?

```
(arrow) tdhock@maude-MacBookPro:~/src/apache-arrow-12.0.0/cpp/build$ ARROW_PARQUET=true ARROW_R_WITH_PARQUET=true ARROW_DEPENDENCY_SOURCE=SYSTEM ARROW_R_DEV=true LIBARROW_BINARY=false PKG_CONFIG_PATH=$HOME/lib/pkgconfig:$CONDA_PREFIX/lib/pkgconfig R CMD INSTALL ../../r
Loading required package: grDevices
* installing to library ‘/home/tdhock/lib/R/library’
* installing *source* package ‘arrow’ ...
** using staged installation
*** Generating code with data-raw/codegen.R
Loading required package: grDevices
Error in library(decor) : there is no package called ‘decor’
Calls: suppressPackageStartupMessages -> withCallingHandlers -> library
Execution halted
*** Arrow C++ libraries found via pkg-config at /home/tdhock/lib
PKG_CFLAGS=-I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_SUBSTRAIT -DARROW_R_WITH_JSON
PKG_LIBS=-L/home/tdhock/lib -larrow_substrait -larrow_acero -larrow_dataset -lparquet -larrow
** libs
using C++ compiler: ‘g++ (GCC) 10.1.0’
using C++17
make: Nothing to be done for 'all'.
installing to /home/tdhock/lib/R/library/00LOCK-r/00new/arrow/libs
** R
** inst
** byte-compile and prepare package for lazy loading
Loading required package: grDevices
** help
*** installing help indices
** building package indices
Loading required package: grDevices
** installing vignettes
** testing if installed package can be loaded from temporary location
libgcc_s.so.1 must be installed for pthread_cancel to work
Loading required package: grDevices
Error: package or namespace load failed for ‘arrow’ in dyn.load(file, DLLpath = DLLpath, ...):
 unable to load shared object '/home/tdhock/lib/R/library/00LOCK-r/00new/arrow/libs/arrow.so':
  /home/tdhock/lib/libarrow.so.1200: undefined symbol: ZSTD_minCLevel
Error: loading failed
Execution halted
Aborted (core dumped)
ERROR: loading failed
* removing ‘/home/tdhock/lib/R/library/arrow’
* restoring previous ‘/home/tdhock/lib/R/library/arrow’
(arrow) tdhock@maude-MacBookPro:~/src/apache-arrow-12.0.0/cpp/build$ ldd /home/tdhock/lib/libarrow.so
	linux-vdso.so.1 (0x00007ffc02cdc000)
	libbrotlienc.so.1 => /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libbrotlienc.so.1 (0x00007fe495f7e000)
	libbrotlidec.so.1 => /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libbrotlidec.so.1 (0x00007fe495f70000)
	libutf8proc.so.2 => /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libutf8proc.so.2 (0x00007fe495f1b000)
	libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007fe4941d0000)
	librt.so.1 => /lib/x86_64-linux-gnu/librt.so.1 (0x00007fe493fc8000)
	libbz2.so.1.0 => /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libbz2.so.1.0 (0x00007fe495ed9000)
	liblz4.so.1 => /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/liblz4.so.1 (0x00007fe495eab000)
	libsnappy.so.1 => /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libsnappy.so.1 (0x00007fe495e9f000)
	libz.so.1 => /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libz.so.1 (0x00007fe495e81000)
	libzstd.so.1 => /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libzstd.so.1 (0x00007fe493eb8000)
	libre2.so.9 => /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/libre2.so.9 (0x00007fe493e42000)
	libstdc++.so.6 => /home/tdhock/lib64/libstdc++.so.6 (0x00007fe493a6f000)
	libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007fe4936d1000)
	libgcc_s.so.1 => /home/tdhock/lib64/libgcc_s.so.1 (0x00007fe4934b9000)
	libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007fe49329a000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fe492ea9000)
	/lib64/ld-linux-x86-64.so.2 (0x00007fe495df7000)
	libbrotlicommon.so.1 => /home/tdhock/.local/share/r-miniconda/envs/arrow/lib/./libbrotlicommon.so.1 (0x00007fe495e5c000)
```

Below we removed build then specify to use same gcc under home,

```
(arrow) tdhock@maude-MacBookPro:~/src/apache-arrow-12.0.0/cpp/build$ CC=gcc cmake .. --preset ninja-release -DCMAKE_INSTALL_PREFIX=$HOME -DARROW_CXXFLAGS=-march=core2 -DARROW_PARQUET=ON -DARROW_SIMD_LEVEL=NONE -DCMAKE_INSTALL_RPATH=$HOME/lib64:$HOME/lib:$CONDA_PREFIX/lib -DCMAKE_PREFIX_PATH=$HOME -DCMAKE_FIND_ROOT_PATH=$HOME  && grep CMAKE_CXX_COMPILER: CMakeCache.txt
Preset CMake variables:

  ARROW_ACERO="ON"
...
  CMAKE_BUILD_TYPE="Release"

-- Building using CMake version: 3.22.1
-- The C compiler identification is GNU 10.1.0
-- The CXX compiler identification is GNU 10.1.0
-- Detecting C compiler ABI info
-- Detecting C compiler ABI info - done
-- Check for working C compiler: /home/tdhock/bin/gcc - skipped
...
-- Build files have been written to: /home/tdhock/src/apache-arrow-12.0.0/cpp/build
CMAKE_CXX_COMPILER:FILEPATH=/home/tdhock/bin/c++
```

The build above worked, but the R package installation below still failed, which indicates the compiler was not the issue:

```
(arrow) tdhock@maude-MacBookPro:~/src/apache-arrow-12.0.0/cpp/build$ ARROW_PARQUET=true ARROW_R_WITH_PARQUET=true ARROW_DEPENDENCY_SOURCE=SYSTEM ARROW_R_DEV=true LIBARROW_BINARY=false PKG_CONFIG_PATH=$HOME/lib/pkgconfig:$CONDA_PREFIX/lib/pkgconfig R CMD INSTALL ../../r
Loading required package: grDevices
* installing to library ‘/home/tdhock/lib/R/library’
* installing *source* package ‘arrow’ ...
** using staged installation
*** Generating code with data-raw/codegen.R
Loading required package: grDevices
Error in library(decor) : there is no package called ‘decor’
Calls: suppressPackageStartupMessages -> withCallingHandlers -> library
Execution halted
*** Arrow C++ libraries found via pkg-config at /home/tdhock/lib
PKG_CFLAGS=-I/home/tdhock/include  -DARROW_R_WITH_PARQUET -DARROW_R_WITH_DATASET -DARROW_R_WITH_ACERO -DARROW_R_WITH_SUBSTRAIT -DARROW_R_WITH_JSON
PKG_LIBS=-L/home/tdhock/lib -larrow_substrait -larrow_acero -larrow_dataset -lparquet -larrow
** libs
using C++ compiler: ‘g++ (GCC) 10.1.0’
using C++17
make: Nothing to be done for 'all'.
installing to /home/tdhock/lib/R/library/00LOCK-r/00new/arrow/libs
** R
** inst
** byte-compile and prepare package for lazy loading
Loading required package: grDevices
** help
*** installing help indices
** building package indices
Loading required package: grDevices
** installing vignettes
** testing if installed package can be loaded from temporary location
libgcc_s.so.1 must be installed for pthread_cancel to work
Loading required package: grDevices
Error: package or namespace load failed for ‘arrow’ in dyn.load(file, DLLpath = DLLpath, ...):
 unable to load shared object '/home/tdhock/lib/R/library/00LOCK-r/00new/arrow/libs/arrow.so':
  /home/tdhock/lib/libarrow.so.1200: undefined symbol: ZSTD_minCLevel
Error: loading failed
Execution halted
Aborted (core dumped)
ERROR: loading failed
* removing ‘/home/tdhock/lib/R/library/arrow’
* restoring previous ‘/home/tdhock/lib/R/library/arrow’
```

The issue must be something in the release build. Better to stick with
ninja-debug-basic.

## Conclusions

* Download release (12 is most recent which compiles on my old MacBook
  Pro circa 2010) from https://arrow.apache.org/release/ save under
  ~/src
* cd ~/src, tar xf arrow.tar.gz, cd arrow-version/cpp, mkdir build, cd build, conda activate arrow, 
* `cmake .. --preset ninja-debug-basic -DCMAKE_INSTALL_PREFIX=$HOME -DARROW_CXXFLAGS=-march=core2 -DARROW_PARQUET=ON -DARROW_SIMD_LEVEL=NONE -DCMAKE_INSTALL_RPATH=$HOME/lib64:$HOME/lib:$CONDA_PREFIX/lib -DCMAKE_PREFIX_PATH=$HOME -DCMAKE_FIND_ROOT_PATH=$HOME`
* `cmake --build .`
* `cmake --install .`
* `ARROW_PARQUET=true ARROW_R_WITH_PARQUET=true ARROW_DEPENDENCY_SOURCE=SYSTEM ARROW_R_DEV=true LIBARROW_BINARY=false PKG_CONFIG_PATH=$HOME/lib/pkgconfig:$CONDA_PREFIX/lib/pkgconfig R CMD INSTALL ../../r`
* Need `cmake -DARROW_CXXFLAGS=-march=core2 ...` to tell cmake to use
  core2 gcc compilation flag. 
* Need `cmake -DARROW_SIMD_LEVEL=NONE ...` to tell cmake to not use
  `-msse4.2` gcc compilation flag.
* Need `cmake -DCMAKE_INSTALL_RPATH=$HOME/lib64:$HOME/lib:$CONDA_PREFIX/lib ...`
  to tell cmake to link against libraries installed in non-standard
  directories.
* When using gcc installed under home directory, need to tell R at
  compilation or in `~/.R/Makevars` to link to libraries in `~/lib`.
* Avoid installing pre-built arrow binaries on older CPUs.
* Need to carefully read the libarrow installation docs, to see how to
  configure the build for older CPUs.
* Arrow R package and build system could have better CPU detection and
  error messages to avoid these installation hassles.
