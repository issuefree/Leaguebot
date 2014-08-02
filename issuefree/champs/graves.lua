require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Graves")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["shot"] = {
   key="Q", 
   range=950-150, 
   color=violet, 
   base={60,95,130,165,200}, 
   adBonus=.8,
   delay=2.4,
   speed=20,
   cone=30, -- checked through DrawSpellCone aagainst the reticule
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
   base={250,400,550}, 
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

   if CastAtCC("shot") then
      return true
   end

   if HotKey() then
      if Action() then
         return true
      end
   end

   if IsOn("lasthit") and Alone() and GetMPerc(me) > .5 then
      if KillMinionsInCone("shot", 2) then
         return true
      end

      if KillMinionsInArea("smoke", 3) then
         return true
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
   -- TestSkillShot("shot")
   -- TestSkillShot("smoke")

   if SkillShot("shot") then
      return true
   end

   if SkillShot("smoke") then
      return true
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

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
