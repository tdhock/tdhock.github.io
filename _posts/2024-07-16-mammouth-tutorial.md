---
layout: post
title: Mammouth tutorial
description: Cluster computing for students at UdeS
---

The goal of this post is to explain how to do parallel computations on
Mammouth, the UdeS super-computer.

To login to mammouth, you need an account with the Digital Research
Alliance of Canada. If you do not have one, then go to
[CCDB](https://ccdb.alliancecan.ca/security/login) and register. When
you register, make sure to indicate your PI/professor/boss as your
sponsor, so your compute time can be billed to their account. As a
part of registration, you need to setup two-factor authentication,
which probably means downloading the Duo Mobile app on your telephone.

Now on some cluster systems, you need to be physically at the
university, or on the VPN, but that is not the case for Mammouth. So
the next step is to just pull up a terminal and use ssh with your CCDB
user name (not your UdeS CIP), to host `mp2.calculcanada.ca` and make
sure to use the `-Y` flag if you want to use X forwarding.

```
(base) tdhock@maude-MacBookPro:~/tdhock.github.io(master)$ ssh -Y thocking@mp2.calculcanada.ca
Warning: Permanently added the ED25519 host key for IP address '204.19.23.216' to the list of known hosts.
Multifactor authentication is now mandatory to connect to this cluster.
You can enroll your account into multifactor authentication on this page:
https://ccdb.alliancecan.ca/multi_factor_authentications
by following the instructions available here:
https://docs.alliancecan.ca/wiki/Multifactor_authentication

=============================================================================

L'authentification multifacteur est maintenant obligatoire pour vous connecter
à cette grappe. Configurez votre compte sur
https://ccdb.alliancecan.ca/multi_factor_authentications
et suivez les directives dans
https://docs.alliancecan.ca/wiki/Multifactor_authentication/fr.

Password: 
```

After you put in the correct password, you get the prompt below, which
means you need to do two-factor authentication,

```
Duo two-factor login for thocking

Enter a passcode or select one of the following options:

 1. Duo Push to iphone (iOS)

Passcode or option (1-1): 
```

So at this point you can either 
* go into your telephone, Duo Mobile app, Digital Research Alliance of
  Canada, Show Passcode. You should get a six digit number that you
  can type at the prompt to login.
* or type 1 at the prompt, and then go into your Duo Mobile app, tap
  accept (green check mark).
  
Then we get the following prompt

```
Success. Logging you in...
Last failed login: Tue Jul 16 22:44:50 EDT 2024 from 70.81.139.71 on ssh:notty
There were 5 failed login attempts since the last successful login.
Last login: Tue Jun 25 13:30:36 2024 from 132.210.204.231
################################################################################
 __  __      ____  _     
|  \/  |_ __|___ \| |__   Bienvenue sur Mammouth-Mp2b / Welcome to Mammoth-Mp2b
| |\/| | '_ \ __) | '_ \ 
| |  | | |_) / __/| |_) | Aide/Support:    mammouth@calculcanada.ca
|_|  |_| .__/_____|_.__/  Globus endpoint: computecanada#mammouth
       |_|                Documentation:   docs.calculcanada.ca
                                           docs.calculcanada.ca/wiki/Mp2

Grappe avec le meme environnement d'utilisation que Cedar et Graham (Slurm scheduler).
Cluster with the same user environment as Cedar and Graham (Slurm scheduler).

________________________________________________________________________________
          |                               |   Slurm |   Slurm |   Slurm
 Mp2b 	  | Memory/Cores 	          | --nodes | --mem   | --cpus-per-task
 nodetype |                               |   max   |   max   |   max
----------+-------------------------------+---------+---------+-----------------
 base     |  31 GB memory, 24 cores/node  |   1588  |   31G   |   24  
 large    | 251 GB memory, 48 cores/node  |     20  |  251G   |   48
 xlarge   | 503 GB memory, 48 cores/node  |      2  |  503G   |   48
__________|_______________________________|_________|_________|_________________


2018-05-16	Slurm --mem option
15:19		==================

SVP specifier la memoire requise par noeud avec l'option --mem a la soumission de 
tache (256 Mo par coeur par defaut).  Maximum --mem=31G pour les noeuds de base.

Please specify the required memory by node with the --mem option at job 
submission (256 MB per core by default).  Maximum --mem=31G for base nodes.


2018-12-19     PAS de sauvegarde de fichiers sur scratch et project sur Mammouth
14:09          NO file backup on scratch and project on Mammoth
               =================================================================

Nous vous recommandons d'avoir une seconde copie de vos fichiers importants 
ailleurs par mesure de precaution.

We recommend that you have a second copy of your important files elsewhere as 
a precaution.


2024-06-04    Repertoire $SCRATCH non-disponible / $SCRATCH directory not available
11:58         =====================================================================

Problème materiel sur une des serveurs MDS de $SCRATCH.
Hardware issue with one of the MDS of $SCRATCH.
    
############################################################################### 
[thocking@ip15-mp2 ~]$ 
```

## emacs

For text editing, I recommend running emacs in either a terminal via
`emacs -nw` (nw means no window),

![emacs in a terminal](/assets/img/2024-07-16-mammouth-tutorial/emacs-terminal.png)

In the screenshot above, I ran `emacs -nw ~/bin/interactive-job.sh` in
the lower right terminal (black and green), which opens that shell
script for editing in emacs (running on mammouth). To suspend this
emacs running in the terminal, you can type Control-Z to get back to
the shell prompt, then you can use the `fg` command to get back to
emacs. Note that there is another emacs running on my local laptop
computer, in the upper left of the screen. 

On a fast internet connection, I prefer running emacs in an X11 window
(more convenient but maybe slower response times),

![emacs in X11](/assets/img/2024-07-16-mammouth-tutorial/emacs-x11.png)

In the screenshot above, I ran `emacs ~/bin/interactive-job.sh &` in
the terminal. The ampersand / and sign `&` means to run the command in
the background (do not wait for it to finish before giving the next
prompt), and then a new X11 window pops up running emacs. You can use
the window name (in emacs language, that is a frame title) to
differentiate the two emacs instances:

* `emacs@ip15.m (on ip15.m)` is on Mammouth.
* `emacs@maude-MacBookPro` is on my local laptop computer.

## Node types

[MP2 docs](https://docs.alliancecan.ca/wiki/Mp2/en) under
[Site-specific
policies](https://docs.alliancecan.ca/wiki/Mp2/en#Site-specific_policies)
says "Each job must have a duration of at least one hour (at least
five minutes for test jobs) and a user cannot have more than 1000 jobs
(running and queued) at any given time. The maximum duration of a job
is 168 hours (seven days)." and under [Node
characteristics](https://docs.alliancecan.ca/wiki/Mp2/en#Node_characteristics)
it says there are three node types.


## srun

TODO Interactive jobs

```
[thocking@ip15-mp2 ~]$ srun -t 4:00:00 --mem=31GB --cpus-per-task=1 --pty bash
srun: error: Unable to allocate resources: Requested time limit is invalid (missing or exceeds some limit)
```

