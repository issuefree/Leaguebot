require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Cassiopeia")

InitAAData({ 
   projSpeed = 1.3, windup=.25,
   -- minMoveTime = 0,
   extraRange=-10,
   particles = {"CassBasicAttack"} 
})

SetChampStyle("caster")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["blast"] = {
   key="Q", 
   range=825, 
   color=yellow, 
   base={75,115,155,195,235},
   ap=.8,
   delay=3, -- hard to test but delay is 2.4 plus .6 from wiki.
   speed=0,
   noblock=true,
   radius=150
} 
spells["miasma"] = {
   key="W", 
   range=850, 
   color=yellow, 
   base={25,35,45,55,65}, 
   ap=.15,
   delay=2.3,
   speed=25,
   noblock=true,
   radius=150+50
} 
spells["fang"] = {
   key="E", 
   range=700, 
   color=violet, 
   base={50,85,120,155,190}, 
   ap=.55,
} 
spells["gaze"] = {
   key="R", 
   range=825, 
   color=red, 
   base={200,325,450}, 
   ap=.6,
   cone=80, -- reticule
   noblock=true
} 

spells["AA"].damOnTarget = 
   function(target)
      return 0
   end

function Run()
   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen

   if CastAtCC("blast") or
      CastAtCC("Miasma")
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
   if IsOn("lasthit") then
      if Alone() then
         if CanUse("blast") then
            if GetMPerc(me) > .66 then
               if KillMinionsInArea("blast", 2) then
                  return true
               end
            else
               if KillMinionsInArea("blast", 3) then
                  return true
               end
            end

         end

         if GetMPerc(me) > .5 then
            if KillMinion("fang") then
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

   if IsOn("clear") then
      if VeryAlone() then
         if CanUse("miasma") then
         end
      end
   end

   EndTickActions()
end

function Action()
   -- TestSkillShot("miasma", "CassMiasma")

   if SkillShot("blast") then
      return true
   end

   if CanUse("miasma") then
      local hits = GetBestArea(me, "miasma", 1, 0, GetFireaheads("miasma", ENEMIES))
      if #hits > 0 then
         CastXYZ("miasma", GetAngularCenter(hits))
         PrintAction("Miasma for AoE", #hits)
         return true
      end
   end

   if CanUse("fang") then
      local target = GetWeakest("fang", GetWithBuff("poison", GetInRange(me, "fang", ENEMIES)))
      if target then
         UseItem("Deathfire Grasp", target)

         Cast("fang", target)
         PrintAction("Fang poisoned", target)
         return true
      end

      -- if not CanUse("blast") and not CanUse("miasma") then
      --    if CastBest("fang") then
      --       return true
      --    end
      -- end
   end

   if CanUse("gaze") then
      local hits, kills, score = GetBestCone(me, "gaze", 1, 1, ENEMIES)
      for _,hit in ipairs(hits) do
         if FacingMe(hit) then
            score = score + 1
         end
      end
      if score >=4 then
         CastXYZ("gaze", GetAngularCenter(hits))
         PrintAction("Gaze for AoE", score)
         return true
      end

      -- highest health execute
      -- don't execute if I'm about to be able to cast fang
      -- don't execute if they're right on top of me
      -- don't execute if their health is less than half the execute damage
      if GetCD("fang") > 2 then
         local target = SortByHealth(GetKills("gaze", GetInRange(me, "gaze", ENEMIES)), "gaze", true)[1]         
         if target and GetDistance(target) > 500 and GetSpellDamage("gaze", target) / 2 < target.health then
            CastFireahead("gaze", target)
            PrintAction("Gaze for execute", target)
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
   PersistOnTargets("poison", object, "Global_Poison", ENEMIES, MINIONS, CREEPS)
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")

