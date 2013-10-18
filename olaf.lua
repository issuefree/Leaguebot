require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Olaf")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("jungle", {on=true, key=113, label="Jungle"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "swing"}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["axe"] = {
   key="Q", 
   range=1000, 
   color=violet, 
   base={70,115,160,205,250}, 
   adBonus=1, 
   type="P",
   delay=2,
   speed=16,
   noblock=true,
   width=75,
   overShoot=150,
   cost={55,60,65,70,75}
}
spells["strikes"] = {
   key="W",
   cost=30
}
spells["swing"] = {
   key="E", 
   range=325, 
   color=yellow, 
   base={70,115,160,205,250}, 
   ad=.4,
   type="T"
}
spells["ragnarok"] = {
   key="R"
}

--[[
Jungling
   Axe stuff. Hit everything I can. Keep it close so I can pick it up.
   Swing at stuff as long as I have enough health.
Ganking
   Axe people.
   Attack people.
   If I can hit people pop W.
   Swing at people.
]]--

function Run()
   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return
   end

   if HotKey() and CanAct() then
      UseItems()
      if Action() then
         return true
      end
   end

   if IsOn("lasthit") and Alone() then
      if KillMinion("swing") then
         return true
      end
      if KillMinionsInLine("axe", 2) then
         PrintAction("Axe for lasthit")
         return true
      end
   end
   
   if IsOn("jungle") then
      local creeps = GetAllInRange(me, 275, CREEPS)
      for _,creep in ipairs(creeps) do
         if ListContains(creep.name, MajorCreepNames, true) or 
            ListContains(creep.name, BigCreepNames, true) 
         then
            if JustAttacked() then -- to keep me from getting distracted when I run through the jungle
               if CanUse("axe") then 
                  CastXYZ("axe", creep)
                  PrintAction("Axe for jungle")
                  return true
               end
               if CanUse("swing") then
                  Cast("swing", creep)
                  PrintAction("Swing for jungle", creep)
                  return true
               end
            end
         end
      end
   end

   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   PrintAction()
end

function Action()   
   if SkillShot("axe") then
      return true
   end
      
   local target = GetMarkedTarget() or GetMeleeTarget()
   if target then
      if CanUse("strikes") then
         Cast("strikes", me)
         PrintAction("Strikes up")
      end

      if CanUse("swing") then
         Cast("swing", target)
         PrintAction("Swing", target)
         return true
      end

      if AA(target) then
         PrintAction("AA", target)
         return true
      end
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
      if me.mana/me.maxMana > .75 then
         if HitMinionsInLine("axe", 3) then
            PrintAction("Axe for clear")
            return true
         end
      elseif me.mana/me.maxMana > .66 then
         if HitMinionsInLine("axe", 4) then
            PrintAction("Axe for clear")
            return true
         end
      elseif me.mana/me.maxMana > .5 then
         if HitMinionsInLine("axe", 5) then
            PrintAction("Axe for clear")
            return true
         end
      end

      if GetHPerc(me) < .75 then
         if CanUse("strikes") and #GetInRange(me, "swing", MINIONS) >= 2 then
            Cast("strikes", me)
            PrintAction("Strikes for clear")
         end
      end

      -- hit the highest health minion
      local minions = SortByHealth(GetInRange(me, "AA", MINIONS))
      if AA(minions[#minions]) then
         PrintAction("AA clear minions")
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
