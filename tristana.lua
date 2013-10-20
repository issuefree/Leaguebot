require "timCommon"
require "modules"

pp("\nTim's Tristana")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

function getShotRange()
   return 650+(9*(me.selflevel-1)*9)
end

spells["rapid"] = {
   key="Q", 
   cost=50
} 
spells["jump"] = {
   key="W", 
   range=900, 
   color=blue, 
   base={70,115,160,205,250}, 
   ap=.8,
   delay=2,
   speed=12, --?
   radius=300, --?
   cost=80
} 
spells["shot"] = {
   key="E", 
   range=getShotRange,
   color=violet, 
   base={110,150,190,230,270}, 
   ap=1,
   radius=150,
   cost={50,60,70,80,90}
} 
spells["buster"] = {
   key="R", 
   range=700, 
   color=red, 
   base={300,400,500}, 
   ap=1.5,
   cost=100
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
   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
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
      if HitMinion("AA", "strong") then
         return true
      end
   end

   if IsOn("move") then
      if RangedMove() then
         return true
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

