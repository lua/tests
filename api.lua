
$ifnot testC

  print('\a\n >>> testC nao ativo: pulando testes da API <<<\n\a')

$else


  print('testando API com C')

function checkstack (...) assert(arg.n == 0) end

testC"beginblock"

a,b = testC("pushnum 1; pushnum 2")
assert(a == 1 and b == 2)

testC[[
	pushnum		1
	pushnum		4
	setglobal	a
	setglobal	b
	call		checkstack
]]
assert(a == 4 and b == 1)

com = "getparam r1 0; pushreg r1"
assert(testC(com) == com)

a = testC[[
	createtable	r1
	pushreg		r1
	pushnum		4
	pushnum		8
	settable
	call		checkstack
	pushreg		r1
]]
assert(a[4] == 8)

function f (a,b,c,d)
  assert(a==b and d==nil);
  if c == nil then
    -- push(3); push(3); push(1); f(); r1 = result(1); push(r1)
    return testC[[
	pushnum		3
	pushnum		3
	pushnum		1
	call		f
	getresult	r1 1
	pushreg		r1
  ]]
  else return a
  end
end

glob = 2
assert(testC[[
	pushnum		2
	getglobal	r1, glob
	pushreg		r1
	call		f
	getresult	r1, 1
	pushreg		r1
	pushreg		r1
	call		f
	getresult	r1, 1
	pushreg		r1
]] == 3)

a = {x=45}
a,b = testC[[
	pushstring	alo
	getglobal	r0, a
	pushreg		r0
	pushstring	x
	gettable	r1
	pushreg		r1
]]
assert(a == 'alo' and b == 45)

testC[[
	pushstring	a
	createtable	r0
	pushreg		r0
	pushnum		1
	pushnum		2
	rawsettable
	pushstring	a
	pushreg		r0
	setglobal	x
	getglobal	r5, x
	pushreg		r5
	pushnum		1
	gettable	r3
	pushreg		r3
	setglobal	a
	call		f
]]		
assert(a == 2 and x[1] == 2)

a,b = testC('pushnum 1; call sin; pushnum 9; getresult r1, 1; pushreg r1')
assert(a == 9 and b == sin(1))
assert(testC('pushnum 1; call sin') == nil)

-- push(1); r3 = getglobal('x'); r1 = param(2); r5 = pop(); push(r1)
a = call(testC, {[[
	pushnum		1
	getglobal	r3, x
	getparam	r1, 1
	pop		r5
	pushreg		r1
]], "testando"}, "pack")
assert(a.n == 1 and a[1] == "testando")

-- teste de muitos locks
Arr = {}
Lim = 100
for i=1,Lim do   -- lock many objects
  Arr[i] = testC("getglobal r1, i; pushreg r1; reflock r1; pushreg r1")
end

for i=1,Lim,2 do   -- unlock half of them
  testC("getparam r1, 1; unref r1", Arr[i])
end


a = nil
a,b = testC[[
	getglobal	r0, a
	pushreg		r0
	reflock		r2
	getref		r3, r2
	pushreg		r3
	pushreg		r2
]]
assert(not a and b == -1)      -- (-1 == LUA_REFNIL)

a = testC("createtable r0, pushreg r0; reflock r1; pushreg r1")

collectgarbage()

assert(type(testC("getglobal r5, a; getref r5, r5; pushreg r5")) == 'table')


-- colect in cl the `val' of all collected tables
tt = newtag()
cl = {n=0}
function f(x)
  local udval = testC('getparam r2, 1; udataval r1, r2; pushreg r1',x)
  cl.n = cl.n+1
  cl[udval] = 1
end
testC([[getparam r1, 1; pushreg r1;
       getparam r2, 2;
       settagmethod r2, gc
]], f, tt)

-- create 3 userdatas with tag `tt' and values 1, 2, and 3
a = testC('getparam r1, 1; getparam r2, 2; pushusertag r1, r2', 1, tt);
b = testC('getparam r1, 1; getparam r2, 2; pushusertag r1, r2', 2, tt);
c = testC('getparam r1, 1; getparam r2, 2; pushusertag r1, r2', 3, tt);

-- create a userdata with tag 0 and another with tag 500 (old uses...)
x = testC('getparam r1, 1; getparam r2, 2; pushusertag r1, r2', 4, 0);
y = testC('getparam r1, 1; getparam r2, 2; pushusertag r1, r2', 5, 500);

assert(tag(x) == 0 and tag(y) == 500)

do   -- test ANYTAG (-1)
  local d = testC('getparam r1, 1; getparam r2, 2; pushusertag r1, r2', 1, -1);
  assert(tag(d) == tt and d == a)
end


d,e,f = testC[[
	getglobal	r1, a
	pushreg		r1
	reflock		r1
	pushreg		r1
	getglobal	r1, b
	pushreg		r1
	ref		r1
	pushreg		r1
	getglobal	r1, c
	pushreg		r1
	ref		r1
	pushreg		r1
]]
-- return lock[d], lock[e], lock[f]
t = call(testC, {[[
	getglobal	r1, d
	getref		r2, r1
	pushreg		r2
	getglobal	r1, e
	getref		r2, r1
	pushreg		r2
	getglobal	r1, f
	getref		r2, r1
	pushreg		r2
]]}, "pack")
assert(t[1] == a and t[2] == b and t[3] == c)
t=nil a=nil b=nil c=nil

collectgarbage()

