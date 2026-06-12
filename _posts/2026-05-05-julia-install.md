---
layout: post
title: Installing Julia
description: and configuring emacs
---

JP Dussault’s instructions told me to go to <https://julialang.org/downloads/>

which is different from web search, first hit <https://docs.julialang.org/en/v1/manual/installation/>

Both sources tell me to install via

```
(base) hoct2726@dinf-thock-02i:~/R/R-4.5.3$ curl -fsSL https://install.julialang.org | sh

info: downloading installer
Welcome to Julia!

This will download and install the official Julia Language distribution
and its version manager Juliaup.

Juliaup will be installed into the Juliaup home directory, located at:

  /home/local/USHERBROOKE/hoct2726/.juliaup

The julia, juliaup and other commands will be added to
Juliaup's bin directory, located at:

  /home/local/USHERBROOKE/hoct2726/.juliaup/bin

This path will then be added to your PATH environment variable by
modifying the profile files located at:

  /home/local/USHERBROOKE/hoct2726/.bashrc
  /home/local/USHERBROOKE/hoct2726/.profile

Julia will look for a new version of Juliaup itself every 1440 minutes when you start julia.

You can uninstall at any time with juliaup self uninstall and these
changes will be reverted.

? Do you want to install with these default configuration choices? ›
❯ Proceed with installation
  Customize installation
  Cancel installation

✔ Do you want to install with these default configuration choices? · Proceed with installation

Now installing Juliaup
    Checking for new Julia versions
  Installing Julia 1.12.6+0.x64.linux.gnu
         Add Installed Julia channel 'release'
   Configure Default Julia version set to 'release'.
Julia was successfully installed on your system.

Depending on which shell you are using, run one of the following
commands to reload the PATH environment variable:

  . /home/local/USHERBROOKE/hoct2726/.bashrc
  . /home/local/USHERBROOKE/hoct2726/.profile
```

After that, like it says, I had to reload the shell to get it to work,

```
(base) hoct2726@dinf-thock-02i:~/R/R-4.5.3$ julia
julia: command not found
(base) hoct2726@dinf-thock-02i:~/R/R-4.5.3$ bash
IN BASHRC BEFORE CONDA INIT
(base) hoct2726@dinf-thock-02i:~/R/R-4.5.3$ julia
]0;Julia]0;Julia               _
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.12.6 (2026-04-09)
 _/ |\__'_|_|_|\__'_|  |  Official https://julialang.org release
|__/                   |

┌ Warning: Terminal not fully functional
└ @ Base client.jl:463
julia> 
```

