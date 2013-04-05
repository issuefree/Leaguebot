require "Utils"
require "timCommon"
require "modules"
require "support"

pp("\nTim's Sona")
AddToggle("lastHit", {on=false, key=112, label="Last Hit", auxLabel="{0}", args={"blue"}})
AddToggle("healTeam", {on=true, key=113, label="Heal Team", auxLabel="{0}", args={"green"}})
AddToggle("fastWalk", {on=true, key=114, label="Fast Walk"})

spells["blue"] = {
   key="Q", 
   range=825, 
   color=blue, 
   base={50,100,150,200,250}, 
   ap=.7
}
spells["green"] = {
   key="W", 
   range=1000, 
   color=green, 
   base={40,60,80,100,120}, 
   ap=.25
}
spells["violet"] = {
   key="E", 
   range=999, 
   color=violet 
}
spells["yellow"] = {
   key="R", 
   range=1001, 
   color=yellow, 
   base={150,250,350}, 
   ap=.8
}

pcBlue = nil
pcGreen = nil
pcViolet = nil

function Run()
   TimTick()
   

   if IsRecalling(me) then
      return
   end
   
   if HotKey() then
      UseItems()
   end
     
   if IsOn("healTeam") and CanUse("green") then
      local spell = spells["green"]
      local closeAllies = GetInRange(me, spell.range, ALLIES)
      local count = 0
      for _,hero in ipairs(closeAllies) do
         if not IsRecalling(hero) then
            if hero.health + GetSpellDamage(spell) < hero.maxHealth*.66 then
               CastSpellTarget(spell.key, me)
               break
            end            
            if hero.health + GetSpellDamage(spell) < hero.maxHealth*.9 then
               count = count + 1
               if count >= 2 then
                  CastSpellTarget(spell.key, me)
                  break
               end
            end
         end
      end
   end
   
   if IsOn("lastHit") and not GetWeakEnemy("MAGIC", 750) then
      local spell = spells["blue"]
      local minionRays = 2 -- - #GetInRange(me, spell.range, ENEMIES)
      local targets = GetInRange(me, spell.range, MINIONS)
      SortByDistance(targets)
      for _,minion in ipairs(targets) do
         if minionRays <= 0 then
            break
         end
         if minion.health < GetSpellDamage(spell, minion) then
            CastSpellTarget("Q", minion)
            break
         end
         minionRays = minionRays - 1
      end
   end
   
   if IsOn("fastWalk") and CanCastSpell("E") and not GetWeakEnemy("MAGIC", 1500) then
      if GetDistance(HOME) > 1000 and me.mana/me.maxMana > .9 then
         CastSpellTarget("E", me)
      elseif ( GetInventorySlot(ITEMS["Tear of the Goddess"].id) or
               GetInventorySlot(ITEMS["Archangel's Staff"].id) or
               GetInventorySlot(ITEMS["Manamune"].id) ) and 
         not Check(tear) and
         me.mana/me.maxMana > .75
      then
         CastSpellTarget("E", me)
      end
   end
   
end


local function onObject(object)
   if find(object.charName, "SonaPowerChordReady") then
      if find(object.charName, "blue") then
         pcBlue = {object.charName, object}
      elseif find(object.charName, "green") then
         pcGreen = {object.charName, object}
      elseif find(object.charName, "violet") then
         pcViolet = {object.charName, object}
      end
   end
   
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")