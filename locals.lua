print('testing local variables and environments')


-- bug in 5.1:

local function f(x) x = nil; return x end
assert(f(10) == nil)

local function f() local x; return x end
assert(f(10) == nil)

local function f(x) x = nil; local y; return x, y end
assert(f(10) == nil and select(2, f(20)) == nil)

do
  local i = 10
  do local i = 100; assert(i==100) end
  do local i = 1000; assert(i==1000) end
  assert(i == 10)
  if i ~= 10 then
    local i = 20
  else
    local i = 30
    assert(i == 30)
  end
end



f = nil

local f
x = 1

a = nil
loadstring('local a = {}')()
assert(a == nil)

function f (a)
  local _1, _2, _3, _4, _5
  local _6, _7, _8, _9, _10
  local x = 3
  local b = a
  local c,d = a,b
  if (d == b) then
    local x = 'q'
    x = b
    assert(x == 2)
  else
    assert(nil)
  end
  assert(x == 3)
  local f = 10
end

local b=10
local a; repeat local b; a,b=1,2; assert(a+1==b); until a+b==3


assert(x == 1)

f(2)
assert(type(f) == 'function')


-- testing globals ;-)
do
  local f = {}
  local _G = _G
  for i=1,10 do f[i] = function (x) A=A+1; return A, _G.getfenv(x) end end
  A=10; assert(f[1]() == 11)
  for i=1,10 do assert(setfenv(f[i], {A=i}) == f[i]) end
  assert(f[3]() == 4 and A == 11)
  local a,b = f[8](1)
  assert(b.A == 9)
  a,b = f[8](0)
  assert(b.A == 11)   -- `real' global
  local g
  local function f () assert(setfenv(2, {a='10'}) == g) end
  g = function () f(); _G.assert(_G.getfenv(1).a == '10') end
  g(); assert(getfenv(g).a == '10')
end


-- test for global table of loaded chunks
assert(debug.getfenv(load("a = 3")) == _G)
local a = {}; local f = loadin(a, "a = 3")
assert(debug.getfenv(f) == a)
assert(a.a == nil)
f()
assert(a.a == 3)


-- testing limits for special instructions

local a
local p = 4
for i=2,31 do
  for j=-3,3 do
    assert(loadstring(string.format([[local a=%s;a=a+
                                            %s;
                                      assert(a
                                      ==2^%s)]], j, p-j, i))) ()
    assert(loadstring(string.format([[local a=%s;
                                      a=a-%s;
                                      assert(a==-2^%s)]], -j, p-j, i))) ()
    assert(loadstring(string.format([[local a,b=0,%s;
                                      a=b-%s;
                                      assert(a==-2^%s)]], -j, p-j, i))) ()
  end
  p =2*p
end

print'+'


if rawget(_G, "querytab") then
  -- testing clearing of dead elements from tables
  collectgarbage("stop")   -- stop GC
  local a = {[{}] = 4, [3] = 0, alo = 1, 
             a1234567890123456789012345678901234567890 = 10}

  local t = querytab(a)

  for k,_ in pairs(a) do a[k] = nil end
  collectgarbage()   -- restore GC and collect dead fiels in `a'
  for i=0,t-1 do
    local k = querytab(a, i)
    assert(k == nil or type(k) == 'number' or k == 'alo')
  end
end


-- testing lexical environments

in (function (...) return ... end)(_G, dummy) do

in {assert=assert} do assert(true) end
mt = {_G = _G}
local foo,x
in mt do
  function foo (x)
    A = x
    in _G do A = 1000 end
    return function (x) return A .. x end
  end
end
assert(debug.getfenv(foo) == mt)
x = foo('hi'); assert(mt.A == 'hi' and A == 1000)
assert(x('*') == mt.A .. '*')

in {assert=assert, A=10} do
  in {assert=assert, A=20} do
    assert(A==20);x=A
  end
  assert(A==10 and x==20)
end
assert(x==20)

-- in as a block (local scope)
A = 20
in _G do local A = 15; assert(A==15) end
assert(A == 20)


-- in versus break
A = 0
for i = 1,20 do
  A = A + 1
  in nil do break end
  error("not here")
end
assert(A == 1)

-- closure in non-table environment
local f = function () in 34 do return function () end end end
local s,msg = pcall(f)
assert(not s and msg:find"not a table")

print('OK')

return 5,f

end

