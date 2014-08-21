require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Morgana")
pp(" - Auto shield CC")
pp(" - Soil CC'd enemies")

AddToggle("shield", {on=true, key=112, label="Auto Shield"})
AddToggle("bind", {on=false, key=113, label="Auto Bind"})
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
   delay=2,
   speed=0,
   cost={70,85,100,115,130},
   noblock=true
}
spells["shield"] = {
   key="E", 
   range=750, 
   color=blue, 
   base={70,140,210,280,350}, 
   ap=.7,
   cost=50
}
spells["shackles"] = {
   key="R", 
   range=600, 
   color=red, 
   base={150,225,300}, 
   ap=.7,
   cost=100
}


function Run()
   if StartTickActions() then
      return true
   end

   local shackleKills = GetKills("shackles", ENEMIES)
   if #shackleKills > 0 then
      for _,kill in ipairs(shackleKills) do
         LineBetween(me, kill)
      end
   end

   if HotKey() then
      if Action() then
         return true
      end
   end

   if CastAtCC("soil", true) then
      return true
   end

   if HotKey() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()
   if IsOn("bind") then
      if CanUse("binding") then
         if SkillShot("binding", "peel") then
            return true
         end
         if SkillShot("binding") then
            return true
         end
      end
   end

   if CanUse("shackles") then      
      local targets = GetInRange(me, "shackles", ENEMIES)
      if #targets >= 3 then
         Cast("shackles", me)
         PrintAction("Shackles for AoE", #targets)
         return true
      end
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

local function onSpell(unit, spell)
   if IsOn("shield") then
      CheckShield("shield", unit, spell, "CC")
   end   
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
