---
layout: post
title: No argument unpacking in C
description: But there is in R and Python
---

Today I was wondering if it is possible to do argument unpacking in
C. What is argument unpacking? It is a super useful programming
technique which allows you to use data instead of code to define how
you want to call a function. For example in python we can unpack a
list to positional arguments via


```python
def fun(left, right):
    return left*2 + right
args = [5, 3]
fun(args[0], args[1])
```

```
## 13
```

```python
fun(*args) # same as above!
```

```
## 13
```

And we can unpack a dict to named arguments via


```python
kwargs = {"right":3, "left":5}
fun(right=kwargs["right"], left=kwargs["left"])
```

```
## 13
```

```python
fun(**kwargs) # same as above!
```

```
## 13
```

In R the equivalent is 


```r
fun <- function(left, right)left*2 + right
## Unpacking un-named list to positional arguments.
args.list <- list(5, 3)
fun(args.list[[1]], args.list[[2]])
```

```
## [1] 13
```

```r
do.call(fun, args.list) # same as above!
```

```
## [1] 13
```

```r
## Unpacking named list to named arguments.
kwargs.list <- list(right=3, left=5)
fun(right=kwargs.list$right, left=kwargs.list$left)
```

```
## [1] 13
```

```r
do.call(fun, kwargs.list) # same as above!
```

```
## [1] 13
```

Exercise for the reader: you can do named/positional unpacking at the
same time in both R (via a list with named and un-named elements) and
python (by using star and double star in the same call). That is
probably confusing and I would recommend avoiding if at all possible.

## Variable number of arguments

