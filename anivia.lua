require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Anivia")

--AddToggle("healTeam", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"green"}})

spells["orb"] = {
   key="Q", 
   range=1100, 
   color=violet, 
   base={60,90,120,150,180}, 
   ap=.5,
   delay=2,
   speed=8,
   width=80,
   area=75
}
spells["wall"] = {
   key="W", 
   range=1000, 
   color=blue
}
spells["spike"] = {
   key="E", 
   range=650, 
   color=violet, 
   base={55,85,115,145,175}, 
   ap=.5
}
spells["storm"] = {
   key="R", 
   range=625, 
   color=yellow, 
   base={80,120,160}, 
   ap=.25
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
