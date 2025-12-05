---
layout: post
title: Research student application
description: Please read if you want to do research under my supervision
---

To work in the LASSO lab, please write an application (1-3 pages), with section headings corresponding to the sections below.
Ideally, please typeset your response using LaTeX and/or Overleaf, and include a bibliography with at least one citation to the paper you read.
So I can evaluate your coding and English writing abilities, please do not use AI tools (ChatGPT, Copilot, etc) when writing your application.

## Mentorship plan reading and writing application

Please read [my mentorship
plan](https://tdhock.github.io/blog/2022/research-mentorship-plan/),
which will help you understand what I expect of my research students.
In the first section of your application, please write a summary of
your understanding of my mentorship plan (in your own words, do not
copy word for word from my mentorship plan). Also write about what
kind of work/study style you have, and what frequency/kind of
interactions with me you expect to have.

## Code of conduct reading and writing application

Please read the LASSO lab [Code of
Conduct](https://tdhock.github.io/blog/2024/code-of-conduct/), which
is a set of rules designed to encourage diversity, equity, and
inclusion. In your application, please write a brief summary of your
understanding of the Code of Conduct. Do you agree to comply with the
Code of Conduct? Do you have any ideas for improving the Code of
Conduct?

## Technical reading and writing application

To work in the LASSO lab, it is important to be
able to read and understand machine learning research papers. It is
also important to have excellent written communication
skills. Therefore I need to judge your reading/writing skills and the
quality of your scientific comprehension/ideas. Please take some time
to choose [one of my
publications](https://tdhock.github.io/publications/) that is
interesting to you, and for which you think there would be an
interesting future research project/publication. Then write a summary,
in your own words (not copying from the publication), that contains

* Your motivation: why did you choose this paper?
* Background: what is the problem setting and data? For example, in regression the data is a n x p input/feature matrix, an n-vector of outputs/labels, problem is learning a function which takes a p-dimensional input/feature vector and returns a real-valued output/prediction.
* Previous work: what are the existing approaches for that problem, and what are their drawbacks that motivate a new algorithm? For example, in regression there are linear models, neural networks, boosting, etc.
* Novelty: what are the new ideas presented in the paper? Are they theoretical or empirical, or both? For example, the paper could use existing models/data and present a new proof about the optimality/speed of an existing algorithm, or it could use existing algorithms/data with a new neural network model architecture, or it could present new benchmark data sets for comparing various existing algorithms/models.
* Results: what comparisons were done to show that the new idea is interesting/useful in theory and/or in practice? For example, you could compare the test accuracy and computation time for different regression algorithms on various data sets.
* Future work: what are some of your ideas for new research papers that could be written as a follow up to this one? Justify why these ideas are sufficiently novel that they warrant a new paper describing them. Also describe what kinds of theoretical and empirical arguments you would need in that future paper. Please answer this point very specifically, because it will be helpful to define your first research project with me.

Make sure to use full sentences and paragraphs, and follow [Mark Schmidt's writing guidelines](https://www.cs.ubc.ca/~schmidtm/Courses/Notes/writing.pdf), so I can evaluate the quality of your English writing skills. For the bibliography:

* Avoid using `\cite{Bruynooghe2024}`
* Use `\usepackage{natbib}` in your LaTeX header, which defines the
  following commands.
* Use `\citet{Bruynooghe2024}` for "Author (year) proposed ..."
* Use `\citep{Bruynooghe2024}` for "The XYZ package does something
  (Author, year)."
* When you cite something, you should write one sentence that
  summarizes what it was about. For example this is pretty good:
  "Bruynooghe (2024) developed pytest-benchmark which integrates
  airspeed velocity benchmarking into pytest..." 

## Coding application

Writing code, and making figures, are important parts of machine
learning research. Please write a summary of one or two of your
previous projects, which answers the following questions.

* one project should involve substantial coding. Please do not include
  the code in your application, but please do include a link to your
  code (on GitHub etc). Please write about the primary challenge of
  the coding project, and what coding techniques you used. Are you
  proud of this coding project? What would you do differently next
  time you need to write code to solve a similar problem?
* one project should involve creating a figure using code. Please
  include a copy of the figure in your application, and a link to the
  code you used to make that figure. Please write about why you made
  the figure, and the main message you wanted to communicate with that
  figure. If you have not ever used code to make figures, please read
  Chapter 2 of the Animint2 Manual in
  [English](https://animint-manual-en.netlify.app)
  or
  [French](https://animint-manual-fr.netlify.app),
  and use one of the exercises to satisfy this application requirement. 
  Best would be to write a whole paragraph about your figure, like we do in research papers:
  * Setting: start by explaining what your goal is: what are you trying to understand by making a figure?
  * Hypothesis/expectation: before making the figure based on the real data, what did you expect to see in the figure, and how does that relate to your goal?
  * Interpretation: what can you actually see in your figure, and how does that relate to your goal? Is the result that you see based on the real data consistent with the hypothesis that you expected?
  * Conclusion: last sentence of paragraph should summarize what new understanding you have as a result of this figure

Updated 6 Aug 2024: added whole paragraph about your figure.

Updated 6 Sep 2024: added code of conduct.

Updated 19 Sept 2024: added natbib guidelines.

Updated 17 Oct 2024: one or two pages.

Updated 5 Dec 2025: one to three pages, your motivation, no AI tools, update animint2 link.
