require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Twitch")

--AddToggle("healTeam", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"green"}})

spells["cask"] = {
   key="W", 
   range=950, 
   color=yellow, 
   delay=2,
   speed=14,
   area=300
}
spells["expColor2"] = {
   key="E", 
   range=1198, 
   color=yellow
}
spells["caskColor2"] = {
   key="W", 
   range=949, 
   color=yellow
}
spells["expunge"] = {
   key="E", 
   range=1200, 
   color=red, 
   base={40,50,60,70,80}, 
   ap=.2,
   adBonus=.25
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
