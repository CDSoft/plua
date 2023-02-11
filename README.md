- [Pandoc Lua interpreter and REPL](#pandoc-lua-interpreter-and-repl)
  - [Compilation](#compilation)
  - [Installation](#installation)
  - [PLua artifacts](#plua-artifacts)
  - [Usage](#usage)
  - [Examples](#examples)
- [PLua improved REPL](#plua-improved-repl)
  - [PLua interactive usage](#plua-interactive-usage)
  - [Additional functions](#additional-functions)
- [PLua library](#plua-library)
  - [F: Functional programming
    utilities](#f-functional-programming-utilities)
  - [L: Pandoc List package](#l-pandoc-list-package)
  - [fs: File System](#fs-file-system)
  - [sh: Shell](#sh-shell)
  - [sys: System module](#sys-system-module)
  - [crypt: cryptography module](#crypt-cryptography-module)
  - [prompt: Prompt module](#prompt-prompt-module)
  - [Serialization](#serialization)
  - [argparse: feature-rich command line parser for
    Lua](#argparse-feature-rich-command-line-parser-for-lua)
- [License](#license)

------------------------------------------------------------------------

# Pandoc Lua interpreter and REPL

`plua` is a Lua interpreter and REPL based on Pandoc and Lua, augmented
with some useful packages. It comes with `pluac` which can produce
standalone scripts from Lua scripts. The only requirement is Pandoc 3.

These scripts can run on any Linux-like environment where Pandoc can run
(Linux, MacOS, Cygwin, WSL, …).

## Compilation

`plua` is written in Lua (Lua interpreter provided by Pandoc). Just
download `plua` (<https://github.com/CDSoft/plua>) and run `make`:

``` sh
$ git clone https://github.com/CDSoft/plua
$ cd plua
$ make                  # compile and test
```

## Installation

``` sh
$ make install              # install plua to ~/.local/bin or ~/bin
$ make install PREFIX=/usr  # install plua to /usr/bin
```

## PLua artifacts

`make install` installs:

- `$PREFIX/bin/plua`: PLua REPL (REPL executed in the Lua interpreter
  provided by Pandoc.
- `$PREFIX/bin/pluac`: PLua “compiler” (bundles Lua scripts in a single
  executable script).
- `$PREFIX/lib/plua.zip`: PLua libraries used by `pluac` to build
  executable scripts (non needed to execute these scripts).
- `$PREFIX/lib/plua.lua`: PLua libraries as a single Lua module
  (e.g. for usage in Pandoc Lua filters).

## Usage

### `plua` interpreter

`plua` is very similar to `lua` and provides a more user friendly
interface.

     ____  _                 |  http://cdelord.fr/plua
    |  _ \| |   _   _  __ _  |
    | |_) | |  | | | |/ _` | |  Version X.Y
    |  __/| |__| |_| | (_| | |  Powered by Lua X.Y
    |_|   |_____\__,_|\__,_| |  and Pandoc X.Y
                             |  on <OS> <ARCH>

    usage: plua [options] [script [args]]

    General options:
      -h            show this help
      -v            show version information
      --            stop handling options

    Lua options:
      -e stat       execute string 'stat'
      -i            enter interactive mode after executing 'script'
      -l name       require library 'name' into global 'name'
      -             stop handling options and execute stdin
                    (incompatible with -i)

    Environment variables:

      LUA_INIT_5_4, LUA_INIT
                    code executed before handling command line options
                    and scripts.
                    When LUA_INIT_5_4 is defined, LUA_INIT is ignored.

### `pluac` « compiler »

`pluac` produces a standalone script containing a set of Lua scripts.

    Overview: Pandoc Lua Compiler

    Usage: pluac [-h] [-v] [-r] -o <output> [<script.lua> ...]

    Options:
        -h              print this help and exits
        -v              verbose output
        -r              use rlwrap
        -o filename     set the output filename
        filename        use filename as a library

    Scripts can contain tags:
        @RUN    run the script with require before the main script
        @LOAD   run the script with require
                and store the module in a global variable
        @MAIN   main script run after other scripts

    The output Lua script requires pandoc to be executed.

    For further details, please see:
    <http://cdelord.fr/plua>

## Examples

### `plua`

`plua` executes Lua scripts:

    $ cat demo.lua
    local xs = F.range(100)
    local sum = xs:sum()

    print("sum of "..xs:head().." + ... + "..xs:last().." = "..sum)

    $ plua demo.lua
    sum of 1 + ... + 100 = 5050

and provides a nice REPL:

    $ plua
     ____  _                 |  http://cdelord.fr/plua
    |  _ \| |   _   _  __ _  |
    | |_) | |  | | | |/ _` | |  Version X.Y
    |  __/| |__| |_| | (_| | |  Powered by Lua X.Y
    |_|   |_____\__,_|\__,_| |  and Pandoc X.Y
                             |  on <OS> <ARCH>

    >> F.range(10):map(function(x) return 2*x end)
    {2, 4, 6, 8, 10, 12, 14, 16, 18, 20}

    >> ast = pandoc.read "Nice *Pandoc* and **Lua** integration"

    >> pandoc.write(ast, "html")
    "<p>Nice <em>Pandoc</em> and <strong>Lua</strong> integration</p>"

### `pluac`

    $ pluac -v demo.lua -o demo
    demo.lua: ok
    demo: zip demo.lua
      adding: demo.lua (deflated 18%)
    demo.lua: main script (require "demo")
    demo: 34024 bytes written

    $ ./demo
    sum of 1 + ... + 100 = 5050

# PLua improved REPL

## PLua interactive usage

The PLua REPL uses the Lua interpreter provided by Pandoc.

``` sh
$ plua
```

The integration with Pandoc is interesting to debug Pandoc Lua filters
and inspect Pandoc AST. E.g.:

    $ plua

     ____  _                 |  http://cdelord.fr/plua
    |  _ \| |   _   _  __ _  |
    | |_) | |  | | | |/ _` | |  Version X.Y
    |  __/| |__| |_| | (_| | |  Powered by Lua X.Y
    |_|   |_____\__,_|\__,_| |  and Pandoc X.Y
                             |  on <OS> <ARCH>

    >> pandoc.read "*Pandoc* is **great**!"
    Pandoc (Meta {unMeta = fromList []}) [Para [Emph [Str "Pandoc"],Space,Str "is",Space,Strong [Str "great"],Str "!"]]

Note that [rlwrap](https://github.com/hanslub42/rlwrap) can be used to
give nice edition facilities to the Pandoc Lua interpreter.

## Additional functions

The `plua` repl provides a few functions for the interactive mode.

In interactive mode, these functions are available as global functions.
`F.show` is used by the PLua REPL to print results.

``` lua
show(x)
```

returns a string representing `x` with nice formatting for tables and
numbers.

``` lua
precision(len, frac)
```

changes the format of floats. `len` is the total number of characters
and `frac` the number of decimals after the floating point (`frac` can
be `nil`). `len` can also be a string (custom format string) or `nil`
(to reset the float format). `b` can be `10` (decimal numbers), `16`
(hexadecimal numbers), `8` (octal numbers), a custom format string or
`nil` (to reset the integer format).

``` lua
base(b)
```

changes the format of integers. `b` can be `10` (decimal numbers), `16`
(hexadecimal numbers), `8` (octal numbers), a custom format string or
`nil` (to reset the integer format).

``` lua
indent(i)
```

indents tables (`i` spaces). If `i` is `nil`, tables are not indented.

``` lua
prints(x)
```

prints `show(x)`

``` lua
inspect(x)
```

calls `inspect(x)` to build a human readable representation of `x` (see
the `inspect` package).

``` lua
printi(x)
```

prints `inspect(x)` (without the metatables).

# PLua library

## F: Functional programming utilities

``` lua
local F = require "F"
```

`F` provides some useful functions inspired by functional programming
languages, especially by these Haskell modules:

- [`Data.List`](https://hackage.haskell.org/package/base-4.17.0.0/docs/Data-List.html)
- [`Data.Map`](https://hackage.haskell.org/package/containers-0.6.6/docs/Data-Map.html)
- [`Data.String`](https://hackage.haskell.org/package/base-4.17.0.0/docs/Data-String.html)
- [`Prelude`](https://hackage.haskell.org/package/base-4.17.0.0/docs/Prelude.html)

### Standard types, and related functions

#### Operators

``` lua
F.op.land(a, b)             -- a and b
F.op.lor(a, b)              -- a or b
F.op.lxor(a, b)             -- (not a and b) or (not b and a)
F.op.lnot(a)                -- not a
```

> Logical operators

``` lua
F.op.band(a, b)             -- a & b
F.op.bor(a, b)              -- a | b
F.op.bxor(a, b)             -- a ~ b
F.op.bnot(a)                -- ~a
F.op.shl(a, b)              -- a << b
F.op.shr(a, b)              -- a >> b
```

> Bitwise operators

``` lua
F.op.eq(a, b)               -- a == b
F.op.ne(a, b)               -- a ~= b
F.op.lt(a, b)               -- a < b
F.op.le(a, b)               -- a <= b
F.op.gt(a, b)               -- a > b
F.op.ge(a, b)               -- a >= b
```

> Comparison operators

``` lua
F.op.ueq(a, b)              -- a == b  (†)
F.op.une(a, b)              -- a ~= b  (†)
F.op.ult(a, b)              -- a < b   (†)
F.op.ule(a, b)              -- a <= b  (†)
F.op.ugt(a, b)              -- a > b   (†)
F.op.uge(a, b)              -- a >= b  (†)
```

> Universal comparison operators ((†) comparisons on elements of
> possibly different Lua types)

``` lua
F.op.add(a, b)              -- a + b
F.op.sub(a, b)              -- a - b
F.op.mul(a, b)              -- a * b
F.op.div(a, b)              -- a / b
F.op.idiv(a, b)             -- a // b
F.op.mod(a, b)              -- a % b
F.op.neg(a)                 -- -a
F.op.pow(a, b)              -- a ^ b
```

> Arithmetic operators

``` lua
F.op.concat(a, b)           -- a .. b
F.op.len(a)                 -- #a
```

> String/list operators

#### Basic data types

``` lua
F.maybe(b, f, a)
```

> Returns f(a) if f(a) is not nil, otherwise b

``` lua
F.default(def, x)
```

> Returns x if x is not nil, otherwise def

``` lua
F.case(x) {
    { t1, v1 },
    ...
    { tn, vn }
}
```

> returns the first `vi` such that `ti == x`. If `ti` is a function, it
> is applied to `x` and the test becomes `ti(x) == x`. If `vi` is a
> function, the value returned by `F.case` is `vi(x)`.

``` lua
F.when {
    { t1, v1 },
    ...
    { tn, vn }
}
```

> returns the first `vi` such that `ti` is true. If `ti` is a function,
> the test becomes `ti()`. If `vi` is a function, the value returned by
> `F.when` is `vi()`.

``` lua
F.otherwise
```

> `F.otherwise` is used with `F.case` and `F.when` to add a default
> branch.

##### Tuples

``` lua
F.fst(xs)
xs:fst()
```

> Extract the first component of a list.

``` lua
F.snd(xs)
xs:snd()
```

> Extract the second component of a list.

``` lua
F.thd(xs)
xs:thd()
```

> Extract the third component of a list.

``` lua
F.nth(n, xs)
xs:nth(n)
```

> Extract the n-th component of a list.

#### Basic type classes

``` lua
F.comp(a, b)
```

> Comparison (-1, 0, 1)

``` lua
F.ucomp(a, b)
```

> Comparison (-1, 0, 1) (using universal comparison operators)

``` lua
F.max(a, b)
```

> max(a, b)

``` lua
F.min(a, b)
```

> min(a, b)

``` lua
F.succ(a)
```

> a + 1

``` lua
F.pred(a)
```

> a - 1

#### Numbers

##### Numeric type classes

``` lua
F.negate(a)
```

> -a

``` lua
F.abs(a)
```

> absolute value of a

``` lua
F.signum(a)
```

> sign of a (-1, 0 or +1)

``` lua
F.quot(a, b)
```

> integer division truncated toward zero

``` lua
F.rem(a, b)
```

> integer remainder satisfying quot(a, b)\*b + rem(a, b) == a, 0 \<=
> rem(a, b) \< abs(b)

``` lua
F.quot_rem(a, b)
```

> simultaneous quot and rem

``` lua
F.div(a, b)
```

> integer division truncated toward negative infinity

``` lua
F.mod(a, b)
```

> integer modulus satisfying div(a, b)\*b + mod(a, b) == a, 0 \<= mod(a,
> b) \< abs(b)

``` lua
F.div_mod(a, b)
```

> simultaneous div and mod

``` lua
F.recip(a)
```

> Reciprocal fraction.

``` lua
F.pi
F.exp(x)
F.log(x), F.log(x, base)
F.sqrt(x)
F.sin(x)
F.cos(x)
F.tan(x)
F.asin(x)
F.acos(x)
F.atan(x)
```

> standard math constants and functions

``` lua
F.proper_fraction(x)
```

> returns a pair (n,f) such that x = n+f, and:
>
> - n is an integral number with the same sign as x
> - f is a fraction with the same type and sign as x, and with absolute
>   value less than 1.

``` lua
F.truncate(x)
```

> returns the integer nearest x between zero and x.

``` lua
F.round(x)
```

> returns the nearest integer to x; the even integer if x is equidistant
> between two integers

``` lua
F.ceiling(x)
```

> returns the least integer not less than x.

``` lua
F.floor(x)
```

> returns the greatest integer not greater than x.

``` lua
F.is_nan(x)
```

> True if the argument is an IEEE “not-a-number” (NaN) value

``` lua
F.is_infinite(x)
```

> True if the argument is an IEEE infinity or negative infinity

``` lua
F.atan2(y, x)
```

> computes the angle (from the positive x-axis) of the vector from the
> origin to the point (x,y).

``` lua
F.even(n)
F.odd(n)
```

> parity check

``` lua
F.gcd(a, b)
F.lcm(a, b)
```

> Greatest Common Divisor and Least Common Multiple of a and b.

#### Miscellaneous functions

``` lua
F.id(x)
```

> Identity function.

``` lua
F.const(...)
```

> Constant function. const(…)(y) always returns …

``` lua
F.compose(fs)
```

> Function composition. compose{f, g, h}(…) returns f(g(h(…))).

``` lua
F.flip(f)
```

> takes its (first) two arguments in the reverse order of f.

``` lua
F.curry(f)
```

> curry(f)(x)(…) calls f(x, …)

``` lua
F.uncurry(f)
```

> uncurry(f)(x, …) calls f(x)(…)

``` lua
F.partial(f, ...)
```

> F.partial(f, xs)(ys) calls f(xs..ys)

``` lua
F.call(f, ...)
```

> calls `f(...)`

``` lua
F.until_(p, f, x)
```

> yields the result of applying f until p holds.

``` lua
F.error(message, level)
F.error_without_stack_trace(message, level)
```

> stops execution and displays an error message (with out without a
> stack trace).

``` lua
F.prefix(pre)
```

> returns a function that adds the prefix pre to a string

``` lua
F.suffix(suf)
```

> returns a function that adds the suffix suf to a string

``` lua
F.memo1(f)
```

> returns a memoized function (one argument)

### Converting to and from string

#### Converting to string

``` lua
F.show(x, [opt])
```

> Convert x to a string
>
> `opt` is an optional table that customizes the output string:
>
> - `opt.int`: integer format
> - `opt.flt`: floating point number format
> - `opt.indent`: number of spaces use to indent tables (`nil` for a
>   single line output)

#### Converting from string

``` lua
F.read(s)
```

> Convert s to a Lua value

### Table construction

``` lua
F(t)
```

> `F(t)` sets the metatable of `t` and returns `t`. Most of the
> functions of `F` will be methods of `t`.
>
> Note that other `F` functions that return tables actually return `F`
> tables.

``` lua
F.clone(t)
t:clone()
```

> `F.clone(t)` clones the first level of `t`.

``` lua
F.deep_clone(t)
t:deep_clone()
```

> `F.deep_clone(t)` recursively clones `t`.

``` lua
F.rep(n, x)
```

> Returns a list of length n with x the value of every element.

``` lua
F.range(a)
F.range(a, b)
F.range(a, b, step)
```

> Returns a range \[1, a\], \[a, b\] or \[a, a+step, … b\]

``` lua
F.concat{xs1, xs2, ... xsn}
F{xs1, xs2, ... xsn}:concat()
xs1 .. xs2
```

> concatenates lists

``` lua
F.flatten(xs)
xs:flatten()
```

> Returns a flat list with all elements recursively taken from xs

``` lua
F.str({s1, s2, ... sn}, [separator])
ss:str([separator])
```

> concatenates strings (separated with an optional separator) and
> returns a string.

``` lua
F.from_set(f, ks)
ks:from_set(f)
```

> Build a map from a set of keys and a function which for each key
> computes its value.

``` lua
F.from_list(kvs)
kvs:from_list()
```

> Build a map from a list of key/value pairs.

### Iterators

``` lua
F.pairs(t, [comp_lt])
t:pairs([comp_lt])
F.ipairs(xs, [comp_lt])
xs:ipairs([comp_lt])
```

> behave like the Lua `pairs` and `ipairs` iterators. `F.pairs` sorts
> keys using the function `comp_lt` or the universal `<=` operator
> (`F.op.ult`).

``` lua
F.keys(t, [comp_lt])
t:keys([comp_lt])
F.values(t, [comp_lt])
t:values([comp_lt])
F.items(t, [comp_lt])
t:items([comp_lt])
```

> returns the list of keys, values or pairs of keys/values (same order
> than F.pairs).

### Table extraction

``` lua
F.head(xs)
xs:head()
F.last(xs)
xs:last()
```

> returns the first element (head) or the last element (last) of a list.

``` lua
F.tail(xs)
xs:tail()
F.init(xs)
xs:init()
```

> returns the list after the head (tail) or before the last element
> (init).

``` lua
F.uncons(xs)
xs:uncons()
```

> returns the head and the tail of a list.

``` lua
F.unpack(xs, [ i, [j] ])
xs:unpack([ i, [j] ])
```

> returns the elements of xs between indices i and j

``` lua
F.take(n, xs)
xs:take(n)
```

> Returns the prefix of xs of length n.

``` lua
F.drop(n, xs)
xs:drop(n)
```

> Returns the suffix of xs after the first n elements.

``` lua
F.split_at(n, xs)
xs:split_at(n)
```

> Returns a tuple where first element is xs prefix of length n and
> second element is the remainder of the list.

``` lua
F.take_while(p, xs)
xs:take_while(p)
```

> Returns the longest prefix (possibly empty) of xs of elements that
> satisfy p.

``` lua
F.drop_while(p, xs)
xs:drop_while(p)
```

> Returns the suffix remaining after `take_while(p, xs)`.

``` lua
F.drop_while_end(p, xs)
xs:drop_while_end(p)
```

> Drops the largest suffix of a list in which the given predicate holds
> for all elements.

``` lua
F.span(p, xs)
xs:span(p)
```

> Returns a tuple where first element is longest prefix (possibly empty)
> of xs of elements that satisfy p and second element is the remainder
> of the list.

``` lua
F.break_(p, xs)
xs:break_(p)
```

> Returns a tuple where first element is longest prefix (possibly empty)
> of xs of elements that do not satisfy p and second element is the
> remainder of the list.

``` lua
F.strip_prefix(prefix, xs)
xs:strip_prefix(prefix)
```

> Drops the given prefix from a list.

``` lua
F.strip_suffix(suffix, xs)
xs:strip_suffix(suffix)
```

> Drops the given suffix from a list.

``` lua
F.group(xs, [comp_eq])
xs:group([comp_eq])
```

> Returns a list of lists such that the concatenation of the result is
> equal to the argument. Moreover, each sublist in the result contains
> only equal elements.

``` lua
F.inits(xs)
xs:inits()
```

> Returns all initial segments of the argument, shortest first.

``` lua
F.tails(xs)
xs:tails()
```

> Returns all final segments of the argument, longest first.

### Predicates

``` lua
F.is_prefix_of(prefix, xs)
prefix:is_prefix_of(xs)
```

> Returns `true` iff `xs` starts with `prefix`

``` lua
F.is_suffix_of(suffix, xs)
suffix:is_suffix_of(xs)
```

> Returns `true` iff `xs` ends with `suffix`

``` lua
F.is_infix_of(infix, xs)
infix:is_infix_of(xs)
```

> Returns `true` iff `xs` caontains `infix`

``` lua
F.has_prefix(xs, prefix)
xs:has_prefix(prefix)
```

> Returns `true` iff `xs` starts with `prefix`

``` lua
F.has_suffix(xs, suffix)
xs:has_suffix(suffix)
```

> Returns `true` iff `xs` ends with `suffix`

``` lua
F.has_infix(xs, infix)
xs:has_infix(infix)
```

> Returns `true` iff `xs` caontains `infix`

``` lua
F.is_subsequence_of(seq, xs)
seq:is_subsequence_of(xs)
```

> Returns `true` if all the elements of the first list occur, in order,
> in the second. The elements do not have to occur consecutively.

``` lua
F.is_submap_of(t1, t2)
t1:is_submap_of(t2)
```

> returns true if all keys in t1 are in t2.

``` lua
F.map_contains(t1, t2, [comp_eq])
t1:map_contains(t2, [comp_eq])
```

> returns true if all keys in t2 are in t1.

``` lua
F.is_proper_submap_of(t1, t2)
t1:is_proper_submap_of(t2)
```

> returns true if all keys in t1 are in t2 and t1 keys and t2 keys are
> different.

``` lua
F.map_strictly_contains(t1, t2, [comp_eq])
t1:map_strictly_contains(t2, [comp_eq])
```

> returns true if all keys in t2 are in t1.

### Searching

``` lua
F.elem(x, xs, [comp_eq])
xs:elem(x, [comp_eq])
```

> Returns `true` if x occurs in xs (using the optional comp_eq
> function).

``` lua
F.not_elem(x, xs, [comp_eq])
xs:not_elem(x, [comp_eq])
```

> Returns `true` if x does not occur in xs (using the optional comp_eq
> function).

``` lua
F.lookup(x, xys, [comp_eq])
xys:lookup(x, [comp_eq])
```

> Looks up a key `x` in an association list (using the optional comp_eq
> function).

``` lua
F.find(p, xs)
xs:find(p)
```

> Returns the leftmost element of xs matching the predicate p.

``` lua
F.filter(p, xs)
xs:filter(p)
```

> Returns the list of those elements that satisfy the predicate p(x).

``` lua
F.filteri(p, xs)
xs:filteri(p)
```

> Returns the list of those elements that satisfy the predicate p(i, x).

``` lua
F.filtert(p, t)
t:filtert(p)
```

> Returns the table of those values that satisfy the predicate p(v).

``` lua
F.filterk(p, t)
t:filterk(p)
```

> Returns the table of those values that satisfy the predicate p(k, v).

``` lua
F.restrictKeys(t, ks)
t:restrict_keys(ks)
```

> Restrict a map to only those keys found in a list.

``` lua
F.without_keys(t, ks)
t:without_keys(ks)
```

> Restrict a map to only those keys found in a list.

``` lua
F.partition(p, xs)
xs:partition(p)
```

> Returns the pair of lists of elements which do and do not satisfy the
> predicate, respectively.

``` lua
F.table_partition(p, t)
t:table_partition(p)
```

> Partition the map according to a predicate. The first map contains all
> elements that satisfy the predicate, the second all elements that fail
> the predicate.

``` lua
F.table_partition_with_key(p, t)
t:table_partition_with_key(p)
```

> Partition the map according to a predicate. The first map contains all
> elements that satisfy the predicate, the second all elements that fail
> the predicate.

``` lua
F.elemIndex(x, xs)
xs:elem_index(x)
```

> Returns the index of the first element in the given list which is
> equal to the query element.

``` lua
F.elem_indices(x, xs)
xs:elem_indices(x)
```

> Returns the indices of all elements equal to the query element, in
> ascending order.

``` lua
F.find_index(p, xs)
xs:find_index(p)
```

> Returns the index of the first element in the list satisfying the
> predicate.

``` lua
F.find_indices(p, xs)
xs:find_indices(p)
```

> Returns the indices of all elements satisfying the predicate, in
> ascending order.

### Table size

``` lua
F.null(xs)
xs:null()
F.null(t)
t:null("t")
```

> checks wether a list or a table is empty.

``` lua
#xs
F.length(xs)
xs:length()
```

> Length of a list.

``` lua
F.size(t)
t:size()
```

> Size of a table (number of (key, value) pairs).

### Table transformations

``` lua
F.map(f, xs)
xs:map(f)
```

> maps `f` to the elements of `xs` and returns
> `{f(xs[1]), f(xs[2]), ...}`

``` lua
F.mapi(f, xs)
xs:mapi(f)
```

> maps `f` to the elements of `xs` and returns
> `{f(1, xs[1]), f(2, xs[2]), ...}`

``` lua
F.mapt(f, t)
t:mapt(f)
```

> maps `f` to the values of `t` and returns
> `{k1=f(t[k1]), k2=f(t[k2]), ...}`

``` lua
F.mapk(f, t)
t:mapk(f)
```

> maps `f` to the values of `t` and returns
> `{k1=f(k1, t[k1]), k2=f(k2, t[k2]), ...}`

``` lua
F.reverse(xs)
xs:reverse()
```

> reverses the order of a list

``` lua
F.transpose(xss)
xss:transpose()
```

> Transposes the rows and columns of its argument.

``` lua
F.update(f, k, t)
t:update(f, k)
```

> Updates the value `x` at `k`. If `f(x)` is nil, the element is
> deleted. Otherwise the key `k` is bound to the value `f(x)`.
>
> **Warning**: in-place modification.

``` lua
F.updatek(f, k, t)
t:updatek(f, k)
```

> Updates the value `x` at `k`. If `f(k, x)` is nil, the element is
> deleted. Otherwise the key `k` is bound to the value `f(k, x)`.
>
> **Warning**: in-place modification.

### Table reductions (folds)

``` lua
F.fold(f, x, xs)
xs:fold(f, x)
```

> Left-associative fold of a list (`f(...f(f(x, xs[1]), xs[2]), ...)`).

``` lua
F.foldi(f, x, xs)
xs:foldi(f, x)
```

> Left-associative fold of a list
> (`f(...f(f(x, 1, xs[1]), 2, xs[2]), ...)`).

``` lua
F.fold1(f, xs)
xs:fold1(f)
```

> Left-associative fold of a list, the initial value is `xs[1]`.

``` lua
F.foldt(f, x, t)
t:foldt(f, x)
```

> Left-associative fold of a table (in the order given by F.pairs).

``` lua
F.foldk(f, x, t)
t:foldk(f, x)
```

> Left-associative fold of a table (in the order given by F.pairs).

``` lua
F.land(bs)
bs:land()
```

> Returns the conjunction of a container of booleans.

``` lua
F.lor(bs)
bs:lor()
```

> Returns the disjunction of a container of booleans.

``` lua
F.any(p, xs)
xs:any(p)
```

> Determines whether any element of the structure satisfies the
> predicate.

``` lua
F.all(p, xs)
xs:all(p)
```

> Determines whether all elements of the structure satisfy the
> predicate.

``` lua
F.sum(xs)
xs:sum()
```

> Returns the sum of the numbers of a structure.

``` lua
F.product(xs)
xs:product()
```

> Returns the product of the numbers of a structure.

``` lua
F.maximum(xs, [comp_lt])
xs:maximum([comp_lt])
```

> The largest element of a non-empty structure, according to the
> optional comparison function.

``` lua
F.minimum(xs, [comp_lt])
xs:minimum([comp_lt])
```

> The least element of a non-empty structure, according to the optional
> comparison function.

``` lua
F.scan(f, x, xs)
xs:scan(f, x)
```

> Similar to `fold` but returns a list of successive reduced values from
> the left.

``` lua
F.scan1(f, xs)
xs:scan1(f)
```

> Like `scan` but the initial value is `xs[1]`.

``` lua
F.concat_map(f, xs)
xs:concat_map(f)
```

> Map a function over all the elements of a container and concatenate
> the resulting lists.

### Zipping

``` lua
F.zip(xss, [f])
xss:zip([f])
```

> `zip` takes a list of lists and returns a list of corresponding
> tuples.

``` lua
F.unzip(xss)
xss:unzip()
```

> Transforms a list of n-tuples into n lists

``` lua
F.zip_with(f, xss)
xss:zip_with(f)
```

> `zip_with` generalises `zip` by zipping with the function given as the
> first argument, instead of a tupling function.

### Set operations

``` lua
F.nub(xs, [comp_eq])
xs:nub([comp_eq])
```

> Removes duplicate elements from a list. In particular, it keeps only
> the first occurrence of each element, according to the optional
> comp_eq function.

``` lua
F.delete(x, xs, [comp_eq])
xs:delete(x, [comp_eq])
```

> Removes the first occurrence of x from its list argument, according to
> the optional comp_eq function.

``` lua
F.difference(xs, ys, [comp_eq])
xs:difference(ys, [comp_eq])
```

> Returns the list difference. In `difference(xs, ys)` the first
> occurrence of each element of ys in turn (if any) has been removed
> from xs, according to the optional comp_eq function.

``` lua
F.union(xs, ys, [comp_eq])
xs:union(ys, [comp_eq])
```

> Returns the list union of the two lists. Duplicates, and elements of
> the first list, are removed from the the second list, but if the first
> list contains duplicates, so will the result, according to the
> optional comp_eq function.

``` lua
F.intersection(xs, ys, [comp_eq])
xs:intersection(ys, [comp_eq])
```

> Returns the list intersection of two lists. If the first list contains
> duplicates, so will the result, according to the optional comp_eq
> function.

### Table operations

``` lua
F.merge(ts)
ts:merge()
F.table_union(ts)
ts:table_union()
```

> Right-biased union of tables.

``` lua
F.merge_with(f, ts)
ts:merge_with(f)
F.table_union_with(f, ts)
ts:table_union_with(f)
```

> Right-biased union of tables with a combining function.

``` lua
F.merge_with_key(f, ts)
ts:merge_with_key(f)
F.table_union_with_key(f, ts)
ts:table_union_with_key(f)
```

> Right-biased union of tables with a combining function.

``` lua
F.table_difference(t1, t2)
t1:table_difference(t2)
```

> Difference of two maps. Return elements of the first map not existing
> in the second map.

``` lua
F.table_difference_with(f, t1, t2)
t1:table_difference_with(f, t2)
```

> Difference with a combining function. When two equal keys are
> encountered, the combining function is applied to the values of these
> keys.

``` lua
F.table_difference_with_key(f, t1, t2)
t1:table_difference_with_key(f, t2)
```

> Union with a combining function.

``` lua
F.table_intersection(t1, t2)
t1:table_intersection(t2)
```

> Intersection of two maps. Return data in the first map for the keys
> existing in both maps.

``` lua
F.table_intersection_with(f, t1, t2)
t1:table_intersection_with(f, t2)
```

> Difference with a combining function. When two equal keys are
> encountered, the combining function is applied to the values of these
> keys.

``` lua
F.table_intersection_with_key(f, t1, t2)
t1:table_intersection_with_key(f, t2)
```

> Union with a combining function.

``` lua
F.disjoint(t1, t2)
t1:disjoint(t2)
```

> Check the intersection of two maps is empty.

``` lua
F.table_compose(t1, t2)
t1:table_compose(t2)
```

> Relate the keys of one map to the values of the other, by using the
> values of the former as keys for lookups in the latter.

``` lua
F.Nil
```

> `F.Nil` is a singleton used to represent `nil` (see `F.patch`)

``` lua
F.patch(t1, t2)
t1:patch(t2)
```

> returns a copy of `t1` where some fields are replaced by values from
> `t2`. Keys not found in `t2` are not modified. If `t2` contains
> `F.Nil` then the corresponding key is removed from `t1`. Unmodified
> subtrees are not cloned but returned as is (common subtrees are
> shared).

### Ordered lists

``` lua
F.sort(xs, [comp_lt])
xs:sort([comp_lt])
```

> Sorts xs from lowest to highest, according to the optional comp_lt
> function.

``` lua
F.sort_on(f, xs, [comp_lt])
xs:sort_on(f, [comp_lt])
```

> Sorts a list by comparing the results of a key function applied to
> each element, according to the optional comp_lt function.

``` lua
F.insert(x, xs, [comp_lt])
xs:insert(x, [comp_lt])
```

> Inserts the element into the list at the first position where it is
> less than or equal to the next element, according to the optional
> comp_lt function.

### Miscellaneous functions

``` lua
F.subsequences(xs)
xs:subsequences()
```

> Returns the list of all subsequences of the argument.

``` lua
F.permutations(xs)
xs:permutations()
```

> Returns the list of all permutations of the argument.

### Functions on strings

``` lua
string.chars(s, i, j)
s:chars(i, j)
```

> Returns the list of characters of a string between indices i and j, or
> the whole string if i and j are not provided.

``` lua
string.head(s)
s:head()
```

> Extract the first element of a string.

``` lua
sting.last(s)
s:last()
```

> Extract the last element of a string.

``` lua
string.tail(s)
s:tail()
```

> Extract the elements after the head of a string

``` lua
string.init(s)
s:init()
```

> Return all the elements of a string except the last one.

``` lua
string.uncons(s)
s:uncons()
```

> Decompose a string into its head and tail.

``` lua
string.null(s)
s:null()
```

> Test whether the string is empty.

``` lua
string.length(s)
s:length()
```

> Returns the length of a string.

``` lua
string.intersperse(c, s)
c:intersperse(s)
```

> Intersperses a element c between the elements of s.

``` lua
string.intercalate(s, ss)
s:intercalate(ss)
```

> Inserts the string s in between the strings in ss and concatenates the
> result.

``` lua
string.subsequences(s)
s:subsequences()
```

> Returns the list of all subsequences of the argument.

``` lua
string.permutations(s)
s:permutations()
```

> Returns the list of all permutations of the argument.

``` lua
string.take(s, n)
s:take(n)
```

> Returns the prefix of s of length n.

``` lua
string.drop(s, n)
s:drop(n)
```

> Returns the suffix of s after the first n elements.

``` lua
string.split_at(s, n)
s:split_at(n)
```

> Returns a tuple where first element is s prefix of length n and second
> element is the remainder of the string.

``` lua
string.take_while(s, p)
s:take_while(p)
```

> Returns the longest prefix (possibly empty) of s of elements that
> satisfy p.

``` lua
string.dropWhile(s, p)
s:dropWhile(p)
```

> Returns the suffix remaining after `s:take_while(p)`.

``` lua
string.drop_while_end(s, p)
s:drop_while_end(p)
```

> Drops the largest suffix of a string in which the given predicate
> holds for all elements.

``` lua
string.strip_prefix(s, prefix)
s:strip_prefix(prefix)
```

> Drops the given prefix from a string.

``` lua
string.strip_suffix(s, suffix)
s:strip_suffix(suffix)
```

> Drops the given suffix from a string.

``` lua
string.inits(s)
s:inits()
```

> Returns all initial segments of the argument, shortest first.

``` lua
string.tails(s)
s:tails()
```

> Returns all final segments of the argument, longest first.

``` lua
string.is_prefix_of(prefix, s)
prefix:is_prefix_of(s)
```

> Returns `true` iff the first string is a prefix of the second.

``` lua
string.has_prefix(s, prefix)
s:has_prefix(prefix)
```

> Returns `true` iff the second string is a prefix of the first.

``` lua
string.is_suffix_of(suffix, s)
suffix:is_suffix_of(s)
```

> Returns `true` iff the first string is a suffix of the second.

``` lua
string.has_suffix(s, suffix)
s:has_suffix(suffix)
```

> Returns `true` iff the second string is a suffix of the first.

``` lua
string.is_infix_of(infix, s)
infix:is_infix_of(s)
```

> Returns `true` iff the first string is contained, wholly and intact,
> anywhere within the second.

``` lua
string.has_infix(s, infix)
s:has_infix(infix)
```

> Returns `true` iff the second string is contained, wholly and intact,
> anywhere within the first.

``` lua
string.split(s, sep, maxsplit, plain)
s:split(sep, maxsplit, plain)
```

> Splits a string `s` around the separator `sep`. `maxsplit` is the
> maximal number of separators. If `plain` is true then the separator is
> a plain string instead of a Lua string pattern.

``` lua
string.lines(s)
s:lines()
```

> Splits the argument into a list of lines stripped of their terminating
> `\n` characters.

``` lua
string.words(s)
s:words()
```

> Breaks a string up into a list of words, which were delimited by white
> space.

``` lua
F.unlines(xs)
xs:unlines()
```

> Appends a `\n` character to each input string, then concatenates the
> results.

``` lua
string.unwords(xs)
xs:unwords()
```

> Joins words with separating spaces.

``` lua
string.ltrim(s)
s:ltrim()
```

> Removes heading spaces

``` lua
string.rtrim(s)
s:rtrim()
```

> Removes trailing spaces

``` lua
string.trim(s)
s:trim()
```

> Removes heading and trailing spaces

``` lua
string.cap(s)
s:cap()
```

> Capitalizes a string. The first character is upper case, other are
> lower case.

### String interpolation

``` lua
string.I(s, t)
s:I(t)
```

> interpolates expressions in the string `s` by replacing `$(...)` with
> the value of `...` in the environment defined by the table `t`.

``` lua
F.I(t)
```

> returns a string interpolator that replaces `$(...)` with the value of
> `...` in the environment defined by the table `t`. An interpolator can
> be given another table to build a new interpolator with new values.

## L: Pandoc List package

``` lua
local L = require "L"
```

`L` is just a shortcut to `Pandoc.List`.

## fs: File System

`fs` is a File System module. It provides functions to handle files and
directory in a portable way.

``` lua
local fs = require "fs"
```

``` lua
fs.getcwd()
```

returns the current working directory.

``` lua
fs.dir([path])
```

returns the list of files and directories in `path` (the default path is
the current directory).

``` lua
fs.remove(name)
```

deletes the file `name`.

``` lua
fs.rename(old_name, new_name)
```

renames the file `old_name` to `new_name`.

``` lua
fs.copy(source_name, target_name)
```

copies file `source_name` to `target_name`. The attributes and times are
preserved.

``` lua
fs.mkdir(path)
```

creates a new directory `path`.

``` lua
fs.stat(name)
```

reads attributes of the file `name`. Attributes are:

- `name`: name
- `type`: `"file"` or `"directory"`
- `size`: size in bytes
- `mtime`, `atime`, `ctime`: modification, access and creation times.
- `mode`: file permissions
- `uR`, `uW`, `uX`: user Read/Write/eXecute permissions
- `gR`, `gW`, `gX`: group Read/Write/eXecute permissions
- `oR`, `oW`, `oX`: other Read/Write/eXecute permissions
- `aR`, `aW`, `aX`: anybody Read/Write/eXecute permissions

``` lua
fs.inode(name)
```

reads device and inode attributes of the file `name`. Attributes are:

- `dev`, `ino`: device and inode numbers

``` lua
fs.chmod(name, other_file_name)
```

sets file `name` permissions as file `other_file_name` (string
containing the name of another file).

``` lua
fs.chmod(name, bit1, ..., bitn)
```

sets file `name` permissions as `bit1` or … or `bitn` (integers).

``` lua
fs.touch(name)
```

sets the access time and the modification time of file `name` with the
current time.

``` lua
fs.touch(name, number)
```

sets the access time and the modification time of file `name` with
`number`.

``` lua
fs.touch(name, other_name)
```

sets the access time and the modification time of file `name` with the
times of file `other_name`.

``` lua
fs.basename(path)
```

return the last component of path.

``` lua
fs.dirname(path)
```

return all but the last component of path.

``` lua
fs.splitext(path)
```

return the name without the extension and the extension.

``` lua
fs.normalize(path)
```

return the normalized path name of path.

``` lua
fs.realpath(path)
```

return the resolved path name of path.

``` lua
fs.absname(path)
```

return the absolute path name of path.

``` lua
fs.join(...)
```

return a path name made of several path components (separated by
`fs.sep`). If a component is absolute, the previous components are
removed.

``` lua
fs.is_file(name)
```

returns `true` if `name` is a file.

``` lua
fs.is_dir(name)
```

returns `true` if `name` is a directory.

``` lua
fs.findpath(name)
```

returns the full path of `name` if `name` is found in `$PATH` or `nil`.

``` lua
fs.mkdirs(path)
```

creates a new directory `path` and its parent directories.

``` lua
fs.mv(old_name, new_name)
```

alias for `fs.rename(old_name, new_name)`.

``` lua
fs.rm(name)
```

alias for `fs.remove(name)`.

``` lua
fs.rmdir(path, [params])
```

deletes the directory `path` and its content recursively.

``` lua
fs.walk([path], [{reverse=true|false, links=true|false, cross=true|false, func=function}])
```

returns a list listing directory and file names in `path` and its
subdirectories (the default path is the current directory).

Options:

- `reverse`: the list is built in a reverse order (suitable for
  recursive directory removal)
- `links`: follow symbolic links
- `cross`: walk across several devices
- `func`: function applied to the current file or directory. `func`
  takes two parameters (path of the file or directory and the stat
  object returned by `fs.stat`) and returns a boolean (to continue or
  not walking recursively through the subdirectories) and a value
  (e.g. the name of the file) to be added to the listed returned by
  `walk`.

``` lua
fs.with_tmpfile(f)
```

calls `f(tmp)` where `tmp` is the name of a temporary file.

``` lua
fs.with_tmpdir(f)
```

calls `f(tmp)` where `tmp` is the name of a temporary directory.

``` lua
fs.with_dir(path, f)
```

changes the current working directory to `path` and calls `f()`.

``` lua
fs.with_env(env, f)
```

changes the environnement to `env` and calls `f()`.

``` lua
fs.read(filename)
```

returns the content of the text file `filename`.

``` lua
fs.write(filename, ...)
```

write `...` to the text file `filename`.

``` lua
fs.read_bin(filename)
```

returns the content of the binary file `filename`.

``` lua
fs.write_bin(filename, ...)
```

write `...` to the binary file `filename`.

## sh: Shell

``` lua
local sh = require "sh"
```

``` lua
sh.run(...)
```

Runs the command `...` with `os.execute`.

``` lua
sh.read(...)
```

Runs the command `...` with `io.popen`. When `sh.read` succeeds, it
returns the content of stdout. Otherwise it returns the error identified
by `io.popen`.

``` lua
sh.write(...)(data)
```

Runs the command `...` with `io.popen` and feeds `stdin` with `data`.
`sh.write` returns the same values returned by `os.execute`.

``` lua
sh.pipe(...)(data)
```

Runs the command `...` with `pandoc.pipe` and feeds `stdin` with `data`.
When `sh.pipe` succeeds, it returns the content of stdout. Otherwise it
returns the error identified by `pandoc.pipe`.

## sys: System module

``` lua
local sys = require "sys"
```

``` lua
sys.os
```

`"linux"`, `"macos"` or `"windows"`.

``` lua
sys.arch
```

`"x86_64"`, `"i386"` or `"aarch64"`.

## crypt: cryptography module

``` lua
local crypt = require "crypt"
```

`crypt` provides (weak but simple) cryptography functions.

> **Warning**: for serious cryptography applications, please do not use
> this module.

### Random number generator

The PLua pseudorandom number generator is a [linear congruential
generator](https://en.wikipedia.org/wiki/Linear_congruential_generator).
This generator is not a cryptographically secure pseudorandom number
generator. It can be used as a repeatable generator (e.g. for repeatable
tests).

``` lua
local rng = crypt.prng(seed)
```

returns a random number generator starting from the optional seed
`seed`.

``` lua
rng:int()
```

returns a random integral number between `0` and `crypt.RAND_MAX`.

``` lua
rng:int(a)
```

returns a random integral number between `0` and `a`.

``` lua
rng:int(a, b)
```

returns a random integral number between `a` and `b`.

``` lua
rng:float()
```

returns a random floating point number between `0` and `1`.

``` lua
rng:float(a)
```

returns a random floating point number between `0` and `a`.

``` lua
rng:float(a, b)
```

returns a random floating point number between `a` and `b`.

``` lua
rng:str(n)
```

returns a string with `n` random bytes.

### Hexadecimal encoding

The hexadecimal encoder transforms a string into a string where bytes
are coded with hexadecimal digits.

``` lua
crypt.hex(data)
data:hex()
```

encodes `data` in hexa.

``` lua
crypt.unhex(data)
data:unhex()
```

decodes the hexa `data`.

### Base64 encoding

The base64 encoder transforms a string with non printable characters
into a printable string (see <https://en.wikipedia.org/wiki/Base64>).

The implementation has been taken from
<https://lua-users.org/wiki/BaseSixtyFour>.

``` lua
crypt.base64(data)
data:base64()
```

encodes `data` in base64.

``` lua
crypt.unbase64(data)
data:unbase64()
```

decodes the base64 `data`.

### CRC32 hash

The CRC-32 algorithm has been generated by [pycrc](https://pycrc.org/)
with the `crc-32` algorithm.

``` lua
crypt.crc32(data)
data:crc32()
```

computes the CRC32 of `data`.

### CRC64 hash

The CRC-64 algorithm has been generated by [pycrc](https://pycrc.org/)
with the `crc-64-xz` algorithm.

``` lua
crypt.crc64(data)
data:crc64()
```

computes the CRC64 of `data`.

### SHA1 hash

The SHA1 hash is provided by the `pandoc` module. `crypt.sha1` is just
an alias for `pandoc.utils.sha1`.

``` lua
crypt.sha1(data)
data:sha1()
```

computes the SHA1 of `data`.

### RC4 encryption

RC4 is a stream cipher (see <https://en.wikipedia.org/wiki/RC4>). It is
design to be fast and simple.

See <https://en.wikipedia.org/wiki/RC4>.

``` lua
crypt.rc4(data, key, [drop])
data:rc4(key, [drop])
crypt.unrc4(data, key, [drop])      -- note that unrc4 == rc4
data:unrc4(key, [drop])
```

encrypts/decrypts `data` using the RC4Drop algorithm and the encryption
key `key` (drops the first `drop` encryption steps, the default value of
`drop` is 768).

## prompt: Prompt module

The prompt module is a basic prompt implementation to display a prompt
and get user inputs.

The use of [rlwrap](https://github.com/hanslub42/rlwrap) is highly
recommended for a better user experience on Linux.

``` lua
local prompt = require "prompt"
```

``` lua
s = prompt.read(p)
```

prints `p` and waits for a user input

``` lua
prompt.clear()
```

clears the screen

## Serialization

PLua provides two serialization modules:

- [inspect](https://github.com/kikito/inspect.lua): Human-readable
  representation of Lua tables
- [serpent](https://github.com/pkulchenko/serpent): Lua serializer and
  pretty printer

## argparse: feature-rich command line parser for Lua

[Argparse](https://github.com/mpeterv/argparse) is a feature-rich
command line parser for Lua inspired by argparse for Python.

Argparse supports positional arguments, options, flags, optional
arguments, subcommands and more. Argparse automatically generates usage,
help and error messages.

Please read the [Argparse turorial](https://argparse.readthedocs.io/)
for more information.

# License

    plua is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    plua is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with plua.  If not, see <https://www.gnu.org/licenses/>.

    For further information about plua you can visit
    http://cdelord.fr/plua

`plua` uses other third party softwares:

- **[Pandoc](https://pandoc.org/)**: a universal document converter
  ([GPL](https://www.gnu.org/copyleft/gpl.html))
- **[Lua 5.4](http://www.lua.org)**: Copyright (C) 1994-2022 Lua.org,
  PUC-Rio ([MIT license](http://www.lua.org/license.html))
- **[inspect](https://github.com/kikito/inspect.lua)**: Human-readable
  representation of Lua tables ([MIT
  license](https://github.com/kikito/inspect.lua/blob/master/MIT-LICENSE.txt))
- **[serpent](https://github.com/pkulchenko/serpent)**: Lua serializer
  and pretty printer. ([MIT
  license](https://github.com/pkulchenko/serpent/blob/master/LICENSE))
- **[Argparse](https://github.com/mpeterv/argparse)**: a feature-rich
  command line parser for Lua ([MIT
  license](https://github.com/mpeterv/argparse/blob/master/LICENSE))
