print("testando erros")

local old = _ERRORMESSAGE

function doit (s)
  local m = {msg = nil}
  call(dostring, {s}, '', function (s) %m.msg = s end)
  assert(%old == _ERRORMESSAGE and %old~=nil)
  return m.msg;
end


-- testa erros comuns e/ou que voavam no passado
assert(not doit("tostring(1)") and doit("tostring()"))
assert(doit"tonumber()")
assert(doit"repeat until 1; a")
assert(doit"|label|")
assert(strfind(doit"break label", "label"))
assert(not doit"|label|a=1")
assert(doit";")
assert(doit"a=1;;")
assert(doit"return;;")

-- testes para mensagens de erro mais explicativas (implementacao desfeita...)

-- assert(strfind(doit"a=1; bbbb=2; bbbb(3)", "global `bbbb'"))
-- assert(strfind(doit"a=1; local a,bbbb=2,3; bbbb(3)", "local `bbbb'"))
-- assert(strfind(doit"a={}; a:bbbb(3)", "field `bbbb'"))
-- assert(strfind(doit"local a={}; a.bbbb(3)", "field `bbbb'"))
-- assert(not strfind(doit"a={13}; local bbbb=1; a[bbbb](3)", "bbbb"))
-- assert(strfind(doit"a={13}; local bbbb=1; a[bbbb](3)", "number"))

-- assert(strfind(doit"aaa.bbb:ddd(9)", "global `aaa'"))
-- assert(strfind(doit"local aaa={bbb=1}; aaa.bbb:ddd(9)", "field `bbb'"))
-- assert(strfind(doit"local aaa={bbb={}}; aaa.bbb:ddd(9)", "field `ddd'"))
-- assert(doit"local aaa={bbb={ddd=next}}; aaa.bbb:ddd(nil)" == nil)

i = 0
function y () i=i+1; y() end

local stackmsg = "stack overflow; possible recursion loop"
assert(doit('y()') == stackmsg)
assert(doit('y()') == stackmsg)
assert(doit('y()') == stackmsg)
print('+')
assert(strfind(doit("syntax error"), "syntax error"))

doit('i = dostring("a=9+"); a=3')
assert(a==3 and i == nil)
print('+')

for i=1,1000 do
  doit('a = ')
  doit('a = 4+nil')
end

print('OK')
