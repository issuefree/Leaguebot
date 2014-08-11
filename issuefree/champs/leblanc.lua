require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's LeBlanc")

function getComboDamage(target, spells)
   local dam = Damage(0)
   local mana = me.mana
   local marked = false
   local mimicMarked = false
   local spells = spells or {"malice", "mimic", "distortion"}

   if CanUse("ignite") then
      dam = dam + GetSpellDamage("ignite", target)
   end

   if CanUse("malice") and mana > GetSpellCost("malice") and ListContains("malice", spells) then
      local marked = true
      dam = dam + GetSpellDamage("malice", target)
      mana = mana - GetSpellCost("malice")
   end

   if CanUse("mimic") and ListContains("mimic", spells) then
      dam = dam + GetSpellDamage("mimicMalice", target)
      mimicMarked = true      
      if marked then
         dam = dam + GetSpellDamage("malice", target)
         marked = false
      end
   end

   if canDistortion() and mana > GetSpellCost("distortion") and ListContains("distortion", spells) then
      dam = dam + GetSpellDamage("distortion", target)
      mana = mana - GetSpellCost("distortion")
      if marked then
         dam = dam + GetSpellDamage("malice", target)
         marked = false
      end
      if mimicMarked then
         dam = dam + GetSpellDamage("mimicMalice", target)
         mimicMarked = false
      end
   end

   if CanUse("chains") and mana > GetSpellCost("chains") and ListContains("chains", spells) then
      dam = dam + GetSpellDamage("chains", target)*2
      mana = mana - GetSpellCost("chains")
      if marked then
         dam = dam + GetSpellDamage("malice", target)
         marked = false
      end
      if mimicMarked then
         dam = dam + GetSpellDamage("mimicMalice", target)
         mimicMarked = false
      end
   end   

   if target and Damage(dam) > Damage(0) then
      if HasBuff("mark", target) then
         dam = dam + GetSpellDamage("malice")
      end
      if HasBuff("markM", target) then
         dam = dam + GetSpellDamage("mimicMalice")
      end
   end

   if CanUseItem("Deathfire Grasp") then
      dam = dam * 1.2
   end
   if target then
      dam = dam + CalculateDamage(target, Damage(target.maxHealth * .15, "M"))
   end

   dam = Damage(dam)

   return dam:toNum()
end

AddToggle("harrass", {on=true, key=112, label="Harrass"})
AddToggle("execute", {on=true, key=113, label="Execute", auxLabel="{0}", args={getComboDamage}})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1} / {2}", args={GetAADamage, "malice", "distortion"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

-- TODO control clone

-- TODO use pad

-- combos
-- DONE W-Q-R high mana harrass
-- (MEH) W-R-Q-E high range harrass

-- Q-(R)-W-E basic - not really a combo. This is just a spell spam I think?

-- E-Q-(R)-W needed?

spells["malice"] = {
   key="Q",
   range=700,
   color=violet,
   base={55,80,105,130,155}, 
   ap=.4
} 

spells["distortion"] = {
   key="W", 
   range=600, 
   color=yellow, 
   base={85,125,165,205,245}, 
   ap=.6,
   delay=2.4, 
   speed=0,
   noblock=true, 
   radius=225 -- reticule
} 
spells["chains"] = {
   key="E", 
   range=950, 
   leash=1000,
   color=blue, 
   base={40,65,90,115,140}, 
   ap=.5,
   delay=2.5, -- testskillshot
   speed=17, -- testskillshot
   width=80 -- reticule
} 
spells["mimicMalice"] = copy(spells["malice"])
spells["mimicMalice"].base = {100,200,300}
spells["mimicMalice"].ap = .65
spells["mimicMalice"].key = "R"

spells["mimicDistortion"] = copy(spells["distortion"])
spells["mimicDistortion"].base = {150,300,450}
spells["mimicDistortion"].ap = .975
spells["mimicDistortion"].key = "R"

spells["mimicChains"] = copy(spells["chains"])
spells["mimicChains"].base = {100,200,300}
spells["mimicChains"].ap = .65
spells["mimicChains"].key = "R"

mimic = "malice"
harrassState = 0

function canDistortion()
   return CanUse("distortion") and me.SpellNameW ~= "leblancslidereturn"
end
function canDistortionM()
   return CanUse("mimic") and mimic == "distortion" and me.SpellNameR ~= "leblancslidereturnm"
end

function getDistortionPoint(target)
   local point = Point(target)
   if GetDistance(target) > GetSpellRange("distortion") then
      point = Projection(me, target, GetSpellRange("distortion"))
   end

   return point
end



