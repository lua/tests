print("testing bitwise operations")

assert(bit.band() == bit.bnot(0))
assert(bit.btest() == true)
assert(bit.bor() == 0)
assert(bit.bxor() == 0)

assert(bit.band() == bit.band(0xffffffff))
assert(bit.band(1,2) == 0)

assert(bit.rol(0, -1) == 0)
assert(bit.rol(0, 7) == 0)
assert(bit.rol(0x12345678, 4) == 0x23456781)
assert(bit.ror(0x12345678, -4) == 0x23456781)
assert(bit.rol(0x12345678, -8) == 0x78123456)
assert(bit.ror(0x12345678, 8) == 0x78123456)
assert(bit.rol(0xaaaaaaaa, 2) == 0xaaaaaaaa)
assert(bit.rol(0xaaaaaaaa, -2) == 0xaaaaaaaa)
for i = -50, 50 do
  assert(bit.rol(0x89abcdef, i) == bit.rol(0x89abcdef, i%32))
end

assert(bit.lshift(0x12345678, 4) == 0x23456780)
assert(bit.lshift(0x12345678, 8) == 0x34567800)
assert(bit.lshift(0x12345678, -4) == 0x01234567)
assert(bit.lshift(0x12345678, -8) == 0x00123456)
assert(bit.rshift(0x12345678, 4) == 0x01234567)
assert(bit.rshift(0x12345678, 8) == 0x00123456)

print("+")
-- some special cases
local c = {0, 1, 2, 3, 10, 0x80000000, 0xaaaaaaaa, 0x55555555,
           0xffffffff, 0x7fffffff}

for _, b in pairs(c) do
  assert(bit.band(b) == b)
  assert(bit.band(b, b) == b)
  assert(bit.btest(b, b) == (b ~= 0))
  assert(bit.band(b, b, b) == b)
  assert(bit.btest(b, b, b) == (b ~= 0))
  assert(bit.band(b, bit.bnot(b)) == 0)
  assert(bit.bor(b, bit.bnot(b)) == bit.bnot(0))
  assert(bit.bor(b) == b)
  assert(bit.bor(b, b) == b)
  assert(bit.bor(b, b, b) == b)
  assert(bit.bxor(b) == b)
  assert(bit.bxor(b, b) == 0)
  assert(bit.bxor(b, 0) == b)
  assert(bit.bnot(b) ~= b)
  assert(bit.bnot(bit.bnot(b)) == b)
  assert(bit.bnot(b) == 2^32 - 1 - b)
  assert(bit.rol(b, 32) == b)
  assert(bit.ror(b, 32) == b)
  assert(bit.lshift(bit.lshift(b, -4), 4) == bit.band(b, bit.bnot(0xf)))
  assert(bit.rshift(bit.rshift(b, 4), -4) == bit.band(b, bit.bnot(0xf)))
  for i = -40, 40 do
    assert(bit.lshift(b, i) == math.floor((b * 2^i) % 2^32))
  end
end

print("+")

assert(not pcall(bit.band, {}))
assert(not pcall(bit.bnot, "a"))
assert(not pcall(bit.lshift, 45))
assert(not pcall(bit.lshift, 45, print))
assert(not pcall(bit.rshift, 45, print))

print'OK'
