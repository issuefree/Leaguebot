require "Utils"
require "timCommon"
require "modules"
require "support"

pp("\nTim's Template")

--AddToggle("healTeam", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"green"}})

--spells["jav"] = {
--   key="Q", 
--   range=1500, 
--   color=violet, 
--   base={55,95,140,185,230}, 
--   ap=.65
--}

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
