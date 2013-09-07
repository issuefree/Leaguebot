require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Master Yi")

--AddToggle("healTeam", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"green"}})

spells["alpha"] = {
  key="Q", 
  range=600, 
  color=violet, 
  base={100,150,200,250,300}, 
  ap=1,
  delay=2
}
spells["meditate"] = {
  key="W", 
  base={200,350,500,650,800}, 
  ap=2,
  delay=2
}
spells["wuju"] = {
  key="E", 
  delay=2
}
spells["highlander"] = {
  key="R", 
  duration={8,10,12},
  delay=2
}

local medTime = -1000
local ultTime = -1000

local function isMed()
	return os.clock() - medTime < 5
end
local function isUlt()
	local ultLevel = GetSpellLevel("R")
	if ultLevel == 0 then
		return false
	end   
	return os.clock() - ultTime < spells["highlander"].duration[ultLevel]
end

-- it might be easier to set a bounding radius and see if looking 
-- for a chain is worth it rather than calculating all of the possible chains
-- i.e. Find a target and see if you can chain rather than looking at
-- all of the chains and finding the best chain
local maxChainDist = 1200

function Run()
	if isMed() or IsRecalling(me) then
		return
	end


	if HotKey() then
		UseItems()

		local ks = alphaBot()

		-- no immediate kill, no small chain kill, just hurt some folks
		if not ks then
			local target = GetWeakEnemy("MAGIC", 600)
			if target then
				if CanUse("alpha") then
					CastSpellTarget("Q", target)
				elseif CanUse("meditate") and me.health/me.maxHealth < .25 then
					CastSpellTarget("W", me)            
				elseif CanUse("wuju") and GetDistance(target) < spells["AA"].range + 50 then
					CastSpellTarget("E", me)
					AttackTarget(target)
				end
			else
				local intersection = 
						GetIntersection( GetInRange(me, 600, MINIONS, ENEMIES),
						GetInRange(target, 600, MINIONS, ENEMIES) )
				for _,t in ipairs(intersection) do
					if #GetInRange(t, 600, MINIONS, ENEMIES) <= 4 and
						#GetInRange(t, 1020, TURRETS) == 0 
					then
						CastSpellTarget("Q", t)
						break
					end
				end
			end
		end
	end
end

function alphaBot()
	if not CanUse("alpha") then return false end ;

	-- pass one. Kill the one you're with		
	local target = GetWeakEnemy("MAGIC", 600)
	if target and 
		GetSpellDamage(spells["alpha"], target) > target.health 
	then
		if #GetInRange(target, 1020, TURRETS) == 0 then
			if not isUlt() then CastSpellTarget("R", me) end
			CastSpellTarget("Q", target)
			CastSpellTarget("E", me)
			AttackTarget(target)
			return true
		end
	end

   -- we have a killable in "range" let's see if we can hit him.

	-- find all of the targets in range that are in range of the target
	-- find one of those targetes that has 4 or less targets in the range
	-- (so we can hit what we wanted to hit)
	target = GetWeakEnemy("MAGIC", maxChainDist)
	if target and 
		GetSpellDamage(spells["alpha"], target) > target.health 
	then
		local intersection = 
			GetIntersection( GetInRange(me, 600, MINIONS, ENEMIES),
								  GetInRange(target, 600, MINIONS, ENEMIES) )
		for _,t in ipairs(intersection) do
			if #GetInRange(t, 600, MINIONS, ENEMIES) <= 4 and
				#GetInRange(t, 1020, TURRETS) == 0 
			then
				pp(GetSpellDamage(spells["alpha"], target).." -> "..target.health)
				if not isUlt() then CastSpellTarget("R", me) end
				CastSpellTarget("Q", t)
				return true
			end
		end
	end
	return false
end

local function onObject(object)   
end

local function onSpell(object, spell)
	if object.name == me.name and spell.name == "Meditate" then
		medTime = os.clock()
	end
	if object.name == me.name and spell.name == "Highlander" then
		ultTime = os.clock()
	end

end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
