require "Utils"
require "timCommon"
require "modules"

pp("Tim's Ryze")
pp(" - prison > overload > flux")
pp(" - lasthit w/overload depending on mana")
pp(" - clear w/overload/flux depending on mana")

local attackObject = "ManaLeach_mis"

spells["overload"] = {key="Q", range=600, color=violet, base={60,85,110,135,160}, ap=.4, mana=.065}
spells["prison"]   = {key="W", range=600, color=red,    base={60,95,130,165,200}, ap=.6, mana=.045}
spells["flux"]     = {key="E", range=600, color=violet, base={50,70,90,110,130},  ap=.35, mana=.01}

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "overload"}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

local aloneRange = 1750  -- if no enemies in this range consider yourself alone
local nearRange = 1000    -- if no enemies in this range consider them not "near"

local lastAttack = GetClock()

function Run()
   TimTick()

   if IsRecalling(me) then
      return
   end
   
	if HotKey() and CanAct() then
      Action()
   end
end

function Action()
   UseItems()


   local target = GetWeakEnemy('MAGIC', spells["prison"].range)
   if target and CanUse("prison") then
      Cast("prison", target)
      return
   end

   target = GetWeakEnemy("MAGIC", spells["overload"].range)
   if target and CanUse("overload") then
      Cast("overload", target)
      return
   end

   target = GetWeakEnemy("MAGIC", spells["flux"].range)
   if target and CanUse("flux") then
      Cast("flux", target)
      return
   end
   
   target = GetWeakEnemy("PHYSICAL", spells["AA"].range)
   if target and AA(target) then
      return
   end

   if IsOn("lasthit") and Alone() then
      local mp = me.mana/me.maxMana
      if ( CanChargeTear() and mp > .33 ) or
         mp > .66
      then
         if KillWeakMinion("overload") then
            return
         end
      end

      if KillWeakMinion("AA") then
         return
      end
   end

   if IsOn("clearminions") and Alone() then
      local minions = GetInRange(me, "overload", MINIONS)
      minions = FilterList(minions, function(item) return item.team ~= me.team end)
      SortByHealth(minions)

      local minion = minions[#minions]

      local mp = me.mana/me.maxMana
      if ( CanChargeTear() and mp > .5 ) or
         mp > .75
      then
         if #GetInRange(minion, 200, minions) > 0 and CanUse("flux") then
            Cast("flux", minion)
            return
         end
         if minion and CanUse("overload") then
            Cast("overload", minion)
            return
         end
      end

      local minions = GetInRange(me, "AA", MINIONS)
      SortByHealth(minions)
      local minion = minions[#minions]      
      -- hit the highest health minion
      if minion and AA(minion) then
         return
      end
   end

   if IsOn("move") then
      MoveToCursor() 
   end
end

local function onObject(object)
   if find(object.charName, attackObject) then
      lastAttack = GetClock()
   end
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")