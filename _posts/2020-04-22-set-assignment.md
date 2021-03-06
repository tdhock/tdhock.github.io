---
layout: post
title: Random train/validation/test assignment
description: Different methods tried by my students
---

In the programming projects that I wrote for [my CS499 Deep Learning
class](https://github.com/tdhock/cs499-spring2020), I require the
students to write code that splits a data set into a certain percent
train/validation/test. For example in [project
4](https://github.com/tdhock/cs499-spring2020/blob/master/projects/4.org)
there is a 80% train / 20% test split, followed by a split of the
train set into 60% subtrain / 40% validation. Sometimes we also want
to split the entire data set into 60% train / 20% validation / 20%
test.

One of my students implemented this in R using the `sample` function
as below

```r
train.test.N <- 4601
train.test.props <- c(train=0.8, test=0.2)
for(seed in 1:3){
  set.seed(seed)
  train.test.vec <- sample(
    names(train.test.props),
    train.test.N,
    replace = TRUE,
    prob = train.test.props)
  print(table(train.test.vec)/train.test.N)
}

```

The code above performs sampling with replacement, with identical
probabilities for each draw, which gives different set sizes for
each seed:

```
train.test.vec
     test     train 
0.2077809 0.7922191 
train.test.vec
     test     train 
0.2082156 0.7917844 
train.test.vec
     test     train 
0.1990872 0.8009128 
```

That code does pretty much what we want: random assignment of sets
with approximately the given proportions. One minor issue was already
mentioned above: the set sizes depend on the random seed. 

What code should we write if we wanted to get the same set sizes for
each random seed, and have those sets be the closest possible to our
target proportions?

Using the `data.table` package I wrote the following function which
takes in a data set size `N` and a named numeric vector of
proportions, and then returns a character vector of size `N`:

```r

library(data.table)
random_set_vec <- function(N, prob.vec){
  obs.dt <- data.table(obs=1:N)
  cum.dt <- data.table(cum.obs=cumsum(prob.vec)*N, set=names(prob.vec))
  join.dt <- cum.dt[i=obs.dt, j=.(set=set[1]), on=.(cum.obs >= obs), by=.EACHI]
  sample(join.dt$set)
}

```

There are several issues with doing it as above, but first let's
discuss the code. The function above makes use of the `cumsum`
function on the second line in order to convert the proportions to
cumulative probabilities. Then the third line uses several advanced
features of the `data.table` package. First, `on=.(cum.obs >= obs)`
indicates a non-equi join, which means to join the two data tables
`obs.dt` and `cum.dt` for all rows such that `cum.i` is greater than
or equal to `i`. Second, `by=.EACHI` means to group by each row of the
given `i` data table `obs.dt`. The `j=.(set=set[1])` argument
indicates to summarize by creating a `set` column that is equal to the
first element of each group. This achieves the desired result:

```r

train.test.N <- 4601
train.test.props <- c(train=0.8, test=0.2)
for(seed in 1:3){
  set.seed(seed)
  train.test.vec <- random_set_vec(train.test.N, train.test.props)
  print(head(train.test.vec))
  print(table(train.test.vec, useNA="ifany")/train.test.N)
}

```

That gives me the following output:

```
[1] "train" "train" "train" "test"  "train" "train"
train.test.vec
     test     train 
0.2001739 0.7998261 
[1] "test"  "train" "test"  "test"  "train" "train"
train.test.vec
     test     train 
0.2001739 0.7998261 
[1] "train" "test"  "train" "train" "train" "train"
train.test.vec
     test     train 
0.2001739 0.7998261 
```

The tables indicate that the set sizes are the same for each seed, and
the head/printed character vector indicates that the placement of the
train/test values is indeed random/different.

Note that this works for any number of sets, e.g. 

```r

tvt.props <- c(test=0.19, train=0.67, validation=0.14)
tvt.N <- 1234567
system.time({
  tvt.vec <- random_set_vec(tvt.N, tvt.props)
})
table(tvt.vec, useNA="ifany")/tvt.N

```

However the group by operation starts to get slow for big N like the
above, e.g.

```
> system.time({
+   tvt.vec <- random_set_vec(tvt.N, tvt.props)
+ })
   user  system elapsed 
  2.611   0.001   2.629 
> table(tvt.vec, useNA="ifany")/tvt.N
tvt.vec
      test      train validation 
 0.1899994  0.6700001  0.1400005 
```

Is there an alternative that uses pure vector operations? The code
below uses the same logic (cumsum etc) but with the vectorized
`data.table::fcase` function:

```r

tvt.seq <- seq(1, tvt.N, l=tvt.N)/tvt.N
system.time({
  tvt.vec <- fcase(
    tvt.seq <= 0.19, "test",
    tvt.seq <= 0.86, "train",
    tvt.seq <= 1, "validation")
})
table(tvt.vec, useNA="ifany")/tvt.N

```

The output is:

```
   user  system elapsed 
   0.04    0.00    0.04 

tvt.vec
      test      train validation 
 0.1900002  0.6699993  0.1400005 
```

That is a lot faster! (1000x) But if we want to use that approach when
the proportions are supplied as data (rather than in code as above) we
need to do some meta-programming (writing code that writes code):

```r

tvt.props <- c(test=0.19, train=0.67, validation=0.14)
tvt.N <- 1234567
tvt.seq <- seq(1, tvt.N, l=tvt.N)/tvt.N
system.time({
  tvt.cum <- cumsum(tvt.props)
  fcase.args <- list(list(quote(data.table::fcase)))
  for(set in names(tvt.cum)){
    set.cum <- tvt.cum[[set]]
    fcase.args[[set]] <- list(
      substitute(tvt.seq <= X, list(X=set.cum)),
      set)
  }
  call.args <- do.call(c, fcase.args)
  fcase.call <- as.call(unname(call.args))
  tvt.vec <- eval(fcase.call)
})
table(tvt.vec, useNA="ifany")/tvt.N

```

What is the code above doing? The big picture is that the code above
creates `fcase.call` an R language object which represents a line of
un-evaluated R code that calls `fcase` just as in the previous,
hard-coded example: 

```
> fcase.call
data.table::fcase(tvt.seq <= 0.19, "test", tvt.seq <= 0.86, "train", 
    tvt.seq <= 1, "validation")
```

It is constructed by first initializing `fcase.args` as a list with
one element: a list containing `quote(data.table::fcase)`. Then each
iteration of the for loop adds a new element to the `fcase.args`
list. Each element is a list with two elements: 

```
> str(fcase.args[[2]])
List of 2
 $ : language tvt.seq <= 0.19
 $ : chr "test"
```

The first is a language object created by `substitute` that represents
an un-evaluated piece of R code, a test for `tvt.seq` less than or
equal to the given constant (which is substituted for the `X` variable
provided in the R code above). The second is a character scalar
constant which will be the value used if the inequality is true. Both
list elements will be used as arguments to `fcase` as in the
hard-coded version above. After the for loop we use `call.args <-
do.call(c, fcase.args)` to get the list below:

```
> str(call.args)
List of 7
 $            : language data.table::fcase
 $ test1      : language tvt.seq <= 0.19
 $ test2      : chr "test"
 $ train1     : language tvt.seq <= 0.86
 $ train2     : chr "train"
 $ validation1: language tvt.seq <= 1
 $ validation2: chr "validation"
```

When we pass the list above to `as.call` it interprets the first
element as the function to call, and the other elements as the
arguments to that function. Finally doing `tvt.vec <-
eval(fcase.call)` converts the R language object (un-evaluated R code)
to the evaluated result, giving us the desired output (character
vector of set names). The output I got from the code above is:

```
   user  system elapsed 
  0.045   0.000   0.046 

tvt.vec
      test      train validation 
 0.1899994  0.6700001  0.1400005 
```

The timing indicates that it is almost as fast as the hard-coded
version above! (there is some overhead in construction of the
list/language objects) 

Exercise 1 for the reader: how to further modify the code so that the
set sizes do not depend on the order in which the
test/train/validation sets are specified? More precisely, in the code
above we have the result below, which depends on the order in which
the sets are specified.

```
> table(random_set_vec(4601, c(train=0.8, test=0.2)))

 test train 
  921  3680 
> table(random_set_vec(4601, c(test=0.2, train=0.8)))

 test train 
  920  3681 
```

How to modify the code above so that the two versions give the same
result?

Exercise 2 for the reader: how to modify the function so that it
checks that the given proportions are valid? (each between 0 and 1 and
sum to 1)

A final question / exercise 3 for the reader: are the set sizes
optimal? Can you re-write the `random_set_vec` function so that it is
guaranteed to return set sizes that are optimal according to the
multinomial likelihood? (the answer is yes, and it significantly
simplifies the code, and it still is fast) Consider `tvt.N=4` with
`c(train=2/3, test=1/3)` and `tvt.N=3` with `c(train=0.5,
test=0.5)`. Hint 1: you can use `dbinom` or `dmultinom` to compute the
likelihood of a set size, given the desired proportions. Hint 2: the
set sizes that maximize the likelihood given by the mode of the
binomial/multinomial distribution. Here is a one-liner "solution" that
uses these ideas, but needs [some modification](https://github.com/tdhock/randomSets/blob/master/R/random_set_vec.R) in order to work
correctly for the given example:

```r
P <- c(test=0.5, train=0.5)
N <- 3
sample(rep(names(P), floor(P*(N+1)))) #two train, two test.
```

## Implementations in machine learning libraries

In this section I present how train/test splits are implemented in
some machine learning libraries.

First there is a sub-optimal implementation in
[sklearn.model_selection.train_test_split](https://github.com/scikit-learn/scikit-learn/blob/5a4340834d23c4bdcd813ccda24a690ae174c168/sklearn/model_selection/_split.py#L1780). Of
course it does not make a significant difference in big data sets, but
it is clear that the counts per set are sub-optimal for some small
data, e.g.

```py
from sklearn.model_selection import train_test_split
set_list = train_test_split(range(4), test_size=1.0/3, shuffle=False)
dict(zip(["train", "test"], set_list))
```

On my system the output of the code above is:

```
>>> dict(zip(["train", "test"], set_list))
{'test': [2, 3], 'train': [0, 1]}
>>> sklearn.__version__
'0.19.1'
```

Again that is not a huge problem, but returning a test set size of two
when the test proportion is 1/3 has binomial probability of 0.296,
whereas a test set size of one has binomial probability of 0.395, so
it would be more appropriate/representative of the given proportion to
return a test set size of one in this case.

Second I checked the implementation in
[mlr3::rsmp("holdout")](https://github.com/mlr-org/mlr3/blob/131afc3f7b6a9a9d1e65831b5139c2e954a5d463/R/ResamplingHoldout.R#L57)
which also appears to be sub-optimal, but in a different way:

```r

N <- 2
prop.train <- 0.7
task <- tsk("iris")$filter(1:N)
rho <- rsmp("holdout", ratio=prop.train)
set.seed(1)
rho$instantiate(task)
rho$train_set(1)
rho$test_set(1)
dbinom(0:N, N, prop.train)

```

The code above creates a data set of size `N <- 2` and then requests a
train/test split with a proportion of `prop.train <- 0.7` in the train
set. In this case a train set size of 2 is optimal with respect to the
binomial likelihood, but `mlr3` returns a split with one observation
in the train set and one observation in the test set:

```
> rho$train_set(1)
[1] 1
> rho$test_set(1)
[1] 2
> dbinom(0:N, N, prop.train)
[1] 0.09 0.42 0.49
> packageVersion("mlr3")
[1] ‘0.2.0’
```

Again, no big deal for big/real data situations, but the code could be
easily modified so that it is optimal in the small data case as well.

### Conclusions

In conclusion I have presented a variety of different methods for
dividing a data set into train/validation/test sets, based on given
proportions. They all give quite similar results, but the ideas I
presented may be desirable to obtain code that is (1) fast (2)
invariant to the order in which the sets are specified, and (3)
resulting in sets of the same/optimal size for any random seed.

