require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Jax")
pp(" - pop counter if it will stun")
pp(" - auto empower if I'm hitting champs or creeps")
pp(" - auto ult if I have 2 or more nearby enemies")
pp(" - leap on marked or weak enemies")
pp(" - prep leap with empower and counter")
pp(" - start counter if I'm in range")
pp(" - lasthit with empower")

AddToggle("move", {on=true, key=112, label="Move"})
AddToggle("autoUlt", {on=true, key=113, label="AutoUlt"})
AddToggle("jungle", {on=true, key=114, label="Jungle", auxLabel="{0}", args={"smite"}})
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
	color=yellow,
	type="P",
	cost={70,75,80,85,90}
}
spells["might"] = {
	key="R",
	cost=100
}

function Run()
   if StartTickActions() then
      return true
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
	   UseItems()
		if Action() then
         return true
      end
	end

	if IsOn("lasthit") then
		if CanUse("leap") and VeryAlone() then
			local minions = GetInRange(me, "leap", MINIONS)
			for _,minion in ipairs(minions) do
				if find(minion.name, "MechCannon") then
					if WillKill("leap", minion) then
						Cast("leap", minion)
						PrintAction("Leap cannon")
						return true
					end
				end
			end
		end

		if Alone() then
	      if ModAAFarm("empower", P.empower) then
	         return true
	      end
	   end

	end

	if IsOn("jungle") then
		if ModAAJungle("empower", P.empower) then
			return true
		end
	end


   if HotKey() then
      if FollowUp() then
         return
      end
   end

   EndTickActions()
end

-- jump to good targets
-- use empower when I can hit shit
-- pop ult when it makes sense
-- stun when I can hit people
-- hit people

-- when I'm about to jump to people or I'm in range of people use stun


function Action()
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


   if MeleeAA("empower") then
      return true
   end

	return false
end

function FollowUp()
   if IsOn("lasthit") and Alone() then
      if KillMinion("AA") then
         return true
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
   if IsOn("autoUlt") and 
   	CanUse("might") and
      GetHPerc(me) < .75 and
      not Alone()
   then
   	if ( spell.target and IsMe(spell.target) and IsEnemy(unit) ) or
   		( SpellShotTarget(unit, spell, me) )
   	then
	      Cast("might", me)
	      PrintAction("Might", spell.name)
	   end
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)

SetTimerCallback("Run")