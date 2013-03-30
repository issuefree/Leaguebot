require "Utils"
require "timCommon"
require "modules"

print("\nTim's Alistar")

AddToggle("combo", {on=true, key=112, label="Combo"})

spells["pulverize"] = {key="Q", range=365, color=red,    base={60,105,150,195,240}, ap=.5, cost={70,80,90,100,110}}
spells["headbutt"]  = {key="W", range=650, color=violet, base={55,110,165,220,275}, ap=.7, cost={70,80,90,100,110}} 
spells["roar"]      = {key="E", range=575, color=green,  base={60,90,120,150,180},  ap=.2}

function Run()
	TimTick()
	
	local target = GetWeakEnemy("MAGIC", 650, "NEARMOUSE")
	
--		LineBetween(me, GetMousePos())
	if target then
		DrawKnockback(target, 650)
	end
	
	if IsOn("combo") and IsKeyDown(hotKey) ~= 0 then
		if target and GetDistance(target) < 365 and CanUse("pulverize") then
			CastSpellTarget("Q", target)
		elseif target and 
		       CanUse("pulverize") and 
		       CanUse("headbutt") and 
		       me.mana > (GetSpellCost(spells["pulverize"]) + GetSpellCost(spells["headbutt"])) 
		then
			CastSpellTarget("W", target)
		end
		UseItems()
	end
end

SetTimerCallback("Run")