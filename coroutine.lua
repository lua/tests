print "testing coroutines"

local f

local main, ismain = coroutine.running()
assert(type(main) == "thread" and ismain)
assert(not coroutine.resume(main))
assert(not pcall(coroutine.yield))


-- tests for global environment

local function foo (a)
  setfenv(0, a)
  coroutine.yield(getfenv())
  assert(getfenv(0) == a)
  assert(getfenv(1) == _G)
  assert(getfenv(loadstring"") == a)
  return getfenv()
end

f = coroutine.wrap(foo)
local a = {}
assert(f(a) == _G)
local a,b = pcall(f)
assert(a and b == _G)


-- tests for multiple yield/resume arguments

local function eqtab (t1, t2)
  assert(table.getn(t1) == table.getn(t2))
  for i,v in ipairs(t1) do
    assert(t2[i] == v)
  end
end

_G.x = nil   -- declare x
function foo (a, ...)
  local x, y = coroutine.running()
  assert(x == f and y == false)
  assert(coroutine.status(f) == "running")
  local arg = {...}
  for i=1,table.getn(arg) do
    _G.x = {coroutine.yield(unpack(arg[i]))}
  end
  return unpack(a)
end

f = coroutine.create(foo)
assert(type(f) == "thread" and coroutine.status(f) == "suspended")
assert(string.find(tostring(f), "thread"))
local s,a,b,c,d
s,a,b,c,d = coroutine.resume(f, {1,2,3}, {}, {1}, {'a', 'b', 'c'})
assert(s and a == nil and coroutine.status(f) == "suspended")
s,a,b,c,d = coroutine.resume(f)
eqtab(_G.x, {})
assert(s and a == 1 and b == nil)
s,a,b,c,d = coroutine.resume(f, 1, 2, 3)
eqtab(_G.x, {1, 2, 3})
assert(s and a == 'a' and b == 'b' and c == 'c' and d == nil)
s,a,b,c,d = coroutine.resume(f, "xuxu")
eqtab(_G.x, {"xuxu"})
assert(s and a == 1 and b == 2 and c == 3 and d == nil)
assert(coroutine.status(f) == "dead")
s, a = coroutine.resume(f, "xuxu")
assert(not s and string.find(a, "dead") and coroutine.status(f) == "dead")


-- yields in tail calls
local function foo (i) return coroutine.yield(i) end
f = coroutine.wrap(function ()
  for i=1,10 do
    assert(foo(i) == _G.x)
  end
  return 'a'
end)
for i=1,10 do _G.x = i; assert(f(i) == i) end
_G.x = 'xuxu'; assert(f('xuxu') == 'a')

-- recursive
function pf (n, i)
  coroutine.yield(n)
  pf(n*i, i+1)
end

f = coroutine.wrap(pf)
local s=1
for i=1,10 do
  assert(f(1, 1) == s)
  s = s*i
end

-- sieve
function gen (n)
  return coroutine.wrap(function ()
    for i=2,n do coroutine.yield(i) end
  end)
end


function filter (p, g)
  return coroutine.wrap(function ()
    while 1 do
      local n = g()
      if n == nil then return end
      if math.fmod(n, p) ~= 0 then coroutine.yield(n) end
    end
  end)
end

local x = gen(100)
local a = {}
while 1 do
  local n = x()
  if n == nil then break end
  table.insert(a, n)
  x = filter(n, x)
end

assert(table.getn(a) == 25 and a[table.getn(a)] == 97)


-- yielding across C boundaries

co = coroutine.wrap(function()
       assert(not pcall(table.sort,{1,2,3}, coroutine.yield))
       coroutine.yield(20)
       return 30
     end)

assert(co() == 20)
assert(co() == 30)


local f = function (s, i) return coroutine.yield(i) end

local f1 = coroutine.wrap(function ()
             return xpcall(pcall, function (...) return ... end,
               function ()
                 local s = 0
                 for i in f, nil, 1 do pcall(function () s = s + i end) end
                 error({s})
               end)
           end)

