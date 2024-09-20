---
layout: post
title: Collaborations not allowed
description: Parsing a web page with regex
---



The goal of this post is to explore what countries and institutions are not allowed in collaborations with researchers in Canada.

## Introduction 

When applying for grants at my new job at Université de Sherbrooke in
Canada, I was asked to agree to not share research "secrets" with a
certain list of organizations, on a web page.  This is silly to ask of
most researchers, who publish in peer-reviewed journals/conferences
that are more or less publicly accessible for anyone. If anyone can
access my research, how can I prevent sharing with these
organizations? This makes me think of the McCarthy-era communist witch
hunt in the USA in the 1950s. Are we going to soon have to swear
loyalty, or renounce a certain idealogy, to continue our jobs at the
university? I find this dubious.

## Simple example

A good example of what the data look like is below:


``` r
some.html <- '
	<li><strong>A.A. Kharkevich Institute for Information Transmission Problems, IITP, Russian Academy of Sciences</strong> (Russia)</li>
	<li><strong>Academy of Military Medical Sciences</strong> (People’s Republic of China)
	<p>Known alias(es): AMMS</p>
	</li>
	<li><strong>Academy of Military Science</strong> (People’s Republic of China)
	<p>Known alias(es): AMS</p>
	</li>
	<li><strong>Aerospace Research Institute</strong> (Iran)
	<p>Known alias(es): ARI</p>
	</li>
'
```

We parse name in each block using the regex below,


``` r
name.pattern <- list(
  "\n\t<li><strong>",
  name=".*?",
  "</strong>")
nc::capture_all_str(
  some.html,
  name.pattern)
```

```
##                                                                                                  name
##                                                                                                <char>
## 1: A.A. Kharkevich Institute for Information Transmission Problems, IITP, Russian Academy of Sciences
## 2:                                                               Academy of Military Medical Sciences
## 3:                                                                        Academy of Military Science
## 4:                                                                       Aerospace Research Institute
```

The table above has four rows and one column.
We can add another column for country via the code below.


``` r
country.pattern <- list(
  " [(]",
  country=".*?",
  " *[)]")
nc::capture_all_str(
  some.html,
  name.pattern,
  country.pattern)
```

```
##                                                                                                  name
##                                                                                                <char>
## 1: A.A. Kharkevich Institute for Information Transmission Problems, IITP, Russian Academy of Sciences
## 2:                                                               Academy of Military Medical Sciences
## 3:                                                                        Academy of Military Science
## 4:                                                                       Aerospace Research Institute
##                       country
##                        <char>
## 1:                     Russia
## 2: People’s Republic of China
## 3: People’s Republic of China
## 4:                       Iran
```

The table above has two columns.
To add a final column for aliases, we use the code below.


``` r
aliases.pattern <- list(
  "\n\t<p>Known alias[(]es[)]: ",
  aliases=".*?",
  "</p>")
nca.pattern <- list(
  name.pattern,
  country.pattern,
  nc::quantifier(aliases.pattern, "?"))
nc::capture_all_str(some.html, nca.pattern)
```

```
##                                                                                                  name
##                                                                                                <char>
## 1: A.A. Kharkevich Institute for Information Transmission Problems, IITP, Russian Academy of Sciences
## 2:                                                               Academy of Military Medical Sciences
## 3:                                                                        Academy of Military Science
## 4:                                                                       Aerospace Research Institute
##                       country aliases
##                        <char>  <char>
## 1:                     Russia        
## 2: People’s Republic of China    AMMS
## 3: People’s Republic of China     AMS
## 4:                       Iran     ARI
```

## Download and parse


``` r
orgs.html <- "../assets/2024-09-09-canada-list-of-risky-research-orgs.html"
if(!file.exists(orgs.html)){
  u <- "https://science.gc.ca/site/science/en/safeguarding-your-research/guidelines-and-tools-implement-research-security/sensitive-technology-research-and-affiliations-concern/named-research-organizations"
  download.file(u, orgs.html)
}
orgs.lines <- readLines(orgs.html)
(n.strong <- length(grep("<strong>",orgs.lines)))
```

```
## [1] 103
```

``` r
orgs.dt <- nc::capture_all_str(orgs.lines, nca.pattern)
nrow(orgs.dt)
```

```
## [1] 103
```

The number of rows above seems to agree with the number of `<strong>` tags (simpler pattern).
Below we check the number of aliases.


``` r
sum(orgs.dt$aliases!="")
```

```
## [1] 75
```

