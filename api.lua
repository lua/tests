
if T==nil then
  print('\a\n >>> testC nao ativo: pulando testes da API <<<\n\a')
  return
end



function tcheck (t1, t2)
  tremove(t1, 1)  -- remove code
  assert(t1.n == t2.n)
  for i=1,t1.n do assert(t1[i] == t2[i]) end
end

function pack(...) return arg end


print('testando API com C')

-- testando alinhamento
a = T.d2s(12458954321123)
assert(strlen(a) == 8)   -- sizeof(double)
assert(T.s2d(a) == 12458954321123)

a,b,c = T.testC("pushnum 1; pushnum 2; pushnum 3; return 2")
assert(a == 2 and b == 3 and not c)

-- test that all trues are equal
a,b,c = T.testC("pushbool 1; pushbool 2; pushbool 0; return 3")
assert(a == b and a == true and c == false)
a,b,c = T.testC"pushbool 0; pushbool 10; pushnil;\
                      tobool -3; tobool -3; tobool -3; return 3"
assert(a==0 and b==1 and c==0)


a,b,c = T.testC("gettop; return 2", 10, 20, 30, 40)
assert(a == 40 and b == 5 and not c)

t = pack(T.testC("settop 5; gettop; return .", 2, 3))
tcheck(t, {n=4,2,3})

t = pack(T.testC("settop 0; settop 15; return 10", 3, 1, 23))
assert(t.n == 10 and t[1] == nil and t[10] == nil)

t = pack(T.testC("remove -2; gettop; return .", 2, 3, 4))
tcheck(t, {n=2,2,4})

t = pack(T.testC("insert -1; gettop; return .", 2, 3))
tcheck(t, {n=2,2,3})

t = pack(T.testC("insert 3; gettop; return .", 2, 3, 4, 5))
tcheck(t, {n=4,2,5,3,4})

t = pack(T.testC("replace 2; gettop; return .", 2, 3, 4, 5))
tcheck(t, {n=3,5,3,4})

t = pack(T.testC("replace -2; gettop; return .", 2, 3, 4, 5))
tcheck(t, {n=3,2,3,5})

t = pack(T.testC("remove 3; gettop; return .", 2, 3, 4, 5))
tcheck(t, {n=3,2,4,5})

t = pack(T.testC("insert 3; pushvalue 3; remove 3; pushvalue 2; remove 2; \
                  insert 2; pushvalue 1; remove 1; insert 1; \
      insert -2; pushvalue -2; remove -3; gettop; return .",
      2, 3, 4, 5, 10, 40, 90))
tcheck(t, {n=7,2,3,4,5,10,40,90})

t = pack(T.testC("concat 5; gettop; return .", "alo", 2, 3, "joao", 12))
tcheck(t, {n=1,"alo23joao12"})

-- testando MULTRET
t = pack(T.testC("rawcall 2,-1; gettop; return .",
     function (a,b) return 1,2,3,4,a,b end, "alo", "joao"))
tcheck(t, {n=6,1,2,3,4,"alo", "joao"})


-- testando lessthan
assert(T.testC("lessthan 2 5, return 1", 3, 2, 2, 4, 2, 2))
assert(T.testC("lessthan 5 2, return 1", 4, 2, 2, 3, 2, 2))
assert(not T.testC("lessthan 2 -3, return 1", "4", "2", "2", "3", "2", "2"))
assert(not T.testC("lessthan -3 2, return 1", "3", "2", "2", "4", "2", "2"))

local b = {__lt = function (a,b) return a[1] < b[1] end}
local a1,a3,a4 = setmetatable({1}, b),
                 setmetatable({3}, b),
                 setmetatable({4}, b)
assert(T.testC("lessthan 2 5, return 1", a3, 2, 2, a4, 2, 2))
assert(T.testC("lessthan 5 -6, return 1", a4, 2, 2, a3, 2, 2))
a,b = T.testC("lessthan 5 -6, return 2", a1, 2, 2, a3, 2, 20)
assert(a == 20 and b == false)


-- testando lua_is

function count (x, n)
  n = n or 2
  local prog = [[
    isnumber %d;
    isstring %d;
    isfunction %d;
    iscfunction %d;
    istable %d;
    isuserdata %d;
    isnil %d;
    isnull %d;
    return 8
  ]]
  prog = format(prog, n, n, n, n, n, n, n, n)
  local a,b,c,d,e,f,g,h = T.testC(prog, x)
  return a+b+c+d+e+f+g+h
end

assert(count(3) == 2)
assert(count('alo') == 1)
assert(count('32') == 2)
assert(count({}) == 1)
assert(count(print) == 2)
assert(count(function () end) == 1)
assert(count(nil) == 1)
assert(count(_INPUT) == 1)
assert(count(nil, 15) == 1)

