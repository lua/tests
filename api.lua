
if T==nil then
  print('\a\n >>> testC nao ativo: pulando testes da API <<<\n\a')
  return
end

-- modulo de compatibilidade com pushuserdata antigo
ANYTAG = -1

local old_newuserdata = T.newuserdata

do

local L = {}
L.tab = weakmode({}, 'v')
L.newuserdata = T.newuserdata

function L.insert (res)
  %L.tab[T.udataval(res)..'|'..tag(res)] = res
  %L.tab[T.udataval(res)..'|'..ANYTAG] = res
end

T.pushuserdata = function (s, t)
  local key = s .. '|' .. t
  if %L.tab[key] then return %L.tab[key] end
  if t == ANYTAG then t = 0 end
  local res = T.newuserdatabox(s)
  T.settag(res, t)
  %L.insert(res)
  return res, 1
end

T.newuserdata = function (s)
  local res = %L.newuserdata(s)
  %L.insert(res)
  return res
end

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

a,b,c = T.testC("gettop; return 2", 10, 20, 30, 40)
assert(a == 40 and b == 5 and not c)

t = pack(T.testC("settop 5; gettop; return .", 2, 3))
tcheck(t, {n=4;2,3})

t = pack(T.testC("settop 0; settop 15; return 10", 3, 1, 23))
assert(t.n == 10 and t[1] == nil and t[10] == nil)

t = pack(T.testC("remove -2; gettop; return .", 2, 3, 4))
tcheck(t, {n=2;2,4})

t = pack(T.testC("insert -1; gettop; return .", 2, 3))
tcheck(t, {n=2;2,3})

t = pack(T.testC("insert 3; gettop; return .", 2, 3, 4, 5))
tcheck(t, {n=4;2,5,3,4})

t = pack(T.testC("remove 3; gettop; return .", 2, 3, 4, 5))
tcheck(t, {n=3;2,4,5})

t = pack(T.testC("insert 3; pushvalue 3; remove 3; pushvalue 2; remove 2; \
                  insert 2; pushvalue 1; remove 1; insert 1; \
      insert -2; pushvalue -2; remove -3; gettop; return .",
      2, 3, 4, 5, 10, 40, 90))
tcheck(t, {n=7;2,3,4,5,10,40,90})

t = pack(T.testC("concat 5; gettop; return .", "alo", 2, 3, "joao", 12))
tcheck(t, {n=1;"alo23joao12"})

-- testando MULTRET
t = pack(T.testC("rawcall 2,-1; gettop; return .",
     function (a,b) return 1,2,3,4,a,b end, "alo", "joao"))
tcheck(t, {n=6;1,2,3,4,"alo", "joao"})


-- testando lessthan
assert(T.testC("lessthan 2 5, return 1", 3, 2, 2, 4, 2, 2))
assert(T.testC("lessthan 5 2, return 1", 4, 2, 2, 3, 2, 2))
assert(not T.testC("lessthan 2 -3, return 1", "4", "2", "2", "3", "2", "2"))
assert(not T.testC("lessthan -3 2, return 1", "3", "2", "2", "4", "2", "2"))

settagmethod("table", "lt", function (a,b) return a[1] < b[1] end)
assert(T.testC("lessthan 2 5, return 1", {3}, 2, 2, {4}, 2, 2))
assert(T.testC("lessthan 5 -6, return 1", {4}, 2, 2, {3}, 2, 2))
a,b = T.testC("lessthan 5 -6, return 2", {1}, 2, 2, {3}, 2, 20)
assert(a == 20 and b == nil)

settagmethod("table", "lt", nil)


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
a = to("tocfunction", sin)
assert(a(3) == sin(3) and a ~= sin)


-- testando erros
local olderr = _ERRORMESSAGE
_ERRORMESSAGE = nil

a,b = T.testC("call 2,3; pushvalue 2; insert -2; call 1,1; dostring 4; \
               dostring 1; dostring 5; return 2",
               sin, 1, "x=150", "x='a'+1", 1, 2, 3, 4, 5)
_ERRORMESSAGE = olderr
assert(a == 1 and b == sin(2) and x == 150)


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

