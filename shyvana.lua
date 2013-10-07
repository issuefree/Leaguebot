require "timCommon"
require "modules"

pp("\nTim's Shyvana")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["bite"] = {
   key="Q"
} 
spells["burnout"] = {
   key="W", 
   range=325, 
   color=red, 
   base={25,40,55,70,85}, 
   bonusAd=.1
} 
spells["breath"] = {
   key="E", 
   range=925, 
   color=violet, 
   base={80,115,150,185,220}, 
   ap=.6,
   delay=2,
   speed=15,
   width=80,
   noblock=true
} 
spells["binding"] = {
   key="R", 
   range=1000, 
   color=yellow, 
   base={200,300,400}, 
   ap=.7,
   delay=2,
   speed=12,
   width=150,
   noblock=true
} 

function Run()
   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return true
   end

   -- auto stuff that always happen

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() then
      UseItems()
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important
   if IsOn("lasthit") and Alone() then
      if CanUse("breath") then
         if KillMinionsInLine("breath", 2) then
            PrintAction("Breath for lasthit")
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

   PrintAction()
end

function Action()
   if SkillShot("breath") then
      return true
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA", GetSpellRange("AA"))
   if target then
      if CanUse("burnout") then
         Cast("burnout", me)
         PrintAction("Burnout", target)
         return true
      end
      if CanUse("bite") and
         JustAttacked() and 
         GetDistance(target) < GetSpellRange("AA") + 100
      then
         Cast("bite", me)
         PrintAction("Bite on", target)
         return true
      end

      if AA(target) then
         PrintAction("AA", target)
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
      -- hit the highest health minion
      local minions = SortByHealth(GetInRange(me, "AA", MINIONS))
      if #minions >= 3 then
         Cast("burnout", me)
         PrintAction("Burnout for clear")
      end
      if AA(minions[#minions]) then
         PrintAction("AA clear minions")
         return true
      end
   end

   if IsOn("move") then
      local target = GetMarkedTarget() or GetWeakEnemy("PHYS", spells["AA"].range*1.5)
      if target then
         if GetDistance(target) > spells["AA"].range then
            MoveToTarget(target)
            return false
         end
      else        
         MoveToCursor() 
         return false
      end
   end

   return false
end

local function onObject(object)
end

local function onSpell(unit, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")

