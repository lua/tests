#!../lua

require "compat"

math.randomseed(0)

--[[
  example of a long [comment],
  [[spanning several [lines]]]

]]

local c = os.clock()

_WD = wd or ""

assert(setlocale"C")

local T,print,gcinfo,format,write,assert,type =
      T,print,gcinfo,string.format,io.write,assert,type

local showmem = function ()
  if not T then
    print(format("    ---- memoria total: %dK ----\n", gcinfo()))
  else
    local a,b,c = T.totalmem()
    local d,e = gcinfo()
    print(format(
  "\n    ---- memoria total: %dK (%dK), maxima: %d,  blocos: %d\n",
                        a/1024,  d,      c/1024,           b))
  end
end


--
-- redefine dofile to run files through dump/undump
--
dofile = function (n)
  showmem()
  local f = assert(loadfile(n))
  local b = string.dump(f)
  f = assert(loadstring(b))
  return f()
end

dofile(_WD..'main.lua')

do
  local u = newproxy(true)
  local newproxy, stderr = newproxy, io.stderr
  getmetatable(u).__gc = function (o)
    stderr:write'.'
    newproxy(o)
  end
end

local f = assert(loadfile(_WD..'gc.lua'))
f()
dofile(_WD..'db.lua')
assert(dofile(_WD..'calls.lua') == deep and deep)
dofile(_WD..'strings.lua')
dofile(_WD..'literals.lua')
assert(dofile(_WD..'attrib.lua') == 27)
assert(dofile(_WD..'locals.lua') == 5)
dofile(_WD..'constructs.lua')
dofile(_WD..'code.lua')
do
  local f = coroutine.wrap(assert(loadfile(_WD..'big.lua')))
  assert(f() == 'b')
  assert(f() == 'a')
end
dofile(_WD..'nextvar.lua')
dofile(_WD..'pm.lua')
dofile(_WD..'api.lua')
assert(dofile(_WD..'events.lua') == 12)
dofile(_WD..'vararg.lua')
dofile(_WD..'closure.lua')
dofile(_WD..'errors.lua')
dofile(_WD..'math.lua')
dofile(_WD..'sort.lua')
assert(dofile(_WD..'verybig.lua') == 10); collectgarbage()
dofile(_WD..'files.lua')
print("final OK !!!")


print('limpando tudo!!!!')

debug.sethook(function (a) assert(type(a) == 'string') end, "cr")

local _G, collectgarbage, showmem, print, format, clock =
      _G, collectgarbage, showmem, print, format, os.clock

local a={}
for n in pairs(_G) do a[n] = 1 end
a.tostring = nil
a.___Glob = nil
for n in pairs(a) do _G[n] = nil end

a = nil
collectgarbage()
collectgarbage()
collectgarbage()
collectgarbage()
collectgarbage()
collectgarbage();showmem()

print(format("\n\ntempo total: %.2f\n", clock()-c))
