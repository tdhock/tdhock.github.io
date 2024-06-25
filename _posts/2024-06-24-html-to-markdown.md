---
layout: post
title: HTML to Markdown
description: Regex for porting my lab web site
---



The goal of this blog post is to show a couple of interesting regex
that I used to port some info from my lab web site to my github blog.


``` r
text <- '
  <li><a href="https://github.com/lamtung16">Tung Lam Nguyen</a>, Inf PHD, Spring 2024 - present.</li>
  <li><a href="https://github.com/DorisAmoakohene">Doris Amoakohene</a>, Inf master,
    Fall 2023 - present.</li>
  <li><a href="https://github.com/bilalaslam45">Bilal Aslam</a>, Inf PHD, Fall 2022 - present.</li>
  <li><a href="https://github.com/harsheka">Karl Harshe</a>, MechE PHD, Fall 2022 - present.</li>
  <li><a href="https://github.com/EngineerDanny">Daniel Agyapong</a>,
  Informatics and Computing PHD, Fall 2022 - present.</li>
  <li><a href="https://github.com/CameronBodine">Cameron Bodine</a>,
  Informatics and Computing PHD, Spring 2020 - present.</li>
  <li><a href="https://github.com/trevb11">Trevor Silverstein</a>, Inf PHD,
    Fall 2023, then went back to teach school.</li>
  <li><a href="https://github.com/phase">Jadon Fowler</a>, CS master,
    Fall 2022 - Spring 2023, working as software developer
    at <a href="https://www.lunarclient.com/">Lunar Client</a>.</li>
  <li><a href="https://github.com/austinmalmin">Austin Malmin</a>, CS master, Spring 2023, now Salesforce developer at <a href="https://www.microchip.com">Microchip</a>.</li>
  <li><a href="https://github.com/rustky">Kyle Rust</a>, CS master,
  Fall 2021 - Fall 2022, working as data scientist
  at <a href="https://www.chsinc.com/">CHS</a>.</li>
  <li><a href="https://github.com/Csaluski">Charlie Saluski</a>,
    CS undergrad, Spring 2022.</li>
  <li><a href="https://github.com/balaji-senthil">Balaji Senthilkumar</a>,
  CS master, Spring 2022.</li>
  <li><a href="https://github.com/jkaufy">Jacob Kaufman</a>, CS
  master, Spring 2022, then went
  to <a href="https://www.gd.com/">General Dynamics</a>.</li>
  <li><a href="https://github.com/amissafari">Amirhossein Safari</a>,
  Informatics and Computing PHD, Spring 2022.</li>
  <li><a href="https://github.com/JWheeler4">Jonathan Wheeler</a>,
  Math master, Spring 2022.</li>
  <li><a href="https://github.com/tds325">Tayler Skirvin</a>, CS
    undergrad, Spring 2022, then went to work as software developer at
    <a href="https://www.cognizant.com">Cognizant</a>.</li>
  <li><a href="https://github.com/brookesebranek">Brooke Sebranek</a>,
    Biomedical Sciences undergrad, Fall 2021 - Spring 2022.</li>
  <li><a href="https://github.com/Prapti-044">Shadmaan Hye</a>,
  Informatics and Computing PHD, Fall 2021, then went to University of
  Arizona CS as PHD student.</li>
  <li><a href="https://github.com/deltarod">Tristan Miller</a>, BS CS
  research associate, Fall 2020 - Fall 2021, then went to work at a
  tech startup.</li>
  <li><a href="https://github.com/akhikolla">Akhila Chowdary
  Kolla</a>, CS master, Spring 2020 - Fall 2021, then went to work as
  software developer at <a href="https://www.amazon.com">Amazon</a>.</li>
  <li><a href="https://github.com/alyssajs">Alyssa Stenberg</a>, CS
  master, Spring 2020, then went
  to <a href="https://www.jbhunt.com/">J.B. Hunt</a> as a software
  engineer (Machine Learning Operations team).</li>
  <li><a href="https://github.com/JonathanHillman">Jonathan Hillman</a>,
  CS undergrad, Summer 2020 - Summer 2021, then did Math master at NAU.</li>
  <li><a href="https://github.com/frankp4">John Francis "Frank" Burkhart</a>,
   Math undergrad, Spring 2020 - Spring 2021, then did <a href="https://brc.ncsu.edu/genomics/bioinformatics/phd-program">Bioinformatics PHD program at North Carolina State University</a>.</li>
  <li><a href="https://github.com/superMicrowave">Weiheng Su</a>, CS
  undergrad, Summer 2020 - Fall 2020, then worked as Machine Learning
  Engineer at <a href="http://www.frontopsky.com/">Frontopsky</a>, and
  then did PHD at Stony Brook University.</li>
  <li><a href="https://github.com/DovahCraft">Joseph Vargovich</a>, CS
  undergrad, Fall 2018 - Fall 2020, then did CS master at NAU, then
  got job offer at <a href="https://www.honeywell.com">Honeywell</a>.</li>
  <li><a href="https://github.com/aLiehrmann">Arnaud Liehrmann</a>,
  master intern, Spring-Summer 2020, then did PHD at <a href="https://centreborelli.ens-paris-saclay.fr/en">Centre Borelli, Paris-Saclay
  University</a>.</li>
  <li><a href="https://github.com/DarienRT">Darien Reyes-Tadeo</a>, CS undergrad, Spring
  2020.</li>
  <li><a href="https://github.com/andruuhurst">Andrew Hurst</a>, CS
  undergrad, Fall 2019 - Spring 2020, then worked as Software
  Developer at <a href="https://www.gm.com/">General Motors</a> in Atlanta.</li>
  <li><a href="https://github.com/LooDaHu">Jinming Yang</a>, CS
    master, Fall 2019 - Spring 2020, then worked as software
    development engineer at <a href="https://www.sangfor.com">Sangfor
    Tech</a> (cybersecurity company in ShenZhen, China specializing in
    Cloud Computing & Network Security).</li>
  <li><a href="https://github.com/Zaoyee">Zaoyi Chi</a>, EE master,
  Fall 2019 - Spring 2020.</li>
  <li><a href="https://github.com/atiyehftn">Atiyeh Fotoohinasab</a>,
  Informatics and Computing PHD, Summer 2019 - Spring 2020, then did <a href="https://grad.arizona.edu/catalog/programinfo/BMEGPHD">University of Arizona Biomedical Engineering PHD program</a>.</li>
  <li><a href="https://github.com/as4378">Anuraag Srivastava</a>, CS
  master, Fall 2018 - Spring 2020, then went to Chicago to work as a 
  software engineer for a company.</li>
  <li><a href="https://github.com/bd288">Brandon Dunn</a>, EE master,
  Fall 2018 - Spring 2019, then went
  to <a href="https://www.rtx.com/">Raytheon</a>.</li>'
no.newlines <- gsub(" +", " ", gsub("\n", "", text))
'[text](link)'
```