Julia main page has a section, [Editors](https://julialang.org/#editors), with a link to [julia-mode on GitHub](https://github.com/JuliaEditorSupport/julia-emacs). It says that starting in emacs 29.1 (`C-h v emacs-version` says 29.3) I can add the code below to `~/emacs`

```elisp
(use-package julia-mode
  :ensure t)
```

`C-h f julia` says

```
julia is an alias for ‘run-ess-julia’ in ‘ess-julia.el’.

(julia &optional START-ARGS)

Start an inferior julia process.
```

so I guess [ess](https://ess.r-project.org/Manual/ess.html) is required too.
I tried `M-x julia` but that errors with:

```
make-process@with-editor-process-filter: Searching for program: No such file or directory, julia
```

I think emacs needs a restart.

After starting emacs from a shell in which julia is not on the path, I can get julia in `M-x shell` but not `M-x julia`.
`M-x getenv PATH` does not include `~/.juliaup`

My `~/.emacs` includes the following lines

```elisp
(setq inferior-R-program "/usr/bin/R")
(setq inferior-R-program "~/bin/R")
```

`C-h v inferior-julia-program` says

```
inferior-julia-program is a variable defined in ‘ess-custom.el’.

Its value is "julia"

Executable for Julia.
Should be an absolute path to the julia executable.
```

Close emacs, start shell with julia on path, start emacs. `M-x julia` works.

`C-x C-f ~/teaching/2026-05-nlopt` then `M-x julia` then

```
julia> include("instal.jl")
  Activating project at `~/teaching/2026-05-nlopt/Dev0/ROP631`
  Installing known registries into `~/.julia`
       Added `General` registry to ~/.julia/registries
    Updating registry at `~/.julia/registries/General.toml`
   Resolving package versions...
   Installed x265_jll ──────────────────── v4.1.0+0
   Installed Scratch ───────────────────── v1.3.0
…
   Resolving package versions...
     Project No packages added to or removed from `~/teaching/2026-05-nlopt/Dev0/ROP631/Project.toml`
    Manifest No packages added to or removed from `~/teaching/2026-05-nlopt/Dev0/ROP631/Manifest.toml`
```

Visit `file.jl` in emacs, `ESS[julia]` mode is activated:

* `C-RET` to send current line to julia REPL.
* `C-c C-c` to send current code block.

## packages

`instal.jl` contains

```
import Pkg
Pkg.activate("ROP631")

Pkg.add("NLPModels")
Pkg.add("JSOSolvers")
Pkg.add("Plots")
Pkg.add("ADNLPModels")
#Pkg.add("PyPlot")
Pkg.add("TaylorSeries")
```

`ROP631/Project.toml` contains

```
[deps]
ADNLPModels = "54578032-b7ea-4c30-94aa-7cbd1cce6c9a"
JSOSolvers = "10dff2fc-5484-5881-a0e0-c90441020f8a"
NLPModels = "a4795742-8479-5a88-8948-cc11e1c8c1a6"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PyPlot = "d330b81b-6aea-500a-939a-2ce795aea3ee"
TaylorSeries = "6aa5eb33-94cf-58f4-a9d0-e4b2c4fc25ea"

```

## windows

On windows, the [downloads page](https://julialang.org/downloads/) says to install Julia using either the MSIX App Installer (a student said they tried this and got a dll load error), or via the package manager,

```
winget install --name Julia --id 9NJNWW8PVKMN -e -s msstore
```

I got:

```
Windows PowerShell
Copyright (C) Microsoft Corporation. All rights reserved.

Install the latest PowerShell for new features and improvements! https://aka.ms/PSWindows

PS C:\Users\hoct2726> winget install --name Julia --id 9NJNWW8PVKMN -e -s msstore
Trouvé Julia [9NJNWW8PVKMN] Version Unknown
Ce package est fourni via Microsoft Store. Le winget devra peut-être acquérir le package à partir du Microsoft Store pour le compte de l’utilisateur actuel.
Contrats pour Julia [9NJNWW8PVKMN] Version Unknown
Version : Unknown
Publisher : JuliaHub, Inc.
ID de l’Editeur https://julialang.org/
URL de support de l’éditeur : mailto:contact@julialang.org
Licence : ms-windows-store://pdp/?ProductId=9NJNWW8PVKMN
URL de confidentialité : https://juliacomputing.com/privacy/
Contrats :
  Category: Developer tools
  Pricing: Free
  Free Trial: No
  Terms of Transaction: https://aka.ms/microsoft-store-terms-of-transaction
  Seizure Warning: https://aka.ms/microsoft-store-seizure-warning
  Store License Terms: https://aka.ms/microsoft-store-license

L’éditeur exige que vous consultiez les informations ci-dessus et acceptiez les contrats avant de procéder à l’installation.
Acceptez-vous les conditions ?
[Y] Oui  [N] Non:
[Y] Oui  [N] Non: Y
Démarrage du package d’installation... Merci de patienter.
  ██████████████████████████████  100%
Installé correctement
PS C:\Users\hoct2726> julia
    Checking for new Julia versions
  Installing Julia 1.12.6+0.x64.w64.mingw32
         Add Installed Julia channel 'release'
               _
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.12.6 (2026-04-09)
 _/ |\__'_|_|_|\__'_|  |  Official https://julialang.org release
|__/                   |

julia>
```
