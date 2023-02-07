-- fs module
-- @LOAD

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

--[[------------------------------------------------------------------------@@@
# fs: File System

`fs` is a File System module. It provides functions to handle files and directory in a portable way.

```lua
local fs = require "fs"
```
@@@]]

local fs = {}

fs.sep = pandoc.path.separator
local pathsep = pandoc.path.search_path_separator

--[[@@@
```lua
fs.getcwd()
```
returns the current working directory.
@@@]]

fs.getcwd = pandoc.system.get_working_directory

--[[@@@
```lua
fs.dir([path])
```
returns the list of files and directories in
`path` (the default path is the current directory).
@@@]]

fs.dir = F.compose{F, pandoc.system.list_directory}

--[[@@@
```lua
fs.remove(name)
```
deletes the file `name`.
@@@]]

function fs.remove(name)
    return os.remove(name)
end

--[[@@@
```lua
fs.rename(old_name, new_name)
```
renames the file `old_name` to `new_name`.
@@@]]

function fs.rename(old_name, new_name)
    return os.rename(old_name, new_name)
end

--[[@@@
```lua
fs.copy(source_name, target_name)
```
copies file `source_name` to `target_name`.
The attributes and times are preserved.
@@@]]

function fs.copy(source_name, target_name)
    local from, err_from = io.open(source_name, "rb")
    if not from then return from, err_from end
    local to, err_to = io.open(target_name, "wb")
    if not to then from:close(); return to, err_to end
    while true do
        local block = from:read(64*1024)
        if not block then break end
        local ok, err = to:write(block)
        if not ok then
            from:close()
            to:close()
            return ok, err
        end
    end
    from:close()
    to:close()
end

--[[@@@
```lua
fs.mkdir(path)
```
creates a new directory `path`.
@@@]]

fs.mkdir = pandoc.system.make_directory

