require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Renekton")

InitAAData({ 
   windup=.2,
   resets = {me.SpellNameQ, me.SpellNameW, me.SpellNameE}
})

SetChampStyle("bruiser")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} /  {1}", args={GetAADamage, "cull"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["cull"] = {
   key="Q", 
   range=225+80, 
   color=yellow, 
   base={60,90,120,150,180}, 
   adBonus=.8,
   type="P",
   scale=function() if GetMPerc(me) >= .5 then return 1.5 end end
} 
spells["predator"] = {
   key="W", 
   base={10,30,50,70,90}, 
   ad=.5,
   type="P",
   modAA="predator",
   object="Renekton_Weapon_Hot.troy",
   range=GetAARange,   
   scale=function() if GetMPerc(me) >= .5 then return 1.5 end end
} 
spells["slice"] = {
   key="E", 
   range=450, 
   color=violet, 
   base={30,60,90,120,150}, 
   ad=.9,
   type="P",
   delay=2,
   speed=12,
   width=75,
   scale=function() if GetMPerc(me) >= .5 then return 1.5 end end
} 
spells["dominus"] = {
   key="R", 
} 

function Run()

   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen
   if CheckDisrupt("predator") then
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
         if KillMinionsInPB("cull", 2) then
            return true
         end
      end

      if VeryAlone() then
         if GetMPerc(me) < .5 then
            if ModAAFarm("predator") then
               return true
            end
         end
      end

      -- if VeryAlone() then
      --    if KillMinionsInLine("slice", 3) then
      --       return true
      --    end
      -- end

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
   if CanUse("cull") then
      if #GetInRange(me, "cull", ENEMIES) > 0 then
         Cast("cull", me)
         PrintAction("Cull the meek")
         return true
      end
   end

   if CanUse("slice") then
      local target = GetMarkedTarget() or GetWeakestEnemy("slice")
      if target and not IsInAARange(target) and IsInRange("slice", target) then
         CastXYZ("slice", target)
         PrintAction("Slice", target)
         return true
      end
   end

   local target = GetMarkedTarget() or GetMeleeTarget()
   if AutoAA(target, "predator") then
      return true
   end

   return false
end
function FollowUp()
   return false
end

function AutoJungle()
   local creeps = GetInRange(me, "cull", CREEPS)
   if #creeps > 0 then
      Cast("cull", me)
      PrintAction("Cull (jungle)")
      return true
   end

   if ModAAJungle("predator") then
      return true
   end
end   
SetAutoJungle(AutoJungle)

local function onCreate(object)
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")

