#!../lua

require "compat"

global in nil

global io, os, str, co, _G, dbg

global wd, _WD

global print, gcinfo, assert, type, dofile, loadfile, _STDERR,
       collectgarbage, error, showmem, globals

global write in io

global format in str

global setlocale, clock in os

global T


--[[
  example of a long [comment],
  [[spanning several [lines]]]

]]

local c = clock()

_WD = wd or ""

assert(setlocale"C")

local T,print,gcinfo,format,write,assert,type =
      T,print,gcinfo,format,write,assert,type

local showmem = function ()
  if not %T then
    %print(%format("    ---- memoria total: %dK ----\n", %gcinfo()))
  else
    local a,b,c = %T.totalmem()
    local d,e = %gcinfo()
    %print(%format(
  "\n    ---- memoria total: %dK (%dK), maxima: %d,  blocos: %d\n",
                        a/1024,  d,      c/1024,           b))
  end
end

assert(dofile(_WD..'main.lua'))

if type(T) == 'table' and false then   -- debug facilities available?
  local mt = {}
  local new = function ()
    local u = T.newuserdata(0)
    T.metatable(u, mt)
  end
  mt.gc = function ()
    write(_STDERR, '.')
    new()
  end
  new()
end

local f = assert(loadfile(_WD..'gc.lua'))
f()
showmem()
assert(dofile(_WD..'db.lua'))
showmem()
global deep; assert(dofile(_WD..'calls.lua') == deep and deep)
showmem()
assert(dofile(_WD..'strings.lua'))
showmem()
assert(dofile(_WD..'literals.lua'))
showmem()
assert(dofile(_WD..'attrib.lua') == 27)
showmem()
assert(dofile(_WD..'locals.lua') == 5)
assert(dofile(_WD..'constructs.lua'))
assert(dofile(_WD..'code.lua'))
do
  local f = co.create(assert(loadfile(_WD..'big.lua')))
  assert(f() == 'b')
  assert(f() == 'a')
end
showmem()
assert(dofile(_WD..'nextvar.lua'))
showmem()
assert(dofile(_WD..'pm.lua'))
showmem()
assert(dofile(_WD..'api.lua'))
showmem()
assert(dofile(_WD..'events.lua') == 12)
showmem()
assert(dofile(_WD..'vararg.lua'))
showmem()
assert(dofile(_WD..'closure.lua'))
showmem()
assert(dofile(_WD..'errors.lua'))
showmem()
assert(dofile(_WD..'math.lua'))
showmem()
assert(dofile(_WD..'sort.lua'))
showmem()
assert(dofile(_WD..'verybig.lua') == 10); collectgarbage()
showmem()
f()
showmem()
assert(dofile(_WD..'files.lua'))
print("final OK !!!")
showmem()

print('limpando tudo!!!!')
local preserve = {
  _STDERR = _G._STDERR,
  error = error,
  _ERRORMESSAGE = _G._ERRORMESSAGE,
  _ALERT = _G._ALERT,
  tostring = _G.tostring,
  _INPUT=_G._INPUT,
  _OUTPUT=_G._OUTPUT}

local collectgarbage, showmem, print, format, clock =
      collectgarbage, showmem, print, format, clock

dbg.setcallhook(function (a) %assert(%type(a) == 'string') end)
globals(preserve)
collectgarbage()
collectgarbage()
collectgarbage()

collectgarbage();showmem()

print(format("\n\ntempo total: %.2f\n", clock()-c))
