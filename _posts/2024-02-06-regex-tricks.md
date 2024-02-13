---
layout: post
title: Capturing regular expressions
description: Extracting data from loosely structured text
---



The goal of this blog post is to explain a couple of interesting
regular expression parsing techniques that were useful in my recent
work.

## nc intro

`nc` is my R package for named capture regular expressions (regex). It
provides functions that make it easy to capture data from regularly
structured text, and output a data table.  For example, we can
consider the problem of converting a typical text representation of
elapsed time, `98:76:54` (98 hours, 76 minutes, 54 seconds) to a
numeric variable. Below we define the text data to parse, which is
called a "subject" in the context of regex matching:


```r
elapsed.subject <- c("98:76:54","01:23:45")
```

Next we define a regex sub-pattern to match an integer,


```r
int.pattern <- list("[0-9]+", as.integer)
```

Note in the code above that we define the regex sub-pattern as a list
in R, which combines the pattern string with a conversion function.
Next we use that sub-pattern list three times to create an overall
pattern for matching to the subject/time text,


```r
elapsed.pattern <- list(
  hours=int.pattern, ":",
  minutes=int.pattern, ":",
  seconds=int.pattern)
```

The pattern is defined in the code above as a list with five
elements. Each of the three named elements becomes a capture group,
and the name is used as a column name in the output (see below). The
two un-named elements (both colons) define text to match between the
capture groups. All elements of the pattern list are concatenated to
obtain the final regex which is matched to each subject, using the
code below.


```r
(elapsed.dt <- nc::capture_first_vec(elapsed.subject, elapsed.pattern))
```

```
##    hours minutes seconds
##    <int>   <int>   <int>
## 1:    98      76      54
## 2:     1      23      45
```

The output above is a data table with one row per subject, and one
column per capture group. Each column is an integer, because
`as.integer` was specified as the type conversion for `int.pattern` in
the code above. To compute the overall time, we can use the code below,


```r
elapsed.dt[
  , overall.minutes := seconds/60+minutes+hours*60
][]
```

```
##    hours minutes seconds overall.minutes
##    <int>   <int>   <int>           <num>
## 1:    98      76      54         5956.90
## 2:     1      23      45           83.75
```

## Parsing log files

Now suppose we have a bunch of log files, created from using the time
command, as below.


```r
R.commands <- c('R.version','library(nc);example(capture_all_str)')
log.subject <- character()
for(cmd.i in seq_along(R.commands)){
  R.cmd <- R.commands[[cmd.i]]
  time.cmd <- sprintf("time R -e '%s' 2>&1", R.cmd)
  log.lines <- system(time.cmd, intern=TRUE)
  print(tail(log.lines))
  log.subject[[R.cmd]] <- paste(log.lines, collapse="\n")
}
```

```
## [1] "version.string R version 4.3.2 (2023-10-31)"                                    
## [2] "nickname       Eye Holes                   "                                    
## [3] "> "                                                                             
## [4] "> "                                                                             
## [5] "0.54user 0.06system 0:00.61elapsed 99%CPU (0avgtext+0avgdata 52668maxresident)k"
## [6] "0inputs+8outputs (2major+13316minor)pagefaults 0swaps"                          
## [1] "2: Transformation introduced infinite values in continuous x-axis "              
## [2] "3: Transformation introduced infinite values in continuous x-axis "              
## [3] "> "                                                                              
## [4] "> "                                                                              
## [5] "6.72user 0.23system 0:07.03elapsed 98%CPU (0avgtext+0avgdata 126084maxresident)k"
## [6] "0inputs+56outputs (2major+30902minor)pagefaults 0swaps"
```

Above we see the last few lines in each time command log.
The timings shown are in seconds (for user, system, elapsed).
Another way to view the data is via the last few characters of each log, via the code below.


```r
substr(log.subject, nchar(log.subject)-150, nchar(log.subject))
```

```
##                                                                                                                                                     R.version 
## "           \n> \n> \n0.54user 0.06system 0:00.61elapsed 99%CPU (0avgtext+0avgdata 52668maxresident)k\n0inputs+8outputs (2major+13316minor)pagefaults 0swaps" 
##                                                                                                                          library(nc);example(capture_all_str) 
## "s x-axis \n> \n> \n6.72user 0.23system 0:07.03elapsed 98%CPU (0avgtext+0avgdata 126084maxresident)k\n0inputs+56outputs (2major+30902minor)pagefaults 0swaps"
```

