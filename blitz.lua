require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Blitz")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("pull", {on=true, key=113, label="Pull"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["grab"] = {
  key="Q", 
  range=1050, 
  color=violet, 
  base={80,135,190,245,300}, 
  ap=1,
  delay=2,
  speed=17,
  width=80,
  cost=120
}
spells["drive"] = {
  key="W", 
  cost=75
}
spells["fist"] = {
  key="E", 
  range=GetSpellRange("AA"), 
  base={0,0,0,0,0},
  ad=1,
  onHit=true,
  color=red, 
  cost=25
}
spells["binding"] = {
  key="R", 
  range=600, 
  color=yellow, 
  base={250,375,500}, 
  ap=1,
  cost=150
}

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
   local target = GetMarkedTarget() or GetWeakEnemy("PHYS", spells["AA"].range*2)
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
      -- hit the highest health minion
      local minions = SortByHealth(GetInRange(me, "AA", MINIONS))
      if AA(minions[#minions]) then
         PrintAction("AA clear minions")
         return true
      end
   end

   if IsOn("move") then
      local target = GetMarkedTarget() or GetWeakEnemy("PHYS", spells["AA"].range*2)
      if target then
         if GetDistance(target) > spells["AA"].range then
            MoveToTarget(target)
            return false
         end
      else        
         MoveToCursor() 
         PrintAction("Move")
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

