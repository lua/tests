if _soft then
  return 'a'
end

print "testing large tables"

local debug = require"debug" 

local lim = 2^18 + 1000
local prog = { "local y = {0" }
for i = 1, lim do prog[#prog + 1] = i  end
prog[#prog + 1] = "}\n"
prog[#prog + 1] = "X = y\n"
prog[#prog + 1] = ("assert(X[%d] == %d)"):format(lim - 1, lim - 2)
prog[#prog + 1] = "return 0"
prog = table.concat(prog, ";")

local env = {string = string, assert = assert}
local f = assert(loadin(env, prog))

f()
assert(env.X[lim] == lim - 1 and env.X[lim + 1] == lim)
for k in pairs(env) do env[k] = nil end

-- yields during accesses larger than K (in RK)
setmetatable(env, {
  __index = function (t, n) coroutine.yield('g'); return _G[n] end,
  __newindex = function (t, n, v) coroutine.yield('s'); _G[n] = v end,
})

X = nil
co = coroutine.wrap(f)
assert(co() == 's')
assert(co() == 'g')
assert(co() == 'g')
assert(co() == 0)

assert(X[lim] == lim - 1 and X[lim + 1] == lim)

-- errors in accesses larger than K (in RK)
getmetatable(env).__index = function () end
getmetatable(env).__newindex = function () end
local e, m = pcall(f)
assert(not e and m:find("global 'X'"))

-- errors in metamethods 
getmetatable(env).__newindex = function () error("hi") end
local e, m = xpcall(f, debug.traceback)
assert(not e and m:find("'__newindex'"))

f, X = nil

coroutine.yield'b'


print "testing string length overflow"

local longs = string.rep("\0", 2^25)
local function catter (i)
  return assert(load(
    string.format("return function(a) return a%s end",
                     string.rep("..a", i-1))))()
end
local rep129 = catter(129)
local a, b = pcall(rep129, longs)
assert(not a and string.find(b, "overflow"))

print'OK'

return 'a'
