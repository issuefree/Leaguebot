require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Galio")

InitAAData({ 
   windup=.25,
   -- extraRange=-20,
})

-- SetChampStyle("marksman")
-- SetChampStyle("caster")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1} / {2}", args={GetAADamage, "smite", "gust"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["smite"] = {
   key="Q", 
   range=940, 
   color=violet, 
   base={80,135,190,245,300}, 
   ap=.6,
   delay=2.6, -- TestSkillShot
   speed=12.5, 
   noblock=true,
   radius=215, -- reticle
} 
spells["bulwark"] = {
   key="W", 
   range=800, 
   color=yellow, 
} 
spells["gust"] = {
   key="E", 
   range=1175, 
   color=blue, 
   base={60,105,150,195,240}, 
   ap=.5,
   delay=2.4, -- TestSkillShot
   speed=12.5, 
   width=125, -- reticle
} 
spells["idol"] = {
   key="R",
   range=600,
   color=red,
   base={220,330,440},
   ap=.6,
   channel=true,
   name="GalioIdolOfDurand",
   object="galio_talion_channel.troy"
} 

function Run()
   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen
   if CastAtCC("smite") or
      CastAtCC("gust")
   then
      return true
   end

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() then
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important
   if IsOn("lasthit") then
      if Alone() then
         if KillMinionsInArea("smite") then
            return true
         end

         if KillMinionsInLine("gust") then
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
   -- TestSkillShot("gust", nil, {"Launcher"})
   if SkillShot("smite") then
      return true
   end

   if SkillShot("gust") then
      return true
   end

   local target = GetMarkedTarget() or GetMeleeTarget()
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
   if ICast("idol", unit, spell) then
      if #GetInRange(me, "idol", ENEMIES, MINIONS) > 0 then
         Cast("bulwark", me)
         PrintAction("Bulwark for taunt")
         return true
      end
   end

   if GetHPerc(me) < .75 then
      CheckShield("bulwark", unit, spell)
   end
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")