harrass = Combo("harass", 3, function() Toggle("harrass", false) end)
harrass:addState("distortion",
   function(combo)
      if canDistortion() then
         CastXYZ("distortion", getDistortionPoint(combo.target))
         PrintAction(combo, combo.target)
      else
         combo.state = "malice"
      end
   end
)
harrass:addState("malice",
   function(combo)
      if CanUse("malice") then
         if IsInRange("malice", combo.target) then
            Cast("malice", combo.target)
            PrintAction(combo, combo.target)
         else
            MoveToTarget(combo.target)
         end
      else
         combo.state = "mimic"
      end
   end
)
harrass:addState("mimic",
   function(combo)
      if CanUse("mimic") then
         if mimic == "malice" then
            if IsInRange("malice", combo.target) then
               Cast("mimic", combo.target)
               PrintAction(combo, combo.target)
            else
               MoveToTarget(combo.target)
            end
         end
      else
         combo.state = "chains"
      end
   end
)
harrass:addState("chains", -- passthrouh state one try and bail
   function(combo)
      if GetMPerc(me) > .5 and CanUse("chains") then
         if SkillShot("chains", nil, {combo.target}) then
         else
            pp("no ss on chains")
         end
      end

      combo.state = "return"
   end
)
harrass:addState("return",
   function(combo)
      if P.pad and CanUse("distortion") then
         Cast("distortion", me)
         PrintAction(combo)
      else
         combo:reset()
      end
   end
)

lvl1harrass = Combo("Level 1 Harrass", 1, function() Toggle("harrass", false) end)
lvl1harrass:addState("distortion",
   function(combo)
      if canDistortion() then
         CastXYZ("distortion", getDistortionPoint(combo.target))
         PrintAction(combo, combo.target)
      else
         combo.state = "return"
      end
   end
)
lvl1harrass:addState("return",
   function(combo)
      if P.pad and CanUse("distortion") then
         Cast("distortion", me)
         PrintAction(combo)
      else
         combo:reset()
      end
   end
)

oore = Combo("Out of Range Execute", 3)
oore:addState("distortion",
   function(combo)
      if canDistortion() then
         CastXYZ("distortion", getDistortionPoint(combo.target))
         PrintAction(combo, combo.target)
      else
         combo.state = "malice"
      end
   end
)
oore:addState("malice",
   function(combo)
      if CanUse("malice") then
         UseItem("Deathfire Grasp", combo.target)
         if IsInRange("malice", combo.target) then
            Cast("malice", combo.target)
            PrintAction(combo, combo.target)
         else
            MoveToTarget(combo.target)
         end            
      else
         combo.state = "mimic"
      end
   end
)
oore:addState("mimic",
   function(combo)
      if CanUse("mimic") then
         if mimic == "malice" then
            if IsInRange("malice", combo.target) then
               Cast("mimic", combo.target)
               PrintAction(combo, combo.target)
            else
               MoveToTarget(combo.target)
            end
         end
      else
         combo:reset()
      end
   end
)

doore = Combo("Double out of Range Execute", 3)
doore:addState("distortion",
   function(combo)
      if canDistortion() then
         CastXYZ("distortion", getDistortionPoint(combo.target))
         PrintAction(combo, combo.target)
      else
         combo.state = "mimic"
      end
   end
)
doore:addState("mimic",
   function(combo)
      if canDistortionM() then
         CastXYZ("mimic", getDistortionPoint(combo.target))
         PrintAction(combo, combo.target)
      else
         combo.state = "malice"
      end
   end
)
doore:addState("malice",
   function(combo)
      if CanUse("malice") then
         if IsInRange("malice", combo.target) then
            UseItem("Deathfire Grasp", combo.target)
            Cast("malice", combo.target)
            PrintAction(combo, combo.target)
         else
            MoveToTarget(combo.target)
         end
      else
         combo:reset()
      end
   end
)

