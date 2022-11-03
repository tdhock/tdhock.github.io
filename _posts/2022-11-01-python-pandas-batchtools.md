---
layout: post
title: Submitting python jobs on monsoon
description: And anaconda setup
---

My university provides the Monsoon computer cluster to researchers who
need lots of parallel computation. It is useful for machine learning,
where we often want to compare lots of different algorithms, data
sets, hyper-parameters, train set sizes, etc. This tutorial shows you
how to use monsoon to run python code in parallel on different cluster
nodes.

## Login to monsoon

Login to the cluster using your NAU user ID and password,

```shell
th798@cmp2986 ~
$ DISPLAY=:0.0 ssh -Y monsoon.hpc.nau.edu
th798@monsoon.hpc.nau.edu's password:
Last login: Wed Oct 26 14:52:23 2022 from 134.114.109.172

################################################################################
#
# Welcome to Monsoon - login node: [wind]
#
# Red Hat Enterprise Linux release 8.6 (Ootpa) - Kernel: 4.18.0-372.19.1.el8_6.x86_64
# slurm 21.08.8-2
#
# You are logged in as th798
#
# Information:
# - Monsoon now running Enterprise Linux 8
# - /scratch : files auto DELETED after 30 days
#
# Issues or questions: ask-arc@nau.edu
#
# Upcoming maintenance on:
# - TBD
#
# Random tip:
#   "sinfo -l -N" -- Get more info on node details and features
#
################################################################################

(emacs1) th798@wind:~$ 
```

The prompt above indicates I am on the login node, wind. The first
thing you should do is ask for a compute node, so you can run/test
your code without over-loading the login node.


```shell
(emacs1) th798@wind:~$ srun -t 24:00:00 --mem=8GB --cpus-per-task=1 --pty bash
srun: job 55316872 queued and waiting for resources
srun: job 55316872 has been allocated resources
(emacs1) th798@cn68:~$
```

The prompt above indicates I am on a compute node, cn68.  It also
shows my active conda environment (emacs1).

## Aside: conda setup

If you do not have a conda prompt, you need to do the following to get
one:

```shell
[th798@cn64 ~ ]$ module load anaconda3
[th798@cn64 ~ ]$ conda init
no change     /packages/anaconda3/2022.05/condabin/conda
no change     /packages/anaconda3/2022.05/bin/conda
no change     /packages/anaconda3/2022.05/bin/conda-env
no change     /packages/anaconda3/2022.05/bin/activate
no change     /packages/anaconda3/2022.05/bin/deactivate
no change     /packages/anaconda3/2022.05/etc/profile.d/conda.sh
no change     /packages/anaconda3/2022.05/etc/fish/conf.d/conda.fish
no change     /packages/anaconda3/2022.05/shell/condabin/Conda.psm1
no change     /packages/anaconda3/2022.05/shell/condabin/conda-hook.ps1
no change     /packages/anaconda3/2022.05/lib/python3.9/site-packages/xontrib/conda.xsh
no change     /packages/anaconda3/2022.05/etc/profile.d/conda.csh
modified      /home/th798/.bashrc

==> For changes to take effect, close and re-open your current shell. <==

[th798@cn64 ~ ]$ bash
(base) [th798@cn64 ~ ]$
```

The output above indicates the (base) conda environment is activated.
To create a new environment use

```shell
(base) [th798@cn64 ~ ]$ conda create -n myenv
Collecting package metadata (current_repodata.json): done
Solving environment: done

==> WARNING: A newer version of conda exists. <==
  current version: 4.12.0
  latest version: 22.9.0

Please update conda by running

    $ conda update -n base -c defaults conda

## Package Plan ##

  environment location: /home/th798/.conda/envs/myenv

Proceed ([y]/n)?
```

As above, it will ask if you want to proceed with the
installation. Hit enter to proceed. After that you can activate your
new environment:


```shell
(base) [th798@cn64 ~ ]$ which python
/packages/anaconda3/2022.05/bin/python
(base) [th798@cn64 ~ ]$ conda activate myenv
(myenv) [th798@cn64 ~ ]$ which python
/packages/anaconda3/2022.05/bin/python
(myenv) [th798@cn64 ~ ]$ python --version
Python 3.9.12
```

