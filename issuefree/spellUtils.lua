require "issuefree/basicUtils"
require "issuefree/items"
require "issuefree/persist"
require "issuefree/telemetry"
require "issuefree/walls"

-- require 'yprediction'
-- local YP = YPrediction()

-- common spell defs
spells = {}

function IsCooledDown(key, extraCooldown, hero)
	hero = hero or me
	extraCooldown = extraCooldown or 0
	if not key then return false end
   return hero["SpellTime"..key] >= .9 + extraCooldown
end

function Cast(thing, target, force)
   local spell = GetSpell(thing)
   spell = spell or thing

   if not force and not CanUse(spell) then
      -- pp("can't use "..spell.key)
      -- pp(debug.traceback())
      return false
   end

   if not target then 
      pp("no target for "..spell.key)
      return false
   end

   if IsSkillShot(spell) then
   	CastFireahead(spell, target)
   else
   	CastSpellTarget(spell.key, target, 0)
   end
   return true
end

function CastXYZ(thing, x,y,z)
   local spell = GetSpell(thing)
   if not spell then return end
   local p = Point(x,y,z)
   CastSpellXYZ(spell.key, p.x,p.y,p.z, 0)      
end

local sx, sy
function CastClick(thing, x,y,z)
   local spell = GetSpell(thing)
   if not spell then return end
   
   local p = Point(x,y,z)

   if IsLoLActive() and IsChatOpen() == 0 then
      if sx == nil then
         sx = GetCursorX()
         sy = GetCursorY()
      end
      ClickSpellXYZ(spell.key, p.x, p.y, p.z, 0)
      DoIn(
         function() 
            if sx then 
               send.mouse_move(sx, sy) 
               sx = nil
               sy = nil
            end
         end, 
         .1 
      )
   end
end

function CastBuff(spell, switch)
   if CanUse(spell) then
      if P[spell] and switch == false then
         Cast(spell, me)
         P[spell] = nil
         PrintAction(spell.." OFF")
         return
      end
      if not P[spell] and switch ~= false then
         Cast(spell, me)
         PersistTemp(spell, .5)
         PrintAction(spell.." ON")
         return
      end
   end
end

function CastFireahead(thing, target)
   if not target then return false end

   local spell = GetSpell(thing)   
   if not spell.speed then spell.speed = 20 end
   if not spell.delay then spell.delay = 1.6 end

   local point = GetSpellFireahead(spell, target)
   if spell.overShoot then
      point = OverShoot(me, point, spell.overShoot)
   end   
   if GetDistance(point) < GetSpellRange(spell) then
      if IsWall(point.x, point.y, point.z) == 1 then
         pp("Casting "..thing.." into wall.")
      end
      CastXYZ(spell, point)
      return true
   end

   return false
end

function GetReachPoint(thing, target)
	local range = GetSpellRange(thing)
	if GetDistance(target) > range then
		return Projection(me, target, range)
	else
		return Point(target)
	end
end

function GetCD(thing)
   local spell = GetSpell(thing)
   local cd = math.ceil(1 - me["SpellTime"..spell.key])
   if cd > 0 then
      return cd
   end
   return 0
end

function CanUse(thing)
   if type(thing) == "table" then -- spell or item
      if thing.name == "attack" then
         return CanAttack()
      end
      if thing.id then -- item
         return IsCooledDown(GetInventorySlot(thing.id))
      elseif thing.key then -- spell
      	if not ListContains(thing.key, {"Q","W","E","R","D","F"}) then
      		return false
      	end
         if thing.key == "D" or thing.key == "F" or ( GetSpellLevel(thing.key) > 0 and me.mana >= GetSpellCost(thing) ) then
         	if P.silence then
         		return false
         	end
            return IsCooledDown(thing.key, thing.extraCooldown)
         else
            return false
         end
      else  -- spells without keys are always ready
         return true
      end
   elseif type(thing) == "number" then -- item id
      return IsCooledDown(GetInventorySlot(thing))
   else -- string
      if thing == "AA" then
         return CanAttack()
      end
      if spells[thing] then -- passed in the name of a spell
         if spells[thing].key then
            return CanUse(spells[thing])
         else
            return true -- a defined spell without a key prob auto attack
         end
      elseif ITEMS[thing] then  -- passed in the name of an item
         return IsCooledDown(GetInventorySlot(ITEMS[thing].id))
      else -- other string must be a slot
         if thing == "D" or thing == "F" then
            return IsSpellReady(thing) == 1
         end
         if #thing > 1 then
            return false
         end
         return GetSpellLevel(thing) > 0 and IsCooledDown(thing) -- should be a spell key "Q"
      end
   end
   pp("Failed to get spell for "..thing)
