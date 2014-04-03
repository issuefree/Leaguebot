require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Anivia")
pp(" - Orb people")
pp(" - Detonate orb when it's near people")
pp(" - Spike chilled people")
pp(" - Storm for aoe")
pp(" - Storm for minion clear")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

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
   ap=.5
}
spells["storm"] = {
   key="R", 
   range=625, 
   color=red, 
   base={80,120,160}, 
   ap=.25,
   radius=400
}

function CheckDisrupt()
   if not P.orb then
      if Disrupt("DeathLotus", "orb") then return true end

      if Disrupt("Grasp", "orb") then return true end

      if Disrupt("AbsoluteZero", "orb") then return true end

      if Disrupt("BulletTime", "orb") then return true end

      if Disrupt("Duress", "orb") then return true end

      if Disrupt("Idol", "orb") then return true end

      if Disrupt("Monsoon", "orb") then return true end

      if Disrupt("Meditate", "orb") then return true end

      if Disrupt("Drain", "orb") then return true end
   end

   return false
end

function Run()
   for _,t in ipairs(GetWithBuff("freeze", ENEMIES)) do
      Circle(hero, nil, blue, 3)
   end

   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return true
   end

   if P.orb then
      Circle(P.orb, spells["orb"].radius, blue)
      if CanUse("orb") then
         local inRange = GetInRange(P.orb, spells["orb"].radius, ENEMIES)
         if #inRange > 0 then
            Cast("orb", me, true)
            PrintAction("Detonate orb", inRange[1])
         end
      end
   end

   if CheckDisrupt() then
      return true
   end

   if not P.orb then
      if CastAtCC("orb") then
         return true
      end
   end

   if HotKey() then   
      UseItems()
      if Action() then
         return true
      end
   end      

   if IsOn("clearminions") and CanUse("storm") and Alone() and not P.storm then
      local hits = GetBestArea(me, "storm", 1, 0, MINIONS)
      if (GetMPerc(me) > .33 and #hits >= 4) or
         (GetMPerc(me) > .66 and #hits >= 3)
      then
         CastXYZ("storm", GetCenter(hits))
         PrintAction("Storm for clear "..#hits)
      end
   end

   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

end

function Action()
   if CanUse("spike") then
      local target = GetWeakestEnemy("spike")
      if target and WillKill("spike", target) then
         Cast("spike", target)
         PrintAction("Spike for execute", target)
         return true
      end

      local enemies = GetInRange(me, "spike", ENEMIES)
      enemies = GetWithBuff("freeze", enemies)
      local target = GetWeakest("spike", enemies)
      if target then
         Cast("spike", target)
         PrintAction("Spike chilled", target)
         return true
      end
   end

   if CanUse("orb") then
      local target = GetWeakEnemy("MAGIC", spells['orb'].range)
      if not P.orb and IsGoodFireahead("orb", target) then
         CastFireahead("orb", target)
         PrintAction("Orb", target)
         return true
      end
   end

   if CanUse("storm") and not P.storm then
      local hits = GetBestArea(me, "storm", 1, 0, ENEMIES)
      if #hits > 0 then
         CastXYZ("storm", GetCenter(hits))
         PrintAction("Storm", #hits)
      end
   end
   return false
end

function FollowUp()
   if IsOn("lasthit") and Alone() then
      if KillMinion("AA") then
         return true
      end
   end

   if IsOn("clearminions") and Alone() then
      -- hit the highest health minion
      local minions = SortByHealth(GetInRange(me, "AA", MINIONS))
      if AA(minions[#minions]) then
         PrintAction("AA clear minions")
         return true
      end
   end
   return false
end

local function onObject(object)
   Persist("orb", object, "cryo_FlashFrost_mis")
   Persist("storm", object, "cryo_storm_green_team")
   PersistOnTargets("freeze", object, "Global_Freeze", ENEMIES)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")