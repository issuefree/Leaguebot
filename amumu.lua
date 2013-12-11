require "timCommon"
require "modules"

pp("\nTim's Amumu")
pp(" - Despair and Tantrum in the jungle")
pp(" - Despair and Tantrum enemies")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("jungle", {on=true, key=113, label="Jungle"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "tantrum"}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["bandage"] = {
  key="Q", 
  range=1100, 
  color=violet, 
  base={80,130,180,230,280}, 
  ap=.7,
  delay=2,
  speed=20,
  width=80,
  cost={80,90,100,110,120}
}
spells["despair"] = {
  key="W", 
  range=300, 
  color=blue
}
spells["tantrum"] = {
  key="E", 
  range=350, 
  color=red, 
  base={75,100,125,150,175}, 
  ap=.5,
  cost=35
}
spells["curse"] = {
  key="R", 
  range=550, 
  color=yellow, 
  base={150,250,350}, 
  ap=.8,
  cost={100,150,200}
}

local despairClearTime = 0

function Run()

   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return true
   end
   if IsChannelling() then
      return true
   end

   if CanUse("despair") then
      if P.despair and 
         #GetAllInRange(me, GetSpellRange("despair")+50, MINIONS, ENEMIES, CREEPS) == 0 
      then
         Cast("despair", me)         
         PrintAction("Despair off")
         StartChannel()
         end
      end
   end

	if HotKey() and CanAct() then
      UseItems()
		if Action() then
			return true
		end
	end

   if IsOn("jungle") then
      if #GetAllInRange(me, "despair", BIGCREEPS, MAJORCREEPS) > 0  then

         if not P.despair and CanUse("despair") then
            CastBuff("despair")
            PrintAction("Despair for jungle")
         end

         if CanUse("tantrum") then
            Cast("tantrum", me)
            PrintAction("Tantrum for jungle")
            return true
         end
      end
   end

	if IsOn("lasthit") and CanUse("tantrum") and not Engaged() then
      if #GetKills("tantrum", GetInRange(me, "tantrum", MINIONS)) >= 2 then
         Cast("tantrum", me)
         PrintAction("Tantrum for lasthit")
         return true
      end
   end

   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end
end

function Action()
   if CanUse("despair") and not P.despair then
      if GetWeakestEnemy("despair") then
         CastBuff("despair")
         PrintAction("Despair")
      end
   end

   if CanUse("tantrum") then
      if GetWeakestEnemy("tantrum") then
         Cast("tantrum", me)
         PrintAction("Tantrum")
         return true
      end
   end

   local target = GetMarkedTarget() or GetMeleeTarget()
   if AA(target) then
      PrintAction("AA", target)
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
      if CanUse("tantrum") and #GetInRange(me, "tantrum", MINIONS) >= 3 then
         Cast("tantrum", me)
         PrintAction("Tantrum for clear")
         return true
      end

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

local function onObject(object)
   if PersistBuff("despair", object, "Despair_buf", 150) then
      pp("despair up")
   end
end

local function onSpell(unit, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
