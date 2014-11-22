require "issuefree/timCommon"

local num = 10
local objects = {}
local spells = {}

local range = 250

local ignoredObjects = {"Minion", "DrawFX", "Mfx_", "mm_ba", "cm_ba"}

local testShot
local testShotDelays = {}
local testShotSpeeds = {}

function debugTick()
   if testShot then
      if time() - testShot.castTime > 2 then
         testShot.object = nil
      else
         if Point(testShot.object):valid() then
            if GetDistance(testShot.object) > 200 then
               Circle(testShot.object)
               table.insert(testShot.points, Point(testShot.object))
               table.insert(testShot.times, time())

               -- else
               -- end
            end
         else
            local total = 0
            if #testShot.points > 1 then
               for i=2,#testShot.points do
                  local d = GetDistance(testShot.points[i], testShot.points[1])
                  local t = testShot.times[i] - testShot.times[1]
                  local speed = d/t
                  -- pp(speed)
                  total = total + speed
               end
               speed = total/(#testShot.points-1)
               table.insert(testShotSpeeds, speed)
               pp("Speed: "..trunc(speed))
               pp("\n -> "..trunc(sum(testShotDelays)/#testShotDelays).." "..trunc(sum(testShotSpeeds)/#testShotSpeeds/100).." <-")
               testShot = nil
            end
         end
      end
   end

   if not ModuleConfig.debug then
      return
   end
   Circle(GetMousePos(), range, blue) 

   PrintState(-5, me.SpellNameQ.."  "..me.SpellTimeQ)
   PrintState(-4, me.SpellNameW.."  "..me.SpellTimeW)
   PrintState(-3, me.SpellNameE.."  "..me.SpellTimeE)
   PrintState(-2, me.SpellNameR.."  "..me.SpellTimeR)

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
         local exclude = false
         if testShot.excludes then
            for _,cn in ipairs(testShot.excludes) do
               if find(object.charName, cn) then
                  exclude = true
                  break
               end
            end
         end
         if not exclude then
            pp("Particle: "..object.charName)
            local delay = trunc(time() - testShot.castTime)
            delay = delay - 2*.05 -- lag
            delay = delay * 10  -- leaguebot units 
            table.insert(testShotDelays, delay)
            pp("Delay: "..delay)
            testShot.object = object
         end
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

function TestSkillShot(thing, charName, excludes)
   local spell = GetSpell(thing)

   if CanUse(spell) then
      CastXYZ(spell, mousePos)
      testShot = {}
      testShot.spell = spell
      testShot.charName = charName
      testShot.excludes = excludes
      testShot.castTime = time()
      testShot.points = {}
      testShot.times = {}
      StartChannel(1)
   end
end

AddOnSpell(onSpell)
AddOnCreate(onObject)

SetTimerCallback("debugTick")
