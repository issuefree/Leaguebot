require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Draven")

SetChampStyle("marksman")

InitAAData({
  projSpeed = 1.4, windup=.2,
  particles = {"Draven_Base_BA", "Draven_Base_Q_mis"} -- "Draven_BasicAttack_mis","Draven_Q_mis", "Draven_Q_mis_bloodless", "Draven_Q_mis_shadow", "Draven_Q_mis_shadow_bloodless", "Draven_Qcrit_mis", "Draven_Qcrit_mis_bloodless", "Draven_Qcrit_mis_shadow", "Draven_Qcrit_mis_shadow_bloodless", "Draven_BasicAttack_mis_shadow", "Draven_BasicAttack_mis_shadow_bloodless", "Draven_BasicAttack_mis_bloodless", "Draven_crit_mis", "Draven_crit_mis_shadow_bloodless", "Draven_crit_mis_bloodless", "Draven_crit_mis_shadow", "Draven_Q_mis", "Draven_Qcrit_mis"
})

AddToggle("catch", {on=true, key=112, label="Catch Axes"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["axe"] = {
   key="Q",
   base=0,
   ad={.45,.55,.65,.75,.85},
   type="P",
   duration=6
}
spells["rush"] = {
   key="W",
}
spells["standaside"] = {
   key="E", 
   range=1050, 
   color=violet, 
   base={70,105,140,175,210}, 
   adBonus=.5,
   type="P",
   delay=2.4, --TestSkillShot
   speed=14, 
   width=135,
   noblock=true,
   overShoot=100
}
spells["death"] = {
    key="R",
    range=99000,
    base={175,275,375},
    adBonus=1.1,
    type="P",
    delay=8, -- ?
    speed=30, -- ?
    width=175,
}

local spinStart = 0
local spinStop = 0
local spinning = false

local axeCatchRange = 115
local axes = {}

function canAxe()
   local axeThresh 
   if GetMPerc(me) > .75 then
      axeThresh = 1.5
   elseif GetMPerc(me) > .5 then
      axeThresh = 1.75
   else
      axeThresh = 2
   end
   return not spinning and time() - spinStop > axeThresh and #GetPersisted("axe") < 2 and CanAttack()
end

function Run()
   if HasBuff("spinning", me) then
      spinning = true
   else
      if spinning then
         spinStop = time()
      end
      spinning = false
   end
   spells["AA"].bonus = 0
   if spinning then
      spells["AA"].bonus = GetSpellDamage("axe")
   end

   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen
   if CheckDisrupt("standaside") then
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
      if CanUse("axe") and canAxe() and 
         #GetInRange(me, "AA", MINIONS, PETS) >= GetThreshMP("axe", .05, 1.5)
      then
         Cast("axe", me)
         PrintAction("Axe for lasthitting")
         return true
      end
   end

   -- axe about to run out. hit something
   if time() - spinStart < 6 and time() - spinStart > 5.25 then
      local target = SortByDistance(GetInRange(me, "AA", MINIONS, CREEPS, PETS))[1]
      if AA(target) then
         PrintAction("Axe for refresh")
         return true
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
   -- TestSkillShot("standaside")
   -- TestSkillShot("death")
   if CanUse("rush") then      
      if not P.rushingM then
         -- gap close
         local target = GetMarkedTarget() or GetWeakestEnemy("AA", 100)
         if target and not IsInAARange(target) and IsInAARange(target, me, 100) then
            Cast("rush", me)
            PrintAction("Rush to close gap", target)
            return true
         end
      end

      if not P.rushingA then
         -- aa boost
         local target = GetWeakestEnemy("AA", -50)
         if target then
            Cast("rush", me)
            PrintAction("Rush for AA", target)
            return true
         end
      end
   end

   -- might want this to be double spinning
   if CanUse("axe") and canAxe() then
      local target = GetWeakestEnemy("AA", -50)
      if target then
         Cast("axe", me)
         PrintAction("Axe for AA", target)
         return true
      end
   end

   if CanUse("standaside") then
      local target = GetMarkedTarget() or GetWeakestEnemy("standaside")
      if target and not IsInAARange(target) and IsInRange("standaside", target) then
         CastFireahead("standaside", target)
         PrintAction("Standaside for chase", target)
         return true
      end
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end

   return false
end

function FollowUp()

   if CanUse("death") then
      local targets = SortByDistance(GetKills("death", GetInRange(me, 1500, ENEMIES)))
      for _,target in ipairs(targets) do
         if #GetInRange(target, 750, ALLIES) == 0 then
            CastFireahead("death", target)
            PrintAction("Whirling Death for execute", target)
            return true
         end
      end
   end

   if IsOn("catch") then
      -- lasthit code from endtickactions here because I want to thread lasthits in on the way to catches
      if IsOn("lasthit") and Alone() then
         if KillMinion("AA") then
            return true
         end
      end

      if HotKey() and IsOn("clear") and Alone() then

         if HitMinion("AA", "strong") then
            return true
         end

      end

      local axes = GetPersisted("axe")
      table.sort(axes, function(a,b) return PData["axe"..a.id].time < PData["axe"..b.id].time end)
      local axe = axes[1]
      if axe and CanMove() and GetDistance(axe) > axeCatchRange  then
         local point 
         if CURSOR then
            if GetDistance(axe, CURSOR) > axeCatchRange then
               point = Projection(axe, CURSOR, axeCatchRange)
            end
         else
            point = Point(axe)
         end
         if point then
            Circle(point, nil, red, 5)
            -- if I'm not in range of enemies or the drop point is go ahead and catch
            if #GetInRange(me, "AA", ENEMIES) <= 0 or
               #GetInRange(point, "AA", ENEMIES) > 0
            then
               MoveToXYZ(point:unpack())
               return true
            end
         end
      end
   end
   return false
end

local function onObject(object)
   PersistOnTargets("spinning", object, "Draven_Base_Q_buf.troy", {me})

   if PersistBuff("spinningActivate", object, "Draven_Base_Q_activation.troy") then
      spinStart = time()
   end

   if PersistBuff("spinningActive", object, "Draven_Base_Q_ReticleCatchSuccess.troy") then
      PrintAction("CATCH")
      spinStart = time()
   end

   PersistBuff("rushingM", object, "Draven_Base_W_move_buf.troy")
   PersistBuff("rushingA", object, "Draven_Base_W_attack_buf.troy")
   PersistAll("axe", object, "Draven_Base_Q_reticle_self.troy")   
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
