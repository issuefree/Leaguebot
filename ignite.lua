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
   for _,enemy in ipairs(ENEMIES) do
      if CanUse("ignite") and enemy.health < GetSpellDamage("ignite") then
         CastSpellTarget(spells["ignite"].key, enemy)
      end      
   end
end

local function onSpell(object, spell)
   if spells["ignite"] and CanUse("ignite") then
      if spell.name == "SwainMetamorphism" or     
         spell.name == "Sadism" or
         spell.name == "meditate"         
      then
         if object.team ~= me.team and GetDistance(object) < spells["ignite"].range then           
            CastSpellTarget(spells["ignite"].key, object)
         end
      end
   end
end

if spells["ignite"] then
   SetTimerCallback("igniteTick")
   ModuleConfig:addParam("ignite", "Auto Ignite", SCRIPT_PARAM_ONOFF, true)
   ModuleConfig:permaShow("ignite")
   AddOnSpell(onSpell)
end



