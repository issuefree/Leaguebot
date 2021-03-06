require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Anivia")
pp(" - Orb people")
pp(" - Detonate orb when it's near people")
pp(" - Spike chilled people")
pp(" - Storm for aoe")
pp(" - Storm for minion clear")

InitAAData({
   speed = 1050, windup = .4,
   particles = {"cryoBasicAttack"}
})

SetChampStyle("caster")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["orb"] = {
   key="Q", 
   range=1100, 
   color=blue, 
   base={60,90,120,150,180}, 
   ap=.5,
   delay=1.5,
   speed=8.5,
   width=80,
   radius=150,
   noblock=true,
   cost={80,90,100,110,120}
}
spells["wall"] = {
   key="W", 
   range=1000, 
   color=yellow,
   cost=70
}
spells["spike"] = {
   key="E", 
   range=650, 
   color=violet, 
   base={55,85,115,145,175}, 
   ap=.5,
   damOnTarget=function(target)
                  if HasBuff("freeze", target) then
                     return GetSpellDamage("spike")
                  end
                  return 0
               end
}
spells["storm"] = {
   key="R", 
   range=625, 
   color=red, 
   base={80,120,160}, 
   ap=.25,
   radius=400
}

function Run()
   if StartTickActions() then
      return true
   end

   if not P.orb then
      if CheckDisrupt("orb") then
         return true
      end
   end

   if P.orb and CanUse("orb") then
      Circle(P.orb, spells["orb"].radius, blue)
      if CanUse("orb") then
         local inRange = GetInRange(P.orb, spells["orb"].radius, ENEMIES)
         if #inRange > 0 then
            Cast("orb", me, true)
            PrintAction("Detonate orb", inRange[1])
         end
      end
   end

   if not P.orb then
      if CastAtCC("orb") then
         return true
      end
   end

   if HotKey() then   
      if Action() then
         return true
      end
   end      

   if IsOn("lasthit") then
      if CanUse("spike") then
         if VeryAlone() then
            if KillMinion("spike", "strong") then
               return true
            end
         end
      end

      if P.orb and #GetInRange(me, "orb", ENEMIES) == 0 then
         if #GetKills("orb", GetInRange(P.orb, spells["orb"].radius, MINIONS)) >= 2 then
            Cast("orb", me, true)
            PrintAction("Detonate orb for LH")
            return true
         end
      end

   end   

   if IsOn("clear") and CanUse("storm") and Alone() and not P.storm then
      local hits = GetBestArea(me, "storm", 1, 0, MINIONS)
      if (GetMPerc(me) > .33 and #hits >= 4) or
         (GetMPerc(me) > .66 and #hits >= 3)
      then
         CastXYZ("storm", GetCastPoint(hits, "storm"))
         PrintAction("Storm for clear "..#hits)
      end
   end

   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()
   if CanUse("spike") then
      local kills = GetKills("spike", GetInRange(me, "spike", ENEMIES))
      if kills[1] then
         Cast("spike", kills[1])
         PrintAction("Spike for execute", kills[1])
         return true
      end

      local target = GetWeakest("spike", GetWithBuff("freeze", GetInRange(me, "spike", ENEMIES)))
      if target then
         UseItem("Deathfire Grasp", target)
         Cast("spike", target)
         PrintAction("Spike chilled", target)
         return true
      end
   end

   if not P.orb then
      if SkillShot("orb") then
         return true
      end
   end

   if CanUse("storm") and not P.storm then
      local hits = GetBestArea(me, "storm", 1, 0, ENEMIES)
      if #hits > 0 then
         CastXYZ("storm", GetCastPoint(hits, "storm"))
         PrintAction("Storm", #hits)
         return true
      end
   end
   return false
end

function FollowUp()
   return false
end

local function onObject(object)
   Persist("orb", object, "cryo_FlashFrost_mis")
   Persist("storm", object, "cryo_storm_green_team")
   PersistOnTargets("freeze", object, "Global_Freeze", ENEMIES)
end

local function onSpell(unit, spell)
   if ICast("orb", unit, spell) then
      PersistTemp("orb", .5)
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
