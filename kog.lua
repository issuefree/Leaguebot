require "Utils"
require "timCommon"
require "modules"

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
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["spittle"] = {
   key="Q", 
   range=625, 
   color=violet, 
   base={60,110,160,210,260}, 
   ap=.7,
   cost=60
}
spells["barrage"] = {
   key="W", 
   cost=50,
   range={130,150,170,190,210},
   healthPerc=0
}
spells["ooze"] = {
  key="E", 
  range=1300, 
  color=yellow, 
  base={60,110,160,210,260}, 
  ap=.7,
  delay=2.65,
  speed=14,
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
  delay=9,
  speed=99,
  radius=200,
  cost=40
}

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

   if time() - lastArtillery > 6 then
      artilleryCount = 0
   end
   spells["artillery"].cost = math.min((artilleryCount+1)*40, 400)
end

function Run()
   updateSpells()

   Circle(P.artillery, spells["artillery"].radius, green, 4)

   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return
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
   if CanUse("spittle") then
      local target = GetMarkedTarget() or GetWeakestEnemy("spittle")
      if target then
         if Cast("spittle", target) then
            PrintAction("Spittle", target)
            return true
         else
            PrintAction("Failed spittle", target)
         end
      end
   end

   if CanUse("ooze") then
      local target = GetMarkedTarget() or GetWeakestEnemy("ooze")
      if target then
         if CastSpellFireahead("ooze", target) then
            PrintAction("Ooze", target)
            return true
         end
      end
   end

   if CanUse("barrage") then
      local target = GetMarkedTarget() or GetWeakEnemy("PHYS", getBarrageRange())
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
            GetSpellDamage(artillery, target) > target.health or
            GetHPerc(target) < tManaP*2
         then
            if CastSpellFireahead("artillery", target) then
               PrintAction("Artillery", target)
               return true
            end
         end
      end
   end

   local target = GetWeakEnemy("PHYS", spells["AA"].range)
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
      -- hit the highest health minion
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