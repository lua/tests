print('testando meta-tabelas')

X = 20; B = 30

globals(metatable({_G = globals()}, {__index=globals()}))

X = X+10
assert(X == 30 and _G.X == 20)
B = false
assert(B == false)
B = nil
assert(B == 30)

assert(metatable{} == nil)
-- assert(metatable(4) == nil)

local a, t = {10,20,30; x="10", y="20"}, {}
assert(metatable(a,t) == a)
assert(metatable(a) == t)
assert(metatable(a,nil) == a)
assert(metatable(a) == nil)
assert(metatable(a,t) == a)


function f (t, i, e)
  assert(not e)
  local p = rawget(t, "parent")
  return (p and p[i]+3), "dummy return"
end

t.__index = f

a.parent = {z=25, x=12, [4] = 24}
assert(a[1] == 10 and a.z == 28 and a[4] == 27 and a.x == "10")


function f(t, i, v) rawset(t, i, v-3) end
t.__settable = f
a[1] = 30; a.x = "101"; a[5] = 200
assert(a[1] == 27 and a.x == 98 and a[5] == 197)


local c = {}
t.__settable = c
a[1] = 10; a[2] = 20; a[3] = 90
assert(c[1] == 10 and c[2] == 20 and c[3] == 90)


do
  local a;
  a = metatable({}, {__index = metatable({},
                     {__index = metatable({},
                     {__index = function (_,n) return a[n-3]+4, "lixo" end})})})
  a[0] = 20
  for i=0,10 do
    assert(a[i*3] == 20 + i*4)
  end
end


function f (t, ...) return t, arg end
t.__call = f

do
  local x,y = a(unpack{'a', 1})
  assert(x==a and y.n==2 and y[1]=='a' and y[2]==1)
  x,y = a()
  assert(x==a and y.n==0)
end


local b = metatable({}, t)
metatable(b,t)

function f(...) cap = arg ; return arg[1] end
t.__add = f
t.__sub = f
t.__mul = f
t.__div = f
t.__unm = f
t.__pow = f

assert(b+5 == b)
assert(cap[1] == b and cap[2] == 5 and cap.n == 2)
b=b-3; assert(metatable(b) == t)
assert(5-a == 5)
assert(cap[1] == 5 and cap[2] == a and cap.n == 2)
assert(a*a == a)
assert(cap[1] == a and cap[2] == a and cap.n == 2)
assert(a/0 == a)
assert(cap[1] == a and cap[2] == 0 and cap.n == 2)
assert(-a == a)
assert(cap[1] == a and cap[2] == nil)
assert(a^4 == a)
assert(cap[1] == a and cap[2] == 4 and cap.n == 2)
assert(4^a == 4)
assert(cap[1] == 4 and cap[2] == a and cap.n == 2)


t.__lt = function (a,b,c)
  assert(c == nil)
  if type(a) == 'table' then a = a.x end
  if type(b) == 'table' then b = b.x end
 return a<b, "dummy"
end

function Op(x) return metatable({x=x}, t) end

assert(not(Op(1)<Op(1)) and (Op(1)<Op(2)) and not(Op(2)<Op(1)))
assert(not(Op('a')<Op('a')) and (Op('a')<Op('b')) and not(Op('b')<Op('a')))
assert((1<=Op(1)) and (Op(1)<=Op(2)) and not(Op(2)<=Op(1)))
assert((Op('a')<='a') and (Op('a')<=Op('b')) and not(Op('b')<=Op('a')))
assert(not(Op(1)>Op(1)) and not(Op(1)>Op(2)) and (Op(2)>Op(1)))
assert(not(Op('a')>Op('a')) and not(Op('a')>Op('b')) and (Op('b')>Op('a')))
assert((Op(1)>=Op(1)) and not(Op(1)>=2) and (Op(2)>=Op(1)))
assert((Op('a')>=Op('a')) and not('a'>=Op('b')) and (Op('b')>=Op('a')))


t.__concat = function (a,b,c)
  assert(c == nil)
  if type(a) == 'table' then a = a.val end
  if type(b) == 'table' then b = b.val end
  if A then return a..b
  else
    return metatable({val=a..b}, t)
  end
end

c = {val="c"}; metatable(c, t)
d = {val="d"}; metatable(d, t)

A = true
assert(c..d == 'cd')
assert(0 .."a".."b"..c..d.."e".."f"..(5+3).."g" == "0abcdef8g")

A = false
x = c..d
assert(metatable(x) == t and x.val == 'cd')
x = 0 .."a".."b"..c..d.."e".."f".."g"
assert(x.val == "0abcdefg")


-- teste de multiplos niveis de calls
local i
local tt = {
  __call = function (t, ...)
    i = i+1
    if t.f then return t.f(unpack(arg))
    else return arg
    end
  end
}

local a = metatable({}, tt)
local b = metatable({f=a}, tt)
local c = metatable({f=b}, tt)

i = 0
x = c(3,4,5)
assert(i == 3 and x[1] == 3 and x[3] == 5)


globals(_G); assert(metatable(globals()) == nil)

assert(X == 20)

print 'OK'

return 12
