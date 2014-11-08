require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Malzahar")

InitAAData({ 
   projSpeed = 1.5, windup=.4,
   extraRange=-10,
   particles = {"AlzaharBasicAttack_mis"}
})

SetChampStyle("caster")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["void"] = {
   key="Q", 
   range=900, 
   color=violet, 
   base={80,135,190,245,300}, 
   ap=.8,
   delay=8-3, -- testskillshot
   speed=0,
   width=400,
   noblock=true
} 
spells["zone"] = {
   key="W", 
   range=800, 
   color=yellow, 
   base={0},   
   targetMaxHealth={.2,.25,.3,.35,.4},
   targetMaxHealthAP=.0005,
   delay=1,
   speed=0,
   radius=250, -- reticle
   noblock=true
} 
spells["visions"] = {
   key="E",
   range=650, 
   color=blue, 
   base={80,140,200,260,320}, 
   ap=.8,
} 
spells["grasp"] = {
   key="R", 
   range=700, 
   color=red, 
   base={250,400,550}, 
   ap=1.3,
   channel=true,
   name="AlzaharNetherGrasp",
   object="AlZaharNetherGrasp_tar.troy",
   channelTime=2.5
} 

function Run()
   if StartTickActions() then
      return true
   end


   -- auto stuff that always happen
   if CheckDisrupt("void") then
      return true
   end

   if CastAtCC("zone") or
      CastAtCC("void")
   then
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
      if KillMinion("visions", "strong") then
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
   -- TestSkillShot("void", "AlzaharCall")
   -- TestSkillShot("zone", "AlzaharNullZone")

   if CastBest("visions") then
      return true
   end

   if SkillShot("void") then
      return true
   end

   local targets = SortByHealth(GetInRange(me, "grasp", ENEMIES))
   for _,target in ipairs(targets) do
      if WillKill("visions", "zone", "grasp", target) then
         MarkTarget(target)
         Cast("zone", target)
         PrintAction("Zone for execute")
         break
      end
   end

   if CanUse("grasp") then
      local target = GetMarkedTarget()
      if target then
         Cast("grasp", target)
         PrintAction("Grasp marked", target)
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

local function onCreate(object)
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")

