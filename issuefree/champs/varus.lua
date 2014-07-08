require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Varus")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["arrow"] = {
   key="Q", 
   range=925,
   maxRange=1400,
   color=violet, 
   base={10,47,83,120,157}, 
   ad=1,
   delay=2,  -- needs testing
   speed=19,
   width=80,
   noblock=true,
   cost={70,75,80,85,90}
} 
spells["quiver"] = {
   base={10,14,18,22,26}, 
   ap=.25
} 
spells["quiverStack"] = {
   base=0,
   percMaxHealth={.02,.0275,.035,.0425,.05},
   percMaxHealthAP={.0002}
} 
--spells["binding"] = {
--    key="E", 
--    range=1175, 
--    color=violet, 
--    base={60,110,160,210,260}, 
--    ap=.7,
--    delay=2,
--    speed=12,
--    width=80,
--    cost={10,20,30,40,50}
--} 
--spells["binding"] = {
--    key="R", 
--    range=1175, 
--    color=violet, 
--    base={60,110,160,210,260}, 
--    ap=.7,
--    delay=2,
--    speed=12,
--    width=80,
--    cost={10,20,30,40,50}
--} 
spells["maxArrow"] = copy(spells["arrow"])
spells["maxArrow"].range = spells["maxArrow"].maxRange

spells["AA"].damOnTarget = 
   function(target)
      return 0
   end


function Run()
   spells["AA"].bonus = GetSpellDamage("quiver")

   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
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
   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end

   return false
end
function FollowUp()
   return false
end

local function onCreate(object)
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")

