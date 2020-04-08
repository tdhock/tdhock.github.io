---
layout: post
title: Custom evaluation metrics in TensorFlow
description: Implementing the exact area under the ROC curve
---

TensorFlow is a low-level neural network library with interfaces in
[python](https://www.tensorflow.org/api_docs/python) and
[R](https://tensorflow.rstudio.com/). Keras is the analogous
high-level API for quick design and experimentation, also with
interfaces in [python](https://www.tensorflow.org/guide/keras) and
[R](https://keras.rstudio.com/).

For my [CS499 Deep Learning class this
semester](https://github.com/tdhock/cs499-spring2020) I have been
making screencasts that show how to use tensorflow/keras in R:
[basics](https://www.youtube.com/playlist?list=PLwc48KSH3D1PYdSd_27USy-WFAHJIfQTK),
[demonstrating that the number of hidden units/layers is a
regularization
parameter](https://www.youtube.com/playlist?list=PLwc48KSH3D1MvTf_JOI00_eIPcoeYMM_o).

In this post I show how to implement a custom evaluation metric, the
exact area under the [Receiver Operating
Characteristic](https://en.wikipedia.org/wiki/Receiver_operating_characteristic)
(ROC) curve. This is common/popular evaluation metric for binary
classification, which is surprisingly not provided by
tensorflow/keras. It does provide an approximate AUC computation,
[tf.keras.metrics.AUC](https://www.tensorflow.org/api_docs/python/tf/keras/metrics/AUC). In
most data/models there should not be big differences between the exact
and approximate method, but in some extreme cases there may be
differences in terms of accuracy (the approximation will not work if
there are lots of predicted scores close to 0 or 1) or speed (for very
large data the approximation may result in speedups).

To begin, I wanted to use the same python/tensorflow/keras versions
that I used from within R, because I noticed that on this old computer
(MacBook Pro circa 2010) the recent versions of tensorflow crash. I
figured out that this is a known
[issue](https://github.com/tensorflow/tensorflow/issues/19584) since
TensorFlow version 1.6, for which the binaries only work on CPUs that
support AVX instructions. My laptop CPU (Intel Core 2 Duo CPU P8600 @
2.40GHz) does not (`grep avx /proc/cpuinfo` returns nothing). So I
installed an old version of tensorflow (1.5.0) and keras (2.1.6) in R
via

```
keras::install_keras(version = "2.1.6", tensorflow = "1.5")
```

That installed those python packages in
`~/.local/share/r-miniconda/envs/r-reticulate/` so get access to that
software I first needed to initialize conda for my shell via

```
~/.local/share/r-miniconda/bin/conda init bash
```

Then I restarted my shell and I got conda on my path

```
(base) tdhock@maude-MacBookPro:~/teaching/cs499-spring2020/projects$ conda -V
conda 4.8.3
```

Next I activate the r-reticulate environment where that software was
installed:

```
(base) tdhock@maude-MacBookPro:~/teaching/cs499-spring2020/projects$ conda activate r-reticulate
(r-reticulate) tdhock@maude-MacBookPro:~/teaching/cs499-spring2020/projects$ 
```

That gives me access to tensorflow inside of python:

```
(r-reticulate) tdhock@maude-MacBookPro:~/teaching/cs499-spring2020/projects$ python -c 'import tensorflow'
/home/tdhock/.local/share/r-miniconda/envs/r-reticulate/lib/python3.6/site-packages/tensorflow/python/framework/dtypes.py:493: FutureWarning: Passing (type, 1) or '1type' as a synonym of type is deprecated; in a future version of numpy, it will be understood as (type, (1,)) / '(1,)type'.
...
```

Now my goal is to first reproduce the same computations that I did in
R, which is fitting a neural network to the spam data set. First I
looked at the python
[keras.Model.fit](https://www.tensorflow.org/api_docs/python/tf/keras/Model#fit)
documentation to see the format it needs for the data:

```
x: Input data. It could be:
- A Numpy array (or array-like), or a list of arrays 
  (in case the model has multiple inputs).
- A TensorFlow tensor, or a list of tensors 
  (in case the model has multiple inputs).
- A dict mapping input names to the corresponding array/tensors, 
  if the model has named inputs.
- A tf.data dataset. Should return a tuple of either 
  (inputs, targets) or (inputs, targets, sample_weights).
- A generator or keras.utils.Sequence returning (inputs, targets)
  or (inputs, targets, sample weights). 
  A more detailed description of unpacking behavior 
  for iterator types (Dataset, generator, Sequence) 
  is given below.

y: Target data. Like the input data x, 
  it could be either Numpy array(s) or TensorFlow tensor(s). 
  It should be consistent with x 
  (you cannot have Numpy inputs and tensor targets, or inversely).
  If x is a dataset, generator, or keras.utils.Sequence instance,
  y should not be specified 
  (since targets will be obtained from x).
```

So I can pass inputs/outputs as numpy arrays, after reading from CSV
and standardizing the inputs:

```
import numpy as np
spam = np.genfromtxt("spam.data", delimiter=" ")
X_unscaled = spam[:,:-1]
X = (X_unscaled-X_unscaled.mean(axis=0))/X_unscaled.std(axis=0)
y = spam[:,-1]
```

Next step is to divide the data into train/test:

```
n_folds = 5
test_fold_ids = np.arange(n_folds)
np.random.seed(0)
test_fold_vec = np.random.permutation(np.tile(test_fold_ids, len(y))[:len(y)])
test_fold = 0
set_dict = {
    "test": test_fold_vec == test_fold,
    "train": test_fold_vec != test_fold,
    }
X_dict = {}
y_dict = {}
for set_name, is_set in set_dict.items():
    X_dict[set_name] = X[is_set, :]
    y_dict[set_name] = y[is_set]
```

Next we can define and fit the neural network model:

```
import tensorflow as tf
from metrics import ExactAUC #my code
inputs = tf.keras.Input(shape=(X.shape[1],))
hidden = tf.keras.layers.Dense(
    100, activation="sigmoid", use_bias=False)(inputs)
outputs = tf.keras.layers.Dense(
    1, activation="sigmoid", use_bias=False)(hidden)
model = tf.keras.Model(inputs=inputs, outputs=outputs, name="spam_model")
model.compile(
    optimizer=tf.keras.optimizers.Adam(),
    loss=tf.keras.losses.binary_crossentropy,
    metrics=["accuracy", ExactAUC])
n_epochs = 100
history = model.fit(
    X_dict["train"], y_dict["train"],
    epochs=n_epochs,
    verbose=2,
    validation_split=0.5)
```

Note that in the `model.compile` call above I gave the ExactAUC custom
metric function defined below (and saved to `metrics.py`):

```
import keras.backend as K
def ExactAUC(label_arg, pred_arg, weight = None):
  N = K.tf.size(label_arg, name="N")
  y_true = K.reshape(label_arg, shape=(N,))
  y_pred = K.reshape(pred_arg, shape=(N,))
  if weight is None:
    weight = K.tf.fill(K.shape(y_pred), 1.0)
  sort_result = K.tf.nn.top_k(y_pred, N, sorted=False, name="sort")
  y = K.gather(y_true, sort_result.indices)
  y_hat = K.gather(y_pred, sort_result.indices)
  w = K.gather(weight, sort_result.indices)
  is_negative = K.equal(y, K.tf.constant(0.0))
  is_positive = K.equal(y, K.tf.constant(1.0))
  w_zero = K.tf.fill(K.shape(y_pred), 0.0)
  w_negative = K.tf.where(is_positive, w_zero, w, name="w_negative")
  w_positive = K.tf.where(is_negative, w_zero, w)
  cum_positive = K.cumsum(w_positive)
  cum_negative = K.cumsum(w_negative)
  is_diff = K.not_equal(y_hat[:-1], y_hat[1:])
  is_end = K.tf.concat([is_diff, K.tf.constant([True])], 0)
  total_positive = cum_positive[-1]
  total_negative = cum_negative[-1]
  TP = K.tf.concat([
    K.tf.constant([0.]),
    K.tf.boolean_mask(cum_positive, is_end),
    ], 0)
  FP = K.tf.concat([
    K.tf.constant([0.]),
    K.tf.boolean_mask(cum_negative, is_end),
    ], 0)
  FPR = FP / total_negative
  TPR = TP / total_positive
  return K.sum((FPR[1:]-FPR[:-1])*(TPR[:-1]+TPR[1:])/2)
```

This may seem like a relatively complex implementation of the AUC, and
it is. For example the `K.reshape` calls at the start seem pretty
un-necessary, but I got errors with keras if I did not include
them. The important thing to realize when reading/writing code like
this is that your function is not performing computations, but it is
instead defining a computation graph. The inputs/outputs to the
ExactAUC function are Tensors, which are essentially nodes in a
computation graph. So the return value of ExactAUC is not the AUC
value, but it is a description about how the AUC may be computed from
two input label/prediction tensors.

I verified my implementation of the AUC by placing the following test
code at the end of the `metrics.py` file:

```
if __name__ == "__main__":
    test_dict = {
      "1 tie":{
        "label":[0, 0, 1, 1],
        "pred":[1.0, 2, 3, 1],
        "auc": 5/8,
      },
      "no ties, perfect":{
        "label":[0,0,1,1],
        "pred":[1,2,3,4],
        "auc":1,
      },
      "one bad error":{
        "label":[0,0,1,1],
        "pred":[1,2,3,-1],
        "auc":1/2,
      },
      "one not so bad error":{
        "label":[0,0,1,1],
        "pred":[1,2,3,1.5],
        "auc":3/4,
      }
    }
    sess = K.tf.Session()
    for test_name, test_data in test_dict.items():
      tensor_data = {
        k:K.tf.constant(v, K.tf.float32)
        for k,v in test_data.items()
      }
      g = ExactAUC(tensor_data["label"], tensor_data["pred"])
      auc = sess.run(g)
      if auc != test_data["auc"]:
        print("%s expected=%f computed=%f" % (test_name, test_data["auc"], auc))
```

When executing that file I get the following output, which indicates
that the AUC computation works as expected (the numpy warnings are
irrelevant):

```
(r-reticulate) tdhock@maude-MacBookPro:~/teaching/cs499-spring2020/projects$ python metrics.py
Using TensorFlow backend.
/home/tdhock/.local/share/r-miniconda/envs/r-reticulate/lib/python3.6/site-packages/tensorflow/python/framework/dtypes.py:493: FutureWarning: Passing (type, 1) or '1type' as a synonym of type is deprecated; in a future version of numpy, it will be understood as (type, (1,)) / '(1,)type'.
  _np_qint8 = np.dtype([("qint8", np.int8, 1)])
/home/tdhock/.local/share/r-miniconda/envs/r-reticulate/lib/python3.6/site-packages/tensorflow/python/framework/dtypes.py:494: FutureWarning: Passing (type, 1) or '1type' as a synonym of type is deprecated; in a future version of numpy, it will be understood as (type, (1,)) / '(1,)type'.
  _np_quint8 = np.dtype([("quint8", np.uint8, 1)])
/home/tdhock/.local/share/r-miniconda/envs/r-reticulate/lib/python3.6/site-packages/tensorflow/python/framework/dtypes.py:495: FutureWarning: Passing (type, 1) or '1type' as a synonym of type is deprecated; in a future version of numpy, it will be understood as (type, (1,)) / '(1,)type'.
  _np_qint16 = np.dtype([("qint16", np.int16, 1)])
/home/tdhock/.local/share/r-miniconda/envs/r-reticulate/lib/python3.6/site-packages/tensorflow/python/framework/dtypes.py:496: FutureWarning: Passing (type, 1) or '1type' as a synonym of type is deprecated; in a future version of numpy, it will be understood as (type, (1,)) / '(1,)type'.
  _np_quint16 = np.dtype([("quint16", np.uint16, 1)])
/home/tdhock/.local/share/r-miniconda/envs/r-reticulate/lib/python3.6/site-packages/tensorflow/python/framework/dtypes.py:497: FutureWarning: Passing (type, 1) or '1type' as a synonym of type is deprecated; in a future version of numpy, it will be understood as (type, (1,)) / '(1,)type'.
  _np_qint32 = np.dtype([("qint32", np.int32, 1)])
/home/tdhock/.local/share/r-miniconda/envs/r-reticulate/lib/python3.6/site-packages/tensorflow/python/framework/dtypes.py:502: FutureWarning: Passing (type, 1) or '1type' as a synonym of type is deprecated; in a future version of numpy, it will be understood as (type, (1,)) / '(1,)type'.
  np_resource = np.dtype([("resource", np.ubyte, 1)])
2020-04-07 20:29:10.802414: I tensorflow/core/platform/cpu_feature_guard.cc:137] Your CPU supports instructions that this TensorFlow binary was not compiled to use: SSE4.1
(r-reticulate) tdhock@maude-MacBookPro:~/teaching/cs499-spring2020/projects$ 
```

So the code above indicates that I actually am using tensorflow
correctly for the AUC computation. Going back to the keras script
where I did the model fit, the result that I get is:

```
>>> model.compile(
...     optimizer=tf.keras.optimizers.Adam(),
...     loss=tf.keras.losses.binary_crossentropy,
...     metrics=["accuracy", ExactAUC])
... 
... n_epochs = 100
... history = model.fit(
...     X_dict["train"], y_dict["train"],
...     epochs=n_epochs,
...     verbose=2,
...     validation_split=0.5)
Train on 1840 samples, validate on 1840 samples
Epoch 1/100
2020-04-07 20:31:58.888751: I tensorflow/core/platform/cpu_feature_guard.cc:137] Your CPU supports instructions that this TensorFlow binary was not compiled to use: SSE4.1
 - 1s - loss: 0.3876 - acc: 0.8147 - ExactAUC: 0.9073 - val_loss: 0.9729 - val_acc: 0.2326 - val_ExactAUC: nan
Epoch 2/100
 - 0s - loss: 0.2656 - acc: 0.8886 - ExactAUC: 0.9529 - val_loss: 0.7407 - val_acc: 0.5875 - val_ExactAUC: nan
...
```

The output above shows numeric AUC values for the train set, but `nan`
for the validation set. I am not sure why this is happening, but I
think it has something to do with what values keras is passing to my
ExactAUC function. I assumed that I would get a vector of all
train/validation labels along with a vector of corresponding predicted
scores, but I guess that is not the case. And the documentation for
custom metrics is very sparse (it does not clarify what exactly is
passed to the custom metric function).

A [keras issue](https://github.com/keras-team/keras/issues/5794) about
removal of precision, recall, and F1 score states that "these are all
global metrics that were approximated batch-wise" which suggests that
(at least that old 2017 version of) keras is not capable of computing
global metrics such as AUC (which require access to the entire
train/validation sets). The versions I am using are as follows. Note
that `keras` and `tf.keras` modules are different:

```
>>> import tensorflow as tf
>>> import keras
>>> tf.__version__
'1.5.0'
>>> tf.keras.__version__
'2.1.2-tf'
>>> keras.__version__
'2.1.6'
```

It seems like in more recent versions of keras there has been some
change in how to define metrics. From the [keras 2.3.0 release
notes](https://github.com/keras-team/keras/releases/tag/2.3.0):

```
Introduce class-based metrics (inheriting from Metric base class). 
This enables metrics to be stateful (e.g. required for supported AUC)
```

This suggests that my exact AUC computation may work if I upgrade to
the most recent keras/tensorflow. So for now I won't file an issue,
because (as typical for active software projects) the [keras
contributing web page](https://keras.io/contributing/) says that
before you report an issue, you should update to the current master
and make sure the bug still is present. 

For next time: try to get my exact AUC metric working on the most
recent version of keras/tensorflow. If it works, it should be
substantially simpler than the existing approximate AUC implementation
in Tensorflow. 