By default the new conda environment does not have any special
software -- the output above indicates the python 3.9 interpreter in
the base environment is used. To install a different python and some
other non-default packages, you can use something like

```shell
(myenv) [th798@cn64 ~ ]$ conda install python=3.10 pandas
Collecting package metadata (current_repodata.json): done
Solving environment: done


==> WARNING: A newer version of conda exists. <==
  current version: 4.12.0
  latest version: 22.9.0

Please update conda by running

    $ conda update -n base -c defaults conda



## Package Plan ##

  environment location: /home/th798/.conda/envs/myenv

  added / updated specs:
    - pandas
    - python=3.10


The following packages will be downloaded:

    package                    |            build
    ---------------------------|-----------------
    bottleneck-1.3.5           |  py310ha9d4c09_0         274 KB
    ca-certificates-2022.10.11 |       h06a4308_0         124 KB
    certifi-2022.9.24          |  py310h06a4308_0         154 KB
    ld_impl_linux-64-2.38      |       h1181459_1         654 KB
    libstdcxx-ng-11.2.0        |       h1234567_1         4.7 MB
    mkl-service-2.4.0          |  py310h7f8727e_0         177 KB
    mkl_fft-1.3.1              |  py310hd6ae3a3_0         567 KB
    mkl_random-1.2.2           |  py310h00e6091_0        1009 KB
    ncurses-6.3                |       h5eee18b_3         781 KB
    numexpr-2.8.3              |  py310hcea2de6_0         321 KB
    numpy-1.23.3               |  py310hd5efca6_0          10 KB
    numpy-base-1.23.3          |  py310h8e6c178_0         5.6 MB
    openssl-1.1.1q             |       h7f8727e_0         2.5 MB
    pandas-1.4.4               |  py310h6a678d5_0        25.5 MB
    pip-22.2.2                 |  py310h06a4308_0         2.4 MB
    pyparsing-3.0.9            |  py310h06a4308_0         153 KB
    python-3.10.6              |       haa1d7c7_1        21.9 MB
    pytz-2022.1                |  py310h06a4308_0         196 KB
    readline-8.2               |       h5eee18b_0         357 KB
    setuptools-65.5.0          |  py310h06a4308_0         1.2 MB
    sqlite-3.39.3              |       h5082296_0         1.1 MB
    tk-8.6.12                  |       h1ccaba5_0         3.0 MB
    tzdata-2022f               |       h04d1e81_0         115 KB
    xz-5.2.6                   |       h5eee18b_0         394 KB
    zlib-1.2.13                |       h5eee18b_0         103 KB
    ------------------------------------------------------------
                                           Total:        73.1 MB

The following NEW packages will be INSTALLED:

  _libgcc_mutex      pkgs/main/linux-64::_libgcc_mutex-0.1-main
  _openmp_mutex      pkgs/main/linux-64::_openmp_mutex-5.1-1_gnu
  blas               pkgs/main/linux-64::blas-1.0-mkl
  bottleneck         pkgs/main/linux-64::bottleneck-1.3.5-py310ha9d4c09_0
  bzip2              pkgs/main/linux-64::bzip2-1.0.8-h7b6447c_0
  ca-certificates    pkgs/main/linux-64::ca-certificates-2022.10.11-h06a4308_0
  certifi            pkgs/main/linux-64::certifi-2022.9.24-py310h06a4308_0
  intel-openmp       pkgs/main/linux-64::intel-openmp-2021.4.0-h06a4308_3561
  ld_impl_linux-64   pkgs/main/linux-64::ld_impl_linux-64-2.38-h1181459_1
  libffi             pkgs/main/linux-64::libffi-3.3-he6710b0_2
  libgcc-ng          pkgs/main/linux-64::libgcc-ng-11.2.0-h1234567_1
  libgomp            pkgs/main/linux-64::libgomp-11.2.0-h1234567_1
  libstdcxx-ng       pkgs/main/linux-64::libstdcxx-ng-11.2.0-h1234567_1
  libuuid            pkgs/main/linux-64::libuuid-1.0.3-h7f8727e_2
  mkl                pkgs/main/linux-64::mkl-2021.4.0-h06a4308_640
  mkl-service        pkgs/main/linux-64::mkl-service-2.4.0-py310h7f8727e_0
  mkl_fft            pkgs/main/linux-64::mkl_fft-1.3.1-py310hd6ae3a3_0
  mkl_random         pkgs/main/linux-64::mkl_random-1.2.2-py310h00e6091_0
  ncurses            pkgs/main/linux-64::ncurses-6.3-h5eee18b_3
  numexpr            pkgs/main/linux-64::numexpr-2.8.3-py310hcea2de6_0
  numpy              pkgs/main/linux-64::numpy-1.23.3-py310hd5efca6_0
  numpy-base         pkgs/main/linux-64::numpy-base-1.23.3-py310h8e6c178_0
  openssl            pkgs/main/linux-64::openssl-1.1.1q-h7f8727e_0
  packaging          pkgs/main/noarch::packaging-21.3-pyhd3eb1b0_0
  pandas             pkgs/main/linux-64::pandas-1.4.4-py310h6a678d5_0
  pip                pkgs/main/linux-64::pip-22.2.2-py310h06a4308_0
  pyparsing          pkgs/main/linux-64::pyparsing-3.0.9-py310h06a4308_0
  python             pkgs/main/linux-64::python-3.10.6-haa1d7c7_1
  python-dateutil    pkgs/main/noarch::python-dateutil-2.8.2-pyhd3eb1b0_0
  pytz               pkgs/main/linux-64::pytz-2022.1-py310h06a4308_0
  readline           pkgs/main/linux-64::readline-8.2-h5eee18b_0
  setuptools         pkgs/main/linux-64::setuptools-65.5.0-py310h06a4308_0
  six                pkgs/main/noarch::six-1.16.0-pyhd3eb1b0_1
  sqlite             pkgs/main/linux-64::sqlite-3.39.3-h5082296_0
  tk                 pkgs/main/linux-64::tk-8.6.12-h1ccaba5_0
  tzdata             pkgs/main/noarch::tzdata-2022f-h04d1e81_0
  wheel              pkgs/main/noarch::wheel-0.37.1-pyhd3eb1b0_0
  xz                 pkgs/main/linux-64::xz-5.2.6-h5eee18b_0
  zlib               pkgs/main/linux-64::zlib-1.2.13-h5eee18b_0


Proceed ([y]/n)?


Downloading and Extracting Packages
libstdcxx-ng-11.2.0  | 4.7 MB    | ##################################### | 100%
pip-22.2.2           | 2.4 MB    | ##################################### | 100%
pyparsing-3.0.9      | 153 KB    | ##################################### | 100%
tzdata-2022f         | 115 KB    | ##################################### | 100%
numpy-base-1.23.3    | 5.6 MB    | ##################################### | 100%
pytz-2022.1          | 196 KB    | ##################################### | 100%
xz-5.2.6             | 394 KB    | ##################################### | 100%
openssl-1.1.1q       | 2.5 MB    | ##################################### | 100%
ld_impl_linux-64-2.3 | 654 KB    | ##################################### | 100%
sqlite-3.39.3        | 1.1 MB    | ##################################### | 100%
mkl-service-2.4.0    | 177 KB    | ##################################### | 100%
ncurses-6.3          | 781 KB    | ##################################### | 100%
python-3.10.6        | 21.9 MB   | ##################################### | 100%
mkl_fft-1.3.1        | 567 KB    | ##################################### | 100%
readline-8.2         | 357 KB    | ##################################### | 100%
pandas-1.4.4         | 25.5 MB   | ##################################### | 100%
zlib-1.2.13          | 103 KB    | ##################################### | 100%
bottleneck-1.3.5     | 274 KB    | ##################################### | 100%
setuptools-65.5.0    | 1.2 MB    | ##################################### | 100%
ca-certificates-2022 | 124 KB    | ##################################### | 100%
mkl_random-1.2.2     | 1009 KB   | ##################################### | 100%
numexpr-2.8.3        | 321 KB    | ##################################### | 100%
certifi-2022.9.24    | 154 KB    | ##################################### | 100%
numpy-1.23.3         | 10 KB     | ##################################### | 100%
tk-8.6.12            | 3.0 MB    | ##################################### | 100%
Preparing transaction: done
Verifying transaction: done
Executing transaction: done
(myenv) [th798@cn64 ~ ]$ python --version
Python 3.10.6
(myenv) [th798@cn64 ~ ]$ which python
~/.conda/envs/myenv/bin/python
(myenv) [th798@cn64 ~ ]$
```

