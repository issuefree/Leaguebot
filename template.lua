require "Utils"
require "timCommon"
require "modules"
require "support"

pp("\nTim's Template")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

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

   if IsRecalling(me) or me.dead == 1 then
      return
   end

	if HotKey() and CanAct() then
		Action()
	end
end

function Action()
   UseItems()
      
   local target = GetWeakEnemy("PHYSICAL", spells["AA"].range)
   if target and AA(target) then
      return
   end

   if IsOn("lasthit") and Alone() then
      if KillWeakMinion("AA") then
         return
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
      MoveToCursor() 
   end
end

local function onObject(object)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
