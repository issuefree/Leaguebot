require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Olaf")
pp(" - Swing for last hits")
pp(" - Ham in jungle")
pp(" - Axe peeps")

AddToggle("", {on=true, key=112, label=""})
AddToggle("jungle", {on=true, key=113, label="Jungle"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "swing"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["axe"] = {
   key="Q", 
   range=1000, 
   color=violet, 
   base={70,115,160,205,250}, 
   adBonus=1, 
   type="P",
   delay=1,
   speed=16,
   noblock=true,
   width=75,
   overShoot=150,
   cost=60
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
   if StartTickActions() then
      return true
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
      local creeps = GetAllInRange(me, GetSpellRange("swing"), CREEPS)
      
      if #creeps > 0 and JustAttacked() then -- justattacked keeps me from aggroing by accident
         if CanUse("axe") and GetMPerc(me) > .5 then
            local hits, _, score = GetBestLine(me, "axe", 1, 2, creeps)
            if score >= 2 then            
               local target = SortByDistance(hits)[#hits]
               CastXYZ("axe", Point(target))
               PrintAction("Axe for jungle aoe", score)
               return true
            end
         end


         for i,creep in ipairs(creeps) do
            if ListContains(creep.name, MajorCreepNames, true) or 
               ListContains(creep.name, BigCreepNames, true) 
            then
               if CanUse("axe") and GetMPerc(me) > .66 then 
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


            if CanUse("swing") and WillKill("swing", creep) and #creeps >= 2 then
               Cast("swing", creep)
               PrintAction("Execute creep")
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

   EndTickActions()
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

   if IsOn("clear") and Alone() then
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

      if HitMinion("AA", "strong") then
         return true
      end
   end

   -- if IsOn("move") then
   --    if MeleeMove() then
   --       return false
   --    end
   -- end
   return false
end

local function onObject(object)
end

local function onSpell(unit, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
