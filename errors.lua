print("testando erros")

local old = _ERRORMESSAGE

function doit (s)
  local f, msg = loadstring(s)
  if f == nil then return msg end
  local cond, msg = pcall(f)
  return (not cond) and msg
end


function checkmessage (prog, msg)
  assert(strfind(doit(prog), msg, 1, true))
end

function checksyntax (prog, extra, token, line)
  local msg = doit(prog)
  local pt = format([[^%%[string ".*"%%]:%d: .- near `%s'$]], line, token)
  assert(strfind(msg, pt))
  assert(strfind(msg, msg, 1, true))
end



-- testa erros comuns e/ou que voavam no passado
assert(doit("unpack{n=2^30}"))
assert(doit("a=sin()"))
assert(not doit("tostring(1)") and doit("tostring()"))
assert(doit"tonumber()")
assert(doit"repeat until 1; a")
checksyntax("break label", "", "label", 1)
assert(doit";")
assert(doit"a=1;;")
assert(doit"return;;")
assert(doit"assert(false)")
assert(doit"assert(nil)")
assert(doit"a=sin\n(3)")
assert(doit("function a (... , ...) end"))
assert(doit("function a (, ...) end"))
--[[?? checksyntax('%a()', "", "a", 1)
checksyntax([[
  local other, var = 1
  other = other or %var

]], "", "var", 2)
]]

checksyntax([[
  local a = {4

]], "`}' expected (to close `{' at line 1)", "<eof>", 3)


-- testes para mensagens de erro mais explicativas

checkmessage("a=1; bbbb=2; a=sin(3)+bbbb(3)", "global `bbbb'")
checkmessage("a=1; local a,bbbb=2,3; a = sin(1) and bbbb(3)",
       "local `bbbb'")
checkmessage("a={}; do local a=1 end a:bbbb(3)", "method `bbbb'")
checkmessage("local a={}; a.bbbb(3)", "field `bbbb'")
assert(not strfind(doit"a={13}; local bbbb=1; a[bbbb](3)", "`bbbb'"))
checkmessage("a={13}; local bbbb=1; a[bbbb](3)", "number")

aaa = nil
checkmessage("aaa.bbb:ddd(9)", "global `aaa'")
checkmessage("local aaa={bbb=1}; aaa.bbb:ddd(9)", "field `bbb'")
checkmessage("local aaa={bbb={}}; aaa.bbb:ddd(9)", "method `ddd'")
assert(not doit"local aaa={bbb={ddd=next}}; aaa.bbb:ddd(nil)")

checkmessage("local aaa='a'; x=aaa+b", "local `aaa'")
checkmessage("aaa={}; x=3/aaa", "global `aaa'")
checkmessage("aaa='2'; b=nil;x=aaa*b", "global `b'")
checkmessage("aaa={}; x=-aaa", "global `aaa'")
assert(not strfind(doit"aaa={}; x=(aaa or aaa)+(aaa and aaa)", "`aaa'"))
assert(not strfind(doit"aaa={}; (aaa or aaa)()", "`aaa'"))

checkmessage([[aaa=9
repeat until 3==3
local x=sin(cos(3))
if sin(1) == x then return 1,2,sin(1) end   -- tail call
local a,b = 1, {
  {x='a'..'b'..'c', y='b', z=x},
  {1,2,3,4,5} or 3+3<=3+3,
  3+1>3+1,
  {d = x and aaa[x or y]}}
]], "global `aaa'")

checkmessage([[
local x,y = {},1
if sin(1) == 0 then return 3 end    -- return
x.a()]], "field `a'")

checkmessage([[
prefix = nil
while 1 do  
  local a
  if nil then break end
  insert(prefix, w)
end]], "global `insert'")

print'+'


-- teste de linha do erro

function lineerror (s)
  local line
  xpcall(function (s) line = getinfo(2, "l").currentline end, loadstring(s))
  return line
end

assert(lineerror"local a\n for i=1,'a' do \n print(i) \n end" == 2)
assert(lineerror"\n local a \n for k,v in 3 \n do \n print(k) \n end" == 3)
assert(lineerror"\n\n for k,v in \n 3 \n do \n print(k) \n end" == 4)

lineerror = nil

C = 0
function y () C=C+1; y() end

function checkstackmessage (m)
  return (string.find(m, "^.-:%d+: stack overflow$"))
end
assert(checkstackmessage(doit('y()')))
assert(checkstackmessage(doit('y()')))
assert(checkstackmessage(doit('y()')))
-- teste de linhas em erro
C = 0
xpcall(function (s)
  if not checkstackmessage(s) then print(s)
    io.stderr:write("exiting!!\n"); os.exit(1)
  end
  local l = getinfo(2, "l").currentline
  assert(getinfo(1, "l").currentline == l+15)
  for i=1,C-1 do assert(getinfo(2+i, "l").currentline == l) end
  assert(getinfo(2+C, "l").currentline == -1)  -- `call'
  assert(getinfo(3+C, "l").currentline == l+10)  -- this file
end, y)
print('+')
checksyntax(("syntax error"), "", "error", 1)

doit('i = loadstring("a=9+"); a=3')
assert(a==3 and i == nil)
print('+')

do
  local a,b = xpcall(error, function () a='x'+1 end)
  assert(a == nil and b == "error in error handling")
end

lim = 1000
if _soft then lim = 100 end
for i=1,lim do
  doit('a = ')
  doit('a = 4+nil')
end

print('OK')
