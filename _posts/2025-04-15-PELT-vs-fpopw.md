---
layout: post
title: Comparing change-point pruning methods using square loss
description: Pruned Exact Linear Time (PELT) and Functional Pruning Optimal Partitioning (FPOP)
---



The goal of this post is to compare two pruning methods for speeding
up the optimal partitioning algorithm, similar to [my previous post
using the Poisson
loss](https://tdhock.github.io/blog/2025/PELT-vs-FPOP/).

* We assume that we want to find change-points in a sequence of `N` data.
* All algorithms discussed are instances of dynamic programming, which
  has a for loop over all `N` data. In each iteration, the algorithm
  considers a certain number of candidate change-points `C` (on
  average). The algorithm is overall `O(NC)` time.
* Optimal partitioning (OPART) computes the best segmentation for a
  given loss function, data sequence, and non-negative penalty
  value. Each iteration considers the loss for each previous candidate
  change-point, `C=O(N)` linear time per iteration, which implies
  quadratic `O(N^2)` time overall.
* Pruned Exact Linear Time (PELT) reduces the number of candidate
  change-points that must be considered at each iteration, from the
  whole data sequence size `N`, to the size of a segment `S`, so
  `C=O(S)`. This gives an algorithm which is `O(NS)` time overall.
  * If the number of change-points grows linearly with the data size
    `N`, then the segment size is constant, `S=O(1)` with respect to
    number of data `N`, and the PELT algorithm is indeed linear time
    overall, `O(N)`.
  * However in the case of a constant number of change-points, with
    segment sizes that grow with the data sequence, `S=O(N)` implies
    quadratic time overall, `O(N^2)`.
* Functional Pruning Optimal Partitioning (FPOP) reduces the number of
  candidate change-points to a number which is always less than the
  number considered by PELT (see Maidstone 2017 paper for detailed
  proof). The goal of this post is to show that it prunes more than
  PELT in both cases:
  * If the number of change-points grows linearly with the data size
    `N`, then both PELT and FPOP are `O(N)` overall.
  * If the number of change-points is constant with respect to data
    size `N`, then FPOP considers only `S=O(log N)` change-points
    (empirically), which gives an algorithm that is `O(N log N)`,
    log-linear time overall.

# Simulate data sequences

We simulate data in two scenarios: linear and constant number of changes.


``` r
mean_vec <- c(10,20,5,25)
sim_fun_list <- list(
  constant_changes=function(N){
    rep(mean_vec, each=N/4)
  },
  linear_changes=function(N){
    rep(rep(mean_vec, each=10), l=N)
  })
lapply(sim_fun_list, function(f)f(40))
```

```
## $constant_changes
##  [1] 10 10 10 10 10 10 10 10 10 10 20 20 20 20 20 20 20 20 20 20  5  5  5  5  5  5  5  5  5  5 25 25 25 25 25 25 25 25
## [39] 25 25
## 
## $linear_changes
##  [1] 10 10 10 10 10 10 10 10 10 10 20 20 20 20 20 20 20 20 20 20  5  5  5  5  5  5  5  5  5  5 25 25 25 25 25 25 25 25
## [39] 25 25
```

As can be seen above, both functions return a vector of values that
represent the true segment mean.
Below we use both functions with a three different data sizes.


``` r
library(data.table)
N_data_vec <- c(40, 400)
sim_data_list <- list()
sim_changes_list <- list()
for(N_data in N_data_vec){
  for(simulation in names(sim_fun_list)){
    sim_fun <- sim_fun_list[[simulation]]
    data_mean_vec <- sim_fun(N_data)
    end <- which(diff(data_mean_vec) != 0)
    set.seed(1)
    data_value <- rnorm(N_data, data_mean_vec, 2)
    sim_data_list[[paste(N_data, simulation)]] <- data.table(
      N_data, simulation, data_i=seq_along(data_value), data_value)
    sim_changes_list[[paste(N_data, simulation)]] <- data.table(
      N_data, simulation, end)
  }
}
addSim <- function(DT)DT[, Simulation := paste0("\n", simulation)][]
(sim_changes <- addSim(rbindlist(sim_changes_list)))
```

```
##     N_data       simulation   end         Simulation
##      <num>           <char> <int>             <char>
##  1:     40 constant_changes    10 \nconstant_changes
##  2:     40 constant_changes    20 \nconstant_changes
##  3:     40 constant_changes    30 \nconstant_changes
##  4:     40   linear_changes    10   \nlinear_changes
##  5:     40   linear_changes    20   \nlinear_changes
##  6:     40   linear_changes    30   \nlinear_changes
##  7:    400 constant_changes   100 \nconstant_changes
##  8:    400 constant_changes   200 \nconstant_changes
##  9:    400 constant_changes   300 \nconstant_changes
## 10:    400   linear_changes    10   \nlinear_changes
## 11:    400   linear_changes    20   \nlinear_changes
## 12:    400   linear_changes    30   \nlinear_changes
## 13:    400   linear_changes    40   \nlinear_changes
## 14:    400   linear_changes    50   \nlinear_changes
## 15:    400   linear_changes    60   \nlinear_changes
## 16:    400   linear_changes    70   \nlinear_changes
## 17:    400   linear_changes    80   \nlinear_changes
## 18:    400   linear_changes    90   \nlinear_changes
## 19:    400   linear_changes   100   \nlinear_changes
## 20:    400   linear_changes   110   \nlinear_changes
## 21:    400   linear_changes   120   \nlinear_changes
## 22:    400   linear_changes   130   \nlinear_changes
## 23:    400   linear_changes   140   \nlinear_changes
## 24:    400   linear_changes   150   \nlinear_changes
## 25:    400   linear_changes   160   \nlinear_changes
## 26:    400   linear_changes   170   \nlinear_changes
## 27:    400   linear_changes   180   \nlinear_changes
## 28:    400   linear_changes   190   \nlinear_changes
## 29:    400   linear_changes   200   \nlinear_changes
## 30:    400   linear_changes   210   \nlinear_changes
## 31:    400   linear_changes   220   \nlinear_changes
## 32:    400   linear_changes   230   \nlinear_changes
## 33:    400   linear_changes   240   \nlinear_changes
## 34:    400   linear_changes   250   \nlinear_changes
## 35:    400   linear_changes   260   \nlinear_changes
## 36:    400   linear_changes   270   \nlinear_changes
## 37:    400   linear_changes   280   \nlinear_changes
## 38:    400   linear_changes   290   \nlinear_changes
## 39:    400   linear_changes   300   \nlinear_changes
## 40:    400   linear_changes   310   \nlinear_changes
## 41:    400   linear_changes   320   \nlinear_changes
## 42:    400   linear_changes   330   \nlinear_changes
## 43:    400   linear_changes   340   \nlinear_changes
## 44:    400   linear_changes   350   \nlinear_changes
## 45:    400   linear_changes   360   \nlinear_changes
## 46:    400   linear_changes   370   \nlinear_changes
## 47:    400   linear_changes   380   \nlinear_changes
## 48:    400   linear_changes   390   \nlinear_changes
##     N_data       simulation   end         Simulation
```

Above we see the table of simulated change-points. 

* For `constant_changes` simulation, there are always 3 change-points.
* For `linear_changes` simulation, there are more change-points when
  there are more data.
  
Below we visualize the simulated data.


``` r
(sim_data <- addSim(rbindlist(sim_data_list)))
```

```
##      N_data       simulation data_i data_value         Simulation
##       <num>           <char>  <int>      <num>             <char>
##   1:     40 constant_changes      1   8.747092 \nconstant_changes
##   2:     40 constant_changes      2  10.367287 \nconstant_changes
##   3:     40 constant_changes      3   8.328743 \nconstant_changes
##   4:     40 constant_changes      4  13.190562 \nconstant_changes
##   5:     40 constant_changes      5  10.659016 \nconstant_changes
##  ---                                                             
## 876:    400   linear_changes    396  23.151374   \nlinear_changes
## 877:    400   linear_changes    397  28.185828   \nlinear_changes
## 878:    400   linear_changes    398  25.090021   \nlinear_changes
## 879:    400   linear_changes    399  23.569743   \nlinear_changes
## 880:    400   linear_changes    400  26.730446   \nlinear_changes
```

``` r
library(ggplot2)
ggplot()+
  theme_bw()+
  theme(text=element_text(size=14))+
  geom_vline(aes(
    xintercept=end+0.5),
    data=sim_changes)+
  geom_point(aes(
    data_i, data_value),
    color="grey50",
    data=sim_data)+
  facet_grid(Simulation ~ N_data, labeller=label_both, scales="free_x", space="free")+
  scale_x_continuous(
    breaks=seq(0,max(N_data_vec),by=20))
```

![plot of chunk sim-data](/assets/img/2025-04-15-PELT-vs-fpopw/sim-data-1.png)

We see in the figure above that the data are the same in the two
simulations, when there are only 40 data points. However, when there
are 80 or 160 data, we see a difference:

* For the `constant_changes` simulation, the number of change-points
  is still three (change-point every quarter of the data).
* For the `linear_changes` simulation, the number of change-points has
  increased from 3 to 7 to 15 (change-point every 25 data points).
  
## PELT

Below we define a function which implements PELT for the Poisson loss,
because we used a count data simulation above.


``` r
PELT <- function(sim.mat, penalty, prune=TRUE, verbose=FALSE){
  if(!is.matrix(sim.mat))sim.mat <- cbind(sim.mat)
  cum.data <- rbind(0, apply(sim.mat, 2, cumsum))
  sum_trick <- function(m, start, end)m[end+1,,drop=FALSE]-m[start,,drop=FALSE]
  cost_trick <- function(start, end){
    sum_vec <- sum_trick(cum.data, start, end)
    N <- end+1-start
    -sum_vec^2/N
  }
  N.data <- nrow(sim.mat)
  pelt.change.vec <- rep(NA_integer_, N.data)
  pelt.cost.vec <- rep(NA_real_, N.data+1)
  pelt.cost.vec[1] <- -penalty
  pelt.candidates.vec <- rep(NA_integer_, N.data)
  candidate.vec <- 1L
  if(verbose)index_dt_list <- list()
  for(up.to in 1:N.data){
    N.cand <- length(candidate.vec)
    pelt.candidates.vec[up.to] <- N.cand
    last.seg.cost <- rowSums(cost_trick(candidate.vec, rep(up.to, N.cand)))
    prev.cost <- pelt.cost.vec[candidate.vec]
    cost.no.penalty <- prev.cost+last.seg.cost
    total.cost <- cost.no.penalty+penalty
    if(verbose)index_dt_list[[up.to]] <- data.table(
      data_i=up.to, change_i=candidate.vec, cost=total.cost/up.to)
    best.i <- which.min(total.cost)
    pelt.change.vec[up.to] <- candidate.vec[best.i]
    total.cost.best <- total.cost[best.i]
    pelt.cost.vec[up.to+1] <- total.cost.best
    keep <- if(isTRUE(prune))cost.no.penalty < total.cost.best else TRUE
    candidate.vec <- c(candidate.vec[keep], up.to+1L)
  }
  list(
    change=pelt.change.vec,
    cost=pelt.cost.vec,
    candidates=pelt.candidates.vec,
    index_dt=if(verbose)rbindlist(index_dt_list))
}
decode <- function(best.change){
  seg.dt.list <- list()
  last.i <- length(best.change)
  while(last.i>0){
    first.i <- best.change[last.i]
    seg.dt.list[[paste(last.i)]] <- data.table(
      first.i, last.i)
    last.i <- first.i-1L
  }
  rbindlist(seg.dt.list)[seq(.N,1)]
}
pelt_info_list <- list()
pelt_segs_list <- list()
both_index_list <- list()
penalty <- 100
algo.prune <- c(
  OPART=FALSE,
  PELT=TRUE)
for(N_data in N_data_vec){
  for(simulation in names(sim_fun_list)){
    N_sim <- paste(N_data, simulation)
    data_value <- sim_data_list[[N_sim]]$data_value
    for(algo in names(algo.prune)){
      prune <- algo.prune[[algo]]
      fit <- PELT(data_value, penalty=penalty, prune=prune, verbose = TRUE)
      both_index_list[[paste(N_data, simulation, algo)]] <- data.table(
        N_data, simulation, algo, fit$index_dt)
      fit_seg_dt <- decode(fit$change)
      pelt_info_list[[paste(N_data,simulation,algo)]] <- data.table(
        N_data,simulation,algo,
        candidates=fit$candidates,
        cost=fit$cost[-1],
        data_i=seq_along(data_value))
      pelt_segs_list[[paste(N_data,simulation,algo)]] <- data.table(
        N_data,simulation,algo,
        fit_seg_dt)
    }
  }
}
(pelt_info <- addSim(rbindlist(pelt_info_list)))
```

```
##       N_data       simulation   algo candidates          cost data_i         Simulation
##        <num>           <char> <char>      <int>         <num>  <int>             <char>
##    1:     40 constant_changes  OPART          1     -76.51163      1 \nconstant_changes
##    2:     40 constant_changes  OPART          2    -182.67974      2 \nconstant_changes
##    3:     40 constant_changes  OPART          3    -251.04164      3 \nconstant_changes
##    4:     40 constant_changes  OPART          4    -412.77406      4 \nconstant_changes
##    5:     40 constant_changes  OPART          5    -526.18819      5 \nconstant_changes
##   ---                                                                                  
## 1756:    400   linear_changes   PELT          6 -109335.43620    396   \nlinear_changes
## 1757:    400   linear_changes   PELT          7 -110124.86554    397   \nlinear_changes
## 1758:    400   linear_changes   PELT          8 -110753.45859    398   \nlinear_changes
## 1759:    400   linear_changes   PELT          9 -111303.80462    399   \nlinear_changes
## 1760:    400   linear_changes   PELT         10 -112017.39690    400   \nlinear_changes
```

``` r
(pelt_segs <- addSim(rbindlist(pelt_segs_list)))
```

```
##      N_data       simulation   algo first.i last.i         Simulation
##       <num>           <char> <char>   <int>  <int>             <char>
##   1:     40 constant_changes  OPART       1     10 \nconstant_changes
##   2:     40 constant_changes  OPART      11     20 \nconstant_changes
##   3:     40 constant_changes  OPART      21     30 \nconstant_changes
##   4:     40 constant_changes  OPART      31     40 \nconstant_changes
##   5:     40 constant_changes   PELT       1     10 \nconstant_changes
##  ---                                                                 
## 100:    400   linear_changes   PELT     351    360   \nlinear_changes
## 101:    400   linear_changes   PELT     361    370   \nlinear_changes
## 102:    400   linear_changes   PELT     371    380   \nlinear_changes
## 103:    400   linear_changes   PELT     381    390   \nlinear_changes
## 104:    400   linear_changes   PELT     391    400   \nlinear_changes
```

We see in the result tables above that the segmentations are the same,
using pruning and no pruning. Below we visualize the number of
candidates considered.


``` r
algo.colors <- c(
  OPART="grey50",
  PELT="red",
  FPOP="blue")
ggplot()+
  theme_bw()+
  theme(
    legend.position=c(0.8, 0.2),
    panel.spacing=grid::unit(1,"lines"),
    text=element_text(size=15))+
  geom_vline(aes(
    xintercept=end+0.5),
    data=sim_changes)+
  scale_color_manual(
    breaks=names(algo.colors),
    values=algo.colors)+
  geom_point(aes(
    data_i, candidates, color=algo),
    data=pelt_info)+
  facet_grid(Simulation ~ N_data, labeller=label_both, scales="free_x", space="free")+
  scale_x_continuous(
    breaks=seq(0,max(N_data_vec),by=20))+
  scale_y_continuous(
    breaks=c(10, 100, 400))+
  theme(panel.grid.minor=element_blank())+
  coord_cartesian(expand=FALSE)
```

![plot of chunk pelt-prune](/assets/img/2025-04-15-PELT-vs-fpopw/pelt-prune-1.png)

We can see in the figure above that PELT considers a much smaller
number of change-points, that tends to reset near zero, for each
change-point detected. 

* In the bottom simulation with linear changes, the number of
  change-point candidates considered by PELT is constant (does not
  depend on number of data), so PELT is linear time, whereas OPART is
  quadratic, in the number of data.
* In the top simulation with constant changes, the number of
  change-point candidates considered by PELT is linear in the number
  of data, so both OPART and PELT are quadratic time in the number of
  data.

## FPOP

Now we run FPOP, which is another pruning method, which is more
complex to implement efficiently, so we use C++ code
in the R package fpopw.


``` r
if(FALSE){
  remotes::install_github("TODO")
}
fpop_info_list <- list()
fpop_segs_list <- list()
for(N_data in N_data_vec){
  for(simulation in names(sim_fun_list)){
    N_sim <- paste(N_data, simulation)
    data_value <- sim_data_list[[N_sim]]$data_value
    pfit <- fpopw::Fpop(
      data_value, penalty, verbose_file=tempfile())
    both_index_list[[paste(N_data, simulation, "FPOP")]] <- data.table(
      N_data, simulation, algo="FPOP", pfit$model
    )[, let(
      data_i=data_i+1L,
      change_i=ifelse(change_i == -10, 0, change_i)+1
    )][]
    end <- pfit$t.est
    start <- c(1, end[-length(end)]+1)
    count_dt <- pfit$model[, .(
      intervals=.N,
      cost=min(cost)
    ), by=data_i]
    fpop_info_list[[paste(N_data,simulation)]] <- data.table(
      N_data,simulation,
      algo="FPOP",
      candidates=count_dt$intervals,
      cost=count_dt$cost,
      data_i=seq_along(data_value))
    fpop_segs_list[[paste(N_data,simulation)]] <- data.table(
      N_data,simulation,start,end)
  }
}
(fpop_info <- addSim(rbindlist(fpop_info_list)))
```

```
##      N_data       simulation   algo candidates         cost data_i         Simulation
##       <num>           <char> <char>      <int>        <num>  <int>             <char>
##   1:     40 constant_changes   FPOP          1     -76.5116      1 \nconstant_changes
##   2:     40 constant_changes   FPOP          2    -182.6800      2 \nconstant_changes
##   3:     40 constant_changes   FPOP          3    -251.0420      3 \nconstant_changes
##   4:     40 constant_changes   FPOP          3    -412.7740      4 \nconstant_changes
##   5:     40 constant_changes   FPOP          4    -526.1880      5 \nconstant_changes
##  ---                                                                                 
## 876:    400   linear_changes   FPOP          2 -109335.0000    396   \nlinear_changes
## 877:    400   linear_changes   FPOP          4 -110125.0000    397   \nlinear_changes
## 878:    400   linear_changes   FPOP          3 -110753.0000    398   \nlinear_changes
## 879:    400   linear_changes   FPOP          3 -111304.0000    399   \nlinear_changes
## 880:    400   linear_changes   FPOP          4 -112017.0000    400   \nlinear_changes
```

``` r
(fpop_segs <- rbindlist(fpop_segs_list))
```

```
##     N_data       simulation start   end
##      <num>           <char> <num> <int>
##  1:     40 constant_changes     1    10
##  2:     40 constant_changes    11    20
##  3:     40 constant_changes    21    30
##  4:     40 constant_changes    31    40
##  5:     40   linear_changes     1    10
##  6:     40   linear_changes    11    20
##  7:     40   linear_changes    21    30
##  8:     40   linear_changes    31    40
##  9:    400 constant_changes     1   100
## 10:    400 constant_changes   101   200
## 11:    400 constant_changes   201   300
## 12:    400 constant_changes   301   400
## 13:    400   linear_changes     1    10
## 14:    400   linear_changes    11    20
## 15:    400   linear_changes    21    30
## 16:    400   linear_changes    31    40
## 17:    400   linear_changes    41    50
## 18:    400   linear_changes    51    60
## 19:    400   linear_changes    61    70
## 20:    400   linear_changes    71    80
## 21:    400   linear_changes    81    90
## 22:    400   linear_changes    91   100
## 23:    400   linear_changes   101   110
## 24:    400   linear_changes   111   120
## 25:    400   linear_changes   121   130
## 26:    400   linear_changes   131   140
## 27:    400   linear_changes   141   150
## 28:    400   linear_changes   151   160
## 29:    400   linear_changes   161   170
## 30:    400   linear_changes   171   180
## 31:    400   linear_changes   181   190
## 32:    400   linear_changes   191   200
## 33:    400   linear_changes   201   210
## 34:    400   linear_changes   211   220
## 35:    400   linear_changes   221   230
## 36:    400   linear_changes   231   240
## 37:    400   linear_changes   241   250
## 38:    400   linear_changes   251   260
## 39:    400   linear_changes   261   270
## 40:    400   linear_changes   271   280
## 41:    400   linear_changes   281   290
## 42:    400   linear_changes   291   300
## 43:    400   linear_changes   301   310
## 44:    400   linear_changes   311   320
## 45:    400   linear_changes   321   330
## 46:    400   linear_changes   331   340
## 47:    400   linear_changes   341   350
## 48:    400   linear_changes   351   360
## 49:    400   linear_changes   361   370
## 50:    400   linear_changes   371   380
## 51:    400   linear_changes   381   390
## 52:    400   linear_changes   391   400
##     N_data       simulation start   end
```

``` r
both_info <- rbind(pelt_info, fpop_info)
ggplot()+
  theme_bw()+
  theme(
    legend.position=c(0.8, 0.2),
    panel.spacing=grid::unit(1,"lines"),
    text=element_text(size=15))+
  geom_vline(aes(
    xintercept=end+0.5),
    data=sim_changes)+
  scale_color_manual(
    breaks=names(algo.colors),
    values=algo.colors)+
  geom_point(aes(
    data_i, candidates, color=algo),
    data=both_info)+
  facet_grid(Simulation ~ N_data, labeller=label_both, scales="free_x", space="free")+
  scale_x_continuous(
    breaks=seq(0,max(N_data_vec),by=20))+
  scale_y_continuous(
    breaks=c(10, 100, 400))+
  theme(panel.grid.minor=element_blank())+
  coord_cartesian(expand=FALSE)
```

![plot of chunk fpop-prune](/assets/img/2025-04-15-PELT-vs-fpopw/fpop-prune-1.png)

In the figure above, we can see the advantage of FPOP: the number of
change-points considered does not increase with the number of data,
even with constant number of changes (larger segments).

* In the top simulation with constant changes, the number of
  change-points candidates considered is linear in the number of data,
  so both OPART and PELT are quadratic time in the number of data,
  whereas FPOP is sub-quadratic (empirically linear or log-linear).
  
The table below compares the cost and number of candidates for the last data point.


``` r
both_info[data_i==max(data_i)][order(simulation, algo)]
```

```
##    N_data       simulation   algo candidates      cost data_i         Simulation
##     <num>           <char> <char>      <int>     <num>  <int>             <char>
## 1:    400 constant_changes   FPOP          5 -115415.0    400 \nconstant_changes
## 2:    400 constant_changes  OPART        400 -115415.2    400 \nconstant_changes
## 3:    400 constant_changes   PELT        100 -115415.2    400 \nconstant_changes
## 4:    400   linear_changes   FPOP          4 -112017.0    400   \nlinear_changes
## 5:    400   linear_changes  OPART        400 -112017.4    400   \nlinear_changes
## 6:    400   linear_changes   PELT         10 -112017.4    400   \nlinear_changes
```

We see above that in both simulations, all three algos compute the same cost. 
We also see that the number of candidates is smallest for FPOP in both simulations.
PELT has substantial pruning (10 candidates) for the case of linear changes, 
but not much pruning (100 candidates) for the case of constant changes.

## Heat maps
  
Another way to view this is by looking at the cost of each candidate
change-point considered, as in the heat map below.


``` r
algo.levs <- c("OPART","PELT","FPOP")
(both_index <- addSim(rbindlist(both_index_list, use.names=TRUE))[, let(
  Algorithm = factor(algo, algo.levs)
)][])
```

```
##         N_data       simulation   algo data_i change_i          cost         Simulation Algorithm
##          <num>           <char> <char>  <int>    <num>         <num>             <char>    <fctr>
##      1:     40 constant_changes  OPART      1        1     -76.51163 \nconstant_changes     OPART
##      2:     40 constant_changes  OPART      2        1     -91.33987 \nconstant_changes     OPART
##      3:     40 constant_changes  OPART      2        2     -41.99613 \nconstant_changes     OPART
##      4:     40 constant_changes  OPART      3        1     -83.68055 \nconstant_changes     OPART
##      5:     40 constant_changes  OPART      3        2     -50.42746 \nconstant_changes     OPART
##     ---                                                                                          
## 189190:    400   linear_changes   FPOP    399      399 -111304.00000   \nlinear_changes      FPOP
## 189191:    400   linear_changes   FPOP    400      400 -111918.00000   \nlinear_changes      FPOP
## 189192:    400   linear_changes   FPOP    400      391 -112017.00000   \nlinear_changes      FPOP
## 189193:    400   linear_changes   FPOP    400      399 -112017.00000   \nlinear_changes      FPOP
## 189194:    400   linear_changes   FPOP    400      400 -112017.00000   \nlinear_changes      FPOP
```

``` r
for(a in algo.levs){
  gg <- ggplot()+
    ggtitle(a)+
    theme_bw()+
    theme(
      text=element_text(size=20))+
    coord_equal()+
    geom_tile(aes(
      data_i, change_i, fill=cost),
      data=both_index[Algorithm==a])+
    scale_fill_gradient(low="black", high="red")+
    facet_grid(Simulation ~ N_data, label=label_both)
  print(gg)
}
```

![plot of chunk cost-heat](/assets/img/2025-04-15-PELT-vs-fpopw/cost-heat-1.png)![plot of chunk cost-heat](/assets/img/2025-04-15-PELT-vs-fpopw/cost-heat-2.png)![plot of chunk cost-heat](/assets/img/2025-04-15-PELT-vs-fpopw/cost-heat-3.png)

Another way to visualize it is in the plot below, which super-imposes
the three algos.


``` r
ggplot()+
  theme_bw()+
  theme(
    legend.position=c(0.8, 0.2),
    text=element_text(size=15))+
  geom_tile(aes(
    data_i, change_i, fill=Algorithm),
    data=both_index)+
  scale_fill_manual(values=algo.colors)+
  scale_x_continuous(
    breaks=seq(0,max(N_data_vec),by=20))+
  facet_grid(Simulation ~ N_data, label=label_both, scales="free", space="free")
```

![plot of chunk candidates-compare](/assets/img/2025-04-15-PELT-vs-fpopw/candidates-compare-1.png)

It is clear that FPOP prunes much more than PELT, especially in the
case of constant changes (segments that get larger with the overall
number of data).

## Double check FPOP for constant changes

Before running a simulation on varying data sizes, here we check that
the penalty value results in the right number of change-points, for a
larger data set.


``` r
N_data <- 1e5
sim_fun <- sim_fun_list$constant_changes
data_mean_vec <- sim_fun(N_data)
set.seed(1)
data_value <- rnorm(N_data, data_mean_vec, 2)
pfit <- fpopw::Fpop(data_value, penalty)
pfit$t.est
```

```
## [1]  25000  50000  75000 100000
```

The result above shows that there are four segments detected (three
change-points), which is the expected number in our "constant changes"
simulation.
  
## atime comparison

The `atime()` function can be used to perform asymptotic time/memory/etc comparisons. 
This means that we will increase N, and monitor how fast certain quantities grow with N.
We begin by defining the data sizes N of interest:


``` r
base_N <- c(100,200,400,800)
(all_N <- unlist(lapply(10^seq(0,3), function(x)x*base_N)))
```

```
##  [1] 1e+02 2e+02 4e+02 8e+02 1e+03 2e+03 4e+03 8e+03 1e+04 2e+04 4e+04 8e+04 1e+05 2e+05 4e+05 8e+05
```

The data sizes above are on a log scale between 10 and 1,000,000.
Next, we define a list that enumerates the different combinations in the experiment.


``` r
grid_args <- list(
  list(simulation=names(sim_fun_list)),
  FPOP=quote({
    pfit <- fpopw::Fpop(
      data_list[[simulation]], penalty, verbose_file=tempfile())
    count_dt <- pfit$model[, .(intervals=.N), by=data_i]
    data.frame(
      mean_candidates=mean(count_dt$intervals),
      segments=length(pfit$t.est),
      max_seg_size=max(diff(c(0,pfit$t.est))))
  }))
for(algo in names(algo.prune)){
  prune <- algo.prune[[algo]]
  grid_args[[algo]] <- substitute({
    data_value <- data_list[[simulation]]
    fit <- PELT(data_value, penalty, prune=prune)
    dec <- decode(fit$change)
    data.frame(
      mean_candidates=mean(fit$candidates),
      segments=nrow(dec),
      max_seg_size=max(diff(c(0,dec$last.i))))
  }, list(prune=prune))
}
(expr.list <- do.call(atime::atime_grid, grid_args))
```

```
## $`FPOP simulation=constant_changes`
## {
##     pfit <- fpopw::Fpop(data_list[["constant_changes"]], penalty, 
##         verbose_file = tempfile())
##     count_dt <- pfit$model[, .(intervals = .N), by = data_i]
##     data.frame(mean_candidates = mean(count_dt$intervals), segments = length(pfit$t.est), 
##         max_seg_size = max(diff(c(0, pfit$t.est))))
## }
## 
## $`FPOP simulation=linear_changes`
## {
##     pfit <- fpopw::Fpop(data_list[["linear_changes"]], penalty, 
##         verbose_file = tempfile())
##     count_dt <- pfit$model[, .(intervals = .N), by = data_i]
##     data.frame(mean_candidates = mean(count_dt$intervals), segments = length(pfit$t.est), 
##         max_seg_size = max(diff(c(0, pfit$t.est))))
## }
## 
## $`OPART simulation=constant_changes`
## {
##     data_value <- data_list[["constant_changes"]]
##     fit <- PELT(data_value, penalty, prune = FALSE)
##     dec <- decode(fit$change)
##     data.frame(mean_candidates = mean(fit$candidates), segments = nrow(dec), 
##         max_seg_size = max(diff(c(0, dec$last.i))))
## }
## 
## $`OPART simulation=linear_changes`
## {
##     data_value <- data_list[["linear_changes"]]
##     fit <- PELT(data_value, penalty, prune = FALSE)
##     dec <- decode(fit$change)
##     data.frame(mean_candidates = mean(fit$candidates), segments = nrow(dec), 
##         max_seg_size = max(diff(c(0, dec$last.i))))
## }
## 
## $`PELT simulation=constant_changes`
## {
##     data_value <- data_list[["constant_changes"]]
##     fit <- PELT(data_value, penalty, prune = TRUE)
##     dec <- decode(fit$change)
##     data.frame(mean_candidates = mean(fit$candidates), segments = nrow(dec), 
##         max_seg_size = max(diff(c(0, dec$last.i))))
## }
## 
## $`PELT simulation=linear_changes`
## {
##     data_value <- data_list[["linear_changes"]]
##     fit <- PELT(data_value, penalty, prune = TRUE)
##     dec <- decode(fit$change)
##     data.frame(mean_candidates = mean(fit$candidates), segments = nrow(dec), 
##         max_seg_size = max(diff(c(0, dec$last.i))))
## }
## 
## attr(,"parameters")
##                            expr.name expr.grid       simulation
##                               <char>    <char>           <char>
## 1:  FPOP simulation=constant_changes      FPOP constant_changes
## 2:    FPOP simulation=linear_changes      FPOP   linear_changes
## 3: OPART simulation=constant_changes     OPART constant_changes
## 4:   OPART simulation=linear_changes     OPART   linear_changes
## 5:  PELT simulation=constant_changes      PELT constant_changes
## 6:    PELT simulation=linear_changes      PELT   linear_changes
```

Above we see a list with 6 expressions to run, and
a data table with the corresponding number of rows. Note that each expression 

* returns a data frame with one row and three columns that will be used as units to analyze as a function of N.
* should depend on data size N, which does not appear in the
  expressions above, but it is used to define `data_list` in the `setup`
  argument below:


``` r
cache.rds <- "2025-04-15-PELT-vs-fpopw.rds"
if(file.exists(cache.rds)){
  atime_list <- readRDS(cache.rds)
}else{
  atime_list <- atime::atime(
    N=all_N,
    setup={
      data_list <- list()
      for(simulation in names(sim_fun_list)){
        sim_fun <- sim_fun_list[[simulation]]
        data_mean_vec <- sim_fun(N)
        set.seed(1)
        data_list[[simulation]] <- rnorm(N, data_mean_vec, 2)
      }
    },
    expr.list=expr.list,
    seconds.limit=1,
    result=TRUE)
  saveRDS(atime_list, cache.rds)
}
```

Note in the code above that we run the timing inside `if(file.exists`, which is a caching mechanism.
The result is time-consuming to compute, so the first time it is computed, it is saved to disk as an RDS file, and then subsequently read from disk, to save time.
Finally, we plot the different units as a function of data size N, in the figure below.


``` r
refs_list <- atime::references_best(atime_list)
ggplot()+
  theme(text=element_text(size=12))+
  directlabels::geom_dl(aes(
    N, empirical, color=expr.grid, label=expr.grid),
    data=refs_list$measurements,
    method="right.polygons")+
  geom_line(aes(
    N, empirical, color=expr.grid),
    data=refs_list$measurements)+
  scale_color_manual(
    "algorithm",
    guide="none",
    values=algo.colors)+
  facet_grid(unit ~ simulation, scales="free")+
  scale_x_log10(
    "N = number of data in sequence",
    breaks=10^seq(2,6),
    limits=c(NA, 1e7))+
  scale_y_log10("")
```

![plot of chunk atime](/assets/img/2025-04-15-PELT-vs-fpopw/atime-1.png)

Above the figure shows a different curve for each algorithm, and a
different panel for each simulation and measurement unit. We can observe that

* PELT memory usage in kilobytes has a larger slope for constant
  changes, than for linear changes. This implies a larger asymptotic complexity class.
* The maximum segment size, `max_seg_size`, is the same for all algos,
  indicating that the penalty was chosen appropriately, and the
  algorithms are computing the same optimal solution.
* Similarly, the mean number of candidates considered by the PELT
  algorithm has a larger slope for constant changes (same as
  OPART/linear in N), than for linear changes (relatively constant).
* For PELT seconds, we see a slightly larger slope for seconds in
  constant changes, compared to linear changes.
* As expected, number of `segments` is constant for a constant number
  of changes (left), and increasing for a linear number of changes
  (right).
  
Below we plot the same data in a different way, that facilitates
comparisons across the type of simulation:


``` r
refs_list$meas[, let(
  Simulation = sub("_","\n",simulation),
  Algorithm = factor(expr.grid, algo.levs)
)][]
```

```
##              unit                         expr.name fun.name fun.latex expr.grid       simulation     N         min
##            <char>                            <char>   <char>    <char>    <char>           <char> <num>       <num>
##   1:    kilobytes  FPOP simulation=constant_changes  N log N N \\log N      FPOP constant_changes 1e+02 0.001923004
##   2:    kilobytes    FPOP simulation=linear_changes        N         N      FPOP   linear_changes 1e+02 0.001408322
##   3:    kilobytes OPART simulation=constant_changes      N^2       N^2     OPART constant_changes 1e+02 0.001260418
##   4:    kilobytes   OPART simulation=linear_changes      N^2       N^2     OPART   linear_changes 1e+02 0.001512533
##   5:    kilobytes  PELT simulation=constant_changes      N^2       N^2      PELT constant_changes 1e+02 0.001140889
##  ---                                                                                                               
## 351: max_seg_size  FPOP simulation=constant_changes        N         N      FPOP constant_changes 2e+05 0.623123770
## 352: max_seg_size    FPOP simulation=linear_changes     <NA>      <NA>      FPOP   linear_changes 2e+05 0.233184754
## 353: max_seg_size  FPOP simulation=constant_changes        N         N      FPOP constant_changes 4e+05 1.290217895
## 354: max_seg_size    FPOP simulation=linear_changes     <NA>      <NA>      FPOP   linear_changes 4e+05 0.443653082
## 355: max_seg_size    FPOP simulation=linear_changes     <NA>      <NA>      FPOP   linear_changes 8e+05 0.885131756
##           median     itr/sec    gc/sec n_itr  n_gc            result
##            <num>       <num>     <num> <int> <num>            <list>
##   1: 0.002858013 365.6938245  0.000000    10     0 <data.frame[1x3]>
##   2: 0.001530828 533.7141430  0.000000    10     0 <data.frame[1x3]>
##   3: 0.001293144 738.3972616 82.044140     9     1 <data.frame[1x3]>
##   4: 0.001558449 611.1312545  0.000000    10     0 <data.frame[1x3]>
##   5: 0.001166694 851.7461725  0.000000    10     0 <data.frame[1x3]>
##  ---                                                                
## 351: 0.641284690   1.5820949  4.218920     3     8 <data.frame[1x3]>
## 352: 0.244886809   4.1251651  1.767928     7     3 <data.frame[1x3]>
## 353: 1.375813736   0.7245143  2.173543     3     9 <data.frame[1x3]>
## 354: 0.456961145   2.1281262  2.128126     5     5 <data.frame[1x3]>
## 355: 0.920766190   1.0998402  2.199680     4     8 <data.frame[1x3]>
##                                                                             time             gc    kilobytes
##                                                                           <list>         <list>        <num>
##   1: 0.003070066,0.001923004,0.003146542,0.003012140,0.002854351,0.002861676,... <tbl_df[10x3]>     70.02344
##   2: 0.002941428,0.002967761,0.001904799,0.001537999,0.001408322,0.002046934,... <tbl_df[10x3]>     67.84375
##   3: 0.001540256,0.001308101,0.001289717,0.001285471,0.001260418,0.001270360,... <tbl_df[10x3]>    591.29688
##   4: 0.002236664,0.001681142,0.001622356,0.001579869,0.001556465,0.001548693,... <tbl_df[10x3]>    688.04688
##   5: 0.001226953,0.001175218,0.001158938,0.001140889,0.001169771,0.001188534,... <tbl_df[10x3]>    184.71094
##  ---                                                                                                        
## 351:             0.6956099,0.6400762,0.6635544,0.6434154,0.6335402,0.6296808,... <tbl_df[10x3]> 105870.07031
## 352:             0.2463387,0.2373003,0.2477549,0.2419929,0.2331848,0.2486809,... <tbl_df[10x3]>  44508.32031
## 353:                   1.395968,1.415357,1.298186,1.440683,1.377810,1.358431,... <tbl_df[10x3]> 225719.64062
## 354:             0.4529089,0.4571245,0.4816742,0.4477365,0.4436531,0.4750724,... <tbl_df[10x3]>  88591.41406
## 355:             0.9838015,0.8875762,0.9541982,0.9208012,0.8851318,0.9082240,... <tbl_df[10x3]> 176501.08594
##              q25         q75         max        mean           sd mean_candidates segments max_seg_size
##            <num>       <num>       <num>       <num>        <num>           <num>    <int>        <num>
##   1: 0.002764960 0.002977869 0.003146542 0.002734528 4.167095e-04        3.370000        4           25
##   2: 0.001481299 0.002011400 0.002967761 0.001873662 6.068937e-04        2.910000       10           10
##   3: 0.001277248 0.001482217 0.014063603 0.002625216 4.021341e-03       50.500000        4           25
##   4: 0.001540108 0.001611734 0.002236664 0.001636310 2.166810e-04       50.500000       10           10
##   5: 0.001151836 0.001185205 0.001226953 0.001174059 3.062441e-05       14.270000        4           25
##  ---                                                                                                   
## 351: 0.634362322 0.658519632 0.695609916 0.647364185 2.162043e-02       10.477825        4        50000
## 352: 0.240113910 0.248449421 0.255162677 0.244747063 7.069087e-03        3.426640    20000           13
## 353: 1.360555145 1.396592802 1.440682719 1.371419802 4.733699e-02       11.201395        4       100000
## 354: 0.453699607 0.480023766 0.492920949 0.465406193 1.793952e-02        3.442537    40000           13
## 355: 0.892738178 0.954015948 0.983801528 0.925884297 3.484566e-02        3.442912    80000           13
##                                     expr.class                                       expr.latex    empirical
##                                         <char>                                           <char>        <num>
##   1: FPOP simulation=constant_changes\nN log N FPOP simulation=constant_changes\n$O(N \\log N)$     70.02344
##   2:         FPOP simulation=linear_changes\nN           FPOP simulation=linear_changes\n$O(N)$     67.84375
##   3:    OPART simulation=constant_changes\nN^2      OPART simulation=constant_changes\n$O(N^2)$    591.29688
##   4:      OPART simulation=linear_changes\nN^2        OPART simulation=linear_changes\n$O(N^2)$    688.04688
##   5:     PELT simulation=constant_changes\nN^2       PELT simulation=constant_changes\n$O(N^2)$    184.71094
##  ---                                                                                                        
## 351:       FPOP simulation=constant_changes\nN         FPOP simulation=constant_changes\n$O(N)$  50000.00000
## 352:        FPOP simulation=linear_changes\nNA          FPOP simulation=linear_changes\n$O(NA)$     13.00000
## 353:       FPOP simulation=constant_changes\nN         FPOP simulation=constant_changes\n$O(N)$ 100000.00000
## 354:        FPOP simulation=linear_changes\nNA          FPOP simulation=linear_changes\n$O(NA)$     13.00000
## 355:        FPOP simulation=linear_changes\nNA          FPOP simulation=linear_changes\n$O(NA)$     13.00000
##             Simulation Algorithm
##                 <char>    <fctr>
##   1: constant\nchanges      FPOP
##   2:   linear\nchanges      FPOP
##   3: constant\nchanges     OPART
##   4:   linear\nchanges     OPART
##   5: constant\nchanges      PELT
##  ---                            
## 351: constant\nchanges      FPOP
## 352:   linear\nchanges      FPOP
## 353: constant\nchanges      FPOP
## 354:   linear\nchanges      FPOP
## 355:   linear\nchanges      FPOP
```

``` r
ggplot()+
  theme(
    legend.position="none",
    text=element_text(size=12))+
  directlabels::geom_dl(aes(
    N, empirical, color=Simulation, label=Simulation),
    data=refs_list$measurements,
    method="right.polygons")+
  geom_line(aes(
    N, empirical, color=Simulation),
    data=refs_list$measurements)+
  facet_grid(unit ~ Algorithm, scales="free")+
  scale_x_log10(
    "N = number of data in sequence",
    breaks=10^seq(2,6),
    limits=c(NA, 1e7))+
  scale_y_log10("")
```

![plot of chunk compare-sims](/assets/img/2025-04-15-PELT-vs-fpopw/compare-sims-1.png)

The plot above makes it easier to notice some interesting trends in
the mean number of candidates:

* For PELT and FPOP the mean number of candidates is increases for a
  constant number of changes, but at different rates (FPOP much slower
  than PELT).


``` r
expr.levs <- CJ(
  algo=algo.levs,
  simulation=names(sim_fun_list)
)[algo.levs, paste0(algo,"\n",simulation), on="algo"]
edit_expr <- function(DT)DT[
, expr.name := factor(sub(" simulation=", "\n", expr.name), expr.levs)]
edit_expr(refs_list$meas)
edit_expr(refs_list$plot.ref)
plot(refs_list)+
  theme(panel.spacing=grid::unit(1.5,"lines"))
```

![plot of chunk plot-refs](/assets/img/2025-04-15-PELT-vs-fpopw/plot-refs-1.png)

The plot above is an empirical verification of our earlier complexity claims.

* OPART `mean_candidates` is linear, `O(N)`, and time and memory are
  quadratic, `O(N^2)`.
* PELT with constant changes has linear `mean_candidates`, `O(N)`, and
  quadratic time and memory, `O(N^2)` (same as OPART, no asymptotic speedup).
* PELT with linear changes has sub-linear `mean_candidates` (constant
  or log), and linear or log-linear time/memory.
* FPOP always has sub-linear `mean_candidates` (constant or log), and
  linear or log-linear time/memory.
  
The code/plot below shows the speedups in this case.


``` r
pred_list <- predict(refs_list)
ggplot()+
  theme_bw()+
  theme(text=element_text(size=20))+
  geom_line(aes(
    N, empirical, color=expr.grid),
    data=pred_list$measurements[unit=="seconds"])+
  directlabels::geom_dl(aes(
    N, unit.value, color=expr.grid, label=sprintf(
      "%s\n%s\nN=%s",
      expr.grid,
      ifelse(expr.grid=="FPOP", "C++", "R"),
      format(round(N), big.mark=",", scientific=FALSE, trim=TRUE))),
    data=pred_list$prediction,
    method=list(cex=1.5,"top.polygons"))+
  scale_color_manual(
    "algorithm",
    guide="none",
    values=algo.colors)+
  facet_grid(. ~ simulation, scales="free", labeller=label_both)+
  scale_x_log10(
    "N = number of data in sequence",
    breaks=10^seq(2,5),
    limits=c(NA, 1e6))+
  scale_y_log10(
    "Computation time (seconds)",
    breaks=10^seq(-3,0),
    limits=10^c(-4,1))
```

![plot of chunk pred-seconds](/assets/img/2025-04-15-PELT-vs-fpopw/pred-seconds-1.png)

The figure above shows the throughput (data size N) which is possible
to compute in 1 second using each algorithm. We see that FPOP is
10-100x faster than OPART/PELT. Part of the difference is that
OPART/PELT were coded in R, whereas FPOP was coded in C++
(faster). Another difference is that FPOP is asymptotically faster
with constant changes, as can be seen by a smaller slope for FPOP,
compared to OPART/PELT.

Below we zoom in on the number of candidate change-points considered
by each algorithm.


``` r
cand_dt <- pred_list$measurements[unit=="mean_candidates"]
ggplot()+
  theme_bw()+
  theme(text=element_text(size=20))+
  geom_line(aes(
    N, empirical, color=expr.grid),
    data=cand_dt)+
  directlabels::geom_dl(aes(
    N, empirical, color=expr.grid, label=expr.grid),
    data=cand_dt,
    method=list(cex=2, "right.polygons"))+
  scale_color_manual(
    "algorithm",
    guide="none",
    values=algo.colors)+
  facet_grid(. ~ simulation, scales="free", labeller=label_both)+
  scale_x_log10(
    "N = number of data in sequence",
    breaks=10^seq(2,6),
    limits=c(NA, 1e7))+
  scale_y_log10("Mean number of candidate change-points")
```

![plot of chunk pred-candidates](/assets/img/2025-04-15-PELT-vs-fpopw/pred-candidates-1.png)

The figure above shows that 

* OPART always considers a linear number of candidates (slow).
* PELT also considers a linear number of candidates (slow), when the number
  of changes is constant.
* PELT considers a sub-linear number of candidates (fast), when the
  number of changes is linear.
* FPOP always considers sub-linear number of candidates (fast), which
  is either constant for a linear number of changes, or logarithmic for
  a constant number of changes.

## Conclusions

We have explored three algorithms for optimal change-point detection.

* The classic OPART algorithm is always quadratic time in the number of data to segment.
* The Pruned Exact Linear Time (PELT) algorithm can indeed be linear
  time in the number of data to segment, but only when the number of
  change-points grows with the number of data points. When the number
  of change-points is constant, there are ever-increasing segments,
  and the PELT algorithm must compute a cost for each candidate on
  these large segments; in this situation, PELT suffers from the same
  quadratic time complexity as OPART.
* The FPOP algorithm is fast (linear or log-linear) in both of the
  scenarios we examined.
  
## Session info


``` r
sessionInfo()
```

```
## R version 4.5.0 (2025-04-11)
## Platform: x86_64-pc-linux-gnu
## Running under: Ubuntu 24.04.2 LTS
## 
## Matrix products: default
## BLAS:   /usr/lib/x86_64-linux-gnu/blas/libblas.so.3.12.0 
## LAPACK: /usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.12.0  LAPACK version 3.12.0
## 
## locale:
##  [1] LC_CTYPE=fr_FR.UTF-8       LC_NUMERIC=C               LC_TIME=fr_FR.UTF-8        LC_COLLATE=fr_FR.UTF-8    
##  [5] LC_MONETARY=fr_FR.UTF-8    LC_MESSAGES=fr_FR.UTF-8    LC_PAPER=fr_FR.UTF-8       LC_NAME=C                 
##  [9] LC_ADDRESS=C               LC_TELEPHONE=C             LC_MEASUREMENT=fr_FR.UTF-8 LC_IDENTIFICATION=C       
## 
## time zone: Europe/Paris
## tzcode source: system (glibc)
## 
## attached base packages:
## [1] stats     graphics  grDevices utils     datasets  methods   base     
## 
## other attached packages:
## [1] ggplot2_3.5.1     data.table_1.17.0
## 
## loaded via a namespace (and not attached):
##  [1] crayon_1.5.3           directlabels_2024.1.21 vctrs_0.6.5            cli_3.6.4              knitr_1.50            
##  [6] rlang_1.1.5            xfun_0.51              generics_0.1.3         glue_1.8.0             labeling_0.4.3        
## [11] colorspace_2.1-1       scales_1.3.0           fpopw_1.1              quadprog_1.5-8         grid_4.5.0            
## [16] munsell_0.5.1          evaluate_1.0.3         tibble_3.2.1           lifecycle_1.0.4        compiler_4.5.0        
## [21] dplyr_1.1.4            pkgconfig_2.0.3        atime_2025.4.1         farver_2.1.2           lattice_0.22-6        
## [26] R6_2.6.1               tidyselect_1.2.1       pillar_1.10.1          magrittr_2.0.3         tools_4.5.0           
## [31] withr_3.0.2            gtable_0.3.6
```
