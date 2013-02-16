require "Utils"
require "timCommon"
require "modules"
require "support"

print("Tim's Soraka")

spells["starfall"]     = {key="Q", range=650,  color=red,    base={60,85,110,135,160},  ap=.4}
spells["heal"]         = {key="W", range=750,  color=green,  base={70,140,210,280,350}, ap=.45}
spells["infuseMana"]   = {key="E", range=725,  color=blue,   base={40,80,120,160,200},  ap=0}
spells["infuseDamage"] = {key="E",                           base={50,100,150,200,250}, ap=.6}
spells["wish"]         = {key="R",                           base={200,320,440},        ap=.7}
spells["consecration"] = {         range=1000, color=yellow}

AddToggle("farm",     {on=false, key=112, label="Farm Minions", auxLabel="{0} / {1}", args={"starfall", "infuseDamage"}})
AddToggle("healing",  {on=true,  key=113, label="Heal Team", auxLabel="{0}", args={"heal"}})
AddToggle("infusing", {on=true,  key=114, label="Infuse Team", auxLabel="{0}", args={"infuseMana"}})
AddToggle("wish",     {on=true,  key=115, label="Wish Alert", auxLabel="{0}", args={"wish"}})

function Run()
	TimTick()
	SupportTick()	

	Wish()

	
	if IsRecalling(me) then
		return
	end

	healTeam()

	target = GetWeakEnemy('MAGIC',725,"NEARMOUSE")

	if IsKeyDown(hotKey) ~= 0 then
		if target ~= nil then
			if GetDistance(me, target) < 650 and CanCastSpell("Q") then CastSpellTarget("Q", target) end 
			if GetDistance(me, target) < 725 and CanCastSpell("E") then CastSpellTarget("E", target) end 
		end
		UseAllItems()
	end

	infuseTeam()
	
	if not GetWeakEnemy("MAGIC", 1000) then
		SafeCall(Farm)
	end
end 

function onCreateObj(object)
	onCreateObjSupport()
end

function Farm()
	if not IsOn("farm") then
		return	
	end
	
	local maxQ = GetSpellDamage("starfall")
	local maxE = GetSpellDamage("infuseDamage")
	local maxA = me.baseDamage + me.addDamage	
	-- count the qfarmable minions
	qMinions = 0
	weakMinion = nil  -- for aa
	strongMinion = nil -- for infuse
	 
	for i, minion in ipairs(MINIONS) do
		if GetDistance(me,minion) < 650 and CalcMagicDamage(minion, maxQ) > minion.health then			
			qMinions = qMinions+1
		end
		if GetDistance(me,minion) < 725 and CalcMagicDamage(minion, maxE) > minion.health then
			if strongMinion == nil or minion.health > strongMinion.health then
				strongMinion = minion
			end
		end
		if GetDistance(me,minion) < me.range and CalcDamage(minion, maxA) > minion.health then
			if weakMinion == nil or minion.health < weakMinion.health then
				weakMinion = minion
			end
		end 
	end
	
	if qMinions > 1 then
		if CanCastSpell("Q") then
			CastSpellTarget("Q", me)
		end	
	end
	
	if weakMinion then
		AttackTarget(weakMinion)
	end
	
	if strongMinion then
		if CanCastSpell("E") then
			CastSpellTarget("E", strongMinion)
		end
	end
	
	if qMinions == 1 then
		if CanCastSpell("Q") then
			CastSpellTarget("Q", me)
		end
	end
end

function healTeam()
	if not IsOn("healing") then
		return
	end
	
	local maxW = GetSpellDamage("heal")

	local bestInRangeT = nil
	local bestInRangeP = 1
	local bestOutRangeT = nil
	local bestOutRangeP = 1
	
	for _,hero in ipairs(ALLIES) do
		if GetDistance(HOME, hero) > 1000 and
		   hero.health + maxW < hero.maxHealth*.9 and
		   not isWounded(hero) and 
		   not IsRecalling(hero)
		then
			if GetDistance(me, hero) < 750 then			
				if not bestInRangeT or
				   hero.health/hero.maxHealth < bestInRangeP
				then				
					bestInRangeT = hero
					bestInRangeP = hero.health/hero.maxHealth
				end
			elseif GetDistance(me, hero) < 1000 then
				if not bestOutRangeT or
				   hero.health/hero.maxHealth < bestOutRangeP
				then				
					bestOutRangeT = hero
					bestOutRangeP = hero.health/hero.maxHealth
				end
			end
		end
	end
	if bestInRangeT then
		DrawCircleObject(bestInRangeT, 100, green)
	end
	if bestOutRangeT and GetDistance(me, bestOutRangeT) > 750 then
		CustomCircle(100, 4, yellow, bestOutRangeT)
	end

	if CanCastSpell("W") then
		-- let me know if someone oustside of range is in need
		if bestOutRangeT and 
		   ( not bestInRangeT or
			 ( bestOutRangeP < .33 and
			   bestInRangeP > .5 ) )			
		then
--			PlaySound("Beep")
		end

		if bestInRangeT then
			CastSpellTarget("W", bestInRangeT)
		end
	end						   
end

function infuseTeam()
	if not IsOn("infusing") or GetSpellLevel("E") == 0 then
		return
	end
	
	local bestInRangeT = nil
	local bestInRangeP = 1
	
	local maxE = GetSpellDamage("infuseMana")
	
	for i = 1, objManager:GetMaxHeroes(), 1 do
		local hero = objManager:GetHero(i)
		if hero.name ~= me.name and
		   hero.team == me.team and		
		   GetDistance(HOME, hero) > 1000 and
		   hero.mana ~= 0 and 
		   hero.mana + maxE <= hero.maxMana and
		   GetDistance(me, hero) < 725 and
		   not IsRecalling(hero)		    
		then			
			if not bestInRangeT or
			   hero.mana/hero.maxMana < bestInRangeP
			then		
				bestInRangeT = hero
				bestInRangeP = hero.mana/hero.maxMana
			end
		end
	end
	
	if bestInRangeT then
		if CanCastSpell("E") and 
		   (not GetWeakEnemy("MAGIC", 800) or bestInRangeP < .5) 
		then
			CastSpellTarget("E", bestInRangeT)
		else
			DrawCircleObject(bestInRangeT, 100, blue)
		end
	end
end     

function Wish()
	if not CanCastSpell("R") then
		return
	end
	for _,ally in ipairs(ALLIES) do
		if ally.health/ally.maxHealth < .33 then
			for _,enemy in ipairs(ENEMIES) do
				if GetDistance(ally, enemy) < 1000 then
					PlaySound("Beep")
					return
				end
			end
		end
	end
end

SetTimerCallback("Run")