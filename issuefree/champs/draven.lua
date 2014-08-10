require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Draven")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["axe"] = {
  key="Q",
  base=0,
  ad={.45,.55,.65,.75,.85},
  type="P",
  cost="45"
}
spells["rush"] = {
  key="W",
  cost=40
}
spells["standaside"] = {
  key="E", 
  range=1050, 
  color=violet, 
  base={70,105,140,175,210}, 
  adBonus=.5,
  delay=2, --?
  speed=12, --?
  width=125,
  noblock=true,
  cost=70
}
spells["death"] = {
   key="R",
   base={175,275,375},
   adBonus=1.1,
   type="P",
   cost=120
}



function Run()
   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen
   if CheckDisrupt("standaside") then
      return true
   end

   -- high priority hotkey actions, e.g. killing enemies
   if HotKey() and CanAct() then
      if Action() then
         return true
      end
   end
   -- auto stuff that should happen if you didn't do something more important

   
   -- low priority hotkey actions, e.g. killing minions, moving
   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end

   return false
end
function FollowUp()
   return false
end

local function onObject(object)
   Persist("axe", object, "axe object") -- TODO
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
