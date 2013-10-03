require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Corki")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["phos"] = {
  key="Q", 
  range=600, 
  color=violet, 
  base={80,130,180,230,280}, 
  ap=.5,
  delay=2,
  speed=0,
  radius=300,
  cost={80,90,100,110,120},
  noblock=true
}
spells["valk"] = {
  key="W", 
  range=800, 
  color=yellow, 
  base={150,225,300,375,450}, 
  ap=1,
  delay=2,
  speed=12,
  width=200,
  cost=50,
  noblock=true
}
spells["gun"] = {
  key="E", 
  range=600, 
  color=red, 
  base={20,32,44,56,68}, 
  bonusAd=.4,
  cost={60,70,80,90,100}
}
spells["barrage"] = {
  key="R", 
  range=1225,
  color=violet,
  base={120,190,260}, 
  ap=.3,
  ad=.2
  delay=1.5,
  speed=19,
  width=80,
  cost={30,35,40}
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
   if IsOn("lasthit") and CanUse("phos") then
      if KillMinionsInArea("phos", 3) then
         return true
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
   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AA(target) then
      PrintAction("AA", target)
      return true
   end

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

   if IsOn("move") then
      if #GetInRange(GetMousePos(), "AA", ENEMIES) == 0 or
         #GetInRange(me, "AA", ENEMIES) == 0 
      then
         MoveToCursor()
         -- PrintAction("Move")
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

