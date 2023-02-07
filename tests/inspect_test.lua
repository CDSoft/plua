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

return function()
    log "- inspect"

    local inspect = require "inspect"
    assert(inspect)

    eq(inspect(42), "42")
    eq(inspect("Hello"), '"Hello"')

    eq(inspect({}), "{}")
    eq(inspect({1, 2, 3}), "{ 1, 2, 3 }")
    eq(inspect({x=1, y=2, z=3}), [[
{
  x = 1,
  y = 2,
  z = 3
}]])
    eq(inspect({a={x=1, y=2}, {x=3, y=4}, 5, 6}), [[
{ {
    x = 3,
    y = 4
  }, 5, 6,
  a = {
    x = 1,
    y = 2
  }
}]])

    local t = setmetatable({x = 1}, { __call = function(self) return self.x end })
    eq(inspect(t), [[
{
  x = 1,
  <metatable> = {
    __call = <function 1>
  }
}]])

end
