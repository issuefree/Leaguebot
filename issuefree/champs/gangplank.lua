require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Gangplank")
pp(" - heal up with oranges")
pp(" - warn for good ult")
pp(" - shoot for lasthit")
pp(" - morale if near enemies")

InitAAData({
	windup=.25,
	extraRange=15,
	resets={me.SpellNameQ}
})

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("ult", {on=true, key=115, label="Ult Alert"})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "gun"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

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
   if StartTickActions() then
      return true
   end

	-- if IsOn("ult") and CanUse("barrage") then
	-- 	for _,enemy in ipairs(ENEMIES) do
	-- 		if enemy and enemy.health/enemy.maxHealth < .5 and #GetInRange(enemy, 500, ALLIES) > 0 then
	-- 			PlaySound("Beep")
	-- 		end
	-- 	end
	-- end

	if CanUse("oranges") and
		( GetHPerc(me) < .5 or 
		  GetHPerc(me) < .75 and Alone() )
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
		if KillMinion("gun", {"far", "lowMana"}, true) then
			return true
		end
	end

   if HotKey() and CanAct() then
	   if FollowUp() then
	   	return true
	   end
	end

	EndTickActions()
end

function Action()
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
		
		if GetMPerc(me) > manaThresh then
			Cast("morale", me)
			PrintAction("morale")
			return true
		end
	end

   local target = GetMarkedTarget() or GetMeleeTarget()
   if AutoAA(target) then
      return true
   end

   return false
end

function FollowUp()
	return false
end

SetTimerCallback("Run")