```
## [1] "[text](link)"
```

``` r
no.ahref <- gsub('<a href="(.*?)">(.*?)</a>', '[\\2](\\1)', no.newlines)
student.dt <- nc::capture_all_str(
  no.ahref,
  '<li>',
  content=".*?",
  '</li>')
cat(paste(paste("*", student.dt$content), collapse="\n"))
```

```
## * [Tung Lam Nguyen](https://github.com/lamtung16), Inf PHD, Spring 2024 - present.
## * [Doris Amoakohene](https://github.com/DorisAmoakohene), Inf master, Fall 2023 - present.
## * [Bilal Aslam](https://github.com/bilalaslam45), Inf PHD, Fall 2022 - present.
## * [Karl Harshe](https://github.com/harsheka), MechE PHD, Fall 2022 - present.
## * [Daniel Agyapong](https://github.com/EngineerDanny), Informatics and Computing PHD, Fall 2022 - present.
## * [Cameron Bodine](https://github.com/CameronBodine), Informatics and Computing PHD, Spring 2020 - present.
## * [Trevor Silverstein](https://github.com/trevb11), Inf PHD, Fall 2023, then went back to teach school.
## * [Jadon Fowler](https://github.com/phase), CS master, Fall 2022 - Spring 2023, working as software developer at [Lunar Client](https://www.lunarclient.com/).
## * [Austin Malmin](https://github.com/austinmalmin), CS master, Spring 2023, now Salesforce developer at [Microchip](https://www.microchip.com).
## * [Kyle Rust](https://github.com/rustky), CS master, Fall 2021 - Fall 2022, working as data scientist at [CHS](https://www.chsinc.com/).
## * [Charlie Saluski](https://github.com/Csaluski), CS undergrad, Spring 2022.
## * [Balaji Senthilkumar](https://github.com/balaji-senthil), CS master, Spring 2022.
## * [Jacob Kaufman](https://github.com/jkaufy), CS master, Spring 2022, then went to [General Dynamics](https://www.gd.com/).
## * [Amirhossein Safari](https://github.com/amissafari), Informatics and Computing PHD, Spring 2022.
## * [Jonathan Wheeler](https://github.com/JWheeler4), Math master, Spring 2022.
## * [Tayler Skirvin](https://github.com/tds325), CS undergrad, Spring 2022, then went to work as software developer at [Cognizant](https://www.cognizant.com).
## * [Brooke Sebranek](https://github.com/brookesebranek), Biomedical Sciences undergrad, Fall 2021 - Spring 2022.
## * [Shadmaan Hye](https://github.com/Prapti-044), Informatics and Computing PHD, Fall 2021, then went to University of Arizona CS as PHD student.
## * [Tristan Miller](https://github.com/deltarod), BS CS research associate, Fall 2020 - Fall 2021, then went to work at a tech startup.
## * [Akhila Chowdary Kolla](https://github.com/akhikolla), CS master, Spring 2020 - Fall 2021, then went to work as software developer at [Amazon](https://www.amazon.com).
## * [Alyssa Stenberg](https://github.com/alyssajs), CS master, Spring 2020, then went to [J.B. Hunt](https://www.jbhunt.com/) as a software engineer (Machine Learning Operations team).
## * [Jonathan Hillman](https://github.com/JonathanHillman), CS undergrad, Summer 2020 - Summer 2021, then did Math master at NAU.
## * [John Francis "Frank" Burkhart](https://github.com/frankp4), Math undergrad, Spring 2020 - Spring 2021, then did [Bioinformatics PHD program at North Carolina State University](https://brc.ncsu.edu/genomics/bioinformatics/phd-program).
## * [Weiheng Su](https://github.com/superMicrowave), CS undergrad, Summer 2020 - Fall 2020, then worked as Machine Learning Engineer at [Frontopsky](http://www.frontopsky.com/), and then did PHD at Stony Brook University.
## * [Joseph Vargovich](https://github.com/DovahCraft), CS undergrad, Fall 2018 - Fall 2020, then did CS master at NAU, then got job offer at [Honeywell](https://www.honeywell.com).
## * [Arnaud Liehrmann](https://github.com/aLiehrmann), master intern, Spring-Summer 2020, then did PHD at [Centre Borelli, Paris-Saclay University](https://centreborelli.ens-paris-saclay.fr/en).
## * [Darien Reyes-Tadeo](https://github.com/DarienRT), CS undergrad, Spring 2020.
## * [Andrew Hurst](https://github.com/andruuhurst), CS undergrad, Fall 2019 - Spring 2020, then worked as Software Developer at [General Motors](https://www.gm.com/) in Atlanta.
## * [Jinming Yang](https://github.com/LooDaHu), CS master, Fall 2019 - Spring 2020, then worked as software development engineer at [Sangfor Tech](https://www.sangfor.com) (cybersecurity company in ShenZhen, China specializing in Cloud Computing & Network Security).
## * [Zaoyi Chi](https://github.com/Zaoyee), EE master, Fall 2019 - Spring 2020.
## * [Atiyeh Fotoohinasab](https://github.com/atiyehftn), Informatics and Computing PHD, Summer 2019 - Spring 2020, then did [University of Arizona Biomedical Engineering PHD program](https://grad.arizona.edu/catalog/programinfo/BMEGPHD).
## * [Anuraag Srivastava](https://github.com/as4378), CS master, Fall 2018 - Spring 2020, then went to Chicago to work as a software engineer for a company.
## * [Brandon Dunn](https://github.com/bd288), EE master, Fall 2018 - Spring 2019, then went to [Raytheon](https://www.rtx.com/).
```