The output above indicates that the newly installed python 3.10 in
myenv is now used. You can also see that conda installs everything
under your home directory, which has a relatively small quota:

```shell
(base) [th798@cn64 ~ ]$ du -ms .conda
1363    .conda
(base) [th798@cn64 ~ ]$ quota -s
Disk quotas for user th798 (uid 682419):
     Filesystem   space   quota   limit   grace   files   quota   limit   grace
minim.ib.nauhpc:/export/home
                  3983M  10000M  10100M           26358       0       0
(base) [th798@cn64 ~ ]$ getquotas
Filesystem            #Bytes  Quota   %    |  #Files  Quota  %
/home                 2620M   10000M  26%  |  -       -      -
/scratch              9.219M  13.97T  0%   |  344     2M     0%
/projects/genomic-ml  7.5T    10T     75%  |  97M     5.2G   2%
```

The output above indicates the conda directory takes up 1363 megabytes
of disk space, which is over 10% of the quota on home (10000M).  To
avoid disk quota errors, I recommend storing the `.conda` directory
under /projects, which has essentially unlimited storage. My project is
called genomic-ml, and you should ask me to add you to my group. After
that, you should have write access to /projects/genomic-ml, so create a
sub-directory with your username and move the `.conda` directory
there:

```shell
(base) [th798@cn64 ~ ]$ ls /projects/genomic-ml/krr387/
hello_world.py
(base) [th798@cn64 ~ ]$ mkdir /projects/genomic-ml/th798
(base) [th798@cn64 ~ ]$ mv .conda /projects/genomic-ml/th798
mv: preserving permissions for /projects/genomic-ml/th798/.conda/envs/myenv/lib/libiomp5.so: Operation not supported
...
(base) [th798@cn64 ~ ]$ ln -s /projects/genomic-ml/th798/.conda
(base) [th798@cn64 ~ ]$ ls -ld .conda
lrwxrwxrwx 1 th798 cluster 33 Nov  1 15:16 .conda -> /projects/genomic-ml/th798/.conda
```

