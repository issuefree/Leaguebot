require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Janna")

spells["tailwind"] = {
	range=800,
	color=blue
}
spells["gale"] = {
   key="Q",
	range=1700, 
	color=violet, 
	base={60,85,110,135,160}, 
	ap=.35
}
spells["galeShort"] = {
   key="Q",
	range=1100, 
	color=violet, 
	base={60,85,110,135,160}, 
	ap=.35
}
spells["zephyr"] = {
	key="W", 
	range=600,  
	color=violet, 
	base={60,115,170,225,280}, 
	ap=.5
}
spells["eye"] = {
	key="E", 
	range=800,  
	color=green,  
	base={80,120,160,200,240}, 
	ap=.7
}
spells["monsoon"] = {
	key="R", 
	range=800, 
	color=green, 
	base=100, 
	ap=1.4
}

AddToggle("shield", {on=true, key=112, label="Auto Shield", auxLabel="{0}", args={"eye"}})

function CheckDisrupt()
   if Disrupt("DeathLotus", "galeShort") then return true end

   if Disrupt("Grasp", "galeShort") then return true end

   if Disrupt("AbsoluteZero", "galeShort") then return true end

   if Disrupt("BulletTime", "galeShort") then return true end

   if Disrupt("Duress", "galeShort") then return true end

   if Disrupt("Idol", "galeShort") then return true end

   if Disrupt("Monsoon", "galeShort") then return true end

   if Disrupt("Meditate", "galeShort") then return true end

   if Disrupt("Drain", "galeShort") then return true end

   return false
end

function Run()
	if IsRecalling(me) then
		return
	end

   if CheckDisrupt() then
      return true
   end

	if HotKey() then	
		UseItems()
	end
end 

local function onSpell(unit, spell)
	if IsOn("shield") then
		CheckShield("eye", unit, spell)
	end
end

AddOnSpell(onSpell)
SetTimerCallback("Run")