require "Utils"
require "timCommon"
require "modules"
require "support"

pp("\nTim's Alistar")
pp(" - Heal nearby allies")
pp(" - Knock shit up, do the Ali dance.")

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

local wantHealPercent  = .8 -- top off
local shouldHealPercent = .66 -- important
local needHealPercent  = .5 -- critical

function Run()
   TimTick()
   
   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return
   end

   UseAutoItems()


   if CanUse("headbutt") then
      local target = GetWeakestEnemy("headbutt")   
      if target then
         DrawKnockback(target, 650)
      end
   end

   if HotKey() then
      if Action() then
         return true
      end
   end

   PrintAction()
end

function Action()
   UseItems()

   -- knockup anything in range
   if CanUse("pulverize") then
      local target = GetWeakestEnemy("pulverize")
      if Cast("pulverize", target) then
         PrintAction("Pulverize", target)
         return true
      end
   end
   
   -- headbutt weakshit near mouse (pulverize will followup)
   if IsOn("combo") and 
      CanUse("pulverize") and 
      CanUse("headbutt") and
      me.mana > GetSpellCost("pulverize") + GetSpellCost("headbutt")
   then
      -- I want the nearmouse
      local target = GetWeakEnemy("MAGIC", spells["headbutt"].range, "NEARMOUSE")
      if target then
         Cast("headbutt", target)
         PrintAction("Headbutt", target)
         return true
      end
   end
end

function heal()
   local spell = spells["roar"]
   if CanUse(spell) then
      local nearAllies = GetInRange(me, spell.range+150, ALLIES)
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
               DrawBB(ally, red)
            elseif p <= shouldHealPercent then
               healScore = healScore - 1
               DrawBB(ally, red)
            end
         end
      end
      if healScore > 1 then
         CastSpellTarget(spell.key, me)
         PrintAction("Heal. score: "..healScore)
         return true
      end
   end

   return false
end

SetTimerCallback("Run")