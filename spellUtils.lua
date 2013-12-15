require "basicUtils"
require "items"
require "persist"
require "telemetry"

-- common spell defs
spells = {}

function IsCooledDown(key)
   return me["SpellTime"..key] >= .8
end

function Cast(thing, target, force)
   local spell = GetSpell(thing)
   if not spell then spell = thing end

   if not force and not CanUse(spell) then
      pp("can't use "..spell.key)
      pp(debug.traceback())
      return false
   end

   if not target then 
      pp("no target for "..spell.key)
      return false
   end

   CastSpellTarget(spell.key, target, 0)
   return true
end

function CastXYZ(thing, x,y,z)
   local spell = GetSpell(thing)
   if not spell then return end
   if x and not y and not z then
      Circle(x, 100, red, 5)
      CastSpellXYZ(spell.key, x.x,x.y,x.z, 0)      
   else
      CastSpellXYZ(spell.key, x,y,z, 0)
   end
end

function CastFireahead(thing, target)
   if not target then return false end

   local spell = GetSpell(thing)   
   if not spell.speed then spell.speed = 20 end
   if not spell.delay then spell.delay = 2 end

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
         if me.mana >= GetSpellCost(thing) then             
            return CanUse(thing.key)
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
         return GetSpellLevel(thing) > 0 and IsCooledDown(thing) -- should be a spell key "Q"
      end
   end
   pp("Failed to get spell for "..thing)
end

function GetSpellCost(thing)
   local spell = GetSpell(thing)
   if spell.cost then
      if type(spell.cost) == "table" then
         return spell.cost[GetSpellLevel(spell.key)] or 0
      elseif type(spell.cost) == "number" then
         return spell.cost or 0
      else
         return spell.cost() or 0
      end
   end
   return 0
end

function GetSpellRange(thing)
   local spell = GetSpell(thing)
   if type(spell.range) == "table" then
      local lvl = GetSpellLevel(spell.key)
      if lvl == 0 then
         return 0
      end
      return spell.range[GetSpellLevel(spell.key)]
   elseif type(spell.range) == "number" then
      return spell.range
   else
      return spell.range()
   end
   return 0
end

function GetSpell(thing)
   local spell
   if type(thing) == "table" then
      spell = thing
   else
      spell = spells[thing]
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
   if type(spell[field]) == "number" then
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

function GetSpellDamage(thing, target)
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


   local damage = GetLVal(spell, "base")

   if spell.ap then
      damage = damage + GetLVal(spell, "ap")*me.ap
   end
   if spell.ad then
      damage = damage + GetLVal(spell, "ad")*(me.baseDamage+me.addDamage)
   end
   if spell.adBonus then
      damage = damage + GetLVal(spell, "adBonus")*me.addDamage
   end
   if spell.adBase then
      damage = damage + GetLVal(spell, "adBase")*me.baseDamage
   end
   if spell.mana then
      damage = damage + GetLVal(spell, "mana")*me.maxMana
   end
   if spell.armor then
      damage = damage + GetLVal(spell, "armor")*me.armor
   end
   if spell.lvl then
      damage = damage + GetLVal(spell, "lvl")*me.selflevel
   end
   if spell.bonus then
      damage = damage + GetLVal(spell, "bonus")
   end
   if spell.percMaxHealth and target then
      damage = damage + GetLVal(spell, "percMaxHealth")*target.maxHealth
   end

   local damageT = 0
   local damageP = 0
   local damageM = 0

   if spell.type == "P" then
      damageP = damage
   elseif spell.type == "T" then
      damageT = damage
   else
      damageM = damage
   end

   damage = 0

   if spell.onHit then
      local ohd = GetOnHitDamage(target, false)
      damageM = damageM + ohd[1]
      damageP = damageP + ohd[2]
   end


   if target then
      if HasBuff("dfg", target) then
         damageM = damageM*1.2
      end
      damage = CalcDamage(target, damageP) +
               CalcMagicDamage(target, damageM) +
               damageT
   else
      damage = damageT + damageP + damageM
   end

   return math.floor(damage)
