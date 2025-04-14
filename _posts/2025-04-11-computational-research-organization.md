---
layout: post
title: Organizing computational research projects
description: Guide for research students
---

This blog describes how I typically organize my computational research
projects and communications.

## Projects

First, I create a git repo for each project. 
Typically each repo will have several different code files.
What files should be added to the git repo?

- Code.
- Figures.
- Intermediate result data files (if they are not too large).

What files should be added to `.gitignore`, and not added to the git repo?

- Raw data files (typically too large).

Note that we do not want to put large files in a git repo, which is
designed for managing lots of small files (mostly code). Instead, put
your raw data files on a web hosting service, or a reproducibility
service (Zenodo/similar), and then write some code that downloads the
data files from that public source.

### Code to compute intermediate results

These code files compute some results and store them in intermediate
data files (CSV, RData, etc). 

- A typical name would be figure-something-data.R to indicate that
  this is the code file which creates the data for figure-something.
- The first thing to do would be check if the data file exists locally
  already, and if not, download it.
- Then read the data and compute some result (time-consuming).
- Then create a file named something.csv as output.

### Code to make figures

These code files make figures based on the intermediate data
files. It is important to separate these two steps, so that visual
properties in the figures can be quickly modified, without having to
re-compute the results (time-consuming).

- Typical name would be figure-something.R to indicate that this is
  the code file for making figure-something.
- output should typically be a PNG file with decent resolution (text
  is large enough to read, anddoes not look blurry when viewing figure
  in slides).
- to create a figure in R, use code like below:

```r
png("figure-something.png", height=5, width=3, units="in", res=200)
print(gg) #for ggplot gg, or other plotting code here.
dev.off()
```

Note in the code above that you typically have to modify the height
and width, but typically not the units and res.

### Overview files

There are three kinds of overview files that may be present.

- README.md or README.org should always be present, so readers on the
  github web site can understand your project.
- There may be project-slides.tex LaTeX beamer source code which can
  be compiled to a slides PDF (or at least include a link to your
  google slides).
- There may be project-paper.tex LaTeX article source code which can
  be compiled to a research paper PDF (or at least include a link to
  your overleaf).

For the README overview,
  
- The first line should include a short title and description of the project idea.
- If the paper is published, include a section at the top which
  describes which source code files were used to make Figure 1, Figure
  2, etc. (TODO add example, FLOPART paper?)
- After that you can have a section of TODOs / future work (or link to
  your issue tracker if you prefer).
- After that, there should be a chronological index of all code and
  result files.
- One section per day that you worked on the project (or result
  generated), with most recent day on the top (so no need to scroll
  all the way to the bottom to see most recent results).
- Each section should include a link to any relevant code, data, and
  figure files, along with your interpretation of any result figures
  or tables.

You may be tempted to keep adding more results and figure files in the
same repo. If there are enough figures in this repo to prove the
points that you want to make in your paper, then stop working in this
repo, and start a new repo for another paper.

## Minimal Reproducible Examples

When you do computational research, you will inevitably encounter
problems that prevent you from advancing / finishing your paper.
How do you get help, when you have an error/issue that is blocking you?
You should ask for help, but to do that, you should first create a
Minimal Reproducible Example (MRE) that that can be used to precisely
communicate your issue to someone else.

Typically the first reflex would be to send your whole git repo a
colleague/advisor, and ask them to run the same code that gave you the
error. That should be reproducible, but that would also probably be
too large/complex of an example for others (and you) to see where the
problem is. So you need to think about what is the central issue, and
see if you can get it to happen with a smaller data set. Ask yourself:
what data are not necessary? What is the smallest/simplest data set
that could be used to reproduce the issue?

- half the data?
- 2 rows?
- 1 row?

Keep going smaller until you can't any more! That is Minimal (necessary details only).
Try smaller column/variable names too.

At this point, you have probably figured out a solution to your
problem already, 90% of the time. The other 10% of the time, you should post an
issue:

- on your github repo, if you are not sure if it is your problem, or
  the problem with somebody else's code.
- on another github repo, if you are pretty sure that somebody else's
  code is responsible for the issue.
- @tag somebody who you think could understand & help you fix the
  issue (your mentor/advisor/collaborator, or maintainer of the
  software you are using).

## Writing issues

First of all, why do we write issues instead of emails?  Emails are
great for private communications.  But most research and open-source
projects should prefer issues because they are public, so others may
be able to benefit from what you learn at the end of your discussion.
Also, github issues provide code highlighting, which can be useful for
readers of your code.

If you are writing an issue on someone else's repo, begin by @tagging
a maintainer who seems to be recently active, and thank them for
maintaining the software that you are using. Free/open-source software
maintainers are often unpaid volunteers, who appreciate praise! From
the perspective of the maintainer, issues are like a TODO list that
somebody else writes for you. So when you write an issue on someone
else's repo, please be polite and thankful for their time.

Next, explain your goal in general terms (big picture). What were you
trying to compute when you ran into the issue?

Next, give details about what code you ran, inside a triple-backticks
block.

````
```r
my_data <- data.frame(x=1:2)
pkg::fun(my_data)
sessionInfo()
```
````

- include import in Python, or library/pkg::fun in R, so that others
  will be able to understand where to find the functions that you are
  using.
- Avoid reading external data (CSV) and instead include a data set by
  creating it in a code chunk. In R you can use `dput(obj)` to print
  out some code that will create `obj`.
- include the MRE you created using the approach in the previous
  section.
- end your code block with sessionInfo() 
  
After showing a block with just the code by itself, then show the
output of the code on your system. Use a fresh environment, which
means putting your code in `your_code.R` and then running something
like `R --vanilla < your_code.R` which will run your code without any
site or user specific configuration files, thanks to the `--vanilla`
option. Or in R you can try `reprex::reprex(your code)`.

Write what you expected the code to do, then write the result you
observed on your system.

Use a question mark to indicate that you would like a response. For
example, is this a bug? I expected that the function should work
without error, but I observed an error on my system. Do you think the
error is normal in this case?

Here are some examples of issues I have posted on other people's
repositories.

- https://github.com/mlr-org/mlr3torch/issues/373
- https://github.com/mlr-org/mlr3torch/issues/374
- https://github.com/r-lib/pak/issues/760
- https://github.com/r-lib/bench/issues/145
- https://github.com/pgadmin-org/pgadmin4/issues/8120
- https://github.com/therneau/survival/issues/270