end

function CanUseItem(itemName)
	return CanUse(ITEMS[itemName])
end

function GetSpellCost(thing)
   local spell = GetSpell(thing)
   if spell.key then
   	return me["SpellMana"..spell.key]
   else
   	return GetLVal(spell, "cost")
   end
end

function GetSpellCostPerc(thing)
	return GetSpellCost(thing) / (me.mana+(MP5*5))
end

function GetSpellRange(thing)
   return GetLVal(GetSpell(thing), "range")
end

function GetSpellName(thing)
	local spell = GetSpell(thing)

	if spell.name then return spell.name end

	for name, s in pairs(spells) do
		if spell == s then
			return name
		end
	end

end

function GetSpell(thing)
   local spell
   if type(thing) == "table" then
      spell = thing
   else
      if type(thing) == "string" and #thing == 1 then
         for _,spell in pairs(spells) do
            if spell.key == thing then
               break
            end
         end
      else
         spell = spells[thing]
      end
      if not spell then
         for _,s in pairs(spells) do
            if thing == s.key then
               spell = s
               break
            end
         end
      end
      -- couldn't find a defined spell.
      -- make a fake spell with the thing as the key as this is almost certainly
      -- an item or a summoner spell
      if not spell then 
         spell = {key=thing}         
      end
   end
   return spell
end

function GetLVal(spell, field)
	if not spell[field] then return 0 end

   if type(spell[field]) == "number" then
      return spell[field]
   end

   if type(spell[field]) == "function" then
   	return spell[field]()
   end

   if spell[field].isDamage then
      return spell[field]
   end

   local lvl = 1
   if spell.key then
      lvl = GetSpellLevel(spell.key)
      if lvl == 0 then
         lvl = 1
      end
   end

   local val = spell[field][lvl]

   if not val then val = 0 end
   
   return val
end

function GetSpellDamage(thing, target, ignoreResists)
   local spell = GetSpell(thing)
   if not spell or not spell.base then
      return 0
   end

   local lvl 
   if spell.key and not (spell.key == "D" or spell.key == "F") then
      lvl = GetSpellLevel(spell.key)
      if lvl == 0 then
         return 0
      end
   else 
      lvl = 1
   end

   local damage = 0

   if spell.modAA and P[spell.modAA] then -- if the mod is on then the damage should already be in the AA
		return GetAADamage()
   end

   damage = damage + Damage(GetLVal(spell, "base"), spell.type or "M")
   damage = damage + GetLVal(spell, "ap")*me.ap
   damage = damage + GetLVal(spell, "ad")*(me.baseDamage+me.addDamage)
   damage = damage + GetLVal(spell, "adBonus")*me.addDamage
   damage = damage + GetLVal(spell, "adBase")*me.baseDamage
   damage = damage + GetLVal(spell, "mana")*me.maxMana
   damage = damage + GetLVal(spell, "armor")*me.armor
   damage = damage + GetLVal(spell, "lvl")*me.selflevel
   damage = damage + GetLVal(spell, "bonus")
   if target then
      local targetMaxHealth = GetLVal(spell, "targetMaxHealth")
      targetMaxHealth = targetMaxHealth + GetLVal(spell, "targetMaxHealthAP")*me.ap
      damage = damage + targetMaxHealth*target.maxHealth
   end
   if target then
      local targetHealth = GetLVal(spell, "targetHealth")
      targetHealth = targetHealth + GetLVal(spell, "targetHealthAP")*me.ap
      damage = damage + targetHealth*target.health
   end
   if target then
      damage = damage + GetLVal(spell, "targetMissingHealth")*(target.maxHealth - target.health)
   end

   if spell.damOnTarget and target then
      damage = damage + spell.damOnTarget(target)
   end

   -- this is technically not right. This should only count for SINGLE TARGETS
   -- it would be good to fix but I don't think it will cause a problem as aoe
   -- attacks don't generally rely on super accurate damage calculations as people who use
   -- a lot of AoE don't get muramana ;)
   if P.muramana then
      damage = damage + Damage(me.mana*.06, "P")
   end

   -- damage for modAA shouldn't be used without combingin with AA damage.
   -- add spellblade if it's not on to account for it's activation.
   -- if it's on AA will account for it so don't add it.
   if spell.modAA and not P[spell.modAA] then
   	-- if the mod is off then add the aa damage here
   	damage = damage + GetAADamage() + GetSpellbladeDamage(false) - GetSpellbladeDamage(true)
   end


   if type(damage) ~= "number" and damage.type ~= "H" and target then
      local mult = 1
      if HasMastery("havoc") then
         mult = mult + .03
      end
      if HasMastery("des") then
         mult = mult + .015
      end
      if HasMastery("executioner") then
         if target and GetHPerc(target) < .5 then
            mult = mult + .05
         end
      end
      damage = damage*mult
   end

   if spell.offModAA then
   	damage = damage + GetSpellbladeDamage(false) - GetSpellbladeDamage(true)
   end

   if spell.onHit then
      damage = damage + GetOnHitDamage(target, false)
   end

   if target then
      if HasBuff("dfg", target) then
         damage.m = damage.m*1.2
      end
      if HasBuff("hemoplague", target) then
         damage.m = damage.m*1.12
      end
      if not ignoreResists then
      	damage = CalculateDamage(target, damage)
      end
   end


   if type(damage) ~= "number" and damage.type == "H" then
      damage = damage:toNum()
   end

   return damage
