---
layout: post
title: Generate publications page
description: Parsing bibtex and generating markdown
---

I have been updating my
[publications](https://tdhock.github.io/publications/) page by editing
markdown for several years. Today I updated my self-citation database,
[TDH-refs.bib](/assets/TDH-refs.bib), so that is is consistent with
that publications page. In this post we explore the extent to which it would be possible to generate the publications page, using the bib file as a source.



## Parse bib into R

Parsing bibtex files is easy using regex. In fact, that is one of the
examples on `?nc::capture_all_str`:


``` r
refs.bib <- "~/tdhock.github.io/assets/TDH-refs.bib"
refs.vec <- readLines(refs.bib)
at.lines <- grep("^@", refs.vec, value=TRUE)
str(at.lines)
```

```
##  chr [1:56] "@article{Bodine2024," "@article{tao2024reply," "@article{kaufman2024functional," ...
```

The output above shows that there are currently 56 lines that start
with `@` in the bib file. Below we use a regex to convert each item
into one row of a data table:


``` r
refs.dt <- nc::capture_all_str(
  refs.vec,
  "@",
  type="[^{]+", tolower,
  "[{]",
  ref="[^,]+",
  ",\n",
  fields="(?:.*\n)+?.*",
  "[}]\\s*(?:$|\n)")
str(refs.dt)
```

```
## Classes 'data.table' and 'data.frame':	56 obs. of  3 variables:
##  $ type  : chr  "article" "article" "article" "article" ...
##  $ ref   : chr  "Bodine2024" "tao2024reply" "kaufman2024functional" "harshe2023predicting" ...
##  $ fields: chr  "author = {Bodine, C. S. and Buscombe, D. and Hocking, T. D.},\ntitle = {Automated River Substrate Mapping From "| __truncated__ "  title={Reply to: Model uncertainty obscures major driver of soil carbon},\n  author={Tao, Feng and Houlton, B"| __truncated__ "  title={Functional Labeled Optimal Partitioning},\n  author={Kaufman, Jacob M and Stenberg, Alyssa J and Hocki"| __truncated__ "  author={Harshe, Karl and Williams, Jack R. and Hocking, Toby D. and Lerner, Zachary F.},\n  journal={IEEE Rob"| __truncated__ ...
##  - attr(*, ".internal.selfref")=<externalptr>
```

The output above shows that the bib file was converted to a table with 56 rows.

## Parsing fields 

First we look at the number of lines with an equals sign, each of which is probably a field.


``` r
eq.lines <- grep("=", refs.vec, value=TRUE)
str(eq.lines)
```

```
##  chr [1:415] "author = {Bodine, C. S. and Buscombe, D. and Hocking, T. D.}," ...
```

Above we see 390 fields.

Below we parse the `fields` column:


``` r
strip <- function(x)gsub("^\\s*|,\\s*$", "", gsub('[{}"]', "", x))
refs.fields <- refs.dt[, nc::capture_all_str(
  fields,
  "\\s*",
  variable="\\S+", tolower,
  "\\s*=",
  value=".*", strip),
  by=.(type, ref)]
refs.fields
```

```
##             type                        ref variable
##           <char>                     <char>   <char>
##   1:     article                 Bodine2024   author
##   2:     article                 Bodine2024    title
##   3:     article                 Bodine2024  journal
##   4:     article                 Bodine2024   volume
##   5:     article                 Bodine2024   number
##  ---                                                
## 411: unpublished hocking2015breakpointError     year
## 412: unpublished          venuto2014support    title
## 413: unpublished          venuto2014support   author
## 414: unpublished          venuto2014support     note
## 415: unpublished          venuto2014support     year
##                                                                           value
##                                                                          <char>
##   1:                          Bodine, C. S. and Buscombe, D. and Hocking, T. D.
##   2: Automated River Substrate Mapping From Sonar Imagery With Machine Learning
##   3:          Journal of Geophysical Research: Machine Learning and Computation
##   4:                                                                          1
##   5:                                                                          3
##  ---                                                                           
## 411:                                                                       2015
## 412:                                         Support vector comparison machines
## 413:             Venuto, D and Hocking, TD and Sphanurattana, L and Sugiyama, M
## 414:                                                   Preprint arXiv:1401.8008
## 415:                                                                       2014
```

Above we see 390 fields, consistent with the simpler `grep` parsing above.

## Verify clean

Normally there should not be any quotes or curly braces in fields:


``` r
cat(grep('[{}"]', refs.fields$value, value=TRUE), sep="\n\n")
```

## Formatting the parsed data

The publications page is organized as follows

* chronologically, newest on top.
* heading `###` for in progress, and each year.
* bullet `-` for each publication.

Each publication has 

* Names like Last1 F1, Last2 F2.
* Title then period.
* Venue/publisher.
* then links.

The links at the end are not stored in the bib file, so that is not
possible to output. (exercise for reader!)

But we can get the other info.

## Venues


``` r
library(data.table)
refs.wide <- dcast(refs.fields, type + ref ~ variable)
refs.wide[, .(
  type,
  year,
  journal=substr(journal,1,10),
  vol=volume, num=number,
  booktitle=substr(booktitle,1,10),
  note=substr(note,1,10),
  school=substr(school,1,10))]
```

```
##              type   year    journal    vol    num  booktitle       note     school
##            <char> <char>     <char> <char> <char>     <char>     <char>     <char>
##  1:       article   2021 Functional     35      4       <NA>       <NA>       <NA>
##  2:       article   2018 The Americ    103      4       <NA>       <NA>       <NA>
##  3:       article   2022 Journal of     31      4       <NA>       <NA>       <NA>
##  4:       article   2024 Journal of      1      3       <NA> e2024JH000       <NA>
##  5:       article   2022 ACM Trans.     29      2       <NA>       <NA>       <NA>
##  6:       article   2016 Clinical C     22     22       <NA>       <NA>       <NA>
##  7:       article   2021 Computers     130   <NA>       <NA>       <NA>       <NA>
##  8:       article   2023 Journal of     24     70       <NA>       <NA>       <NA>
##  9:       article   2013 BMC Bioinf     14    164       <NA>       <NA>       <NA>
## 10:       article   2014 Bioinforma     30     11       <NA>       <NA>       <NA>
## 11:       article   2016 Bioinforma     33      4       <NA>       <NA>       <NA>
## 12:       article   2020 Journal of     21     87       <NA>       <NA>       <NA>
## 13:       article   2021 The R Jour     13      1       <NA>       <NA>       <NA>
## 14:       article   2022 Journal of    101     10       <NA>       <NA>       <NA>
## 15:       article   2023 Computatio     38   <NA>       <NA>       <NA>       <NA>
## 16:       article   2019 Biostatist     21      4       <NA>       <NA>       <NA>
## 17:       article   2021 BMC Bioinf     22    323       <NA>       <NA>       <NA>
## 18:       article   2017 Statistics     27   <NA>       <NA>       <NA>       <NA>
## 19:       article   2019 The R Jour     11      2       <NA>       <NA>       <NA>
## 20:       article   2023 Journal of    106      6       <NA>       <NA>       <NA>
## 21:       article   2016   Leukemia     30      7       <NA>       <NA>       <NA>
## 22:       article   2019 Journal of     28      2       <NA>       <NA>       <NA>
## 23:       article   2014 Cancer Sci    105      7       <NA>       <NA>       <NA>
## 24:       article   2023     Nature    618   <NA>       <NA> DOI:10.103       <NA>
## 25:       article   2022 Journal of     31      2       <NA>       <NA>       <NA>
## 26:       article   2018 JNCI: Jour    110     10       <NA>       <NA>       <NA>
## 27:       article   2018 Scientific      5      1       <NA>       <NA>       <NA>
## 28:       article   2010   PLoS one      5      8       <NA>       <NA>       <NA>
## 29:       article   2023 IEEE Robot      8      8       <NA>       <NA>       <NA>
## 30:       article   2013 Journal of     54   <NA>       <NA>       <NA>       <NA>
## 31:       article   2024 Journal of   <NA>   <NA>       <NA>       <NA>       <NA>
## 32:       article   2022 Biology Me      7      1       <NA>       <NA>       <NA>
## 33:       article   2024     Nature    627   8002       <NA>       <NA>       <NA>
## 34:  incollection   2017       <NA>   <NA>   <NA> Advances i       <NA>       <NA>
## 35:  incollection   2022       <NA>   <NA>   <NA> Land Carbo       <NA>       <NA>
## 36: inproceedings   2020       <NA>   <NA>   <NA> 2020 54th        <NA>       <NA>
## 37: inproceedings   2020       <NA>   <NA>   <NA> 2020 42nd        <NA>       <NA>
## 38: inproceedings   2013       <NA>   <NA>   <NA> Proc. 30th       <NA>       <NA>
## 39: inproceedings   2015       <NA>   <NA>   <NA> Proc. 32nd       <NA>       <NA>
## 40: inproceedings   2020       <NA>     25   <NA> Proc. Paci       <NA>       <NA>
## 41: inproceedings   2021       <NA>   <NA>   <NA> 2021 IEEE        <NA>       <NA>
## 42: inproceedings   2023       <NA>   <NA>   <NA> 2023 Inter       <NA>       <NA>
## 43: inproceedings   2022       <NA>   <NA>   <NA> 2022 Fourt       <NA>       <NA>
## 44: inproceedings   2022       <NA>   <NA>   <NA> 2022 fourt       <NA>       <NA>
## 45: inproceedings   2011       <NA>   <NA>   <NA> 28th inter       <NA>       <NA>
## 46: inproceedings   2022       <NA>   <NA>   <NA> 2022 Fourt       <NA>       <NA>
## 47:     phdthesis   2012       <NA>   <NA>   <NA>       <NA>       <NA> Ecole norm
## 48:   unpublished   2023       <NA>   <NA>   <NA>       <NA> Preprint a       <NA>
## 49:   unpublished   2023       <NA>   <NA>   <NA>       <NA> Preprint e       <NA>
## 50:   unpublished   2024       <NA>   <NA>   <NA>       <NA> Preprint a       <NA>
## 51:   unpublished   2023       <NA>   <NA>   <NA>       <NA> Preprint a       <NA>
## 52:   unpublished   2016       <NA>   <NA>   <NA>       <NA> Online boo       <NA>
## 53:   unpublished   2017       <NA>   <NA>   <NA>       <NA> Tutorial a       <NA>
## 54:   unpublished   2015       <NA>   <NA>   <NA>       <NA> Preprint a       <NA>
## 55:   unpublished   2016       <NA>   <NA>   <NA>       <NA> Tutorial a       <NA>
## 56:   unpublished   2014       <NA>   <NA>   <NA>       <NA> Preprint a       <NA>
##              type   year    journal    vol    num  booktitle       note     school
```

As can be seen in the table above, we can use various fields to define the venue of publication:

* `article`: most journal articles have a `volume` and `number`. The only exception is a recently published article that has not yet been assigned a volume.
* `incollection` and `inproceedings`: can use `booktitle`.
* `unpublished`: can use `note`.
* `phdthesis`: can use `school`.

These rules are encoded below,


``` r
refs.wide[, venue := fcase(
  type=="article", paste0(
    journal, ifelse(
      is.na(volume),
      paste0(", DOI:", doi),
      paste0(
        " ",
        volume,
        ifelse(is.na(number), "", sprintf("(%s)", number))
      )
    )
  ),
  grepl("^in", type), booktitle,
  type=="phdthesis", school,
  type=="unpublished", note
)][, .(type, year, venue=substr(venue, nchar(venue)-30,nchar(venue)))]
```

```
##              type   year                           venue
##            <char> <char>                          <char>
##  1:       article   2021        Functional Ecology 35(4)
##  2:       article   2018 ournal of Human Genetics 103(4)
##  3:       article   2022  and Graphical Statistics 31(4)
##  4:       article   2024 e Learning and Computation 1(3)
##  5:       article   2022 s. Comput.-Hum. Interact. 29(2)
##  6:       article   2016 Clinical Cancer Research 22(22)
##  7:       article   2021 ers in Biology and Medicine 130
##  8:       article   2023 achine Learning Research 24(70)
##  9:       article   2013      BMC Bioinformatics 14(164)
## 10:       article   2014           Bioinformatics 30(11)
## 11:       article   2016            Bioinformatics 33(4)
## 12:       article   2020 achine Learning Research 21(87)
## 13:       article   2021             The R Journal 13(1)
## 14:       article   2022 of Statistical Software 101(10)
## 15:       article   2023     Computational Statistics 38
## 16:       article   2019             Biostatistics 21(4)
## 17:       article   2021      BMC Bioinformatics 22(323)
## 18:       article   2017     Statistics and Computing 27
## 19:       article   2019             The R Journal 11(2)
## 20:       article   2023  of Statistical Software 106(6)
## 21:       article   2016                  Leukemia 30(7)
## 22:       article   2019  and Graphical Statistics 28(2)
## 23:       article   2014               Cancer Sci 105(7)
## 24:       article   2023                      Nature 618
## 25:       article   2022  and Graphical Statistics 31(2)
## 26:       article   2018 tional Cancer Institute 110(10)
## 27:       article   2018            Scientific data 5(1)
## 28:       article   2010                   PLoS one 5(8)
## 29:       article   2023 ics and Automation Letters 8(8)
## 30:       article   2013 rnal of Statistical Software 54
## 31:       article   2024 I:10.1080/10618600.2023.2293216
## 32:       article   2022 logy Methods and Protocols 7(1)
## 33:       article   2024                Nature 627(8002)
## 34:  incollection   2017 formation Processing Systems 30
## 35:  incollection   2022 ion, and Ecological Forecasting
## 36: inproceedings   2020 Signals, Systems, and Computers
## 37: inproceedings   2020 dicine   Biology Society (EMBC)
## 38: inproceedings   2013                 Proc. 30th ICML
## 39: inproceedings   2015                 Proc. 32nd ICML
## 40: inproceedings   2020 cific Symposium on Biocomputing
## 41: inproceedings   2021 Reliability Engineering (ISSRE)
## 42: inproceedings   2023 Technology and Computing (IETC)
## 43: inproceedings   2022  Transdisciplinary AI (TransAI)
## 44: inproceedings   2022  transdisciplinary AI (TransAI)
## 45: inproceedings   2011  conference on machine learning
## 46: inproceedings   2022  Transdisciplinary AI (TransAI)
## 47:     phdthesis   2012 supérieure de Cachan-ENS Cachan
## 48:   unpublished   2023       Preprint arXiv:2309.15225
## 49:   unpublished   2023        Preprint eartharXiv:6448
## 50:   unpublished   2024       Preprint arXiv:2408.00856
## 51:   unpublished   2023       Preprint arXiv:2302.11062
## 52:   unpublished   2016 ine book with multiple chapters
## 53:   unpublished   2017 ernational useR 2017 conference
## 54:   unpublished   2015       Preprint arXiv:1509.00368
## 55:   unpublished   2016 ernational useR 2016 conference
## 56:   unpublished   2014        Preprint arXiv:1401.8008
##              type   year                           venue
```

## Authors

Author names come in two forms:

* Family, Given1 Given2
* Given1 Given2 Family


``` r
subject <- c("Toby Dylan Hocking", "Hocking, Toby Dylan")
alt.pattern <- nc::alternatives_with_shared_groups(
  family="[A-Z][^,]+",
  given="[^,]+",
  list("^", given, " ", family, "$"),
  list("^", family, ", ", given, "$"))
nc::capture_first_vec(subject, alt.pattern)
```

```
##         given  family
##        <char>  <char>
## 1: Toby Dylan Hocking
## 2: Toby Dylan Hocking
```

The pattern above matches either of the two forms.
Below we use it to match all of the data.


``` r
(authors <- refs.wide[, {
  complete <- strsplit(author, split=" and ")[[1]]
  data.table(complete, nc::capture_first_vec(
    complete,
    alt.pattern,
    nomatch.error=FALSE))
}, by=ref
][
, abbrev := gsub("[a-z. ]", "", given)
][
, show := ifelse(is.na(family), complete, paste(family, abbrev))
][])
```

```
##                            ref             complete       given        family abbrev            show
##                         <char>               <char>      <char>        <char> <char>          <char>
##   1:               Abraham2021   Abraham, Andrew J.   Andrew J.       Abraham     AJ      Abraham AJ
##   2:               Abraham2021 Prys-Jones, Tomos O.    Tomos O.    Prys-Jones     TO   Prys-Jones TO
##   3:               Abraham2021  De Cuyper, Annelies    Annelies     De Cuyper      A     De Cuyper A
##   4:               Abraham2021      Ridenour, Chase       Chase      Ridenour      C      Ridenour C
##   5:               Abraham2021   Hempson, Gareth P.   Gareth P.       Hempson     GP      Hempson GP
##  ---                                                                                                
## 299: interactive-tutorial-2016 Ekstrøm, Claus Thorn Claus Thorn       Ekstrøm     CT      Ekstrøm CT
## 300:         venuto2014support            Venuto, D           D        Venuto      D        Venuto D
## 301:         venuto2014support          Hocking, TD          TD       Hocking     TD      Hocking TD
## 302:         venuto2014support     Sphanurattana, L           L Sphanurattana      L Sphanurattana L
## 303:         venuto2014support          Sugiyama, M           M      Sugiyama      M      Sugiyama M
```

The table above shows all names standardized to a common format in the `show` column.
Below we verify that all names matched.


``` r
authors[is.na(family)]
```

```
##                   ref complete  given family abbrev   show
##                <char>   <char> <char> <char> <char> <char>
## 1: depuydt2018genomic   others   <NA>   <NA>   <NA> others
## 2:       tao2024reply   others   <NA>   <NA>   <NA> others
```

The table above shows that the only names that did not match were "others" which is OK.


``` r
abbrev.dt <- authors[, .(
  authors_abbrev=paste(show, collapse=", ")
), by=ref]
abbrev.dt[, .(ref, authors_abbrev=substr(authors_abbrev,1,30))]
```

```
##                                               ref                 authors_abbrev
##                                            <char>                         <char>
##  1:                                   Abraham2021 Abraham AJ, Prys-Jones TO, De 
##  2:                                 Alirezaie2018 Alirezaie N, Kernohan KD, Hart
##  3:                               Barnwal2022jcgs    Barnwal A, Cho H, Hocking T
##  4:                                    Bodine2024 Bodine CS, Buscombe D, Hocking
##  5:                                    Chaves2022 Chaves AP, Egbert J, Hocking T
##  6:                                   Chicard2016 Chicard M, Boyault S, Colmet D
##  7:                    FOTOOHINASAB2021CompBioMed Fotoohinasab A, Hocking T, Afg
##  8:                                   Hillman2023          Hillman J, Hocking TD
##  9:                     Hocking2013bioinformatics Hocking TD, Schleiermacher G, 
## 10:                                   Hocking2014 Hocking TD, Boeva V, Rigaill G
## 11:                            Hocking2017bioinfo Hocking TD, Goerner-Potvin P, 
## 12:                               Hocking2020jmlr Hocking TD, Rigaill G, Fearnhe
## 13:                           Hocking2021RJournal                     Hocking TD
## 14:                                Hocking2022jss Hocking TD, Rigaill G, Fearnhe
## 15:                            Hocking2023-LOPART       Hocking TD, Srivastava A
## 16:                                    Jewell2019 Jewell SW, Hocking TD, Fearnhe
## 17:                          Liehrmann2021chipseq Liehrmann A, Rigaill G, Hockin
## 18:                                 Maidstone2017 Maidstone R, Hocking T, Rigail
## 19:                                   RJ-2019-050                     Hocking TD
## 20:                                     Runge2023 Runge V, Hocking TD, Romano G,
## 21:                                   Shimada2016 Shimada K, Shimada S, Sugimoto
## 22:                                   Sievert2019 Sievert C, VanderPlas S, Cai J
## 23:                                    Suguro2014 Suguro M, Yoshida N, Umino A, 
## 24:                                       Tao2023 Tao F, Huang Y, Hungate BA, Ma
## 25:                                 Vargovich2022        Vargovich J, Hocking TD
## 26:                            depuydt2018genomic Depuydt P, Boeva V, Hocking TD
## 27:                               depuydt2018meta Depuydt P, Koster J, Boeva V, 
## 28:                           gautier2010bayesian Gautier M, Hocking TD, Foulley
## 29:                          harshe2023predicting Harshe K, Williams JR, Hocking
## 30:                        hocking2013sustainable Hocking TD, Wutzler T, Ponting
## 31:                         kaufman2024functional Kaufman JM, Stenberg AJ, Hocki
## 32:                      mihaljevic2022sparsemodr Mihaljevic JR, Borkovec S, Rat
## 33:                                  tao2024reply Tao F, Houlton BZ, Frey SD, Le
## 34:                                    Drouin2017 Drouin A, Hocking T, Laviolett
## 35:                                hocking22intro                     Hocking TD
## 36: Fotoohinasab2020automaticQRSdetectionAsilomar Fotoohinasab A, Hocking T, Afg
## 37:              Fotoohinasab2020segmentationEMBC Fotoohinasab A, Hocking T, Afg
## 38:                               Hocking2013icml Rigaill G, Hocking T, Vert J-P
## 39:                                   Hocking2015 Hocking TD, Rigaill G, Bourque
## 40:                                Hocking2020psb          Hocking TD, Bourque G
## 41:                                     Kolla2021  Kolla AC, Groce A, Hocking TD
## 42:                                   Sweeney2023 Sweeney N, Xu C, Shaw JA, Hock
## 43:                           barr2022classifying Barr JR, Hocking TD, Morton G,
## 44:                                 barr2022graph Barr JR, Shaw P, Abu-Khzam FN,
## 45:                        hocking2011clusterpath Hocking TD, Joulin A, Bach F, 
## 46:                      hocking2022interpretable Hocking TD, Barr JR, Thatcher 
## 47:                           hocking2012learning                     Hocking TD
## 48:                                  Agyapong2023 Agyapong D, Propster JR, Marks
## 49:                                    Bodine2023 Bodine CS, Buscombe D, Hocking
## 50:                                    Nguyen2024           Nguyen T, Hocking TD
## 51:              Rust2023-all-pairs-squared-hinge            Rust KR, Hocking TD
## 52:                          animint2-manual-2016                     Hocking TD
## 53:                          change-tutorial-2017          Hocking TD, Killick R
## 54:                    hocking2015breakpointError                     Hocking TD
## 55:                     interactive-tutorial-2016         Hocking TD, Ekstrøm CT
## 56:                             venuto2014support Venuto D, Hocking TD, Sphanura
##                                               ref                 authors_abbrev
```

The output above shows the abbreviated author list is reasonable.

## Output markdown

The code below joins the authors back to the original table, then outputs markdown.


``` r
abbrev.wide <- refs.wide[
  abbrev.dt, on="ref"
][, let(
  heading = ifelse(type=="unpublished", "In Progress", year),
  citation = sprintf("- %s (%s). %s. %s.", authors_abbrev, year, title, venue)
)][order(-heading, -year, authors_abbrev)]
abbrev.some <- abbrev.wide[unique(heading)[1:3], .SD[1:2], on="heading", by=heading]
abbrev.some[
, .(markdown=sprintf("### %s\n%s\n", heading, paste(citation, collapse="\n")))
, by=heading
][
, cat(paste(markdown, collapse="\n"))
]
```

### In Progress
- Nguyen T, Hocking TD (2024). Deep Learning Approach for Changepoint Detection: Penalty Parameter Optimization. Preprint arXiv:2408.00856.
- Agyapong D, Propster JR, Marks J, Hocking TD (2023). Cross-Validation for Training and Testing Co-occurrence Network Inference Algorithms. Preprint arXiv:2309.15225.

### 2024
- Bodine CS, Buscombe D, Hocking TD (2024). Automated River Substrate Mapping From Sonar Imagery With Machine Learning. Journal of Geophysical Research: Machine Learning and Computation 1(3).
- Kaufman JM, Stenberg AJ, Hocking TD (2024). Functional Labeled Optimal Partitioning. Journal of Computational and Graphical Statistics, DOI:10.1080/10618600.2023.2293216.

### 2023
- Harshe K, Williams JR, Hocking TD, Lerner ZF (2023). Predicting Neuromuscular Engagement to Improve Gait Training With a Robotic Ankle Exoskeleton. IEEE Robotics and Automation Letters 8(8).
- Hillman J, Hocking TD (2023). Optimizing ROC Curves with a Sort-Based Surrogate Loss for Binary Classification and Changepoint Detection. Journal of Machine Learning Research 24(70).
NULL

## Another output

One advantage of this is that we can easily modify output formats.

| year | authors | title | venue |
|------|---------|-------|-------|
|      |         |       |       |


``` r
some.out <- abbrev.some[, .(published=heading, authors_abbrev, title, venue)]
knitr::kable(some.out)
```



|published   |authors_abbrev                               |title                                                                                                      |venue                                                                                |
|:-----------|:--------------------------------------------|:----------------------------------------------------------------------------------------------------------|:------------------------------------------------------------------------------------|
|In Progress |Nguyen T, Hocking TD                         |Deep Learning Approach for Changepoint Detection: Penalty Parameter Optimization                           |Preprint arXiv:2408.00856                                                            |
|In Progress |Agyapong D, Propster JR, Marks J, Hocking TD |Cross-Validation for Training and Testing Co-occurrence Network Inference Algorithms                       |Preprint arXiv:2309.15225                                                            |
|2024        |Bodine CS, Buscombe D, Hocking TD            |Automated River Substrate Mapping From Sonar Imagery With Machine Learning                                 |Journal of Geophysical Research: Machine Learning and Computation 1(3)               |
|2024        |Kaufman JM, Stenberg AJ, Hocking TD          |Functional Labeled Optimal Partitioning                                                                    |Journal of Computational and Graphical Statistics, DOI:10.1080/10618600.2023.2293216 |
|2023        |Harshe K, Williams JR, Hocking TD, Lerner ZF |Predicting Neuromuscular Engagement to Improve Gait Training With a Robotic Ankle Exoskeleton              |IEEE Robotics and Automation Letters 8(8)                                            |
|2023        |Hillman J, Hocking TD                        |Optimizing ROC Curves with a Sort-Based Surrogate Loss for Binary Classification and Changepoint Detection |Journal of Machine Learning Research 24(70)                                          |
