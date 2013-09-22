require "Utils"
require "timCommon"
require "modules"
require "support"

pp("\nTim's Morgana")

AddToggle("shield", {on=true, key=112, label="Auto Shield"})
AddToggle("soil", {on=true, key=113, label="Auto Soil"})
AddToggle("", {on=true, key=114, label=""})

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

-- shield if someone is going to be hit by a stun
-- shield other random spells
-- binding people
-- soil people

function Run()
   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return true
   end
   
   if HotKey() and CanAct() then
      UseItems()
      if Action() then
         return true
      end
   end

   if IsOn("soil") and CanUse("soil") then
      local target = 
         SortByHealth( 
            GetWithBuff("cc", 
               GetInRange(me, GetSpellRange("soil")+spells["soil"].radius-25, ENEMIES) ) )[1]
      if target then
         -- If they're out of range cast where the edge of soil will hit em
         local point = Projection(me, target, math.min(GetDistance(target), GetSpellRange("soil")))
         CastXYZ("soil", point)
         PrintAction("Soil ccd", target)
         return true
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
   if CanUse("bind") then
      local target = SkillShot("binding", "peel")
      if target then
         CastFireahead("binding", target)
         PrintAction("Binding for peel", target)
         return true
      end
      local target = SkillShot("binding")
      if target then
         CastFireahead("binding", target)
         PrintAction("Binding", target)
         return true
      end
   end
end

function FollowUp()

end

local function onObject(object)
end

local function onSpell(unit, spell)
   if IsOn("shield") then
      CheckShield("shield", unit, spell, "MAGIC")
   end   
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
