#!../lua

math.randomseed(0)

collectgarbage("setstepmul", 180)
collectgarbage("setpause", 190)


--[=[
  example of a long [comment],
  [[spanning several [lines]]]

]=]

print("current path:\n  " .. string.gsub(package.path, ";", "\n  "))


local c = os.clock()

local collectgarbage = collectgarbage

do

local msgs = {}
function Message (m)
  print(m)
  msgs[#msgs+1] = string.sub(m, 3, -3)
end

assert(os.setlocale"C")

local T,print,format,write,assert,type,unpack =
      T,print,string.format,io.write,assert,type,table.unpack

local function F (m)
  if m < 1024 then return m
  else
    m = m/1024 - m/1024%1
    if m < 1024 then return m.."K"
    else
      m = m/1024 - m/1024%1
      return m.."M"
    end
  end
end

local showmem = function ()
  if not T then
    print(format("    ---- total memory: %s ----\n",
          F(collectgarbage("count"))))
  else
    T.checkmemory()
    local total, numblocks, maxmem = T.totalmem()
    local count = collectgarbage("count")
    print(format(
      "\n    ---- total memory: %s (%dK), max use: %s,  blocks: %d\n",
      F(total), count, F(maxmem), numblocks))
    print(format("\t(strings:  %d, tables: %d, functions: %d, "..
                 "\n\tudata: %d, threads: %d)",
                 T.totalmem"string", T.totalmem"table", T.totalmem"function",
                 T.totalmem"userdata", T.totalmem"thread"))

          
  end
end


--
-- redefine dofile to run files through dump/undump
--
local function report (n) print("\n***** FILE '"..n.."'*****") end
local olddofile = dofile
dofile = function (n)
  showmem()
  report(n)
  local f = assert(loadfile(n))
  local b = string.dump(f)
  f = assert(loadstring(b))
  return f()
end

dofile('main.lua')

do
  local u = newproxy(true)
  local eph = setmetatable({}, {__mode = "k"})   -- create an ephemeron table
  eph[u] = function () return u end
  local next, newproxy, stderr = next, newproxy, io.stderr
  getmetatable(u).__gc = function (o)
    stderr:write'.'
    assert(eph[o]() == o and next(eph) == o and next(eph, o) == nil)
    local n = newproxy(o)
    eph[n] = function () return n end
    o = nil
    local a,b,c,d,e = nil    -- erase 'o' from the stack
  end
end

local f = assert(loadfile('gc.lua'))
f()
dofile('db.lua')
assert(dofile('calls.lua') == deep and deep)
olddofile('strings.lua')
olddofile('literals.lua')
assert(dofile('attrib.lua') == 27)
assert(dofile('locals.lua') == 5)
dofile('constructs.lua')
dofile('code.lua')
do
  report('big.lua')
  local f = coroutine.wrap(assert(loadfile('big.lua')))
  assert(f() == 'b')
  assert(f() == 'a')
end
dofile('nextvar.lua')
dofile('pm.lua')
dofile('api.lua')
assert(dofile('events.lua') == 12)
dofile('vararg.lua')
dofile('closure.lua')
dofile('coroutine.lua')
dofile('errors.lua')
dofile('math.lua')
dofile('sort.lua')
dofile('bitwise.lua')
assert(dofile('verybig.lua') == 10); collectgarbage()
dofile('files.lua')

if #msgs > 0 then
  print("\ntests not performed:")
  for i=1,#msgs do
    print(msgs[i])
  end
  print()
end

print("final OK !!!")

require "debug"

debug.sethook(function (a) assert(type(a) == 'string') end, "cr")

-- to survive outside block
_G.showmem = showmem

end

local _G, showmem, print, format, clock =
      _G, showmem, print, string.format, os.clock

-- erase (almost) all globals
print('cleaning all!!!!')
for n in pairs(_G) do
  if not ({___Glob = 1, tostring = 1})[n] then
    _G[n] = nil
  end
end


collectgarbage()
collectgarbage()
collectgarbage()
collectgarbage()
collectgarbage()
collectgarbage();showmem()

print(format("\n\ntotal time: %.2f\n", clock()-c))
