require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Orianna")

InitAAData({ 
   projSpeed = 1.3, windup=.25,
   particles = {"OrianaBasicAttack_mis"} 
})

SetChampStyle("caster")

AddToggle("shield", {on=true, key=112, label="Protect"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "attack"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["windup"] = {
   base=2,
   bonus=function() return math.floor((me.selflevel+2)/3)*8 end,
   ap=.15,
   scale=function(target)
      if P.lasthit and P.lasthit.object and target then
         if target.charName == P.lasthit.object.charName then
            if P.lasthit.hits == 1 then
               return 1.2
            elseif P.lasthit.hits >= 2 then
               return 1.4
            end
         end
      end
   end
}
spells["AA"].bonus = function(target) 
   if target then
      return GetSpellDamage("windup", target, true) 
   end
end

spells["attack"] = {
   key="Q", 
   range=825, 
   color=violet, 
   base={60,90,120,150,180}, 
   ap=.5,
   delay=0,    --tss
   speed=12,   --tss
   radius=160-25, --TODO
   noblock=true,
   overShoot=100,
   scale=function(target)
      if target and IsBlocked(target, "attack", P.ball or me, MINIONS) then
         return .4
      end
   end,
   cost=50
} 
spells["dissonance"] = {
   key="W", 
   radius=250-25,
   base={70,115,160,205,250}, 
   ap=.7,
   cost={70,80,90,100,110}
} 
spells["protect"] = {
   key="E", 
   range=1100, 
   color=blue, 
   base={60,90,120,150,180}, 
   ap=.3,
   delay=0,    --tss
   speed=12,   --tss
   width=160-25,  --TODO
   cost=60
} 
spells["shockwave"] = {
   key="R", 
   radius=400,
   base={150,225,300}, 
   ap=.7,
   cost={100,125,150}
} 

function Run()
   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen
   -- if CheckDisrupt("shockwave") then
   --    return true
   -- end

   -- if CastAtCC("attack") then
   --    return true
   -- end

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
		if Action() then
         return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important
   if IsOn("lasthit") then
      if Alone() then
         local ball = P.ball or me            
         
         if CanUse("attack") then
            local hits, kills, score = GetBestLine(ball, "attack", .05, .95, GetInRange(me, "attack", MINIONS))
            if score > GetThreshMP("attack", .1, 1.5) then
               local target = SortByDistance(hits, ball, true)[1]
               AddWillKill(kills, "attack")
               CastXYZ("attack", target)
               PrintAction("Ball for LH", score)
               return true
            end
         end

         if CanUse("dissonance") then
            local hits = GetInRange(ball, spells["dissonance"].radius, MINIONS)
            local score, kills = scoreHits("dissonance", hits, .05, .95)
            if score > GetThreshMP("attack", .1, 1.5) then
               AddWillKill(kills, "dissonance")
               Cast("dissonance", me)
               PrintAction("Dissonance for LH", score)
               return true
            end
         end

         -- TODO combo attack and dissonance for lasthitting
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
   -- TestSkillShot("attack")
   local ball = P.ball or me
   
   if CanUse("attack") then
      local hits, kills, score = GetBestLine(ball, "attack", 1, 5, GetInRange(me, "attack", ENEMIES))
      if score >= 1 then
         local target = SortByDistance(hits, ball, true)[1]
         CastXYZ("attack", target)
         PrintAction("Ball Attack targets", #hits)
         return true
      end
   end

   if not P.ball then
      if SkillShot("attack") then
         return true
      end
   end

   -- if CanUse("shockwave") then
   --    local inRange = GetInRange(ball, spells["shockwave"].radius, ENEMIES)
   --    if #inRange >=2 then
   --       Cast("shockwave", me)
   --       PrintAction("SUCK!")
   --       return true
   --    end
   -- end

   if CanUse("dissonance") then
      if #GetInRange(ball, spells["dissonance"].radius, ENEMIES) >= 1 then
         Cast("dissonance", me)
         PrintAction("Dissonance enemies")
         return true
      end
   end

   -- if all my protectable allies are healthy then use shield for hits
   if CanUse("protect") then      
      local allies = SortByHealth(GetInRange(me, "protect", ALLIES))      
      if allies[1] and GetHPerc(allies[1]) > .75 then
         local ally = SelectFromList(allies,
            function(ally)
               return #GetBetween(ball, ally, spells["attack"].radius, ENEMIES)
            end
         )
         if ally then
            Cast("protect", ally)
            PrintAction("Shield for hits")
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

-- function AutoJungle()
--    local creep = GetBiggestCreep(GetInRange(me, "AA", CREEPS))
--    local score = ScoreCreeps(creep)
--    if AA(creep) then
--       PrintAction("AA "..creep.charName)
--       return true
--    end
-- end   
-- SetAutoJungle(AutoJungle)

local function onCreate(object)
   Persist("ball", object, "TheDoomBall")
   PersistOnTargets("windup1", object, "TODO", MINIONS, CREEPS, PETS, ENEMIES)
   PersistOnTargets("windup2", object, "TODO", MINIONS, CREEPS, PETS, ENEMIES)
end

local function onSpell(unit, spell)
   if IsOn("shield") then
      if P.ball and CanUse("dissonance") and #GetInRange(P.ball, spells["dissonance"].radius, ENEMIES) then
         CheckShield("protect", unit, spell)
      end
   end

   local hit = 0
   if IAttack(unit, spell) then
      if P.lasthit and SameUnit(P.lasthit.object, spell.target) then
         hit = P.lasthit.hits + 1
      end
      PersistTemp("lasthit", 4)
      P.lasthit.hits = hit
      P.lasthit.object = spell.target
   end
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")

