require "Utils"
require "timCommon"
require "modules"
--require "support"

pp("\nTim's Janna")

spells["gale"]    = {key="Q", range=1700, color=violet, base={60,85,110,135,160}, ap=.75}
spells["zephyr"]  = {key="W", range=600,  color=violet, base={60,115,170,225,280}, ap=.6}
spells["eye"]     = {key="E", range=800,  color=green,  base={80,120,160,200,240}, ap=.9}
spells["monsoon"] = {key="R", range=800, color=green, base={280,440,600}, ap=1.4}

AddToggle("shield", {on=true, key=113, label="Auto Shield", auxLabel="{0}", args={"eye"}})

function Run()
	TimTick()

	if IsRecalling(me) then
		return
	end

	if HotKey() then	
		UseAllItems()
	end
end 

function checkShield(object, spell)
	if not spell.target or
	   find(object.name, "Minion") or
	   find(spell.target.name, "Minion") or
	   IsRecalling(me) or
	   not CanUse("eye") or
	   object.team == me.team or
	   GetDistance(spell.target) > 800 or
	   spell.target.team ~= me.team
	then
		return
	end

	pp(object.name.." : "..spell.name.." -> "..spell.target.name)
	CastSpellTarget("E", spell.target)
end

AddOnSpell(checkShield)
SetTimerCallback("Run")