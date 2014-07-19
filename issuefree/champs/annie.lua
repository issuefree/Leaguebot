require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Annie")

-- SetChampStyle("support")
SetChampStyle("caster")

spells["dis"] = {
   key="Q", 
   range=625, 
   color=violet, 
   base={80,115,150,185,220}, 
   cost={60,65,70,75,80},
   ap=.8
}
spells["inc"] = {
   key="W", 
   range=575-75, 
   color=red,    
   base={70,115,160,205,250},
   cost={70,80,90,100,110}, 
   ap=.85, 
   cone=50,  -- checked through DrawSpellCone aagainst the reticule
   delay=2,
   speed=0,
   noblock=true
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
   base={175,300,425},
   cost={125,175,225}, 
   ap=.8,
   radius=250,
   petRange=300,
   cost=100
}


function stunOn()
   if P.stun then
      return "ON"
   else
      return "off"
   end
end

-- build up and hold on to stun
AddToggle("stoke", {on=true, key=112, label="Stoke", auxLabel="{0}", args={stunOn}})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1} / {2}", args={GetAADamage, "dis", "inc"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

function Run()
   if StartTickActions() then
      return true
   end

   AutoPet(P.tibbers)

   if P.stun then
      if CheckDisrupt("dis") or
         CheckDisrupt("inc")
      then
         return true
      end
   end

   if CastAtCC("inc") then
      return true
   end

   if HotKey() and CanAct() then
      if Action() then
         return true
      end
   end
   
   -- if i don't have stun and I have mana and I'm alone, stack stun with shield
   if IsOn("stoke") and 
      Alone() and
      not P.stun and 
      CanUse("shield") and
      GetMPerc(me) > .25 
   then
      Cast("shield", me)
      PrintAction("Shield for stoke")
      return true
   end
   

   -- if we're alone blast everything.
   -- if there's a near, try to save stun
   -- if we're alone blast 2 or more
   -- if we're not alone but not near blast 2 if we're stoking else 3
   if IsOn("lasthit") then

      if VeryAlone() then
         if KillMinionsInCone("inc", 2) then
            return true
         end
      elseif Alone() then
         if IsOn("stoke") and not P.stun then
            if KillMinionsInCone("inc", 2) then
               return true
            end
         else
            if KillMinionsInCone("inc", 3) then
               return true
            end
         end
      end

      if VeryAlone() then
         if KillMinion("dis", nil, true) then
            return true
         end
      elseif Alone() then
         if IsOn("stoke") and not P.stun then
            if KillMinion("dis", nil, true) then
               return true
            end
         end    
      end

   end

   if HotKey() then
      if FollowUp() then
         return
      end
   end

   EndTickActions()
end

function Action()
-- actually I think it's simple. just hit whoever I can with disintigrate
-- and incinerate and rely on movement to get me in range for shit.

-- if I can hit 2 people with tibbers or kill with tibbers do that.

-- so scan everyone in range of tibbers. Check each target for most hits.
-- if hits >= 2 hit the best one

-- then hit best target with dis or int

-- check for finish offs with tibbers. (handle the one target left kill case)

   if CanUse("tibbers") and not P.tibbers then
      local hits, kills, score = GetBestArea(me, "tibbers", 1, 3, ENEMIES)
      if score >= 2 then
         UseItem("Deathfire Grasp", GetWeakest("tibbers", hits))
         CastXYZ("tibbers", GetAngularCenter(hits))
         PrintAction("Tibbers for AoE")
         return true
      end
   end

   if CanUse("inc") then
      -- if SkillShot("inc") then
      --    return true
      -- end
      local target = GetMarkedTarget() or GetWeakestEnemy("inc")
      if target then
         if ( IsOn("stoke") and not P.stun ) or -- hold off on incinerate if you're holding a stun and they're at the edge of range
            GetDistance(target) < 525 
         then
            if CanUse("dis") then
               UseItem("Deathfire Grasp", target)
            end
            Cast("inc", target)
            PrintAction("Incinerate", target)
            return true
         end
      end
   end

   if CanUse("dis") then
      local target = GetMarkedTarget() or GetWeakestEnemy("dis")
      if target then
         if CanUse("inc") then
            UseItem("Deathfire Grasp", target)
         end
         Cast("dis", target)
         PrintAction("Disintigrate", target)
         return true
      end
   end

   if CanUse("tibbers") and me.SpellNameR == "InfernalGuardian" then
      local hits, kills, score = GetBestArea(me, "tibbers", .1, 1, ENEMIES)

      if #kills >= 1 then
         CastXYZ("tibbers", GetAngularCenter(hits))
         PrintAction("Tibbers for execute", target)
         return true
      end
   end

   return false
end   

function FollowUp()
   return false
end


local function onObject(object)
   PersistBuff("stun", object, "StunReady")

   Persist("tibbers", object, "Tibbers", me.team)
end

local function onSpell(unit, spell)
   CheckShield("shield", unit, spell)   

   CheckPetTarget(P.tibbers, unit, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)

SetTimerCallback("Run")