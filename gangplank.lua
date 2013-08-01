require "Utils"
require "timCommon"
require "modules"

print("\nTim's Gangplank")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("ult", {on=true, key=115, label="Ult Alert"})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "gun"}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["gun"] = {
	key="Q", 
	range=625, 
	color=yellow, 
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
	TimTick()
			
   if IsRecalling(me) or me.dead == 1 then
      return
   end

   if HotKey() and CanAct() then
      Action()
   end
	
	if IsOn("ult") and CanCastSpell("R") then
		for _,enemy in ipairs(ENEMIES) do
			if enemy and enemy.health/enemy.maxHealth < .5 and #GetInRange(enemy, 500, ALLIES) > 0 then
				PlaySound("Beep")
			end
		end
	end

	if CanUse("oranges") and me.health/me.maxHealth < .5 then
		Cast("oranges", me)
		return
	end

	if CanUse("orange") and me.health/me.maxHealth < .75 and Alone() then
		Cast("oranges", me)
		return
	end
	
	if IsOn("lasthit") and Alone() then
		KillFarMinion(spells["gun"])
	end
end

function Action()
	UseItems()

	local target = GetWeakEnemy("PHYS", spells["gun"].range)
	if target and CanUse("shot") then
		Cast("gun", target)
		return
	end

	if target and CanUse("morale") then
		local manaThresh = 1
		manaThresh = manaThresh - .1*#GetInRange(me, spells["morale"].range, ALLIES)
		manaThresh = manaThresh - .05*#GetInRange(me, spells["gun"].range, ENEMIES)
		
		if me.mana/me.maxMana > manaThresh then
			Cast("morale", me)
			return
		end
	end

	local aaTarget = GetWeakEnemy("PHYS", spells["AA"].range+100)
	if AA(aaTarget) then
		return
	end

	if IsOn("lasthit") and Alone() then
      if KillWeakMinion("AA") then
         return
      end
	end		

	if IsOn("clearminions") and Alone() then
      local minions = SortByHealth(GetInRange(me, "AA", MINIONS))
      if AA(minions[#minions]) then
         return
      end
   end

   if IsOn("move") and not aaTarget then
      MoveToCursor() 
   end

end

SetTimerCallback("Run")