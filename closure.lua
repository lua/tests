print "testando closures e co-rotinas"

local A,B = 0,{g=10}
function f(x)
  local a = {}
  for i=1,1000 do
    local y = 0
    do
      a[i] = function () B.g = B.g+1; y = y+x; return y+A end
    end
  end
  local dummy = function () return a[A] end
  collectgarbage()
  A = 1; assert(dummy() == a[1]); A = 0;
  assert(a[1]() == x)
  assert(a[3]() == x)
  collectgarbage()
  assert(B.g == 12)
  return a
end

a = f(10)
-- force a GC in this level
local x = setmode({[1] = {}}, 'kv'); -- to detect a GC
while x[1] do   -- repeat until GC
  local a = A..A..A..A  -- create garbage
  A = A+1
end
assert(a[1]() == 20+A)
assert(a[1]() == 30+A)
assert(a[2]() == 10+A)
collectgarbage()
assert(a[2]() == 20+A)
assert(a[2]() == 30+A)
assert(a[3]() == 20+A)
assert(a[8]() == 10+A)
assert(getmode(x) == 'kv')
assert(B.g == 19)

-- teste de closure com variavel de controle do for
a = {}
for i=1,2 do
  a[i] = {set = function(x) i=x end, get = function () return i end}
end
a[1].set(10)
assert(a[2].get() == 10)
a[2].set('a')
assert(a[1].get() == 'a')

a = {}
for i in {'a', 'b'} do
  a[i] = {set = function(x) i=x end, get = function () return i end}
end
a[1].set(10)
assert(a[2].get() == 10)
a[2].set('a')
assert(a[1].get() == 'a')

-- teste de closure x break x return x erros

local b
function f(x)
  local first = 1
  while 1 do
    if x == 3 and not first then return end
    local a = 'xuxu'
    b = function (op, y) if op == 'set' then a = x+y else return a end end
    if x == 1 then do break end
    elseif x == 2 then return
    else if x ~= 3 then error() end
    end
    first = nil
  end
end

for i=1,3 do
  f(i)
  assert(b('get') == 'xuxu')
  b('set', 10); assert(b('get') == 10+i)
  b = nil
end

pcall(f, 4);
assert(b('get') == 'xuxu')
b('set', 10); assert(b('get') == 14)


local w
-- teste de closure com varios niveis
function f(x)
  return function (y)
    return function (z) return w+x+y+z end
  end
end

y = f(10)
w = 1.345
assert(y(20)(30) == 60+w)

print'+'

-- teste de co-rotinas

local function eqtab (t1, t2)
  assert(table.getn(t1) == table.getn(t2))
  for i,v in ipairs(t1) do
    assert(t2[i] == v)
  end
end

function foo (a, ...)
  for i=1,arg.n do
    _G.x = {coroutine.yield(unpack(arg[i]))}
  end
  return unpack(a)
end

local f = coroutine.create(foo)
assert(type(f) == "thread")
local s,a,b,c,d
s,a,b,c,d = coroutine.resume(f, {1,2,3}, {}, {1}, {'a', 'b', 'c'})
assert(s and a == nil)
s,a,b,c,d = coroutine.resume(f)
eqtab(_G.x, {})
assert(s and a == 1 and b == nil)
s,a,b,c,d = coroutine.resume(f, 1, 2, 3)
eqtab(_G.x, {1, 2, 3})
assert(s and a == 'a' and b == 'b' and c == 'c' and d == nil)
s,a,b,c,d = coroutine.resume(f, "xuxu")
eqtab(_G.x, {"xuxu"})
assert(s and a == 1 and b == 2 and c == 3 and d == nil)
s, a = coroutine.resume(f, "xuxu")
assert(not s and string.find(a, "dead"))


-- yields in tail calls
local function foo (i) return coroutine.yield(i) end
f = coroutine.wrap(function ()
  for i=1,10 do
    assert(foo(i) == _G.x)
  end
  return 'a'
end)
for i=1,10 do _G.x = i; assert(f(i) == i) end
_G.x = 'xuxu'; assert(f('xuxu') == 'a')

-- recursive
function pf (n, i)
  coroutine.yield(n)
  pf(n*i, i+1)
end

f = coroutine.wrap(pf)
local s=1
for i=1,10 do
  assert(f(1, 1) == s)
  s = s*i
end

-- sieve
function gen (n)
  return coroutine.wrap(function ()
    for i=2,n do coroutine.yield(i) end
  end)
end


function filter (p, g)
  return coroutine.wrap(function ()
    while 1 do
      local n = g()
      if n == nil then return end
      if math.mod(n, p) ~= 0 then coroutine.yield(n) end
    end
  end)
end

local x = gen(100)
local a = {}
while 1 do
  local n = x()
  if n == nil then break end
  table.insert(a, n)
  x = filter(n, x)
end

assert(table.getn(a) == 25 and a[table.getn(a)] == 97)


-- errors in coroutines
function foo ()
  assert(debug.getinfo(1).currentline == debug.getinfo(foo).linedefined + 1)
  assert(debug.getinfo(2).currentline == debug.getinfo(goo).linedefined)
  coroutine.yield(3)
  error(foo)
end

function goo() foo() end
x = coroutine.wrap(goo)
assert(x() == 3)
local a,b = pcall(x)
assert(not a and b == foo)

x = coroutine.create(goo)
a,b = coroutine.resume(x)
assert(a and b == 3)
a,b = coroutine.resume(x)
assert(not a and b == foo)
a,b = coroutine.resume(x)
assert(not a and string.find(b, "dead"))


-- co-routines x for loop
function all (a, n, k)
  if k == 0 then coroutine.yield(a)
  else
    for i=1,n do
      a[k] = i
      all(a, n, k-1)
    end
  end
end

local a = 0
for t in coroutine.wrap(function () all({}, 5, 4) end) do
  a = a+1
end
assert(a == 5^4)


-- access to locals of "dead" corroutines
local C = {}; setmode(C, "kv")
local x = coroutine.wrap (function ()
            local a = 10
            local function f () a = a+10; return a end
            while true do
              a = a+1
              coroutine.yield(f)
            end
          end)

C[1] = x;

local f = x()
assert(f() == 21 and x()() == 32 and x() == f)
x = nil
collectgarbage()
assert(C[1] == nil)
assert(f() == 43 and f() == 53)


print'OK'
