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
	range=1000, 
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


function Run()
   if StartTickActions() then
      return true
   end

   if CheckDisrupt("galeShort") then   	
      return true
   end

	if HotKey() then	
		UseItems()
		if Action() then
			return true
		end
	end
end 

function Action()
	if CanUse("zephyr") then
		if CastBest("zephyr") then
			return true
		end
	end

	return false
end

local function onSpell(unit, spell)
	if IsOn("shield") then
		CheckShield("eye", unit, spell)
	end
end

AddOnSpell(onSpell)
SetTimerCallback("Run")