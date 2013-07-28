require "Utils"
require "timCommon"
require "modules"
require "support"

pp("\nTim's Kayle")

--AddToggle("healTeam", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"green"}})

spells["reckoning"] = {
  key="Q", 
  range=650, 
  color=violet, 
  base={60,110,160,210,260}, 
  ap=1,
  bonusAd=1
}
spells["blessing"] = {
  key="W", 
  range=900, 
  color=green, 
  base={60,105,150,195,240}, 
  ap=.35
}
spells["fury"] = {
  key="E", 
  range=525, 
  color=red
}
spells["intervention"] = {
  key="R", 
  range=900, 
  color=yellow
}

-- reckoning is pretty spammable, so spam it.
-- if people are in range and fury is off, turn it on
-- intervention is hard to use safely, might try something like
--   if someone is under 25% and becomes the target of an enemy ability intervene

local fury = nil

function Run()
   TimTick()

   -- if Check(fury) then
   --    PrintState(0, "FURY")
   -- else
   --    PrintState(0, "no")
   -- end

   -- determine who I should attack
   if me.ap > me.addDamage then
      type = "MAGIC"
   else
      type = "PHYSICAL"
   end

   if HotKey() then      
      UseItems()

      local spell = spells["reckoning"]
      if CanUse(spell) then
         local target = GetWeakEnemy("MAGIC", spell.range)
         if target then
            CastSpellTarget(spell.key, target)
            return
         end
      end

      local spell = spells["fury"]
      local target = GetWeakEnemy(type, spell.range)
      if target then
         if Check(fury) then
            --AttackTarget(target)
         elseif CanUse(spell) then
            CastSpellTarget(spell.key, me)
         end
      end

   end
end

local function onObject(object)
   if find(object.charName,"RighteousFuryHalo") and 
      GetDistance(object) < 50 
   then
      fury = {object.charName, object}
   end
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
