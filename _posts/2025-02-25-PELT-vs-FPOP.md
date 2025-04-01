---
layout: post
title: Comparing pruning methods for optimal partitioning
description: Pruned Exact Linear Time (PELT) and Functional Pruning Optimal Partitioning (FPOP)
---



The goal of this post is to compare two pruning methods for speeding
up the optimal partitioning algorithm.

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
    rep(rep(mean_vec, each=25), l=N)
  })
lapply(sim_fun_list, function(f)f(100))
```

```
## $constant_changes
##   [1] 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 20 20 20 20 20 20 20 20 20 20 20 20 20
##  [39] 20 20 20 20 20 20 20 20 20 20 20 20  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5 25
##  [77] 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25
## 
## $linear_changes
##   [1] 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 20 20 20 20 20 20 20 20 20 20 20 20 20
##  [39] 20 20 20 20 20 20 20 20 20 20 20 20  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5 25
##  [77] 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25
```

As can be seen above, both functions return a vector of values that
represent the true segment mean.
Below we use both functions with a three different data sizes.


``` r
library(data.table)
N_data_vec <- c(100,200,400)
sim_data_list <- list()
sim_changes_list <- list()
for(N_data in N_data_vec){
  for(simulation in names(sim_fun_list)){
    sim_fun <- sim_fun_list[[simulation]]
    data_mean_vec <- sim_fun(N_data)
    end <- which(diff(data_mean_vec) != 0)
    set.seed(1)
    data_value <- rpois(N_data, data_mean_vec)
    sim_data_list[[paste(N_data, simulation)]] <- data.table(
      N_data, simulation, data_index=seq_along(data_value), data_value)
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
##  1:    100 constant_changes    25 \nconstant_changes
##  2:    100 constant_changes    50 \nconstant_changes
##  3:    100 constant_changes    75 \nconstant_changes
##  4:    100   linear_changes    25   \nlinear_changes
##  5:    100   linear_changes    50   \nlinear_changes
##  6:    100   linear_changes    75   \nlinear_changes
##  7:    200 constant_changes    50 \nconstant_changes
##  8:    200 constant_changes   100 \nconstant_changes
##  9:    200 constant_changes   150 \nconstant_changes
## 10:    200   linear_changes    25   \nlinear_changes
## 11:    200   linear_changes    50   \nlinear_changes
## 12:    200   linear_changes    75   \nlinear_changes
## 13:    200   linear_changes   100   \nlinear_changes
## 14:    200   linear_changes   125   \nlinear_changes
## 15:    200   linear_changes   150   \nlinear_changes
## 16:    200   linear_changes   175   \nlinear_changes
## 17:    400 constant_changes   100 \nconstant_changes
## 18:    400 constant_changes   200 \nconstant_changes
## 19:    400 constant_changes   300 \nconstant_changes
## 20:    400   linear_changes    25   \nlinear_changes
## 21:    400   linear_changes    50   \nlinear_changes
## 22:    400   linear_changes    75   \nlinear_changes
## 23:    400   linear_changes   100   \nlinear_changes
## 24:    400   linear_changes   125   \nlinear_changes
## 25:    400   linear_changes   150   \nlinear_changes
## 26:    400   linear_changes   175   \nlinear_changes
## 27:    400   linear_changes   200   \nlinear_changes
## 28:    400   linear_changes   225   \nlinear_changes
## 29:    400   linear_changes   250   \nlinear_changes
## 30:    400   linear_changes   275   \nlinear_changes
## 31:    400   linear_changes   300   \nlinear_changes
## 32:    400   linear_changes   325   \nlinear_changes
## 33:    400   linear_changes   350   \nlinear_changes
## 34:    400   linear_changes   375   \nlinear_changes
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
##       N_data       simulation data_index data_value         Simulation
##        <num>           <char>      <int>      <int>             <char>
##    1:    100 constant_changes          1          8 \nconstant_changes
##    2:    100 constant_changes          2         10 \nconstant_changes
##    3:    100 constant_changes          3          7 \nconstant_changes
##    4:    100 constant_changes          4         11 \nconstant_changes
##    5:    100 constant_changes          5         14 \nconstant_changes
##   ---                                                                 
## 1396:    400   linear_changes        396         24   \nlinear_changes
## 1397:    400   linear_changes        397         20   \nlinear_changes
## 1398:    400   linear_changes        398         22   \nlinear_changes
## 1399:    400   linear_changes        399         21   \nlinear_changes
## 1400:    400   linear_changes        400         23   \nlinear_changes
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
    data_index, data_value),
    color="grey50",
    data=sim_data)+
  facet_grid(Simulation ~ N_data, labeller=label_both, scales="free_x", space="free")+
  scale_x_continuous(
    breaks=seq(0,max(N_data_vec),by=50))
