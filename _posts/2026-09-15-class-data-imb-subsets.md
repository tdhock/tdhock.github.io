---
layout: post
title: Generating imbalanced subsets for SOAK benchmark
description: Creating meta-data for several data files
---



The purpose of this page is to continue the exploration of [Hierarchical imbalanced data generation](https://tdhock.github.io/blog/2026/hierachical-imbalanced-subset-generation).
That post explained how to divide a binary classification data set into hierarchical imbalanced subsets:

* Either the two subsets are both balanced (baseline),
* or one or the other subset is imbalanced to given proportions.
* each subset always has the same sample size, 
* and more imbalanced subsets are hierarchical: minor class samples are removed, major class samples are added (so there is a certain kind of continuity between imbalance proportions).

## Download benchmarks

Our goal is to apply this imbalance generation method to each data set used in the SOAK paper.
First, we download these data from zenodo.


``` r
if(FALSE){
  unlink("SOAK_data_Classif.zip")
}
if(!file.exists("SOAK_data_Classif.zip")){
  options(timeout=9999)
  download.file(
    "https://zenodo.org/records/18273949/files/SOAK_data_Classif.zip?download=1",
    "SOAK_data_Classif.zip")
}
if(!file.exists("data_Classif")){
  unzip("SOAK_data_Classif.zip")
}
```

Then we read the target y values:


``` r
(y.dt <- nc::capture_first_glob(
  Sys.glob("data_Classif/*"),
  "/",
  data.name=".*?",
  "[.]",
  READ=function(x)fread(x, select="y")))
```

```
##          data.name        y
##             <char>   <char>
##       1:  aztrees3 Not tree
##       2:  aztrees3 Not tree
##       3:  aztrees3 Not tree
##       4:  aztrees3 Not tree
##       5:  aztrees3 Not tree
##      ---                   
## 3788669:   zipUSPS        3
## 3788670:   zipUSPS        3
## 3788671:   zipUSPS        3
## 3788672:   zipUSPS        0
## 3788673:   zipUSPS        1
```

Then we analyze them:


``` r
(meta.dt <- y.dt[
, odd := as.integer(factor(y)) %% 2
, by=data.name
][, .(
  pos=sum(odd==1),
  neg=sum(odd==0),
  rows=.N
), by=data.name][
, min := pmin(pos, neg)
][order(min)])
```

```
##                   data.name    pos     neg    rows    min
##                      <char>  <int>   <int>   <int>  <int>
##  1:                waveform    542     258     800    258
##  2:                   vowel    540     450     990    450
##  3: CanadaFires_downSampled    588     903    1491    588
##  4:                aztrees3   5282     674    5956    674
##  5:                aztrees4   5282     674    5956    674
##  6:             NSCH_autism  44607    1403   46010   1403
##  7:         CanadaFires_all   1629    3198    4827   1629
##  8:                    spam   2788    1813    4601   1813
##  9:                 zipUSPS   4876    4422    9298   4422
## 10:                   STL10   6500    6500   13000   6500
## 11:                 CIFAR10  30000   30000   60000  30000
## 12:                   MNIST  34418   35582   70000  34418
## 13:                  EMNIST  35000   35000   70000  35000
## 14:            FashionMNIST  35000   35000   70000  35000
## 15:                  KMNIST  35000   35000   70000  35000
## 16:                  QMNIST  59097   60903  120000  59097
## 17:            MNIST_EMNIST  69418   70582  140000  69418
## 18:        MNIST_EMNIST_rot  69418   70582  140000  69418
## 19:      MNIST_FashionMNIST  69418   70582  140000  69418
## 20:         FishSonar_river 677258 2138486 2815744 677258
##                   data.name    pos     neg    rows    min
##                      <char>  <int>   <int>   <int>  <int>
```

The responses were binarized:  `odd` is 1 if factorized `y` was odd, otherwise 0.
We exclude small data sets:


``` r
data.list <- split(y.dt[, .(y, odd)], y.dt$data.name)[
  meta.dt[min>10000, data.name]
]
str(data.list)
```

```
## List of 10
##  $ CIFAR10           :Classes 'data.table' and 'data.frame':	60000 obs. of  2 variables:
##   ..$ y  : chr [1:60000] "6" "9" "9" "4" ...
##   ..$ odd: num [1:60000] 1 0 0 1 0 0 1 0 1 0 ...
##   ..- attr(*, ".internal.selfref")=<pointer: 0x63462bc04b10> 
##  $ MNIST             :Classes 'data.table' and 'data.frame':	70000 obs. of  2 variables:
##   ..$ y  : chr [1:70000] "5" "0" "4" "1" ...
##   ..$ odd: num [1:70000] 0 1 1 0 0 1 0 0 0 1 ...
##   ..- attr(*, ".internal.selfref")=<pointer: 0x63462bc04b10> 
##  $ EMNIST            :Classes 'data.table' and 'data.frame':	70000 obs. of  2 variables:
##   ..$ y  : chr [1:70000] "4" "1" "4" "1" ...
##   ..$ odd: num [1:70000] 1 0 1 0 1 0 1 1 1 0 ...
##   ..- attr(*, ".internal.selfref")=<pointer: 0x63462bc04b10> 
##  $ FashionMNIST      :Classes 'data.table' and 'data.frame':	70000 obs. of  2 variables:
##   ..$ y  : chr [1:70000] "9" "0" "0" "3" ...
##   ..$ odd: num [1:70000] 0 1 1 0 1 1 0 1 0 0 ...
##   ..- attr(*, ".internal.selfref")=<pointer: 0x63462bc04b10> 
##  $ KMNIST            :Classes 'data.table' and 'data.frame':	70000 obs. of  2 variables:
##   ..$ y  : chr [1:70000] "8" "7" "0" "1" ...
##   ..$ odd: num [1:70000] 1 0 1 0 1 1 1 1 0 0 ...
##   ..- attr(*, ".internal.selfref")=<pointer: 0x63462bc04b10> 
##  $ QMNIST            :Classes 'data.table' and 'data.frame':	120000 obs. of  2 variables:
##   ..$ y  : chr [1:120000] "5" "0" "4" "1" ...
##   ..$ odd: num [1:120000] 0 1 1 0 0 1 0 0 0 1 ...
##   ..- attr(*, ".internal.selfref")=<pointer: 0x63462bc04b10> 
##  $ MNIST_EMNIST      :Classes 'data.table' and 'data.frame':	140000 obs. of  2 variables:
##   ..$ y  : chr [1:140000] "4" "1" "4" "1" ...
##   ..$ odd: num [1:140000] 1 0 1 0 1 0 1 1 1 0 ...
##   ..- attr(*, ".internal.selfref")=<pointer: 0x63462bc04b10> 
##  $ MNIST_EMNIST_rot  :Classes 'data.table' and 'data.frame':	140000 obs. of  2 variables:
##   ..$ y  : chr [1:140000] "5" "0" "4" "1" ...
##   ..$ odd: num [1:140000] 0 1 1 0 0 1 0 0 0 1 ...
##   ..- attr(*, ".internal.selfref")=<pointer: 0x63462bc04b10> 
##  $ MNIST_FashionMNIST:Classes 'data.table' and 'data.frame':	140000 obs. of  2 variables:
##   ..$ y  : chr [1:140000] "9" "0" "0" "3" ...
##   ..$ odd: num [1:140000] 0 1 1 0 1 1 0 1 0 0 ...
##   ..- attr(*, ".internal.selfref")=<pointer: 0x63462bc04b10> 
##  $ FishSonar_river   :Classes 'data.table' and 'data.frame':	2815744 obs. of  2 variables:
##   ..$ y  : chr [1:2815744] "other" "other" "other" "other" ...
##   ..$ odd: num [1:2815744] 0 0 0 0 0 0 0 0 0 0 ...
##   ..- attr(*, ".internal.selfref")=<pointer: 0x63462bc04b10>
```

## Generate subsets


``` r
extab <- function(Tprop, N, Tpos, Tneg){
  dt <- data.table(
    p_neg=sort(c(0.5, Tprop)),
    n_bal=2L*N
  )[, let(
    n_neg=as.integer(round(2*N*p_neg))
  )][, let(
    n_pos=n_bal-n_neg
  )][, let(
    n_imb=n_pos+n_neg,
    unused_pos=Tpos-n_pos-N,
    unused_neg=Tneg-n_neg-N
  )][]
  list(props=dt, params=dt[, data.table(
    extra_pos=max(n_pos-N),
    extra_neg=max(n_neg-N),
    N)])
}
ntab <- function(Target_prop, Tpos, Tneg){
  if(all(Target_prop<0.5)){
    Tminor <- Tneg
    Tmajor <- Tpos
    p_minor <- Target_prop
  }else if(all(Target_prop>0.5)){
    Tminor <- Tpos
    Tmajor <- Tneg
    p_minor <- 1-Target_prop
  }else stop("Target_prop should be numeric, with each entry greater than 0.5, or each entry less than 0.5")
  xp_minor <- min(p_minor)
  (n_pos_max <- 2*Tmajor*(1-xp_minor)/(3-2*xp_minor))
  (n_pos_max_neg <- n_pos_max*xp_minor/(1-xp_minor))
  (n_pos_max_N <- as.integer(floor((n_pos_max_neg+n_pos_max)/2)))
  (n_pos_max_bal_neg <- n_pos_max_N*2)
  (Tminor_N <- as.integer(floor(Tminor/2)))
  N <- if(Tminor<n_pos_max_bal_neg)Tminor_N else n_pos_max_N
  extab(Target_prop, N, Tpos, Tneg)
}
get_subsets <- function(y.vec, p_neg, n.folds=5L){
  Tlist <- setNames(as.list(table(y.vec)), c("Tneg", "Tpos"))
  Tlist$Target_prop <- p_neg
  Tlist
  (count.list <- do.call(ntab, Tlist))
  (ind.dt <- data.table(y=y.vec)[
  , row := .I
  ][sample(.N)][
  , set := NA_character_
  ][])
  label.list <- list(pos=1,neg=0)
  N <- count.list$params$N
  for(label.name in names(label.list)){
    label.value <- label.list[[label.name]]
    label.extra <- count.list$params[[paste0("extra_", label.name)]]
    set.values <- rep(c("X","Y","E"), c(N,N,label.extra))
    label.i <- which(ind.dt$y==label.value)[seq_along(set.values)]
    ind.dt[label.i, set := set.values]
  }
  ind.dt[, fold := rep(1:n.folds, length.out=.N), by=.(set, y)][]
  (out.unsort <- ind.dt[, data.table(
    fold,
    Xb_Yb=ifelse(set %in% c("X","Y"), set, NA))])
  imb.counts <- count.list$props[p_neg != 0.5][order(abs(p_neg-0.5))]
  pos.part <- function(x)ifelse(x<0, 0, x)
  for(cformat in c("Xineg%s_Yb", "Xb_Yineg%s")){
    for(imb.i in 1:nrow(imb.counts)){
      imb.row <- imb.counts[imb.i]
      j.name <- sprintf(cformat, imb.row$p_neg)
      set(
        out.unsort,
        j=j.name,
        value=ind.dt$set)
      imb.set <- ifelse(grepl("Xi", cformat), "X", "Y")
      for(label.name in names(label.list)){
        label.value <- label.list[[label.name]]
        label.n <- imb.row[[paste0("n_", label.name)]]
        find.rep.dt <- rowwiseDT(
          find.set=, sign=, rep.set=,
          imb.set, 1, NA, #rm
          "E", -1, imb.set)#add
        for(find.rep.i in 1:nrow(find.rep.dt)){
          find.rep.row <- find.rep.dt[find.rep.i]
          possible.indices <- ind.dt[, which(y==label.value & set==find.rep.row$find.set)]
          change.n <- pos.part((N-label.n)*find.rep.row$sign)
          change.indices <- possible.indices[seq_len(change.n)]
          set(
            out.unsort,
            i=change.indices,
            j=j.name,
            value=find.rep.row$rep.set)
        }
        is.E <- which(out.unsort[[j.name]]=="E")
        set(
          out.unsort,
          i=is.E,
          j=j.name,
          value=NA)
      }
    }
  }
  orig.ord <- order(ind.dt$row)
  out.unsort[orig.ord]
}

for(data.name in names(data.list)){
  data.dt <- data.list[[data.name]]
  floor.log10 <- floor(log10(min(table(data.dt$odd)))-1)
  (p.neg <- (10^seq(-floor.log10, -1))*0.5)
  p.list <- list(neg=p.neg, pos=1-p.neg)
  for(minor.class in names(p.list)){
    p.vec <- p.list[[minor.class]]
    for(seed in 1:2){
      set.seed(seed)
      (data.sub.dt <- get_subsets(data.dt$odd, p.vec))
      print(out.csv <- sprintf(
        "data_Classif_imb_subsets/%s/seed=%d_pneg[%s,%s].csv",
        data.name, seed, min(p.vec), max(p.vec)))
      out.dir <- dirname(out.csv)
      dir.create(out.dir, showWarnings = FALSE, recursive = TRUE)
      fwrite(data.sub.dt, out.csv)
    }
  }
}
```

```
## [1] "data_Classif_imb_subsets/CIFAR10/seed=1_pneg[5e-04,0.05].csv"
## [1] "data_Classif_imb_subsets/CIFAR10/seed=2_pneg[5e-04,0.05].csv"
## [1] "data_Classif_imb_subsets/CIFAR10/seed=1_pneg[0.95,0.9995].csv"
## [1] "data_Classif_imb_subsets/CIFAR10/seed=2_pneg[0.95,0.9995].csv"
## [1] "data_Classif_imb_subsets/MNIST/seed=1_pneg[5e-04,0.05].csv"
## [1] "data_Classif_imb_subsets/MNIST/seed=2_pneg[5e-04,0.05].csv"
## [1] "data_Classif_imb_subsets/MNIST/seed=1_pneg[0.95,0.9995].csv"
## [1] "data_Classif_imb_subsets/MNIST/seed=2_pneg[0.95,0.9995].csv"
## [1] "data_Classif_imb_subsets/EMNIST/seed=1_pneg[5e-04,0.05].csv"
## [1] "data_Classif_imb_subsets/EMNIST/seed=2_pneg[5e-04,0.05].csv"
## [1] "data_Classif_imb_subsets/EMNIST/seed=1_pneg[0.95,0.9995].csv"
## [1] "data_Classif_imb_subsets/EMNIST/seed=2_pneg[0.95,0.9995].csv"
## [1] "data_Classif_imb_subsets/FashionMNIST/seed=1_pneg[5e-04,0.05].csv"
## [1] "data_Classif_imb_subsets/FashionMNIST/seed=2_pneg[5e-04,0.05].csv"
## [1] "data_Classif_imb_subsets/FashionMNIST/seed=1_pneg[0.95,0.9995].csv"
## [1] "data_Classif_imb_subsets/FashionMNIST/seed=2_pneg[0.95,0.9995].csv"
## [1] "data_Classif_imb_subsets/KMNIST/seed=1_pneg[5e-04,0.05].csv"
## [1] "data_Classif_imb_subsets/KMNIST/seed=2_pneg[5e-04,0.05].csv"
## [1] "data_Classif_imb_subsets/KMNIST/seed=1_pneg[0.95,0.9995].csv"
## [1] "data_Classif_imb_subsets/KMNIST/seed=2_pneg[0.95,0.9995].csv"
## [1] "data_Classif_imb_subsets/QMNIST/seed=1_pneg[5e-04,0.05].csv"
## [1] "data_Classif_imb_subsets/QMNIST/seed=2_pneg[5e-04,0.05].csv"
## [1] "data_Classif_imb_subsets/QMNIST/seed=1_pneg[0.95,0.9995].csv"
## [1] "data_Classif_imb_subsets/QMNIST/seed=2_pneg[0.95,0.9995].csv"
## [1] "data_Classif_imb_subsets/MNIST_EMNIST/seed=1_pneg[5e-04,0.05].csv"
## [1] "data_Classif_imb_subsets/MNIST_EMNIST/seed=2_pneg[5e-04,0.05].csv"
## [1] "data_Classif_imb_subsets/MNIST_EMNIST/seed=1_pneg[0.95,0.9995].csv"
## [1] "data_Classif_imb_subsets/MNIST_EMNIST/seed=2_pneg[0.95,0.9995].csv"
## [1] "data_Classif_imb_subsets/MNIST_EMNIST_rot/seed=1_pneg[5e-04,0.05].csv"
## [1] "data_Classif_imb_subsets/MNIST_EMNIST_rot/seed=2_pneg[5e-04,0.05].csv"
## [1] "data_Classif_imb_subsets/MNIST_EMNIST_rot/seed=1_pneg[0.95,0.9995].csv"
## [1] "data_Classif_imb_subsets/MNIST_EMNIST_rot/seed=2_pneg[0.95,0.9995].csv"
## [1] "data_Classif_imb_subsets/MNIST_FashionMNIST/seed=1_pneg[5e-04,0.05].csv"
## [1] "data_Classif_imb_subsets/MNIST_FashionMNIST/seed=2_pneg[5e-04,0.05].csv"
## [1] "data_Classif_imb_subsets/MNIST_FashionMNIST/seed=1_pneg[0.95,0.9995].csv"
## [1] "data_Classif_imb_subsets/MNIST_FashionMNIST/seed=2_pneg[0.95,0.9995].csv"
## [1] "data_Classif_imb_subsets/FishSonar_river/seed=1_pneg[5e-05,0.05].csv"
## [1] "data_Classif_imb_subsets/FishSonar_river/seed=2_pneg[5e-05,0.05].csv"
## [1] "data_Classif_imb_subsets/FishSonar_river/seed=1_pneg[0.95,0.99995].csv"
## [1] "data_Classif_imb_subsets/FishSonar_river/seed=2_pneg[0.95,0.99995].csv"
```

``` r
table(data.sub.dt$fold, paste(data.sub.dt[["Xb_Yineg0.99995"]], data.dt$odd))
```

```
##    
##       NA 0   NA 1    X 0    X 1    Y 0    Y 1
##   1 224527  67719  67726  67726 135445      7
##   2 224527  67719  67726  67726 135445      7
##   3 224527  67719  67726  67726 135445      7
##   4 224526  67719  67726  67726 135445      7
##   5 224526  67719  67725  67725 135444      6
```


``` r
cat(system("du -ms data_Classif_imb_subsets/*/*", intern=TRUE), sep="\n")
```

```
## 1	data_Classif_imb_subsets/CIFAR10/seed=1_pneg[0.95,0.9995].csv
## 1	data_Classif_imb_subsets/CIFAR10/seed=1_pneg[5e-04,0.05].csv
## 1	data_Classif_imb_subsets/CIFAR10/seed=2_pneg[0.95,0.9995].csv
## 1	data_Classif_imb_subsets/CIFAR10/seed=2_pneg[5e-04,0.05].csv
## 1	data_Classif_imb_subsets/EMNIST/seed=1_pneg[0.95,0.9995].csv
## 1	data_Classif_imb_subsets/EMNIST/seed=1_pneg[5e-04,0.05].csv
## 1	data_Classif_imb_subsets/EMNIST/seed=2_pneg[0.95,0.9995].csv
## 1	data_Classif_imb_subsets/EMNIST/seed=2_pneg[5e-04,0.05].csv
## 1	data_Classif_imb_subsets/FashionMNIST/seed=1_pneg[0.95,0.9995].csv
## 1	data_Classif_imb_subsets/FashionMNIST/seed=1_pneg[5e-04,0.05].csv
## 1	data_Classif_imb_subsets/FashionMNIST/seed=2_pneg[0.95,0.9995].csv
## 1	data_Classif_imb_subsets/FashionMNIST/seed=2_pneg[5e-04,0.05].csv
## 42	data_Classif_imb_subsets/FishSonar_river/seed=1_pneg[0.95,0.99995].csv
## 38	data_Classif_imb_subsets/FishSonar_river/seed=1_pneg[5e-05,0.05].csv
## 42	data_Classif_imb_subsets/FishSonar_river/seed=2_pneg[0.95,0.99995].csv
## 38	data_Classif_imb_subsets/FishSonar_river/seed=2_pneg[5e-05,0.05].csv
## 1	data_Classif_imb_subsets/KMNIST/seed=1_pneg[0.95,0.9995].csv
## 1	data_Classif_imb_subsets/KMNIST/seed=1_pneg[5e-04,0.05].csv
## 1	data_Classif_imb_subsets/KMNIST/seed=2_pneg[0.95,0.9995].csv
## 1	data_Classif_imb_subsets/KMNIST/seed=2_pneg[5e-04,0.05].csv
## 1	data_Classif_imb_subsets/MNIST/seed=1_pneg[0.95,0.9995].csv
## 1	data_Classif_imb_subsets/MNIST/seed=1_pneg[5e-04,0.05].csv
## 1	data_Classif_imb_subsets/MNIST/seed=2_pneg[0.95,0.9995].csv
## 1	data_Classif_imb_subsets/MNIST/seed=2_pneg[5e-04,0.05].csv
## 2	data_Classif_imb_subsets/MNIST_EMNIST/seed=1_pneg[0.95,0.9995].csv
## 2	data_Classif_imb_subsets/MNIST_EMNIST/seed=1_pneg[5e-04,0.05].csv
## 2	data_Classif_imb_subsets/MNIST_EMNIST/seed=2_pneg[0.95,0.9995].csv
## 2	data_Classif_imb_subsets/MNIST_EMNIST/seed=2_pneg[5e-04,0.05].csv
## 2	data_Classif_imb_subsets/MNIST_EMNIST_rot/seed=1_pneg[0.95,0.9995].csv
## 2	data_Classif_imb_subsets/MNIST_EMNIST_rot/seed=1_pneg[5e-04,0.05].csv
## 2	data_Classif_imb_subsets/MNIST_EMNIST_rot/seed=2_pneg[0.95,0.9995].csv
## 2	data_Classif_imb_subsets/MNIST_EMNIST_rot/seed=2_pneg[5e-04,0.05].csv
## 2	data_Classif_imb_subsets/MNIST_FashionMNIST/seed=1_pneg[0.95,0.9995].csv
## 2	data_Classif_imb_subsets/MNIST_FashionMNIST/seed=1_pneg[5e-04,0.05].csv
## 2	data_Classif_imb_subsets/MNIST_FashionMNIST/seed=2_pneg[0.95,0.9995].csv
## 2	data_Classif_imb_subsets/MNIST_FashionMNIST/seed=2_pneg[5e-04,0.05].csv
## 2	data_Classif_imb_subsets/QMNIST/seed=1_pneg[0.95,0.9995].csv
## 2	data_Classif_imb_subsets/QMNIST/seed=1_pneg[5e-04,0.05].csv
## 2	data_Classif_imb_subsets/QMNIST/seed=2_pneg[0.95,0.9995].csv
## 2	data_Classif_imb_subsets/QMNIST/seed=2_pneg[5e-04,0.05].csv
```

Above we can see the csv files created are from 1 to 42 MB.

## Session info


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
##  [1] LC_CTYPE=en_US.UTF-8       LC_NUMERIC=C               LC_TIME=fr_FR.UTF-8        LC_COLLATE=en_US.UTF-8    
##  [5] LC_MONETARY=fr_FR.UTF-8    LC_MESSAGES=en_US.UTF-8    LC_PAPER=fr_FR.UTF-8       LC_NAME=C                 
##  [9] LC_ADDRESS=C               LC_TELEPHONE=C             LC_MEASUREMENT=fr_FR.UTF-8 LC_IDENTIFICATION=C       
## 
## time zone: America/Toronto
## tzcode source: system (glibc)
## 
## attached base packages:
## [1] stats     graphics  grDevices utils     datasets  methods   base     
## 
## other attached packages:
## [1] data.table_1.18.6.1
## 
## loaded via a namespace (and not attached):
## [1] compiler_4.7.0 nc_2026.4.20   cli_3.6.6      tools_4.7.0    otel_0.2.0     knitr_1.51     xfun_0.60     
## [8] rlang_1.3.0    evaluate_1.0.5
```
