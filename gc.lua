print('testando coleta de lixo')

collectgarbage()

setglobal("while", 234)

limit = 5000


contCreate = 0

print('tabelas')
while contCreate <= limit do
  local a = {}; a = nil
  contCreate = contCreate+1
end

a = "a"

contCreate = 0
print('strings')
while contCreate <= limit do
  a = contCreate .. "b";
  a = gsub(a, '(%d%d*)', strupper)
  a = "a"
  contCreate = contCreate+1
end


contCreate = 0

a = {}

print('funcoes')
function a:test ()
  while contCreate <= limit do
    dostring(format("function temp(a) return 'a%d' end", contCreate))
    assert(temp() == format('a%d', contCreate))
    contCreate = contCreate+1
  end
end

a:test()

print('strings longos')
x = "01234567890123456789012345678901234567890123456789012345678901234567890123456789"
assert(strlen(x)==80)
s = ''
n = 0
k = 300
while n < k do s = s..x; n=n+1; j=tostring(n)  end
assert(strlen(s) == k*80)
s = strsub(s, 1, 20000)
s, i = gsub(s, '(%d%d%d%d)', sin)
assert(i==20000/4)
s = nil
x = nil

assert(getglobal("while") == 234)


local oldtm = settagmethod(tag(nil), 'gc', function (x) i = nil end)
i = 1;
while i do a = {} end  -- run until gc

collectgarbage()
i = 1
collectgarbage()
assert(i == nil)

settagmethod(tag(nil), 'gc', oldtm)

print('OK')
