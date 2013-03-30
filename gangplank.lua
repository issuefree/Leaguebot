require "Utils"
require "timCommon"
require "modules"

print("\nTim's Template")

AddToggle("farm", {on=true, key=112, label="Q Farm", auxLabel="{0}", args={"gun"}})
AddToggle("ult",  {on=true, key=113, label="Check Ult"})

spells["gun"]     = {key="Q", range=625, color=yellow, base={20,45,70,95,120}, ad=1}
spells["oranges"] = {key="W",                          base={80,150,220,290,360}, ap=1}
spells["morale"]  = {key="E", range=1200, color=blue}

function Run()
	TimTick()
			
	if HotKey() then
		local target = GetWeakEnemy("PHYS", spells["gun"].range)
		UseItems()
		if target and CanCastSpell("Q") then
			CastSpellTarget("Q", target)
		end
		if me.health/me.maxHealth < .5 then
			CastSpellTarget("W", me)
		end
	end
	
	if IsOn("ult") and CanCastSpell("R") then
		for _,enemy in ipairs(ENEMIES) do
			if enemy and enemy.health/enemy.maxHealth < .5 and #GetInRange(enemy, 500, ALLIES) > 0 then
				PlaySound("Beep")
			end
		end
	end
	
	if IsOn("farm") and not GetWeakEnemy("PHYS", 800) then
		KillFarMinion(spells["gun"])
--		killNearMinion("AA")
	end			
end


SetTimerCallback("Run")