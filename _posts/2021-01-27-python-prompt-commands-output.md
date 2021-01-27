---
layout: post
title: Emulating the python interactive console
description: My hack using the code module
---

Yesterday and today I had students in my CS470/570 AI class ask me
about how we were supposed to get python output like

```python
>>> add(1, 2)
3

>>> add(3, 4)
7

```

You can use the `python` command to start up the REPL, then paste your
code, and you should get output as above.

Almost. By default there is no newline before the prompt, but you can
get that by resetting
[sys.ps1](https://docs.python.org/3/library/sys.html#sys.ps1),

```python
import sys
sys.ps1 = "\n>>>"
```

But is there a way to run a python script such that the prompt, input,
and output are printed? (without having to copy-paste the code into
the interactive REPL)

In R this is easy, just run `R` on the command line, redirect an R
script to its standard input, and set the `prompt` option in that
script:

```r
$ R --quiet --vanilla < add.R 
> options(prompt="\n> ")

> add <- function(x,y){
+   x+y
+ }

> add(1,2)
[1] 3

> add(3,4)
[1] 7

```

I was thinking there would be a [python command line
option](https://docs.python.org/3/using/cmdline.html) which would
allow this easily, but I did not find one.
Instead I hacked my own solution which I called
[interpreter.py](https://github.com/tdhock/cs470-570-spring-2021/blob/master/interpreter.py). 

It uses the
[code](https://github.com/python/cpython/blob/master/Lib/code.py)
module, which provides all sorts of functionality related to the REPL,
including the `InteractiveConsole` class. Docs for its
[raw_input](https://docs.python.org/3/library/code.html#code.InteractiveConsole.raw_input)
method mention that "The base implementation reads from sys.stdin; a
subclass may replace this with a different implementation."  That
suggested to me that we can define a subclass which takes `raw_input`
from a python script on disk rather than from stdin. 

The `raw_input` method was not super well documented so I had to look
at the source code and do some trial and error, but I eventually
figured out that

* it should read one line of code (InteractiveConsole reads from
  stdin, my subclass reads from a text file on disk).
* if there is nothing else to read (no more lines of code) then
  `EOFError` should be raised.
* it should print the prompt as well as the code.
* it should return a string, line of code with no newline at the end.

That results in the new subclass,

```python
import code
class FileConsole(code.InteractiveConsole):
    """Emulate python console but use file instead of stdin"""
    def raw_input(self, prompt):
        line = f.readline()
        if line=="":
            raise EOFError()
        print(prompt, line.replace("\n", ""))
        return line
```

Note in the code above we assume that `f` is the file handle from
which we want to read lines. To use this class to get the desired
output, we can use the code below:

```python
import sys
sys.ps1 = "\n>>>"
f = open(sys.argv[1])
FileConsole().interact(banner="", exitmsg="")
```

The code above first adds a newline to the prompt, then opens the file
specified as the first command line argument, then instantiates a
`FileConsole` and calls its `interact` method (which repeatedly calls
`raw_input` until `EOFError` is raised). The `banner` and `exitmsg`
arguments specify that nothing should be printed at the start and end
of the console.

Now assume we have a python script file `add.py` as below that we
would like to process just as if we copied its code and pasted it into
the python interpreter:

```python
def add(x, y):
    return x + y
add(1, 2)
add(3, 4)
```

The result of running the above `add.py` script through
[interpreter.py](https://github.com/tdhock/cs470-570-spring-2021/blob/master/interpreter.py)
is

```bash
$ python interpreter.py add.py

>>> def add(x, y):
...      return x + y

>>> add(1, 2)
3

>>> add(3, 4)
7

```

And actually this is more flexible than the copy-paste method because
that results in a `SyntaxError` because in the `add.py` script there
is no empty line after the function definition,

```bash
$ python
Python 3.7.6 (default, Jan  8 2020, 19:59:22) 
[GCC 7.3.0] :: Anaconda, Inc. on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> def add(x, y):
...     return x + y
... add(1, 2)
  File "<stdin>", line 3
    add(1, 2)
      ^
SyntaxError: invalid syntax
>>> add(3, 4)
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
NameError: name 'add' is not defined
```
Overall this
[interpreter.py](https://github.com/tdhock/cs470-570-spring-2021/blob/master/interpreter.py)
python script seems pretty complicated compared to the R solution ---
is there an easier way to do this in python?
