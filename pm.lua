print('testando pattern matching')

function f(s, p)
  local i,e = strfind(s, p)
  if i then return strsub(s, i, e) end
end

a,b = strfind('', '')    -- empty patterns are tricky
assert(a == 1 and b == 0);
a,b = strfind('alo', '')
assert(a == 1 and b == 0)
a,b = strfind('a\0o a\0o a\0o', 'a', 1)   -- first position
assert(a == 1 and b == 1)
a,b = strfind('a\0o a\0o a\0o', 'a\0o', 2)   -- starts in the midle
assert(a == 5 and b == 7)
a,b = strfind('a\0o a\0o a\0o', 'a\0o', 9)   -- starts in the midle
assert(a == 9 and b == 11)
a,b = strfind('a\0a\0a\0a\0\0ab', '\0ab', 2);  -- finds at the end
assert(a == 9 and b == 11);
a,b = strfind('a\0a\0a\0a\0\0ab', 'b')    -- last position
assert(a == 11 and b == 11)
assert(strfind('a\0a\0a\0a\0\0ab', 'b\0') == nil)   -- check ending
assert(strfind('', '\0') == nil)
assert(strfind('alo123alo', '12') == 4)
assert(strfind('alo123alo', '^12') == nil)

assert(f('aaab', 'a*') == 'aaa');
assert(f('aaa', '^.*$') == 'aaa');
assert(f('aaa', 'b*') == '');
assert(f('aaa', 'ab*a') == 'aa')
assert(f('aba', 'ab*a') == 'aba')
assert(f('aaab', 'a+') == 'aaa')
assert(f('aaa', '^.+$') == 'aaa')
assert(f('aaa', 'b+') == nil)
assert(f('aaa', 'ab+a') == nil)
assert(f('aba', 'ab+a') == 'aba')
assert(f('a$a', '.$') == 'a')
assert(f('a$a', '.%$') == 'a$')
assert(f('a$a', '.$.') == 'a$a')
assert(f('a$a', '$$') == nil)
assert(f('a$b', 'a$') == nil)
assert(f('a$a', '$') == '')
assert(f('', 'b*') == '')
assert(f('aaa', 'bb*') == nil)
assert(f('aaab', 'a-') == '')
assert(f('aaa', '^.-$') == 'aaa')
assert(f('aabaaabaaabaaaba', 'b.*b') == 'baaabaaabaaab')
assert(f('aabaaabaaabaaaba', 'b.-b') == 'baaab')
assert(f('alo xo', '.o$') == 'xo')
assert(f(' \n isto é assim', '%S%S*') == 'isto')
assert(f(' \n isto é assim', '%S*$') == 'assim')
assert(f(' \n isto é assim', '[a-z]*$') == 'assim')
assert(f('um caracter ? extra', '[^%sa-z]') == '?')
assert(f('', 'a?') == '')
assert(f('á', 'á?') == 'á')
assert(f('ábl', 'á?b?l?') == 'ábl')
assert(f('  ábl', 'á?b?l?') == '')
assert(f('aa', '^aa?a?a') == 'aa')
assert(f(']]]áb', '[^]]') == 'á')
assert(f("0alo alo", "%x*") == "0a")
assert(f("alo alo", "%C+") == "alo alo")
print('+')