b = settag({p = a}, newtag())
settagmethod(tag(b), "index", function (t, i) return t.p[i] end)
k, x = T.testC("gettable 3, return 2", 4, b, 20, 35, "x")
assert(x == 15 and k == 35)
settagmethod(tag(b), "gettable", function (t, i) return a[i] end)
settagmethod(tag(b), "settable", function (t, i,v ) a[i] = v end)
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
tcheck(t, {n=1;a})
a = {a=3}
t = pack(T.testC("next; gettop; return .", a, nil))
tcheck(t, {n=3;a,'a',3})
t = pack(T.testC("next; pop 1; next; gettop; return .", a, nil))
tcheck(t, {n=1;a})


-- testando upvalues

function X (s)
  local REGISTRYINDEX = -10000
  return (gsub(s, '$(%d+)', function (d) return REGISTRYINDEX-1-d end))
end

a = T.testC[[ pushnum 10; pushnum 20; pushcclosure 2; return 1]]
t, b, c = a(X[[pushvalue $0; pushvalue $1; pushvalue $2; return 3]])
assert(b == 10 and c == 20 and type(t) == 'table')
a, b, c, d = a("pushnum 1; pushupvalues; pushnum 44; return 4")
assert(a == 1 and b == 10 and c == 20 and d == 44)


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


-- colect in cl the `val' of all collected tables
tt = T.newtag("NewTag", 0)
cl = {n=0}
function f(x)
  local udval = T.udataval(x)
  local d = T.newuserdata(100)   -- cria lixo
  d = nil
  dostring("tinsert({}, {})")   -- cria mais lixo
  collectgarbage()   -- forca coleta de lixo durante coleta!
  cl.n = cl.n+1
  cl[udval] = 1
  udval = {}    -- cria lixo durante coleta
  A = x   -- ressucita userdata
  return 1,2,3
end
T.settagmethod(tt, 'gc', f)

do
  collectgarbage();
  local x = gcinfo();
  local a = T.newuserdata(5000)
  assert(gcinfo() >= x+4) 
  assert(T.pushuserdata(T.udataval(a), 0) == a)
  assert(T.pushuserdata(T.udataval(a), ANYTAG) == a)
  a = nil
  collectgarbage();
  assert(gcinfo() <= x+1)
end


collectgarbage(10000000)

-- create 3 userdatas with tag `tt' and values 1, 2, and 3
a = T.pushuserdata(1, tt)
b = T.pushuserdata(2, tt)
c = T.pushuserdata(3, tt)

-- create userdata with tag 0
x = T.pushuserdata(4, 0)
y = T.pushuserdata(0, 0)

assert(tag(x) == 0 and T.udataval(x) == 4)
assert(tag(y) == 0 and T.udataval(y) == 0)  -- check udata NULL

do
  local d, new = T.pushuserdata(1, ANYTAG)
  assert(tag(d) == tt and d == a and not new)
  local t = T.newtag()
  d, new = T.pushuserdata(1, t)
  assert(tag(d) == t and new)
  d, new = T.pushuserdata(1, tt)
  assert(d == a and tag(a) == tt and not new)
  d, new = T.pushuserdata(20, 0)
  assert(tag(d) == 0 and new)
  d, new = T.pushuserdata(21, t)
  assert(tag(d) == t and new)
  d, new = T.pushuserdata(22, ANYTAG)
  assert(tag(d) == 0 and new)
end

d=T.ref(a);
e=T.ref(b);
f=T.ref(c);
t = {T.getref(d), T.getref(e), T.getref(f)}
assert(t[1] == a and t[2] == b and t[3] == c)

t=nil; a=nil; c=nil;
T.unref(e); T.unref(f)

collectgarbage()

x = T.getref(d)
assert(rawtype(x) == 'userdata' and tag(x) == tt)
x=nil

-- check that unref objects have been collected
assert(cl.n == 1 and not cl[2] and cl[3] and not cl[1])
b = nil

T.unref(d);
collectgarbage()
assert(cl.n == 3 and cl[1])

for i=2,Lim,2 do   -- unlock the other half
  T.unref(Arr[i])
end

