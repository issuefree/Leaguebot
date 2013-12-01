require "timCommon"

function SupportTick()
end

function HealTeam(thing)   
   local spell = GetSpell(thing)
   if not spell then return false end
   if not CanUse(spell) then return false end
      
   local maxW = GetSpellDamage(spell)

   local bestInRangeT = nil
   local bestInRangeP = 1
   local bestOutRangeT = nil
   local bestOutRangeP = 1
   
   for _,hero in ipairs(ALLIES) do
      if GetDistance(HOME, hero) > spell.range+250 and
         hero.health + maxW < hero.maxHealth*.9 and
         not HasBuff("wound", hero) and 
         not IsRecalling(hero)
      then
         if GetDistance(hero) < spell.range then        
            if not bestInRangeT or
               GetHPerc(hero) < bestInRangeP
            then           
               bestInRangeT = hero
               bestInRangeP = GetHPerc(hero)
            end
         elseif GetDistance(hero) < spell.range+250 then
            if not bestOutRangeT or
               GetHPerc(hero) < bestOutRangeP
            then           
               bestOutRangeT = hero
               bestOutRangeP = GetHPerc(hero)
            end
         end
      end
   end
   if bestInRangeT then
      Circle(bestInRangeT, 100, green)
   end
   if bestOutRangeT and GetDistance(me, bestOutRangeT) > spell.range then
      Circle(bestOutRangeT, 100, yellow, 4)
   end

   if bestInRangeT then
      Cast(spell, bestInRangeT)
      return true
   end
   return false
end

local function onCreateObjectSupport(object)
   PersistOnTargets("wound", object, "Mortal_Strike", ENEMIES)
end

function CheckShield(thing, unit, spell, type)
   if find(unit.name, "Minion") or
      IsRecalling(me) or
      not CanUse(thing) or
      unit.team == me.team
   then
      return false
   end
   
   if type == "MAGIC" or type == "SPELL" then
      if find(spell.name, "attack") then
         return false
      end
   end

   local shield = GetSpell(thing)
   
   if spell.target and 
      not find(spell.target.name, "Minion") and 
      GetDistance(spell.target) < GetSpellRange(shield)
   then
      if type == "MAGIC" then
         local shot = GetSpellDef(unit.name, spell.name)
         if not shot or shot.physical then
            return false
         end
      end

      if type ~= "CHECK" then
         Cast(shield, spell.target)
      end
      PrintAction("["..spell.target.name.."] - "..unit.name.."'s "..spell.name)
      return spell.target
   end

   local allies = GetInRange(me, shield, ALLIES)
   for _,ally in ipairs(allies) do
      local shot = SpellShotTarget(unit, spell, ally)
      if shot then
         if type == "MAGIC" and shot.spell.physical then
            return false
         end

         if type ~= "CHECK" then
            Cast(shield, ally)
         end
         PrintAction("("..ally.name..") - "..unit.name.."'s "..spell.name)
         return ally
      end
   end
   return false
end


AddOnCreate(onCreateObjectSupport)
AddOnTick(SupportTick)