print("testing bitwise operations")

assert(bit32.AND() == bit32.NOT(0))
assert(bit32.TEST() == true)
assert(bit32.OR() == 0)
assert(bit32.XOR() == 0)

assert(bit32.AND() == bit32.AND(0xffffffff))
assert(bit32.AND(1,2) == 0)


-- out-of-range numbers
assert(bit32.AND(-1) == 0xffffffff)
assert(bit32.AND(2^33 - 1) == 0xffffffff)
assert(bit32.AND(-2^33 - 1) == 0xffffffff)
assert(bit32.AND(2^33 + 1) == 1)
assert(bit32.AND(-2^33 + 1) == 1)
assert(bit32.AND(-2^40) == 0)
assert(bit32.AND(2^40) == 0)
assert(bit32.AND(-2^40 - 2) == 0xfffffffe)
assert(bit32.AND(2^40 - 4) == 0xfffffffc)

assert(bit32.ROL(0, -1) == 0)
assert(bit32.ROL(0, 7) == 0)
assert(bit32.ROL(0x12345678, 4) == 0x23456781)
assert(bit32.ROR(0x12345678, -4) == 0x23456781)
assert(bit32.ROL(0x12345678, -8) == 0x78123456)
assert(bit32.ROR(0x12345678, 8) == 0x78123456)
assert(bit32.ROL(0xaaaaaaaa, 2) == 0xaaaaaaaa)
assert(bit32.ROL(0xaaaaaaaa, -2) == 0xaaaaaaaa)
for i = -50, 50 do
  assert(bit32.ROL(0x89abcdef, i) == bit32.ROL(0x89abcdef, i%32))
end

assert(bit32.SHL(0x12345678, 4) == 0x23456780)
assert(bit32.SHL(0x12345678, 8) == 0x34567800)
assert(bit32.SHL(0x12345678, -4) == 0x01234567)
assert(bit32.SHL(0x12345678, -8) == 0x00123456)
assert(bit32.SHL(0x12345678, 32) == 0)
assert(bit32.SHL(0x12345678, -32) == 0)
assert(bit32.SHR(0x12345678, 4) == 0x01234567)
assert(bit32.SHR(0x12345678, 8) == 0x00123456)
assert(bit32.SHR(0x12345678, 32) == 0)
assert(bit32.SHR(0x12345678, -32) == 0)
assert(bit32.SAR(0x12345678, 0) == 0x12345678)
assert(bit32.SAR(0x12345678, 1) == 0x12345678 / 2)
assert(bit32.SAR(0x12345678, -1) == 0x12345678 * 2)
assert(bit32.SAR(-1, 1) == 0xffffffff)
assert(bit32.SAR(-1, 24) == 0xffffffff)
assert(bit32.SAR(-1, 32) == 0xffffffff)
assert(bit32.SAR(-1, -1) == (-1 * 2) % 2^32)

print("+")
-- some special cases
local c = {0, 1, 2, 3, 10, 0x80000000, 0xaaaaaaaa, 0x55555555,
           0xffffffff, 0x7fffffff}

for _, b in pairs(c) do
  assert(bit32.AND(b) == b)
  assert(bit32.AND(b, b) == b)
  assert(bit32.TEST(b, b) == (b ~= 0))
  assert(bit32.AND(b, b, b) == b)
  assert(bit32.TEST(b, b, b) == (b ~= 0))
  assert(bit32.AND(b, bit32.NOT(b)) == 0)
  assert(bit32.OR(b, bit32.NOT(b)) == bit32.NOT(0))
  assert(bit32.OR(b) == b)
  assert(bit32.OR(b, b) == b)
  assert(bit32.OR(b, b, b) == b)
  assert(bit32.XOR(b) == b)
  assert(bit32.XOR(b, b) == 0)
  assert(bit32.XOR(b, 0) == b)
  assert(bit32.NOT(b) ~= b)
  assert(bit32.NOT(bit32.NOT(b)) == b)
  assert(bit32.NOT(b) == 2^32 - 1 - b)
  assert(bit32.ROL(b, 32) == b)
  assert(bit32.ROR(b, 32) == b)
  assert(bit32.SHL(bit32.SHL(b, -4), 4) == bit32.AND(b, bit32.NOT(0xf)))
  assert(bit32.SHR(bit32.SHR(b, 4), -4) == bit32.AND(b, bit32.NOT(0xf)))
  for i = -40, 40 do
    assert(bit32.SHL(b, i) == math.floor((b * 2^i) % 2^32))
  end
end

print("+")

assert(not pcall(bit32.AND, {}))
assert(not pcall(bit32.NOT, "a"))
assert(not pcall(bit32.SHL, 45))
assert(not pcall(bit32.SHL, 45, print))
assert(not pcall(bit32.SHR, 45, print))

print'OK'
