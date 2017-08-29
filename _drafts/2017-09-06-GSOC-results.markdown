This is a summary of R project in Google Summer of Code 2017.

We had 35 projects funded at the beginning of summer, and I mentored
three of these projects.

[Marlin Na](https://github.com/Marlin-Na) wrote the
[TnT](https://github.com/marlin-na/TnT) package for rendering
interactive genome browsers in R. This project was his idea, and he
was very self motivated. We did not have skype calls, but he provided
very detailed email updates all throughout GSOC. He plans to submit
the package to Bioconductor.

[Rover Van](https://github.com/RoverVan) implemented speed
optimizations for the [iregnet](https://github.com/anujkhare/iregnet)
package which implements a machine learning algorithm for regression
with censored outputs. His commits for GSOC2017 are summarized on
[PR59](https://github.com/anujkhare/iregnet/pull/59).

It was my second year working on the interactive grammar of graphics
with [Faizan Khan](https://github.com/faizan-khan-iit). His GSOC
project was a very ambitious rewrite of the original
[animint](https://github.com/tdhock/animint) package. This resulted in
[animint2](https://github.com/tdhock/animint2), which supports an
simpler syntax for defining interactivity using parameters rather than
aesthetics. It also has dropped the dependency on ggplot2; we now
instead use the
[ggplot2Animint](https://github.com/faizan-khan-iit/ggplot2) fork,
which will be more stable and easier to maintain (no need to provide
updates every time the ggplot2 developers make backwards incompatible
changes).
