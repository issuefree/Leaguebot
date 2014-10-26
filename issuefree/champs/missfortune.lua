require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Miss Fortune")

InitAAData({
   projSpeed = 2.0, windup=.25,
   particles = {"missFortune_basicAttack_mis", "missFortune_crit_mis"}
})

SetChampStyle("marksman")

AddToggle("double", {on=true, key=112, label="DoubleUp Enemies", auxLabel="{0}", args={"doubleBounce"}})
AddToggle("", {on=true, key=113, label="- - -"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}-{2}", args={GetAADamage, "double", "doubleBounce"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["double"] = {
   key="Q", 
   range=GetAARange, 
   rangeType="e2e",
   color=violet, 
   base={20,35,50,65,80},
   ad=.85,
   ap=.35,
   type="P",
   cost={43,46,49,52,55},
   radius=500,
   onhit=true -- not sheen so watch for that
}
spells["doubleBounce"] = {
   key="Q",
   range=function() return GetSpellRange("double") + 50 + spells["double"].radius end, -- estimate for range circle. not used in calcs.
   color=spells["double"].color,
   base={40,70,100,130,160},
   ad=1,
   ap=.5,
   onhit=true
}
spells["impure"] = {
   key="W",
   ad=.06,
   type="M",
   cost={30,35,40,45,50}
}
spells["rain"] = {
   key="E", 
   range=800, 
   color=yellow, 
   base={90,145,200,255,310}, 
   ap=.8,
   radius=200,
   cost=80
}
spells["bullet"] = {
   key="R", 
   range=1400, 
   color=red, 
   base={400,600,1000}, 
   ap=1.6,
   cost=100,
   channel=true,
   object="MissFortune_Base_R_cas"
}

