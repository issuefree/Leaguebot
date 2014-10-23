require "issuefree/timCommon"
require "issuefree/modules"

-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Morde")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1} / {2}", args={GetAADamage, "mace", "siphon"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=112, label="Move to Mouse"})

spells["mace"] = {
   key="Q", 
   color=red,
   range=GetAARange(),
   base={80,110,140,170,200}, 
   ap=.4,
   adBonus=1,
   type="M",
   onHit=true,
   radius=600
}
spells["shield"] = {
   key="W", 
   range=750, 
   color=yellow, 
   base={24,38,52,66,80}, 
   ap=.2,
   type="M",
   radius=250
}
spells["siphon"] = {
   key="E", 
   color=violet, 
   range=650, 
   cone=50,  -- checked through DrawSpellCone aagainst the reticle
   base={70,115,160,205,250}, 
   ap=.6,
   type="M",
   delay=2,
   speed=0,
   noblock=true,
}
spells["grave"] = {
   key="R", 
   range=850, 
   color=red, 
   base={0,0,0}, 
   targetMaxHealth={.24,.29,.34},
   targetMaxHealthAP=.0004,
   type="M",
   cost=0
}

function Run()
   if StartTickActions() then
      return true
   end

   AutoPet(P.cotg)

	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

   if IsOn("lasthit") and Alone() then

      if CanUse("siphon") then
         if KillMinionsInCone("siphon", 2) then
            return true
         end
      end

      if P.mace then
         local kills = SortByDistance(GetKills("mace", GetInAARange(me, MINIONS)))
         if kills[1] then
            if AA(kills[1]) then
               PrintAction("Clobber minion")
               return true
            end
         end
      end

      if CanUse("mace") and not P.mace then
         local kills = SortByDistance(GetKills("mace", GetInAARange(me, MINIONS)))
         if kills[1] then
            Cast("mace", me)
            AttackTarget(kills[1])
            PrintAction("Mace on for LH")
            return true
         end
      end


   end

   if HotKey() and CanAct() then
      if FollowUp() then
         return
      end
   end
   EndTickActions()
end

function Action()
   if CanUse("grave") and not P.cotg then
      -- if I'm low and engaged I want it for the lifesteal.
      -- if they don't have backup then the graveling won't do much so don't waste it
      -- if I don't have backup then be more conservative about casting it

      if GetHPerc(me) < .33 and Engaged() then
         local target = SortByMaxHealth(GetInRange(me, "grave", ENEMIES), me, true)[1]
         if target then
            Cast("grave", target)
            PrintAction("Grave to try to survive", target)
            return true
         end
      end

      local target = GetMarkedTarget() or GetWeakestEnemy("grave")
      if target then
         if #GetInRange(target, 750, ENEMIES) >= 2 then
            local hpThresh = 1
            if #GetInRange(target, 1000, ALLIES) >= 2 then
               hpThresh = .75
            end
            if GetSpellDamage("grave", target) > target.health*hpThresh then
               Cast("grave", target)
               PrintAction("Grave for kill", target)
               return true
            end
         end
      end
   end

   if CanUse("shield") then
      if #GetInRange(me, spells["shield"].radius+GetWidth(me), ENEMIES) > 0 then
         Cast("shield", me)
         PrintAction("Shield me")
         return true
      end
   end

   if CanUse("siphon") then
      UseItem("Deathfire Grasp", GetWeakestEnemy("siphon"))
   end

   if CastBest("siphon") then
      return true
   end

   local target = GetMarkedTarget() or GetMeleeTarget()
   if CanUse("mace") then
      if target and 
         not P.mace and
         IsInAARange(target, me, 25)
      then
         Cast("mace", me)
         PrintAction("Mace up", nil, 1)
      end

   end
   if AutoAA(target) then
      return true
   end

   return false
end

function FollowUp()
   if IsOn("clear") and Alone() then
      if CanUse("mace") and not P.mace then
         local target = SortByDistance(GetInRange(me, 200, MINIONS))[1]
         if #GetInRange(target, spells["mace"].radius, MINIONS) > 2 then
            Cast("mace", me)
            AttackTarget(target)
            PrintAction("Mace for clear")
            return true
         end
      end
   end

   -- if CanUse("mace") then
   --    if IsOn("move") then
   --       if MeleeMove() then
   --          return true
   --       end
   --    end
   -- end


   return false
end

local function onObject(object)
   if Persist("cotg", object, "mordekaiser_cotg_ring") then
      pp("GOT PET!")
   end

   PersistBuff("mace", object, "mordakaiser_maceOfSpades_activate")
end

local function onSpell(object, spell)
   CheckPetTarget(P.cotg, unit, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
