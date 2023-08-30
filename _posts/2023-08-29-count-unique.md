---
layout: post
title: Count unique students
description: Regex and data table summarization
---



The goal of this post is to show how to count the number of unique
google summer of code students I have mentored. The data source is my
[Teaching web
page](https://github.com/tdhock/tdhock.github.io/blob/master/_pages/teaching.md),
source code shown below:


```r
projects.string <- "
I have mentored the
following students in coding free/open-source software.
- [Arthur Pan](https://github.com/ampurrr), 2023, polars in R.
- [Jocelyne Chen](https://github.com/ampurr), 2023, [animint2
  documentation and bug fixes](https://gsoc.ampurr.com).
- [Yufan Fei](https://github.com/Faye-yufan), 2023, animint2:
  interactive grammar of graphics.
- [Yufan Fei](https://github.com/Faye-yufan), 2022, [animint2: interactive
  grammar of
  graphics](https://github.com/Faye-yufan/gsoc22-animint/blob/master/README.md).
- [Fabrizio Sandri](https://github.com/FabrizioSandri), 2022,
  [RcppDeepState: github action for fuzz testing C++ code in R
  packages](https://fabriziosandri.github.io/gsoc-2022-blog/summary/2022/09/08/gsoc-summary.html).
- [Daniel Agyapong](https://github.com/EngineerDanny), 2022, [Rperform
  github action for performance testing R
  packages](https://engineerdanny.github.io/GSOC22-RPerform-Blog/).
- [Anirban Chetia](https://github.com/Anirban166), 2021, [directlabels
  improvements](https://github.com/Anirban166/directlabels).
- [Diego Urgell](https://github.com/diego-urgell), 2021,
  [BinSeg](https://github.com/diego-urgell/BinSeg) efficient C++
  implementation of binary segmentation.
- [Mark Nawar](https://github.com/Mark-Nawar), 2021, [re2r back on CRAN](https://github.com/rstats-gsoc/gsoc2021/wiki/re2r-back-on-CRAN)
- [Sanchit Saini](https://github.com/sanchit-saini), 2020,
  [rtracklayer R package
  improvements](https://github.com/rstats-gsoc/gsoc2020/wiki/rtracklayer-improvements).
- [Himanshu Singh](https://github.com/lazycipher), 2020, [animint2:
  interactive grammar of
  graphics](https://github.com/tdhock/animint2).
- [Julian Stanley](https://github.com/julianstanley), 2020, [Graphical
  User Interface for gfpop R
  package](https://github.com/julianstanley/gfpop-gui).
- [Anirban Chetia](https://github.com/Anirban166), 2020,
  [testComplexity R
  package](https://github.com/Anirban166/testComplexity).
- [Anuraag Srivastava](https://github.com/as4378), 2019, [Optimal
  Partitioning algorithm and opart R
  package](https://github.com/as4378/opart).
- [Avinash Barnwal](https://github.com/avinashbarnwal/), 2019, [AFT
  and Binomial loss functions for
  xgboost](https://github.com/avinashbarnwal/GSOC-2019).
- [Aditya Sam](https://github.com/theadityasam/), 2019, [Elastic net regularized interval regression and iregnet R package](https://theadityasam.github.io/GSOC2019/).
- [Alan Williams](https://github.com/aw1231), 2018,
  [SegAnnDB: machine learning system for DNA copy number analysis](https://github.com/tdhock/SegAnnDB),
  [blog](https://medium.com/alans-gsoc-blog/work-product-a1080d175160).
- [Vivek Kumar](https://github.com/vivekktiwari), 2018,
  [animint2: interactive grammar of graphics](https://github.com/tdhock/animint2),
  [blog](https://vivekktiwari.github.io/gsoc18/).
- [Johan Larsson](https://github.com/jolars), 2018,
  [sgdnet: SAGA algorithm for sparse linear models](https://github.com/jolars/sgdnet).
- [Marlin Na](https://github.com/Marlin-Na), 2017,
  [TnT: interactive genome browser](https://github.com/Marlin-Na/TnT).
- [Rover Van](https://github.com/RoverVan), 2017, [iregnet: regularized interval regression](https://github.com/anujkhare/iregnet).
- [Abhishek Shrivastava](https://github.com/abstatic), 2016,
  [SegAnnDB: interactive system for labeling and machine learning in genomic data](https://github.com/tdhock/SegAnnDB).
- [Faizan Khan](https://github.com/faizan-khan-iit), 2016--2017, [animint: interactive grammar of graphics](https://github.com/tdhock/animint).
- [Anuj Khare](https://github.com/anujkhare), 2016, [iregnet: regularized interval regression](https://github.com/anujkhare/iregnet).
- [Qin Wenfeng](https://github.com/qinwf), 2016, [re2r: regular expressions](https://github.com/qinwf/re2r).
- [Akash Tandon](https://github.com/analyticalmonk), 2016, [Rperform: performance testing R packages](https://github.com/analyticalmonk/Rperform).
- [Ishmael Belghazi](https://github.com/IshmaelBelghazi), 2015, [bigoptim: stochastic average gradient algorithm](https://github.com/IshmaelBelghazi/bigoptim).
- [Kevin Ferris](https://github.com/kferris10), 2015, [animint: interactive grammar of graphics](https://github.com/tdhock/animint).
- [Tony Tsai](https://github.com/caijun), 2015, [animint: interactive grammar of graphics](https://github.com/tdhock/animint).
- [Carson Sievert](https://github.com/cpsievert), 2014, [animint: interactive grammar of graphics](https://github.com/tdhock/animint).
- [Susan VanderPlas](https://github.com/srvanderplas), 2013, [animint: interactive grammar of graphics](https://github.com/tdhock/animint).
"
```

The markdown code above has a regular structure: newline, dash, space,
open square bracket, then student name. Later on there is a comma,
space, then a year for the GSOC project. We can convert the text
string above to a data table with columns for name and year, using the
regular expression R code below.


```r
(projects.dt <- nc::capture_all_str(
  projects.string,
  "\n- \\[",
  name="[^]]+",
  ".*?, ",
  year="[0-9]+", as.integer))
```

```
##                     name  year
##                   <char> <int>
##  1:           Arthur Pan  2023
##  2:        Jocelyne Chen  2023
##  3:            Yufan Fei  2023
##  4:            Yufan Fei  2022
##  5:      Fabrizio Sandri  2022
##  6:      Daniel Agyapong  2022
##  7:       Anirban Chetia  2021
##  8:         Diego Urgell  2021
##  9:           Mark Nawar  2021
## 10:        Sanchit Saini  2020
## 11:       Himanshu Singh  2020
## 12:       Julian Stanley  2020
## 13:       Anirban Chetia  2020
## 14:   Anuraag Srivastava  2019
## 15:      Avinash Barnwal  2019
## 16:           Aditya Sam  2019
## 17:        Alan Williams  2018
## 18:          Vivek Kumar  2018
## 19:        Johan Larsson  2018
## 20:            Marlin Na  2017
## 21:            Rover Van  2017
## 22: Abhishek Shrivastava  2016
## 23:          Faizan Khan  2016
## 24:           Anuj Khare  2016
## 25:          Qin Wenfeng  2016
## 26:         Akash Tandon  2016
## 27:     Ishmael Belghazi  2015
## 28:         Kevin Ferris  2015
## 29:            Tony Tsai  2015
## 30:       Carson Sievert  2014
## 31:     Susan VanderPlas  2013
##                     name  year
```

One way to get unique students is to use `by` inside of data table
square brackets, as below:


```r
projects.dt[, .(projects=.N), by=.(student=name)]
```

```
##                  student projects
##                   <char>    <int>
##  1:           Arthur Pan        1
##  2:        Jocelyne Chen        1
##  3:            Yufan Fei        2
##  4:      Fabrizio Sandri        1
##  5:      Daniel Agyapong        1
##  6:       Anirban Chetia        2
##  7:         Diego Urgell        1
##  8:           Mark Nawar        1
##  9:        Sanchit Saini        1
## 10:       Himanshu Singh        1
## 11:       Julian Stanley        1
## 12:   Anuraag Srivastava        1
## 13:      Avinash Barnwal        1
## 14:           Aditya Sam        1
## 15:        Alan Williams        1
## 16:          Vivek Kumar        1
## 17:        Johan Larsson        1
## 18:            Marlin Na        1
## 19:            Rover Van        1
## 20: Abhishek Shrivastava        1
## 21:          Faizan Khan        1
## 22:           Anuj Khare        1
## 23:          Qin Wenfeng        1
## 24:         Akash Tandon        1
## 25:     Ishmael Belghazi        1
## 26:         Kevin Ferris        1
## 27:            Tony Tsai        1
## 28:       Carson Sievert        1
## 29:     Susan VanderPlas        1
##                  student projects
```

Another way to do that is to `dcast`, which is shown below,


```r
data.table::dcast(
  projects.dt,
  name ~ .,
  list(length, min, max),
  value.var="year"
)[, year_range := ifelse(
  year_min==year_max,
  year_min,
  sprintf("%d-%d", year_min, year_max)
)][order(year_range)]
```

```
## Warning in dcast.data.table(projects.dt, name ~ ., list(length, min, max), :
## NAs introduits lors de la conversion automatique en 'integer'

## Warning in dcast.data.table(projects.dt, name ~ ., list(length, min, max), :
## NAs introduits lors de la conversion automatique en 'integer'
```

```
##                     name year_length year_min year_max year_range
##                   <char>       <int>    <int>    <int>     <char>
##  1:     Susan VanderPlas           1     2013     2013       2013
##  2:       Carson Sievert           1     2014     2014       2014
##  3:     Ishmael Belghazi           1     2015     2015       2015
##  4:         Kevin Ferris           1     2015     2015       2015
##  5:            Tony Tsai           1     2015     2015       2015
##  6: Abhishek Shrivastava           1     2016     2016       2016
##  7:         Akash Tandon           1     2016     2016       2016
##  8:           Anuj Khare           1     2016     2016       2016
##  9:          Faizan Khan           1     2016     2016       2016
## 10:          Qin Wenfeng           1     2016     2016       2016
## 11:            Marlin Na           1     2017     2017       2017
## 12:            Rover Van           1     2017     2017       2017
## 13:        Alan Williams           1     2018     2018       2018
## 14:        Johan Larsson           1     2018     2018       2018
## 15:          Vivek Kumar           1     2018     2018       2018
## 16:           Aditya Sam           1     2019     2019       2019
## 17:   Anuraag Srivastava           1     2019     2019       2019
## 18:      Avinash Barnwal           1     2019     2019       2019
## 19:       Himanshu Singh           1     2020     2020       2020
## 20:       Julian Stanley           1     2020     2020       2020
## 21:        Sanchit Saini           1     2020     2020       2020
## 22:       Anirban Chetia           2     2020     2021  2020-2021
## 23:         Diego Urgell           1     2021     2021       2021
## 24:           Mark Nawar           1     2021     2021       2021
## 25:      Daniel Agyapong           1     2022     2022       2022
## 26:      Fabrizio Sandri           1     2022     2022       2022
## 27:            Yufan Fei           2     2022     2023  2022-2023
## 28:           Arthur Pan           1     2023     2023       2023
## 29:        Jocelyne Chen           1     2023     2023       2023
##                     name year_length year_min year_max year_range
```

The table above has 29 rows, one for each GSOC student I have
mentored. There are a total of 31 projects; Anirban Chetia and Yufan
Fei each did two consecutive years of GSOC.

Note that the warning above about NAs is a false positive, [that I
proposed to
remove](https://github.com/Rdatatable/data.table/issues/5512).

Exercise for the reader: add some code above to download the markdown
text string of data to parse (`projects.string`), rather than defining
it directly in R code.
