require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Udyr")

AddToggle("- - -", {on=true, key=112, label="- - -"})
AddToggle("jungle", {on=true, key=113, label="Jungle"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["tiger"] = {
   key="Q",   
   cost={47,44,41,38,35}
} 
spells["turtle"] = {
   key="W", 
   range=25,
   cost={47,44,41,38,35}
}
spells["bear"] = {
   key="E", 
   cost={47,44,41,38,35}
} 
spells["phoenix"] = {
   key="R", 
   base={15,25,35,45,55},
   ap=.25,
   radius=250,
   cost={47,44,41,38,35}
} 

spells["AA"].damOnTarget = 
   function(target)
      return 0
   end

function Run()
   if P.tiger then
      spells["AA"].bonus = (me.baseDamage+me.addDamage)*.15
   else
      spells["AA"].bonus = 0
   end

   if P.tiger then      
      PrintState(0,"TIGER")
   elseif P.turtle then
      PrintState(0,"TURTLE")
   elseif P.phoenix then
      PrintState(0,"PHOENIX")
   else
      PrintState(0, "BEAR")
   end

   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important

   if IsOn("lasthit") and GetMPerc(me) > .33 and Alone() then
      if CanUse("phoenix") then
         if #GetKills("phoenix", GetInRange(me, spells["phoenix"].radius, MINIONS)) >= 2 then
            Cast("phoenix", me)
            PrintAction("Phoenix for aoe lasthit")
            return true
         end
      end            
   end

   if IsOn("clear") and GetMPerc(me) > .66 and JustAttacked() then
      if CanUse("phoenix") and
         #GetInRange(me, spells["phoenix"].radius, MINIONS) >= 3 and 
         spells["phoenix"].spellLevel > spells["tiger"].spellLevel
      then
         Cast("phoenix", me)
         PrintAction("Phoenix for clear")
         return true
      end
      if CanUse("turtle") and GetHPerc(me) < .66 then
         Cast("turtle", me)
         PrintAction("Turtle for clear")
         return true
      end
      if CanUse("tiger") and #GetInRange(me, 500, MINIONS) >= 2 then
         Cast("tiger", me)
         PrintAction("Tiger for clear")
         return true
      end
   end

   if IsOn("jungle") and VeryAlone() then      
      local creeps = GetAllInRange(me, 750, CREEPS)
      if #creeps >= 1 then
         if me.mana > 200 and GetHPerc(me) < .8 then
            if CanUse("turtle") and JustAttacked() then
               Cast("turtle", me)
               PrintAction("Turtle in the jungle")
               return true
            end
         end
         local tl = GetSpellLevel(spells["tiger"].key)
         local pl = GetSpellLevel(spells["phoenix"].key)
         if JustAttacked() then
            if ( not P.phoenix and pl > tl ) or #creeps >= 3 then
               if CanUse("phoenix") then
                  Cast("phoenix", me)
                  PrintAction("Phoenix in the jungle")
                  return true
               end
            end
            if CanUse("tiger") then
               Cast("tiger", me)
               PrintAction("Tiger in the jungle")
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

   local target = GetMarkedTarget() or GetMeleeTarget()
   if target then
      if GetDistance(target) > GetSpellRange("AA") then
         if CanUse("bear") then
            Cast("bear", me)
            PrintAction("BEAR")
            return true
         end
      else
         local tl = GetSpellLevel(spells["tiger"].key)
         local pl = GetSpellLevel(spells["phoenix"].key)
         if CanUse("phoenix") and pl > tl then
            Cast("phoenix", me)
            PrintAction("PHOENIX")
            return true
         end
         if CanUse("tiger") and tl >= pl then
            Cast("tiger", me)
            PrintAction("TIGER")
            return true
         end
         if CanUse("bear") then
            Cast("bear", me)
            PrintAction("BEAR")
            return true
         end
      end
   end

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
   PersistBuff("tiger", object, "TigerPelt")
   PersistBuff("turtle", object, "TurtlePelt")
   PersistBuff("phoenix", object, "PhoenixPelt")
end

local function onSpell(unit, spell)   
   CheckShield("turtle", unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")

