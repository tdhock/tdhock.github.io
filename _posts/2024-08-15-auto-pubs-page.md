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
##  chr [1:66] "@unpublished{Gurney2024power," "@unpublished{Nguyen2024," "@unpublished{Truong2024circular," ...
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
##  $ ref   : chr  "Gurney2024power" "Nguyen2024" "Truong2024circular" "Hocking2024cv" ...
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
##  chr [1:460] "  title={Assessment of the Climate Trace global powerplant CO2 emissions}," ...
```

Above we see 460 fields.

Below we parse the `fields` column:


``` r
strip <- function(x)gsub("^\\s*|,\\s*$", "", gsub('[{}"]', "", x))
field.pattern <- list(
  "\\s*",
  variable="\\S+", tolower,
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
##   5: unpublished         Nguyen2024     title
##  ---                                         
## 456:     article doyon2008heritable    volume
## 457:     article doyon2008heritable    number
## 458:     article doyon2008heritable     pages
## 459:     article doyon2008heritable      year
## 460:     article doyon2008heritable publisher
##                                                                                                                   value
##                                                                                                                  <char>
##   1:                                                    Assessment of the Climate Trace global powerplant CO2 emissions
##   2: Kevin Gurney and Bilal Aslam and Pawlok Dass and L Gawuc and Toby Dylan Hocking and Jarrett J Barber and Anna Kato
##   3:                                                                     Under review at Environmental Research Letters
##   4:                                                                                                               2024
##   5:                                   Deep Learning Approach for Changepoint Detection: Penalty Parameter Optimization
##  ---                                                                                                                   
## 456:                                                                                                                 26
## 457:                                                                                                                  6
## 458:                                                                                                           702--708
## 459:                                                                                                               2008
## 460:                                                                                Nature Publishing Group US New York
```

Above we see 460 fields, consistent with the simpler `grep` parsing above. 
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
## 456:    volume
## 457:    number
## 458:     pages
## 459:      year
## 460: publisher
##                                                                                                                   value
##                                                                                                                  <char>
##   1:                                                    Assessment of the Climate Trace global powerplant CO2 emissions
##   2: Kevin Gurney and Bilal Aslam and Pawlok Dass and L Gawuc and Toby Dylan Hocking and Jarrett J Barber and Anna Kato
##   3:                                                                     Under review at Environmental Research Letters
##   4:                                                                                                               2024
##   5:                                   Deep Learning Approach for Changepoint Detection: Penalty Parameter Optimization
##  ---                                                                                                                   
## 456:                                                                                                                 26
## 457:                                                                                                                  6
## 458:                                                                                                           702--708
## 459:                                                                                                               2008
## 460:                                                                                Nature Publishing Group US New York
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
## 28:       article   2008 Nature bio     26      6       <NA>       <NA>       <NA>
## 29:       article   2010   PLoS one      5      8       <NA>       <NA>       <NA>
## 30:       article   2023 IEEE Robot      8      8       <NA>       <NA>       <NA>
## 31:       article   2013 Journal of     54   <NA>       <NA>       <NA>       <NA>
## 32:       article   2024 Journal of   <NA>   <NA>       <NA>       <NA>       <NA>
## 33:       article   2022 Biology Me      7      1       <NA>       <NA>       <NA>
## 34:       article   2024     Nature    627   8002       <NA>       <NA>       <NA>
## 35:  incollection   2022       <NA>   <NA>   <NA> Land Carbo       <NA>       <NA>
## 36: inproceedings   2017       <NA>   <NA>   <NA> Advances i       <NA>       <NA>
## 37: inproceedings   2020       <NA>   <NA>   <NA> 2020 54th        <NA>       <NA>
## 38: inproceedings   2020       <NA>   <NA>   <NA> 2020 42nd        <NA>       <NA>
## 39: inproceedings   2013       <NA>   <NA>   <NA> Proc. 30th       <NA>       <NA>
## 40: inproceedings   2015       <NA>   <NA>   <NA> Proc. 32nd       <NA>       <NA>
## 41: inproceedings   2020       <NA>     25   <NA> Proc. Paci       <NA>       <NA>
## 42: inproceedings   2021       <NA>   <NA>   <NA> 2021 IEEE        <NA>       <NA>
## 43: inproceedings   2023       <NA>   <NA>   <NA> 2023 Inter       <NA>       <NA>
## 44: inproceedings   2022       <NA>   <NA>   <NA> 2022 Fourt       <NA>       <NA>
## 45: inproceedings   2022       <NA>   <NA>   <NA> 2022 fourt       <NA>       <NA>
## 46: inproceedings   2011       <NA>   <NA>   <NA> 28th inter       <NA>       <NA>
## 47: inproceedings   2022       <NA>   <NA>   <NA> 2022 Fourt       <NA>       <NA>
## 48:     phdthesis   2012       <NA>   <NA>   <NA>       <NA>       <NA> Ecole norm
## 49:   unpublished   2023       <NA>   <NA>   <NA>       <NA> Preprint a       <NA>
## 50:   unpublished   2024       <NA>   <NA>   <NA>       <NA> In progres       <NA>
## 51:   unpublished   2024       <NA>   <NA>   <NA>       <NA> Under revi       <NA>
## 52:   unpublished   2023       <NA>   <NA>   <NA>       <NA> In progres       <NA>
## 53:   unpublished   2024       <NA>   <NA>   <NA>       <NA> In progres       <NA>
## 54:   unpublished   2024       <NA>   <NA>   <NA>       <NA> In progres       <NA>
## 55:   unpublished   2024       <NA>   <NA>   <NA>       <NA> In progres       <NA>
## 56:   unpublished   2024       <NA>   <NA>   <NA>       <NA> In progres       <NA>
## 57:   unpublished   2024       <NA>   <NA>   <NA>       <NA> In progres       <NA>
## 58:   unpublished   2024       <NA>   <NA>   <NA>       <NA> In progres       <NA>
## 59:   unpublished   2024       <NA>   <NA>   <NA>       <NA> Preprint a       <NA>
## 60:   unpublished   2023       <NA>   <NA>   <NA>       <NA> Preprint a       <NA>
## 61:   unpublished   2024       <NA>   <NA>   <NA>       <NA> In progres       <NA>
## 62:   unpublished   2024       <NA>   <NA>   <NA>       <NA> In progres       <NA>
## 63:   unpublished   2017       <NA>   <NA>   <NA>       <NA> Tutorial a       <NA>
## 64:   unpublished   2015       <NA>   <NA>   <NA>       <NA> Preprint a       <NA>
## 65:   unpublished   2016       <NA>   <NA>   <NA>       <NA> Tutorial a       <NA>
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
## 28:       article   2008      Nature biotechnology 26(6)
## 29:       article   2010                   PLoS one 5(8)
## 30:       article   2023 ics and Automation Letters 8(8)
## 31:       article   2013 rnal of Statistical Software 54
## 32:       article   2024  1080/10618600 . 2023 . 2293216
## 33:       article   2022 logy Methods and Protocols 7(1)
## 34:       article   2024                Nature 627(8002)
## 35:  incollection   2022 published by Taylor and Francis
## 36: inproceedings   2017 formation Processing Systems 30
## 37: inproceedings   2020 Signals, Systems, and Computers
## 38: inproceedings   2020 dicine   Biology Society (EMBC)
## 39: inproceedings   2013                 Proc. 30th ICML
## 40: inproceedings   2015                 Proc. 32nd ICML
## 41: inproceedings   2020 cific Symposium on Biocomputing
## 42: inproceedings   2021 Reliability Engineering (ISSRE)
## 43: inproceedings   2023 Technology and Computing (IETC)
## 44: inproceedings   2022  Transdisciplinary AI (TransAI)
## 45: inproceedings   2022  transdisciplinary AI (TransAI)
## 46: inproceedings   2011  conference on machine learning
## 47: inproceedings   2022  Transdisciplinary AI (TransAI)
## 48:     phdthesis   2012 supérieure de Cachan-ENS Cachan
## 49:   unpublished   2023 er review at BMC Bioinformatics
## 50:   unpublished   2024                     In progress
## 51:   unpublished   2024  Environmental Research Letters
## 52:   unpublished   2023                     In progress
## 53:   unpublished   2024                     In progress
## 54:   unpublished   2024                     In progress
## 55:   unpublished   2024                     In progress
## 56:   unpublished   2024                     In progress
## 57:   unpublished   2024                     In progress
## 58:   unpublished   2024                     In progress
## 59:   unpublished   2024       Preprint arXiv:2408.00856
## 60:   unpublished   2023       Preprint arXiv:2302.11062
## 61:   unpublished   2024                     In progress
## 62:   unpublished   2024                     In progress
## 63:   unpublished   2017 onference, textbook in progress
## 64:   unpublished   2015       Preprint arXiv:1509.00368
## 65:   unpublished   2016 ernational useR 2016 conference
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
##                            ref             complete       given        family abbrev            show
##                         <char>               <char>      <char>        <char> <char>          <char>
##   1:               Abraham2021   Abraham, Andrew J.   Andrew J.       Abraham     AJ      Abraham AJ
##   2:               Abraham2021 Prys-Jones, Tomos O.    Tomos O.    Prys-Jones     TO   Prys-Jones TO
##   3:               Abraham2021  De Cuyper, Annelies    Annelies     De Cuyper      A     De Cuyper A
##   4:               Abraham2021      Ridenour, Chase       Chase      Ridenour      C      Ridenour C
##   5:               Abraham2021   Hempson, Gareth P.   Gareth P.       Hempson     GP      Hempson GP
##  ---                                                                                                
## 382: interactive-tutorial-2016 Ekstrøm, Claus Thorn Claus Thorn       Ekstrøm     CT      Ekstrøm CT
## 383:         venuto2014support            Venuto, D           D        Venuto      D        Venuto D
## 384:         venuto2014support          Hocking, TD          TD       Hocking     TD      Hocking TD
## 385:         venuto2014support     Sphanurattana, L           L Sphanurattana      L Sphanurattana L
## 386:         venuto2014support          Sugiyama, M           M      Sugiyama      M      Sugiyama M
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
##  1:                                   Abraham2021 Abraham AJ, Prys-Jones TO, De 
##  2:                                 Alirezaie2018 Alirezaie N, Kernohan KD, Hart
##  3:                               Barnwal2022jcgs    Barnwal A, Cho H, Hocking T
##  4:                              Bodine2024JGRMLC Bodine CS, Buscombe D, Hocking
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
## 28:                            doyon2008heritable Doyon Y, McCammon JM, Miller J
## 29:                           gautier2010bayesian Gautier M, Hocking TD, Foulley
## 30:                          harshe2023predicting Harshe K, Williams JR, Hocking
## 31:                        hocking2013sustainable Hocking TD, Wutzler T, Ponting
## 32:                         kaufman2024functional Kaufman JM, Stenberg AJ, Hocki
## 33:                      mihaljevic2022sparsemodr Mihaljevic JR, Borkovec S, Rat
## 34:                                  tao2024reply Tao F, Houlton BZ, Frey SD, Le
## 35:                                hocking22intro                     Hocking TD
## 36:                                    Drouin2017 Drouin A, Hocking T, Laviolett
## 37: Fotoohinasab2020automaticQRSdetectionAsilomar Fotoohinasab A, Hocking T, Afg
## 38:              Fotoohinasab2020segmentationEMBC Fotoohinasab A, Hocking T, Afg
## 39:                               Hocking2013icml Rigaill G, Hocking T, Vert J-P
## 40:                                   Hocking2015 Hocking TD, Rigaill G, Bourque
## 41:                                Hocking2020psb          Hocking TD, Bourque G
## 42:                                     Kolla2021  Kolla AC, Groce A, Hocking TD
## 43:                                   Sweeney2023 Sweeney N, Xu C, Shaw JA, Hock
## 44:                           barr2022classifying Barr JR, Hocking TD, Morton G,
## 45:                                 barr2022graph Barr JR, Shaw P, Abu-Khzam FN,
## 46:                        hocking2011clusterpath Hocking TD, Joulin A, Bach F, 
## 47:                      hocking2022interpretable Hocking TD, Barr JR, Thatcher 
## 48:                           hocking2012learning                     Hocking TD
## 49:                                  Agyapong2023 Agyapong D, Propster JR, Marks
## 50:                                Fowler2024line           Fowler J, Hocking TD
## 51:                               Gurney2024power Gurney K, Aslam B, Dass P, Gaw
## 52:                         Hocking2023functional                     Hocking TD
## 53:                             Hocking2024autism Sutherland V, Hocking TD, Lind
## 54:                             Hocking2024binary                     Hocking TD
## 55:                         Hocking2024binsegRcpp                     Hocking TD
## 56:                                 Hocking2024cv                     Hocking TD
## 57:                                Hocking2024hmm                     Hocking TD
## 58:                               Hocking2024soak Bodine CS, Thibault G, Arellan
## 59:                                    Nguyen2024           Nguyen T, Hocking TD
## 60:              Rust2023-all-pairs-squared-hinge            Rust KR, Hocking TD
## 61:                            Thibault2024forest Thibault G, Hocking TD, Achim 
## 62:                            Truong2024circular           Truong C, Hocking TD
## 63:                          change-tutorial-2017          Hocking TD, Killick R
## 64:                    hocking2015breakpointError                     Hocking TD
## 65:                     interactive-tutorial-2016         Hocking TD, Ekstrøm CT
## 66:                             venuto2014support Venuto D, Hocking TD, Sphanura
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
  heading = ifelse(type=="unpublished", "In Progress", year),
  citation = sprintf("- %s (%s). %s. %s. %s", authors_abbrev, year, title, venue, links)
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
- Bodine CS, Thibault G, Arellano PN, Shenkin AF, Lindly O, Hocking TD (2024). SOAK: Same/Other/All K-fold cross-validation for estimating similarity of patterns in data subsets. In progress. [Software](https://github.com/tdhock/mlr3resampling), [Reproducible](https://github.com/tdhock/cv-same-other-paper)
- Fowler J, Hocking TD (2024). Efficient line search for optimizing Area Under the ROC Curve in gradient descent. In progress. [Talk announcement for JSM'23 Toronto](https://ww2.aievolution.com/JSMAnnual/index.cfm?do=ev.viewEv&ev=2810), [Video of talk at Université Laval July 2023](https://www.youtube.com/watch?v=22ODpDTZ4VE), [Slides PDF](https://github.com/tdhock/max-generalized-auc/blob/master/HOCKING-slides-toronto.pdf), [source](https://github.com/tdhock/max-generalized-auc/#4-may-2023)

### 2024
- Bodine CS, Buscombe D, Hocking TD (2024). Automated River Substrate Mapping From Sonar Imagery With Machine Learning. Journal of Geophysical Research: Machine Learning and Computation 1(3). [Preprint eartharXiv:6448](https://eartharxiv.org/repository/view/6448/), [Software](https://github.com/CameronBodine/PINGMapper)
- Kaufman JM, Stenberg AJ, Hocking TD (2024). Functional Labeled Optimal Partitioning. Journal of Computational and Graphical Statistics, DOI: 10 . 1080/10618600 . 2023 . 2293216. NA

### 2023
- Harshe K, Williams JR, Hocking TD, Lerner ZF (2023). Predicting Neuromuscular Engagement to Improve Gait Training With a Robotic Ankle Exoskeleton. IEEE Robotics and Automation Letters 8(8). NA
- Hillman J, Hocking TD (2023). Optimizing ROC Curves with a Sort-Based Surrogate Loss for Binary Classification and Changepoint Detection. Journal of Machine Learning Research 24(70). NA
NULL

## Another output: markdown table with images

One advantage of this is that we can easily modify output formats.


``` r
some.out <- abbrev.some[, .(
  figure=sprintf(
    '<img src="/assets/img/publications/%s.png" width="150" />',
    ref),
  published=heading, authors_abbrev, title, venue, links)]
knitr::kable(some.out)
```



|figure                                                                       |published   |authors_abbrev                                                       |title                                                                                                      |venue                                                                                       |links                                                                                                 |
|:----------------------------------------------------------------------------|:-----------|:--------------------------------------------------------------------|:----------------------------------------------------------------------------------------------------------|:-------------------------------------------------------------------------------------------|:-----------------------------------------------------------------------------------------------------|
|<img src="/assets/img/publications/Hocking2024soak.png" width="150" />       |In Progress |Bodine CS, Thibault G, Arellano PN, Shenkin AF, Lindly O, Hocking TD |SOAK: Same/Other/All K-fold cross-validation for estimating similarity of patterns in data subsets         |In progress                                                                                 |[Software](https://github.com/tdhock/mlr3resampling), [Reproducible](https://github.com/tdhock/cv-same-other-paper)|
|<img src="/assets/img/publications/Fowler2024line.png" width="150" />        |In Progress |Fowler J, Hocking TD                                                 |Efficient line search for optimizing Area Under the ROC Curve in gradient descent                          |In progress                                                                                 |[Talk announcement for JSM'23 Toronto](https://ww2.aievolution.com/JSMAnnual/index.cfm?do=ev.viewEv&ev=2810), [Video of talk at Université Laval July 2023](https://www.youtube.com/watch?v=22ODpDTZ4VE), [Slides PDF](https://github.com/tdhock/max-generalized-auc/blob/master/HOCKING-slides-toronto.pdf), [source](https://github.com/tdhock/max-generalized-auc/#4-may-2023)|
|<img src="/assets/img/publications/Bodine2024JGRMLC.png" width="150" />      |2024        |Bodine CS, Buscombe D, Hocking TD                                    |Automated River Substrate Mapping From Sonar Imagery With Machine Learning                                 |Journal of Geophysical Research: Machine Learning and Computation 1(3)                      |[Preprint eartharXiv:6448](https://eartharxiv.org/repository/view/6448/), [Software](https://github.com/CameronBodine/PINGMapper)|
|<img src="/assets/img/publications/kaufman2024functional.png" width="150" /> |2024        |Kaufman JM, Stenberg AJ, Hocking TD                                  |Functional Labeled Optimal Partitioning                                                                    |Journal of Computational and Graphical Statistics, DOI: 10 . 1080/10618600 . 2023 . 2293216 |NA                                                                                                    |
|<img src="/assets/img/publications/harshe2023predicting.png" width="150" />  |2023        |Harshe K, Williams JR, Hocking TD, Lerner ZF                         |Predicting Neuromuscular Engagement to Improve Gait Training With a Robotic Ankle Exoskeleton              |IEEE Robotics and Automation Letters 8(8)                                                   |NA                                                                                                    |
|<img src="/assets/img/publications/Hillman2023.png" width="150" />           |2023        |Hillman J, Hocking TD                                                |Optimizing ROC Curves with a Sort-Based Surrogate Loss for Binary Classification and Changepoint Detection |Journal of Machine Learning Research 24(70)                                                 |NA                                                                                                    |

The output above is a table with one row per publication, and an image column that shows a figure from the paper.
The trick to getting that to display, is putting it in this repo, with a standard name, based on the bib file key.

## Make sure pdflatex likes it

This part only works in Rmd, not md/jekyll for some reason.



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
##  [7] later_1.3.2       fastmap_1.1.1     mime_0.12         R6_2.5.1          knitr_1.47        htmlwidgets_1.6.4
## [13] desc_1.4.3        profvis_0.3.8     rprojroot_2.0.4   shiny_1.8.0       rlang_1.1.3       cachem_1.0.8     
## [19] stringi_1.8.3     xfun_0.45         httpuv_1.6.14     fs_1.6.3          pkgload_1.3.4     memoise_2.0.1    
## [25] cli_3.6.2         withr_3.0.0       magrittr_2.0.3    digest_0.6.34     rstudioapi_0.15.0 xtable_1.8-4     
## [31] remotes_2.5.0     devtools_2.4.5    lifecycle_1.0.4   vctrs_0.6.5       evaluate_0.23     glue_1.7.0       
## [37] urlchecker_1.0.1  sessioninfo_1.2.2 pkgbuild_1.4.3    purrr_1.0.2       tools_4.4.1       usethis_2.2.2    
## [43] ellipsis_0.3.2    htmltools_0.5.7
```
