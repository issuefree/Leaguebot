require "Utils"

pp("Tim's Ryze")

spells["overload"] = {key="Q", range=650, color=violet, base={60,85,110,135,160}, ap=.4, mana=.065}
spells["prison"]   = {key="W", range=625, color=red,    base={60,95,130,165,200}, ap=.6, mana=.045}
spells["flux"]     = {key="E", range=675, color=violet, base={50,70,90,110,130},  ap=.35, mana=.01}

AddToggle("lasthit", {on=true, key=112, label="Last Hit"})

local aloneRange = 1750  -- if no enemies in this range consider yourself alone
local nearRange = 900    -- if no enemies in this range consider them not "near"

local qLast, wLast = false, false
function Run()
	if HotKey() then
   	local target = GetWeakEnemy('MAGIC',675)
		if target then
			if rotationReady() then
				if GetDistance(myHero, target) < 650 then castQ(target) end
				if GetDistance(myHero, target) < 625 then castW(target) end
				if GetDistance(myHero, target) < 649 then castE(target) end
			else
				CastSpellTarget("Q", target)
				CastSpellTarget("W", target)
				CastSpellTarget("E", target)
			end
		end
	end
	
	if IsOn("lasthit") and not GetWeakEnemy("MAGIC", nearRange) then
	  KillWeakMinion("AA")
	end
end

function castQ(target)
	if IsSpellReady("Q") == 1 then
		CastSpellTarget("Q",target)
		setLast("Q")
	end
end

function castW(target)
	if IsSpellReady("W") == 1 and (qLast) and IsSpellReady("Q") == 0 then
		CastSpellTarget("W",target)
		setLast("W")
	end
end

function castE(target)
	if IsSpellReady("E") == 1 then
		CastSpellTarget("E", target)
		setLast("E")
	end
end

function setLast(spell)
	if spell == "Q" then 
		qLast=true 
		wLast=false
	elseif spell == "W" then 
	qLast=false 
	wLast=true
	elseif spell == "E" then
	qLast=false 
	wLast=false
	end
end
	
function rotationReady()
	if GetSpellLevel("Q") > 0 and GetSpellLevel("W") > 0 and GetSpellLevel("E") > 0 then return true
	else return false end
end

function moveToMouse()
	MoveToXYZ(GetCursorWorldX(), GetCursorWorldY(), GetCursorWorldZ())
end

function GetTick()
	return GetClock()
end


SetTimerCallback("Run")