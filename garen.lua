require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Garen")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["strike"] = {
   key="Q", 
   base={30,55,80,105,130}, 
   ad=1.4
}
spells["courage"] = {
  key="W"
}
spells["judgement"] = {
  key="E", 
  range=330,
  color=violet
}
spells["justice"] = {
  key="R", 
  range=400,
  color=red,
  base={175,350,525},
  missing={3.5,3,2.5}
}

local strike
local spinT

function Run()
	TimTick()

   if isSpinning() then
      PrintState(1, "SPIN")
   end

   if IsRecalling(me) or me.dead == 1 then
      return
   end

   spinT = nil
   -- highlight best spin location within 3x spin range
   if CanUse("judgement") then
      local minions = SortByDistance(GetInRange(me, spells["judgement"].range*3, MINIONS))
      local bestMinions = {}
      for _,minion in ipairs(minions) do
         local hits = GetInRange(minion, "judgement", minions)
         if #hits > #bestMinions then
            bestMinions = hits
         end
      end

      if #bestMinions > 2 then 
         local x,y,z = GetCenter(bestMinions)
         spinT = {x=x, y=y, z=z}
         DrawThickCircle(spinT.x, spinT.y, spinT.z, 50, yellow, 6)
      end
   end


	if HotKey() and CanAct() then
		if Action() then
         return
      end
	end

	-- always stuff here

   if HotKey() and CanAct() then
      if FollowUp() then
         return
      end
   end
end

function Action()
   UseItems()
   
   -- if justice will kill, use justice (probably worth chasing)
   -- If my target is in 2x aa range then activate strike to catch and smack em
   --   don't activate if I'm spinning
   -- If someone targets me and I'm < 50% activate courage
   -- If strike is on cooldown and I have >= 2 enemies in range, activate spin

   if CanUse("justice") then
      local targets = SortByDistance(GetInRange(me, spells["justice"].range*1.5, ENEMIES))
      for _,target in ipairs(targets) do
         if target.health < getJusticeDam(target) then
            Cast("justice", target)
            return true            
         end
      end
   end

   local aaTarget = GetWeakEnemy("PHYS", spells["AA"].range*2)

   if aaTarget and not isSpinning() and CanUse("strike") then
      Cast("strike", me)
      -- no return
   end

   if not isSpinning() and CanUse("judgement") and not CanUse("strike") and not Check(strike) then
      local targets = GetInRange(me, spells["judgement"].range, ENEMIES)
      if #targets > 0 then
         Cast("judgement", me)
      end
   end

   if aaTarget and isSpinning() then
      MoveToTarget(aaTarget)
      return true
   end

   if aaTarget and AA(aaTarget) then
   	return true
   end

end

function FollowUp()
   if IsOn("lasthit") and Alone() then
      if KillWeakMinion("AA") then
         return true
      end
   end

   if IsOn("clearminions") and Alone() then
      -- if I'm close to the best spin spot then spin
      if not isSpinning() and CanUse("judgement") and spinT then
         if GetDistance(me, spinT) < 200 then
            Cast("judgement", me)
         end
      end

      -- if I'm spinning then move close to the spin spot.
      if isSpinning() and spinT then
         MoveToXYZ(spinT.x, spinT.y, spinT.z)
         return true
      end

      if not spinT or (not isSpinning() and not CanUse("judgement")) then
         -- hit the highest health minion
         local minions = SortByHealth(GetInRange(me, "AA", MINIONS))
         local minion = minions[#minions]
         if minion and AA(minion) then
            return true
         end
      end
   end

   if IsOn("move") then
      if aaTarget then
         MoveToTarget(aaTarget)
         return true
      else
         MoveToCursor() 
         return true
      end
   end

   return false
end

function getJusticeDam(target)
   if not target then return 0 end
   local sLvl = me.SpellLevelR
   if sLvl < 1 then return 0 end

   local dam = GetSpellDamage("justice")
   local missingHealth = target.maxHealth - target.health
   dam = dam + missingHealth / spells["justice"].missing[sLvl]
   return CalcMagicDamage(target, dam)
end

function isSpinning()
   return me.SpellNameE == "garenbladestormleave"
end

local function onObject(object)
   if HasBuff(me, object, "garen_decisiveStrike_indicator") then
      strike = StateObj(object)
   end
end

local function onSpell(object, spell)
   if spell.target and spell.target.name == me.name and
      me.health / me.maxHealth < .5 and
      CanUse("courage")
   then
      Cast("courage", me)
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
