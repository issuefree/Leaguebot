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
   delay=2,
   speed=50,
   cone=30,
   noblock=true
}
spells["smoke"] = {
   key="W", 
   range=950, 
   color=yellow, 
   base={60,110,160,210,260}, 
   ap=.6,
   delay=2,
   speed=0,
   noblock=true,
   radius=250
}
spells["dash"] = {
   key="W", 
   range=425, 
   color=blue
}
spells["boom"] = {
   key="R", 
   range=1000, 
   color=red, 
   base={250,350,450}, 
   adBonus=1.4,
   delay=2,
   speed=50,
   noblock=true
}
spells["boomCone"] = {
   key="R", 
   range=1800, 
   color=red, 
   base={140,250,360}, 
   adBonus=1.2,
   delay=2,
   speed=50
}

function Run()
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
   -- if IsOn("lasthit") and Alone() then
   --    if KillMinion("AA") then
   --       return true
   --    end
   -- end

   -- if IsOn("clearminions") and Alone() then
   --    if HitMinion("AA", "strong") then
   --       return true
   --    end
   -- end
   return false
end

local function onObject(object)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
