print "testing UTF-8 library"

local utf8 = require'utf8'


local function len (s)
  return #string.gsub(s, "[\x80-\xBF]", "")
end


local justone = "^" .. utf8.charpatt .. "$"

-- 't' is the list of codepoints of 's'
local function checksyntax (s, t)
  local ts = {"return '"}
  for i = 1, #t do ts[i + 1] = string.format("\\u{%x}", t[i]) end
  ts[#t + 2] = "'"
  ts = table.concat(ts)
  assert(assert(load(ts))() == s)
end


-- 't' is the list of codepoints of 's'
local function check (s, t)
  local l = utf8.len(s) 
  assert(#t == l and len(s) == l)
  assert(utf8.char(table.unpack(t)) == s)

  checksyntax(s, t)

  local t1 = {utf8.codepoint(s, 1, -1)}
  assert(#t == #t1)
  for i = 1, #t do assert(t[i] == t1[i]) end

  for i = 1, l do
    local pi = utf8.offset(s, i)        -- position of i-th char
    local pi1 = utf8.offset(s, 2, pi)   -- position of next char
    assert(string.find(string.sub(s, pi, pi1 - 1), justone))
    assert(utf8.offset(s, -1, pi1) == pi)
    assert(pi1 - pi == #utf8.char(utf8.codepoint(s, pi)))
    for j = pi, pi1 - 1 do 
      assert(utf8.offset(s, 0, j) == pi)
    end
    for j = pi + 1, pi1 - 1 do
      assert(utf8.len(s, j) == nil)
    end
  end

  local i = 0
  for p, c in utf8.codes(s) do
    i = i + 1
    assert(c == t[i] and p == utf8.offset(s, i))
    assert(utf8.codepoint(s, p) == c)
  end
  assert(i == #t)

  i = 0
  for p, c in utf8.codes(s) do
    i = i + 1
    assert(c == t[i] and p == utf8.offset(s, i)) 
  end
  assert(i == #t)

  i = 0
  for c in string.gmatch(s, utf8.charpatt) do
    i = i + 1
    assert(c == utf8.char(t[i]))
  end
  assert(i == #t)

  for i = 1, l do
    assert(utf8.offset(s, i) == utf8.offset(s, i - l - 1, #s + 1))
  end

end

local s = "hello World"
local t = {string.byte(s, 1, -1)}
for i = 1, utf8.len(s) do assert(t[i] == string.byte(s, i)) end
check(s, t)

check("汉字/漢字", {27721, 23383, 47, 28450, 23383,})

do
  local s = "áéí\128"
  local t = {utf8.codepoint(s,1,#s - 1)}
  assert(#t == 3 and t[1] == 225 and t[2] == 233 and t[3] == 237)
  assert(not pcall(utf8.codepoint, s, 1, #s))
end

assert(utf8.char() == "")
assert(utf8.char(97, 98, 99) == "abc")

assert(utf8.codepoint(utf8.char(0x10FFFF)) == 0x10FFFF)

-- value out fo valid range
assert(not pcall(utf8.char, 0x10FFFF + 1))

local function invalid (s)
  assert(not pcall(utf8.codepoint, s))
  assert(utf8.len(s) == nil)
end

-- UTF-8 representation for 0x11ffff (value out of valid range)
invalid("\xF4\x9F\xBF\xBF")

-- overlong sequences
invalid("\xC0\x80")          -- zero
invalid("\xC1\xBF")          -- 0x7F (should be coded in 1 byte)
invalid("\xE0\x9F\xBF")      -- 0x7FF (should be coded in 2 bytes)
invalid("\xF0\x8F\xBF\xBF")  -- 0xFFFF (should be coded in 3 bytes)


-- invalid bytes
invalid("\x80")  -- continuation byte
invalid("\xBF")  -- continuation byte
invalid("\xFE")  -- invalid byte
invalid("\xFF")  -- invalid byte


-- minimum and maximum values for each sequence size
s = "\0 \x7F\z
     \xC2\x80 \xDF\xBF\z
     \xE0\xA0\x80 \xEF\xBF\xBF\z
     \xF0\x90\x80\x80  \xF4\x8F\xBF\xBF"
s = string.gsub(s, " ", "")
check(s, {0,0x7F, 0x80,0x7FF, 0x800,0xFFFF, 0x10000,0x10FFFF})

x = "日本語a-4\0éó"
check(x, {26085, 26412, 35486, 97, 45, 52, 0, 233, 243})


-- Supplementary Characters
check("𣲷𠜎𠱓𡁻𠵼ab𠺢",
      {0x23CB7, 0x2070E, 0x20C53, 0x2107B, 0x20D7C, 0x61, 0x62, 0x20EA2,})

check("𨳊𩶘𦧺𨳒𥄫𤓓\xF4\x8F\xBF\xBF",
      {0x28CCA, 0x29D98, 0x269FA, 0x28CD2, 0x2512B, 0x244D3, 0x10ffff})


local i = 0
for p, c in string.gmatch(x, "()(" .. utf8.charpatt .. ")") do
  i = i + 1
  assert(utf8.offset(x, i) == p)
  assert(utf8.len(x, p) == utf8.len(x) - i + 1)
  assert(utf8.len(c) == 1)
  for j = 1, #c - 1 do
    assert(utf8.offset(x, 0, p + j - 1) == p)
  end
end

print'ok'

