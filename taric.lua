 require "Utils"
require "timCommon"
require "modules"
require "support"

pp("Tim's Taric")
pp(" - Heal")

spells["heal"] = {
	key="Q",
	range=750,
	color=green,
	base={60,100,140,180,220}, 
	ap=.6
}
spells["shatter"]  = {key="W", range=400,  color=red,    base={60,105,150,195,240}, ap=.6}
spells["radiance"] = {key="R", range=400,  color=red,    base={171,285,399},        ap=.7}
spells["aura"]     = {key="W", range=1000, color=yellow}
spells["stun"]     = {key="E", range=625,  color=violet,    base={150,195,240},        ap=.6}

AddToggle("healing", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"heal"}})

function Run()
   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return
   end

   if IsOn("healing") and CanUse("heal") then
		if healTeam() then
			return true
		end
	end

	if HotKey() and CanAct() then
		if Action() then
			return
		end
	end
end 

function Action()
	UseItems()
	return false
end

function healTeam()
	local maxHeal = GetSpellDamage("heal")

	local bestInRangeT = nil
	local bestInRangeP = 1
	local bestOutRangeT = nil
	local bestOutRangeP = 1
	
	for _,hero in ipairs(ALLIES) do
		if GetDistance(HOME, hero) > 1000 and
		   hero.name ~= me.name and
		   hero.health + maxHeal < hero.maxHealth*.9 and
		   hero.dead == 0 and
		   hero.visible == 1 and
		   not isWounded(hero) and 
		   not IsRecalling(hero)
		then
			local dist = GetDistance(hero)
			if dist < 750 then
				if not bestInRangeT or
				   hero.health/hero.maxHealth < bestInRangeP
				then
					bestInRangeT = hero
					bestInRangeP = hero.health/hero.maxHealth
				end
			elseif dist < 1000 then
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
		Circle(bestInRangeT, 100, green)
	end
	if bestOutRangeT and GetDistance(me, bestOutRangeT) > 750 then
		Circle(bestOutRangeT, 100, yellow, 4)
	end

	-- let me know if someone oustside of range is in need
	if bestOutRangeT and 
	   ( not bestInRangeT or
		  ( bestOutRangeP < .33 and
		    bestInRangeP > .5 ) 
		)
	then
--			PlaySound("Beep")
	end
		
	if bestInRangeT then
		Cast("heal", bestInRangeT)
		PrintAction("Heal", bestInRangeT)
		return true
	elseif me.health + maxHeal*1.4 < me.maxHealth*.75 then
		Cast("heal", me)
		PrintAction("Heal", me)
		return true
	end
end

function useItems()
	UseItems()
end

SetTimerCallback("Run")