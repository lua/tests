#!../lua

local version = "Lua 5.3"
if _VERSION ~= version then
  io.stderr:write("\nThis test suite is for ", version, ", not for ", _VERSION,
    "\nExiting tests\n")
  return
end


-- next variables control the execution of some tests
-- true means no test (so an undefined variable does not skip a test)
-- defaults are for Linux; test everything

_soft = false      -- true to avoid long or memory consuming tests
_port = false      -- true to avoid non-portable tests
_nomsg = false     -- true to avoid messages about tests not performed
_noposix = false   -- false assumes LUA_USE_POSIX
_noformatA = false   -- false assumes LUA_USE_AFORMAT


local usertests = rawget(_G, "_U")

if usertests then
  -- tests for sissies ;)  Avoid problems
  _soft = true
  _port = true
  _nomsg = true
  _noposix = true
  _noformatA = true; 
end

-- no "internal" tests for user tests
if usertests then T = nil end

T = rawget(_G, "T")  -- avoid problems with 'strict' module

math.randomseed(0)



--[=[
  example of a long [comment],
  [[spanning several [lines]]]

]=]

print("current path:\n****" .. package.path .. "****\n")


local c = os.clock()
local walltime = os.time()

local collectgarbage = collectgarbage

do   -- (

-- track messages for tests not performed
local msgs = {}
function Message (m)
  if not _nomsg then
    print(m)
    msgs[#msgs+1] = string.sub(m, 3, -3)
  end
end

assert(os.setlocale"C")

local T,print,format,write,assert,type,unpack,floor =
      T,print,string.format,io.write,assert,type,table.unpack,math.floor

-- use K for 1000 and M for 1000000 (not 2^10 -- 2^20)
local function F (m)
  local function round (m)
    m = m + 0.04999
    return format("%.1f", m)      -- keep one decimal digit
  end
  if m < 1000 then return m
  else
    m = m / 1000
    if m < 1000 then return round(m).."K"
    else
      return round(m/1000).."M"
    end
  end
end

local showmem
if not T then
  local max = 0
  showmem = function ()
    local m = collectgarbage("count") * 1024
    max = (m > max) and m or max
    print(format("    ---- total memory: %s, max memory: %s ----\n",
          F(m), F(max)))
  end
else
  showmem = function ()
    T.checkmemory()
    local total, numblocks, maxmem = T.totalmem()
    local count = collectgarbage("count")
    print(format(
      "\n    ---- total memory: %s (%.0fK), max use: %s,  blocks: %d\n",
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
dofile = function (n, strip)
  showmem()
  print("time :", os.clock() - c)
  report(n)
  local f = assert(loadfile(n))
  local b = string.dump(f, strip)
  f = assert(load(b))
  return f()
end

dofile('main.lua')

do
  local next, setmetatable, stderr = next, setmetatable, io.stderr
  -- track collections
  local mt = {}
  -- each time a table is collected, remark it for finalization
  -- on next cycle
  mt.__gc = function (o)
     stderr:write'.'    -- mark progress
     local n = setmetatable(o, mt)   -- remark it
   end
   local n = setmetatable({}, mt)    -- create object
end

report"gc.lua"
local f = assert(loadfile('gc.lua'))
f()

dofile('db.lua')
assert(dofile('calls.lua') == deep and deep)
olddofile('strings.lua')
olddofile('literals.lua')
assert(dofile('attrib.lua') == 27)

assert(dofile('locals.lua') == 5)
dofile('constructs.lua')
dofile('code.lua', true)
if not _G._soft then
  report('big.lua')
  local f = coroutine.wrap(assert(loadfile('big.lua')))
  assert(f() == 'b')
  assert(f() == 'a')
end
dofile('nextvar.lua')
dofile('pm.lua')
dofile('utf8.lua')
dofile('api.lua')
assert(dofile('events.lua') == 12)
dofile('vararg.lua')
dofile('closure.lua')
dofile('coroutine.lua')
dofile('goto.lua', true)
dofile('errors.lua')
dofile('math.lua')
dofile('sort.lua', true)
dofile('bitwise.lua')
assert(dofile('verybig.lua', true) == 10); collectgarbage()
dofile('files.lua')

if #msgs > 0 then
  print("\ntests not performed:")
  for i=1,#msgs do
    print(msgs[i])
  end
  print()
end

local debug = require "debug"

print(string.format("%d-bit integers, %d-bit floats",
        debug.sizeof'I' * 8, debug.sizeof'F' * 8))
print("final OK !!!")

debug.sethook(function (a) assert(type(a) == 'string') end, "cr")

-- to survive outside block
_G.showmem = showmem

end   --)

local _G, showmem, print, format, clock, time, assert, open =
      _G, showmem, print, string.format, os.clock, os.time, assert, io.open

-- file with time of last performed test
local fname = T and "time-debug.txt" or "time.txt"
local lasttime

if not usertests then
  -- open file with time of last performed test
  local f = io.open(fname)
  if f then
    lasttime = assert(tonumber(f:read'a'))
    f:close();
  else   -- no such file; assume it is recording time for first time
    lasttime = nil
  end
end

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

local clocktime = clock() - c
walltime = time() - walltime

print(format("\n\ntotal time: %.2fs (wall time: %ds)\n", clocktime, walltime))

if not usertests then
  lasttime = lasttime or clocktime    -- if no last time, ignore difference
  -- check whether current test time differs more than 5% from last time
  local diff = (clocktime - lasttime) / clocktime
  local tolerance = 0.05    -- 5%
  if (diff >= tolerance or diff <= -tolerance) then
    print(format("WARNING: time difference from previous test: %+.1f%%",
                  diff * 100))
  end
  assert(open(fname, "w")):write(clocktime):close()
end

