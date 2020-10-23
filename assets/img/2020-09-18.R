## iris data
X.mat <- as.matrix(iris[, 1:4])
set.prop.vec <- c(validation=0.5, train=0.5)
(rounded.counts <- floor(set.prop.vec*(nrow(X.mat)+1)))
not.shuffled.sets <- rep(names(set.prop.vec), rounded.counts)
set.seed(1)
shuffled.sets <- sample(not.shuffled.sets)
table(shuffled.sets, iris$Species)
n.clusters <- 2
kmeans.result <- stats::kmeans(X.mat[shuffled.sets=="train", ], n.clusters)

##1 base array for kmeans sum of squares per set computation.
array.dim <- c(nrow(X.mat), ncol(X.mat), nrow(kmeans.result$centers))
array.names <- list(obs=NULL, feature=NULL, cluster=NULL)
X.array <- array(
  X.mat, array.dim, array.names)
head(X.array)
head(X.mat)
m.array <- array(
  rep(t(kmeans.result$centers), each=nrow(X.mat)), array.dim, array.names)
head(m.array)
kmeans.result$centers
squares.array <- (X.array-m.array)^2
sum.squares.mat <- apply(squares.array, c("obs", "cluster"), sum)
min.vec <- apply(sum.squares.mat, "obs", min)
tapply(min.vec, shuffled.sets, sum)
kmeans.result$tot.withinss

## data.table cartesian join version of same computation.
(X.dt <- data.table::data.table(
  value=as.numeric(X.mat),
  obs=as.integer(row(X.mat)),
  feature=as.integer(col(X.mat))))
(m.dt <- data.table::data.table(
  center=as.numeric(kmeans.result$centers),
  cluster=as.integer(row(kmeans.result$centers)),
  feature=as.integer(col(kmeans.result$centers))))
squares.dt <- X.dt[m.dt, on="feature", allow.cartesian=TRUE]
squares.dt[, square := (value-center)^2 ]
squares.dt
length(squares.array)
sum.squares.dt <- squares.dt[, .(
  sum.squares=sum(square)
), by=c("obs", "cluster")]
min.dt <- sum.squares.dt[, .(
  min.ss=min(sum.squares)
), by="obs"]
min.dt[, .(
  tot.withinss=sum(min.ss)
), by=.(set=shuffled.sets[obs])]
kmeans.result$tot.withinss




## base.for.obs
min.vec <- rep(NA_real_, nrow(X.mat))
for(obs in 1:nrow(X.mat)){
  diff.mat <- X.mat[obs, ] - t(kmeans.result$centers)
  min.vec[[obs]] <- min(colSums(diff.mat^2))
}
tapply(min.vec, shuffled.sets, sum)
kmeans.result$tot.withinss

## data.table.for.obs
min.dt.list <- list()
for(obs in 1:nrow(X.mat)){
  diff.mat <- X.mat[obs, ] - t(kmeans.result$centers)
  min.dt.list[[obs]] <- data.table(
    obs, min.ss=min(colSums(diff.mat^2)))
}
min.dt <- do.call(rbind, min.dt.list)
min.dt[, .(tot.withinss=sum(min.ss)), by=.(set=shuffled.sets[obs])]
kmeans.result$tot.withinss

## data.table.by.obs
(min.dt <- data.table(obs=1:nrow(X.mat))[, {
  diff.mat <- X.mat[obs, ] - t(kmeans.result$centers)
  min.dt.list[[obs]] <- data.table(
    min.ss=min(colSums(diff.mat^2)))
}, by=obs])
min.dt[, .(tot.withinss=sum(min.ss)), by=.(set=shuffled.sets[obs])]
kmeans.result$tot.withinss




## base.for.set.obs
tot.withinss <- structure(
  rep(NA_real_, length(set.prop.vec)),
  names=names(set.prop.vec))
for(set in names(set.prop.vec)){
  X.set <- X.mat[shuffled.sets == set, ]
  set.obs.mins <- rep(NA_real_, nrow(X.set))
  for(obs in 1:nrow(X.set)){
    diff.mat <- X.set[obs, ] - t(kmeans.result$centers)
    set.obs.mins[[obs]] <- min(colSums(diff.mat^2))
  }
  tot.withinss[[set]] <- sum(set.obs.mins)
}
tot.withinss
kmeans.result$tot.withinss