function Run()
   if me.SpellNameR == "LeblancChaosOrbM" then
      spells["mimic"] = spells["mimicMalice"]
      mimic = "malice"
   end
   if me.SpellNameR == "LeblancSlideM" then
      spells["mimic"] = spells["mimicDistortion"]
      mimic = "distortion"
   end   
   if me.SpellNameR == "LeblancSoulShackleM" then
      spells["mimic"] = spells["mimicChains"]
      mimic = "chains"
   end

   if StartTickActions() then
      return true
   end

   if CastAtCC("chains") then
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
         if CanUse("malice") and GetMPerc(me) > .75 then
            if KillMinion("malice") then
               return true
            end
         end
      end

      if VeryAlone() then

         if canDistortion() then
            if GetMPerc(me) > .75 then
               killThresh = 2
            elseif GetMPerc(me) > .33 then
               killThresh = 3
            else
               killThresh = 4
            end
            if KillMinionsInArea("distortion", killThresh) then
               return true
            end
         end

         if canDistortionM() then
            if KillMinionsInArea("mimic", 4) then
               return true
            end
         end
      end

   end

   if IsOn("clear") then
      if Alone() then
         if canDistortion() then
            local minScore
            if GetMPerc(me) > .75 then
               minScore = 4
            elseif GetMPerc(me) > .33 then
               minScore = 6
            else
               minScore = 8
            end
            local hits, kills, score = GetBestArea(me, "distortion", 1, 1, MINIONS)
            if score >= minScore then
               CastXYZ("distortion", GetAngularCenter(hits))
               PrintAction("Distortion for AoE clear", score)
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
   -- TestSkillShot("chains")

   if oore:run() or
      doore:run() or
      harrass:run() or
      lvl1harrass:run()
   then
      return true
   end
   
   SortByHealth(ENEMIES)
   for _,target in ipairs(GetInRange(me, "malice", ENEMIES)) do
      if getComboDamage(target) > target.health then
         
         UseItem("Deathfire Grasp", target)

         if CanUse("malice") then
            Cast("Malice execute", target)
            PrintAction("Malice execute", target)
            return true
         end
         if CanUse("mimic") and mimic == "malice" then
            Cast("mimic", target)
            PrintAction("Mimic Malice execute", target)
            return true
         end
         if canDistortion() then
            CastXYZ("distortion", getDistortionPoint(target))
            PrintAction("Distortion execute", target)
            return true
         end
      end
   end

   -- check for out of range executes
   -- TODO use chains in executes (check if there are blockers around for the skillshot)
   if CanUse("malice") and canDistortion() and
      me.mana > GetSpellCost("malice") + GetSpellCost("distortion")
   then
      local targets = SortByHealth(GetInRange(me, GetSpellRange("malice") + GetSpellRange("distortion"), ENEMIES))
      targets = FilterList(targets, function(item) return not IsInRange("malice", item) end)
      for _,target in ipairs(targets) do
         if getComboDamage(target, {"malice", "mimic"}) > target.health then
            oore.target = target
            oore:start()
            return true
         end
      end
   end

   if CanUse("malice") and CanUse("mimic") and canDistortion() and
      me.mana > GetSpellCost("malice") + GetSpellCost("distortion")
   then
      local targets = SortByHealth(GetInRange(me, GetSpellRange("malice") + GetSpellRange("distortion")*2, ENEMIES))      
      targets = FilterList(targets, function(item) return GetDistance(item) > (GetSpellRange("malice") + GetSpellRange("distortion")) end)
      for _,target in ipairs(targets) do
         if getComboDamage(target, {"malice"}) > target.health then
            doore.target = target
            doore:start()
            return true
         end
      end
   end

   -- start the combo
   if CanUse("malice") and 
      ( CanUse("mimic") or 
        ( CanUse("distortion") and me.mana > GetSpellCost("mimic") + GetSpellCost("distortion") ) or
        ( CanUse("chains") and me.mana > GetSpellCost("mimic") + GetSpellCost("chains") ) )
   then
      local target = GetWeakestEnemy("malice")
      if target then
         UseItem("Deathfire Grasp", target)

         Cast("malice", target)
         PrintAction("Start Combo Malice", target)
         return true
      end
   end

   -- finish the combo
   local target = GetMarkedTarget()
   if target then
      if mimic == "malice" and CanUse("mimic") then
         if IsInRange("mimic", target) then
            Cast("mimic", target)
            PrintAction("Mimic Malice marked", target)
            return true
         end
      end

      if canDistortion() then
         -- if SkillShot("distortion", nil, {target}) then
         --    return true
         -- end

         local point = getDistortionPoint(target)
         if GetDistance(point) < GetSpellRange("distortion") + spells["distortion"].radius - 25 then
            CastXYZ("distortion", point)
            PrintAction("Distortion marked", target)
            return true
         end
      end

      if CanUse("chains") then
         if SkillShot("chains", nil, {target}) then
            return true
         end
      end
   end

   if SkillShot("chains") then
      return true
   end   

   if mimic == "malice" and CastBest("mimic") then
      return true
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end

   return false
end
function FollowUp()
   if IsOn("harrass") then

      if canDistortion() and me.SpellLevelQ == 0 then
         local target = GetWeakest("distortion", GetInRange(me, GetSpellRange("distortion")+spells["distortion"].radius-50, ENEMIES))
         if target then
            lvl1harrass.target = target
            lvl1harrass:start()
            pp("start")
            return true
         end
      end

      if not GetWeakestEnemy("malice") and
         CanUse("malice") and canDistortion() and
         me.mana > GetSpellCost("malice") + GetSpellCost("distortion")
      then
         local target = GetWeakest("malice", GetInRange(me, GetSpellRange("malice")+GetSpellRange("distortion"), ENEMIES))         
         if target and not IsInRange("malice", target) then
            harrass.target = target
            harrass:start()
            return true
         end
      end

   end

   return false
end

local function onCreate(object)
   Persist("pad", object, "Leblanc_displacement_blink_indicator.troy")
   Persist("padM", object, "Leblanc_displacement_blink_indicator_ult")

   local m = PersistOnTargets("mark", object, "leBlanc_displace_AOE_tar.troy", ENEMIES, MINIONS, CREEPS)
   if m then
      MarkTarget(m)
   end
   local m = PersistOnTargets("markM", object, "leBlanc_displace_AOE_tar_ult.troy", ENEMIES, MINIONS, CREEPS)
   if m then
      MarkTarget(m)
   end
   -- Persist("shackle", object, "leBlanc_shackle_tar")

   Persist("pet", object, "LeblancImage")
end

local function onSpell(unit, spell)

end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")

