print('testando variaveis locais e uns extras')

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

assert(type(dostring('local a = {}')) ~= 'table')

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
local a; repeat local b; a,b=1,2; assert(a+1==b); until a+b==11


assert(x == 1)

f(2)
assert(type(f) == 'function')


-- testando globais ;-)
do
  local f = {}
  local _G = _G
  for i=1,10 do f[i] = function (x) A=A+1; return A, _G.getglobals(x) end end
  A=10; assert(f[1]() == 11)
  for i=1,10 do setglobals(f[i], {A=i}) end
  assert(f[3]() == 4 and A == 11)
  local a,b = f[8](1)
  assert(b.A == 9)
  a,b = f[8](0)
  assert(b.A == 11)   -- `real' global
  local function f () setglobals(2, {a='10'}) end
  local function g () f(); _G.assert(_G.getglobals(1).a == '10') end
  g(); assert(getglobals(g).a == '10')
end


-- testando limites para instrucoes especiais

local a
local p = 4
for i=2,31 do
  for j=-3,3 do
    assert(dostring(format([[local a=%s;a=a+
                                            %s;
                             assert(a
                                      ==2^%s)]], j, p-j, i)))
    assert(dostring(format([[local a=%s;
                             a=a-%s;
                             assert(a==-2^%s)]], -j, p-j, i)))
    assert(dostring(format([[local a,b=0,%s;
                             a=b-%s;
                             assert(a==-2^%s)]], -j, p-j, i)))
  end
  p =2*p
end

print'+'


if querytab then
  -- testando remocao de elementos mortos dos indices de tabelas
  collectgarbage(1000000)   -- stop GC
  local a = {[{}] = 4, [3] = 0, alo = 1, 
             a1234567890123456789012345678901234567890 = 10}

  local t = querytab(a)

  for k,_ in a do a[k] = nil end
  collectgarbage()   -- restore GC and collect dead fiels in `a'
  for i=0,t-1 do
    local k = querytab(a, i)
    assert(k == nil or type(k) == 'number' or k == 'alo')
  end
end

print('OK')

return 5,f
