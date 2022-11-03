---
layout: post
title: Generalization to new subsets
description: Cross-validation in python
---





A number of students have asked me how to properly code
cross-validation, in order to compare generalization / accuracy of
different machine learning algorithms, when trained on different data
sets. For example in one project, a student is trying to build an
algorithm for satellite image segmentation. For each pixel in each
image, there should be a predicted class, which represents the
intensity of forest fire burn in that area of the image. The student
has about 10000 rows (pixels with labels), where each row comes from
one of 9 different images. I suggested the following cross-validation
experiment to determine the extent to which prediction error increases
when generalizing to new images.

Let's say there are 1000 rows,


```python
import pandas as pd
import numpy as np
N = 1000
full_df = pd.DataFrame({
    "feature":np.random.randn(N),
    "label":np.tile(["burned","no burn"],int(N/2)),
    })
```

And let's say that each row has an image ID, one of four images,


```python
full_df["image"] = np.concatenate([
    np.repeat(1, 0.2*N), np.repeat(2, 0.4*N),
    np.repeat(3, 0.3*N), np.repeat(4, 0.1*N)
])
full_df
```

```
##       feature    label  image
## 0    0.528527   burned      1
## 1   -0.701357  no burn      1
## 2   -0.430664   burned      1
## 3    0.083043  no burn      1
## 4   -0.468872   burned      1
## ..        ...      ...    ...
## 995  0.524254  no burn      4
## 996 -0.103435   burned      4
## 997 -2.282597  no burn      4
## 998  1.122587   burned      4
## 999  1.608295  no burn      4
## 
## [1000 rows x 3 columns]
```

We would like to fix a test image, and then compare models trained on
either the same image, or on different images (or all images). To
create a K-fold cross-validation experiment (say K=3 folds), we
therefore need to assign fold IDs in a way such that each image is
present in each fold. One way to do that would be to just use random
integers,


```python
n_folds = 3
np.random.seed(1)
full_df["random_fold"] = np.random.randint(1, n_folds+1, size=N)
pd.crosstab(full_df["random_fold"], full_df["image"])
```

```
## image         1    2    3   4
## random_fold                  
## 1            72  139   95  28
## 2            75  111  104  39
## 3            53  150  101  33
```

In the output above we see that for each image, there is not an equal
number of data assigned to each fold. How could we do that?


```python
import math
def get_fold_ids(some_array):
    n_out = len(some_array)
    arange_vec = np.arange(n_folds)
    tile_vec = np.tile(arange_vec, math.ceil(n_out/n_folds))[:n_out]
    return pd.DataFrame({
        "fold":np.random.permutation(tile_vec),
        })
np.random.seed(1)
new_fold_df = full_df.groupby("image").apply(get_fold_ids)
full_df["fold"] = new_fold_df.reset_index().fold
full_df
```

```
##       feature    label  image  random_fold  fold
## 0    0.528527   burned      1            2     1
## 1   -0.701357  no burn      1            1     1
## 2   -0.430664   burned      1            1     1
## 3    0.083043  no burn      1            2     0
## 4   -0.468872   burned      1            2     1
## ..        ...      ...    ...          ...   ...
## 995  0.524254  no burn      4            2     2
## 996 -0.103435   burned      4            3     0
## 997 -2.282597  no burn      4            2     2
## 998  1.122587   burned      4            1     0
## 999  1.608295  no burn      4            2     1
## 
## [1000 rows x 5 columns]
```

```python
pd.crosstab(full_df.fold, full_df.image)
```

```
## image   1    2    3   4
## fold                   
## 0      67  134  100  34
## 1      67  133  100  33
## 2      66  133  100  33
```

The table above shows that for each image, the number of data per fold
is equal (or off by one).

We can use these fold IDs with `GroupKFold` from Scikit-learn:


```python
from sklearn.model_selection import GroupKFold
gkf = GroupKFold(n_splits=n_folds)
for test_fold, index_tup in enumerate(gkf.split(full_df, groups=full_df.fold)):
    set_indices = dict(zip(["train","test"], index_tup))
    for set_name, index_array in set_indices.items():
        set_df = full_df.iloc[index_array]
        print("\nfold=%s, set=%s"%(test_fold,set_name))
        print(pd.crosstab(set_df.fold, set_df.image))
```

```
## 
## fold=0, set=train
## image   1    2    3   4
## fold                   
## 1      67  133  100  33
## 2      66  133  100  33
## 
## fold=0, set=test
## image   1    2    3   4
## fold                   
## 0      67  134  100  34
## 
## fold=1, set=train
## image   1    2    3   4
## fold                   
## 0      67  134  100  34
## 2      66  133  100  33
## 
## fold=1, set=test
## image   1    2    3   4
## fold                   
## 1      67  133  100  33
## 
## fold=2, set=train
## image   1    2    3   4
## fold                   
## 0      67  134  100  34
## 1      67  133  100  33
## 
## fold=2, set=test
## image   1    2    3   4
## fold                   
## 2      66  133  100  33
```

