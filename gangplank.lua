require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Gangplank")
pp(" - heal up with oranges")
pp(" - warn for good ult")
pp(" - shoot for lasthit")
pp(" - morale if near enemies")


AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("ult", {on=true, key=115, label="Ult Alert"})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "gun"}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["gun"] = {
	key="Q", 
	range=625, 
	color=violet, 
	base={20,45,70,95,120}, 
	ad=1,
	onHit=true,
	type="P",
	cost={50,55,60,65,70}
}
spells["oranges"] = {
	key="W",
	base={80,150,220,290,360}, 
	ap=1,
	cost=65
}
spells["morale"] = {
	key="E", 
	range=1200, 
	color=blue,
	cost={50,55,60,65,70}
}
spells["barrage"] = {
	key="R",
	base="75,120,165",
	ap=.2,
	area="575",
	cost=100
}

function Run()
   if IsRecalling(me) or me.dead == 1 then
      return
   end

	-- if IsOn("ult") and CanUse("barrage") then
	-- 	for _,enemy in ipairs(ENEMIES) do
	-- 		if enemy and enemy.health/enemy.maxHealth < .5 and #GetInRange(enemy, 500, ALLIES) > 0 then
	-- 			PlaySound("Beep")
	-- 		end
	-- 	end
	-- end

	if CanUse("oranges") abd
		( me.health/me.maxHealth < .5 or 
		  me.health/me.maxHealth < .75 and Alone() )
	then
		PrintAction("oranges")
		Cast("oranges", me)		
		return true
	end

   if HotKey() and CanAct() then
      if Action() then
      	return true
      end
   end

	if IsOn("lasthit") and Alone() then
		if KillFarMinion("gun") then
			PrintAction("gun down a minion")
			return true
		end
	end

   if HotKey() and CanAct() then
	   if FollowUp() then
	   	return true
	   end
	end
end

function Action()
	UseItems()

	if CanUse("gun") then
		local target = GetMarkedTarget() or GetWeakestEnemy("gun")
		if target and Cast("gun", target) then
			PrintAction("Shoot", target)
			return true
		end
	end

	if not Alone() and CanUse("morale") then
		local manaThresh = 1
		manaThresh = manaThresh - .1*#GetInRange(me, spells["morale"].range, ALLIES)
		manaThresh = manaThresh - .05*#GetInRange(me, spells["gun"].range, ENEMIES)
		
		if me.mana/me.maxMana > manaThresh then
			Cast("morale", me)
			PrintAction("morale")
			return true
		end
	end

   local target = GetMarkedTarget() or GetWeakEnemy("PHYS", spells["AA"].range*2)
   if AA(target) then
		PrintAction("AA "..target.charName)
	   return true
   end

   return false
end

function FollowUp()
   if IsOn("lasthit") and Alone() then
      if KillWeakMinion("AA") then
         PrintAction("AA lasthit")
         return true
      end
   end

   if IsOn("clearminions") and Alone() then
      -- hit the highest health minion
      local minions = SortByHealth(GetInRange(me, "AA", MINIONS))
      if AA(minions[#minions]) then
         PrintAction("AA clear minions")
         return true
      end
   end

   if IsOn("move") then
      local target = GetMarkedTarget() or GetWeakEnemy("PHYS", spells["AA"].range*2)
      if target then
      	if GetDistance(target) > spells["AA"].range then
	      	PrintAction("MTT")
	         MoveToTarget(target)
	         return true
	      end
      else      	
         MoveToCursor() 
         PrintAction("Move")
         return true
      end
   end

	return false
end

SetTimerCallback("Run")