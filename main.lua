print ("testando opcoes de lua.c")

prog = tmpname()
out = tmpname()

function prepfile (s)
  assert(writeto(prog))
  write(s)
  assert(writeto())
end

function checkout (s)
  assert(readfrom(out))
  local t = read("*a")
  assert(s == t)
  readfrom()
  assert(remove(out))
end

prepfile[[
  assert(arg.n == 3 and arg[1] == 'a' and arg[2] == 'b' and arg[3] == 'c')
]]
assert(execute(format("lua -f %s a b c", prog)))

prepfile"assert(arg==nil)"
assert(execute(format("lua %s", prog)))

prepfile[[
  print(
1, a
)
]]
assert(execute(format("lua a=nil - < %s > %s", prog, out)))
checkout("1\tnil\n")

prompt = "alo"
prepfile[[
a = 2
]]
assert(execute(format("lua _PROMPT=%s -i < %s > %s", prompt, prog, out)))
checkout(strrep(prompt, 3).."\n")
  
assert(remove(prog))
assert(not remove(out))

print("OK")