f1()
for i = 1, 10 do assert(f1(i) == i) end
local r1, r2, v = f1(nil)
assert(r1 and not r2 and v[1] ==  (10 + 1)*10/2)


function f (a, b) a = coroutine.yield(a);  error{a + b} end
function g(x) return x[1]*2 end

co = coroutine.wrap(function ()
       coroutine.yield(xpcall(f, g, 10, 20))
     end)

assert(co() == 10)
r, msg = co(100)
assert(not r and msg == 240)


-- errors in coroutines
function foo ()
  assert(debug.getinfo(1).currentline == debug.getinfo(foo).linedefined + 1)
  assert(debug.getinfo(2).currentline == debug.getinfo(goo).linedefined)
  coroutine.yield(3)
  error(foo)
end

function goo() foo() end
x = coroutine.wrap(goo)
assert(x() == 3)
local a,b = pcall(x)
assert(not a and b == foo)

x = coroutine.create(goo)
a,b = coroutine.resume(x)
assert(a and b == 3)
a,b = coroutine.resume(x)
assert(not a and b == foo and coroutine.status(x) == "dead")
a,b = coroutine.resume(x)
assert(not a and string.find(b, "dead") and coroutine.status(x) == "dead")


-- co-routines x for loop
function all (a, n, k)
  if k == 0 then coroutine.yield(a)
  else
    for i=1,n do
      a[k] = i
      all(a, n, k-1)
    end
  end
end

local a = 0
for t in coroutine.wrap(function () all({}, 5, 4) end) do
  a = a+1
end
assert(a == 5^4)


-- access to locals of collected corroutines
local C = {}; setmetatable(C, {__mode = "kv"})
local x = coroutine.wrap (function ()
            local a = 10
            local function f () a = a+10; return a end
            while true do
              a = a+1
              coroutine.yield(f)
            end
          end)

C[1] = x;

local f = x()
assert(f() == 21 and x()() == 32 and x() == f)
x = nil
collectgarbage()
assert(C[1] == nil)
assert(f() == 43 and f() == 53)


-- old bug: attempt to resume itself

function co_func (current_co)
  assert(coroutine.running() == current_co)
  assert(coroutine.resume(current_co) == false)
  assert(coroutine.resume(current_co) == false)
  return 10
end

local co = coroutine.create(co_func)
local a,b = coroutine.resume(co, co)
assert(a == true and b == 10)
assert(coroutine.resume(co, co) == false)
assert(coroutine.resume(co, co) == false)


-- attempt to resume 'normal' coroutine
co1 = coroutine.create(function () return co2() end)
co2 = coroutine.wrap(function ()
        assert(coroutine.status(co1) == 'normal')
        assert(not coroutine.resume(co1))
        coroutine.yield(3)
      end)

a,b = coroutine.resume(co1)
assert(a and b == 3)
assert(coroutine.status(co1) == 'dead')

-- infinite recursion of coroutines
a = function(a) coroutine.wrap(a)(a) end
assert(not pcall(a, a))


-- access to locals of erroneous coroutines
local x = coroutine.create (function ()
            local a = 10
            _G.f = function () a=a+1; return a end
            error('x')
          end)

