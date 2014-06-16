require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Lulu")

spells["lance"] = {
	key="Q", 
	range=925, 
	color=violet, 
	base={80,125,170,215,260}, 
	ap=.5,
	noblock=true,
	cost={60,65,70,75,80}
}
spells["whimsy"] = {
	key="W", 
	range=650,  
	color=yellow,
	cost={65,70,75,80,85}	
}
spells["pix"] = {
	key="E", 
	range=650,  
	color=blue,  
	base={80,110,140,170,200}, 
	ap=.4,
	cost={60,70,80,90,100}
}
spells["growth"] = {
	key="R", 
	range=900,  
	color=green,  
	base={300,450,600}, 
	ap=.5,
	cost=100
}

AddToggle("move", {on=false, key=112, label="Move to Mouse"})
AddToggle("shield", {on=true, key=114, label="Auto Shield", auxLabel="{0}", args={"pix"}})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})

function CheckDisrupt()
   if Disrupt("DeathLotus", "whimsy") then return true end

   if Disrupt("Grasp", "whimsy") then return true end

   if Disrupt("AbsoluteZero", "whimsy") then return true end

   if Disrupt("BulletTime", "whimsy") then return true end

   if Disrupt("Duress", "whimsy") then return true end

   if Disrupt("Idol", "whimsy") then return true end

   if Disrupt("Monsoon", "whimsy") then return true end

   if Disrupt("Meditate", "whimsy") then return true end

   if Disrupt("Drain", "whimsy") then return true end

   return false
end

function Run()
   if StartTickActions() then
      return true
   end

   if CheckDisrupt() then
      return true
   end

	if HotKey() then
      UseItems()
		if Action() then
			return true
		end
	end

   if HotKey() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()	
end 

function Action()
end

function FollowUp()
   if IsOn("lasthit") and Alone() then
      if KillMinion("AA") then
         return true
      end
   end

   if IsOn("clear") and Alone() then
      -- hit the highest health minion
      local minions = SortByHealth(GetInRange(me, "AA", MINIONS))
      if AA(minions[#minions]) then
         PrintAction("AA clear minions")
         return true
      end
   end

   return false
end

local function onSpell(unit, spell)
	if IsOn("shield") then
		CheckShield("pix", unit, spell)
	end
end

AddOnSpell(onSpell)
SetTimerCallback("Run")