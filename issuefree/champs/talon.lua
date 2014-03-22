require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Talon")

--AddToggle("healTeam", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"green"}})

spells["diplomacy"] = {
   key="Q", 
   base={30 / 60 / 90 / 120 / 150}, 
   type="P",
   ad=.3
 }
spells["rake"] = {
   key="W", 
   range=600, 
   color=violet, 
   base={30 / 55 / 80 / 105 / 130}, 
   ad=.6,
   type="P"
}
spells["cutthroat"] = {
   key="E", 
   range=700, 
   color=yellow
}
spells["assault"] = {
   key="R", 
   base={120 / 170 / 220}, 
   ad=.75,
   type="P"
}

function Run()
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
