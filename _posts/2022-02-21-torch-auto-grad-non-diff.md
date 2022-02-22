---
layout: post
title: AUM in Torch
description: Auto-grad of a non-differentiable loss function
---





Last week I met Joe Barr of [Acronis](https://acronisscs.com/) who
gave a talk at NAU about an application of machine learning to
predicting security vulnerabilities based on source code analysis, and
a database of exploits. The data they are using for training/testing
their models is highly imbalanced so I suggested trying my new [Area
Under the Min(FP,FN) loss function (AUM)](https://arxiv.org/abs/2107.01285).

After talking with them about the easiest way to try this new loss
function on their data, I decided that it would be good to code it up
in torch (for automatic differentiation). To do that we need the
`torch.argsort` operation, which is also used for Area Under ROC Curve
computation in `_binary_clf_curve` in `roc` in `auroc` in `forward`
method of `AUROC` class, see
[pytorch_lightning.metrics.classification](https://github.com/PyTorchLightning/PyTorch-Lightning/blob/0.8.5/pytorch_lightning/metrics/classification.py)
and
[metrics.function.classification](https://github.com/PyTorchLightning/pytorch-lightning/blob/92d6abcbb9e73645fff0bba2914f7a7e0e748a91/pytorch_lightning/metrics/functional/classification.py)
source code.

Below I wrote an implementation of our AUM loss function, 


```python
import torch
def AUM(pred_tensor, label_tensor):
    """Area Under Min(FP,FN)

    Loss function for imbalanced binary classification
    problems. Minimizing AUM empirically results in maximizing Area
    Under the ROC Curve (AUC). Arguments: pred_tensor and label_tensor
    should both be 1d tensors (vectors of real-valued predictions and
    labels for each observation in the set/batch).

    """
    fn_diff = torch.where(label_tensor == 1, -1, 0)
    fp_diff = torch.where(label_tensor == 1, 0, 1)
    thresh_tensor = -pred_tensor.flatten()
    sorted_indices = torch.argsort(thresh_tensor)
    sorted_fp_cum = fp_diff[sorted_indices].cumsum(axis=0)
    sorted_fn_cum = -fn_diff[sorted_indices].flip(0).cumsum(axis=0).flip(0)
    sorted_thresh = thresh_tensor[sorted_indices]
    sorted_is_diff = sorted_thresh.diff() != 0
    sorted_fp_end = torch.cat([sorted_is_diff, torch.tensor([True])])
    sorted_fn_end = torch.cat([torch.tensor([True]), sorted_is_diff])
    uniq_thresh = sorted_thresh[sorted_fp_end]
    uniq_fp_after = sorted_fp_cum[sorted_fp_end]
    uniq_fn_before = sorted_fn_cum[sorted_fn_end]
    uniq_min = torch.minimum(uniq_fn_before[1:], uniq_fp_after[:-1])
    return torch.sum(uniq_min * uniq_thresh.diff())
```

The implementation above consists of vectorized torch operations, all
of which should be differentiable almost everywhere. To check the
automatically computed gradient from torch with the directional
derivatives described in our paper, we can use the backward method,


```python
def loss_grad(pred_vec, label_vec):
    pred_tensor = torch.tensor(pred_vec)
    pred_tensor.requires_grad = True
    label_tensor = torch.tensor(label_vec)
    loss = AUM(pred_tensor, label_tensor)
    loss.backward()
    return loss, pred_tensor.grad
```

## Simple differentiable points

Let us consider an example from the aum R package,


```r
bin.diffs <- aum::aum_diffs_binary(c(0,1))
aum::aum(bin.diffs, c(-10,10))
```

```
## $aum
## [1] 0
## 
## $derivative_mat
##      [,1] [,2]
## [1,]    0    0
## [2,]    0    0
```

The R code and output above shows that for one negative label with
predicted value -10, and one positive label with predicted value 10,
we have AUM=0 and directional derivatives are also zero. That is also
seen in the python code below:


```python
y_list = [0, 1]
loss_grad([-10.0, 10.0], y_list)
```

```
## (tensor(0., grad_fn=<SumBackward0>), tensor([-0., -0.]))
```

Another example is for the same labels but the opposite predicted
values, for which the R code is below,


```r
aum::aum(bin.diffs, c(10,-10))
```

```
## $aum
## [1] 20
## 
## $derivative_mat
##      [,1] [,2]
## [1,]    1    1
## [2,]   -1   -1
```

The R code and output above shows that we have AUM=20 and derivative 1
for the first/negative example, and derivative -1 for the
second/positive example. Those derivatives indicate that the AUM can
be decreased by decreasing the predicted value for the first/negative
example and/or increasing the predicted vale for the second/positive
example. Consistent results can be observed from the python code
below,


```python
loss_grad([10.0, -10.0], y_list)
```

```
## (tensor(20., grad_fn=<SumBackward0>), tensor([ 1., -1.]))
```

## Non-differentiable points

As discussed in our paper, the AUM is not differentiable everywhere.
So what happens when you use auto-grad on a non-differentiable loss?
Apparently the backward method returns a subgradient, as explained in
[an issue discussing autograd of L1 loss
function](https://github.com/pytorch/pytorch/issues/7172).

One example, again taken from the aum R package, is when both
predicted values are zero,


```r
aum::aum(bin.diffs, c(0,0))
```

```
## $aum
## [1] 0
## 
## $derivative_mat
##      [,1] [,2]
## [1,]    0    1
## [2,]   -1    0
```

The output above indicates AUM=0 with directional derivatives which
are not equal on the left and right. The first row of the directional
derivative matrix says that decreasing the first/negative predicted
value will result in no change to AUM, whereas increasing will result
in increasing AUM. The second row says that decreasing the
second/positive predicted value results in increasing AUM, whereas
increasing the predicted value results in no change to AUM. Is the
python torch auto-grad code consistent?


```python
loss_grad([0.0, 0.0], y_list)
```

```
## (tensor(0., grad_fn=<SumBackward0>), tensor([-0., -0.]))
```

The output above says that the gradient is zero, which is OK (these
predicted values are a minimum) but it is missing some information
about what happens nearby.

## Non-convex points

The implementation above of AUM is only for binary classification, but
in our paper we also discuss an application to changepoint detection
problems. In the case of changepoint detection problems with
non-monotonic error functions, the AUM may be non-convex, and there
may be points at which there are no subgradients. Some are used as
[test cases in our R package](https://github.com/tdhock/aum/blob/main/tests/testthat/test-CRAN.R).
What does auto-grad return in that case? (exercise for the reader)

