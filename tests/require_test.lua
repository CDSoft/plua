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

---------------------------------------------------------------------
-- embeded modules can be loaded with require
---------------------------------------------------------------------

return function()
    log "- require"
    local lib = require "lib"
    local traceback = lib.hello "World":gsub("\t", "    ")
    local expected_traceback = [[
@lib.lua says: Hello World
Traceback test
stack traceback:
    lib.lua:25: in function 'lib.hello'
    require_test.lua:28: in function 'require_test'
    main.lua:30: in main chunk]]

    startswith(traceback, expected_traceback)

end
