require "utils"
		
local enemies = {}
local hotkey = GetScriptKey() 	
local myHero = GetSelf()	
local lastSpell = ""
local target
local wUsedAt = GetClock()				

function Run()	
	Draw()
	local key = IsKeyDown(hotkey) 						
	target = GetWeakEnemy('MAGIC',1300,"NEARMOUSE") 		
	
	if key == 1 then 									
		if target ~= nil then
			if GetDistance(myHero, target) < 1300 then
				castW(target)
			end
	
			useItems()
                       	if GetDistance(myHero, target) < 700 then 	
				castQ(target)
			end		

			if GetDistance(myHero, target) < 700 then	
				castR(target)
			end	

		end
	end
end

function castW(target)
	if IsSpellReady("W") == 1 and GetSpellLevel("W") > 0 and GetClock() > wUsedAt + 4000 then
		CastHotkey("SPELLW:WEAKENEMY RANGE=1300 SMARTCAST")
		lastSpell = "W"	
		wUsedAt = GetClock()
	end
end

function castQ(target)	
	if IsSpellReady("Q") and GetSpellLevel("Q") > 0 then
		CastSpellTarget("Q", target) 
		lastSpell = "Q"
	end
end

function castR(target)	
	if lastSpell == "Q" and IsSpellReady("Q") == 0 and ultReady() then
		CastSpellTarget("R", target) 
		lastSpell = "R"	
	end
end

function ultReady()
	if GetSpellLevel("R") == 0 or IsSpellReady("R") == 0 then return false else return true end
end

function Draw()
	DrawCircle(myHero.x, myHero.y, myHero.z, 1300, 0x02)
	DrawCircle(myHero.x, myHero.y, myHero.z, 700, 0x02)
end

function useItems()
	if target ~= nil then
		if GetDistance(myHero, target) < 700 then
			useItem(3128)
		end
	end
end

function UseItem(item)
	if GetInventoryItem(1) == item then 
		CastSpellTarget("1", target)
	elseif GetInventoryItem(2) == item then 
		CastSpellTarget("2", target)
	elseif GetInventoryItem(3) == item then 
		CastSpellTarget("3", target)
	elseif GetInventoryItem(4) == item then 
		CastSpellTarget("4", target)
	elseif GetInventoryItem(5) == item then 
		CastSpellTarget("5", target)
	elseif GetInventoryItem(6) == item then 
		CastSpellTarget("6", target)
	end
end

SetTimerCallback("Run")