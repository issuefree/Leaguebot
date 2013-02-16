require "Utils"
require "timCommon"
--require "modules"

spells["blades"]   = {key="Q", range=675, color=violet, base={60,85,110,135,160}, ap=.45}
spells["dagger"]   = {key="Q",                          base={15,30,45,60,75},    ap=.15}
spells["sinister"] = {key="W", range=375, color=red,    base={40,75,110,145,180}, ap=.25, adb=.6}
spells["shunpo"]   = {key="E", range=700, color=yellow, base={60,85,110,135,160}, ap=.4}
spells["lotus"]    = {key="R", range=550, color=red,    base={400,500,600},       ap=2,   adb=3}

function getComboDamage()
	local comboDam = GetSpellDamage("shunpo") + 
		              GetSpellDamage("blades") +
		              GetSpellDamage("sinister")
	if CanUse("blades") then
		comboDam = comboDam + GetSpellDamage("dagger")
	end
	return comboDam
end

AddToggle("qFarm",  {on=true, key=112, label="Q Farm", auxLabel="{0}", args={"blades"}})
AddToggle("steal",  {on=true, key=113, label="Secure Kills", auxLabel="{0}", args={getComboDamage}})

pp("Tim's Katarina")

local lastRDagger = 0
local spinning = false
local lastHotkey = 3

local daggers = {}

local lastQ = GetClock()

function Run()
	TimTick()	

	for _,m in ipairs(MINIONS) do
		DrawCircleObject(m, 100, red)
	end

	if me.dead == 1 then
		return
	end

--	local turrets = GetInRange(me, 20000, TURRETS)
--	for _,turret in ipairs(turrets) do
--		if find(turret.charName, "Turret") then
--			DrawCircleObject(turret, 950, yellow)
--			DrawTextObject(turret.range, turret, 0xffffffff)
--		end
--	end

	Clean(daggers)
			
	if KeyDown(string.byte("X")) then
		WardJump("E")
	end

	local target = GetWeakEnemy('MAGIC',730)
	
	if GetClock() > lastRDagger + 250 then
		spinning = false 
	end

	if IsOn("steal") and target and not spinning then 
		killSteal() 
	end
	
	if KeyDown(hotKey) and target then
		if not spinning then
			UseAllItems()
			if spells["Ignite"] and CanUse("Ignite") and target.health < GetSpellDamage("Ignite") then
				CastSpellTarget(spells["Ignite"].key, target)
			end
			if CanUse("blades") and GetDistance(target) < spells["blades"].range then
				CastQ(target)
			elseif CanUse("sinister") and GetDistance(target) < spells["sinister"].range then
				CastSpellTarget("W", target)
			elseif CanUse("shunpo") and GetDistance(target) < spells["shunpo"].range then
				CastSpellTarget("E", target)
			elseif CanUse("lotus") and GetDistance(target) < 275 then
				CastSpellTarget("R", target)
				spinning = true
				lastRDagger = GetClock()
			end
		end
		if not spinning then
			AttackTarget(target)
		end
	end
	
--	local nearMouse = GetInRange(GetMousePos(), 2000, MINIONS)
--	SortByDistance(nearMouse, GetMousePos())
--	if #nearMouse > 0 and GetDistance(GetMousePos(), nearMouse[1]) < 100 then
--		local tKills, tKillTargets, tKillDeaths = getBouncePath(nearMouse[1], nearMouse)
--		for i = 1, #tKillTargets do
--			DrawCircleObject(tKillTargets[1], 90, violet)
--		
--			if i > 1 then
--				LineBetween(tKillTargets[i-1], tKillTargets[i])
--			end
--			if tKillDeaths[i] then
--				DrawCircleObject(tKillTargets[i], 70, red)
--				DrawCircleObject(tKillTargets[i], 72, red)
--				DrawCircleObject(tKillTargets[i], 74, red)
--			else
--				DrawCircleObject(tKillTargets[i], 70, yellow)								
--			end
--
--		end
--	end
	if IsOn("qFarm") and not GetWeakEnemy("MAGIC", 750) then
		QFarm()
	end
end

function killSteal()
	-- full combo
	local target = GetWeakEnemy("MAGIC", spells["shunpo"].range)
	if target and
		CanUse("shunpo") and
		CanUse("blades") and
		CanUse("sinister")
	then
		local comboDam = GetSpellDamage("shunpo", target) + 
		                 GetSpellDamage("blades", target) +
		                 GetSpellDamage("dagger", target) +
		                 GetSpellDamage("sinister", target)
--		PrintState(0, "FC: "..comboDam.."/"..target.health)
		if comboDam > target.health then
			if GetDistance(target) > spells["blades"].range then
				CastSpellTarget("E", target)
--				PrintState(1, "Did E")
				return
			else
				CastSpellTarget("Q", target)
