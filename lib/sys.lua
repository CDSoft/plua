-- sys module
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
# sys: System module

```lua
local sys = require "sys"
```
@@@]]

local sys = {}

--[[@@@
```lua
sys.os
```
`"linux"`, `"macos"` or `"windows"`.

```lua
sys.arch
```
`"x86_64"`, `"i386"` or `"aarch64"`.
@@@]]

sys.os = pandoc.system.os
sys.arch = pandoc.system.arch

-------------------------------------------------------------------------------
-- module
-------------------------------------------------------------------------------

return sys
