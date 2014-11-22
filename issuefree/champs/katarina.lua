require "issuefree/timCommon"
require "issuefree/modules"

spells["blades"] = {
   key="Q", 
   range=675, 
   color=violet, 
   base={60,85,110,135,160}, 
   ap=.45,
   name="KatarinaQ"
}
spells["dagger"] = {
   key="Q",
   base={15,30,45,60,75},
   ap=.15
}
spells["sinister"] = {
   key="W", 
   range=375, 
   color=red,
   base={40,75,110,145,180},
   ap=.25,
   adBonus=.6,
   name="KatarinaW"
}
spells["shunpo"] = {
   key="E", 
   range=700, 
   color=yellow, 
   base={60,85,110,135,160}, 
   ap=.4,
   name="KatarinaE"
}
spells["lotus"] = {
   key="R", 
   range=550, 
   color=red,
   base={350,550,750},
   ap=2.5,
   adBonus=3.75,
   channel=true,
   object="katarina_deathLotus_mis.troy",
   objectTimeout=.5,
   name="KatarinaR"
}

-- don't calculate resists
spells["AA"].damOnTarget = 
   function(target)
      if HasBuff("dagger", target) then
         return GetSpellDamage("dagger")
      end
   end

function fullCombo()
   local comboDam = Damage()
   if CanUse("blades") then
      comboDam = comboDam + GetSpellDamage("blades") + GetSpellDamage("dagger")
   end
   if CanUse("sinister") then
      comboDam = comboDam + GetSpellDamage("sinister")
   end
   if CanUse("shunpo") then
      comboDam = comboDam + GetSpellDamage("shunpo")
   end
   if CanUse("lotus") then
      comboDam = comboDam + GetSpellDamage("lotus")
   end
   return comboDam
end

function getComboDamage(target)
   local daggered = HasBuff("dagger", target)
   local canShunpo = false
   local dist = GetDistance(target)

   local comboDam = 0
   if CanUse("blades") and dist < GetSpellRange("blades") then
      comboDam = comboDam + GetSpellDamage("blades", target)
      daggered = true
   end
   if CanUse("shunpo") and dist < GetSpellRange("shunpo") then
      canShunpo = true
      comboDam = comboDam + GetSpellDamage("shunpo", target)
      if daggered then
         comboDam = comboDam + GetSpellDamage("dagger", target)
         daggered = false
      end
   end
   if CanUse("sinister") and ( canShunpo or dist < GetSpellRange("sinister") ) then
      comboDam = comboDam + GetSpellDamage("sinister", target)
      if daggered then
         comboDam = comboDam + GetSpellDamage("dagger", target)
         daggered = false
      end
   end

   return comboDam
end