In both cases above, we see the number of seconds is a numeric variable with a decimal point.
Below we define a pattern to match a numeric variable encoded in text,


```r
num.pattern <- list("[0-9.]+", as.numeric)
```

Below we combine the sub-pattern above with a suffix to get a first
partial match. Note that we use `capture_all_str` inside of
`by=R.cmd`, so that it is run for each unique value of `R.cmd`. Since
the log files have the same name as the command that was run,
`capture_all_str` will read each log file, and find each 


```r
user.pattern <- list(user=num.pattern, "user")
nc::capture_first_vec(log.subject, user.pattern)
```

```
##     user
##    <num>
## 1:  0.54
## 2:  6.72
```

The output above is a data table with one row per log file, and one
column per capture group defined in the regex.  Below we define a more
complex pattern, to additionally capture the system time,


```r
user.system.pattern <- list(user.pattern, " ", system=num.pattern, "system")
nc::capture_first_vec(log.subject, user.system.pattern)
```

```
##     user system
##    <num>  <num>
## 1:  0.54   0.06
## 2:  6.72   0.23
```

Exercise for the reader: modify the pattern to additional capture
elapsed, CPU, etc.

## Parsing multi-line log files

Now suppose we had to parse POSIX instead of GNU time, as in the code
below, which includes the `-p` flag to `time`.


```r
posix.subject <- character()
for(cmd.i in seq_along(R.commands)){
  R.cmd <- R.commands[[cmd.i]]
  time.cmd <- sprintf("time -p R -e '%s' 2>&1", R.cmd)
  log.lines <- system(time.cmd, intern=TRUE)
  print(tail(log.lines))
  posix.subject[[R.cmd]] <- paste(log.lines, collapse="\n")
}
```

```
## [1] "nickname       Eye Holes                   " "> "                                         
## [3] "> "                                          "real 0.68"                                  
## [5] "user 0.56"                                   "sys 0.06"                                   
## [1] "3: Transformation introduced infinite values in continuous x-axis "
## [2] "> "                                                                
## [3] "> "                                                                
## [4] "real 6.98"                                                         
## [5] "user 6.75"                                                         
## [6] "sys 0.14"
```

Another way to view the data is via the last few characters of each
log, via the code below.


```r
substr(posix.subject, nchar(posix.subject)-50, nchar(posix.subject))
```

```
##                                                  R.version                       library(nc);example(capture_all_str) 
## "                \n> \n> \nreal 0.68\nuser 0.56\nsys 0.06" "ntinuous x-axis \n> \n> \nreal 6.98\nuser 6.75\nsys 0.14"
```

Again we can parse using a regex, which we begin to build in the code below.


```r
real.pattern <- list("real ", real=num.pattern)
nc::capture_first_vec(posix.subject, real.pattern)
```

```
##     real
##    <num>
## 1:  0.68
## 2:  6.98
```

We build a more complex regex in the code below,


```r
real.user.pattern <- list(real.pattern, "\nuser ", user=num.pattern)
nc::capture_first_vec(posix.subject, real.user.pattern)
```

```
##     real  user
##    <num> <num>
## 1:  0.68  0.56
## 2:  6.98  6.75
```

Exercise for the reader: create a more complex regex that additionally
matches the sys time.

## Parse all times in log 

In the last sections, we created a new pattern for each of the
times. But is it possible to have a single regex that matches all of
the times? Yes! We can use `capture_all_str`, which inputs a text
string (or file) to parse with a regex. To get that to work with
multiple subjects, each which is a multi-line log string/file, we need
to use it inside of a data table `by` clause, as below,


```r
data.table(R.cmd=R.commands)[, nc::capture_all_str(
  posix.subject[[R.cmd]], type="real|user|sys", " ", seconds=num.pattern
), by=R.cmd]
```

```
##                                   R.cmd   type seconds
##                                  <char> <char>   <num>
## 1:                            R.version   real    0.68
## 2:                            R.version   user    0.56
## 3:                            R.version    sys    0.06
## 4: library(nc);example(capture_all_str)   real    6.98
## 5: library(nc);example(capture_all_str)   user    6.75
## 6: library(nc);example(capture_all_str)    sys    0.14
```

Exercise for the reader: do something similar with `log.subject`
instead of `posix.subject`.

