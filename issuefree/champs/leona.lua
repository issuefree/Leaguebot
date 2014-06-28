require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Leona")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})

spells["shield"] = {
   key="Q", 
   base={40,70,100,130,160}, 
   ap=.3,
   type="M",
   cost={45,50,55,60,65}
} 
spells["eclipse"] = {
   key="W", 
   base={60,110,160,210,260}, 
   ap=.4,
   type="M",
   cost=60
} 
spells["blade"] = {
   key="E", 
   range=700, 
   color=violet, 
   base={60,100,140,180,220}, 
   ap=.7,
   type="M",
   delay=2,
   speed=20,
   width=100,
   noblock=true,
   showFireahead=true,
   cost=60
} 
spells["flare"] = {
   key="R", 
   range=1200, 
   color=red, 
   base={150,250,350}, 
   ap=.8,
   type="M",
   radius=250,
   cost={100,150,200}
} 


function Run()
   if P.shield then
      PrintState(0, "shield")
   end
   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen

   -- turn on eclipse and shield when blade hits



   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() then
      UseItems()
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important
   if IsOn("lasthit") then
      if Alone() then
         if GetMPerc(me) > .5 then
            if ModAAFarm("shield", P.shield) then
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

   if AutoAA("shield") then
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
   PersistBuff("shield", object, "Leona_ShieldOfDaybreak")
   if find(object.charName, "Leona_ZenithBlade_arrive") then
      if CanUse("eclipse") then
         Cast("eclipse", me)
         PrintAction("Zenith -> Eclipse")
      end
      if CanUse("shield") then
         DoIn(
            function() 
               Cast("shield", me)
               PrintAction("Zenith -> Shield")
            end,
            .15
         )
      end
      PrintAction("Zenith lands")
   end
end

local function onSpell(unit, spell)
   if IAttack(unit, spell) then

      -- if w and CanUse("shield") then
      --    Cast("shield", me)
      --    DoIn(function() ClickSpellXYZ("M", w.x, w.y, w.z, 0) end, .1)
      -- end
   end
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")