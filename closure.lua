print "testando closures e co-rotinas"

local A,B = 0,{g=10}
global g in B
function f(x)
  local a = {}
  for i=1,10000 do
    local y = 0
    do
      a[i] = function () g = g+1; y = y+x; return y+A end
    end
  end
  local dummy = function () return a[A] end
  collectgarbage()
  A = 1; assert(dummy() == a[1]); A = 0;
  assert(a[1]() == x)
  assert(a[3]() == x)
  collectgarbage()
  assert(g == 12)
  return a
end

a = f(10)
-- force a GC in this level
local x = metatable({[1] = {}}, {__weakmode='kv'}); -- to detect a GC
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
assert(metatable(x).__weakmode == 'kv')
assert(g == 19)

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

call(f, {4}, 'x');
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

function foo (a, ...)
  for i=1,getn(arg) do
    assert(yield(unpack(arg[i])) == nil)
  end
  return unpack(a)
end

local f = coroutine(foo, {1,2,3}, {}, {1}, {'a', 'b', 'c'})
local a,b,c,d
a,b,c,d = f()
assert(a == nil)
a,b,c,d = f()
assert(a == 1 and b == nil)
a,b,c,d = f()
assert(a == 'a' and b == 'b' and c == 'c' and d == nil)
a,b,c,d = f()
assert(a == 1 and b == 2 and c == 3 and d == nil)


-- recursive
function pf (n, i)
  yield(n)
  pf(n*i, i+1)
end

f = coroutine(pf, 1, 1)
local s=1
for i=1,10 do
  assert(f() == s)
  s = s*i
end

-- sieve
function gen (n)
  return coroutine(function ()
    for i=2,n do yield(i) end
  end)
end


function filter (p, g)
  return coroutine(function (g)
    while 1 do
      local n = g()
      if n == nil then return end
      if mod(n, p) ~= 0 then yield(n) end
    end
  end, g)
end

local x = gen(100)
local a = {}
while 1 do
  local n = x()
  if n == nil then break end
  tinsert(a, n)
  x = filter(n, x)
end

assert(a.n == 25 and a[a.n] == 97)


-- errors in coroutines
function foo ()
  assert(getinfo(1).currentline == getinfo(foo).linedefined + 1)
  assert(getinfo(2).currentline == getinfo(goo).linedefined)
  yield(3)
  error('a')
end

function goo() foo() end
x = coroutine(goo)
assert(x() == 3)
local msg = {}
call(x, {}, "x", function (_msg) tinsert(msg, _msg) end)
assert(msg[1] == 'a' and msg.n == 2)


-- co-routines x for loop
function all (a, n, k)
  if k == 0 then yield(a)
  else
    for i=1,n do
      a[k] = i
      all(a, n, k-1)
    end
  end
end

local a = 0
for t in coroutine(all, {}, 5, 4) do
  a = a+1
end
assert(a == 5^4)
  
print'OK'
