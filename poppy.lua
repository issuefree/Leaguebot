require "timCommon"
require "modules"

pp("\nTim's Poppy")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("autoUlt", {on=true, key=113, label="AutoUlt"})
AddToggle("jungle", {on=true, key=114, label="Jungle"})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "blow"}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["blow"] = {
   key="Q", 
   base={20,40,60,80,100}, 
   max={75,150,225,300,375},
   perMaxHealth=.08,
   ap=.6, 
   ad=1,
   onHit=true,
   cost=55
}
spells["charge"] = {
   key="E", 
   range=525, 
   color=violet, 
   base={50,75,100,125,150}, 
   ap=.4
}
spells["collision"] = {
   key="E", 
   range=300, 
   base={75,125,175,225,275}, 
   ap=.4
}
spells["immunity"] = {
   key="R", 
   range=900, 
   color=blue
}

function Run()
   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return
   end

   if HotKey() then
      if Action() then
         return true
      end
   end

   if IsOn("lasthit") and GetMPerc(me) > .5 and Alone() then
      if ModAAFarm("blow", P.blow) then
         return true
      end
   end      

   if IsOn("jungle") and GetMPerc(me) > .5 then
      if ModAAJungle("blow", P.blow) then
         return true
      end
   end

   if HotKey() then
      if FollowUp() then
         return true
      end
   end   

   return false
end

function Action()
   checkCharge()

   local target = GetMarkedTarget() or GetMeleeTarget()
   if target and ModAA("blow", target) then
      return true
   end

   return false
end

function FollowUp()
   if IsOn("lasthit") and Alone() then
      if KillMinion("AA") then
         return true
      end

      if CanUse("blow") then
         local target = SortByHealth(GetInRange(me, GetSpellRange("AA"), MINIONS))[1]        
         if target and WillKill("blow", target) and
            ( JustAttacked() or not WillKill("AA", target) )
         then
            Cast("blow", me)
            PrintAction("Blow lasthit")
            AttackTarget(target)
            return true
         end
      end
   end

   if IsOn("clearminions") and Alone() then
      if HitMinion("AA", "strong") then
         return true
      end
   end

   if IsOn("move") then
      if MeleeMove() then
         return true
      end
   end

   return false
end

function checkCharge()
   if CanUse("charge") then
      local inRange = GetInRange(me, spells["charge"].range, ENEMIES)
      for _,enemy in ipairs(inRange) do
         if WillHitWall(enemy, spells["collision"].range) == 1 then
            CastSpellTarget("E", enemy) 
            return
         end
      end
   end
end

local function onObject(object)
   PersistBuff("blow", object, "Poppy_DevastatingBlow", 150)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
