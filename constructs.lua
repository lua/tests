print "testando sintaxe"

x = {}; x={;}; x={x=1;}; x={;x=1}; x={1}; x={1;}; x={;1}; x={1;x=1}; x={x=1;1}

function f (i)
  if i < 10 then return 'a'
  elseif i < 20 then return 'b'
  elseif i < 30 then return 'c'
  else return 'd'
  end
end

assert(f(3) == 'a' and f(12) == 'b' and f(26) == 'c' and f(100) == 'd')

function f (i)
  return if i < 10 then 'a'
  elseif i < 20 then 'b'
  elseif i < 30 then 'c'
  end, 10
end

assert(f(3) == 'a' and f(12) == 'b' and f(26) == 'c')
a,b=(f(100))
assert(a==nil and b==10)


print'OK'
