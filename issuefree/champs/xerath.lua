require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Xerath")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "bolt"}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

local locusRange = 400

spells["bolt"] = {
   key="Q", 
   range=750,
   maxRange=1400,
   color=violet, 
   base={80,120,160,200,240}, 
   ap=.75,
   delay=7,
   speed=0,
   width=75,
   noblock=true,
   cost={80,90,100,110,120}
} 
spells["eye"] = {
   key="W",
   range=1100,
   color="blue",
   base={60,90,120,150,180},
   ap=.6,
   delay=7,
   speed=0,
   radius=200,
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
   radius=200,
   cost=100
} 

function Run()
   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return true
   end

   if IsChannelling() then
      return true
   end

   if CastAtCC("eye") then
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

	-- auto stuff that should happen if you didn't do something more important

   -- if IsOn("lasthit") and CanUse("bolt") then
   --    if VeryAlone() then
   --       if KillMinionsInLine("bolt", 2) then
   --          return true
   --       end
   --    elseif Alone() then
   --       if KillMinionsInLine("bolt", 3) then
   --          return true
   --       end
   --    end
   -- end

   -- low priority hotkey actions, e.g. killing minions, moving
   if HotKey() then
      if FollowUp() then
         return true
      end
   end

   PrintAction()
end

function Action()

   return false
end
function FollowUp()
   if IsOn("lasthit") and Alone() then
      if KillMinion("AA") then
         return true
      end
   end

   if IsOn("clearminions") and Alone() then
      if HitMinion("AA", "strong") then
         return true
      end
   end

   return false
end

local function onObject(object)
end

local function onSpell(unit, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")


function Run()