-- testando lua_to...

function to (s, x, n)
  n = n or 2
  return T.testC(format("%s %d; return 1", s, n), x)
end

assert(to("tostring", {}) == nil)
assert(to("tostring", "alo") == "alo")
assert(to("tostring", 12) == "12")
assert(to("tostring", 12, 3) == nil)
assert(to("strlen", {}) == 0)
assert(to("strlen", "alo\0\0a") == 6)
assert(to("strlen", 12) == 2)
assert(to("strlen", 12, 3) == 0)
assert(to("tonumber", {}) == 0)
assert(to("tonumber", "12") == 12)
assert(to("tonumber", "s2") == 0)
assert(to("tonumber", 1, 20) == 0)
a = to("tocfunction", deg)
assert(a(3) == deg(3) and a ~= deg)


-- testando erros

a = T.testC([[
  loadstring 2; call 0,1;
  pushvalue 3; insert -2; call 1, 1;
  call 0, 0;
  return 1
]], "x=150", function (a) assert(a==nil); return 3 end)

assert(type(a) == 'string' and x == 150)

function check3(p, ...)
  assert(arg.n == 3)
  assert(strfind(arg[3], p))
end
check3(":1:", T.testC("loadstring 2; gettop; return .", "x="))
check3("cannot read", T.testC("loadfile 2; gettop; return .", "."))
check3("cannot read xxxx", T.testC("loadfile 2; gettop; return .", "xxxx"))

-- testando acesso a tabelas

a = {x=0, y=12}
x, y = T.testC("gettable 2; pushvalue 4; gettable 2; return 2",
                a, 3, "y", 4, "x")
assert(x == 0 and y == 12)
T.testC("settable -5", a, 3, 4, "x", 15)
assert(a.x == 15)
a[a] = print
x = T.testC("gettable 2; return 1", a)  -- table and key are the same object!
assert(x == print)
T.testC("settable 2", a, "x")    -- table and key are the same object!
assert(a[a] == "x")

b = setmetatable({p = a}, {})
getmetatable(b).__index = function (t, i) return t.p[i] end
k, x = T.testC("gettable 3, return 2", 4, b, 20, 35, "x")
assert(x == 15 and k == 35)
getmetatable(b).__index = function (t, i) return a[i] end
getmetatable(b).__newindex = function (t, i,v ) a[i] = v end
y = T.testC("insert 2; gettable -5; return 1", 2, 3, 4, "y", b)
assert(y == 12)
k = T.testC("settable -5, return 1", b, 3, 4, "x", 16)
assert(a.x == 16 and k == 4)
a[b] = 'xuxu'
y = T.testC("gettable 2, return 1", b)
assert(y == 'xuxu')
T.testC("settable 2", b, 19)
assert(a[b] == 19)

-- testando next
a = {}
t = pack(T.testC("next; gettop; return .", a, nil))
tcheck(t, {n=1,a})
a = {a=3}
t = pack(T.testC("next; gettop; return .", a, nil))
tcheck(t, {n=3,a,'a',3})
t = pack(T.testC("next; pop 1; next; gettop; return .", a, nil))
tcheck(t, {n=1,a})


-- testando upvalues

function X (s)
  local REGISTRYINDEX = -10000
  return (gsub(s, '$(%d+)', function (d) return REGISTRYINDEX-1-d end))
end

do
  local A = T.testC[[ pushnum 10; pushnum 20; pushcclosure 2; return 1]]
  t, b, c = A(X[[pushvalue $0; pushvalue $1; pushvalue $2; return 3]])
  assert(b == 10 and c == 20 and type(t) == 'table')
  a, b, c, d = A("pushnum 1; pushupvalues; pushnum 44; return 4")
  assert(a == 1 and b == 10 and c == 20 and d == 44)
  A(X[[pushnum 100; pushnum 200; replace $2; replace $1]])
  b, c = A(X[[pushvalue $1; pushvalue $2; return 2]])
  assert(b == 100 and c == 200)
end


-- testando locks (refs)

Arr = {}
Lim = 100
for i=1,Lim do   -- lock many objects
  Arr[i] = T.ref({})
end

for i=1,Lim do   -- unlock all them
  T.unref(Arr[i])
end

function printlocks ()
  local n = T.testC("gettable -10000; return 1", "n")
  print("n", n)
  for i=0,n do
    print(i, T.testC("gettable -10000; return 1", i))
  end
end


for i=1,Lim do   -- lock many objects
  Arr[i] = T.ref({})
end

for i=1,Lim,2 do   -- unlock half of them
  T.unref(Arr[i])
end

