require "issuefree/timCommon"
require "issuefree/modules"

pp("Tim's Soraka")

SetChampStyle("support")

InitAAData({ 
	projSpeed = 1.0, windup=.25,
	particles = {"SorakaBasicAttack"}
})

spells["starcall"] = {
	key="Q", 
	range=950,  
	color=violet,    
	base={70,110,150,190,230},
	ap=.35,
	delay=2.4+5-6,
	speed=15, --?
	radius=300-25, -- reticle
	innerRadius=100,
	noblock=true,
}
spells["heal"] = {
	key="W", 
	range=450,  
	color=green,  
	base={110,140,170,200,230}, 
	ap=.6,
	type="H",
	cost={80,100,120,140,160}
}
spells["equinox"] = {
	key="E", 
	range=925,  
	color=blue,    
	base={70,110,150,190,230},
	ap=.4,
	delay=2.4+5-3, 
	speed=0, 
	radius=300, -- reticle
	noblock=true,
}
spells["wish"] = {
	key="R",
	base={150,250,350},
	ap=.55,
	cost=100
}

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=false, key=116, label="Last Hit", auxLabel="{0} / {1}", args={"AA", "starcall"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

function Run()
   if StartTickActions() then
      return true
   end
		
	Wish()

   if CheckDisrupt("equinox") then
      return true
   end

	if IsRecalling(me) then
		PrintAction("Recalling")
		return
	end
   
   if healTeam("heal") then
   	return true
   end

	if HotKey() then
		if Action() then
			return true
		end
	end
	
	if IsOn("lasthit") and Alone() then
		if KillMinionsInArea("starcall") then
			return true
		end
	end

   if HotKey() and CanAct() then -- interrupt because this is low priority stuff
      if FollowUp() then
         return true
      end
   end
   EndTickActions()
end 

function Action()
	if SkillShot("equinox") then
		return true
	end

	if SkillShot("starcall", nil, nil, .7) then
		return true
   end

	return false		
end

function FollowUp()
   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end

	if IsOn("clear") and Alone() then

   end

   return false
end

function healTeam()   
   if not CanUse("heal") then return false end

   if GetHPerc(me) < .33 then return false end
      
   local value = GetSpellDamage("heal")

   local spell = GetSpell("heal")

   local bestInRangeT = nil
   local bestInRangeP = 1
   local bestOutRangeT = nil
   local bestOutRangeP = 1
   
   for _,hero in ipairs(ALLIES) do
   	if not IsMe(hero) then
	      if GetDistance(HOME, hero) > spell.range+250 and
	         hero.health + value < hero.maxHealth*.9 and
	         GetHPerc(me) >= GetHPerc(hero) and
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

function Wish()
	if not CanUse("wish") then
		return false
	end
	for _,ally in ipairs(ALLIES) do
		if GetHPerc(ally) < .33 then
			for _,enemy in ipairs(ENEMIES) do
				if GetDistance(ally, enemy) < 1000 then
					-- PlaySound("Beep")
					LineBetween(me, ally)
					-- return false
				end
			end
		end
	end
	return false
end

function AutoJungle()
   local creep = GetBiggestCreep(GetInRange(me, "AA", CREEPS))
   if AA(creep) then
      PrintAction("AA "..creep.charName)
      return true
   end
end   
SetAutoJungle(AutoJungle)

function onCreateObj(object)
end

SetTimerCallback("Run")