x = testC("getparam r1, 1; getref r5, r1; pushreg r5", d)
assert(type(x) == 'userdata' and tag(x) == tt)
-- atempt to get "collected object"; must gives an error
call(testC, {"getparam r1, 1; getref r5, r1; pushreg r5" , e},
                "px", function (s) x=s end)
assert(strfind(x, "NOOBJECT"))

-- check that unlocked objects have been collected
assert(cl.n == 2 and cl[2] and cl[3] and not cl[1])

-- unref(d); unref(e); unref(f)
testC([[
	getparam	r2, 1
	getparam	r3, 2
	getparam	r4, 3
	unref		r2
	unref		r3
	unref		r4
	call		checkstack
]], d, e, f)
collectgarbage()
assert(cl.n == 3 and cl[1])

for i=2,Lim,2 do   -- unlock the other half
  testC("getparam r1, 1; unref r1", Arr[i])    -- unref(Arr[i])
end

print'+'

assert(testC("getparam r2, 1; getparam r3, 2; equal r2, r3",
              print, print) == 1)
assert(testC("getparam r2, 1; getparam r3, 2; equal r2, r3",
             'alo', "alo") == 1)
assert(testC("getparam r2, 1; getparam r3, 1; equal r2, r3", {}) == 1)
assert(testC("getparam r2, 1; getparam r3, 2; equal r2, r3",
             {}, {}) == 0)
assert(testC("getparam r2, 1; getparam r3, 2; equal r2, r3",
             print, 34) == 0)

f = testC("getparam r1, 1; pushreg r1; pushnum 8; closure testC, 2",
          "getparam r2, 1; getparam r3, 2; pushreg r2; pushreg r3")
a,b = f(4)
assert(a == 8 and b == 4)
--assert(testC"closure f, 0" == testC)


-- testando lua_nextvar
X = nil
local a,b,c,d,e,f,g = testC[[
	getglobal	r2, X
	pushnum		9
	nextvar		r2
	getresult	r5, 1
	pop		r3
	pushnum		8
	getresult	r7, 2
	nextvar		r3
	pop		r4
	getresult	r6, 1
	pushreg		r3
	pushreg		r5
	pushreg		r4
	pushreg		r6
	getresult	r9, 2
	pushreg		r7
	pushreg		r9
]]

local x,y = nextvar(nil)
assert(a==x and b==x and e==y)
x,y = nextvar(x)
assert(c==x and d==x and f==y)
assert(not g)

foreachvar(function (n) X=n end)   -- get 'last' global var
local a,b = testC[[
	pushnum		7
	pushnum		8
	pushnum		9
	getglobal	r2, X
	nextvar		r2
	pop		r3
	pushreg		r3
	pushreg		r2
]]
assert(not a and b == X)

-- testando lua_next
X = {x="alo"}
local a,b,c,d = testC[[
	pushnum		0
	pop		r1
	rawgetglobal	r0, X
	pushnum		8
	next		r0, r1
	getresult	r5, 1
	getresult	r6, 2
	pop		r1
	pushnum		9
	next		r0, r1
	pop		r1
	pushreg		r1
	pushreg		r5
	pushreg		r6
]]
assert(a==0 and b=='x' and c=='alo' and d == nil)


-- testando begin/end block
prog = strrep("beginblock ", 10000)  -- too many open blocks
a = call(testC, {prog}, "px", function (s) var=s end)
assert(a == nil and var == 'too many nested blocks')

prog = [[
	beginblock
	pushnum		1
	getglobal	r0, prog
	rawgetglobal	r1, print
	pushnum		3
	endblock
]]

prog = strrep(prog, 3000)
prog = [[
	pushnum		1
	getglobal	r5, prog
]]..prog..[[
	pushnum 	5
	pushreg		r5
]]

a,b,c = testC(prog)
assert(a==5 and b==prog and c==nil)

-- testando multiplos estados
testC("newstate 100, 1; pop r1; closestate r1")
L1, a = testC([[
	newstate	15, 0
	pop		r1
	getparam	r2, 1
	doremote	r1, r2
	pushreg		r1
]], "function f () return 'alo', 3 end; f()")
assert(type(L1) == 'userdata' and a == nil)

a, b, c = testC("getparam r1, 1; getparam r2, 2; doremote r1, r2; pushnum 1",
      L1, "return f()")
assert(a == 'alo' and b == '3' and c == 1)

a, b = testC("getparam r1, 1; getparam r2, 2; doremote r1, r2; pushnum 1",
      L1, "return tostring(1)")   -- error: `sin' is not defined
assert(a == 1 and b == nil)

testC("getparam r1, 1; closestate r1", L1)

print'+'


-- testando tag methods
testC([[getparam r1, 1; pushreg r1;
       getparam r2, 2;
       settagmethod r2, gc
]], nil, tt)   -- reset from previous tests

var = {var=12}; settag(var, tt);
settagmethod(tt, "getglobal", function (n, v) return sin(v[n]) end)
a,b,c,d = testC[[
	pushnum		1
	getglobal	r1, var
	pushreg		r1
	rawgetglobal	r2, var
	pushreg		r2
	pushnum		2
]]
assert(a == 1 and b == sin(12) and c == rawgetglobal"var" and d == 2)


testC('endblock; pushstring OK; call print')




-- function to show all string tables
function showstringtables ()
  local i = 1
  local n, s
  while 1 do
    n, s = querystr(i);
    if not n then break end
    print("\n\t", n, s)
    for j=1,s do
      local str = call(querystr, {i,j}, "p")
      tinsert(str, 1, j)
      call(print, str)
    end
    i = i+1
  end
end

--showstringtables()
$end
