require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Ashe")

--AddToggle("healTeam", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"green"}})

function getHawkRange()   
   if GetSpellLevel("E") == 1 then return 2500 end
   if GetSpellLevel("E") == 2 then return 3250 end
   if GetSpellLevel("E") == 3 then return 4000 end
   if GetSpellLevel("E") == 4 then return 4750 end
   if GetSpellLevel("E") == 3 then return 5500 end
   return 0
end

spells["volley"] = {
  key="W", 
  range=1200, 
  color=violet, 
  base={40,50,60,70,80}, 
  ad=1,
  delay=2,
  speed=20,
  cone=57.5
}

spells["hawkshot"] = {
  key="E", 
  range=getHawkRange, 
  color=blue
}

spells["arrow"] = {
  key="R", 
  range=1600, 
  color=violet, 
  base={250,425,600}, 
  ap=1,
  delay=2,
  speed=16,
  width=160,
  area=250
}

function Run()
	TimTick()
	if HotKey() then
		UseItems()
	end
end

local function onObject(object)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")