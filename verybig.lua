print "testando LONGARGs"

-- template to create a very big test file
prog = [[$
a = nil

while a ~= 20 do
if not a then
b = nil or {$1$
  b30009 = 65534,
  b30010 = 65535,
  b30011 = 65536,
  b30012 = 65537,
  b30013 = 16777214,
  b30014 = 16777215,
  b30015 = 16777216,
  b30016 = 16777217,
  b30017 = 4294967294,
  b30018 = 4294967295,
  b30019 = 4294967296,
  b30020 = 4294967297,
  b30021 = -65534,
  b30022 = -65535,
  b30023 = -65536,
  b30024 = -4294967297,
  b30025 = 15012.5,
  $2$
}; a=b else a = 20 end
end

assert(b.a50008 == 25004 and b["a11"] == 5.5)
assert(b.a33007 == 16503.5 and b.a50009 == 25004.5)
assert(b["b"..30024] == -4294967297)

s = 0; n=0
foreach(b, function(a,b) s=s+b; n=n+1 end)
assert(s==13977183656.5  and n==70001)

a = nil; b = nil
print'+'

function f(x) b=x end

repeat
a = f{$3$} or 10
until a and b

assert(a==10)
assert(b[1] == "a10" and b[2] == 5 and b[getn(b)-1] == "a50009")


function xxxx (x) return %b[x] end

assert(xxxx(3) == "a11")

a = nil; b=nil
xxxx = nil

return 10]]

-- functions to fill in the $n$
F = {
function ()   -- $1$
  local i = 10
  while i<=50009 do
    write('a', i, ' = ', 5+((i-10)/2), ',\n')
    i = i+1
  end
end,

function ()   -- $2$
  local i = 30026
  while i<=50009 do
    write('b', i, ' = ', 15013+((i-30026)/2), ',\n')
    i = i+1
  end
end,

function ()   -- $3$
  local i = 10
  while i<=50009 do
    write('"a', i, '", ', 5+((i-10)/2), ',\n')
    i = i+1
  end
end,
}

file = tmpname()
assert(writeto(file))
gsub(prog, "$([^$]+)", function (s)
  local n = tonumber(s)
  if not n then write(s) else F[n]() end
end)
assert(writeto())
result = dofile(file)
assert(remove(file))
print'OK'
return result