## More complex regex 

For a more challenging example, let us consider data from python doc
strings, taken from torchvision.


```r
doc.strings <- c('`The Rendered SST2 Dataset <https://github.com/openai/CLIP/blob/main/data/rendered-sst2.md>`_.\n\n    Rendered SST2 is an image classification dataset used to evaluate the models capability on optical\n    character recognition. This dataset was generated by rendering sentences in the Standford Sentiment\n    Treebank v2 dataset.\n\n    This dataset contains two classes (positive and negative) and is divided in three splits: a  train\n    split containing 6920 images (3610 positive and 3310 negative), a validation split containing 872 images\n    (444 positive and 428 negative), and a test split containing 1821 images (909 positive and 912 negative).\n\n    Args:\n        root (string): Root directory of the dataset.\n        split (string, optional): The dataset split, supports ``"train"`` (default), `"val"` and ``"test"``.\n        transform (callable, optional): A function/transform that  takes in an PIL image and returns a transformed\n            version. E.g, ``transforms.RandomCrop``.\n        target_transform (callable, optional): A function/transform that takes in the target and transforms it.\n        download (bool, optional): If True, downloads the dataset from the internet and\n            puts it in root directory. If dataset is already downloaded, it is not\n            downloaded again. Default is False.\n    ', "`WIDERFace <http://shuoyang1213.me/WIDERFACE/>`_ Dataset.\n\n    Args:\n        root (string): Root directory where images and annotations are downloaded to.\n            Expects the following folder structure if download=False:\n\n            .. code::\n\n                <root>\n                    \u2514\u2500\u2500 widerface\n                        \u251c\u2500\u2500 wider_face_split ('wider_face_split.zip' if compressed)\n                        \u251c\u2500\u2500 WIDER_train ('WIDER_train.zip' if compressed)\n                        \u251c\u2500\u2500 WIDER_val ('WIDER_val.zip' if compressed)\n                        \u2514\u2500\u2500 WIDER_test ('WIDER_test.zip' if compressed)\n        split (string): The dataset split to use. One of {``train``, ``val``, ``test``}.\n            Defaults to ``train``.\n        transform (callable, optional): A function/transform that  takes in a PIL image\n            and returns a transformed version. E.g, ``transforms.RandomCrop``\n        target_transform (callable, optional): A function/transform that takes in the\n            target and transforms it.\n        download (bool, optional): If true, downloads the dataset from the internet and\n            puts it in root directory. If dataset is already downloaded, it is not\n            downloaded again.\n\n    ", '`EMNIST <https://www.westernsydney.edu.au/bens/home/reproducible_research/emnist>`_ Dataset.\n\n    Args:\n        root (string): Root directory of dataset where ``EMNIST/raw/train-images-idx3-ubyte``\n            and  ``EMNIST/raw/t10k-images-idx3-ubyte`` exist.\n        split (string): The dataset has 6 different splits: ``byclass``, ``bymerge``,\n            ``balanced``, ``letters``, ``digits`` and ``mnist``. This argument specifies\n            which one to use.\n        train (bool, optional): If True, creates dataset from ``training.pt``,\n            otherwise from ``test.pt``.\n        download (bool, optional): If True, downloads the dataset from the internet and\n            puts it in root directory. If dataset is already downloaded, it is not\n            downloaded again.\n        transform (callable, optional): A function/transform that  takes in an PIL image\n            and returns a transformed version. E.g, ``transforms.RandomCrop``\n        target_transform (callable, optional): A function/transform that takes in the\n            target and transforms it.\n    ')
cat(doc.strings, sep="\n\n-----\n\n")
```

```
## `The Rendered SST2 Dataset <https://github.com/openai/CLIP/blob/main/data/rendered-sst2.md>`_.
## 
##     Rendered SST2 is an image classification dataset used to evaluate the models capability on optical
##     character recognition. This dataset was generated by rendering sentences in the Standford Sentiment
##     Treebank v2 dataset.
## 
##     This dataset contains two classes (positive and negative) and is divided in three splits: a  train
##     split containing 6920 images (3610 positive and 3310 negative), a validation split containing 872 images
##     (444 positive and 428 negative), and a test split containing 1821 images (909 positive and 912 negative).
## 
##     Args:
##         root (string): Root directory of the dataset.
##         split (string, optional): The dataset split, supports ``"train"`` (default), `"val"` and ``"test"``.
##         transform (callable, optional): A function/transform that  takes in an PIL image and returns a transformed
##             version. E.g, ``transforms.RandomCrop``.
##         target_transform (callable, optional): A function/transform that takes in the target and transforms it.
##         download (bool, optional): If True, downloads the dataset from the internet and
##             puts it in root directory. If dataset is already downloaded, it is not
##             downloaded again. Default is False.
##     
## 
## -----
## 
## `WIDERFace <http://shuoyang1213.me/WIDERFACE/>`_ Dataset.
## 
##     Args:
##         root (string): Root directory where images and annotations are downloaded to.
##             Expects the following folder structure if download=False:
## 
##             .. code::
## 
##                 <root>
##                     └── widerface
##                         ├── wider_face_split ('wider_face_split.zip' if compressed)
##                         ├── WIDER_train ('WIDER_train.zip' if compressed)
##                         ├── WIDER_val ('WIDER_val.zip' if compressed)
##                         └── WIDER_test ('WIDER_test.zip' if compressed)
##         split (string): The dataset split to use. One of {``train``, ``val``, ``test``}.
##             Defaults to ``train``.
##         transform (callable, optional): A function/transform that  takes in a PIL image
##             and returns a transformed version. E.g, ``transforms.RandomCrop``
##         target_transform (callable, optional): A function/transform that takes in the
##             target and transforms it.
##         download (bool, optional): If true, downloads the dataset from the internet and
##             puts it in root directory. If dataset is already downloaded, it is not
##             downloaded again.
## 
##     
## 
## -----
## 
## `EMNIST <https://www.westernsydney.edu.au/bens/home/reproducible_research/emnist>`_ Dataset.
## 
##     Args:
##         root (string): Root directory of dataset where ``EMNIST/raw/train-images-idx3-ubyte``
##             and  ``EMNIST/raw/t10k-images-idx3-ubyte`` exist.
##         split (string): The dataset has 6 different splits: ``byclass``, ``bymerge``,
##             ``balanced``, ``letters``, ``digits`` and ``mnist``. This argument specifies
##             which one to use.
##         train (bool, optional): If True, creates dataset from ``training.pt``,
##             otherwise from ``test.pt``.
##         download (bool, optional): If True, downloads the dataset from the internet and
##             puts it in root directory. If dataset is already downloaded, it is not
##             downloaded again.
##         transform (callable, optional): A function/transform that  takes in an PIL image
##             and returns a transformed version. E.g, ``transforms.RandomCrop``
##         target_transform (callable, optional): A function/transform that takes in the
##             target and transforms it.
## 
```

There is some structure in these doc strings, so it is possible to
parse them using regex.

* Title and URL on first line.
* optional multi-line description below.
* Args: section below.
* Each arg name (type): description.

Here we focus just on parsing each argument (others are exercises for the reader).
The pattern is relatively straightforward, if we want to just get one line:


```r
before.name <- " +"
name.pattern <- "[^ ]+"
after.name <- " [(]"
name.type.pattern <- list(before.name, name=name.pattern, after.name, type=".*?", "[)]: ")
nc::capture_all_str(doc.strings, name.type.pattern, description=".*")
```

```
##                 name               type                                                                description
##               <char>             <char>                                                                     <char>
##  1:             root             string                                             Root directory of the dataset.
##  2:            split   string, optional The dataset split, supports ``"train"`` (default), `"val"` and ``"test"``.
##  3:        transform callable, optional A function/transform that  takes in an PIL image and returns a transformed
##  4: target_transform callable, optional           A function/transform that takes in the target and transforms it.
##  5:         download     bool, optional                       If True, downloads the dataset from the internet and
##  6:             root             string             Root directory where images and annotations are downloaded to.
##  7:            split             string           The dataset split to use. One of {``train``, ``val``, ``test``}.
##  8:        transform callable, optional                            A function/transform that  takes in a PIL image
##  9: target_transform callable, optional                                     A function/transform that takes in the
## 10:         download     bool, optional                       If true, downloads the dataset from the internet and
## 11:             root             string     Root directory of dataset where ``EMNIST/raw/train-images-idx3-ubyte``
## 12:            split             string              The dataset has 6 different splits: ``byclass``, ``bymerge``,
## 13:            train     bool, optional                             If True, creates dataset from ``training.pt``,
## 14:         download     bool, optional                       If True, downloads the dataset from the internet and
## 15:        transform callable, optional                           A function/transform that  takes in an PIL image
## 16: target_transform callable, optional                                     A function/transform that takes in the
```

But what if we want to get all of the lines of the description? We
could try a multi-line greedy match, but that gives us only one row
with too much in the description.


```r
str(nc::capture_all_str(doc.strings, name.type.pattern, description="(?:.*\n)*"))
```

```
## Classes 'data.table' and 'data.frame':	1 obs. of  3 variables:
##  $ name       : chr "root"
##  $ type       : chr "string"
##  $ description: chr "Root directory of the dataset.\n        split (string, optional): The dataset split, supports ``\"train\"`` (de"| __truncated__
##  - attr(*, ".internal.selfref")=<externalptr>
```

The trick to getting this to work is to be more specific about what
kinds of lines are allowed to match in the description. Basically, we
can add a line if it is not going to match another argument. To do
that we need negative lookahead.


```r
not.arg <- list(
  "(?!",#negative lookahead, makes match fail if another argument name on this line.
  before.name, name.pattern, after.name, ")")
