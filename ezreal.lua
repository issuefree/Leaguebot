require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Ezreal")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("harrass", {on=true, key=113, label="Harrass"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Farm", auxLabel="{0} / {1}", args={GetAADamage, "shot"}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["shot"] = {
   key="Q", 
   range=1100, 
   width=75, 
   color=violet, 
   base={35,55,75,95,115}, 
   ad=1, 
   ap=.2,
   delay=2,
   speed=20, 
   type="P",
   cost={28,31,34,37,40}
}
spells["flux"] = {
   key="W", 
   range=900, 
   color=yellow, 
   base={70,115,160,205,250}, 
   ap=.8,
   delay=2,
   speed=15,
   noblock=true,
   cost={50,60,70,80,90}
}
spells["arrow"] = {
   key="E", 
   range=475+750, 
   color=violet, 
   base={75,125,175,225,275}, 
   ap=.75
}
spells["shift"] = {
   key="E", 
   range=475, 
   color=green,
   cost=90
}
spells["barrage"] = {
   key="R", 
   base={350,500,650}, 
   ad=1, 
   ap=.9,
   delay=12,
   speed=20,
   noblock=true,
   cost=100
}


function Run()
   -- TODO something with ult
--   local target = GetWeakEnemy("MAGIC", 99999)
--   if target then
--      Circle(GetFireahead(target, 1.2, 20),100, red )
--   end
  
   if IsOn("harrass") then
      if SkillShot("shot") then
         return true
      end
   end

   if HotKey() and CanAct() then
      UseItems()
      if Action() then
         return true
      end
   end
   
   if IsOn("lasthit") and Alone() then
      if CanUse("shot") then
         for _,minion in ipairs(SortByHealth(GetUnblocked(me, "shot", MINIONS))) do
            if WillKill("shot", minion) and
               ( JustAttacked() or
                 GetDistance(minion) > spells["AA"].range )
            then
               CastXYZ("shot", minion)
               PrintAction("Shot for lasthit")
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
   local minFluxLevel = 0
   -- flux enemy if flux is over level 1 (waste of mana at low levels)
   if GetSpellLevel("W") > minFluxLevel then
      if SkillShot("flux") then
         return true
      end
   end
   
   if SkillShot("shot") then -- in case harass is off
      return true
   end

   local target = GetWeakEnemy("PHYS", spells["AA"].range)
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
      MoveToCursor() 
      PrintAction("Move")
      return false
   end
end

local function onObject(object)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
