require "utils"
require "timCommon"
require "modules"

pp("Tim's Mundo")

local berserkToggleTime = GetClock()
function getBerserkTime()
	return math.floor(10.5 - (GetClock() - berserkToggleTime)/1000)
end

spells["cleaver"] = {key="Q", range=1000, color=red, base={80,130,180,230,280}}
spells["agony"]   = {key="W", range=325,  color=red, base={35,50,65,80,95}, ap=.2} 

AddToggle("berserk", {on=false, key=112, label="BERSERK", auxLabel="{0}", args={getBerserkTime}})
AddToggle("burn",    {on=true,  key=113, label="Burn minions", auxLabel="{0}", args={"agony"}})

-- holder for my burning agony object
local burningAgony = nil

function Run()
	TimTick()
	updateObjects()

	if GetWeakEnemy("MAGIC", 1200) or not IsOn("berserk") then
		berserkToggleTime = GetClock()
	elseif GetClock() - berserkToggleTime > 10000 then
		keyToggles["berserk"].on = false
	end   
	
--	if burningAgony then
--		print("burn")
--	else
--		print("noburn")
--	end

	if IsKeyDown(hotKey) == 1 then
		local target = GetWeakEnemy('MAGIC', 950)		
		if target then
			UseAllItems()
			if GetDistance(me, target) < 950 and CanCastSpell("Q") then			
				CastHotkey('SPELLQ:WEAKENEMY RANGE=950 FIREAHEAD=2,20 CANBLOCK')				
			elseif IsOn("berserk") then
				if GetDistance(me, target) < 350 then
					if CanCastSpell("E") then
						CastSpellTarget("E", me)
					end
					if not burningAgony and CanCastSpell("W") then
						CastSpellTarget("W", me)
					end

					AttackTarget(target)
				end
			end 
		else
		end
	end

	local maxHealthMonster = nil
	local doBurn = false
	for _,minion in ipairs(MINIONS) do
		if ( GetDistance(me, minion) < spells["agony"].range and 
		   minion.health < GetSpellDamage("agony") and 
		   CanCastSpell("W") )
		then
			doBurn = true				
		end															

		if not burningAgony and doBurn and IsOn("burn") then
			CastSpellTarget("W", me)
		end
	end
	
	for _,minion in ipairs(getSSMinions(1050, 80, MINIONS)) do
		LineBetween(me, minion, 80)
		if CanUse("cleaver") and GetSpellDamage("cleaver", minion) > minion.health then
			CastSpellXYZ("Q", minion.x, minion.y, minion.z)
--			break
		end	
	end
end

function getSSMinions(range, width, minions)
	local minionWidth = 55
	local nearMinions = GetInRange(me, range, minions)
	
	SortByDistance(nearMinions)
	
	local blocked = {}
--	local unblocked = copy(nearMinions)
	
	for i,minion in ipairs(nearMinions) do
		local d = GetDistance(minion)
		for m = i+1, #nearMinions do
			local a = AngleBetween(me, nearMinions[m])
			local proj = {x=me.x+math.sin(a)*d, z=me.z+math.cos(a)*d}
			if GetDistance(minion, proj) < width+minionWidth then
				table.insert(blocked, nearMinions[m])
			end
		end
	end


	local unblocked = {}
	for i,b in ipairs(blocked) do
		DrawCircleObject(b, minionWidth, red)
	end
	for i,minion in ipairs(nearMinions) do
		local mb = false
		for m,bm in ipairs(blocked) do
			if bm == minion then				
				mb = true
				break
			end
		end
		if not mb then
			table.insert(unblocked, minion)
		end
	end
	return unblocked
end

function checkBurning(object)
	if find(object.charName, "burning_agony") and GetDistance(me, object) < 100 then
		burningAgony = object
	end
end

function updateObjects()
	if burningAgony and burningAgony.x and burningAgony.z and GetDistance(me, burningAgony) < 50 then
	else
		burningAgony = nil
	end
end

AddOnCreate(checkBurning)

SetTimerCallback("Run")