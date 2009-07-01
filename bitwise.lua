print("testing bitwise operations")

assert(bit.band() == bit.bnot(0))
assert(bit.btest() == true)
assert(bit.bor() == 0)
assert(bit.bxor() == 0)

assert(bit.band() == bit.band(0xffffffff))
assert(bit.band(1,2) == 0)

assert(bit.brotate(0, -1) == 0)
assert(bit.brotate(0, 7) == 0)
assert(bit.brotate(0x12345678, 4) == 0x23456781)
assert(bit.brotate(0x12345678, -8) == 0x78123456)
assert(bit.brotate(0xaaaaaaaa, 2) == 0xaaaaaaaa)
assert(bit.brotate(0xaaaaaaaa, -2) == 0xaaaaaaaa)
for i = -50, 50 do
  assert(bit.brotate(0x89abcdef, i) == bit.brotate(0x89abcdef, i%32))
end

assert(bit.bshift(0x12345678, 4) == 0x23456780)
assert(bit.bshift(0x12345678, 8) == 0x34567800)
assert(bit.bshift(0x12345678, -4) == 0x01234567)
assert(bit.bshift(0x12345678, -8) == 0x00123456)

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
  assert(bit.brotate(b, 32) == b)
  assert(bit.bshift(bit.bshift(b, -4), 4) == bit.band(b, bit.bnot(0xf)))
  for i = -40, 40 do
    assert(bit.bshift(b, i) == math.floor((b * 2^i) % 2^32))
  end
end

print("+")

assert(not pcall(bit.band, {}))
assert(not pcall(bit.bnot, "a"))
assert(not pcall(bit.bshift, 45))
assert(not pcall(bit.bshift, 45, print))

print'OK'
