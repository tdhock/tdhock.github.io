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
```

```
## Warning in readLines(refs.bib): ligne finale incomplète trouvée dans '~/tdhock.github.io/assets/TDH-refs.bib'
```

``` r
at.lines <- grep("^@", refs.vec, value=TRUE)
str(at.lines)
```

```
##  chr [1:66] "@unpublished{Gurney2024power," "@unpublished{Nguyen2024penalty," "@unpublished{Truong2024circular," ...
```

The output above shows that there are currently 66 lines that start
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
## Classes 'data.table' and 'data.frame':	66 obs. of  3 variables:
##  $ type  : chr  "unpublished" "unpublished" "unpublished" "unpublished" ...
##  $ ref   : chr  "Gurney2024power" "Nguyen2024penalty" "Truong2024circular" "Hocking2024mlr3resampling" ...
##  $ fields: chr  "  title={Assessment of the Climate Trace global powerplant CO2 emissions},\n  author={Kevin Gurney and Bilal As"| __truncated__ "  title={Deep Learning Approach for Changepoint Detection: Penalty Parameter Optimization},\n  author={Nguyen, "| __truncated__ "  title={Efficient change-point detection for multivariate circular data},\n  author={Charles Truong and Toby D"| __truncated__ "  title={mlr3resampling: an R implementation of cross-validation for comparing models learned using different t"| __truncated__ ...
##  - attr(*, ".internal.selfref")=<externalptr>
```

The output above shows that the bib file was converted to a table with 66 rows.

## Parsing fields 

First we look at the number of lines with an equals sign, each of which is probably a field.


``` r
eq.lines <- grep("=", refs.vec, value=TRUE)
str(eq.lines)
```

```
##  chr [1:511] "  title={Assessment of the Climate Trace global powerplant CO2 emissions}," ...
```

Above we see 511 fields.

Below we parse the `fields` column:


``` r
strip <- function(x)gsub("^\\s*|,\\s*$", "", gsub('[{}"]', "", x))
field.pattern <- list(
  "\\s*",
  variable="[^= ]+", tolower,
  "\\s*=",
  value=".*", strip)  
(refs.fields <- refs.dt[, nc::capture_all_str(
  fields, field.pattern),
  by=.(type, ref)])
```

```
##             type                ref  variable
##           <char>             <char>    <char>
##   1: unpublished    Gurney2024power     title
##   2: unpublished    Gurney2024power    author
##   3: unpublished    Gurney2024power      note
##   4: unpublished    Gurney2024power      year
##   5: unpublished  Nguyen2024penalty     title
##  ---                                         
## 507:     article Doyon2008heritable    number
## 508:     article Doyon2008heritable     pages
## 509:     article Doyon2008heritable      year
## 510:     article Doyon2008heritable     links
## 511:     article Doyon2008heritable publisher
##                                                                                                                   value
##                                                                                                                  <char>
##   1:                                                    Assessment of the Climate Trace global powerplant CO2 emissions
##   2: Kevin Gurney and Bilal Aslam and Pawlok Dass and L Gawuc and Toby Dylan Hocking and Jarrett J Barber and Anna Kato
##   3:                                                                     Under review at Environmental Research Letters
##   4:                                                                                                               2024
##   5:                                   Deep Learning Approach for Changepoint Detection: Penalty Parameter Optimization
##  ---                                                                                                                   
## 507:                                                                                                                  6
## 508:                                                                                                           702--708
## 509:                                                                                                               2008
## 510:                                                              [Pubmed](http://www.ncbi.nlm.nih.gov/pubmed/18500334)
## 511:                                                                                Nature Publishing Group US New York
```

Above we see 511 fields, consistent with the simpler `grep` parsing above. 
If it is not consistent, we can use the code below to find out where:


``` r
(eq.dt <- nc::capture_first_vec(eq.lines, field.pattern))
```

```
##       variable
##         <char>
##   1:     title
##   2:    author
##   3:      note
##   4:      year
##   5:     title
##  ---          
## 507:    number
## 508:     pages
## 509:      year
## 510:     links
## 511: publisher
##                                                                                                                   value
##                                                                                                                  <char>
##   1:                                                    Assessment of the Climate Trace global powerplant CO2 emissions
##   2: Kevin Gurney and Bilal Aslam and Pawlok Dass and L Gawuc and Toby Dylan Hocking and Jarrett J Barber and Anna Kato
##   3:                                                                     Under review at Environmental Research Letters
##   4:                                                                                                               2024
##   5:                                   Deep Learning Approach for Changepoint Detection: Penalty Parameter Optimization
##  ---                                                                                                                   
## 507:                                                                                                                  6
## 508:                                                                                                           702--708
## 509:                                                                                                               2008
## 510:                                                              [Pubmed](http://www.ncbi.nlm.nih.gov/pubmed/18500334)
## 511:                                                                                Nature Publishing Group US New York
```

``` r
eq.dt[!refs.fields, on=.(variable,value)]
```

```
##    variable                     value
##      <char>                    <char>
## 1:      doi 10.1007/s11222-016-9636-3
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
##  7:       article   2018 JNCI: Jour    110     10       <NA>       <NA>       <NA>
##  8:       article   2018 Scientific      5      1       <NA>       <NA>       <NA>
##  9:       article   2008 Nature bio     26      6       <NA>       <NA>       <NA>
## 10:       article   2021 Computers     130   <NA>       <NA>       <NA>       <NA>
## 11:       article   2010   PLoS one      5      8       <NA>       <NA>       <NA>
## 12:       article   2023 IEEE Robot      8      8       <NA>       <NA>       <NA>
## 13:       article   2023 Journal of     24     70       <NA>       <NA>       <NA>
## 14:       article   2013 BMC Bioinf     14    164       <NA>       <NA>       <NA>
## 15:       article   2013 Journal of     54   <NA>       <NA>       <NA>       <NA>
## 16:       article   2014 Bioinforma     30     11       <NA>       <NA>       <NA>
## 17:       article   2017 Bioinforma     33      4       <NA>       <NA>       <NA>
## 18:       article   2019 The R Jour     11      2       <NA>       <NA>       <NA>
## 19:       article   2020 Journal of     21     87       <NA>       <NA>       <NA>
## 20:       article   2021 The R Jour     13      1       <NA>       <NA>       <NA>
## 21:       article   2022 Journal of    101     10       <NA>       <NA>       <NA>
## 22:       article   2023 Computatio     38   <NA>       <NA>       <NA>       <NA>
## 23:       article   2019 Biostatist     21      4       <NA>       <NA>       <NA>
## 24:       article   2024 Journal of   <NA>   <NA>       <NA>       <NA>       <NA>
## 25:       article   2021 BMC Bioinf     22    323       <NA>       <NA>       <NA>
## 26:       article   2017 Statistics     27   <NA>       <NA>       <NA>       <NA>
## 27:       article   2022 Biology Me      7      1       <NA>       <NA>       <NA>
## 28:       article   2023 Journal of    106      6       <NA>       <NA>       <NA>
## 29:       article   2016   Leukemia     30      7       <NA>       <NA>       <NA>
## 30:       article   2019 Journal of     28      2       <NA>       <NA>       <NA>
## 31:       article   2014 Cancer Sci    105      7       <NA>       <NA>       <NA>
## 32:       article   2023     Nature    618   <NA>       <NA> DOI:10.103       <NA>
## 33:       article   2024     Nature    627   8002       <NA>       <NA>       <NA>
## 34:       article   2022 Journal of     31      2       <NA>       <NA>       <NA>
## 35:  incollection   2022       <NA>   <NA>   <NA> Land Carbo       <NA>       <NA>
## 36: inproceedings   2017       <NA>   <NA>   <NA> Advances i       <NA>       <NA>
## 37: inproceedings   2020       <NA>   <NA>   <NA> 2020 54th        <NA>       <NA>
## 38: inproceedings   2020       <NA>   <NA>   <NA> 2020 42nd        <NA>       <NA>
## 39: inproceedings   2011       <NA>   <NA>   <NA> 28th inter       <NA>       <NA>
## 40: inproceedings   2013       <NA>   <NA>   <NA> Proc. 30th       <NA>       <NA>
## 41: inproceedings   2015       <NA>   <NA>   <NA> Proc. 32nd       <NA>       <NA>
## 42: inproceedings   2020       <NA>     25   <NA> Proc. Paci       <NA>       <NA>
## 43: inproceedings   2021       <NA>   <NA>   <NA> 2021 IEEE        <NA>       <NA>
## 44: inproceedings   2023       <NA>   <NA>   <NA> 2023 Inter       <NA>       <NA>
## 45: inproceedings   2022       <NA>   <NA>   <NA> 2022 Fourt       <NA>       <NA>
## 46: inproceedings   2022       <NA>   <NA>   <NA> 2022 fourt       <NA>       <NA>
## 47: inproceedings   2022       <NA>   <NA>   <NA> 2022 Fourt       <NA>       <NA>
## 48:     phdthesis   2012       <NA>   <NA>   <NA>       <NA>       <NA> Ecole norm
## 49:   unpublished   2023       <NA>   <NA>   <NA>       <NA> Preprint a       <NA>
## 50:   unpublished   2024       <NA>   <NA>   <NA>       <NA> In progres       <NA>
## 51:   unpublished   2024       <NA>   <NA>   <NA>       <NA> Under revi       <NA>
## 52:   unpublished   2015       <NA>   <NA>   <NA>       <NA> Preprint a       <NA>
## 53:   unpublished   2016       <NA>   <NA>   <NA>       <NA> Tutorial a       <NA>
## 54:   unpublished   2017       <NA>   <NA>   <NA>       <NA> Tutorial a       <NA>
## 55:   unpublished   2023       <NA>   <NA>   <NA>       <NA> In progres       <NA>
## 56:   unpublished   2024       <NA>   <NA>   <NA>       <NA> In progres       <NA>
## 57:   unpublished   2024       <NA>   <NA>   <NA>       <NA> In progres       <NA>
## 58:   unpublished   2024       <NA>   <NA>   <NA>       <NA> In progres       <NA>
## 59:   unpublished   2024       <NA>   <NA>   <NA>       <NA> In progres       <NA>
## 60:   unpublished   2024       <NA>   <NA>   <NA>       <NA> In progres       <NA>
## 61:   unpublished   2024       <NA>   <NA>   <NA>       <NA> In progres       <NA>
## 62:   unpublished   2024       <NA>   <NA>   <NA>       <NA> Preprint a       <NA>
## 63:   unpublished   2023       <NA>   <NA>   <NA>       <NA> Preprint a       <NA>
## 64:   unpublished   2024       <NA>   <NA>   <NA>       <NA> In progres       <NA>
## 65:   unpublished   2024       <NA>   <NA>   <NA>       <NA> In progres       <NA>
## 66:   unpublished   2014       <NA>   <NA>   <NA>       <NA> Preprint a       <NA>
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
      paste0(", DOI: ", gsub("[.]", " . ", doi)),
      paste0(
        " ",
        volume,
        ifelse(is.na(number), "", sprintf("(%s)", number))
      )
    )
  ),
  type=="inproceedings", booktitle,
  type=="incollection", sprintf("Chapter in %s, edited by %s, published by %s", booktitle, editor, publisher),
  type=="phdthesis", paste("PHD thesis,", school),
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
##  7:       article   2018 tional Cancer Institute 110(10)
##  8:       article   2018            Scientific data 5(1)
##  9:       article   2008      Nature biotechnology 26(6)
## 10:       article   2021 ers in Biology and Medicine 130
## 11:       article   2010                   PLoS one 5(8)
## 12:       article   2023 ics and Automation Letters 8(8)
## 13:       article   2023 achine Learning Research 24(70)
## 14:       article   2013      BMC Bioinformatics 14(164)
## 15:       article   2013 rnal of Statistical Software 54
## 16:       article   2014           Bioinformatics 30(11)
## 17:       article   2017            Bioinformatics 33(4)
## 18:       article   2019             The R Journal 11(2)
## 19:       article   2020 achine Learning Research 21(87)
## 20:       article   2021             The R Journal 13(1)
## 21:       article   2022 of Statistical Software 101(10)
## 22:       article   2023     Computational Statistics 38
## 23:       article   2019             Biostatistics 21(4)
## 24:       article   2024  1080/10618600 . 2023 . 2293216
## 25:       article   2021      BMC Bioinformatics 22(323)
## 26:       article   2017     Statistics and Computing 27
## 27:       article   2022 logy Methods and Protocols 7(1)
## 28:       article   2023  of Statistical Software 106(6)
## 29:       article   2016                  Leukemia 30(7)
## 30:       article   2019  and Graphical Statistics 28(2)
## 31:       article   2014               Cancer Sci 105(7)
## 32:       article   2023                      Nature 618
## 33:       article   2024                Nature 627(8002)
## 34:       article   2022  and Graphical Statistics 31(2)
## 35:  incollection   2022 published by Taylor and Francis
## 36: inproceedings   2017 formation Processing Systems 30
## 37: inproceedings   2020 Signals, Systems, and Computers
## 38: inproceedings   2020 Medicine Biology Society (EMBC)
## 39: inproceedings   2011  conference on machine learning
## 40: inproceedings   2013                 Proc. 30th ICML
## 41: inproceedings   2015                 Proc. 32nd ICML
## 42: inproceedings   2020 cific Symposium on Biocomputing
## 43: inproceedings   2021 Reliability Engineering (ISSRE)
## 44: inproceedings   2023 Technology and Computing (IETC)
## 45: inproceedings   2022  Transdisciplinary AI (TransAI)
## 46: inproceedings   2022  transdisciplinary AI (TransAI)
## 47: inproceedings   2022  Transdisciplinary AI (TransAI)
## 48:     phdthesis   2012 le normale supérieure de Cachan
## 49:   unpublished   2023 er review at BMC Bioinformatics
## 50:   unpublished   2024                     In progress
## 51:   unpublished   2024  Environmental Research Letters
## 52:   unpublished   2015       Preprint arXiv:1509.00368
## 53:   unpublished   2016 ernational useR 2016 conference
## 54:   unpublished   2017 onference, textbook in progress
## 55:   unpublished   2023                     In progress
## 56:   unpublished   2024                     In progress
## 57:   unpublished   2024                     In progress
## 58:   unpublished   2024                     In progress
## 59:   unpublished   2024                     In progress
## 60:   unpublished   2024                     In progress
## 61:   unpublished   2024                     In progress
## 62:   unpublished   2024       Preprint arXiv:2408.00856
## 63:   unpublished   2023       Preprint arXiv:2302.11062
## 64:   unpublished   2024                     In progress
## 65:   unpublished   2024                     In progress
## 66:   unpublished   2014        Preprint arXiv:1401.8008
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
##                     ref             complete      given        family abbrev            show
##                  <char>               <char>     <char>        <char> <char>          <char>
##   1:     Abraham2021gut   Abraham, Andrew J.  Andrew J.       Abraham     AJ      Abraham AJ
##   2:     Abraham2021gut Prys-Jones, Tomos O.   Tomos O.    Prys-Jones     TO   Prys-Jones TO
##   3:     Abraham2021gut  De Cuyper, Annelies   Annelies     De Cuyper      A     De Cuyper A
##   4:     Abraham2021gut      Ridenour, Chase      Chase      Ridenour      C      Ridenour C
##   5:     Abraham2021gut   Hempson, Gareth P.  Gareth P.       Hempson     GP      Hempson GP
##  ---                                                                                        
## 382: Truong2024circular   Toby Dylan Hocking Toby Dylan       Hocking     TD      Hocking TD
## 383:  Venuto2014support            Venuto, D          D        Venuto      D        Venuto D
## 384:  Venuto2014support  Hocking, Toby Dylan Toby Dylan       Hocking     TD      Hocking TD
## 385:  Venuto2014support     Sphanurattana, L          L Sphanurattana      L Sphanurattana L
## 386:  Venuto2014support          Sugiyama, M          M      Sugiyama      M      Sugiyama M
```

