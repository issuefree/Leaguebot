require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Xerath")
pp(" - Xerath sucks")

SetChampStyle("caster")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "bolt"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=112, label="Move"})


spells["bolt"] = {
   key="Q", 
   range=750,
   baseRange=750,
   maxRange=1400,
   color=violet, 
   base={80,120,160,200,240}, 
   ap=.75,
   delay=3,
   speed=0,
   width=50,
   noblock=true,
   cost={80,90,100,110,120},
   extraCooldown=.75
} 
spells["eye"] = {
   key="W",
   range=1100,
   color=blue,
   base={60,90,120,150,180},
   ap=.6,
   delay=7,
   speed=0,
   radius=275,
   cost={70,80,90,100,110}
} 
spells["orb"] = {
   key="E", 
   range=1050,
   color=yellow, 
   base={80,110,140,170,200}, 
   ap=.45,
   delay=2,
   speed=14,
   width=90,
   cost={60,65,70,75,80}
} 
spells["rite"] = {
   key="R",
   range={3200,4400,5600},
   color=red,
   base={190,245,300},
   ap=.43,
   delay=5,
   speed=0,
   noblock=true,
   radius=150,
   cost=100,
   baseCost=100
} 

spells["maxBolt"] = copy(spells["bolt"])
spells["maxBolt"].range = spells["maxBolt"].maxRange

local chargeStartTime = 0

local x,y = me.x, me.z

function Run()
   if P.rite then
      PrintState(0, "RITE")
   end

   if P.charging then
      local chargeDuration = math.min(time() - chargeStartTime, 1.5)
      local addRange = spells["bolt"].maxRange - spells["bolt"].baseRange
      addRange = addRange * chargeDuration/1.5
      spells["bolt"].range = spells["bolt"].baseRange + addRange
   else
      spells["bolt"].range = spells["bolt"].baseRange
   end

   if P.rite then
      spells["rite"].cost = 0
   else
      spells["rite"].cost = spells["rite"].baseCost
   end

   if StartTickActions() then
      return true
   end

   if CanUse("rite") then
      local target = GetWeakestEnemy("rite")
      if target then
         if GetSpellDamage("rite", target)*3 > target.health*1.1 then
            LineBetween(me, target, 10)
         end
      end
   end

   if P.rite then
      SkillShot("rite")
      return true
   end

   if P.charging then
      local _,_,maxScore = GetBestLine(me, "maxBolt", 0, 10, ENEMIES)
      local hits,_,score = GetBestLine(me, "bolt", .1, 10, ENEMIES)
      if score >= maxScore and score > 0 then
         local target = GetWeakestEnemy("bolt")
         if target then 
            FinishBolt(GetSpellFireahead("bolt", target))
            PrintAction("bolt", target)
            return true
         end
      end

      if #GetInRange(me, GetSpellRange("maxBolt")*1.1, ENEMIES) == 0 then
         local _,_,maxScore = GetBestLine(me, "maxBolt", .1, 1, MINIONS)
         local hits,_,score = GetBestLine(me, "bolt", .1, 1, MINIONS)
         if score >= maxScore and score > 0 then
            FinishBolt(GetCenter(hits))
            PrintAction("bolt lh", score)
            PauseToggle("lasthit", .5)
            return true
         end
      end

      return true
   end

   -- auto stuff that always happen
   if CheckDisrupt("orb") then
      return true
   end

   if CastAtCC("eye") or
      CastAtCC("orb")
   then
      return true
   end

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() then
      StartBolt(1)      
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important

   if IsOn("lasthit") and not P.rite then
      local killsNeeded = 5
      if GetMPerc(me) > .75 then
         killsNeeded = 2
      elseif GetMPerc(me) > .5 then
         killsNeeded = 3
      elseif GetMPerc(me) > .25 then
         killsNeeded = 4
      end

      if Alone() and CanUse("eye") then
         if KillMinionsInArea("eye", killsNeeded) then
            PauseToggle("lasthit", .75)
            return true
         end
      end

      if Alone() and CanUse("bolt") then
         local _,_,maxScore = GetBestLine(me, "maxBolt", .1, 1, MINIONS)

         if not P.charging then
            if maxScore >= killsNeeded then
               StartBolt()
               return true
            end
         end
      end

   end

   -- low priority hotkey actions, e.g. killing minions, moving
   if HotKey() then
      if FollowUp() then
         return true
      end
   end

   P.markedTarget = nil
   EndTickActions()
end

function Action()
   if CanUse("bolt") and not P.charging then

      local _,_,maxScore = GetBestLine(me, "maxBolt", 1, 10, ENEMIES)
      if maxScore >= 1 then
         StartBolt()
         return true
      end
   end

   if SkillShot("eye") then
      return true
   end

   return false
end

function FollowUp()

   return false
end

function StartBolt(timeout)
   if IsLoLActive() and IsChatOpen() == 0 then
      if CanUse("bolt") and not P.charging then
         pp(me.SpellTimeQ)
         send.key_down(SKeys.Q)
         PrintAction("Start Bolt")
         PersistTemp("charging", .25)

         if timeout then
            DoIn(function() FinishBolt(mousePos) end, timeout)
         end
      end
   end
end

local sx, sy
function FinishBolt(t)
   pp(debug.traceback())
   if IsLoLActive() and IsChatOpen() == 0 and P.charging then      
      if sx == nil then
         sx = GetCursorX()
         sy = GetCursorY()
      end
      ClickSpellXYZ("Q", t.x, t.y, t.z, 0)
      PrintAction("Finish Bolt")
      send.key_up(SKeys.Q)
      DoIn(
         function() 
            if sx then 
               send.mouse_move(sx, sy) 
               sx = nil
               sy = nil
            end
         end, 
         .1 
      )
   end
end


local function onObject(object)
   if Persist("charging", object, "Xerath_Base_Q_cas_charge") then
      chargeStartTime = time()
   end

   Persist("rite", object, "Xerath_Base_R_buf")
end

local function onSpell(unit, spell)
   if IsMe(unit) and spell.name == "xeratharcanopulse2" then
      P.charging = nil
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
