print("testando chamadas")
oldfb = seterrormethod(print)

function f(a,b,c) local d = 'a'; t={a,b,c,d} end

f(1,2)
assert(t[1] == 1 and t[2] == 2 and t[3] == nil and t[4] == 'a')
f(1,2,3,4)
assert(t[1] == 1 and t[2] == 2 and t[3] == 3 and t[4] == 'a')

function fat(x)
  if x <= 1 then return 1
  else return x*dostring("return fat(" .. x-1 .. ")")
  end
end

assert(dostring "dostring 'assert(fat(6)==720)' ")
a,b = dostring('return fat(5), 3')
assert(a == 120 and b == 3)
print('+')

function err_on_n (n)
  if n==0 then error(); assert(nil);
  else err_on_n (n-1); assert(nil);
  end
end

function dummy (n)
  if n > 0 then
    %assert(%dostring("err_on_n(" .. n .. ")") == nil)
    dummy(n-1)
  end
end

dummy(10)

function deep (n)
  if n>0 then deep(n-1) end
end
deep(10)
deep(200)
assert(seterrormethod(oldfb) == print)
print('+')



-- testando closures

-- operador de ponto fixo
Y = function (le)
      local a = function (f)
                  return %le(function (x) return %f(%f)(x) end)
                end
      return a(a)
    end


-- fatorial sem recursao

F = function (f)
      return function (n)
               if n == 0 then return 1
               else return n*%f(n-1) end
             end
    end

fat = Y(F)

assert(fat(0) == 1 and fat(4) == 24 and Y(F)(5)==5*Y(F)(4))

local g = function (z)
  local f = function (a,b,c,d)
    local z = %z
    return function (x,y) return %a+%b+%c+%d+%a+x+y+%z end
  end
  return f(z,z+1,z+2,z+3)
end

f = g(10)
assert(f(9, 16) == 10+11+12+13+10+9+16+10)

Y, F, f = nil
print('+')

-- testando multiplos retornos

function unpack (t, i)
  i = i or 1
  if (i <= getn(t)) then
    return t[i], unpack(t, i+1)
  end
end

function pack (...) return arg end

function equaltab (t1, t2)
  assert(getn(t1) == getn(t2))
  local i, n = 1, getn(t1)
  while i<=n do
    assert(t1[i] == t2[i])
    i = i+1
  end
end

function f() return 1,2,30,4 end
function ret2 (a,b) return a,b end

a,b,c,d = unpack{1,2,3}
assert(a==1 and b==2 and c==3 and d==nil)
a = {1,2,3,4,nil,10,'alo',nil,assert}
equaltab(pack(unpack(a)), a)
equaltab(pack(unpack(a), -1), {1,-1})
a,b,c,d = ret2(f()), ret2(f())
assert(a==1, b==1, c==2, d==30)
a,b,c,d = unpack(pack(ret2(f()), ret2(f())))
assert(a==1, b==1, c==2, d==30)

print('OK')
return deep
