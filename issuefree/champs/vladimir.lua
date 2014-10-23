require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Vladimir")
-- TODO auto pool

InitAAData({ 
   projSpeed = 1.4, windup=.3, -- tests ok at .25 but I thought I got a couple misses.
   particles = {"Vladimir_Base_BA_mis.troy"}
})

SetChampStyle("caster")

function getComboDamage()
   if CanUse("plague") then
      if GetCD("transfusion") < spells["plague"].timeout and GetCD("tides") < spells["plague"].timeout then
         local preDam = GetSpellDamage("transfusion") + GetSpellDamage("tides") + GetAADamage()
         local dam = preDam * 1.12 -- for the plague
         dam = dam + GetSpellDamage("plague")
         return dam
      end
   end
   return 0
end

AddToggle("plague", {on=true, key=112, label="Auto Plague", auxLabel="{0}", args={getComboDamage}})
AddToggle("pool", {on=false, key=113, label="Auto Pool"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1} / {2}", args={GetAADamage, "transfusion", "tides"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["transfusion"] = {
   key="Q", 
   range=600-25,
   color=violet, 
   base={90,125,160,195,230}, 
   ap=.6
} 
spells["transfusionHeal"] = {
   base={15,25,35,45,55}, 
   ap=.25
} 
spells["pool"] = {
   key="W",
   radius=150
} 
spells["tides"] = {
   key="E", 
   range=610-45, 
   color=yellow, 
   base={60,85,110,135,160}, 
   ap=.45,
   healthCost={30,40,50,60,70},
   stackTime=10
}
spells["tideStack"] = {
   base=spells["tides"].base
}
spells["plague"] = {
   key="R", 
   range=700, 
   color=red, 
   base={168,280,392}, 
   ap=.784,
   radius=375, -- reticle
   timeout=5
} 

local tideStacks = 0
local lastTideTime = 0
function Run()
   for _,t in ipairs(GetWithBuff("hemoplague"), ENEMIES, MINIONS) do
      Circle(t)
   end
   spells["tides"].bonus = GetSpellDamage("tideStack")*tideStacks*.25

   if lastTideTime + 10 < time() then
      tideStacks = 0
   end

   if StartTickActions() then
      return true
   end

   if P.pool then
      if IsOn("move") then
         AutoMove()
      end
      return
   end      

   -- auto stuff that always happen


   -- high priority hotkey actions, e.g. killing enemies
   if HotKey() and CanAct() then
      if Action() then
         return true
      end
   end

   -- auto stuff that should happen if you didn't do something more important
   if IsOn("lasthit") then
      if not GetWeakestEnemy("transfusion") then
         if KillMinion("transfusion", nil, true) then
            return true
         end
      end

      if Alone() then
         if CanUse("tides") then
            local cost = GetLVal(spells["tides"], "healthCost")*(tideStacks+4)*.25
            local kills = GetKills("tides", GetInRange(me, "tides", MINIONS))
            if cost/me.health < #kills * .075 then
               Cast("tides", me)
               PrintAction("Tides for AoE LH", #kills)
               return true
            end
         end
      end
   end

   if Alone() then
      if GetHPerc(me) < .5 and Alone() and CanUse("transfusion") then
         if HitMinion("transfusion", "strong") then
            return true
         end
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
   if IsOn("plague") and CanUse("plague") then

      -- aoe in team fights
      local nearEnemies = GetInRange(me, 750, ENEMIES)
      local nearAllies = #GetInRange(me, 750, ALLIES)
      -- there are a couple of them and at least as many of us as there are of them.
      if #nearEnemies >=2 and
         nearAllies >= #nearEnemies
      then
         local hits, kills, score = GetBestArea(me, "plague", 1, .5, nearEnemies)
         local ePlague = copy(spells["plague"])
         ePlague.range = ePlague.range + 250
         local thits, tkills, tscore = GetBestArea(me, ePlague, 1, .5, ENEMIES)

         -- I hit at least 2 and a better hit isn't "just" out of range
         if score >= 2 and score >= tscore then
            CastXYZ("plague", GetCastPoint(hits, "plague"))
            PrintAction("Plague for AoE", score)
            return true
         end
      end

      -- check for long range executes
      local targets = GetInRange(me, GetSpellRange("plague") + spells["plague"].radius - 50, ENEMIES)
      targets = FilterList(targets, function(item) return GetDistance(item) > GetSpellRange("transfusion") end)
      targets = GetKills("plague", targets)
      targets = reverse(SortByDistance(targets))
      local target = targets[1]
      if target then
         CastXYZ("plague", GetReachPoint("plague", target))
         PrintAction("Plague for long range kill", target)
         return true
      end

      -- check for combo executes
      if GetCD("transfusion") < spells["plague"].timeout and GetCD("tides") < spells["plague"].timeout then         
         local targets = SortByHealth(GetInRange(me, "transfusion", ENEMIES), "plague") -- transfusion shortest range on combo
         local preDam = GetSpellDamage("transfusion") + GetSpellDamage("tides") + GetAADamage()
         local dam = preDam * 1.12 -- for the plague
         dam = dam + GetSpellDamage("plague")
         for _,target in ipairs(targets) do
            -- if the combo will kill them without plague, don't do it.
            -- if the combo will kill them with plague do do it.
            if not IsImmune("plague", target) and
               CalculateDamage(target, dam) > target.health and
               CalculateDamage(target, preDam) < target.health
            then
               MarkTarget(target)
               CastXYZ("plague", GetReachPoint("plague", target))
               PrintAction("Plague for combo", target)
               return true
            end
         end
      end
   end

   if CanUse("tides") and GetWeakestEnemy("tides") then
      Cast("tides", me)
      PrintAction("Tides")
      return true
   end

   if CastBest("transfusion") then
      return true
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end

   return false
end
function FollowUp()

   if Alone() then
      if CanUse("transfusion") then
         local sm = reverse(SortByHealth(FilterList(GetInRange(me, "transfusion", MINIONS), function(item) return IsSuperMinion(item) end)))[1]
         if sm then
            Cast("transfusion", sm)
            PrintAction("Kill Super Minions")
            return true
         end
      end
   end

   if IsOn("clear") then
      if Alone() then
         if CanUse("tides") then
            local cost = GetLVal(spells["tides"], "healthCost")*(tideStacks+4)*.25
            local hits = GetInRange(me, "tides", MINIONS)
            local kills = GetKills("tides", hits)
            if cost/me.health < (#kills*.02 + #hits*.01) then
               Cast("tides", me)
               PrintAction("Tides for AoE clear", #hits)
               return true
            end
         end
      end
   end

   return false
end

local function onCreate(object)
   -- TODO track affected by plague
   PersistBuff("pool", object, "Vladimir_Base_W_buf.troy")
end

function addTidesStack()
   lastTideTime = time()
   tideStacks = math.min(tideStacks+1, 4)
end

local function onSpell(unit, spell)
   if ICast("tides", unit, spell) then
      addTidesStack()
   end
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")

