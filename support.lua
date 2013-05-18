require "timCommon"

local mortalStrikes = {}

--AddToggle("hug", {on=false, key=113, label="Hug Tower"})
--   if IsOn("hug") then
--      SortByDistance(ALLIES, me)
--      local hugTarget = ALLIES[2]
--      hugTower(hugTarget, 500)
--   end
--function hugTower(target, range)
--   SortByDistance(MYTURRETS, target)   
--   local tower = MYTURRETS[1]
--   LineBetween(target, tower)
--   local angle = AngleBetween(target, tower)
--   local dist = math.min(GetDistance(target, tower), range)
--   local x = target.x + math.sin(angle)*dist
--   local z = target.z + math.cos(angle)*dist
--   DrawCircle(x, 0, z, 35, yellow)
--   if GetDistance({x=x,z=z}) > 200 then
--      MoveToXYZ(x, 0, z)
--   end
--end


function SupportTick()
	Clean(mortalStrikes, "charName", "Mortal_Strike")
end

function healTeam(thing)
   
   local spell = GetSpell(thing)
   if not spell then
      return
   end
      
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
         if GetDistance(me, hero) < spell.range then        
            if not bestInRangeT or
               hero.health/hero.maxHealth < bestInRangeP
            then           
               bestInRangeT = hero
               bestInRangeP = hero.health/hero.maxHealth
            end
         elseif GetDistance(me, hero) < spell.range+250 then
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

   if CanCastSpell(spell.key) and me.dead ~= 1 then
      -- let me know if someone oustside of range is in need
      if bestOutRangeT and 
         ( not bestInRangeT or
          ( bestOutRangeP < .33 and
            bestInRangeP > .5 ) )         
      then
--       PlaySound("Beep")
      end

      if bestInRangeT then
         CastSpellTarget(spell.key, bestInRangeT)
      end
   end                     
end

function isWounded(hero)
	for _,obj in ipairs(mortalStrikes) do
		if obj and GetDistance(hero, obj) < 50 then
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

AddOnCreate(onCreateObjectSupport)
SetTimerCallback("SupportTick")