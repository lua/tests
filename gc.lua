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
    loadstring(format("function temp(a) return 'a%d' end", contCreate))()
    assert(temp() == format('a%d', contCreate))
    contCreate = contCreate+1
  end
end

a:test()

-- coleta de funcao sem locais, globais, etc.
do local f = function () end end


print("funcoes com erros")
prog = [[
do
  a = 10;
  function foo(x,y)
    a = sin(a+0.456-0.23e-12);
    return function (z) return sin(%x+z) end
  end
  local x = function (w) a=a+w; end
end
]]
do
  local step = 1
  if _soft then step = 13 end
  for i=1, strlen(prog), step do
    for j=i, strlen(prog), step do
      pcall(loadstring(strsub(prog, i, j)))
    end
  end
end

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


local bytes = gcinfo()
while 1 do
  local nbytes = gcinfo()
  if nbytes < bytes then break end   -- run until gc
  bytes = nbytes
  a = {}
end

collectgarbage()

do  -- testa collectgarbage com valores
  local a,b = gcinfo()
  collectgarbage(b+10)
  local c,d = gcinfo(); assert(c<=d)
  assert(d == b+10)
  collectgarbage(2^30)
  c,d = gcinfo(); assert(c<=d)
  assert(d == 2^22-1)   -- ULONG_MAX/1K
  collectgarbage(b)     -- restore original value
  c,d = gcinfo(); assert(c<=d)
  assert(d == b)
end

lim = 15
a = {}
-- fill a with `collectable' indices
for i=1,lim do a[{}] = i end
b = {}
for k,v in a do b[k]=v end
-- remove all indices and collect them
for n in b do
  a[n] = nil
  assert(type(n) == 'table' and next(n) == nil)
  collectgarbage()
end
b = nil
collectgarbage()
for n in a do error'cannot be here' end
for i=1,lim do a[i] = i end
for i=1,lim do assert(a[i] == i) end


print('weak tables')
a = setmode({}, 'k'); assert(getmode(a) == 'k')
-- fill a with some `collectable' indices
for i=1,lim do a[{}] = i end
-- and some non-collectable ones
for i=1,lim do local t={}; a[t]=t end
for i=1,lim do a[i] = i end
for i=1,lim do local s=strrep('@', i); a[s] = s..'#' end
collectgarbage()
local i = 0
for k,v in a do assert(k==v or k..'#'==v); i=i+1 end
assert(i == 3*lim)

a = setmode({}, 'v'); assert(getmode(a) == 'v')
a[1] = strrep('b', 21)
collectgarbage()
assert(a[1])   -- strings are *values*
a[1] = nil
-- test setn
do
  local t = {}; table.setn(t, 10);
  assert(table.getn(t) == 10)
  a[1] = t
end
collectgarbage()
assert(a[1] == nil)
-- fill a with some `collectable' values (in both parts of the table)
for i=1,lim do a[i] = {} end
for i=1,lim do a[i..'x'] = {} end
-- and some non-collectable ones
for i=1,lim do local t={}; a[t]=t end
for i=1,lim do a[i+lim]=i..'x' end
collectgarbage()
local i = 0
for k,v in a do assert(k==v or k-lim..'x' == v); i=i+1 end
assert(i == 2*lim)

a = setmode({}, 'vk'); assert(getmode(a) == 'kv')
local x, y, z = {}, {}, {}
-- keep only some items
a[1], a[2], a[3] = x, y, z
a[strrep('$', 11)] = strrep('$', 11)
-- fill a with some `collectable' values
for i=4,lim do a[i] = {} end
for i=1,lim do a[{}] = i end
for i=1,lim do local t={}; a[t]=t end
collectgarbage()
assert(next(a) ~= nil)
local i = 0
for k,v in a do
  assert((k == 1 and v == x) or
         (k == 2 and v == y) or
         (k == 3 and v == z) or k==v);
  i = i+1
end
assert(i == 4)
x,y,z=nil
collectgarbage()
assert(next(a) == strrep('$', 11))
assert(getmode(a) == 'kv'); setmode(a, ''); assert(getmode(a) == '')


-- teste de userdata
collectgarbage(2^30)   -- stop collection
local u = newproxy(true)
local s = 0
local a = setmode({[u] = 0}, 'vk')
for i=1,10 do a[newproxy(u)] = i end
for k in pairs(a) do assert(getmetatable(k) == getmetatable(u)) end
local a1 = {}; for k,v in pairs(a) do a1[k] = v end
for k,v in pairs(a1) do a[v] = k end
for i =1,10 do assert(a[i]) end
getmetatable(u).a = a1
getmetatable(u).u = u
do
  local u = u
  getmetatable(u).__gc = function (o)
    assert(a[o] == 10-s)
    assert(a[10-s] == nil) -- udata already removed from weak table
    assert(getmetatable(o) == getmetatable(u))
    assert(getmetatable(o).a[o] == 10-s)
    s=s+1
  end
end
a1, u = nil
assert(next(a) ~= nil)
collectgarbage(0)
assert(next(a) ~= nil and s==11)
collectgarbage(0)
assert(next(a) == nil)  -- finalized keys are removed in two cycles



-- erro na coleta
u = newproxy(true)
getmetatable(u).__gc = function () error "!!!" end
u = nil
assert(not pcall(collectgarbage, 0))


if not _soft then
  print("deep structures")
  local a = {}
  for i = 1,200000 do
    a = {next = a}
  end
  collectgarbage()
end



-- cria udata para ser coletado quando fechar o estado

do
  local newproxy,assert,type,print,getmetatable =
        newproxy,assert,type,print,getmetatable
  local u = newproxy(true)
  local tt = getmetatable(u)
  ___Glob = u   -- evita que udata seja coletado antes da coleta final
  tt.__gc = function (o)
    assert(getmetatable(o) == tt)
    -- cria objetos durante coleta de lixo
    local a = 'xuxu'..(10+3)..'joao', {}
    ___Glob = o  -- ressucita objeto!
    newproxy(o)  -- cria outro com mesma metatable
    print(">>> fechando estado " .. "<<<\n")
  end
end

print('OK')