assert(not coroutine.resume(x))
-- overwrite previous position of local `a'
assert(not coroutine.resume(x, 1, 1, 1, 1, 1, 1, 1))
assert(_G.f() == 11)
assert(_G.f() == 12)


if not T then
  (Message or print)('\a\n >>> testC not active: skipping yield/hook tests <<<\n\a')
else
  print "testing yields inside hooks"

  local turn
  
  function fact (t, x)
    assert(turn == t)
    if x == 0 then return 1
    else return x*fact(t, x-1)
    end
  end

  local A,B,a,b = 0,0,0,0

  local x = coroutine.create(function ()
    T.setyhook("", 2)
    A = fact("A", 10)
  end)

  local y = coroutine.create(function ()
    T.setyhook("", 3)
    B = fact("B", 11)
  end)

  while A==0 or B==0 do
    if A==0 then turn = "A"; assert(T.resume(x)) end
    if B==0 then turn = "B"; assert(T.resume(y)) end
  end

  assert(B/A == 11)
end


-- leaving a pending coroutine open
_X = coroutine.wrap(function ()
      local a = 10
      local x = function () a = a+1 end
      coroutine.yield()
    end)

_X()


-- coroutine environments
co = coroutine.create(function ()
       coroutine.yield(getfenv(0))
       return loadstring("return a")()
     end)

a = {a = 15}
debug.setfenv(co, a)
assert(debug.getfenv(co) == a)
assert(select(2, coroutine.resume(co)) == a)
assert(select(2, coroutine.resume(co)) == a.a)


-- bug (stack overflow)
local j = 2^9
local lim = 1000000    -- (C stack limit; assume 32-bit machine)
for _, j in ipairs{lim - 10, lim - 5, lim - 1, lim, lim + 1} do
  co = coroutine.create(function()
         t = {}
         for i = 1, j do t[i] = i end
         return unpack(t)
       end)
  local r, msg = coroutine.resume(co)
  assert(not r)
end


assert(coroutine.running() == main)

print"+"


print"testing yields inside metamethods"

local mt = {
  __eq = function(a,b) coroutine.yield(nil, "eq"); return a.x == b.x end,
  __lt = function(a,b) coroutine.yield(nil, "lt"); return a.x < b.x end,
  __le = function(a,b) coroutine.yield(nil, "le"); return a - b <= 0 end,
  __add = function(a,b) coroutine.yield(nil, "add"); return a.x + b.x end,
  __sub = function(a,b) coroutine.yield(nil, "sub"); return a.x - b.x end,
  __concat = function(a,b)
               coroutine.yield(nil, "concat");
               a = type(a) == "table" and a.x or a
               b = type(b) == "table" and b.x or b
               return a .. b
             end,
  __index = function (t,k) coroutine.yield(nil, "idx"); return t.k[k] end,
  __newindex = function (t,k,v) coroutine.yield(nil, "nidx"); t.k[k] = v end,
}


local function new (x)
  return setmetatable({x = x, k = {}}, mt)
end


local a = new(10)
local b = new(12)
local c = new"hello"

local function run (f, t)
  local i = 1
  local c = coroutine.wrap(f)
  while true do
    local res, stat = c()
    if res then assert(t[i] == nil); return res, t end
    assert(stat == t[i])
    i = i + 1
  end
end


assert(run(function () if (a>=b) then return '>=' else return '<' end end,
       {"le", "sub"}) == "<")
-- '<=' using '<'
mt.__le = nil
assert(run(function () if (a<=b) then return '<=' else return '>' end end,
       {"lt"}) == "<=")
assert(run(function () if (a==b) then return '==' else return '~=' end end,
       {"eq"}) == "~=")

-- assert(run(function () return a..b end, {"concat"}) == "1012")

assert(run(function() return a .. b .. c .. a end,
       {"concat", "concat", "concat"}) == "1012hello10")

assert(run(function() return "a" .. "b" .. a .. "c" .. c .. b .. "x" end,
       {"concat", "concat", "concat"}) == "ab10chello12x")

assert(run(function ()
             a.BB = print
             return a.BB
           end, {"nidx", "idx"}) == print)


print"+"

print"testing yields inside 'for' iterators"

local f = function (s, i)
      if i%2 == 0 then coroutine.yield(nil, "for") end
      if i < s then return i + 1 end
    end

assert(run(function ()
             local s = 0
             for i in f, 4, 0 do s = s + i end
             return s
           end, {"for", "for", "for"}) == 10)


-- yields inside foreachi (testing context preservation)
function f (a,b)
  coroutine.yield(a, new(a) + b)
end

t = {new(10),new(20),new(30)}

co = coroutine.wrap(function() table.foreachi(t, f) end)

for i = 1,#t do
  local k,v,x = co()
  assert(k == nil and v == "add")
  local k,v,x = co()
  assert(k == i and v == t[i].x + i and x == nil)
end

print'OK'
