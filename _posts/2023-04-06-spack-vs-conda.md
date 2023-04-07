---
layout: post
title: spack package manager
description: contrast with conda
---

On the NAU Monsoon super-computer, I have been using the user-space
[conda](https://conda.io/projects/conda/en/latest/user-guide/install/index.html)
data science package manager for a few years.  Today I heard there is
another user-space package manager,
[spack](https://spack-tutorial.readthedocs.io/en/latest/). What is the
difference?
- spack builds from source downloaded from github (slow), whereas
  conda downloads pre-built binaries (fast).
- conda's focus is on packages for data science (including on
  windows), whereas spack's focus is on HPC (no windows support).
  
I tried [Basic
installation](https://spack-tutorial.readthedocs.io/en/latest/tutorial_basics.html)
on cygwin and I got:

```
th798@cmp2986 ~/spack
$ . share/spack/setup-env.sh
-bash: $'\r': command not found
-bash: $'\r': command not found
-bash: $'\r': command not found
-bash: share/spack/setup-env.sh: line 49: syntax error near unexpected token `$'{\r''
'bash: share/spack/setup-env.sh: line 49: `_spack_shell_wrapper() {
```
  
Related: [Using Spack to Replace Homebrew/Conda](https://spack.readthedocs.io/en/latest/replace_conda_homebrew.html).
  
TODO: check to see if spack supports [these
packages](https://github.com/tdhock/data.table-revdeps#software-required)
that I had to build from source on Monsoon.