```

![plot of chunk sim-data](/assets/img/2025-02-25-PELT-vs-FPOP/sim-data-1.png)

We see in the figure above that the data are the same in the two
simulations, when there are only 100 data points. However, when there
are 200 or 400 data, we see a difference:

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
    mean_vec <- sum_vec/N
    ifelse(sum_vec==0, 0, sum_vec*(1-log(mean_vec)))
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
      data_index=up.to, change=candidate.vec, cost=total.cost/up.to)
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
penalty <- 10
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
        candidates=fit$candidates,data_index=seq_along(data_value))
      pelt_segs_list[[paste(N_data,simulation,algo)]] <- data.table(
        N_data,simulation,algo,
        fit_seg_dt)
    }
  }
}
(pelt_info <- addSim(rbindlist(pelt_info_list)))
```

```
##       N_data       simulation   algo candidates data_index         Simulation
##        <num>           <char> <char>      <int>      <int>             <char>
##    1:    100 constant_changes  OPART          1          1 \nconstant_changes
##    2:    100 constant_changes  OPART          2          2 \nconstant_changes
##    3:    100 constant_changes  OPART          3          3 \nconstant_changes
##    4:    100 constant_changes  OPART          4          4 \nconstant_changes
##    5:    100 constant_changes  OPART          5          5 \nconstant_changes
##   ---                                                                        
## 2796:    400   linear_changes   PELT         20        396   \nlinear_changes
## 2797:    400   linear_changes   PELT         20        397   \nlinear_changes
## 2798:    400   linear_changes   PELT         21        398   \nlinear_changes
## 2799:    400   linear_changes   PELT         22        399   \nlinear_changes
## 2800:    400   linear_changes   PELT         23        400   \nlinear_changes
```

``` r
(pelt_segs <- addSim(rbindlist(pelt_segs_list)))
```