## data.table.for.set.obs
tot.withinss.dt.list <- list()
for(set in names(set.prop.vec)){
  X.set <- X.mat[shuffled.sets == set, ]
  set.obs.mins.dt.list <- list()
  for(obs in 1:nrow(X.set)){
    diff.mat <- X.set[obs, ] - t(kmeans.result$centers)
    set.obs.mins.dt.list[[obs]] <- data.table::data.table(
      obs, min.ss=min(colSums(diff.mat^2)))
  }
  set.obs.mins.dt <- do.call(rbind, set.obs.mins.dt.list)
  tot.withinss.dt.list[[set]] <- set.obs.mins.dt[, .(
    set,
    tot.withinss=sum(min.ss))]
}
(tot.withinss.dt <- do.call(rbind, tot.withinss.dt.list))
kmeans.result$tot.withinss

## data.table.by.set.obs
(set.obs.ids <- data.table::data.table(
  set=shuffled.sets, obs=seq_along(shuffled.sets)))
set.obs.ids[, {
  set.obs.mins <- .SD[, {
    diff.mat <- X.mat[obs, ] - t(kmeans.result$centers)
    .(min.ss=min(colSums(diff.mat^2)))
  }, by="obs"]
  set.obs.mins[, .(tot.withinss=sum(min.ss))]
}, by="set"]
kmeans.result$tot.withinss




## base.for.cluster
sum.squares.mat <- matrix(
  NA_real_, nrow(X.mat), n.clusters,
  dimnames=list(obs=NULL, cluster=NULL))
for(cluster in 1:n.clusters){
  diff.mat <- t(X.mat) - kmeans.result$centers[cluster,]
  sum.squares.mat[, cluster] <- colSums(diff.mat^2)
}
min.vec <- apply(sum.squares.mat, "obs", min)
tapply(min.vec, shuffled.sets, sum)
kmeans.result$tot.withinss

## data.table.for.cluster
sum.squares.dt.list <- list()
for(cluster in 1:n.clusters){
  diff.mat <- t(X.mat) - kmeans.result$centers[cluster,]
  sum.squares.dt.list[[cluster]] <- data.table(
    cluster, obs=1:nrow(X.mat), sum.squares=colSums(diff.mat^2))
}
(sum.squares.dt <- do.call(rbind, sum.squares.dt.list))
(min.dt <- sum.squares.dt[, .(min.ss=min(sum.squares)), by=obs])
min.dt[, .(tot.withinss=sum(min.ss)), by=.(set=shuffled.sets[obs])]
kmeans.result$tot.withinss

## data.table.by.cluster
(sum.squares.dt <- data.table(cluster=1:n.clusters)[, {
  diff.mat <- t(X.mat) - kmeans.result$centers[cluster,]
  data.table(
    obs=1:nrow(X.mat), sum.squares=colSums(diff.mat^2))
}, by=cluster])
(min.dt <- sum.squares.dt[, .(min.ss=min(sum.squares)), by=obs])
min.dt[, .(tot.withinss=sum(min.ss)), by=.(set=shuffled.sets[obs])]
kmeans.result$tot.withinss


