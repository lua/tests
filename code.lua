
if T==nil then
  print('\a\n >>> tests.c nao ativo: pulando testes de opcodes <<<\n\a')
  return
end
print "testando geracao de codigo/otimizacoes"


function check (f, ...)
  local c = T.listcode(f)
  for i=1, arg.n do
    -- print(arg[i], c[i])
    assert(strfind(c[i], arg[i]))
  end
  assert(c[arg.n+2] == nil)
end


function checkequal (a, b)
  a = T.listcode(a)
  b = T.listcode(b)
  for i = 1, getn(a) do
    -- print(a[i], b[i])
    assert(a[i] == b[i])
  end
end


-- some basic instructions
check(function ()
  (function () end){f()}
end, 'CLOSURE', 'NEWTABLE', 'GETGLOBAL', 'CALL', 'SETLISTO', 'CALL', 'RETURN')


-- sequence of LOADNILs
check(function ()
  local a,b,c
  local d; local e;
  a = nil; d=nil
end, 'LOADNIL')


-- single return  (no more tests; optimization incompatible with CLOSE)
-- check (function (a,b,c) return a end, 'RETURN')


-- direct access to locals
check(function ()
  local a,b,c,d
  a = b*2
  c[4], a[b] = -((a + d/-20.5 - a[b]) ^ a.x), b
end,
  'LOADNIL',
  'MUL',
  'DIV', 'ADD', 'GETTABLE', 'SUB', 'GETTABLE', 'POW',
    'UNM', 'SETTABLE', 'SETTABLE')

-- x == nil , x ~= nil
checkequal(function () if (a==nil) then a=1 end; if a~=nil then a=1 end end,
           function () if (not a) then a=1 end; if a then a=1 end end)

-- de morgan
checkequal(function () local a; if not (a or b) then b=a end end,
           function () local a; if (not a and not b) then b=a end end)

checkequal(function (l) local a; return 0 <= a and a <= l end,
           function (l) local a; return not (a < 0 or a > l) end)


print 'OK'

