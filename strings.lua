print('testing strings and string library')

local Csize = require'debug'.Csize

local maxi, mini = math.maxinteger, math.mininteger

-- testing string comparisons
assert('alo' < 'alo1')
assert('' < 'a')
assert('alo\0alo' < 'alo\0b')
assert('alo\0alo\0\0' > 'alo\0alo\0')
assert('alo' < 'alo\0')
assert('alo\0' > 'alo')
assert('\0' < '\1')
assert('\0\0' < '\0\1')
assert('\1\0a\0a' <= '\1\0a\0a')
assert(not ('\1\0a\0b' <= '\1\0a\0a'))
assert('\0\0\0' < '\0\0\0\0')
assert(not('\0\0\0\0' < '\0\0\0'))
assert('\0\0\0' <= '\0\0\0\0')
assert(not('\0\0\0\0' <= '\0\0\0'))
assert('\0\0\0' <= '\0\0\0')
assert('\0\0\0' >= '\0\0\0')
assert(not ('\0\0b' < '\0\0a\0'))

-- testing string.sub
assert(string.sub("123456789",2,4) == "234")
assert(string.sub("123456789",7) == "789")
assert(string.sub("123456789",7,6) == "")
assert(string.sub("123456789",7,7) == "7")
assert(string.sub("123456789",0,0) == "")
assert(string.sub("123456789",-10,10) == "123456789")
assert(string.sub("123456789",1,9) == "123456789")
assert(string.sub("123456789",-10,-20) == "")
assert(string.sub("123456789",-1) == "9")
assert(string.sub("123456789",-4) == "6789")
assert(string.sub("123456789",-6, -4) == "456")
assert(string.sub("123456789", mini, -4) == "123456")
assert(string.sub("123456789", mini, maxi) == "123456789")
assert(string.sub("123456789", mini, mini) == "")
assert(string.sub("\000123456789",3,5) == "234")
assert(("\000123456789"):sub(8) == "789")

-- testing string.find
assert(string.find("123456789", "345") == 3)
a,b = string.find("123456789", "345")
assert(string.sub("123456789", a, b) == "345")
assert(string.find("1234567890123456789", "345", 3) == 3)
assert(string.find("1234567890123456789", "345", 4) == 13)
assert(string.find("1234567890123456789", "346", 4) == nil)
assert(string.find("1234567890123456789", ".45", -9) == 13)
assert(string.find("abcdefg", "\0", 5, 1) == nil)
assert(string.find("", "") == 1)
assert(string.find("", "", 1) == 1)
assert(not string.find("", "", 2))
assert(string.find('', 'aaa', 1) == nil)
assert(('alo(.)alo'):find('(.)', 1, 1) == 4)

assert(string.len("") == 0)
assert(string.len("\0\0\0") == 3)
assert(string.len("1234567890") == 10)

