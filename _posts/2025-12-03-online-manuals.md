---
layout: post
title: Software for creating online manuals
description: Or “books”
---

Recently I ported my online manual for `animint2` from:

* `Rmd` source files on GitHub
* converted to `HTML` files on my computer
* using `jekyll`, `library(rmarkdown)`, and an old version of `library(bookdown)`
* deployed to `rcdata.nau.edu` using `rsync -r`

to:

* `qmd` source files on GitHub
* converted to `HTML` on GitHub Actions
* using `quarto`
* deployed to `netlify`

This is documented in [my French `animint2` slides](https://docs.google.com/presentation/d/1WpRZs9qz9wm1yik_MLj8tIJyWuL5-IBPYKLhOHZ9X4Y/edit?slide=id.g381cb582a55_0_0#slide=id.g381cb582a55_0_0).

A major advantage of this setup is the netlify deployment, which creates a preview web site for every pull request! (separate from the main deployment)

Alternatives to quarto include [Jupyter Book](https://jupyterbook.org/stable/), [GitBook](https://www.gitbook.com/solutions/public-docs) and [mdBook](https://rust-lang.github.io/mdBook/continuous-integration.html).

`Jupyter Book` version 2 is based on [MyST](https://mystmd.org/), [supports math](https://jupyterbook.org/stable/authoring/math/), and [executable code chunks](https://jupyterbook.org/stable/execution/execution/) (python or R). Demo includes figure output, so this seems to be most similar to `quarto`.

`mdBook` is based on `rust` and was used to create [this online physics-based simulation manual](https://phys-sim-book.github.io/). It supports [executable rust code blocks](https://rust-lang.github.io/mdBook/format/mdbook.html#rust-playground), but I do not see any other languages mentioned (R and python support missing).

`GitBook` also [supports pull request preview](https://gitbook.com/docs/getting-started/git-sync/github-pull-request-preview), and [code syntax highlighting](https://gitbook.com/docs/creating-content/formatting/markdown#code-blocks), but I do not see any mention of code chunk execution, although [variables](https://gitbook.com/docs/creating-content/variables-and-expressions) seem to be similar.
