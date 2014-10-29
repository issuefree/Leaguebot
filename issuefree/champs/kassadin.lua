require "issuefree/timCommon"
require "issuefree/modules"

print("Tim's Kassadin")

SetChampStyle("caster")

InitAAData({
	windup=.2,
	resets = {me.SpellNameW}
})

AddToggle("execute", {on=false, key=112, label="Execute", auxLabel="", args={}})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}({1}) / {2}", args={GetAADamage, "blade", "sphere"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["sphere"] = {
	key="Q", 
	range=650, 
	color=violet, 
	base={80,105,130,155,180}, 
	ap=.7,
	cost={70,75,80,85,90}
}
spells["bladePassive"] = {
	key="W",
	base=20,
	ap=.1
}
spells["blade"] = {
	key="W",
	-- base={40,65,90,115,140},
	base={20,45,70,95,120},
	-- ap=.6,
	ap=.5,
	range=GetAARange,
	rangeType="e2e",
	modAA="blade",
	object="Kassadin_Base_W_buf"
}
spells["pulse"] = {
	key="E", 
	range=700-50, 
	color=yellow,
	base={80,105,130,155,180}, 
	ap=.7,
	delay=2,
	speed=0,
	cone=80,
	noblock=true
}
spells["rift"] = {
	key="R",
	range=700,
	color=blue, 
	base={80,100,120},
	maxMana=.02,
	cost=function() return 75*(2^riftStacks) end,
	bonus=function() return GetSpellDamage("riftStack")*riftStacks end,
	timeout=12,
	radius=150+GetWidth(me)
}
spells["riftStack"] = {
	base={40,50,60},
	maxMana=.01
}

lastRift = 0
riftStacks = 0

function Run()
	-- if P.blade then
	-- 	spells["AA"].bonus = 0
	-- else
		spells["AA"].bonus = GetSpellDamage("bladePassive")
	-- end

	if time() - lastRift > spells["rift"].timeout then
		riftStacks = 0
	end

   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen
   if CheckDisrupt("sphere") then
      return true
   end

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important
	if IsOn("lasthit") then
		if Alone() then

	      if ModAAFarm("blade") then
	      	return true
	      end

	   end

	   if VeryAlone() then
      	if CanUse("pulse") and P.pulse then
      		if KillMinionsInCone("pulse") then
      			return true
      		end
      	end

      	if KillMinion("sphere", "far") then
      		return true
      	end
	   end
   end

   
   -- low priority hotkey actions, e.g. killing minions, moving
   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()	
	if CanUse("rift") then
		for _,target in ipairs(ENEMIES) do
			if GetDistance(target) > 650 then -- out of range of normal spells
				if WillKill("sphere", target) or
					( WillKill("sphere", "pulse", target) and P.pulse )
				then
					CastXYZ("rift", target)
					PrintAction("Rift close for execute", target)
					return true
				end
			else
				if WillKill("sphere", target) or
				   ( WillKill("sphere", "pulse", target) and P.pulse )
				then
				else
					if WillKill("rift", "sphere", "blade", target) or
						( WillKill("rift", "sphere", "blade", "pulse", target) and P.pulse )
					then						
						CastXYZ("rift", target)
						PrintAction("Rift for execute", target)
						return true
					end
				end
			end
		end
	end

	if CastBest("sphere") then
		return true
	end

	if P.pulse then
		if CastBest("pulse") then
			return true
		end
	end

   local target = GetMarkedTarget() or GetMeleeTarget()
   if AutoAA(target, "blade") then
      return true
   end

   return false
end
function FollowUp()
	-- if CanUse("blade") then
	--    if IsOn("move") then
	--       if MeleeMove() then
	--          return true
	--       end
	--    end
	-- end
   return false
end

local function onCreate(object)
	PersistBuff("pulse", object, "Kassadin_Base_E_ready_buf")
end

local function onSpell(unit, spell)
	if ICast("rift", unit, spell) then
		lastRift = time()
		riftStacks = riftStacks + 1
	end
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")

