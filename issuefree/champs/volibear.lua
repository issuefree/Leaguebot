require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Volibear")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["thunder"] = {
   key="Q", 
   base={30,60,90,120,150}, 
   type="P",
   cost=40
} 
spells["frenzy"] = {
   key="W", 
   range=400,
   color=violet, 
   base={80,125,170,215,260}, 
   bonusHealth=.15,
   type="P",
   cost=35
} 
spells["roar"] = {
   key="E", 
   range=425, 
   color=yellow, 
   base={60,105,150,195,240},
   ap=.6,
   cost={60,65,70,75,80}
} 
spells["claws"] = {
   key="R", 
   color=violet, 
   base={75,115,155}, 
   ap=.3,
   radius=300,
   cost=100
} 

spells["AA"].damOnTarget = 
   function(target)
      if target then
         return GetSpellDamage("frenzy") * (1-GetHPerc(target))
      end
      return 0
   end

function CheckDisrupt()
   return false
end

function Run()
   local bonusHealth = me.maxHealth - 440*(me.selfLevel-1)*86
   spell["frenzy"].bonus = bonusHealth * .15

   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen
   if CheckDisrupt() then
      return true
   end

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
      UseItems()
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important

   -- low priority hotkey actions, e.g. killing minions, moving
   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()
   if CanUse("roar") then
      if #GetInRange(me, "roar", ENEMIES) > 0 then
         Cast("roar", me)
         PrintAction("Roar")
         return true
      end
   end

   if CanUse("frenzy") then
      local target = GetMarkedTarget() or GetWeakestEnemy("frenzy")
      local dist = GetDistance(target)
      local range = GetSpellRange("AA")
   
      if ( dist <= range and
           JustAttacked() ) or
         dist > range
      then
         Cast("frenzy", target)
         PrintAction("Frenzy", target)
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
      if HitMinion("AA", "strong") then
         return true
      end
   end

   -- if IsOn("move") then
   --    if MeleeMove() then
   --       return true
   --    end
   -- end

   return false
end

local function onCreate(object)
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")

