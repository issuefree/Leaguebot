require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Brand")

SetChampStyle("caster")

AddToggle("", {on=true, key=112, label="- - -"})
AddToggle("ult", {on=true, key=113, label="Auto Ult"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1} / {2} / {3}", args={GetAADamage, "sear", "pillar", "conflag"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

-- check for blaze on targets
-- combos with blaze
-- pyro bounce

spells["sear"] = {
  key="Q", 
  range=900, 
  color=violet, 
  base={80,120,160,200,240}, 
  ap=.65,
  delay=2,
  speed=16,
  width=80,
  cost=50
}
spells["pillar"] = {
  key="W", 
  range=902, 
  color=yellow, 
  base={75,120,165,210,255}, 
  ap=.6,
  delay=8.5,
  speed=0,
  radius=250,
  noblock=true,
  cost={70,75,80,85,90}
}
spells["conflag"] = {
  key="E", 
  range=625, 
  color=violet, 
  base={70,105,140,175,210}, 
  ap=.55,
  radius=300,
  cost={70,75,80,85,90}
}
spells["pyro"] = {
  key="R", 
  range=750, 
  radius=400, -- probably much too large but I can test it down
  color=red, 
  base={150,250,350}, 
  ap=.5,
  cost=100
}

function Run()
   if StartTickActions() then
      return true
   end

   if CastAtCC("pillar") or 
      CastAtCC("sear") 
   then
      return true
   end


   -- high priority hotkey actions, e.g. killing enemies
   if HotKey() and CanAct() then
      if Action() then
         return true
      end
   end

   -- auto stuff that should happen if you didn't do something more important
   if VeryAlone() and IsOn("lasthit") then
      local killsNeeded = 4
      if GetMPerc(me) > .75 then
         killsNeeded = 2
      elseif GetMPerc(me) > .5 then
         killsNeeded = 3
      end
      if CanUse("conflag") then
         local minions = GetInRange(me, "conflag", GetWithBuff("ablaze", MINIONS))
         for _,minion in ipairs(minions) do
            local kills = GetKills("conflag", GetInRange(minion, spells["conflag"].radius, MINIONS))
            if #kills >= 2 then
               Cast("conflag", minion)
               PrintAction("Conflagration for AoE LH", #kills)
               return true
            end
         end
      end

      if KillMinionsInArea("pillar", 2) then
         return true
      end

      if CanUse("sear") then
         local minions = SortByDistance(GetKills("sear", GetUnblocked(me, "sear", MINIONS)))
         for _,minion in ipairs(minions) do
            if not WillKill("AA", minion) then
               CastFireahead("sear", minion)
               PrintAction("Sear for LH")
               return true
            end
         end
      end

      if KillMinion("sear") then
         return true
      end
   end
   
   -- low priority hotkey actions, e.g. killing minions, moving
   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()
   -- TestSkillShot("sear")
   -- TestSkillShot("pillar", "BrandPOF_tar.troy")

   if CanUse("conflag") and CanUse("sear") and CanUse("pillar") then
      local target = UseItem("Deathfire Grasp", target)
      if target then
         UseItem("Deathfire Grasp", target)
      end
   end
   
   if CastBest("conflag") then
      return true
   end

   -- sear burning enemies
   if SkillShot("sear", nil, GetWithBuff("ablaze", ENEMIES)) then
      return true
   end

   if CanUse("pyro") then
      for _,enemy in ipairs(SortByHealth(GetInRange(me, "pyro", ENEMIES)), "pyro") do
         if WillKill("pyro", enemy) then
            Cast("pyro", enemy)
            PrintAction("Pyro for the kill")
            return true
         end


         if GetSpellDamage("pyro", enemy)*2 > enemy.health then
            local bounceTargets = #GetInRange(enemy, spells["pyro"].radius, ENEMIES, MINIONS)
            if bounceTargets >= 2 and bounceTargets <= 3 then
               Cast("pyro", enemy)
               PrintAction("Pyro for the bounce kill")
               return true
            end
         end

         local bounceEnemies = #GetInRange(enemy, spells["pyro"].radius, ENEMIES)
         local bounceMinions = #GetInRange(enemy, spells["pyro"].radius, MINIONS)
         if bounceEnemies >= 2 and bounceMinions <= 1 then
            Cast("pyro", enemy)
            PrintAction("Pyro for AoE damage")
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
   return false
end

local function onCreate(object)
   PersistOnTargets("ablaze", object, "BrandBlaze_hotfoot", ENEMIES, MINIONS)
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")

