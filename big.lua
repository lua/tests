print "testing large tables"

local lim = 2^18 - 10
local prog = { "x = {" }
for i = 1, lim do prog[#prog + 1] = i .. ','  end
prog[#prog + 1] = "}\n"
prog[#prog + 1] = string.format("assert(x[%d] == %d)", lim - 1, lim - 1)
prog = table.concat(prog)
assert(loadstring(prog))()

coroutine.yield'b'
-- do return end


print "testing string length overflow"

local longs = string.rep("\0", 2^25)
local function catter (i)
  return assert(loadstring(
    string.format("return function(a) return a%s end",
                     string.rep("..a", i-1))))()
end
rep129 = catter(129)
local a, b = pcall(rep129, longs)
assert(not a and string.find(b, "overflow"))

print'OK'

return 'a'
