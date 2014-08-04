require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Corki")

SetChampStyle("marksman")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("tear", {on=true, key=115, label="Tear"})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["bomb"] = {
   key="Q", 
   range=825,
   color=violet,
   base={80,130,180,230,280},
   ap=.5,
   bonusAd=.5,
   delay=1.4,
   speed=11,
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

   color=red, 
   range=600, 
   cone=55,  -- checked through DrawSpellCone aagainst the reticule
   noblock=true,
   
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
   delay=.7,
   speed=20,
   width=80,
   cost=20,
   missileTime={12,10,8},
   name="MissileBarrage"
}

local missiles = 7
local mst = time()
local mCount = 0
local bigOne = false

function Run()
   spells["AA"].bonus = Damage((me.baseDamage+me.addDamage)*.1, "T")

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

   if StartTickActions() then
      return true
   end

   if IsOn("tear") then
      UseItem("Muramana")
   end

   -- auto stuff that always happen

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important
   if IsOn("lasthit") and Alone() then

      if KillMinionsInArea("bomb", 3) then
         return true
      end

      if CanUse("barrage") and VeryAlone() and missiles >= 4 then
         local minion = GetWeakest("barrage", GetUnblocked("barrage", me, MINIONS))
         if WillKill("barrage", minion) and
            GetDistance(minion) > spells["AA"].range
         then
            CastXYZ("barrage", minion)
            PrintAction("Barrage for lasthit")
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
   -- TestSkillShot("bomb", "Q_Mis")
   -- TestSkillShot("barrage")

   if SkillShot("bomb") then
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
   if AutoAA(target) then
      return true
   end

   return false
end

function FollowUp()
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

