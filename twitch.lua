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
spells["expColor1"] = {
   key="E", 
   range=1198, 
   color=red
}
spells["expColor2"] = {
   key="E", 
   range=1202, 
   color=red
}
spells["expunge"] = {
   key="E", 
   range=1200, 
   color=yellow, 
   base={40,50,60,70,80}, 
   ap=.2,
   adBonus=.25
}

local poisons = {}

function Run()
	TimTick()

   drawPoisons()

	if HotKey() then
		UseItems()
	end
end

function drawPoisons()
   Clean(poisons, "charName", "twitch_poison_counter_0")
   for _,p in ipairs(poisons) do
      local count = 0+string.match(p.charName, "r_(%d*)")
      for i=1,count do
         if i%2 == 0 then
            DrawCircleObject(p, 85+(i*2), green)
         else
            DrawCircleObject(p, 85+(i*2), yellow)
         end
      end
   end
end



local function onObject(object)
   if find(object.charName, "twitch_poison_counter_0") then
      table.insert(poisons, object)
   end 
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
