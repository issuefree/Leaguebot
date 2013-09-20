require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Heimerdinger")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["aura"] = {
  range=800, 
  color=green
}
spells["turret"] = {
  key="Q", 
  range=250,
  turretRange=525,
  color=yellow,
  cost={70,80,90,100,110}
}
spells["rockets"] = {
  key="W", 
  range=1000, 
  color=violet, 
  base={85,135,185,235,285}, 
  ap=.55,
  cost={65,85,105,125,145}
}
spells["grenade"] = {
  key="E", 
  range=925, 
  color=blue, 
  base={80,135,190,245,300}, 
  ap=.6,
  delay=2.5,
  speed=7.5,
  radius=250,
  cost={80,90,100,110,120}
}
spells["upgrade"] = {
  key="R", 
  cost=90
}

function Run()
   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return true
   end

   if P.upgrade then
      PrintState(1, "UPGRADE")
      spells["grenade"].speed = 10
      numRockets = 5
   else
      spells["grenade"].speed = 7.5
      numRockets = 3
   end

	if HotKey() and CanAct() then
      UseItems()
		if Action() then
			return true
		end
	end

   if IsOn("lasthit") and CanUse("rockets") and VeryAlone() then
      local targets = SortByDistance(GetInRange(me, "rockets", MINIONS))
      if #targets >= 2 and 
         GetSpellDamage("rockets", targets[1]) > targets[1].health and
         GetSpellDamage("rockets", targets[2]) > targets[2].health
      then
         Cast("rockets", me)
         PrintAction("Rockets for lasthit")
         return true
      end
   end

   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end
end

function Action()
   if CanUse("rockets") and CanUse("upgrade") then
      local targets = SortByDistance(GetInRange(me, "rockets", ENEMIES, MINIONS))
      local validEnemies = 0
      for i = 1, 5, 1 do
         local target = targets[i]
         if target and not IsMinion(target) then
            validEnemies = validEnemies + 1
            if validEnemies > 3 then -- upgrade so I can hit more people with rockets
               Cast("upgrade", me)
               PrintAction("UPGRADE!")
            end
         end
      end
   end

   if CanUse("grenade") then
      if IsGoodFireahead("grenade", EADC) then
         CastFireahead("grenade", EADC)
         PrintAction("Grenade ADC", EADC)
         return true
      end
      local targets = SortByHealth(GetInRange(me, "grenade", ENEMIES))
      for _,target in ipairs(targets) do
         if IsGoodFireahead("grenade", target) then
            CastFireahead("grenade", target)
            PrintAction("Fire in the hole", target)
            return true
         end
      end
   end

   if CanUse("rockets") then
      local targets = SortByDistance(GetInRange(me, "rockets", ENEMIES, MINIONS))
      for i = 1, numRockets, 1 do
         local target = targets[i]
         if target and not IsMinion(target) then
            Cast("rockets", me)
            PrintAction("Rockets", target)
            return true
         end
      end
   end

   return false
end

function FollowUp()
   if IsOn("lasthit") and Alone() then
      if KillWeakMinion("AA") then
         PrintAction("AA lasthit")
         return true
      end
   end

   if IsOn("clearminions") and Alone() then
      -- hit the highest health minion
      local minions = SortByHealth(GetInRange(me, "AA", MINIONS))
      if AA(minions[#minions]) then
         PrintAction("AA clear minions")
         return true
      end
   end

   return false
end

local function onObject(object)
   PersistBuff("upgrade", object, "HolyFervor_buf")
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
