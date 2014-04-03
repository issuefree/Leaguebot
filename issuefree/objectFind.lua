require "issuefree/timCommon"

local num = 10
local objects = {}
local spells = {}

local range = 200

local ignoredObjects = {"Minion", "PurpleWiz", "BlueWiz", "DrawFX"}

local testShot
local testShotDelays = {}
local testShotSpeeds = {}

function debugTick()
   if testShot then
      if testShot.object and GetDistance(testShot.object) > 200 then
         if not testShot.firstPoint then
            testShot.firstPoint = Point(testShot.object)
            testShot.firstTime = time()
         elseif not testShot.nextPoint then
            testShot.nextPoint = Point(testShot.object)
            testShot.nextTime = time()
         else
            local d = GetDistance(testShot.firstPoint, Point(testShot.object))
            local t = time() - testShot.firstTime
            local speed = d/t
            table.insert(testShotSpeeds, speed)
            pp("Speed: "..trunc(speed))
            pp("\n -> "..trunc(sum(testShotDelays)/#testShotDelays).." "..trunc(sum(testShotSpeeds)/#testShotSpeeds/100).." <-")
            testShot = nil
         end
      elseif time() - testShot.castTime > 2 then
         testShot = nil
      end
   end

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
         table.insert(spells, unit.name.." : "..spell.name.." -> "..spell.target.name)
         pp(unit.name.." : "..spell.name.." -> "..spell.target.name)
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
   if testShot and not testShot.object then
      if GetDistance(object) < 1000 and
         object.charName ~= "LineMissile" and
         object.charName ~= "missile" and
         not find(object.charName, "DrawFX") and
         not find(object.charName, "FountainHeal") and
         not find(object.charName, "LevelProp") and
         not find(object.charName, "Minion") and
         not find(object.charName, "Audio") and
         not find(object.charName, "Mfx") and
         not find(object.charName, "ElixirSight") and
         ( not testShot.charName or find(object.charName, testShot.charName) )
      then
         pp("Particle: "..object.charName)
         local delay = trunc(time() - testShot.castTime)
         delay = delay - 2*.05 -- lag
         delay = delay * 10  -- leaguebot units 
         table.insert(testShotDelays, delay)
         pp("Delay: "..delay)
         testShot.object = object
      end
   end

   if not ModuleConfig.debug then
      return
   end
   if GetDistance(object, GetMousePos()) < range then
      if not ListContains(object.charName, ignoredObjects) then
         pp(object.charName.."      "..object.charName)
      end
   end
end

function TestSkillShot(thing, charName)
   local spell = GetSpell(thing)

   if CanUse(spell) then
      CastXYZ(spell, mousePos)
      testShot = {}
      testShot.spell = spell
      testShot.charName = charName
      testShot.castTime = time()
   end
end

AddOnSpell(onSpell)
AddOnCreate(onObject)

SetTimerCallback("debugTick")
