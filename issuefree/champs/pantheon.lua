require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Pantheon")
pp(" - Don't interrupt channels")
pp(" - Spear if they're approaching")
pp(" - Dive if they're out of aa range")
pp(" - Strike if they're near")
pp(" - Spear if they're running")
pp(" - Spear to lasthit far minions if I have mana")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("dive", {on=false, key=113, label="Dive"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "spear"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})

spells["spear"] = {
  key="Q", 
  range=600, 
  color=violet, 
  base={65,105,145,185,225}, 
  adBonus=1.4,
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
  range=600, 
  color=red, 
  base={39,69,99,129,159}, 
  adBonus=1.8,
  cone=60,
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

local strikeTime = 0
local skyfallTime = 0

local function isStriking()
   if P.strike then
      CHANNELLING = true
      return true
   end
   if time() - strikeTime < 1 then
      CHANNELLING = true
      return true
   end
   CHANNELLING = false
   return false
end

local function isSkyfall()
   if P.skyfall then
      CHANNELLING = true
      return true
   end
   if time() - skyfallTime < 1 then
      CHANNELLING = true
      return true
   end
   CHANNELLING = false
   return false
end


function Run()
   if StartTickActions() then
      return true
   end

   if isStriking() then
      PrintAction("Striking") 
      return true
   end

   if isSkyfall() then
      PrintAction("Skyfalling")  
      return true
   end

   if CheckDisrupt("aegis") then
      return true
   end

   if HotKey() and CanAct() then
      UseItems()
      if Action() then
         return true
      end
   end 

   if VeryAlone() and IsOn("lasthit") then
      if KillMinionsInCone("strike", 3) then
         PrintAction("Strike for lasthits")
         return true
      end
   end    

   if Alone() then
      -- auto stuff that should happen if you didn't do something more important
      if IsOn("lasthit") and CanUse("spear") and me.mana/me.maxMana > .75 then
         local minions = SortByHealth(GetInRange(me, "spear", MINIONS), "spear")
         for _,minion in ipairs(minions) do
            if GetDistance(minion) > spells["AA"].range and
               WillKill("spear", minion)
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
   if CanUse("spear") then
      local target = GetMarkedTarget() or GetWeakestEnemy("spear")
      if target and FacingMe(target) then
         Cast("spear", target)
         PrintAction("Spear first", target)
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
      local target = GetWeakEnemy("PHYS", 400)
      if target then
         Cast("strike", target)
         PrintAction("Strike", target)
         return true
      end
   end

   if CanUse("spear") then
      local target = GetMarkedTarget() or GetWeakestEnemy("spear")
      if target then
         Cast("spear", target)
         PrintAction("Spear followup", target)
         return true
      end
   end

   local target = GetMarkedTarget() or GetMeleeTarget()
   if AutoAA(target) then
      return true
   end

   return false
end

function FollowUp()
   if IsOn("move") then
      if MeleeMove() then
         return false
      end
   end

   return false
end

local function onObject(object)
   PersistBuff("strike", object, "pantheon_heartseeker_cas2", 150)
   PersistBuff("skyfall", object, "pantheon_grandskyfall_cas", 150)
end

local function onSpell(object, spell)
   if object.charName == me.charName and
      find(spell.name, "Heartseeker")
   then
      strikeTime = time()
   end
   if object.charName == me.charName and
      find(spell.name, "GrandSkyfall")
   then
      skyfallTime = time()
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
