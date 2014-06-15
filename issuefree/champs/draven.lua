require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Draven")

--AddToggle("healTeam", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"green"}})

spells["axe"] = {
  key="Q"
}
spells["rush"] = {
  key="W"
}
spells["standaside"] = {
  key="E", 
  range=1050, 
  color=violet, 
  base={70 / 105 / 140 / 175 / 210}, 
  adBonus=.5,
  delay=2,
  speed=12,
  width=100,
  noblock=true
}



function Run()
   if StartTickActions() then
      return true
   end

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
