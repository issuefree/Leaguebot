require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Jax")
pp(" - pop counter if it will stun")
pp(" - auto empower if I'm hitting champs or creeps")
pp(" - auto ult if I have 2 or more nearby enemies")
pp(" - leap on marked or weak enemies")
pp(" - prep leap with empower and counter")
pp(" - start counter if I'm in range")
pp(" - auto attack marked or weak in 2xAA range")
pp(" - lasthit with AA or empower")
pp(" - clear minions")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("autoUlt", {on=true, key=113, label="AutoUlt"})
AddToggle("jungle", {on=true, key=114, label="Jungle"})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "empower"}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["leap"] = {
	key="Q", 
	range=700, 
	color=violet, 
	base={70,110,150,190,230}, 
	ap=.6, 
	adBonus=1,
	type="P",
	cost=65
}
spells["empower"] = {
	key="W", 
	base={40,75,110,145,180}, 
	ap=.6,
	ad=1,
	type="M",
	onHit=true,
	cost=30
}
spells["counter"] = {
	key="E", 
	range=375, 
	color=red,
	type="P",
	cost={70,75,80,85,90}
}
spells["might"] = {
	key="R",
	cost=100
}

function Run()
   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return
   end

	if IsKeyDown(string.byte("X")) == 1 then
		WardJump("leap")
		PrintAction("Wardjump")
		return
	end

	if P.counter and GetWeakestEnemy("counter") and CanUse("counter") then
		Cast("counter", me)
		PrintAction("Stun")
	end

	if HotKey() then
		if Action() then
         return
      end
	end

	if CanUse("empower") and not P.empower then

		if IsOn("lasthit") then
			local target = SortByHealth(GetInRange(me, "AA", MINIONS))[1]	   	
			if target and WillKill("empower", target) and CanAct() and JustAttacked() then
	         Cast("empower", me)
	         PrintAction("empower lasthit")
	         AttackTarget(target)
	         return true
		   end
		end

		if IsOn("jungle") then
			local creeps = SortByHealth(GetAllInRange(me, GetSpellRange("AA")+50, CREEPS))
			local creep = creeps[#creeps]
			if creep then pp(creep.charName) end
			if creep and not WillKill("AA", creep) then
				if JustAttacked() then
					Cast("empower", me)
					PrintAction("Whap jungle")
				end
			end
		end

	end

   if HotKey() then
      if FollowUp() then
         return
      end
   end

end

-- jump to good targets
-- use empower when I can hit shit
-- pop ult when it makes sense
-- stun when I can hit people
-- hit people

-- when I'm about to jump to people or I'm in range of people use stun


function Action()
   UseItems()

   if IsOn("autoUlt") and
   	CanUse("might") and 
   	#GetInRange(me, spells["AA"].range*2, ENEMIES) >= 2 
  	then
   	Cast("might", me)
  		PrintAction("Might")
   end

   if CanUse("leap") then
	   local target = GetMarkedTarget() or GetWeakestEnemy("leap")
	   if target and
	   	GetDistance(target) < spells["leap"].range and
	   	GetDistance(target) > spells["AA"].range+50
	   then
	   	if CanUse("counter") and not P.counter then
	   		Cast("counter", me)
	   		PrintAction("prep counter")
	   	end
	   	if CanUse("empower") and not P.empower then
	   		Cast("empower", me)
	   		PrintAction("Empower Leap")
	   	end
	   	Cast("leap", target)
	   	PrintAction("Leap", target)
	   	return true
	   end
	end

	if GetWeakestEnemy("counter") and CanUse("counter") and not P.counter then
		Cast("counter", me)
		PrintAction("start counter")
	end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA", GetSpellRange("AA"))
   if target and ModAA("empower", target) then
      return true
   end


	return false
end

function FollowUp()
   if IsOn("lasthit") and Alone() then
      if KillMinion("AA") then
         return true
      end

   	if CanUse("empower") then
	   	local target = SortByHealth(GetInRange(me, GetSpellRange("AA"), MINIONS))[1]	   	
	      if target and WillKill("empower", target) and
	      	( JustAttacked() or not WillKill("AA", target) )
	      then
	         Cast("empower", me)
	         PrintAction("empower lasthit")
	         AttackTarget(target)
	         return true
	      end
	   end
	end

   if IsOn("clearminions") and Alone() then
      if HitMinion("AA", "strong") then
         return true
      end
   end

   if IsOn("move") then
      if MeleeMove() then
         return true
      end
   end

  	return false
end

local function onObject(object)
	PersistBuff("counter", object, "jaxdodger")
	PersistBuff("empower", object, "armsmaster_empower", 150)
end


local function onSpell(unit, spell)
   -- if spell.target and spell.target.name == me.name and
   --    me.health / me.maxHealth < .5 and
   --    CanUse("might")
   -- then
   --    Cast("might", me)
   -- end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)

SetTimerCallback("Run")