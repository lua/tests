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
  s = call(format, arg)
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
  assert(x.n == 7 and x[1] == '-s30' and x[x.n] == arg[3])
]]
RUN("lua -s30 -c -f %s a b c", prog)

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

prompt = "alo"
prepfile[[ --
a = 2
]]
RUN("lua _PROMPT=%s -i < %s > %s", prompt, prog, out)
checkout(strrep(prompt, 3).."\n")

prepfile[[ -- \
function f(x) \
  return x+1    \
  -- \\
end
print(f(10))]]
RUN("lua -q < %s > %s", prog, out)
checkout("11\n\n")
  
prepfile[[#comment in 1st line without \n at the end]]
RUN("lua %s", prog)

-- close Lua with an open file
prepfile(format([[writeto(%q); write('alo')]], out))
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
