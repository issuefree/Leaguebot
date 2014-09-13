require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Varus")

InitAAData({ 
   projSpeed = 2.0, windup=.25,
   particles = {"Varus_basicAttack_mis"}
})

SetChampStyle("marksman")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

function getBlightDamage(target)
   local stacks = getBlightStacks(target)
   if stacks > 0 then
      return stacks*GetSpellDamage("blight", target, true)
   end
   return 0
end

function getBlightStacks(target)
   if HasBuff("blight1", target) then
      return 1
   elseif HasBuff("blight2", target) then
      return 2
   elseif HasBuff("blight3", target) then
      return 3
   end
   return 0
end

spells["arrow"] = {
   key="Q", 
   range=925,
   baseRange=925,
   maxRange=1525,
   overShoot=50,
   chargeTime=1.25,  -- time to max charge
   color=violet, 
   base    ={10,47, 83,120,157},
   baseBase={10,47, 83,120,157},
   maxBase ={15,70,125,180,235},
   ad=1,
   baseAd=1,
   maxAd=1.6,
   type="P",
   delay=.8,  -- tested
   speed=19, -- tested matches wiki
   width=75,
   noblock=true,
   cost={70,75,80,85,90},
   damOnTarget=function(target)      
      local dam
      if IsMinion(target) then
         dam = GetSpellDamage("arrow")*(-2/3) + getBlightDamage(target)
      else
         dam = getBlightDamage(target)
      end
      return dam
   end,

   chargeTimeout=4
} 
spells["quiver"] = {
   base={10,14,18,22,26}, 
   ap=.25
} 
spells["blight"] = {
   base=0,
   targetMaxHealth={.02,.0275,.035,.0425,.05},
   targetMaxHealthAP={.0002}
} 
spells["hail"] = {
   key="E", 
   range=925, 
   color=yellow, 
   base={65,100,135,170,205}, 
   adBonus=.6,
   type="P",
   delay=7.2-2, -- tests at 7.2 for VarusECircleGreen
   speed=0, -- tests at 0
   radius=275,  -- tested visusally
   cost=80,
   damOnTarget=getBlightDamage
} 
spells["chain"] = {
   key="R", 
   range=1075, 
   color=red, 
   base={150,250,350}, 
   ap=1,
   delay=2,  -- TODO test
   speed=20,  -- wiki number
   width=120, -- TODO test
   chainRadius=550,
   cost={10,20,30,40,50},
   damOnTarget=getBlightDamage
} 
spells["maxArrow"] = copy(spells["arrow"])
spells["maxArrow"].range = spells["arrow"].maxRange
spells["maxArrow"].base = spells["arrow"].maxBase
spells["maxArrow"].ad = spells["arrow"].maxAd

spells["AA"].damOnTarget = 
   function(target)
      return 0
   end


local chargeStartTime = 0

