print('testando tags e tag methods')

assert(tag(2) == tag(0) and tag{} == tag{})
assert(tag(function () end) == tag(function () local a = %print end))
assert(tag(function () end) ~= tag(print))
assert(tag(sin) == tag(read))
assert(type(function () end) == 'function')
assert(type(function () local a = %print end) == 'function')

for i=1,100 do newtag() end

t1 = settag({5,6,"noite"}, newtag())
tt = tag(t1)
assert(type(t1) == 'table' and tag(t1) == tt)

t2 = settag({1,2,"alo"}, newtag())
tt2 = tag(t2)

t3 = {10,2,3}

function f(t, i) return rawget(t, i)+3 end
assert(gettagmethod(tt, 'gettable') == nil)
assert(settagmethod(tt, 'gettable', f) == nil)
assert(gettagmethod(tt, 'gettable') == f)
assert(settagmethod(tt, 'gettable', f) == f)

function f(t, i, v) rawset(t, i, v-3) end
settagmethod(tt, 'settable', f)

tt1 = newtag()
copytagmethods(tt1, tt)
settag(t1, tt1)


assert(t1[1] == 8)
assert(rawget(t1, 1) == 5)
assert(t2[3] == 'alo')
assert(rawget(t1, 3) == "noite")
assert(rawget(t2, 1) == 1)

t1.x, a, b, t1.y, c = 10, 1, 1, 15
assert(rawget(t1, 'x') == 7 and rawget(t1, 'y') == 12)
assert(t1.x == 10 and t1.y == 15)
settagmethod(tt, 'gettable', nil)
copytagmethods(tt1, tt)
assert(t1.x == 7)

t2.x = 10
assert(rawget(t2, 'x') == t3[1])
assert(t2.x == 10)
print('+')

function f(t, ...) return t, arg end
settagmethod(tt1, 'function', f)

do
  local a,b = t1(next({a=1}, nil))
  assert(a==t1 and b.n==2 and b[1]=='a' and b[2]==1)
end

t2.x = 'alo'
function f (s1, s2)
  if type(s1) == 'table' then s1 = s1.x end
  if type(s2) == 'table' then s2 = s2.x end
  return s1..s2
end
settagmethod(tt2, 'concat', f)
assert(t2..'x' == 'alox')
assert('a'..t2 == 'aalo')

tt = newtag()
x = {realvalue = 0}
settag(x, tt)
assert(tag(x) == tt)

function fs (name, oldvalue, newvalue)
  oldvalue.realvalue = newvalue   -- modifica o realvalue
  y = newvalue
end
settagmethod(tt, 'setglobal', fs)

function fg (name, value)
  return value.realvalue   -- retorna valor 'real' de x
end
settagmethod(tt, 'getglobal', fg)
_G = globals()
a,x,b = 2,10,1
assert(x == 10 and a == 2 and b == 1 and y == 10 and getglobal('x') == 10 and
       type(rawget(_G, 'x')) == 'table')

setglobal('x', print)
assert(x == print and y == print and getglobal('x') == print and
       type(rawget(_G, 'x')) == 'table')

rawset(_G, 'x', 4)
x = 12
assert(x == 12 and y == print)

rawset(_G, 'x', nil); fs = nil; fg = nil;
assert(x == nil)

print('+')


do
tt = newtag()
a = {}
local b = {}
settag(a, tt)
settag(b, tt)

function f(...) cap = arg ; return arg[1] end
settagmethod(tt, 'add', f)
settagmethod(tt, 'sub', f)
settagmethod(tt, 'mul', f)
settagmethod(tt, 'div', f)
settagmethod(tt, 'unm', f)

assert(b+5 == b)
assert(cap[1] == b and cap[2] == 5 and cap[3] == 'add')
b=b-3; assert(tag(b) == tt)
assert(5-a == 5)
assert(cap[1] == 5 and cap[2] == a and cap[3] == 'sub')
assert(a*a == a)
assert(cap[1] == a and cap[2] == a and cap[3] == 'mul')
assert(a/0 == a)
assert(cap[1] == a and cap[2] == 0 and cap[3] == 'div')
assert(-a == a)
assert(cap[1] == a and cap[2] == nil and cap[3] == 'unm')

end

settagmethod(tt, 'lt', function (a,b)
  if type(a) == 'table' then a = a.x end
  if type(b) == 'table' then b = b.x end
 return a<b
end)

function Op(x) local a = {x=x}; settag(a, tt); return a end

assert(not(Op(1)<Op(1)) and (Op(1)<Op(2)) and not(Op(2)<Op(1)))
assert(not(Op('a')<Op('a')) and (Op('a')<Op('b')) and not(Op('b')<Op('a')))
assert((1<=Op(1)) and (Op(1)<=Op(2)) and not(Op(2)<=Op(1)))
assert((Op('a')<='a') and (Op('a')<=Op('b')) and not(Op('b')<=Op('a')))
assert(not(Op(1)>Op(1)) and not(Op(1)>Op(2)) and (Op(2)>Op(1)))
assert(not(Op('a')>Op('a')) and not(Op('a')>Op('b')) and (Op('b')>Op('a')))
assert((Op(1)>=Op(1)) and not(Op(1)>=2) and (Op(2)>=Op(1)))
assert((Op('a')>=Op('a')) and not('a'>=Op('b')) and (Op('b')>=Op('a')))

local conctag = function (a,b,c)
  assert(c == 'concat')
  if type(a) == 'table' then a = a.val end
  if type(b) == 'table' then b = b.val end
  if A then return a..b
  else
    local res = {val=a..b}
    settag(res, tt)
    return res
 end
end

settagmethod(tt, 'concat', conctag)
c = {val="c"}; settag(c, tt)
d = {val="d"}; settag(d, tt)

A = 1
assert(0 .."a".."b"..c..d.."e".."f"..(5+3).."g" == "0abcdef8g")

A = nil
x = 0 .."a".."b"..c..d.."e".."f".."g"
assert(x.val == "0abcdefg")


tt1 = newtag()
assert(copytagmethods(tt1, tt) == tt1)
assert(gettagmethod(tt1, 'concat') == conctag)


-- teste de coleta de tabelas, se disponivel

a = {n=0}
f = function (t) a.n=a.n+1; a[t.v] = 1 end
if not call(settagmethod, {tt1, 'gc', f}, "xp", nil) then
  print "gc tag method para tabelas desabilitado"
else
  print "testando gc tag method para tabelas"
  for i=1,1000 do
    local a = {v=i}
    settag(a, tt1)
  end
  collectgarbage()  -- must collect all those tables
  assert(a.n == 1000 and a[1] and a[1000] and not a[1001])
  settagmethod(tt1, 'gc', nil)
end


print('OK')

return 12
