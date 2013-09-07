require "Utils"
require "timCommon"
require "modules"

print("\nTim's Cho'Gath")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("feast", {on=true, key=113, label="Feast"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

local function feastRange()
	return GetWidth(me)+150
end

spells["rupture"] = {
	key="Q",
	range=950,
	color=yellow,
	base={80,135,190,245,305},
	ap=1,
	delay=9,
	speed=99,
	radius=275,
	cost=90
}
spells["scream"] = {
	key="W",
	range=700,
	color=violet,
	base={75,125,175,225,275},
	delay=2.5,
	ap=.7
}
spells["feast"] = {
	key="R",
	range=feastRange,
	color=red,
	base={300,475,650}, 
	ap=.7,
	cost=100,
	type="T"
}

function Run()
   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return true
   end

	if CanUse("feast") then
		local target = GetWeakestEnemy("feast")
		if target and target.health < GetSpellDamage("feast") then
			Cast("feast", target)
			PrintAction("Feast", target)
			return true
		end

		GetInRange(me, "feast", CREEPS)
		for _,creep in ipairs(CREEPS) do
			if ListContains(creep.name, MajorCreepNames) and
				creep.health < 1000 + me.ap*.7
			then
				Cast("feast", creep)
				PrintAction("Feast", creep)
				return true
			end
		end
	end	

	if HotKey() and CanAct() then
		UseItems()
		if Action() then
			return true
		end
	end

   if IsOn("lasthit") and Alone() then
      -- lasthit with rupture if it kills 2 minions or more
      if KillMinionsInArea("rupture", 2) then
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
	if CanUse("scream") then
		local target = GetMarkedTarget() or GetWeakestEnemy("scream")
		if target then
			Cast("scream", target)
			PrintAction("Scream", target)
			return true
		end
	end

   -- try to deal some damage with rupture
   if CanUse("rupture") then
      -- look for a big group or some kills.
      local hits, kills, score = GetBestArea(me, "rupture", 1, 3, ENEMIES)
      if score >= 3 then
         CastXYZ("rupture", GetCenter(hits))
         PrintAction("Rupture for AoE")
         return true
      end

      -- barring that throw it at the weakest single
      local target = GetMarkedTarget() or GetWeakestEnemy("rupture")
      if target then
         CastSpellFireahead("rupture", target)
         PrintAction("Rupture", target)
         return true
      end
   end

   local target = GetMarkedTarget() or GetWeakEnemy("PHYS", spells["AA"].range*2)
   if target and AA(target) then
      PrintAction("AA", target)
      return true
   end
   return false
end

function FollowUp()
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

SetTimerCallback("Run")