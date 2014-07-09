require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Alistar")
pp(" - Heal nearby allies")
pp(" - Knock shit up, do the Ali dance.")

AddToggle("heal", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"roar"}})
AddToggle("combo", {on=true, key=113, label="Combo"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

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
   ap=.2,
   cost={40,50,60,70,80}
}

local wantHealPercent  = .8 -- top off
local shouldHealPercent = .66 -- important
local needHealPercent  = .5 -- critical

function Run()
   if StartTickActions() then
      return true
   end

   if CheckDisrupt("pulverize") or
      CheckDisrupt("headbutt")
   then
      return true
   end

   if heal() then
      return true
   end

   if HotKey() then
      if Action() then
         return true
      end
   end

   EndTickActions()
end

function Action()
   -- knockup anything in range
   if CastBest("pulverize") then
      return true
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
         UseItem("Deathfire Grasp", target)
         Cast("headbutt", target)
         PrintAction("Headbutt", target)
         return true
      end
   end

   local target = GetMarkedTarget() or GetMeleeTarget()
   if AutoAA(target) then
      return true
   end
   return false
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
               Circle(ally, nil, yellow)
            elseif p <= shouldHealPercent then
               healScore = healScore - 1
               Circle(ally, nil, red)
            end
         end
      end
      if healScore > 1 then
         Cast("roar", me)
         PrintAction("Heal", healScore)
         return true
      end
   end

   return false
end

local function onCreate(object)
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)

SetTimerCallback("Run")