assert(f('alo alx 123 b\0o b\0o', '(..*) %1') == "b\0o b\0o")
assert(f('axz123= 4= 4 34', '(.+)=(.*)=%2 %1') == '3= 4= 4 3')
_,_,a = strfind('=======', '^(=*)=%1$')
assert(a == '===')
assert(f('==========', '^([=]*)=%1$') == nil)

  local abc = "\0\1\2\3\4\5\6\7\8\9\10\11\12\13\14\15\16\17\18\19\20\21" ..
  "\22\23\24\25\26\27\28\29\30\31\32\33\34\35\36\37\38\39\40\41" ..
  "\42\43\44\45\46\47\48\49\50\51\52\53\54\55\56\57\58\59\60\61" ..
  "\62\63\64\65\66\67\68\69\70\71\72\73\74\75\76\77\78\79\80\81" ..
  "\82\83\84\85\86\87\88\89\90\91\92\93\94\95\96\97\98\99\100\101" ..
  "\102\103\104\105\106\107\108\109\110\111\112\113\114\115\116\117\118" ..
  "\119\120\121\122\123\124\125\126\127\128\129\130\131\132\133\134\135" ..
  "\136\137\138\139\140\141\142\143\144\145\146\147\148\149\150\151\152" ..
  "\153\154\155\156\157\158\159\160\161\162\163\164\165\166\167\168\169\170" ..
  "\171\172\173\174\175\176\177\178\179\180\181\182\183\184\185\186\187\188" ..
  "\189\190\191\192\193\194\195\196\197\198\199\200\201\202\203\204\205\206" ..
  "\207\208\209\210\211\212\213\214\215\216\217\218\219\220\221\222\223\224" ..
  "\225\226\227\228\229\230\231\232\233\234\235\236\237\238\239\240\241\242" ..
  "\243\244\245\246\247\248\249\250\251\252\253\254\255";

assert(strlen(abc) == 256)

function strset (p)
  local res = {s=''}
  gsub(%abc, p, function (c) %res.s = %res.s .. c end)
  return res.s
end;

assert(strlen(strset('[\200-\210]')) == 11)

assert(strset('[a-z]') == "abcdefghijklmnopqrstuvwxyz")
assert(strset('[a-z%d]') == strset('[%da-uu-z]'))
assert(strset('[a-]') == "-a")
assert(strset('[^%W]') == strset('[%w]'))
assert(strset('[]%%]') == '%]')
assert(strset('[a%-z]') == '-az')
assert(strset('[%^%[%-a%]%-b]') == '-[]^ab')
assert(strset('%Z') == strset('[\1-\255]'))
assert(strset('.') == strset('[\1-\255%z]'))
print('+');

function f(s, p)
  local _, __, c = strfind(s, p);
  return c;
end

assert(f("alo xyzK", "(%w+)K") == "xyz")
assert(f("254 K", "(%d*)K") == "")
assert(f("alo ", "(%w*)$") == "")
assert(f("alo ", "(%w+)$") == nil)
assert(strfind("(álo)", "%(á") == 1)
_, _, a, b, c, d, e = strfind("âlo alo", "^(((.).).* (%w*))$")
assert(a == 'âlo alo' and b == 'âl' and c == 'â' and d == 'alo' and e == nil)
_, _, a, b, c, d  = strfind('0123456789', '(.+(.?)())')
assert(a == '0123456789' and b == '' and c == 11 and d == nil)
print('+')

assert(gsub('ülo ülo', 'ü', 'x') == 'xlo xlo')
assert(gsub('alo úlo  ', ' +$', '') == 'alo úlo')  -- trim
assert(gsub('  alo alo  ', '^%s*(.-)%s*$', '%1') == 'alo alo')  -- double trim
assert(gsub('alo  alo  \n 123\n ', '%s+', ' ') == 'alo alo 123 ')
t = "abç d"
a, b = gsub(t, '(.)', '%1@')
assert('@'..a == gsub(t, '', '@') and b == 5)
a, b = gsub('abçd', '(.)', '%1@', 2)
assert(a == 'a@b@çd' and b == 2)
assert(gsub('alo alo', '()[al]', '%1') == '12o 56o')
assert(gsub("abc=xyz", "(%w*)(%p)(%w+)", "%3%2%1") == "xyz=abc")
assert(gsub('áéí', '$', '\0óú') == 'áéí\0óú')
assert(gsub('', '^', 'r') == 'r')
assert(gsub('', '$', 'r') == 'r')
print('+')

assert(gsub("um (dois) tres (quatro)", "(%(%w+%))", strupper) ==
            "um (DOIS) tres (QUATRO)")

do
  gsub("a=roberto,roberto=a", "(%w+)=(%w%w*)", setglobal)
  assert(_G.a=="roberto" and _G.roberto=="a")
end

function f(a,b) return gsub(a,'.',b) end
assert(gsub("trocar tudo em |teste|b| é |beleza|al|", "|([^|]*)|([^|]*)|", f) ==
            "trocar tudo em bbbbb é alalalalalal")