The table above shows all names standardized to a common format in the `show` column.
Below we verify that all names matched.


``` r
authors[is.na(family)]
```

```
## Empty data.table (0 rows and 6 cols): ref,complete,given,family,abbrev,show
```

The table above shows that there are no entries that did not match the regex, which is OK.


``` r
abbrev.dt <- authors[, .(
  authors_abbrev=paste(show, collapse=", ")
), by=ref]
abbrev.dt[, length(grep("Hocking",authors_abbrev))]
```

```
## [1] 66
```

The output above shows that there are 66 items for which I am listed as an author.


``` r
abbrev.dt[, .(ref, authors_abbrev=substr(authors_abbrev,1,30))]
```

```
##                                               ref                 authors_abbrev
##                                            <char>                         <char>
##  1:                                Abraham2021gut Abraham AJ, Prys-Jones TO, De 
##  2:                         Alirezaie2018clinpred Alirezaie N, Kernohan KD, Hart
##  3:                               Barnwal2022jcgs    Barnwal A, Cho H, Hocking T
##  4:                             Bodine2024mapping Bodine CS, Buscombe D, Hocking
##  5:                             Chaves2022chatbot Chaves AP, Egbert J, Hocking T
##  6:                             Chicard2016cancer Chicard M, Boyault S, Colmet D
##  7:                            Depuydt2018genomic Depuydt P, Boeva V, Hocking TD
##  8:                               Depuydt2018meta Depuydt P, Koster J, Boeva V, 
##  9:                            Doyon2008heritable Doyon Y, McCammon JM, Miller J
## 10:                        Fotoohinasab2021greedy Fotoohinasab A, Hocking T, Afg
## 11:                           Gautier2010bayesian Gautier M, Hocking TD, Foulley
## 12:                         Harshe2023exoskeleton Harshe K, Williams JR, Hocking
## 13:                               Hillman2023jmlr          Hillman J, Hocking TD
## 14:                     Hocking2013bioinformatics Hocking TD, Schleiermacher G, 
## 15:                        Hocking2013sustainable Hocking TD, Wutzler T, Ponting
## 16:                     Hocking2014bioinformatics Hocking TD, Boeva V, Rigaill G
## 17:                            Hocking2017bioinfo Hocking TD, Goerner-Potvin P, 
## 18:                              Hocking2019regex                     Hocking TD
## 19:                               Hocking2020jmlr Hocking TD, Rigaill G, Fearnhe
## 20:                          Hocking2021reshaping                     Hocking TD
## 21:                                Hocking2022jss Hocking TD, Rigaill G, Fearnhe
## 22:                             Hocking2023lopart       Hocking TD, Srivastava A
## 23:                       Jewell2019biostatistics Jewell SW, Hocking TD, Fearnhe
## 24:                         Kaufman2024functional Kaufman JM, Stenberg AJ, Hocki
## 25:                          Liehrmann2021chipseq Liehrmann A, Rigaill G, Hockin
## 26:                          Maidstone2017optimal Maidstone R, Hocking T, Rigail
## 27:                      Mihaljevic2022sparsemodr Mihaljevic JR, Borkovec S, Rat
## 28:                                  Runge2023jss Runge V, Hocking TD, Romano G,
## 29:                           Shimada2016leukemia Shimada K, Shimada S, Sugimoto
## 30:                               Sievert2019jcgs Sievert C, VanderPlas S, Cai J
## 31:                              Suguro2014cancer Suguro M, Yoshida N, Umino A, 
## 32:                                 Tao2023nature Tao F, Huang Y, Hungate BA, Ma
## 33:                                  Tao2024reply Tao F, Houlton BZ, Frey SD, Le
## 34:                      Vargovich2022breakpoints        Vargovich J, Hocking TD
## 35:                                Hocking22intro                     Hocking TD
## 36:                                Drouin2017mmit Drouin A, Hocking T, Laviolett
## 37: Fotoohinasab2020automaticQRSdetectionAsilomar Fotoohinasab A, Hocking T, Afg
## 38:              Fotoohinasab2020segmentationEMBC Fotoohinasab A, Hocking T, Afg
## 39:                        Hocking2011clusterpath Hocking TD, Joulin A, Bach F, 
## 40:                               Hocking2013icml Rigaill G, Hocking T, Vert J-P
## 41:                               Hocking2015icml Hocking TD, Rigaill G, Bourque
## 42:                                Hocking2020psb          Hocking TD, Bourque G
## 43:                                 Kolla2021fuzz  Kolla AC, Groce A, Hocking TD
## 44:                             Sweeney2023insect Sweeney N, Xu C, Shaw JA, Hock
## 45:                           barr2022classifying Barr JR, Hocking TD, Morton G,
## 46:                                 barr2022graph Barr JR, Shaw P, Abu-Khzam FN,
## 47:                      hocking2022interpretable Hocking TD, Barr JR, Thatcher 
## 48:                                Hocking2012phd                     Hocking TD
## 49:                                Agyapong2023cv Agyapong D, Propster JR, Marks
## 50:                                Fowler2024line           Fowler J, Hocking TD
## 51:                               Gurney2024power Gurney K, Aslam B, Dass P, Gaw
## 52:                    Hocking2015breakpointError                     Hocking TD
## 53:                        Hocking2016interactive         Hocking TD, Ekstrøm CT
## 54:                        Hocking2017changepoint          Hocking TD, Killick R
## 55:                         Hocking2023functional                     Hocking TD
## 56:                             Hocking2024autism Sutherland V, Hocking TD, Lind
## 57:                         Hocking2024binsegRcpp                     Hocking TD
## 58:                             Hocking2024finite                     Hocking TD
## 59:                                Hocking2024hmm                     Hocking TD
## 60:                     Hocking2024mlr3resampling                     Hocking TD
## 61:                               Hocking2024soak Bodine CS, Thibault G, Arellan
## 62:                             Nguyen2024penalty           Nguyen T, Hocking TD
## 63:                                 Rust2023pairs            Rust KR, Hocking TD
## 64:                            Thibault2024forest Thibault G, Hocking TD, Achim 
## 65:                            Truong2024circular           Truong C, Hocking TD
## 66:                             Venuto2014support Venuto D, Hocking TD, Sphanura
##                                               ref                 authors_abbrev
```

The output above shows the abbreviated author list is reasonable.

## Count article types


``` r
type2long <- c(
  article="journal paper",
  incollection="book chapter",
  inproceedings="conference paper",
  phdthesis="PHD thesis",
  unpublished="in progress")
refs.wide[, .(count=.N), by=.(Type=type2long[type])][order(-count)]
```

```
##                Type count
##              <char> <int>
## 1:    journal paper    34
## 2:      in progress    18
## 3: conference paper    12
## 4:     book chapter     1
## 5:       PHD thesis     1
```

## Output markdown

The code below joins the authors back to the original table, then outputs markdown.


``` r
abbrev.wide <- refs.wide[
  abbrev.dt, on="ref"
][, let(
  heading = ifelse(type=="unpublished", "In progress", year),
  citation = sprintf("- %s (%s). %s. %s. %s", authors_abbrev, year, title, venue, links)
)][order(-heading, -year, authors_abbrev)]
abbrev.some <- abbrev.wide[unique(heading)[1:3], .SD[1:2], on="heading", by=heading]
abbrev.some <- abbrev.wide
abbrev.some[
, .(markdown=sprintf("### %s\n%s\n", heading, paste(citation, collapse="\n")))
, by=heading
][
, cat(paste(markdown, collapse="\n"))
]
```