AddToggle("", {on=true, key=112, label="- - -"})
AddToggle("steal",  {on=false, key=113, label="Secure Kills", auxLabel="{0}", args={fullCombo}})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={"blades", "sinister"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

pp("Tim's Katarina")

function Run()
   if IsChannelling("lotus") then

      for _,enemy in ipairs(ENEMIES) do -- early abort for execute
         if GetDistance(enemy) > GetSpellRange("lotus") and 
            getComboDamage(enemy) > enemy.health 
         then
            P.lotus = nil
            break
         end
      end

      if not P.lotus or #GetInRange(me, GetSpellRange("lotus"), ENEMIES) == 0 then
         P.lotus = nil
      else
         PrintAction("LOTUS")
         return true
      end

   end

   if StartTickActions() then
      return true
   end

   if KeyDown(string.byte("X")) then
      WardJump("shunpo")
      return true
   end

   if HotKey() then
      if Action() then
         return true
      end
   end

   if IsOn("lasthit") then
      if Farm() then
         return true
      end
   end

   if HotKey() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end



function Action()
   if CanUse("blades") and CanUse("sinister") and CanUse("shunpo") then
      UseItem("Deathfire Grasp", GetWeakestEnemy("blades"))
   end
   
   -- blades and sinister are no brainers   
   if CanUse("blades") then
      local target = GetMarkedTarget() or GetWeakestEnemy("blades")
      if target then
         Cast("blades", target)
         PrintAction("Blades", target)
         return true
      end
   end
   if CanUse("sinister") then
      if #GetInRange(me, "sinister", ENEMIES) > 0 then
         Cast("sinister", me)
         PrintAction("Sinister")
         return true
      end      
   end

   if CanUse("lotus") then      
      if GetMarkedTarget() and IsInRange(GetSpellRange("lotus")*.5, GetMarkedTarget()) then
         Cast("lotus", me)
         PrintAction("Lotus marked", GetMarkedTarget())
         return true
      end

      local enemies = GetInRange(me, GetSpellRange("lotus")*.75, ENEMIES)

      local kills = GetKills("lotus", enemies)
      if #kills > 0 then
         Cast("lotus", me)
         PrintAction("Lotus for kill", kills[1])
         return true
      end

      if #enemies >= 2 then
         Cast("lotus", me)
         PrintAction("Lotus for aoe", #enemies)
         return true
      end
   end

   if CanUse("shunpo") then
      
      local target = GetWeakestEnemy("shunpo")
      if target then
         local dam = GetSpellDamage("shunpo")
         if HasBuff("dagger", target) then
            dam = dam + GetSpellDamage("dagger")
         end
         if CanUse("sinister") then
            dam = dam + GetSpellDamage("sinister", target)
         end
         if CanUse("lotus") then
            dam = dam + GetSpellDamage("lotus", target)
         end
         if CalculateDamage(target, dam) > target.health then
            Cast("shunpo", target)
            PrintAction("Shunpo", target)
            return true
         end
      end

      local target = GetMarkedTarget()
      if target and IsInRange("shunpo", target) and ( CanUse("sinister") or HasBuff("daggered", target) ) then
         Cast("shunpo", target)
         PrintAction("Shunpo (harrass)", target)
         return true
      end

   end
   return false
end

function FollowUp()
   return false
end


-- preferrs throws that include hitting heroes.
-- will keep throwing until heroes get pretty close.
function Farm()
   if CanUse("sinister") then
      local weakest = GetWeakestEnemy("sinister")
      if weakest and UnderTower() and UnderTower(weakest) then
         PrintAction("-Sinister: Tower danger")
      else
         local sinRange = GetInRange(me, "sinister", MINIONS)
         for _,minion in ipairs(sinRange) do
            local dam = GetSpellDamage("sinister", minion)
            if HasBuff("dagger", minion) then
               dam = dam + GetSpellDamage("dagger", minion)
            end
            if minion.health < dam then
               Cast("sinister", me)
               PrintAction("Sinister for lasthit")
               return true
            end
         end
      end
   end

   if CanUse("blades") then
      local nearTargets = GetInRange(me, 3000, MINIONS, ENEMIES)
      local initialTargets = SortByDistance(GetInRange(me, GetSpellRange("blades")+150, MINIONS, ENEMIES))

      -- bounce path with the best score      
      local bestKills = 0
      local bestKillTargets = nil
      local bestKillDeaths  = nil
      
      for _, initialTarget in ipairs(initialTargets) do
         local tKills, tKillTargets, tKillDeaths = getBouncePath(initialTarget, nearTargets) 
      
         if tKills > bestKills then
            bestKillTargets = tKillTargets
            bestKills = tKills
            bestKillDeaths = tKillDeaths
         end
      end
      
      if bestKillTargets then
         PrintState(0, "Farm score: "..bestKills)
         Circle(bestKillTargets[1], 90, violet)
         for i,t in ipairs(bestKillTargets) do
            local bkti = bestKillTargets[i]
            if i > 1 then
               LineBetween(bestKillTargets[i-1], bkti)
            end
            if not find(bkti.charName, "Minion") then
               Circle(bkti, 80, green)
            end
            if bestKillDeaths[i] then
               Circle(bkti, 70, red, 3)
            else
               Circle(bkti, 70, yellow)                        
            end
         end
         if GetDistance(bestKillTargets[1]) < GetSpellRange("blades") then
            if GetWeakEnemy("MAGIC", 1500) and UnderTower() then
               -- do nothing if there's a hero nearby and i'm under a tower
            elseif bestKills >= 1 then
               Cast("blades", bestKillTargets[1])
               PrintAction("Blades for lasthit", bestKills)
               return true
            end
         end
      end
   end

   if CanUse("shunpo") and not CanUse("blades") then
      local shunpoRange = GetInRange(me, "shunpo", MINIONS)
      local bestT
      local bestS
      for _,minion in ipairs(shunpoRange) do
         if GetDistance(minion) > GetSpellRange("sinister") and
            not UnderTower(minion)
         then
            local dam = GetSpellDamage("shunpo", minion)
            if HasBuff("dagger", minion) then
               dam = dam + GetSpellDamage("dagger", minion)
            end

            if minion.health < dam then
               local s = GetInRange(minion, "sinister", MINIONS)
               if not bestT or #s > bestS then
                  bestT = minion
                  bestS = #s
               end
            end
         end
      end
      if bestT and
         #GetInRange(bestT, (750+(me.selflevel*25))*1.5, ENEMIES) == 0
      then
         Cast("shunpo", bestT)
         PrintAction("Shunpo into minions")
         return true
      end
   end

end

function getBouncePath(target, nearTargets)
   local tKills = 0 
   local tKillTargets = {}
   local tKillDeaths  = {}

   local bbDam = GetSpellDamage("blades") -- reset blades damage for next path
   local testNearby = copy(nearTargets)
   local jumps = 0
   while jumps < 5 do
      local nearestI = GetNearestIndex(target, testNearby)
      if nearestI then
         if target and GetDistance(target, testNearby[nearestI]) > 375 then
            break
         end
         target = testNearby[nearestI]
         local isHero = not IsMinion(target)
         table.insert(tKillTargets, target)
         if CalculateDamage(target, bbDam) > target.health then
            if isHero then
               tKills = tKills + 5  -- 5 points for a hero kill
            else
               tKills = tKills + 1  -- 1 point for a minion kill
            end
            table.insert(tKillDeaths, true)
         else
            if isHero then
               tKills = tKills + (5-jumps)/5
            end
            table.insert(tKillDeaths, false)
         end
         table.remove(testNearby, nearestI)
      else
         break  -- out of bounce targets
      end
      jumps = jumps+1
      bbDam = bbDam*.9 
   end
   return tKills, tKillTargets, tKillDeaths
end

function onObject(object)
   PersistOnTargets("dagger", object, "katarina_daggered", ENEMIES, MINIONS)
end

function onSpell(unit, spell)
   -- this is here to make sure I let blades land before I consider my next move as it may change based on what gets hit.
   if ICast("blades", unit, spell) then
      StartChannel(.33, "blades")
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")