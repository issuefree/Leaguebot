require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Shyvana")

AddToggle("", {on=true, key=112, label="- - -"})
AddToggle("jungle", {on=true, key=113, label="Jungle"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "bite"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["bite"] = {
   key="Q",
   base=0,
   ad=1,
   onhit=true,
   perc={.8,.85,.9,.95,1},
   modAA="bite"
   onHit=true,
   type="P"
} 
spells["burnout"] = {
   key="W", 
   range=325, 
   color=red, 
   base={20,35,50,65,80}, 
   bonusAd=.1
} 
spells["breath"] = {
   key="E", 
   range=925, 
   color=violet, 
   base={60,100,140,180,220}, 
   ap=.6,
   delay=2,
   speed=15,
   width=80,
   noblock=true
} 
spells["binding"] = {
   key="R", 
   range=1000, 
   color=yellow, 
   base={175,300,425}, 
   ap=.7,
   delay=2,
   speed=12,
   width=150,
   noblock=true
} 

function Run()
   local biteLevel = GetSpellLevel(spells["bite"].key)
   if biteLevel > 0 then
      spells["bite"].base = (me.baseDamage+me.addDamage)*spells["bite"].perc
   end

   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() then
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important
   if IsOn("lasthit") and Alone() then
      if CanUse("breath") then
         if KillMinionsInLine("breath", 2) then
            PrintAction("Breath for lasthit")
            return true
         end
      end
   end

   if CanUse("bite") and Alone() then

      if IsOn("lasthit") then
         local target = GetWeakest("bite", GetInRange(me, "AA", MINIONS))
         if target and WillKill("bite", target) and CanAct() and JustAttacked() then
            Cast("bite", me)
            PrintAction("Bite lasthit")
            AttackTarget(target)
            return true
         end
      end

      if IsOn("jungle") then
         local creeps = SortByHealth(GetAllInRange(me, GetSpellRange("AA")+50, CREEPS), "AA")
         local creep = creeps[#creeps]
         if creep and not WillKill("AA", creep) then
            if JustAttacked() then
               Cast("bite", me)
               PrintAction("Bite jungle")
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
   if SkillShot("breath") then
      return true
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA", 0, GetSpellRange("AA"))
   if target then
      if CanUse("burnout") then
         Cast("burnout", me)
         PrintAction("Burnout", target)
         return true
      end      
   end

   if AutoAA("bite") then
      return true
   end

   return false
end

function FollowUp()
   if CanUse("bite") then
      local target = GetWeakest("AA", GetInRange(me, GetSpellRange("AA"), MINIONS))
      if target and WillKill("bite", target) and
         ( JustAttacked() or not WillKill("AA", target) )
      then
         Cast("bite", me)
         PrintAction("Bite lasthit")
         AttackTarget(target)
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
end

local function onSpell(unit, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")

