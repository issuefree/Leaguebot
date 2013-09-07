require "Utils"
require "timCommon"
require "modules"

-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Morde")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["mace"] = {
  key="Q", 
  base={80,110,140,170,200}, 
  ap=.4,
  adBonus=1,
  radius=600
}
spells["shield"] = {
  key="W", 
  range=750, 
  color=yellow, 
  base={24,38,52,66,80}, 
  ap=.2,
  radius=250
}
spells["siphon"] = {
  key="E", 
  range=700, 
  color=violet, 
  base={70,115,160,205,250}, 
  ap=.6,
  delay=2,
  speed=99,
  cone=30
}
spells["grave"] = {
  key="R", 
  range=850, 
  color=red, 
  base={0,0,0}, 
  healthPerc={.24,.29,.34},
  cost=0
}

local childObj = nil
local child = nil

function Run()
   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return
   end

   autoChild()

	if HotKey() and CanAct() then
      UseItems()
		if Action() then
			return
		end
	end

   if IsOn("lasthit") and Alone() then
      if CanUse("siphon") then
         if KillMinionsInCone("siphon", 2, 0, false) then
            PrintAction("Siphon minions")
            return true
         end
      end
   end

   if HotKey() and CanAct() then
      if FollowUp() then
         return
      end
   end
end
function autoChild()
   -- SpellNameR when not tibbers is "InfernalGuardian"
   -- SpellNameR when tibbers is "infernalguardianguide"
   if Check(childObj) then
      child = GetObj(childObj)

      -- find the closest target to tibbers
      local target = SortByDistance(GetInRange(child, 1000, ENEMIES))[1]
      if target then
         childAttack(target)
      end      
   else
      child = nil
   end
end

local lastChildAttack = 0
function childAttack(target)
   if time() - lastChildAttack > 1.5 then
      CastSpellTarget("R", target)
      lastChildAttack = time()
      PrintAction("Child Attack", target)
   end
end

function Action()
   if CanUse("grave") and not Check(childObj) then      
      local target = GetMarkedTarget() or GetWeakEnemy("MAGIC", spells["grave"].range)
      if target then
         local spell = spells["grave"]
         local perc = spell.healthPerc[GetSpellLevel(spell.key)]+(me.ap*.0004)
         local dam = target.maxHealth*perc
         if CalcMagicDamage(target, dam) > target.health*.75 then
            Cast("grave", target)
            PrintAction("Grave", target)
            return true
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
      local target = GetWeakestEnemy("siphon")
      if target then
         Cast("siphon", target)
         PrintAction("Siphon", target)
         return true
      end
   end

   local target = GetMarkedTarget() or GetWeakEnemy("PHYS", spells["AA"].range*2)
   if CanUse("mace") and 
      target and 
      GetDistance(target) < spells["AA"].range+25 
   then
      Cast("mace", me)
      PrintAction("Mace up")
   end

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
      if CanUse("mace") then
         local target = SortByDistance(GetInRange(me, 200, MINIONS))[1]
         if #GetInRange(target, spells["mace"].radius, MINIONS) > 2 then
            Cast("mace", me)
            AttackTarget(target)
            PrintAction("Mace for clear")
            return true
         end
      end
   end

   if IsOn("move") then
      local target = GetMarkedTarget() or GetWeakEnemy("PHYS", spells["AA"].range*1.5)
      if target then
         if GetDistance(target) > spells["AA"].range then
            MoveToTarget(target)
            PrintAction("MTT")
            return false
         end
      else        
         MoveToCursor() 
         PrintAction("Move")
         return false
      end
   end

   return false
end

local function onObject(object)
   if find(object.charName, "mordekaiser_cotg_ring") then
      childObj = StateObj(object)         
   end
end

local function onSpell(object, spell)

end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
