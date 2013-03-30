require "timCommon"

local num = 10
local objects = {}
local spells = {}

local range = 100

function debugTick()
   if not ModuleConfig.debug then
      return
   end
   DrawCircle(GetMousePos().x, GetMousePos().y, GetMousePos().z, range, blue) 

   objects = {}
   for i = 1, objManager:GetMaxObjects(), 1 do
      local object = objManager:GetObject(i)
      if object and object.x and object.charName and
         GetDistance(object, GetMousePos()) < 100 then
         table.insert(objects, object.charName.."      "..object.name)
      end
   end
      
   if #spells > num then   
      for i = 1, #spells - num do
         table.remove(spells, 1)
      end
   end
   
   PrintState(1, "Objects")
   for i, object in ipairs(objects) do
      PrintState(i+1, objects[i])
   end

   PrintState(21, "Spells")
   for i, spell in ipairs(spells) do
      PrintState(21+i, spells[i])
   end
end

local function onSpell(unit, spell)
   if not ModuleConfig.debug then
      return
   end
   if GetDistance(unit) < 100 or GetDistance(unit, GetMousePos()) < 100 then
      if spell.target and spell.target.charName then
         table.insert(spells, unit.name.." : "..spell.name.." -> "..spell.target.charName)
      else
         if spell.endPos then
--            if GetDistance(unit, spell.endPos) > GetDistance(unit, EADC) then
--               if math.abs(AngleBetween(unit, EADC) - AngleBetween(unit, spell.endPos)) < 10 then
--                  table.insert(spells, unit.name.." : "..spell.name.." ~> "..EADC.name)                  
--               else
--                  pp(math.abs(AngleBetween(unit, EADC) - AngleBetween(unit, spell.endPos)))
--               end
--            else
--               pp(GetDistance(unit, spell.endPos).." "..GetDistance(unit, EADC))
--            end
         end
         table.insert(spells, unit.name.." : "..spell.name)
      end
   end
end

local function onObject(object)
--   if GetDistance(object, GetMousePos()) < 100 then
--      table.insert(objects, object.charName)
--   end
end

ModuleConfig:addParam("debug", "Debug Objects", SCRIPT_PARAM_ONOFF, false)
ModuleConfig:permaShow("debug")

AddOnSpell(onSpell)
AddOnSpell(onObject)

SetTimerCallback("debugTick")
