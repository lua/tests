
if T==nil then
  print('\a\n >>> tests.c nao ativo: pulando testes de opcodes <<<\n\a')
  return
end
print "testando geracao de codigo/otimizacoes"


function check (f, ...)
  local c = T.listcode(f)
  for i=1, arg.n do
    -- print(arg[i], c[i])
    assert(strfind(c[i], '- '..arg[i]..' *%d'))
  end
  assert(c[arg.n+2] == nil)
end


function checkequal (a, b)
  a = T.listcode(a)
  b = T.listcode(b)
  for i = 1, getn(a) do
    a[i] = gsub(a[i], '%b()', '')   -- remove line number
    b[i] = gsub(b[i], '%b()', '')   -- remove line number
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


-- single return
check (function (a,b,c) return a end, 'RETURN')


-- infinite loops
check(function () while true do local a = -1 end end,
'JMP', 'LOADK', 'JMP', 'RETURN')

check(function () while 1 do local a = -1 end end,
'JMP', 'LOADK', 'JMP', 'RETURN')

check(function () repeat local x = 1 until false end,
'LOADK', 'JMP', 'RETURN')

check(function () repeat local x = 1 until nil end,
'LOADK', 'JMP', 'RETURN')


-- not
check(function () return not not nil end, 'LOADBOOL', 'RETURN')
check(function () return not not false end, 'LOADBOOL', 'RETURN')
check(function () return not not true end, 'LOADBOOL', 'RETURN')
check(function () return not not 1 end, 'LOADBOOL', 'RETURN')

-- direct access to locals
check(function ()
  local a,b,c,d
  a = b*2
  c[4], a[b] = -((a + d/-20.5 - a[b]) ^ a.x), b
end,
  'LOADNIL',
  'MUL',
  'DIV', 'ADD', 'GETTABLE', 'SUB', 'GETTABLE', 'POW',
    'UNM', 'SETTABLE', 'SETTABLE', 'RETURN')

check(function ()
  local a,b,c
  b[c], a = c, b
  b[a], a = c, b
  a, b = c, a
  a = a
end, 'LOADNIL',
  'MOVE', 'MOVE', 'SETTABLE',
  'MOVE', 'MOVE', 'MOVE', 'SETTABLE',
  'MOVE', 'MOVE', 'MOVE',
  -- no code for a = a
  'RETURN')


-- x == nil , x ~= nil
checkequal(function () if (a==nil) then a=1 end; if a~=nil then a=1 end end,
           function () if (a==9) then a=1 end; if a~=9 then a=1 end end)

check(function () if a==nil then a=1 end end,
'GETGLOBAL', 'EQ', 'JMP', 'LOADK', 'SETGLOBAL', 'RETURN')

-- de morgan
checkequal(function () local a; if not (a or b) then b=a end end,
           function () local a; if (not a and not b) then b=a end end)

checkequal(function (l) local a; return 0 <= a and a <= l end,
           function (l) local a; return not (not(a >= 0) or not(a <= l)) end)


print 'OK'

