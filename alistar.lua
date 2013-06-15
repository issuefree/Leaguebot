require "Utils"
require "timCommon"
require "modules"
require "support"

print("\nTim's Alistar")

AddToggle("heal", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"roar"}})
AddToggle("combo", {on=true, key=113, label="Combo"})

spells["pulverize"] = {
   key="Q", 
   range=365, 
   color=red,    
   base={60,105,150,195,240}, 
   ap=.5, 
   cost={70,80,90,100,110}
}
spells["headbutt"] = {
   key="W", 
   range=650, 
   color=violet, 
   base={55,110,165,220,275}, 
   ap=.7, 
   cost={70,80,90,100,110}
} 
spells["roar"] = {
   key="E", 
   range=575, 
   color=green,  
   base={60,90,120,150,180},  
   ap=.2
}

local wantHealPercent  = .9 -- top off
local shouldHealPercent = .75 -- important
local needHealPercent  = .5 -- critical

function Run()
   TimTick()
   
   if IsRecalling(me) then
      return
   end

   local spell = spells["roar"]
   if CanUse(spell) then
      local nearAllies = GetInRange(me, spell.range+100, ALLIES)
      local healScore = 0
      for _,ally in ipairs(nearAllies) do
         local p = ally.health/ally.maxHealth
         if GetDistance(ally) < spell.range then
            if p <= needHealPercent then
               healScore = healScore + 100
               break
            elseif p <= shouldHealPercent then
               healScore = healScore + 2
            elseif p <= wantHealPercent then
               healScore = healScore + 1
            end         
         else
            if p <= needHealPercent then
               healScore = healScore - 3
               DrawCircleObject(ally,75,red)
            elseif p <= shouldHealPercent then
               healScore = healScore - 1
               DrawCircleObject(ally, 75, red)
            end
         end
      end
      if healScore > 1 then
         CastSpellTarget(spell.key, me)
      end
   end


   local target = GetWeakEnemy("MAGIC", 650, "NEARMOUSE")
   
   if target then
      DrawKnockback(target, 650)
   end
   
   if IsOn("combo") and HotKey() then
      if target and CanUse("pulverize") then
         if GetDistance(target) < 365 then
            CastSpellTarget("Q", target)
         elseif 
            CanUse("headbutt") and 
            me.mana > (GetSpellCost(spells["pulverize"]) + GetSpellCost(spells["headbutt"])) 
         then
            CastSpellTarget("W", target)
         end
      end
      UseItems()
   end
end

SetTimerCallback("Run")