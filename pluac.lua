#!/usr/bin/env -S pandoc lua --
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

local function usage(msg, ...)
    local out = msg and io.stderr or io.stdout
    out:write [[Overview: Pandoc Lua Compiler

]]
    if msg then
        out:write("Error: ", msg:format(...), "\n\n")
    end
    out:write [[Usage: pluac [-h] [-v] [-r] -o <output> [<script.lua> ...]

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
]]
    os.exit(msg and 1)
end

local function err(msg, ...)
    io.stderr:write("Error: ", msg:format(...), "\n\n")
    os.exit(1)
end

local zip = pandoc.zip
local path = pandoc.path
local split_ext = pandoc.path.split_extension
local L = pandoc.List

local scripts = L{} -- all scripts {script_name, tags}
local output        -- output filename (-o)
local verbose = false
local rlwrap = false
do
    local i = 1
    while arg[i] do
        local a = arg[i]
        i = i+1
        if a == "-h" then
            usage()
        elseif a == "-v" then
            verbose = true
        elseif a == "-r" then
            rlwrap = true
        elseif a == "-o" then
            if output then usage "Duplicate -o option" end
            output = arg[i]
            i = i+1
        elseif a:match "^%-" then
            usage("%s: invalid argument", a)
        else
            scripts:insert(a)
        end
    end
end

local function log(fmt, ...)
    if verbose then
        print(fmt:format(...))
    end
end

if #scripts == 0 then usage "No input scripts" end
if not output then usage "No output" end

local function file_exists(name)
    local f = io.open(name)
    local found
    if f ~= nil then
        found = true
        f:close()
    end
    return found
end

local function read_file(name)
    local f = assert(io.open(name))
    local content = f:read "a"
    f:close()
    return content
end

-- Check that all scripts compile or print compilation errors
local tags = {}
scripts:map(function(script)
    local f, msg = io.open(script)
    local tag = {}
    if f then
        local content = f:read "a"
        tag = {
            load = content:find "@LOAD",
            run = content:find "@RUN",
            main = content:find "@MAIN",
        }
        if tag.main and (tag.load or tag.run) then
            err("%s: a library (@LOAD or @RUN) can not be a main script (@MAIN)")
        end
        f:close()
    else
       err("%s", msg)
   end
    assert(loadfile(script))
    log("%s: ok", script)
    tags[script] = tag
end)

if #scripts == 1 then
    -- assume the only script on the commande line is the main script
    tags[scripts[1]].main = true
end

-- Scripts are stored in a Zip archive that is used at runtime to load Lua packages
log("%s: zip %s", output, table.concat(scripts, " "))
local archive = zip.zip(scripts, {verbose=verbose})

-- Add modules from the standard library
local stdlib_path = L{
    path.join{path.directory(path.directory(arg[0])), "lib", "plua.zip"},
    path.join{path.directory(arg[0]), "lib", "plua.zip"},
    path.join{path.directory(arg[0]), "plua.zip"},
} : find_if(file_exists) or err "plua.zip not found"
archive.entries:extend(zip.Archive(read_file(stdlib_path)).entries)

-- The loader is the first module loaded at runtime.
local nb_main = 0
local loader =
    L{
        "local entries = (...)\n",
        "local libs = {}\n",
        "entries:map(function(e) libs[pandoc.path.split_extension(e.path)] = e end)\n",
        "table.insert(package.searchers, 1, function(name)\n",
        "    local e = libs[name]\n",
        "    return e and assert(load(e:contents(),'@'..e.path))\n",
        "end)\n",
    }
    -- It loads the standard library
    ..L{ "require 'plua-stdlib'\n" }
    -- It loads the scripts with the @LOAD or @RUN tags.
    ..scripts:map(function(script)
        if tags[script].load then
            log("%s: loaded at init (%s = require %q)", script, split_ext(path.filename(script)):gsub("-", "_"), split_ext(path.filename(script)))
            return ("%s = require %q\n"):format(split_ext(path.filename(script)):gsub("-", "_"), split_ext(path.filename(script)))
        elseif tags[script].run then
            log("%s: run at init (require %q)", script, split_ext(path.filename(script)))
            return ("require %q\n"):format(split_ext(path.filename(script)))
        end
        return ""
    end)
    -- and finally the main script
    ..scripts:map(function(script)
        if tags[script].main then
            log("%s: main script (require %q)", script, split_ext(path.filename(script)))
            nb_main = nb_main + 1
            return ("require %q\n"):format(split_ext(path.filename(script)))
        end
        return ""
    end)
if nb_main == 0 then err "No main script" end
if nb_main > 1 then err "There shall be a single main script" end
-- The loader is stored in the Zip archive as other packages.
-- It must be the first entry.
archive.entries:insert(1, zip.Entry("plua-loader", table.concat(loader)))

-- junk dirnames
archive.entries:map(function(entry) entry.path = path.filename(entry.path) end)

-- The archive is stored in a Lua comment.
-- It shall be delimited by comment boundaries that do not appear in the archive.
local archive_bytestring = archive:bytestring():gsub('.', function(c) return string.char(c:byte()~0xA5) end)
local eqs = ""
do
    local n = 0
    while archive_bytestring:find("]"..eqs.."]", nil, true) do
        n = n+1
        eqs = ("="):rep(n)
    end
end

local shebang = "#!/usr/bin/env -S "
        ..(rlwrap and ("rlwrap -C "..path.filename(output).." ") or "")
        .."pandoc lua --\n"
local start, stop = "--["..eqs.."[", "]"..eqs.."]"
local i = #shebang + #start + 1
local j = i + #archive_bytestring - 1

local code = table.concat {
    shebang,
    -- Lua comment containing the Zip archive
    start, archive_bytestring, stop,
    -- _ is the Zip archived stored in the file between indices i and j
    "local _=pandoc.zip.Archive(",
        "(", "io.open(arg[0])",
                 ":read'a'",
                 (":sub(%d,%d)"):format(i, j),
                 ":gsub('.',function(x)",
                     "return string.char(x:byte()~0xA5)",
                 "end)",
        ")",
    ").entries;",
    -- the first entry is a function that takes entries,
    -- updates package.searchers,
    -- loads libraries
    -- and runs the main script
    "assert(load(_[1]:contents(),'@'..arg[0]))(_)",
}

local f, msg = io.open(output, "wb")
if not f then err("%s", msg) end
assert(f)
f:write(code)
f:close()

log("%s: %d bytes written", output, #code)

local ok, chmod_error = pcall(pandoc.pipe, "chmod", {"+x", output}, "")
if not ok then
    err("%s: %s", output, chmod_error)
end
