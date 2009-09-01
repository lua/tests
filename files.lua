
print('testing i/o')

assert(type(os.getenv"PATH") == "string")

assert(io.input(io.stdin) == io.stdin)
assert(not pcall(io.input, "non-existent-file"))
assert(io.output(io.stdout) == io.stdout)

-- cannot close standard files
assert(not io.close(io.stdin) and
       not io.stdout:close() and
       not io.stderr:close())


assert(type(io.input()) == "userdata" and io.type(io.output()) == "file")
assert(type(io.stdin) == "userdata" and io.type(io.stderr) == "file")
assert(io.type(8) == nil)
local a = {}; setmetatable(a, {})
assert(io.type(a) == nil)

local a,b,c = io.open('xuxu_nao_existe')
assert(not a and type(b) == "string" and type(c) == "number")

a,b,c = io.open('/a/b/c/d', 'w')
assert(not a and type(b) == "string" and type(c) == "number")

local file = os.tmpname()
local otherfile = os.tmpname()

assert(not pcall(io.open, file, "rw"))     -- invalid mode
assert(not pcall(io.open, file, "rb+"))    -- invalid mode
assert(not pcall(io.open, file, "r+bk"))   -- invalid mode
assert(not pcall(io.open, file, ""))       -- invalid mode
assert(not pcall(io.open, file, "+"))      -- invalid mode
assert(not pcall(io.open, file, "b"))      -- invalid mode
assert(io.open(file, "r+b")):close()
assert(io.open(file, "r+")):close()
assert(io.open(file, "rb")):close()

assert(os.setlocale('C', 'all'))

io.input(io.stdin); io.output(io.stdout);

os.remove(file)
assert(loadfile(file) == nil)
assert(io.open(file) == nil)
io.output(file)
assert(io.output() ~= io.stdout)

assert(io.output():seek() == 0)
assert(io.write("alo alo"):seek() == string.len("alo alo"))
assert(io.output():seek("cur", -3) == string.len("alo alo")-3)
assert(io.write("joao"))
assert(io.output():seek("end") == string.len("alo joao"))

assert(io.output():seek("set") == 0)

assert(io.write('"álo"', "{a}\n", "second line\n", "third line \n"))
assert(io.write('çfourth_line'))
io.output(io.stdout)
collectgarbage()  -- file should be closed by GC
assert(io.input() == io.stdin and rawequal(io.output(), io.stdout))
print('+')

-- test GC for files
collectgarbage()
for i=1,120 do
  for i=1,5 do
    io.input(file)
    assert(io.open(file, 'r'))
    io.lines(file)
  end
  collectgarbage()
end

assert(os.rename(file, otherfile))
assert(os.rename(file, otherfile) == nil)

io.output(io.open(otherfile, "ab"))
assert(io.write("\n\n\t\t  3450\n"));
io.close()

-- test line generators
assert(not pcall(io.lines, "non-existent-file"))
assert(os.rename(otherfile, file))
io.output(otherfile)
local f = io.lines(file)
while f() do end;
assert(not pcall(f))  -- read lines after EOF
assert(not pcall(f))  -- read lines after EOF
-- copy from file to otherfile
for l in io.lines(file) do io.write(l, "\n") end
io.close()
-- copy from otherfile back to file
local f = assert(io.open(otherfile))
assert(io.type(f) == "file")
io.output(file)
assert(io.output():read() == nil)
for l in f:lines() do io.write(l, "\n") end
assert(tostring(f):sub(1, 5) == "file ")
assert(f:close()); io.close()
assert(not pcall(io.close, f))   -- error trying to close again
assert(tostring(f) == "file (closed)")
assert(io.type(f) == "closed file")
io.input(file)
f = io.open(otherfile):lines()
for l in io.lines() do assert(l == f()) end
assert(os.remove(otherfile))

io.input(file)
do  -- test error returns
  local a,b,c = io.input():write("xuxu")
  assert(not a and type(b) == "string" and type(c) == "number")