assert(type(T.getref(Arr[2])) == 'table')


assert(T.getref(-1) == nil)


a = T.ref({})

collectgarbage()

assert(type(T.getref(a)) == 'table')


-- colect in cl the `val' of all collected userdata
tt = {}
cl = {n=0}
A = nil; B = nil
local F
F = function (x)
  local udval = T.udataval(x)
  local d = T.newuserdata(100)   -- cria lixo
  d = nil
  assert(T.metatable(x).__gc == F)
  dostring("tinsert({}, {})")   -- cria mais lixo
  tinsert(cl, udval)
  collectgarbage()   -- forca coleta de lixo durante coleta!
  assert(T.metatable(x).__gc == F)   -- coleta anterior nao melou isso?
  local dummy = {}    -- cria lixo durante coleta
  if A ~= nil then
    assert(type(A) == "userdata")
    assert(T.udataval(A) == B)
    T.metatable(A)    -- just acess it
  end
  A = x   -- ressucita userdata
  B = udval
  return 1,2,3
end
tt.__gc = F

do
  collectgarbage();
  local x = gcinfo();
  local a = T.newuserdata(5001)
  assert(gcinfo() >= x+4) 
  a = nil
  collectgarbage();
  assert(gcinfo() <= x+1)
end


collectgarbage(10000000)

-- create 3 userdatas with tag `tt' and values 1, 2, and 3
a = T.newuserdata(1); T.metatable(a, tt); na = T.udataval(a)
b = T.newuserdata(2); T.metatable(b, tt); nb = T.udataval(b)
c = T.newuserdata(3); T.metatable(c, tt); nc = T.udataval(c)

-- create userdata without meta table
x = T.newuserdata(4)
y = T.newuserdata(0)

assert(T.metatable(x) == nil and T.metatable(y) == nil)

d=T.ref(a);
e=T.ref(b);
f=T.ref(c);
t = {T.getref(d), T.getref(e), T.getref(f)}
assert(t[1] == a and t[2] == b and t[3] == c)

t=nil; a=nil; c=nil;
T.unref(e); T.unref(f)

collectgarbage()

-- check that unref objects have been collected
assert(cl.n == 1 and cl[1] == nc)

x = T.getref(d)
assert(type(x) == 'userdata' and T.metatable(x) == tt)
x =nil
tt.b = b  -- cria ciclo
tt=nil    -- libera tt para GC
A = nil
b = nil
T.unref(d);
n5 = T.udataval(T.metatable(T.newuserdata(5), {__gc=F}))
collectgarbage()
-- check order of collection
assert(cl.n == 4 and cl[2] == n5 and cl[3] == nb and cl[4] == na)


a, na = {}, {}
for i=30,1,-1 do
  a[i] = T.metatable(T.newuserdata(i), {__gc=F})
  na[i] = T.udataval(a[i])
end
cl.n = 0
a = nil; collectgarbage()
assert(cl.n == 30)
for i=1,30 do assert(cl[i] == na[i]) end
na = nil


for i=2,Lim,2 do   -- unlock the other half
  T.unref(Arr[i])
end

