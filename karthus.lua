require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Template")

AddToggle("farm", {on=true, key=112, label="Waste Minions", auxLabel="{0}", args={"lay"}})

spells["lay"] = {key="Q", range=875, color=violet, base={40,60,80,100,120}, ap=.3, radius=137.5}
spells["wall"] = {key="W", range=1000, color=yellow}
spells["defile"] = {key="E", range=550, color=yellow, base={30,50,70,90,110}, ap=.2}
spells["ult"] = {key="R", base={250,400,55}, ap=.6}

local defiling = nil

local function getLayFireAhead(target)
   return GetFireahead(target,5,999)
end

function Run()
   local target = GetWeakEnemy("MAGIC", 90000) 
   if target and CanUse("ult") and GetSpellDamage("ult", target) > target.health then
      PlaySound("Beep")
   end 
     
   if HotKey() then
      UseItems()
      
      target = GetWeakEnemy("MAGIC", spells["lay"].range)
      if target then
         if CanUse("lay") then
            local x, y, z = getLayFireAhead(target)
            CastSpellXYZ("Q", x,y,z)
         end
      end
      
      target = GetWeakEnemy("MAGIC", spells["defile"].range-50)      
      if target and not Check(defiling) and CanUse("defile") then
         CastSpellTarget("E", me)
      end
      
      target = GetWeakEnemy("MAGIC", spells["defile"].range+50)
      if target and Check(defiling) then
         CastSpellTarget("E", me)
      end
      
   end
   
   DrawCircle(GetMousePos().x, GetMousePos().y, GetMousePos().z, spells["lay"].radius, red)
   
   if IsRecalling(me) then
      return
   end
   
   if IsOn("farm") and not GetWeakEnemy("MAGIC", 1000) and CanUse("lay") then
      local wMinion = nil
      local wMinionK = 0
      local wMinionX = {}

      local nearMinions = GetInRange(me, spells["lay"].range, MINIONS)   
      for _,minion in ipairs(nearMinions) do
         local tK = 0
         local vnMinions = GetInRange(minion, spells["lay"].radius, nearMinions)
         if #vnMinions == 1 then
            if GetSpellDamage("lay", minion)*2 > minion.health then
               if not wMinion or wMinionK < 1 then
                  wMinion = minion
                  wMinionK = 1
                  local x, y, z = getLayFireAhead(wMinion)
                  wMinionX = {x=x,y=y,z=z}
                  DrawCircle(wMinionX.x, wMinionX.y, wMinionX.z, spells["lay"].radius, red)
                  DrawCircle(wMinionX.x, wMinionX.y, wMinionX.z, spells["lay"].radius+2, red)
               end
            end
         else
            for _,vnM in ipairs(vnMinions) do
               if GetSpellDamage("lay", vnM) > minion.health then
                  tK = tK + 1
               end
            end
            if wMinionK < tK then
               wMinion = minion
               wMinionK = tK
               local x, y, z = getLayFireAhead(wMinion)
               wMinionX = {x=x,y=y,z=z}
            end
         end
      end
      
      if wMinion then
--         CastSpellTarget("Q", wMinion)
         CastSpellXYZ("Q", wMinionX.x, wMinionX.y, wMinionX.z)
--         DrawCircleObject(wMinion, spells["lay"].radius, red)
         DrawCircle(wMinionX.x, wMinionX.y, wMinionX.z, spells["lay"].radius, yellow)
      end
   end   
end

local function onObject(object)
   if find(object.charName, "Defile_glow") and GetDistance(object) < 100 then
      defiling = {object.charName, object}
   end
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
