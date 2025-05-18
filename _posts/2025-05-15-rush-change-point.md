---
layout: post
title: Centralized vs de-centralized parallelization
description: Exploring rush
---



I recently wrote about [New parallel computing frameworks in
R](https://tdhock.github.io/blog/2025/rush/), including the
[rush](https://github.com/mlr-org/rush) package by Marc Becker, who I
met in a visit to Bernd Bischl's lab in Munich this week.  The goal of
this blog is to explore different ways rush can be used for parallel
computation of change-point models.

## Genomic data

In the PeakSegDisk package, we have the Mono27ac data set, which
represents part of a genomic profile, with several peaks that
represent active regions.


``` r
data(Mono27ac, package="PeakSegDisk")
library(data.table)
Mono27ac$coverage
```

```
##        chrom chromStart chromEnd count
##       <char>      <int>    <int> <int>
##    1:  chr11      60000   132601     0
##    2:  chr11     132601   132643     1
##    3:  chr11     132643   146765     0
##    4:  chr11     146765   146807     1
##    5:  chr11     146807   175254     0
##   ---                                 
## 6917:  chr11     579752   579792     1
## 6918:  chr11     579792   579794     2
## 6919:  chr11     579794   579834     1
## 6920:  chr11     579834   579980     0
## 6921:  chr11     579980   580000     1
```

These data can be visualized via the code below.


``` r
library(ggplot2)
ggplot()+
  theme_bw()+
  geom_step(aes(
    chromStart/1e3, count),
    color="grey50",
    data=Mono27ac$coverage)
```

![plot of chunk data](/assets/img/2025-05-15-rush-change-point/data-1.png)

## Computing a peak model

We may like to compute a sequence of change-point models for these
data.  In the PeakSegDisk package, you can use the
`sequentialSearch_dir` function to compute a model with a given number
of peaks. You first must save the data to disk, as in the code below.


``` r
data.dir <- file.path(
  tempfile(),
  "H3K27ac-H3K4me3_TDHAM_BP",
  "samples",
  "Mono1_H3K27ac",
  "S001YW_NCMLS",
  "problems",
  "chr11-60000-580000")
dir.create(data.dir, recursive=TRUE, showWarnings=FALSE)
write.table(
  Mono27ac$coverage, file.path(data.dir, "coverage.bedGraph"),
  col.names=FALSE, row.names=FALSE, quote=FALSE, sep="\t")
```

After that, you can run the sequential search algorithm, in parallel
if you declare a future plan as in the code below.


``` r
future::plan("multisession")
fit10 <- PeakSegDisk::sequentialSearch_dir(data.dir, 10L, verbose=1)
```

```
## Next = 0, Inf 
## Next = 157.994737329317 
## Next = 1952.66876946418 
## Next = 21915.161494366 
## Next = 6699.96265606243 
## Next = 3738.08792382758 
## Next = 5674.91008099583
```

The code uses a penalized solver, which means a non-negative penalty
value must be specified as the model complexity hyper-parameter, and
we do not know in advance how many change-points (and peaks) that will
give. The sequential search algorithm evaluates a bunch of different
penalty values until it finds the desired number of peaks (10 in this
case). This model is shown below,


``` r
plot(fit10)+
  geom_step(aes(
    chromStart, count),
    color="grey50",
    data=Mono27ac$coverage)
```

![plot of chunk peaks-10](/assets/img/2025-05-15-rush-change-point/peaks-10-1.png)

The plot above shows that the model change-points are a reasonable fit
to the data, but we may want to examine other model sizes (say from 5
to 15 peaks). 


``` r
target.min.peaks <- 5
target.max.peaks <- 15
```

To do that, we could implement a parallel computation of
the penalty values.  `Next` output above shows the penalties that were
evaluated in the search. We see that the first two penalties are `0`
and `Inf`, which give the largest/smallest change-point models (3199
and 0 peaks in this case). Those are the only two that are evaluated
in parallel. Next, we show how we could evaluate several penalties in
parallel.

## Computing a range of models

Computing a range of change-point model sizes can be implemented using
the CROCS algorithm, described in [our BMC Bioinformatics 2021 paper,
with Arnaud Liehrmann and Guillem
Rigaill](https://bmcbioinformatics.biomedcentral.com/articles/10.1186/s12859-021-04221-5).
To do that, we first compute the most extreme models.


``` r
pen.vec <- c(0,Inf)
loss.dt.list <- list()
for(pen in pen.vec){
  fit <- PeakSegDisk::PeakSegFPOP_dir(data.dir, pen)
  loss.dt.list[[paste(pen)]] <- fit$loss[, .(penalty, peaks, total.loss)]
}
(loss.dt <- rbindlist(loss.dt.list))
```

```
##    penalty peaks total.loss
##      <num> <int>      <num>
## 1:       0  3199  -130227.3
## 2:     Inf     0   375197.9
```

The table above shows the number of peaks and Poisson loss values for
the two models. The optimization objective is the cost plus the
penalty times the number of peaks. Therefore, the number of peaks
selected for a given penalty is the argmin of a finite number of
linear functions. Each linear function has slope equal to number of
peaks, and intercept equal to total Poisson loss.  We can compute an
estimate of a model selection function, which maps penalty/lambda
values to model sizes (in peaks) via the code below.


``` r
get_selection <- function(loss){
  selection.df <- penaltyLearning::modelSelection(loss, "total.loss", "peaks")
  with(selection.df, data.table(
    total.loss,
    min.lambda,
    penalty,
    max.lambda,
    peaks_after=c(peaks[-1],NA),
    peaks
  ))[
  , helpful := peaks_after<target.max.peaks & peaks>target.min.peaks &
      peaks_after+1 < peaks & !max.lambda %in% names(loss.dt.list)
  ][]
}
(selection.dt <- get_selection(loss.dt))
```

```
##    total.loss min.lambda penalty max.lambda peaks_after peaks helpful
##         <num>      <num>   <num>      <num>       <int> <int>  <lgcl>
## 1:  -130227.3     0.0000       0   157.9947           0  3199    TRUE
## 2:   375197.9   157.9947     Inf        Inf          NA     0   FALSE
```

The table above has columns for `min.lambda` and `max.lambda`, which
indicate a range of penalties for which we have evidence that `peaks`
may be selected. We can visualize these functions via the plot below,


``` r
get_gg <- function(){
  dot.dt <- rbind(
    data.table(loss.dt[, .(
      penalty, peaks, total.loss, helpful=FALSE)], dot="evaluated"),
    data.table(selection.dt[-.N, .(
      penalty=max.lambda, peaks, total.loss, helpful)], dot="candidate"))
  ggplot()+
    geom_abline(aes(
      slope=peaks,
      intercept=total.loss),
      data=loss.dt)+
    geom_point(aes(
      penalty,
      total.loss+ifelse(peaks==0, 0, penalty*peaks),
      color=helpful),
      size=5,
      data=dot.dt)+
    geom_point(aes(
      penalty,
      total.loss+ifelse(peaks==0, 0, penalty*peaks),
      color=helpful,
      fill=dot),
      shape=21,
      size=4,
      data=dot.dt)+
    geom_label(aes(
      penalty,
      total.loss+ifelse(peaks==0, 0, penalty*peaks),
      hjust=ifelse(penalty==Inf, 1, 0.5),
      label=peaks),
      vjust=1.5,
      alpha=0.5,
      data=dot.dt[dot=="evaluated"])+
    scale_fill_manual(values=c(evaluated="white", candidate="black"))+
    scale_color_manual(values=c("TRUE"="red", "FALSE"="black"))+
    scale_y_continuous("Cost = Loss + penalty * peaks")
}
get_gg()
```

![plot of chunk model-sel](/assets/img/2025-05-15-rush-change-point/model-sel-1.png)

``` r
pen <- selection.dt$max.lambda[1]
```

We see in the plot above that there is an intersection of these
functions at penalty=157.9947373. Since these functions are for
3199 and 0 peaks, and our target numbers of peaks is between (5 to
15), we are guaranteed to make progress if we compute a new penalty at
the intersection point. We do that in the code below,


``` r
fit <- PeakSegDisk::PeakSegFPOP_dir(data.dir, pen)
loss.dt.list[[paste(pen)]] <- fit$loss[, .(penalty, peaks, total.loss)]
(loss.dt <- rbindlist(loss.dt.list))
```

```
##     penalty peaks total.loss
##       <num> <int>      <num>
## 1:   0.0000  3199 -130227.29
## 2:      Inf     0  375197.87
## 3: 157.9947   224  -62199.93
```

We see in the new loss table that there is an intermediate number of
peaks, 224.  This results in two intersection point
candidates (the first two rows of the table below).


``` r
(selection.dt <- get_selection(loss.dt))
```

```
##    total.loss min.lambda  penalty max.lambda peaks_after peaks helpful
##         <num>      <num>    <num>      <num>       <int> <int>  <lgcl>
## 1: -130227.29    0.00000   0.0000   22.86634         224  3199   FALSE
## 2:  -62199.93   22.86634 157.9947 1952.66877           0   224    TRUE
## 3:  375197.87 1952.66877      Inf        Inf          NA     0   FALSE
```

``` r
get_gg()
```

![plot of chunk model-sel-3](/assets/img/2025-05-15-rush-change-point/model-sel-3-1.png)

We see in the figure above that only one of the two candidates is helpful toward our goal of computing models between 5 and 15 peaks.
We can evaluate the penalty at that candidate in order to make progress.
Let's keep going until we have more than one interesting/helpful candidate.


``` r
while(sum(selection.dt$helpful)==1){
  pen <- selection.dt[helpful==TRUE, max.lambda]
  fit <- PeakSegDisk::PeakSegFPOP_dir(data.dir, pen)
  print(loss.dt.list[[paste(pen)]] <- fit$loss[, .(penalty, peaks, total.loss)])
  loss.dt <- rbindlist(loss.dt.list)
  selection.dt <- get_selection(loss.dt)
}
```

```
##     penalty peaks total.loss
##       <num> <int>      <num>
## 1: 1952.669    17   2640.128
##     penalty peaks total.loss
##       <num> <int>      <num>
## 1: 21915.16     4   89739.64
##     penalty peaks total.loss
##       <num> <int>      <num>
## 1: 6699.963     8   36282.92
```

``` r
selection.dt
```

```
##     total.loss  min.lambda    penalty  max.lambda peaks_after peaks helpful
##          <num>       <num>      <num>       <num>       <int> <int>  <lgcl>
## 1: -130227.291     0.00000     0.0000    22.86634         224  3199   FALSE
## 2:  -62199.931    22.86634   157.9947   313.23700          17   224   FALSE
## 3:    2640.128   313.23700  1952.6688  3738.08792           8    17    TRUE
## 4:   36282.919  3738.08792  6699.9627 13364.18080           4     8    TRUE
## 5:   89739.642 13364.18080 21915.1615 71364.55772           0     4   FALSE
## 6:  375197.873 71364.55772        Inf         Inf          NA     0   FALSE
```

The output above shows that there are now two helpful candidates. The
code below visualizes them.


``` r
get_gg()
```

![plot of chunk model-sel-6](/assets/img/2025-05-15-rush-change-point/model-sel-6-1.png)

Above we see that there are 5 candidate penalties, but only 2 helpful
penalties that would make progress toward computing all
models between 5 and 15 peaks.
At this point we may think of how to parallelize.

## Centralized launching, future.apply

One way to do it is by first computing the candidate penalties in a
central process, then sending those penalties to workers for
computation. That is implemented in the code below.


``` r
pen.list <- list()
seq_it <- function(){
  pen.vec <- selection.dt[helpful==TRUE, max.lambda]
  pen.list[[length(pen.list)+1]] <<- pen.vec
  loss.dt.list[paste(pen.vec)] <<- future.apply::future_lapply(pen.vec, function(pen){
    fit <- PeakSegDisk::PeakSegFPOP_dir(data.dir, pen)
    fit$loss[, .(penalty, peaks, total.loss)]
  })
  loss.dt <<- rbindlist(loss.dt.list)
  selection.dt <<- get_selection(loss.dt)
  get_gg()
}
seq_it()
```

![plot of chunk pit-1](/assets/img/2025-05-15-rush-change-point/pit-1-1.png)

After the first parallel iteration above, we see four helpful candidates.


``` r
seq_it()
```

![plot of chunk pit-2](/assets/img/2025-05-15-rush-change-point/pit-2-1.png)

Let's keep going.


``` r
while(any(selection.dt$helpful)){
  gg <- seq_it()
}
gg
```

![plot of chunk pit-3](/assets/img/2025-05-15-rush-change-point/pit-3-1.png)

``` r
selection.dt
```

```
##      total.loss  min.lambda    penalty  max.lambda peaks_after peaks helpful
##           <num>       <num>      <num>       <num>       <int> <int>  <lgcl>
##  1: -130227.291     0.00000     0.0000    22.86634         224  3199   FALSE
##  2:  -62199.931    22.86634   157.9947   313.23700          17   224   FALSE
##  3:    2640.128   313.23700  1952.6688  2512.24686          16    17   FALSE
##  4:    5152.375  2512.24686  2729.6793  2729.67926          14    16   FALSE
##  5:   10611.733  2729.67926  2740.3022  2761.54815          13    14   FALSE
##  6:   13373.281  2761.54815  2769.6768  2868.53480          12    13   FALSE
##  7:   16241.816  2868.53480  2942.4538  3016.37275          11    12   FALSE
##  8:   19258.189  3016.37275  3738.0879  4850.20081          10    11   FALSE
##  9:   24108.390  4850.20081  5674.9101  5956.50214           9    10   FALSE
## 10:   30064.892  5956.50214  6087.2647  6218.02730           8     9   FALSE
## 11:   36282.919  6218.02730  6699.9627  7562.33626           7     8   FALSE
## 12:   43845.255  7562.33626  9400.8673 11239.39840           6     7   FALSE
## 13:   55084.654 11239.39840 13364.1808 15609.51789           5     6   FALSE
## 14:   70694.172 15609.51789 17327.4943 19045.47066           4     5   FALSE
## 15:   89739.642 19045.47066 21915.1615 71364.55772           0     4   FALSE
## 16:  375197.873 71364.55772        Inf         Inf          NA     0   FALSE
```

We see in the table above that there are 16 iterations total.

### Coding a function

Overall the algorithm which uses a central launcher to determine
candidates can be implemented via the code below.


``` r
central_launch <- function(target.min.peaks, target.max.peaks){
  data.dir <- file.path(
    tempfile(),
    "H3K27ac-H3K4me3_TDHAM_BP",
    "samples",
    "Mono1_H3K27ac",
    "S001YW_NCMLS",
    "problems",
    "chr11-60000-580000")
  dir.create(data.dir, recursive=TRUE, showWarnings=FALSE)
  write.table(
    Mono27ac$coverage, file.path(data.dir, "coverage.bedGraph"),
    col.names=FALSE, row.names=FALSE, quote=FALSE, sep="\t")
  pen.vec <- c(0,Inf)
  loss.dt.list <- list()
  cand.dt.list <- list()
  iteration <- 1L
  while(length(pen.vec)){
    loss.dt.list[paste(pen.vec)] <- future.apply::future_lapply(
      pen.vec, function(pen){
        start.time <- Sys.time()
        fit <- PeakSegDisk::PeakSegFPOP_dir(data.dir, pen)
        fit$loss[, .(
          penalty, peaks, total.loss, iteration,
          process=factor(Sys.getpid()), start.time, end.time=Sys.time())]
      }
    )
    start.time <- Sys.time()
    loss.dt <- rbindlist(loss.dt.list)
    selection.df <- penaltyLearning::modelSelection(loss.dt, "total.loss", "peaks")
    selection.dt <- with(selection.df, data.table(
      total.loss,
      min.lambda,
      penalty,
      max.lambda,
      peaks_after=c(peaks[-1],NA),
      peaks
    ))[
    , helpful := peaks_after<target.max.peaks & peaks>target.min.peaks &
        peaks_after+1 < peaks & !max.lambda %in% names(loss.dt.list)
    ][]
    pen.vec <- selection.dt[helpful==TRUE, max.lambda]
    cand.dt.list[[length(cand.dt.list)+1]] <- data.table(
      iteration,
      process=factor("central"), start.time, end.time=Sys.time())
    iteration <- iteration+1L
  }
  list(loss=loss.dt, candidates=rbindlist(cand.dt.list))
}
(loss_5_15 <- central_launch(5,15))
```

```
## $loss
##        penalty peaks  total.loss iteration process          start.time            end.time
##          <num> <int>       <num>     <int>  <fctr>              <POSc>              <POSc>
##  1:     0.0000  3199 -130227.291         1  197162 2025-05-18 09:28:32 2025-05-18 09:28:32
##  2:        Inf     0  375197.873         1  197166 2025-05-18 09:28:32 2025-05-18 09:28:32
##  3:   157.9947   224  -62199.931         2  197162 2025-05-18 09:28:33 2025-05-18 09:28:33
##  4:  1952.6688    17    2640.128         3  197162 2025-05-18 09:28:33 2025-05-18 09:28:33
##  5: 21915.1615     4   89739.642         4  197162 2025-05-18 09:28:33 2025-05-18 09:28:33
##  6:  6699.9627     8   36282.919         5  197162 2025-05-18 09:28:33 2025-05-18 09:28:34
##  7:  3738.0879    11   19258.189         6  197162 2025-05-18 09:28:34 2025-05-18 09:28:34
##  8: 13364.1808     6   55084.654         6  197166 2025-05-18 09:28:34 2025-05-18 09:28:34
##  9:  2769.6768    13   13373.281         7  197162 2025-05-18 09:28:34 2025-05-18 09:28:34
## 10:  5674.9101    10   24108.390         7  197166 2025-05-18 09:28:34 2025-05-18 09:28:34
## 11:  9400.8673     7   43845.255         7  197165 2025-05-18 09:28:34 2025-05-18 09:28:34
## 12: 17327.4943     5   70694.172         7  197158 2025-05-18 09:28:35 2025-05-18 09:28:35
## 13:  2683.2884    16    5152.375         8  197162 2025-05-18 09:28:35 2025-05-18 09:28:35
## 14:  2942.4538    12   16241.816         8  197166 2025-05-18 09:28:35 2025-05-18 09:28:35
## 15:  6087.2647     9   30064.892         8  197165 2025-05-18 09:28:35 2025-05-18 09:28:35
## 16:  2740.3022    14   10611.733         9  197162 2025-05-18 09:28:35 2025-05-18 09:28:36
## 17:  2729.6793    16    5152.375        10  197162 2025-05-18 09:28:36 2025-05-18 09:28:36
## 18:  2729.6793    16    5152.375        11  197162 2025-05-18 09:28:36 2025-05-18 09:28:36
## 
## $candidates
##     iteration process          start.time            end.time
##         <int>  <fctr>              <POSc>              <POSc>
##  1:         1 central 2025-05-18 09:28:32 2025-05-18 09:28:32
##  2:         2 central 2025-05-18 09:28:33 2025-05-18 09:28:33
##  3:         3 central 2025-05-18 09:28:33 2025-05-18 09:28:33
##  4:         4 central 2025-05-18 09:28:33 2025-05-18 09:28:33
##  5:         5 central 2025-05-18 09:28:34 2025-05-18 09:28:34
##  6:         6 central 2025-05-18 09:28:34 2025-05-18 09:28:34
##  7:         7 central 2025-05-18 09:28:35 2025-05-18 09:28:35
##  8:         8 central 2025-05-18 09:28:35 2025-05-18 09:28:35
##  9:         9 central 2025-05-18 09:28:36 2025-05-18 09:28:36
## 10:        10 central 2025-05-18 09:28:36 2025-05-18 09:28:36
## 11:        11 central 2025-05-18 09:28:36 2025-05-18 09:28:36
```

The result is a list of two tables:

* `loss` has one row per penalty value computed.
* `candidates` has one row per computation of new candidates.


``` r
viz_workers <- function(L){
  min.time <- min(L$loss$start.time)
  for(N in names(L)){
    L[[N]] <- data.table(L[[N]], computation=N)
    for(pos in c("start", "end")){
      time.vec <- L[[N]][[paste0(pos,".time")]]
      set(L[[N]], j=paste0(pos,".seconds"), value=time.vec-min.time)
    }
  }
  ##L$cand$process <- L$loss[, .(count=.N), by=process][order(-count)][1, process]
  biggest.diff <- L$loss[,as.numeric(diff(c(min(start.seconds),max(end.seconds))))]
  n.proc <- length(unique(L$loss$process))
  best.seconds <- n.proc*biggest.diff
  total.seconds <- L$loss[,sum(end.seconds-start.seconds)]
  efficiency <- total.seconds/best.seconds
  seg.dt <- rbind(L$cand,L$loss[,names(L$cand),with=FALSE])
  text.dt <- L$loss[,.(
    mid.seconds=as.POSIXct((as.numeric(min(start.seconds))+as.numeric(max(end.seconds)))/2),
    label=paste(peaks,collapse=",")
  ),by=.(process,iteration)]
  it.dt <- seg.dt[, .(min.seconds=min(start.seconds), max.seconds=max(end.seconds)), by=iteration]
  ggplot()+
    theme_bw()+
    ggtitle(sprintf("Worker efficiency = %.1f%%", 100*total.seconds/best.seconds))+
    geom_rect(aes(
      xmin=min.seconds, xmax=max.seconds,
      ymin=-Inf, ymax=Inf),
      fill="grey",
      data=it.dt)+
    geom_text(aes(
      x=(min.seconds+max.seconds)/2, Inf,
      hjust=ifelse(iteration==1, 1, 0.5),
      label=paste0(ifelse(iteration==1, "it=", ""), iteration)),
      data=it.dt,
      vjust=1)+
    geom_segment(aes(
      start.seconds, process,
      color=computation,
      xend=end.seconds, yend=process),
      data=seg.dt)+
    geom_point(aes(
      start.seconds, process,
      color=computation),
      shape=1,
      data=seg.dt)+
    geom_text(aes(
      mid.seconds, process, label=label),
      vjust=1.5,
      data=text.dt)+
    scale_color_manual(values=c(
      loss="black",
      candidates="red"))+
    scale_y_discrete("process")+
    scale_x_continuous("time (seconds)")
}
viz_workers(loss_5_15)
```

![plot of chunk central-5-15](/assets/img/2025-05-15-rush-change-point/central-5-15-1.png)

The figure above shows how the computation proceeds over time (X axis)
in the different parallel processes (Y axis). Iterations are shown in
grey rectangles, with iteration numbers at the top of the plot. In
each iteration, There are at most four parallel workers (black) at any
given time.


``` r
(loss_1_100 <- central_launch(1,100))
```

```
## $loss
##        penalty peaks  total.loss iteration process          start.time            end.time
##          <num> <int>       <num>     <int>  <fctr>              <POSc>              <POSc>
##   1:    0.0000  3199 -130227.291         1  197162 2025-05-18 09:28:37 2025-05-18 09:28:37
##   2:       Inf     0  375197.873         1  197166 2025-05-18 09:28:37 2025-05-18 09:28:37
##   3:  157.9947   224  -62199.931         2  197162 2025-05-18 09:28:37 2025-05-18 09:28:37
##   4: 1952.6688    17    2640.128         3  197162 2025-05-18 09:28:37 2025-05-18 09:28:37
##   5:  313.2370    74  -31865.715         4  197162 2025-05-18 09:28:37 2025-05-18 09:28:38
##  ---                                                                                      
## 112:  314.0074    74  -31865.715        13  197158 2025-05-18 09:28:52 2025-05-18 09:28:52
## 113:  327.0344    62  -28011.480        13  197161 2025-05-18 09:28:52 2025-05-18 09:28:52
## 114:  247.0699    95  -37499.236        14  197162 2025-05-18 09:28:53 2025-05-18 09:28:53
## 115:  247.5600    95  -37499.236        14  197166 2025-05-18 09:28:53 2025-05-18 09:28:53
## 116:  327.0344    62  -28011.480        14  197165 2025-05-18 09:28:53 2025-05-18 09:28:53
## 
## $candidates
##     iteration process          start.time            end.time
##         <int>  <fctr>              <POSc>              <POSc>
##  1:         1 central 2025-05-18 09:28:37 2025-05-18 09:28:37
##  2:         2 central 2025-05-18 09:28:37 2025-05-18 09:28:37
##  3:         3 central 2025-05-18 09:28:37 2025-05-18 09:28:37
##  4:         4 central 2025-05-18 09:28:38 2025-05-18 09:28:38
##  5:         5 central 2025-05-18 09:28:39 2025-05-18 09:28:39
##  6:         6 central 2025-05-18 09:28:40 2025-05-18 09:28:40
##  7:         7 central 2025-05-18 09:28:41 2025-05-18 09:28:41
##  8:         8 central 2025-05-18 09:28:43 2025-05-18 09:28:43
##  9:         9 central 2025-05-18 09:28:46 2025-05-18 09:28:46
## 10:        10 central 2025-05-18 09:28:48 2025-05-18 09:28:48
## 11:        11 central 2025-05-18 09:28:50 2025-05-18 09:28:50
## 12:        12 central 2025-05-18 09:28:51 2025-05-18 09:28:51
## 13:        13 central 2025-05-18 09:28:52 2025-05-18 09:28:52
## 14:        14 central 2025-05-18 09:28:53 2025-05-18 09:28:53
```

``` r
viz_workers(loss_1_100)
```

![plot of chunk central-1-100](/assets/img/2025-05-15-rush-change-point/central-1-100-1.png)
