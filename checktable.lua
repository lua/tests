
assert(stat == nil)  -- module not loaded before

if T == nil then
  stat = function () print"`querytab' nao ativo" end
  return
end


function checktable (t)
  local size, ff = T.querytab(t)
  local l = {}
  for i=0,size-1 do
    local key,val,next = T.querytab(t, i)
    if not key then
      assert(l[i] == nil and val==nil and next==nil)
    elseif key == "<undef>" then
      assert(val==nil)
    else
      local mp = T.hash(key, t)
      assert(t[key] == val)
      if l[i] then
        assert(l[i] == mp)
      elseif mp ~= i then
        l[i] = mp
      else  -- list head
        l[mp] = {mp; n=1}   -- first element
        while next do
          assert(size > next and next > ff)
          if l[next] then assert(l[next] == mp) else l[next] = mp end
          tinsert(l[mp], next)
          key,val,next = T.querytab(t, next)
          assert(key)
        end
      end
    end
  end
  assert(l[ff] == nil)
  l.size = size; l.ff = ff
  return l
end

function mostra (t)
  local size, ff = T.querytab(t)
  print(size, ff)
  for i=0,size-1 do
    print(i, T.querytab(t, i))
  end
end

function stat (t)
  t = checktable(t)
  local nelem, nlist = 0, 0
  local maxlist = {}
  for i=0,t.size-1 do
    if type(t[i]) == 'table' then
      local n = t[i].n
      nlist = nlist+1
      nelem = nelem + n
      if not maxlist[n] then maxlist[n] = 0 end
      maxlist[n] = maxlist[n]+1
    end
  end
  print(format("size=%d  elements=%d  load=%.2f  med.len=%.2f",
          t.size, nelem, nelem/t.size, nelem/nlist))
  for i=1,getn(maxlist) do
    n = maxlist[i] or 0
    print(format("%5d %10d %.2f%%", i, n, n*100/nlist))
  end
end

