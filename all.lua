#!../lua
$debug

local c = clock()

_WD = wd or ""

assert(setlocale"C")

local showmem = function ()
  if totalmem then
    local a,b = totalmem()
    print(format("\n ---- memoria total: %d,  blocos: %d\n", a, b))
  end
end

assert(dofile(_WD..'tracgc.lua'))
showmem()
assert(dofile(_WD..'gc.lua'))
showmem()
assert(dofile(_WD..'db.lua'))
showmem()
assert(dofile(_WD..'calls.lua') == deep)
showmem()
assert(dofile(_WD..'fallback.lua'))
showmem()
assert(dofile(_WD..'strings.lua'))
showmem()
assert(dofile(_WD..'literals.lua'))
showmem()
assert(dofile(_WD..'attrib.lua') == 27)
showmem()
assert(dofile(_WD..'locals.lua') == 5)
assert(dofile(_WD..'constructs.lua'))
assert(dofile(_WD..'big.lua') == 'a')
assert(dofile(_WD..'verybig.lua') == 10); collectgarbage()
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
assert(dofile(_WD..'pragmas.lua'))
showmem()
assert(dofile(_WD..'errors.lua'))
showmem()
assert(dofile(_WD..'math.lua'))
showmem()
assert(dofile(_WD..'sort.lua'))
showmem()
assert(dofile(_WD..'gc.lua'))
showmem()
assert(dofile(_WD..'files.lua'))
print("final OK !!!")
showmem()

$ifnot _hard_i
print('limpando tudo!!!!')
local preserve = {showmem = 1, collectgarbage = 1, print = 1, tostring = 1,
  settag = 1, tag = 1, type = 1, _STDERR = 1, totalmem = 1, error = 1,
  format = 1, execute = 1, format = 1, clock = 1, }

foreachvar(function (n) if not %preserve[n] then %setglobal(n, nil) end end)
$end

collectgarbage();showmem()

print(format("\n\ntempo total: %.2f\n", clock()-c))