assert(#"" == 0)
assert(#"\0\0\0" == 3)
assert(#"1234567890" == 10)

-- testing string.byte/string.char
assert(string.byte("a") == 97)
assert(string.byte("\xe4") > 127)
assert(string.byte(string.char(255)) == 255)
assert(string.byte(string.char(0)) == 0)
assert(string.byte("\0") == 0)
assert(string.byte("\0\0alo\0x", -1) == string.byte('x'))
assert(string.byte("ba", 2) == 97)
assert(string.byte("\n\n", 2, -1) == 10)
assert(string.byte("\n\n", 2, 2) == 10)
assert(string.byte("") == nil)
assert(string.byte("hi", -3) == nil)
assert(string.byte("hi", 3) == nil)
assert(string.byte("hi", 9, 10) == nil)
assert(string.byte("hi", 2, 1) == nil)
assert(string.char() == "")
assert(string.char(0, 255, 0) == "\0\255\0")
assert(string.char(0, string.byte("\xe4"), 0) == "\0\xe4\0")
assert(string.char(string.byte("\xe4l\0óu", 1, -1)) == "\xe4l\0óu")
assert(string.char(string.byte("\xe4l\0óu", 1, 0)) == "")
assert(string.char(string.byte("\xe4l\0óu", -10, 100)) == "\xe4l\0óu")

assert(string.upper("ab\0c") == "AB\0C")
assert(string.lower("\0ABCc%$") == "\0abcc%$")
assert(string.rep('teste', 0) == '')
assert(string.rep('tés\00tê', 2) == 'tés\0têtés\000tê')
assert(string.rep('', 10) == '')

-- repetitions with separator
assert(string.rep('teste', 0, 'xuxu') == '')
assert(string.rep('teste', 1, 'xuxu') == 'teste')
assert(string.rep('\1\0\1', 2, '\0\0') == '\1\0\1\0\0\1\0\1')
assert(string.rep('', 10, '.') == string.rep('.', 9))
assert(not pcall(string.rep, "aa", maxi // 2))
assert(not pcall(string.rep, "", maxi // 2, "aa"))

assert(string.reverse"" == "")
assert(string.reverse"\0\1\2\3" == "\3\2\1\0")
assert(string.reverse"\0001234" == "4321\0")

for i=0,30 do assert(string.len(string.rep('a', i)) == i) end

assert(type(tostring(nil)) == 'string')
assert(type(tostring(12)) == 'string')
assert('' .. 12 == '12' and 12.0 .. '' == '12')
assert(string.find(tostring{}, 'table:'))
assert(string.find(tostring(print), 'function:'))
assert(#tostring('\0') == 1)
assert(tostring(true) == "true")
assert(tostring(false) == "false")
assert(tostring(-1203) == "-1203")
assert(tostring(1203.125) == "1203.125")
assert(tostring(0.0) == "0.0")
assert(tostring(-0.5) == "-0.5")
assert(tostring(-1203 + 0.0) == "-1203.0")
assert(tostring(-32767) == "-32767")
if 2147483647 > 0 then   -- no overflow? (32 bits)
  assert(tostring(-2147483647) == "-2147483647")
end
if 4611686018427387904 > 0 then   -- no overflow? (64 bits)
  assert(tostring(4611686018427387904) == "4611686018427387904")
  assert(tostring(-4611686018427387904) == "-4611686018427387904")
end

x = '"ílo"\n\\'
assert(string.format('%q%s', x, x) == '"\\"ílo\\"\\\n\\\\""ílo"\n\\')
assert(string.format('%q', "\0") == [["\0"]])
assert(load(string.format('return %q', x))() == x)
x = "\0\1\0023\5\0009"
assert(load(string.format('return %q', x))() == x)
assert(string.format("\0%c\0%c%x\0", string.byte("\xe4"), string.byte("b"), 140) ==
              "\0\xe4\0b8c\0")
assert(string.format('') == "")
assert(string.format("%c",34)..string.format("%c",48)..string.format("%c",90)..string.format("%c",100) ==
       string.format("%c%c%c%c", 34, 48, 90, 100))
assert(string.format("%s\0 is not \0%s", 'not be', 'be') == 'not be\0 is not \0be')
assert(string.format("%%%d %010d", 10, 23) == "%10 0000000023")
assert(tonumber(string.format("%f", 10.3)) == 10.3)
x = string.format('"%-50s"', 'a')
assert(#x == 52)
assert(string.sub(x, 1, 4) == '"a  ')

assert(string.format("-%.20s.20s", string.rep("%", 2000)) ==
                     "-"..string.rep("%", 20)..".20s")
assert(string.format('"-%20s.20s"', string.rep("%", 2000)) ==
       string.format("%q", "-"..string.rep("%", 2000)..".20s"))

-- format x tostring
assert(string.format("%s %s", nil, true) == "nil true")
assert(string.format("%s %.4s", false, true) == "false true")
assert(string.format("%.3s %.3s", false, true) == "fal tru")
local m = setmetatable({}, {__tostring = function () return "hello" end})
assert(string.format("%s %.10s", m, m) == "hello hello")


assert(string.format("%x", 0.3) == "0")
assert(string.format("%02x", 0.1) == "00")
assert(string.format("%08X", 4294967295) == "FFFFFFFF")
assert(string.format("%+08d", 31501) == "+0031501")
assert(string.format("%+08d", -30927) == "-0030927")


-- longest number that can be formated
local largefinite = (Csize("F") >= 8) and 1e308 or 1e38
assert(string.len(string.format('%99.99f', -largefinite)) >= 100)


-- testing large numbers for format
do   -- assume at least 32 bits
  local max, min = 0x7fffffff, -0x80000000    -- "large" for 32 bits
  assert(string.sub(string.format("%8x", -1), -8) == "ffffffff")
  assert(string.format("%x", max) == "7fffffff")
  assert(string.sub(string.format("%x", min), -8) == "80000000")
  assert(string.format("%d", max) ==  "2147483647")
  assert(string.format("%d", min) == "-2147483648")

  max, min = math.maxinteger, math.mininteger
  if max > 2.0^53 then  -- only for 64 bits
    assert(string.format("%x", 2^52 // 1 - 1) == "fffffffffffff")
    assert(string.format("0x%8X", 0x8f000003) == "0x8F000003")
    assert(string.format("%d", 2^53) == "9007199254740992")
    assert(string.format("%d", -2^53) == "-9007199254740992")
    assert(string.format("%x", max) == "7fffffffffffffff")
    assert(string.format("%x", min) == "8000000000000000")
    assert(string.format("%d", max) ==  "9223372036854775807")
    assert(string.format("%d", min) == "-9223372036854775808")
    assert(tostring(1234567890123) == '1234567890123')
  end
end

if not _noformatA then
  print("testing 'format %a %A'")
  assert(tonumber(string.format("%.2a", 0.5)) == 0x1.00p-1)
  assert(tonumber(string.format("%A", 0x1fffff.0)) == 0X1.FFFFFP+20)
  assert(tonumber(string.format("%.4a", -3)) == -0x1.8000p+1)
  assert(tonumber(string.format("%a", -0.1)) == -0.1)
end


-- errors in format

local function check (fmt, msg)
  local s, err = pcall(string.format, fmt, 10)
  assert(not s and string.find(err, msg))
end

local aux = string.rep('0', 600)
check("%100.3d", "too long")
check("%1"..aux..".3d", "too long")
check("%1.100d", "too long")
check("%10.1"..aux.."004d", "too long")
check("%t", "invalid option")
check("%"..aux.."d", "repeated flags")
check("%d %d", "no value")


assert(load("return 1\n--comment without ending EOL")() == 1)


assert(table.concat{} == "")
assert(table.concat({}, 'x') == "")
assert(table.concat({'\0', '\0\1', '\0\1\2'}, '.\0.') == "\0.\0.\0\1.\0.\0\1\2")
local a = {}; for i=1,300 do a[i] = "xuxu" end
assert(table.concat(a, "123").."123" == string.rep("xuxu123", 300))
assert(table.concat(a, "b", 20, 20) == "xuxu")
assert(table.concat(a, "", 20, 21) == "xuxuxuxu")
assert(table.concat(a, "x", 22, 21) == "")
assert(table.concat(a, "3", 299) == "xuxu3xuxu")
assert(table.concat({}, "x", maxi, maxi - 1) == "")
assert(table.concat({}, "x", mini + 1, mini) == "")
assert(table.concat({}, "x", maxi, mini) == "")
assert(table.concat({[maxi] = "alo"}, "x", maxi, maxi) == "alo")
assert(table.concat({[maxi] = "alo", [maxi - 1] = "y"}, "-", maxi - 1, maxi)
       == "y-alo")

assert(not pcall(table.concat, {"a", "b", {}}))

a = {"a","b","c"}
assert(table.concat(a, ",", 1, 0) == "")
assert(table.concat(a, ",", 1, 1) == "a")
assert(table.concat(a, ",", 1, 2) == "a,b")
assert(table.concat(a, ",", 2) == "b,c")
assert(table.concat(a, ",", 3) == "c")
assert(table.concat(a, ",", 4) == "")

if not _port then

  local locales = { "ptb", "ISO-8859-1", "pt_BR" }
  local function trylocale (w)
    for i = 1, #locales do
      if os.setlocale(locales[i], w) then return true end
    end
    return false
  end

  if not trylocale("collate")  then
    print("locale not supported")
  else
    assert("alo" < "álo" and "álo" < "amo")
  end

  if not trylocale("ctype") then
    print("locale not supported")
  else
    assert(load("a = 3.4"));  -- parser should not change outside locale
    assert(not load("á = 3.4"));  -- even with errors
    assert(string.gsub("áéíóú", "%a", "x") == "xxxxx")
    assert(string.gsub("áÁéÉ", "%l", "x") == "xÁxÉ")
    assert(string.gsub("áÁéÉ", "%u", "x") == "áxéx")
    assert(string.upper"áÁé{xuxu}ção" == "ÁÁÉ{XUXU}ÇÃO")
  end

  os.setlocale("C")
  assert(os.setlocale() == 'C')
  assert(os.setlocale(nil, "numeric") == 'C')

end


print"testing dump/undump"

local numbytes = Csize'I'

local maxbytes = 12

-- basic dump/undump with default arguments
for _, i in ipairs{0, 1, 2, 127, 128, 255, -128, -1, -2} do
  assert(string.undumpint(string.dumpint(i)) == i)
end

-- basic dump/undump with non-default arguments
for _, e in pairs{"l", "b"} do
  for s = 2, maxbytes do
    for _, i in ipairs{0, 1, 2, 127, 128, 255, 32767, -32768,
                       -128, -1, -2, 0x5BCD} do
      assert(string.undumpint(string.dumpint(i, s, e), 1, s, e) == i)
    end
  end
end

-- default size is the size of a Lua integer
assert(#string.dumpint(0) == numbytes)
assert(string.dumpint(-234, 0) == string.dumpint(-234))

-- endianess
assert(string.dumpint(34, 4, 'l') == "\34\0\0\0")
assert(string.dumpint(34, 4, 'b') == "\0\0\0\34")
assert(string.dumpint(0, 3, 'n') == "\0\0\0")


-- unsigned values
assert(string.dumpint(255, 1, 'l') == "\255")
assert(string.dumpint(0xffffff, 3) == "\255\255\255")
assert(string.dumpint(0x8000, 2, 'b') == "\x80\0")

-- for unsigned, we need to mask results (but there is no errors)
assert(string.undumpint("\x80\0", 1, 2, 'b') & 0xFFFF == 0x8000)

local m = 0xf1f2f3ff
assert(string.undumpint('\0\0\0\0\xf1\xf2\xf3\xff', 5, 4, 'b') & m == m)



local function check (i, s, n)
  assert(string.dumpint(n, i, 'l') == s)
  assert(string.dumpint(n, i, 'b') == s:reverse())
  assert(string.undumpint(s, 1, i, 'l') == n)
  assert(string.undumpint(s:reverse(), 1, i, 'b') == n)
end


for i = 1, maxbytes do
  -- 1111111...111111
  check(i, string.rep("\255", i), -1)
  local p = 1 << (i*8 - 1)
  if p ~= 0 then
    -- 10000...00000000
    check(i, string.rep("\0", i - 1) .. "\x80", -p)
    -- 01111...1111111
    check(i, string.rep("\255", i - 1) .. "\x7f", p - 1)
  end
  -- 000...0001111111
  check(i, "\127" .. string.rep("\0", i - 1), 127)
  check(i, "\209" .. string.rep("\255", i - 1), 209 - 256)
end


for i = 0, maxbytes - numbytes do
  -- largest allowed unsigned number with extra leading zeros
  local s = string.rep("\0", i) .. string.rep("\255", numbytes)
  assert(string.undumpint(s, 1, i + numbytes, "b") == ~0)
  -- another large unsigned number
  s = string.rep("\0", i) .. string.rep("\255", numbytes - 1) .. "\12"
  assert(string.undumpint(s, 1, i + numbytes, "b") == ~0 - (255 - 12))
end
 

-- signal extension
assert(string.undumpint("\x19\xff\0", -3, 3, 'l') == 0xff19)
assert(string.undumpint("\19\xff\0", -3, 2, 'l') == -237)


-- position
local s = "\0\255\123\9\1\47\200"
for i = 1, #s do
  assert(string.undumpint(s, i, 1) & 0xff == string.byte(s, i))
end

for i = 1, #s - 1 do
  assert(string.undumpint(s, i, 2, 'b') & 0xffff ==
  string.byte(s, i)*256 + string.byte(s, i + 1))
end

for i = 1, #s - 2 do
  assert(string.undumpint(s, i, 3, 'l') & 0xffffff ==
  string.byte(s, i + 2)*256^2 + string.byte(s, i + 1)*256 + string.byte(s, i))
end


-- testing overflow in dumping

local function checkerror (n, size, endian)
  local status, msg = pcall(string.dumpint, n, size, endian)
  assert(not status and string.find(msg, "does not fit"))
end

for i = 1, numbytes - 1 do
  local maxunsigned = (1 << i*8) - 1
  local minsigned = -maxunsigned // 2

  local s = string.dumpint(maxunsigned, i)
  assert(string.undumpint(s, 1, i) % (maxunsigned + 1) == maxunsigned)
  checkerror(maxunsigned + 1, i, 'l')
  checkerror(maxunsigned + 1, i, 'b')
  if i > 1 then
    checkerror(maxunsigned, i - 1)
  end

  s = string.dumpint(minsigned, i)
  assert(string.undumpint(s, 1, i) == minsigned)
  checkerror(minsigned - 1, i, 'l')
  checkerror(minsigned - 1, i, 'b')
end


-- testing overflow in undumping

checkerror = function (s, size, endian)
    local status, msg = pcall(string.undumpint, s, 1, size, endian)
    assert(not status and string.find(msg, "does not fit"))
end

checkerror("\3\0\0\0\0\0\0\0\0\0", 10, 'b')
checkerror("\0\0\0\0\0\0\0\0\3", 9, 'l')
checkerror("\x7f\xff\xff\xff\xff\xff\xff\xff\xff\xff", 10, 'b')
checkerror("\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x7f", 12, 'l')

-- looks like negative integers, but they are not (because of leading zero)
checkerror("\0\xff\xff\xff\xff\xff\xff\xff\xff\x23", 10, 'b')
checkerror("\0\0\xff\xff\xff\xff\xff\xff\xff\xff\xff\x23", 12, 'b')
-- looks like positive integers, but they are not
checkerror("\x01\0\0\0\0\0\0\0\0\x23", 10, 'b')
checkerror("\x80\0\0\0\0\0\0\0\0\0\0\x23", 12, 'b')


-- check errors in arguments
function check (msg, f, ...)
  local status, err = pcall(f, ...)
  assert(not status and string.find(err, msg))
end

check("string too short", string.undumpint, "\1\2\3\4", maxi)
check("string too short", string.undumpint, "\1\2\3\4", (1 << 31) - 1)
check("string too short", string.undumpint, "\1\2\3\4", 4, 2)
check("endianness", string.undumpint, "\1\2\3\4", 1, 2, 'x')
check("endianness", string.dumpint, -1, 2, 'x')
check("out of valid range", string.dumpint, -1, maxbytes + 1)



-- checking dump/undump of floating numbers

check("string too short", string.undumpfloat, "\1\2\3\4", 2, "f")
check("string too short", string.undumpfloat, "\1\2\3\4\5\6\7", 2, "d")
check("string too short", string.undumpfloat, "\1\2\3\4", (1 << 31) - 1)

assert(string.undumpfloat(string.dumpfloat(120.5, 'n', 'n'), 1, 'n', 'n')
   == 120.5)

for _, n in ipairs{0, -1.1, 1.9, 1/0, -1/0, 1e20, -1e20, 0.1, 2000.7} do
  assert(string.undumpfloat(string.dumpfloat(n)) == n)
  assert(string.undumpfloat(string.dumpfloat(n, 'n'), 1, 'n') == n)
  assert(string.dumpfloat(n, 'f', 'l') ==
         string.dumpfloat(n, 'f', 'b'):reverse())
  assert(string.dumpfloat(n, 'd', 'b') ==
         string.dumpfloat(n, 'd', 'l'):reverse())
end

-- for non-native precisions, test only with "round" numbers
for _, n in ipairs{0, -1.5, 1/0, -1/0, 1e10, -1e9, 0.5, 2000.25} do
  assert(string.undumpfloat(string.dumpfloat(n, 'f'), 1, 'f') == n)
  assert(string.undumpfloat(string.dumpfloat(n, 'd'), 1, 'd') == n)
end

-- position
for i = 1, 11 do
  local s = string.rep("0", i)  .. string.dumpfloat(3.125)
  assert(string.undumpfloat(s, i + 1) == 3.125)
end

if not _port then
  assert(#string.dumpfloat(0, 'f') == 4)
  assert(#string.dumpfloat(0, 'd') == 8)
end

print('OK')

