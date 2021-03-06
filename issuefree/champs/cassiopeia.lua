require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Cassiopeia")

InitAAData({ 
   speed = 1300, windup=.25,
   -- extraRange=-10,
   particles = {"CassBasicAttack"} 
})

SetChampStyle("caster")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1} / {2}", args={GetAADamage, "blast", "fang"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["blast"] = {
   key="Q", 
   range=825, 
   color=yellow, 
   base={25,38,52,65,78},
   ap=.45/3,
   -- base={75,115,155,195,235},
   -- ap=.35,
   delay=3-2, -- hard to test but delay is 2.4 plus .6 from wiki.
   speed=0,
   noblock=true,
   radius=150
} 
spells["miasma"] = {
   key="W", 
   range=850, -- need this for planting poison for E spam
   color=yellow, 
   base={10,15,20,25,30}, 
   ap=.1,
   delay=2.3-1,
   speed=0,
   noblock=true,
   radius=150+25
} 
spells["fang"] = {
   key="E", 
   range=700, 
   color=violet, 
   base={55,80,105,130,155},
   ap={.55},
} 
spells["gaze"] = {
   key="R", 
   range=825, 
   color=red, 
   base={150,250,350}, 
   ap=.5,
   cone=80, -- reticle
   noblock=true
} 

function Run()
   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen

   if CastAtCC("blast") or
      CastAtCC("miasma")
   then
      return true
   end

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() then
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important
   if IsOn("lasthit") then
      if Alone() then
         if HitMinionsInArea("blast", GetThreshMP(thing, .05, 2)) then
            return true
         end

         if CanUse("fang") then
            if GetThreshMP("fang", .15) <= 1 then
               local minions = GetKills("fang", GetWithBuff("poison", GetInRange(me, "fang", MINIONS)))
               local minion = SortByHealth(minions, "fang", true)[1]
               if minion then
                  AddWillKill(minion, "fang")
                  Cast("fang", minion)
                  PrintAction("Fang LH poisoned")
                  return true
               end
            end
         end

         if KillMinion("fang") then
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

   if IsOn("clear") then
      if Alone() then
         if HitMinionsInArea("miasma") then
            return true
         end
      end
   end

   EndTickActions()
end

function Action()
   if SkillShot("blast") then
      return true
   end

   if CanUse("miasma") then
      local hits = GetBestArea(me, "miasma", 1, 0, GetFireaheads("miasma", ENEMIES))
      if #hits > 1 then
         CastXYZ("miasma", GetCastPoint(hits, "miasma"))
         PrintAction("Miasma for AoE", #hits)
         return true
      end

      local target = GetWeakestEnemy("miasma", -250)
      if target then
         CastXYZ("miasma", target)
         PrintAction("Miasma near", target)
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

function AutoJungle()
   if JungleAoE("miasma") then
      return true
   end
   if JungleAoE("blast") then
      return true
   end

   if CanUse("fang") then
      local creep = GetBiggestCreep(GetInRange(me, "fang", CREEPS))
      if creep then
         if HasBuff("poison", creep) then
            Cast("fang", creep)
            PrintAction("Fang (jungle)")
            return true
         end
      end
   end

   local creep = GetBiggestCreep(GetInRange(me, "AA", CREEPS))
   if AA(creep) then
      PrintAction("AA "..creep.charName)
      return true
   end
end   
SetAutoJungle(AutoJungle)

local function onCreate(object)
   PersistOnTargets("poison", object, "Global_Poison", ENEMIES, MINIONS, CREEPS)
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")

