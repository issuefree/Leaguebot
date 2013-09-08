require "Utils"
require "timCommon"
require "modules"
require "support"

pp("Tim's Soraka")

spells["starfall"] = {
	key="Q", 
	range=650,  
	color=red,    
	base={60,85,110,135,160},
	ap=.4,
	cost={20,35,50,65,80}
}
spells["heal"] = {
	key="W", 
	range=750,  
	color=green,  
	base={70,140,210,280,350}, 
	ap=.45,
	cost={80,110,140,170,200}
}
spells["infuseMana"] = {
	key="E", 
	range=725,
	color=blue,   
	base={40,80,120,160,200}
}
spells["infuse"] = {
	key="E",
	range=725,
	base={50,100,150,200,250}, 
	ap=.6
}
spells["wish"] = {
	key="R",
	base={200,320,440},
	ap=.7,
	cost={100,175,250}	
}
spells["consecration"] = {
	range=1000, 
	color=yellow
}



AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=false, key=116, label="Last Hit", auxLabel="{0} / {1}", args={"starfall", "infuseDamage"}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

function Run()
	if me.dead == 1 then
		return
	end
		
	Wish()

	if IsRecalling(me) then
		return
	end
   
   -- lots of actions aren't calling CanAct() because I want to interrupt AA

   if healTeam("heal") then
   	return true
   end

	if infuseTeam() then
		return true
	end

	if HotKey() then
		if Action() then
			return true
		end
	end
	
	if IsOn("lasthit") and Alone() then
		if infuseMinion() then
			return true
		end
	end

   if HotKey() and CanAct() then -- interrupt because this is low priority stuff
      if FollowUp() then
         return true
      end
   end

end 

function Action()
	UseItems()

	if CanUse("infuse") then
		local target = GetMarkedTarget() or GetWeakestEnemy("infuse")
		Cast("infuse", target)
		PrintAction("Infuse", target)
		return true
	end

	if CanUse("starfall") then
		local target = GetWeakestEnemy("starfall")
		if target then
			Cast("starfall", me) 
			PrintAction("Starfall")
			return true
		end
   end
	return false		
end

function infuseMinion()
	if not CanUse("infuse") then return false	end

	local dam = GetSpellDamage("infuse")

	local minions = SortByHealth(GetInRange(me, "infuse", MINIONS))
	for _,minion in ipairs(minions) do
		if CalcMagicDamage(minion, dam) > minion.health then
			Cast("infuse", minion)
			return true
		end
	end
	return false
end

function FollowUp()
	if IsOn("lasthit") and Alone() then
		if CanUse("starfall") then
			local dam = GetSpellDamage("starfall")
			local minions = SortByHealth(GetInRange(me, "starfall", MINIONS))
			local kills = 0
			for _,minion in ipairs(minions) do
				if CalcMagicDamage(minion, dam) > minion.health then
					kills = kills + 1
					if kills >= 2 then
						Cast("starfall", me)
						return true
					end
				end
			end
		end

		if KillWeakMinion("AA") then
         return true
      end		
	end

	if IsOn("clearminions") and Alone() then
		if CanUse("starfall") then
			if #GetInRange(me, "starfall", MINIONS) > 2 then
				Cast("starfall", me)
				return true
			end
		end

      local minions = SortByHealth(GetInRange(me, "AA", MINIONS))
      local minion = minions[#minions]
      if minion and AA(minion) then
         return true
      end
   end

   return false
end

function infuseTeam()
	if not CanUse("infuse") then
		return false
	end
	
	local maxE = GetSpellDamage("infuseMana")

	local bestInRangeT = nil
	local bestInRangeP = 1
		
	local heroes = GetInRange(me, "infuse", ALLIES)
	for _,hero in ipairs(heroes) do
		if hero.name ~= me.name and
			GetDistance(HOME, hero) > 1000 and
		   hero.mana ~= 0 and 
		   hero.mana + maxE <= hero.maxMana and
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
		-- don't infuse mostly full people if there's a nearby enemy
		if not GetWeakEnemy("MAGIC", 800) or bestInRangeP < .5 then
			Cast("infuse", bestInRangeT)
			return true
		else
			Circle(bestInRangeT, 100, blue)
			return false
		end
	end
	return false
end     

function Wish()
	if not CanUse("wish") then
		return false
	end
	for _,ally in ipairs(ALLIES) do
		if ally.health/ally.maxHealth < .33 then
			for _,enemy in ipairs(ENEMIES) do
				if GetDistance(ally, enemy) < 1000 then
					PlaySound("Beep")
					return false
				end
			end
		end
	end
	return false
end

function onCreateObj(object)
end

SetTimerCallback("Run")