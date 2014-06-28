require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Kennen")

-- track marks
-- 

--AddToggle("healTeam", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"green"}})

spells["shuriken"] = {
   key="Q", 
   range=1050, 
   color=violet, 
   base={75,115,155,195,235}, 
   ap=.75,
   delay=2+1,
   speed=12,
   width=80
}
spells["surge"] = {
   key="W", 
   range=800, 
   color=yellow, 
   base={65,95,125,155,185}, 
   ap=.55
}
spells["rush"] = {
   key="E", 
   base={85,125,165,205,245}, 
   ap=.6
}
spells["maelstrom"] = {
   key="R", 
   range=550, 
   color=red, 
   base={80,145,210}, 
   ap=.4
}

function Run()
   if StartTickActions() then
      return true
   end

	if HotKey() then
	end
end

local function onObject(object)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
