
if T==nil then
  print('\a\n >>> testC nao ativo: pulando testes da API <<<\n\a')
  return
end

function pack(...) return arg end
function tcheck (t1, t2)
  tremove(t1, 1)  -- remove code
  assert(t1.n == t2.n)
  for i=1,t1.n do assert(t1[i] == t2[i]) end
end


print('testando API com C')

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


-- testando lua_is

function count (x, n)
  n = n or 2
  local prog = [[
    isnumber %1$d;
    isstring %1$d;
    isfunction %1$d;
    iscfunction %1$d;
    istable %1$d;
    isuserdata %1$d;
    isnil %1$d;
    isnull %1$d;
    return 8
  ]]
  prog = format(prog, n)
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


-- testando tabelas
a = {x=0, y=12}
x, y = T.testC("gettable 2; pushvalue 4; gettable 2; return 2",
                a, 3, "y", 4, "x")
assert(x == 0 and y == 12)
T.testC("settable -5", a, 3, 4, "x", 15)
assert(a.x == 15)

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

-- testando next
a = {}
t = pack(T.testC("next; gettop; return .", a, nil))
tcheck(t, {n=1;a})
a = {a=3}
t = pack(T.testC("next; gettop; return .", a, nil))
tcheck(t, {n=3;a,'a',3})
t = pack(T.testC("next; pop 1; next; gettop; return .", a, nil))
tcheck(t, {n=1;a})

-- teste de muitos locks
Arr = {}
Lim = 100
for i=1,Lim do   -- lock many objects
  Arr[i] = T.ref({}, 1)
end


for i=1,Lim,2 do   -- unlock half of them
  T.unref(Arr[i])
end

assert(T.getref(-1) == nil)
assert(type(T.getref(0)) == 'table')  -- API table
assert(T.ref(nil, 1) == -1)      -- (-1 == LUA_REFNIL)
assert(T.ref(nil, 0) == -1)      -- (-1 == LUA_REFNIL)


a = T.ref({}, 1)

collectgarbage()

assert(type(T.getref(a)) == 'table')


-- colect in cl the `val' of all collected tables
tt = newtag()
cl = {n=0}
function f(x)
  local udval = T.udataval(x)
  cl.n = cl.n+1
  cl[udval] = 1
end
T.settagmethod(tt, 'gc', f)

do
  collectgarbage();
  local x = gcinfo();
  local a = T.newuserdata(5000)
  assert(gcinfo() >= x+5) 
  assert(T.newuserdata(T.udataval(a), 0) == a)
  assert(T.newuserdata(T.udataval(a), -1) == a)
  a = nil
  collectgarbage();
  assert(gcinfo() <= x+1)
end


collectgarbage(10000000)

-- create 3 userdatas with tag `tt' and values 1, 2, and 3
a = T.newuserdata(1, tt)
b = T.newuserdata(2, tt)
c = T.newuserdata(3, tt)

-- create a userdata with tag 0
x = T.newuserdata(4, 0)

assert(tag(x) == 0)

do   -- test ANYTAG (-1)
  local d = T.newuserdata(1, -1)
  assert(tag(d) == tt and d == a)
end

d=T.ref(a, 1);
e=T.ref(b, 0);
f=T.ref(c, 0);
t = {T.getref(d), T.getref(e), T.getref(f)}
assert(t[1] == a and t[2] == b and t[3] == c)

t=nil; a=nil; c=nil;

collectgarbage()

x = T.getref(d)
assert(type(x) == 'userdata' and tag(x) == tt)
-- atempt to get "collected object"; must give an error
assert(T.getref(f) == nil)
x=nil

-- check that unreferenced unlocked objects have been collected
assert(cl.n == 1 and not cl[2] and cl[3] and not cl[1])
assert(T.getref(e) == b)
b = nil

-- check that unref objects have been collected
T.unref(d); T.unref(e); T.unref(f)
collectgarbage()
assert(cl.n == 3 and cl[1])

for i=2,Lim,2 do   -- unlock the other half
  T.unref(Arr[i])
end

-- create a userdata with tag `tt' and value 40
x = T.newuserdata(40, tt)
cl.n = 0; cl[40] = nil;
a = {[x] = 1}
x = nil
collectgarbage()
-- old `x' cannot be collected (`a' still uses it)
assert(cl.n == 0 and not cl[40])
for n,_ in a do a[n] = nil end
collectgarbage()
assert(cl.n == 1 and cl[40] == 1)   -- old `x' must be collected


assert(T.equal(print, print))
assert(T.equal('alo', "alo"))
assert(not T.equal({}, {}))
assert(not T.equal())
assert(not T.equal(3))

print'+'


-- testando multiplos estados
T.closestate(T.newstate(100));
L1 = T.newstate(15)
assert(type(L1) == 'userdata')
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

T.closestate(L1);

T.settagmethod(tt, 'gc', nil)


-- testa limite de memoria
collectgarbage()
T.totalmem(T.totalmem()+5000)   -- seta limite `baixo' para memoria (+5k)
assert(dostring"local a={}; for i=1,100000 do a[i]=i end" == nil)
T.totalmem(32000000)  -- restaura limite alto (32M)

-- testa erros de memoria na criacao de um estado; vai aumentando o limite
-- de memoria gradativamente, de modo a dar erros em varios passos durante
-- a criacao de um estado, ate' ter memoria suficiente para nao dar erro

local args = {0}
local M = T.totalmem()
local oldM = M
local a = nil
while 1 do
  M = M+81   -- aumenta gradativamente a memoria
  T.totalmem(M)
  a = call(T.newstate, args, "x")  -- tenta criar estado
  if a ~= nil then break end       -- para quando conseguir
end
T.closestate(a);  -- fecha estado que conseguiu abrir
T.totalmem(32000000)  -- restaura limite alto (32M)
print("limite para criar estado: "..M-oldM)


print'OK'

