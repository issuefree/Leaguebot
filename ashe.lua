require "Utils"
require "timCommon"
require "modules"

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
   delay=2,
   speed=16,
   width=160,
   radius=250,
   cost=150
}

local frostTime = 0

function Run()
   if IsRecalling(me) or me.dead == 1 then
      return
   end

   if Alone() then
      if P.frost and time() - frostTime > .5 then
         frostTime = time()
         Cast("frost", me)
         PrintAction("Frost OFF")
      end
   end

   if HotKey() and CanAct() then
      if Action() then
         return true
      end
   end   

   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end
end

function Action()
   UseItems()

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
      if not P.frost and time() - frostTime > .5 and
         GetDistance(target) < GetSpellRange("AA") 
      then
         Cast("frost", me)
         frostTime = time()
         PrintAction("Frost ON")
      end      

      if AA(target) then
         PrintAction("AA", target)
         return true
      end
   end

   return false
end

function FollowUp()
   if IsOn("lasthit") and Alone() then
      if KillWeakMinion("AA") then
         PrintAction("lasthit")
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
      PrintAction("move")
      MoveToCursor()
      return false   
   end

   return false
end
   

local function onObject(object)
   PersistBuff("frost", object, "iceSparkle", 125)
end

local function onSpell(unit, spell)
   if unit.name == me.name and find(spell.name, "FrostShot") then
      frostTime = time()
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
