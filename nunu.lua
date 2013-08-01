require "Utils"
require "timCommon"
require "modules"
require "support"

print("\nTim's Nunu")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("boil",  {on=true, key=113, label="Boil ADC"})
AddToggle("blast", {on=true, key=114, label="Auto Blast", auxLabel="{0}", args={"iceblast"}})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "consume"}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})


spells["consume"] = {
	key="Q",
	range=125,
	base={500,625,750,875,1000},
	color=yellow
}
spells["fed"] = {
	key="Q",
	base={90,130,170,210,250},
	ap=.75
}
spells["boil"] = {
	key="W", 
	range=700,  
	color=green
}
spells["iceblast"] = {
	key="E", 
	range=550,  
	color=violet, 
	base={85,130,175,225,275}, 
	ap=1
}
spells["zero"] = {
	key="R", 
	range=650, 
	color=red,    
	base={625,875,1125}, 
	ap=2.5
}

local lastBoil = time()

function Run()
	TimTick()
	
   if IsRecalling(me) or me.dead == 1 then
      return
   end

	if HotKey() and CanAct() then 
		Action()
	end
end

function Action()
	UseItems()
	if IsOn("boil") then
		if CanUse("boil") and
		   time() - lastBoil > 12 and 
		   ADC and
		   ADC.name ~= me.name and
		   GetDistance(ADC) < spells["boil"].range 
		then
			Cast("boil", ADC)
			lastBoil = time()
			return
		end
	end
	
	if IsOn("blast") then
		local spell = GetSpell("iceblast")
		if CanUse("iceblast") then
			if GetDistance(EADC) < spell.range then
				Cast("iceblast", EADC)
				return
			else
				local target = GetWeakEnemy("MAGIC", spell.range)
				if target then
					Cast("iceblast", target)
					return
				end
			end
		end
	end

   local aaTarget = GetWeakEnemy("PHYSICAL", spells["swing"].range+100)
   if aaTarget then
      if AA(aaTarget) then
         return
      end
	end

	if IsOn("lasthit") then
		if me.maxHealth - me.health > GetSpellDamage("fed") then
			if KillWeakMinion("consume") then
				return
			end
		end

		if Alone() and KillWeakMinion("AA") then
			return
		end
	end

   if IsOn("clearminions") and Alone() then
      local minions = SortByHealth(GetInRange(me, "AA", MINIONS))
      if AA(minions[#minions]) then
         return
      end
   end

   if IsOn("move") then
      MoveToCursor() 
   end
end

SetTimerCallback("Run")