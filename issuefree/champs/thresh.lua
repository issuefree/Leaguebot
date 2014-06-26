require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Thresh")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})

spells["hook"] = {
   key="Q", 
   range=1075, 
   color=violet, 
   base={80,120,160,200,240}, 
   ap=.5,
   delay=1.5,
   speed=12,
   width=80,
   cost=80
} 
spells["lantern"] = {
   key="W", 
   range=950, 
   color=blue, 
   base={60,100,140,180,220}, 
   ap=.4,
   cost={50,55,60,65,70}
} 
spells["flay"] = {
   key="E", 
   range=400, 
   color=yellow, 
   base={65,95,125,155,185}, 
   ap=.4,
   cost={60,65,70,75 / 80}
} 
spells["box"] = {
   key="R", 
   range=450, 
   color=red, 
   base={250,400,550}, 
   ap=1,
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
   if CheckDisrupt("hook") then
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
-- ranged
   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AA(target) then
      PrintAction("AA", target)
      return true
   end

-- melee
   -- local target = GetMarkedTarget() or GetMeleeTarget()
   -- if AA(target) then
   --    PrintAction("AA", target)
   --    return true
   -- end


   return false
end
function FollowUp()
   if IsOn("lasthit") and Alone() then
      if KillMinion("AA") then
         return true
      end
   end

   if IsOn("clear") and Alone() then
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

