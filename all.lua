#!../lua

local c = clock()

_WD = wd or ""

LUA_PATH = (LUA_PATH or getenv("LUA_PATH") or "./") .. ";" .. _WD

assert(setlocale"C")

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

if type(T) == 'table' then   -- debug facilities available?
  T.settagmethod(tag(nil), 'gc', function (a)
    %write(_STDERR, '.')
  end)
end

local f = assert(loadfile(_WD..'gc.lua'))
f()
showmem()
assert(dofile(_WD..'db.lua'))
showmem()
assert(dofile(_WD..'calls.lua') == deep)
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
assert(dofile(_WD..'big.lua') == 'a')
showmem()
assert(dofile(_WD..'func.lua'))
showmem()
assert(dofile(_WD..'nextvar.lua'))
showmem()
assert(dofile(_WD..'pm.lua'))
showmem()
assert(dofile(_WD..'api.lua'))
showmem()
assert(dofile(_WD..'tag.lua') == 12)
showmem()
assert(dofile(_WD..'vararg.lua'))
showmem()
assert(dofile(_WD..'errors.lua'))
showmem()
assert(dofile(_WD..'fallback.lua'))
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
  _STDERR = _STDERR,
  error = error,
  _ERRORMESSAGE = _ERRORMESSAGE,
  _ALERT = _ALERT,
  tostring = tostring,
  _INPUT=_INPUT,
  _OUTPUT=_OUTPUT}

local collectgarbage, showmem, print, format, clock =
      collectgarbage, showmem, print, format, clock

setcallhook(function (a) %assert(%type(a) == 'string') end)
globals(preserve)
collectgarbage()
collectgarbage()
collectgarbage()

collectgarbage();showmem()

print(format("\n\ntempo total: %.2f\n", clock()-c))
