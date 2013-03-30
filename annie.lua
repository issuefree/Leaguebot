require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Annie")

spells["dis"] = {
   key="Q", 
   range=625, 
   color=violet, 
   base={85,125,165,205,245}, 
   cost={60,65,70,75,80},
   ap=.7
}
spells["inc"] = {
   key="W", 
   range=625, 
   color=red,    
   base={80,130,180,230,280},
   cost={70,80,90,100,110}, 
   ap=.75, 
   cone=45
}
spells["tibbers"] = {
   key="R", 
   range=600, 
   color=red, 
   base={200,325,450},
   cost={125,175,225}, 
   ap=.7,
   area=250
}

local aloneRange = 2000  -- if no enemies in this range consider yourself alone
local nearRange = 900    -- if no enemies in this range consider them not "near"

local stun = nil
function stunOn()
   if Check(stun) then
      return "ON"
   else
      return "off"
   end
end

-- last hit weakest nearby minion with Disintegrate
AddToggle("lastH", {on=true, key=112, label="Crispy Critters", auxLabel="{0}", args={"dis"}})
-- kill graoups of weak minions with Incinerate
AddToggle("flame", {on=true, key=113, label="Extra Crispy", auxLabel="{0}", args={"inc"}})
-- build up and hold on to stun
AddToggle("stoke", {on=true, key=114, label="Stoke", auxLabel="{0}", args={stunOn}})


function Run()
   TimTick()      
   
   if IsRecalling(me) then
      return 
   end

   if HotKey() then
      local target = GetWeakEnemy('MAGIC',625+50,"NEARMOUSE")
      if target then
         UseItems() 
      
         if Check(stun) then
            if CanUse("tibbers") and GetDistance(target) < 600 then
               CastSpellTarget("R", target)
            elseif CanUse("inc") and GetDistance(target) < 600 then
               CastSpellTarget("W", target)
            elseif CanUse("dis") then
               CastSpellTarget("Q", target)
            end
         else
            if CanUse("dis") then
               CastSpellTarget("Q", target)
            elseif CanUse("inc") then
               CastSpellTarget("W", target)
            end
         end
      end
   end   
   
   -- if i don't have stun and I have mana and I'm alone, stack stun with shield
   if IsOn("stoke") and 
      not Check(stun) and 
      me.mana / me.maxMana > .25 and
      not GetWeakEnemy("MAGIC", aloneRange) 
   then
      CastSpellTarget("E", me)
   end
   
   -- if we're alone blast everything.
   -- if there's a near, try to save stun
   if IsOn("lastH") then
      if not GetWeakEnemy("MAGIC", aloneRange) then
         if CanUse("dis") then
            KillWeakMinion("dis", 100)
         else
            KillWeakMinion("AA", 100)
         end      
      elseif not GetWeakEnemy("MAGIC", nearRange) then
         if (IsOn("stoke") and Check(stun)) or not CanUse("dis") then
            KillWeakMinion("AA")
         else
            KillWeakMinion("dis", 50)
         end
      end
   end   
   
   -- if we're alone blast 2 or more
   -- if we're not alone but not near blast 2 if we're stoking else 3
   if IsOn("flame") then
      if not GetWeakEnemy("MAGIC", aloneRange) then
         KillMinionsInCone(spells["inc"], 2, 200, Check(stun))
      elseif not GetWeakEnemy("MAGIC", nearRange) then
         if IsOn("stoke") and not Check(stun) then
            KillMinionsInCone(spells["inc"], 2, 200, Check(stun))
         else
            KillMinionsInCone(spells["inc"], 3, 200, Check(stun))
         end
      end
   end
end

local function onObject(object)
--   if GetDistance(object) < 100 then
--      pp(object.charName)
--   end
   if find(object.charName,"StunReady") and 
      GetDistance(object) < 50 
   then
      stun = {object.charName, object}
   end
end

local function onSpell(object, spell)
   if find(object.name, "Minion") then return end
   if object.team == me.team then return end
   if spell.target and spell.target.name == me.name and CanCastSpell("E") then
      CastSpellTarget("E", me)
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)

SetTimerCallback("Run")