desc.pattern <- list(description=list(
  ".*\n",#first line
  nc::quantifier(not.arg, ".*\n", "*")))
arg.dt <- nc::capture_all_str(doc.strings, name.type.pattern, desc.pattern)
arg.dt[, .(name, type, desc=substr(description, 1, 40))]
```

```
##                 name               type                                      desc
##               <char>             <char>                                    <char>
##  1:             root             string          Root directory of the dataset.\n
##  2:            split   string, optional  The dataset split, supports ``"train"`` 
##  3:        transform callable, optional  A function/transform that  takes in an P
##  4: target_transform callable, optional  A function/transform that takes in the t
##  5:         download     bool, optional  If True, downloads the dataset from the 
##  6:             root             string  Root directory where images and annotati
##  7:            split             string  The dataset split to use. One of {``trai
##  8:        transform callable, optional  A function/transform that  takes in a PI
##  9: target_transform callable, optional A function/transform that takes in the\n 
## 10:         download     bool, optional  If true, downloads the dataset from the 
## 11:             root             string  Root directory of dataset where ``EMNIST
## 12:            split             string  The dataset has 6 different splits: ``by
## 13:            train     bool, optional  If True, creates dataset from ``training
## 14:         download     bool, optional  If True, downloads the dataset from the 
## 15:        transform callable, optional  A function/transform that  takes in an P
## 16: target_transform callable, optional A function/transform that takes in the\n
```

```r
arg.dt[, cat(sprintf("%s (%s): %s", name, type, description),sep="\n")]
```

```
## root (string): Root directory of the dataset.
## 
## split (string, optional): The dataset split, supports ``"train"`` (default), `"val"` and ``"test"``.
## 
## transform (callable, optional): A function/transform that  takes in an PIL image and returns a transformed
##             version. E.g, ``transforms.RandomCrop``.
## 
## target_transform (callable, optional): A function/transform that takes in the target and transforms it.
## 
## download (bool, optional): If True, downloads the dataset from the internet and
##             puts it in root directory. If dataset is already downloaded, it is not
##             downloaded again. Default is False.
##     
## `WIDERFace <http://shuoyang1213.me/WIDERFACE/>`_ Dataset.
## 
##     Args:
## 
## root (string): Root directory where images and annotations are downloaded to.
##             Expects the following folder structure if download=False:
## 
##             .. code::
## 
##                 <root>
##                     └── widerface
##                         ├── wider_face_split ('wider_face_split.zip' if compressed)
##                         ├── WIDER_train ('WIDER_train.zip' if compressed)
##                         ├── WIDER_val ('WIDER_val.zip' if compressed)
##                         └── WIDER_test ('WIDER_test.zip' if compressed)
## 
## split (string): The dataset split to use. One of {``train``, ``val``, ``test``}.
##             Defaults to ``train``.
## 
## transform (callable, optional): A function/transform that  takes in a PIL image
##             and returns a transformed version. E.g, ``transforms.RandomCrop``
## 
## target_transform (callable, optional): A function/transform that takes in the
##             target and transforms it.
## 
## download (bool, optional): If true, downloads the dataset from the internet and
##             puts it in root directory. If dataset is already downloaded, it is not
##             downloaded again.
## 
##     
## `EMNIST <https://www.westernsydney.edu.au/bens/home/reproducible_research/emnist>`_ Dataset.
## 
##     Args:
## 
## root (string): Root directory of dataset where ``EMNIST/raw/train-images-idx3-ubyte``
##             and  ``EMNIST/raw/t10k-images-idx3-ubyte`` exist.
## 
## split (string): The dataset has 6 different splits: ``byclass``, ``bymerge``,
##             ``balanced``, ``letters``, ``digits`` and ``mnist``. This argument specifies
##             which one to use.
## 
## train (bool, optional): If True, creates dataset from ``training.pt``,
##             otherwise from ``test.pt``.
## 
## download (bool, optional): If True, downloads the dataset from the internet and
##             puts it in root directory. If dataset is already downloaded, it is not
##             downloaded again.
## 
## transform (callable, optional): A function/transform that  takes in an PIL image
##             and returns a transformed version. E.g, ``transforms.RandomCrop``
## 
## target_transform (callable, optional): A function/transform that takes in the
##             target and transforms it.
```

```
## NULL
```

Note how the above output indeed captures each argument description,
but some of them include more than necessary (title of next data set
is included in download arg description). Exercise for the reader: fix
this by putting `capture_all_str` inside of `by` and creating a new
regex to parse out the different sections of the doc string (title,
url, args), and then use the regex that we created above to parse the
args section.

## Conclusion

We have seen various applications of regular expressions using `nc` in
R. For even more practice, I recommend reading my
[regex-tutorial](https://github.com/tdhock/regex-tutorial) repo.

## Session info


```r
sessionInfo()
```

```
## R version 4.3.2 (2023-10-31)
## Platform: x86_64-pc-linux-gnu (64-bit)
## Running under: Ubuntu 22.04.3 LTS
## 
## Matrix products: default
## BLAS:   /usr/lib/x86_64-linux-gnu/blas/libblas.so.3.10.0 
## LAPACK: /usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.10.0
## 
## locale:
##  [1] LC_CTYPE=fr_FR.UTF-8       LC_NUMERIC=C               LC_TIME=fr_FR.UTF-8        LC_COLLATE=fr_FR.UTF-8    
##  [5] LC_MONETARY=fr_FR.UTF-8    LC_MESSAGES=fr_FR.UTF-8    LC_PAPER=fr_FR.UTF-8       LC_NAME=C                 
##  [9] LC_ADDRESS=C               LC_TELEPHONE=C             LC_MEASUREMENT=fr_FR.UTF-8 LC_IDENTIFICATION=C       
## 
## time zone: America/Phoenix
## tzcode source: system (glibc)
## 
## attached base packages:
## [1] stats     graphics  utils     datasets  grDevices methods   base     
## 
## other attached packages:
## [1] future_1.33.1     ggplot2_3.4.4     data.table_1.15.0
## 
## loaded via a namespace (and not attached):
##  [1] future.apply_1.11.1    gtable_0.3.4           dplyr_1.1.4            compiler_4.3.2         crayon_1.5.2          
##  [6] tidyselect_1.2.0       parallel_4.3.2         globals_0.16.2         scales_1.3.0           uuid_1.2-0            
## [11] RhpcBLASctl_0.23-42    R6_2.5.1               mlr3tuning_0.19.2      labeling_0.4.3         generics_0.1.3        
## [16] knitr_1.45             palmerpenguins_0.1.1   backports_1.4.1        checkmate_2.3.1        tibble_3.2.1          
## [21] munsell_0.5.0          paradox_0.11.1         pillar_1.9.0           mlr3tuningspaces_0.4.0 mlr3measures_0.5.0    
## [26] rlang_1.1.3            utf8_1.2.4             xfun_0.41              lgr_0.4.4              mlr3_0.17.2           
## [31] mlr3misc_0.13.0        cli_3.6.2              withr_3.0.0            magrittr_2.0.3         digest_0.6.34         
## [36] grid_4.3.2             mlr3learners_0.5.8     bbotk_0.7.3            nc_2024.2.6            lifecycle_1.0.4       
## [41] vctrs_0.6.5            evaluate_0.23          glue_1.7.0             farver_2.1.1           listenv_0.9.1         
## [46] codetools_0.2-19       parallelly_1.36.0      fansi_1.0.6            colorspace_2.1-0       tools_4.3.2           
## [51] pkgconfig_2.0.3
```


