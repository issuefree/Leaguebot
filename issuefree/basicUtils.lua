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
            table.insert(sb, tostring(key).." = {\n");
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
   if not str then
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

function trunc(num, places)
   if not places then places = 2 end
   local factor = 10^places
   return math.floor(num*factor)/factor
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

function reverse(t)
   local reversedTable = {}
   local itemCount = #t
   for k, v in ipairs(t) do
       reversedTable[itemCount + 1 - k] = v
   end
   return reversedTable
end

function sum(t)
   local total = 0
   for _,v in ipairs(t) do
      total = total + v
   end
   return total
end

function max(t)
   local max
   for _,v in ipairs(t) do
      if not max or v > max then
         max = v
      end
   end
   return max
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

function startsWith(source, target)
   local s, e = find(source, target)
   if s then
      return s == 1
   end
   return false
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

OBJECT_CALLBACKS = {}
SPELL_CALLBACKS = {}

function AddOnTick(callback)
   RegisterLibraryOnTick(callback)
end

function AddOnCreate(callback)
   table.insert(OBJECT_CALLBACKS, callback)
   -- RegisterLibraryOnCreateObj(callback)
end

function AddOnSpell(callback)
   -- table.insert(SPELL_CALLBACKS, callback)
   RegisterLibraryOnProcessSpell(callback)
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
   if not o1 or not o2 then return false end
   return o1.name == o2.name and
          o1.charName == o2.charName and
          o1.x == o2.x and
          o1.z == o2.z
end

function IsMe(unit)
   return SameUnit(me, unit)
end

function CalculateDamage(target, dam)
   if dam.m and dam.m > 0 then
      local res = math.max(target.magicArmor*me.magicPenPercent - me.magicPen, 0)
      dam.m = dam.m*(100/(100+res))
   end
   if dam.p and dam.p > 0 then
      local res = math.max(target.armor*me.armorPenPercent - me.armorPen, 0)
      dam.p = dam.p*(100/(100+res))
   end

   return dam:toNum()
end

Damage = class()
function Damage:__init(p, m, t)
   self.isDamage = true
   if m and type(m) == "string" then
      if type(p) ~= "number" then
         p = p:toNum()
      end
      if m == "P" then
         self.type = "P"
         self.p = p or 0
         self.m = 0
         self.t = 0
         return self
      elseif m == "T" then
         self.type = "T"
         self.p = 0
         self.m = 0
         self.t = p or 0
         return self
      elseif m == "M" then
         self.type = "M"
         self.p = 0
         self.m = p or 0
         self.t = 0
         return self
      elseif m == "H" then
         self.type = "H"
         self.p = 0
         self.m = 0
         self.t = p or 0
         return self
      end
   end

   self.p = p or 0
   self.m = m or 0
   self.t = t or 0
end
function Damage:__add(d)
   if not d then
      return self
   end

   if type(self) == "number" then
      return d+self
   end

   if type(d) == "number" then
      if d == 0 then
         return self
      end
      if self.type == "P" or ( self.p ~= 0 and self.m == 0 and self.t == 0 ) then
         self.p = self.p + d
         return self
      elseif self.type == "M" or ( self.p == 0 and self.m ~= 0 and self.t == 0 ) then
         self.m = self.m + d
         return self
      elseif self.type == "T" or ( self.p == 0 and self.m == 0 and self.t ~= 0 ) then
         self.t = self.t + d
         return self
      else
         pp(debug.traceback())
         return self
      end
   end
   return Damage(self.p+d.p, self.m+d.m, self.t+d.t)
end

function Damage:__sub(d)
   if not d then
      return self
   end

   if type(self) == "number" then
      return self-d:toNum()
   end

   if type(d) == "number" then
      return self + -d
   end
   return Damage(self.p-d.p, self.m-d.m, self.t-d.t)
end

function Damage:__mul(d)
   if type(self) == "number" then
      return d*self
   end

   return Damage(self.p*d, self.m*d, self.t*d)
end

function Damage:__div(d)
   assert(type(d) == "number")
   return Damage(self.p/d, self.m/d, self.t/d)
end

function Damage:__le(d)
   return self:toNum() <= d:toNum()
end

function Damage:__lt(d)
   return self:toNum() < d:toNum()
end

function Damage:__tostring()
   return tostring(self:toNum())
   -- return "{"..self.p..","..self.m..","..self.t.."}"
end

function Damage:toNum()
   return math.floor(self.p+self.m+self.t)
end

