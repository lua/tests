print("testando erros")

local old = _ERRORMESSAGE

function doit (s)
  local m = {msg = nil}
  call(dostring, {s}, '', function (s) %m.msg = s end)
  assert(%old == _ERRORMESSAGE and %old~=nil)
  return m.msg;
end


-- testa erros comuns e/ou que voavam no passado
assert(doit("a=sin()"))
assert(not doit("tostring(1)") and doit("tostring()"))
assert(doit"tonumber()")
assert(doit"repeat until 1; a")
assert(strfind(doit"break label", "label"))
assert(doit";")
assert(doit"a=1;;")
assert(doit"return;;")
assert(doit"assert(false)")
assert(doit"assert(nil)")
assert(doit"a=sin\n(3)")
assert(doit("function a (... , ...) end"))
assert(doit("function a (, ...) end"))
assert(strfind(doit'%a()', "line 1"))
assert(strfind(doit[[
  local other, var = 1
  other = other or %var

]], "line 2"))

-- testes para mensagens de erro mais explicativas

assert(strfind(doit"a=1; bbbb=2; a=sin(3)+bbbb(3)", "global `bbbb'"))
assert(strfind(doit"a=1; local a,bbbb=2,3; a = sin(1) and bbbb(3)",
       "local `bbbb'"))
assert(strfind(doit"a={}; do local a=1 end a:bbbb(3)", "field `bbbb'"))
assert(strfind(doit"local a={}; a.bbbb(3)", "field `bbbb'"))
assert(not strfind(doit"a={13}; local bbbb=1; a[bbbb](3)", "bbbb"))
assert(strfind(doit"a={13}; local bbbb=1; a[bbbb](3)", "number"))

aaa = nil
assert(strfind(doit"aaa.bbb:ddd(9)", "global `aaa'"))
assert(strfind(doit"local aaa={bbb=1}; aaa.bbb:ddd(9)", "field `bbb'"))
assert(strfind(doit"local aaa={bbb={}}; aaa.bbb:ddd(9)", "field `ddd'"))
assert(doit"local aaa={bbb={ddd=next}}; aaa.bbb:ddd(nil)" == nil)

assert(strfind(doit"local aaa='a'; x=aaa+b", "local `aaa'"))
assert(strfind(doit"aaa={}; x=3/aaa", "global `aaa'"))
assert(strfind(doit"aaa='2'; b=nil;x=aaa*b", "global `b'"))
assert(strfind(doit"aaa={}; x=-aaa", "global `aaa'"))
assert(not strfind(doit"aaa={}; x=(aaa or aaa)+(aaa and aaa)", "aaa"))
assert(not strfind(doit"aaa={}; (aaa or aaa)()", "aaa"))

assert(strfind(doit[[aaa=9
repeat until 3==3
local x=sin(cos(3))
if sin(1) == x then return 1,2,sin(1) end   -- tail call
local a,b = 1, {
  {x='a'..'b'..'c', y='b', z=x},
  {1,2,3,4,5} or 3+3<=3+3,
  3+1>3+1,
  {d = x and aaa[x or y]}}
]], "global `aaa'"))

assert(strfind(doit[[
local x,y = {},1
if sin(1) == 0 then return 3 end    -- return
x.a()]], "field `a'"))

assert(strfind(doit[[
prefix = nil
while 1 do  
  local a
  if nil then break end
  insert(prefix, w)
end]], "global `insert'"))


i = 0
function y () i=i+1; y() end

local stackmsg = "stack overflow"
assert(doit('y()') == stackmsg)
assert(doit('y()') == stackmsg)
assert(doit('y()') == stackmsg)
print('+')
assert(strfind(doit("syntax error"), "syntax error"))

doit('i = dostring("a=9+"); a=3')
assert(a==3 and i == nil)
print('+')

do
  local a,b = call(dostring, {"a='x'+1"}, 'x', error)
  assert(a == nil and b == "error in error handling")
end

lim = 1000
if _soft then lim = 100 end
for i=1,lim do
  doit('a = ')
  doit('a = 4+nil')
end

print('OK')
