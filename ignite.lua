require "timCommon"

local ignite = {range=600, color=red, base={50}, lvl=20}

if me.SummonerD == "SummonerDot" then
   ignite.key = "D"
   spells["ignite"] = ignite
-- print("Ignite in "..ignite.key)
elseif me.SummonerF == "SummonerDot" then
   ignite.key = "F"
   spells["ignite"] = ignite
-- print("Ignite in "..ignite.key)
end

function igniteTick()
   local inRange = GetInRange(me, spells["ignite"].range, ENEMIES)
   for _,enemy in ipairs(inRange) do
      if CanUse("ignite") and enemy.health < GetSpellDamage("ignite") then
         CastSpellTarget(spells["ignite"].key, enemy)
      end      
   end
end

local function onSpell(unit, spell)
   if spells["ignite"] and CanUse("ignite") then
      if spell.name == "SwainMetamorphism" or     
         spell.name == "Sadism" or
         spell.name == "meditate"         
      then
         if unit.team ~= me.team and GetDistance(unit) < spells["ignite"].range then           
            CastSpellTarget(spells["ignite"].key, unit)
         end
      end
   end
end

if spells["ignite"] then
   SetTimerCallback("igniteTick")
   AddOnSpell(onSpell)
end
