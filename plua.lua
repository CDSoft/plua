-- @MAIN
-- vim: set filetype=lua ts=4 sw=4 foldmethod=marker :

--[[
This file is part of plua.

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
--]]

local fs = require "fs"
local sys = require "sys"
local F = require "F"
local I = F.I(_G)

local welcome = I{sys=sys}[[
 ____  _                 |  http://cdelord.fr/plua
|  _ \| |   _   _  __ _  |
| |_) | |  | | | |/ _` | |  Version $(_PLUA_VERSION)
|  __/| |__| |_| | (_| | |  Powered by $(_VERSION)
|_|   |_____\__,_|\__,_| |  and Pandoc $(PANDOC_VERSION)
                         |  on $(sys.os:cap()) $(sys.arch)
]]

local LUA_INIT = F{
    "LUA_INIT_" .. _VERSION:gsub(".* ", ""):gsub("%.", "_"),
    "LUA_INIT",
}

local usage = F.unlines(F.flatten {
    I{fs=fs,init=LUA_INIT}[==[
usage: $(fs.basename(arg[0])) [options] [script [args]]

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

  $(init[1]), $(init[2])
                code executed before handling command line options
                and scripts.
                When $(init[1]) is defined, $(init[2]) is ignored.
]==]
    })

local function print_welcome()
    print(welcome)
end

local function print_usage(fmt, ...)
    print_welcome()
    if fmt then
        print(("error: %s"):format(fmt:format(...)))
        print("")
    end
    print(usage)
end

local function err(fmt, ...)
    print_usage(fmt, ...)
    os.exit(1)
end

local function wrong_arg(a)
    err("unrecognized option '%s'", a)
end

-- Read options

local interactive = #arg == 0
local run_stdin = false
local args = {}

local plua_loaded = false

local actions = setmetatable({
        actions = F{}
    }, {
    __index = {
        add = function(self, action) self.actions[#self.actions+1] = action end,
        run = function(self) self.actions:map(F.call) end,
    },
})

--[=[-----------------------------------------------------------------------@@@
# PLua interactive usage

The PLua REPL uses the Lua interpreter provided by Pandoc.

``` sh
$ plua
```

The integration with Pandoc is interesting
to debug Pandoc Lua filters and inspect Pandoc AST.
E.g.:

```
$ plua

 ____  _                 |  http://cdelord.fr/plua
|  _ \| |   _   _  __ _  |
| |_) | |  | | | |/ _` | |  Version X.Y
|  __/| |__| |_| | (_| | |  Powered by Lua X.Y
|_|   |_____\__,_|\__,_| |  and Pandoc X.Y
                         |  on <OS> <ARCH>

>> pandoc.read "*Pandoc* is **great**!"
Pandoc (Meta {unMeta = fromList []}) [Para [Emph [Str "Pandoc"],Space,Str "is",Space,Strong [Str "great"],Str "!"]]
```

Note that [rlwrap](https://github.com/hanslub42/rlwrap)
can be used to give nice edition facilities to the Pandoc Lua interpreter.

@@@]=]

--[=[-----------------------------------------------------------------------@@@
# Additional functions

The `plua` repl provides a few functions for the interactive mode.

In interactive mode, these functions are available as global functions.
`F.show`{.lua} is used by the PLua REPL to print results.
@@@]=]

local function populate_repl()

    -- plua functions loaded at the top level in interactive mode only

    if plua_loaded then return end
    plua_loaded = true

    local show_opt = F{}

--[[@@@
```lua
show(x)
```
returns a string representing `x` with nice formatting for tables and numbers.
@@@]]

    function _ENV.show(x, opt)
        return F.show(x, show_opt:patch(opt))
    end

--[[@@@
```lua
precision(len, frac)
```
changes the format of floats. `len` is the
total number of characters and `frac` the number of decimals after the floating
point (`frac` can be `nil`). `len` can also be a string (custom format string)
or `nil` (to reset the float format). `b` can be `10` (decimal numbers), `16`
(hexadecimal numbers), `8` (octal numbers), a custom format string or `nil` (to
reset the integer format).
@@@]]

    function _ENV.precision(len, frac)
        show_opt.flt =
            type(len) == "string"                               and len
            or type(len) == "number" and type(frac) == "number" and ("%%%s.%sf"):format(len, frac)
            or type(len) == "number" and frac == nil            and ("%%%sf"):format(len, frac)
            or "%s"
    end

--[[@@@
```lua
base(b)
```
changes the format of integers. `b` can be `10` (decimal
numbers), `16` (hexadecimal numbers), `8` (octal numbers), a custom format
string or `nil` (to reset the integer format).
@@@]]

    function _ENV.base(b)
        show_opt.int =
            type(b) == "string" and b
            or b == 10          and "%s"
            or b == 16          and "0x%x"
            or b == 8           and "0o%o"
            or "%s"
    end

--[[@@@
```lua
indent(i)
```
indents tables (`i` spaces). If `i` is `nil`, tables are not indented.
@@@]]

    function _ENV.indent(i)
        show_opt.indent = i
    end

--[[@@@
```lua
prints(x)
```
prints `show(x)`
@@@]]

    function _ENV.prints(x)
        print(show(x))
    end

