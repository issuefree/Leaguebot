foo = {1,2,3,4,5}

function FilterList(list, f)
   local res = {}
   for _,item in ipairs(list) do
      if f(item) then
         table.insert(res, item)
      end
   end
   return res
end

res = FilterList(foo, function(item) return item > 2 end)

for k,v in pairs(res) do
   print(k,v)
end