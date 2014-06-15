require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Malphite")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["shard"] = {
   key="Q", 
   range=625, 
   color=violet, 
   base={70 / 120 / 170 / 220 / 270},
   ap=.6,
   type="M",
   cost={70 / 75 / 80 / 85 / 90}
} 
spells["strikes"] = {
   key="W", 
   cost={50 / 55 / 60 / 65 / 70}
} 
spells["slam"] = {
   key="E", 
   range=200, 
   color=yellow, 
   base={60 / 100 / 140 / 180 / 220}, 
   ap=.2,
   armor=.3,
   cost={50 / 55 / 60 / 65 / 70}
} 
spells["force"] = {
   key="R", 
   range=1000, 
   color=red, 
   base={200 / 300 / 400}, 
   ap=1,
   delay=2,
   speed=18,
   radius=300,
   cost=100
} 

spells["AA"].damOnTarget = 
   function(target)
      return 0
   end

function Run()
   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen

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
-- melee
   local target = GetMarkedTarget() or GetMeleeTarget()
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
      if MeleeMove() then
         return true
      end
   end

   return false
end

local function onCreate(object)
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")

