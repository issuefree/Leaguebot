require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Blitz")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("pull", {on=true, key=113, label="Pull"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "fist"}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["grab"] = {
   key="Q", 
   range=1050, 
   color=violet, 
   base={80,135,190,245,300}, 
   ap=1,
   delay=2,
   speed=17,
   width=80,
   cost=120
}
spells["drive"] = {
   key="W", 
   cost=75
}
spells["fist"] = {
   key="E", 
   range=GetSpellRange("AA"), 
   base=0,
   ad=2,
   onHit=true,
   color=red, 
   cost=25
}
spells["field"] = {
   key="R", 
   range=600, 
   color=yellow, 
   base={250,375,500}, 
   ap=1,
   cost=150
}

function Run()
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
      if ModAAFarm("fist", P.fist) then
         return true
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

   local target = GetMarkedTarget() or GetMeleeTarget()
   if target and ModAA("fist", target) then
      return true
   end

   return false
end

function FollowUp()
   if IsOn("lasthit") and Alone() then
      if KillMinion("AA") then
         return true
      end

      if CanUse("fist") then
         local target = SortByHealth(GetInRange(me, GetSpellRange("AA"), MINIONS))[1]        
         if target and WillKill("fist", target) and
            ( JustAttacked() or not WillKill("AA", target) )
         then
            Cast("fist", me)
            PrintAction("fist lasthit")
            AttackTarget(target)
            return true
         end
      end

   end

   if IsOn("clearminions") and Alone() then
      if HitMinion("AA", "strong") then
         return true
      end
   end

   if IsOn("move") then
      if MeleeMove() then
         return true
      end
   end

   return false
end

local function onObject(object)
   PersistBuff("fist", object, "Powerfist_buf", 150)
end

local function onSpell(unit, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")

