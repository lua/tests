# testing special comment on first line

-- most (all?) tests here assume a reasonable "Unix-like" shell
if _port then return end

print ("testing stand-alone interpreter")

assert(os.execute())   -- machine has a system command

local prog = os.tmpname()
local otherprog = os.tmpname()
local out = os.tmpname()

local progname
do
  local i = 0
  while arg[i] do i=i-1 end
  progname = arg[i+1]
end
print("progname: "..progname)

local prepfile = function (s, p)
  p = p or prog
  io.output(p)
  io.write(s)
  assert(io.close())
end

local function getoutput ()
  io.input(out)
  local t = io.read("a")
  io.input():close()
  assert(os.remove(out))
  return t
end

local function checkprogout (s)
  local t = getoutput()
  for line in string.gmatch(s, ".-\n") do
    assert(string.find(t, line, 1, true))
  end
end

local function checkout (s)
  local t = getoutput()
  if s ~= t then print(string.format("'%s' - '%s'\n", s, t)) end
  assert(s == t)
  return t
end

local function auxrun (...)
  local s = string.format(...)
  s = string.gsub(s, "@lua", '"'..progname..'"', 1)
  return os.execute(s)
end

local function RUN (...)
  assert(auxrun(...))
end

local function NoRun (...)
  assert(not auxrun(...))
end

local function NoRunMsg (...)
  print("\n(the next error is expected by the test)")
  return NoRun(...)
end

RUN("@lua -v")

-- running stdin as a file
RUN("@lua > %s << eof\nprint(10)\nprint(2)\neof\n", out)
checkout("10\n2\n")

-- test environment variables used by Lua
prepfile("print(package.path)")

RUN("env LUA_INIT= LUA_PATH=x @lua %s > %s", prog, out)
checkout("x\n")

RUN("env LUA_INIT= LUA_PATH_5_3=y LUA_PATH=x @lua %s > %s", prog, out)
checkout("y\n")

prepfile("print(package.cpath)")
RUN("env LUA_INIT= LUA_CPATH=xuxu @lua %s > %s", prog, out)
checkout("xuxu\n")

RUN("env LUA_INIT= LUA_CPATH_5_3=yacc LUA_CPATH=x @lua %s > %s", prog, out)
checkout("yacc\n")

prepfile("print(X)")
RUN('env LUA_INIT="X=tonumber(arg[1])" @lua %s 3.2 > %s', prog, out)
checkout("3.2\n")

prepfile("print(X)")
RUN('env LUA_INIT_5_3="X=10" LUA_INIT="X=3" @lua %s > %s', prog, out)
checkout("10\n")

prepfile("x = x or 10; print(x); x = x + 1")
RUN("env LUA_INIT='@%s' @lua %s > %s", prog, prog, out)
checkout("10\n11\n")

-- test option '-E'
local defaultpath, defaultCpath

do
  prepfile("print(package.path, package.cpath)")
  RUN('env LUA_INIT="error(10)" LUA_PATH=xxx LUA_CPATH=xxx @lua -E %s > %s',
       prog, out)
  local out = getoutput()
  defaultpath = string.match(out, "^(.-)\t")
  defaultCpath = string.match(out, "\t(.-)$")
end

-- paths did not changed
assert(not string.find(defaultpath, "xxx") and
       string.find(defaultpath, "lua") and
       not string.find(defaultCpath, "xxx") and
       string.find(defaultCpath, "lua"))


-- test replacement of ';;' to default path
local function convert (p)
  prepfile("print(package.path)")
  RUN('env LUA_PATH="%s" @lua %s > %s', p, prog, out)
  local expected = getoutput()
  expected = string.sub(expected, 1, -2)   -- cut final end of line
  assert(string.gsub(p, ";;", ";"..defaultpath..";") == expected)
end

convert(";")
convert(";;")
convert(";;;")
convert(";;;;")
convert(";;;;;")
convert(";;a;;;bc")


-- test 2 files
prepfile("print(1); a=2; return {x=15}")
prepfile(("print(a); print(_G['%s'].x)"):format(prog), otherprog)
RUN('env LUA_PATH="?;;" @lua -l %s -l%s -lstring -l io %s > %s', prog, otherprog, otherprog, out)
checkout("1\n2\n15\n2\n15\n")

local a = [[
  assert(#arg == 3 and arg[1] == 'a' and
         arg[2] == 'b' and arg[3] == 'c')
  assert(arg[-1] == '--' and arg[-2] == "-e " and arg[-3] == '%s')
  assert(arg[4] == nil and arg[-4] == nil)
  local a, b, c = ...
  assert(... == 'a' and a == 'a' and b == 'b' and c == 'c')
]]
a = string.format(a, progname)
prepfile(a)
RUN('@lua "-e " -- %s a b c', prog)

