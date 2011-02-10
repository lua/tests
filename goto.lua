local function errmsg (code, m)
  local st, msg = loadstring(code)
  assert(not st and string.find(msg, m))
end

errmsg([[
goto l1;
do @l1: end
]], "label 'l1'")

errmsg([[
goto l1;
local aa
@l1: print(3)
]], "local 'aa'")

errmsg([[
do local bb, cc; goto l1; end
local aa
@l1: print(3)
]], "local 'aa'")

errmsg([[  -- cannot continue a repeat-until
  repeat
    if x then goto cont end
    local xuxu = 10
    @cont:
  until xuxu < x
]], "local 'xuxu'")

local x
do
  local y = 12
  goto l1
  @l2: x = x + 1; goto l3
  @l1: x = y; goto l2
end
@l3: assert(x == 13)

do
  goto l1   -- ok to jump over local dec. to end of block
  local a = 23
  x = a
  @l1:;
end

while true do
  goto l4
  goto l5  -- ok to jump over local dec. to end of block
  goto l5  -- multiple uses of same label
  local x = 45
  @l5: ;;;
end
@l4: assert(x == 13)

if print then
  goto l1   -- ok to jump over local dec. to end of block
  local x
  @l1:
else end

do
  local a = {}
  goto l3
  @l1: a[#a + 1] = 1; goto l2;
  @l2: a[#a + 1] = 2; goto l5;
  @l3: a[#a + 1] = 3; goto l1;
  @l4: a[#a + 1] = 4; goto l6;
  @l5: a[#a + 1] = 5; goto l4;
  @l6: assert(a[1] == 3 and a[2] == 1 and a[3] == 2 and
              a[4] == 5 and a[5] == 4)
  if not a[6] then a[6] = true; goto l3 end   -- do it twice
end


--------------------------------------------------------------------------------
-- testing closing of upvalues

local function foo ()
  local a = {}
  do
  local i = 1
  local k = 0
  a[0] = function (y) k = y end
  @l1: do
    local x
    if i > 2 then goto l2 end
    a[i] = function (y) if y then x = y else return x + k end end
    i = i + 1
    goto l1
  end
  end
  @l2: return a
end

local a = foo()
a[1](10); a[2](20)
assert(a[1]() == 10 and a[2]() == 20 and a[3] == nil)
a[0](13)
assert(a[1]() == 23 and a[2]() == 33)
--------------------------------------------------------------------------------


print'OK'
