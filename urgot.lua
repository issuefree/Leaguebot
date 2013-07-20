require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Urgot")

--AddToggle("healTeam", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"green"}})

-- find charges
-- mouseover hit enemies with charges

spells["hunter"] = {
  key="Q", 
  range=1000,
  lockedRange=1200,
  color=violet, 
  base={10,40,70,100,130}, 
  ad=.85,
  delay=2,
  speed=15,
  width=80
}
spells["capacitor"] = {
  key="W"
}
spells["charge"] = {
  key="E", 
  range=900, 
  color=yellow, 
  base={75,130,185,240,295}, 
  bonusAd=.6,
  delay=2,
  speed=12,
  width=300
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
