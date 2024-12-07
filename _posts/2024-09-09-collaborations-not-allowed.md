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

## Bonus: French

Below we combine the different parts of the regex code above into a
single regex code block below, with some additions specific to the
French version of the web page.


``` r
## https://science.gc.ca/site/science/fr/protegez-votre-recherche/lignes-directrices-outils-pour-mise-oeuvre-securite-recherche/recherche-technologies-sensibles-affiliations-preoccupantes/organisations-recherche-nommees
french.html <- "
	<li><strong>Académie des transports militaires de l'armée <em>[Army Military Transportation Academy]</em></strong> (République populaire de Chine)
	<p>Alias connu(s) : <em>Academy of Military Transportation</em></p>
	</li>
	<li><strong>Académie d'infanterie de l'armée <em>[Army Infantry Academy]</em></strong> (République populaire de Chine)
	<p>Alias connu(s) : <em>Army Infantry Academy of PLA; PLA Army Infantry Academy; Nachang Army Academy</em></p>
	</li>
	<li><strong>Académie du service militaire <em>[Army Service Academy]</em></strong> (République populaire de Chine)
	<p>Alias connu(s) : <em>PLA Army Service Academy</em></p>
	</li>
	<li><strong>Académie militaire d'artillerie et de la défense aérienne <em>[Army Academy of Artillery and Air Defense]</em></strong> (République populaire de Chine)</li>
	<li><strong>Académie militaire de défense des frontières et des côtes <em>[Army Academy of Border and Coastal Defense]</em></strong> (République populaire de Chine)</li>
	<li><strong>Académie militaire des forces blindées <em>[Army Academy of Armored Forces]</em></strong> (République populaire de Chine)
	<p>Alias connu(s) : <em>Army Armored Forces Academy; Armored Forces Engineering Academy Académie navale de Dalian (Dalian)</em></p>
	</li>
	<li><strong>Académie navale de Dalian <em>[Dalian Naval Academy]</em></strong> (République populaire de Chine)
	<p>Alias connu(s) : <em>PLA Dalian Naval Academy</em></p>
	</li>
	<li><strong>Association professionnelle de l'Organisation autonome à but non lucratif des concepteurs de systèmes informatiques <em>[Autonomous Noncommercial Organization Professional Association of Designers of Data Processing Systems]</em></strong> (Russie)
	<p>Alias connu(s) : <em>ANO PO KSI</em></p>
	</li>
"
french.dt <- nc::capture_all_str(
  french.html,
  "\n\t<li><strong>",
  french=".*?",
  " <em>\\[",
  english=".*?",
  "\\]</em></strong> [(]",
  pays=".*?",
  " *[)]",
  nc::quantifier(
    "\n+\t<p>Alias connu[(]s[)] : <em>", 
    aliases=".*?",
    "</em>",
    "?"
  )
)
abbrev <- function(x,m)paste0(substr(x,1,m),"…")
(french.aliases <- french.dt[, let(
  alias.list = strsplit(aliases,split="; "),
  français = abbrev(french,25),
  English = abbrev(english,20)
)][
, .(alias=alias.list[[1]]), by=français
])
```

```
##                      français                                                                 alias
##                        <char>                                                                <char>
## 1: Académie des transports m…                                    Academy of Military Transportation
## 2: Académie d'infanterie de …                                          Army Infantry Academy of PLA
## 3: Académie d'infanterie de …                                             PLA Army Infantry Academy
## 4: Académie d'infanterie de …                                                  Nachang Army Academy
## 5: Académie du service milit…                                              PLA Army Service Academy
## 6: Académie militaire des fo…                                           Army Armored Forces Academy
## 7: Académie militaire des fo… Armored Forces Engineering Academy Académie navale de Dalian (Dalian)
## 8: Académie navale de Dalian…                                              PLA Dalian Naval Academy
## 9: Association professionnel…                                                            ANO PO KSI
```

The result table above has one row for each alias.
The code below produces an table with one row per organisation.


``` r
french.aliases[french.dt, .(
  English,
  pays,  
  Alias=if(.N)paste(abbrev(alias,10), collapse="; ") else ""
), by=.EACHI, on="français"]
```

```
##                      français               English                          pays                                 Alias
##                        <char>                <char>                        <char>                                <char>
## 1: Académie des transports m… Army Military Transp… République populaire de Chine                           Academy of…
## 2: Académie d'infanterie de … Army Infantry Academ… République populaire de Chine Army Infan…; PLA Army I…; Nachang Ar…
## 3: Académie du service milit… Army Service Academy… République populaire de Chine                           PLA Army S…
## 4: Académie militaire d'arti… Army Academy of Arti… République populaire de Chine                                      
## 5: Académie militaire de déf… Army Academy of Bord… République populaire de Chine                                      
## 6: Académie militaire des fo… Army Academy of Armo… République populaire de Chine              Army Armor…; Armored Fo…
## 7: Académie navale de Dalian… Dalian Naval Academy… République populaire de Chine                           PLA Dalian…
## 8: Association professionnel… Autonomous Noncommer…                        Russie                           ANO PO KSI…
```

Exercise for the reader: download the French web page, and convert it to a table using this new regex code. Do you get the same number of organisations as with the English version?

## Conclusions

We used regular expressions to help us understand that Canada does not
want researchers collaborating with certain organizations in three
countries: Russia, Iran, China.

## Session info


``` r
sessionInfo()
```

```
## R Under development (unstable) (2024-10-01 r87205)
## Platform: x86_64-pc-linux-gnu
## Running under: Ubuntu 22.04.5 LTS
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
## loaded via a namespace (and not attached):
##  [1] utf8_1.2.4        xfun_0.45         nc_2024.9.19      magrittr_2.0.3    glue_1.7.0        tibble_3.2.1     
##  [7] knitr_1.47        pkgconfig_2.0.3   lifecycle_1.0.4   cli_3.6.2         fansi_1.0.6       vctrs_0.6.5      
## [13] data.table_1.16.2 compiler_4.5.0    tools_4.5.0       evaluate_0.23     pillar_1.9.0      rlang_1.1.3
```