The output above indicates that there are equal proportions of each
image in each set (train and test). So we can fix a test fold, say 2,
and also a test image, say 4. Then there are 33 data points in that
test set. We can try to predict them by using machine learning
algorithms on several different train sets: 

* same: train folds (0 and 1) and same image (4), there are 34+33=67
  train data in this set.
* other: train folds (0 and 1) and other images (1-3), there are 601
  train data in this set.
* all: train folds (0 and 1) and all images (1-4), there are 668 train
  data in this set.

For each of the three trained models, we compute prediction error on
the test set (image 4, fold 2), then compare the error rates to
determine how much error changes when we train on a different set of
images.

* Because there are relatively few data from image 4, it may be
  beneficial to train on a larger data set (including images 1-3),
  even if those data are somewhat different. (and other/all error may
  actually be smaller than same error)
* Conversely, if the data in images 1-3 are substantially different,
  then it may not help at all to use different images. (in this case,
  same error would be smaller than other/all error)
  
Typically if there are a reasonable number of train data, the same
model should do better than other/all, but you have to do the
computational experiment to find out what is true for your particular
data set. The code to do that should look something like below,


```python
error_df_list = []
gkf = GroupKFold(n_splits=n_folds)
for test_fold, index_tup in enumerate(gkf.split(full_df, groups=full_df.fold)):
    index_dict = dict(zip(["train","test"], index_tup))
    df_dict = {
        set_name:full_df.iloc[index_array]
        for set_name, index_array in index_dict.items()}
    for target_img in full_df.image.unique():
        is_same_dict = {
            set_name:set_df.image == target_img
            for set_name, set_df in df_dict.items()}
        test_df = df_dict["test"].loc[ is_same_dict["test"], :]
        test_nrow, test_ncol = test_df.shape
        train_same_dict = {
            "all":[True,False],
            "same":[True],
            "other":[False],
            }
        for data_name, is_same_values in train_same_dict.items():
            train_is_same = is_same_dict["train"].isin(is_same_values)
            train_df = df_dict["train"].loc[train_is_same,:]
            train_nrow, train_col = train_df.shape
            # all of your model fitting code
            # prediction on test set, test_df
            out_df=pd.DataFrame({
                "test_fold":[test_fold],
                "target_img":[target_img],
                "test_nrow":[test_nrow],
                "train_nrow":[train_nrow],
                "data_name":[data_name],
                "error_percent":["TODO"],
                })
            error_df_list.append(out_df)
pd.concat(error_df_list)
```

```
##    test_fold  target_img  test_nrow  train_nrow data_name error_percent
## 0          0           1         67         665       all          TODO
## 0          0           1         67         133      same          TODO
## 0          0           1         67         532     other          TODO
## 0          0           2        134         665       all          TODO
## 0          0           2        134         266      same          TODO
## 0          0           2        134         399     other          TODO
## 0          0           3        100         665       all          TODO
## 0          0           3        100         200      same          TODO
## 0          0           3        100         465     other          TODO
## 0          0           4         34         665       all          TODO
## 0          0           4         34          66      same          TODO
## 0          0           4         34         599     other          TODO
## 0          1           1         67         667       all          TODO
## 0          1           1         67         133      same          TODO
## 0          1           1         67         534     other          TODO
## 0          1           2        133         667       all          TODO
## 0          1           2        133         267      same          TODO
## 0          1           2        133         400     other          TODO
## 0          1           3        100         667       all          TODO
## 0          1           3        100         200      same          TODO
## 0          1           3        100         467     other          TODO
## 0          1           4         33         667       all          TODO
## 0          1           4         33          67      same          TODO
## 0          1           4         33         600     other          TODO
## 0          2           1         66         668       all          TODO
## 0          2           1         66         134      same          TODO
## 0          2           1         66         534     other          TODO
## 0          2           2        133         668       all          TODO
## 0          2           2        133         267      same          TODO
## 0          2           2        133         401     other          TODO
## 0          2           3        100         668       all          TODO
## 0          2           3        100         200      same          TODO
## 0          2           3        100         468     other          TODO
## 0          2           4         33         668       all          TODO
## 0          2           4         33          67      same          TODO
## 0          2           4         33         601     other          TODO
```

The result table above has a row for every combination of test fold,
target image, ane train data name (all/other/same). Exercise for the
reader: fill in the TODO with some actual prediction error values. You
should have one more for loop over learning algorithms (and a
corresponding column in `out_df`). Try at least featureless (always
predict most frequent class in train data), linear model, and nearest
neighbors, as in my [Deep Learning class homework
2](https://github.com/tdhock/cs499-599-fall-2022/blob/main/homeworks/02-k-fold-cross-validation.org).