The commands above also create a symlink from the `.conda` under
/projects, to the `.conda` under your home directory.

Finally I put `conda activate emacs1` as the last line in my `.bashrc`
file so that I do not have to activate it manually every time I use
the cluster.

## Write your scripts

I recommend writing three python scripts to use the cluster. 

* `params.py` creates parameter combinations CSV files.
* `run_one.py` runs the computation for one parameter combination.
* `analyze.py` combines the result from each parameter combination
  into a single data file or plot/figure.
  
Put them all in `/projects/genomic-ml/your_id/jobs/your_job_name`.

  
### Defining parameter combinations to run in parallel

The first one should be called `params.py` with something like the
following contents:

```python
from datetime import datetime
import pandas as pd
import numpy as np
import os
import shutil
exp_start = 1
exp_stop = 3
exp_by=0.5
exp_num = int((exp_stop-exp_start)/exp_by+1)
n_train_vec = np.logspace(exp_start, exp_stop, exp_num).astype(int)
params_dict =  {
    'data': ["spam","zip"],
    'n_train': n_train_vec,
}
params_df = pd.MultiIndex.from_product(
    params_dict.values(),
    names=params_dict.keys()
).to_frame().reset_index(drop=True)
n_tasks, ncol = params_df.shape
job_name = datetime.now().strftime("%Y-%m-%d_%H:%M:%S")
job_name = "python_cluster_demo"
job_dir = "/scratch/th798/"+job_name
results_dir = os.path.join(job_dir, "results")
os.system("mkdir -p "+results_dir)
params_csv = os.path.join(job_dir, "params.csv")
params_df.to_csv(params_csv,index=False)
run_one_contents = f"""#!/bin/bash
#SBATCH --array=0-{n_tasks-1}
#SBATCH --time=24:00:00
#SBATCH --mem=8GB
#SBATCH --cpus-per-task=1
#SBATCH --output={job_dir}/slurm-%A_%a.out
#SBATCH --error={job_dir}/slurm-%A_%a.out
#SBATCH --job-name={job_name}
cd {job_dir}
python run_one.py $SLURM_ARRAY_TASK_ID
"""
run_one_sh = os.path.join(job_dir, "run_one.sh")
with open(run_one_sh, "w") as run_one_f:
    run_one_f.write(run_one_contents)
run_one_py = os.path.join(job_dir, "run_one.py")
run_orig_py = "demo_run.py"
shutil.copyfile(run_orig_py, run_one_py)
orig_dir = os.path.dirname(run_orig_py)
orig_results = os.path.join(orig_dir, "results")
os.system("mkdir -p "+orig_results)
orig_csv = os.path.join(orig_dir, "params.csv")
params_df.to_csv(orig_csv,index=False)
msg=f"""created params CSV files and job scripts, test with
python {run_orig_py} 0
SLURM_ARRAY_TASK_ID=0 bash {run_one_sh}"""
print(msg)
```

