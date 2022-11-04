import os
on_windows = os.name == "nt"
rendering = r.rendering if 'r' in dir() else False
using_agg = on_windows and not rendering
if using_agg:
    import matplotlib
    matplotlib.use("agg")
import pandas as pd
import numpy as np
np.random.seed(1)
N = 1000
full_df = pd.DataFrame({
    "label":np.tile(["burned","no burn"],int(N/2)),
    "image":np.concatenate([
        np.repeat(1, 0.2*N), np.repeat(2, 0.4*N),
        np.repeat(3, 0.3*N), np.repeat(4, 0.1*N)
    ])
})
uniq_images = full_df.image.unique()
n_images = len(uniq_images)
full_df["signal"] = np.where(full_df.label=="no burn", 0, 2)
full_df
for n_noise in range(n_images-1):
    full_df["feature_easy_%s"%n_noise] = np.random.randn(N)
full_df["feature_easy_%s"%n_images] = np.random.randn(N)+full_df.signal
for img in uniq_images:
    noise = np.random.randn(N)
    is_img = full_df.image == img
    full_df["feature_impossible_%s"%img] = np.where(
        is_img, full_df.signal+noise, noise)
n_folds = 3
import math
def get_fold_ids(some_array):
    n_out = len(some_array)
    arange_vec = np.arange(n_folds)
    tile_vec = np.tile(arange_vec, math.ceil(n_out/n_folds))[:n_out]
    return pd.DataFrame({
        "fold":np.random.permutation(tile_vec),
        })
new_fold_df = full_df.groupby("image").apply(get_fold_ids)
full_df["fold"] = new_fold_df.reset_index().fold
pd.crosstab(full_df.fold, full_df.image)
from sklearn.model_selection import GroupKFold
gkf = GroupKFold(n_splits=n_folds)
from sklearn.linear_model import LogisticRegressionCV
from sklearn.model_selection import GridSearchCV
from sklearn.neighbors import KNeighborsClassifier
error_df_list = []
extract_df = full_df.columns.str.extract("feature_(?P<type>[^_]+)")
feature_name_series = extract_df.value_counts().reset_index().type
for feature_name in feature_name_series:
    is_feature = np.array([feature_name in col for col in full_df.columns])
    for test_fold, index_tup in enumerate(gkf.split(full_df, groups=full_df.fold)):
        index_dict = dict(zip(["all_train","all_test"], index_tup))
        df_dict = {
            set_name:full_df.iloc[index_array]
            for set_name, index_array in index_dict.items()}
        for target_img in full_df.image.unique():
            is_same_dict = {
                set_name:set_df.image == target_img
                for set_name, set_df in df_dict.items()}
            df_dict["test"] = df_dict["all_test"].loc[ is_same_dict["all_test"], :]
            is_same_values_dict = {
                "all":[True,False],
                "same":[True],
                "other":[False],
                }
            train_name_list = []
            for data_name, is_same_values in is_same_values_dict.items():
                train_name_list.append(data_name)
                train_is_same = is_same_dict["all_train"].isin(is_same_values)
                df_dict[data_name] = df_dict["all_train"].loc[train_is_same,:]
            same_nrow, same_ncol = df_dict["same"].shape
            for data_name in "all", "other":
                small_name = data_name+"_small"
                train_name_list.append(small_name)
                train_df = df_dict[data_name]
                all_indices = np.arange(len(train_df))
                small_indices = np.random.permutation(all_indices)[:same_nrow]
                df_dict[small_name] = train_df.iloc[small_indices,:]
            xy_dict = {
                data_name:(df.loc[:,is_feature], df.label)
                for data_name, df in df_dict.items()}
            test_X, test_y = xy_dict["test"]
            for train_name in train_name_list:
                train_X, train_y = xy_dict[train_name]
                param_dicts = [{'n_neighbors':[x]} for x in range(1, 21)]
                learner_dict = {
                    "linear_model":LogisticRegressionCV(),
                    "nearest_neighbors":GridSearchCV(
                        KNeighborsClassifier(), param_dicts)
                    }
                featureless_pred = train_y.value_counts().index[0]
                pred_dict = {
                    "featureless":np.repeat(featureless_pred, len(test_y)),
                }
                for algorithm, learner in learner_dict.items():
                    learner.fit(train_X, train_y)
                    pred_dict[algorithm] = learner.predict(test_X)
                for algorithm, pred_vec in pred_dict.items():
                    error_vec = pred_vec != test_y
                    out_df=pd.DataFrame({
                        "feature_name":[feature_name],
                        "test_fold":[test_fold],
                        "target_img":[target_img],
                        "test_nrow":[len(test_y)],
                        "train_nrow":[len(train_y)],
                        "train_name":[train_name],
                        "algorithm":[algorithm],
                        "error_percent":[error_vec.mean()*100],
                        })
                    print(out_df)
                    error_df_list.append(out_df)
error_df = pd.concat(error_df_list)
import plotnine as p9

for feature_name in feature_name_series:
    feature_df = error_df.query("feature_name == '%s'"%feature_name)
    feature_df["Algorithm"] = "\n"+feature_df.algorithm
    gg = p9.ggplot()+\
        p9.geom_point(
            p9.aes(
                x="error_percent",
                y="train_name"
            ),
            data=feature_df)+\
        p9.facet_grid("Algorithm ~ target_img", scales="free", labeller="label_both")+\
        p9.ggtitle("Features: "+feature_name)
    gg.save("2022-11-03-generalization-to-new-subsets-%s.png"%feature_name, width=10, height=5)
