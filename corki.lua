require "timCommon"
require "modules"

pp("\nTim's Corki")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["phos"] = {
   key="Q", 
   range=825,
   color=violet,
   base={80,130,180,230,280},
   ap=.5,
   delay=2,
   speed=20,
   radius=300,
   cost={60,70,80,90,100},
   noblock=true
}
spells["valk"] = {
   key="W", 
   range=800, 
   color=yellow, 
   base={150,225,300,375,450}, 
   ap=1,
   delay=2,
   speed=12,
   width=200,
   cost=50,
   noblock=true
}
spells["gun"] = {
   key="E", 
   range=600, 
   color=red, 
   base={20,32,44,56,68}, 
   bonusAd=.4,
   cost=50
}
spells["barrage"] = {
   key="R", 
   range=1225,
   color=violet,
   base={100,180,260}, 
   ap=.3,
   ad={.2,.3,.4},
   delay=1.5,
   speed=19,
   width=80,
   cost={30,35,40},
   missileTime={12,10,8},
   name="MissileBarrage"
}

local missiles = 7
local mst = time()
local mCount = 0
local bigOne = false

function Run()
   spells["AA"].bonus = Damage(GetSpellDamage("AA")*.1, "T")

   local lvl = GetSpellLevel("R")
   if lvl > 0 then
      if me.dead == 1 then
         missiles = 4
         mst = time()
      end
      if missiles == 7 then
         mst = time()
      else
         local mTime = spells["barrage"].missileTime[lvl] * (1+me.cdr)
         if time() - mst > mTime then
            mst = time()
            missiles = missiles + 1
         end
      end
      if mCount == 2 then
         bigOne = true
      end
   end
   if bigOne then
      PrintState(1, "BIGONE")
   end

   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return true
   end

   -- auto stuff that always happen

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
      UseItems()
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important
   if IsOn("lasthit") and Alone() then

      if KillMinionsInArea("phos", 3) then
         return true
      end

      if CanUse("barrage") and VeryAlone() and missiles >= 4 then
         for _,minion in ipairs(SortByHealth(GetUnblocked(me, "barrage", MINIONS))) do
            if WillKill("barrage", minion) and
               GetDistance(minion) > spells["AA"].range
            then
               CastXYZ("barrage", minion)
               PrintAction("Barrage for lasthit")
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

   PrintAction()
end

function Action()
   if SkillShot("phos") then
      return true
   end

   if CanUse("barrage") then
      if JustAttacked() or not GetWeakestEnemy("AA") then
         if SkillShot("barrage") then
            return true
         end
      end
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AA(target) then
      PrintAction("AA", target)
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

   if IsOn("move") then
      if RangedMove() then
         return true
      end
   end

   return false
end

local function onObject(object)
end

local function onSpell(unit, spell)
   if ICast("barrage", unit, spell) then
      missiles = missiles - 1
      mCount = mCount + 1
   end
   if ICast("MissileBarrageMissile2", unit, spell) then
      mCount = 0
      bigOne = false
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")