```
##     N_data       simulation   algo first.i last.i         Simulation
##      <num>           <char> <char>   <int>  <int>             <char>
##  1:    100 constant_changes  OPART       1     25 \nconstant_changes
##  2:    100 constant_changes  OPART      26     50 \nconstant_changes
##  3:    100 constant_changes  OPART      51     75 \nconstant_changes
##  4:    100 constant_changes  OPART      76    100 \nconstant_changes
##  5:    100 constant_changes   PELT       1     25 \nconstant_changes
##  6:    100 constant_changes   PELT      26     50 \nconstant_changes
##  7:    100 constant_changes   PELT      51     75 \nconstant_changes
##  8:    100 constant_changes   PELT      76    100 \nconstant_changes
##  9:    100   linear_changes  OPART       1     25   \nlinear_changes
## 10:    100   linear_changes  OPART      26     50   \nlinear_changes
## 11:    100   linear_changes  OPART      51     75   \nlinear_changes
## 12:    100   linear_changes  OPART      76    100   \nlinear_changes
## 13:    100   linear_changes   PELT       1     25   \nlinear_changes
## 14:    100   linear_changes   PELT      26     50   \nlinear_changes
## 15:    100   linear_changes   PELT      51     75   \nlinear_changes
## 16:    100   linear_changes   PELT      76    100   \nlinear_changes
## 17:    200 constant_changes  OPART       1     50 \nconstant_changes
## 18:    200 constant_changes  OPART      51    100 \nconstant_changes
## 19:    200 constant_changes  OPART     101    150 \nconstant_changes
## 20:    200 constant_changes  OPART     151    200 \nconstant_changes
## 21:    200 constant_changes   PELT       1     50 \nconstant_changes
## 22:    200 constant_changes   PELT      51    100 \nconstant_changes
## 23:    200 constant_changes   PELT     101    150 \nconstant_changes
## 24:    200 constant_changes   PELT     151    200 \nconstant_changes
## 25:    200   linear_changes  OPART       1     25   \nlinear_changes
## 26:    200   linear_changes  OPART      26     50   \nlinear_changes
## 27:    200   linear_changes  OPART      51     75   \nlinear_changes
## 28:    200   linear_changes  OPART      76    100   \nlinear_changes
## 29:    200   linear_changes  OPART     101    125   \nlinear_changes
## 30:    200   linear_changes  OPART     126    150   \nlinear_changes
## 31:    200   linear_changes  OPART     151    175   \nlinear_changes
## 32:    200   linear_changes  OPART     176    200   \nlinear_changes
## 33:    200   linear_changes   PELT       1     25   \nlinear_changes
## 34:    200   linear_changes   PELT      26     50   \nlinear_changes
## 35:    200   linear_changes   PELT      51     75   \nlinear_changes
## 36:    200   linear_changes   PELT      76    100   \nlinear_changes
## 37:    200   linear_changes   PELT     101    125   \nlinear_changes
## 38:    200   linear_changes   PELT     126    150   \nlinear_changes
## 39:    200   linear_changes   PELT     151    175   \nlinear_changes
## 40:    200   linear_changes   PELT     176    200   \nlinear_changes
## 41:    400 constant_changes  OPART       1    100 \nconstant_changes
## 42:    400 constant_changes  OPART     101    200 \nconstant_changes
## 43:    400 constant_changes  OPART     201    300 \nconstant_changes
## 44:    400 constant_changes  OPART     301    400 \nconstant_changes
## 45:    400 constant_changes   PELT       1    100 \nconstant_changes
## 46:    400 constant_changes   PELT     101    200 \nconstant_changes
## 47:    400 constant_changes   PELT     201    300 \nconstant_changes
## 48:    400 constant_changes   PELT     301    400 \nconstant_changes
## 49:    400   linear_changes  OPART       1     25   \nlinear_changes
## 50:    400   linear_changes  OPART      26     50   \nlinear_changes
## 51:    400   linear_changes  OPART      51     75   \nlinear_changes
## 52:    400   linear_changes  OPART      76    100   \nlinear_changes
## 53:    400   linear_changes  OPART     101    125   \nlinear_changes
## 54:    400   linear_changes  OPART     126    150   \nlinear_changes
## 55:    400   linear_changes  OPART     151    175   \nlinear_changes
## 56:    400   linear_changes  OPART     176    201   \nlinear_changes
## 57:    400   linear_changes  OPART     202    224   \nlinear_changes
## 58:    400   linear_changes  OPART     225    250   \nlinear_changes
## 59:    400   linear_changes  OPART     251    275   \nlinear_changes
## 60:    400   linear_changes  OPART     276    300   \nlinear_changes
## 61:    400   linear_changes  OPART     301    325   \nlinear_changes
## 62:    400   linear_changes  OPART     326    350   \nlinear_changes
## 63:    400   linear_changes  OPART     351    375   \nlinear_changes
## 64:    400   linear_changes  OPART     376    400   \nlinear_changes
## 65:    400   linear_changes   PELT       1     25   \nlinear_changes
## 66:    400   linear_changes   PELT      26     50   \nlinear_changes
## 67:    400   linear_changes   PELT      51     75   \nlinear_changes
## 68:    400   linear_changes   PELT      76    100   \nlinear_changes
## 69:    400   linear_changes   PELT     101    125   \nlinear_changes
## 70:    400   linear_changes   PELT     126    150   \nlinear_changes
## 71:    400   linear_changes   PELT     151    175   \nlinear_changes
## 72:    400   linear_changes   PELT     176    201   \nlinear_changes
## 73:    400   linear_changes   PELT     202    224   \nlinear_changes
## 74:    400   linear_changes   PELT     225    250   \nlinear_changes
## 75:    400   linear_changes   PELT     251    275   \nlinear_changes
## 76:    400   linear_changes   PELT     276    300   \nlinear_changes
## 77:    400   linear_changes   PELT     301    325   \nlinear_changes
## 78:    400   linear_changes   PELT     326    350   \nlinear_changes
## 79:    400   linear_changes   PELT     351    375   \nlinear_changes
## 80:    400   linear_changes   PELT     376    400   \nlinear_changes
##     N_data       simulation   algo first.i last.i         Simulation
```

We see in the result tables above that the segmentations are the same,
using pruning and no pruning. Below we visualize the number of
candidates considered.


``` r
algo.colors <- c(
  FPOP="blue",
  OPART="grey50",
  PELT="red")
ggplot()+
  theme_bw()+
  theme(
    panel.spacing=grid::unit(1,"lines"),
    text=element_text(size=15))+
  geom_vline(aes(
    xintercept=end+0.5),
    data=sim_changes)+
  scale_color_manual(values=algo.colors)+
  geom_point(aes(
    data_index, candidates, color=algo),
    data=pelt_info)+
  facet_grid(Simulation ~ N_data, labeller=label_both, scales="free_x", space="free")+
  scale_x_continuous(
    breaks=seq(0,max(N_data_vec),by=50))
```

