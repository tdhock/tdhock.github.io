---
layout: post
title: Creating large imbalanced data benchmarks
description: Tutorial with OpenML
---



The goal of this post is to show how to create imbalanced classification data
sets for use with our recently proposed [SOAK
algorithm](https://arxiv.org/abs/2410.08643), which will be able to
tell us if we can train on imbalanced data, and get accurate
predictions on balanced data (and vice versa).

## Read and order OpenML data

OpenML is a web site and repository where we can download machine learning benchmark data sets.
We begin by reading the list of meta-data,


``` r
omlds <- OpenML::listOMLDataSets(limit=1e6)
library(data.table)
omldt <- data.table(omlds)[order(-number.of.instances)]
class_dt <- omldt[is.finite(number.of.classes)][number.of.classes>1]
unique(class_dt[, .(
  data.id, name, rows=number.of.instances, Nclass=number.of.classes,
  Nmajor=majority.class.size, Nminor=minority.class.size
)])[1:100]
```

```
##      data.id                                  name     rows Nclass  Nmajor  Nminor
##        <int>                                <char>    <int>  <int>   <int>   <int>
##   1:   45570                                 Higgs 11000000      2 5829123 5170877
##   2:   45654                      bates_classif_20  5100000      2 2550423 2549577
##   3:   45656                       simulated_adult  5100000      2 3832046 1267954
##   4:   45660                 simulated_electricity  5100000      2 2939411 2160589
##   5:   45665                                 colon  5100000      2 2550563 2549437
##   6:   45668                     bates_classif_100  5100000      2 2550705 2549295
##   7:   45669                                breast  5100000      2 2550498 2549502
##   8:   45672                              prostate  5100000      2 2550678 2549322
##   9:   45689                       simulated_adult  5100000      2 3832034 1267966
##  10:   45693                 simulated_electricity  5100000      2 2939411 2160589
##  11:   45703              simulated_bank_marketing  5100000      2 4507263  592737
##  12:   45704                   simulated_covertype  5100000      2 2550934 2549066
##  13:    1110                         KDDCup99_full  4898431     23 2807886       2
##  14:   42746                              KDDCup99  4898431     23 2807886       2
##  15:   46678                   mimic_extract_los_3  4156450     79 2028438       1
##  16:   46816                   mimic_extract_los_3  4155294     78 2028438       1
##  17:   46887                   mimic_extract_los_3  4155294     78 2028438       1
##  18:   42553               BitcoinHeist_Ransomware  2916697     29 2875284       1
##  19:   42732                   sf-police-incidents  2215023      2 1945704  269319
##  20:    1218                Click_prediction_small  1997410      2 1664406  333004
##  21:   46801                             ACSIncome  1664500      2  866735  797765
##  22:   42078                          beer_reviews  1586614    104  117586     241
##  23:   42087                          beer_reviews  1586614    104  117586     241
##  24:   42088                          beer_reviews  1586614    104  117586     241
##  25:   42089                    vancouver_employee  1586614    104  117586     241
##  26:   42132                    Traffic_violations  1578154      4  789812     899
##  27:   46817                      physionet_sepsis  1552210      2 1524294   27916
##  28:   46888                      physionet_sepsis  1552210      2 1524294   27916
##  29:    1216                Click_prediction_small  1496391      2 1429610   66781
##  30:     149                            CovPokElec  1455525     10  654548       2
##  31:   45274                                  PASS  1439588  94137      80       1
##  32:   46649                               DDXPlus  1292579     49   81767     325
##  33:   46804                               DDXPlus  1292579     49   81767     325
##  34:   45579                             Microsoft  1200192      5  624263    8881
##  35:   46802                     ACSPublicCoverage  1138289      2 1048325   89964
##  36:    1240                   AirlinesCodrnaAdult  1076790      2  603138  473652
##  37:     354                                 poker  1025010      2  513702  511308
##  38:    1567                            poker-hand  1025009     10  513701       8
##  39:    1569                            poker-hand  1025000      9  513701      17
##  40:      70           BNG(anneal,nominal,1000000)  1000000      6  759513     597
##  41:      71      BNG(anneal.ORIG,nominal,1000000)  1000000      6  759513     597
##  42:      72                         BNG(kr-vs-kp)  1000000      2  521875  478125
##  43:      73            BNG(labor,nominal,1000000)  1000000      2  645520  354480
##  44:      74           BNG(letter,nominal,1000000)  1000000     26   40828   36483
##  45:      75            BNG(autos,nominal,1000000)  1000000      7  323286    2430
##  46:      76            BNG(lymph,nominal,1000000)  1000000      4  543512   16553
##  47:      77    BNG(breast-cancer,nominal,1000000)  1000000      2  702823  297177
##  48:      78    BNG(mfeat-fourier,nominal,1000000)  1000000     10  100595   99773
##  49:     115   BNG(mfeat-karhunen,nominal,1000000)  1000000     10  100393   99523
##  50:     116 BNG(bridges_version1,nominal,1000000)  1000000      6  422711   95098
##  51:     117 BNG(bridges_version2,nominal,1000000)  1000000      6  422711   95098
##  52:     118    BNG(mfeat-zernike,nominal,1000000)  1000000     10  100380   99430
##  53:     120                         BNG(mushroom)  1000000      2  518298  481702
##  54:     121       BNG(colic.ORIG,nominal,1000000)  1000000      2  662777  337223
##  55:     122            BNG(colic,nominal,1000000)  1000000      2  629653  370347
##  56:     123                        BNG(optdigits)  1000000     10  101675   98637
##  57:     124         BNG(credit-a,nominal,1000000)  1000000      2  554898  445102
##  58:     126         BNG(credit-g,nominal,1000000)  1000000      2  699587  300413
##  59:     127        BNG(pendigits,nominal,1000000)  1000000     10  104573   95300
##  60:     128   BNG(cylinder-bands,nominal,1000000)  1000000      2  577023  422977
##  61:     129      BNG(dermatology,nominal,1000000)  1000000      6  304611   54922
##  62:     130                          BNG(segment)  1000000      7  143586  142366
##  63:     131             BNG(sick,nominal,1000000)  1000000      2  938761   61239
##  64:     132            BNG(sonar,nominal,1000000)  1000000      2  533556  466444
##  65:     134                          BNG(soybean)  1000000     19  133345   12441
##  66:     135                         BNG(spambase)  1000000      2  605948  394052
##  67:     136          BNG(heart-c,nominal,1000000)  1000000      5  540810    1618
##  68:     138          BNG(heart-h,nominal,1000000)  1000000      5  634862    1659
##  69:     139                           BNG(trains)  1000000      2  501119  498881
##  70:     140    BNG(heart-statlog,nominal,1000000)  1000000      2  554324  445676
##  71:     141          BNG(vehicle,nominal,1000000)  1000000      4  258113  234833
##  72:     142        BNG(hepatitis,nominal,1000000)  1000000      2  791048  208952
##  73:     144      BNG(hypothyroid,nominal,1000000)  1000000      4  922578     677
##  74:     146                       BNG(ionosphere)  1000000      2  641025  358975
##  75:     147    BNG(waveform-5000,nominal,1000000)  1000000      3  337805  330548
##  76:     148              BNG(zoo,nominal,1000000)  1000000      7  396212   42992
##  77:     152                    Hyperplane_10_1E-3  1000000      2  500007  499993
##  78:     153                    Hyperplane_10_1E-4  1000000      2  500166  499834
##  79:     154                            LED(50000)  1000000     10  100824   99427
##  80:     156                         RandomRBF_0_0  1000000      5  300096   92713
##  81:     157                     RandomRBF_10_1E-3  1000000      5  300096   92713
##  82:     158                     RandomRBF_10_1E-4  1000000      5  300096   92713
##  83:     159                     RandomRBF_50_1E-3  1000000      5  300096   92713
##  84:     160                     RandomRBF_50_1E-4  1000000      5  300096   92713
##  85:     161                               SEA(50)  1000000      2  614342  385658
##  86:     162                            SEA(50000)  1000000      2  614332  385668
##  87:     244                           BNG(anneal)  1000000      6  759652     555
##  88:     245                      BNG(anneal.ORIG)  1000000      6  759652     555
##  89:     246                            BNG(labor)  1000000      2  647000  353000
##  90:     247                           BNG(letter)  1000000     26   40765   36811
##  91:     248                            BNG(autos)  1000000      7  323554    2441
##  92:     249                            BNG(lymph)  1000000      4  543495   16508
##  93:     250                    BNG(mfeat-fourier)  1000000     10  100515   99530
##  94:     252                   BNG(mfeat-karhunen)  1000000     10  100410   99545
##  95:     253                 BNG(bridges_version1)  1000000      6  423139   95207
##  96:     254                    BNG(mfeat-zernike)  1000000     10  100289   99797
##  97:     256                       BNG(colic.ORIG)  1000000      2  637594  362406
##  98:     257                            BNG(colic)  1000000      2  630221  369779
##  99:     258                         BNG(credit-a)  1000000      2  554008  445992
## 100:     260                         BNG(credit-g)  1000000      2  699774  300226
##      data.id                                  name     rows Nclass  Nmajor  Nminor
```

The table above shows the 100 largest data sets, in terms of number of instances/rows.

## Reading higgs data set

Since we want to create an imbalanced data set, we would like to use a very large data set, so that we can try very small minority class frequencies (1% or smaller).
The code below attempts to read the largest data set, higgs.


``` r
higgs.id <- 45570
if(FALSE){
  higgs.data <- OpenML::getOMLDataSet(higgs.id)
}
```

I put the above inside `if(FALSE)` because the data set is very large!
A better way of doing this would be via a cache:


``` r
if(!file.exists("higgs_orig.arff")){
  download.file("https://api.openml.org/data/download/22116554/dataset", "higgs_orig.arff")
}
```

When I tried to read this into R, I got an error message, that [I reported as an OpenML issue](https://github.com/openml/openml-data/issues/71#issue-3228574014):

```r
> higgs <- farff::readARFF("higgs_orig.arff")
Parse with reader=readr : C:\Users\hoct2726/Downloads/dataset
Error in parseHeader(path) : 
  Invalid column specification line found in ARFF header:
@ATTRIBUTE "lepton pT" REAL
Timing stopped at: 0 0 0.03
```

Since this file is very large, we will do experiments on a smaller version:


``` r
sys::exec_wait("head", c("-100", "higgs_orig.arff"), std_out="higgs_head100.arff")
```

```
## [1] 0
```

``` r
higgs.head100 <- farff::readARFF("higgs_head100.arff")
```

```
## Parse with reader=readr : higgs_head100.arff
```

```
## Error in parseHeader(path): Invalid column specification line found in ARFF header:
## @ATTRIBUTE "lepton pT" REAL
```

```
## Timing stopped at: 0.01 0 0
```

We see the same error above.
We can try to work around it by replacing spaces with underscores in double quotes:


``` r
sed.replace <- r'{s/ ([^"]+")/_\1/g}'
for(i in 1:2){
  sys::exec_wait("sed", c("-ri", sed.replace, "higgs_head100.arff"))
}
sys::exec_wait("grep", c('@ATTRIBUTE', "higgs_head100.arff"), std_out="higgs_attributes.csv")
```

```
## [1] 0
```

``` r
higgs.head100 <- farff::readARFF("higgs_head100.arff")
```

```
## Parse with reader=readr : higgs_head100.arff
```

```
## header: 0.020000; preproc: 0.000000; data: 0.030000; postproc: 0.000000; total: 0.050000
```

``` r
library(data.table)
sys::exec_wait("sed", c("s/ [{R].*//", "higgs_attributes.csv"), std_out="higgs_names.csv")
```

```
## [1] 0
```

``` r
attr_dt <- fread("higgs_names.csv", header=FALSE, col.names="name", select=2)
higgs100_dt <- suppressWarnings(fread("higgs_head100.arff", col.names=attr_dt$name))
```


``` r
system.time({
  higgs_dt <- suppressWarnings(fread("higgs_orig.arff", col.names=attr_dt$name))
})
```

```
##    user  system elapsed 
##    8.01    3.22   11.78
```

``` r
higgs_dt[1]
```

```
##    Target lepton_pT lepton_eta lepton_phi missing_energy_magnitude missing_energy_phi  jet_1_pt  jet_1_eta jet_1_phi
##     <num>     <num>      <num>      <num>                    <num>              <num>     <num>      <num>     <num>
## 1:      1 0.8692932 -0.6350818  0.2256903                0.3274701         -0.6899932 0.7542022 -0.2485731 -1.092064
##    jet_1_b-tag jet_2_pt  jet_2_eta jet_2_phi jet_2_b-tag jet_3_pt jet_3_eta jet_3_phi jet_3_b-tag  jet_4_pt   jet_4_eta
##          <num>    <num>      <num>     <num>       <num>    <num>     <num>     <num>       <num>     <num>       <num>
## 1:           0 1.374992 -0.6536742 0.9303491    1.107436 1.138904 -1.578198 -1.046985           0 0.6579295 -0.01045457
##      jet_4_phi jet_4_b-tag    m_jj     m_jjj      m_lv     m_jlv      m_bb     m_wbb    m_wwbb
##          <num>       <num>   <num>     <num>     <num>     <num>     <num>     <num>     <num>
## 1: -0.04576717    3.101961 1.35376 0.9795631 0.9780762 0.9200048 0.7216575 0.9887509 0.8766783
```

The output above indicates fread can read 11M rows in about 10 seconds.
In contrast, the readARFF function can be used via:

```r
system.time({
  sys::exec_wait("sed", c("-r", sed.replace, "higgs_orig.arff"), std_out="higgs_underscore.arff")
  sys::exec_wait("sed", c("-ri", sed.replace, "higgs_underscore.arff"))
})
higgs <- farff::readARFF("higgs_orig.arff")
```

```r
> system.time({
+ sys::exec_wait("sed", c("-r", sed.replace, "higgs_orig.arff"), std_out="higgs_underscore.arff")
+ sys::exec_wait("sed", c("-ri", sed.replace, "higgs_underscore.arff"))
+ })
   user  system elapsed 
   1.72    2.14 1813.55 
```

The output above indicates that replacing underscores in the header took about 30 minutes.
The output below shows that reading the arff file into R took about 2 minutes (much slower than the 10 seconds required for data.table::fread).

```r
> higgs <- farff::readARFF("higgs_orig.arff")
Parse with reader=readr : C:\Users\hoct2726/Downloads/dataset
Loading required package: readr
header: 0.060000; preproc: 53.690000; data: 71.650000; postproc: 0.170000; total: 125.570000
> str(higgs)
'data.frame':	11000000 obs. of  29 variables:
 $ Target                  : Factor w/ 2 levels "0.0","1.0": 2 2 2 1 2 1 2 2 2 2 ...
 $ lepton_pT               : num  0.869 0.908 0.799 1.344 1.105 ...
 $ lepton_eta              : num  -0.635 0.329 1.471 -0.877 0.321 ...
 $ lepton_phi              : num  0.226 0.359 -1.636 0.936 1.522 ...
 $ missing_energy_magnitude: num  0.327 1.498 0.454 1.992 0.883 ...
 $ missing_energy_phi      : num  -0.69 -0.313 0.426 0.882 -1.205 ...
 $ jet_1_pt                : num  0.754 1.096 1.105 1.786 0.681 ...
 $ jet_1_eta               : num  -0.249 -0.558 1.282 -1.647 -1.07 ...
 $ jet_1_phi               : num  -1.092 -1.588 1.382 -0.942 -0.922 ...
 $ jet_1_b-tag             : num  0 2.17 0 0 0 ...
 $ jet_2_pt                : num  1.375 0.813 0.852 2.423 0.801 ...
 $ jet_2_eta               : num  -0.654 -0.214 1.541 -0.676 1.021 ...
 $ jet_2_phi               : num  0.93 1.271 -0.82 0.736 0.971 ...
 $ jet_2_b-tag             : num  1.11 2.21 2.21 2.21 2.21 ...
 $ jet_3_pt                : num  1.139 0.5 0.993 1.299 0.597 ...
 $ jet_3_eta               : num  -1.578 -1.261 0.356 -1.431 -0.35 ...
 $ jet_3_phi               : num  -1.047 0.732 -0.209 -0.365 0.631 ...
 $ jet_3_b-tag             : num  0 0 2.55 0 0 ...
 $ jet_4_pt                : num  0.658 0.399 1.257 0.745 0.48 ...
 $ jet_4_eta               : num  -0.0105 -1.1389 1.1288 -0.6784 -0.3736 ...
 $ jet_4_phi               : num  -0.045767 -0.000819 0.900461 -1.360356 0.113041 ...
 $ jet_4_b-tag             : num  3.1 0 0 0 0 ...
 $ m_jj                    : num  1.354 0.302 0.91 0.947 0.756 ...
 $ m_jjj                   : num  0.98 0.833 1.108 1.029 1.361 ...
 $ m_lv                    : num  0.978 0.986 0.986 0.999 0.987 ...
 $ m_jlv                   : num  0.92 0.978 0.951 0.728 0.838 ...
 $ m_bb                    : num  0.722 0.78 0.803 0.869 1.133 ...
 $ m_wbb                   : num  0.989 0.992 0.866 1.027 0.872 ...
 $ m_wwbb                  : num  0.877 0.798 0.78 0.958 0.808 ...
```

We see that these data have a `target` column (output to predict). The class distribution
is as follows:


``` r
(higgs_counts <- higgs_dt[, .(
  count=.N,
  prop=.N/nrow(higgs_dt)
), by=Target][order(-prop)])
```

```
##    Target   count      prop
##     <num>   <int>     <num>
## 1:      1 5829123 0.5299203
## 2:      0 5170877 0.4700797
```

In the table above, we see the overall `count` (number of rows) for each target.
We see in the `prop` column above that there are about an equal amount of data
for each class, from 47% to about 53%.

## Proportional versus random ordering

We would like to preserve these
proportions when we take subsamples of the data. To do that, we first
take a random order of the data (in case the original file had some
special structure), and then we assign a new proportional ordering
based on the label value.


``` r
my.seed <- 1
set.seed(my.seed)
rand_ord <- higgs_dt[, sample(.N)]
prop_ord <- data.table(y=higgs_dt$Target[rand_ord])[
, prop_y := seq(0,1,l=.N), by=y
][, order(prop_y)]
ord_list <- list(
  random=rand_ord,
  proportional=rand_ord[prop_ord])
ord_prop_dt_list <- list()
for(ord_name in names(ord_list)){
  ord_vec <- ord_list[[ord_name]]
  y_ord <- higgs_dt$Target[ord_vec]
  for(prop_data in c(0.01, 0.1, 1)){
    N <- nrow(higgs_dt)*prop_data
    N_props <- data.table(y=y_ord[1:N])[, .(
      count=.N,
      prop_y=.N/N
    ), by=y][order(-prop_y)]
    ord_prop_dt_list[[paste(ord_name, prop_data)]] <- data.table(
      ord_name, prop_data, N_props)
  }
}
ord_prop_dt <- rbindlist(ord_prop_dt_list)
dcast(ord_prop_dt, ord_name + prop_data ~ y, value.var="prop_y")
```

```
## Key: <ord_name, prop_data>
##        ord_name prop_data         0         1
##          <char>     <num>     <num>     <num>
## 1: proportional      0.01 0.4700818 0.5299182
## 2: proportional      0.10 0.4700800 0.5299200
## 3: proportional      1.00 0.4700797 0.5299203
## 4:       random      0.01 0.4691727 0.5308273
## 5:       random      0.10 0.4705191 0.5294809
## 6:       random      1.00 0.4700797 0.5299203
```

The output above shows that the proportional ordering is somewhat more
stable than the random ordering, which has some variations in the `0` and `1`
columns, between the different rows (values of prop_data).

## Creating class imbalance, one imbalance proportion

We would like to split the rows into two subsets, one balanced, and one imbalanced.
The balanced subset will have an equal number of positive and negative labels.
The imbalanced subset should be the same size as the balanced subset, but have imbalance in the labels, with a certain proportion of negative labels, `Pneg`, defined below.


``` r
(Tpos <- higgs_counts$count[1])
```

```
## [1] 5829123
```

``` r
(Tneg <- higgs_counts$count[2])
```

```
## [1] 5170877
```

``` r
Pneg <- 0.001
```

Next, we compute the number of rows in each subset. The formulas below can be derived from assuming:

* `N` is the number of positive (and negative) labels in the balanced subset.
* `n_pos` and `n_neg` are the numbers of postive/negative labels in the imbalanced subset: `Pneg(n_neg+n_pos)=n_neg`.
* The subsets are the same size: `n_neg + n_pos= 2*N`.
* All of the positive labels are used: `Tpos = n_pos + N`.


``` r
(N <- as.integer(Tpos/(3-2*Pneg)))
```

```
## [1] 1944337
```

``` r
(n_pos <- Tpos-N)
```

```
## [1] 3884786
```

``` r
(n_neg <- as.integer(Pneg*n_pos/(1-Pneg)))
```

```
## [1] 3888
```

The code below can be used to check the results.


``` r
rbind(n_pos+N, Tpos) # all positive labels are used.
```

```
##         [,1]
##      5829123
## Tpos 5829123
```

``` r
rbind(n_neg+N, Tneg) # negative labels used is less than total negative labels.
```

```
##         [,1]
##      1948225
## Tneg 5170877
```

``` r
rbind(2*N, n_pos+n_neg) # imbalanced and balanced subsets are same size.
```

```
##         [,1]
## [1,] 3888674
## [2,] 3888674
```

## Creating class imbalance, several imbalance proportions

We will create different versions of `higgs`, each version having two subsets:

* one which is balanced: 50% positive labels, 50% negative labels.
* one which is imbalanced: a smaller proportion of negative labels
  (from 10% to 0.1%).

To do that, we use the following code to compute the number of samples
we would need:


``` r
Target_prop <- 10^seq(-1, -5)
(smaller_dt <- data.table(
  Target_prop,
  N_pos_neg = as.integer(Tpos/(3-2*Target_prop))
)[
, n_pos := Tpos-N_pos_neg
][
, n_neg := as.integer(Target_prop*n_pos/(1-Target_prop))
][
, check_N_im := n_pos+n_neg
][, let(
  check_N_bal = N_pos_neg*2,
  check_prop = n_neg/check_N_im
)][])
```

```
##    Target_prop N_pos_neg   n_pos  n_neg check_N_im check_N_bal   check_prop
##          <num>     <int>   <int>  <int>      <int>       <num>        <num>
## 1:       1e-01   2081829 3747294 416366    4163660     4163658 1.000000e-01
## 2:       1e-02   1956081 3873042  39121    3912163     3912162 9.999839e-03
## 3:       1e-03   1944337 3884786   3888    3888674     3888674 9.998267e-04
## 4:       1e-04   1943170 3885953    388    3886341     3886340 9.983684e-05
## 5:       1e-05   1943053 3886070     38    3886108     3886106 9.778421e-06
```

Above we see 

* `Target_prop`, the desired proportion of negative labels in the imbalanced subset,
* `N_pos_neg`, the number of negative (and positive) labels in the balanced subset,
* `n_pos` and `n_neg`, the number of positive/negative labels in the imbalanced subset,
* `check_prop`, the empirical proportion of negative labels in the imbalanced subset, 
* `check_N_bal` and `check_N_im`, the number of rows in the balanced/imbalanced subsets.

It is clear from the table above that the empirical proportions are
consistent with the desired proportions. To create the different imbalanced data
sets, we loop over the rows of this table, to assign rows to each
subset of each imbalanced variant (each corresponding to a column of
`subset_mat`).


``` r
subset_mat <- matrix(
  NA, nrow(higgs_dt), nrow(smaller_dt),
  dimnames=list(
    NULL,
    Target_prop=paste0(
      "seed",
      my.seed,
      "_prop",
      smaller_dt$Target_prop)))
emp_y_list <- list()
emp_props_list <- list()
higgs_ord <- higgs_dt[, .(Target, .I)][ord_list$proportional]
for(im_i in 1:nrow(smaller_dt)){
  im_row <- smaller_dt[im_i]
  im_count_dt <- im_row[, rbind(
    data.table(subset="b", Target=c(0,1), count=N_pos_neg),
    data.table(subset="i", Target=c(0,1), count=c(n_neg, n_pos))
  )]
  higgs_ord[, subset := NA_character_]
  for(Target_value in c(1,0)){
    tval_dt <- im_count_dt[Target==Target_value]
    sub_vals <- tval_dt[, rep(subset, count)]
    tval_idx <- which(higgs_ord$Target==Target_value)
    some_idx <- tval_idx[1:length(sub_vals)]
    higgs_ord[some_idx, subset := sub_vals]
  }
  subset_mat[higgs_ord$I, im_i] <- higgs_ord$subset
  (im_higgs <- data.table(
    Target_prop=im_row$Target_prop,
    subset=subset_mat[,im_i],
    Target=higgs_dt$Target
  )[, idx := .I][!is.na(subset)])
  emp_y_list[[im_i]] <- im_higgs[, .(
    count=.N
  ), by=.(Target_prop,subset,Target)]
  emp_props_list[[im_i]] <- im_higgs[, .(
    count=.N,
    first=idx[1], 
    last=idx[.N]
  ), by=.(Target_prop,subset,Target)
  ][
  , prop_in_subset := count/sum(count)
  , by=subset
  ][]
}
emp_y <- rbindlist(emp_y_list)
(emp_props <- rbindlist(emp_props_list))
```

```
##     Target_prop subset Target   count  first     last prop_in_subset
##           <num> <char>  <num>   <int>  <int>    <int>          <num>
##  1:       1e-01      b      1 2081829      1 10999997   5.000000e-01
##  2:       1e-01      i      1 3747294      2 10999998   9.000000e-01
##  3:       1e-01      b      0 2081829      4 11000000   5.000000e-01
##  4:       1e-01      i      0  416366     75 10999993   1.000000e-01
##  5:       1e-02      b      1 1956081      1 10999997   5.000000e-01
##  6:       1e-02      i      1 3873042      2 10999998   9.900002e-01
##  7:       1e-02      b      0 1956081      4 11000000   5.000000e-01
##  8:       1e-02      i      0   39121    438 10999907   9.999839e-03
##  9:       1e-03      b      1 1944337      1 10999997   5.000000e-01
## 10:       1e-03      i      1 3884786      2 10999998   9.990002e-01
## 11:       1e-03      b      0 1944337      4 11000000   5.000000e-01
## 12:       1e-03      i      0    3888   1112 10999778   9.998267e-04
## 13:       1e-04      b      1 1943170      1 10999997   5.000000e-01
## 14:       1e-04      i      1 3885953      2 10999998   9.999002e-01
## 15:       1e-04      b      0 1943170      4 11000000   5.000000e-01
## 16:       1e-04      i      0     388  52704 10984369   9.983684e-05
## 17:       1e-05      b      1 1943053      1 10999997   5.000000e-01
## 18:       1e-05      i      1 3886070      2 10999998   9.999902e-01
## 19:       1e-05      b      0 1943053      4 11000000   5.000000e-01
## 20:       1e-05      i      0      38 423109 10901153   9.778421e-06
##     Target_prop subset Target   count  first     last prop_in_subset
```

The table above can be used to verify that the subset assignments are
consistent with the Target label proportions. It has one row for each
unique combination of Target proportion, subset, and label (Target). For
each value of `Target_prop`, we have `prop_in_subset=0.5` when `subset=b` (balanced).

The subset assignment above was based on the idea of using all of the positive Targets in each subset.
There are other constraints we could consider:

* Each smaller Target proportion is a strict subset: going to 1% from
  10% just involves taking away some samples. For example, with 2000
  samples overall, 10% would look like 500/500 in balanced and 900/100
  imbalanced. Going to 1% would mean 455/455 in balanced (for a total
  of 910), and 900/10 imbalanced (also a total of 910).
* Same data size across imbalance proportions. For example, keeping
  500/500 for each balanced set, and then adjusting the size of the
  imbalanced set, so it always has a total of 1000 samples. For 10% we
  have 900/100, for 1% we have 10/990, etc.

Note that some of the constraints discussed above are mutually
exclusive (can not be done at the same time).

## Write the subset columns to a new CSV file

Finally, we create new columns for each subset.


``` r
fwrite(subset_mat, "2025-07-14-imbalance-openml.csv")
```

```
## x being coerced from class: matrix to data.table
```

``` r
sys::exec_wait("head","2025-07-14-imbalance-openml.csv")
```

```
## seed1_prop0.1,seed1_prop0.01,seed1_prop0.001,seed1_prop1e-04,seed1_prop1e-05
## b,b,b,b,b
## i,i,i,i,i
## i,i,i,i,i
## b,b,b,b,b
## i,i,i,i,i
## b,b,b,b,b
## i,i,i,i,i
## i,i,i,i,i
## b,i,i,i,i
```

```
## [1] 0
```

``` r
sys::exec_wait("wc", c("-l","2025-07-14-imbalance-openml.csv"))
```

```
## 11000001 2025-07-14-imbalance-openml.csv
```

```
## [1] 0
```

``` r
sys::exec_wait("du",c("-k","2025-07-14-imbalance-openml.csv"))
```

```
## 103004	2025-07-14-imbalance-openml.csv
```

```
## [1] 0
```

## Conclusions

This tutorial showed how to divide a data set into two subsets with the same number of samples (balanced and imbalanced). Each
imbalanced data set is represented as a new column (with the same
number of rows as the original data file), with two values: `b` for balanced
and `i` for imbalanced, that can be efficiently saved to a new CSV file
(without having to copy or modify the original data CSV). 
Each column in the resulting CSV files can be used to create a
different mlr3 Task (each with a different definition of subset), so
our recently proposed [SOAK
algorithm](https://arxiv.org/abs/2410.08643) can be used to determine
if a learning algorithm is able to generalize between data subsets
with different proportions of labels (50% minority class versus 1%,
etc).

## Session info


``` r
sessionInfo()
```

```
## R version 4.5.1 (2025-06-13 ucrt)
## Platform: x86_64-w64-mingw32/x64
## Running under: Windows 11 x64 (build 22631)
## 
## Matrix products: default
##   LAPACK version 3.12.1
## 
## locale:
## [1] LC_COLLATE=English_United States.utf8  LC_CTYPE=English_United States.utf8    LC_MONETARY=English_United States.utf8
## [4] LC_NUMERIC=C                           LC_TIME=English_United States.utf8    
## 
## time zone: America/Toronto
## tzcode source: internal
## 
## attached base packages:
## [1] stats     graphics  utils     datasets  grDevices methods   base     
## 
## other attached packages:
## [1] readr_2.1.5        data.table_1.16.99
## 
## loaded via a namespace (and not attached):
##  [1] crayon_1.5.3     vctrs_0.6.5      httr_1.4.7       cli_3.6.3        knitr_1.49       xfun_0.49       
##  [7] rlang_1.1.4      stringi_1.8.4    OpenML_1.12      jsonlite_1.8.9   glue_1.8.0       bit_4.5.0       
## [13] backports_1.5.0  XML_3.99-0.17    farff_1.1.1      sys_3.4.3        hms_1.1.3        fansi_1.0.6     
## [19] evaluate_1.0.1   BBmisc_1.13      tibble_3.2.1     fastmap_1.2.0    tzdb_0.4.0       lifecycle_1.0.4 
## [25] memoise_2.0.1    compiler_4.5.1   pkgconfig_2.0.3  digest_0.6.37    R6_2.5.1         tidyselect_1.2.1
## [31] utf8_1.2.4       curl_5.2.3       vroom_1.6.5      pillar_1.9.0     parallel_4.5.1   magrittr_2.0.3  
## [37] checkmate_2.3.2  tools_4.5.1      withr_3.0.2      bit64_4.5.2      cachem_1.1.0
```
