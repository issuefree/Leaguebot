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


InitAAData({
	windup=.3,
	extraRange=-25,
	particles = {"RelentlessAssault_tar", "EmpowerTwoHit"},
	attacks={"JaxBasicAttack", "JaxCritAttack", "jaxrelentless"},
	resets = {me.SpellNameW}
})

SetChampStyle("bruiser")

AddToggle("", {on=true, key=112, label="- - -"})
AddToggle("autoUlt", {on=true, key=113, label="AutoUlt"})
AddToggle("jungle", {on=true, key=114, label="Jungle", auxLabel="{0}", args={"smite"}})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "empower"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

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
	type="M",
	modAA="empower",
	object="armsmaster_empower",
	range=GetAARange,
	rangeType="e2e",
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
spells["relentless"] = {
	base={100,160,220},
	ap=.7,
	type="M"
}

local ultCounter = 0

function WillProcMight()
	return GetSpellLevel("R") > 0 and ultCounter >= 2
end

function Run()
	spells["AA"].bonus = 0
	if WillProcMight() then
		spells["AA"].bonus = GetSpellDamage("relentless")
		if CanAct() then			
			Circle(me, GetAARange()+3+GetWidth()/2, yellow, 3)
		end
	end

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

	if HotKey() and CanAct() then
		if Action() then
         return true
      end
	end

	if IsOn("lasthit") then
		if CanUse("leap") and VeryAlone() then
			local minions = GetInRange(me, "leap", MINIONS)
			for _,minion in ipairs(minions) do
				if IsBigMinion(minion) then
					if WillKill("leap", minion) then
						if IsInAARange(minion) and
						   ( WillKill("AA", minion) or 
						     ( CanUse("empower") and WillKill("empower", minion) ) )
						then
						else
							Cast("leap", minion)
							PrintAction("Leap cannon")
							return true
						end
					end
				end
			end
		end

		if Alone() then
	      if ModAAFarm("empower") then
	         return true
	      end
	   end

	end

	if IsOn("jungle") then
		if ModAAJungle("empower") then
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
	   	not IsInAARange(target, me, 50)
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

   local target = GetMarkedTarget() or GetMeleeTarget()
   if AutoAA(target, "empower") then
      return true
   end

	return false
end

function FollowUp()
  	return false
end

local function onObject(object)
	PersistBuff("counter", object, "jaxdodger")

   if find(object.charName, "RelentlessAssault") and GetDistance(object) < 350 then
   	ultCounter = 0
   	pp("reset ultCounter on activate")
   end
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

   if IAttack(unit, spell) and GetSpellLevel("R") > 0 then
   	ultCounter = ultCounter + 1
   	DoIn(
   		function() 
   			ultCounter = 0 
   			pp("reset ultCounter on timeout")
   		end, 
   		2.75, "ultCounter")
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)

SetTimerCallback("Run")