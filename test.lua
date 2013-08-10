local function table_print (tt, indent, done)
   done = done or {}
   indent = indent or 0
   if type(tt) == "table" then
      local sb = {}
      for key, value in pairs (tt) do
         table.insert(sb, string.rep (" ", indent)) -- indent it
         if type (value) == "table" and not done [value] then
            done [value] = true
            table.insert(sb, "{\n");
            table.insert(sb, table_print (value, indent + 2, done))
            table.insert(sb, string.rep (" ", indent)) -- indent it
            table.insert(sb, "}\n");
         elseif "number" == type(key) then
            table.insert(sb, string.format("\"%s\"\n", tostring(value)))
         else
            table.insert(sb, string.format(
            "%s = \"%s\"\n", tostring (key), tostring(value)))
         end
      end
      return table.concat(sb)
   else
      return tt .. "\n"
   end
end

function pp(str)
   if str == nil then
      pp("nil")
   elseif type(str) == "table" then
      pp(table_print(str, 2))
   else
      print(str)
   end
end

function concat(...)
   local resTable = {}
   for _,tablex in ipairs(arg) do
      if type(tablex) == "table" then
         for _,v in ipairs(tablex) do
            table.insert(resTable, v)
         end
      else
         table.insert(resTable, tablex)
      end      
   end
   return resTable
end

function foo()
   return 1, 2
end

function t(a, b)
   pp(a.." "..b)
end

t(foo())


