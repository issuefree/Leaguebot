require "Utils"
require "timCommon"
require "modules"
require "support"

pp("\nTim's Morgana")

AddToggle("shield", {on=true, key=112, label="Auto Shield"})
AddToggle("bind", {on=true, key=113, label="Auto Bind"})
AddToggle("soil", {on=true, key=114, label="Auto Soil"})

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
   base={25,40,55,70,85}, 
   ap=.2,
   radius=300,
   cost={70,85,100,115,130}
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

local Q = spells["binding"]
local W = spells["soil"]
local E = spells["shield"]
local R = spells["shackles"]

-- shield if someone is going to be hit by a stun
-- shield other random spells
-- binding people
-- soil people

local lastBinding = GetClock()

function Run()
--   local testTarget = GetMousePos()
--   local testFA = {x=testTarget.x + 500, y = testTarget.y, z = testTarget.z}
--   
--   DrawCircle(testTarget.x, testTarget.y, testTarget.z, 100, yellow)
--   DrawCircle(testFA.x, testFA.y, testFA.z, 100, violet)
--   
--   local attack = (math.abs( AngleBetween(testTarget, me) - AngleBetween(testTarget, testFA) )*180/math.pi)
--   attack = math.abs((attack-90))
--   pp(attack)
   
   if HotKey() then
      UseItems()
      
      if IsOn("bind") then
         if not SkillShot("binding", "peel") then
            SkillShot("binding")
         end
      end
      
      -- try just soiling things I bind
      
      local targets = GetInRange(me, W.range, ENEMIES)
      if #targets > 0 and CanUse("soil") and IsOn("soil") then
         if not CanUse("binding") then            
            for _,target in ipairs(targets) do
               local point = ToPoint(GetFireahead(target, 2.5, 0))
               if GetDistance(target, point) < W.radius/4 then
                  CastXYZ("soil", point)
                  PrintAction("Soil unmoving target", target)
                  return true
               end
            end
         end 
      end
      
   end
end

local function onObject(object)
   if find(object.charName, "DarkBinding") then
      if IsOn("soil") and CanUse("soil") then
         for _,enemy in ipairs(ENEMIES) do
            if GetDistance(object, enemy) < 50 then
               Cast("soil", object)
               PrintAction("Soil", object)
               break
            end
         end
      end
   end 
end

local function onSpell(unit, spell)
   if IsOn("shield") then
      CheckShield("shield", unit, spell, "MAGIC")
   end
   
   if unit.name == me.name and find(spell.name, "darkbinding") then
      lastBinding = GetClock()
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