Important points in the code above:

* `params_dict` defines the parameter values. Each parameter
  combination will be saved to a row in the `params.csv` files, then
  eventually run in parallel as a task in a job array.
* `job_name` should be set to a name or date which will be used for
  the directory under `/scratch/your_id`.
* `run_one_contents` should be a shell script with SBATCH headers that
  will be saved as `run_one.sh`, for testing via `bash` or running in
  parallel via `sbatch`.
* `run_orig_py` should be the path to the `run_one.py` python script
  which you want to run in parallel.
  
### Run one parameter combination
  
The `run_one.py` file should be something like below:

```python
import numpy as np
import pandas as pd
import sys, os
params_df = pd.read_csv("params.csv")
if len(sys.argv)==2:
    prog_name, task_str = sys.argv
    param_row = int(task_str)
else:
    print("len(sys.argv)=%d so trying first param"%len(sys.argv))
    param_row = 0
param_series = params_df.iloc[param_row,:]
param_dict = dict(param_series)
print("data=%(data)s, n_train=%(n_train)s"%param_dict)
out_file = f"results/{param_row}.csv"
out_dict = dict(param_dict)
out_dict["accuracy"] = np.random.uniform(size=10)
out_df = pd.DataFrame(out_dict)
out_df.to_csv(out_file,index=False)
```

Important points in the script above:

* It begins by reading `params.csv` from the working
  directory. Running `params.py` creates a `params.csv` file in both
  `/projects/genomic-ml/your_id/jobs/your_job_name` and
  `/scratch/your_id/your_job_name`.
* It reads the task id from the first command line argument (which is
  in turn taken from the `SLURM_ARRAY_TASK_ID` environment variable,
  set by sbatch during job arrays), and gets the parameters in that
  row.
* It writes a CSV `out_file` to the results directory.

Here is an example run.

```shell
(emacs1) th798@cn64:/projects/genomic-ml/danny_demo$ python demo_params.py
created params CSV files and job scripts, test with
python demo_run.py 0
SLURM_ARRAY_TASK_ID=0 bash /scratch/th798/python_cluster_demo/run_one.sh
```

That created the `params.csv` files. Now, before sending your jobs to
the cluster to run in parallel, you should first run one or two tests
interactively, to make sure your job scripts work as expected:

```shell
(emacs1) th798@cn64:/projects/genomic-ml/danny_demo$ python demo_run.py 0
data=spam, n_train=10
(emacs1) th798@cn64:/projects/genomic-ml/danny_demo$ python demo_run.py 1
data=spam, n_train=31
(emacs1) th798@cn64:/projects/genomic-ml/danny_demo$ head results/*
==> results/0.csv <==
data,n_train,accuracy
spam,10,0.19380098396317136
spam,10,0.15103648808160253
spam,10,0.2708364347057266
spam,10,0.06392744376778148
spam,10,0.5950303948769095
spam,10,0.964137509350703
spam,10,0.4254650094618341
spam,10,0.5100533066016443
spam,10,0.43787575270102863

==> results/1.csv <==
data,n_train,accuracy
spam,31,0.8111215329653155
spam,31,0.7421233374878483
spam,31,0.5136229920707922
spam,31,0.09897616883194194
spam,31,0.5588310648424377
spam,31,0.1815483077057971
spam,31,0.37959710095119825
spam,31,0.8775077528816725
spam,31,0.8024679503541767
```

