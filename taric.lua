require "Utils"
require "timCommon"
require "modules"
require "support"

pp("Tim's Taric")

spells["heal"]     = {key="Q", range=750,  color=green,  base={60,100,140,180,220}, ap=.6}
spells["shatter"]  = {key="W", range=400,  color=red,    base={60,105,150,195,240}, ap=.6}
spells["radiance"] = {key="R", range=400,  color=red,    base={171,285,399},        ap=.7}
spells["aura"]     = {key="W", range=1000, color=yellow}
spells["stun"]     = {key="E", range=625,  color=violet,    base={150,195,240},        ap=.6}

AddToggle("healing", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"heal"}})

function Run()
	TimTick()

	if IsRecalling(me) then
		return
	end

	healTeam()
	if IsKeyDown(hotKey) ~= 0 then	
		useItems()
	end
end 

function onCreateObj(object)
	onCreateObjSupport()
end

function healTeam()
	if not IsOn("healing") then
		return
	end
	
	local maxHeal = GetSpellDamage("heal")

	local bestInRangeT = nil
	local bestInRangeP = 1
	local bestOutRangeT = nil
	local bestOutRangeP = 1
	
	for _,hero in ipairs(ALLIES) do
		if GetDistance(HOME, hero) > 1000 and
		   hero.charName ~= me.name and
		   hero.health + maxHeal < hero.maxHealth*.9 and
		   hero.dead == 0 and
		   hero.visible == 1 and
--		   not isWounded(hero) and 
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
		DrawCircleObject(bestOutRangeT, 100, yellow)
		DrawCircleObject(bestOutRangeT, 102, yellow)
		DrawCircleObject(bestOutRangeT, 104, yellow)
	end

	if CanCastSpell("Q") then
	
		-- let me know if someone oustside of range is in need
		if bestOutRangeT and 
		   ( not bestInRangeT or
			 ( bestOutRangeP < .33 and
			   bestInRangeP > .5 ) )			
		then
--			PlaySound("Beep")
		end
			
		if bestInRangeT then
			CastSpellTarget("Q", bestInRangeT)
			pp("Healing: "..bestInRangeT.name)
		elseif me.health + maxHeal*1.4 < me.maxHealth*.75 then
			CastSpellTarget("Q", me)
			pp("Healing: me")
		end
	end		
end

function useItems()
	UseItems()
end

SetTimerCallback("Run")