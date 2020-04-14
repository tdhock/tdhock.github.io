---
layout: post
title: Data manipulation libraries
description: Translating between data.table, pandas, dplyr
---

Writing code for data manipulation is an important part of any machine
learning project or research paper. To me data manipulation is a very
general class of operations which involves anything that converts data
from one format to another. Data manipulation is useful for (1)
pre-processing in order to get the right format for machine learning
algorithms, and (2) post-processing in order to get the right format
for visualization using tables or figures.

### Python pandas and R data.table for plotting keras model fit metrics

When training machine learning models such as neural networks, it is
important to monitor various loss/accuracy metrics, and plot them as a
function of the regularization hyper-parameter. For example in my
[screencasts about neural networks using keras in
R](https://www.youtube.com/playlist?list=PLwc48KSH3D1PYdSd_27USy-WFAHJIfQTK)
we plot subtrain/validation loss/accuracy versus number of epochs, in
order to see when the neural network starts to overfit. In this
section I comment on how I coded this in R, and how I translaed it
into python.

The first step is to use the keras package in R to declare and fit a
neural network model, which I did with the following code (note `....`
means a bunch of irrelevant code has been omitted):

```r
model <- keras::keras_model_sequential() %>% ....
history <- model %>% keras::fit(....)
```

The `fit` function returns a named list of numeric vectors (names are
metrics such as `loss`, `val_loss`, `acc`, `val_acc` for logistic loss
and proportion accuracy with respect to train or validation sets),
which we then convert to a data table with an additional `epoch`
column via:

```r
history.wide <- do.call(data.table::data.table, history$metrics)
history.wide[, epoch := 1:.N]
```

The resulting data table looks like

```r
      val_loss   val_acc       loss       acc epoch
  1: 0.3261010 0.9010870 0.49783516 0.7798913     1
  2: 0.2535547 0.9114130 0.26578763 0.9228261     2
  3: 0.2392319 0.9163043 0.21651624 0.9326087     3
  4: 0.2274921 0.9206522 0.19466753 0.9304348     4
  5: 0.2212409 0.9255435 0.18036880 0.9336957     5
 ---                                               
 96: 0.3007694 0.9255435 0.05798265 0.9831522    96
 97: 0.3010736 0.9244565 0.05763476 0.9831522    97
 98: 0.3025759 0.9260870 0.05615792 0.9820652    98
 99: 0.3045697 0.9260870 0.05674289 0.9836957    99
100: 0.3036924 0.9250000 0.05580203 0.9820652   100
```

Doing the same computations in python looks like

```py
import tensorflow as tf
import pandas as pd
model = tf.keras.Model(....)
history = model.fit(....)
history_wide = pd.DataFrame(history.history)
history_wide["epoch"] = np.arange(len(history_wide.index))+1
```

The python `model.fit` method above returns a dictionary with keys for
metric names (`val_loss` etc) and values which are numpy arrays, which
are combined into a `DataFrame` with one row for each epoch. 

After having created a wide data table (with different metrics in
different columns), the next step to visualizing these data with the
grammar of graphics (ggplots) is to reshape the data into tall format,
e.g.

```r
     epoch prefix metric     value
  1:     1   val_   loss 0.3261010
  2:     2   val_   loss 0.2535547
  3:     3   val_   loss 0.2392319
  4:     4   val_   loss 0.2274921
  5:     5   val_   loss 0.2212409
 ---                              
396:    96           acc 0.9831522
397:    97           acc 0.9831522
398:    98           acc 0.9820652
399:    99           acc 0.9836957
400:   100           acc 0.9820652
```

In the tall data table above, the original four metric columns have
been reshaped into a single `value` column. There is also a copy of
the original `epoch` column, and two new columns which indicate the
set and metric. To accomplish that conversion in R I used the
following function from my
[nc](https://cloud.r-project.org/web/packages/nc/) package:

```r
history.tall.sets <- nc::capture_melt_single(
  history.wide,
  set="val_|",
  metric="loss|acc")
```

The functional call above performs the reshape operation on all of the
columns from the first argument `history.wide` which match the regex
provided in the other arguments, which are pasted together to form the
final regex which will be used for matching. For more info see [my
recently submitted article about the new functions in nc for data
reshaping using regular
expressions](https://github.com/tdhock/nc-article/raw/master/RJwrapper.pdf). 

To accomplish something similar in the python code below we first use
the `melt` function to get a tall version of the data, then we use
`extract` and `concat` functions to get the desired output:

```py
history_tall = pd.melt(history_wide, id_vars="epoch")
history_var_info = history_tall["variable"].str.extract(
    "(?P<prefix>val_|)(?P<metric>.*)")
history_tall_sets = pd.concat([history_tall, history_var_info], axis=1)
```

Translating the code above back to R results in the code below, which
is essentially what `nc::capture_melt_single` does under the hood:

```r
history.tall <- data.table::melt(history.wide, id.vars="epoch")
history.var.info <- nc::capture_first_vec(
  history.tall$variable, prefix="val_|", metric=".*")
history.tall.sets <- data.table::data.table(history.tall, history.var.info)
```

The next step is to add a variable for the set name that we want to
display in the plot,

```r
history.tall.sets[, set := ifelse(prefix=="val_", "validation", "subtrain")]
```

```py
history_tall_sets["set"] = history_tall_sets["prefix"].apply(
    lambda x: "validation" if x == "val_" else "subtrain")
```

Finally we plot these data using the R code

```r
library(ggplot2)
ggplot()+
  geom_line(aes(
    x=epoch, y=value, color=set),
    data=history.tall.sets)+
  theme_bw()+
  theme(panel.spacing=grid::unit(0, "lines"))+
  facet_grid("metric")
ggsave("5-acc-loss.png", width=5, height=5)
```

Or the equivalent python code,

```py
import plotnine as p9
gg = p9.ggplot(
    history_tall_sets,
    p9.aes(x="epoch", y="value", color="set"))+\
    p9.geom_line()+\
    p9.theme_bw()+\
    p9.facet_grid("metric ~ .", scales="free")+\
    p9.theme(
        facet_spacing={'right': 0.75}, #due to bug in legend.
        panel_spacing=0)
gg.save("5-acc-loss.png", width=5, height=5)
```

Note that the [plotnine](https://github.com/has2k1/plotnine) python
module seems to be the current best implementation of ggplots, but I
still prefer ggplots in R, especially because it is so easy to add
textual labels for these kind of plots via my
[directlabels](http://directlabels.r-forge.r-project.org/docs/lineplot/posfuns/last.polygons.html)
package.

### Comparison with datatable python module

The R `data.table` developers have created a port of their highly
efficient C code to python, in the
[datatable](https://github.com/h2oai/datatable) module. However I
wasn't able to use it do to the same computations as above, because it
does not yet support the melt operation (wide to tall data
reshaping). I posted an
[issue](https://github.com/h2oai/datatable/issues/2400) because the
presence/absence of this key feature was not mentioned in the
[documentation](https://datatable.readthedocs.io/en/v0.10.1/quick-start.html). In
that issue there is a link to [a very detailed comparison of features
provided by data.table and dplyr/tidyverse in
R](https://atrebas.github.io/post/2019-03-03-datatable-dplyr/), which
I would recommend reading for anyone doing data manipulation in R (and
especially my students). [Another interesting
comparison](https://towardsdatascience.com/an-overview-of-pythons-datatable-package-5d3a97394ee9)
shows that for some big data sets, reading CSV using datatable and
then converting to pandas can actually be faster than directly reading
data in pandas.

