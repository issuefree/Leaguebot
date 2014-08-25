require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Shaco")

InitAAData({ 
   windup=.25,
   extraRange=-20,
})

-- SetChampStyle("marksman")
-- SetChampStyle("caster")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "shiv"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["deceive"] = {
   key="Q", 
   range=400, 
   color=blue, 
} 
spells["box"] = {
   key="W", 
   range=425, 
   color=yellow, 
   base={35,50,65,80,95}, 
   ap=.2,
   delay=2,
   speed=0,
   radius=300,
} 
spells["shiv"] = {
   key="E", 
   range=625, 
   color=violet, 
   base={50,90,130,170,210}, 
   ap=1,
   adBonus=1,
} 
spells["clone"] = {
   key="R", 
   base={300,450,600}, 
   ap=1,
   radius=250
} 

function Run()
   Circle(P.clone)
   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen
   if CheckDisrupt("box") then
      return true
   end

   AutoPet(P.clone)

   if P.deceive then
      PrintState(0, "Stealth")
      AutoMove()
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
         if KillMinion("shiv") then
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

   local target = GetMarkedTarget() or GetMeleeTarget()
   if AutoAA(target) then
      return true
   end

   return false
end
function FollowUp()
   if IsOn("move") then
      if MeleeMove() then
         return true
      end
   end
   return false
end

local function onCreate(object)
   if object.type == 12 then
      Persist("clone", object, me.charName, me.team)
   end
end

local function onSpell(unit, spell)
   if ICast("deceive", unit, spell) then
      PersistTemp("deceive", 3.5)
   end

   CheckPetTarget(P.clone, unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")

