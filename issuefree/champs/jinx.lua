require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Jinx")

SetChampStyle("marksman")

InitAAData({ 
   speed = 2400, windup=.2,
   particles = {"Jinx_Q_Minigun_mis", "Jinx_Q_Rocket_mis"}
})

AddToggle("switch", {on=true, key=112, label="Auto Switch"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["switch"] = {
   key="Q",
   ad=.1,
   radius=150,
   baseRange=525,
   range={75,100,125,150,175}
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
local baseRange = 0

function Run()
   if me.range <= 525 then
      minigun = true
      spells["AA"].ad = 1
   else
      minigun = false
      spells["AA"].ad = 1.1
   end

   if minigun then
      launcherRange = GetAARange() + GetSpellRange("switch")
      baseRange = GetAARange()
   else
      launcherRange = GetAARange()
      baseRange = GetAARange() - GetSpellRange("switch")
   end


   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() then
		if Action() then
			return true
		end
	end

   if IsOn("switch") and Alone() and CanUse("switch") then
      if minigun then
         if #GetKills("AA", GetInRange(me, "AA", MINIONS)) == 0 then
            local minions = FilterList(GetInE2ERange(me, launcherRange, MINIONS), function(m) return not IsInAARange(m) end)
            for _,minion in ipairs(minions) do
               if WillKill("AA", "switch", minion) then
                  Cast("switch", me)
                  PrintAction("Rockets - long range LH")
                  return true
               end
            end
         end         

         local minions = GetInRange(me, launcherRange+spells["switch"].radius, MINIONS)
         for _,minion in ipairs(minions) do
            local kills = GetKills("AA", GetInRange(minion, spells["switch"].radius, MINIONS))
            if #kills >= 2 then
               Cast("switch", me)
               PrintAction("Rockets - AoE LH")
               return true
            end
         end      
      elseif not IsOn("clear") then
         Cast("switch", me)
         PrintAction("Switch back to minigun")
         return true
      end
   end

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

   if not GetWeakestEnemy("AA") then
      if SkillShot("zap") then
         return true
      end
   end

   if IsOn("switch") and CanUse("switch") then
      local target
      if minigun then
         target = GetMarkedTarget() or GetWeakestEnemy("AA", GetSpellRange("switch"))
      else
         target = GetMarkedTarget() or GetWeakestEnemy("AA")
      end

      if target and GetDistance(target) > baseRange+50 and minigun then
         Cast("switch", me)
         PrintAction("Rockets - long range AA")
         return true
      elseif target and #GetInRange(target, spells["switch"].radius, ENEMIES) >= 3 and minigun then
         Cast("switch", me)
         PrintAction("Rockets - AoE AA")
         return true
      elseif not minigun and target and GetDistance(target) < baseRange-50 then
         Cast("switch", me)
         PrintAction("Minigun - single target RoF")
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
   return false
end

local function onObject(object)

end

local function onSpell(unit, spell)
   if IAttack(unit, spell) then
      -- if #GetInRange(spell.target, 150, MINIONS, ENEMIES, CREEPS) > 1 then
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

