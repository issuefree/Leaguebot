require "timCommon"
require "modules"

pp("\nTim's Poppy")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("autoUlt", {on=true, key=113, label="AutoUlt"})
AddToggle("jungle", {on=true, key=114, label="Jungle"})
AddToggle("kb", {on=true, key=115, label="Auto KB"})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "blow"}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["blow"] = {
   key="Q", 
   base={20,40,60,80,100}, 
   max={75,150,225,300,375},
   percMaxHealth=.08,
   ap=.6, 
   ad=1,
   onHit=true,
   type="M",
   cost=55
}
spells["paragon"] = {
   key="W"
}
spells["charge"] = {
   key="E", 
   range=525, 
   color=violet, 
   base={50,75,100,125,150}, 
   ap=.4,
   type="M",
   knockback=400
}
spells["collision"] = {
   key="E", 
   range=300, 
   base={75,125,175,225,275}, 
   ap=.4,
   type="M"
}
spells["immunity"] = {
   key="R", 
   range=900, 
   color=blue
}

function CheckDisrupt()
   if Disrupt("DeathLotus", "charge") then return true end

   if Disrupt("Grasp", "charge") then return true end

   if Disrupt("AbsoluteZero", "charge") then return true end

   if Disrupt("BulletTime", "charge") then return true end

   if Disrupt("Duress", "charge") then return true end

   if Disrupt("Idol", "charge") then return true end

   if Disrupt("Monsoon", "charge") then return true end

   if Disrupt("Drain", "charge") then return true end

   return false
end

function Run()
   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return
   end

   if CanUse("charge") then
      local target = GetWeakestEnemy("charge")
      if target then
         DrawKnockback(target, "charge")
      end
   end

   if HotKey() then
      UseItems()
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

   if CheckDisrupt() then
      return true
   end

   if HotKey() then
      if FollowUp() then
         return true
      end
   end   

   return false
end

function Action()
   local enemy = checkCharge()
   if enemy then
      Cast("charge", enemy)
      PrintAction("Charge for slam", enemy)
      if CanUse("blow") then
         Cast("blow", me)
         PrintAction("  w/blow")
      end
      return true
   end

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
   end

   if IsOn("clearminions") and Alone() then
      if HitMinion("AA", "strong") then
         return true
      end
   end

   return false
end

function checkCharge()
   if IsOn("kb") and CanUse("charge") then
      local enemies = SortByHealth(GetInRange(me, "charge", ENEMIES))
      for _,enemy in ipairs(enemies) do
         local kb = GetKnockback("charge", me, enemy)
         if WillCollide(enemy, kb) then
            return enemy
         end
      end
   end
   return nil
end

local function onObject(object)
   PersistBuff("blow", object, "Poppy_DevastatingBlow", 150)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