``` r
html <- '
    <h3>ASU West ML day, Apr 2024</h3>
    <p>Left to right: Tung, Toby, Doris, Bilal, Danny.<br />
      <img src="photos/2024-04-26-ASU-West-ML-Day.JPG" alt="ASU West ML day Apr 2024" />
    </p>
    <h3>Cross-country ski day, Feb 2024</h3>
    <p>Left to right: Toby, Tung, Doris, Danny.<br />
      <img src="photos/2024-02-20-toby-tung-doris-danny-lunch.jpg" alt="Cross-country ski day Feb 2024" />
    </p>
    <h3>ML group meeting, Sep 2023</h3>
    <p>Left to right: Richard, Trevor, Bilal, Danny, Toby, Doris, Karl.<br />
      <img src="photos/2023-09-13-ml-group-meeting.jpg" alt="ML group meeting Sep 2023" />
    </p>
    <h3>SICCS ML lab at ASU West ML Day, April 2023</h3>
    <p>Left to right: Bilal, Toby, Anirban, Danny, Austin, Jadon.<br />
      <img src="photos/2023-04-14-ASU-ML-Day.jpg" alt="SICCS at ASU April 2023" />
    </p>
    <h3>ML group meeting, Feb 2023</h3>
    <p>Left to right: Austin, Jadon, Danny, Toby, Bilal, Cam.<br />
      <img src="photos/2023-02-02-group-meeting.jpg" alt="SICCS group meeting 2023 Feb 2" />
    </p>
    <h3>SICCS camping, Oct 2022</h3>
    <p>Left to right: Kyle, Toby, Danny, Basil.<br />  
      <img src="photos/2022-10-14_ML_camp_fire.jpg" alt="SICCS camping" />
    </p>
    <h3>ML group meeting, Oct 2022</h3>
    <p>Left to right: Cam, Bilal, Toby, Danny, Kyle, Gabi.<br />  
      <img src="photos/2022-10-14_ML_group_meeting.jpg" alt="group meeting Oct 2022" />
    </p>
    <h3>RcppDeepState project members, Oct 2021</h3>
    <p>Left to right: Toby, Alex, Akhila.<br />  
      <img src="photos/2021-10-12-Toby-Alex-Akhila.jpg" alt="Rcpp project members" />
    </p>
    <h3>First fall semester group meeting, Aug 2021</h3>
    <p>Left to right: Tristan, Anirban, Toby, Shadmaan, Akhila, Balaji, Kyle.<br />  
      <img src="photos/2021-08-16-first-fall-ml-group-meeting.jpg" alt="lab meeting fall 2021" />
    </p>
    <h3>Downhill ski day, Mar 2021</h3>
    <p>Left to right: Toby, Jon, Tristan, Frank, Akhila, Alyssa.<br />  
      <img src="photos/2021-03-lab-ski-lunch.jpg" alt="ski 2021" />
    </p>
    <h3>Summer Pizza Party, July 2020</h3>
    <p>Foreground: Akhila, left to right in the back: Benoît, Arnaud,
      Toby, Basil, John.<br />  
      <img src="photos/2020-07-summer-pizza-ben-baz.jpg" alt="summer
      pizza" />
    </p>
    <h3>Winter Pizza Party, Feb 2020</h3>
    <p>Left to right: Atiyeh, Darien, Joe, Arnaud, Benoît, Toby.<br />
      We are showing "six" fingers for SICCS (School of Informatics,
      Computing and Cyber Systems). <br />
      <img src="photos/2020-02-ml-lab-pizza-cropped-lores.jpeg"
      alt="winter pizza" />
    </p>
    <h3>Hiking in Sedona, Dec 2019</h3>
    <p>Left to right: Joe, Toby, Farnoosh, Atiyeh, Anuraag, Zaoyi.<br />
      <img 
	  src="photos/2019-12-ml-lab-sedona-cropped-lores.jpeg" 
	  alt="sedona"
	  />
    </p>
'
src.pattern <- nc::field('src','="','[^"]+')
nc::capture_all_str(html, src.pattern)
```

