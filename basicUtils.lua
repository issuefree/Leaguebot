-- globals for convenience
me = GetSelf()

function class()
    local cls = {}
    cls.__index = cls
    return setmetatable(cls, {__call = function (c, ...)
        local instance = setmetatable({}, cls)
        if cls.__init then
            cls.__init(instance, ...)
        end
        return instance
    end})
end

local function table_print(tt, indent, done)
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
            table.insert(sb, string.format("%s = \"%s\"\n", tostring (key), tostring(value)))
         end
      end
      return table.concat(sb)
   else
      return tt .. "\n"
   end
end

function time()
   return os.clock()
end

function pp(str)
   if str == nil then
      pp("nil")
   elseif type(str) == "table" then
      pp(table_print(str, 2))
   elseif type(str) == "userdata" then
      if str.charName then
         pp(str.charName..": "..str.id)
         pp("  ("..math.floor(str.x+.5)..","..math.floor(str.z+.5)..")")
      end
   else
      printtext(tostring(str).."\n")
   end
end


function merge(table1, table2)
   local resTable = {}
   for k,v in pairs(table1) do
      resTable[k] = v
   end
   for k,v in pairs(table2) do
      resTable[k] = v
   end
   return resTable
end

function reverse(table)
   local reversedTable = {}
   local itemCount = #t
   for k, v in ipairs(t) do
       reversedTable[itemCount + 1 - k] = v
   end
   return reversedTable
end

function concat(...)
   local resTable = {}
   for _,tablex in ipairs(GetVarArg(...)) do
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

function rpairs(t)
   return prev, t, table.getn(t)+1
end

function prev(t, i)
   if i == 1 then
      return nil
   end
   return i-1, t[i-1]
end

local line = 0
function PrintState(state, str)
   DrawText(str,100,100+state*15,0xFFCCEECC);
end

function ClearState(state)
   printStates[state+1] = ""
end

function find(source, target)
   if not source then
      return false
   end
   if string.len(target) == 0 then
      return false
   end
   return string.find(string.lower(source), string.lower(target))
end

function copy(orig)
   local orig_type = type(orig)
   local copy
   if orig_type == 'table' then
      copy = {}
      for orig_key, orig_value in pairs(orig) do
         copy[orig_key] = orig_value
      end
   else -- number, string, boolean, etc
      copy = orig
   end
   return copy
end

function FilterList(list, f)
   local res = {}
   for _,item in ipairs(list) do
      if f(item) then
         table.insert(res, item)
      end
   end
   return res
end

function ListContains(item, list, exact)
   if type(item) ~= "string" then
      exact = true
   end
   for _,test in pairs(list) do
      if exact then
         if item == test then return true end
      else
         if find(item, test) then return true end
      end
   end
   return false
end

function GetIntersection(list1, list2)
   local intersection = {}
   for _,v1 in ipairs(list1) do
      for _,v2 in ipairs(list2) do
         if v1 == v2 then
            table.insert(intersection, v1)
         end
      end
   end
   return intersection
end

function SameUnit(o1, o2)
   return o1.name == o2.name and
          o1.charName == o2.charName and
          o1.x == o2.x and
          o1.z == o2.z
end

function IsMe(unit)
   return SameUnit(me, unit)
end