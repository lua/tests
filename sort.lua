print"verificando sort"


function check (a, f)
  f = f or function (x,y) return x<y end;
  for n=getn(a),2,-1 do
    assert(not f(a[n], a[n-1]))
  end
end

a = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep",
     "Oct", "Nov", "Dec"}

sort(a)
check(a)


limit = 30000

a = {}
for i=1,limit do
  a[i] = random()
end

local x = clock()
sort(a)
print(format("Sorting %d elements in %.2f sec.", limit, clock()-x))
check(a)

x = clock()
sort(a)
print(format("Re-sorting %d elements in %.2f sec.", limit, clock()-x))
check(a)

a = {}
for i=1,limit do
  a[i] = random()
end

x = clock(); i=0
sort(a, function(x,y) i=i+1; return y<x end)
print(format("Invert-sorting other %d elements in %.2f sec., with %i comparisons",
      limit, clock()-x, i))
check(a, function(x,y) return y<x end)


sort{}  -- array vazio

a.n = 2
sort(a)  -- so' 2 primeiros elementos
assert(a[1] <= a[2] and a.n == 2)
for i=3,limit-1 do
  assert(a[i] >= a[i+1])
end

a = {n=limit}
x = clock();
sort(a, function(x,y) return nil end)
print(format("Sorting %d equal elements in %.2f sec.", limit, clock()-x))
check(a, function(x,y) return nil end)
foreach(a, function(i,v) assert (i=='n' and v==limit) end)

a = {"álo", "\0first :-)", "alo", "then this one", "45", "and a new"}
sort(a)
check(a)

sort(a, function (x, y)
          dostring(format("a[%q] = ''", x))
          collectgarbage()
          return x<y
        end)


tt = newtag()
a = {}
for i=1,10 do  a[i] = {val=random(100)}; settag(a[i], tt); end
f = function (a,b) return a.val < b.val end
settagmethod(tt, 'lt', f)
sort(a)
check(a, f)

print"OK"
