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
AddToggle("", {on=true, key=114, label=""})
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
   delay=2,
   speed=20,
   width=300
}

local charges = {}
local chargedEnemies = {}

function Run()
   updateCharges()

   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return
   end

   if HotKey() and CanAct() then
      if Action() then
         return true
      end
   end           
   
end

function Action()
   UseItems()

   -- if I have a charged enemy just hit it. It may not be as ideal
   -- as hitting a very weak guy with a skill shot but I could miss
   -- that one and it's only 5 seconds...
   local target = GetWeakest("hunter", GetInRange(me, spells["hunter"].lockedRange, chargedEnemies))
   if target then
      if IsOn("capacitor") and CanUse("capacitor") then
         Cast("capacitor", me)
         PrintAction("Capacitor for slow")
         return true
      end
      if CanUse("hunter") then
         CastSpellXYZ(spells["hunter"].key, target.x, target.y, target.z)
         return true
      end
   end

   if CanUse("charge") then
      local target = GetWeakEnemy("MAGIC", spells["charge"].range)
      if target then
         CastSpellFireahead("charge", target)
         PrintAction("Drop a charge", target)
         return true
      end
   end

   local target = GetWeakEnemy("PHYSICAL", spells["AA"].range)
   if AA(target) then
      PrintAction("AA", target)
      return true
   end

   if SkillShot("hunter") then
      PrintAction("Hunter SS")
      return true
   end

   if IsOn("lasthit") and Alone() then
      if lastHit() then
         return true
      end
   end

   if IsOn("clearminions") and Alone() then
      local minion = SortByDistance(GetInRange(me, "hunter", MINIONS))[1]
      local mp = me.mana/me.maxMana
      if ( CanChargeTear() and mp > .33 ) or
         mp > .66
      then
         if minion and CanUse("hunter") then
            CastXYZ("hunter", minion)
            return
         end
      end
      
      local minions = SortByHealth(GetInRange(me, "AA", MINIONS))
      local minion = minions[#minions]
      -- hit the highest health minion
      if AA(minion) then
         return true
      end
   end

   if IsOn("move") then
      MoveToCursor()
      return false
   end
   return false
end

function lastHit()
   if KillWeakMinion("AA") then
      return true
   end
   local spell = spells["hunter"]
   if CanUse(spell) then
      local minion = SortByHealth(GetUnblocked(me, spell, GetInRange(me, spell, MINIONS)))[1]
      if minion and GetSpellDamage(spell, minion) > minion.health then
         -- LineBetween(me, minion, spell.width)
         CastXYZ("hunter", minion)
         return true
      end
   end
   return false
end

function updateCharges()
   chargedEnemies = {}

   Clean(charges, "charName", "UrgotCorrosiveDebuff")
   for _,charge in ipairs(charges) do
      Circle(charge, 85, green)

      for _,enemy in ipairs(ENEMIES) do
         if GetDistance(charge, enemy) < 50 then
            table.insert(chargedEnemies, enemy)
            break
         end
      end      
   end
end

local function onObject(object)
   if find(object.charName, "UrgotCorrosiveDebuff") then
      for _,enemy in ipairs(ENEMIES) do
         if GetDistance(object, enemy) < 50 then
            table.insert(charges, object)
            break
         end
      end
   end 
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
