require "timCommon"
require "spell_shot"

local mortalStrikes = {}

function SupportTick()
	Clean(mortalStrikes, "charName", "Mortal_Strike")
end

function healTeam(thing)   
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
         not isWounded(hero) and 
         not IsRecalling(hero)
      then
         if GetDistance(hero) < spell.range then        
            if not bestInRangeT or
               hero.health/hero.maxHealth < bestInRangeP
            then           
               bestInRangeT = hero
               bestInRangeP = hero.health/hero.maxHealth
            end
         elseif GetDistance(hero) < spell.range+250 then
            if not bestOutRangeT or
               hero.health/hero.maxHealth < bestOutRangeP
            then           
               bestOutRangeT = hero
               bestOutRangeP = hero.health/hero.maxHealth
            end
         end
      end
   end
   if bestInRangeT then
      DrawCircleObject(bestInRangeT, 100, green)
   end
   if bestOutRangeT and GetDistance(me, bestOutRangeT) > spell.range then
      CustomCircle(100, 4, yellow, bestOutRangeT)
   end

   if bestInRangeT then
      Cast(spell, bestInRangeT)
      return true
   end
   return false
end

function isWounded(hero)
	for _,obj in ipairs(mortalStrikes) do
		if obj and GetDistance(hero, obj) < 75 then
			return true
		end
	end
	return false
end

local function onCreateObjectSupport(object)
	if find(object.charName, "Mortal_Strike") then
		table.insert(mortalStrikes, object)
	end
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
         local shot = GetSpellShot(unit.name, spell.name)
         if shot and shot.physical then
            return false
         end
      end

      Cast(shield, spell.target)
      PrintAction("["..spell.target.name.."] - "..unit.name.."'s "..spell.name)
      return true
   end

   local allies = GetInRange(me, shield, ALLIES)
   for _,ally in ipairs(allies) do
      local shot = SpellShotTarget(unit, spell, ally)
      if shot then
         if type == "MAGIC" and shot.spell.physical then
            return false
         end

         Cast(shield, ally)
         PrintAction("("..ally.name..") - "..unit.name.."'s "..spell.name)
         return true
      end
   end
   return false
end


AddOnCreate(onCreateObjectSupport)
AddOnTick(SupportTick)