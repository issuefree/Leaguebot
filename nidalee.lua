require "Utils"
require "timCommon"
require "modules"
require "support"

pp("\nTim's Nidalee")

AddToggle("healTeam", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"surge"}})

spells["jav"] = {
   key="Q", 
   range=1500, 
   color=violet, 
   base={55,95,140,185,230}, 
   ap=.65,
   type="M",
   width=80,
   delay=2,
   speed=13
}

spells["surge"] = {
   key="E", 
   range=600, 
   color=green, 
   base={50,85,120,155,190}, 
   ap=.7
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
