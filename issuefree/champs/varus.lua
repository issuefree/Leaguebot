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

spells["AA"].damOnTarget = 
   function(target)
      return 0
   end

function CheckDisrupt()
   if Disrupt("DeathLotus", "scream") then return true end

   if Disrupt("Grasp", "scream") then return true end

   if Disrupt("AbsoluteZero", "scream") then return true end

   if Disrupt("BulletTime", "scream") then return true end

   if Disrupt("Duress", "scream") then return true end

   if Disrupt("Idol", "rupture") then return true end

   if Disrupt("Monsoon", "scream") then return true end

   if Disrupt("Meditate", "scream") then return true end

   if Disrupt("Drain", "scream") then return true end

   return false
end

function Run()
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

   if IsOn("lasthit") and Alone() then
      if KillMinion("AA") then
         return true         
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
-- ranged
   -- local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   -- if AA(target) then
   --    PrintAction("AA", target)
   --    return true
   -- end

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