function Run()
   P.markedTarget = nil

   if P.charging then      
      local chargeDuration = math.min(time() - chargeStartTime, spells["arrow"].chargeTime)

      local chargeRatio = chargeDuration/spells["arrow"].chargeTime

      local addRange = spells["arrow"].maxRange - spells["arrow"].baseRange
      addRange = addRange * chargeRatio
      spells["arrow"].range = spells["arrow"].baseRange + addRange - spells["arrow"].overShoot -- lead a bit
      
      local addBase = GetLVal(spells["arrow"], "maxBase") - GetLVal(spells["arrow"], "baseBase")
      addBase = addBase * chargeRatio
      spells["arrow"].base = GetLVal(spells["arrow"], "baseBase") + addBase

      local addAd = spells["arrow"].maxAd - spells["arrow"].baseAd
      addAd = addAd * chargeRatio
      spells["arrow"].ad = GetLVal(spells["arrow"], "baseAd") + addAd
   else
      spells["arrow"].range = spells["arrow"].baseRange
      spells["arrow"].base = GetLVal(spells["arrow"], "baseBase")
      spells["arrow"].ad = spells["arrow"].baseAd
   end

   spells["AA"].bonus = GetSpellDamage("quiver")

   if StartTickActions() then
      return true
   end

   if P.charging then
      local chargingTime = time() - chargeStartTime
      local chargeTimeLeft = spells["arrow"].chargeTimeout - chargingTime
      -- All I can do in here is move and check for release targets.

      -- check for kills
      -- check for max stack blight
      -- check for weak enemies

      local kills = GetKills("maxArrow", ENEMIES)
      for _,kill in ipairs(kills) do
         if GetDistance(kill) < GetSpellRange("arrow") - spells["arrow"].overShoot and
            IsGoodFireahead("arrow", kill) 
         then
            FinishArrow(GetSpellFireahead("arrow", kill))
            PrintAction("Arrow for kill on", kill)
            return true
         end
      end
      if #kills > 0 and chargeTimeLeft > .5 then
         return false -- you've got a kill in sights, hold... hold...
      end

      local targets = GetInRange(me, "maxArrow", ENEMIES)
      local haveBlights = false
      for _,target in ipairs(targets) do
         if getBlightStacks(target) == 3 then
            haveBlights = true
            if GetDistance(target) < GetSpellRange("arrow") - spells["arrow"].overShoot  and
               IsGoodFireahead("arrow", target) 
            then
               FinishArrow(GetSpellFireahead("arrow", target))
               PrintAction("Arrow for blights", target)
               PersistTemp("blighting", .75)
               return true
            end
         end
      end

      if haveBlights and chargeTimeLeft > .5 then
         return false  -- you've got a blighted target in sights, hold... hold...
      end

      local target = GetWeakest("maxArrow", GetGoodFireaheads("maxArrow", nil, ENEMIES))
      if target and 
         GetDistance(target) < GetSpellRange("arrow") - 75 and 
         chargingTime > spells["arrow"].chargeTime 
      then
         FinishArrow(GetSpellFireahead("arrow", target))
         PrintAction("Arrow for damage", target)
         return true
      end      

      if #GetInRange(me, GetSpellRange("maxArrow")*1.1, ENEMIES) == 0 
         or chargeTimeLeft < .5
      then
         local _,_,maxScore = GetBestLine(me, "maxArrow", .1, 1, MINIONS)
         local hits,kills,score = GetBestLine(me, "arrow", .1, 1, MINIONS)
         if score >= maxScore and score > 1 then
            AddWillKill(kills, "arrow")
            FinishArrow(GetAngularCenter(hits))
            PrintAction("arrow lh", score)
            -- PauseToggle("lasthit", .5)
            return true
         end
      end

      AutoMove()
      return true
   end

   if not CanUse("arrow") then
      ClearQ()
   end

   -- auto stuff that always happen

   if CanUse("chain") then
      local targets = SortByDistance(GetInRange(me, "chain", ENEMIES))
      local bestT
      local bestTs = {}
      for _,target in ipairs(targets) do
         local ts = GetInRange(me, spells["chain"].chainRadius-50, ENEMIES)
         if #ts > 1 and #ts > #bestTs then
            bestT = target
            bestTs = ts
         end
      end
      if bestTs then
         for _,target in ipairs(bestTs) do
            LineBetween(me, target, 5)
         end
      end
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
         if KillMinionsInArea("hail") then
            -- PauseToggle("lasthit", .75)
            return true
         end
      end

      if VeryAlone() then
         if CanUse("arrow") and not P.charging then
            local hits, kills, score = GetBestLine(me, "maxArrow", .1, 1, MINIONS, ENEMIES)
            if score > GetThreshMP("arrow", .1, 1.5) then
               StartArrow()
               PrintAction("Starting arrow for LH", #kills)
               --PauseToggle("lasthit", .75)
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
   -- TestSkillShot("hail", "VarusECircleGreen")
   -- TestSkillShot("arrow", "VarusQ_mis")
   -- TestSkillShot("chain") -- not done

-- ?   if CanUse("chain")

   if CanUse("hail") then
      local targets = SortByHealth(GetInRange(me, "hail", ENEMIES), "hail")
      if GetSpellLevel("blight") == 0 then
         if SkillShot("hail") then
            PrintAction("Hail for damage")
            return true
         end
      end
      for _,target in ipairs(targets) do
         if getBlightStacks(target) == 3 or WillKill("hail", target) then
            CastFireahead("hail", target)
            PrintAction("Hail for kill or blights", target)
            PersistTemp("blighting", .75)
            return true
         end
      end
   end

   if CanUse("arrow") and not P.charging then
      local enemies = SortByDistance(GetInRange(me, "maxArrow", ENEMIES))
      if not P.blighting then
         for _,enemy in ipairs(enemies) do
            if getBlightStacks(enemy) == 3 then -- TODO add some more reasons to start arrows
               StartArrow()
               PrintAction("Start arrow for blight finish")
               return true
            end
         end
      end

      local target = GetWeakestEnemy("maxArrow")
      if target and WillKill("maxArrow", target) and
         ( GetDistance(target) > GetAARange() or not WillKill("AA", target) )
      then
         StartArrow()
         PrintAction("Start arrow for execute")
         return true
      end

      if #enemies > 0 and GetDistance(enemies[1]) > GetSpellRange("arrow") then
         local target = GetWeakestEnemy("maxArrow")
         if target and GetMPerc(me) > .5 then
            StartArrow()
            PrintAction("Start arrow for poke")
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

function StartArrow(timeout)
   if IsLoLActive() and IsChatOpen() == 0 then
      if CanUse("arrow") and not P.charging then
         send.key_down(SKeys.Q)
         PersistTemp("charging", .25)
         chargeStartTime = time()
         if timeout then
            DoIn(function() FinishArrow(mousePos) end, timeout)
         end
      end
   end
end

local sx, sy
function FinishArrow(t)
   if IsLoLActive() and IsChatOpen() == 0 and P.charging then      
      if sx == nil then
         sx = GetCursorX()
         sy = GetCursorY()
      end
      ClickSpellXYZ("Q", t.x, t.y, t.z, 0)
      send.key_up(SKeys.Q)
      DoIn(
         function() 
            if sx then 
               send.mouse_move(sx, sy) 
               P.markedTarget = nil
               sx = nil
               sy = nil
            end
         end, 
         .1
      )
   end
end

function ClearQ()
   send.key_up(SKeys.Q)
end

local function onCreate(object)
   PersistOnTargets("blight1", object, "VarusW_counter_01", MINIONS, ENEMIES, CREEPS)
   PersistOnTargets("blight2", object, "VarusW_counter_02", MINIONS, ENEMIES, CREEPS)
   PersistOnTargets("blight3", object, "VarusW_counter_03", MINIONS, ENEMIES, CREEPS)

   if Persist("charging", object, "VarusQChannel") then
      chargeStartTime = time()
   end

end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")

