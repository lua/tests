print"testando biblioteca de depuração"

$debug

function test (s, l)
  local f = function (line)
    if tremove(%l, 1) ~= line then print("wrong trace!!"); exit(1) end
  end
  setlinehook(f); dostring(s); setlinehook()
  assert(l.n == 0)
end

test([[if
1
then
  a=1
else
  a=2
end
]], {1,2,3,4,7})

test([[
if nil then
  a=1
else
  a=2
end
]], {2,4,5,6})

test([[a=1
repeat
  a=a

+1
until a==3
]], {1,2,3,5,6,2,3,5,6})

test([[ do
  return
end
]], {1,2})

test([[local a
a=1
while a<=3 do
  a=a+1
end
]], {1,2,3,4,3,4,3,4,3,5})

test([[while 1 do
  if 1
  then
    break
  end
end
a=1]], {1,2,3,4,7})



print'+'

a = {}
setcallhook(function (e)
  collectgarbage()   -- force GC during a hook
  if e == "call" then
    local f = getstack(2, "f").func
    a[f] = 1
  end 
end)

glob = 1
oldglob = glob
setlinehook(function (l)
  if glob ~= oldglob then
    L = l-1   -- get the first line where "glob" has changed
    oldglob = glob
  end
end)

function f(a,b)
  collectgarbage()
  local _, x = getlocal(1, 1)
  local _, y = getlocal(1, 2)
  assert(x == a and y == b)
  assert(setlocal(2, 1, "pera") == "AA".."AA")
  assert(setlocal(2, 2, "maçã") == "B")
  x = getstack(2)
  assert(x.func == g and x.what == "Lua" and x.name == 'g' and
         x.nups == 0 and strfind(x.source, "^@.*db%.lua"))
  glob = glob+1
  assert(getstack(1, "l").currentline == L+1)
  assert(getstack(1, "l").currentline == L+2)
end

glob = glob+1
assert(getstack(1, "l").currentline == L+1)


assert(getstack(1, "l").currentline == L+4)  -- check count of empty lines


function g()
  local AAAA,B = "xuxu", "mamão"
  f(AAAA,B)
  assert(AAAA == "pera" and B == "maçã")
  do
     local B = 13
     local x,y = getlocal(1,3)
     assert(x == 'B' and y == 13)
  end
end

g()


assert(a[f] and a[g] and a[assert] and a[getlocal] and not a[print])
 

setcallhook(); setlinehook()


-- testando pegar argumentos de funcao (locais existentes no inicio da funcao)

X = nil
a = {}
function a:f (a, b, ...) local c = 13 end
setcallhook(function ()
  setcallhook()  -- hook e' chamado uma unica vez
  setlinehook(function (l) 
    setlinehook()  -- hook e' chamado uma unica vez
    assert(not X)  -- verifica fato acima
    X = {}; local i = 1
    local x,y
    while 1 do
      x,y = getlocal(2, i)
      if x==nil then break end
      X[x] = y
      i = i+1
    end
  end)
end)

a:f(1,2,3,4,5)
assert(X.self == a and X.a == 1   and X.b == 2 and X.arg.n == 3 and X.c == nil)
print'OK'


-- ..\lua\debug\lua db.lua