## zip data
if(!file.exists("zip.train.gz")){
  download.file(
    "https://web.stanford.edu/~hastie/ElemStatLearn/datasets/zip.train.gz",
    "zip.train.gz")
}
zip.dt <- data.table::fread("zip.train.gz")
X.mat <- as.matrix(zip.dt[, -1])
set.seed(1)
set.names <- c("train", "validation")
shuffled.sets <- sample(rep(set.names, l=nrow(X.mat)))
n.clusters <- 5
set.seed(1)
kmeans.result <- stats::kmeans(X.mat[shuffled.sets=="train", ], n.clusters)
kmeans.result$centers
exprs <- function(...){
  match.call()[-1]
}
exprs.list <- exprs(
  kmeans={
    stats::kmeans(X.mat[shuffled.sets=="train", ], n.clusters)
  },
  base.all.combos={
    array.dim <- c(nrow(X.mat), ncol(X.mat), nrow(kmeans.result$centers))
    array.names <- list(obs=NULL, feature=NULL, cluster=NULL)
    X.array <- array(
      X.mat, array.dim, array.names)
    head(X.array)
    head(X.mat)
    m.array <- array(
      rep(t(kmeans.result$centers), each=nrow(X.mat)), array.dim, array.names)
    head(m.array)
    kmeans.result$centers
    squares.array <- (X.array-m.array)^2
    sum.squares.mat <- apply(squares.array, c("obs", "cluster"), sum)
    min.vec <- apply(sum.squares.mat, "obs", min)
    tapply(min.vec, shuffled.sets, sum)
  },
  data.table.all.combos={
    (X.dt <- data.table::data.table(
      value=as.numeric(X.mat),
      obs=as.integer(row(X.mat)),
      feature=as.integer(col(X.mat))))
    (m.dt <- data.table::data.table(
      center=as.numeric(kmeans.result$centers),
      cluster=as.integer(row(kmeans.result$centers)),
      feature=as.integer(col(kmeans.result$centers))))
    squares.dt <- X.dt[m.dt, on="feature", allow.cartesian=TRUE]
    squares.dt[, square := (value-center)^2 ]
    sum.squares.dt <- squares.dt[, .(
      sum.squares=sum(square)
    ), by=c("obs", "cluster")]
    min.dt <- sum.squares.dt[, .(
      min.ss=min(sum.squares)
    ), by="obs"]
    min.dt[, .(
      tot.withinss=sum(min.ss)
    ), by=.(set=shuffled.sets[obs])]
  },
  base.for.obs={
    min.vec <- rep(NA_real_, nrow(X.mat))
    for(obs in 1:nrow(X.mat)){
      diff.mat <- X.mat[obs, ] - t(kmeans.result$centers)
      min.vec[[obs]] <- min(colSums(diff.mat^2))
    }
    tapply(min.vec, shuffled.sets, sum)
  }, 
  data.table.for.obs={
    min.dt.list <- list()
    for(obs in 1:nrow(X.mat)){
      diff.mat <- X.mat[obs, ] - t(kmeans.result$centers)
      min.dt.list[[obs]] <- data.table(
        obs, min.ss=min(colSums(diff.mat^2)))
    }
    min.dt <- do.call(rbind, min.dt.list)
    min.dt[, .(tot.withinss=sum(min.ss)), by=.(set=shuffled.sets[obs])]
  },
  data.table.by.obs={
    (min.dt <- data.table(obs=1:nrow(X.mat))[, {
      diff.mat <- X.mat[obs, ] - t(kmeans.result$centers)
      min.dt.list[[obs]] <- data.table(
        min.ss=min(colSums(diff.mat^2)))
    }, by=obs])
    min.dt[, .(tot.withinss=sum(min.ss)), by=.(set=shuffled.sets[obs])]
  }, 
  base.for.set.obs={
    tot.withinss <- structure(
      rep(NA_real_, length(set.names)),
      names=set.names)
    for(set in set.names){
      X.set <- X.mat[shuffled.sets == set, ]
      set.obs.mins <- rep(NA_real_, nrow(X.set))
      for(obs in 1:nrow(X.set)){
        diff.mat <- X.set[obs, ] - t(kmeans.result$centers)
        set.obs.mins[[obs]] <- min(colSums(diff.mat^2))
      }
      tot.withinss[[set]] <- sum(set.obs.mins)
    }
  },
  data.table.for.set.obs={
    tot.withinss.dt.list <- list()
    for(set in set.names){
      X.set <- X.mat[shuffled.sets == set, ]
      set.obs.mins.dt.list <- list()
      for(obs in 1:nrow(X.set)){
        diff.mat <- X.set[obs, ] - t(kmeans.result$centers)
        set.obs.mins.dt.list[[obs]] <- data.table::data.table(
          obs, min.ss=min(colSums(diff.mat^2)))
      }
      set.obs.mins.dt <- do.call(rbind, set.obs.mins.dt.list)
      tot.withinss.dt.list[[set]] <- set.obs.mins.dt[, .(
        set,
        tot.withinss=sum(min.ss))]
    }
    (tot.withinss.dt <- do.call(rbind, tot.withinss.dt.list))
  },
  data.table.by.set.obs={
    (set.obs.ids <- data.table::data.table(
      set=shuffled.sets, obs=seq_along(shuffled.sets)))
    set.obs.ids[, {
      set.obs.mins <- .SD[, {
        diff.mat <- X.mat[obs, ] - t(kmeans.result$centers)
        .(min.ss=min(colSums(diff.mat^2)))
      }, by="obs"]
      set.obs.mins[, .(tot.withinss=sum(min.ss))]
    }, by="set"]
  }, 
  base.for.cluster={
    sum.squares.mat <- matrix(
      NA_real_, nrow(X.mat), n.clusters,
      dimnames=list(obs=NULL, cluster=NULL))
    for(cluster in 1:n.clusters){
      diff.mat <- t(X.mat) - kmeans.result$centers[cluster,]
      sum.squares.mat[, cluster] <- colSums(diff.mat^2)
    }
    min.vec <- apply(sum.squares.mat, "obs", min)
    tapply(min.vec, shuffled.sets, sum)
  },
  data.table.for.cluster={
    sum.squares.dt.list <- list()
    for(cluster in 1:n.clusters){
      diff.mat <- t(X.mat) - kmeans.result$centers[cluster,]
      sum.squares.dt.list[[cluster]] <- data.table(
        cluster, obs=1:nrow(X.mat), sum.squares=colSums(diff.mat^2))
    }
    (sum.squares.dt <- do.call(rbind, sum.squares.dt.list))
    (min.dt <- sum.squares.dt[, .(min.ss=min(sum.squares)), by=obs])
    min.dt[, .(tot.withinss=sum(min.ss)), by=.(set=shuffled.sets[obs])]
  }, 
  data.table.by.cluster={
    (sum.squares.dt <- data.table(cluster=1:n.clusters)[, {
      diff.mat <- t(X.mat) - kmeans.result$centers[cluster,]
      data.table(
        obs=1:nrow(X.mat), sum.squares=colSums(diff.mat^2))
    }, by=cluster])
    (min.dt <- sum.squares.dt[, .(min.ss=min(sum.squares)), by=obs])
    min.dt[, .(tot.withinss=sum(min.ss)), by=.(set=shuffled.sets[obs])]
  }
)
library(data.table)
timings.dt.list <- list()
for(n.clusters in 2:5){
  print(n.clusters)
  kmeans.result <- eval(exprs.list[["kmeans"]])
  print(kmeans.result$centers)
  for(seed in 1:3){
    set.seed(seed)
    for(method in sample(names(exprs.list))){
      mt.list <- memtime::memtime(eval(exprs.list[[method]]))
      timings.dt.list[[paste(n.clusters, method, seed)]] <- data.table(
        n.clusters, method, seed,
        kilobytes=mt.list[["memory"]]["max.increase", "kilobytes"],
        seconds=mt.list[["time"]][["elapsed"]])
    }
  }
}
timings.dt <- do.call(rbind, timings.dt.list)
saveRDS(timings.dt, "2020-09-18-seeds.rds")

