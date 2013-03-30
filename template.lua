require "Utils"
require "timCommon"
require "modules"
require "support"

pp("\nTim's Template")

--AddToggle("healTeam", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"green"}})

--spells["blind"] = {key="Q", range=680, color=yellow, base={80,125,170,215,260}, ap=.8}

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
