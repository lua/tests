print"testando biblioteca de depuração"

$debug

a = {}
setcallhook(function (f) if f then a[f] = 1 end end)

glob = 1
oldglob = glob
setlinehook(function (l)
  if not L and glob ~= oldglob then
    L = l-1   -- get the first line where "glob" has changed
  end
end)

function f(a,b)
  collectgarbage()
  local x = getlocal(1)
  assert(x.a == a and x.b == b)
  assert(getlocal(1,"x") == x and getlocal(1, 2) == b)
  assert(getlocal(2, "AA".."AA") == a and getlocal(2).B == b)
  setlocal(2, 1, "pera"); setlocal(2, "B", "maçã")
  x = getstack(2)
  assert(x.func == g and x.kind == "Lua" and
         strfind(x.source, "^@.*db%.lua"))
  glob = glob+1
  assert(getstack(1).current == L+1)
  assert(getstack(1).current == L+2)
end

setglobal("AA".."AA", nil)   -- make sure AAAA can be collected
function g()
  local AAAA,B = "xuxu", "mamão"
  f(AAAA,B)
  assert(AAAA == "pera" and B == "maçã")
end

g()

assert(funcinfo(g).name == "g")
assert(funcinfo(print).kind == "C")

assert(a[f] and a[g] and a[assert] and a[getlocal] and not a[print])
 

setcallhook(); setlinehook()

prog = [[
function f(x)
  return x
end
]]

dostring(prog);
assert(funcinfo(f).source == prog)

print'OK'


-- ..\lua\debug\lua db.lua
