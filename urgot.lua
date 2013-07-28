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
   TimTick()   

   updateCharges()

   if IsRecalling(me) then
      return
   end

   if HotKey() and CanAct() then
      Action()
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
         CastSpellTarget(spells["capacitor"].key, me)
         return
      end
      if CanUse("hunter") then
         CastSpellXYZ(spells["hunter"].key, target.x, target.y, target.z)
         return
      end
   end

   if CanUse("charge") then
      local target = GetWeakEnemy("MAGIC", spells["charge"].range)
      if target then
         CastSpellFireahead("charge", target)
         return
      end
   end

   local target = GetWeakEnemy("PHYSICAL", spells["AA"].range)
   if target then
      if AA(target) then
         return
      end
   end

   if SkillShot("hunter") then
      return
   end

   if IsOn("lasthit") and Alone() then
      if lastHit() then
         return
      end
   end

   if IsOn("clearminions") and Alone() then
      local minions = GetInRange(me, "hunter", MINIONS)
      SortByDistance(minions)
      local minion = minions[1]

      local mp = me.mana/me.maxMana
      if ( CanChargeTear() and mp > .5 ) or
         mp > .75
      then
         if minion and CanUse("hunter") then
            CastXYZ("hunter", minion)
            return
         end
      end
      
      minions = GetInRange(me, "AA", MINIONS)
      SortByHealth(minions)
      local minion = minions[1]
      -- hit the highest health minion
      if minion and AA(minion) then
         return
      end
   end

   if IsOn("move") then
      MoveToCursor() 
   end
end

function lastHit()
   if KillWeakMinion("AA") then
      return true
   end
   local spell = spells["hunter"]
   if CanUse(spell) and CanAct() then
      local minions = GetUnblocked(me, spell, GetInRange(me, spell, MINIONS))
      SortByHealth(minions)
      for _,minion in ipairs(minions) do
         if GetSpellDamage(spell, minion) > minion.health then
            -- LineBetween(me, minion, spell.width)
            -- CastSpellXYZ(spell.key, minion.x, minion.y, minion.z)
            CastXYZ("hunter", minion)
            return true
         end   
      end
   end
   return false
end

function updateCharges()
   chargedEnemies = {}

   Clean(charges, "charName", "UrgotCorrosiveDebuff")
   for _,charge in ipairs(charges) do
      DrawCircleObject(charge, 85, green)

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
