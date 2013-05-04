require "Utils"
require "timCommon"
require "modules"
require "support"

pp("\nTim's Template")

--AddToggle("healTeam", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"green"}})

--spells["binding"] = {
--   key="Q", 
--   range=1175, 
--   color=violet, 
--   base={60,110,160,210,260}, 
--   ap=.7,
--   delay=2,
--   speed=12,
--   width=80
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
