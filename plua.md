-------------------------------------------------------------------------------

# Pandoc Lua interpreter and REPL

`plua` is a Lua interpreter and REPL based on Pandoc and Lua, augmented with
some useful packages. It comes with `pluac` which can produce standalone
scripts from Lua scripts. The only requirement is Pandoc 3.

These scripts can run on any Linux-like environment where Pandoc can run
(Linux, MacOS, Cygwin, WSL, ...).

**WARNING**: PLua was an experimentation with the Pandoc Lua interpreter. Its
features have been integrated to [LuaX](https://github.com/CDSoft/luax) and is
no longer maintained. Please consider using
[LuaX](https://github.com/CDSoft/luax) instead.

## Compilation

`plua` is written in Lua (Lua interpreter provided by Pandoc). Just download
`plua` (<https://github.com/CDSoft/plua>) and run `make`:

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

- `$PREFIX/bin/plua`: PLua REPL (REPL executed in the Lua interpreter provided
  by Pandoc.
- `$PREFIX/bin/pluac`: PLua "compiler" (bundles Lua scripts in a single
  executable script).
- `$PREFIX/lib/plua.zip`: PLua libraries used by `pluac` to build executable
  scripts (non needed to execute these scripts).
- `$PREFIX/lib/plua.lua`: PLua libraries as a single Lua module (e.g. for usage
  in Pandoc Lua filters).

## Usage

### `plua` interpreter

`plua` is very similar to `lua` and provides a more user friendly interface.

```{cmd="sh"}
.build/bin/plua -h | sed \
    -e 's/|  \(Version\|Powered by Lua\|and Pandoc\) .*/|  \1 X.Y/' \
    -e 's/|  on .*/|  on <OS> <ARCH>/'
```

### `pluac` « compiler »

`pluac` produces a standalone script containing a set of Lua scripts.

```{cmd="sh"}
.build/bin/pluac -h
```

## Examples

### `plua`

`plua` executes Lua scripts:

```
$ cat demo.lua
local xs = F.range(100)
local sum = xs:sum()

print("sum of "..xs:head().." + ... + "..xs:last().." = "..sum)

$ plua demo.lua
sum of 1 + ... + 100 = 5050
```

and provides a nice REPL:

```
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
```

### `pluac`

```
$ pluac -v demo.lua -o demo
demo.lua: ok
demo: zip demo.lua
  adding: demo.lua (deflated 18%)
demo.lua: main script (require "demo")
demo: 34024 bytes written

$ ./demo
sum of 1 + ... + 100 = 5050
```

# PLua improved REPL

:::{doc=plua.lua shift=1}
:::

# PLua library

:::{doc=lib/F.lua shift=1}
:::
:::{doc=lib/L.lua shift=1}
:::
:::{doc=lib/fs.lua shift=1}
:::
:::{doc=lib/sh.lua shift=1}
:::
:::{doc=lib/sys.lua shift=1}
:::
:::{doc=lib/crypt.lua shift=1}
:::
:::{doc=lib/prompt.lua shift=1}
:::

## Serialization

PLua provides two serialization modules:

- [inspect](https://github.com/kikito/inspect.lua): Human-readable representation of Lua tables
- [serpent](https://github.com/pkulchenko/serpent): Lua serializer and pretty printer

## argparse: feature-rich command line parser for Lua

[Argparse](https://github.com/mpeterv/argparse) is a feature-rich command line
parser for Lua inspired by argparse for Python.

Argparse supports positional arguments, options, flags, optional arguments,
subcommands and more. Argparse automatically generates usage, help and error
messages.

Please read the [Argparse turorial](https://argparse.readthedocs.io/) for more
information.

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
- **[Lua 5.4](http://www.lua.org)**: Copyright (C) 1994-2022 Lua.org, PUC-Rio
  ([MIT license](http://www.lua.org/license.html))
- **[inspect](https://github.com/kikito/inspect.lua)**: Human-readable
  representation of Lua tables ([MIT
  license](https://github.com/kikito/inspect.lua/blob/master/MIT-LICENSE.txt))
- **[serpent](https://github.com/pkulchenko/serpent)**: Lua serializer and
  pretty printer. ([MIT
  license](https://github.com/pkulchenko/serpent/blob/master/LICENSE))
- **[Argparse](https://github.com/mpeterv/argparse)**: a feature-rich command
  line parser for Lua ([MIT
  license](https://github.com/mpeterv/argparse/blob/master/LICENSE))
