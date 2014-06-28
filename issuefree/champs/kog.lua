require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Kog")
pp(" - spittle weak people")
pp(" - slow weak people")
pp(" - if someone is in range of aa + barrage range turn it on")
pp(" - aa people")
pp(" - artillery people based on mana/their health")
pp(" - lasthit ooze >= 3 if mana > .5 and very alone")
pp(" - lasthit artillery >= 2 if no stacks and alone")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})

spells["spittle"] = {
   key="Q", 
   range=1000, 
   color=violet, 
   base={80,130,180,230,280}, 
   ap=.5,
   cost=60,
   delay=1.2,
   speed=17.5,
   width=80
}
spells["barrage"] = {
   key="W", 
   range={130,150,170,190,210},
   healthPerc=0
}
spells["ooze"] = {
   key="E", 
   range=1300, 
   color=yellow, 
   base={60,110,160,210,260}, 
   ap=.7,
   delay=1.65,
   speed=14,
   noblock=true,
   width=200,
   cost={80,90,100,110,120}
}
spells["artillery"] = {
   key="R", 
   range={1200, 1500, 1800},
   color=green, 
   base={80,120,160},
   ap=.3,
   bonusAd=.5,
   delay=10,
   speed=0,
   noblock=true,
   radius=200,
   cost=40
}

spells["AA"].damOnTarget = 
   function(target)
      return Damage(spells["barrage"].healthPerc*target.maxHealth, "M")
   end

local barrage = nil
local lastArtillery = 0
local artilleryCount = 0

local function getBarrageRange()
   local spell = spells["barrage"]
   local lvl = GetSpellLevel(spell.key)
   if lvl > 0 then      
      return spells["AA"].range+GetSpellRange("barrage")
   end
   return spells["AA"].range
end

local function updateSpells()
   local spell = spells["barrage"]
   local lvl = GetSpellLevel(spell.key)
   if lvl > 0 then      
      if P.barrage then
         spells["barrage"].healthPerc = (lvl+1+(me.ap*.01))/100
         
         spells["AA"].range = getBarrageRange()
      end
   end

   if time() - lastArtillery > 6.25 then
      artilleryCount = 0
   end
   spells["artillery"].cost = math.min((artilleryCount+1)*40, 400)
end

function Run()
   updateSpells()

   Circle(P.artillery, spells["artillery"].radius, green, 4)

   if StartTickActions() then
      return true
   end

   if CastAtCC("artillery") then
      return true
   end

	if HotKey() and CanAct() then
      UseItems()
		if Action() then
			return
		end
	end

   if IsOn("lasthit") and VeryAlone() then
      if me.mana/me.maxMana > .5 then         
         if KillMinionsInLine("ooze", 3) then
            return true
         end
      end
   end
   if IsOn("lasthit") and Alone() then
      if artilleryCount == 0 then
         if KillMinionsInArea("artillery", 2) then
            return true
         end
      end
   end
   -- low priority hotkey actions, e.g. killing minions, moving
   if HotKey() and CanAct() then
      if FollowUp() then
         return
      end
   end
end

function Action()

   -- TestSkillShot("spittle")

   if SkillShot("spittle") then
      return true
   end

   if CanUse("ooze") and GetMPerc(me) > .5 then
      local target = GetMarkedTarget() or GetWeakestEnemy("ooze")
      if target then
         if CastFireahead("ooze", target) then
            PrintAction("Ooze", target)
            return true
         end
      end
   end

   if CanUse("barrage") then
      local target = GetWeakEnemy("PHYS", getBarrageRange())
      if target then
         Cast("barrage", me)
         PrintAction("Barrage")
      end
   end

   if CanUse("artillery") then
      local target = GetMarkedTarget() or GetWeakestEnemy("artillery")
      local tManaP = (me.mana - GetSpellCost("artillery")) / me.maxMana
      if target and 
         ( GetDistance(target) > spells["AA"].range or
           JustAttacked() )
      then
         if artilleryCount == 0 or 
            GetMPerc(me) > .5 or
            GetSpellDamage("artillery", target) > target.health or
            GetHPerc(target) < tManaP*2
         then
            if CastFireahead("artillery", target) then
               PrintAction("Artillery", target)
               return true
            end
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
   return false
end

local function onObject(object)
   PersistBuff("barrage", object, "KogMaw_Fossile_Eye_Glow")
   Persist("artillery", object, "KogMawLivingArtillery_cas")
end

local function onSpell(object, spell)
   if object.name == me.name and find(spell.name, "KogMawLivingArtillery") then
      artilleryCount = artilleryCount + 1
      lastArtillery = time()
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
