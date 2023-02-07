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

-- @MAIN

log "Testing plua:"

-- Check the test environment first
require "test_test"()

-- plua builtins
require "arg_test"()
require "require_test"()

-- plua libraries
require "F_test"()
require "sys_test"()
require "fs_test"()
require "sh_test"()
require "crypt_test"()
require "inspect_test"()
require "serpent_test"()
