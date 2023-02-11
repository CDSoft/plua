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
-- crypt
---------------------------------------------------------------------

local crypt = require "crypt"

return function()
    log "- crypt"
    local prng = crypt.prng()
    do
        local x = "foobarbaz"
        local y = crypt.hex(x)
        local z = x:hex()
        eq(y, "666F6F62617262617A")
        eq(y, z)
        eq(crypt.unhex(y), x)
        eq(z:unhex(), x)
        for _ = 1, 100 do
            local s = prng:str(256)
            eq(s:hex():unhex(), s)
        end
    end
    do
        do
            local x = "foobarbaz"
            local y = crypt.base64(x)
            local z = x:base64()
            eq(y, "Zm9vYmFyYmF6")
            eq(y, z)
            eq(crypt.unbase64(y), x)
            eq(z:unbase64(), x)
        end
        do
            local x = "foobarbaz1"
            local y = crypt.base64(x)
            local z = x:base64()
            eq(y, "Zm9vYmFyYmF6MQ==")
            eq(y, z)
            eq(crypt.unbase64(y), x)
            eq(z:unbase64(), x)
        end
        do
            local x = "foobarbaz12"
            local y = crypt.base64(x)
            local z = x:base64()
            eq(y, "Zm9vYmFyYmF6MTI=")
            eq(y, z)
            eq(crypt.unbase64(y), x)
            eq(z:unbase64(), x)
        end
        eq((""):base64():unbase64(), "")
        for i = 0, 255 do
            eq(string.char(i):base64():unbase64(), string.char(i))
        end
        for i = 1, 100 do
            local s = prng:str(256 + i%3)
            eq(s:base64():unbase64(), s)
        end
    end
    do
        local x = "foo123456789"
        local y = crypt.crc32(x)
        local z = x:crc32()
        eq(y, 0x72871f0c)
        eq(y, z)
    end
    do
        local x = "foo123456789"
        local y = crypt.crc64(x)
        local z = x:crc64()
        eq(y, 0xd85c06f88a2a27d8)
        eq(y, z)
    end
    do
        do
            local x = "foobar!"
            local key = "rc4key"
            local y = crypt.rc4(x, key)
            local z = crypt.unrc4(y, key)
            ne(y, x)
            eq(z, x)
            eq(crypt.rc4(x, key), x:rc4(key))
            eq(crypt.unrc4(y, key), y:unrc4(key))
            eq(x:rc4(key):unrc4(key), x)
            for _ = 1, 100 do
                local s = prng:str(256)
                local k = prng:str(256)
                eq(s:rc4(k):unrc4(k), s)
            end
        end
        for drop = 0, 10 do
            local x = "foobar!"
            local key = "rc4key"
            local y = crypt.rc4(x, key, drop)
            local z = crypt.unrc4(y, key, drop)
            ne(y, x)
            eq(z, x)
            eq(crypt.rc4(x, key, drop), x:rc4(key, drop))
            eq(crypt.unrc4(y, key, drop), y:unrc4(key, drop))
            eq(x:rc4(key, drop):unrc4(key, drop), x)
            for _ = 1, 100 do
                local s = prng:str(256)
                local k = prng:str(256)
                eq(s:rc4(k, drop):unrc4(k, drop), s)
            end
        end
        do
            for _ = 1, 100 do
                local s = prng:str(256)
                local k = prng:str(256)
                local drop = prng:int() % 4096
                eq(s:rc4(k, drop):unrc4(k, drop), s)
            end
        end
    end
    do
        local rands = {}
        local i = 0
        local done = false
        while not done and i < 10000 do
            i = i+1
            local x = prng:int() % 100                        eq(type(x), "number") eq(math.type(x), "integer")
            bounded(x, 0, 100)
            rands[x] = true
            done = true
            for y = 0, 99 do done = done and rands[y] end
        end
        eq(done, true)
        bounded(i, 100, 2000)
        for _ = 1, 1000 do
            local x = prng:int()                              eq(type(x), "number") eq(math.type(x), "integer")
            local y = prng:int()                              eq(type(y), "number") eq(math.type(y), "integer")
            bounded(x, 0, crypt.RAND_MAX)
            bounded(y, 0, crypt.RAND_MAX)
            ne(x, y)
        end
        for _ = 1, 1000 do
            local x = prng:float()                             eq(type(x), "number") eq(math.type(x), "float")
            local y = prng:float()                             eq(type(y), "number") eq(math.type(y), "float")
            bounded(x, 0.0, 1.0)
            bounded(y, 0.0, 1.0)
            ne(x, y)
        end
        for _ = 1, 100 do
            local x = prng:str(16)                           eq(type(x), "string")
            local y = prng:str(16)                           eq(type(y), "string")
            eq(#x, 16)
            eq(#y, 16)
            ne(x, y)
        end
        for _ = 1, 1000 do
            bounded(prng:int(), 0, crypt.RAND_MAX)
            bounded(prng:int(15), 0, 15)
            bounded(prng:int(5, 15), 5, 15)
            bounded(prng:float(), 0.0, 1.0)
            bounded(prng:float(3.5), 0.0, 3.5)
            bounded(prng:float(2.5, 3.5), 2.5, 3.5)
        end
    end
    do
        local r1 = crypt.prng(42)
        local r2 = crypt.prng(42)
        local r3 = crypt.prng(43)
        for _ = 1, 100 do
            local x1 = r1:int()                                eq(type(x1), "number") eq(math.type(x1), "integer")
            local x2 = r2:int()                                eq(type(x2), "number") eq(math.type(x2), "integer")
            local x3 = r3:int()                                eq(type(x2), "number") eq(math.type(x3), "integer")
            eq(x1, x2)
            ne(x1, x3)
            local s1 = r1:str(32)                             eq(type(s1), "string") eq(#s1, 32)
            local s2 = r2:str(32)                             eq(type(s2), "string") eq(#s2, 32)
            local s3 = r3:str(32)                             eq(type(s3), "string") eq(#s3, 32)
            eq(s1, s2)
            ne(s1, s3)
            local f1 = r1:float()                               eq(type(f1), "number") eq(math.type(f1), "float")
            local f2 = r2:float()                               eq(type(f2), "number") eq(math.type(f2), "float")
            local f3 = r3:float()                               eq(type(f3), "number") eq(math.type(f3), "float")
            eq(f1, f2)
            ne(f1, f3)
        end
        for _ = 1, 1000 do
            bounded(r1:int(), 0, crypt.RAND_MAX)
            bounded(r1:int(15), 0, 15)
            bounded(r1:int(5, 15), 5, 15)
            bounded(r1:float(), 0.0, 1.0)
            bounded(r1:float(3.5), 0.0, 3.5)
            bounded(r1:float(2.5, 3.5), 2.5, 3.5)
        end
    end

    -- Encryption tests
    do
        eq(crypt.sha1("abc"), "a9993e364706816aba3e25717850c26c9cd0d89d")
        eq(crypt.sha1(""), "da39a3ee5e6b4b0d3255bfef95601890afd80709")
        eq(crypt.sha1("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"), "84983e441c3bd26ebaae4aa1f95129e5e54670f1")
        for _ = 1, 100 do
            local s = prng:str(prng:int()%1024)
            eq(s:sha1(), crypt.sha1(s))
        end
    end
    do
        do
            for _ = 1, 100 do
                local x = prng:str(prng:int(1, 256))
                local key = prng:str(prng:int(1, 256))
                local y = crypt.rc4(x, key)
                local z = crypt.unrc4(y, key)
                ne({y:byte(1, -1)}, {x:byte(1, -1)})
                eq({z:byte(1, -1)}, {x:byte(1, -1)})
                eq({y:byte(1, -1)}, {x:rc4(key):byte(1, -1)})
                eq({z:byte(1, -1)}, {y:unrc4(key):byte(1, -1)})
            end
        end
    end
end
