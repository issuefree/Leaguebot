require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Fiddlesticks")
pp(" - dark wind on weakest")
pp(" - pause while draining")

AddToggle("offense", {on=true, key=112, label="Offensive stance"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=false, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=115, label="Move"})

spells["fear"] = {
   key="Q", 
   range=575, 
   color=violet,
   cost=65
}
spells["drain"] = {
   key="W", 
   range=575,
   color=green,
   cost={80,90,100,110,120}
}
spells["wind"] = {
   key="E", 
   range=750, 
   color=red, 
   base={65,85,105,125,145},
   ap=.45,
   cost={50,70,90,110,130}
}
spells["crow"] = {
   key="R", 
   range=800, 
   color=yellow,
   cost=100,
   radius=600
}

-- block spells while drain is on
-- beep for good crowstorm
-- auto zhonias

local drain = nil
local drainCastTime = 0

local function isDraining()
   if P.drain then
      CHANNELLING = true
      return true
   end
   if time() - drainCastTime < 1 then
      CHANNELLING = true
      return true
   end
   CHANNELLING = false
   return false
end

function CheckDisrupt()
   if Disrupt("DeathLotus", "fear") then return true end
   if Disrupt("DeathLotus", "wind") then return true end

   if Disrupt("Grasp", "fear") then return true end
   if Disrupt("Grasp", "wind") then return true end

   if Disrupt("AbsoluteZero", "fear") then return true end
   if Disrupt("AbsoluteZero", "wind") then return true end

   if Disrupt("BulletTime", "fear") then return true end
   if Disrupt("BulletTime", "wind") then return true end

   if Disrupt("Duress", "fear") then return true end
   if Disrupt("Duress", "wind") then return true end

   if Disrupt("Idol", "fear") then return true end
   if Disrupt("Idol", "wind") then return true end

   if Disrupt("Monsoon", "fear") then return true end
   if Disrupt("Monsoon", "wind") then return true end

   if Disrupt("Meditate", "fear") then return true end
   if Disrupt("Meditate", "wind") then return true end

   if Disrupt("Drain", "fear") then return true end
   if Disrupt("Drain", "wind") then return true end

   return false
end

function Run()
   if isDraining() then
      PrintAction("Draining")
      return true
   end

   if StartTickActions() then
      return true
   end

   if CheckDisrupt("wind") or
      CheckDisrupt("fear") 
   then
      return true
   end

	if HotKey() then
		if Action() then
			return
		end
	end

	-- always stuff here

   if HotKey() and CanAct() then
      if FollowUp() then
         return
      end
   end

   EndTickActions()
end

function Action()
   UseItems()
   
   --[[
   I want something like...
   Fear if I can. I want to target EADC and EAPC if they're in range otherwise whoever is weak
   Drain if I can. I should probably try to target whatever I feared but weak will probably do.
      I think I want this over wind as wind is longer range and I probably just feared them.
   --]]
   if IsOn("offense") then      
      if CanUse("fear") then
         local target = GetMarkedTarget() or 
                        GetWeakest("fear", GetInRange(me, "fear", {EADC, EAPC})) or 
                        GetWeakestEnemy("fear", 0, 100)

         if target then
            Cast("fear", target)
            PrintAction("Fear", target)
            return true
         end
      end

      if CanUse("drain") then
         -- might update this to target feared guys first
         local target = GetMarkedTarget() or GetWeakestEnemy("drain", 0, 100)
         if target and Cast("drain", target) then
            PrintAction("Drain", target)
            return true
         end
      end
   end

   if CanUse("wind") then
      local target = GetWeakestEnemy("wind")
      if target and Cast("wind", target) then
         PrintAction("Wind Harass", target)
         return true
      end
   end

   return false
end

function FollowUp()
   -- clear with wind if there's 3 or more
   if IsOn("clear") and Alone() and
      me.mana/me.maxMana > .5 
   then
      if CanUse("wind") then
         local minions = SortByHealth(GetInRange(me, "wind", MINIONS), "wind")
         if #minions > 2 then
            Cast("wind", minions[1])
            PrintAction("Dark wind clearing")
            return true
         end
      end
   end

   return false
end

local function onObject(object)
  PersistBuff("drain", object, "Drain.troy")
end

local function onSpell(object, spell)
   if object.charName == me.charName and
      find(spell.name, "DrainChannel")
   then
      drainCastTime = time()
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
