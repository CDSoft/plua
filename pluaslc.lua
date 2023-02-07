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
    local out = msg and io.stdout or io.stderr
    out:write [[Overview: Pandoc Lua Standard Library Compiler

]]
    if msg then
        out:write("Error: ", msg:format(...), "\n\n")
    end
    out:write [[Usage: pluaslc.lua [-h] -o <output> [<script.lua>]

Options:
    -h              print this help and exits
    -o filename     set the output filename
    filename        use filename as a library

Scripts can contain tags:
    @RUN    run the script with require before the main script
    @LOAD   run the script with require
            and store the module in a global variable

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
do
    local i = 1
    while arg[i] do
        local a = arg[i]
        i = i+1
        if a == "-h" then
            usage()
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
    print(fmt:format(...))
end

if #scripts == 0 then usage "No input scripts" end
if not output then usage "No output" end

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
        if tag.main then
            err("%s: a library can not contain main script (@MAIN)")
        end
        f:close()
    else
       err("%s", msg)
   end
    assert(loadfile(script))
    log("%s: ok", script)
    tags[script] = tag
end)

local _, lib_type = split_ext(output)

if lib_type == ".zip" then

    -- Scripts are stored in a Zip archive that is used at runtime to load Lua packages
    log("%s: zip %s", output, table.concat(scripts, " "))
    local archive = zip.zip(scripts, {verbose=true})

    -- The loader is the first module loaded at runtime.
    -- It loads the scripts tagged with @LOAD or @RUN
    local loader = scripts:map(function(script)
        if tags[script].load then
            log("%s: loaded at init (%s = require %q)", script, split_ext(path.filename(script)):gsub("-", "_"), split_ext(path.filename(script)))
            return ("%s = require %q\n"):format(split_ext(path.filename(script)):gsub("-", "_"), split_ext(path.filename(script)))
        elseif tags[script].run then
            log("%s: run at init (require %q)", script, split_ext(path.filename(script)))
            return ("require %q\n"):format(split_ext(path.filename(script)))
        end
        return ""
    end)
    -- The loader is stored in the Zip archive as other packages
    archive.entries:insert(zip.Entry("plua-stdlib.lua", table.concat(loader)))

    -- junk dirnames
    archive.entries:map(function(entry) entry.path = path.filename(entry.path) end)

    local archive_bytestring = archive:bytestring()

    local f, msg = io.open(output, "wb")
    if not f then err("%s", msg) end
    assert(f)
    f:write(archive_bytestring)
    f:close()

    log("%s: %d bytes written", output, #archive_bytestring)

elseif lib_type == ".lua" then

    log("%s: lua %s", output, table.concat(scripts, " "))
    local archive = L{}

    archive:insert("local plua_libs = {")
    scripts:map(function(script)
        archive:insert(("%s = (function()"):format(split_ext(path.filename(script))))
        local f = assert(io.open(script))
        archive:insert(f:read "a")
        f:close()
        archive:insert("end),")
    end)
    archive:insert("}")
    archive:insert("table.insert(package.searchers, 1, function(name)")
    archive:insert("    return plua_libs[name]")
    archive:insert("end)")

    -- It loads the scripts tagged with @LOAD or @RUN
    scripts:map(function(script)
        if tags[script].load then
            log("%s: loaded at init (%s = require %q)", script, split_ext(path.filename(script)):gsub("-", "_"), split_ext(path.filename(script)))
            archive:insert(("%s = require %q"):format(split_ext(path.filename(script)):gsub("-", "_"), split_ext(path.filename(script))))
        elseif tags[script].run then
            log("%s: run at init (require %q)", script, split_ext(path.filename(script)))
            archive:insert(("require %q"):format(split_ext(path.filename(script))))
        end
    end)

    local archive_str = table.concat(archive, "\n")

    local f, msg = io.open(output, "wb")
    if not f then err("%s", msg) end
    assert(f)
    f:write(archive_str)
    f:close()

    log("%s: %d bytes written", output, #archive_str)

end
