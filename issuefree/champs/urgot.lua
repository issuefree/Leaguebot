require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Urgot")
pp(" - corrosive charge enemies")
pp(" - tracks charged enemies")
pp(" - use capacitor if there's a charged enemy to hit")
pp(" - auto homing hunters")
pp(" - auto ss hunters")
pp(" - minion farming")

InitAAData({
   projSpeed = 1.3, windup=.2,
   particles = {"UrgotBasicAttack_mis"}
})

SetChampStyle("marksman")

AddToggle("capacitor", {on=true, key=112, label="Capacitor"})
AddToggle("tear", {on=true, key=113, label="Charge tear"})
AddToggle("harrass", {on=true, key=114, label="Harass"})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "hunter"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["hunter"] = {
   key="Q", 
   range=1000-50,
   lockedRange=1200,
   color=violet, 
   base={10,40,70,100,130}, 
   ad=.85,
   type="P",
   delay=1.5,
   speed=15.5,
   width=85,
   cost=40
}
spells["capacitor"] = {
   key="W",
   range=25,
   cost={55,60,65,70,75}
}
spells["charge"] = {
   key="E", 
   range=900, 
   color=yellow, 
   base={75,130,185,240,295}, 
   adBonus=.6,
   type="P",
   delay=2.7,
   speed=15,
   noblock=true,
   radius=300,
   cost={50,55,60,65,70}
}
spells["reverser"] = {
   key="R",
   range={550,700,850},
   cost=120
}

function Run()
   for _,enemy in ipairs(GetWithBuff("charge", ENEMIES)) do
      Circle(enemy, nil, green, 3)
   end

   if StartTickActions() then
      return true
   end

   if IsOn("tear") then
      UseItem("Muramana")
   end
   
   if CastAtCC("charge") then
      return true
   end

   if HotKey() then
      if Action() then
         return true
      end
   end           

   if IsOn("harrass") then
      if SkillShot("hunter") then
         return true
      end
   end

   if IsOn("lasthit") and CanUse("hunter") and Alone() then
      if KillMinion("hunter") then
         return true
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

   EndTickActions()

end

function Action()
   -- TestSkillShot("hunter")
   -- TestSkillShot("charge", "UrgotPlasmaGrenade_mis")
   
   -- if I have a charged enemy just hit it. It may not be as ideal
   -- as hitting a very weak guy with a skill shot but I could miss
   -- that one and it's only 5 seconds...
   if CanUse("hunter") then
      local target = GetWeakest("hunter", GetInRange(me, spells["hunter"].lockedRange, GetWithBuff("charge", ENEMIES)))
      if target then
         if IsOn("capacitor") and CanUse("capacitor") then
            Cast("capacitor", me)
            PrintAction("Capacitor for slow")
            return true
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
         PrintAction("Drop a charge", target)
         return true
      end
   end

   if CanUse("hunter") then
      if not chargeThrown then
         if SkillShot("hunter") then
            return true
         end
      end
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end

   return false
end

function FollowUp()
   if IsOn("clear") and Alone() then
      if CanUse("hunter") then
         local minion = SortByDistance(GetInRange(me, "hunter", MINIONS))[1]
         if GetThreshMP(thing, .1) < 1 then
            if minion then
               CastXYZ("hunter", minion)
               PrintAction("Hunter for clear")
               return true
            end
         end
      end      
   end

   return false
end

local function onObject(object)
   PersistOnTargets("charge", object, "UrgotCorrosiveDebuff", ENEMIES)
   if find(object.charName, "UrgotPlasmaGrenade") then
      DoIn(function() chargeThrown = false end, .1)
   end
end

local function onSpell(unit, spell)
   if GetHPerc(me) < .75 then
      CheckShield("capacitor", unit, spell)
   end
   if ICast(unit, spell, "charge") then
      chargeThrown = true
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