end

-- if you specify a target you get % health damage
-- if needSpellbladeActive is true check for sheen ready (for activated on hit abilities)
-- if needSpellbladeActive is nil or false it only adds sheen if it's already on
function GetOnHitDamage(target, needSpellbladeActive) -- gives your onhit damage broken down by magic,phys
   local damageM = 0
   local damageP = 0
   if GetInventorySlot(ITEMS["Nashor's Tooth"].id) then
      damageM = damageM + GetSpellDamage(ITEMS["Nashor's Tooth"])
   end
   if GetInventorySlot(ITEMS["Wit's End"].id) then
      damageM = damageM + GetSpellDamage(ITEMS["Wit's End"])
   end

   local spellbladeDamage = GetSpellbladeDamage(needSpellbladeActive)
   if spellbladeDamage then
      damageP = damageP + spellbladeDamage
   end

   if GetInventorySlot(ITEMS["Blade of the Ruined King"].id) then
      if target then
         damageP = damageP + target.health*.05
      end
   end

   if GetInventorySlot(ITEMS["Kitae's Bloodrazor"].id) then
      if target then
         damageM = damageM + target.maxHealth*.025
      end
   end
   return {damageM, damageP}
end

-- treating all as phys as it's so much easier
function GetSpellbladeDamage(needActive)
   return getSBDam(ITEMS["Lich Bane"], P.lichbane, needActive) or
          getSBDam(ITEMS["Trinity Force"], P.enrage, needActive) or
          getSBDam(ITEMS["Iceborn Gauntlet"], P.iceborn, needActive) or
          getSBDam(ITEMS["Sheen"], P.enrage, needActive)
end

function getSBDam(item, buff, needActive)
   local slot = GetInventorySlot(item.id)
   if slot then
      if buff or (not needActive and CanUse(item)) then
         return GetSpellDamage(item)
      end
   end
   return nil
end

local trackTicks = 5
tfas = {}
function TrackSpellFireahead(thing, target)
   local spell = GetSpell(thing)   
   local key = spell.key
   local tcn = target.charName

   if not tfas[key] then
      tfas[key] = {}
   end
   if not ValidTarget(target) or not tfas[key][tcn] then
      tfas[key][tcn] = {}
   end

   table.insert(tfas[key][tcn], Point(GetFireahead(target, spell.delay, spell.speed)) - Point(target))
   if #tfas[key][tcn] > trackTicks then
      table.remove(tfas[key][tcn], 1)
   end
end

function GetSpellFireahead(thing, target)   
   local spell = GetSpell(thing)
   if not tfas[spell.key] or not tfas[spell.key][target.charName] then
      pp("faking fireahead")
      return Point(GetFireahead(target, spell.delay, spell.speed*SS_FUDGE))
   end

   return Point(target) + GetCenter(tfas[spell.key][target.charName])
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
   local spell = GetSpell(thing)
   if not ValidTarget(target) then return false end   
    -- check for "goodness". I'm testing good is when the tfas are all the same (or similar)
    -- this should imply that the target is moving steadily.

   local point = GetSpellFireahead(spell, target)
   if spell.overShoot then
      point = OverShoot(me, point, spell.overShoot)
   end

   if GetDistance(point) > GetSpellRange(spell) then
      return false
   end

   if GetDistance(target, point) < 75 then
      return true
   end

   -- for collision skill shots dead on or dead away people are easy to hit
   -- no spell speed is a short cut for this. Gragas barrel won't work the best.
   if spell.speed > 0 then
      if ApproachAngleRel(target, me) < 10 then
         return true
      end
   end

   -- local r = spell.width or spell.radius

   local tps = tfas[spell.key][target.charName]
   local point = GetCenter(tps)
   if GetDistance(tps[1], point) < 50 and
      GetDistance(tps[#tps], point) < 50
   then
      return true
   end

   return false   
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