``` r
aliases.lines <- grep("alias(es)", orgs.lines, fixed=TRUE, value=TRUE)
length(aliases.lines)
```

```
## [1] 94
```

Above it looks like there were some aliases not parsed. Which ones?


``` r
alias.dt <- nc::capture_first_vec(paste0("\n",aliases.lines), aliases.pattern)
alias.dt[!orgs.dt,.(aliases40=substr(aliases,1,40)),on="aliases"]
```

```
##                                    aliases40
##                                       <char>
##  1: BMSU; Bagiatollah Medical Sciences Unive
##  2: HPSTAR; Beijing High Voltage Science Res
##  3:                 PLA Dalian Naval Academy
##  4:               PAP Engineering University
##  5:                                      HEU
##  6: Imam Hussein University; IHU; Imam Hosse
##  7: Institute of Cadre Management; Institute
##  8:                                    KLISE
##  9:                 PAP Logistics University
## 10: Forensic Identification Center of the Mi
## 11:         PLA Nanjing Army Command College
## 12: PAP Officers' College; People's Armed Po
## 13:        People's Armed Police NCO College
## 14: Ministry of Public Security Railway Poli
## 15: SBU; Martyr Baheshti University; Univers
## 16:                                      TJU
## 17:                                    UESTC
## 18:                                     XATU
## 19:                                 27th NTs
```

### Trying again

Looking at the ones that did not match, it seems that there are some empty lines which are optional.


``` r
odd.html <- '
	<li><strong>Center for High Pressure Science and Technology Advanced Research</strong> (People’s Republic of China)

	<p>Known alias(es): HPSTAR; Beijing High Voltage Science Research Center</p>
	</li>
	<li><strong>Engineering University of the CAPF</strong> (People’s Republic of China)

	<p>Known alias(es): PAP Engineering University</p>
	</li>
	<li><strong>Explosion and Impact Technology Research Centre</strong> (Iran)
	<p>Known alias(es): Research Centre for Explosion and Impact; METFAZ</p>
	</li>
	<li><strong>Institute of NBC Defense</strong> (People’s Republic of China)</li>
'
aliases.plus.pattern <- list(
  "\n+\t<p>Known alias[(]es[)]: ", #added a +
  aliases=".*?",
  "</p>")
nca.plus.pattern <- list(
  name.pattern,
  country.pattern,
  nc::quantifier(aliases.plus.pattern, "?"))
nc::capture_all_str(some.html, nca.plus.pattern)
```

```
##                                                                                                  name
##                                                                                                <char>
## 1: A.A. Kharkevich Institute for Information Transmission Problems, IITP, Russian Academy of Sciences
## 2:                                                               Academy of Military Medical Sciences
## 3:                                                                        Academy of Military Science
## 4:                                                                       Aerospace Research Institute
##                       country aliases
##                        <char>  <char>
## 1:                     Russia        
## 2: People’s Republic of China    AMMS
## 3: People’s Republic of China     AMS
## 4:                       Iran     ARI
```

``` r
nc::capture_all_str(odd.html, nca.plus.pattern)
```

```
##                                                                 name                    country
##                                                               <char>                     <char>
## 1: Center for High Pressure Science and Technology Advanced Research People’s Republic of China
## 2:                                Engineering University of the CAPF People’s Republic of China
## 3:                   Explosion and Impact Technology Research Centre                       Iran
## 4:                                          Institute of NBC Defense People’s Republic of China
##                                                 aliases
##                                                  <char>
## 1: HPSTAR; Beijing High Voltage Science Research Center
## 2:                           PAP Engineering University
## 3:     Research Centre for Explosion and Impact; METFAZ
## 4:
```

Results above look great! Let's try it again below.



``` r
plus.dt <- nc::capture_all_str(orgs.lines, nca.plus.pattern)
nrow(plus.dt)
```

```
## [1] 103
```

``` r
n.strong
```

```
## [1] 103
```

``` r
sum(plus.dt$aliases!="")
```

```
## [1] 94
```

``` r
length(aliases.lines)
```

```
## [1] 94
```

Numbers agreeing in the output above indicate that the data were parsed correctly.

## Country analysis


``` r
plus.dt[, .(organizations=.N), by=country]
```

```
##                       country organizations
##                        <char>         <int>
## 1:                     Russia             6
## 2: People’s Republic of China            85
## 3:                       Iran            12
```

The output above indicates there are just three countries with organizations to avoid.

## Aliases

How many aliases per organization?


``` r
(a.dt <- plus.dt[
, alias.list := strsplit(aliases,split="; ")
][
, .(alias=alias.list[[1]]), by=name
])
```

