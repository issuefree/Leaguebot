require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Morgana")
pp(" - Auto shield CC")
pp(" - Soil CC'd enemies")

AddToggle("shield", {on=true, key=112, label="Auto Shield"})
AddToggle("soil", {on=true, key=113, label="Auto Soil"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["binding"] = {
   key="Q", 
   range=1100, -- this is really 1300 but max range never seems to hit
   color=red, 
   base={80,135,190,245,300}, 
   ap=.9,
   delay=2,
   speed=12,
   width=90,
   cost={50,60,70,80,90}
}
spells["soil"] = {
   key="W", 
   range=900, 
   color=violet, 
   base={24,38,52,66,80}, 
   ap=.22,
   radius=275,
   cost={70,85,100,115,130},
   noblock=true
}
spells["shield"] = {
   key="E", 
   range=750, 
   color=blue, 
   base={95,160,225,290,355}, 
   ap=.7,
   cost=50
}
spells["shackles"] = {
   key="R", 
   range=600, 
   color=red, 
   base={175,250,325}, 
   ap=.7,
   cost=100
}


function Run()
   if StartTickActions() then
      return true
   end

   if HotKey() and CanAct() then
      if Action() then
         return true
      end
   end

   if CastAtCC("soil") then
      return true
   end

   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()
   if CanUse("bind") then
      if SkillShot("binding", "peel") then
         return true
      end
      if SkillShot("binding") then
         return true
      end
   end
   return false
end

function FollowUp()
   return false
end

local function onObject(object)
end

local function onSpell(unit, spell)
   if IsOn("shield") then
      CheckShield("shield", unit, spell, "CC")
   end   
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
