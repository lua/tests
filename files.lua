print('testando i/o')

assert(type(_INPUT) == "FileHandle")

a,b,c = readfrom('xuxu_nao_existe')
assert(not a and type(b) == "string" and type(c) == "number")

a,b,c = writeto('/a/b/c/d')
assert(not a and type(b) == "string" and type(c) == "number")

a,b,c = appendto('/a/b/c/d')
assert(not a and type(b) == "string" and type(c) == "number")

file = tmpname()
otherfile = tmpname()

assert(setlocale('C', 'all'))

readfrom()
writeto()
assert(_INPUT == _STDIN and _OUTPUT == _STDOUT)

remove(file)
assert(dofile(file) == nil)
assert(readfrom(file) == nil)
assert(rawtype(writeto(file)) == 'userdata')
assert(_OUTPUT ~= _STDOUT)

assert(seek(_OUTPUT) == 0)
assert(write("alo alo"))
assert(seek(_OUTPUT) == strlen("alo alo"))
assert(seek(_OUTPUT, "cur", -3) == strlen("alo alo")-3)
assert(write("joao"))
assert(seek(_OUTPUT, "end") == strlen("alo joao"))

assert(seek(_OUTPUT, "set") == 0)

assert(write('"álo"', "{a}\n", "second line\n", "third\0line \n"))
assert(write('çfourth_line'))
_OUTPUT = _STDOUT;
collectgarbage()  -- file should be closed by GC
assert(_INPUT == _STDIN and _OUTPUT == _STDOUT)
print('+')

assert(rename(file, otherfile))
assert(rename(file, otherfile) == nil)

assert(appendto(otherfile))
assert(write("\n\n\t\t  3450\n"));
assert(writeto())

assert(rename(otherfile, file))
assert(readfrom(file))
assert(read(0) == "")   -- not eof
assert(read(5, '*l') == '"álo"')
assert(read(0) == "")
assert(read() == "second line")
x = seek(_INPUT)
assert(read() == "third\0line ")
assert(seek(_INPUT, "set", x))
assert(read('*l') == "third\0line ")
if call(read, {"{a?}b?c?"}, "x", nil) then  -- read patterns implemented!
  print "        testando read patterns (deprecated!)"
  assert(read('.') == "ç")
  assert(read'{%s*}%S+' == "fourth_line")
else
  assert(read(1) == "ç")
  assert(read(strlen"fourth_line") == "fourth_line")
