print('testando vararg')
function f(a, ...)
  assert(type(arg) == 'table')
  assert(type(arg.n) == 'number')
  for i=1,arg.n do assert(a[i]==arg[i]) end
  return arg.n
end

function c12 (...)
  local res = (arg.n==2 and arg[1] == 1 and arg[2] == 2)
  if res then res = 55 end
  return res, 2
end

assert(f() == 0)
assert(f({1,2,3}, 1, 2, 3) == 3)
assert(f({"alo", nil, 45, f, nil}, "alo", nil, 45, f, nil) == 5)

assert(c12(1,2)==55)
a,b = call(c12, {1,2})
assert(a == 55 and b == 2)
a = call(c12, {1,2;n=2})
assert(a == 55 and b == 2)
a = call(c12, {1,2;n=1})
assert(a == nil)
assert(c12(1,2,3) == nil)
local a = call(next, {globals(),nil;n=2}, "pack")
local b,c = next(globals())
assert(a[1] == b and a[2] == c and a.n == 2)
a = call(call, {c12, {1,2}, "pack"})
assert(a.n == 2 and a[1] == 55 and a[2] == 2)
a = call(print, {'+'})
assert(a == nil)

local t = {1, 10}
function t:f (...) return self[arg[1]]+arg.n end
assert(t:f(1,4) == 3 and t:f(2) == 11)
print('+')

lim = 800
local i, a = 1, {}
while i <= lim do a[i] = i+0.3; i=i+1 end

function f(a, b, c, d, ...)
  assert(a == 1.3 and arg[1] == 5.3 and
         arg[lim-4] == lim+0.3 and not arg[lim-3])
end

function g(a,b,c)
  assert(a == 1.3 and b == 2.3 and c == 3.3)
end

call(f, a)
call(g, a)

a = {}
i = 1
while i <= lim do a[i] = i; i=i+1 end
assert(call(max, a) == lim)

print('OK')