```
##                                            name                                                        alias
##                                          <char>                                                       <char>
##   1:       Academy of Military Medical Sciences                                                         AMMS
##   2:                Academy of Military Science                                                          AMS
##   3:               Aerospace Research Institute                                                          ARI
##   4:               Air Force Medical University                                 Air Force Medical University
##   5:               Air Force Medical University                        Air Force Military Medical University
##  ---                                                                                                        
## 250: 48th Central Scientific Research Institute             Military Technical Scientific Research Institute
## 251: 48th Central Scientific Research Institute Center for Military Technical Problems of Biological Defense
## 252: 48th Central Scientific Research Institute                                             48th TsNII Kirov
## 253: 48th Central Scientific Research Institute                Scientific Research Institute of Microbiology
## 254: 48th Central Scientific Research Institute    Scientific Research Institute of Epidemiology and Hygiene
```

``` r
tibble::tibble(plus.dt[
, n.alias := sapply(alias.list, length)
]) # for nice print.
```

```
## # A tibble: 103 × 5
##    name                                                                               country aliases alias.list n.alias
##    <chr>                                                                              <chr>   <chr>   <list>       <int>
##  1 A.A. Kharkevich Institute for Information Transmission Problems, IITP, Russian Ac… Russia  ""      <chr [0]>        0
##  2 Academy of Military Medical Sciences                                               People… "AMMS"  <chr [1]>        1
##  3 Academy of Military Science                                                        People… "AMS"   <chr [1]>        1
##  4 Aerospace Research Institute                                                       Iran    "ARI"   <chr [1]>        1
##  5 Air Force Medical University                                                       People… "Air F… <chr [4]>        4
##  6 Air Force Research Institute                                                       People… "Air F… <chr [2]>        2
##  7 Air Force Xi’an Flight Academy                                                     People… "PLA A… <chr [3]>        3
##  8 Airforce Command College                                                           People… "PLA A… <chr [4]>        4
##  9 Airforce Communication NCO Academy                                                 People… "Dalia… <chr [1]>        1
## 10 Airforce Early Warning Academy                                                     People… "Wuhan… <chr [1]>        1
## # ℹ 93 more rows
```

``` r
## another way to get the count is via .N in join:
a.dt[plus.dt, .(.N=.N, n.alias), on='name', by=.EACHI]
```

```
##                                                                                                    name    .N n.alias
##                                                                                                  <char> <int>   <int>
##   1: A.A. Kharkevich Institute for Information Transmission Problems, IITP, Russian Academy of Sciences     0       0
##   2:                                                               Academy of Military Medical Sciences     1       1
##   3:                                                                        Academy of Military Science     1       1
##   4:                                                                       Aerospace Research Institute     1       1
##   5:                                                                       Air Force Medical University     4       4
##  ---                                                                                                                 
##  99:                                                                     Xi'an Technological University     1       1
## 100:                                          27th Scientific Center of the Russian Ministry of Defense     1       1
## 101:                                                     33rd Scientific Research and Testing Institute     1       1
## 102:                                                   46th TSNII Central Scientific Research Institute     2       2
## 103:                                                         48th Central Scientific Research Institute    10      10
```

## Conclusions

We used regular expressions to help us understand that Canada does not
want researchers collaborating with certain organizations in three
countries: Russia, Iran, China.

## Session info


``` r
sessionInfo()
```

```
## R version 4.4.1 (2024-06-14 ucrt)
## Platform: x86_64-w64-mingw32/x64
## Running under: Windows 11 x64 (build 22631)
## 
## Matrix products: default
## 
## 
## locale:
## [1] LC_COLLATE=English_United States.utf8  LC_CTYPE=English_United States.utf8    LC_MONETARY=English_United States.utf8
## [4] LC_NUMERIC=C                           LC_TIME=English_United States.utf8    
## 
## time zone: America/Toronto
## tzcode source: internal
## 
## attached base packages:
## [1] stats     graphics  utils     datasets  grDevices methods   base     
## 
## loaded via a namespace (and not attached):
##  [1] utf8_1.2.4         xfun_0.47          nc_2024.9.20       magrittr_2.0.3     glue_1.7.0         tibble_3.2.1      
##  [7] knitr_1.48         pkgconfig_2.0.3    lifecycle_1.0.4    cli_3.6.3          fansi_1.0.6        vctrs_0.6.5       
## [13] data.table_1.16.99 compiler_4.4.1     tools_4.4.1        evaluate_0.24.0    pillar_1.9.0       rlang_1.1.4
```
