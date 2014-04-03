require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Miss Fortune")

function doubleUpDam()
   return GetSpellDamage("double")*1.2
end

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
-- AddToggle("double", {on=false, key=113, label="DoubleUp Enemies", auxLabel="{0}", args={doubleUpDam}})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["double"] = {
   key="Q", 
   range=spells["AA"].range, 
   color=violet, 
   base={30,72,114,156,198},
   ad=.9,
   type="P",
   cost={70,75,80,85,90},
   radius=500,
   onhit=true -- not sheen so watch for that
}
spells["impure"] = {
   key="W",
   base={6,8,10,12,14},
   ap=.05,
   cost=50
}
spells["rain"] = {
   key="E", 
   range=800, 
   color=yellow, 
   base={90,145,195,255,310}, 
   ap=.8,
   radius=200,
   cost=80
}
spells["bullet"] = {
   key="R", 
   range=1400, 
   color=red, 
   base={520,760,1000}, 
   adBonus=2.8,
   ap=1.6,
   cost=100
}

function GetBestDouble(target, targets, goodTargets)
   if not goodTargets then
      goodTargets = targets
   end
   local ta = AngleBetween(me, target)
   local bdt
   local bdta = 1000
   for _,dt in ipairs(targets) do
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
   spells["AA"].bonus = GetSpellDamage("impure")

   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return
   end

   if IsChannelling(P.bulletTime) then
      CHANNELLING = true
      return true
   end
   if CHANNELLING then
   end
   CHANNELLING = false

   if HotKey() and CanAct() then
      UseItems()
      if Action() then
         return true
      end
   end   

   if IsOn("lasthit") and VeryAlone() then
      if CanUse("double") and GetMPerc() > .75 then
         local minions = SortByHealth(GetInRange(me, "double", MINIONS))
         local lowMinions = GetKills("double", GetInRange(me, GetSpellRange("double")+spells["double"].radius, MINIONS))
         for _,t in ipairs(minions) do
            local bta = GetBestDouble(t, minions, lowMinions)
            if bta then
               Cast("double", t)
               PrintAction("Double for lasthit")
               return true
            end
         end
      end
   end

   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end
   
end

function Action()
   if CanUse("double") then 
      local bestDT
      local bestDTA
      for _,t in ipairs(GetInRange(me, GetSpellRange("double")+250, MINIONS, ENEMIES)) do
         local doubleTargets = GetInRange(t, spells["double"].radius, MINIONS, ENEMIES) 
         local bt, bta = GetBestDouble(t, doubleTargets, ENEMIES)
         if bt then
            Circle(t, 60, blue)
            LineBetween(t, bt)
            Circle(bt, 45, yellow)
            if not bestDT or bta < bestDTA then
               bestDT = t
               bestDTA = bta
            end
         end
      end
      if bestDT and GetDistance(bestDT) < GetSpellRange("double") then
         Cast("double", bestDT)
         PrintAction("Double", bestDT)
         return true
      end
   end

   if CanUse("impure") then
      local target = GetMarkedTarget() or GetWeakestEnemy("AA")
      if target then
         Cast("impure", me)         
         PrintAction("Impure")
      end
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AA(target) then
      PrintAction("AA", target)
      return true
   end

   return false
end

function FollowUp()
   if IsOn("lasthit") and Alone() then
      if KillMinion("AA") then
         return true
      end
   end

   if IsOn("clearminions") and Alone() then
      if HitMinion("AA", "strong") then
         return true
      end
   end

   if IsOn("move") then
      if RangedMove() then
         return true
      end
   end

   return false
end

local function onObject(object)
   Persist("bulletTime", object, "missFortune_bulletTime")
end

local function onSpell(unit, spell)
   if unit.charName == me.charName and find(spell.name, "MissFortuneBulletTime") then
      StartChannel()
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")