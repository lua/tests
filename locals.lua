print('testando variaveis locais')

f = nil

local f
x = 1

assert(type(dostring('local a = {}')) == 'userdata')

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

-- shadowing
assert(not call(dostring, {[[local a; function a() x=a end]]}, '', nil))

assert(x == 1)

f(2)
assert(type(f) == 'function')


-- testando limites para instrucoes especiais

local a
local p = 4
for i=2,31 do
  for j=-3,3 do
    assert(dostring(format([[local a=%d;a=a+
                                            %u;
                             assert(a
                                      ==2^%d)]], j, p-j, i)))
    assert(dostring(format([[local a=%d;
                             a=a-%u;
                             assert(a==-2^%d)]], -j, p-j, i)))
    assert(dostring(format([[local a,b=0,%d;
                             a=b-%u;
                             assert(a==-2^%d)]], -j, p-j, i)))
  end
  p =2*p
end

print('OK')

return 5,f
