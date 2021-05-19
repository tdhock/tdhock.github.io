---
layout: post
title: Convex clustering theory
description: Recent results on trees and cluster shapes
---

During my PhD studies (ten years ago!) I published my first ML
conference paper, about [convex
clustering](http://www.icml-2011.org/papers/419_icmlpaper.pdf) for
ICML'11. This has been a very influential paper, with over 200
citations as of 2021 according to [Google
Scholar](https://scholar.google.com/scholar?cites=12486355391677933103&as_sdt=805&sciodt=0,3&hl=en). In
this paper we proved that the regularization path of convex clustering
is agglomerative (it is a tree), for the case of L1 norm
regularization with identity weights.

There have been a number of very interesting theoretical results
published since then, by other groups. For example Chi and
Steinerberger, in Recovering Trees with Convex Clustering [SIAM
J. Math. Data
Sci. (2019)](http://www.ericchi.com/ec_papers/ChiSteinerberger2019.pdf),
show conditions that are required for an agglomerative regularization
path. Basically, the weights should be consistent with the data.

Another really interesting and well-written paper appeared on arXiv
today: Nguyen and Mamitsuka, On Convex Clustering Solutions
[arXiv:2105.08348](https://arxiv.org/pdf/2105.08348.pdf). They prove
various results for the case of the L2 norm and identity
weights. First, the recovered cluster shape must be convex (can NOT
recover non-convex shapes as in classical the
agglomerative/hierarchical clustering algorithm). Second, clusters are
circular, which means there are bounding balls with significant gaps
between them (k-means clusters have no gaps). Third, the distance
between cluster center and boundary is proportional to the cluster
size (unlike k-means in which this distance is constant between
clusters).

