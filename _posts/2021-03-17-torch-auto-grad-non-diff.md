---
layout: post
title: AUM in Torch
description: Auto-grad of a non-differentiable loss function
---

This is a work in progress!

## What happens with auto-grad on a non-differentiable loss?

Apparently the backward method returns a subgradient, as explained in
[an issue discussing autograd of L1 loss
function](https://github.com/pytorch/pytorch/issues/7172). 

However In the case of the non-convex AUM loss function, there may be
no subgradients. What should we return?

## Can we implement AUM loss in torch?

We would need a sort operation.

How do existing ROC-AUC functions work?
[ignite](https://github.com/pytorch/ignite/blob/cc76de461f63475f3b792c7c109fede95301556e/tests/ignite/contrib/metrics/test_roc_auc.py)
uses sklearn's implementation via `np.argsort` in `_binary_clf_curve`
in `roc_curve` in `_binary_roc_auc_score`, see
[sklearn.metrics._ranking](https://github.com/scikit-learn/scikit-learn/blob/95119c13af77c76e150b753485c662b7c52a41a2/sklearn/metrics/_ranking.py)
source code.

Torch lightning source code shows that the implementation is adapted
from sklearn:

```
adapted from https://github.com/scikit-learn/scikit-learn/blob/master/sklearn/metrics/_ranking.py
```

It uses `torch.argsort` in `_binary_clf_curve` in `roc` in `auroc` in
`forward` method of `AUROC` class, see
[pytorch_lightning.metrics.classification](https://github.com/PyTorchLightning/PyTorch-Lightning/blob/0.8.5/pytorch_lightning/metrics/classification.py)
and
[metrics.function.classification](https://github.com/PyTorchLightning/pytorch-lightning/blob/92d6abcbb9e73645fff0bba2914f7a7e0e748a91/pytorch_lightning/metrics/functional/classification.py)
source code.