The output above shows that the result files were correctly created
using the python script. Now we try the same using the shell script:

```shell
(emacs1) th798@cn64:/projects/genomic-ml/danny_demo$ SLURM_ARRAY_TASK_ID=0 bash /scratch/th798/python_cluster_demo/run_one.sh
data=spam, n_train=10
(emacs1) th798@cn64:/projects/genomic-ml/danny_demo$ SLURM_ARRAY_TASK_ID=5 bash /scratch/th798/python_cluster_demo/run_one.sh
data=zip, n_train=10
(emacs1) th798@cn64:/projects/genomic-ml/danny_demo$ head /scratch/th798/python_cluster_demo/results/*
==> /scratch/th798/python_cluster_demo/results/0.csv <==
data,n_train,accuracy
spam,10,0.08092739059510368
spam,10,0.015905700682324553
spam,10,0.9454032184509514
spam,10,0.8800981008839108
spam,10,0.21525163475095177
spam,10,0.6079585918424504
spam,10,0.3998709507864645
spam,10,0.6785904256631412
spam,10,0.8040576508342843

==> /scratch/th798/python_cluster_demo/results/5.csv <==
data,n_train,accuracy
zip,10,0.6589333815954588
zip,10,0.3159551472782026
zip,10,0.6728424807278107
zip,10,0.05146996394681247
zip,10,0.5860689711923894
zip,10,0.5276091214097611
zip,10,0.5239496465945707
zip,10,0.7951374105640484
zip,10,0.4303313319491068
```

Note that in this example we have a simple script which does not have
a long run time, so we can just run it interactively and wait for it
to finish. In general each parameter combination will probably take a
long time (that is why you are doing this computation in parallel on
the cluster, right?), so you may not want to wait for it to finish in
your interactive testing. But at least you should start it
interactively and wait to see if it is reading whatever necessary
files and maybe printing some expected output without error, and then
use Control-C to quit once you have seen that it is working as
expected.

The next step is to submit the jobs to the cluster:

```shell
(emacs1) th798@cn64:/projects/genomic-ml/danny_demo$ sbatch /scratch/th798/python_cluster_demo/run_one.sh
Submitted batch job 55370815
(emacs1) th798@cn64:/projects/genomic-ml/danny_demo$ squeue -u th798
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
        55370815_0      core python_c    th798  R       0:00      1 cn57
        55370815_1      core python_c    th798  R       0:00      1 cn54
        55370815_2      core python_c    th798  R       0:00      1 cn54
        55370815_3      core python_c    th798  R       0:00      1 cn52
        55370815_4      core python_c    th798  R       0:00      1 cn52
        55370815_5      core python_c    th798  R       0:00      1 cn51
        55370815_6      core python_c    th798  R       0:00      1 cn51
        55370815_7      core python_c    th798  R       0:00      1 cn50
        55370815_8      core python_c    th798  R       0:00      1 cn41
        55370815_9      core python_c    th798  R       0:00      1 cn41
          55317235      core     bash    th798  R   23:41:33      1 cn64
```

While the jobs are running, `squeue` should show output similar to the
above (ST=R means Status=Running for the job id that `sbatch`
submitted). Keep looking at `squeue` until you see output as below,
indicating that the jobs are finished


```shell
(emacs1) th798@cn64:/projects/genomic-ml/danny_demo$ squeue -u th798
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
          55317235      core     bash    th798  R   23:41:35      1 cn64
(emacs1) th798@cn64:/projects/genomic-ml/danny_demo$ squeue -j 55370815
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
(emacs1) th798@cn64:/projects/genomic-ml/danny_demo$ squeue -j 55370815 --states=all
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
        55370815_9      core python_c    th798 CD       0:01      1 cn41
        55370815_8      core python_c    th798 CD       0:01      1 cn41
        55370815_7      core python_c    th798 CD       0:01      1 cn50
        55370815_6      core python_c    th798 CD       0:01      1 cn51
        55370815_5      core python_c    th798 CD       0:01      1 cn51
        55370815_4      core python_c    th798 CD       0:01      1 cn52
        55370815_3      core python_c    th798 CD       0:01      1 cn52
        55370815_2      core python_c    th798 CD       0:01      1 cn54
        55370815_1      core python_c    th798 CD       0:01      1 cn54
        55370815_0      core python_c    th798 CD       0:01      1 cn57
```

