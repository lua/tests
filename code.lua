print "testing code-consistency checker"

do
-- the following tests all get bugs in 5.1.3

-- SETLIST - RETURN ending a function
local a1 = string.dump(function()return;end)
local a = a1:gsub(string.char(30,37,122,128), string.char(34,0,0), 1)
assert(a1 ~= a)
assert(not loadstring(a))

-- LOADBOOL - SETLIST - CLOSURE (LOADBOOL jumps over SETLIST, going to
-- a non instruction)
a1 = string.dump(function(...)a,b,c,d=...;a=1;end)
a = a1:gsub("e%z\128\2.....",'\2@\128\0"\0\128\0$')
assert(a1 ~= a)
assert(not loadstring(a))

-- lua_assert instead of check
a1 = string.dump(function(a,b,c)end)
a = a1:gsub("%z\3%z\3","\0\255\1\3",1)
assert(a1 ~= a)
assert(not loadstring(a))

-- precheck assumes code size >= 1 (when checking OP_RETURN at the end)
a = string.dump(function()end)
a = a:gsub("....\30%z\128%z.*",("\0"):rep(64),1)
assert(not loadstring(a))

-- code validator rejected (maliciously crafted) correct code
z={}
for i=1,27290 do z[i]='1,' end
z = 'if 1+1==2 then local a={' .. table.concat(z) .. '} end'
func = loadstring(z)
assert(loadstring(string.dump(func)))

-- invalid boolean values
maybe = string.dump(function() return ({[true]=true})[true] end)
maybe = maybe:gsub('\1\1','\1\2')
maybe = loadstring(maybe)()
assert(type(maybe) == "boolean" and maybe == true)

-- code too deep in precompiled chunk
local init = '\27\76\117\97\81\0\1\4\4\4\8\0\7\0\0\0\61\115\116' ..
             '\100\105\110\0\1\0\0\0\1\0\0\0\0\0\0\2\2\0\0\0\36' ..
             '\0\0\0\30\0\128\0\0\0\0\0\1\0\0\0\0\0\0\0\1\0\0\0' ..
             '\1\0\0\0\0\0\0\2'
local mid = '\1\0\0\0\30\0\128\0\0\0\0\0\0\0\0\0\1\0\0\0\1\0\0\0\0'
local fin = '\0\0\0\0\0\0\0\2\0\0\0\1\0\0\0\1\0\0\0\1\0\0\0\2\0' ..
            '\0\0\97\0\1\0\0\0\1\0\0\0\0\0\0\0'
local lch = '\2\0\0\0\36\0\0\0\30\0\128\0\0\0\0\0\1\0\0\0\0\0\0' ..
            '\0\1\0\0\0\1\0\0\0\0\0\0\2'
local rch = '\0\0\0\0\0\0\0\2\0\0\0\1\0\0\0\1\0\0\0\1\0\0\0\2\0' ..
            '\0\0\97\0\1\0\0\0\1'
for i=1,10 do lch,rch = lch..lch,rch..rch end
assert(not loadstring(init .. lch .. mid .. rch .. fin))


-- incomplete dumps
local prog = string.dump(function () local a = 10; a=a+3.4; return a end)
for i = 1, #prog - 1 do
  assert(not loadstring(prog:sub(1,i)))
