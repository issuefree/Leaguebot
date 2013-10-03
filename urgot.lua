require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Urgot")
pp(" - corrosive charge enemies")
pp(" - tracks charged enemies")
pp(" - use capacitor if there's a charged enemy to hit")
pp(" - auto homing hunters")
pp(" - auto ss hunters")
pp(" - minion farming")


AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("capacitor", {on=true, key=113, label="Capacitor"})
AddToggle("tear", {on=true, key=114, label="Charge tear"})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "hunter"}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["hunter"] = {
   key="Q", 
   range=900,
   lockedRange=1200,
   color=violet, 
   base={10,40,70,100,130}, 
   ad=.85,
   type="P",
   delay=2,
   speed=15,
   width=80
}
spells["capacitor"] = {
   key="W"
}
spells["charge"] = {
   key="E", 
   range=900, 
   color=yellow, 
   base={75,130,185,240,295}, 
   bonusAd=.6,
   type="P",
   delay=2.5,
   speed=15,
   noblock=true,
   width=300
}

local chargeTime = 0

function Run()

   for i,t in ipairs(tearTimes) do
      PrintState(i+1, t)
   end

   PrintState(4, GetCD("1"))

   for _,enemy in ipairs(GetWithBuff("charge", ENEMIES)) do
      Circle(enemy, nil, green, 3)
   end

   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return true
   end

   if HotKey() and CanAct() then
      UseItems()
      if Action() then
         return true
      end
   end           

   if CanUse("hunter") and Alone() then
      if GetMPerc(me) > .66 or
         ( GetMPerc(me) > .33 and CanChargeTear())
      then
         local minion = SortByHealth(GetUnblocked(me, "hunter", GetInRange(me, "hunter", MINIONS)))[1]
         if minion and WillKill("hunter", minion) then
            -- LineBetween(me, minion, spell.width)
            CastXYZ("hunter", minion)
            return true
         end
      end
   end

   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   if IsOn("tear") and CanUse("hunter") and CanChargeTear() and VeryAlone() and GetMPerc(me) > .75 then
      local minion = SortByDistance(GetInRange(me, "hunter", MINIONS))[1]
      if minion then
         CastXYZ("hunter", minion)
      else
         CastXYZ("hunter", GetMousePos())
      end
      PrintAction("Hunter for charge")
      return true
   end

end

function Action()

   -- if I have a charged enemy just hit it. It may not be as ideal
   -- as hitting a very weak guy with a skill shot but I could miss
   -- that one and it's only 5 seconds...
   if CanUse("hunter") then
      local target = GetWeakest("hunter", GetInRange(me, spells["hunter"].lockedRange, GetWithBuff("charge", ENEMIES)))
      if target then
         if IsOn("capacitor") and CanUse("capacitor") then
            Cast("capacitor", me)
            PrintAction("Capacitor for slow")
         end
         
         CastXYZ("hunter", target)
         PrintAction("Hunter charged", target)
         return true
      end
   end

   if CanUse("charge") then
      local target = GetMarkedTarget() or GetWeakestEnemy("charge")
      if target and IsGoodFireahead("charge", target) then
         CastFireahead("charge", target)
         chargeTime = time()
         PrintAction("Drop a charge", target)
         return true
      end
   end

   if CanUse("hunter") then
      if time() - chargeTime < .5 then
         PrintAction("Waiting for charge to land "..time()-chargeTime)
      else
         if SkillShot("hunter") then
            return true
         end
      end
   end

   local target = GetWeakEnemy("PHYSICAL", spells["AA"].range)
   if AA(target) then
      PrintAction("AA", target)
      return true
   end


   return false
end

function FollowUp()
   if IsOn("lasthit") and Alone() then
      if KillWeakMinion("AA") then
         PrintAction("AA lasthit")
         return true
      end
   end

   if IsOn("clearminions") and Alone() then
      if CanUse("hunter") then
         local minion = SortByDistance(GetInRange(me, "hunter", MINIONS))[1]
         local mp = GetMPerc(me)
         if ( CanChargeTear() and mp > .33 ) or
            mp > .66
         then
            if minion then
               CastXYZ("hunter", minion)
               PrintAction("Hunter for clear")
               return
            end
         end
      end
      
      local minions = SortByHealth(GetInRange(me, "AA", MINIONS))
      if AA(minions[#minions]) then
         PrintAction("AA clear minions")
         return true
      end
   end

   if IsOn("move") then
      MoveToCursor() 
      PrintAction("Move")
      return false
   end
end

local function onObject(object)
   PersistOnTargets("charge", object, "UrgotCorrosiveDebuff", ENEMIES)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