end
assert(seek(_INPUT, "cur", -strlen"fourth_line"))
assert(read() == "fourth_line")
assert(read() == "")  -- empty line
assert(read('*n') == 3450)
assert(read(1) == '\n')
assert(read(0) == nil)  -- end of file
assert(read(1) == nil)  -- end of file
assert({read(1)}[2] == nil)
assert(read() == nil)  -- end of file
assert({read()}[2] == nil)
assert(read('*n') == nil)  -- end of file
assert({read('*n')}[2] == nil)
assert(read('*a') == '')  -- end of file (OK for `*a')
collectgarbage()
print('+')
assert(readfrom())
assert(remove(file))

t = '0123456789'
i=1
for i=1,12 do t = t..t; end
l = strlen(t)
assert(l == 10*2^12)

writeto(file)
write("alo\n")
writeto()
f = appendto(file)
collectgarbage()

assert(write(' ' .. t .. ' '))
assert(write(';', 'end of file\n'))
flush(f); flush()
writeto()
print('+')

assert(readfrom(file))
assert(read() == "alo")
assert(read'*u ' == '')
assert(read('*u ') == t)
assert(read(0))
assert(read('*a') == ';end of file\n')
assert(read(0) == nil)
assert(readfrom())

assert(remove(file))
print('+')

x1 = "string\n\n\\com \"\"''coisas [[estranhas]] ]]'"
assert(writeto(file))
assert(write(format("x2 = %q\n-- comentário sem EOL no final", x1)))
assert(writeto())
assert(dofile(file))
assert(x1 == x2)
print('+')
assert(remove(file))
assert(remove(file) == nil)
assert(remove(otherfile) == nil)

assert(writeto(file))
assert(write("qualquer coisa\n"))
assert(write("mais qualquer coisa"))
assert(writeto())
_OUTPUT = assert(openfile(otherfile, 'wb'))
assert(write("outra coisa\0\1\3\0\0\0\0\255\0"))
assert(writeto())

filehandle = assert(openfile(file, 'r'))
otherfilehandle = assert(openfile(otherfile, 'rb'))
assert(filehandle ~= otherfilehandle)
assert(rawtype(filehandle) == "userdata")
assert(read(filehandle,'*l') == "qualquer coisa")
_INPUT = otherfilehandle
assert(read(strlen"outra coisa") == "outra coisa")
assert(read(filehandle, '*l') == "mais qualquer coisa")
assert(tag(filehandle) == tag(_INPUT))
closefile(filehandle);
assert(tag(filehandle) ~= tag(_INPUT))
assert(rawtype(filehandle) == "userdata" and
       type(filehandle) == "ClosedFileHandle")
_INPUT = otherfilehandle
assert(read(4) == "\0\1\3\0")
assert(read(3) == "\0\0\0")
assert(read(0) == "")        -- 255 is not eof
assert(read(1) == "\255")
assert(read('*a') == "\0")
assert(not read(0))
assert(otherfilehandle == _INPUT)
readfrom()  -- close otherfilehandle
assert(remove(file))
assert(remove(otherfile))
assert(_INPUT == _STDIN)
collectgarbage()

assert(writeto(file))
write[[
 123.4	-56e-2  not a number
second line
third line
a_word   another_word
and the rest of the file
]]
assert(writeto())
assert(readfrom(file))
_,a,b,c,d,e,f,g,h,__ = read(_INPUT, 1, '*n', '*n', '*l', '*l', '*l',
                              '*uword', '*uword', '*a', 10)
assert(readfrom())
assert(_ == ' ' and __ == nil)
assert(type(a) == 'number' and a==123.4 and b==-56e-2)
assert(d=='second line' and e=='third line')
assert(f=='a_' and g=='   another_')
assert(h==[[

and the rest of the file
]])
assert(remove(file))
collectgarbage()

settagmethod(tag(_INPUT), 'gettable', read)
settagmethod(tag(_OUTPUT), 'settable', function(f, _, a) write(f,a) end)
x = writeto(file);
y = writeto(otherfile);
x.n, y.n = "abcdef", "012345";
_OUTPUT = x
writeto()
_OUTPUT = y
writeto()

f1 = readfrom(file)
f2 = readfrom(otherfile)
assert(f1 and f2)
assert(f1[1] == 'a' and f2[1] == '0')
assert(f1[2] == 'bc' and f2[02] == '12')
assert(f1['*a'] == 'def' and f2['*a'] == '345')
_INPUT = f1; readfrom()
_INPUT = f2; readfrom()

assert(remove(file) and remove(otherfile))


-- teste de read_until
assert(writeto(file))
write'01001000100001000001010101\n'
write'01001000100001000001010101\n'
write'01001000100001000001010101\n'
writeto()
assert(readfrom(file))
assert(read("*u0001") == "01001")
assert(read("*u101") == "0000100000")
read()  -- go to next line
assert(read("*u101\n") == "01001000100001000001010")
assert(read("*u01\0") == "01001000100001000001010101\n")
assert(read("*u01") == nil)
assert(read("*u0") == nil)
readfrom()
assert(writeto(file))
write'01'
writeto()
assert(readfrom(file)); assert(read('*u1') == '0')
assert(readfrom(file)); assert(read('*u01') == '')
assert(readfrom(file)); assert(read('*u01\0') == '01')
assert(readfrom(file)); assert(read('*u001') == '01')
assert(remove(file))

-- teste de arquivos grandes (> BUFSIZ)
assert(writeto(file))
for i=1,5001 do write('0123456789123') end
write('012346')
writeto()
assert(readfrom(file))
x = read('*a')
seek(_INPUT, 'set', 0)
y = read(30001)..read(1005)..read(0)..read(1)..read(100003)
assert(x == y and strlen(x) == 5001*13 + 6)
seek(_INPUT, 'set', 0)
y = read('*u012346')
assert(x == y..'012346')
seek(_INPUT, 'set', 0)
y = read()  -- huge line
assert(x == y)
readfrom()
assert(remove(file))
x = nil; y = nil

assert(_INPUT == _STDIN and _OUTPUT == _STDOUT)
print'+'

local t = time()
T = date("*t", t)
assert(dostring(date([[assert(T.year==%Y and T.month==%m and T.day==%d and
  T.hour==%H and T.min==%M and T.sec==%S and
  T.wday==%w+1 and T.yday==%j and tonumber(T.isdst))]], t)))

assert(time(T) == t)

T = date("!*t", t)
assert(dostring(date([[!assert(T.year==%Y and T.month==%m and T.day==%d and
  T.hour==%H and T.min==%M and T.sec==%S and
  T.wday==%w+1 and T.yday==%j and tonumber(T.isdst))]], t)))

t = time(T)
T.year = T.year-1;
local t1 = time(T)
-- allow for leap years
assert(abs(difftime(t,t1)/(24*3600) - 365) < 2)

t = time()
t1 = time(date("*t"))
assert(difftime(t1,t) <= 2)

t1 = time{year=2000, month=10, day=1, hour=23, min=12, sec=17}
t2 = time{year=2000, month=10, day=1, hour=23, min=10, sec=19}
assert(difftime(t1,t2) == 60*2-2)

meses = { 'janeiro', 'fevereiro', 'março', 'abril',
'maio', 'junho', 'julho', 'agosto',
'setembro', 'outubro', 'novembro', 'dezembro' }

dias = {'domingo', 'segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado'}
assert(writeto())
d = date('%d')
m = tonumber(date('%m'))
a = date('%Y')
ds = date('%w') + 1
h = date('%H')
min = date('%M')
s = date('%S')
write(format('%s\n', date()))
write(format('teste feito no dia %2.2d de %s de %4d (%s)',
          d, meses[m], a, dias[ds]))
write(format(', as %2.2dh%2.2dm%2.2ds\n', h, min, s))
write(format('%s\n', _VERSION))
