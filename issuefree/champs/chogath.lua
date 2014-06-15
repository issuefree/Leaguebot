require "issuefree/timCommon"
require "issuefree/modules"

print("\nTim's Cho'Gath")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("feast", {on=true, key=113, label="Feast"})
AddToggle("jungle", {on=true, key=114, label="Jungle"})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "rupture"}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

local function feastRange()
	return GetWidth(me)+150
end

MAX_FEAST_RANGE = 161

spells["rupture"] = {
	key="Q",
	range=950,
	color=yellow,
	base={80,135,190,245,305},
	ap=1,
	delay=10,
	speed=0,
	radius=275,
	cost=90,
	noblock=true
}
spells["scream"] = {
	key="W",
	range=650,
	color=violet,
	base={75,125,175,225,275}
}
spells["vorpal"] = {
	key="E",
	base={20,35,50,65,80},
	ap=.3,
	type="M"
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
spells["feastCreep"] = {
	key="R",
	range=feastRange,
	color=red,
	base=1000, 
	ap=.7,
	cost=100,
	type="T"
}

spells["AA"].damOnTarget = 
   function(target)
      return 0
   end


function CheckDisrupt()
	if Disrupt("DeathLotus", "scream") then return true end
	if Disrupt("DeathLotus", "rupture") then return true end

	if Disrupt("Grasp", "scream") then return true end
	if Disrupt("Grasp", "rupture") then return true end

	if Disrupt("AbsoluteZero", "scream") then return true end
	if Disrupt("AbsoluteZero", "rupture") then return true end

	if Disrupt("BulletTime", "scream") then return true end
	if Disrupt("BulletTime", "rupture") then return true end

	if Disrupt("Duress", "scream") then return true end
	if Disrupt("Duress", "rupture") then return true end

	if Disrupt("Idol", "rupture") then return true end

	if Disrupt("Monsoon", "scream") then return true end
	if Disrupt("Monsoon", "rupture") then return true end

	if Disrupt("Meditate", "scream") then return true end
	if Disrupt("Meditate", "rupture") then return true end

	if Disrupt("Drain", "scream") then return true end
	if Disrupt("Drain", "rupture") then return true end

	return false
end

function Run()
	spells["AA"].bonus = GetSpellDamage("vorpal")

   if StartTickActions() then
      return true
   end

	if CanUse("feast") then
		local target = GetWeakestEnemy("feast")
		if target and WillKill("feast", target) then
			Cast("feast", target)
			PrintAction("Feast", target)
			return true
		end

	end	

	if CheckDisrupt() then
		return true
	end

   if CastAtCC("rupture") then
      return true
   end

	if HotKey() then
		UseItems()
		if Action() then
			return true
		end
	end


   if IsOn("lasthit") then
   	if VeryAlone() then
   		if me.range < MAX_FEAST_RANGE then   		
	   		if KillMinion("feastCreep") then
	   			PrintAction("Feast on creep")
	   			return true
	   		end
	   	end
   	end

   	if Alone() then
   		if GetMPerc(me) > .33 then
		      if KillMinionsInArea("rupture", 2) then
		         return true
		      end
			end
		end
   end


	if IsOn("jungle") and Alone() then
		if CanUse("feast") then
			local creeps = MAJORCREEPS
			
			if me.range < MAX_FEAST_RANGE then
				creeps = concat(creeps, BIGCREEPS)
			end

			for _,creep in ipairs(GetAllInRange(me, "feast", BIGCREEPS, MAJORCREEPS)) do
				if WillKill("feastCreep", creep) then
					Cast("feast", creep)
					PrintAction("Feast", creep)
					return true
				end
			end
		end
	end

   if HotKey() then
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

   	-- target marked first if applicable
      local target = GetMarkedTarget() 
      if target and IsGoodFireahead("rupture", target) then
         CastFireahead("rupture", target)
         PrintAction("Rupture marked", target)
         return true
      end

      -- look for a big group or some kills.
      local hits, kills, score = GetBestArea(me, "rupture", 1, 3, ENEMIES)
      if score >= 3 then
         CastXYZ("rupture", GetCenter(hits))
         PrintAction("Rupture for AoE")
         return true
      end

      -- barring that throw it at the weakest single
      if SkillShot("rupture") then
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
   -- if IsOn("move") then
   --    if MeleeMove() then
   --       return false
   --    end
   -- end
   return false
end

SetTimerCallback("Run")