### In progress
- Bodine CS, Thibault G, Arellano PN, Shenkin AF, Lindly O, Hocking TD (2024). SOAK: Same/Other/All K-fold cross-validation for estimating similarity of patterns in data subsets. In progress. [Software](https://github.com/tdhock/mlr3resampling), [Reproducible](https://github.com/tdhock/cv-same-other-paper)
- Fowler J, Hocking TD (2024). Efficient line search for optimizing Area Under the ROC Curve in gradient descent. In progress. [Talk announcement for JSM'23 Toronto](https://ww2.aievolution.com/JSMAnnual/index.cfm?do=ev.viewEv&ev=2810), [Video of talk at Université Laval July 2023](https://www.youtube.com/watch?v=22ODpDTZ4VE), [Slides PDF](https://github.com/tdhock/max-generalized-auc/blob/master/HOCKING-slides-toronto.pdf), [source](https://github.com/tdhock/max-generalized-auc/#4-may-2023)
- Gurney K, Aslam B, Dass P, Gawuc L, Hocking TD, Barber JJ, Kato A (2024). Assessment of the Climate Trace global powerplant CO2 emissions. Under review at Environmental Research Letters. NA
- Hocking TD (2024). Comparing binsegRcpp with other implementations of binary segmentation for changepoint detection. In progress. [Reproducible](https://github.com/tdhock/binseg-model-selection), [Software](https://github.com/tdhock/binsegRcpp)
- Hocking TD (2024). Finite Sample Complexity Analysis of Binary Segmentation. In progress. [Reproducible](https://github.com/tdhock/binseg-model-selection), [Software](https://github.com/tdhock/binsegRcpp)
- Hocking TD (2024). Teaching Hidden Markov Models Using Interactive Data Visualization. In progress. [Reproducible](https://github.com/tdhock/2023-08-unsupervised-learning/blob/main/slides/07-hidden-markov-models.Rmd), [Slides](https://github.com/tdhock/2023-08-unsupervised-learning/blob/main/slides/07-hidden-markov-models.pdf)
- Hocking TD (2024). mlr3resampling: an R implementation of cross-validation for comparing models learned using different train subsets. In progress. [Software](https://github.com/tdhock/mlr3resampling)
- Nguyen T, Hocking TD (2024). Deep Learning Approach for Changepoint Detection: Penalty Parameter Optimization. Preprint arXiv:2408.00856. [Preprint](https://arxiv.org/abs/2408.00856)
- Sutherland V, Hocking TD, Lindly O (2024). Interpretable machine learning algorithms for understanding factors related to childhood autism. In progress. [Reproducible](https://github.com/tdhock/2024-01-ml-for-autism)
- Thibault G, Hocking TD, Achim A (2024). Predicting forest burn from satellite image data. In progress. NA
- Truong C, Hocking TD (2024). Efficient change-point detection for multivariate circular data. In progress. [Reproducible](https://github.com/tdhock/angular-change-paper), [Software](https://github.com/tdhock/geodesichange)
- Agyapong D, Propster JR, Marks J, Hocking TD (2023). Cross-Validation for Training and Testing Co-occurrence Network Inference Algorithms. Preprint arXiv:2309.15225, under review at BMC Bioinformatics. [Preprint](https://arxiv.org/abs/2309.15225)
- Hocking TD (2023). Why does functional pruning yield such fast algorithms for optimal changepoint detection?. In progress. Invited talk for TRIPODS seminar [video](https://arizona.hosted.panopto.com/Panopto/Pages/Viewer.aspx?id=4e87c8d0-96d2-40d1-808c-ad16014c6962), [slides](https://github.com/tdhock/functional-pruning-theory#readme), [IEEE NJACS](https://events.vtools.ieee.org/m/280515), [ASU West ML Day](https://newcollege.asu.edu/machine-learning-day-1)
- Rust KR, Hocking TD (2023). A Log-linear Gradient Descent Algorithm for Unbalanced Binary Classification using the All Pairs Squared Hinge Loss. Preprint arXiv:2302.11062. [Preprint](https://arxiv.org/abs/2302.11062)
- Hocking TD, Killick R (2017). Introduction to optimal changepoint detection algorithms. Tutorial at international useR 2017 conference, textbook in progress. [Tutorial](https://github.com/tdhock/change-tutorial), [Book](https://github.com/tdhock/changepoint-book)
- Hocking TD, Ekstrøm CT (2016). Understanding and Creating Interactive Graphics. Tutorial at international useR 2016 conference. [Tutorial](http://user2016.r-project.org/tutorials/13.html), [Reproducible](https://github.com/tdhock/interactive-tutorial)
- Hocking TD (2015). A breakpoint detection error function for segmentation model selection and validation. Preprint arXiv:1509.00368. [Preprint](https://arxiv.org/abs/1509.00368), [Software](http://r-forge.r-project.org/scm/?group_id=1540), [Reproducible](https://github.com/tdhock/breakpointError-orig)
- Venuto D, Hocking TD, Sphanurattana L, Sugiyama M (2014). Support vector comparison machines. Preprint arXiv:1401.8008. [Preprint](https://arxiv.org/abs/1401.8008), [Software](https://github.com/tdhock/rankSVMcompare), [Reproducible](https://github.com/tdhock/compare-paper)

### 2024
- Bodine CS, Buscombe D, Hocking TD (2024). Automated River Substrate Mapping From Sonar Imagery With Machine Learning. Journal of Geophysical Research: Machine Learning and Computation 1(3). [DOI](https://doi.org/10.1029/2024JH000135), [Preprint](https://eartharxiv.org/repository/view/6448/), [Software](https://github.com/CameronBodine/PINGMapper)
- Kaufman JM, Stenberg AJ, Hocking TD (2024). Functional Labeled Optimal Partitioning. Journal of Computational and Graphical Statistics, DOI: 10 . 1080/10618600 . 2023 . 2293216. [DOI](https://doi.org/10.1080/10618600.2023.2293216), [Preprint](https://arxiv.org/abs/2210.02580), [Software](https://github.com/tdhock/FLOPART), [Reproducible](https://github.com/jkaufy/Flopart-Paper), [Preliminary code](https://github.com/tdhock/LabeledFPOP-paper)
- Tao F, Houlton BZ, Frey SD, Lehmann J, Manzoni S, Huang Y, Jiang L, Mishra U, Hungate BA, Schmidt MWI, Reichstein M, Carvalhais N, Ciais P, Wang Y-P, Ahrens B, Hugelius G, Hocking TD, Lu X, Shi Z, Viatkin K, Vargas R, Yigini Y, Omuto C, Malik AA, Peralta G, Cuevas-Corona R, Paolo LED, Luotto I, Liao C, Liang Y-S, Saynes VS, Huang X, Luo Y (2024). Reply to: Model uncertainty obscures major driver of soil carbon. Nature 627(8002). [Publisher](https://www.nature.com/articles/s41586-023-07000-9), [Preprint](https://eartharxiv.org/repository/view/6125/)

### 2023
- Harshe K, Williams JR, Hocking TD, Lerner ZF (2023). Predicting Neuromuscular Engagement to Improve Gait Training With a Robotic Ankle Exoskeleton. IEEE Robotics and Automation Letters 8(8). [Publisher](https://ieeexplore.ieee.org/document/10172008)
- Hillman J, Hocking TD (2023). Optimizing ROC Curves with a Sort-Based Surrogate Loss for Binary Classification and Changepoint Detection. Journal of Machine Learning Research 24(70). [Publisher](https://jmlr.org/papers/v24/21-0751.html), [Preprint](https://arxiv.org/abs/2107.01285), [Software](https://github.com/tdhock/aum), [Reproducible](https://github.com/tdhock/max-generalized-auc)
- Hocking TD, Srivastava A (2023). Labeled optimal partitioning. Computational Statistics 38. [Publisher](https://rdcu.be/cQ8qM), [Preprint](https://arxiv.org/abs/2006.13967), [Video](https://www.youtube.com/watch?v=lm_6_33zOWc), [Software](https://github.com/tdhock/LOPART), [Reproducible](https://github.com/tdhock/LOPART-paper)
- Runge V, Hocking TD, Romano G, Afghah F, Fearnhead P, Rigaill G (2023). gfpop: An R Package for Univariate Graph-Constrained Change-Point Detection. Journal of Statistical Software 106(6). [Publisher](https://www.jstatsoft.org/article/view/v106i06), [Preprint](https://arxiv.org/abs/2002.03646), [Software](https://github.com/vrunge/gfpop), [GUI](https://github.com/julianstanley/gfpopgui), [Reproducible](https://github.com/vrunge/gfpop/blob/master/vignettes/applications.Rmd)
- Sweeney N, Xu C, Shaw JA, Hocking TD, Whitaker BM (2023). Insect Identification in Pulsed Lidar Images Using Changepoint Detection Algorithms. 2023 Intermountain Engineering, Technology and Computing (IETC). [Publisher](https://ieeexplore.ieee.org/abstract/document/10152205)
- Tao F, Huang Y, Hungate BA, Manzoni S, Frey SD, Schmidt MWI, Reichstein M, Carvalhais N, Ciais P, Jiang L, Lehmann J, Mishra U, Hugelius G, Hocking TD, Lu X, Shi Z, Viatkin K, Vargas R, Yigini Y, Omuto C, Malik AA, Perualta G, Cuevas-Corona R, Paolo LED, Luotto I, Liao C, Liang Y-S, Saynes VS, Huang X, Luo Y (2023). Microbial carbon use efficiency promotes global soil carbon storage. Nature 618. [Publisher](https://www.nature.com/articles/s41586-023-06042-3)

### 2022
- Barnwal A, Cho H, Hocking T (2022). Survival Regression with Accelerated Failure Time Model in XGBoost. Journal of Computational and Graphical Statistics 31(4). [Publisher](https://www.tandfonline.com/doi/full/10.1080/10618600.2022.2067548), [Preprint](https://arxiv.org/abs/2006.04920), [Software](https://github.com/dmlc/xgboost), [Documentation](https://xgboost.readthedocs.io/en/latest/tutorials/aft_survival_analysis.html), [Video](https://www.youtube.com/watch?v=HuWRnzgGuIo), [Reproducible](https://github.com/avinashbarnwal/aftXgboostPaper/)
- Barr JR, Hocking TD, Morton G, Thatcher T, Shaw P (2022). Classifying Imbalanced Data with AUM Loss. 2022 Fourth International Conference on Transdisciplinary AI (TransAI). [Publisher](https://ieeexplore.ieee.org/document/9951523)
- Barr JR, Shaw P, Abu-Khzam FN, Thatcher T, Hocking TD (2022). Graph embedding: A methodological survey. 2022 fourth international conference on transdisciplinary AI (TransAI). [Publisher](https://ieeexplore.ieee.org/document/9951469/)
- Chaves AP, Egbert J, Hocking T, Doerry E, Gerosa MA (2022). Chatbots Language Design: The Influence of Language Variation on User Experience with Tourist Assistant Chatbots. ACM Trans. Comput.-Hum. Interact. 29(2). [Publisher](https://dl.acm.org/doi/10.1145/3487193), [Preprint](https://arxiv.org/abs/2101.11089)
- Hocking TD (2022). Introduction to machine learning and neural networks. Chapter in Land Carbon Cycle Modeling: Matrix Approach, Data Assimilation, and Ecological Forecasting, edited by Yiqi Luo, published by Taylor and Francis. [Publisher](https://www.taylorfrancis.com/books/oa-edit/10.1201/9780429155659/land-carbon-cycle-modeling-yiqi-luo-benjamin-smith), [My chapter](https://raw.githubusercontent.com/tdhock/2020-yiqi-summer-school/master/HOCKING-chapter.pdf), [Reproducible](https://github.com/tdhock/2020-yiqi-summer-school#prepared-for-the-summer-school-4th-year-2021)
- Hocking TD, Barr JR, Thatcher T (2022). Interpretable linear models for predicting security vulnerabilities in source code. 2022 Fourth International Conference on Transdisciplinary AI (TransAI). [Publisher](https://ieeexplore.ieee.org/document/9951610/)
- Hocking TD, Rigaill G, Fearnhead P, Bourque G (2022). Generalized Functional Pruning Optimal Partitioning (GFPOP) for Constrained Changepoint Detection in Genomic Data. Journal of Statistical Software 101(10). [Publisher](https://www.jstatsoft.org/article/view/v101i10), [Software](https://github.com/tdhock/PeakSegDisk), [Reproducible](https://github.com/tdhock/PeakSegFPOP-paper), [Slides](http://www.user2019.fr/static/pres/t257847.pdf), [Video](https://www.youtube.com/watch?v=XlC4WCqsbuI)
- Mihaljevic JR, Borkovec S, Ratnavale S, Hocking TD, Banister KE, Eppinger JE, Hepp C, Doerry E (2022). SPARSEMODr: Rapidly simulate spatially explicit and stochastic models of COVID-19 and other infectious diseases. Biology Methods and Protocols 7(1). [Publisher](https://academic.oup.com/biomethods/advance-article/doi/10.1093/biomethods/bpac022/6680179), [Preprint](https://www.medrxiv.org/content/10.1101/2021.05.13.21256216v1), [Software](https://github.com/NAU-CCL/SPARSEMODr)
- Vargovich J, Hocking TD (2022). Linear time dynamic programming for computing breakpoints in the regularization path of models selected from a finite set. Journal of Computational and Graphical Statistics 31(2). [Publisher](https://amstat.tandfonline.com/doi/full/10.1080/10618600.2021.2000422), [Preprint](https://arxiv.org/abs/2003.02808), [Software](https://github.com/tdhock/penaltyLearning), [Reproducible](https://github.com/tdhock/changepoint-data-structure#source-code-for-figures-in-paper)

### 2021
- Abraham AJ, Prys-Jones TO, De Cuyper A, Ridenour C, Hempson GP, Hocking T, Clauss M, Doughty CE (2021). Improved estimation of gut passage time considerably affects trait-based dispersal models. Functional Ecology 35(4). [Publisher](https://besjournals.onlinelibrary.wiley.com/doi/10.1111/1365-2435.13726)
- Fotoohinasab A, Hocking T, Afghah F (2021). A greedy graph search algorithm based on changepoint analysis for automatic QRS complex detection. Computers in Biology and Medicine 130. [Publisher](https://www.sciencedirect.com/science/article/pii/S0010482521000020), [Preprint](https://arxiv.org/abs/2004.13558)
- Hocking TD (2021). Wide-to-tall Data Reshaping Using Regular Expressions and the nc Package. The R Journal 13(1). [Publisher](https://journal.r-project.org/archive/2021/RJ-2021-029/index.html), [Software](https://github.com/tdhock/nc), [Reproducible](https://github.com/tdhock/nc-article)
- Kolla AC, Groce A, Hocking TD (2021). Fuzz Testing the Compiled Code in R Packages. 2021 IEEE 32nd International Symposium on Software Reliability Engineering (ISSRE). [Publisher](https://ieeexplore.ieee.org/document/9700272), [Software](https://github.com/akhikolla/RcppDeepState), [GitHub Action](https://github.com/FabrizioSandri/RcppDeepState-action), [Abstract](https://www.conftool.org/user2021/index.php?page=browseSessions&form_session=9#paperID123), [Video](https://www.youtube.com/watch?v=LXyruwSo2K0&t=245s), [Blog](https://akhikolla.github.io), [Results](https://akhikolla.github.io/packages-folders/)
- Liehrmann A, Rigaill G, Hocking TD (2021). Increased peak detection accuracy in over-dispersed ChIP-seq data with supervised segmentation models. BMC Bioinformatics 22(323). [Publisher](https://bmcbioinformatics.biomedcentral.com/articles/10.1186/s12859-021-04221-5), [Reproducible](https://github.com/aLiehrmann/ChIP_SEQ_segmentation_paper), [Software](https://github.com/aliehrmann/crocs)

### 2020
- Fotoohinasab A, Hocking T, Afghah F (2020). A Graph-Constrained Changepoint Learning Approach for Automatic QRS-Complex Detection. 2020 54th Asilomar Conference on Signals, Systems, and Computers. [Publisher](https://ieeexplore.ieee.org/document/9443307), [Abstract](https://www2.securecms.com/Asilomar2020/Papers/ViewPapers.asp?PaperNum=1323),  [Preprint](https://arxiv.org/abs/2004.13558)
- Fotoohinasab A, Hocking T, Afghah F (2020). A Graph-constrained Changepoint Detection Approach for ECG Segmentation. 2020 42nd Annual International Conference of the IEEE Engineering in Medicine Biology Society (EMBC). [Publisher](https://ieeexplore.ieee.org/document/9175333)
- Hocking TD, Bourque G (2020). Machine Learning Algorithms for Simultaneous Supervised Detection of Peaks in Multiple Samples and Cell Types. Proc. Pacific Symposium on Biocomputing. [Publisher](http://psb.stanford.edu/psb-online/proceedings/psb20/Hocking.pdf), [Software](https://github.com/tdhock/PeakSegJoint), [Preprint](https://arxiv.org/abs/1506.01286), [Reproducible](https://github.com/tdhock/PeakSegJoint-paper)
- Hocking TD, Rigaill G, Fearnhead P, Bourque G (2020). Constrained Dynamic Programming and Supervised Penalty Learning Algorithms for Peak Detection in Genomic Data. Journal of Machine Learning Research 21(87). [Publisher](http://jmlr.org/papers/v21/18-843.html), [Preprint](https://arxiv.org/abs/1703.03352), [Software](https://github.com/tdhock/PeakSegOptimal), [Reproducible](https://github.com/tdhock/PeakSegFPOP-paper)

### 2019
- Hocking TD (2019). Comparing namedCapture with other R packages for regular expressions. The R Journal 11(2). [Publisher](https://journal.r-project.org/archive/2019/RJ-2019-050/index.html), [Software](https://github.com/tdhock/namedCapture), [Reproducible](https://github.com/tdhock/namedCapture-article)
- Jewell SW, Hocking TD, Fearnhead P, Witten DM (2019). Fast nonconvex deconvolution of calcium imaging data. Biostatistics 21(4). [Pubmed](https://www.ncbi.nlm.nih.gov/pubmed/30753436)
- Sievert C, VanderPlas S, Cai J, Ferris K, Khan FUF, Hocking TD (2019). Extending ggplot2 for Linked and Animated Web Graphics. Journal of Computational and Graphical Statistics 28(2). [Publisher](https://amstat.tandfonline.com/doi/full/10.1080/10618600.2018.1513367), [Manual](https://rcdata.nau.edu/genomic-ml/animint2-manual/Ch02-ggplot2.html), [Software](https://github.com/tdhock/animint), [Reproducible](https://github.com/tdhock/animint-paper), [Interactive Figures](https://rcdata.nau.edu/genomic-ml/public_html/animint-paper-figures/)

### 2018
- Alirezaie N, Kernohan KD, Hartley T, Majewski J, Hocking TD (2018). ClinPred: Prediction Tool to Identify Disease-Relevant Nonsynonymous Single-Nucleotide Variants. The American Journal of Human Genetics 103(4). [DOI](https://doi.org/10.1016/j.ajhg.2018.08.005), [Software](http://github.com/tdhock/predict-clinically-pathogenic), [used in dbNSFP](https://sites.google.com/site/jpopgen/dbNSFP)
- Depuydt P, Boeva V, Hocking TD, Cannoodt R, Ambros IM, Ambros PF, Asgharzadeh S, Attiyeh EF, Combaret Vé, Defferrari R, Fischer M, Hero B, Hogarty MD, Irwin MS, Koster J, Kreissman S, Ladenstein R, Lapouble E, Laureys Gè, London WB, Mazzocco K, Nakagawara A, Noguera R, Ohira M, Park JR, Pötschger U, Theissen J, Tonini GP, Valteau-Couanet D, Varesio L, Versteeg R, Speleman F, Maris JM, Schleiermacher G, Preter KD (2018). Genomic amplifications and distal 6q loss: novel markers for poor survival in high-risk neuroblastoma patients. JNCI: Journal of the National Cancer Institute 110(10). [Publisher](https://academic.oup.com/jnci/advance-article/doi/10.1093/jnci/djy022/4921185)
- Depuydt P, Koster J, Boeva V, Hocking TD, Speleman F, Schleiermacher G, De Preter K (2018). Meta-mining of copy number profiles of high-risk neuroblastoma tumors. Scientific data 5(1). [Publisher](https://www.nature.com/articles/sdata2018240)

### 2017
- Drouin A, Hocking T, Laviolette F (2017). Maximum Margin Interval Trees. Advances in Neural Information Processing Systems 30. [Publisher](http://papers.nips.cc/paper/7080-maximum-margin-interval-trees), [Software](https://github.com/aldro61/mmit), [Reproducible](https://github.com/tdhock/mmit-paper), [Preprint](https://arxiv.org/abs/1710.04234), [Video](https://www.youtube.com/watch?v=sNrMH9z1rb4)
- Hocking TD, Goerner-Potvin P, Morin A, Shao X, Pastinen T, Bourque G (2017). Optimizing ChIP-seq peak detectors using visual labels and supervised machine learning. Bioinformatics 33(4). [Pubmed](https://www.ncbi.nlm.nih.gov/pubmed/27797775), [Software](https://github.com/tdhock/PeakError), [Reproducible](https://bitbucket.org/mugqic/chip-seq-paper), [Data](https://rcdata.nau.edu/genomic-ml/chip-seq-chunk-db/)
- Maidstone R, Hocking T, Rigaill G, Fearnhead P (2017). On optimal multiple changepoint algorithms for large data. Statistics and Computing 27. [Publisher](https://link.springer.com/article/10.1007/s11222-016-9636-3), [Software](https://r-forge.r-project.org/R/?group_id=1851), [Reproducible](https://r-forge.r-project.org/scm/viewvc.php/benchmark/?root=opfp)

### 2016
- Chicard M, Boyault S, Colmet Daage L, Richer W, Gentien D, Pierron G, Lapouble E, Bellini A, Clement N, Iacono I, Bréjon Sé, Carrere M, Reyes Cé, Hocking T, Bernard V, Peuchmaur M, Corradini Nè, Faure-Conter Cé, Coze C, Plantaz D, Defachelles AS, Thebaud E, Gambart M, Millot Féé, Valteau-Couanet D, Michon J, Puisieux A, Delattre O, Combaret Vé, Schleiermacher G (2016). Genomic Copy Number Profiling Using Circulating Free Tumor DNA Highlights Heterogeneity in Neuroblastoma. Clinical Cancer Research 22(22). [Publisher](http://clincancerres.aacrjournals.org/content/early/2016/11/03/1078-0432.CCR-16-0500)
- Shimada K, Shimada S, Sugimoto K, Nakatochi M, Suguro M, Hirakawa A, Hocking TD, Takeuchi I, Tokunaga T, Takagi Y, Sakamoto A, Aoki T, Naoe T, Nakamura S, Hayakawa F, Seto M, Tomita A, Kiyoi H (2016). Development and analysis of patient-derived xenograft mouse models in intravascular large B-cell lymphoma. Leukemia 30(7). [Pubmed](https://www.ncbi.nlm.nih.gov/pubmed/27001523)

### 2015
- Hocking TD, Rigaill G, Bourque G (2015). PeakSeg: constrained optimal segmentation and supervised penalty learning for peak detection in count data. Proc. 32nd ICML. [Publisher](http://proceedings.mlr.press/v37/hocking15.html), [Video](http://videolectures.net/icml2015_hocking_count_data/?q=hocking), [Software](https://github.com/tdhock/PeakSegDP), [Reproducible](https://github.com/tdhock/PeakSeg-paper)

### 2014
- Hocking TD, Boeva V, Rigaill G, Schleiermacher G, Janoueix-Lerosey I, Delattre O, Richer W, Bourdeaut F, Suguro M, Seto M, Bach F, Vert JP (2014). SegAnnDB: interactive Web-based genomic segmentation. Bioinformatics 30(11). [Pubmed](http://www.ncbi.nlm.nih.gov/pubmed/24493034), [Software](https://github.com/tdhock/SegAnnDB), [Reproducible](https://gforge.inria.fr/scm/viewvc.php/breakpoints/webapp/applications-note/), [Preprint](https://hal.inria.fr/hal-00759129), [Package](https://r-forge.r-project.org/scm/?group_id=1541), [Reproducible](https://gforge.inria.fr/scm/viewvc.php/pruned-dp/SegAnnot/inst/doc/?root=breakpoints)
- Suguro M, Yoshida N, Umino A, Kato H, Tagawa H, Nakagawa M, Fukuhara N, Karnan S, Takeuchi I, Hocking TD, Arita K, Karube K, Tsuzuki S, Nakamura S, Kinoshita T, Seto M (2014). Clonal heterogeneity of lymphoid malignancies correlates with poor prognosis. Cancer Sci 105(7). [Pubmed](http://www.ncbi.nlm.nih.gov/pubmed/24815991)

### 2013
- Hocking TD, Schleiermacher G, Janoueix-Lerosey I, Boeva V, Cappo J, Delattre O, Bach F, Vert J-P (2013). Learning smoothing models of copy number profiles using breakpoint annotations. BMC Bioinformatics 14(164). [Publisher](https://bmcbioinformatics.biomedcentral.com/articles/10.1186/1471-2105-14-164), [Software](https://cran.r-project.org/src/contrib/Archive/bams/), [Reproducible](https://rcdata.nau.edu/genomic-ml/public_html/papers/2012-01-27-Breakpoint-annotation-model-smoothing/HOCKING-breakpoint-annotation-model-smoothing.tgz)
- Hocking TD, Wutzler T, Ponting K, Grosjean P (2013). Sustainable, Extensible Documentation Generation using inlinedocs. Journal of Statistical Software 54. [Publisher](https://www.jstatsoft.org/article/view/v054i06), [Software](https://cran.r-project.org/package=inlinedocs), [Reproducible](https://r-forge.r-project.org/scm/viewvc.php/tex/jss762/?root=inlinedocs)
- Rigaill G, Hocking T, Vert J-P, Bach F (2013). Learning sparse penalties for change-point detection using max margin interval regression. Proc. 30th ICML. [Publisher](http://proceedings.mlr.press/v28/hocking13.html), [Video](http://techtalks.tv/talks/learning-sparse-penalties-for-change-point-detection-using-max-margin-interval-regression/58208/), [Software](https://github.com/tdhock/penaltyLearning), [Reproducible](https://gforge.inria.fr/scm/viewvc.php/pruned-dp/?root=breakpoints)

### 2012
- Hocking TD (2012). Learning algorithms and statistical software, with applications to bioinformatics. PHD thesis, Ecole normale supérieure de Cachan. [Publisher](https://tel.archives-ouvertes.fr/tel-00906029/), [Reproducible](https://rcdata.nau.edu/genomic-ml/public_html/papers/2012-11-20-PhD-thesis/HOCKING-phd-thesis.tgz)

### 2011
- Hocking TD, Joulin A, Bach F, Vert J-P (2011). Clusterpath an algorithm for clustering using convex fusion penalties. 28th international conference on machine learning. [Publisher](http://www.icml-2011.org/papers/419_icmlpaper.pdf), [Video](http://techtalks.tv/talks/clusterpath-an-algorithm-for-clustering-using-convex-fusion-penalties/54405/), [Software](https://r-forge.r-project.org/scm/?group_id=1090), [Reproducible](https://r-forge.r-project.org/scm/viewvc.php/tex/?root=clusterpath), [Cited in Ihaka lecture](https://www.youtube.com/watch?v=2g-akN6q8aI)

### 2010
- Gautier M, Hocking TD, Foulley J-L (2010). A Bayesian outlier criterion to detect SNPs under selection in large data sets. PLoS one 5(8). [Publisher](http://journals.plos.org/plosone/article?id=10.1371/journal.pone.0011913)

### 2008
- Doyon Y, McCammon JM, Miller JC, Faraji F, Ngo C, Katibah GE, Amora R, Hocking TD, Zhang L, Rebar EJ, Gregory PD, Urnov FD, Amacher SL (2008). Heritable targeted gene disruption in zebrafish using designed zinc-finger nucleases. Nature biotechnology 26(6). [Pubmed](http://www.ncbi.nlm.nih.gov/pubmed/18500334)
NULL

## Another output: markdown table with images

One advantage of this is that we can easily modify output formats.


``` r
for(large.png in Sys.glob("../assets/img/publications/*.png")){
  thumb.png <- file.path(
    dirname(large.png),
    "thumb",
    basename(large.png))
  if(!file.exists(thumb.png)){
    dir.create(dirname(thumb.png))
    convert.cmd <- paste("convert", large.png, "-scale 150", thumb.png)
    print(convert.cmd)
    system(convert.cmd)
  }
}
some.out <- abbrev.some[
, figure.png := sprintf("/assets/img/publications/thumb/%s.png", ref)
][, .(
  Figure=ifelse(
    file.exists(file.path("..", figure.png)),
    sprintf('<img src="%s" width="150" />', figure.png),
    ""),
  Published=heading,
  Authors=authors_abbrev,
  Title=title,
  Venue=venue,
  Links=ifelse(is.na(links), "", links)
)]
knitr::kable(some.out)
```



|Figure                                                                                  |Published   |Authors                                                                                                                                                                                                                                                                                                                                                                                                                         |Title                                                                                                                     |Venue                                                                                                                                                      |Links                                                                                                 |
|:---------------------------------------------------------------------------------------|:-----------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:-------------------------------------------------------------------------------------------------------------------------|:----------------------------------------------------------------------------------------------------------------------------------------------------------|:-----------------------------------------------------------------------------------------------------|
|<img src="/assets/img/publications/thumb/Hocking2024soak.png" width="150" />            |In progress |Bodine CS, Thibault G, Arellano PN, Shenkin AF, Lindly O, Hocking TD                                                                                                                                                                                                                                                                                                                                                            |SOAK: Same/Other/All K-fold cross-validation for estimating similarity of patterns in data subsets                        |In progress                                                                                                                                                |[Software](https://github.com/tdhock/mlr3resampling), [Reproducible](https://github.com/tdhock/cv-same-other-paper)|
|<img src="/assets/img/publications/thumb/Fowler2024line.png" width="150" />             |In progress |Fowler J, Hocking TD                                                                                                                                                                                                                                                                                                                                                                                                            |Efficient line search for optimizing Area Under the ROC Curve in gradient descent                                         |In progress                                                                                                                                                |[Talk announcement for JSM'23 Toronto](https://ww2.aievolution.com/JSMAnnual/index.cfm?do=ev.viewEv&ev=2810), [Video of talk at Université Laval July 2023](https://www.youtube.com/watch?v=22ODpDTZ4VE), [Slides PDF](https://github.com/tdhock/max-generalized-auc/blob/master/HOCKING-slides-toronto.pdf), [source](https://github.com/tdhock/max-generalized-auc/#4-may-2023)|
|                                                                                        |In progress |Gurney K, Aslam B, Dass P, Gawuc L, Hocking TD, Barber JJ, Kato A                                                                                                                                                                                                                                                                                                                                                               |Assessment of the Climate Trace global powerplant CO2 emissions                                                           |Under review at Environmental Research Letters                                                                                                             |                                                                                                      |
|<img src="/assets/img/publications/thumb/Hocking2024binsegRcpp.png" width="150" />      |In progress |Hocking TD                                                                                                                                                                                                                                                                                                                                                                                                                      |Comparing binsegRcpp with other implementations of binary segmentation for changepoint detection                          |In progress                                                                                                                                                |[Reproducible](https://github.com/tdhock/binseg-model-selection), [Software](https://github.com/tdhock/binsegRcpp)|
|<img src="/assets/img/publications/thumb/Hocking2024finite.png" width="150" />          |In progress |Hocking TD                                                                                                                                                                                                                                                                                                                                                                                                                      |Finite Sample Complexity Analysis of Binary Segmentation                                                                  |In progress                                                                                                                                                |[Reproducible](https://github.com/tdhock/binseg-model-selection), [Software](https://github.com/tdhock/binsegRcpp)|
|<img src="/assets/img/publications/thumb/Hocking2024hmm.png" width="150" />             |In progress |Hocking TD                                                                                                                                                                                                                                                                                                                                                                                                                      |Teaching Hidden Markov Models Using Interactive Data Visualization                                                        |In progress                                                                                                                                                |[Reproducible](https://github.com/tdhock/2023-08-unsupervised-learning/blob/main/slides/07-hidden-markov-models.Rmd), [Slides](https://github.com/tdhock/2023-08-unsupervised-learning/blob/main/slides/07-hidden-markov-models.pdf)|
|<img src="/assets/img/publications/thumb/Hocking2024mlr3resampling.png" width="150" />  |In progress |Hocking TD                                                                                                                                                                                                                                                                                                                                                                                                                      |mlr3resampling: an R implementation of cross-validation for comparing models learned using different train subsets        |In progress                                                                                                                                                |[Software](https://github.com/tdhock/mlr3resampling)                                                  |
|<img src="/assets/img/publications/thumb/Nguyen2024penalty.png" width="150" />          |In progress |Nguyen T, Hocking TD                                                                                                                                                                                                                                                                                                                                                                                                            |Deep Learning Approach for Changepoint Detection: Penalty Parameter Optimization                                          |Preprint arXiv:2408.00856                                                                                                                                  |[Preprint](https://arxiv.org/abs/2408.00856)                                                          |
|<img src="/assets/img/publications/thumb/Hocking2024autism.png" width="150" />          |In progress |Sutherland V, Hocking TD, Lindly O                                                                                                                                                                                                                                                                                                                                                                                              |Interpretable machine learning algorithms for understanding factors related to childhood autism                           |In progress                                                                                                                                                |[Reproducible](https://github.com/tdhock/2024-01-ml-for-autism)                                       |
|                                                                                        |In progress |Thibault G, Hocking TD, Achim A                                                                                                                                                                                                                                                                                                                                                                                                 |Predicting forest burn from satellite image data                                                                          |In progress                                                                                                                                                |                                                                                                      |
|<img src="/assets/img/publications/thumb/Truong2024circular.png" width="150" />         |In progress |Truong C, Hocking TD                                                                                                                                                                                                                                                                                                                                                                                                            |Efficient change-point detection for multivariate circular data                                                           |In progress                                                                                                                                                |[Reproducible](https://github.com/tdhock/angular-change-paper), [Software](https://github.com/tdhock/geodesichange)|
|<img src="/assets/img/publications/thumb/Agyapong2023cv.png" width="150" />             |In progress |Agyapong D, Propster JR, Marks J, Hocking TD                                                                                                                                                                                                                                                                                                                                                                                    |Cross-Validation for Training and Testing Co-occurrence Network Inference Algorithms                                      |Preprint arXiv:2309.15225, under review at BMC Bioinformatics                                                                                              |[Preprint](https://arxiv.org/abs/2309.15225)                                                          |
|<img src="/assets/img/publications/thumb/Hocking2023functional.png" width="150" />      |In progress |Hocking TD                                                                                                                                                                                                                                                                                                                                                                                                                      |Why does functional pruning yield such fast algorithms for optimal changepoint detection?                                 |In progress                                                                                                                                                |Invited talk for TRIPODS seminar [video](https://arizona.hosted.panopto.com/Panopto/Pages/Viewer.aspx?id=4e87c8d0-96d2-40d1-808c-ad16014c6962), [slides](https://github.com/tdhock/functional-pruning-theory#readme), [IEEE NJACS](https://events.vtools.ieee.org/m/280515), [ASU West ML Day](https://newcollege.asu.edu/machine-learning-day-1)|
|<img src="/assets/img/publications/thumb/Rust2023pairs.png" width="150" />              |In progress |Rust KR, Hocking TD                                                                                                                                                                                                                                                                                                                                                                                                             |A Log-linear Gradient Descent Algorithm for Unbalanced Binary Classification using the All Pairs Squared Hinge Loss       |Preprint arXiv:2302.11062                                                                                                                                  |[Preprint](https://arxiv.org/abs/2302.11062)                                                          |
|<img src="/assets/img/publications/thumb/Hocking2017changepoint.png" width="150" />     |In progress |Hocking TD, Killick R                                                                                                                                                                                                                                                                                                                                                                                                           |Introduction to optimal changepoint detection algorithms                                                                  |Tutorial at international useR 2017 conference, textbook in progress                                                                                       |[Tutorial](https://github.com/tdhock/change-tutorial), [Book](https://github.com/tdhock/changepoint-book)|
|<img src="/assets/img/publications/thumb/Hocking2016interactive.png" width="150" />     |In progress |Hocking TD, Ekstrøm CT                                                                                                                                                                                                                                                                                                                                                                                                          |Understanding and Creating Interactive Graphics                                                                           |Tutorial at international useR 2016 conference                                                                                                             |[Tutorial](http://user2016.r-project.org/tutorials/13.html), [Reproducible](https://github.com/tdhock/interactive-tutorial)|
|<img src="/assets/img/publications/thumb/Hocking2015breakpointError.png" width="150" /> |In progress |Hocking TD                                                                                                                                                                                                                                                                                                                                                                                                                      |A breakpoint detection error function for segmentation model selection and validation                                     |Preprint arXiv:1509.00368                                                                                                                                  |[Preprint](https://arxiv.org/abs/1509.00368), [Software](http://r-forge.r-project.org/scm/?group_id=1540), [Reproducible](https://github.com/tdhock/breakpointError-orig)|
|<img src="/assets/img/publications/thumb/Venuto2014support.png" width="150" />          |In progress |Venuto D, Hocking TD, Sphanurattana L, Sugiyama M                                                                                                                                                                                                                                                                                                                                                                               |Support vector comparison machines                                                                                        |Preprint arXiv:1401.8008                                                                                                                                   |[Preprint](https://arxiv.org/abs/1401.8008), [Software](https://github.com/tdhock/rankSVMcompare), [Reproducible](https://github.com/tdhock/compare-paper)|
|<img src="/assets/img/publications/thumb/Bodine2024mapping.png" width="150" />          |2024        |Bodine CS, Buscombe D, Hocking TD                                                                                                                                                                                                                                                                                                                                                                                               |Automated River Substrate Mapping From Sonar Imagery With Machine Learning                                                |Journal of Geophysical Research: Machine Learning and Computation 1(3)                                                                                     |[DOI](https://doi.org/10.1029/2024JH000135), [Preprint](https://eartharxiv.org/repository/view/6448/), [Software](https://github.com/CameronBodine/PINGMapper)|
|<img src="/assets/img/publications/thumb/Kaufman2024functional.png" width="150" />      |2024        |Kaufman JM, Stenberg AJ, Hocking TD                                                                                                                                                                                                                                                                                                                                                                                             |Functional Labeled Optimal Partitioning                                                                                   |Journal of Computational and Graphical Statistics, DOI: 10 . 1080/10618600 . 2023 . 2293216                                                                |[DOI](https://doi.org/10.1080/10618600.2023.2293216), [Preprint](https://arxiv.org/abs/2210.02580), [Software](https://github.com/tdhock/FLOPART), [Reproducible](https://github.com/jkaufy/Flopart-Paper), [Preliminary code](https://github.com/tdhock/LabeledFPOP-paper)|
|<img src="/assets/img/publications/thumb/Tao2024reply.png" width="150" />               |2024        |Tao F, Houlton BZ, Frey SD, Lehmann J, Manzoni S, Huang Y, Jiang L, Mishra U, Hungate BA, Schmidt MWI, Reichstein M, Carvalhais N, Ciais P, Wang Y-P, Ahrens B, Hugelius G, Hocking TD, Lu X, Shi Z, Viatkin K, Vargas R, Yigini Y, Omuto C, Malik AA, Peralta G, Cuevas-Corona R, Paolo LED, Luotto I, Liao C, Liang Y-S, Saynes VS, Huang X, Luo Y                                                                            |Reply to: Model uncertainty obscures major driver of soil carbon                                                          |Nature 627(8002)                                                                                                                                           |[Publisher](https://www.nature.com/articles/s41586-023-07000-9), [Preprint](https://eartharxiv.org/repository/view/6125/)|
|                                                                                        |2023        |Harshe K, Williams JR, Hocking TD, Lerner ZF                                                                                                                                                                                                                                                                                                                                                                                    |Predicting Neuromuscular Engagement to Improve Gait Training With a Robotic Ankle Exoskeleton                             |IEEE Robotics and Automation Letters 8(8)                                                                                                                  |[Publisher](https://ieeexplore.ieee.org/document/10172008)                                            |
|<img src="/assets/img/publications/thumb/Hillman2023jmlr.png" width="150" />            |2023        |Hillman J, Hocking TD                                                                                                                                                                                                                                                                                                                                                                                                           |Optimizing ROC Curves with a Sort-Based Surrogate Loss for Binary Classification and Changepoint Detection                |Journal of Machine Learning Research 24(70)                                                                                                                |[Publisher](https://jmlr.org/papers/v24/21-0751.html), [Preprint](https://arxiv.org/abs/2107.01285), [Software](https://github.com/tdhock/aum), [Reproducible](https://github.com/tdhock/max-generalized-auc)|
|<img src="/assets/img/publications/thumb/Hocking2023lopart.png" width="150" />          |2023        |Hocking TD, Srivastava A                                                                                                                                                                                                                                                                                                                                                                                                        |Labeled optimal partitioning                                                                                              |Computational Statistics 38                                                                                                                                |[Publisher](https://rdcu.be/cQ8qM), [Preprint](https://arxiv.org/abs/2006.13967), [Video](https://www.youtube.com/watch?v=lm_6_33zOWc), [Software](https://github.com/tdhock/LOPART), [Reproducible](https://github.com/tdhock/LOPART-paper)|
|<img src="/assets/img/publications/thumb/Runge2023jss.png" width="150" />               |2023        |Runge V, Hocking TD, Romano G, Afghah F, Fearnhead P, Rigaill G                                                                                                                                                                                                                                                                                                                                                                 |gfpop: An R Package for Univariate Graph-Constrained Change-Point Detection                                               |Journal of Statistical Software 106(6)                                                                                                                     |[Publisher](https://www.jstatsoft.org/article/view/v106i06), [Preprint](https://arxiv.org/abs/2002.03646), [Software](https://github.com/vrunge/gfpop), [GUI](https://github.com/julianstanley/gfpopgui), [Reproducible](https://github.com/vrunge/gfpop/blob/master/vignettes/applications.Rmd)|
|                                                                                        |2023        |Sweeney N, Xu C, Shaw JA, Hocking TD, Whitaker BM                                                                                                                                                                                                                                                                                                                                                                               |Insect Identification in Pulsed Lidar Images Using Changepoint Detection Algorithms                                       |2023 Intermountain Engineering, Technology and Computing (IETC)                                                                                            |[Publisher](https://ieeexplore.ieee.org/abstract/document/10152205)                                   |
|<img src="/assets/img/publications/thumb/Tao2023nature.png" width="150" />              |2023        |Tao F, Huang Y, Hungate BA, Manzoni S, Frey SD, Schmidt MWI, Reichstein M, Carvalhais N, Ciais P, Jiang L, Lehmann J, Mishra U, Hugelius G, Hocking TD, Lu X, Shi Z, Viatkin K, Vargas R, Yigini Y, Omuto C, Malik AA, Perualta G, Cuevas-Corona R, Paolo LED, Luotto I, Liao C, Liang Y-S, Saynes VS, Huang X, Luo Y                                                                                                           |Microbial carbon use efficiency promotes global soil carbon storage                                                       |Nature 618                                                                                                                                                 |[Publisher](https://www.nature.com/articles/s41586-023-06042-3)                                       |
|                                                                                        |2022        |Barnwal A, Cho H, Hocking T                                                                                                                                                                                                                                                                                                                                                                                                     |Survival Regression with Accelerated Failure Time Model in XGBoost                                                        |Journal of Computational and Graphical Statistics 31(4)                                                                                                    |[Publisher](https://www.tandfonline.com/doi/full/10.1080/10618600.2022.2067548), [Preprint](https://arxiv.org/abs/2006.04920), [Software](https://github.com/dmlc/xgboost), [Documentation](https://xgboost.readthedocs.io/en/latest/tutorials/aft_survival_analysis.html), [Video](https://www.youtube.com/watch?v=HuWRnzgGuIo), [Reproducible](https://github.com/avinashbarnwal/aftXgboostPaper/)|
|                                                                                        |2022        |Barr JR, Hocking TD, Morton G, Thatcher T, Shaw P                                                                                                                                                                                                                                                                                                                                                                               |Classifying Imbalanced Data with AUM Loss                                                                                 |2022 Fourth International Conference on Transdisciplinary AI (TransAI)                                                                                     |[Publisher](https://ieeexplore.ieee.org/document/9951523)                                             |
|                                                                                        |2022        |Barr JR, Shaw P, Abu-Khzam FN, Thatcher T, Hocking TD                                                                                                                                                                                                                                                                                                                                                                           |Graph embedding: A methodological survey                                                                                  |2022 fourth international conference on transdisciplinary AI (TransAI)                                                                                     |[Publisher](https://ieeexplore.ieee.org/document/9951469/)                                            |
|                                                                                        |2022        |Chaves AP, Egbert J, Hocking T, Doerry E, Gerosa MA                                                                                                                                                                                                                                                                                                                                                                             |Chatbots Language Design: The Influence of Language Variation on User Experience with Tourist Assistant Chatbots          |ACM Trans. Comput.-Hum. Interact. 29(2)                                                                                                                    |[Publisher](https://dl.acm.org/doi/10.1145/3487193), [Preprint](https://arxiv.org/abs/2101.11089)     |
|<img src="/assets/img/publications/thumb/Hocking22intro.png" width="150" />             |2022        |Hocking TD                                                                                                                                                                                                                                                                                                                                                                                                                      |Introduction to machine learning and neural networks                                                                      |Chapter in Land Carbon Cycle Modeling: Matrix Approach, Data Assimilation, and Ecological Forecasting, edited by Yiqi Luo, published by Taylor and Francis |[Publisher](https://www.taylorfrancis.com/books/oa-edit/10.1201/9780429155659/land-carbon-cycle-modeling-yiqi-luo-benjamin-smith), [My chapter](https://raw.githubusercontent.com/tdhock/2020-yiqi-summer-school/master/HOCKING-chapter.pdf), [Reproducible](https://github.com/tdhock/2020-yiqi-summer-school#prepared-for-the-summer-school-4th-year-2021)|
|                                                                                        |2022        |Hocking TD, Barr JR, Thatcher T                                                                                                                                                                                                                                                                                                                                                                                                 |Interpretable linear models for predicting security vulnerabilities in source code                                        |2022 Fourth International Conference on Transdisciplinary AI (TransAI)                                                                                     |[Publisher](https://ieeexplore.ieee.org/document/9951610/)                                            |
|<img src="/assets/img/publications/thumb/Hocking2022jss.png" width="150" />             |2022        |Hocking TD, Rigaill G, Fearnhead P, Bourque G                                                                                                                                                                                                                                                                                                                                                                                   |Generalized Functional Pruning Optimal Partitioning (GFPOP) for Constrained Changepoint Detection in Genomic Data         |Journal of Statistical Software 101(10)                                                                                                                    |[Publisher](https://www.jstatsoft.org/article/view/v101i10), [Software](https://github.com/tdhock/PeakSegDisk), [Reproducible](https://github.com/tdhock/PeakSegFPOP-paper), [Slides](http://www.user2019.fr/static/pres/t257847.pdf), [Video](https://www.youtube.com/watch?v=XlC4WCqsbuI)|
|<img src="/assets/img/publications/thumb/Mihaljevic2022sparsemodr.png" width="150" />   |2022        |Mihaljevic JR, Borkovec S, Ratnavale S, Hocking TD, Banister KE, Eppinger JE, Hepp C, Doerry E                                                                                                                                                                                                                                                                                                                                  |SPARSEMODr: Rapidly simulate spatially explicit and stochastic models of COVID-19 and other infectious diseases           |Biology Methods and Protocols 7(1)                                                                                                                         |[Publisher](https://academic.oup.com/biomethods/advance-article/doi/10.1093/biomethods/bpac022/6680179), [Preprint](https://www.medrxiv.org/content/10.1101/2021.05.13.21256216v1), [Software](https://github.com/NAU-CCL/SPARSEMODr)|
|                                                                                        |2022        |Vargovich J, Hocking TD                                                                                                                                                                                                                                                                                                                                                                                                         |Linear time dynamic programming for computing breakpoints in the regularization path of models selected from a finite set |Journal of Computational and Graphical Statistics 31(2)                                                                                                    |[Publisher](https://amstat.tandfonline.com/doi/full/10.1080/10618600.2021.2000422), [Preprint](https://arxiv.org/abs/2003.02808), [Software](https://github.com/tdhock/penaltyLearning), [Reproducible](https://github.com/tdhock/changepoint-data-structure#source-code-for-figures-in-paper)|
|<img src="/assets/img/publications/thumb/Abraham2021gut.png" width="150" />             |2021        |Abraham AJ, Prys-Jones TO, De Cuyper A, Ridenour C, Hempson GP, Hocking T, Clauss M, Doughty CE                                                                                                                                                                                                                                                                                                                                 |Improved estimation of gut passage time considerably affects trait-based dispersal models                                 |Functional Ecology 35(4)                                                                                                                                   |[Publisher](https://besjournals.onlinelibrary.wiley.com/doi/10.1111/1365-2435.13726)                  |
|<img src="/assets/img/publications/thumb/Fotoohinasab2021greedy.png" width="150" />     |2021        |Fotoohinasab A, Hocking T, Afghah F                                                                                                                                                                                                                                                                                                                                                                                             |A greedy graph search algorithm based on changepoint analysis for automatic QRS complex detection                         |Computers in Biology and Medicine 130                                                                                                                      |[Publisher](https://www.sciencedirect.com/science/article/pii/S0010482521000020), [Preprint](https://arxiv.org/abs/2004.13558)|
|<img src="/assets/img/publications/thumb/Hocking2021reshaping.png" width="150" />       |2021        |Hocking TD                                                                                                                                                                                                                                                                                                                                                                                                                      |Wide-to-tall Data Reshaping Using Regular Expressions and the nc Package                                                  |The R Journal 13(1)                                                                                                                                        |[Publisher](https://journal.r-project.org/archive/2021/RJ-2021-029/index.html), [Software](https://github.com/tdhock/nc), [Reproducible](https://github.com/tdhock/nc-article)|
|                                                                                        |2021        |Kolla AC, Groce A, Hocking TD                                                                                                                                                                                                                                                                                                                                                                                                   |Fuzz Testing the Compiled Code in R Packages                                                                              |2021 IEEE 32nd International Symposium on Software Reliability Engineering (ISSRE)                                                                         |[Publisher](https://ieeexplore.ieee.org/document/9700272), [Software](https://github.com/akhikolla/RcppDeepState), [GitHub Action](https://github.com/FabrizioSandri/RcppDeepState-action), [Abstract](https://www.conftool.org/user2021/index.php?page=browseSessions&form_session=9#paperID123), [Video](https://www.youtube.com/watch?v=LXyruwSo2K0&t=245s), [Blog](https://akhikolla.github.io), [Results](https://akhikolla.github.io/packages-folders/)|
|<img src="/assets/img/publications/thumb/Liehrmann2021chipseq.png" width="150" />       |2021        |Liehrmann A, Rigaill G, Hocking TD                                                                                                                                                                                                                                                                                                                                                                                              |Increased peak detection accuracy in over-dispersed ChIP-seq data with supervised segmentation models                     |BMC Bioinformatics 22(323)                                                                                                                                 |[Publisher](https://bmcbioinformatics.biomedcentral.com/articles/10.1186/s12859-021-04221-5), [Reproducible](https://github.com/aLiehrmann/ChIP_SEQ_segmentation_paper), [Software](https://github.com/aliehrmann/crocs)|
|                                                                                        |2020        |Fotoohinasab A, Hocking T, Afghah F                                                                                                                                                                                                                                                                                                                                                                                             |A Graph-Constrained Changepoint Learning Approach for Automatic QRS-Complex Detection                                     |2020 54th Asilomar Conference on Signals, Systems, and Computers                                                                                           |[Publisher](https://ieeexplore.ieee.org/document/9443307), [Abstract](https://www2.securecms.com/Asilomar2020/Papers/ViewPapers.asp?PaperNum=1323),  [Preprint](https://arxiv.org/abs/2004.13558)|
|                                                                                        |2020        |Fotoohinasab A, Hocking T, Afghah F                                                                                                                                                                                                                                                                                                                                                                                             |A Graph-constrained Changepoint Detection Approach for ECG Segmentation                                                   |2020 42nd Annual International Conference of the IEEE Engineering in Medicine Biology Society (EMBC)                                                       |[Publisher](https://ieeexplore.ieee.org/document/9175333)                                             |
|<img src="/assets/img/publications/thumb/Hocking2020psb.png" width="150" />             |2020        |Hocking TD, Bourque G                                                                                                                                                                                                                                                                                                                                                                                                           |Machine Learning Algorithms for Simultaneous Supervised Detection of Peaks in Multiple Samples and Cell Types             |Proc. Pacific Symposium on Biocomputing                                                                                                                    |[Publisher](http://psb.stanford.edu/psb-online/proceedings/psb20/Hocking.pdf), [Software](https://github.com/tdhock/PeakSegJoint), [Preprint](https://arxiv.org/abs/1506.01286), [Reproducible](https://github.com/tdhock/PeakSegJoint-paper)|
|<img src="/assets/img/publications/thumb/Hocking2020jmlr.png" width="150" />            |2020        |Hocking TD, Rigaill G, Fearnhead P, Bourque G                                                                                                                                                                                                                                                                                                                                                                                   |Constrained Dynamic Programming and Supervised Penalty Learning Algorithms for Peak Detection in Genomic Data             |Journal of Machine Learning Research 21(87)                                                                                                                |[Publisher](http://jmlr.org/papers/v21/18-843.html), [Preprint](https://arxiv.org/abs/1703.03352), [Software](https://github.com/tdhock/PeakSegOptimal), [Reproducible](https://github.com/tdhock/PeakSegFPOP-paper)|
|<img src="/assets/img/publications/thumb/Hocking2019regex.png" width="150" />           |2019        |Hocking TD                                                                                                                                                                                                                                                                                                                                                                                                                      |Comparing namedCapture with other R packages for regular expressions                                                      |The R Journal 11(2)                                                                                                                                        |[Publisher](https://journal.r-project.org/archive/2019/RJ-2019-050/index.html), [Software](https://github.com/tdhock/namedCapture), [Reproducible](https://github.com/tdhock/namedCapture-article)|
|<img src="/assets/img/publications/thumb/Jewell2019biostatistics.png" width="150" />    |2019        |Jewell SW, Hocking TD, Fearnhead P, Witten DM                                                                                                                                                                                                                                                                                                                                                                                   |Fast nonconvex deconvolution of calcium imaging data                                                                      |Biostatistics 21(4)                                                                                                                                        |[Pubmed](https://www.ncbi.nlm.nih.gov/pubmed/30753436)                                                |
|                                                                                        |2019        |Sievert C, VanderPlas S, Cai J, Ferris K, Khan FUF, Hocking TD                                                                                                                                                                                                                                                                                                                                                                  |Extending ggplot2 for Linked and Animated Web Graphics                                                                    |Journal of Computational and Graphical Statistics 28(2)                                                                                                    |[Publisher](https://amstat.tandfonline.com/doi/full/10.1080/10618600.2018.1513367), [Manual](https://rcdata.nau.edu/genomic-ml/animint2-manual/Ch02-ggplot2.html), [Software](https://github.com/tdhock/animint), [Reproducible](https://github.com/tdhock/animint-paper), [Interactive Figures](https://rcdata.nau.edu/genomic-ml/public_html/animint-paper-figures/)|
|<img src="/assets/img/publications/thumb/Alirezaie2018clinpred.png" width="150" />      |2018        |Alirezaie N, Kernohan KD, Hartley T, Majewski J, Hocking TD                                                                                                                                                                                                                                                                                                                                                                     |ClinPred: Prediction Tool to Identify Disease-Relevant Nonsynonymous Single-Nucleotide Variants                           |The American Journal of Human Genetics 103(4)                                                                                                              |[DOI](https://doi.org/10.1016/j.ajhg.2018.08.005), [Software](http://github.com/tdhock/predict-clinically-pathogenic), [used in dbNSFP](https://sites.google.com/site/jpopgen/dbNSFP)|
|<img src="/assets/img/publications/thumb/Depuydt2018genomic.png" width="150" />         |2018        |Depuydt P, Boeva V, Hocking TD, Cannoodt R, Ambros IM, Ambros PF, Asgharzadeh S, Attiyeh EF, Combaret Vé, Defferrari R, Fischer M, Hero B, Hogarty MD, Irwin MS, Koster J, Kreissman S, Ladenstein R, Lapouble E, Laureys Gè, London WB, Mazzocco K, Nakagawara A, Noguera R, Ohira M, Park JR, Pötschger U, Theissen J, Tonini GP, Valteau-Couanet D, Varesio L, Versteeg R, Speleman F, Maris JM, Schleiermacher G, Preter KD |Genomic amplifications and distal 6q loss: novel markers for poor survival in high-risk neuroblastoma patients            |JNCI: Journal of the National Cancer Institute 110(10)                                                                                                     |[Publisher](https://academic.oup.com/jnci/advance-article/doi/10.1093/jnci/djy022/4921185)            |
|<img src="/assets/img/publications/thumb/Depuydt2018meta.png" width="150" />            |2018        |Depuydt P, Koster J, Boeva V, Hocking TD, Speleman F, Schleiermacher G, De Preter K                                                                                                                                                                                                                                                                                                                                             |Meta-mining of copy number profiles of high-risk neuroblastoma tumors                                                     |Scientific data 5(1)                                                                                                                                       |[Publisher](https://www.nature.com/articles/sdata2018240)                                             |
|<img src="/assets/img/publications/thumb/Drouin2017mmit.png" width="150" />             |2017        |Drouin A, Hocking T, Laviolette F                                                                                                                                                                                                                                                                                                                                                                                               |Maximum Margin Interval Trees                                                                                             |Advances in Neural Information Processing Systems 30                                                                                                       |[Publisher](http://papers.nips.cc/paper/7080-maximum-margin-interval-trees), [Software](https://github.com/aldro61/mmit), [Reproducible](https://github.com/tdhock/mmit-paper), [Preprint](https://arxiv.org/abs/1710.04234), [Video](https://www.youtube.com/watch?v=sNrMH9z1rb4)|
|<img src="/assets/img/publications/thumb/Hocking2017bioinfo.png" width="150" />         |2017        |Hocking TD, Goerner-Potvin P, Morin A, Shao X, Pastinen T, Bourque G                                                                                                                                                                                                                                                                                                                                                            |Optimizing ChIP-seq peak detectors using visual labels and supervised machine learning                                    |Bioinformatics 33(4)                                                                                                                                       |[Pubmed](https://www.ncbi.nlm.nih.gov/pubmed/27797775), [Software](https://github.com/tdhock/PeakError), [Reproducible](https://bitbucket.org/mugqic/chip-seq-paper), [Data](https://rcdata.nau.edu/genomic-ml/chip-seq-chunk-db/)|
|<img src="/assets/img/publications/thumb/Maidstone2017optimal.png" width="150" />       |2017        |Maidstone R, Hocking T, Rigaill G, Fearnhead P                                                                                                                                                                                                                                                                                                                                                                                  |On optimal multiple changepoint algorithms for large data                                                                 |Statistics and Computing 27                                                                                                                                |[Publisher](https://link.springer.com/article/10.1007/s11222-016-9636-3), [Software](https://r-forge.r-project.org/R/?group_id=1851), [Reproducible](https://r-forge.r-project.org/scm/viewvc.php/benchmark/?root=opfp)|
|<img src="/assets/img/publications/thumb/Chicard2016cancer.png" width="150" />          |2016        |Chicard M, Boyault S, Colmet Daage L, Richer W, Gentien D, Pierron G, Lapouble E, Bellini A, Clement N, Iacono I, Bréjon Sé, Carrere M, Reyes Cé, Hocking T, Bernard V, Peuchmaur M, Corradini Nè, Faure-Conter Cé, Coze C, Plantaz D, Defachelles AS, Thebaud E, Gambart M, Millot Féé, Valteau-Couanet D, Michon J, Puisieux A, Delattre O, Combaret Vé, Schleiermacher G                                                     |Genomic Copy Number Profiling Using Circulating Free Tumor DNA Highlights Heterogeneity in Neuroblastoma                  |Clinical Cancer Research 22(22)                                                                                                                            |[Publisher](http://clincancerres.aacrjournals.org/content/early/2016/11/03/1078-0432.CCR-16-0500)     |
|                                                                                        |2016        |Shimada K, Shimada S, Sugimoto K, Nakatochi M, Suguro M, Hirakawa A, Hocking TD, Takeuchi I, Tokunaga T, Takagi Y, Sakamoto A, Aoki T, Naoe T, Nakamura S, Hayakawa F, Seto M, Tomita A, Kiyoi H                                                                                                                                                                                                                                |Development and analysis of patient-derived xenograft mouse models in intravascular large B-cell lymphoma                 |Leukemia 30(7)                                                                                                                                             |[Pubmed](https://www.ncbi.nlm.nih.gov/pubmed/27001523)                                                |
|<img src="/assets/img/publications/thumb/Hocking2015icml.png" width="150" />            |2015        |Hocking TD, Rigaill G, Bourque G                                                                                                                                                                                                                                                                                                                                                                                                |PeakSeg: constrained optimal segmentation and supervised penalty learning for peak detection in count data                |Proc. 32nd ICML                                                                                                                                            |[Publisher](http://proceedings.mlr.press/v37/hocking15.html), [Video](http://videolectures.net/icml2015_hocking_count_data/?q=hocking), [Software](https://github.com/tdhock/PeakSegDP), [Reproducible](https://github.com/tdhock/PeakSeg-paper)|
|<img src="/assets/img/publications/thumb/Hocking2014bioinformatics.png" width="150" />  |2014        |Hocking TD, Boeva V, Rigaill G, Schleiermacher G, Janoueix-Lerosey I, Delattre O, Richer W, Bourdeaut F, Suguro M, Seto M, Bach F, Vert JP                                                                                                                                                                                                                                                                                      |SegAnnDB: interactive Web-based genomic segmentation                                                                      |Bioinformatics 30(11)                                                                                                                                      |[Pubmed](http://www.ncbi.nlm.nih.gov/pubmed/24493034), [Software](https://github.com/tdhock/SegAnnDB), [Reproducible](https://gforge.inria.fr/scm/viewvc.php/breakpoints/webapp/applications-note/), [Preprint](https://hal.inria.fr/hal-00759129), [Package](https://r-forge.r-project.org/scm/?group_id=1541), [Reproducible](https://gforge.inria.fr/scm/viewvc.php/pruned-dp/SegAnnot/inst/doc/?root=breakpoints)|
|<img src="/assets/img/publications/thumb/Suguro2014cancer.png" width="150" />           |2014        |Suguro M, Yoshida N, Umino A, Kato H, Tagawa H, Nakagawa M, Fukuhara N, Karnan S, Takeuchi I, Hocking TD, Arita K, Karube K, Tsuzuki S, Nakamura S, Kinoshita T, Seto M                                                                                                                                                                                                                                                         |Clonal heterogeneity of lymphoid malignancies correlates with poor prognosis                                              |Cancer Sci 105(7)                                                                                                                                          |[Pubmed](http://www.ncbi.nlm.nih.gov/pubmed/24815991)                                                 |
|<img src="/assets/img/publications/thumb/Hocking2013bioinformatics.png" width="150" />  |2013        |Hocking TD, Schleiermacher G, Janoueix-Lerosey I, Boeva V, Cappo J, Delattre O, Bach F, Vert J-P                                                                                                                                                                                                                                                                                                                                |Learning smoothing models of copy number profiles using breakpoint annotations                                            |BMC Bioinformatics 14(164)                                                                                                                                 |[Publisher](https://bmcbioinformatics.biomedcentral.com/articles/10.1186/1471-2105-14-164), [Software](https://cran.r-project.org/src/contrib/Archive/bams/), [Reproducible](https://rcdata.nau.edu/genomic-ml/public_html/papers/2012-01-27-Breakpoint-annotation-model-smoothing/HOCKING-breakpoint-annotation-model-smoothing.tgz)|
|<img src="/assets/img/publications/thumb/Hocking2013sustainable.png" width="150" />     |2013        |Hocking TD, Wutzler T, Ponting K, Grosjean P                                                                                                                                                                                                                                                                                                                                                                                    |Sustainable, Extensible Documentation Generation using inlinedocs                                                         |Journal of Statistical Software 54                                                                                                                         |[Publisher](https://www.jstatsoft.org/article/view/v054i06), [Software](https://cran.r-project.org/package=inlinedocs), [Reproducible](https://r-forge.r-project.org/scm/viewvc.php/tex/jss762/?root=inlinedocs)|
|<img src="/assets/img/publications/thumb/Hocking2013icml.png" width="150" />            |2013        |Rigaill G, Hocking T, Vert J-P, Bach F                                                                                                                                                                                                                                                                                                                                                                                          |Learning sparse penalties for change-point detection using max margin interval regression                                 |Proc. 30th ICML                                                                                                                                            |[Publisher](http://proceedings.mlr.press/v28/hocking13.html), [Video](http://techtalks.tv/talks/learning-sparse-penalties-for-change-point-detection-using-max-margin-interval-regression/58208/), [Software](https://github.com/tdhock/penaltyLearning), [Reproducible](https://gforge.inria.fr/scm/viewvc.php/pruned-dp/?root=breakpoints)|
|<img src="/assets/img/publications/thumb/Hocking2012phd.png" width="150" />             |2012        |Hocking TD                                                                                                                                                                                                                                                                                                                                                                                                                      |Learning algorithms and statistical software, with applications to bioinformatics                                         |PHD thesis, Ecole normale supérieure de Cachan                                                                                                             |[Publisher](https://tel.archives-ouvertes.fr/tel-00906029/), [Reproducible](https://rcdata.nau.edu/genomic-ml/public_html/papers/2012-11-20-PhD-thesis/HOCKING-phd-thesis.tgz)|
|<img src="/assets/img/publications/thumb/Hocking2011clusterpath.png" width="150" />     |2011        |Hocking TD, Joulin A, Bach F, Vert J-P                                                                                                                                                                                                                                                                                                                                                                                          |Clusterpath an algorithm for clustering using convex fusion penalties                                                     |28th international conference on machine learning                                                                                                          |[Publisher](http://www.icml-2011.org/papers/419_icmlpaper.pdf), [Video](http://techtalks.tv/talks/clusterpath-an-algorithm-for-clustering-using-convex-fusion-penalties/54405/), [Software](https://r-forge.r-project.org/scm/?group_id=1090), [Reproducible](https://r-forge.r-project.org/scm/viewvc.php/tex/?root=clusterpath), [Cited in Ihaka lecture](https://www.youtube.com/watch?v=2g-akN6q8aI)|
|<img src="/assets/img/publications/thumb/Gautier2010bayesian.png" width="150" />        |2010        |Gautier M, Hocking TD, Foulley J-L                                                                                                                                                                                                                                                                                                                                                                                              |A Bayesian outlier criterion to detect SNPs under selection in large data sets                                            |PLoS one 5(8)                                                                                                                                              |[Publisher](http://journals.plos.org/plosone/article?id=10.1371/journal.pone.0011913)                 |
|<img src="/assets/img/publications/thumb/Doyon2008heritable.png" width="150" />         |2008        |Doyon Y, McCammon JM, Miller JC, Faraji F, Ngo C, Katibah GE, Amora R, Hocking TD, Zhang L, Rebar EJ, Gregory PD, Urnov FD, Amacher SL                                                                                                                                                                                                                                                                                          |Heritable targeted gene disruption in zebrafish using designed zinc-finger nucleases                                      |Nature biotechnology 26(6)                                                                                                                                 |[Pubmed](http://www.ncbi.nlm.nih.gov/pubmed/18500334)                                                 |

The output above is a table with one row per publication, and an image column that shows a figure from the paper.
The trick to getting that to display, is putting it in this repo, with a standard name, based on the bib file key.

The code below checks for missing figures.


``` r
some.out[figure=='', title]
```

```
## Error in process_file(text, output): Object 'figure' not found. Perhaps you intended [Figure]
```

## Make sure pdflatex likes it

This part only works in Rmd, not md/jekyll for some reason.



## Report mis-match between image files and refs


``` r
img.dt <- data.table(ref=sub(".png", "", dir("../assets/img/publications/")))
img.dt[!refs.wide,on="ref"] #images without bib entries
```

```
##       ref
##    <char>
## 1:  thumb
```

``` r
refs.wide[!img.dt,.(ref),on="ref"] #bib entries without images
```

```
##                                               ref
##                                            <char>
##  1:                               Barnwal2022jcgs
##  2:                             Chaves2022chatbot
##  3:                         Harshe2023exoskeleton
##  4:                           Shimada2016leukemia
##  5:                               Sievert2019jcgs
##  6:                      Vargovich2022breakpoints
##  7: Fotoohinasab2020automaticQRSdetectionAsilomar
##  8:              Fotoohinasab2020segmentationEMBC
##  9:                                 Kolla2021fuzz
## 10:                             Sweeney2023insect
## 11:                           barr2022classifying
## 12:                                 barr2022graph
## 13:                      hocking2022interpretable
## 14:                               Gurney2024power
## 15:                            Thibault2024forest
```

## Conclusion

We have seen how a bib file can be used to define a publications web page.

## Session info


``` r
sessionInfo()
```

```
## R version 4.4.1 (2024-06-14)
## Platform: x86_64-pc-linux-gnu
## Running under: Ubuntu 22.04.4 LTS
## 
## Matrix products: default
## BLAS:   /usr/lib/x86_64-linux-gnu/blas/libblas.so.3.10.0 
## LAPACK: /usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.10.0
## 
## locale:
##  [1] LC_CTYPE=fr_FR.UTF-8       LC_NUMERIC=C               LC_TIME=fr_FR.UTF-8        LC_COLLATE=fr_FR.UTF-8    
##  [5] LC_MONETARY=fr_FR.UTF-8    LC_MESSAGES=fr_FR.UTF-8    LC_PAPER=fr_FR.UTF-8       LC_NAME=C                 
##  [9] LC_ADDRESS=C               LC_TELEPHONE=C             LC_MEASUREMENT=fr_FR.UTF-8 LC_IDENTIFICATION=C       
## 
## time zone: America/New_York
## tzcode source: system (glibc)
## 
## attached base packages:
## [1] stats     graphics  utils     datasets  grDevices methods   base     
## 
## other attached packages:
## [1] nc_2024.8.15       testthat_3.2.1.1   data.table_1.15.99
## 
## loaded via a namespace (and not attached):
##  [1] miniUI_0.1.1.1    compiler_4.4.1    brio_1.1.4        promises_1.2.1    Rcpp_1.0.12       stringr_1.5.1    
##  [7] magick_2.8.4      later_1.3.2       fastmap_1.1.1     mime_0.12         R6_2.5.1          knitr_1.47       
## [13] htmlwidgets_1.6.4 desc_1.4.3        profvis_0.3.8     rprojroot_2.0.4   shiny_1.8.0       rlang_1.1.3      
## [19] cachem_1.0.8      stringi_1.8.3     xfun_0.45         httpuv_1.6.14     fs_1.6.3          pkgload_1.3.4    
## [25] memoise_2.0.1     cli_3.6.2         withr_3.0.0       magrittr_2.0.3    digest_0.6.34     rstudioapi_0.15.0
## [31] xtable_1.8-4      remotes_2.5.0     devtools_2.4.5    lifecycle_1.0.4   vctrs_0.6.5       evaluate_0.23    
## [37] glue_1.7.0        urlchecker_1.0.1  sessioninfo_1.2.2 pkgbuild_1.4.3    purrr_1.0.2       tools_4.4.1      
## [43] usethis_2.2.2     ellipsis_0.3.2    htmltools_0.5.7
```
