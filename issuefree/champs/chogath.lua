require "issuefree/timCommon"
require "issuefree/modules"

print("\nTim's Cho'Gath")

AddToggle("", {on=true, key=112, label="- - -"})
AddToggle("feast", {on=true, key=113, label="Feast"})
AddToggle("jungle", {on=true, key=114, label="Jungle"})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "rupture"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

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
	noblock=true,
	cost=90
}
spells["scream"] = {
	key="W",
	range=650,
	color=violet,
	base={75,125,175,225,275},
	cost={70,80,90,100,110},
	cone=60
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


function Run()
	spells["AA"].bonus = GetSpellDamage("vorpal")

   if StartTickActions() then
      return true
   end

   if CheckDisrupt("scream") or
   	CheckDisrupt("rupture")
	then
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

   if CastAtCC("rupture") then
      return true
   end

	if HotKey() and CanAct() then
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

			local creeps = reverse(SortByHealth(GetAllInRange(me, "feast", BIGCREEPS, MAJORCREEPS)))
			for _,creep in ipairs(creeps) do
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

   EndTickActions()
end

function Action()
	if CanUse("scream") then
		local target = GetMarkedTarget() or GetWeakestEnemy("scream")
		if target then
			UseItem("Deathfire Grasp", target)
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

   local target = GetMarkedTarget() or GetMeleeTarget()
   if AutoAA(target) then
      return true
   end
   return false
end

function FollowUp()
   if IsOn("move") then
      if MeleeMove() then
         return false
      end
   end
   return false
end

local function onCreate(object)
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)

SetTimerCallback("Run")