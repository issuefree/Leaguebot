require "Utils"
require "timCommon"
require "modules"
require "support"

pp("\nTim's Annie")

spells["dis"] = {
   key="Q", 
   range=625, 
   color=violet, 
   base={85,125,165,205,245}, 
   cost={60,65,70,75,80},
   ap=.7,
   cost={85,125,165,205,245}
}
spells["inc"] = {
   key="W", 
   range=600, 
   color=red,    
   base={80,130,180,230,280},
   cost={70,80,90,100,110}, 
   ap=.75, 
   cone=45,
   cost={80,130,180,230,280}
}
spells["shield"] = {
   key="E",
   range=50,
   cost=20
}
spells["tibbers"] = {
   key="R", 
   range=600, 
   color=red, 
   base={200,325,450},
   cost={125,175,225}, 
   ap=.7,
   radius=250,
   cost=100
}


local stun = nil
function stunOn()
   if Check(stun) then
      return "ON"
   else
      return "off"
   end
end

AddToggle("", {on=true, key=112, label=""})
-- build up and hold on to stun
AddToggle("stoke", {on=true, key=113, label="Stoke", auxLabel="{0}", args={stunOn}})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1} / {2}", args={GetAADamage, "dis", "inc"}})

local tibbersObj = nil
local tibbers = nil
local tibbersHasTarget = false
local tibbersRange = 300

function Run()
   if IsRecalling(me) or me.dead == 1 then
      return
   end

   autoTibbers()   

   if HotKey() and CanAct() then
      if Action() then
         return
      end
   end
   
   -- if i don't have stun and I have mana and I'm alone, stack stun with shield
   if IsOn("stoke") and Alone() and
      not Check(stun) and 
      CanUse("shield") and
      me.mana / me.maxMana > .25 
   then
      Cast("shield", me)
      PrintAction("Shield for stoke")
      return
   end
   
   -- if we're alone blast everything.
   -- if there's a near, try to save stun

   if IsOn("lasthit") then
      if VeryAlone() then
         if KillWeakMinion("dis") then
            PrintAction("Disintigrate for lasthit")
            return
         end
      elseif Alone() then
         if IsOn("stoke") and not Check(stun) then
            if KillWeakMinion("dis") then
               PrintAction("Distintigrate for lasthit")
               return
            end
         end         
      end
   end   

   -- if we're alone blast 2 or more
   -- if we're not alone but not near blast 2 if we're stoking else 3
   if IsOn("lasthit") then
      if VeryAlone() then
         if KillMinionsInCone(spells["inc"], 2, 0, false) then
            PrintAction("Incinerate 2")
            return
         end
      elseif Alone() then
         if IsOn("stoke") and not Check(stun) then
            if KillMinionsInCone(spells["inc"], 2, 0, Check(stun)) then
               PrintAction("Incinerate 2")
               return
            end
         else
            if KillMinionsInCone(spells["inc"], 3, 0, false) then
               PrintAction("Incinerate 3")
               return
            end
         end
      end
   end

   if HotKey() and CanAct() then
      if FollowUp() then
         return
      end
   end
end

function autoTibbers()
   -- SpellNameR when not tibbers is "InfernalGuardian"
   -- SpellNameR when tibbers is "infernalguardianguide"
   if Check(tibbersObj) then
      tibbers = GetObj(tibbersObj)
      Circle(tibbers, tibbersRange, red)

      tibbersHasTarget = false
      -- find the closest target to tibbers
      local target = SortByDistance(GetInRange(tibbers, 1000, ENEMIES))[1]
      if target then
         tibbersHasTarget = true
         tibbersAttack(target)
      end      
   else
      tibbers = nil
   end
end

function tibbersAttack(target)
   if GetDistance(tibbers, target) > tibbersRange then
      CastSpellTarget("R", target)
      PrintAction("Tibbers CHARGE", target)
   else
      PrintAction("Tibbers ATTACK", target)      
   end
end

function Action()
   UseItems() 

-- actually I think it's simple. just hit whoever I can with disintigrate
-- and incinerate and rely on movement to get me in range for shit.

-- if I can hit 2 people with tibbers or kill with tibbers do that.

-- so scan everyone in range of tibbers. Check each target for most hits.
-- if hits >= 2 hit the best one

-- then hit best target with dis or int

-- check for finish offs with tibbers. (handle the one target left kill case)

   if CanUse("tibbers") and me.SpellNameR == "InfernalGuardian" then
      local hits, kills, score = GetBestArea(me, "tibbers", 1, 3, ENEMIES)
      if score >= 3 then
         CastXYZ("tibbers", GetCenter(hits))
         PrintAction("Tibbers for AoE")
         return true
      end
   end

   if CanUse("inc") then
      local target = GetMarkedTarget() or GetWeakestEnemy("inc")
      if target then
         Cast("inc", target)
         PrintAction("Incinerate", target)
         return true
      end
   end

   if CanUse("dis") then
      local target = GetMarkedTarget() or GetWeakestEnemy("dis")
      if target then
         Cast("dis", target)
         PrintAction("Disintigrate", target)
         return true
      end
   end

   if CanUse("tibbers") then
      local target = GetWeakestEnemy("tibbers")
      if target and target.health < GetSpellDamage("tibbers", target) then
         Cast("tibbers", target)
         PrintAction("Tibbers for execute", target)
         return true
      end
   end

   return false
end   

function FollowUp()
   if IsOn("lasthit") and Alone() then
      if KillWeakMinion("AA") then
         PrintAction("AA for lasthit")
         return true
      end
   end

   return false
end


local function onObject(object)
   if find(object.charName,"StunReady") and 
      GetDistance(object) < 50 
   then
      stun = StateObj(object)
   end

   if object.charName == "Tibbers" and object.team == me.team then
      tibbersObj = StateObj(object)
   end

end

local function onSpell(unit, spell)
   CheckShield("shield", unit, spell)   

   if tibbers and 
      unit.name == me.name and 
      spell.target and
      spell.target.team ~= me.team and
      not tibbersHasTarget
   then
      tibbersAttack(spell.target)
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)

SetTimerCallback("Run")