require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Ashe")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["frost"] = {
   key="Q"
}

spells["volley"] = {
   key="W", 
   range=1100, 
   color=violet, 
   base={40,50,60,70,80}, 
   ad=1,
   delay=2.5,
   speed=20,
   cone=57.5,
   cost=60
}

spells["hawkshot"] = {
   key="E", 
   range={2500,3250,4000,4750,5500},
   color=blue
}

spells["arrow"] = {
   key="R",
   base={250,425,600}, 
   ap=1,
   delay=2.6,
   speed=16,
   width=160,
   radius=250,
   cost=100,
   particle="Ashe_Base_R_mis.troy",
   spellName="EnchantedCrystalArrow"
}

function Run()
   if StartTickActions() then
      return true
   end

   if GetMPerc(me) > .5 and CanChargeTear() or not Alone() then
      if not P.frost then         
         CastBuff("frost")
         -- PrintAction("Frost ON")
      end
   else      
      if P.frost then
         Cast("frost", me)
         -- PrintAction("Frost OFF")
         StartChannel()
      end
   end

   if HotKey() and CanAct() then
      UseItems()
      if Action() then
         return true
      end
   end   

   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()   
   -- TestSkillShot("arrow")

   if CanUse("volley") then
      local target = GetMarkedTarget() or GetWeakestEnemy("volley")
      if target then
         Cast("volley", target)
         PrintAction("Volley", target)
         return true
      end
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if target then
      if AA(target) then
         PrintAction("AA", target)
         return true
      end
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
      -- hit the highest health minion
      local minions = SortByHealth(GetInRange(me, "AA", MINIONS))
      if AA(minions[#minions]) then
         PrintAction("AA for clear")
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
   PersistBuff("frost", object, "Ashe_Base_q_buf", 125)
end

local function onSpell(unit, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
