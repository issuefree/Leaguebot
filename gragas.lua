require "Utils"
require "timCommon"
require "modules"
require "support"

pp("\nTim's Template")

--AddToggle("healTeam", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"green"}})

spells["barrel"] = {
  key="Q", 
  range=1100, 
  color=violet, 
  base={85,135,185,235,285}, 
  ap=.9,
  delay=2,
  speed=12,
  area=375
}
spells["rage"] = {
  key="W"
}
spells["slam"] = {
  key="E", 
  range=650,
  color=yellow, 
  base={80,120,160,200,240}, 
  ap=.5,
  ad=.66,
  delay=2,
  speed=9,
  area=150
}
spells["cask"] = {
  key="R", 
  range=1050,
  color=red, 
  base={200,325,450}, 
  ap=1,
  delay=2,
  speed=9,
  area=400
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
