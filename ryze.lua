require "Utils"

print=printtext
printtext("Sida's Ryze")
local hotkey=GetScriptKey()
local myHero = GetSelf()
local qLast, wLast = false, false
function Run()
	local k=IsKeyDown(hotkey)
	local target = GetWeakEnemy('MAGIC',650)
	if k~=0 then
		if target ~= nil then
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
		moveToMouse()
	end	
	Draw()
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

function Draw()
	DrawCircle(myHero.x, myHero.y, myHero.z, 650, 0x02)
end

SetTimerCallback("Run")