-- create a userdata with tag `tt' and value 40
x = T.pushuserdata(40, tt)
cl.n = 0; cl[40] = nil;
a = {[x] = 1}
x = nil
collectgarbage()
-- old `x' cannot be collected (`a' still uses it)
assert(cl.n == 0 and not cl[40])
for n,_ in a do a[n] = nil end
collectgarbage()
assert(cl.n == 1 and cl[40] == 1)   -- old `x' must be collected

-- testando lua_equal
assert(T.testC("equal 2 4; return 1", print, 1, print, 20))
assert(T.testC("equal 3 2; return 1", 'alo', "alo"))
assert(not T.testC("equal 2 3; return 1", {}, {}))
assert(not T.testC("equal 2 3; return 1"))
assert(not T.testC("equal 2 3; return 1", 3))

print'+'


-- cria udata para ser coletado quando fechar o estado
do
  local assert,type,print = assert,type,print
  local tt = T.newtag("Final", 0)
  local u = T.newuserdata(10)
  T.settag(u, tt)
  local settag = T.settag
  T.settagmethod(tt, "gc", function (o)
    %assert(%type(o) == "Final")
    -- cria objetos durante coleta de lixo
    local a = 'xuxu'..(10+3)..'joao', {}
    %assert(o == %u)  -- upvalue evita que u seja coletado antes do close
    A = o  -- ressucita objeto!
    %print(">>> fechando estado " .. "<<<\n")
  end)

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
a = T.doremote(L1, "strlibopen(); return strsub('xuxu', 1, 2)")
assert(a == "xu")

T.closestate(L1);

T.settagmethod(tt, 'gc', nil)

L1 = nil

print('+')
-------------------------------------------------------------------------
-- testa limite de memoria
-------------------------------------------------------------------------
collectgarbage()
T.totalmem(T.totalmem()+5000)   -- seta limite `baixo' para memoria (+5k)
assert(dostring"local a={}; for i=1,100000 do a[i]=i end" == nil)
T.totalmem(32000000)  -- restaura limite alto (32M)

-- testa erros de memoria na criacao de um estado; vai aumentando o limite
-- de memoria gradativamente, de modo a dar erros em varios passos durante
-- a criacao de um estado, ate' ter memoria suficiente para nao dar erro

local args = {0;n=1}
local M = T.totalmem()
local oldM = M
local a = nil
while 1 do
  M = M+3   -- aumenta gradativamente a memoria
  T.totalmem(M)
  a = call(T.newstate, args, "x")  -- tenta criar estado
  if a ~= nil then break end       -- para quando conseguir
end
T.closestate(a);  -- fecha estado que conseguiu abrir
T.totalmem(32000000)  -- restaura limite alto (32M)
print("\nlimite para criar estado: "..M-oldM)


-------------------------------------------------------------------------
-- teste de threads
-------------------------------------------------------------------------

function expand (n,x,s)
  if n==0 then return ""
  else return format("T.doonnewstack(%d, [[ %s;\n collectgarbage(); %s]])\n",
                                      x, s, expand(n-1,x,s))
  end
end

G=0; collectgarbage(); a =gcinfo()
dostring(expand(20,100,"G=G+1"))
assert(G==20); collectgarbage(); assert(gcinfo() <= a+1)


args = {10, "";n=2}
M = T.totalmem()
oldM = M
a = nil
while 1 do
  M = M+3   -- aumenta gradativamente a memoria
  T.totalmem(M)
  a = call(T.doonnewstack, args, "x")  -- tenta criar pilha
  if a ~= nil then break end       -- para quando conseguir
end
T.totalmem(32000000)  -- restaura limite alto (32M)
print("\nlimite para criar pilha: "..M-oldM)


-------------------------------------------------------------------------
-- teste de memoria x compilador
-------------------------------------------------------------------------

collectgarbage()
args = {"x=1";n=1}
x=nil
M = T.totalmem()
oldM = M
a = nil
while 1 do
  M = M+3   -- aumenta gradativamente a memoria
  T.totalmem(M)
  a = call(dostring, args, "x")  -- tenta fazer o dostring
  if a ~= nil then break end       -- para quando conseguir
end
T.totalmem(32000000)  -- restaura limite alto (32M)
assert(x)
print("\nlimite para dostring: "..M-oldM)

print'OK'