--[[@@@
```lua
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
@@@]]

local S_IRUSR = 1 << 8
local S_IWUSR = 1 << 7
local S_IXUSR = 1 << 6
local S_IRGRP = 1 << 5
local S_IWGRP = 1 << 4
local S_IXGRP = 1 << 3
local S_IROTH = 1 << 2
local S_IWOTH = 1 << 1
local S_IXOTH = 1 << 0

fs.uR = S_IRUSR
fs.uW = S_IWUSR
fs.uX = S_IXUSR
fs.aR = S_IRUSR|S_IRGRP|S_IROTH
fs.aW = S_IWUSR|S_IWGRP|S_IWOTH
fs.aX = S_IXUSR|S_IXGRP|S_IXOTH
fs.gR = S_IRGRP
fs.gW = S_IWGRP
fs.gX = S_IXGRP
fs.oR = S_IROTH
fs.oW = S_IWOTH
fs.oX = S_IXOTH

function fs.stat(name)
    local st = sh.read("LANG=C", "stat", "-L", "-c '%s;%Y;%X;%W;%F;%f'", name, "2>/dev/null")
    if not st then return nil, "cannot stat "..name end
    local size, mtime, atime, ctime, type, mode = st:trim():split ";":unpack()
    mode = tonumber(mode, 16)
    if type == "regular file" then type = "file" end
    return F{
        name = name,
        size = tonumber(size),
        mtime = tonumber(mtime),
        atime = tonumber(atime),
        ctime = tonumber(ctime),
        type = type,
        mode = mode,
        uR = (mode & S_IRUSR) ~= 0,
        uW = (mode & S_IWUSR) ~= 0,
        uX = (mode & S_IXUSR) ~= 0,
        gR = (mode & S_IRGRP) ~= 0,
        gW = (mode & S_IWGRP) ~= 0,
        gX = (mode & S_IXGRP) ~= 0,
        oR = (mode & S_IROTH) ~= 0,
        oW = (mode & S_IWOTH) ~= 0,
        oX = (mode & S_IXOTH) ~= 0,
        aR = (mode & (S_IRUSR|S_IRGRP|S_IROTH)) ~= 0,
        aW = (mode & (S_IWUSR|S_IWGRP|S_IWOTH)) ~= 0,
        aX = (mode & (S_IXUSR|S_IXGRP|S_IXOTH)) ~= 0,
    }
end

--[[@@@
```lua
fs.inode(name)
```
reads device and inode attributes of the file `name`.
Attributes are:

- `dev`, `ino`: device and inode numbers
@@@]]

function fs.inode(name)
    local st = sh.read("LANG=C", "stat", "-L", "-c '%d;%i'", name, "2>/dev/null")
    if not st then return nil, "cannot stat "..name end
    local dev, ino = st:trim():split ";":unpack()
    return F{
        ino = tonumber(ino),
        dev = tonumber(dev),
    }
end

--[[@@@
```lua
fs.chmod(name, other_file_name)
```
sets file `name` permissions as
file `other_file_name` (string containing the name of another file).

```lua
fs.chmod(name, bit1, ..., bitn)
```
sets file `name` permissions as
`bit1` or ... or `bitn` (integers).
@@@]]

function fs.chmod(name, ...)
    local mode = {...}
    if type(mode[1]) == "string" then
        return sh.run("chmod", "--reference="..mode[1], name, "2>/dev/null")
    else
        return sh.run("chmod", ("%o"):format(F(mode):fold(F.op.bor, 0)), name)
    end
end

--[[@@@
```lua
fs.touch(name)
```
sets the access time and the modification time of
file `name` with the current time.

```lua
fs.touch(name, number)
```
sets the access time and the modification
time of file `name` with `number`.

```lua
fs.touch(name, other_name)
```
sets the access time and the
modification time of file `name` with the times of file `other_name`.
@@@]]

function fs.touch(name, opt)
    if opt == nil then
        return sh.run("touch", name, "2>/dev/null")
    elseif type(opt) == "number" then
        return sh.run("touch", "-d", '"'..os.date("%c", opt)..'"', name, "2>/dev/null")
    elseif type(opt) == "string" then
        return sh.run("touch", "--reference="..opt, name, "2>/dev/null")
    else
        error "bad argument #2 to touch (none, nil, number or string expected)"
    end
end

--[[@@@
```lua
fs.basename(path)
```
return the last component of path.
@@@]]

fs.basename = pandoc.path.filename

--[[@@@
```lua
fs.dirname(path)
```
return all but the last component of path.
@@@]]

fs.dirname = pandoc.path.directory

--[[@@@
```lua
fs.splitext(path)
```
return the name without the extension and the extension.
@@@]]

fs.splitext = pandoc.path.split_extension

--[[@@@
```lua
fs.normalize(path)
```
return the normalized path name of path.
@@@]]

fs.normalize = pandoc.path.normalize

--[[@@@
```lua
fs.realpath(path)
```
return the resolved path name of path.
@@@]]

function fs.realpath(path)
    return sh.read("realpath", path) : trim()
end

--[[@@@
```lua
fs.absname(path)
```
return the absolute path name of path.
@@@]]

function fs.absname(path)
    if path:match "^[/\\]" or path:match "^.:" then return path end
    return fs.getcwd()..fs.sep..path
end

--[[@@@
```lua
fs.join(...)
```
return a path name made of several path components
(separated by `fs.sep`).
If a component is absolute, the previous components are removed.
@@@]]

function fs.join(...)
    return pandoc.path.join(F.flatten{...})
end

--[[@@@
```lua
fs.is_file(name)
```
returns `true` if `name` is a file.
@@@]]

function fs.is_file(name)
    local stat = fs.stat(name)
    return stat ~= nil and stat.type == "file"
end

--[[@@@
```lua
fs.is_dir(name)
```
returns `true` if `name` is a directory.
@@@]]

function fs.is_dir(name)
    local stat = fs.stat(name)
    return stat ~= nil and stat.type == "directory"
end

--[[@@@
```lua
fs.findpath(name)
```
returns the full path of `name` if `name` is found in `$PATH` or `nil`.
@@@]]

function fs.findpath(name)
    local function exists_in(path) return fs.is_file(fs.join(path, name)) end
    local path = os.getenv("PATH")
        :split(pathsep)
        :find(exists_in)
    if path then return fs.join(path, name) end
    return nil, name..": not found in $PATH"
end

--[[@@@
```lua
fs.mkdirs(path)
```
creates a new directory `path` and its parent directories.
@@@]]

function fs.mkdirs(path)
    return pandoc.system.make_directory(path, true)
end

--[[@@@
```lua
fs.mv(old_name, new_name)
```
alias for `fs.rename(old_name, new_name)`.
@@@]]

fs.mv = fs.rename

--[[@@@
```lua
fs.rm(name)
```
alias for `fs.remove(name)`.
@@@]]

fs.rm = fs.remove

--[[@@@
```lua
fs.rmdir(path, [params])
```
deletes the directory `path` and its content recursively.
@@@]]

function fs.rmdir(path)
    pandoc.system.remove_directory(path, true)
    return true
end

--[[@@@
```lua
fs.walk([path], [{reverse=true|false, links=true|false, cross=true|false, func=function}])
```
returns a list listing directory and
file names in `path` and its subdirectories (the default path is the current
directory).

Options:

- `reverse`: the list is built in a reverse order
  (suitable for recursive directory removal)
- `links`: follow symbolic links
- `cross`: walk across several devices
- `func`: function applied to the current file or directory.
  `func` takes two parameters (path of the file or directory and the stat object returned by `fs.stat`)
  and returns a boolean (to continue or not walking recursively through the subdirectories)
  and a value (e.g. the name of the file) to be added to the listed returned by `walk`.
@@@]]

function fs.walk(path, options)
    options = options or {}
    local reverse = options.reverse
    local follow_links = options.links
    local cross_device = options.cross
    local func = options.func or function(name, _) return true, name end
    local dirs = {path or "."}
    local acc_files = {}
    local acc_dirs = {}
    local seen = {}
    local dev0 = nil
    local function already_seen(name)
        local inode = fs.inode(name)
        if not inode then return true end
        dev0 = dev0 or inode.dev
        if dev0 ~= inode.dev and not cross_device then
            return true
        end
        if not seen[inode.dev] then
            seen[inode.dev] = {[inode]=true}
            return false
        end
        if not seen[inode.dev][inode.ino] then
            seen[inode.dev][inode.ino] = true
            return false
        end
        return true
    end
    while #dirs > 0 do
        local dir = table.remove(dirs)
        if not already_seen(dir) then
            local names = fs.dir(dir)
            if names then
                table.sort(names)
                for i = 1, #names do
                    local name = dir..fs.sep..names[i]
                    local stat = fs.stat(name)
                    if stat then
                        if stat.type == "directory" or (follow_links and stat.type == "link") then
                            local continue, new_name = func(name, stat)
                            if continue then
                                dirs[#dirs+1] = name
                            end
                            if new_name then
                                if reverse then acc_dirs = {new_name, acc_dirs}
                                else acc_dirs[#acc_dirs+1] = new_name
                                end
                            end
                        else
                            local _, new_name = func(name, stat)
                            if new_name then
                                acc_files[#acc_files+1] = new_name
                            end
                        end
                    end
                end
            end
        end
    end
    return F.flatten(reverse and {acc_files, acc_dirs} or {acc_dirs, acc_files})
end

--[[@@@
```lua
fs.with_tmpfile(f)
```
calls `f(tmp)` where `tmp` is the name of a temporary file.
@@@]]

function fs.with_tmpfile(f)
    return pandoc.system.with_temporary_directory("plua-XXXXXX", function(tmpdir)
        return f(fs.join(tmpdir, "tmpfile"))
    end)
end

--[[@@@
```lua
fs.with_tmpdir(f)
```
calls `f(tmp)` where `tmp` is the name of a temporary directory.
@@@]]

function fs.with_tmpdir(f)
    return pandoc.system.with_temporary_directory("plua-XXXXXX", f)
end

--[[@@@
```lua
fs.with_dir(path, f)
```
changes the current working directory to `path` and calls `f()`.
@@@]]

fs.with_dir = pandoc.system.with_working_directory

--[[@@@
```lua
fs.with_env(env, f)
```
changes the environnement to `env` and calls `f()`.
@@@]]

fs.with_env = pandoc.system.with_environment

--[[@@@
```lua
fs.read(filename)
```
returns the content of the text file `filename`.
@@@]]

function fs.read(name)
    local f, oerr = io.open(name, "r")
    if not f then return f, oerr end
    local content, rerr = f:read("a")
    f:close()
    return content, rerr
end

--[[@@@
```lua
fs.write(filename, ...)
```
write `...` to the text file `filename`.
@@@]]

function fs.write(name, ...)
    local content = F{...}:flatten():str()
    local f, oerr = io.open(name, "w")
    if not f then return f, oerr end
    local ok, werr = f:write(content)
    f:close()
    return ok, werr
end

--[[@@@
```lua
fs.read_bin(filename)
```
returns the content of the binary file `filename`.
@@@]]

function fs.read_bin(name)
    local f, oerr = io.open(name, "rb")
    if not f then return f, oerr end
    local content, rerr = f:read("a")
    f:close()
    return content, rerr
end

--[[@@@
```lua
fs.write_bin(filename, ...)
```
write `...` to the binary file `filename`.
@@@]]

function fs.write_bin(name, ...)
    local content = F{...}:flatten():str()
    local f, oerr = io.open(name, "wb")
    if not f then return f, oerr end
    local ok, werr = f:write(content)
    f:close()
    return ok, werr
end

-------------------------------------------------------------------------------
-- module
-------------------------------------------------------------------------------

return fs