assert(gsub("alo $a=1$ novamente $return a$", "$([^$]*)%$", dostring) ==
            "alo  novamente 1")

x = gsub("$x=gsub('alo', '.', strupper)$ assim vai para $return x$",
         "$([^$]*)%$", dostring)
assert(x == ' assim vai para ALO')

t = {}
gsub('a alo jose  joao', '()(%w+)()', function (a,w,b)
  assert(strlen(w) == b-a);
  t[a] = b-a;
end)
assert(t[1] == 1 and t[3] == 3 and t[7] == 4 and t[13] == 4)


function isbalanced (s)
  return strfind(gsub(s, "%b()", ""), "[()]") == nil
end

assert(isbalanced("(9 ((8))(\0) 7) \0\0 a b ()(c)() a"))
assert(not isbalanced("(9 ((8) 7) a b (\0 c) a"))
assert(gsub("alo 'oi' alo", "%b''", '"') == 'alo " alo')


local t = {"apple", "orange", "lime"; n=0}
assert(gsub("x and x and x", "x", function () %t.n=%t.n+1; return %t[%t.n] end)
        == "apple and orange and lime")

t = {n=0}
gsub("first second word", "%w%w*", function (w) %t.n=%t.n+1; %t[%t.n] = w end)
assert(t[1] == "first" and t[2] == "second" and t[3] == "word" and t.n == 3)

t = {n=0}
gsub("first second word", "%w+",
      function (w) %t.n=%t.n+1; %t[%t.n] = w end, 2)
assert(t[1] == "first" and t[2] == "second" and t[3] == nil)

assert(not pcall(gsub, "alo", "(.", print))
assert(not pcall(gsub, "alo", ".)", print))

-- big strings
local a = strrep('a', 300000)
assert(strfind(a, '^a*(.?)$'))
assert(not strfind(a, '^a*(.?)b$'))
assert(strfind(a, '^a-(.?)$'))

-- deep nest of gsubs
function rev (s)
  return gsub(s, "(.)(.+)", function (c,s1) return rev(s1)..c end)
end

local x = strrep('012345', 10)
assert(rev(rev(x)) == x)


-- tests for gfind
local a = 0
for i in string.gfind('abcde', '()') do assert(i == a+1); a=i end
assert(a==6)

t = {n=0}
for w in string.gfind("first second word", "%w+") do
      t.n=t.n+1; t[t.n] = w
end
assert(t[1] == "first" and t[2] == "second" and t[3] == "word")

t = {3, 6, 9}
for i in string.gfind ("xuxx uu ppar r", "()(.)%2") do
  assert(i == tremove(t, 1))
end
assert(getn(t) == 0)

t = {}
for i,j in string.gfind("13 14 10 = 11, 15= 16, 22=23", "(%d+)%s*=%s*(%d+)") do
  t[i] = j
end
a = 0
for k,v in t do assert(k+1 == v+0); a=a+1 end
assert(a == 3)


-- tests for `%f' (`frontiers')

assert(string.gsub("aaa aa a aaa a", "%f[%w]a", "x") == "xaa xa x xaa x")
assert(string.gsub("[[]] [][] [[[[", "%f[[].", "x") == "x[]] x]x] x[[[")
assert(string.gsub("01abc45de3", "%f[%d]", ".") == ".01abc.45de.3")
assert(string.gsub("01abc45 de3x", "%f[%D]%w", ".") == "01.bc45 de3.")
assert(string.gsub("function", "%f[\1-\255]%w", ".") == ".unction")
assert(string.gsub("function", "%f[^\1-\255]", ".") == "function.")

local i, e, k = string.find(" alo aalo allo", "%f[%S](.-%f[%s].-%f[%S])")
assert(i == 2 and e == 5 and k == 'alo ')

local a = {1, 5, 9, 14, 17,}
for k in string.gfind("alo alo th02 is 1hat", "()%f[%w%d]") do
  assert(table.remove(a, 1) == k)
end
assert(table.getn(a) == 0)


print('OK')