![plot of chunk pelt-prune](/assets/img/2025-02-25-PELT-vs-FPOP/pelt-prune-1.png)

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
in the R package PeakSegOptimal.


``` r
if(FALSE){
  remotes::install_github("tdhock/PeakSegOptimal@f05834ad4b452070da1818f25412e5ac97454833")
}
fpop_info_list <- list()
fpop_segs_list <- list()
for(N_data in N_data_vec){
  for(simulation in names(sim_fun_list)){
    N_sim <- paste(N_data, simulation)
    data_value <- sim_data_list[[N_sim]]$data_value
    pfit <- PeakSegOptimal::UnconstrainedFPOP(
      data_value, penalty=penalty, verbose_file=tempfile())
    both_index_list[[paste(N_data, simulation, "FPOP")]] <- data.table(
      N_data, simulation, algo="FPOP", pfit$index_dt
    )[, let(
      data_index=data_index+1L,
      change=change+2L
    )][]
    start <- rev(with(pfit, ends.vec[ends.vec>=0])+1L)
    end <- c(start[-1]-1L,length(data_value))
    fpop_info_list[[paste(N_data,simulation)]] <- data.table(
      N_data,simulation,
      algo="FPOP",
      candidates=pfit$intervals.vec,
      data_index=seq_along(data_value))
    fpop_segs_list[[paste(N_data,simulation)]] <- data.table(
      N_data,simulation,start,end)
  }
}
(fpop_info <- addSim(rbindlist(fpop_info_list)))
```

```
##       N_data       simulation   algo candidates data_index         Simulation
##        <num>           <char> <char>      <int>      <int>             <char>
##    1:    100 constant_changes   FPOP          1          1 \nconstant_changes
##    2:    100 constant_changes   FPOP          2          2 \nconstant_changes
##    3:    100 constant_changes   FPOP          3          3 \nconstant_changes
##    4:    100 constant_changes   FPOP          3          4 \nconstant_changes
##    5:    100 constant_changes   FPOP          3          5 \nconstant_changes
##   ---                                                                        
## 1396:    400   linear_changes   FPOP          5        396   \nlinear_changes
## 1397:    400   linear_changes   FPOP          5        397   \nlinear_changes
## 1398:    400   linear_changes   FPOP          6        398   \nlinear_changes
## 1399:    400   linear_changes   FPOP          6        399   \nlinear_changes
## 1400:    400   linear_changes   FPOP          6        400   \nlinear_changes
```

``` r
(fpop_segs <- rbindlist(fpop_segs_list))
```

```
##     N_data       simulation start   end
##      <num>           <char> <int> <int>
##  1:    100 constant_changes    26    50
##  2:    100 constant_changes    51    75
##  3:    100 constant_changes    76   100
##  4:    100 constant_changes   101   100
##  5:    100   linear_changes    26    50
##  6:    100   linear_changes    51    75
##  7:    100   linear_changes    76   100
##  8:    100   linear_changes   101   100
##  9:    200 constant_changes    51   100
## 10:    200 constant_changes   101   150
## 11:    200 constant_changes   151   200
## 12:    200 constant_changes   201   200
## 13:    200   linear_changes    26    50
## 14:    200   linear_changes    51    75
## 15:    200   linear_changes    76   100
## 16:    200   linear_changes   101   125
## 17:    200   linear_changes   126   150
## 18:    200   linear_changes   151   175
## 19:    200   linear_changes   176   200
## 20:    200   linear_changes   201   200
## 21:    400 constant_changes   101   200
## 22:    400 constant_changes   201   300
## 23:    400 constant_changes   301   400
## 24:    400 constant_changes   401   400
## 25:    400   linear_changes    26    50
## 26:    400   linear_changes    51    75
## 27:    400   linear_changes    76   100
## 28:    400   linear_changes   101   125
## 29:    400   linear_changes   126   150
## 30:    400   linear_changes   151   175
## 31:    400   linear_changes   176   201
## 32:    400   linear_changes   202   224
## 33:    400   linear_changes   225   250
## 34:    400   linear_changes   251   275
## 35:    400   linear_changes   276   300
## 36:    400   linear_changes   301   325
## 37:    400   linear_changes   326   350
## 38:    400   linear_changes   351   375
## 39:    400   linear_changes   376   400
## 40:    400   linear_changes   401   400
##     N_data       simulation start   end
```

