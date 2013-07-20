require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Template")

--AddToggle("autoQ", {on=false, key=112, label="Auto Q"})

spells["blow"] =      {key="Q", range=spells["AA"].range, color=yellow, base={20,40,60,80,100}, ap=.6, ad=1}
spells["charge"] =    {key="E", range=525, color=violet, base={50,75,100,125,150}, ap=.4}
spells["collision"] = {key="E", range=300, base={75,125,175,225,275}, ap=.4}
spells["immunity"] =  {key="R", range=900, color=blue}

function Run()
   TimTick()
   
   if HotKey() then
      UseItems()     
      checkCharge()
      local target = GetWeakEnemy("MAGIC", spells["AA"].range+100)
      if target then
         if CanUse("blow") then
            CastSpellTarget("Q", me)
            AttackTarget(target)
         end
      end      
   end
end

function checkCharge()
   if CanUse("charge") then
      local inRange = GetInRange(me, spells["charge"].range, ENEMIES)
      for _,enemy in ipairs(inRange) do
         if WillHitWall(enemy, spells["collision"].range) == 1 then
            CastSpellTarget("E", enemy) 
            return
         end
      end
   end
end

local function onObject(object)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
