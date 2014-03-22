require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Twitch")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
-- AddToggle("pp", {on=true, key=113, label="Piltover", auxLabel="{0}", args={"pp"}})
-- AddToggle("trap", {on=true, key=114, label="Trap"})
-- AddToggle("execute", {on=true, key=115, label="AutoExecute", auxLabel="{0}", args={"ace"}})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["cask"] = {
   key="W", 
   range=950, 
   color=yellow, 
   delay=2,
   speed=14,
   noblock=true,
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
   drawPoisons()

	if HotKey() and CanAct() then
		Action()
	end
end

function drawPoisons()
   Clean(poisons, "charName", "twitch_poison_counter_0")
   for _,p in ipairs(poisons) do
      local count = 0+string.match(p.charName, "r_(%d*)")
      for i=1,count do
         if i%2 == 0 then
            Circle(p, 85+(i*2), green)
         else
            Circle(p, 85+(i*2), yellow)
         end
      end
   end
end

function Action()
   UseItems()
      
   local target = GetWeakEnemy("PHYSICAL", spells["AA"].range)
   if target then
      if AA(target) then
         return
      end
   end

   if IsOn("lasthit") and Alone() then
      if KillMinion("AA") then
         return true
      end
   end

   if IsOn("clearminions") and Alone() then
      -- hit the highest health minion
      local minions = GetInRange(me, "AA", MINIONS)
      SortByHealth(minions)
      local minion = minions[#minions]
      if minion and AA(minion) then
         return
      end
   end

   if IsOn("move") then
      if RangedMove() then
         return true
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
