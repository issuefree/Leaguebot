require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Akali")
pp(" - Mark enemies that have no mark")
pp(" - Slash nearby enemies")
pp(" - Dance to far enemies")
pp(" - Mark for last hit")
pp(" - Slash for last hit >= 2")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "mark"}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["mark"] = {
  key="Q",
  range=600,
  color=violet,
  base={35,55,75,95,115},
  ap=.4,
  cost=60
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
  radius=600,
  cost={80,75,70,65,60}
}
spells["slash"] = {
  key="E", 
  range=325, 
  color=red,
  base={30,55,80,105,130}, 
  ap=.3,
  ad=.6,
  type="P",
  cost={60,55,50,45,40}
}
spells["dance"] = {
  key="R", 
  range=800, 
  color=yellow, 
  base={100,175,250}, 
  ap=.5
}

function Run()
   for _,t in ipairs(GetWithBuff("mark", MINIONS)) do
      Circle(t)
   end

   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return true
   end

	if HotKey() and CanAct() then
      UseItems()
		if Action() then
			return true
		end
	end

   if IsOn("lasthit") and Alone() and CanAct() then
      if CanUse("mark") then
         local targets = SortByDistance(GetKills("mark", GetInRange(me, "mark", MINIONS)))
         local target = targets[#targets]
         if target and 
            ( GetDistance(target) > GetSpellRange("AA") or
              JustAttacked() )
         then
            Cast("mark", target)
            PrintAction("Mark for lasthit")
            return true
         end
      end

      if CanUse("slash") then
         local kills = 0
         for _,minion in ipairs(GetInRange(me, "slash", MINIONS)) do
            if WillKill("slash", minion) then
               kills = kills + 1
            elseif HasBuff("mark", minion) and 
               GetSpellDamage("slash", minion) + GetSpellDamage("detonate", minion) > minion.health
            then
               kills = kills + 1
            end
            if kills >= 2 then
               Cast("slash", me)
               PrintAction("Slash for lasthit")
               return true
            end
         end
      end

   end

   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end
end

function Action()
   if CanUse("mark") then
      local target = GetMarkedTarget() or GetWeakestEnemy("mark")
      if target and not HasBuff("mark", target) then
         PrintAction("Mark", target)
         Cast("mark", target)
         return true
      end
   end

   if CanUse("dance") then
      local target = GetMarkedTarget() or GetWeakestEnemy("dance")
      if target and GetDistance(target) > GetSpellRange("slash") then
         PrintAction("Dance", target)
         Cast("dance", target)
         return true
      end
   end

   if CanUse("slash") then
      local target = GetWeakestEnemy("slash")
      if target then
         PrintAction("Slash", target)
         Cast("slash", me)
         return true
      end
   end

   local target = GetMarkedTarget() or GetWeakEnemy("PHYS", spells["AA"].range*1.5)
   if AA(target) then
      PrintAction("AA", target)
      return true
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

   if IsOn("move") then
      local target = GetMarkedTarget() or GetWeakEnemy("PHYS", spells["AA"].range*1.5)
      if target then
         if GetDistance(target) > spells["AA"].range then
            MoveToTarget(target)
            return false
         end
      else        
         MoveToCursor() 
         PrintAction("Move")
         return false
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