function getDoubleHits(target, debug)
   --[[
   1. Enemy champions in a 40° cone with at least one stack of Impure Shots.
   2. Minions and neutral monsters within a 20° cone.
   3. Enemy champions within a 20° cone.
   4. Minions and neutral monsters within a 40° cone.
   5. Enemy champions within a 40° cone.
   6. Enemy or neutral units within a 110° cone.
   7. Enemy or neutral units within a 150-range 160° cone.
   ]]--

   if debug then
      Circle(target, nil, red, 4)
      DrawCone(target, AngleBetween(me, target), DegsToRads(20), spells["double"].radius)
      DrawCone(target, AngleBetween(me, target), DegsToRads(40), spells["double"].radius)
   end

   local angle = AngleBetween(me, target)

   local targets = GetInCone(target, angle, DegsToRads(40), GetInRange(target, spells["double"].radius, impureEnemies))
   if #targets > 0 then
      return targets
   end

   local targets = GetInCone(target, angle, DegsToRads(20+5), GetInRange(target, spells["double"].radius, MINIONS, CREEPS, PETS))
   if #targets > 0 then      
      if debug then
         pp(#targets.." in 20")
      end
      return targets
   end

   local targets = GetInCone(target, angle, DegsToRads(20), GetInRange(target, spells["double"].radius, ENEMIES))
   if #targets > 0 then
      return targets
   end

   local targets = GetInCone(target, angle, DegsToRads(40+5), GetInRange(target, spells["double"].radius, MINIONS, CREEPS, PETS))
   if #targets > 0 then
      if debug then
         pp(#targets.." in 40")
      end
      return targets
   end

   local targets = GetInCone(target, angle, DegsToRads(40), GetInRange(target, spells["double"].radius, ENEMIES))
   if #targets > 0 then
      return targets
   end

   local targets = GetInCone(target, angle, DegsToRads(110), GetInRange(target, spells["double"].radius, MINIONS, CREEPS, PETS, ENEMIES))
   if #targets > 0 then
      if debug then
         pp(#targets.." in 110")
      end
      return targets
   end

   local targets = GetInCone(target, angle, DegsToRads(160), GetInRange(me, 150, MINIONS, CREEPS, PETS, ENEMIES))
   if #targets > 0 then
      if debug then
         pp(#targets.." in 160")
      end
      return targets
   end

   return {}
end
   
function scoreDouble(target, debug)
   local score = 0
   local hits = {}
   local kills = {}
   if WillKill("double", target) then
      local ihs = .5
      if JustAttacked() then
         ihs = ihs + .25
      end
      if IsBigMinion(target) then
         ihs = ihs * 1.5
      end
      score = score + ihs
      if debug then
         pp(score.." from initial hit")
      end
   end
   hits = getDoubleHits(target)
   if #hits > 0 then
      kills = GetKills("doubleBounce", hits)
      if #kills > 0 then
         local tks = 0
         for _,kill in ipairs(kills) do
            local ks = .75
            if JustAttacked() then
               ks = ks + .1
            end
            if not IsInAARange(kill) then
               ks = ks + .5
            end
            if IsBigMinion(kill) then
               ks = ks * 1.5
            end                     
            tks = tks + ks
         end
         if debug then
            pp(#kills.. "kills")
            pp(tks.." total kill score")
            pp(#hits.." total bounce hits")
         end
         score = score + tks/#hits
      end
   end
   if debug then
      if score > 0 then
         pp(score.." total score")
         pp("-------------------------")
      end
   end
   return score, hits, kills
end

impureEnemies = {}
hasImpurity = {}

function doubleUpEnemy()
   if not CanUse("double") then return false end

   local initialTargets = GetInRange(me, "double", MINIONS, ENEMIES, PETS)
   initialTargets = reverse(SortByDistance(initialTargets))

   for _,target in ipairs(initialTargets) do
      local hits = getDoubleHits(target)      
      local enemyHits = FilterList(hits, IsEnemy)
      if #enemyHits > 0 and #hits == #enemyHits then
         Cast("double", target)
         PrintAction("Double for long range hit")
         return true
      end
   end
end

function Run()
   -- local tests = TestTargets()
   -- local angle = DegsToRads(0)
   -- local arc = DegsToRads(45)
   -- local range = 750
   -- local targets = GetInCone(me, angle, arc, GetInRange(me, range, tests))
   -- for _,t in ipairs(targets) do
   --    Circle(t, 25, blue, 3)
   -- end
   -- LineBetween(me, ProjectionA(me, angle+(arc/2), range))
   -- LineBetween(me, ProjectionA(me, angle-(arc/2), range))

   spells["AA"].bonus = GetSpellDamage("impure")

   impureEnemies = {}
   for _,enemy in ipairs(ENEMIES) do
      if hasImpurity[enemy.name] then
         table.insert(impureEnemies, enemy)
      end
   end

   if StartTickActions() then
      return true
   end

   if IsOn("double") then
      if doubleUpEnemy() then
         return true
      end
   end
 
   if HotKey() and CanAct() then
      if Action() then
         return true
      end
   end   


   -- initial kills aren't worth as much because I could just auto attack them.
   -- this should go up a bit if I just attacked.
   -- high chance kills out of aa range is good
   -- gauranteed double kills are good

   -- I want to go for gauranteed double kills
   -- I want to go for gauranteed out of range kills

   -- thresh of > 1

   -- initial target base = .5
   -- initial target after attack = .75
   -- in range kill on bounce = .75
   -- irkob after attack = 1
   -- orkob = 1.5
   -- orkob ja = 1.75

   -- will kill big minions after attack on first hit (ok)
   -- will go for any initial kill after attack with a bit of a chance of a second kill (ok)

   if IsOn("lasthit") and Alone() then
      if CanUse("double") then
         local target, score = SelectFromList(GetInRange(me, "double", MINIONS), scoreDouble)

         if target and score > GetThreshMP("double") then
            -- getDoubleHits(bestT, true)
            -- scoreDouble(bestT, true)
            Cast("double", target)
            PrintAction("double for LH", score)
            return true
         end
            
      end
   end

   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end
   
   EndTickActions()
end

function Action()
   if not IsOn("double") then
      if doubleUpEnemy() then
         return true
      end
   end

   if JustAttacked() then
      if CastBest("double") then
         return true
      end
   end

   if CanUse("impure") then
      if GetWeakestEnemy("AA") then
         Cast("impure", me)         
         PrintAction("Impure")
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
   -- there's no object for impurity stacks.
end

local function onSpell(unit, spell)
   if IAttack(unit, spell) then
      if IsEnemy(spell.target) then
         hasImpurity[spell.target.name] = true
         DoIn(function() hasImpurity[spell.target.name] = false end, 5, "impurity"..spell.target.name)
      end
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
