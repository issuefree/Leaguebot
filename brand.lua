require "Utils"
require "timCommon"
require "modules"
require "support"

pp("\nTim's Brand")

--AddToggle("healTeam", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"green"}})

spells["sear"] = {
  key="Q", 
  range=900, 
  color=violet, 
  base={80 / 120 / 160 / 200 / 240}, 
  ap=.65,
  delay=2,
  speed=12,
  width=80
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
