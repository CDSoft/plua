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
-- arg is built by the runtime
---------------------------------------------------------------------

return function()
    log "- arg"
    eq(arg, {
        [-2]="pandoc lua", [-1]="--",
        [0]=".build/test-plua",
        "Pandoc", "and", "Lua", "are", "great"
    })
end
