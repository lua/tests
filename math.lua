print("testando reais e bib. matematica")

do
  local a,b,c = "2", " 3e0 ", " 10  "
  assert(a+b == 5 and -b == -3 and b+"2" == 5 and "10"-c == 0)
  assert(type(a) == 'string' and type(b) == 'string' and type(c) == 'string')
  assert(a == "2" and b == " 3e0 " and c == " 10  ")
end


function f(...) if arg.n == 1 then return arg[1] else return "***" end end

assert(tonumber{} == nil)
assert(tonumber'+0.01' == 1/100 and tonumber'+.01' == 0.01 and
       tonumber'.01' == 0.01    and tonumber'-1.' == -1 and
       tonumber'+1.' == 1)
assert(tonumber'+ 0.01' == nil and tonumber'+.e1' == nil and
       tonumber'1e' == nil     and tonumber'1.0e+' == nil and
       tonumber'.' == nil)
assert(tonumber('-12') == -10-2)
assert(tonumber('-1.2e2') == - - -120)
assert(f(tonumber('1  a')) == nil)
assert(f(tonumber('e1')) == nil)
assert(f(tonumber('e  1')) == nil)
assert(f(tonumber(' 3.4.5 ')) == nil)
assert(f(tonumber('')) == nil)
assert(f(tonumber('', 8)) == nil)
assert(f(tonumber('  ')) == nil)
assert(f(tonumber('  ', 9)) == nil)
assert(f(tonumber('99', 8)) == nil)
assert(tonumber('  1010  ', 2) == 10)
assert(tonumber('10', 36) == 36)
--assert(tonumber('\n  -10  \n', 36) == -36)
--assert(tonumber('-fFfa', 16) == -(10+(16*(15+(16*(15+(16*15)))))))
assert(tonumber('fFfa', 15) == nil)
--assert(tonumber(strrep('1', 42), 2) + 1 == 2^42)
assert(tonumber(strrep('1', 32), 2) + 1 == 2^32)
--assert(tonumber('-fffffFFFFF', 16)-1 == -2^40)
assert(tonumber('ffffFFFF', 16)+1 == 2^32)

assert(1.1 == 1.+.1)
assert(100.0 == 1E2 and .01 == 1e-2)
assert(1111111111111111-1111111111111110== 1000.00e-03)
--     1234567890123456
assert(1.1 == '1.'+'.1')
assert('1111111111111111'-'1111111111111110' == tonumber"  +0.001e+3 \n\t")

function eq (a,b,limit)
  if not limit then limit = 10E-10 end
  return abs(a-b) <= limit
end

assert(0.1e-30 > 0.9E-31 and 0.9E30 < 0.1e31)

assert(0.123456 > 0.123455)

assert(tonumber('+1.23E30') == 1.23*10^30)

-- testando operadores de ordem
assert(not(1<1) and (1<2) and not(2<1))
assert(not('a'<'a') and ('a'<'b') and not('b'<'a'))
assert((1<=1) and (1<=2) and not(2<=1))
assert(('a'<='a') and ('a'<='b') and not('b'<='a'))
assert(not(1>1) and not(1>2) and (2>1))
assert(not('a'>'a') and not('a'>'b') and ('b'>'a'))
assert((1>=1) and not(1>=2) and (2>=1))
assert(('a'>='a') and not('a'>='b') and ('b'>='a'))

assert(eq(sin(-9.8)^2 + cos(-9.8)^2, 1))
assert(eq(sin(90), 1) and eq(cos(90), 0))
assert(eq(atan(1), 45) and eq(acos(0), 90) and eq(asin(1), 90))
assert(eq(tan(deg(PI/4)), 1) and eq(rad(90), PI/2))
assert(abs(-10) == 10)
assert(eq(atan2(1,0), 90))
assert(ceil(4.5) == 5.0)
assert(floor(4.5) == 4.0)
assert(mod(10,3) == 1)
assert(eq(sqrt(10)^2, 10))
assert(eq(log10(2), log(2)/log(10)))
assert(eq(exp(0), 1))

assert(tonumber(' 1.3e-2 ') == 1.3e-2)
assert(tonumber(' -1.00000000000001 ') == -1.00000000000001)

-- testando limites de constantes
-- 2^23 = 8388608
assert(8388609 + -8388609 == 0)
assert(8388608 + -8388608 == 0)
assert(8388607 + -8388607 == 0)

if _soft then return end

f = tmpfile()
assert(f)
write(f, "a = {")
i = 1
repeat
  write(f, "{", sin(i), ", ", cos(i), ", ", i/3, "},\n")
  i=i+1
until i > 1000
write(f, "}")
seek(f, "set", 0)
dostring(read(f, '*a'))
assert(closefile(f))

assert(eq(a[300][1], sin(300)))
assert(eq(a[600][1], sin(600)))
assert(eq(a[500][2], cos(500)))
assert(eq(a[800][2], cos(800)))
assert(eq(a[200][3], 200/3))
assert(eq(a[1000][3], 1000/3, 0.001))
print('+')

require "checktable"
stat(a)

a = nil

randomseed(date'%S')

local i = 0
local Max = 0
local Min = 2
repeat
  local t = random()
  Max = max(Max, t)
  Min = min(Min, t)
  i=i+1
  flag = eq(Max, 1, 0.001) and eq(Min, 0, 0.001)
until flag or i>10000
assert(0 <= Min and Max<1)
assert(flag);

for i=1,10 do
  local t = random(5)
  assert(1 <= t and t <= 5)
end

i = 0
Max = -200
Min = 200
repeat
  local t = random(-10,0)
  Max = max(Max, t)
  Min = min(Min, t)
  i=i+1
  flag = (Max == 0 and Min == -10)
until flag or i>10000
assert(-10 <= Min and Max<=0)
assert(flag);


print('OK')
