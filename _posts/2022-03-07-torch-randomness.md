---
layout: post
title: Torch randomness
description: Reproducible neural network learning
---



Today I discussed with my students how to control randomness in torch
neural network learning code. The [torch
docs](https://pytorch.org/docs/stable/generated/torch.manual_seed.html)
describe manual_seed as "Sets the seed for generating random numbers."

## Neural network weights

When you instantiate a class which represents weights in a neural
network, their values are a function of the random seed. For example:


```python
import torch
n_outputs = 2
n_seeds = 2
n_reps = 2
for seed in range(n_seeds):
    for repetition in range(n_reps):
        torch.manual_seed(seed)
        weight_vec = torch.nn.Linear(n_outputs, 1)
        print("seed=%s repetition=%s"%(seed,repetition))
        print(weight_vec._parameters)
        print("")
```

```
## <torch._C.Generator object at 0x0000000060764670>
## seed=0 repetition=0
## OrderedDict([('weight', Parameter containing:
## tensor([[-0.0053,  0.3793]], requires_grad=True)), ('bias', Parameter containing:
## tensor([-0.5820], requires_grad=True))])
## 
## <torch._C.Generator object at 0x0000000060764670>
## seed=0 repetition=1
## OrderedDict([('weight', Parameter containing:
## tensor([[-0.0053,  0.3793]], requires_grad=True)), ('bias', Parameter containing:
## tensor([-0.5820], requires_grad=True))])
## 
## <torch._C.Generator object at 0x0000000060764670>
## seed=1 repetition=0
## OrderedDict([('weight', Parameter containing:
## tensor([[ 0.3643, -0.3121]], requires_grad=True)), ('bias', Parameter containing:
## tensor([-0.1371], requires_grad=True))])
## 
## <torch._C.Generator object at 0x0000000060764670>
## seed=1 repetition=1
## OrderedDict([('weight', Parameter containing:
## tensor([[ 0.3643, -0.3121]], requires_grad=True)), ('bias', Parameter containing:
## tensor([-0.1371], requires_grad=True))])
```

## Batch order in Stochastic Gradient Descent

Actually in torch the stochastic gradient descent sampling is
typically controlled via a `DataLoader`. If `shuffle=False` then the
batch indices go from smallest to largest.


```python
N_data = 10
class trivial(torch.utils.data.Dataset):
    def __getitem__(self, item):
        return item
    def __len__(self):
        return N_data
ds = trivial()
dl = torch.utils.data.DataLoader(ds, batch_size=3, shuffle=False)
[batch for batch in dl]
```

```
## [tensor([0, 1, 2]), tensor([3, 4, 5]), tensor([6, 7, 8]), tensor([9])]
```

If you want random batching you can do `shuffle=True` and control for
randomness via `manual_seed`,


```python
n_epochs = 2
for seed in range(n_seeds):
    for repetition in range(n_reps):
        torch.manual_seed(seed)
        dl = torch.utils.data.DataLoader(ds, batch_size=3, shuffle=True)
        for epoch in range(n_epochs):
            print("seed=%s repetition=%s epoch=%s"%(seed,repetition,epoch))
            print([batch for batch in dl])
            print("")
```

```
## <torch._C.Generator object at 0x0000000060764670>
## seed=0 repetition=0 epoch=0
## [tensor([6, 7, 1]), tensor([4, 2, 0]), tensor([9, 8, 3]), tensor([5])]
## 
## seed=0 repetition=0 epoch=1
## [tensor([2, 4, 7]), tensor([0, 8, 9]), tensor([5, 3, 6]), tensor([1])]
## 
## <torch._C.Generator object at 0x0000000060764670>
## seed=0 repetition=1 epoch=0
## [tensor([6, 7, 1]), tensor([4, 2, 0]), tensor([9, 8, 3]), tensor([5])]
## 
## seed=0 repetition=1 epoch=1
## [tensor([2, 4, 7]), tensor([0, 8, 9]), tensor([5, 3, 6]), tensor([1])]
## 
## <torch._C.Generator object at 0x0000000060764670>
## seed=1 repetition=0 epoch=0
## [tensor([4, 2, 0]), tensor([6, 8, 7]), tensor([9, 1, 5]), tensor([3])]
## 
## seed=1 repetition=0 epoch=1
## [tensor([4, 8, 1]), tensor([5, 0, 2]), tensor([3, 6, 9]), tensor([7])]
## 
## <torch._C.Generator object at 0x0000000060764670>
## seed=1 repetition=1 epoch=0
## [tensor([4, 2, 0]), tensor([6, 8, 7]), tensor([9, 1, 5]), tensor([3])]
## 
## seed=1 repetition=1 epoch=1
## [tensor([4, 8, 1]), tensor([5, 0, 2]), tensor([3, 6, 9]), tensor([7])]
```

## Data splitting

Some splits are deterministic, others are random. Exercise for the
reader: show how to control randomness in data splitting, as above.