timings.dt <- readRDS("2020-09-18-seeds.rds")
timings.dt[, megabytes := kilobytes/1024]
library(ggplot2)
pkg.dt <- nc::capture_first_df(
  timings.dt[grepl("for|by", method)],
  method=list(pkg="data.table|base", "[.]", loop="for|by", "[.]", vars=".*"))
measure.vars <- c("seconds", "megabytes")
timings.tall <- data.table::melt(
  pkg.dt,
  measure.vars=measure.vars)
timings.kmeans <- melt(timings.dt[method=="kmeans"], measure.vars=measure.vars)
gg <- ggplot()+
  ggtitle("Requirements for computing train/validation sum of squares
(black=kmeans)")+
  geom_line(aes(
    n.clusters, value, linetype=loop, color=pkg,
    group=paste(loop, pkg, seed)),
    data=timings.tall)+
  geom_line(aes(
    n.clusters, value, group=seed),
    data=timings.kmeans)+
  ylab("")+
  scale_y_log10()+
  facet_grid(variable ~ vars, scales="free")
only.seconds <- function(DT)DT[variable=="seconds"]
gg <- ggplot()+
  ggtitle("Time to compute train/validation sum of squares (black=kmeans)")+
  geom_line(aes(
    n.clusters, value, linetype=loop, color=pkg,
    group=paste(loop, pkg, seed)),
    data=only.seconds(timings.tall))+
  geom_line(aes(
    n.clusters, value, group=seed),
    data=only.seconds(timings.kmeans))+
  ylab("seconds")+
  scale_y_log10()+
  facet_grid(. ~ vars, scales="free")
png(
  "2020-09-18-figure-loops.png",
  width=6, height=3, units="in", res=100)
print(gg)
dev.off()

some.wide <- timings.dt[grepl("data.table.by.cluster|kmeans|all", method)]
some.tall <- data.table::melt(
  some.wide,
  measure.vars=measure.vars)
gg <- ggplot()+
  ggtitle("All observation/cluster combinations is inefficient")+
  geom_line(aes(
    n.clusters, value, color=method,
    group=paste(method, seed)),
    data=some.tall)+
  ylab("")+
  facet_grid(variable ~ ., scales="free")
dl <- directlabels::direct.label(gg, "right.polygons")+
  some.tall[, xlim(min(n.clusters), max(n.clusters)+2)]
png(
  "2020-09-18-figure-all.png",
  width=6, height=4, units="in", res=100)
print(dl)
dev.off()
