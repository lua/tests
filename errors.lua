print("testando erros")


function doit (s)
  local m = {msg = nil}
  call(dostring, {s}, '', function (s) %m.msg = s end)
  return m.msg;
end


assert(strfind(doit"a=1; bbbb=2; bbbb(3)", "global `bbbb'"))
assert(strfind(doit"a=1; local a,bbbb=2,3; bbbb(3)", "local `bbbb'"))
assert(strfind(doit"a={}; a:bbbb(3)", "field `bbbb'"))
assert(strfind(doit"local a={}; a.bbbb(3)", "field `bbbb'"))
assert(not strfind(doit"a={13}; local bbbb=1; a[bbbb](3)", "bbbb"))
assert(strfind(doit"a={13}; local bbbb=1; a[bbbb](3)", "number"))

assert(strfind(doit"aaa.bbb:ddd(9)", "global `aaa'"))
assert(strfind(doit"local aaa={bbb=1}; aaa.bbb:ddd(9)", "field `bbb'"))
assert(strfind(doit"local aaa={bbb={}}; aaa.bbb:ddd(9)", "field `ddd'"))
assert(doit"local aaa={bbb={ddd=next}}; aaa.bbb:ddd(nil)" == nil)

i = 0
function y () i=i+1; y() end

assert(doit('y()')=="stack size overflow")
assert(doit('y()')=="stack size overflow")
assert(doit('y()')=="stack size overflow")
print('+')
assert(strfind(doit("syntax error"), "syntax error"))

doit('i = dostring("a=9+"); a=3')
assert(a==3 and i == nil)
print('+')

i = 1
while i<10000 do
  doit('a = ')
  doit('a = 4+nil')
  i = i+1
end

print('OK')
