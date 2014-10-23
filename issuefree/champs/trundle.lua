require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Trundle")

InitAAData({ 
   windup=.25,
   -- particles = {"Trundle_Attack"},
   resets={me.SpellNameQ}
})

SetChampStyle("bruiser")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["tribute"] = {
   range=1000,
   color=green
}
spells["chomp"] = {
   key="Q", 
   color=violet, 
   base={20,40,60,80,100}, 
   ad={0,.05,.1,.15,.2},
   modAA="chomp",
   object="Trundle_Q_TrollSmash_buf.troy",
   range=GetAARange(), -- TODO
   type="P"
} 
spells["domain"] = {
   key="W", 
   range=825, 
   color=blue, 
   radius=800,  -- reticle
} 
spells["pillar"] = {
   key="E", 
   range=1000, 
   color=yellow, 
   radius=350, -- reticle
}
spells["subjugate"] = {
   key="R", 
   range=700, 
   color=red, 
   base=0, 
   targetMaxHealth={.20,.24,.28},
   targetMaxHealthAP=.02,
} 

function Run()
   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen
   if CheckDisrupt("pillar") then
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
         if ModAAFarm("chomp") then
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
   if AutoAA(target, "chomp") then
      return true
   end

   return false
end
function FollowUp()
   return false
end

function AutoJungle()
   if ModAAJungle("chomp") then
      return true
   end

   local creep = GetBiggestCreep(GetInRange(me, "AA", CREEPS))
   local score = ScoreCreeps(creep)
   if AA(creep) then
      PrintAction("AA "..creep.charName)
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

