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
- conda's focus is on packages for data science, whereas spack's focus
  is on HPC.
  
TODO: check to see if spack supports [these
packages](https://github.com/tdhock/data.table-revdeps#software-required)
that I had to build from source on Monsoon.
