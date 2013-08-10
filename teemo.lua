require "Utils"
require "timCommon"
require "modules"

print("\nTim's Teemo")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("shroom", {on=true, key=113, label="Auto Shroom"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["blind"] = {
	key="Q", 
	range=680, 
	color=violet, 
	base={80,125,170,215,260}, 
	ap=.8
}
spells["toxic"] = {
	key="E", 
	base={10,20,30,40,50}, 
	ap=.3
}
spells["shroom"] = {
	key="R",
	range=230,
	color=green,	
	base={200,325,450},
	ap=.8,
	radius=115
}

local poisons = {}
local shrooms = {}

function Run()
	TimTick()
	
	Clean(poisons, "charName", "Global_poison")
	Clean(shrooms, "charName", "Noxious Trap")

   if IsRecalling(me) or me.dead == 1 then
      return
   end
	
	if HotKey() and CanAct() then
		Action()
	end
end
    
function Action()
	UseItems()

	if CanUse("blind") then
		local spell = spells["blind"]
   	if EADC and GetDistance(EADC) < spell.range then
      	Cast("blind", EADC)
      	return
   	else
         local target = GetWeakEnemy("MAGIC", spell.range)
         if target then
            Cast("blind", target)
            return
         end
      end
   end   

   -- get enemies I can throw a shroom at (shroom range + shroom boom radius)
   -- make sure there isn't already a nearby shroom (try not to spam them)
   -- throw the shroom at them or as far as I can in their direction
   if IsOn("shroom") and CanUse("shroom") then
   	local shroom = spells["shroom"]
   	local targets = SortByDistance(GetInRange(me, shroom.range+shroom.radius, ENEMIES))
   	for _,target in ipairs(targets) do
   		if #GetInRange(target, shroom.radius*3, shrooms) == 0 then

   			local dist = math.min(shroom.range, GetDistance(target))   			
   			local point = Projection(me, target, dist)
   			CastXYZ(shroom, point)
   			return

   		end
   	end
   end
	
	local target = GetWeakEnemy("MAGIC", spells["AA"].range)
   if AA(target) then
   	return
   end

	if IsOn("lasthit") and Alone() then
      if KillWeakMinion("AA") then
      	return
      end
	end 
	
	-- hit the highest health minion in range that isn't poisoned	
	-- if there isn't one, hit the highest health minion
	if IsOn("clearminions") and Alone() then
		local nearMinions = SortByHealth(GetInRange(me, "AA", MINIONS))

		for _,minion in rpairs(nearMinions) do
			if not (#GetInRange(minion, 50, poisons) > 0) then
				if AA(minion) then
					return
				end
			end
		end

		for _,minion in rpairs(nearMinions) do
			if AA(minion) then
				return
			end
		end
	end

	if IsOn("move") then
      MoveToCursor() 
   end
end

--BlindShot_tar.troy
--BlindShot_mis.troy
--Toxicshot_tar.troy
--Toxicshot_mis.troy

local function onObject(object)
	if IsOn("clearminions") and GetDistance(object) < 1000 then
		if find(object.charName, "Global_poison") then
			table.insert(poisons, object)
		end 
	end

	if find(object.charName, "Noxious Trap") then
		table.insert(shrooms, object)
	end
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")