print("testando erros")

local old = _ERRORMESSAGE

function doit (s)
  local msg = nil
  call(dostring, {s}, '', function (s) msg = s end)
  assert(%old == _ERRORMESSAGE and %old~=nil)
  return msg;
end


function checkmessage (prog, msg)
  assert(strfind(doit(prog), msg))
end


-- testa erros comuns e/ou que voavam no passado
assert(doit("unpack{n=2^30}"))
assert(doit("a=sin()"))
assert(not doit("tostring(1)") and doit("tostring()"))
assert(doit"tonumber()")
assert(doit"repeat until 1; a")
checkmessage("break label", "label")
assert(doit";")
assert(doit"a=1;;")
assert(doit"return;;")
assert(doit"assert(false)")
assert(doit"assert(nil)")
assert(doit"a=sin\n(3)")
assert(doit("function a (... , ...) end"))
assert(doit("function a (, ...) end"))
checkmessage('%a()', "line 1")
checkmessage([[
  local other, var = 1
  other = other or %var

]], "line 2")

-- testes para mensagens de erro mais explicativas

checkmessage("global a, bbbb, sin; a=1; bbbb=2; a=sin(3)+bbbb(3)",
             "global `bbbb'")
checkmessage("global z in {}; x=2; a=sin(3)+z(3)", "global `z'")
checkmessage("a=1; local a,bbbb=2,3; a = sin(1) and bbbb(3)",
       "local `bbbb'")
checkmessage("a={}; do local a=1 end a:bbbb(3)", "method `bbbb'")
checkmessage("local a={}; a.bbbb(3)", "field `bbbb'")
assert(not strfind(doit"a={13}; local bbbb=1; a[bbbb](3)", "bbbb"))
checkmessage("a={13}; local bbbb=1; a[bbbb](3)", "number")

aaa = nil
checkmessage("aaa.bbb:ddd(9)", "global `aaa'")
checkmessage("local aaa={bbb=1}; aaa.bbb:ddd(9)", "field `bbb'")
checkmessage("local aaa={bbb={}}; aaa.bbb:ddd(9)", "method `ddd'")
assert(doit"local aaa={bbb={ddd=next}}; aaa.bbb:ddd(nil)" == nil)

checkmessage("local aaa='a'; x=aaa+b", "local `aaa'")
checkmessage("aaa={}; x=3/aaa", "global `aaa'")
checkmessage("aaa='2'; b=nil;x=aaa*b", "global `b'")
checkmessage("aaa={}; x=-aaa", "global `aaa'")
assert(not strfind(doit"aaa={}; x=(aaa or aaa)+(aaa and aaa)", "aaa"))
assert(not strfind(doit"aaa={}; (aaa or aaa)()", "aaa"))

checkmessage([[aaa=9
repeat until 3==3
local x=sin(cos(3))
if sin(1) == x then return 1,2,sin(1) end   -- tail call
local a,b = 1, {
  {x='a'..'b'..'c', y='b', z=x},
  {1,2,3,4,5} or 3+3<=3+3,
  3+1>3+1,
  {d = x and aaa[x or y]}}
]], "global `aaa'")

checkmessage([[
local x,y = {},1
if sin(1) == 0 then return 3 end    -- return
x.a()]], "field `a'")

checkmessage([[
prefix = nil
while 1 do  
  local a
  if nil then break end
  insert(prefix, w)
end]], "global `insert'")

print'+'


-- teste de linha do erro

function lineerror (s)
  local line
  call(dostring, {s}, '', function (s) line = getinfo(2, "l").currentline end)
  return line
end

assert(lineerror"local a\n for i=1,'a' do \n print(i) \n end" == 2)
assert(lineerror"\n local a \n for k,v in 3 \n do \n print(k) \n end" == 3)
assert(lineerror"\n\n for k,v in \n 3 \n do \n print(k) \n end" == 4)

lineerror = nil


i = 0
function y () i=i+1; y() end

local stackmsg = "stack overflow"
assert(doit('y()') == stackmsg)
assert(doit('y()') == stackmsg)
assert(doit('y()') == stackmsg)
print('+')
checkmessage(("syntax error"), "syntax error")

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