I was wondering, can we do something similar in C? I did not see any
mention in the C book [Chapter 4,
function](https://webhome.phy.duke.edu/~rgb/General/c_book/c_book/chapter4/index.html)
nor [Section 5.6, Pointers to
functions](https://webhome.phy.duke.edu/~rgb/General/c_book/c_book/chapter5/function_pointers.html). [Section
9.9 Variable numbers of
arguments](https://webhome.phy.duke.edu/~rgb/General/c_book/c_book/chapter9/stdarg.html)
discusses the inverse concept: defining a function which allows a
variable number of arguments. Whereas argument unpacking is used to
turn data into function arguments, variable arguments allows turning
code/arguments into data. For example in python we can designate a
list variable to capture all positional arguments via single star:


```python
def sum_of_squares(*args):
    return sum([x**2 for x in args])
sum_of_squares(1)
```

```
## 1
```

```python
sum_of_squares(2, 3)
```

```
## 13
```

And we can designate a dict variable to capture all keyword arguments
using the double star:


```python
def print_names_values(**kwargs):
    for name, value in kwargs.items():
        print("name=%s, value=%s"%(name,value))
print_names_values(a=1)
```

```
## name=a, value=1
```

```python
print_names_values(b=2, c=3)
```

```
## name=b, value=2
## name=c, value=3
```

Similarly in R we can do


```r
## ... with un-named arguments:
sum_of_squares <- function(...)sum(c(...)^2)
sum_of_squares(1)
```

```
## [1] 1
```

```r
sum_of_squares(2,3)
```

```
## [1] 13
```

```r
## ... with named arguments:
print_names_values <- function(...){
  named.vec <- c(...)
  out.vec <- sprintf("name=%s value=%s\n", names(named.vec), named.vec)
  cat(out.vec, sep="")
}
print_names_values(a=1)
```

```
## name=a value=1
```

```r
print_names_values(b=2, c=3)
```

```
## name=b value=2
## name=c value=3
```

In R it is somewhat more complicated than python as `...` is a unique
data type, which is typically used with `c(...)` or `list(...)` to
create a (possibly named) vector or list from the arguments.

In C we use [stdarg.h](https://www.cplusplus.com/reference/cstdarg/)
macros/functions `va_start(va_list my_list, last_arg_before_dots)`,
`value=va_arg(my_list, type)`, `va_end(my_list)`. Note that there must
be at least one other argument which defines how many additional
arguments there are, for example an int number of arguments, or the
first arg of printf which is parsed to determine the number of format
substrings such as `%d` present.

## How does R implement argument unpacking for C functions?

The R system is implemented in C, and it supports calling user-defined
C/C++/FORTRAN functions, each with a user-defined number of
arguments. For example
[penaltyLearning/src/interface.cpp](https://github.com/tdhock/penaltyLearning/blob/master/src/interface.cpp)
defines several interface functions, each with a different number of
arguments. We use a `R_CMethodDef` array to associate each C function
pointer with a name and an expected number of arguments,

```c
R_CMethodDef cMethods[] = {
	{"modelSelectionQuadratic_interface", (DL_FUNC) &modelSelectionQuadratic_interface, 5},
	{"modelSelectionFwd_interface", (DL_FUNC) &modelSelectionFwd_interface, 6},
	{"modelSelection_interface", (DL_FUNC) &modelSelection_interface, 5},
	{"largestContinuousMinimum_interface", (DL_FUNC) &largestContinuousMinimum_interface, 4},
	{NULL, NULL, 0}
};
```

Similarly, when we use the excellent Rcpp interface, a
[RcppExports.cpp](https://github.com/tdhock/FLOPART/blob/master/src/RcppExports.cpp)
file is generated with a similar `R_CallMethodDef` array:

```c++
static const R_CallMethodDef CallEntries[] = {
    {"_FLOPART_get_label_code", (DL_FUNC) &_FLOPART_get_label_code, 0},
    {"_FLOPART_FLOPART_interface", (DL_FUNC) &_FLOPART_FLOPART_interface, 6},
    {NULL, NULL, 0}
};
```

Again the code above associates each C function pointer with a name
and an expected number of arguments. So in the C source code of R,
there must be something that calls these functions using these
pointers with a list of data from R, similar to argument
unpacking. How does that work?

Looking in [src/main/dotcode.c in R source
code](https://github.com/wch/r-source/blob/trunk/src/main/dotcode.c)
shows that there is a huge block of code with a switch over the number
of arguments:

```
SEXP attribute_hidden R_doDotCall(DL_FUNC ofun, int nargs, SEXP *cargs,
				  SEXP call) {
    VarFun fun = NULL;
    SEXP retval = R_NilValue;	/* -Wall */
    fun = (VarFun) ofun;
    switch (nargs) {
    case 0:
	retval = (SEXP)ofun();
	break;
    case 1:
	retval = (SEXP)fun(cargs[0]);
	break;
    case 2:
	retval = (SEXP)fun(cargs[0], cargs[1]);
	break;
...
    case 65:
	retval = (SEXP)fun(
	    cargs[0],  cargs[1],  cargs[2],  cargs[3],  cargs[4],
	    cargs[5],  cargs[6],  cargs[7],  cargs[8],  cargs[9],
	    cargs[10], cargs[11], cargs[12], cargs[13], cargs[14],
	    cargs[15], cargs[16], cargs[17], cargs[18], cargs[19],
	    cargs[20], cargs[21], cargs[22], cargs[23], cargs[24],
	    cargs[25], cargs[26], cargs[27], cargs[28], cargs[29],
	    cargs[30], cargs[31], cargs[32], cargs[33], cargs[34],
	    cargs[35], cargs[36], cargs[37], cargs[38], cargs[39],
	    cargs[40], cargs[41], cargs[42], cargs[43], cargs[44],
	    cargs[45], cargs[46], cargs[47], cargs[48], cargs[49],
	    cargs[50], cargs[51], cargs[52], cargs[53], cargs[54],
	    cargs[55], cargs[56], cargs[57], cargs[58], cargs[59],
	    cargs[60], cargs[61], cargs[62], cargs[63], cargs[64]);
	break;
    default:
	errorcall(call, _("too many arguments, sorry"));
    }
    return retval;
}
```

So the C source code of R does not show any evidence of any special
unpacking syntax.

## How does python do it?

How does Python call C code? For example I recently coded
[interface.c](https://github.com/tdhock/model_selection_breakpoints/blob/master/interface.c)
which defines a python/C++ interface function
ModelSelectionInterface. It is declared as using `METH_VARARGS` which
means there are always two arguments, as documented in [Common Object
Structures](https://docs.python.org/3/c-api/structures.html#METH_VARARGS):
"This is the typical calling convention, where the methods have the
type PyCFunction. The function expects two PyObject* values. The first
one is the self object for methods; for module functions, it is the
module object. The second parameter (often called args) is a tuple
object representing all arguments." That doc page explains that Python
allows several other `METH_SOMETHING` values, each of which have a
specified number of arguments, one or more of which is a tuple/array
representing any number of arguments. So python does not have a limit
on the number of arguments, except for the size of a tuple/array. 
In python the number and types of arguments are defined by
`PyArg_ParseTuple` which is arguably cleaner than the R solution.

## What about C++?

Does argument unpacking exist in C++? Yes, since C++17 or C++20. There
is some support via
[std::apply](https://en.cppreference.com/w/cpp/utility/apply) (for
callables, [here is another blog post with a discussion and
example](https://www.rangakrish.com/index.php/2018/10/14/c17-stdapply-and-stdinvoke/))
and
[std::make_from_tuple](https://en.cppreference.com/w/cpp/utility/make_from_tuple)
(for instantiation/construction).
Could R be re-implemented in C++ to
take advantage of this new feature, and avoid that huge switch block?
For the `.Call` interface it could, because it could use std::apply
with a tuple of SEXP. For the `.C` interface it could do something
similar with tuple of pointers to int/double/etc.

What about the inverse operation, variable number of arguments? The
C++ equivalent of C's `va_arg` etc is described as variadic on
[parameter_pack](https://en.cppreference.com/w/cpp/language/parameter_pack).

