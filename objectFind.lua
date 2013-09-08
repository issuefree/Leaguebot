require "timCommon"

local num = 10
local objects = {}
local spells = {}

local range = 200

local ignoredObjects = {"Minion", "PurpleWiz", "BlueWiz", "DrawFX"}

function debugTick()
   if not ModuleConfig.debug then
      return
   end
   Circle(GetMousePos(), range, blue) 

   objects = {}
   for i = 1, objManager:GetMaxObjects(), 1 do
      local object = objManager:GetObject(i)
      if object and object.x and object.charName and
         GetDistance(object, GetMousePos()) < range 
      then
         if not ListContains(object.charName, ignoredObjects) then
            table.insert(objects, object.charName.."      "..object.name)
         end
      end
   end
      
   if #spells > num then   
      for i = 1, #spells - num do
         table.remove(spells, 1)
      end
   end
   
   PrintState(1, "Objects: chN     N")
   for i, object in ipairs(objects) do
      PrintState(i+1, objects[i])
   end

   PrintState(21, "Spells")
   for i, spell in ipairs(spells) do
      PrintState(21+i, spells[i])
   end

   if CanAttack() then
      setAttackState(0)
      PrintState(0, "!")
   end
   if IsAttacking() then
      setAttackState(1)
      PrintState(0, "  -")
   end
   if waitingForAttack() then
      setAttackState(2)
      PrintState(0, "  --")
   end
   if JustAttacked() then
      PrintState(0, "    :")
   end
   if CanAct() then
      setAttackState(3)
      PrintState(0, "       )")
   end
   if CanMove() then
      setAttackState(4)
      PrintState(0, "         >")
   end

   -- PrintState(1, (1 / me.attackspeed))
   -- PrintState(2, me.attackspeed)
end

local function onSpell(unit, spell)
   if not ModuleConfig.debug then
      return
   end
   if find(unit.charName, "Minion") then
      return
   end   
   if GetDistance(unit) < range or GetDistance(unit, GetMousePos()) < range then
      if spell.target and spell.target.charName then
         table.insert(spells, unit.name.." : "..spell.name.." -> "..spell.target.charName)
         pp(unit.name.." : "..spell.name.." -> "..spell.target.charName)
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
         pp(unit.name.." : "..spell.name)
      end
   end
end

local function onObject(object)
   if not ModuleConfig.debug then
      return
   end
   if GetDistance(object, GetMousePos()) < range then
      if not ListContains(object.charName, ignoredObjects) then
         pp(object.charName.."      "..object.name)
      end
   end
end

ModuleConfig:addParam("debug", "Debug Objects", SCRIPT_PARAM_ONOFF, false)
ModuleConfig:permaShow("debug")

AddOnSpell(onSpell)
AddOnCreate(onObject)

SetTimerCallback("debugTick")
