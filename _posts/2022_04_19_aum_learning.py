import pandas as pd
import numpy as np
from pytorch_lightning.metrics.classification import AUROC
compute_auc = AUROC()

# work-around for rendering plots under windows, which hangs within
# emacs python shell: instead write a PNG file and view in browser.
import webbrowser
on_windows = os.name == "nt"
in_render = r.in_render if 'r' in dir() else False
using_agg = on_windows and not in_render
if using_agg:
    import matplotlib
    matplotlib.use("agg")
def show(g):
    if not using_agg:
        return g
    g.save("tmp.png")
    webbrowser.open('tmp.png')

spam_df = pd.read_csv(
    "~/teaching/cs570-spring-2022/data/spam.data",
    header=None,
    sep=" ")

spam_features = spam_df.iloc[:,:-1].to_numpy()
spam_labels = spam_df.iloc[:,-1].to_numpy()
# 1. feature scaling
spam_mean = spam_features.mean(axis=0)
spam_sd = np.sqrt(spam_features.var(axis=0))
scaled_features = (spam_features-spam_mean)/spam_sd
scaled_features.mean(axis=0)
scaled_features.var(axis=0)

np.random.seed(1)
n_folds = 5
fold_vec = np.random.randint(low=0, high=n_folds, size=spam_labels.size)
validation_fold = 0
is_set_dict = {
    "validation":fold_vec == validation_fold,
    "subtrain":fold_vec != validation_fold,
}

import torch
set_features = {}
set_labels = {}
for set_name, is_set in is_set_dict.items():
    set_features[set_name] = torch.from_numpy(
        scaled_features[is_set,:]).float()
    set_labels[set_name] = torch.from_numpy(
        spam_labels[is_set]).float()
{set_name:array.shape for set_name, array in set_features.items()}

nrow, ncol = set_features["subtrain"].shape
class NNet(torch.nn.Module):
    def __init__(self, n_hidden=200):
        super(NNet, self).__init__()
        self.seq = torch.nn.Sequential(
            torch.nn.Linear(ncol, n_hidden),
            torch.nn.ReLU(),
            torch.nn.Linear(n_hidden, 1)
            )
    def forward(self, feature_mat):
        return self.seq(feature_mat)

class CSV(torch.utils.data.Dataset):
    def __init__(self, features, labels):
        self.features = features
        self.labels = labels
    def __getitem__(self, item):
        return self.features[item,:], self.labels[item]
    def __len__(self):
        return len(self.labels)
subtrain_dataset = CSV(set_features["subtrain"], set_labels["subtrain"])
subtrain_dataloader = torch.utils.data.DataLoader(
    subtrain_dataset, batch_size=20, shuffle=True)

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
    return torch.mean(uniq_min * uniq_thresh.diff())

loss_dict = {
    "logistic":torch.nn.BCEWithLogitsLoss(),
    "AUM":(AUM, 0.00004)
    }

def compute_loss_pred(features, labels):
    pred_mat = model(features)
    pred_vec = pred_mat.reshape(len(pred_mat))
    return loss_dict["logistic"](pred_vec, labels), pred_vec

loss_df_list = []
max_epochs=100
torch.manual_seed(1)
model = NNet()
optimizer = torch.optim.Adam(model.parameters(), lr=0.0005)
for epoch in range(max_epochs):
    # first update weights.
    for batch_features, batch_labels in subtrain_dataloader:
        optimizer.zero_grad()
        batch_loss, pred_vec = compute_loss_pred(batch_features, batch_labels)
        batch_loss.backward()
        optimizer.step()
    # then compute subtrain/validation loss.
    for set_name in set_features:
        feature_mat = set_features[set_name]
        label_vec = set_labels[set_name]
        set_loss, pred_vec = compute_loss_pred(feature_mat, label_vec)
        loss_df_list.append(pd.DataFrame({
            "epoch":[epoch],
            "set_name":[set_name],
            "variable":["AUM"],
            "value":set_loss.detach().numpy(),
            }))
        loss_df_list.append(pd.DataFrame({
            "epoch":[epoch],
            "set_name":[set_name],
            "variable":["AUC"],
            "value":compute_auc(pred_vec, label_vec).detach().numpy(),
            }))
loss_df = pd.concat(loss_df_list)

import plotnine as p9
gg = p9.ggplot()+\
    p9.facet_grid("variable ~ .", labeller="label_both", scales="free")+\
    p9.geom_line(
        p9.aes(
            x="epoch",
            y="value",
            color="set_name"
        ),
        data=loss_df)
show(gg)
