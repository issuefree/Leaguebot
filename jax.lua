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
AddToggle("autoUlt", {on=false, key=113, label="AutoUlt"})
AddToggle("", {on=true, key=114, label=""})
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

local counter = nil
local empower = nil

function Run()
	TimTick()

   UseAutoItems()

	if IsKeyDown(string.byte("X")) == 1 then
		WardJump("leap")
		PrintAction("Wardjump")
		return
	end

	if Check(counter) and GetWeakestEnemy("counter") and CanUse("counter") then
		PrintAction("stun")
		Cast("counter", me)
	end

	if JustAttacked() and CanUse("empower") and not Check(empower) then
	   if GetWeakestEnemy("AA") or #GetAllInRange(me, spells["AA"].range+50, CREEPS) > 0 then
			PrintAction("Whap")
			Cast("empower", me)
		end
	end


	if HotKey() and CanAct() then
		if Action() then
         return
      end
	end

   if HotKey() and CanAct() then
      if FollowUp() then
         return
      end
   end

	PrintAction()
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
	   	GetDistance(target) > spells["AA"].range
	   then
	   	if CanUse("counter") and not Check(counter) then
	   		Cast("counter", me)
	   		PrintAction("prep counter")
	   	end
	   	if CanUse("empower") and not Check(empower) then
	   		Cast("Empower the leap", me)
	   		PrintAction("start empower")
	   	end
	   	Cast("leap", target)
	   	PrintAction("Leap "..target.charName)
	   	return true
	   end
	end

	if GetWeakestEnemy("counter") and CanUse("counter") and not Check(counter) then
		Cast("counter", me)
		PrintAction("start counter")
	end

   local target = GetMarkedTarget() or GetWeakEnemy("PHYS", spells["AA"].range*2)
   if AA(target) then
		PrintAction("AA "..target.charName)
	   return true
   end

   if IsOn("move") then
      local target = GetMarkedTarget() or GetWeakEnemy("PHYS", spells["AA"].range*2)
      if target then
      	if GetDistance(target) > spells["AA"].range then
	         MoveToTarget(target)
	      	PrintAction("MTT")
	         return false
	      end
      else      	
         MoveToCursor() 
         PrintAction("Move")
         return false
      end
   end

	return false
end

function FollowUp()
   if IsOn("lasthit") and Alone() then
	   if KillWeakMinion("AA") then
	   	PrintAction("AA lasthit")
	      return true
	   end

   	if CanUse("empower") then
	   	local minions = SortByHealth(SortByDistance(GetInRange(me, spells["AA"].range+100, CREEPS, MINIONS)))
			local target = minions[1]
	      if target and GetSpellDamage("empower", target) > target.health then
	         Cast("empower", me)
	         PrintAction("empower lasthit")
	         if ListContains(target, CREEPS) then
	            ClickSpellXYZ("M", target.x, target.y, target.z, 0)
	            return true
	         else 
	            AttackTarget(target) -- not using AA as I want to interupt auto attacks
	            return true
	         end
	      end
	   end
	end

   if IsOn("clearminions") and Alone() then
      local minions = SortByHealth(GetInRange(me, "AA", MINIONS))
      if AA(minions[#minions]) then
         PrintAction("AA clear minions")
         return true
      end
   end

	return false
end

function DrawTarget()
	if CanCastSpell("Q") then
		if target then
			CustomCircle(100,6,2,target)
	    end
	elseif targetaa then
		CustomCircle(100,6,2,targetaa)
	end
end

local function onObject(object)
   if find(object.charName,"jaxdodger") and 
      GetDistance(object) < 75 
   then
      counter = StateObj(object)
   end   
   if find(object.charName,"armsmaster_empower") and 
      GetDistance(object) < 150 
   then
      empower = StateObj(object)
   end   

end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)

SetTimerCallback("Run")