x = T.newuserdata(40); T.metatable(x, {__gc=F})
cl.n = 0
a = {[x] = 1}
x = T.udataval(x)
collectgarbage()
-- old `x' cannot be collected (`a' still uses it)
assert(cl.n == 0)
for n in a do a[n] = nil end
collectgarbage()
assert(cl.n == 1 and cl[1] == x)   -- old `x' must be collected

-- testando lua_equal
assert(T.testC("equal 2 4; return 1", print, 1, print, 20))
assert(T.testC("equal 3 2; return 1", 'alo', "alo"))
assert(T.testC("equal 2 3; return 1", nil, nil))
assert(not T.testC("equal 2 3; return 1", {}, {}))
assert(not T.testC("equal 2 3; return 1"))
assert(not T.testC("equal 2 3; return 1", 3))

-- testando lua_equal com fallbacks
do
  local map = {}
  local t = {__eq = function (a,b) return map[a] == map[b] end}
  local function f(x)
    local u = T.metatable(T.newuserdata(0), t)
    map[u] = x
    return u
  end
  assert(f(10) == f(10))
  assert(f(10) ~= f(11))
  assert(T.testC("equal 2 3; return 1", f(10), f(10)))
  assert(not T.testC("equal 2 3; return 1", f(10), f(20)))
  t.__eq = nil
  assert(f(10) ~= f(10))
end

print'+'



-------------------------------------------------------------------------
do   -- teste de erro durante coleta de lixo
  local a = {}
  for i=1,20 do
    a[i] = T.newuserdata(i)   -- cria varios udata
  end
  for i=1,20,2 do   -- marca metade deles para dar erro durante coleta de lixo
    T.metatable(a[i], {__gc = function (x) error("error inside gc") end})
  end
  for i=2,20,2 do   -- marca outra metade para contar e criar mais lixo
    T.metatable(a[i], {__gc = function (x) dostring("A=A+1") end})
  end
  _G.A = 0
  a = 0
  while 1 do
  if xpcall(collectgarbage, function (s) a=a+1 end) then
    break   -- stop if no more errors
  end
  end
  assert(a == 10)  -- numero de erros
  assert(A == 10)  -- numero de coletas normais
end
-------------------------------------------------------------------------
-- teste de userdata vals
do
  local a = {}; local lim = 30
  for i=0,lim do a[i] = T.pushuserdata(i) end
  for i=0,lim do assert(T.udataval(a[i]) == i) end
  for i=0,lim do assert(T.pushuserdata(i) == a[i]) end
  for i=0,lim do a[a[i]] = i end
  for i=0,lim do a[T.pushuserdata(i)] = i end
end


-------------------------------------------------------------------------
-- testando multiplos estados
T.closestate(T.newstate(100));
L1 = T.newstate(25)
assert(L1)
assert(pack(T.doremote(L1, "function f () return 'alo', 3 end; f()")).n == 0)

a, b = T.doremote(L1, "return f()")
assert(a == 'alo' and b == '3')

T.doremote(L1, "_ERRORMESSAGE = nil")
-- error: `sin' is not defined
a, b = T.doremote(L1, "return sin(1)")
assert(a == nil and b == 1)   -- 1 == run-time error

-- error: syntax error
a, b = T.doremote(L1, "return a+")
assert(a == nil and b == 3)   -- 3 == syntax error

T.loadlib(L1)
a = T.doremote(L1, "strlibopen(); return string.sub('xuxu', 1, 2)")
assert(a == "xu")

T.closestate(L1);

L1 = nil

print('+')

-------------------------------------------------------------------------
-- testa limites de memoria
-------------------------------------------------------------------------
collectgarbage()
T.totalmem(T.totalmem()+5000)   -- seta limite `baixo' para memoria (+5k)
assert(not pcall(loadstring"local a={}; for i=1,100000 do a[i]=i end"))
T.totalmem(32000000)  -- restaura limite alto (32M)


-- testa erros de memoria; vai aumentando o limite de memoria
-- gradativamente, de modo a dar erros em varios passos durante
-- determinada atividade, ate' ter memoria suficiente para nao dar erro
function testamem (s, f)
  collectgarbage()
  local M = T.totalmem()
  local oldM = M
  local a,b = nil
  while 1 do
    M = M+3   -- aumenta gradativamente a memoria
    T.totalmem(M)
    a, b = pcall(f)
    if a and b then break end       -- para quando conseguir
    collectgarbage()
  end
  T.totalmem(32000000)  -- restaura limite alto (32M)
  print("\nlimite para " .. s .. ": " .. M-oldM)
  return b
end


-- testa erros de memoria na criacao de um estado

b = testamem("criar estado", T.newstate)
T.closestate(b);  -- fecha estado que conseguiu abrir


-- teste de threads

function expand (n,s)
  if n==0 then return ""
  else return format("T.doonnewstack([[ %s;\n collectgarbage(); %s]])\n",
                                      s, expand(n-1,s))
  end
end

G=0; collectgarbage(); a =gcinfo()
dostring(expand(20,"G=G+1"))
assert(G==20); collectgarbage();  -- assert(gcinfo() <= a+1)

testamem("criar thread", function ()
  return T.doonnewstack("x=1") == 0  -- tenta criar thread
end)


-- teste de memoria x compilador

testamem("dostring", function ()
  return loadstring("x=1")  -- tenta fazer o dostring
end)


-- testes mais genericos

testamem("teste criacao de strings", function ()
  local a, b = gsub("alo alo", "(a)", function (x) return x..'b' end)
  return (a == 'ablo ablo')
end)

testamem("teste criacao de arquivos", function ()
  local t = tmpname()
  local f = assert(io.open(t, 'w'))
  assert (not io.open"nomenaoexistente")
  io.close(f); os.remove(t)
  return not loadfile'nomenaoexistente'
end)

testamem("teste criacao de tabelas", function ()
  local a, lim = {}, 10
  for i=1,lim do a[i] = i; a[i..'a'] = {} end
  return (type(a[lim..'a']) == 'table' and a[lim] == lim)
end)

testamem("teste criacao de closures", function ()
  function close (a,b,c)
   return function (x) return a+b+c+x end
  end
  return (close(1,2,3)(4) == 10)
end)

print'OK'

