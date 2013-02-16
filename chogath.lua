require "Utils"
require "timCommon"
require "modules"

print("\nTim's Cho'Gath")

AddToggle("autocast", {on=true, key=112, label="Win button"})
AddToggle("feast", {on=true, key=113, label="Feast"})

spells["rupture"] = {key="Q", range=950, color=yellow, base={80,135,190,245,305}, ap=1}
spells["scream"]  = {key="W", range=700, color=violet, base={75,125,175,225,275}, ap=.7}
spells["feast"]   = {key="R", range=200, color=red,    base={300,475,650}, ap=.7}

local lastPos


function Run()
	TimTick()
	
	if KeyDown(hotKey) then
		UseAllItems()
--		local target = GetWeakEnemy("MAGIC", 950)
--		if target then
--			local x,y,z = GetFireahead(target,1.5*5,999) ;
--			DrawCircle(x,y,z, 300, violet)
--			CastSpellXYZ("Q",x,y,z)
--		end
	end
	
	
	if CanUse("feast") then
		local target = GetWeakEnemy("TRUE", spells["feast"].range+50)
		if target and target.health < GetSpellDamage("feast") then
			CastSpellTarget("R", target)
		end
	end	
end

SetTimerCallback("Run")