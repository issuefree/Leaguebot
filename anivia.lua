require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Anivia")

--AddToggle("healTeam", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"green"}})

spells["orb"] = {
   key="Q", 
   range=1100, 
   color=violet, 
   base={60,90,120,150,180}, 
   ap=.5,
   delay=2,
   speed=8,
   width=80,
   area=75
}
spells["wall"] = {
   key="W", 
   range=1000, 
   color=blue
}
spells["spike"] = {
   key="E", 
   range=650, 
   color=violet, 
   base={55,85,115,145,175}, 
   ap=.5
}
spells["storm"] = {
   key="R", 
   range=625, 
   color=yellow, 
   base={80,120,160}, 
   ap=.25
}

-- throw orb at people.
-- stun them.
-- spike people who are "frosted"
--   either detect this or spike people hit by orb or ult.

function Run()
   for _,hero in ipairs(ENEMIES) do
      if isFrozen(hero) then
         Circle(hero, nil, blue)
      end
   end

   if P.orb then
      Circle(P.orb, 150, blue)
      local inRange = GetInRange(orb[2], 150, ENEMIES)
      if #inRange > 0 then
         CastSpellTarget("Q", me)
      end
   end

   if HotKey() then   
      UseItems()
      
      local target = GetWeakEnemy("MAGIC", spells['orb'].range)
      if not P.orb and IsGoodFireahead(target, "orb") then
         CastSpellFireahead(target, "orb")
      end
            
      if CanUse("spike") then
         local spell = spells["spike"]
         local enemies = GetInRange(me, spell.range, ENEMIES)
         enemies = GetWithBuff("freeze", enemies)
         local target = GetWeakest(spell, enemies)
         if target then
            Cast(spell.key, target)
         end
      end
   end

end

local function onObject(object)
--   if GetDistance(me, object) then
--      pp(object.)
   Persist("orb", object, "cryo_FlashFrost_mis")
   PersistOnTargets("freeze", object, "Global_Freeze", ENEMIES)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
