require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Akali")
pp(" - Mark enemies that have no mark")
pp(" - Slash nearby enemies")
pp(" - Dance to far enemies")
pp(" - Mark for last hit")
pp(" - Slash for last hit >= 2")

SetChampStyle("caster")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1} / {2}", args={GetAADamage, "mark", "slash"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})

spells["mark"] = {
  key="Q",
  range=600,
  color=violet,
  base={35,55,75,95,115},
  ap=.4
  -- cost=60
}
spells["detonate"] = {
   key="Q",
   base={45,70,95,120,145},
   ap=.5
}
spells["shroud"] = {
  key="W", 
  range=700, 
  color=blue, 
  radius=600
  -- cost={80,75,70,65,60}
}
spells["slash"] = {
  key="E", 
  range=325, 
  color=red,
  base={30,55,80,105,130}, 
  ap=.3,
  ad=.6,
  type="P",
  -- cost={60,55,50,45,40},
  damOnTarget=function(target) return getDetonateDam(target) end
}
spells["dance"] = {
  key="R", 
  range=800, 
  color=yellow, 
  base={100,175,250}, 
  ap=.5
}

function getDetonateDam(target)
   if HasBuff("mark", target) then
      return GetSpellDamage("detonate")
   end
   return 0
end

spells["AA"].damOnTarget = 
   function(target)
      return getDetonateDam(target)
   end

function Run()
   for _,t in ipairs(GetWithBuff("mark", MINIONS)) do
      Circle(t)
   end

   spells["AA"].bonus = GetSpellDamage("AA")*(.06+(me.ap/6/100))

   if StartTickActions() then
      return true
   end

	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

   if IsOn("lasthit") and Alone() and CanAct() then
      if KillMinion("mark", "far") then
         return true
      end

      if CanUse("slash") then
         local kills = GetKills("slash", MINIONS)
         if kills >= 2 then
            Cast("slash", me)
            PrintAction("Slash for lasthit")
            return true
         end
      end

   end

   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()
   if CanUse("mark") then
      local target = GetMarkedTarget() or GetWeakestEnemy("mark")
      if target and not HasBuff("mark", target) then
         UseItem("Deathfire Grasp", target)
         Cast("mark", target)
         PrintAction("Mark", target)
         return true
      end
   end

   if CanUse("dance") then
      local target = GetMarkedTarget() or GetWeakestEnemy("dance")
      if target and GetDistance(target) > GetSpellRange("AA") then
         UseItem("Deathfire Grasp", target)
         Cast("dance", target)
         PrintAction("Dance", target)
         return true
      end
   end

   if CastBest("slash") then
      return true
   end

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

local function onObject(object)
   local target = PersistOnTargets("mark", object, "akali_markOftheAssasin_marker", ENEMIES)
   if not GetMarkedTarget() then
      Persist("markedTarget", target)
   end
   PersistOnTargets("mark", object, "akali_markOftheAssasin_marker", MINIONS)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
