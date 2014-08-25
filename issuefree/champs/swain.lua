require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Swain")

InitAAData({ 
   projSpeed = 1.6, windup=.15,
   particles = {"swainBasicAttack_mis"}
   -- "swain_basicAttack_bird_cas", "swain_basicAttack_cas", 
})

SetChampStyle("caster")

AddToggle("crow", {on=true, key=112, label="Auto Crow"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["decrepify"] = {
   key="Q", 
   range=625, 
   color=yellow, 
   base={75,120,165,210,255}, 
   ap=.9,
} 
spells["nevermore"] = {
   key="W", 
   range=900,
   color=blue, 
   base={80,120,160,200,240}, 
   ap=.7,
   delay=2.6, -- testskillshot
   speed=0,
   radius=250, -- reticle
   noblock=true,
} 
spells["torment"] = {
   key="E", 
   range=625, 
   color=violet, 
   base={75,115,155,195,235},
   ap=.8,
   extraDamage={.08,.11,.14,.17,.2},
} 
spells["crow"] = {
   key="R",
   range=700,
   color=red,
   base={50,70,90},
   ap=.2
} 

function Run()
   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen

   if CastAtCC("nevermore") then
      return true
   end

   if IsOn("crow") and P.crow and
      Alone() and #GetInRange(me, spells["crow"].range+50, MINIONS, CREEPS) == 0 
   then
      CastBuff("crow", false)
   end


   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important
   if IsOn("lasthit") then
      if VeryAlone() and IsOn("crow") and not P.crow and CanUse("crow") then
         local tics = 1
         if GetMPerc(me) > .75 then
            tics = 3
         elseif GetMPerc(me) > .5 then
            tics = 2
         else
            tics = 1
         end
         local kills = 0
         local minions = GetInRange(me, "crow", MINIONS)
         for i,minion in ipairs(minions) do
            if GetSpellDamage("crow", minion)*tics > minion.health then
               PrintState(i, GetSpellDamage("crow", minion)*tics.." "..minion.health)
               Circle(minion)
               kills = kills + 1
            end
         end
         if kills >= 3 then
            CastBuff("crow")
            PrintAction("Crow for AoE LH", kills)
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
   -- TestSkillShot("nevermore")
   if CanUse("torment") then
      local target = GetWeakestEnemy("torment")
      if target then
         Cast("torment", target)
         return true
      end
   end

   if CanUse("decrepify") then
      local target = GetWithBuff("decrepify", ENEMIES)[1]
      if target and IsInRange("decrepify", target) then
         Cast("decrepify", target)
         PrintAction("Decrepify tormented", target)
         return true
      else
         if CastBest("decrepify") then
            return true
         end
      end
   end

   -- if SkillShot("nevermore") then
   --    return true
   -- end

   if IsOn("crow") and CanUse("crow") and not P.crow then
      if GetMPerc(me) > .33 and GetWeakestEnemy("crow",-150) then
         CastBuff("crow")
         PrintAction("Crow to duel")
         return true
      elseif #GetInRange(me, "crow", ENEMIES) >= 2 then
         CastBuff("crow")
         PrintAction("Crow for AoE teamfight")
         return true
      end
   end

   if not P.crow then
      local target = GetMarkedTarget() or GetWeakestEnemy("AA")
      if AutoAA(target) then
         return true
      end
   end

   return false
end

function FollowUp()
   return false
end

local function onCreate(object)
   PersistBuff("crow", object, "swain_demonForm_idle.troy")
   PersistOnTargets("decrepify", object, "swain_torment_marker.troy", ENEMIES)
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")