```
##                                                   src
##                                                <char>
##  1:             photos/2024-04-26-ASU-West-ML-Day.JPG
##  2: photos/2024-02-20-toby-tung-doris-danny-lunch.jpg
##  3:            photos/2023-09-13-ml-group-meeting.jpg
##  4:                  photos/2023-04-14-ASU-ML-Day.jpg
##  5:               photos/2023-02-02-group-meeting.jpg
##  6:                photos/2022-10-14_ML_camp_fire.jpg
##  7:            photos/2022-10-14_ML_group_meeting.jpg
##  8:            photos/2021-10-12-Toby-Alex-Akhila.jpg
##  9: photos/2021-08-16-first-fall-ml-group-meeting.jpg
## 10:                  photos/2021-03-lab-ski-lunch.jpg
## 11:           photos/2020-07-summer-pizza-ben-baz.jpg
## 12:    photos/2020-02-ml-lab-pizza-cropped-lores.jpeg
## 13:   photos/2019-12-ml-lab-sedona-cropped-lores.jpeg
```

``` r
img.dt <- nc::capture_all_str(
  html,
  '<h3>',
  h3=".*?",
  '</h3>.*\n.*?<p>',
  caption="(?:.*\n)*?.*",
  "<br /> *\n",
  ##img="(?:.*\n)*?.*",
  '[^<]*<img[^s]+',
  src.pattern,
  '"[^a]+',
  nc::field('alt','="','[^"]+'),
  '"')
'![Alt](/path/to/img.jpg)'
```

