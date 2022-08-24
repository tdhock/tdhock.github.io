---
layout: post
title: R packages on github
description: How to query CRAN meta-data
---



The goal here is to find beta testers for
[RcppDeepState-action](https://github.com/FabrizioSandri/RcppDeepState-action).
Previously, Akhila Kolla created [a list of R packages with
RcppDeepState issues](https://akhikolla.github.io./packages-folders/).
Some of these packages may be hosted on github, but how to find that
programmatically? 

First, we download the web page which lists all of the candidate packages,


```r
if(!file.exists("problems.html")){
  download.file(
    "https://akhikolla.github.io./packages-folders/",
    "problems.html")
}
(prob.dt <- nc::capture_all_str(
  "problems.html",
  '<li><a href="',
  Package=".*?",
  '[.]html">'))
```

```
##            Package
##             <char>
##   1: accelerometry
##   2:          BNSL
##   3:     factorcpt
##   4:  humaniformat
##   5: IntegratedMRF
##  ---              
## 308:         waspr
## 309:    windfarmGA
## 310:            wk
## 311:       wkutils
## 312:           xyz
```

The code above shows that there are 312 packages on that
web page. Can we find the CRAN meta-data for each of them? First we
download the current CRAN meta-data,


```r
if(!file.exists("packages.rds")){
  download.file(
    "https://cloud.r-project.org/web/packages/packages.rds",
    "packages.rds")
}
meta.mat <- readRDS("packages.rds")
nrow(meta.mat)
```

```
## [1] 18469
```

Then we can subset the meta-data based on the packages on that web page,


```r
library(data.table)
```

```
## data.table 1.14.3 IN DEVELOPMENT built 2022-07-20 16:55:52 UTC; th798 using 6 threads (see ?getDTthreads).  Latest news: r-datatable.com
## **********
## This development version of data.table was built more than 4 weeks ago. Please update: data.table::update_dev_pkg()
## **********
```

```r
meta.dt <- data.table(meta.mat)
meta.prob <- meta.dt[prob.dt, on="Package"]
meta.prob[, .(Package, URL.truncated=substr(URL, 1, 50))]
```

```
##            Package                                       URL.truncated
##             <char>                                              <char>
##   1: accelerometry                                                <NA>
##   2:          BNSL                                                <NA>
##   3:     factorcpt                                                <NA>
##   4:  humaniformat          https://github.com/ironholds/humaniformat/
##   5: IntegratedMRF                                                <NA>
##  ---                                                                  
## 308:         waspr                                                <NA>
## 309:    windfarmGA                                                <NA>
## 310:            wk https://paleolimbot.github.io/wk/,\nhttps://github.
## 311:       wkutils https://paleolimbot.github.io/wkutils/,\nhttps://gi
## 312:           xyz                                                <NA>
```

The output above shows that there are several packages which mention
github in the URL field. To find the repo URL we can do,


```r
pkg.repos <- meta.prob[, nc::capture_all_str(
  c("",URL), # to avoid attempting to download URL.
  repo.url="https://github.com/.*?/[^#/ ,]+"),
  by=Package]
pkg.repos$repo.url
```

```
##   [1] "https://github.com/ironholds/humaniformat"           
##   [2] "https://github.com/jMotif/jmotif-R"                  
##   [3] "https://github.com/Ironholds/olctools"               
##   [4] "https://github.com/WinVector/RcppDynProg"            
##   [5] "https://github.com/shabbychef/BWStest"               
##   [6] "https://github.com/CollinErickson/CGGP"              
##   [7] "https://github.com/ekstroem/MESS"                    
##   [8] "https://github.com/paulhibbing/PAutilities"          
##   [9] "https://github.com/ms609/Quartet"                    
##  [10] "https://github.com/MikeJaredS/hermiter"              
##  [11] "https://github.com/dahtah/imager"                    
##  [12] "https://github.com/ntthung/ldsr"                     
##  [13] "https://github.com/saraswatmks/superml"              
##  [14] "https://github.com/statistikat/surveysd"             
##  [15] "https://github.com/Ironholds/urltools"               
##  [16] "https://github.com/wbnicholson/BigVAR"               
##  [17] "https://github.com/duncanplee/CARBayes"              
##  [18] "https://github.com/alexanderrobitzsch/CDM"           
##  [19] "https://github.com/emilsjoerup/DriftBurstHypothesis" 
##  [20] "https://github.com/mdsteiner/EFAtools"               
##  [21] "https://github.com/wush978/FeatureHashing"           
##  [22] "https://github.com/BMasinde/FlyingR"                 
##  [23] "https://github.com/Wenchao-Ma/GDINA"                 
##  [24] "https://github.com/wadpac/GGIR"                      
##  [25] "https://github.com/vpicheny/GPGame"                  
##  [26] "https://github.com/mbinois/GPareto"                  
##  [27] "https://github.com/thijsjanzen/GUILDS"               
##  [28] "https://github.com/raymondtsr/KSgeneral"             
##  [29] "https://github.com/Lionning/MuChPoint"               
##  [30] "https://github.com/stla/OwenQ"                       
##  [31] "https://github.com/jansteinfeld/PP"                  
##  [32] "https://github.com/anastasiospanagiotelis/ProbReco"  
##  [33] "https://github.com/jkrijthe/RSSL"                    
##  [34] "https://github.com/bleutner/RStoolbox"               
##  [35] "https://github.com/BZPaper/RTransferEntropy"         
##  [36] "https://github.com/PolMine/RcppCWB"                  
##  [37] "https://github.com/RcppCore/RcppEigen"               
##  [38] "https://github.com/yixuan/RcppNumerical"             
##  [39] "https://github.com/TReynkens/ReIns"                  
##  [40] "https://github.com/rudeboybert/SpatialEpi"           
##  [41] "https://github.com/bzhanglab/WebGestaltR"            
##  [42] "https://github.com/btbeal/adheRenceRX"               
##  [43] "https://github.com/thomasp85/ambient"                
##  [44] "https://github.com/jmsigner/amt"                     
##  [45] "https://github.com/rnuske/apcf"                      
##  [46] "https://github.com/jchiquet/aricode"                 
##  [47] "https://github.com/rorynolan/autothresholdr"         
##  [48] "https://github.com/zpneal/backbone"                  
##  [49] "https://github.com/bmihaljevic/bnclassify"           
##  [50] "https://github.com/digEmAll/bsearchtools"            
##  [51] "https://github.com/kasperwelbers/corpustools"        
##  [52] "https://github.com/lrnv/cort"                        
##  [53] "https://github.com/mhahsler/dbscan"                  
##  [54] "https://github.com/feng-li/dng"                      
##  [55] "https://github.com/eheinzen/elo"                     
##  [56] "https://github.com/mariarizzo/energy"                
##  [57] "https://github.com/bdsegal/exceedProb"               
##  [58] "https://github.com/somakd/fad"                       
##  [59] "https://github.com/souravc83/fastAdaboost"           
##  [60] "https://github.com/lrberge/fixest"                   
##  [61] "https://github.com/munterfi/flexpolyline"            
##  [62] "https://github.com/aberHRML/forestControl"           
##  [63] "https://github.com/tbalan/frailtyEM"                 
##  [64] "https://github.com/thomasp85/ggraph"                 
##  [65] "https://github.com/achubaty/grainscape"              
##  [66] "https://github.com/schochastics/graphlayouts"        
##  [67] "https://github.com/davidbuch/gretel"                 
##  [68] "https://github.com/agisga/grpSLOPE"                  
##  [69] "https://github.com/ipeaGIT/gtfs2gps"                 
##  [70] "https://github.com/jonathancornelissen/highfrequency"
##  [71] "https://github.com/hughparsonage/hutilscpp"          
##  [72] "https://github.com/rezakj/iCellR"                    
##  [73] "https://github.com/traets/idefix"                    
##  [74] "https://github.com/ShotaOchi/imagerExtra"            
##  [75] "https://github.com/alexanderrobitzsch/immer"         
##  [76] "https://github.com/immunomind/immunarch"             
##  [77] "https://github.com/qinwf/jiebaR"                     
##  [78] "https://github.com/dariomasante/landscapeR"          
##  [79] "https://github.com/spedygiorgio/lifecontingencies"   
##  [80] "https://github.com/alexanderrobitzsch/mnlfa"         
##  [81] "https://github.com/pascalkieslich/mousetrap"         
##  [82] "https://github.com/rorynolan/nandb"                  
##  [83] "https://github.com/jknape/nmixgof"                   
##  [84] "https://github.com/ycphs/openxlsx"                   
##  [85] "https://github.com/EdwinTh/padr"                     
##  [86] "https://github.com/thomasp85/particles"              
##  [87] "https://github.com/ropensci/parzer"                  
##  [88] "https://github.com/christinehohensinn/pcIRT"         
##  [89] "https://github.com/fmichonneau/phylobase"            
##  [90] "https://github.com/olssol/psrwe"                     
##  [91] "https://github.com/PhilippPro/quantregRanger"        
##  [92] "https://github.com/alarm-redist/redist"              
##  [93] "https://github.com/erlisR/robustBLME"                
##  [94] "https://github.com/r-spatial/s2"                     
##  [95] "https://github.com/raim/segmenTier"                  
##  [96] "https://github.com/mooresm/serrsBayes"               
##  [97] "https://github.com/michbur/signalhsmm"               
##  [98] "https://github.com/schochastics/signnet"             
##  [99] "https://github.com/statistikat/simPop"               
## [100] "https://github.com/kgoldfeld/simstudy"               
## [101] "https://github.com/sdparsons/splithalf"              
## [102] "https://github.com/schnorr/starvz"                   
## [103] "https://github.com/RaphaelS1/survivalmodels"         
## [104] "https://github.com/rstub/swephR"                     
## [105] "https://github.com/business-science/tibbletime"      
## [106] "https://github.com/const-ae/tidygenomics"            
## [107] "https://github.com/thomasp85/tidygraph"              
## [108] "https://github.com/nacnudus/tidyxl"                  
## [109] "https://github.com/marjoleinbruijning/trackdem"      
## [110] "https://github.com/irkaal/triangulr"                 
## [111] "https://github.com/thomasp85/tweenr"                 
## [112] "https://github.com/jlmelville/uwot"                  
## [113] "https://github.com/hypertidy/vapour"                 
## [114] "https://github.com/paleolimbot/wk"                   
## [115] "https://github.com/paleolimbot/wkutils"
```

Exercise for the reader: programmatically fork each of these repos,
then make a new branch, then add a
[RcppDeepState.yaml](https://github.com/tdhock/binsegRcpp/blob/32d09699bc55c32c09a70b8580b21c335791fb81/.github/workflows/RcppDeepState.yaml)
file, then push. This may be doable in R via
[gh](https://github.com/r-lib/gh), an R package for making calls to
the GitHub API.

UPDATE: my excellent GSOC student Fabrizio Sandri describes how to do
that [on his
blog](https://fabriziosandri.github.io/gsoc-2022-blog/github%20action/2022/08/23/rcppdeepstate-beta-test.html).