end

-- if you specify a target you get % health damage
-- if needSpellbladeActive is true check for sheen ready (for activated on hit abilities)
-- if needSpellbladeActive is nil or false it only adds sheen if it's already on
function GetOnHitDamage(target, needSpellbladeActive) -- gives your onhit damage broken down by magic,phys
   local damage = Damage()

   if GetInventorySlot(ITEMS["Nashor's Tooth"].id) then
      damage = damage + GetSpellDamage(ITEMS["Nashor's Tooth"])
   end
   if GetInventorySlot(ITEMS["Wit's End"].id) then
      damage = damage + GetSpellDamage(ITEMS["Wit's End"])
   end

   damage = damage + GetSpellbladeDamage(needSpellbladeActive)

   if GetInventorySlot(ITEMS["Blade of the Ruined King"].id) then
      if target then
         damage = damage + Damage(target.health*.08, "P")
      end
   end

   if GetInventorySlot(ITEMS["Kitae's Bloodrazor"].id) then
      if target then
         damage = damage + Damage(target.maxHealth*.025, "M")
      end
   end
   return damage
end

-- treating all as phys as it's so much easier
function GetSpellbladeDamage(needActive)
   return getSBDam(ITEMS["Lich Bane"], P.lichbane, needActive) +
          getSBDam(ITEMS["Trinity Force"], P.enrage, needActive) +
          getSBDam(ITEMS["Iceborn Gauntlet"], P.iceborn, needActive) +
          getSBDam(ITEMS["Sheen"], P.enrage, needActive)
end

function getSBDam(item, buff, needActive)
   local slot = GetInventorySlot(item.id)
   if slot then
      if buff or (not needActive and CanUse(item)) then
         return GetSpellDamage(item)
      end
   end
   return Damage()
end

function GetKnockback(thing, source, target)
   local spell = GetSpell(thing)
   local a = target.x - source.x
   local b = target.z - source.z 
   
   local angle = math.atan(a/b)
   
   if b < 0 then
      angle = angle+math.pi
   end

   return ProjectionA(target, angle, GetLVal(spell, "knockback"))
end

local trackTime = .75
tfas = {}
function TrackSpellFireahead(thing, target)
   local spell = GetSpell(thing)   
   local key = spell.key
   local tcn = target.charName

   if not tfas[key] then
      tfas[key] = {}
   end
   if not IsValid(target) or not tfas[key][tcn] then
      tfas[key][tcn] = {}
   end
   local p = Point(GetFireahead(target, spell.delay, spell.speed)) - Point(target)
   p.y = 0
   table.insert(tfas[key][tcn], p)

   local trackTicks = trackTime/TICK_DELAY
   if #tfas[key][tcn] > trackTicks then
      table.remove(tfas[key][tcn], 1)
   end
end

