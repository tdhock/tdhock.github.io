---
layout: post
title: Ward clustering
description: Review of existing segmentation and clustering 
---

How fast is [Ward clustering](https://en.wikipedia.org/wiki/Ward%27s_method)?
This is an agglomerative/hierarchical clustering algorithm which can be implemented in terms of joining data points by minimizing pairwise distances (like single linkage), and it can be interpreted as minimizing the within-cluster sum of squares (like binary segmentation).

## In theory

The [hierarchical clustering](https://en.wikipedia.org/wiki/Hierarchical_clustering) wikipedia page says it is cubic, `O(N^3)` in the general case.

* Have to compute `O(N^2)` pairwise distance matrix.
* Then need to perform `N-1` joins.
* So overall depends on how fast each join can be computed.
* Each join using single linkage (min) criterion is `O(N)`, so overall `O(N^2)`.
* Ward algorithm is a special case of the [Lance-Williams algorithms](https://en.wikipedia.org/wiki/Ward%27s_method#Lance%E2%80%93Williams_algorithms), which is when each new distance, after cluster join, can be computed using a simple `O(1)` update rule. So each join event requires `O(N)` time to re-compute distances. Computing all `N-1` join events therefore takes `O(N^2)` time.

## With constraints

In an application to HiC data, the `N` samples we want to cluster occur on a 2D grid.
Assuming 4-connectivity, we can only join with 4 neighbors (not `N-1`), so the algorithm should be faster.
But we want to avoid computing the `O(N^2)` pairwise distance matrix, so we can no longer use a Lance-Williams update rule.
Instead we would have to update cluster means, which we use to compute new distances.

## In code

[_agglomerative.py](https://github.com/scikit-learn/scikit-learn/blob/c60dae2060/sklearn/cluster/_agglomerative.py) has `ward_tree()` has a recursive merge loop.

* It uses a heap, keeps distances sorted (log-time insertion, constant time min).
* It uses moments matrices: `moments_1` is the number of samples (clusters x 1), and `moments_2` is the matrix of sums (clusters x features).
* It sets `n_nodes` to the number of output nodes in the tree, and initially allocates various arrays of this size (moments, used indicator, parent, etc).
* `used_node` indicator marks joins which are no longer possible, because the corresponding nodes have already been involved in other joins. There is a `while` loop which keeps going until it finds a join which involves only unused nodes. This is slightly sub-optimal (in C++ this could be reduced from log to constant time using pointers, but this does not matter much).

[_hierarchical_fast.pyx](https://github.com/scikit-learn/scikit-learn/blob/c60dae20604f8b9e585fc18a8fa0e0fb50712179/sklearn/cluster/_hierarchical_fast.pyx)
has `compute_ward_dist()` which has two for loops: `size_max` (I guess clusters) and `n_features`.

Using the cumulative sum trick would be about as fast (same asymptotic complexity class) as this python code, which seems to compute the new distances in constant time given the means, based on the formula involving the difference of two means from [Hierarchical Clustering, Cluster Linkage](https://en.wikipedia.org/wiki/Hierarchical_clustering#Cluster_Linkage).

## Exercises for the reader

* Compute empirical asymptotic time complexity of `ward_tree()`.
* Show that the three segmentation algos give the same result in 1D (Ward via Lance-Williams, Ward via moments as in python, cumsum trick).