``` r
both_info <- rbind(pelt_info, fpop_info)
ggplot()+
  theme_bw()+
  theme(
    panel.spacing=grid::unit(1,"lines"),
    text=element_text(size=15))+
  geom_vline(aes(
    xintercept=end+0.5),
    data=sim_changes)+
  scale_color_manual(values=algo.colors)+
  geom_point(aes(
    data_index, candidates, color=algo),
    data=both_info)+
  facet_grid(Simulation ~ N_data, labeller=label_both, scales="free_x", space="free")+
  scale_x_continuous(
    breaks=seq(0,max(N_data_vec),by=50))
```

![plot of chunk fpop-prune](/assets/img/2025-02-25-PELT-vs-FPOP/fpop-prune-1.png)

In the figure above, we can see the advantage of FPOP: the number of
change-points considered does not increase with the number of data,
even with constant number of changes (larger segments).

* In the top simulation with constant changes, the number of
  change-points candidates considered is linear in the number of data,
  so both OPART and PELT are quadratic time in the number of data,
  whereas FPOP is sub-quadratic (empirically linear or log-linear).
  
## Heat maps
  
Another way to view this is by looking at the cost of each candidate
change-point considered, as in the heat map below.


``` r
algo.levs <- c("OPART","PELT","FPOP")
(both_index <- addSim(rbindlist(both_index_list))[, let(
  Algorithm = factor(algo, algo.levs)
)][])
```

```
##         N_data       simulation   algo data_index change       cost         Simulation Algorithm
##          <num>           <char> <char>      <int>  <int>      <num>             <char>    <fctr>
##      1:    100 constant_changes  OPART          1      1  -8.635532 \nconstant_changes     OPART
##      2:    100 constant_changes  OPART          2      1 -10.775021 \nconstant_changes     OPART
##      3:    100 constant_changes  OPART          2      2  -5.830692 \nconstant_changes     OPART
##      4:    100 constant_changes  OPART          3      1  -9.335529 \nconstant_changes     OPART
##      5:    100 constant_changes  OPART          3      2  -6.005552 \nconstant_changes     OPART
##     ---                                                                                         
## 253677:    400   linear_changes   FPOP        400    397 -26.949800   \nlinear_changes      FPOP
## 253678:    400   linear_changes   FPOP        400    395 -26.952800   \nlinear_changes      FPOP
## 253679:    400   linear_changes   FPOP        400    394 -26.953300   \nlinear_changes      FPOP
## 253680:    400   linear_changes   FPOP        400    376 -26.969100   \nlinear_changes      FPOP
## 253681:    400   linear_changes   FPOP        400    400 -26.944700   \nlinear_changes      FPOP
```

``` r
both_index[data_index==2 & N_data==400 & simulation=="constant_changes"]
```

```
##    N_data       simulation   algo data_index change       cost         Simulation Algorithm
##     <num>           <char> <char>      <int>  <int>      <num>             <char>    <fctr>
## 1:    400 constant_changes  OPART          2      1 -10.775021 \nconstant_changes     OPART
## 2:    400 constant_changes  OPART          2      2  -5.830692 \nconstant_changes     OPART
## 3:    400 constant_changes   PELT          2      1 -10.775021 \nconstant_changes      PELT
## 4:    400 constant_changes   PELT          2      2  -5.830692 \nconstant_changes      PELT
## 5:    400 constant_changes   FPOP          2      2  -5.830690 \nconstant_changes      FPOP
## 6:    400 constant_changes   FPOP          2      1 -10.775000 \nconstant_changes      FPOP
## 7:    400 constant_changes   FPOP          2      2  -5.830690 \nconstant_changes      FPOP
```

``` r
for(a in algo.levs){
  gg <- ggplot()+
    ggtitle(a)+
    theme_bw()+
    theme(text=element_text(size=20))+
    coord_equal()+
    geom_tile(aes(
      data_index, change, fill=cost),
      data=both_index[Algorithm==a])+
    scale_fill_gradient(low="black", high="red")+
    facet_grid(Simulation ~ N_data, label=label_both)
  print(gg)
}
```

![plot of chunk cost-heat](/assets/img/2025-02-25-PELT-vs-FPOP/cost-heat-1.png)![plot of chunk cost-heat](/assets/img/2025-02-25-PELT-vs-FPOP/cost-heat-2.png)![plot of chunk cost-heat](/assets/img/2025-02-25-PELT-vs-FPOP/cost-heat-3.png)

