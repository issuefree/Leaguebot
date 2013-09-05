require "Utils"
require "timCommon"
require "modules"
require "support"

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
--   key="Q", 
--   range=1175, 
--   color=violet, 
--   base={60,110,160,210,260}, 
--   ap=.7,
--   delay=2,
--   speed=12,
--   width=80,
--   cost={10,20,30,40,50}
--}

function Run()
	TimTick()

   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return
   end

   -- auto stuff that always happen

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
      UseItems()
		if Action() then
			return
		end
	end

	-- auto stuff that should happen if you didn't do something more important

   -- low priority hotkey actions, e.g. killing minions, moving
   if HotKey() and CanAct() then
      if FollowUp() then
         return
      end
   end
end

function Action()
-- ranged
   local target = GetWeakEnemy("PHYS", spells["AA"].range)
   if AA(target) then
      PrintAction("AA", target)
      return true
   end

-- melee
   -- local target = GetMarkedTarget() or GetWeakEnemy("PHYS", spells["AA"].range*2)
   -- if AA(target) then
   --    PrintAction("AA", target)
   --    return true
   -- end


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

-- ranged
   if IsOn("move") then
      MoveToCursor() 
      PrintAction("Move")
      return false
   end

-- melee
   -- if IsOn("move") then
   --    local target = GetMarkedTarget() or GetWeakEnemy("PHYS", spells["AA"].range*2)
   --    if target then
   --       if GetDistance(target) > spells["AA"].range then
   --          MoveToTarget(target)
   --          PrintAction("MTT")
   --          return false
   --       end
   --    else        
   --       MoveToCursor() 
   --       PrintAction("Move")
   --       return false
   --    end
   -- end

   return false
end

local function onObject(object)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
