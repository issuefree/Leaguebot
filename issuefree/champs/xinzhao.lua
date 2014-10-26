require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Xin Zhao")

InitAAData({
   windup=.35,
   particles={"xen_ziou_intimidate"},
   resets={me.SpellNameQ}
})

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} ({1})", args={GetAADamage, "talon"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["talon"] = {
   key="Q", 
   base={15,30,45,60,75}, 
   ad=.2,
   type="P",
   modAA="talon",
   object="xenZiou_ChainAttack_indicator",
   range=GetAARange,
   cost=30
} 
spells["cry"] = {
   key="W", 
   base={26,32,38,44,50}, 
   ap=.7,
   type="H",
   cost=40
} 
spells["charge"] = {
   key="E", 
   range=600, 
   color=yellow,
   base={70,105,140,175,210}, 
   ap=.6,
   type="M",
   radius=function() return GetWidth(me) + 112.5 end,  --TODO test
   cost=60
} 
spells["sweep"] = {
   key="R", 
   range=function() return GetWidth(me) + 187.5 end,  --TODO test
   color=red, 
   base={75,175,275},
   adBonus=1,
   targetHealth=.15,
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
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important   
   if IsOn("lasthit") then
      if Alone() then
         if ModAAFarm("talon") then
            return true
         end
      end
   end      
   
   -- low priority hotkey actions, e.g. killing minions, moving
   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()

   if CanUse("cry") and GetWeakestEnemy("AA") then
      Cast("cry", me)
      PrintAction("Cry", nil, 1)
   end


   if CanUse("charge") then
      local target = GetMarkedTarget() or GetWeakestEnemy("charge")
      if target and 
         not UnderTower(target) and 
         IsInRange("charge", target) and 
         not IsInRange("AA", target) 
      then
         Cast("charge", target)
         PrintAction("Charge", target)
         return true
      end
   end

   if CanUse("challenge") then
      local target = GetMarkedTarget() or GetWeakestEnemy("sweep")
      if target and HasBuff("challenge", target) then
         if #GetInRange(target, "sweep", ENEMIES) >= 2 then
            Cast("sweep", target)
            PrintAction("Sweep", target)
            return true
         end
      end
   end

   local target = GetMarkedTarget() or GetMeleeTarget()
   if AutoAA(target, "talon") then
      return true
   end

   return false
end
function FollowUp()
   return false
end

local function onCreate(object)
   PersistOnTargets("challenge", object, "xen_ziou_intimidate", ENEMIES)
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")