end
assert(loadstring(prog:sub(1,#prog))() == 13.4)


end


print"+"



-- old bug: the assignment of nil to the parameter was optimized away
function f (a)
  a=nil
  return a
end

assert(f("test") == nil)

if T==nil then
  (Message or print)('\a\n >>> testC not active: skipping opcode tests <<<\n\a')
  return
end
print "testing code generation and optimizations"


-- this code gave an error for the code checker
do
  local function f (a)
  for k,v,w in a do end
  end
end



function check (f, ...)
  local c = T.listcode(f)
  for i=1, arg.n do
    -- print(arg[i], c[i])
    assert(string.find(c[i], '- '..arg[i]..' *%d'))
  end
  assert(c[arg.n+2] == nil)
end


function checkequal (a, b)
  a = T.listcode(a)
  b = T.listcode(b)
  for i = 1, table.getn(a) do
    a[i] = string.gsub(a[i], '%b()', '')   -- remove line number
    b[i] = string.gsub(b[i], '%b()', '')   -- remove line number
    assert(a[i] == b[i])
  end
end


-- some basic instructions
check(function ()
  (function () end){f()}
end, 'CLOSURE', 'NEWTABLE', 'GETGLOBAL', 'CALL', 'SETLIST', 'CALL', 'RETURN')


-- sequence of LOADNILs
check(function ()
  local a,b,c
  local d; local e;
  a = nil; d=nil
end, 'LOADNIL', 'LOADNIL', 'RETURN')


-- single return
check (function (a,b,c) return a end, 'RETURN')


-- infinite loops
check(function () while true do local a = -1 end end,
'LOADK', 'JMP', 'RETURN')

check(function () while 1 do local a = -1 end end,
'LOADK', 'JMP', 'RETURN')

check(function () repeat local x = 1 until false end,
'LOADK', 'JMP', 'RETURN')

check(function () repeat local x until nil end,
'LOADNIL', 'JMP', 'RETURN')

check(function () repeat local x = 1 until true end,
'LOADK', 'RETURN')


-- concat optimization
check(function (a,b,c,d) return a..b..c..d end,
  'MOVE', 'MOVE', 'MOVE', 'MOVE', 'CONCAT', 'RETURN')

-- not
check(function () return not not nil end, 'LOADBOOL', 'RETURN')
check(function () return not not false end, 'LOADBOOL', 'RETURN')
check(function () return not not true end, 'LOADBOOL', 'RETURN')
check(function () return not not 1 end, 'LOADBOOL', 'RETURN')

-- direct access to locals
check(function ()
  local a,b,c,d
  a = b*2
  c[4], a[b] = -((a + d/-20.5 - a[b]) ^ a.x), b
end,
  'MUL',
  'DIV', 'ADD', 'GETTABLE', 'SUB', 'GETTABLE', 'POW',
    'UNM', 'SETTABLE', 'SETTABLE', 'RETURN')


-- direct access to constants
check(function ()
  local a,b
  a.x = 0
  a.x = b
  a[b] = 'y'
  a = 1 - a
  b = 1/a
  b = 5+4
  a[true] = false
end,
  'SETTABLE', 'SETTABLE', 'SETTABLE', 'SUB', 'DIV', 'LOADK',
  'SETTABLE', 'RETURN')

local function f () return -((2^8 + -(-1)) % 8)/2 * 4 - 3 end

check(f, 'LOADK', 'RETURN')
assert(f() == -5)

check(function ()
  local a,b,c
  b[c], a = c, b
  b[a], a = c, b
  a, b = c, a
  a = a
end, 
  'MOVE', 'MOVE', 'SETTABLE',
  'MOVE', 'MOVE', 'MOVE', 'SETTABLE',
  'MOVE', 'MOVE', 'MOVE',
  -- no code for a = a
  'RETURN')

-- bug in constant folding for 5.1
check(function () return -nil end, 'UNM', 'RETURN')


-- x == nil , x ~= nil
checkequal(function () if (a==nil) then a=1 end; if a~=nil then a=1 end end,
           function () if (a==9) then a=1 end; if a~=9 then a=1 end end)

check(function () if a==nil then a=1 end end,
'GETGLOBAL', 'EQ', 'JMP', 'LOADK', 'SETGLOBAL', 'RETURN')

-- de morgan
checkequal(function () local a; if not (a or b) then b=a end end,
           function () local a; if (not a and not b) then b=a end end)

checkequal(function (l) local a; return 0 <= a and a <= l end,
           function (l) local a; return not (not(a >= 0) or not(a <= l)) end)


print 'OK'

