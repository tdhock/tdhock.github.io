---
layout: post
title: Finding issues in bibtex
description: Parsing bibtex using regular expressions
---



Since writing
[Generate publications page](https://tdhock.github.io/blog/2024/auto-pubs-page/)
in 2024,
I have been updating my
[publications](https://tdhock.github.io/publications/) page by editing 
[TDH-refs.bib](/assets/TDH-refs.bib).
Now my university wants me to update [my entry in the Répertoire des Spécialistes](https://www.usherbrooke.ca/recherche/fr/specialistes/details/Toby.Dylan.Hocking), which pulls publications from [my ORCID works](https://orcid.org/0000-0002-3146-0865).
They have a bibtex import feature, but it gives error messages that are difficult to interpret.
For example, using [TDH-refs-old-sept-2026.bib](/assets/TDH-refs-old-sept-2026.bib) I get the error below:

```
This file cannot be read. Please check the BibTeX formatting and try again.
Value expected: single_value2023 } @article{Hillman2023jmlr, author = {Jonathan Hillman and Toby Dylan Hocking}, title = {Optimizing {ROC} Curves with a Sort-Based Surrogate Loss for Binary Classification and Changepoint Detection}, journal = {Journal of Machine Learning Research}, year = {2023}, volume = {24}, number = {70}, pages = {1--24}, links={[Publisher](https://jmlr.org/papers/v24/21-0751.html), [Preprint](https://arxiv.org/abs/2107.01285), [Software](https://github.com/tdhock/aum), [Reproducible](https://github.com/tdhock/max-generalized-auc), [Video](https://www.youtube.com/watch?v=GX6aqsi96IQ)}, url = {http://jmlr.org/papers/v24/21-0751.html} } @INPROCEEDINGS{Sweeney2023insect, author={Sweeney, Nathaniel and Xu, Caroline and Shaw, Joseph A. and Hocking, Toby D. and Whitaker, Bradley M.}, booktitle={2023 Intermountain Engineering, Technology and Computing (IETC)}, title={Insect Identification in Pulsed Lidar Images Using Changepoint Detection Algorithms}, year={2023}, pages={93-97}, links={[Publisher](https://ieeexplore.ieee.org/abstract/document/10152205)}, 
```

After deleting the links and trailing commas I get [TDH-refs-simplified-sept-2026.bib](/assets/TDH-refs-simplified-sept-2026.bib) with the error below:

```
This file cannot be read. Please check the BibTeX formatting and try again.
TypeError: Token mismatch: match
```

Neither error is helpful enough for me to figure out how to fix my bibtex input.
Below we use R to check the bib files.

## Parse bib into R

Parsing bibtex files is easy using regex. In fact, that is one of the
examples on `?nc::capture_all_str`:


``` r
refs.bib <- "~/tdhock.github.io/assets/TDH-refs-old-sept-2026.bib"
refs.vec <- readLines(refs.bib)
at.lines <- grep("^@", refs.vec, value=TRUE)
str(at.lines)
```

```
##  chr [1:76] "@unpublished{Agyapong2026poisson," "@unpublished{Agyapong2026fused," ...
```

The output above shows that there are 76 lines that start
with `@` in the bib file. Below we use a regex to convert each item
into one row of a data table:


``` r
options(datatable.prettyprint.char=15)
(refs.dt <- nc::capture_all_str(
  refs.vec,
  nc::before_match(
    "@",
    type="[^{]+", tolower,
    "[{]",
    ref="[^,]+",
    ",\n",
    fields="(?s).*?", function(x)gsub("\\{\\{", "\\{ \\{", x),
    "[}](?:$|\n *\n)")))
```

```
##                 before              match          type                ref               fields
##                 <char>             <char>        <char>             <char>               <char>
##  1:                    @unpublished{Ag...   unpublished Agyapong2026poi...     title={Unders...
##  2:                    @unpublished{Ag...   unpublished Agyapong2026fus...     title={Fused ...
##  3:                    @unpublished{Ng...   unpublished Nguyen2025compa...     title={ {Inte...
##  4:                    @unpublished{Ng...   unpublished Nguyen2025autom...     title={ {Pena...
##  5:                    @unpublished{Tr...   unpublished Truong2024circu...     title={Effici...
##  6:                    @unpublished{Ho...   unpublished Hocking2024mlr3...     title={ {mlr3...
##  7:                    @unpublished{Fo...   unpublished     Fowler2024line     title={Effici...
##  8:                    @unpublished{Ho...   unpublished Hocking2024bins...     title={ {Comp...
##  9:                    @unpublished{Ho...   unpublished     Hocking2024hmm     title={ {Teac...
## 10:                    @unpublished{Th...   unpublished Thibault2024for...     title={Spatia...
## 11:                    @unpublished{Li...   unpublished Lindly2026autis...     title={Predic...
## 12:                    @unpublished{Ho...   unpublished    Hocking2026down     title={ {Cros...
## 13:                    @unpublished{Ho...   unpublished Hocking2023func...     title={Why do...
## 14:                    @unpublished{Ru...   unpublished      Rust2023pairs     title={A Log-...
## 15:                    @unpublished{Ho...   unpublished Hocking2017chan...     title={Introd...
## 16:                    @unpublished{Ho...   unpublished Hocking2016inte...     title={Unders...
## 17:                    @unpublished{Ho...   unpublished Hocking2015brea...     title={A brea...
## 18:                    @unpublished{Ve...   unpublished Venuto2014suppo...     title={Suppor...
## 19: % Above in prog... @article{Hockin...       article Hocking2026fini...     title={ {Fini...
## 20:                    @article{Jorge2...       article Jorge2026hicrea...     title={ {hicr...
## 21:                    @article{Suther...       article Sutherland2026a...     title={ {Pedi...
## 22:                    @book{Hocking20...          book Hocking2026visu...     title={Visual...
## 23:                    @article{Amoako...       article Amoakohene2026a...     title={Asympt...
## 24:                    @article{Hockin...       article    Hocking2026soak     title={ {SOAK...
## 25:                    @inproceedings{... inproceedings Oliveira2025gov...     title={ {Gove...
## 26:                    @article{Nguyen...       article      Nguyen2025mlp     title={ {Pena...
## 27:                    @article{Agyapo...       article     Agyapong2025cv     title={Cross-...
## 28:                    @article{Gurney...       article    Gurney2024power     doi = {10.108...
## 29:                    @article{Bodine...       article Bodine2024mappi...   author = {Bodin...
## 30:                    @article{Tao202...       article       Tao2024reply     title={Reply ...
## 31:                    @article{Kaufma...       article Kaufman2024func...     title={ {Func...
## 32:                    @article{Harshe...       article Harshe2023exosk...     author={Harsh...
## 33:                    @article{Tao202...       article      Tao2023nature   author = {Feng ...
## 34:                    @article{Hillma...       article    Hillman2023jmlr     author  = {Jo...
## 35:                    @INPROCEEDINGS{... inproceedings Sweeney2023inse...     author={Sween...
## 36:                    @article{Runge2...       article       Runge2023jss    title={gfpop: ...
## 37:                    @article{Hockin...       article Hocking2023lopa... year = {2023}, \n...
## 38:                    @inproceedings{... inproceedings Barr2022classif...     title={Classi...
## 39:                    @inproceedings{... inproceedings Hocking2022inte...     title={Interp...
## 40:                    @inproceedings{... inproceedings      Barr2022graph     title={Graph ...
## 41:                    @article{Mihalj...       article Mihaljevic2022s...     title={SPARSE...
## 42:                    @InCollection{H...  incollection Hocking2022intr...     author =    {...
## 43:                    @article{Barnwa...       article    Barnwal2022jcgs   author = {Avina...
## 44:                    @article{Chaves...       article Chaves2022chatb...   author = {Chave...
## 45:                    @article{Hockin...       article     Hocking2022jss    title={General...
## 46:                    @article{Vargov...       article Vargovich2022br...   author = {Josep...
## 47:                    @INPROCEEDINGS{... inproceedings      Kolla2021fuzz     author={Kolla...
## 48:                    @article{Hockin...       article Hocking2021resh...     author = {Tob...
## 49:                    @article{Liehrm...       article Liehrmann2021ch...     title={Increa...
## 50:                    @article{Fotooh...       article Fotoohinasab202...   title = {A gree...
## 51:                    @article{Abraha...       article     Abraham2021gut   author = {Abrah...
## 52:                    @INPROCEEDINGS{... inproceedings Fotoohinasab202...     author={Fotoo...
## 53:                    @INPROCEEDINGS{... inproceedings Fotoohinasab202...     author={Fotoo...
## 54:                    @article{Hockin...       article    Hocking2020jmlr     author  = {To...
## 55:                    @inproceedings{... inproceedings     Hocking2020psb     title={ {Mach...
## 56:                    @article{Hockin...       article Hocking2019rege...     author = {Tob...
## 57:                    @article{Jewell...       article Jewell2019biost...       author = {J...
## 58:                    @article{Siever...       article    Sievert2019jcgs   author = {Carso...
## 59:                    @article{Depuyd...       article    Depuydt2018meta     title={Meta-m...
## 60:                    @article{Alirez...       article Alirezaie2018cl...   title = {ClinPr...
## 61:                    @article{Depuyd...       article Depuydt2018geno...     title={Genomi...
## 62:                    @inproceedings{... inproceedings     Drouin2017mmit   title = {Maximu...
## 63:                    @article{Hockin...       article Hocking2017bioi...       author = {H...
## 64:                    @Article{Maidst...       article Maidstone2017op...    author="Maidst...
## 65:                    @Article{Shimad...       article Shimada2016leuk...      Author="Shim...
## 66:                    @article{Chicar...       article Chicard2016canc...       author = {C...
## 67:                    @inproceedings{... inproceedings    Hocking2015icml     title={ {Peak...
## 68:                    @Article{Suguro...       article Suguro2014cance...      Author="Sugu...
## 69:                    @Article{Hockin...       article Hocking2014bioi...   author = \t {Ho...
## 70:                    @article{Hockin...       article Hocking2013sust...     title={Sustai...
## 71:                    @Article{Hockin...       article Hocking2013bioi...   author = \t {To...
## 72:                    @inproceedings{... inproceedings    Hocking2013icml     title={Learni...
## 73:                    @phdthesis{Hock...     phdthesis     Hocking2012phd     title={Learni...
## 74:                    @inproceedings{... inproceedings Hocking2011clus...     title={Cluste...
## 75:                    @article{Gautie...       article Gautier2010baye...     title={A Baye...
## 76:                    @article{Doyon2...       article Doyon2008herita...     title={Herita...
##                 before              match          type                ref               fields
##                 <char>             <char>        <char>             <char>               <char>
```

``` r
refs.dt[c(1,.N), fields]
```

```
## [1] "  title={Understanding When Poisson Log-Normal Models Outperform Penalized Poisson Regression for Microbiome Count Data},\n  note={Preprint arXiv:2509.09413, under review at Statistical Applications in Genetics and Molecular Biology},\n  author={Daniel Agyapong and Julien Chiquet and Jane Marks and Toby Dylan Hocking},\n  links={[Preprint](https://arxiv.org/abs/2604.03853), [Reproducible](https://github.com/EngineerDanny/pln_eval)},\n  year={2026}\n"                                                                                                                                         
## [2] "  title={Heritable targeted gene disruption in zebrafish using designed zinc-finger nucleases},\n  author={Doyon, Yannick and McCammon, Jasmine M and Miller, Jeffrey C and Faraji, Farhoud and Ngo, Catherine and Katibah, George E and Amora, Rainier and Hocking, Toby D and Zhang, Lei and Rebar, Edward J and Gregory, Philip D and Urnov, Fyodor D and Amacher, Sharon L},\n  journal={Nature biotechnology},\n  volume={26},\n  number={6},\n  pages={702--708},\n  year={2008},\n  links={[Pubmed](http://www.ncbi.nlm.nih.gov/pubmed/18500334)},\n  publisher={Nature Publishing Group US New York}\n"
```

The output above shows that the bib file was converted to a table with 76 rows.

## Check for fields too ling


``` r
refs.dt[grep("@", fields)]
```

```
## Empty data.table (0 rows and 5 cols): before,match,type,ref,fields
```

## Check for trailing commas


``` r
refs.dt[grep(",\\s*$", fields)]
```

```
##    before              match    type                ref               fields
##    <char>             <char>  <char>             <char>               <char>
## 1:        @article{Hockin... article Hocking2023lopa... year = {2023}, \n...
## 2:        @article{Fotooh... article Fotoohinasab202...   title = {A gree...
## 3:        @article{Alirez... article Alirezaie2018cl...   title = {ClinPr...
## 4:        @article{Hockin... article Hocking2017bioi...       author = {H...
```

## Parsing fields 

First we look at the number of lines with an equals sign, each of which is probably a field.


``` r
eq.lines <- grep("=", refs.vec, value=TRUE)
str(eq.lines)
```

```
##  chr [1:598] "  title={Understanding When Poisson Log-Normal Models Outperform Penalized Poisson Regression for Microbiome Count Data}," ...
```

Above we see 598 fields.

Below we parse the `fields` column:


``` r
strip <- function(x)gsub("^\\s*|,\\s*$", "", gsub('[{}"]', "", x))
field.pattern <- list(
  "\\s*",
  variable="[^= ]+", tolower,
  "\\s*=",
  value=".*", strip)
(refs.fields.before.match <- refs.dt[, nc::capture_all_str(
  fields, nc::before_match(field.pattern)),
  by=.(type, ref)])
```

```
##             type                ref before                match  variable              value
##           <char>             <char> <char>               <char>    <char>             <char>
##   1: unpublished Agyapong2026poi...            title={Unders...     title Understanding W...
##   2: unpublished Agyapong2026poi...        \n  note={Preprin...      note Preprint arXiv:...
##   3: unpublished Agyapong2026poi...        \n  author={Danie...    author Daniel Agyapong...
##   4: unpublished Agyapong2026poi...        \n  links={[Prepr...     links [Preprint](http...
##   5: unpublished Agyapong2026poi...             \n  year={2026}      year               2026
##  ---                                                                                        
## 663:     article Doyon2008herita...        \n  pages={702--7...     pages           702--708
## 664:     article Doyon2008herita...            \n  year={2008},      year               2008
## 665:     article Doyon2008herita...        \n  links={[Pubme...     links [Pubmed](http:/...
## 666:     article Doyon2008herita...        \n  publisher={Na... publisher Nature Publishi...
## 667:     article Doyon2008herita...     \n
```

The table above has extra rows with empty match, which we exclude below:


``` r
(refs.fields <- refs.fields.before.match[match!=""])
```

```
##             type                ref before                match  variable              value
##           <char>             <char> <char>               <char>    <char>             <char>
##   1: unpublished Agyapong2026poi...            title={Unders...     title Understanding W...
##   2: unpublished Agyapong2026poi...        \n  note={Preprin...      note Preprint arXiv:...
##   3: unpublished Agyapong2026poi...        \n  author={Danie...    author Daniel Agyapong...
##   4: unpublished Agyapong2026poi...        \n  links={[Prepr...     links [Preprint](http...
##   5: unpublished Agyapong2026poi...             \n  year={2026}      year               2026
##  ---                                                                                        
## 594:     article Doyon2008herita...             \n  number={6},    number                  6
## 595:     article Doyon2008herita...        \n  pages={702--7...     pages           702--708
## 596:     article Doyon2008herita...            \n  year={2008},      year               2008
## 597:     article Doyon2008herita...        \n  links={[Pubme...     links [Pubmed](http:/...
## 598:     article Doyon2008herita...        \n  publisher={Na... publisher Nature Publishi...
```

Above we see 598 fields, consistent with the simpler `grep` parsing above. 
If it is not consistent, we can use the code below to find out where:


``` r
(eq.dt <- nc::capture_first_vec(eq.lines, field.pattern))
```

```
##       variable              value
##         <char>             <char>
##   1:     title Understanding W...
##   2:      note Preprint arXiv:...
##   3:    author Daniel Agyapong...
##   4:     links [Preprint](http...
##   5:      year               2026
##  ---                             
## 594:    number                  6
## 595:     pages           702--708
## 596:      year               2008
## 597:     links [Pubmed](http:/...
## 598: publisher Nature Publishi...
```

``` r
eq.dt[!refs.fields, on=.(variable,value)]
```

```
## Empty data.table (0 rows and 2 cols): variable,value
```

``` r
eq.counts <- eq.dt[, .(eq.count=.N), by=.(variable,value)]
refs.fields[, .(ref.count=.N), by=.(variable,value)][eq.counts,on=.(variable,value)][eq.count!=ref.count]
```

```
## Empty data.table (0 rows and 4 cols): variable,value,ref.count,eq.count
```

## Verify clean

Normally there should not be any quotes or curly braces in fields:


``` r
cat(grep('[{}"]', refs.fields$value, value=TRUE), sep="\n\n")
```

## Conclusion

We have seen how to parse and check a bib file.

* `nc::before_match()` creates a pattern that parses an entire string into groups `before` and `match`.

## Session info


``` r
sessionInfo()
```

```
## R Under development (unstable) (2026-07-28 r90311)
## Platform: x86_64-pc-linux-gnu
## Running under: Ubuntu 24.04.5 LTS
## 
## Matrix products: default
## BLAS:   /usr/lib/x86_64-linux-gnu/blas/libblas.so.3.12.0 
## LAPACK: /usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.12.0  LAPACK version 3.12.0
## 
## locale:
##  [1] LC_CTYPE=en_US.UTF-8       LC_NUMERIC=C               LC_TIME=fr_FR.UTF-8        LC_COLLATE=en_US.UTF-8    
##  [5] LC_MONETARY=fr_FR.UTF-8    LC_MESSAGES=en_US.UTF-8    LC_PAPER=fr_FR.UTF-8       LC_NAME=C                 
##  [9] LC_ADDRESS=C               LC_TELEPHONE=C             LC_MEASUREMENT=fr_FR.UTF-8 LC_IDENTIFICATION=C       
## 
## time zone: America/Toronto
## tzcode source: system (glibc)
## 
## attached base packages:
## [1] stats     graphics  grDevices utils     datasets  methods   base     
## 
## loaded via a namespace (and not attached):
##  [1] compiler_4.7.0      nc_2026.4.20        cli_3.6.6           tools_4.7.0         otel_0.2.0         
##  [6] knitr_1.52          data.table_1.18.6.1 xfun_0.61           rlang_1.3.0         evaluate_1.0.5
```
