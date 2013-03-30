require "Utils"
require "timCommon"
require "modules"
require "support"

print("\nTim's Nunu")

AddToggle("boil",  {on=true, key=112, label="Boil ADC"})
AddToggle("blast", {on=true, key=113, label="Auto Blast", auxLabel="{0}", args={"iceblast"}})

spells["bloodboil"] = {key="W", range=700,  color=green}
spells["iceblast"]  = {key="E", range=550,  color=yellow, base={85,130,175,225,275}, ap=1}
spells["zero"]      = {key="R", range=650, color=red,    base={625,875,1125}, ap=2.5}

local lastBoil = GetClock()

function Run()
	TimTick()
	
	if IsKeyDown(hotKey) == 1 then 
		if IsOn("boil") then
			if CanCastSpell("W") and
			   GetClock() - lastBoil > 12000 and 
			   ADC and
			   ADC.name ~= me.name and
			   GetDistance(ADC) < spells["bloodboil"].range 
			then
				CastSpellTarget("W", ADC)
				lastBoil = GetClock()
			end
		end
		
		if IsOn("blast") then
			if CanCastSpell("E") then
				if GetDistance(EADC) < spells["iceblast"].range then
					CastSpellTarget("E", EADC)
				else
					local target = GetWeakEnemy("MAGIC", spells["iceblast"].range)
					if target then
						CastSpellTarget("E", target)
					end
				end
			end
		end
		
		UseItems()
	end
end


SetTimerCallback("Run")