function GetSpellFireahead2(thing, target)
   local spell = GetSpell(thing)

   local point, chance
   if IsLinearSkillShot(spell) then
		point, chance = YP:GetLineCastPosition(target, spell.delay/10, spell.width, spell.range, spell.speed*100, me)
	else
		point, chance = YP:GetCircularCastPosition(target, spell.delay/10, spell.radius, spell.range, spell.speed*100, me)
	end

	if true then
		return point, chance
	end

   local trackingFudge = 0
   if tfas[spell.key] then   
   	local trackedPoints = tfas[spell.key][target.charName]
   	if trackedPoints and #trackedPoints > 1 then
	      local trackError = GetDistance(trackedPoints[1], trackedPoints[#trackedPoints])
	      local r = spell.width or spell.cone or spell.radius*2 

	      trackingFudge = 1 + (trackError/r * .25)
	   end
   end

   local fudge = math.max(SS_FUDGE, trackingFudge)

   return Point(GetFireahead(target, spell.delay/fudge, spell.speed*fudge))
   -- end

   -- return Point(target) + GetCenter(tfas[spell.key][target.charName])
end

-- do fireahead calculations with a speedup to account for player direction changes
SS_FUDGE = 1.25

function GetSpellFireahead(thing, target)
   local spell = GetSpell(thing)

   local trackingFudge = 0
   if tfas[spell.key] then   
   	local trackedPoints = tfas[spell.key][target.charName]
   	if trackedPoints and #trackedPoints > 1 then
	      local trackError = GetDistance(trackedPoints[1], trackedPoints[#trackedPoints])
	      local r = spell.width or spell.cone or spell.radius*2 

	      trackingFudge = 1 + (trackError/r * .1)
	   end
   end

   local fudge = trackingFudge

   local chance = 2 - fudge

   return Point(GetFireahead(target, spell.delay/fudge, spell.speed*fudge)), chance
   -- end

   -- return Point(target) + GetCenter(tfas[spell.key][target.charName])
end

function GetFireaheads(thing, targets)
   local fas = {}
   for _,target in ipairs(targets) do
      local fa = GetSpellFireahead(thing, target)
      fa.unit = target
      table.insert(fas, fa)
   end
   return fas
end

function IsGoodFireahead(thing, target)
	-- PrintAction("SS", target.name)
   local spell = GetSpell(thing)
   if not IsValid(target) and not IsImmune(thing, target) then return false end   
    -- check for "goodness". I'm testing good is when the tfas are all the same (or similar)
    -- this should imply that the target is moving steadily.

   local point, chance = GetSpellFireahead(spell, target)

   point.name = target.name
   if GetDistance(point) > GetSpellRange(spell) then
   	-- PrintAction("SS oor")
      return false
   end

   if chance < .2 then
   	-- PrintAction("Low chance SS")
   	return false
   end

   local blockers = concat(MINIONS, ENEMIES, PETS)
   blockers = RemoveFromList(blockers, {target})
   if not spell.noblock and IsBlocked(point, thing, me, blockers) then
   	-- PrintAction("SS blocked")
 		return false
   end

   if spell.overShoot then
      point = OverShoot(me, point, spell.overShoot)
   end

   -- TODO do something better!
   if IsSolid(point) then -- don't shoot into walls
   	PrintAction("Don't shoot into walls")
      return false
   end

	return true
end

function GetGoodFireaheads(thing, ...)
   return FilterList(
      concat(...), 
      function(item)
         return IsGoodFireahead(thing, item)
      end
   )
end

function ICast(thing, unit, spell)
   if not IsMe(unit) then return false end
   local mySpell = GetSpell(thing)
   if #mySpell.key > 1 then -- hack for if getspell fails
      return find(spell.name, thing)      
   else
      if mySpell.name then
         return find(spell.name, mySpell.name)
      else
         return spell.name == me["SpellName"..mySpell.key]
      end
   end
end

function IsSkillShot(thing)
	local spell = GetSpell(thing)
	if not spell then return false end

	return spell.speed and spell.delay 
end

function IsLinearSkillShot(thing)
	local spell = GetSpell(thing)
	if not spell then return false end

	return spell.delay and spell.speed and spell.speed > 0
end

function IsBlockedSkillShot(thing)
	local spell = GetSpell(thing)
	if not spell then return false end

	return IsLinearSkillShot(thing) and not spell.noblock
end

function DrawCone(source, angle, arc, dist)
   local a1 = angle - arc/2
   local a2 = angle + arc/2
   local p1 = ProjectionA(source, a1, dist)
   local p2 = ProjectionA(source, a2, dist)
   LineBetween(source, p1)
   LineBetween(source, p2)
end

function DrawSpellCone(thing)
	local spell = GetSpell(thing)

	local a = AngleBetween(me, mousePos)
   local a1 = a - DegsToRads(spell.cone)/2
   local a2 = a + DegsToRads(spell.cone)/2
   local p1 = ProjectionA(me, a1, GetSpellRange(thing))
   local p2 = ProjectionA(me, a2, GetSpellRange(thing))
   LineBetween(me, p1)
   LineBetween(me, p2)
end

function DrawReticule(thing)
	local spell = GetSpell(thing)
	if spell.cone then
		DrawSpellCone(spell)
	elseif spell.delay or spell.radius then
		if spell.speed and spell.speed > 0 then
			LineBetween(me, mousePos, spell.width)
		end
		Circle(mousePos, spell.radius)
	end
end
