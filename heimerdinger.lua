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
  range=1100, 
  color=green
}
spells["turret"] = {
  key="Q", 
  range=450,
  turretRange=525,
  color=yellow,
  cost=20
}
spells["rockets"] = {
  key="W", 
  range=1200, 
  color=violet, 
  base={60,90,120,150,180}, 
  ap=.45,
  delay=1,
  speed=40,
  width=50,
  overShoot=-75,
  cost={70,80,90,100,110}
}
spells["grenade"] = {
  key="E", 
  range=925, 
  color=blue, 
  base={60,100,140,180,220}, 
  ap=.6,
  delay=2.5,
  speed=12,
  noblock=true,
  radius=210,
  radiusBase=210,
  radiusUp=420,
  cost=85
}
spells["upgrade"] = {
  key="R", 
  cost=100
}

function Run()
   local sentries = GetPersisted("sentry")

   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return true
   end

   if P.upgrade then
      PrintState(1, "UPGRADE")
      spells["rockets"].noblock = true
      spells["grenade"].radius = spells["grenade"].radiusUp
   else
      spells["rockets"].noblock = false
      spells["grenade"].radius = spells["grenade"].radiusBase
   end

	if HotKey() then
      UseItems()
		if Action() then
			return true
		end
	end

   -- if IsOn("lasthit") and CanUse("rockets") and VeryAlone() then
   --    local targets = SortByDistance(GetInRange(me, "rockets", MINIONS))
   --    if #targets >= 2 and 
   --       WillKill("rockets", targets[1]) and
   --       WillKill("rockets", targets[2])
   --    then
   --       Cast("rockets", me)
   --       PrintAction("Rockets for lasthit")
   --       return true
   --    end
   -- end

   if HotKey() then
      if FollowUp() then
         return true
      end
   end
end

function Action()
   if CanUse("upgrade") or P.upgrade then

      if CanUse("grenade") then
         spells["grenade"].radius = spells["grenade"].radiusUp
         local hits = GetBestArea(me, "grenade", 1, 0, GetFireaheads("grenade", ENEMIES))
         if #hits >= 2 then
            if not P.upgrade then
               Cast("upgrade", me)
            end
            CastXYZ("grenade", GetCenter(hits))
            PrintAction("Grenade (UPGRADE)", #hits)
            return true
         end
      end

      if CanUse("rockets") then
         spells["rockets"].noblock = true
         local target = GetSkillShot("rockets")
         if target then
            if not P.upgrade then
               Cast("upgrade", me)
            end
            CastFireahead("rockets", target)
            PrintAction("Rockets (UPGRADE)", target)
            return true
         end
      end

   end
   if P.upgrade then
      PrintState(1, "UPGRADE")
      spells["rockets"].noblock = true
      spells["grenade"].radius = spells["grenade"].radiusUp
   else
      spells["rockets"].noblock = false
      spells["grenade"].radius = spells["grenade"].radiusBase
   end

   if SkillShot("grenade") then
      return true
   end
   if SkillShot("rockets") then
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
   PersistAll("sentry", object, "H-28G Evolution Turret")
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
