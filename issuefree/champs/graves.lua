require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Graves")

--AddToggle("healTeam", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"green"}})

spells["shot"] = {
   key="Q", 
   range=950-150, 
   color=violet, 
   base={60,95,130,165,200}, 
   adBonus=.8,
   delay=2.4,
   speed=20,
   cone=30,
   noblock=true,
   cost={60,70,80,90,100}
}
spells["smoke"] = {
   key="W", 
   range=950, 
   color=yellow, 
   base={60,110,160,210,260}, 
   ap=.6,
   delay=2.3,
   speed=15,
   noblock=true,
   radius=250,
   cost={70,75,80,85,90}
}
spells["dash"] = {
   key="E", 
   range=425, 
   cost=40,
   color=blue
}
spells["boom"] = {
   key="R", 
   range=1000, 
   color=red, 
   base={250,350,450}, 
   adBonus=1.5,
   delay=2,
   speed=50,
   noblock=true,
   cost=100
}
spells["boomCone"] = {
   key="R", 
   range=1800, 
   color=red, 
   base={200,280,360}, 
   adBonus=1.2,
   delay=2,
   speed=50
}

function Run()
   if StartTickActions() then
      return true
   end

   if HotKey() then
      UseItems()

      if Action() then
         return true
      end
   end   

   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end
end

function Action()
   -- TestSkillShot("shot")
   TestSkillShot("smoke")

   if SkillShot("shot") then
      return true
   end

   if SkillShot("smoke") then
      return true
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AA(target) then
      PrintAction("AA", target)
      return true
   end

   return false
end

function FollowUp()
   return false
end

local function onObject(object)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