Another way to visualize it is in the plot below, which super-imposes
the three algos.


``` r
ggplot()+
  theme_bw()+
  theme(text=element_text(size=15))+
  geom_tile(aes(
    data_index, change, fill=Algorithm),
    data=both_index)+
  scale_fill_manual(values=algo.colors)+
  scale_x_continuous(
    breaks=seq(0,max(N_data_vec),by=50))+
  facet_grid(Simulation ~ N_data, label=label_both, scales="free", space="free")
```

![plot of chunk candidates-compare](/assets/img/2025-02-25-PELT-vs-FPOP/candidates-compare-1.png)

It is clear that FPOP prunes much more than PELT, especially in the
case of constant changes (segments that get larger with the overall
number of data).

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
    pfit <- PeakSegOptimal::UnconstrainedFPOP(
      data_list[[simulation]], penalty=penalty)
    data.frame(
      mean_candidates=mean(pfit$intervals.vec),
      segments=sum(is.finite(pfit$mean.vec)),
      max_seg_size=max(-diff(pfit$ends.vec)))
  }))
for(algo in names(algo.prune)){
  prune <- algo.prune[[algo]]
  grid_args[[algo]] <- substitute({
    fit <- PELT(data_list[[simulation]], penalty=penalty, prune=prune)
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
##     pfit <- PeakSegOptimal::UnconstrainedFPOP(data_list[["constant_changes"]], 
##         penalty = penalty)
##     data.frame(mean_candidates = mean(pfit$intervals.vec), segments = sum(is.finite(pfit$mean.vec)), 
##         max_seg_size = max(-diff(pfit$ends.vec)))
## }
## 
## $`FPOP simulation=linear_changes`
## {
##     pfit <- PeakSegOptimal::UnconstrainedFPOP(data_list[["linear_changes"]], 
##         penalty = penalty)
##     data.frame(mean_candidates = mean(pfit$intervals.vec), segments = sum(is.finite(pfit$mean.vec)), 
##         max_seg_size = max(-diff(pfit$ends.vec)))
## }
## 
## $`OPART simulation=constant_changes`
## {
##     fit <- PELT(data_list[["constant_changes"]], penalty = penalty, 
##         prune = FALSE)
##     dec <- decode(fit$change)
##     data.frame(mean_candidates = mean(fit$candidates), segments = nrow(dec), 
##         max_seg_size = max(diff(c(0, dec$last.i))))
## }
## 
## $`OPART simulation=linear_changes`
## {
##     fit <- PELT(data_list[["linear_changes"]], penalty = penalty, 
##         prune = FALSE)
##     dec <- decode(fit$change)
##     data.frame(mean_candidates = mean(fit$candidates), segments = nrow(dec), 
##         max_seg_size = max(diff(c(0, dec$last.i))))
## }
## 
## $`PELT simulation=constant_changes`
## {
##     fit <- PELT(data_list[["constant_changes"]], penalty = penalty, 
##         prune = TRUE)
##     dec <- decode(fit$change)
##     data.frame(mean_candidates = mean(fit$candidates), segments = nrow(dec), 
##         max_seg_size = max(diff(c(0, dec$last.i))))
## }
## 
## $`PELT simulation=linear_changes`
## {
##     fit <- PELT(data_list[["linear_changes"]], penalty = penalty, 
##         prune = TRUE)
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
cache.rds <- "2025-02-25-PELT-vs-FPOP.rds"
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
        data_list[[simulation]] <- rpois(N, data_mean_vec)
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

![plot of chunk atime](/assets/img/2025-02-25-PELT-vs-FPOP/atime-1.png)

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
##              unit                         expr.name fun.name fun.latex expr.grid       simulation     N          min
##            <char>                            <char>   <char>    <char>    <char>           <char> <num>        <num>
##   1:    kilobytes  FPOP simulation=constant_changes        N         N      FPOP constant_changes 1e+02 0.0002316179
##   2:    kilobytes    FPOP simulation=linear_changes        N         N      FPOP   linear_changes 1e+02 0.0002302140
##   3:    kilobytes OPART simulation=constant_changes      N^2       N^2     OPART constant_changes 1e+02 0.0017665051
##   4:    kilobytes   OPART simulation=linear_changes      N^2       N^2     OPART   linear_changes 1e+02 0.0016728539
##   5:    kilobytes  PELT simulation=constant_changes      N^2       N^2      PELT constant_changes 1e+02 0.0015523479
##  ---                                                                                                                
## 341: max_seg_size  FPOP simulation=constant_changes        N         N      FPOP constant_changes 2e+05 0.4901819581
## 342: max_seg_size    FPOP simulation=linear_changes     <NA>      <NA>      FPOP   linear_changes 2e+05 0.2828991731
## 343: max_seg_size  FPOP simulation=constant_changes        N         N      FPOP constant_changes 4e+05 1.0259534011
## 344: max_seg_size    FPOP simulation=linear_changes     <NA>      <NA>      FPOP   linear_changes 4e+05 0.5639357400
## 345: max_seg_size    FPOP simulation=linear_changes     <NA>      <NA>      FPOP   linear_changes 8e+05 1.1226613900
##            median      itr/sec     gc/sec n_itr  n_gc            result                                          time
##             <num>        <num>      <num> <int> <num>            <list>                                        <list>
##   1: 0.0002442150 3574.5331805  0.0000000    10     0 <data.frame[1x3]>       470µs,368µs,257µs,266µs,241µs,240µs,...
##   2: 0.0002421311 3926.2117915  0.0000000    10     0 <data.frame[1x3]>       367µs,261µs,252µs,240µs,250µs,230µs,...
##   3: 0.0018940541  520.7369060 57.8596562     9     1 <data.frame[1x3]> 2.05ms,1.91ms,1.85ms,1.83ms,1.82ms,1.96ms,...
##   4: 0.0017234740  560.3588067  0.0000000    10     0 <data.frame[1x3]>  2.05ms,1.93ms,1.9ms,1.76ms,1.73ms,1.72ms,...
##   5: 0.0015820405  620.1694706  0.0000000    10     0 <data.frame[1x3]> 1.72ms,1.69ms,1.66ms,1.62ms,1.57ms,1.55ms,...
##  ---                                                                                                                 
## 341: 0.4939388145    2.0151479  0.2239053     9     1 <data.frame[1x3]>       501ms,519ms,496ms,496ms,499ms,491ms,...
## 342: 0.2836681501    3.5201557  0.0000000    10     0 <data.frame[1x3]>       284ms,289ms,283ms,284ms,284ms,283ms,...
## 343: 1.0293976846    0.9718521  0.1079836     9     1 <data.frame[1x3]>       1.03s,1.03s,1.03s,1.03s,1.03s,1.03s,...
## 344: 0.5655546531    1.7680311  0.4420078     8     2 <data.frame[1x3]>       570ms,566ms,565ms,570ms,566ms,564ms,...
## 345: 1.1287645885    0.8806040  0.3774017     7     3 <data.frame[1x3]>       1.12s,1.13s,1.12s,1.13s,1.14s,1.16s,...
##                  gc   kilobytes          q25          q75          max         mean           sd mean_candidates
##              <list>       <num>        <num>        <num>        <num>        <num>        <num>           <num>
##   1: <tbl_df[10x3]>    35.90625 0.0002398966 0.0002642278 0.0004700619 0.0002797568 7.787649e-05        3.620000
##   2: <tbl_df[10x3]>    12.60156 0.0002335893 0.0002519581 0.0003666921 0.0002546984 4.061837e-05        3.620000
##   3: <tbl_df[10x3]>   885.89062 0.0018383883 0.0020245181 0.0074834061 0.0024766606 1.764018e-03       50.500000
##   4: <tbl_df[10x3]>   885.89062 0.0016983075 0.0018617817 0.0020506069 0.0017845709 1.289868e-04       50.500000
##   5: <tbl_df[10x3]>   214.77344 0.0015705522 0.0016500467 0.0017230110 0.0016124625 5.942568e-05       14.360000
##  ---                                                                                                            
## 341: <tbl_df[10x3]> 22657.52344 0.4908575067 0.4983258765 0.5188986610 0.4965229103 8.702945e-03       10.506720
## 342: <tbl_df[10x3]> 22657.52344 0.2834965774 0.2837788898 0.2887644571 0.2840783453 1.674366e-03        4.306425
## 343: <tbl_df[10x3]> 45314.74219 1.0275195075 1.0305302114 1.0334158142 1.0293166748 2.486430e-03       11.443157
## 344: <tbl_df[10x3]> 45313.77344 0.5645482798 0.5677078616 0.5698938600 0.5662693475 2.230345e-03        4.320775
## 345: <tbl_df[10x3]> 90626.27344 1.1242019855 1.1568015352 1.3523598550 1.1572877460 7.026321e-02        4.323669
##      segments max_seg_size                             expr.class                                  expr.latex
##         <int>        <num>                                 <char>                                      <char>
##   1:        4           26    FPOP simulation=constant_changes\nN    FPOP simulation=constant_changes\n$O(N)$
##   2:        4           26      FPOP simulation=linear_changes\nN      FPOP simulation=linear_changes\n$O(N)$
##   3:        4           25 OPART simulation=constant_changes\nN^2 OPART simulation=constant_changes\n$O(N^2)$
##   4:        4           25   OPART simulation=linear_changes\nN^2   OPART simulation=linear_changes\n$O(N^2)$
##   5:        4           25  PELT simulation=constant_changes\nN^2  PELT simulation=constant_changes\n$O(N^2)$
##  ---                                                                                                         
## 341:        4        50003    FPOP simulation=constant_changes\nN    FPOP simulation=constant_changes\n$O(N)$
## 342:     8000           33     FPOP simulation=linear_changes\nNA     FPOP simulation=linear_changes\n$O(NA)$
## 343:        4       100002    FPOP simulation=constant_changes\nN    FPOP simulation=constant_changes\n$O(N)$
## 344:    16000           33     FPOP simulation=linear_changes\nNA     FPOP simulation=linear_changes\n$O(NA)$
## 345:    32002           33     FPOP simulation=linear_changes\nNA     FPOP simulation=linear_changes\n$O(NA)$
##         empirical        Simulation Algorithm
##             <num>            <char>    <fctr>
##   1:     35.90625 constant\nchanges      FPOP
##   2:     12.60156   linear\nchanges      FPOP
##   3:    885.89062 constant\nchanges     OPART
##   4:    885.89062   linear\nchanges     OPART
##   5:    214.77344 constant\nchanges      PELT
##  ---                                         
## 341:  50003.00000 constant\nchanges      FPOP
## 342:     33.00000   linear\nchanges      FPOP
## 343: 100002.00000 constant\nchanges      FPOP
## 344:     33.00000   linear\nchanges      FPOP
## 345:     33.00000   linear\nchanges      FPOP
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

![plot of chunk compare-sims](/assets/img/2025-02-25-PELT-vs-FPOP/compare-sims-1.png)

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
  theme(panel.spacing=grid::unit(1,"lines"))
```

```
## Warning in (function (..., deparse.level = 1) : number of rows of result is not a multiple of vector length (arg 2)
```

![plot of chunk plot-refs](/assets/img/2025-02-25-PELT-vs-FPOP/plot-refs-1.png)

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

![plot of chunk pred-seconds](/assets/img/2025-02-25-PELT-vs-FPOP/pred-seconds-1.png)

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

![plot of chunk pred-candidates](/assets/img/2025-02-25-PELT-vs-FPOP/pred-candidates-1.png)

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
## R version 4.4.3 (2025-02-28)
## Platform: x86_64-pc-linux-gnu
## Running under: Ubuntu 24.04.2 LTS
## 
## Matrix products: default
## BLAS:   /usr/lib/x86_64-linux-gnu/blas/libblas.so.3.12.0 
## LAPACK: /usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.12.0
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
## [1] ggplot2_3.5.1      data.table_1.17.99
## 
## loaded via a namespace (and not attached):
##  [1] directlabels_2024.1.21   vctrs_0.6.5              cli_3.6.4                knitr_1.50              
##  [5] rlang_1.1.5              xfun_0.51                penaltyLearning_2024.9.3 bench_1.1.4             
##  [9] generics_0.1.3           glue_1.8.0               labeling_0.4.3           colorspace_2.1-1        
## [13] scales_1.3.0             quadprog_1.5-8           grid_4.4.3               munsell_0.5.1           
## [17] evaluate_1.0.3           tibble_3.2.1             profmem_0.6.0            lifecycle_1.0.4         
## [21] compiler_4.4.3           dplyr_1.1.4              pkgconfig_2.0.3          PeakSegOptimal_2025.3.31
## [25] atime_2025.4.1           lattice_0.22-6           farver_2.1.2             R6_2.6.1                
## [29] tidyselect_1.2.1         pillar_1.10.1            magrittr_2.0.3           tools_4.4.3             
## [33] withr_3.0.2              gtable_0.3.6
```
