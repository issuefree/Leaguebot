require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Template")

--AddToggle("autoQ", {on=false, key=112, label="Auto Q"})

--spells["blind"] = {key="Q", range=680, color=yellow, base={80,125,170,215,260}, ap=.8}

function Run()
	TimTick()
	if HotKey() then
		UseAllItems()
	end
end

local function onObject(object)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")

SetTimerCallback("Run")