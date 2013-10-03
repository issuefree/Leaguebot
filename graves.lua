require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Graves")

--AddToggle("healTeam", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"green"}})

spells["shot"] = {
  key="Q", 
  range=950, 
  color=violet, 
  base={60,95,130,165,200}, 
  adBonus=.8,
  delay=2,
  speed=50,
  cone=30,
  noblock=true
}
spells["smoke"] = {
  key="W", 
  range=951, 
  color=yellow, 
  base={60,110,160,210,260}, 
  ap=.6,
  delay=2,
  speed=0,
  noblock=true
  area=250
}
spells["dash"] = {
  key="W", 
  range=425, 
  color=blue
}
spells["boom"] = {
  key="R", 
  range=1000, 
  color=red, 
  base={250,350,450}, 
  adBonus=1.4,
  delay=2,
  speed=50
}
spells["boomCone"] = {
  key="R", 
  range=1800, 
  color=red, 
  base={140,250,360}, 
  adBonus=1.2,
  delay=2,
  speed=50
}

function Run()
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