--				PrintState(1, "Did Q")
				return
			end
		end
		return -- if full combo won't do it don't bother
	end	

	-- try to execute with W
	target = GetWeakEnemy("MAGIC", spells["sinister"].range)
	if target and 
		CanUse("sinister") and
		not CanUse("blades") and
		not CanUse("shunpo") 
	then
		local comboDam = GetSpellDamage("sinister", target)
		if #GetInRange(target, 50, daggers) > 0 then
			comboDam = comboDam + GetSpellDamage("dagger", target)
		end
--		PrintState(2, "W: "..comboDam.."/"..target.health)
		if comboDam > target.health then
			CastSpellTarget("W", target)
--			PrintState(2, "Did W")
			return
		end
	end

	-- try to execute with Q
	target = GetWeakEnemy("MAGIC", spells["blades"].range)
	if target and 
		CanUse("blades") and
		not CanUse("sinister") and
		not CanUse("shunpo")
	then
		local comboDam = GetSpellDamage("blades", target)
--		PrintState(3, "Q: "..comboDam.."/"..target.health)
		if comboDam > target.health then
			CastSpellTarget("Q", target)
--			PrintState(3, "Did Q")
			return
		end
	end	

	-- try to execute with E
	target = GetWeakEnemy("MAGIC", spells["shunpo"].range)
	if target and CanUse("shunpo") then
		local comboDam = GetSpellDamage("shunpo", target)
		if #GetInRange(target, 50, daggers) > 0 then
			comboDam = comboDam + GetSpellDamage("dagger", target)
		end
--		PrintState(4, "E: "..comboDam.."/"..target.health)
		if comboDam > target.health then
			CastSpellTarget("E", target)
--			PrintState(4, "Did E")
			return
		end
	end
	

	-- I have shunpo and sinister left
	-- if in sinister range, prefer that
	target = GetWeakEnemy("MAGIC", spells["shunpo"].range)	
	if target and 
		CanUse("shunpo") and
		CanUse("sinister")
	then
		local comboDam = GetSpellDamage("shunpo", target) + 
		                 GetSpellDamage("sinister", target)
		if #GetInRange(target, 50, daggers) > 0 then
			comboDam = comboDam + GetSpellDamage("dagger", target)
		end
--		PrintState(5, "WE: "..comboDam.."/"..target.health)		
		if comboDam > target.health then
			if GetDistance(target) < spells["sinister"].range then
				CastSpellTarget("W", target)
--				PrintState(5, "Did W")
				return
			else
				CastSpellTarget("E", target)
--				PrintState(5, "Did E")
				return
			end
		end
	end

	-- I have blades and sinister left
	target = GetWeakEnemy("MAGIC", spells["blades"].range)	
	if target and 
		CanUse("blades") and
		CanUse("sinister")
	then
		local comboDam = GetSpellDamage("blades", target) + 
		                 GetSpellDamage("dagger", target) +
		                 GetSpellDamage("sinister", target)
--		PrintState(6, "QW: "..comboDam.."/"..target.health)
		if comboDam > target.health then
			CastSpellTarget("Q", target)
--			PrintState(6, "Did Q")
			return
		end
	end

--
--	if lastHotkey == 3 then 
--		CastHotkey("SPELLE:WEAKENEMY ONESPELLHIT=#((spellq_ready)*(((spellq_level*30)+30+((player_ap*45)/100))-1)+(spelle_ready)*(((spelle_level*25)+15+((player_ap*4)/10))-1)+(spellw_ready)*(((spellw_level*35)+5+((player_ap*25)/100)+((player_ad*6)/10))-1)+(spell4_ready)*(((target_hpmax*15)/100)-1)+(spell3_ready)*(300+((player_ap*4)/10))) RANGE=700 NOSHOW")
--		lastHotkey = 1
--		return
--	elseif lastHotkey == 1 then
--		CastHotkey("SPELLW:WEAKENEMY ONESPELLHIT=#((spellq_ready)*(((spellq_level*30)+30+((player_ap*45)/100))-1)+(spelle_ready)*(((spelle_level*25)+15+((player_ap*4)/10))-1)+(spellw_ready)*(((spellw_level*35)+5+((player_ap*25)/100)+((player_ad*6)/10))-1)+(spell4_ready)*(((target_hpmax*15)/100)-1)+(spell3_ready)*(300+((player_ap*4)/10))) RANGE=375 NOSHOW")
--		lastHotkey = 2
--		return
--	elseif lastHotkey == 2 then
--		CastHotkey("SPELLQ:WEAKENEMY ONESPELLHIT=#((spellq_ready)*(((spellq_level*30)+30+((player_ap*45)/100))-1)+(spelle_ready)*(((spelle_level*25)+15+((player_ap*4)/10))-1)+(spellw_ready)*(((spellw_level*35)+5+((player_ap*25)/100)+((player_ad*6)/10))-1)+(spell4_ready)*(((target_hpmax*15)/100)-1)+(spell3_ready)*(300+((player_ap*4)/10))) RANGE=675 NOSHOW")
--		lastHotkey = 3
--		return
--	end
end

