require "Utils"
require "timCommon"
require "modules"
require "support"

pp("\nTim's Lulu")

spells["glitter"] = {
	key="Q", 
	range=925, 
	color=violet, 
	base={80,125,170,215,260}, 
	ap=.5,
	cost={60,65,70,75,80}
}
-- spells["zephyr"]  = {key="W", range=600,  color=violet, base={60,115,170,225,280}, ap=.6}
spells["pix"] = {
	key="E", 
	range=650,  
	color=yellow,  
	base={80,120,160,200,240}, 
	ap=.6,
	cost={60,70,80,90,100}
}
-- spells["monsoon"] = {key="R", range=800, color=green, base={280,440,600}, ap=1.4}

AddToggle("shield", {on=true, key=112, label="Auto Shield", auxLabel="{0}", args={"eye"}})

function Run()
	if IsRecalling(me) then
		return
	end

	if HotKey() then	
		UseItems()
	end
end 

local function onSpell(unit, spell)
	if IsOn("shield") then
		CheckShield("pix", unit, spell)
	end
end

AddOnSpell(onSpell)
SetTimerCallback("Run")