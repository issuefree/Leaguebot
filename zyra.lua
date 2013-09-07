require "Utils"
require "timCommon"
require "modules"
require "support"

pp("\nTim's Zyra")

--AddToggle("healTeam", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"green"}})

spells["bloom"] = {
  key="Q", 
  range=825, 
  color=violet, 
  base={75,115,155,195,235}, 
  ap=.6,
  delay=2,
  speed=12, --?
  area=300  --?
}
spells["seed"] = {
  key="W", 
  range=825, 
  color=green
}
spells["roots"] = {
  key="E", 
  range=1100, 
  color=yellow, 
  base={60,95,130,165,200}, 
  ap=.5,
  delay=2,
  speed=12, --?
  width=80  --?
}
spells["strangle"] = {
  key="R", 
  range=700, 
  color=red, 
  base={180,265,350}, 
  ap=.7,
  delay=2,
  area=600  --?
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