function onCreateObj(object)
	local s=object.charName
	if find(s,"katarina_daggered") then
		table.insert(daggers, object)
	elseif find(s,"katarina_deathLotus_mis.troy") then
		spinning = true
		lastRDagger = GetClock()
	end
end

-- preferrs throws that include hitting heroes.
-- will keep throwing until heroes get pretty close.
function QFarm()
	local didW = false
	if CanUse("sinister") and GetClock() - lastQ > 500 then			
		local sinRange = GetInRange(me, spells["sinister"].range, MINIONS)
		local dagDam = GetSpellDamage("dagger")
		for _,minion in ipairs(sinRange) do
			if minion.health < GetSpellDamage("sinister", minion) then
				didW = true
				CastSpellTarget("W", minion)
				break
			elseif #GetInRange(minion, 50, daggers) > 0 and 
				minion.health < (GetSpellDamage("sinister", minion) + GetSpellDamage("dagger", minion)) 
			then
				didW = true
				if GetWeakEnemy("MAGIC", spells["sinister"].range) and
					#GetInRange(me, 950, TURRETS) > 0
				then
					CastSpellTarget("W", minion)
				end
				break
			end
		end
	end

	if CanCastSpell("Q") and not didW then
	
		local nearTargets = {}
		local initialTargets = {}

		-- gather the possible bounce targets and possible initial targets		
		local boundingDistance = 3000
		for _,minion in ipairs(MINIONS) do
			if GetDistance(me, minion) < boundingDistance then
				table.insert(nearTargets, minion)
				if GetDistance(me, minion) < 675+150 then
					table.insert(initialTargets, minion)
				end
			end
		end
		for _,hero in ipairs(ENEMIES) do
			if hero.visible == 1 and GetDistance(me, hero) < boundingDistance and hero.dead ~= 1 then
				table.insert(nearTargets, hero)
				if GetDistance(me, hero) < 675+150 then
					table.insert(initialTargets, hero)
				end
			end
		end
		
		SortByDistance(initialTargets)
		
		-- bounce path with the best score		
		local bestKills = 0
		local bestKillTargets = nil
		local bestKillDeaths  = nil
		
		for _, initialTarget in ipairs(initialTargets) do
			local tKills, tKillTargets, tKillDeaths = getBouncePath(initialTarget, nearTargets) 
		
			if tKills > bestKills then
				bestKillTargets = tKillTargets
				bestKills = tKills
				bestKillDeaths = tKillDeaths
			end
		end
		
		if bestKillTargets then
			DrawCircleObject(bestKillTargets[1], 90, violet)
			for i,t in ipairs(bestKillTargets) do
				local bkti = bestKillTargets[i]
				if i > 1 then
					LineBetween(bestKillTargets[i-1], bkti)
				end
				if not find(bkti.charName, "Minion") then
					DrawCircleObject(bkti, 80, green)
				end
				if bestKillDeaths[i] then
					DrawCircleObject(bkti, 70, red)
					DrawCircleObject(bkti, 72, red)
					DrawCircleObject(bkti, 74, red)
				else
					DrawCircleObject(bkti, 70, yellow)								
				end
			end
			if GetDistance(bestKillTargets[1]) < 675 then
				if GetWeakEnemy("MAGIC", 1500) and
					#GetInRange(me, 950, TURRETS) > 0
				then
					-- do nothing if there's a hero nearby and i'm under a tower
				else 
					CastQ(bestKillTargets[1])
				end
			end
		end
	end	
end

function getBouncePath(target, nearTargets)
	local tKills = 0 
	local tKillTargets = {}
	local tKillDeaths  = {}

	local bbDam = GetSpellDamage("blades") -- reset blades damage for next path
	local testNearby = copy(nearTargets)
	local jumps = 0
	while jumps < 5 do
		local nearestI = GetNearestIndex(target, testNearby)
		if nearestI then
			if target and GetDistance(target, testNearby[nearestI]) > 400 then
				break
			end
			target = testNearby[nearestI]					
			local isHero = not find(target.charName, "Minion")
			table.insert(tKillTargets, target)
			if CalcMagicDamage(target, bbDam) > target.health then
				if isHero then
					tKills = tKills + 5  -- 5 points for a hero kill
				else
					tKills = tKills + 1  -- 1 point for a minion kill
				end
				table.insert(tKillDeaths, true)
			else
				if isHero then
					tKills = tKills + .5  -- half a point for hitting a champ
				end
				table.insert(tKillDeaths, false)
			end
			table.remove(testNearby, nearestI)
		else
			break  -- out of bounce targets
		end
		jumps = jumps+1
		bbDam = bbDam*.9 
	end
	return tKills, tKillTargets, tKillDeaths
end

function CastQ(target)
	lastQ = GetClock()
	CastSpellTarget("Q", target)
end

AddOnCreate(onCreateObj)
SetTimerCallback("Run")