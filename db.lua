-- testes da biblioteca de depuracao



print"testando biblioteca de depuração e informacoes de debug"

do
local a=1
end

function test (s, l, p)
  collectgarbage()   -- avoid gc during trace
  local function f (event, line)
    assert(event == 'line')
    local l = table.remove(%l, 1)
    if p then print(l, line) end
    assert(l == line, "wrong trace!!")
  end
  debug.sethook(f,"l"); loadstring(s)(); debug.sethook()
  assert(table.getn(l) == 0)
end


do
  local a = getinfo(print)
  assert(a.name == "print" and a.what == "C" and a.namewhat == "global"
         and a.short_src == "[C]")
  local b = getinfo(test, "Sf")
  assert(b.name == nil and b.what == "Lua" and b.linedefined == 11 and
         b.func == test and not strfind(b.short_src, "%["))
end


-- testa truncagem de nomes de arquivos e strings
a = "function f () end"
local function dostring (s, x) return loadstring(s, x)() end
dostring(a)
assert(getinfo(f).short_src == format('[string "%s"]', a))
dostring(a..format("; %s\n=1", strrep('p', 400)))
assert(strfind(getinfo(f).short_src, '^%[string [^\n]*%.%.%."%]$'))
dostring("\n"..a)
assert(getinfo(f).short_src == '[string "..."]')
dostring(a, "")
assert(getinfo(f).short_src == '[string ""]')
dostring(a, "@xuxu")
assert(getinfo(f).short_src == "xuxu")
dostring(a, "@"..strrep('p', 1000)..'t')
assert(strfind(getinfo(f).short_src, "^%.%.%.p*t$"))
dostring(a, "=xuxu")
assert(getinfo(f).short_src == "xuxu")
dostring(a, format("=%s", strrep('x', 500)))
assert(strfind(getinfo(f).short_src, "^x*"))
dostring(a, "=")
assert(getinfo(f).short_src == "")
a = nil; f = nil;


repeat
  local g = {x = function ()
    local a = getinfo(2)
    assert(a.name == 'f' and a.namewhat == 'local')
    a = getinfo(1)
    assert(a.name == 'x' and a.namewhat == 'field')
    return 'xixi'
  end}
  local f = function () return 1+1 and (not 1 or %g.x()) end
  assert(f() == 'xixi')
  g = getinfo(f)
  assert(g.what == "Lua" and g.func == f and g.namewhat == "" and not g.name)

  function f (x, name)   -- local!
    name = name or 'f'
    local a = getinfo(1)
    assert(a.name == name and a.namewhat == 'local')
    return x
  end

  -- breaks in different conditions
  if 3>4 then break end; f()
  if 3<4 then a=1 else break end; f()
  while 1 do local x=10; break end; f()
  local b = 1
  if 3>4 then return sin(1) end; f()
  a = 3<4; f()
  a = 3<4 or 1; f()
  repeat local x=20; if 4>3 then f() else break end; f() until 1
  g = {}
  f(g).x = f(2) and f(10)+f(9)
  assert(g.x == f(19))
  function g(x) if not x then return 3 end return (x('a', 'x')) end
  assert(g(f) == 'a')
until 1

test([[if
sin(1)
then
  a=1
else
  a=2
end
]], {2,4,7})

test([[--
if nil then
  a=1
else
  a=2
end
]], {2,5,6})

test([[a=1
repeat
  a=a+1
until a==3
]], {1,3,4,3,4})

test([[ do
  return
end
]], {2})

test([[local a
a=1
while a<=3 do
  a=a+1
end
]], {1,2,3,4,3,4,3,4,3,5})

test([[while sin(1) do
  if sin(1)
  then
    break
  end
end
a=1]], {1,2,4,7})

test([[for i=1,3 do
  a=i
end
]], {1,2,1,2,1,2,1,3})

test([[for i,v in {'a','b'} do
  a=i..v
end
]], {1,2,1,2,1,3})

test([[for i=1,4 do a=1 end]], {1,1,1,1,1})



print'+'

a = {}
local glob = 1
local oldglob = glob
debug.sethook(function (e,l)
  collectgarbage()   -- force GC during a hook
  local f, m, c = debug.gethook()
  assert(m == 'crl' and c == 0)
  if e == "line" then
    if glob ~= oldglob then
      L = l-1   -- get the first line where "glob" has changed
      oldglob = glob
    end
  elseif e == "call" then
      local f = getinfo(2, "f").func
      a[f] = 1
  else assert(e == "return")
  end
end, "crl")

function f(a,b)
  collectgarbage()
  local _, x = getlocal(1, 1)
  local _, y = getlocal(1, 2)
  assert(x == a and y == b)
  assert(setlocal(2, 3, "pera") == "AA".."AA")
  assert(setlocal(2, 4, "maçã") == "B")
  x = getinfo(2)
  assert(x.func == g and x.what == "Lua" and x.name == 'g' and
         x.nups == 0 and strfind(x.source, "^@.*db%.lua"))
  glob = glob+1
  assert(getinfo(1, "l").currentline == L+1)
  assert(getinfo(1, "l").currentline == L+2)
end

function foo()
  glob = glob+1
  assert(getinfo(1, "l").currentline == L+1)
end; foo()  -- set L
-- check line counting inside strings and empty lines

_ = 'alo\
alo' .. [[

]]
--[[
]]
assert(getinfo(1, "l").currentline == L+11)  -- check count of lines


function g(...)
  do local a,b,c; a=sin(40); end
  local feijao
  local AAAA,B = "xuxu", "mamão"
  f(AAAA,B)
  assert(AAAA == "pera" and B == "maçã")
  do
     local B = 13
     local x,y = getlocal(1,5)
     assert(x == 'B' and y == 13)
  end
end

g()


assert(a[f] and a[g] and a[assert] and a[getlocal] and not a[print])
 

debug.sethook(nil);
assert(debug.gethook() == nil)


-- testando pegar argumentos de funcao (locais existentes no inicio da funcao)

X = nil
a = {}
function a:f (a, b, ...) local c = 13 end
debug.sethook(function (e)
  assert(e == "call")
  dostring("XX = 12")  -- testa dostring dentro de hooks
  -- testa erros dentro de hook (chamando _ERRORMESSAGE)
  assert(not pcall(loadstring("a='joao'+1")))
  debug.sethook(function (e, l) 
    local f,m,c = debug.gethook()
    assert(e == "line")
    assert(m == 'l' and c == 0)
    debug.sethook(nil)  -- hook e' chamado uma unica vez
    assert(not X)  -- verifica fato acima
    X = {}; local i = 1
    local x,y
    while 1 do
      x,y = getlocal(2, i)
      if x==nil then break end
      X[x] = y
      i = i+1
    end
  end, "l")
end, "c")

a:f(1,2,3,4,5)
assert(X.self == a and X.a == 1   and X.b == 2 and X.arg.n == 3 and X.c == nil)
assert(XX == 12)
assert(debug.gethook() == nil)


-- testando count hooks
local a=0
debug.sethook(function (e) a=a+1 end, "", 1)
a=0; for i=1,1000 do end; assert(1000 < a and a < 1010)
debug.sethook(function (e) a=a+1 end, "", 2)
a=0; for i=1,1000 do end; assert(250 < a and a < 255)
local f,m,c = debug.gethook()
assert(m == "" and c == 2)
debug.sethook()

print'OK'

