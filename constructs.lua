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


print'OK'
