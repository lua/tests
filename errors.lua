print("testando erros")


function doit (s)
  local m = {msg = nil}
  call(dostring, {s}, '', function (s) %m.msg = s end)
  return m.msg;
end

i = 0
function y () i=i+1; y() end

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
