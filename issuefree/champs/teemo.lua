require "issuefree/timCommon"
require "issuefree/modules"

print("\nTim's Teemo")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("shroom", {on=true, key=113, label="Auto Shroom"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})

spells["blind"] = {
	key="Q", 
	range=680, 
	color=violet, 
	base={80,125,170,215,260}, 
	ap=.8,
	cost={70,80,90,100,110}
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
	ap=.5,
	radius=115,
	cost={75,100,125}
}

local poisons = {}
local shrooms = {}

function Run()
	Clean(poisons, "charName", "Global_poison")
	Clean(shrooms, "charName", "Noxious Trap")

	spells["AA"].bonus = GetSpellDamage("toxic")

   if StartTickActions() then
      return true
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
      	PrintAction("Blind ADC", EADC)
      	return true
   	else
         local target = GetWeakEnemy("MAGIC", spell.range)
         if target then
            Cast("blind", target)
            PrintAction("Blind", target)
            return true
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
   			PrintAction("Plant a Shroom")
   			return true
   		end
   	end
   end
	
   -- teemo really wants to aa people with low MR right?
   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end

	-- hit the highest health minion in range that isn't poisoned	
	-- if there isn't one, hit the highest health minion
	if IsOn("clear") and Alone() then
		local nearMinions = SortByHealth(GetInRange(me, "AA", MINIONS))

		for _,minion in rpairs(nearMinions) do
			if not (#GetInRange(minion, 50, poisons) > 0) then
				if AA(minion) then
					PrintAction("AA for clear")
					return true
				end
			end
		end
	end

	return false
end

--BlindShot_tar.troy
--BlindShot_mis.troy
--Toxicshot_tar.troy
--Toxicshot_mis.troy

local function onObject(object)
	if IsOn("clear") and GetDistance(object) < 1000 then
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