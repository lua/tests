# teste de comentario especial na 1a linha

print ("testando opcoes de lua.c")

prog = tmpname()
out = tmpname()

progname = getargs()[0]
print(progname)

function prepfile (s)
  assert(writeto(prog))
  write(s)
  assert(writeto())
end

function checkout (s)
  assert(readfrom(out))
  local t = read("*a")
  if s then assert(s == t) end
  readfrom()
  assert(remove(out))
  return t
end

function RUN (...)
  s = call(format, arg)
  s = gsub(s, "lua", progname)
  assert(execute(s) == 0)
end


prepfile[[
  assert(arg.n == 3 and arg[1] == 'a' and arg[2] == 'b' and arg[3] == 'c')
  x = getargs()
  assert(x.n == 7 and x[1] == '-s20' and x[x.n] == arg[3])
]]
RUN("lua -s20 -d -f %s a b c", prog)

prepfile"assert(arg==nil)"
RUN("lua %s", prog)

prepfile""
RUN("lua < %s > %s", prog, out)
checkout("")

-- some "shells" (e.g. command.com) do not understand the quotes around
-- print(1); others require them...
RUN("lua -e 'print(1)' a=b -e 'print(a)' > %s", out)
checkout("1\nb\n")

prepfile[[
  print(
1, a
)
]]
RUN("lua a=nil - < %s > %s", prog, out)
checkout("1\tnil\n")

prompt = "alo"
prepfile[[
a = 2
]]
RUN("lua _PROMPT=%s -i < %s > %s", prompt, prog, out)
checkout(strrep(prompt, 3).."\n")
  
assert(remove(prog))
assert(not remove(out))

RUN("lua -v")
print("OK")
