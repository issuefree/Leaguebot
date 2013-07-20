require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Brand")

--AddToggle("healTeam", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"green"}})

-- check for blaze on targets
-- combos with blaze
-- pyro bounce

spells["sear"] = {
  key="Q", 
  range=900, 
  color=violet, 
  base={80,120,160,200,240}, 
  ap=.65,
  delay=2,
  speed=12,
  width=80
}
spells["pillar"] = {
  key="W", 
  range=902, 
  color=yellow, 
  base={75,120,165,210,255}, 
  ap=.6,
  delay=2+6,
  speed=99,
  area=250
}
spells["conflag"] = {
  key="E", 
  range=625, 
  color=violet, 
  base={70,105,140,175,210}, 
  ap=.55,
  delay=2,
  area=300
}
spells["conflag"] = {
  key="E", 
  range=625, 
  color=violet, 
  base={70,105,140,175,210}, 
  ap=.55,
  delay=2+2,
  area=200
}
spells["pyro"] = {
  key="R", 
  range=750, 
  color=red, 
  base={150,250,350}, 
  ap=.5,
  delay=2,
  speed=10
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
