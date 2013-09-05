require "Utils"
require "timCommon"
require "modules"
require "support"

pp("\nTim's Janna")

spells["gale"]    = {key="Q", range=1700, color=violet, base={60,85,110,135,160}, ap=.75}
spells["zephyr"]  = {key="W", range=600,  color=violet, base={60,115,170,225,280}, ap=.6}
spells["eye"]     = {key="E", range=800,  color=green,  base={80,120,160,200,240}, ap=.9}
spells["monsoon"] = {key="R", range=800, color=green, base={280,440,600}, ap=1.4}

AddToggle("shield", {on=true, key=112, label="Auto Shield", auxLabel="{0}", args={"eye"}})

function Run()
	TimTick()

	if IsRecalling(me) then
		return
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