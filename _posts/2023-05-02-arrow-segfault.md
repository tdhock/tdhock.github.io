---
layout: post
title: Segfault using R arrow
description: Reproducing an error
---

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

