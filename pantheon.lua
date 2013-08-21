require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Pantheon")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("dive", {on=false, key=113, label="Dive"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["spear"] = {
  key="Q", 
  range=602, 
  color=violet, 
  base={65,105,145,185,225}, 
  bonusAd=1.4,
  type="P",
  cost=45
}
spells["aegis"] = {
  key="W", 
  range=600, 
  color=yellow, 
  base={50,75,100,125,150}, 
  ap=1,
  cost=55
}
spells["strike"] = {
  key="E", 
  range=598, 
  color=red, 
  base={78,138,198,258,318}, 
  bonusAd=3.6,
  type="P",
  cost={45,50,55,60,65}
}
spells["skyfall"] = {
  key="R", 
  range=5500, 
  color=red, 
  base={400,700,1000}, 
  ap=1,
  cost=125,
  radius=1000
}

local strike = nil
local strikeTime = 0

local function isStriking()
   if Check(strike) then
      return true
   end
   if time() - strikeTime < 1 then
      return true
   end
   return false
end

function Run()
   TimTick()

   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return
   end

   if isStriking() then
      PrintAction("Striking")
      return true
   end

   UseAutoItems()

   -- auto stuff that always happen

   -- high priority hotkey actions, e.g. killing enemies
   if HotKey() and CanAct() then
      if Action() then
         return
      end
   end

   if Alone() then
      -- auto stuff that should happen if you didn't do something more important
      if IsOn("lasthit") and CanUse("spear") and me.mana/me.maxMana > .75 then
         local minions = SortByHealth(GetInRange(me, "spear", MINIONS))
         for _,minion in ipairs(minions) do
            if GetDistance(minion) > spells["AA"].range and
               GetSpellDamage("spear", minion) > minion.health
            then
               Cast("spear", minion)
               PrintAction("Spear for lasthit")
               return true
            end
         end
      end
   end

   -- low priority hotkey actions, e.g. killing minions, moving
   if HotKey() and CanAct() then
      if FollowUp() then
         return
      end
   end
end

function Action()
   UseItems()

   if CanUse("spear") then
      local target = GetMarkedTarget() or GetWeakestEnemy("spear")
      if target then
         Cast("spear", target)
         PrintAction("Spear", target)
         return true
      end
   end

   if IsOn("dive") and CanUse("aegis") then
      local target = GetMarkedTarget() or GetWeakestEnemy("aegis")
      if target and
         GetDistance(target) > spells["AA"].range
      then
         Cast("aegis", target)
         PrintAction("Aegis", target)
         return true
      end
   end

   if CanUse("strike") then
      -- I want to hit them a couple times so don't go for things right on the edge
      local target = GetWeakEnemy("PHYS", 300)
      if target then
         Cast("strike", target)
         PrintAction("Strike", target)
         return true
      end
   end

   local target = GetMarkedTarget() or GetWeakEnemy("PHYS", spells["AA"].range*2)
   if AA(target) then
      PrintAction("AA", target)
      return true
   end

   return false
end

function FollowUp()
   if IsOn("lasthit") and Alone() then
      if KillWeakMinion("AA") then
         PrintAction("AA lasthit")
         return true
      end
   end

   if IsOn("clearminions") and Alone() then
      -- hit the highest health minion
      local minions = SortByHealth(GetInRange(me, "AA", MINIONS))
      if AA(minions[#minions]) then
         PrintAction("AA clear minions")
         return true
      end
   end

   if IsOn("move") then
      local target = GetMarkedTarget() or GetWeakEnemy("PHYS", spells["AA"].range*2)
      if target then
         if GetDistance(target) > spells["AA"].range then
            MoveToTarget(target)
            PrintAction("MTT")
            return false
         end
      else        
         MoveToCursor() 
         PrintAction("Move")
         return false
      end
   end

   return false
end

local function onObject(object)
   if find(object.charName,"pantheon_heartseeker_cas2") and 
      GetDistance(object) < 150
   then
      strike = StateObj(object)
   end   
end

local function onSpell(object, spell)
   if object.charName == me.charName and
      find(spell.name, "Heartseeker")
   then
      strikeTime = time()
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
