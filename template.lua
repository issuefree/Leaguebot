require "timCommon"
require "modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Template")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

--spells["binding"] = {
--    key="Q", 
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
--    key="W", 
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

function Run()
   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
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

   PrintAction()
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

local function onObject(object)
end

local function onSpell(unit, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")

