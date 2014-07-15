require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Evelynn")

AddToggle("stealth", {on=false, key=112, label="Stealth Mode"})
AddToggle("jungle", {on=true, key=113, label="Jungle"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1} / {2}", args={GetAADamage, "spike", "ravage"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

--[[
Hate Spike will firstly prioritize Evelynn's most recent target and 
   it will target low health units secondly if Evelynn has not attacked a unit. 
   If both an enemy champion and a low health minion are in range, Hate Spike will prioritize the enemy champion.
Hate Spike is only usable when a visible enemy unit is within its range.
]]
spells["spike"] = {
   key="Q", 
   range=500, 
   color=violet, 
   base={40,60,80,100,120}, 
   ap=.45,
   bonusAd=.5,
   width=80,
   noblock=true,
   cost={16,22,28,34,40}
} 
spells["frenzy"] = {
   key="W"
} 

-- test if this is a modaa or an attack reset
spells["ravage"] = {
   key="E", 
   range=225+GetWidth(me),
   color=yellow, 
   base={70,110,150,190,230}, 
   ap=1,
   bonusAd=1,
   cost={50,55,60,65,70}
} 
spells["embrace"] = {
   key="R",
   range=650,
   radius=350, -- test
   color=red,
   base=0, 
   targetHealth={.15,.20,.25},
   targetHealthAP=.0001,   
   cost=100
} 

spells["AA"].damOnTarget = 
   function(target)
      return 0
   end

function Run()
   if StartTickActions() then
      return true
   end

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important

   if IsOn("lasthit") then
      if ( not P.walk and not Engaged() ) or
           VeryAlone() or
           not ( P.walk and IsOn("stealth") and Alone() ) 
      then

         if CanUse("spike") then
            if ( Alone() and GetMPerc(me) > .33 ) or
               VeryAlone()
            then
               local minions = GetInRange(me, "spike", MINIONS)
               local lt = SortByHealth(GetWithBuff("attack", minions))[1]
               if lt and WillKill("spike", lt) and
                  ( JustAttacked() or not IsInRange("AA", lt) )
               then
                  Cast("spike", me)
                  AddWillKill(lt)
                  PrintAction("Spike last attack for LH")
                  return true
               end

               local lt = SortByHealth(minions)[1]
               if lt and WillKill("spike", lt) then
                  Cast("spike", me)
                  AddWillKill(lt)
                  PrintAction("Spike for LH")
                  return true
               end
            end
         end

         if CanUse("ravage") then
            if ( Alone() and GetMPerc(me) > .5 ) or
               ( VeryAlone() and GetMPerc(me) > .25 )
            then
               local target = KillMinion("ravage", "strong", true)
               if target and not WillKill("AA", target) then
                  if KillMinion("ravage", "strong") then
                     return true
                  end
               end
            end
         end

      end
   end
   
   if IsOn("jungle") and Alone() then
      if JustAttacked() then
         if CanUse("spike") then
            local creeps = GetInRange(me, "spike", CREEPS)
            if #creeps > 0 then
               Cast("spike", me)
               PrintAction("Spike in jungle")
               return true
            end
         end

         if CanUse("ravage") then
            local creep = SortByMaxHealth(GetInRange(me, "spike", CREEPS), nil, true)[1]
            if creep then
               Cast("ravage", creep)
               PrintAction("Ravage in jungle")
               return true
            end
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
   -- probably cast early
   -- probably hold off casting if there are people just out of range
   if CanUse("embrace") then
      local hits, kills, score = GetBestArea(me, "embrace", 1, 1, ENEMIES)
      if #hits >= 2 then
         CastXYZ("embrace", GetAngularCenter(hits))
      elseif #hits == 1 and GetHPerc(hits[1]) > .75 then
         CastXYZ("embrace", hits[1])
      end
   end

   if CastBest("spike") then
      return true
   end

   if CastBest("ravage") then
      return true
   end

   -- TODO auto W?

   local target = GetMarkedTarget() or GetMeleeTarget()
   if AutoAA(target) then
      return true
   end

   return false
end
function FollowUp()
   if IsOn("move") then
      if MeleeMove() then
         return true
      end
   end
   return false
end

local function onCreate(object)
   Persist("walk", object, "Evelynn_Ring_Green")
   PersistOnTargets("attack", object, "EvelynnBasicAttack", MINIONS, CREEPS)
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")

