print "testando closures"

local A = 0
function f(x)
  local a = {}
  for i=1,10000 do
    local y = 0
    a[i] = function () y = y+x; return y+A end
  end
  local dummy = function () return a[A] end
  collectgarbage()
  A = 1; assert(dummy() == a[1]); A = 0;
  assert(a[1]() == x)
  assert(a[3]() == x)
  collectgarbage()
  return a
end

a = f(10)
-- force a GC in this level
local x = {}; weakmode(x, 'kv'); x[1] = {}  -- to detect a GC
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


-- teste de closure com variavel de controle do for
a = {}
for i=1,2 do
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
    if x == 1 then break
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

print'OK'
