require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Miss Fortune")

function doubleUpDam()
   return GetSpellDamage("double")*1.2
end

AddToggle("farm", {on=false, key=112, label="Auto Farm"})
AddToggle("double", {on=false, key=113, label="DoubleUp Enemies", auxLabel="{0}", args={doubleUpDam}})

spells["double"] = {
   key="Q", 
   range=spells["AA"].range, 
   color=violet, 
   base={25,60,95,130,165},
   ad=.75,
   type="P"
}
spells["rain"] = {
   key="E", 
   range=800, 
   color=yellow, 
   base={90,145,195,255,310}, 
   ap=.8,
   area=200
}
spells["bullet"] = {
   key="R", 
   range=1400, 
   color=red, 
   base={520,760,1000}, 
   adBonus=2.8,
   ap=1.6
}

local Q = spells["double"]
local E = spells["rain"]
local R = spells["bullet"]

local bulletTime

function GetBestDouble(target, targets, goodTargets)
   if not goodTargets then
      goodTargets = targets
   end
   local ta = AngleBetween(me, target)
   local bdt
   local bdta = 1000
   for i,dt in ipairs(targets) do
      if target ~= dt then
         local dta = math.abs(ta - AngleBetween(target, dt))
         if dta > 3*math.pi/2 then
            dta = dta - math.pi
         end
         if dta < math.pi/2 or dta > 3*math.pi/2 then
            if dta < bdta then
               bdt = dt
               bdta = dta
            end
         end
      end
   end
   if bdt then
      for _,gt in ipairs(goodTargets) do
         if bdt == gt then
            return bdt, bdta
         end
      end
   end

end
   

function Run()
   TimTick()
   if me.dead == 1 then
      return
   end
   if IsRecalling(me) then
      return
   end 
   if Check(bulletTime) then
      return
   end
   if HotKey() then
      UseItems()
   end
--   local t = GetMousePos()
--   t.y = me.y
--   local t2 = {x=t.x+250, y=t.y, z=t.z+150}
--   local t3 = {x=t.x-250, y=t.y, z=t.z+150}
--   
--   DrawCircle(t.x, t.y, t.z, 20, blue)
--   DrawCircle(t2.x, t2.y, t2.z, 20, red)
--   DrawCircle(t3.x, t3.y, t3.z, 20, red)
   
   if CanUse("double") and (IsOn("double") or HotKey()) then 
      local bestDT
      local bestDTA
      for _,t in ipairs(GetInRange(me, Q.range+250, MINIONS, GetVis(ENEMIES))) do
         local doubleTargets = GetInRange(t, 500, MINIONS, GetVis(ENEMIES)) 
         local bt, bta = GetBestDouble(t, doubleTargets, ENEMIES)
         if bt then
            DrawCircleObject(t, 60, blue)
            LineBetween(t, bt)
            DrawCircle(bt.x, bt.y, bt.z, 45, yellow)
            if not bestDT or bta < bestDTA then
               bestDT = t
               bestDTA = bta
            end
         end
      end
      if bestDT and GetDistance(bestDT) < Q.range and CanUse("double") then
         CastSpellTarget("Q", bestDT)
      end
   end

   local near = GetWeakEnemy("PHYS", 850)
   if IsOn("farm") and not near then
      KillWeakMinion("AA")
      if CanUse("double") then
         local minions = GetInRange(me, Q.range, MINIONS)
         SortByHealth(minions)
         local lowMinions = FilterList(
            GetInRange(me, Q.range+500, MINIONS), 
               function(item) 
                  return item.health < GetSpellDamage("double", item) 
               end
         )
         for _,t in ipairs(minions) do
            local bta = GetBestDouble(t, minions, lowMinions)
            if bta then
               CastSpellTarget("Q", t)
               break
            end
         end
      end
   end
   
end

local function onObject(object)
   if find(object.charName, "missFortune_bulletTime") then
      bulletTime = {object.charName, object}
   end 
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
