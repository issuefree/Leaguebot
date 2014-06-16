require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Jinx")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})

spells["switch"] = {
   key="Q",
   launcherRange={75,100,125,150,175}
} 
spells["zap"] = {
   key="W", 
   range=1500, 
   color=violet, 
   base={10,60,110,160,210},
   ad=1.4,
   delay=6.5,
   speed=24,
   width=80,
   cost={50,60,70,80,90},
   type="P"
} 
spells["chompers"] = {
   key="E", 
   range=900, 
   color=yellow, 
   base={80,135,190,245,300},
   ap=1,
   delay=4,
   speed=30,
   width=80,
   noblock=true,
   cost=50
} 
spells["rocket"] = {
   key="R",
   base={125,175,225},
   ap=.7,
   delay=2,
   speed=20,
   width=150,
   cost=100,
   type="P"
} 

local minigun = true
local launcherRange = 0

function Run()

   launcherRange = me.range + GetLVal(spells["switch"], "launcherRange")

   if me.range == 525 then
      minigun = true
      spells["AA"].ad = 1
   else
      minigun = false
      spells["AA"].ad = 1.1
   end

   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() then
      UseItems()
		if Action() then
			return true
		end
	end

   -- if VeryAlone() and minigun then
   --    local minions = GetInRange(me, launcherRange+250, MINIONS)
   --    for _,minion in ipairs(minions) do
   --       local kills = GetKills("AA", GetInRange(minion, spells["switch"].launchRadius, MINIONS))
   --       if #kills >= 2 then
   --          Cast("switch", me)
   --          PrintAction("Switch for AOE minions")
   --          return true
   --       end
   --    end
   -- end

	-- auto stuff that should happen if you didn't do something more important

   -- low priority hotkey actions, e.g. killing minions, moving
   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()

   if CanUse("zap") then
      if SkillShot("zap") then
         return true
      end
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AA(target) then
      PrintAction("AA", target)
      return true
   end

   return false
end
function FollowUp()
   if IsOn("lasthit") and Alone() then
      if KillMinion("AA") then
         return true
      end
   end

   if IsOn("clear") and Alone() then
      if HitMinion("AA", "strong") then
         return true
      end
   end

   return false
end

local function onObject(object)
end

local function onSpell(unit, spell)
   if IAttack(unit, spell) then
      -- if #GetAllInRange(spell.target, 150, MINIONS, ENEMIES, CREEPS) > 1 then
      --    if minigun then
      --       Cast("switch", me)
      --    end
      -- else
      --    if not minigun then
      --       Cast("switch", me)
      --    end
      -- end
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")

