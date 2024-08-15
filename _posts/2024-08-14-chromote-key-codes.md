---
layout: post
title: Writing comprehensible tests
description: Documenting key code magic numbers in animint2 tests
---

[animint2](https://github.com/tdhock/animint2) is an R package
for animated, interactive data visualization.
It uses R ggplot code, which makes it possible to define a wide range of web-based data visualizations, as can be seen in the [gallery](https://animint.github.io/gallery/).
The goal of this post is to explain some changes in the framework used for testing `animint2`.



### Background about animint2

Since `animint2` creates web-based data visualizations, we can test
the software by using a web browser to render, and examining the
output HTML.  This is a concept called [headless
browser](https://en.wikipedia.org/wiki/Headless_browser) testing (if
there is no browser window to be seen), and/or remote-controlled
browser testing (if you control a browser window with the command
line). 

Since about 2014, the animint project has been using this kind of
testing, to make sure that the code keeps working, even when making
changes to the code. Currently, these tests are found in the 59
`test-renderer*` files in
[animint2/tests/testthat](https://github.com/animint/animint2/tree/master/tests/testthat),
which contain 755 `expect_*` test lines.

Originally, these tests were implemented using RSelenium, a package
that supported firefox as a remote-controlled browser, and PhantomJS
as a headless browser.  Currently in GSOC'24, Siddhesh Deodhar is
working in [PR#126](https://github.com/animint/animint2/pull/126) on
migrating these tests to the chromote package, which is a different
implementation that requires the Google Chrome browser.

Since `animint2` creates interactive data visualizations, we need to
test the interactivity, by simulating mouse clicks and keyboard typing
in various areas of the web page.  The different testing frameworks
(RSelenium and chromote) use different APIs to simulate these
interactivity events. The rest of this post will explore some
challenges we encountered when migrating these interactivity events in
the tests.

### Old test

As an example, consider the code below, which tests for the number of
circles, before and after sending various key interaction events to
the web browser.

```r
test_that("top widget adds/remove points", {
  expect_equal(get_circles(), list(10, 10))
  remDr$sendKeysToActiveElement(list(key="backspace"))
  expect_equal(get_circles(), list(5, 10))
  remDr$sendKeysToActiveElement(list(key="backspace"))
  expect_equal(get_circles(), list(0, 10))
  remDr$sendKeysToActiveElement(list("a", key="enter"))
  expect_equal(get_circles(), list(5, 10))
  remDr$sendKeysToActiveElement(list("b", key="enter"))
  expect_equal(get_circles(), list(10, 10))
})
```

The code above is fairly easy to read/understand:
* `get_circles()` gets a list of counts of currently displayed circles.
* `remDr$sendKeysToActiveElement()` simulates a keyboard interaction
  event, where `enter` and `backspace` are special keywords for the
  corresponding keys.

### Siddesh's first proposition

In chromote, the analog of `sendKeysToActiveElement()` is
`dispatchKeyEvent()`, which requires specifying a key and
corresponding code, as in the example below, [from one of Siddhesh's
commits](https://github.com/animint/animint2/blob/d2b5de7cd69bd22e50bbc6da88b528f89828c598/tests/testthat/test-renderer1-knit-print.R):

```r
sendKey <- function(key, code, keyCode) {
  remDr$Input$dispatchKeyEvent(
    type = "keyDown", key = key, code = code,
    windowsVirtualKeyCode = keyCode,
    nativeVirtualKeyCode = keyCode)
  remDr$Input$dispatchKeyEvent(
    type = "keyUp", key = key, code = code,
    windowsVirtualKeyCode = keyCode,
    nativeVirtualKeyCode = keyCode)
}
sendBackspace <- function() {
  if (remDr$browserName == "chromote") {
    sendKey("Backspace", "Backspace", 8)
  } else {
    remDr$sendKeysToActiveElement(list(key="backspace"))
  }
  Sys.sleep(0.5)
}
sendA <- function() {
  if (remDr$browserName == "chromote") {
    remDr$Input$insertText(text = "a")
    sendKey("Enter", "Enter", 13)
  } else {
    remDr$sendKeysToActiveElement(list("a", key="enter"))
  }
  Sys.sleep(0.5)
}
sendB <- function() {
  if (remDr$browserName == "chromote") {
    remDr$Input$insertText(text = "b")
    sendKey("Enter", "Enter", 13)
  } else {
    remDr$sendKeysToActiveElement(list("b", key="enter"))
  }
  Sys.sleep(0.5)
}
```

There are several instances of "repeated code blocks" in the code
above, which is one of the mistakes that I see frequently enough, that
I have written about it in my [R General Usage
Rubric](https://docs.google.com/document/d/1W6-HdQLgHayOFXaQtscO5J5yf05G7E6KeXyiBJFcT7A/edit#heading=h.pekgvy78tviz),
which I use to grade R programming assignments. The repetition issues
below can be fixed by using loops, functions, or some other
programming technique:

* In `sendKey()` the two lines are the same except for `type =
  "keyUp"` or `Down`. 
* The `sendA` and `sendB` functions are identical except for
  `text="a"` or `b`.
* `sendKey(x,y,z)` is always called with `x` same as `y`, such as
  `sendKey("Enter", "Enter", 13)`.
  
Another issue is the `13` which appears in the code, but is not
explained, so it is a [Magic
Number](https://en.wikipedia.org/wiki/Magic_number_(programming)#Unnamed_numerical_constants). Any
reasonable reader of the code may wonder, where does this 13 come
from, and what number should I use if I wanted to call this function
to simulate a different key press?

### Siddesh's proposed fix

I asked Siddhesh to fix these issues, and [he commited a new version](
https://github.com/animint/animint2/blob/2a633480122337d98888b8686a6f81b699828ad9/tests/testthat/helper-HTML.R#L83)
with:

```r
sendKey <- function(key) {
  stopifnot(is.character(key))
  #The key codes in the list below are adopted from Windows Virtual keycode standards
  #https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
  # VK_BACK->Backspace, VK_RETURN->Enter, VK_DOWN->ArrowDown
  # we use the corresponding decimal values of the key codes given in hex value in the above link
  key2code <- c(
    Backspace=8,
    Enter=13,
    ArrowDown=40)
  for (type in c("keyDown", "keyUp")) {
    remDr$Input$dispatchKeyEvent(
	  type = type, key = key, code = key, 
	  windowsVirtualKeyCode = key2code[[key]], 
	  nativeVirtualKeyCode = key2code[[key]])
  }
}
sendBackspace <- function() {
  sendKey("Backspace")
  Sys.sleep(0.5)
}
send <- function(alphabet) {
  remDr$Input$insertText(text = alphabet)
  sendKey("Enter")
  Sys.sleep(0.5)
}
test_that("top widget adds/remove points", {
  expect_equal(get_circles(), list(10, 10))
  sendBackspace()
  expect_equal(get_circles(), list(5, 10))
  sendBackspace()
  expect_equal(get_circles(), list(0, 10))
  send("a")
  expect_equal(get_circles(), list(5, 10))
  send("b")
  expect_equal(get_circles(), list(10, 10))
})
```

The above code fixes most of the repetition issues, but does not fully fix the magic number issue, because the link in comments, to [Microsoft docs](https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes), 

* only has hex codes, not decimal codes (required by chromote in R)
* only has names like `VK_BACK`, not like `Backspace` (required by chromote in R)

So there is still some mystery. Any reasonable programmer may wonder,
are these really the decimal versions of the hex codes listed on that
page? How to find what the keyword should be for a new key?

### My proposed new test

I proposed the following fix [in a recent commit](https://github.com/animint/animint2/blob/053dde95b5be7f2fced0741cc71a1ddb8b900d19/tests/testthat/helper-HTML.R):

```r 
### The hex codes come from
### https://developer.mozilla.org/en-US/docs/Web/API/UI_Events/Keyboard_event_key_values
key2hex_code <- c(
  Backspace="08",
  Enter="0D",
  ArrowDown="28")
### https://chromedevtools.github.io/devtools-protocol/tot/Input/ says
### that dispatchKeyEvent() requires DOM key codes (in decimal) for
### the windowsVirtualKeyCode and nativeVirtualKeyCode arguments.
key2dec_code <- structure(
  strtoi(key2hex_code,base=16),
  names=names(key2hex_code))
# Function to send a key event
sendKey <- function(key) {
  stopifnot(is.character(key))
  for (type in c("keyDown", "keyUp")) {
    remDr$Input$dispatchKeyEvent(type = type, key = key, code = key, windowsVirtualKeyCode = key2dec_code[[key]], nativeVirtualKeyCode = key2dec_code[[key]])
  }
}
```

The above code provides two links

* [Chrome dev tools docs](https://chromedevtools.github.io/devtools-protocol/tot/Input/) explain that `dispatchKeyEvent()` requires DOM key codes.
* [Mozilla
  docs](https://developer.mozilla.org/en-US/docs/Web/API/UI_Events/Keyboard_event_key_values)
  has a table that lists DOM key names and corresponding codes like
  `Backspace` (along with the windows virtual key codes like
  `VK_BACK`).
  
So by following those links in the nearby comments, it should be obvious, to find the key codes to use, if we ever wanted to simulate a new/different key entry. And making such a change would be easy, by just adding a new entry to `key2hex_code`, since the repetition has been removed.

### What about the other hex codes?

Another reasonable question we may ask is, can our R code support all
of the key codes listed on [Mozilla
docs](https://developer.mozilla.org/en-US/docs/Web/API/UI_Events/Keyboard_event_key_values)?

To do that, we could download the web page, and parse/extract the
relevant information (names and hex code values). 

### Define expected values

First, we define
what we expect to extract from that web page:


``` r
library(data.table)
```

```
## data.table 1.15.99 IN DEVELOPMENT built 2024-05-02 04:20:26 UTC using 1 threads (see ?getDTthreads).  Latest news: r-datatable.com
## **********
## This development version of data.table was built more than 4 weeks ago. Please update: data.table::update_dev_pkg()
## **********
```

``` r
code <- function(dom_name, key_name, hex){
  data.table(dom_name, key_name, hex)
}
(animint2.expected <- rbind(
  code("Backspace", "VK_BACK",   "08"),
  code("Enter",     "VK_RETURN", "0D"),
  code("ArrowDown", "VK_DOWN",   "28")))
```

```
##     dom_name  key_name    hex
##       <char>    <char> <char>
## 1: Backspace   VK_BACK     08
## 2:     Enter VK_RETURN     0D
## 3: ArrowDown   VK_DOWN     28
```

The table above has three rows, one for each key code that we used in
the `animint2` test code.

### Create input text for a small, relevant example

When extracting data from loosely structured text in web pages, the
first thing to do is download a copy of the web page,


``` r
local.html <- "~/teaching/regex-tutorial/Keyboard_event_key_values.html"
if(!file.exists(local.html)){
  remote.url <- "https://developer.mozilla.org/en-US/docs/Web/API/UI_Events/Keyboard_event_key_values"
  download.file(remote.url, local.html)
}
html.lines <- readLines(local.html)
```

```
## Warning in readLines(local.html): ligne finale incomplète trouvée dans
## '~/teaching/regex-tutorial/Keyboard_event_key_values.html'
```

Then, instead of trying to extract from the whole web page right away,
first open up the local web page in a text editor like emacs, and copy
a few relevant parts of the text data to a R string literal. Working
with this small example will enable easy/fast testing of the
extraction code, because you should know what the correct extraction
should look like. For example, below we define a string literal
containing five examples from that web page:


``` r
some.html <- r'{
	<tr>
      <td><code>"Backspace"</code></td>
      <td>
        The <kbd>Backspace</kbd> key. This key is labeled <kbd>Delete</kbd> on
        Mac keyboards.
      </td>
      <td><code>VK_BACK</code> (0x08)</td>
      <td><code>kVK_Delete</code> (0x33)</td>
      <td>
        <code>GDK_KEY_BackSpace</code> (0xFF08)<br><code>Qt::Key_Backspace</code>
        (0x01000003)
      </td>
      <td><code>KEYCODE_DEL</code> (67)</td>
    </tr>
    <tr>
      <td><code>"Enter"</code></td>
      <td>
        The <kbd>Enter</kbd> or <kbd>↵</kbd> key (sometimes labeled
        <kbd>Return</kbd>).
      </td>
      <td><code>VK_RETURN</code> (0x0D)</td>
      <td>
        <code>kVK_Return</code> (0x24)<br><code>kVK_ANSI_KeypadEnter</code>
        (0x4C)<br><code>kVK_Powerbook_KeypadEnter</code> (0x34)
      </td>
      <td>
        <code>GDK_KEY_Return</code> (0xFF0D)<br><code>GDK_KEY_KP_Enter</code>
        (0xFF8D)<br><code>GDK_KEY_ISO_Enter</code> (0xFE34)<br><code>GDK_KEY_3270_Enter</code>
        (0xFD1E)<br><code>Qt::Key_Return</code> (0x01000004)<br><code>Qt::Key_Enter</code>
        (0x01000005)
      </td>
      <td>
        <code>KEYCODE_ENTER</code> (66)<br><code>KEYCODE_NUMPAD_ENTER</code>
        (160)<br><code>KEYCODE_DPAD_CENTER</code> (23)
      </td>
    </tr>
	<tr>
      <td><code>"ArrowDown"</code> [1]</td>
      <td>The down arrow key.</td>
      <td><code>VK_DOWN</code> (0x28)</td>
      <td><code>kVK_DownArrow</code> (0x7D)</td>
      <td>
        <code>GDK_KEY_Down</code> (0xFF54)<br><code>GDK_KEY_KP_Down</code>
        (0xFF99)<br><code>Qt::Key_Down</code> (0x01000015)
      </td>
      <td><code>KEYCODE_DPAD_DOWN</code> (20)</td>
    </tr>
    <tr>
      <td><code>"Alt"</code> [4]</td>
      <td>The <kbd>Alt</kbd> (Alternative) key.</td>
      <td>
        <code>VK_MENU</code> (0x12)<br><code>VK_LMENU</code> (0xA4)<br><code>VK_RMENU</code>
        (0xA5)
      </td>
      <td><code>kVK_Option</code> (0x3A)<br><code>kVK_RightOption</code> (0x3D)</td>
      <td>
        <code>GDK_KEY_Alt_L</code> (0xFFE9)<br><code>GDK_KEY_Alt_R</code>
        (0xFFEA)<br><code>Qt::Key_Alt</code> (0x01000023)
      </td>
      <td>
        <code>KEYCODE_ALT_LEFT</code> (57)<br><code>KEYCODE_ALT_RIGHT</code>
        (58)
      </td>
    </tr>
    <tr>
      <td><code>"Dead"</code></td>
      <td>
        <p>
          A dead "combining" key; that is, a key which is used in tandem with
          other keys to generate accented and other modified characters. If
          pressed by itself, it doesn't generate a character.
        </p>
        <p>
          If you wish to identify which specific dead key was pressed (in cases
          where more than one exists), you can do so by examining the
          <a href="/en-US/docs/Web/API/KeyboardEvent"><code>KeyboardEvent</code></a>'s associated
          <a href="/en-US/docs/Web/API/Element/compositionupdate_event" title="compositionupdate"><code>compositionupdate</code></a> event's
          <a href="/en-US/docs/Web/API/CompositionEvent/data" title="data"><code>data</code></a> property.
        </p>
      </td>
      <td></td>
      <td></td>
      <td>See <a href="#dead_keycodes_for_linux">Dead keycodes for Linux</a> below</td>
      <td></td>
    </tr>
}'
```

The examples above include the three keys used in `animint2` tests
(Backspace, Enter, ArrowDown), as well as one `Dead` entry that does
not have any corresponding hex codes ([dead
keys](https://developer.mozilla.org/en-US/docs/Web/API/UI_Events/Keyboard_event_key_values#dead_keycodes_for_linux
))., and one `Alt` entry that has more than one hex code.

To extract each DOM name from those text data, we can use my `nc`
package, as in the code below:


``` r
dom_name_pattern <- list(
  '<td><code>"',
  dom_name='[^"]+')
nc::capture_all_str(some.html, dom_name_pattern)
```

```
##     dom_name
##       <char>
## 1: Backspace
## 2:     Enter
## 3: ArrowDown
## 4:       Alt
## 5:      Dead
```

The output above is a table with five rows, one for each of the five
expected entries. Next, we try to match the rest of the entry after
the DOM name,


``` r
dom_name_rest_pattern <- list(
  dom_name_pattern,
  rest="(?:.*\n)*?",
  "    </tr>")
(dom.rest.dt <- nc::capture_all_str(some.html, dom_name_rest_pattern))
```

```
##     dom_name
##       <char>
## 1: Backspace
## 2:     Enter
## 3: ArrowDown
## 4:       Alt
## 5:      Dead
##                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          rest
##                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        <char>
## 1:                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                "</code></td>\n      <td>\n        The <kbd>Backspace</kbd> key. This key is labeled <kbd>Delete</kbd> on\n        Mac keyboards.\n      </td>\n      <td><code>VK_BACK</code> (0x08)</td>\n      <td><code>kVK_Delete</code> (0x33)</td>\n      <td>\n        <code>GDK_KEY_BackSpace</code> (0xFF08)<br><code>Qt::Key_Backspace</code>\n        (0x01000003)\n      </td>\n      <td><code>KEYCODE_DEL</code> (67)</td>\n
## 2:                                                                                                                                   "</code></td>\n      <td>\n        The <kbd>Enter</kbd> or <kbd>↵</kbd> key (sometimes labeled\n        <kbd>Return</kbd>).\n      </td>\n      <td><code>VK_RETURN</code> (0x0D)</td>\n      <td>\n        <code>kVK_Return</code> (0x24)<br><code>kVK_ANSI_KeypadEnter</code>\n        (0x4C)<br><code>kVK_Powerbook_KeypadEnter</code> (0x34)\n      </td>\n      <td>\n        <code>GDK_KEY_Return</code> (0xFF0D)<br><code>GDK_KEY_KP_Enter</code>\n        (0xFF8D)<br><code>GDK_KEY_ISO_Enter</code> (0xFE34)<br><code>GDK_KEY_3270_Enter</code>\n        (0xFD1E)<br><code>Qt::Key_Return</code> (0x01000004)<br><code>Qt::Key_Enter</code>\n        (0x01000005)\n      </td>\n      <td>\n        <code>KEYCODE_ENTER</code> (66)<br><code>KEYCODE_NUMPAD_ENTER</code>\n        (160)<br><code>KEYCODE_DPAD_CENTER</code> (23)\n      </td>\n
## 3:                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 "</code> [1]</td>\n      <td>The down arrow key.</td>\n      <td><code>VK_DOWN</code> (0x28)</td>\n      <td><code>kVK_DownArrow</code> (0x7D)</td>\n      <td>\n        <code>GDK_KEY_Down</code> (0xFF54)<br><code>GDK_KEY_KP_Down</code>\n        (0xFF99)<br><code>Qt::Key_Down</code> (0x01000015)\n      </td>\n      <td><code>KEYCODE_DPAD_DOWN</code> (20)</td>\n
## 4:                                                                                                                                                                                                                                                                                                                                                                                                 "</code> [4]</td>\n      <td>The <kbd>Alt</kbd> (Alternative) key.</td>\n      <td>\n        <code>VK_MENU</code> (0x12)<br><code>VK_LMENU</code> (0xA4)<br><code>VK_RMENU</code>\n        (0xA5)\n      </td>\n      <td><code>kVK_Option</code> (0x3A)<br><code>kVK_RightOption</code> (0x3D)</td>\n      <td>\n        <code>GDK_KEY_Alt_L</code> (0xFFE9)<br><code>GDK_KEY_Alt_R</code>\n        (0xFFEA)<br><code>Qt::Key_Alt</code> (0x01000023)\n      </td>\n      <td>\n        <code>KEYCODE_ALT_LEFT</code> (57)<br><code>KEYCODE_ALT_RIGHT</code>\n        (58)\n      </td>\n
## 5: "</code></td>\n      <td>\n        <p>\n          A dead "combining" key; that is, a key which is used in tandem with\n          other keys to generate accented and other modified characters. If\n          pressed by itself, it doesn't generate a character.\n        </p>\n        <p>\n          If you wish to identify which specific dead key was pressed (in cases\n          where more than one exists), you can do so by examining the\n          <a href="/en-US/docs/Web/API/KeyboardEvent"><code>KeyboardEvent</code></a>'s associated\n          <a href="/en-US/docs/Web/API/Element/compositionupdate_event" title="compositionupdate"><code>compositionupdate</code></a> event's\n          <a href="/en-US/docs/Web/API/CompositionEvent/data" title="data"><code>data</code></a> property.\n        </p>\n      </td>\n      <td></td>\n      <td></td>\n      <td>See <a href="#dead_keycodes_for_linux">Dead keycodes for Linux</a> below</td>\n      <td></td>\n
```

The table above contains a lot of text, but since there are only five
rows, it is actually manageable to look through. Next, we use another
regex to extract hex codes,


``` r
key_name_hex_pattern <- list(
  '<code>',
  key_name=".*?",
  '</code>',
  space='\\s+',
  '[(]0x',
  hex='.*?',
  '[)]')
nc::capture_all_str(some.html, key_name_hex_pattern)
```

```
##                      key_name      space      hex
##                        <char>     <char>   <char>
##  1:                   VK_BACK                  08
##  2:                kVK_Delete                  33
##  3:         GDK_KEY_BackSpace                FF08
##  4:         Qt::Key_Backspace \n         01000003
##  5:                 VK_RETURN                  0D
##  6:                kVK_Return                  24
##  7:      kVK_ANSI_KeypadEnter \n               4C
##  8: kVK_Powerbook_KeypadEnter                  34
##  9:            GDK_KEY_Return                FF0D
## 10:          GDK_KEY_KP_Enter \n             FF8D
## 11:         GDK_KEY_ISO_Enter                FE34
## 12:        GDK_KEY_3270_Enter \n             FD1E
## 13:            Qt::Key_Return            01000004
## 14:             Qt::Key_Enter \n         01000005
## 15:                   VK_DOWN                  28
## 16:             kVK_DownArrow                  7D
## 17:              GDK_KEY_Down                FF54
## 18:           GDK_KEY_KP_Down \n             FF99
## 19:              Qt::Key_Down            01000015
## 20:                   VK_MENU                  12
## 21:                  VK_LMENU                  A4
## 22:                  VK_RMENU \n               A5
## 23:                kVK_Option                  3A
## 24:           kVK_RightOption                  3D
## 25:             GDK_KEY_Alt_L                FFE9
## 26:             GDK_KEY_Alt_R \n             FFEA
## 27:               Qt::Key_Alt            01000023
##                      key_name      space      hex
```

The table above has one row for every occurence of the hex code in the
original data, but there is no column for DOM code. To get that, we
can use the code below:


``` r
(dom.hex.all <- dom.rest.dt[, nc::capture_all_str(
  rest, key_name_hex_pattern
), by=dom_name])
```

```
##      dom_name                  key_name      space      hex
##        <char>                    <char>     <char>   <char>
##  1: Backspace                   VK_BACK                  08
##  2: Backspace                kVK_Delete                  33
##  3: Backspace         GDK_KEY_BackSpace                FF08
##  4: Backspace         Qt::Key_Backspace \n         01000003
##  5:     Enter                 VK_RETURN                  0D
##  6:     Enter                kVK_Return                  24
##  7:     Enter      kVK_ANSI_KeypadEnter \n               4C
##  8:     Enter kVK_Powerbook_KeypadEnter                  34
##  9:     Enter            GDK_KEY_Return                FF0D
## 10:     Enter          GDK_KEY_KP_Enter \n             FF8D
## 11:     Enter         GDK_KEY_ISO_Enter                FE34
## 12:     Enter        GDK_KEY_3270_Enter \n             FD1E
## 13:     Enter            Qt::Key_Return            01000004
## 14:     Enter             Qt::Key_Enter \n         01000005
## 15: ArrowDown                   VK_DOWN                  28
## 16: ArrowDown             kVK_DownArrow                  7D
## 17: ArrowDown              GDK_KEY_Down                FF54
## 18: ArrowDown           GDK_KEY_KP_Down \n             FF99
## 19: ArrowDown              Qt::Key_Down            01000015
## 20:       Alt                   VK_MENU                  12
## 21:       Alt                  VK_LMENU                  A4
## 22:       Alt                  VK_RMENU \n               A5
## 23:       Alt                kVK_Option                  3A
## 24:       Alt           kVK_RightOption                  3D
## 25:       Alt             GDK_KEY_Alt_L                FFE9
## 26:       Alt             GDK_KEY_Alt_R \n             FFEA
## 27:       Alt               Qt::Key_Alt            01000023
##      dom_name                  key_name      space      hex
```

The output above has the `dom_name` column in addition to the others
shown previously. To just get the windows virtual key codes, we can do:


``` r
(dom.hex.windows <- dom.hex.all[grepl("^VK_", key_name)])
```

```
##     dom_name  key_name      space    hex
##       <char>    <char>     <char> <char>
## 1: Backspace   VK_BACK                08
## 2:     Enter VK_RETURN                0D
## 3: ArrowDown   VK_DOWN                28
## 4:       Alt   VK_MENU                12
## 5:       Alt  VK_LMENU                A4
## 6:       Alt  VK_RMENU \n             A5
```

In the code below we keep just the first windows key code found:


``` r
(dom.hex.first <- dom.hex.windows[, .SD[1], by=dom_name])
```

```
##     dom_name  key_name  space    hex
##       <char>    <char> <char> <char>
## 1: Backspace   VK_BACK            08
## 2:     Enter VK_RETURN            0D
## 3: ArrowDown   VK_DOWN            28
## 4:       Alt   VK_MENU            12
```

We see that these DOM key names and windows virtual key codes are
consistent with those in the existing `animint2` tests:


``` r
animint2.expected
```

```
##     dom_name  key_name    hex
##       <char>    <char> <char>
## 1: Backspace   VK_BACK     08
## 2:     Enter VK_RETURN     0D
## 3: ArrowDown   VK_DOWN     28
```

### Making a function

Next, make a function which runs the whole process from beginning to end.


``` r
get_dom_win_hex <- function(in.html){
  nc::capture_all_str(
    in.html, dom_name_rest_pattern
  )[, {
    nc::capture_all_str(
      rest, key_name_hex_pattern
    )[
      grepl("^VK_", key_name), .SD[1]
    ]
  }, by=dom_name]
}
get_dom_win_hex(some.html)
```

```
##     dom_name  key_name  space    hex
##       <char>    <char> <char> <char>
## 1: Backspace   VK_BACK            08
## 2:     Enter VK_RETURN            0D
## 3: ArrowDown   VK_DOWN            28
## 4:       Alt   VK_MENU            12
## 5:      Dead      <NA>   <NA>   <NA>
```

The table above additionally contains rows with `NA` for DOM names
that had no corresponding hex codes.

### Using it on the whole data set


``` r
(full_win_codes <- get_dom_win_hex(html.lines))
```

```
##          dom_name     key_name  space    hex
##            <char>       <char> <char> <char>
##   1: Unidentified         <NA>   <NA>   <NA>
##   2:          Alt      VK_MENU            12
##   3:     AltGraph         <NA>   <NA>   <NA>
##   4:     CapsLock   VK_CAPITAL            14
##   5:      Control   VK_CONTROL            11
##  ---                                        
## 314:          Add       VK_ADD            6B
## 315:       Divide    VK_DIVIDE            6F
## 316:     Subtract  VK_SUBTRACT            6D
## 317:    Separator VK_SEPARATOR            6C
## 318:            0   VK_NUMPAD0            60
```

The table above could be used to define a new `key2hex_code` variable,
which would expand the keys supported in `animint2` tests:


``` r
key2hex_code <- full_win_codes[, structure(hex, names=dom_name)]
dput(key2hex_code)
```

```
## c(Unidentified = NA, Alt = "12", AltGraph = NA, CapsLock = "14", 
## Control = "11", Fn = NA, FnLock = NA, Hyper = NA, Meta = "5B", 
## NumLock = "90", ScrollLock = "91", Shift = "10", Super = NA, 
## Symbol = NA, SymbolLock = NA, Enter = "0D", Tab = "09", ` ` = "20", 
## ArrowDown = "28", ArrowLeft = "25", ArrowRight = "27", ArrowUp = "26", 
## End = "23", Home = "24", PageDown = "22", PageUp = "21", Backspace = "08", 
## Clear = "0C", Copy = NA, CrSel = "F7", Cut = NA, Delete = "2E", 
## EraseEof = "F9", ExSel = "F8", Insert = "2D", Paste = NA, Redo = NA, 
## Undo = NA, Accept = "1E", Again = NA, Attn = "F0", Cancel = NA, 
## ContextMenu = "5D", Escape = "1B", Execute = "2B", Find = NA, 
## Finish = "F1", Help = "2F", Pause = "13", Play = "FA", Props = NA, 
## Select = "29", ZoomIn = NA, ZoomOut = NA, BrightnessDown = NA, 
## BrightnessUp = NA, Eject = NA, LogOff = NA, Power = NA, PowerOff = NA, 
## PrintScreen = "2C", Hibernate = NA, Standby = "5F", WakeUp = NA, 
## AllCandidates = NA, Alphanumeric = "F0", CodeInput = NA, Compose = NA, 
## Convert = "1C", Dead = NA, FinalMode = "18", GroupFirst = NA, 
## GroupLast = NA, GroupNext = NA, GroupPrevious = NA, ModeChange = "1F", 
## NextCandidate = NA, NonConvert = "1D", PreviousCandidate = NA, 
## Process = "E5", SingleCandidate = NA, HangulMode = "15", HanjaMode = "19", 
## JunjaMode = "17", Eisu = NA, Hankaku = "F3", Hiragana = "F2", 
## HiraganaKatakana = NA, KanaMode = "15", KanjiMode = NA, Katakana = "F1", 
## Romaji = "F5", Zenkaku = "F4", ZenkakuHanaku = NA, F1 = "70", 
## F2 = "71", F3 = "72", F4 = "73", F5 = "74", F6 = "75", F7 = "76", 
## F8 = "77", F9 = "78", F10 = "79", F11 = "7A", F12 = "7B", F13 = "7C", 
## F14 = "7D", F15 = "7E", F16 = "7F", F17 = "80", F18 = "81", F19 = "82", 
## F20 = "83", Soft1 = NA, Soft2 = NA, Soft3 = NA, Soft4 = NA, AppSwitch = NA, 
## Call = NA, Camera = NA, CameraFocus = NA, EndCall = NA, GoBack = NA, 
## GoHome = NA, HeadsetHook = NA, LastNumberRedial = NA, Notification = NA, 
## MannerMode = NA, VoiceDial = NA, ChannelDown = NA, ChannelUp = NA, 
## MediaFastForward = NA, MediaPause = NA, MediaPlay = NA, MediaPlayPause = "B3", 
## MediaRecord = NA, MediaRewind = NA, MediaStop = "B2", MediaTrackNext = "B0", 
## MediaTrackPrevious = "B1", AudioBalanceLeft = NA, AudioBalanceRight = NA, 
## AudioBassDown = NA, AudioBassBoostDown = NA, AudioBassBoostToggle = NA, 
## AudioBassBoostUp = NA, AudioBassUp = NA, AudioFaderFront = NA, 
## AudioFaderRear = NA, AudioSurroundModeNext = NA, AudioTrebleDown = NA, 
## AudioTrebleUp = NA, AudioVolumeDown = "AE", AudioVolumeMute = "AD", 
## AudioVolumeUp = "AF", MicrophoneToggle = NA, MicrophoneVolumeDown = NA, 
## MicrophoneVolumeMute = NA, MicrophoneVolumeUp = NA, TV = NA, 
## TV3DMode = NA, TVAntennaCable = NA, TVAudioDescription = NA, 
## TVAudioDescriptionMixDown = NA, TVAudioDescriptionMixUp = NA, 
## TVContentsMenu = NA, TVDataService = NA, TVInput = NA, TVInputComponent1 = NA, 
## TVInputComponent2 = NA, TVInputComposite1 = NA, TVInputComposite2 = NA, 
## TVInputHDMI1 = NA, TVInputHDMI2 = NA, TVInputHDMI3 = NA, TVInputHDMI4 = NA, 
## TVInputVGA1 = NA, TVMediaContext = NA, TVNetwork = NA, TVNumberEntry = NA, 
## TVPower = NA, TVRadioService = NA, TVSatellite = NA, TVSatelliteBS = NA, 
## TVSatelliteCS = NA, TVSatelliteToggle = NA, TVTerrestrialAnalog = NA, 
## TVTerrestrialDigital = NA, TVTimer = NA, AVRInput = NA, AVRPower = NA, 
## ColorF0Red = NA, ColorF1Green = NA, ColorF2Yellow = NA, ColorF3Blue = NA, 
## ColorF4Grey = NA, ColorF5Brown = NA, ClosedCaptionToggle = NA, 
## Dimmer = NA, DisplaySwap = NA, DVR = NA, Exit = NA, FavoriteClear0 = NA, 
## FavoriteClear1 = NA, FavoriteClear2 = NA, FavoriteClear3 = NA, 
## FavoriteRecall0 = NA, FavoriteRecall1 = NA, FavoriteRecall2 = NA, 
## FavoriteRecall3 = NA, FavoriteStore0 = NA, FavoriteStore1 = NA, 
## FavoriteStore2 = NA, FavoriteStore3 = NA, Guide = NA, GuideNextDay = NA, 
## GuidePreviousDay = NA, Info = NA, InstantReplay = NA, Link = NA, 
## ListProgram = NA, LiveContent = NA, Lock = NA, MediaApps = NA, 
## MediaAudioTrack = NA, MediaLast = NA, MediaSkipBackward = NA, 
## MediaSkipForward = NA, MediaStepBackward = NA, MediaStepForward = NA, 
## MediaTopMenu = NA, NavigateIn = NA, NavigateNext = NA, NavigateOut = NA, 
## NavigatePrevious = NA, NextFavoriteChannel = NA, NextUserProfile = NA, 
## OnDemand = NA, Pairing = NA, PinPDown = NA, PinPMove = NA, PinPToggle = NA, 
## PinPUp = NA, PlaySpeedDown = NA, PlaySpeedReset = NA, PlaySpeedUp = NA, 
## RandomToggle = NA, RcLowBattery = NA, RecordSpeedNext = NA, RfBypass = NA, 
## ScanChannelsToggle = NA, ScreenModeNext = NA, Settings = NA, 
## SplitScreenToggle = NA, STBInput = NA, STBPower = NA, Subtitle = NA, 
## Teletext = NA, VideoModeNext = NA, Wink = NA, ZoomToggle = "FB", 
## SpeechCorrectionList = NA, SpeechInputToggle = NA, Close = NA, 
## New = NA, Open = NA, Print = NA, Save = NA, SpellCheck = NA, 
## MailForward = NA, MailReply = NA, MailSend = NA, LaunchCalculator = NA, 
## LaunchCalendar = NA, LaunchContacts = NA, LaunchMail = "B4", 
## LaunchMediaPlayer = "B5", LaunchMusicPlayer = NA, LaunchMyComputer = NA, 
## LaunchPhone = NA, LaunchScreenSaver = NA, LaunchSpreadsheet = NA, 
## LaunchWebBrowser = NA, LaunchWebCam = NA, LaunchWordProcessor = NA, 
## LaunchApplication1 = "B6", LaunchApplication2 = "B7", LaunchApplication3 = NA, 
## LaunchApplication4 = NA, LaunchApplication5 = NA, LaunchApplication6 = NA, 
## LaunchApplication7 = NA, LaunchApplication8 = NA, LaunchApplication9 = NA, 
## LaunchApplication10 = NA, LaunchApplication11 = NA, LaunchApplication12 = NA, 
## LaunchApplication13 = NA, LaunchApplication14 = NA, LaunchApplication15 = NA, 
## LaunchApplication16 = NA, BrowserBack = "A6", BrowserFavorites = "AB", 
## BrowserForward = "A7", BrowserHome = "AC", BrowserRefresh = "A8", 
## BrowserSearch = "AA", BrowserStop = "A9", Decimal = "6E", Key11 = NA, 
## Key12 = NA, Multiply = "6A", Add = "6B", Divide = "6F", Subtract = "6D", 
## Separator = "6C", `0` = "60")
```

### Conclusions

When refactoring `animint2` tests to use chromote, we saw how to use
regex to extract a table of hex codes from a web page with DOM key
names.

### Session info


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
## [1] data.table_1.15.99
## 
## loaded via a namespace (and not attached):
## [1] compiler_4.4.1 nc_2024.2.21   tools_4.4.1    knitr_1.47     xfun_0.45      evaluate_0.23
```
