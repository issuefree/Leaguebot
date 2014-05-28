require "issuefree/timCommon"
require "issuefree/modules"

pp("Tim's Soraka")

spells["starfall"] = {
	key="Q", 
	range=650,  
	color=red,    
	base={40,65,90,115,140},
	ap=.4,
	cost={30,40,50,60,70}
}
spells["heal"] = {
	key="W", 
	range=750,  
	color=green,  
	base={70,120,170,220,270}, 
	ap=.35,
	type="H",
	cost={80,100,120,140,160}
}
spells["infuseMana"] = {
	key="E", 
	range=725,
	color=blue,   
	base={20,40,60,80,100},
	mana=.05,
	type="H"
}
spells["infuse"] = {
	key="E",
	range=725,
	base={40,70,100,130,160}, 
	mana=.05,
	ap=.4
}
spells["wish"] = {
	key="R",
	base={150,250,350},
	ap=.55,
	cost=100
}
spells["consecration"] = {
	range=1000, 
	color=yellow
}



AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=false, key=116, label="Last Hit", auxLabel="{0} / {1}", args={"starfall", "infuse"}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

function CheckDisrupt()
   if Disrupt("DeathLotus", "infuse") then return true end

   if Disrupt("Grasp", "infuse") then return true end

   if Disrupt("AbsoluteZero", "infuse") then return true end

   if Disrupt("BulletTime", "infuse") then return true end

   if Disrupt("Duress", "infuse") then return true end

   if Disrupt("Idol", "infuse") then return true end

   if Disrupt("Monsoon", "infuse") then return true end

   if Disrupt("Meditate", "infuse") then return true end

   if Disrupt("Drain", "infuse") then return true end

   if Disrupt("HeartSeeker", "infuse") then return true end

   return false
end

function Run()
	spells["infuseMana"].cost = me.maxMana * .05

	if me.dead == 1 then
		PrintAction("Dead")
		return
	end
		
	Wish()

   if CheckDisrupt() then
      return true
   end

	if IsRecalling(me) then
		PrintAction("Recalling")
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

		if KillMinion("starfall") then
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
		if target then
			Cast("infuse", target)
			PrintAction("Infuse D", target)
			return true
		end
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
	if not CanUse("infuse") then return false end

	local dam = GetSpellDamage("infuse")

	local minions = SortByHealth(GetInRange(me, "infuse", MINIONS))
	for _,minion in ipairs(minions) do
		if WillKill("infuse", minion) then
			Cast("infuse", minion)
			PrintAction("Infuse lasthit")
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
				if CalculateDamage(minion, dam) > minion.health then
					kills = kills + 1
					if kills >= 2 then
						Cast("starfall", me)
						PrintAction("Starfall for lasthit")
						return true
					end
				end
			end
		end

      if KillMinion("AA") then
         return true
      end
	end

	if IsOn("clearminions") and Alone() then
		if CanUse("starfall") then
			if #GetInRange(me, "starfall", MINIONS) > 2 then
				Cast("starfall", me)
				PrintAction("Starfall for clear")
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

function healTeam()   
   if not CanUse("heal") then return false end
      
   local base = GetSpellDamage("heal")

   local spell = GetSpell("heal")

   local bestInRangeT = nil
   local bestInRangeP = 1
   local bestOutRangeT = nil
   local bestOutRangeP = 1
   
   for _,hero in ipairs(ALLIES) do
   	local value = base * 1+(1-GetHPerc(hero))/2
      if GetDistance(HOME, hero) > spell.range+250 and
         hero.health + value < hero.maxHealth*.9 and
         not HasBuff("wound", hero) and 
         not IsRecalling(hero)
      then
         if GetDistance(hero) < spell.range then        
            if not bestInRangeT or
               GetHPerc(hero) < bestInRangeP
            then           
               bestInRangeT = hero
               bestInRangeP = GetHPerc(hero)
            end
         elseif GetDistance(hero) < spell.range+250 then
            if not bestOutRangeT or
               GetHPerc(hero) < bestOutRangeP
            then           
               bestOutRangeT = hero
               bestOutRangeP = GetHPerc(hero)
            end
         end
      end
   end
   if bestInRangeT then
      Circle(bestInRangeT, 100, green)
   end
   if bestOutRangeT and GetDistance(me, bestOutRangeT) > spell.range then
      Circle(bestOutRangeT, 100, yellow, 4)
   end

   if bestInRangeT then
      Cast(spell, bestInRangeT)
      return true
   end
   return false
end

function infuseTeam()
	if not CanUse("infuse") then
		return false
	end
	
	local base = GetSpellDamage("infuseMana")

	local bestInRangeT = nil
	local bestInRangeP = 1
		
	local heroes = GetInRange(me, "infuse", ALLIES)
	for _,hero in ipairs(heroes) do
		local value = base * 1+(1-GetMPerc(hero))/2
		if not IsMe(hero) and
		   GetDistance(HOME, hero) > 1000 and
		   hero.mana > 0 and 
		   hero.mana + value <= hero.maxMana and
		   not IsRecalling(hero)
		then			
			if not bestInRangeT or
			   GetMPerc(hero) < bestInRangeP
			then		
				bestInRangeT = hero
				bestInRangeP = GetMPerc(hero)
			end
		end
	end
	
	if bestInRangeT then
		-- don't infuse mostly full people if there's a nearby enemy
		if Alone() or bestInRangeP < .5 then
			Cast("infuse", bestInRangeT)
			PrintAction("Infuse M", bestInRangeT)
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
		if GetHPerc(ally) < .33 then
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