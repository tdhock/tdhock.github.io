---
layout: post
title: Visualizing prediction error
description: And clearly showing differences between algorithms
---



In machine learning papers, we often need to compare the prediction
error/accuracy of different algorithms. This post explains how to do
that using data visualizations that are easy to read/interpret.

## Example: gradient descent learning of binary classification models

Classification is a machine learning problem that has been widely
studied for the last few decades. Binary classification is the special
case when there are two possible classes to predict (spam vs normal
email, cat vs dog in images, etc). To evaluate the prediction accuracy
of learned binary classification models, we often use the Area Under
the ROC Curve, because it allows fair comparison, even when the
distribution of labels is unbalanced (for example, 1% positive/spam
and 99% negative/normal email).

In our recent [JMLR'23](https://jmlr.org/papers/v24/21-0751.html)
paper, we proposed the AUM loss function, which can be used in
gradient descent learning algorithms, to optimize ROC curves.
Recently I did a computational experiment to compare this loss
function to others, via the following setup.

* We were motivated by the following question: Can gradient descent
  using the AUM loss result in faster computation of a model with good
  generalization properties? (large AUC on held-out data)
* We wanted to compare the AUM loss to the standard
  Logistic/Cross-Entropy loss used in classification, as well as the
  all pairs squared hinge loss which is a popular relaxation of the
  Mann-Whitney U statistic (and therefore a surrogate for ROC-AUC, for
  more info see [my paper with Kyle
  Rust](https://arxiv.org/abs/2302.11062)).
* We analyzed four different image classification data sets, in which
  each had 10 classes. So in each data set we converted to a binary
  problem, by using the first class (0) as the negative/0 class, and
  using all of the other classes as the positive/1 class. So each data
  set had about 10% negative and 90% positive labels.
* Data sets had different numbers of features, so were down-sampled to
  different sizes, in order to get train times which were similar
  between data sets. For example STL10 had the largest number of
  features (27648), so had the smallest train set; MNIST with only 784
  features had the largest train set.
* Source code used to compute the result, for a given loss function
  and learning rate, is in
  [data_Classif.py](https://github.com/tdhock/max-generalized-auc/blob/master/data_Classif.py)
* We tried a range of learning rates, `10^seq(-4,5)`, and three different loss functions, as can be seen in [data_Classif_batchtools.R](https://github.com/tdhock/max-generalized-auc/blob/master/data_Classif_batchtools.R).
* For each algorithm, data set, random seed, and learning rate, we
  used torch to initialize a random linear model, and then did 100000
  epochs of gradient descent learning with constant step size (learning rate).
* Then for each algorithm, data set, and random seed, we select only
  the epoch/iteration and step size that achieved the max AUC on the
  validation set.

The results can be read from
[data_Classif_batchtools_best_valid.csv](../assets/data_Classif_batchtools_best_valid.csv),
as shown in the code below:


``` r
library(data.table)
```

```
## data.table 1.16.0 using 1 threads (see ?getDTthreads).  Latest news: r-datatable.com
```

``` r
(best.dt <- fread("../assets/data_Classif_batchtools_best_valid.csv"))
```

```
##        data.name     N         loss  seed    lr step_number   loss_value       auc
##           <char> <int>       <char> <int> <num>       <int>        <num>     <num>
##  1:      CIFAR10  5623          AUM     1 1e+00          45 5.196870e+01 0.8220866
##  2:      CIFAR10  5623          AUM     2 1e+04          40 5.412949e+05 0.8192649
##  3:      CIFAR10  5623          AUM     3 1e+05          55 4.929346e+06 0.8197657
##  4:      CIFAR10  5623          AUM     4 1e+03          29 4.944706e+04 0.8211118
##  5:      CIFAR10  5623     Logistic     1 1e+01          63 1.137827e+02 0.8084200
##  6:      CIFAR10  5623     Logistic     2 1e+05           7 6.490934e+05 0.8177584
##  7:      CIFAR10  5623     Logistic     3 1e+01          12 1.027919e+02 0.8096859
##  8:      CIFAR10  5623     Logistic     4 1e+04          13 1.202190e+05 0.8072651
##  9:      CIFAR10  5623 SquaredHinge     1 1e+03           1 1.744445e+07 0.7710211
## 10:      CIFAR10  5623 SquaredHinge     2 1e+00           1 1.163525e+03 0.7354803
## 11:      CIFAR10  5623 SquaredHinge     3 1e+00           8 2.199932e+09 0.7309735
## 12:      CIFAR10  5623 SquaredHinge     4 1e+05           1 1.974501e+11 0.7753759
## 13: FashionMNIST 10000          AUM     1 1e+02          61 1.475747e+02 0.9817591
## 14: FashionMNIST 10000          AUM     2 1e+01          70 1.553757e+01 0.9816031
## 15: FashionMNIST 10000          AUM     3 1e+05          75 1.575107e+05 0.9818049
## 16: FashionMNIST 10000          AUM     4 1e+02          67 1.507560e+02 0.9820311
## 17: FashionMNIST 10000     Logistic     1 1e+00         397 8.089332e+00 0.9408162
## 18: FashionMNIST 10000     Logistic     2 1e+02        1125 6.918590e+02 0.9405631
## 19: FashionMNIST 10000     Logistic     3 1e+02        1213 6.432875e+02 0.9414778
## 20: FashionMNIST 10000     Logistic     4 1e+03         931 7.283925e+03 0.9408533
## 21: FashionMNIST 10000 SquaredHinge     1 1e+01          71 4.527093e-02 0.9781764
## 22: FashionMNIST 10000 SquaredHinge     2 1e+01          94 1.379243e-01 0.9808044
## 23: FashionMNIST 10000 SquaredHinge     3 1e+01          47 5.958961e-02 0.9759747
## 24: FashionMNIST 10000 SquaredHinge     4 1e+01          23 4.981834e-02 0.9650889
## 25:        MNIST 18032          AUM     1 1e+01          28 3.038475e+00 0.9967078
## 26:        MNIST 18032          AUM     2 1e+03          36 3.333767e+02 0.9967440
## 27:        MNIST 18032          AUM     3 1e+03          29 2.631508e+02 0.9969475
## 28:        MNIST 18032          AUM     4 1e+02          34 2.607299e+01 0.9970675
## 29:        MNIST 18032     Logistic     1 1e+00       45322 7.714394e+00 0.9899026
## 30:        MNIST 18032     Logistic     2 1e+00       44783 7.678055e+00 0.9898945
## 31:        MNIST 18032     Logistic     3 1e+00       44620 7.705319e+00 0.9899023
## 32:        MNIST 18032     Logistic     4 1e+00       44829 7.701845e+00 0.9901057
## 33:        MNIST 18032 SquaredHinge     1 1e+02         215 1.577004e-02 0.9964240
## 34:        MNIST 18032 SquaredHinge     2 1e+02         178 1.847402e-02 0.9968762
## 35:        MNIST 18032 SquaredHinge     3 1e+02         158 1.802334e-02 0.9968006
## 36:        MNIST 18032 SquaredHinge     4 1e+02         225 1.207210e-02 0.9969883
## 37:        STL10  1778          AUM     1 1e+01          22 2.455220e+03 0.8432584
## 38:        STL10  1778          AUM     2 1e+00          21 2.232408e+02 0.8457865
## 39:        STL10  1778          AUM     3 1e+05          23 2.420980e+07 0.8483989
## 40:        STL10  1778          AUM     4 1e+00          13 2.384768e+02 0.8461657
## 41:        STL10  1778     Logistic     1 1e+03          17 1.080996e+05 0.8076966
## 42:        STL10  1778     Logistic     2 1e+02           2 6.999322e+03 0.8243258
## 43:        STL10  1778     Logistic     3 1e+03           5 1.096540e+05 0.8046910
## 44:        STL10  1778     Logistic     4 1e+01          14 1.213560e+03 0.8106742
## 45:        STL10  1778 SquaredHinge     1 1e-01           1 5.429723e+03 0.7627528
## 46:        STL10  1778 SquaredHinge     2 1e+05           1 2.601109e+16 0.7589888
## 47:        STL10  1778 SquaredHinge     3 1e+01           6 4.489175e+34 0.7541152
## 48:        STL10  1778 SquaredHinge     4 1e-01           1 2.382808e+02 0.8266292
##        data.name     N         loss  seed    lr step_number   loss_value       auc
```

## Easy dot plot visualization

A visualization method which is simple to code is shown below:


``` r
library(ggplot2)
ggplot()+
  geom_point(aes(
    auc, loss),
    data=best.dt)+
  facet_grid(. ~ data.name)
```

![plot of chunk dot](/assets/img/2024-08-30-viz-pred-err/dot-1.png)

The plot above shows four dots for each loss and data set. Already we
can see that loss=AUM tends to have the largest `auc` values, in each
data set. Rather than showing the four data sets using the same X axis
scale, we can show more subtle differences, by allowing each data set
to have its own X axis scale, as below.


``` r
ggplot()+
  geom_point(aes(
    auc, loss),
    data=best.dt)+
  facet_grid(. ~ data.name, scales="free", labeller=label_both)
```

![plot of chunk dot-scale-free](/assets/img/2024-08-30-viz-pred-err/dot-scale-free-1.png)

Above we see each data set has its own scale, but some of the tick
marks are not readable. This can be fixed by specifying non-default
panel spacing values in the theme, as below.


``` r
ggplot()+
  geom_point(aes(
    auc, loss),
    data=best.dt)+
  facet_grid(. ~ data.name, scales="free", labeller=label_both)+
  theme(
    panel.spacing=grid::unit(1.5, "lines"))
```

![plot of chunk dot-panel-space](/assets/img/2024-08-30-viz-pred-err/dot-panel-space-1.png)

In the plot above there is now another issue: the last X tick mark
goes off the right edge of the plot. To fix that we need to adjust the
plot margin, as below.


``` r
ggplot()+
  geom_point(aes(
    auc, loss),
    data=best.dt)+
  facet_grid(. ~ data.name, scales="free", labeller=label_both)+
  theme(
    plot.margin=grid::unit(c(0,1,0,0), "lines"),
    panel.spacing=grid::unit(1.5, "lines"))
```

![plot of chunk dot-plot-margin](/assets/img/2024-08-30-viz-pred-err/dot-plot-margin-1.png)

The plot above looks like a reasonable summary of the results, but the labels could be improved.

* We could explain more details about each algorithm in the Y axis labels.
* We could simplify the panel/facet variable names, `data.name` above, to simply `Data`, as below.
* We could use the more common capital `AUC` rather than lower `auc`, and explain that it is the max on the validation set.


``` r
loss2show <- rev(c(
  Logistic="Logistic/Cross-entropy\n(classic baseline)",
  SquaredHinge="All Pairs Squared Hinge\n(recent alternative)",
  AUM="AUM=Area Under Min(FP,FN)\n(proposed complex loss)",
  NULL))
best.dt[, `:=`(
  Loss = factor(loss2show[loss], loss2show),
  Data = data.name
)]
ggplot()+
  geom_point(aes(
    auc, Loss),
    data=best.dt)+
  facet_grid(. ~ Data, scales="free", labeller=label_both)+
  scale_x_continuous(
    "Max validation AUC (4 random initializations)")+
  theme(
    plot.margin=grid::unit(c(0,1,0,0), "lines"),
    panel.spacing=grid::unit(1.5, "lines"))
```

![plot of chunk dot-labels](/assets/img/2024-08-30-viz-pred-err/dot-labels-1.png)

Note the `Loss` names in code above is arranged to be consistent with
their display in the plot above: the `Loss` column factor levels come
from `loss2show`, and are used to determine the order of display of
the tick marks in the Y axis.

## Display mean and standard deviation

Whereas in the previous section we displayed each random seed as a
different dot, below we compute and plot the mean and SD over random seeds.
And while we are at it, we can also compute the range (min and max), for the AUC as well as for the number of gradient descent epochs.


``` r
(best.wide <- dcast(
  best.dt,
  Data + Loss ~ .,
  list(mean, sd, length, min, max),
  value.var=c("auc","step_number")))
```

```
## Key: <Data, Loss>
##             Data                                               Loss  auc_mean step_number_mean       auc_sd
##           <char>                                             <fctr>     <num>            <num>        <num>
##  1:      CIFAR10 AUM=Area Under Min(FP,FN)\n(proposed complex loss) 0.8205572            42.25 0.0012836241
##  2:      CIFAR10      All Pairs Squared Hinge\n(recent alternative) 0.7532127             2.75 0.0232189982
##  3:      CIFAR10         Logistic/Cross-entropy\n(classic baseline) 0.8107824            23.75 0.0047546328
##  4: FashionMNIST AUM=Area Under Min(FP,FN)\n(proposed complex loss) 0.9817996            68.25 0.0001768922
##  5: FashionMNIST      All Pairs Squared Hinge\n(recent alternative) 0.9750111            58.75 0.0069031630
##  6: FashionMNIST         Logistic/Cross-entropy\n(classic baseline) 0.9409276           916.50 0.0003887880
##  7:        MNIST AUM=Area Under Min(FP,FN)\n(proposed complex loss) 0.9968667            31.75 0.0001704442
##  8:        MNIST      All Pairs Squared Hinge\n(recent alternative) 0.9967723           194.00 0.0002446508
##  9:        MNIST         Logistic/Cross-entropy\n(classic baseline) 0.9899513         44888.50 0.0001030444
## 10:        STL10 AUM=Area Under Min(FP,FN)\n(proposed complex loss) 0.8459024            19.75 0.0021060041
## 11:        STL10      All Pairs Squared Hinge\n(recent alternative) 0.7756215             2.25 0.0341884983
## 12:        STL10         Logistic/Cross-entropy\n(classic baseline) 0.8118469             9.50 0.0086704638
##     step_number_sd auc_length step_number_length   auc_min step_number_min   auc_max step_number_max
##              <num>      <int>              <int>     <num>           <int>     <num>           <int>
##  1:      10.812801          4                  4 0.8192649              29 0.8220866              55
##  2:       3.500000          4                  4 0.7309735               1 0.7753759               8
##  3:      26.297972          4                  4 0.8072651               7 0.8177584              63
##  4:       5.852350          4                  4 0.9816031              61 0.9820311              75
##  5:      30.598203          4                  4 0.9650889              23 0.9808044              94
##  6:     365.820994          4                  4 0.9405631             397 0.9414778            1213
##  7:       3.862210          4                  4 0.9967078              28 0.9970675              36
##  8:      31.379399          4                  4 0.9964240             158 0.9969883             225
##  9:     302.591584          4                  4 0.9898945           44620 0.9901057           45322
## 10:       4.573474          4                  4 0.8432584              13 0.8483989              23
## 11:       2.500000          4                  4 0.7541152               1 0.8266292               6
## 12:       7.141428          4                  4 0.8046910               2 0.8243258              17
```

In the result table above, we also compute the `length` to double
check that the mean/etc was indeed taken over the four random seeds.
The code/plot below only uses the mean.


``` r
ggplot()+
  theme(
    plot.margin=grid::unit(c(0,1,0,0), "lines"),
    panel.spacing=grid::unit(1.5, "lines"))+
  geom_point(aes(
    auc_mean, Loss),
    shape=1,
    data=best.wide)+
  facet_grid(. ~ Data, labeller=label_both, scales="free")+
  scale_x_continuous(
    "Max validation AUC (Mean over 4 random initializations)")
```

![plot of chunk mean-only](/assets/img/2024-08-30-viz-pred-err/mean-only-1.png)

The plot above is not very useful for comparing the different Loss
functions, because it only shows the mean, without showing any measure
of the variance. We fix that in the code/plot below, by computing `lo`
and `hi` limits to display based on the SD.


``` r
best.wide[, `:=`(
  lo = auc_mean-auc_sd,
  hi = auc_mean+auc_sd
)]
ggplot()+
  theme(
    plot.margin=grid::unit(c(0,1,0,0), "lines"),
    panel.spacing=grid::unit(1.5, "lines"))+
  geom_point(aes(
    auc_mean, Loss),
    shape=1,
    data=best.wide)+
  geom_segment(aes(
    lo, Loss,
    xend=hi, yend=Loss),
    data=best.wide)+
  facet_grid(. ~ Data, labeller=label_both, scales="free")+
  scale_x_continuous(
    "Max validation AUC (Mean ± SD over 4 random initializations)")
```

![plot of chunk mean-sd](/assets/img/2024-08-30-viz-pred-err/mean-sd-1.png)

The plot above is much better, because it shows the SD as well as the mean.
We could additionally write the values of mean and SD, as below.


``` r
ggplot()+
  theme(
    plot.margin=grid::unit(c(0,1,0,0), "lines"),
    panel.spacing=grid::unit(1.5, "lines"))+
  geom_point(aes(
    auc_mean, Loss),
    shape=1,
    data=best.wide)+
  geom_segment(aes(
    lo, Loss,
    xend=hi, yend=Loss),
    data=best.wide)+
  geom_text(aes(
    auc_mean, Loss,
    label=sprintf(
      "%.4f±%.4f", auc_mean, auc_sd)),
    size=3,
    vjust=1.5,
    data=best.wide)+
  facet_grid(. ~ Data, labeller=label_both, scales="free")+
  scale_x_continuous(
    "Max validation AUC (Mean ± SD over 4 random initializations)")
```

![plot of chunk mean-sd-text-mid](/assets/img/2024-08-30-viz-pred-err/mean-sd-text-mid-1.png)

Above, only some of the text is readable, and others go outside of the panels.
To fix this, we can use `aes(hjust)`:

* The default `hjust=0.5`, used in the plot above, draws the text centered around the mean value.
* if the mean is less than the mid point of the panel X axis, then we
  can use `hjust=0` which means text will be left justified with the
  mean value as the limit. In other words, the text will start writing
  from the mean value, and go to the right of the mean value, but is
  guaranteed to not go left of the mean value, so it will not go off
  the panel to the left.
* otherwise, we can use `hjust=1` which means text will be right
  justified to the mean value.
  
To get this scheme to work, we need to compute the mid-point on the X
axis (auc) of each panel, which we do in the code below.


``` r
best.wide[
, mid := (min(lo)+max(hi))/2
, by=Data]
ggplot()+
  theme(
    plot.margin=grid::unit(c(0,1,0,0), "lines"),
    panel.spacing=grid::unit(1.5, "lines"))+
  geom_point(aes(
    auc_mean, Loss),
    shape=1,
    data=best.wide)+
  geom_segment(aes(
    lo, Loss,
    xend=hi, yend=Loss),
    data=best.wide)+
  geom_text(aes(
    auc_mean, Loss,
    hjust=ifelse(auc_mean<mid, 0, 1),
    label=sprintf(
      "%.4f±%.4f", auc_mean, auc_sd)),
    size=3,
    vjust=1.5,
    data=best.wide)+
  facet_grid(. ~ Data, labeller=label_both, scales="free")+
  scale_x_continuous(
    "Max validation AUC (Mean ± SD over 4 random initializations)")
```

![plot of chunk mean-sd-aes-hjust](/assets/img/2024-08-30-viz-pred-err/mean-sd-aes-hjust-1.png)

The plot above has text that can be read to determine the mean and SD values of each loss, in each data set.

## Display accuracy and computation time in scatter plot

In the plots above, we only examined prediction accuracy. Below we
additionally examine the number of iterations/epochs of gradient
descent, in order to determine which loss function results in fastest learning.


``` r
ggplot()+
  theme_bw()+
  theme(
    plot.margin=grid::unit(c(0,1,0,0), "lines"),
    legend.key.spacing.y=grid::unit(1, "lines"),
    axis.text.x=element_text(angle=30, hjust=1),
    panel.spacing=grid::unit(1.5, "lines"))+
  geom_point(aes(
    auc_mean, step_number_mean,
    color=Loss),
    shape=1,
    data=best.wide)+
  geom_segment(aes(
    auc_min, step_number_mean,
    color=Loss,
    xend=auc_max, yend=step_number_mean),
    data=best.wide)+
  geom_segment(aes(
    auc_mean, step_number_min,
    color=Loss,
    xend=auc_mean, yend=step_number_max),
    data=best.wide)+
  facet_wrap("Data", nrow=1, labeller=label_both, scales="free")+
  scale_y_log10(
    "Gradient descent epochs\n(using best learning rate)")+
  scale_x_continuous(
    "Best validation AUC (dot=mean, segments=range over 4 random initializations)")
```

![plot of chunk scatter](/assets/img/2024-08-30-viz-pred-err/scatter-1.png)

In the plot above, we again see Best validation AUC on the X axis, and
we see number of epochs on the Y axis. So we can see that the AUM loss
has largest Best validation AUC (so AUM can be more accurate), as well
as comparable/smaller number of epochs (so AUM can be faster). However
there are a couple of details worth fixing, for improved clarity:

* The default color scale in ggplot2 results in a blue and green which
  can be difficult to distinguish, so I recommend using Cynthia
  Brewer's color palettes, such as
  [Dark2](https://colorbrewer2.org/#type=qualitative&scheme=Dark2&n=3).
* Some data/segments go outside the range of the Y axis ticks, which
  can make the Y axis difficult to read, so we can use `geom_blank` to
  increase the Y axis range.


``` r
dput(RColorBrewer::brewer.pal(3,"Dark2"))
```

```
## c("#1B9E77", "#D95F02", "#7570B3")
```

``` r
loss.colors <- c("black", "#D95F02", "#7570B3")
names(loss.colors) <- loss2show
p <- function(Data,x,y)data.table(Data,x,y)
blank.dt <- rbind(
  p("CIFAR10",0.8,100),
  p("MNIST",0.99,c(10,100000)),
  p("STL10",0.8,30))
ggplot()+
  theme_bw()+
  theme(
    plot.margin=grid::unit(c(0,1,0,0), "lines"),
    legend.key.spacing.y=grid::unit(1, "lines"),
    axis.text.x=element_text(angle=30, hjust=1),
    panel.spacing=grid::unit(1.5, "lines"))+
  geom_blank(aes(x, y), data=blank.dt)+
  geom_point(aes(
    auc_mean, step_number_mean,
    color=Loss),
    shape=1,
    data=best.wide)+
  geom_segment(aes(
    auc_min, step_number_mean,
    color=Loss,
    xend=auc_max, yend=step_number_mean),
    data=best.wide)+
  geom_segment(aes(
    auc_mean, step_number_min,
    color=Loss,
    xend=auc_mean, yend=step_number_max),
    data=best.wide)+
  facet_wrap("Data", nrow=1, labeller=label_both, scales="free")+
  scale_color_manual(
    values=loss.colors)+
  scale_y_log10(
    "Gradient descent epochs\n(using best learning rate)")+
  scale_x_continuous(
    "Best validation AUC (dot=mean, segments=range over 4 random initializations)")
```

![plot of chunk scatter-improved](/assets/img/2024-08-30-viz-pred-err/scatter-improved-1.png)

Note above how the Y axes have expanded, and now there are tick marks
above the range of the data/segments, which makes the Y axis easier to
read. Also the color legend has changed: I use black for the proposed
method, and two other colors from Cynthia Brewer's Dark2 palette.

## Conclusions

Our goal was to explore how machine learning error/accuracy rates can be visualized, in order to compare different algorithms. 
We discussed various techniques for creating visualizations that make it easy for the reader to compare different algorithms.

## Session info


``` r
sessionInfo()
```

```
## R version 4.4.1 (2024-06-14)
## Platform: x86_64-pc-linux-gnu
## Running under: Ubuntu 22.04.4 LTS
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
## time zone: America/New_York
## tzcode source: system (glibc)
## 
## attached base packages:
## [1] stats     graphics  utils     datasets  grDevices methods   base     
## 
## other attached packages:
## [1] ggplot2_3.5.1     data.table_1.16.0
## 
## loaded via a namespace (and not attached):
##  [1] vctrs_0.6.5        cli_3.6.2          knitr_1.47         rlang_1.1.3        xfun_0.45          highr_0.11        
##  [7] generics_0.1.3     glue_1.7.0         labeling_0.4.3     colorspace_2.1-0   scales_1.3.0       fansi_1.0.6       
## [13] grid_4.4.1         munsell_0.5.0      evaluate_0.23      tibble_3.2.1       lifecycle_1.0.4    compiler_4.4.1    
## [19] dplyr_1.1.4        RColorBrewer_1.1-3 pkgconfig_2.0.3    farver_2.1.1       R6_2.5.1           tidyselect_1.2.1  
## [25] utf8_1.2.4         pillar_1.9.0       magrittr_2.0.3     tools_4.4.1        withr_3.0.0        gtable_0.3.4
```
