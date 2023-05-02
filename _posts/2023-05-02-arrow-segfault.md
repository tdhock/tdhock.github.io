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