prepfile"assert(arg)"
prepfile("assert(arg)", otherprog)
RUN('env LUA_PATH="?;;" @lua -l%s - < %s', prog, otherprog)

prepfile""
RUN("@lua - < %s > %s", prog, out)
checkout("")

-- test many arguments
prepfile[[print(({...})[30])]]
RUN("@lua %s %s > %s", prog, string.rep(" a", 30), out)
checkout("a\n")

RUN([[@lua "-eprint(1)" -ea=3 -e "print(a)" > %s]], out)
checkout("1\n3\n")

prepfile[[
  print(
1, a
)
]]
RUN("@lua - < %s > %s", prog, out)
checkout("1\tnil\n")

prepfile[[
(6*2-6) -- ===
a =
10
print(a)
a]]
RUN([[@lua -e"_PROMPT='' _PROMPT2=''" -i < %s > %s]], prog, out)
checkprogout("6\n10\n10\n\n")

prepfile("a = [[b\nc\nd\ne]]\n=a")
print("temporary program file: "..prog)
RUN([[@lua -e"_PROMPT='' _PROMPT2=''" -i < %s > %s]], prog, out)
checkprogout("b\nc\nd\ne\n\n")

prompt = "alo"
prepfile[[ --
a = 2
]]
RUN([[@lua "-e_PROMPT='%s'" -i < %s > %s]], prompt, prog, out)
local t = getoutput()
assert(string.find(t, prompt .. ".*" .. prompt .. ".*" .. prompt))

-- test for error objects
prepfile[[
debug = require "debug"
m = {x=0}
setmetatable(m, {__tostring = function(x)
  return tostring(debug.getinfo(4).currentline + x.x)
end})
error(m)
]]
NoRun([[@lua %s 2> %s]], prog, out)
checkout(progname..": 6\n")

prepfile("error{}")
NoRun([[@lua %s 2> %s]], prog, out)
assert(string.find(getoutput(), "error object is a table value"))


s = [=[ -- 
function f ( x ) 
  local a = [[
xuxu
]]
  local b = "\
xuxu\n"
  if x == 11 then return 1 + 12 , 2 + 20 end  --[[ test multiple returns ]]
  return x + 1 
  --\\
end
return( f( 100 ) )
assert( a == b )
do return f( 11 ) end  ]=]
s = string.gsub(s, ' ', '\n\n')
prepfile(s)
RUN([[@lua -e"_PROMPT='' _PROMPT2=''" -i < %s > %s]], prog, out)
checkprogout("101\n13\t22\n\n")
  
prepfile[[#comment in 1st line without \n at the end]]
RUN("@lua %s", prog)
  
prepfile[[#test line number when file starts with comment line
debug = require"debug"
print(debug.getinfo(1).currentline)
]]
RUN("@lua %s > %s", prog, out)
checkprogout('3')

-- close Lua with an open file
prepfile(string.format([[io.output(%q); io.write('alo')]], out))
RUN("@lua %s", prog)
checkout('alo')

-- bug in 5.2 beta (extra \0 after version line)
RUN([[@lua -v  -e'print"hello"' > %s]], out)
t = getoutput()
assert(string.find(t, "PUC%-Rio\nhello"))


-- testing os.exit
prepfile("os.exit(nil, true)")
RUN("@lua %s", prog)
prepfile("os.exit(0, true)")
RUN("@lua %s", prog)
prepfile("os.exit(true, true)")
RUN("@lua %s", prog)
prepfile("os.exit(1, true)")
NoRun("@lua %s", prog)   -- no message
prepfile("os.exit(false, true)")
NoRun("@lua %s", prog)   -- no message

assert(os.remove(prog))
assert(os.remove(otherprog))
assert(not os.remove(out))

print('testing Ctrl C')
do
  -- Lua script that runs protected infinite loop and then prints '42'
  local luaprg = 'pcall(function () while true do end end); print(42)'

  -- shell script to run 'luaprg' in background and echo its pid
  local shellprg = string.format("%s -e '%s' & echo $!", progname, luaprg)

  local f = io.popen(shellprg, "r")   -- run shell script
  local pid = f:read()   -- get pid for Lua script
  print("(if this test fails, it may leave an infinite Lua script [pid "
          .. pid .. "] running in your system)")
  -- waits a little, so script can reach the pcall loop
  assert(os.execute("sleep 1"))
  -- send INT signal to Lua script
  assert(os.execute(string.format("kill -INT %d", pid)))
  assert(f:read() == "42")  -- expected output
  assert(f:close())
end
print('+')

NoRunMsg("@lua -h")
NoRunMsg("@lua -e")
NoRunMsg("@lua -e a")
NoRunMsg("@lua -l")

print("OK")
