require "basicUtils"
require "spellUtils"

-- globals for the toggle menus
keyToggles = {}
toggleOrder = {}

function AddToggle(key, value)
   keyToggles[key] = value
   table.insert(toggleOrder, key)
end

function IsOn(key)
   return keyToggles[key].on
end

local pressed = {}
function checkToggles()
   for _,toggle in pairs(keyToggles) do      
      local key = toggle.key     
      if IsKeyDown(key) == 1 then
         pressed[key] = true
      elseif IsKeyDown(key) == 0 then
         if pressed[key] == true then 
            toggle.on = not toggle.on 
            pressed[key] = false
         end
      end
   end
   DrawToggles()
end

local labelX = 320
local labelY = 960
function DrawToggles()
   for i,key in ipairs(toggleOrder) do
      local val = keyToggles[key]
      local label = val.label
      local auxLabel = val.auxLabel
      if val.args then
         for a,v in ipairs(val.args) do
            local arg = expandToggleArg(val.args[a])           
            label = string.gsub(label, "{"..(a-1).."}", arg)
            auxLabel = string.gsub(auxLabel, "{"..(a-1).."}", arg)
         end
      end
      if val.on then
         DrawText(label,labelX,labelY+(i-1)*15,0xFF00EE00);
         if auxLabel then        
            DrawText(auxLabel,labelX+150,labelY+(i-1)*15,0xFF00EE00);
         end
      else
         DrawText(label,labelX,labelY+(i-1)*15,0xFFFFFF00);
         if auxLabel then
            DrawText(auxLabel,labelX+150,labelY+(i-1)*15,0xFFFFFF00);
         end
      end
   end   
end

function expandToggleArg(arg)
   if type(arg) == "string" then
      return GetSpellDamage(arg) 
   elseif type(arg) == "function" then
      return arg()
   end
end