--[[@@@
```lua
inspect(x)
```
calls `inspect(x)` to build a human readable
representation of `x` (see the `inspect` package).
@@@]]

    local inspect = require "inspect"

    local remove_all_metatables = function(item, path)
        if path[#path] ~= inspect.METATABLE then return item end
    end

    local default_options = {
        process = remove_all_metatables,
    }

    function _ENV.inspect(x, options)
        return inspect(x, F.merge{default_options, options})
    end

--[[@@@
```lua
printi(x)
```
prints `inspect(x)` (without the metatables).
@@@]]

    function _ENV.printi(x)
        print(inspect.inspect(x))
    end

end

local function traceback(message)
    local trace = F.flatten {
        "plua: "..message,
        debug.traceback():lines(),
    }
    local pos = 1
    trace:mapi(function(i, line)
        if line:trim() == "[C]: in function 'xpcall'" then
            pos = i-1
        end
    end)
    io.stderr:write(trace:take(pos):unlines())
end

local function run_lua_init()
    LUA_INIT
        : filter(function(var) return os.getenv(var) ~= nil end)
        : take(1)
        : map(function(var)
            local code = assert(os.getenv(var))
            local filename = code:match "^@(.*)"
            local chunk, chunk_err
            if filename then
                chunk, chunk_err = loadfile(filename)
            else
                chunk, chunk_err = load(code, "="..var)
            end
            if not chunk then
                print(chunk_err)
                os.exit(1)
            end
            if chunk and not xpcall(chunk, traceback) then
                os.exit(1)
            end
        end)
end

actions:add(run_lua_init)

do
    local i = 1
    -- Scan options
    while i <= #arg do
        local a = arg[i]
        if a == '-e' then
            i = i+1
            local stat = arg[i]
            if stat == nil then wrong_arg(a) end
            actions:add(function()
                assert(stat)
                populate_repl()
                local chunk, msg = load(stat, "=(command line)")
                if not chunk then
                    io.stderr:write(("%s: %s\n"):format(arg[0], msg))
                    os.exit(1)
                end
                assert(chunk)
                local res = table.pack(xpcall(chunk, traceback))
                local ok = table.remove(res, 1)
                if ok then
                    if #res > 0 then
                        print(table.unpack(F.map(show, res)))
                    end
                else
                    os.exit(1)
                end
            end)
        elseif a == '-i' then
            interactive = true
        elseif a == '-l' then
            i = i+1
            local lib = arg[i]
            if lib == nil then wrong_arg(a) end
            actions:add(function()
                assert(lib)
                _G[lib] = require(lib)
            end)
        elseif a == '-v' then
            print_welcome()
            os.exit()
        elseif a == '-h' then
            print_usage()
            os.exit(0)
        elseif a == '--' then
            i = i+1
            break
        elseif a == '-' then
            run_stdin = true
            -- this is not an option but a file (stdin) to execute
            args[#args+1] = arg[i]
            break
        elseif a:match "^%-" then
            wrong_arg(a)
        else
            -- this is not an option but a file to execute/compile
            break
        end
        i = i+1
    end
    -- scan files/arguments to execute/compile
    while i <= #arg do
        args[#args+1] = arg[i]
        i = i+1
    end
end

local function run_interpreter()

    -- scripts

    populate_repl()

    if #args >= 1 then
        arg = {}
        local script = args[1]
        arg[0] = script == "-" and "stdin" or script
        for i = 2, #args do arg[i-1] = args[i] end
        local chunk, msg
        if script == "-" then
            chunk, msg = load(io.stdin:read "*a")
        else
            chunk, msg = loadfile(script)
        end
        if not chunk then
            io.stderr:write(("%s: %s\n"):format(script, msg))
            os.exit(1)
        end
        assert(chunk)
        local res = table.pack(xpcall(chunk, traceback))
        local ok = table.remove(res, 1)
        if ok then
            if #res > 0 then
                print(table.unpack(F.map(show, res)))
            end
        else
            os.exit(1)
        end
    end

    -- interactive REPL

    if interactive then
        local prompt = require "prompt"
        local function try(input)
            local chunk, msg = load(input, "=stdin")
            if not chunk then
                if msg and type(msg) == "string" and msg:match "<eof>$" then return "cont" end
                return nil, msg
            end
            local res = table.pack(xpcall(chunk, traceback))
            local ok = table.remove(res, 1)
            if ok then
                if res ~= nil then print(table.unpack(F.map(show, res))) end
            end
            return "done"
        end
        print_welcome()
        while true do
            local inputs = {}
            local p = ">> "
            while true do
                local line = prompt.read(p)
                if not line then os.exit() end
                table.insert(inputs, line)
                local input = table.concat(inputs, "\n")
                local try_expr, err_expr = try("return "..input)
                if try_expr == "done" then break end
                local try_stat, err_stat = try(input)
                if try_stat == "done" then break end
                if try_expr ~= "cont" and try_stat ~= "cont" then
                    print(try_stat == nil and err_stat or err_expr)
                    break
                end
                p = ".. "
            end
        end
    end

end

if interactive and run_stdin then
    err "Interactive mode and stdin execution are incompatible"
end

actions:add(run_interpreter)

actions:run()

-- vim: set ts=4 sw=4 foldmethod=marker :