end
assert(io.read(0) == "")   -- not eof
assert(io.read(5, '*l') == '"álo"')
assert(io.read(0) == "")
assert(io.read() == "second line")
local x = io.input():seek()
assert(io.read() == "third line ")
assert(io.input():seek("set", x))
assert(io.read('*l') == "third line ")
assert(io.read(1) == "ç")
assert(io.read(string.len"fourth_line") == "fourth_line")
assert(io.input():seek("cur", -string.len"fourth_line"))
assert(io.read() == "fourth_line")
assert(io.read() == "")  -- empty line
assert(io.read('*n') == 3450)
assert(io.read(1) == '\n')
assert(io.read(0) == nil)  -- end of file
assert(io.read(1) == nil)  -- end of file
assert(io.read(30000) == nil)  -- end of file
assert(({io.read(1)})[2] == nil)
assert(io.read() == nil)  -- end of file
assert(({io.read()})[2] == nil)
assert(io.read('*n') == nil)  -- end of file
assert(({io.read('*n')})[2] == nil)
assert(io.read('*a') == '')  -- end of file (OK for `*a')
assert(io.read('*a') == '')  -- end of file (OK for `*a')
collectgarbage()
print('+')
io.close(io.input())
assert(not pcall(io.read))

assert(os.remove(file))

local t = '0123456789'
for i=1,12 do t = t..t; end
assert(string.len(t) == 10*2^12)

io.output(file)
io.write("alo"):write("\n")
io.close()
assert(not pcall(io.write))
local f = io.open(file, "a+b")
io.output(f)
collectgarbage()

assert(io.write(' ' .. t .. ' '))
assert(io.write(';', 'end of file\n'))
f:flush(); io.flush()
f:close()
print('+')

io.input(file)
assert(io.read() == "alo")
assert(io.read(1) == ' ')
assert(io.read(string.len(t)) == t)
assert(io.read(1) == ' ')
assert(io.read(0))
assert(io.read('*a') == ';end of file\n')
assert(io.read(0) == nil)
assert(io.close(io.input()))

assert(os.remove(file))
print('+')

local x1 = "string\n\n\\com \"\"''coisas [[estranhas]] ]]'"
io.output(file)
assert(io.write(string.format("x2 = %q\n-- comment without ending EOS", x1)))
io.close()
assert(loadfile(file))()
assert(x1 == x2)
print('+')
assert(os.remove(file))
assert(os.remove(file) == nil)
assert(os.remove(otherfile) == nil)

io.output(file)
assert(io.write("qualquer coisa\n"))
assert(io.write("mais qualquer coisa"))
io.close()
assert(io.output(assert(io.open(otherfile, 'wb')))
       :write("outra coisa\0\1\3\0\0\0\0\255\0")
       :close())

local filehandle = assert(io.open(file, 'r+b'))
local otherfilehandle = assert(io.open(otherfile, 'rb'))
assert(filehandle ~= otherfilehandle)
assert(type(filehandle) == "userdata")
assert(filehandle:read('*l') == "qualquer coisa")
io.input(otherfilehandle)
assert(io.read(string.len"outra coisa") == "outra coisa")
assert(filehandle:read('*l') == "mais qualquer coisa")
filehandle:close();
assert(type(filehandle) == "userdata")
io.input(otherfilehandle)
assert(io.read(4) == "\0\1\3\0")
assert(io.read(3) == "\0\0\0")
assert(io.read(0) == "")        -- 255 is not eof
assert(io.read(1) == "\255")
assert(io.read('*a') == "\0")
assert(not io.read(0))
assert(otherfilehandle == io.input())
otherfilehandle:close()
assert(os.remove(file))
assert(os.remove(otherfile))
collectgarbage()

io.output(file)
  :write[[
 123.4	-56e-2  not a number
second line
third line

and the rest of the file
]]
  :close()
io.input(file)
local _,a,b,c,d,e,h,__ = io.read(1, '*n', '*n', '*l', '*l', '*l', '*a', 10)
assert(io.close(io.input()))
assert(_ == ' ' and __ == nil)
assert(type(a) == 'number' and a==123.4 and b==-56e-2)
assert(d=='second line' and e=='third line')
assert(h==[[

and the rest of the file
]])
assert(os.remove(file))
collectgarbage()

-- testing buffers
do
  local f = assert(io.open(file, "w"))
  local fr = assert(io.open(file, "r"))
  assert(f:setvbuf("full", 2000))
  f:write("x")
  assert(fr:read("*all") == "")  -- full buffer; output not written yet
  f:close()
  fr:seek("set")
  assert(fr:read("*all") == "x")   -- `close' flushes it
  f = assert(io.open(file), "w")
  assert(f:setvbuf("no"))
  f:write("x")
  fr:seek("set")
  assert(fr:read("*all") == "x")  -- no buffer; output is ready
  f:close()
  f = assert(io.open(file, "a"))
  assert(f:setvbuf("line"))
  f:write("x")
  fr:seek("set", 1)
  assert(fr:read("*all") == "")   -- line buffer; no output without `\n'
  f:write("a\n"):seek("set", 1)
  assert(fr:read("*all") == "xa\n")  -- now we have a whole line
  f:close(); fr:close()
end


-- testing large files (> BUFSIZ)
io.output(file)
for i=1,5001 do io.write('0123456789123') end
io.write('\n12346'):close()
io.input(file)
local x = io.read('*a')
io.input():seek('set', 0)
local y = io.read(30001)..io.read(1005)..io.read(0)..io.read(1)..io.read(100003)
assert(x == y and string.len(x) == 5001*13 + 6)
io.input():seek('set', 0)
y = io.read()  -- huge line
assert(x == y..'\n'..io.read())
assert(io.read() == nil)
io.close(io.input())
assert(os.remove(file))
x = nil; y = nil

x, y = pcall(io.popen, "ls")
if x then
  assert(y:read("*a"))
  assert(y:close() == 0)
  assert(not io.open("no program with this name"))
else
  (Message or print)('\a\n >>> popen not available<<<\n\a')
end

print'+'


assert(os.date("") == "")
assert(os.date("!") == "")
local x = string.rep("a", 10000)
assert(os.date(x) == x)
local t = os.time()
T = os.date("*t", t)
assert(os.date(string.rep("%d", 1000), t) ==
       string.rep(os.date("%d", t), 1000))
assert(os.date(string.rep("%", 200)) == string.rep("%", 100))

local t = os.time()
T = os.date("*t", t)
loadstring(os.date([[assert(T.year==%Y and T.month==%m and T.day==%d and
  T.hour==%H and T.min==%M and T.sec==%S and
  T.wday==%w+1 and T.yday==%j and type(T.isdst) == 'boolean')]], t))()

assert(not pcall(os.date, "%9"))   -- invalid conversion specifier
assert(not pcall(os.date, "%"))   -- invalid conversion specifier
assert(not pcall(os.date, "%O"))   -- invalid conversion specifier
assert(not pcall(os.date, "%E"))   -- invalid conversion specifier
assert(not pcall(os.date, "%Ea"))   -- invalid conversion specifier

-- assume POSIX
assert(type(os.date("%Ex")) == 'string')
assert(type(os.date("%Oy")) == 'string')

assert(os.time(T) == t)
assert(not pcall(os.time, {hour = 12}))

T = os.date("!*t", t)
loadstring(os.date([[!assert(T.year==%Y and T.month==%m and T.day==%d and
  T.hour==%H and T.min==%M and T.sec==%S and
  T.wday==%w+1 and T.yday==%j and type(T.isdst) == 'boolean')]], t))()

do
  local T = os.date("*t")
  local t = os.time(T)
  assert(type(T.isdst) == 'boolean')
  T.isdst = nil
  local t1 = os.time(T)
  assert(t == t1)   -- if isdst is absent uses correct default
end   

t = os.time(T)
T.year = T.year-1;
local t1 = os.time(T)
-- allow for leap years
assert(math.abs(os.difftime(t,t1)/(24*3600) - 365) < 2)

t = os.time()
t1 = os.time(os.date("*t"))
assert(os.difftime(t1,t) <= 2)

local t1 = os.time{year=2000, month=10, day=1, hour=23, min=12}
local t2 = os.time{year=2000, month=10, day=1, hour=23, min=10, sec=19}
assert(os.difftime(t1,t2) == 60*2-19)

io.output(io.stdout)
local d = os.date('%d')
local m = os.date('%m')
local a = os.date('%Y')
local ds = os.date('%w') + 1
local h = os.date('%H')
local min = os.date('%M')
local s = os.date('%S')
io.write(string.format('test done on %2.2d/%2.2d/%d', d, m, a))
io.write(string.format(', at %2.2d:%2.2d:%2.2d\n', h, min, s))
io.write(string.format('%s\n', _VERSION))

f = io.tmpfile()
assert(io.type(f) == "file")
f:write("alo")
f:seek("set")
assert(f:read"*a" == "alo")