```
## [1] "![Alt](/path/to/img.jpg)"
```

``` r
markdown.vec <- img.dt[, sprintf(
  '\n### %s\n%s\n![%s](%s)',
  h3, caption,
  gsub("[\n ]+", " ", alt),
  sub("photos", "/assets/img/lab-photos", src))]
cat(paste(markdown.vec, collapse="\n"))
```

```
## 
## ### ASU West ML day, Apr 2024
## Left to right: Tung, Toby, Doris, Bilal, Danny.
## ![ASU West ML day Apr 2024](/assets/img/lab-photos/2024-04-26-ASU-West-ML-Day.JPG)
## 
## ### Cross-country ski day, Feb 2024
## Left to right: Toby, Tung, Doris, Danny.
## ![Cross-country ski day Feb 2024](/assets/img/lab-photos/2024-02-20-toby-tung-doris-danny-lunch.jpg)
## 
## ### ML group meeting, Sep 2023
## Left to right: Richard, Trevor, Bilal, Danny, Toby, Doris, Karl.
## ![ML group meeting Sep 2023](/assets/img/lab-photos/2023-09-13-ml-group-meeting.jpg)
## 
## ### SICCS ML lab at ASU West ML Day, April 2023
## Left to right: Bilal, Toby, Anirban, Danny, Austin, Jadon.
## ![SICCS at ASU April 2023](/assets/img/lab-photos/2023-04-14-ASU-ML-Day.jpg)
## 
## ### ML group meeting, Feb 2023
## Left to right: Austin, Jadon, Danny, Toby, Bilal, Cam.
## ![SICCS group meeting 2023 Feb 2](/assets/img/lab-photos/2023-02-02-group-meeting.jpg)
## 
## ### SICCS camping, Oct 2022
## Left to right: Kyle, Toby, Danny, Basil.
## ![SICCS camping](/assets/img/lab-photos/2022-10-14_ML_camp_fire.jpg)
## 
## ### ML group meeting, Oct 2022
## Left to right: Cam, Bilal, Toby, Danny, Kyle, Gabi.
## ![group meeting Oct 2022](/assets/img/lab-photos/2022-10-14_ML_group_meeting.jpg)
## 
## ### RcppDeepState project members, Oct 2021
## Left to right: Toby, Alex, Akhila.
## ![Rcpp project members](/assets/img/lab-photos/2021-10-12-Toby-Alex-Akhila.jpg)
## 
## ### First fall semester group meeting, Aug 2021
## Left to right: Tristan, Anirban, Toby, Shadmaan, Akhila, Balaji, Kyle.
## ![lab meeting fall 2021](/assets/img/lab-photos/2021-08-16-first-fall-ml-group-meeting.jpg)
## 
## ### Downhill ski day, Mar 2021
## Left to right: Toby, Jon, Tristan, Frank, Akhila, Alyssa.
## ![ski 2021](/assets/img/lab-photos/2021-03-lab-ski-lunch.jpg)
## 
## ### Summer Pizza Party, July 2020
## Foreground: Akhila, left to right in the back: Benoît, Arnaud,
##       Toby, Basil, John.
## ![summer pizza](/assets/img/lab-photos/2020-07-summer-pizza-ben-baz.jpg)
## 
## ### Winter Pizza Party, Feb 2020
## Left to right: Atiyeh, Darien, Joe, Arnaud, Benoît, Toby.<br />
##       We are showing "six" fingers for SICCS (School of Informatics,
##       Computing and Cyber Systems). 
## ![winter pizza](/assets/img/lab-photos/2020-02-ml-lab-pizza-cropped-lores.jpeg)
## 
## ### Hiking in Sedona, Dec 2019
## Left to right: Joe, Toby, Farnoosh, Atiyeh, Anuraag, Zaoyi.
## ![sedona](/assets/img/lab-photos/2019-12-ml-lab-sedona-cropped-lores.jpeg)
```