You can see the stdout/stderr from each job by looking in the
corresponding log file:

```shell
(emacs1) th798@cn64:/projects/genomic-ml/danny_demo$ head /scratch/th798/python_cluster_demo/slurm-*.out
==> /scratch/th798/python_cluster_demo/slurm-55370815_0.out <==
slurmstepd: error: Unable to create TMPDIR [/tmp/th798/55317235]: No such file or directory
slurmstepd: error: Setting TMPDIR to /tmp
data=spam, n_train=10

...

==> /scratch/th798/python_cluster_demo/slurm-55370815_9.out <==
slurmstepd: error: Unable to create TMPDIR [/tmp/th798/55317235]: No such file or directory
slurmstepd: error: Setting TMPDIR to /tmp
data=zip, n_train=1000
```

You can see the output CSV in the results directory:

```shell
(emacs1) th798@cn64:/projects/genomic-ml/danny_demo$ head /scratch/th798/python_cluster_demo/results/*
==> /scratch/th798/python_cluster_demo/results/0.csv <==
data,n_train,accuracy
spam,10,0.5715544544385103
spam,10,0.17794869162835647
spam,10,0.6130404209279962
spam,10,0.6169945578485531
spam,10,0.20522827774361874
spam,10,0.6396524895897306
spam,10,0.004164873517831902
spam,10,0.9932723599106694
spam,10,0.6157234020120316

...

==> /scratch/th798/python_cluster_demo/results/9.csv <==
data,n_train,accuracy
zip,1000,0.18884081134327246
zip,1000,0.07068831055323843
zip,1000,0.5590348649735482
zip,1000,0.0942516748761798
zip,1000,0.20019945047534293
zip,1000,0.07460014482545552
zip,1000,0.10848588685545335
zip,1000,0.6800091969153506
zip,1000,0.7359981689910392
```

Because scratch files are deleted after 30 days, you should copy the
result files to your projects directory for long term storage,

```shell
(emacs1) th798@cn64:/projects/genomic-ml/danny_demo$ rsync -rv /scratch/th798/python_cluster_demo/results/ results/
sending incremental file list
0.csv
1.csv
2.csv
3.csv
4.csv
5.csv
6.csv
7.csv
8.csv
9.csv

sent 3,563 bytes  received 206 bytes  7,538.00 bytes/sec
total size is 2,989  speedup is 0.79
```

### Combine and analyze results

Finally, you should combine and analyze those CSV output files using a
third `analyze.py` script, something like below

```python
import pandas as pd
from glob import glob
out_df_list = []
for out_csv in glob("results/*.csv"):
    out_df_list.append(pd.read_csv(out_csv))
out_df = pd.concat(out_df_list)
print(out_df)
```

Running that script should give something like:

```shell
(emacs1) th798@wind:~/genomic-ml/danny_demo$ python demo_analyze.py
    data  n_train  accuracy
0   spam      100  0.810597
1   spam      100  0.113314
2   spam      100  0.118181
3   spam      100  0.192121
4   spam      100  0.567469
..   ...      ...       ...
5   spam       31  0.580285
6   spam       31  0.379325
7   spam       31  0.572077
8   spam       31  0.890156
9   spam       31  0.023703

[100 rows x 3 columns]
```

The output above shows the combined results of all ten jobs in a
single data frame.

## Conclusion

This concludes my tutorial on running Python scripts in parallel on
the Monsoon cluster. We have seen how to define parameter
combinations, how to interactively test before sending your job to the
cluster, how to send the shell script to the cluster using `sbatch`,
how to check if your jobs are still running, how to copy results from
`/scratch` to `/projects`, and finally how to combine and analyze
result files.
