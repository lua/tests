# teste de comentario especial na 1a linha

print ("testando opcoes de lua.c")

prog = tmpname()
otherprog = tmpname()
out = tmpname()

progname = '"'..getargs()[0]..'"'
print(progname)

local prepfile = function (s, p)
  p = p or prog
  assert(writeto(p))
  write(s)
  assert(writeto())
end

function checkout (s)
  assert(readfrom(out))
  local t = read("*a")
  readfrom()
  assert(remove(out))
  if s ~= t then print(format("`%s' - `%s'\n", s, t)) end
  assert(s == t)
  return t
end

function auxrun (arg)
  s = format(unpack(arg))
  s = gsub(s, "lua", progname)
  return execute(s)
end

function RUN (...)
  assert(auxrun(arg) == 0)
end

function NoRun (...)
  assert(auxrun(arg) ~= 0)
end

-- test 2 files
prepfile("print(1); a=2")
prepfile("print(a)", otherprog)
RUN("lua %s %s > %s", prog, otherprog, out)
checkout("1\n2\n")

prepfile
[[assert(arg.n == 3 and arg[1] == 'a' and arg[2] == 'b' and arg[3] == 'c')
  x = getargs()
  assert(x.n == 6 and x[1] == '-c' and x[x.n] == arg[3])
]]
RUN("lua -c -f %s a b c", prog)

prepfile"assert(arg==nil)"
RUN("lua %s", prog)

prepfile""
RUN("lua - < %s > %s", prog, out)
checkout("")

RUN('lua -e "print(1)" a=b -e "print(a)" > %s', out)
checkout("1\nb\n")

prepfile[[
  print(
1, a
)
]]
RUN("lua a=nil - < %s > %s", prog, out)
checkout("1\tnil\n")

prepfile[[
= (6*2-6) -- ===
a 
= 10
print(a)
= a]]
RUN("lua _PROMPT= _PROMPT2= -i < %s > %s", prog, out)
checkout("6\n10\n10\n\n")

prompt = "alo"
prepfile[[ --
a = 2
]]
RUN("lua _PROMPT=%s -i < %s > %s", prompt, prog, out)
checkout(strrep(prompt, 3).."\n")

s = [[ -- 
function f ( x ) 
  local a = [[
xuxu
]]
  local b = "\
xuxu\n"
  return x + 1 
  --\\
end
assert( a == b )
=( f( 10 ) ) ]]
s = gsub(s, ' ', '\n\n')
prepfile(s)
RUN("lua _PROMPT= _PROMPT2= -i < %s > %s", prog, out)
checkout("11\n\n")
  
prepfile[[#comment in 1st line without \n at the end]]
RUN("lua %s", prog)

-- close Lua with an open file
prepfile(string.format([[io.output(%q); io.write('alo')]], out))
RUN("lua -c %s", prog)
checkout('alo')

assert(remove(prog))
assert(remove(otherprog))
assert(not remove(out))

RUN("lua -v")

-- NoRun("lua -h")
-- NoRun("lua -e")
-- NoRun("lua -e a")
-- NoRun("lua -f")
-- NoRun("lua -s")

print("OK")
