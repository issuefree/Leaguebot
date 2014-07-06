require "issuefree/timCommon"
require "issuefree/modules"

print("\nTim's Nunu")

AddToggle("", {on=true, key=112, label=""})
AddToggle("boil",  {on=true, key=113, label="Boil ADC"})
AddToggle("blast", {on=true, key=114, label="Auto Blast", auxLabel="{0}", args={"iceblast"}})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "consume"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})


spells["consume"] = {
	key="Q",
	range=225,
	base={400,550,700,850,1000},
	type="T",
	color=yellow,
	cost=60
}
spells["fed"] = {
	key="Q",
	base={70,115,160,205,250},
	type="H",
	ap=.75
}
spells["boil"] = {
	key="W", 
	range=700,  
	color=green,
	cost=50
}
spells["iceblast"] = {
	key="E", 
	range=575,  
	color=violet, 
	base={85,130,175,225,275}, 
	type="M",
	ap=1,
	cost={75,85,95,105,115}
}
spells["zero"] = {
	key="R", 
	range=650, 
	color=red,    
	base={625,875,1125}, 
	ap=2.5,
	type="M",
	cost=100
}

local lastBoil = time()

function Run()
   if StartTickActions() then
      return true
   end

	if HotKey() then 
		if Action() then
			return true
		end
	end

	if IsOn("lasthit") then
		if me.maxHealth - me.health > GetSpellDamage("fed") then
			if KillMinion("consume", nil, force) then
				return true
			end
		end
	end

	EndTickActions()
end

function Action()
	if IsOn("boil") then
		if CanUse("boil") and
		   time() - lastBoil > 12 and 
		   ADC and
		   ADC.name ~= me.name and
		   GetDistance(ADC) < GetSpellRange("boil")
		then
			Cast("boil", ADC)
			PrintAction("Boil", ADC)
			lastBoil = time()
			return true
		end
	end
	
	if IsOn("blast") then
		if CanUse("iceblast") then
			if EADC and GetDistance(EADC) < GetSpellRange("iceblast") then
				Cast("iceblast", EADC)
				PrintAction("Iceblast EADC", EADC)
				return true
			else
				local target =  GetMarkedTarget() or GetWeakestEnemy("iceblast")
				if target then
					Cast("iceblast", target)
					PrintAction("Iceblast", target)
					return true
				end
			end
		end
	end

   local target = GetMarkedTarget() or GetMeleeTarget()
   if AutoAA(target) then
      return true
   end

   return false
end

SetTimerCallback("Run")