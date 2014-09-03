require "Utils"
require "issuefree/utils_scriptconfig"
require "winapi"
ModuleConfig = scriptConfig("Module Config", "modules")
require "issuefree/basicUtils"
require "issuefree/spell_shot"
require "issuefree/telemetry"
require "issuefree/drawing"
require "issuefree/items"
require "issuefree/autoAttackUtil"
-- yayo = require "Common/yayo"
require "issuefree/persist"
require "issuefree/spellUtils"
require "issuefree/toggles"
require "issuefree/walls"

require "issuefree/champWealth"

send = require "Common/SendInput"

require "Common/SKeys"

-- function CanAct()
--    return yayo.CanMove()
-- end
-- function CanMove()
--    return yayo.CanMove()
-- end
-- function CanAttack()
--    return yayo.CanAttack()
-- end

SetScriptTimer(10)

FRAME = time()

if me.SpellLevelQ == 0 and
   me.SpellLevelW == 0 and
   me.SpellLevelE == 0
then
   os.remove("lualog.txt")
   MoveToXYZ(me.x, me.y, me.z)
end

healSpell = {range=700+GetWidth(me), color=green, summoners=true}

if me.SpellNameD == "SummonerHeal" then
   spells["summonerHeal"] = healSpell
   spells["summonerHeal"].key = "D"
elseif me.SpellNameF == "SummonerHeal" then
   spells["summonerHeal"] = healSpell
   spells["summonerHeal"].key = "F"
end

MASTERIES = {}
BLOCK_FOR_AA = true
CHAMP_STYLE = nil
function SetChampStyle(style)
   CHAMP_STYLE = style
   if style == "caster" then
      MASTERIES = {"executioner"} -- "havoc", "des", -- might not be applied to minions?
      BLOCK_FOR_AA = false
   elseif style == "marksman" then
      MASTERIES = {"executioner"} -- "havoc", 
   elseif style == "bruiser" then
   elseif style == "support" then
      BLOCK_FOR_AA = false
   end
end

function HasMastery(mastery)
   return ListContains("havoc", MASTERIES)
end


local lastActions = {}
local lastActionsTimes = {}
local lastAction = nil
local lastActionTime = time()
function PrintAction(str, target, timeout)
   for i,t in rpairs(lastActionsTimes) do
      if time() > t then
         table.remove(lastActions, i)
         table.remove(lastActionsTimes, i)
      end
   end
   if str == nil then 
      lastAction = nil
      return
   end
   if str ~= lastAction and not ListContains(str, lastActions) then
      local ttl = math.floor((time() - lastActionTime)*100)/100
      local out = " # "..str
      if target then
         if type(target) == "string" or
            type(target) == "number"
         then
            out = out.." : "..target
         else
            out = out.." -> "..target.name
         end
      end
      local spaces = ""
      for i=1, 50-string.len(out), 1 do
         spaces = spaces.." "
      end
      pp(out..spaces.."+"..ttl)
      lastActionTime = time()
      if not timeout then
         lastAction = str
      else      
         table.insert(lastActions, str)
         table.insert(lastActionsTimes, time()+timeout)
      end
   end
end

LOADING = true

ACTIVE_SKILL_SHOTS = {}
function addSkillShot(spellShot)
   table.insert(ACTIVE_SKILL_SHOTS, spellShot)
end

local function OnKey(msg, key)
   if msg == WM_LBUTTONUP then
      MarkTarget()
   end
end
function AddOnKey(callback)
   RegisterLibraryOnWndMsg(callback)
end
AddOnKey(OnKey)

-- globals for convenience
hotKey = GetScriptKey()
playerTeam = ""


spells["AA"] = {
   range=GetAARange(), 
   base={0}, 
   ad=1,
   type="P", 
   color=red,
   name="attack"   
}

CHAR_SPELLS = {}

HOME = nil

repeat
   if string.format(me.team) == "100" then
      playerTeam = "Blue"
      HOME = {x=27, z=265}
   elseif string.format(me.team) == "200" then  
      playerTeam = "Red"
      HOME = {x=13923, z=14169}
   end
until playerTeam ~= nil and playerTeam ~= "0"

local wall = {}

-- for line in io.lines("walls4.txt") do
--    for x, z in string.gmatch(line, "(%d+)%.*%d*, (%d+)%.*%d*") do
--       table.insert(wall, Point(x, 0, z))
--    end
-- end

local function drawCommon()
   DrawHeroWealth()

   if me.dead == 1 then
      return
   end

   for i=1,#wall-1,1 do
      if GetDistance(wall[i], wall[i+1]) < 250 then
         LineBetween(wall[i], wall[i+1])
      end
   end

   for _,turret in ipairs(TURRETS) do
      Circle(turret, 950, red)
   end

   for _,minion in ipairs(MINIONS) do
      if IsValid(minion) and GetDistance(minion) < 2000 then
         local hits = math.ceil(minion.health/GetAADamage(minion))
         if hits == 1 then
            DrawTextObject(hits.." hp", minion, blueT)
            Circle(minion, 50, red, 3)
         elseif hits <= 3 then
            DrawTextObject(hits.." hp", minion, greenT)
         end

         for _,spell in pairs(spells) do
            if spell.lh and CanUse(spell) and GetDistance(minion) < GetSpellRange(spell)*1.5 then
               if WillKill(spell, minion) then
                  if spell.key == "Q" then
                     Circle(minion, 55, spell.color, 2)
                  elseif spell.key =="W" then
                     Circle(minion, 60, spell.color, 2)
                  elseif spell.key =="E" then
                     Circle(minion, 65, spell.color, 2)
                  elseif spell.key =="R" then
                     Circle(minion, 70, spell.color, 2)
                  end
               end
            end
         end
      end
   end

   if P.markedTarget then
      Circle(P.markedTarget, nil, red, 7)
   end


   if tfas then
      for key,spell in pairs(tfas) do
         local activeSpell = GetSpell(key)

         if activeSpell and activeSpell.showFireahead then
            for name,trackedPoints in pairs(spell) do
               local target
               for _,enemy in ipairs(ENEMIES) do
                  if enemy.charName == name then
                     target = enemy
                     break
                  end
               end

               if not target then break end
               local point, chance = GetSpellFireahead(key, target)

               if GetDistance(point) < GetSpellRange(activeSpell)+100 then

                  if chance > .75 then
                     Circle(point, 50, green, 3)
                  elseif chance > .5 then
                     Circle(point, 50, green, 2)                  
                  elseif chance > .25 then
                     Circle(point, 50, green, 1)
                  end
                  LineBetween(target, point)
               end
            end
         end
      end
   end

   for i,shot in rpairs(ACTIVE_SKILL_SHOTS) do
      if shot.timeOut < time() then
         table.remove(ACTIVE_SKILL_SHOTS, i)
      else
         if shot.safePoint then
            Circle(shot.safePoint)
         end
         if shot.isline then
            LineBetween(shot.startPoint, Projection(shot.startPoint, shot.endPoint, GetDistance(shot.startPoint, shot.endPoint)+shot.radius), shot.radius)
         end
         if not shot.isline or shot.point then
            Circle(shot.endPoint, shot.radius, blue, 4)
         end
      end
   end
end

function LoadConfig(name)
   local status, config = pcall( 
      function()
         local config = {}
         for line in io.lines(name..".cfg") do
            for k,v in string.gmatch(line, "(%w+)=(%w+)") do
               config[k] = v
            end
         end
         return config
      end 
   )
   if status then return config end
end

function SaveConfig(name, config)
   local file = io.open(name..".cfg", "w")
   for k,v in pairs(config) do
      file:write(k.."="..v.."\n")
   end
   file:close()
end

function doCreateObj(object)
   if not (object and object.x and object.z) then
      return
   end

   createForPersist(object)

   for spell, info in pairs(DISRUPTS) do
      persistForDisrupt(info.char, info.obj, spell, object)
   end

   -- if IsHero(object) and not CHAR_SPELLS[object.name] then
   --    CHAR_SPELLS[object.name] = LoadConfig("charSpells/"..object.name)
   --    if not CHAR_SPELLS[object.name] then
   --       CHAR_SPELLS[object.name] = {}
   --    end
   -- end

   for _,name in ipairs(channeledSpells) do
      if spells[name] and spells[name].channel then
         if spells[name].object then
            if spells[name].objectTimeout then
               if object and 
                  find(object.charName, spells[name].object) and
                  GetDistance(object) < 200
               then
                  PersistTemp(name, spells[name].objectTimeout)
                  -- PrintAction("found a channel temp object "..object.charName.." for "..name)
               end
            else               
               if PersistBuff(name, object, spells[name].object, 200) then
                  PrintAction("found a channel object "..object.charName.." for "..name)
               end
            end
         else
            if not spells[name].channelTime then
               pp("cast a channeled spell "..name.." without a persisting object or channel time")
            end
         end
      end
   end

   for i, callback in ipairs(OBJECT_CALLBACKS) do
      callback(object)
   end
end 

function persistForDisrupt(char, oName, label, object)
   if find(object.charName, oName) then
      for _,enemy in ipairs(ENEMIES) do
         if enemy.name == char and GetDistance(enemy, object) < 150 then
            Persist(char, enemy, enemy.charName)
            break
         end
      end
      if P[char] and GetDistance(P[char], object) < 150 then
         Persist(label, object, oName)
      end
   end
end

function Disrupt(targetSpell, thing)
   local spell = GetSpell(thing)
   if not CanUse(spell) then 
      return false
   end
   if P[targetSpell] then
      local target = P[DISRUPTS[targetSpell].char]
      if IsInRange(spell, target) then
         if spell.delay then
            if spell.noblock then
               CastXYZ(spell, target)
            else
               if IsUnblocked(target, spell, me, MINIONS, ENEMIES) then
                  CastXYZ(spell, target)
               else
                  return false
               end
            end
         else
            Cast(spell, target)
         end         
         PrintAction(thing.." to disrupt "..targetSpell, target)
         P[targetSpell] = nil
         return true
      end
   end
   return false
end

STALLERS = {
   'katarinar',
   'drain',
   'crowstorm',
   'consume',
   'absolutezero',
   'rocketgrab',
   'staticfield',
   'cassiopeiapetrifyinggaze',
   'ezrealtrueshotbarrage',
   'galioidolofdurand',
   'gragasdrunkenrage',
   'luxmalicecannon',
   'reapthewhirlwind',
   'jinxw',
   'jinxr',
   'missfortunebullettime',
   'shenstandunited',
   'threshe',
   'threshrpenta',
   'infiniteduress',
   'meditate',
}

GAPCLOSERS = {
   'AkaliShadowDance', 
   'Headbutt', 
   'DariusExecute', 
   'DianaTeleport', 
   'EliseSpiderQCast', 
   'FioraQ', 
   'UrchinStrike', 
   'IreliaGatotsu', 
   'JarvanIVCataclysm', 
   'JaxLeapStrike', 
   'JayceToTheSkies', 
   'blindmonkqtwo', 
   'BlindMonkWOne', 
   'MaokaiUnstableGrowth', 
   'AlphaStrike', 
   'NocturneParanoia', 
   'Pantheon_LeapBash', 
   'MonkeyKingNimbus', 
   'XenZhaoSweep', 
   'ViR', 
   'YasuoDashWrapper', 
   'TalonCutthroat', 
   'KatarinaE', 
   'InfiniteDuress'
}

DASHES = {
   AatroxQ=650,
   AhriTumble=550,
   CarpetBomb=800,
   GragasBodySlam=600,
   GravesMove=425,
   LucianE=425,
   RenektonSliceAndDice=450,
   SejuaniArcticAssault=650,
   ShenShadowDash=600,
   ShyvanaTransformCast=1000,
   slashCast=660,
   ViQ=725,
   FizzJump=400,
   HecarimUlt=1000,
   KhazixE=600,
   khazixelong=900,
   LeblancSlide=600,
   LeblancSlideM=600,
   UFSlash=1000,
   Pounce=375,
   Deceive=400,
   VayneTumble=300,
   RivenTriCleave=260,
   RivenFeint=325,
   EzrealArcaneShift=475,
   RiftWalk=700,
   RocketJump=900,
}

function PredictEnemy(unit, spell)
   if IsEnemy(unit) then
      if ListContains(spell.name, STALLERS) then
         return Point(unit), unit
      elseif ListContains(spell.name, GAPCLOSERS) then
         return Point(spell.endPos), unit
      end
      for name,range in pairs(DASHES) do
         if spell.name == name then
            local p = Point(spell.endPos)
            if GetDistance(unit, p) > range then
               p = Projection(unit, p, range)
               return p, unit
            end
         end
      end
   end
   return nil
end


function DumpCloseObjects(object)
   if GetDistance(object) < 50 then
      pp(object.name.." "..object.charName)
   end
end
function DumpSpells(unit, spell)
   if unit.name == me.name then
      pp(unit.name.." "..spell.name)
   end
end

function IsMinion(unit)
   if not IsValid(unit) then return false end
   return find(unit.name, "Minion")
end

function IsBigMinion(minion)
   return find(minion.name, "MechCannon")
end

function IsSuperMinion(minion)
   return find(minion.name, "MechMelee")
end

function IsHero(unit)
   return unit.type == 20
   -- for _,hero in ipairs(concat(ALLIES, ENEMIES)) do
   --    if SameUnit(unit, hero) then
   --       return true
   --    end
   -- end
   -- return false
end

function IsEnemy(unit)
   if not unit then return false end
   return unit.team ~= me.team and IsHero(unit)
end

function IsValid(target)
   if not target or not target.x then
      return false
   end
   if target.dead == 1 or target.invulnerable == 1 then
      return false
   end
   if target.visible == 0 then
      if target.type == 36 then

      else
         return false
      end
   end
   return true
end

function ValidTargets(list)
   if not list then return {} end
   return FilterList(list, 
      function(item)
         return IsValid(item)
      end
   )
end

local function updateObjects()
   local mark = GetMarkedTarget()
   if mark then
      if mark.dead == 1 or mark.visible == 0 or GetDistance(mark) > 1750 then
         P.markedTarget = nil
      end
   end

   cleanWillKills()
end

WILL_KILLS = {}
WILL_KILLS_TIMEOUTS = {}
WILL_KILLS_BY_SPELL = {}

function AddWillKill(items, spellName)
   assert(spellName)

   if type(items) ~= "table"  then
      AddWillKill({items}, spellName)
      return
   end

   spellName = spellName or "nil"

   local timeout = time()+.75
   for _,item in ipairs(items) do
      table.insert(WILL_KILLS, item)
      table.insert(WILL_KILLS_TIMEOUTS, timeout)
      table.insert(WILL_KILLS_BY_SPELL, spellName)
   end
end

function RemoveWillKills(list, spellName)
   assert(spellName)
   for i,sn in rpairs(WILL_KILLS_BY_SPELL) do
      if sn == spellName then
         table.remove(WILL_KILLS, i)
         table.remove(WILL_KILLS_TIMEOUTS, i)
         table.remove(WILL_KILLS_BY_SPELL, i)
      end
   end

   return FilterList(list, function(item) return not ListContains(item, WILL_KILLS) end)
end

function cleanWillKills()
   for i,_ in rpairs(WILL_KILLS_TIMEOUTS) do
      if time() > WILL_KILLS_TIMEOUTS[i] then
         table.remove(WILL_KILLS, i)
         table.remove(WILL_KILLS_TIMEOUTS, i)
         table.remove(WILL_KILLS_BY_SPELL, i)
      end
   end
end

function GetNearestCreep()
   return SortByDistance(CREEPS)[1]
end
function GetGolem()
   for _,creep in ipairs(SortByDistance(CREEPS)) do
      if find(creep.name, "AncientGolem") then
         return creep
      end
   end
end
function GetLizard()
   for _,creep in ipairs(SortByDistance(CREEPS)) do
      if find(creep.name, "LizardElder") then
         return creep
      end
   end
end
function GetWraith()
   for _,creep in ipairs(SortByDistance(CREEPS)) do
      if creep.name == "Wraith" then
         return creep
      end
   end
end

function cloneTarget(target)
   local t = {}
   t.x = target.x
   t.y = target.y
   t.z = target.z
   t.health = target.health
   t.maxHealth = target.maxHealth
   t.armor = target.armor
   return t
end

THROTTLES = {}
function throttle(id, millis)
   -- first time, set a timer and return false
   if THROTTLES[id] == nil then
      THROTTLES[id] = GetClock() + millis
      return false
   -- Enough time has passed, reset the clock and return false
   elseif GetClock() > THROTTLES[id] then
      THROTTLES[id] = GetClock() + millis
      return false
   end
   return true
end

function CastBest(thing)
   local spell = GetSpell(thing)
   if not spell or not CanUse(spell) then
      return false
   end
   local target = GetMarkedTarget() or GetWeakestEnemy(thing)
   if target then
      Cast(thing, target)
      PrintAction(thing, target)
      return true
   end
   return false
end

-- "mark" the enemy closest to a mouse click (i.e. click to mark)
function MarkTarget(target)
   if target and IsEnemy(target) then
      Persist("markedTarget", target)
      return target
   end
   if #GetInRange(GetMousePos(), 500, ENEMIES) == 0 then
      P.markedTarget = nil
      return
   end
   local targets = SortByDistance(GetInRange(mousePos, 200, ENEMIES), GetMousePos())
   if targets[1] then
      Persist("markedTarget", targets[1])
      return targets[1]
   end
end
function GetMarkedTarget()
   return P.markedTarget
end


function MoveToTarget(t)
   if CanMove() then
      local x,y,z = GetFireahead(t, 2.5, 0)
      MoveToXYZ(x,y,z)
      CURSOR = Point(x,y,z)
      PrintAction("MTT", t, 1)
      return true
   end
   return false
end

function MoveToCursor()
   if not CanMove() then
      return
   end
   -- local moveSqr = math.sqrt((mousePos.x - myHero.x)^2+(mousePos.z - myHero.z)^2)
   -- if moveSqr < 1000 then
   --    local moveX = myHero.x + 300*((mousePos.x - myHero.x)/moveSqr)
   --    local moveZ = myHero.z + 300*((mousePos.z - myHero.z)/moveSqr)
   --    -- pp(GetDistance(me, {x=moveX, y=me.y, z=moveZ}))
   --    MoveToXYZ(moveX,myHero.y,moveZ)
   -- else
   if GetDistance(mousePos) < 10 then
      StopMove()
   else
      MoveToMouse()
   end
end

-- weak, far, near, strong
-- if force is false, try to play nice with auto attacking lasthits
-- if force is true, kill it now.
function KillMinion(thing, method, force, targetOnly)
   local spell = GetSpell(thing)
   if not CanUse(spell) then return false end
   
   if spell.name and spell.name == "attack" then
      force = true
   end

   method = method or "weak"

   local minions 
   if IsBlockedSkillShot(thing) then
      minions = RemoveWillKills(GetKills(thing, GetIntersection(MINIONS, GetUnblocked(thing, me, MINIONS, ENEMIES, PETS))), thing)
   else
      minions = RemoveWillKills(GetKills(thing, GetInRange(me, thing, MINIONS)), thing)
   end      

   local ignoreMana = false

   if method == "weak" then
      SortByHealth(minions, spell)
   elseif method == "far" then
      SortByDistance(minions)
      minions = reverse(minions)
   elseif method == "near" then
      SortByDistance(minions)
   elseif method == "strong" then
      SortByHealth(minions, spell)
      minions = reverse(minions)
   elseif method == "burn" then
      ignoreMana = true
   end



   local targets = {}

   local spellName = GetSpellName(thing)
   -- first pass to prioritize big minions (yeah I'll get dup minions but who cares)
   for _,minion in ipairs(minions) do
      if IsBigMinion(minion) then
         table.insert(targets, minion)
      end
   end

   for _,minion in ipairs(minions) do
      table.insert(targets, minion)
   end

   local target = nil
   for _,minion in ipairs(targets) do
      if force then
         target = minion
         break
      else
         rangeThresh = GetAARange()
         if IsMelee(me) then
            rangeThresh = GetAARange() + 25
         end
         if JustAttacked() or
            GetDistance(minion) > rangeThresh or
            GetAADamage(minion)*1.5 < minion.health
         then
            target = minion
            break
         end
      end
   end

   if IsValid(target) then

      if not ignoreMana then
         local score = 1
         if IsBigMinion(target) then
            score = 1.5
         end
         if GetThreshMP(thing, .1) > score then
            return nil
         end
      end

      if targetOnly then
         return target
      end


      AddWillKill(target, thing)

      if spell.name and spell.name == "attack" then
         AA(target)
         PrintAction("Kill "..method.." minion")
         return target
      else
         if IsSkillShot(thing) then
            CastFireahead(thing, target)
         else
            Cast(spell, target)
         end
         -- pp("setting lkms to "..spellName)
         PrintAction(spellName.." "..method.." minion")
         return target
      end
   end

   return false
end

-- weak, far, near, strong
function HitMinion(thing, method, extraRange)
   if not CanUse(thing) then return false end

   local spell = GetSpell(thing)

   if not extraRange then extraRange = 0 end
   if not method then method = "weak" end

   local minions = GetInRange(me, GetSpellRange(spell)+extraRange, MINIONS)
   if method == "weak" then
      SortByHealth(minions, spell)
   elseif method == "far" then
      SortByDistance(minions)
      minions = reverse(minions)
   elseif method == "near" then
      SortByDistance(minions)
   elseif method == "strong" then
      SortByHealth(minions, spell)
      minions = reverse(minions)
   end

   for _,minion in ipairs(minions) do
      if spell.name and spell.name == "attack" then
         if AA(minion) then
            PrintAction("AA "..method.." minion")
            return true
         end
      else
         Cast(spell, minion)
         PrintAction(thing.." "..method.." minion")
         return true
      end
   end
   return false
end

function HitObjectives()
   local targets = GetInRange(me, GetAARange()+50, TURRETS, INHIBS)
   table.sort(targets, function(a,b) return a.maxhealth > b.maxhealth end)

   if targets[1] and CanAttack() then
      if AA(targets[1]) then
         PrintAction("Hit objective", target)
         return true
      end
   end
   return false
end

function scoreHits(spell, hits, hitScore, killScore)
   local score = #hits*hitScore
   local kills = {}

   if killScore ~= 0 then     
      for _,hit in ipairs(hits) do
         if WillKill(spell, hit) then
            if IsBigMinion(hit) then
               score = score + (killScore / 2)
            end
            score = score + killScore
            table.insert(kills, hit)
         end
      end
   end
   return score, kills
end

function GetThreshMP(thing, mPercHit, min)
   mPercHit = mPercHit or .1
   min = min or 1
   local thresh = GetSpellCostPerc(thing)/mPercHit
   if CanChargeTear() then
      thresh = thresh * .5
   end
   if VeryAlone() then
      thresh = thresh * .8
   end
   if GetMPerc(me) == 1 then
      thresh = thresh * .5
   end
   return math.max(min, thresh)
end

function HitInShape(thing, GetBestF, targets, thresh, hs, ks, action)
   local spell = GetSpell(thing)
   if not spell or not CanUse(spell) then return false end

   thresh = thresh or GetThreshMP(thing, .1, 1.5)
   action = action or "hits"

   local hits, kills, score = GetBestF(me, thing, hs, ks, RemoveWillKills(targets, thing))
   if score >= thresh then
      AddWillKill(kills, thing)
      local point = GetCastPoint(hits, thing)
      if spell.overShoot then
         point = Projection(me, point, GetDistance(point)+spell.overShoot)
      end
      CastXYZ(thing, point)
      PrintAction(thing.." for "..action, score)
      return true
   end
   return false
end

local khs, kks = .05, .95
local hhs, hks = 1, .5

function KillMinionsInArea(thing, thresh)   
   if HitInShape(thing, GetBestArea, MINIONS, thresh, khs, kks, "kills") then
      return true
   end
end

function HitMinionsInArea(thing, thresh)
   if HitInShape(thing, GetBestArea, MINIONS, thresh, hhs, hks, "hits") then
      return true
   end
end

function KillMinionsInCone(thing, thresh)
   if HitInShape(thing, GetBestCone, MINIONS, thresh, khs, kks, "kills") then
      return true
   end
end

function HitMinionsInCone(thing, thresh)
   if HitInShape(thing, GetBestCone, MINIONS, thresh, hhs, hks, "hits") then
      return true
   end
end

function KillMinionsInLine(thing, thresh)
   if HitInShape(thing, GetBestLine, MINIONS, thresh, khs, kks, "kills") then
      return true
   end
end

function HitMinionsInLine(thing, thresh)
   if HitInShape(thing, GetBestLine, MINIONS, thresh, hhs, hks, "kills") then
      return true
   end
end

function KillMinionsInPB(thing, thresh)
   if HitInShape(thing, GetBestPB, MINIONS, thresh, khs, kks, "kills") then
      return true
   end
end

function HitMinionsInPB(thing, thresh)
   if HitInShape(thing, GetBestPB, MINIONS, thresh, hhs, hks, "hits") then
      return true
   end
end

-- returns hits, kills (if scored), score
function GetBestArea(source, thing, hitScore, killScore, ...)
   local spell = GetSpell(thing)
   if not spell.radius then
      pp("No radius set for.."..thing)
      return {}
   end

   local targets = GetInRange(source, GetSpellRange(spell)+spell.radius, concat(...))

   local bestS = 0
   local bestT = {}
   local bestK = {}
   for _,target in ipairs(targets) do
      -- get everything that could be hit and still hit the target (a double blast radius)
      local hits = GetInRange(target, spell.radius*2, targets)

      local center
      -- trim outliers until everyone fits
      while true do
         center = GetCastPoint(hits, spell, source)
         SortByDistance(hits, center)         
         if GetDistance(center, hits[#hits]) > spell.radius then
            table.remove(hits, #hits)
         else
            break
         end
      end

      local score, kills = scoreHits(spell, hits, hitScore, killScore)
      if not bestT or score > bestS then
         bestS = score
         bestT = hits
         bestK = kills
      end
   end
   return bestT, bestK, bestS
end

function GetBestCone(source, thing, hitScore, killScore, ...)
   local spell = GetSpell(thing)
   if not spell.cone then
      pp("No cone set for.. "..thing)
      return {}
   end

   local targets = GetInRange(source, thing, concat(...))
   if not spell.noblock then
      targets = GetIntersection(targets, GetUnblocked(thing, source, MINIONS, ENEMIES, PETS))
   end

   -- results variables
   local bestS = 0
   local bestT = {}
   local bestK = {}

   for _,target in ipairs(targets) do
      local hits = FilterList(targets, function(item) return RadsToDegs(RelativeAngleRight(me, target, item)) < spell.cone end)
      local score, kills = scoreHits(spell, hits, hitScore, killScore)

      if score > bestS then
         bestS = score
         bestT = hits
         bestK = kills
      end
   end
         
   return bestT, bestK, bestS
end

function GetBestLine(source, thing, hitScore, killScore, ...)
   local spell = GetSpell(thing)
   local width = spell.width or spell.radius
   if not width then
      spell.width = 80
      pp("No width set for "..thing)
   end

   local targets = GetInRange(source, spell, concat(...))

   local bestS = 0
   local bestT = {}
   local bestK = {}
   for _,target in ipairs(targets) do
      local hits = GetInLineR(source, spell, target, targets)
      local score, kills = scoreHits(spell, hits, hitScore, killScore)
      if not bestT or score > bestS then
         bestS = score
         bestT = hits
         bestK = kills
      end
   end

   return bestT, bestK, bestS
end

-- this is pretty obvious but I need it for the interface
function GetBestPB(source, thing, hitScore, killScore, ...)
   local hits = GetInRange(source, thing, concat(...))
   local score, kills = scoreHits(spell, hits, hitScore, killScore)
   return hits, kills, score
end

function SkillShot(thing, purpose, targets)
   local target = GetSkillShot(thing, purpose, targets)
   if target then
      CastFireahead(thing, target)
      PrintAction(thing, target)
      return target
   end
   return false
end

function GetSkillShot(thing, purpose, targets)
   local spell = GetSpell(thing)
   if not CanUse(spell) then return nil end

   targets = targets or ENEMIES   

   targets = GetInRange(me, GetSpellRange(spell)+500, targets)

   targets = GetGoodFireaheads(spell, targets)

   local target
   -- find the best target in the remaining unblocked
   if purpose == "peel" then
      target = GetPeel({ADC, APC, me}, targets)
   else
      target = GetWeakest(spell, targets)
   end
   
   return target
end

function GetOtherAllies()
   return FilterList(ALLIES, function(ally) return not IsMe(ally) end)
end

function HotKey()
   return IsKeyDown(hotKey) ~= 0
end

function IsRecalling(hero)
   return HasBuff("recall", hero)
end

function UseAutoItems()
   UseItem("Zhonya's Hourglass")
   UseItem("Wooglet's Witchcap")
   UseItem("Seraph's Embrace")
   UseItem("Mikael's Crucible")
   UseItem("Locket of the Iron Solari")
   UseItem("Crystaline Flask")
end

function GetNearestIndex(target, list)
   local nearDist = 10000
   local nearInd = nil
   for i,near in ipairs(list) do
      local tDist = GetDistance(target, near)
      if tDist < nearDist then
         nearInd = i
         nearDist = tDist
      end
   end
   return nearInd  
end

function GetKills(thing, list)
   list = RemoveWillKills(list, thing)
   local result = FilterList(list, 
      function(item) 
         if not item.health then return false end
         return WillKill(thing, item)
      end
   )
   return result
end

function CanChargeTear()
   local slot = GetInventorySlot(ITEMS["Tear of the Goddess"].id) or
                GetInventorySlot(ITEMS["Archangel's Staff"].id) or
                GetInventorySlot(ITEMS["Manamune"].id)   
   if not slot then
      return false
   end
   return IsCooledDown(slot)
end

function GetWardingSlot()
   local wardSlots = {
      3340, 3350, 3361, 3362, -- trinkets
      3154, -- wriggles
      2049, 2045, -- sightstones
      2044 -- sight ward
   }
   local wardSlot
   for _,id in ipairs(wardSlots) do
      local wardSlot = GetInventorySlot(id)
      if wardSlot and IsCooledDown(wardSlot) then
         return wardSlot
      end
   end
end

local wardCastTime = time() 
function WardJump(thing, pos)
   local spell = GetSpell(thing)
   if not CanUse(spell) then
      return false
   end

   if not pos then
      pos = GetMousePos()
   end

   local ward = SortByDistance(GetAllInRange(pos, 200, ALLIES, MYMINIONS, WARDS), pos)[1]

   -- there isn't so cast one and return, we'll jump on the next pass -- on second delay between casting wards to prevent doubles
   if not ward then
      if time() - wardCastTime > 3 then
         local wardSlot = GetWardingSlot()
         if wardSlot then
            CastXYZ(wardSlot, pos)
            PrintAction("Throw ward")
            wardCastTime = time()
         end
         return true
      end
   elseif GetDistance(ward) < GetSpellRange(spell) then
      -- Cast can't target wards as they're not visible
      Cast(spell, ward)
      StartChannel(.25)
      PrintAction("Jump to ward")
      return true
   end
   return false
end

function GetAADamage(target)   
   local damage = GetSpellDamage("AA", target, true)
   
   for name,spell in pairs(spells) do
      if spell.modAA and P[spell.modAA] then
         modSpell = copy(spell)
         modSpell.modAA = nil
         modSpell.offModAA = true
         damage = damage + GetSpellDamage(modSpell)
      end
   end

   -- items
   damage = damage + GetOnHitDamage(target, true)

   if target then
      damage = CalculateDamage(target, damage)
   else
      damage = damage:toNum()
   end
   return math.floor(damage+.5)
end

-- list of spells with the target being the last arg
function WillKill(...)
   local arg = GetVarArg(...)
   local target = arg[#arg]
   local damage = 0
   local usedMana = 0
   for i=1,#arg-1,1 do      
      local thing = arg[i]
      local spell = GetSpell(thing)
      if not IsImmune(thing, target) then
         if spell.name and spell.name == "attack" then
            damage = damage + GetAADamage(target)
         else         
            if CanUse(thing) and usedMana + GetSpellCost(thing) <= me.mana then
               damage = damage + GetSpellDamage(thing, target)
               usedMana = usedMana + GetSpellCost(thing)
            end
         end
      end
      if damage > target.health then
         return true
      end
   end
   return false
end

--[[
This should look at the allies in [save] in order 
and return an enemy in [stop] that is trying to kill that ally in [save]
--]]
function GetPeel(save, stop)
   for _,ally in ipairs(save) do
      SortByDistance(stop, ally)
      -- check if the target is moving "directly" toward this ally
      -- check if the target is close enough to the ally to be a threat
      for _,enemy in ipairs(stop) do
         if GetDistance(enemy, ally) < 500 then
            local aa = ApproachAngle(enemy, ally)
            if aa < 30 then
               return enemy
            end
         end
      end
   end
end

function GetHPerc(target)
   if not target then target = me end
   return target.health/target.maxHealth
end
function GetMPerc(target)
   if not target then target = me end
   return target.mana/target.maxMana
end

function AutoPet(pet)
   if pet then
      -- find the closest target to pet
      local target = SortByDistance(GetInRange(pet, 1000, ENEMIES))[1]
      if target then
         PetAttack(target)
      end
   end
end
local lastPetAttack = 0
function PetAttack(target, key)
   if not key then key = "R" end
   if time() - lastPetAttack > 1.5 then
      CastSpellTarget(key, target)
      lastPetAttack = time()
      PrintAction("Pet Attack", target)
   end
end
function CheckPetTarget(pet, unit, spell, key)
   if pet and not pet.timeout then
      local petTarget = SortByDistance(GetInRange(pet, 1000, ENEMIES), pet)[1]
      if not petTarget then
         if IsMe(unit) and
            spell.target and
            spell.target.team ~= me.team 
         then
            PetAttack(spell.target, key)
         end
      end
   end
end


function GetWeakestEnemy(thing, extraRange, stretch)
   if not extraRange then
      extraRange = 0
   end
   if not stretch then
      stretch = 0
   end

   local type

   local spell = GetSpell(thing)
   if spell then
      if thing.type then
         type = thing.type
      end
   end
   if type == "T" then
      type = "TRUE"
   elseif type == "P" then
      type = "PHYS"
   else 
      type = "MAGIC"
   end

   return GetWeakest(thing, GetInRange(me, GetSpellRange(spell)+extraRange, ENEMIES)) or
          GetWeakest(thing, GetInRange(me, GetSpellRange(spell)+extraRange+stretch, ENEMIES))
end


function GetWeakest(thing, list)
   if not list or #list == 0 then
      return nil
   end

   local type = "M"
   
   local spell = GetSpell(thing)
   if spell then
      if thing.type then
         type = thing.type
      end
   else
      type = thing
   end
   
   local weakest
   local wScore
   

   for _,target in ipairs(list) do      
      if target then
         if IsImmune(thing, target) then
            -- pp("Don't cast "..thing.." on "..target.name.." due to invuln")
         else
            local tScore = target.health / CalculateDamage(target, Damage(100, type))
            if weakest == nil or tScore < wScore then
               weakest = target
               wScore = tScore
            end
         end
      end
   end
   
   return weakest
end

function IsImmune(thing, target)
   local spell = GetSpell(thing)
   if target.team == me.team then
      return false
   end
   if spell and spell.name == "AA" then
      return HasBuff("invulnerable", target)
   else
      return HasBuff("invulnerable", target) or HasBuff("spellImmune", target)
   end
   return false
end

function SelectFromList(list, scoreFunction, args)
   local bestItem
   local bestScore = 0
   for _,item in ipairs(list) do
      local score = scoreFunction(item, args)
      if score > bestScore then
         bestItem = item
         bestScore = score
      end
   end
   if bestItem then 
      return bestItem, bestScore 
   end
   return nil, 0
end

DOLATERS = {}
function DoIn(f, timeout, key)
   if key then
      DOLATERS[key] = {time()+timeout, f}
   else
      table.insert(DOLATERS, {time()+timeout, f})
   end
end

function StartChannel(timeout, label)   
   timeout = timeout or .5
   label = label or "channel"

   AddChannelObject(label)
   PersistTemp(label, timeout)   
end

function IsChannelling(name)
   if name then
      if P[name] then
         return name
      end
      return false
   end
   for _,name in ipairs(channeledObjects) do
      if P[name] then
         return name
      end
   end
   for _,name in ipairs(channeledSpells) do
      if P[name] then
         return name
      end
   end

   return false
end

function PauseToggle(key, timeout)
   Toggle(key, false)
   DoIn( function() Toggle(key, true) end,
         timeout,
         "pause"..key )
end

function checkDodge(shot)
   if shot.safePoint then
      if shot.block and not shot.range then
         pp("Blocking SS without defined range")
         pp(shot)
      end
      if not shot.block or ( shot.block and IsUnblocked(me, shot, shot.target, MINIONS, ENEMIES) ) then
         if not IsChannelling() or (shot.cc and shot.cc >= 3) then
            PrintAction("Dodge "..shot.name)
            BlockingMove(shot.safePoint)
         end
      end
   end
end

function processShot(shot)
   if not shot then return end

   if shot.show then
      addSkillShot(shot)
   end


   if me.dead == 0 then
      shot = ShotTarget(shot, me)
      if shot then
         if not shot.show then
            addSkillShot(shot)
         end

         if Engaged() and shot.safePoint then
            PrintAction("Don't dodge - engaged -",shot.name, 1)
            return false
         end
         if IsChannelling() and shot.safePoint then
            PrintAction("Don't dodge - channelling -",shot.name, 1)
            return false
         end

         checkDodge(shot)
      end
   end
end

function OnProcessSpell(unit, spell)
   if ModuleConfig.ass and unit.team ~= me.team then
      local shot = GetSpellShot(unit, spell)
      if shot and not shot.dodgeByObject then
         processShot(shot)
      end
   end

   if ICast("Recall", unit, spell) then
      StartChannel(1)
   end

   for _,name in ipairs(channeledSpells) do
      if ICast(name, unit, spell) then
         if spells[name].channelTime then
            PrintAction("Cast "..name.." and started channel for "..spells[name].channelTime)
            PersistTemp(name, spells[name].channelTime)
         else
            PrintAction("Cast "..name.." and started channel")
            PersistTemp(name, 1)
         end
         break
      end
   end

   for _,sp in pairs(spells) do
      if sp.manualCooldown then
         if ICast(sp, unit, spell) then
            sp.lastCast = time() + .1 -- lag
         end
      end
   end

   -- shortcut for "creep" cast a spell
   if unit.team == 300 then
      CREEP_ACTIVE = true
      DoIn(function() CREEP_ACTIVE = false end, 2, "creepactive")
   end

   if spell.name == "HallucinateFull" then
      PersistTemp("shacoClone", 3)
      P.shacoClone.charName = unit.charName
   end

end
AddOnSpell(OnProcessSpell)

local blockTimeout = .25
local lastMove = 0 
function BlockingMove(move_dest)
   -- pp("block and move")
   if time() - lastMove > 1 then
      
      MoveToXYZ(move_dest.x, 0, move_dest.z)
      BlockOrders()
      DoIn( function()
               UnblockOrders()
            end,
            blockTimeout )  
      lastMove = time()
   end

end

MP5 = 0

TICK_DELAY = .05
-- Common stuff that should happen every time
local tt = time()
function TimTick()
   FRAME = time()
   DrawText(trunc(1/(time()-tt),1),1800,60,0xFFCCEECC);
   TICK_DELAY = time()-tt
   tt = time()
   if not LOADING then
      for i = 1, objManager:GetMaxNewObjects(), 1 do
         local object = objManager:GetNewObject(i)
         if object then
            doCreateObj(object)
         end
      end
   else
      for i = 1, objManager:GetMaxObjects(), 1 do
         local object = objManager:GetObject(i)
         if object then
            doCreateObj(object)
         end
      end
      LOADING = false
   end
   
   spells["AA"].range = GetAARange()

   for _,spell in pairs(spells) do
      if spell.key == "Q" or
         spell.key == "W" or
         spell.key == "E" or
         spell.key == "R"
      then
         spell.spellLevel = GetSpellLevel(spell.key)
      end
   end

   checkToggles()
   updateObjects()
   drawCommon()
   
   MP5 = 5 + (me.selflevel/2)
   local haveChalice = false
   for slot=1, 7 do
      local item = itemPrices[me["InventorySlot"..slot]]        
      if item then
         MP5 = MP5 + item.mp5
         if item.name == "Chalice of Harmony" or
            item.name == "Mikael's Crucible" or
            item.name == "Athene's Unholy Grail"
         then
            haveChalice = true
         end
      end
   end 
   if haveChalice then
      MP5 = MP5*1.5
   end

   if ModuleConfig.ass then
      if blockAndMove then 
         blockAndMove() 
      end
   end

   for key,doLater in pairs(DOLATERS) do
      if doLater[1] < time() then
         doLater[2]()
         DOLATERS[key] = nil
      end
   end

   for _,spell in pairs(spells) do
      if spell.delay and spell.speed then
         for _,enemy in ipairs(ENEMIES) do
            TrackSpellFireahead(spell, enemy)
         end
      end
   end

   TrackMyPosition()

   if P.cursorM and GetDistance(P.cursorM, PData.cursorM.lastPos) > 0 then
      CURSOR = Point(P.cursorM)
      PData.cursorM.lastPos = Point(P.cursorM)
      -- if IsAttacking() and VeryAlone() then
      --    pp("interrupt attack")
      --    ResetAttack()
      -- end
   elseif P.cursorA and GetDistance(P.cursorA, PData.cursorA.lastPos) > 0 then
      CURSOR = nil --P.cursorA
      PData.cursorA.lastPos = Point(P.cursorA)
      -- if IsAttacking() then
      --    ResetAttack()
      -- end
   end

   if GetDistance(me, CURSOR) < 50 and CURSOR then
      ClearCursor()
      -- StopMove()
   end

   if Point(CURSOR):valid() then
      Circle(CURSOR, 33, blue)
      LineBetween(me, CURSOR)
   end

   for spell, info in pairs(DISRUPTS) do
      if P[spell] then
         Circle(P[info.char], 100, green, 10)
      end
   end

   if ModuleConfig.ass then

      for _,pName in ipairs(GetTrackedSpells()) do
         if P[pName] and PData[pName].direction then
            local pd = PData[pName]
            local shot = GetSpellDef(pd.champName, pd.spellName)

            if shot then
               shot.timeOut = os.clock()+shot.time
               shot.startPoint = pd.lastPos
               shot.endPoint = ProjectionA(pd.lastPos, pd.direction, shot.range)
               SetEndPoints(shot)

               processShot(shot)
            end
         end
      end

   end
end

DISRUPTS = {
   DeathLotus={char="Katarina", obj="Katarina_deathLotus_cas"},
   -- StandUnited={char="Shen", obj=""},
   Meditate={char="MasterYi", obj="MasterYi_Base_W_Buf"},
   -- Idol={char="Galio", obj=""},
   Monsoon={char="Janna", obj="ReapTheWhirlwind_green_cas"},
   BulletTime={char="MissFortune", obj="missFortune_ult_cas"},
   AbsoluteZero={char="Nunu", obj="AbsoluteZero2"},
   Duress={char="Warwick", obj="InfiniteDuress_tar"},
   -- Grasp={char="Malzahar", obj=""},
   -- Drain={char="FiddleSticks", obj="drain.troy"},
}

function CheckDisrupt(spell)
   for disrupt,_ in pairs(DISRUPTS) do
      if Disrupt(disrupt, spell) then
         return true
      end
   end
   return false
end

champInit = false
wasChannelling = false
function StartTickActions()
   if not champInit then
      for name, spell in pairs(spells) do
         if spell.channel then
            AddChannelSpell(name)
         end
      end

      champInit = true
   end

   if IsRecalling(me) or me.dead == 1 then
      CURSOR = nil
      PrintAction("Recalling or dead")
      return true
   end

   if IsChannelling() then
      wasChannelling = true
      return true
   end

   if wasChannelling then
      -- PrintAction("end channel")
      wasChannelling = false
   end

   UseAutoItems()

   if HotKey() then
      if UseItems() then
         return true
      end
   end

   if HotKey() then
      if GetDistance(mousePos) < 3000 then
         CURSOR = Point(mousePos)
      end
   end

   return false
end

channeledSpells = {}
channeledObjects = {}
function AddChannelSpell(name)
   table.insert(channeledSpells, name)
end
function AddChannelObject(name)
   if not ListContains(name, channeledObjects) then
      table.insert(channeledObjects, name)
   end
end


needMove = false

function AutoMove()
   if IsOn("move") and CanMove() then
      if HotKey() then
         if GetDistance(mousePos) < 3000 then
            MoveToCursor()
         end
      end
      if needMove and CURSOR then      
         MoveToXYZ(Point(CURSOR):unpack())
         -- PrintAction("move")
         needMove = false
      end
   end
end

function EndTickActions()
   if IsOn("lasthit") and Alone() then
      if KillMinion("AA") then
         return true
      end
   end

   if HitObjectives() then
      return true
   end

   if HotKey() and IsOn("clear") and Alone() then

      if HitMinion("AA", "strong") then
         return true
      end

   end

   AutoMove()

   PrintAction()
   return false
end

function IsLoLActive()
   return tostring(winapi.get_foreground_window()) == "League of Legends (TM) Client"
end

function AA(target)
   if CanAttack() and IsValid(target) then
      AttackTarget(target)
      needMove = true
      return true
   end
   return false
end

function AutoAA(target, thing) -- thing is for modaa like Jax AutoAA(target, "empower")
   local mod = ""
   if target and GetDistance(target) < GetAARange()+150 then
      if thing and CanUse(thing) and not P[thing] and
         ( JustAttacked() or GetDistance(target) > GetAARange() ) 
      then
         Cast(thing, me)
         mod = " ("..thing..")"
      end

      if GetDistance(target) < GetAARange() then
         if AA(target) then
            if GetAARange() < 300 then
               ClearCursor()
            end
            PrintAction("AA"..mod, target)
            return true
         end
      end
   else
      target = GetWeakestEnemy("AA")
      if target and AA(target) then
         PrintAction("AA driveby "..mod, target)
         return true
      end
   end
   return false
end

function ModAAFarm(thing)
   if CanUse(thing) and not P[thing] and GetThreshMP(thing) <= 1 then
      local minions = SortByHealth(RemoveWillKills(GetInRange(me, "AA", MINIONS), thing), thing)
      for i,minion in ipairs(minions) do
         if WillKill(thing, minion) and 
            ( JustAttacked() or ( IsOn("clear") and not WillKill("AA", minion) ) )
         then
            AddWillKill(minion, thing)
            Cast(thing, minion)
            AttackTarget(minion)
            PrintAction(thing.." lasthit", minion)
            return true
         end
      end
   end   
   return false
end

function ModAAJungle(thing)
   if CanUse(thing) and not P[thing] then
      local creeps = SortByHealth(GetInRange(me, GetSpellRange("AA")+50, CREEPS), thing)
      local creep = creeps[#creeps]
      if creep and not WillKill("AA", creep) and JustAttacked() then
         Cast(thing, me)
         PrintAction(thing.." jungle", creep)
         return true
      end
   end
   return false
end

function MeleeMove()
   local lockRange = 350
   if CanMove() then   
      local target = GetMarkedTarget() or GetMeleeTarget()
      if target then
         if GetDistance(target) > GetAARange() then            
            -- if not RetreatingFrom(target) then
            Circle(target, lockRange, yellow)
            if GetDistance(target, CURSOR) < 350 then
               Circle(target, lockRange, red, 3)
               if MoveToTarget(target) then
                  return true
               end
            end
         end
      else        
         -- MoveToCursor() 
         -- return false
      end
   end
   return false
end

-- get the weakest nearby target so we don't get stuck on a tank.
-- don't jump too far as you end up chasing.
-- look out further to find a target if there isn't one at hand.
function GetMeleeTarget()
   return GetWeakEnemy("PHYS", GetSpellRange("AA")*1.5) or
          GetWeakEnemy("PHYS", GetSpellRange("AA")*2)
end

function DrawKnockback(object2, thing)
   local dist
   if type(thing) == "number" then
      dist = thing
   else
      local spell = GetSpell(thing)
      dist = spell.knockback
   end
   local a = object2.x - me.x
   local b = object2.z - me.z 
   
   local angle = math.atan(a/b)
   
   if b < 0 then
      angle = angle+math.pi
   end
   
   DrawLineObject(object2, dist, 0, angle, 0)
end

function UseItems(target)
   for item,_ in pairs(ITEMS) do
      UseItem(item, target)
   end
end

local flaskCharges = 3
function UseItem(itemName, target)
   local item = ITEMS[itemName]
   local slot = GetInventorySlot(item.id)
   if not slot then return end   
   slot = tostring(slot)

   if not IsCooledDown(slot) then return end

   if itemName == "Entropy" or
      itemName == "Bilgewater Cutlass" or
      itemName == "Hextech Gunblade" or
      itemName == "Blade of the Ruined King" or
      itemName == "Youmuu's Ghostblade" or
      itemName == "Randuin's Omen"
   then
      if target and GetDistance(target) > item.range then
         return
      end
      if not target then
         target = GetWeakEnemy("MAGIC", item.range)
      end
      if target then
         CastSpellTarget(slot, target)
         PrintAction(itemName, target, 1)
         return true
      end

   elseif itemName == "Deathfire Grasp" then
      if target and GetDistance(target) < item.range then
         CastSpellTarget(slot, target)
         PrintAction(itemName, target, .5)
         return true
      end

   elseif itemName == "Tiamat" or
          itemName == "Ravenous Hydra"
   then
      if not target then
         target = GetMeleeTarget()
      end
      if target and JustAttacked() then
         CastSpellTarget(slot, me)
         PrintAction(itemName, nil, 1)
         return true
      end

   elseif itemName == "Frost Queen's Claim" then
      local target = SelectFromList(GetInRange(me, item, ENEMIES), function(enemy) return #GetInRange(enemy, item.radius, ENEMIES) end)
      if target then
         CastXYZ(slot, target)
         PrintAction(itemName, target, 1)
         return true
      end

   elseif itemName == "Shard of True Ice" then
      -- shard
      -- look at all nearby heros in range and target the one with the most nearby enemies
      local shardRadius = 300

      local nearCount = 0
      target = nil
      for i,hero in ipairs(ALLIES) do
         if GetDistance(me, hero) < 750 then
            local near = #GetInRange(hero, shardRadius, ENEMIES)
            if near > nearCount then
               target = hero
               nearCount = near
            end
         end
      end
      if target then
         CastSpellTarget(slot, target)
         PrintAction(itemName, target)
         return true
      end

   elseif itemName == "Guardian's Horn" then
      target = GetWeakEnemy("MAGIC", 600)
      if target then
         CastSpellTarget(slot, me)
      end

   elseif itemName == "Locket of the Iron Solari" then
      -- how about 2 nearby allies and 2 nearby enemies
      local locketRange = ITEMS[itemName].range
      if #GetInRange(me, locketRange, ALLIES) >= 2 and
         #GetInRange(me, locketRange, ENEMIES) >= 2 
      then
         CastSpellTarget(slot, me)
      end

   elseif itemName == "Zhonya's Hourglass" or 
          itemName == "Wooglet's Witchcap" or
          itemName == "Seraph's Embrace"
   then
      -- use it if I'm at x% and there's an enemy nearby
      -- may expand this to trigger when a spell is cast on me that will kill me
      if not Alone() and GetHPerc(me) < .25 then
         CastSpellTarget(slot, me)
         return true
      end

   elseif itemName == "Muramana" then
      if target == nil or target then
         if not P.muramana then
            CastSpellTarget(slot, me)
            PrintAction("Muramana ON", nil, 1)
            return true
         end
      else
         if P.muramana then
            CastSpellTarget(slot, me)
            PrintAction("Muramana OFF")
            return true
         end
      end


   elseif itemName == "Mikael's Crucible" then
      -- It can heal or it can cleans
      -- heal is better the lower they are so how about scan in range heros and heal the lowest under 25%
      -- the cleanse is trickier. should I save it for higher priority targets or just use it on the first who needs it?\
      -- I took (or tried to) take out the slows so it will only work on harder cc.
      -- how about try to free adc then apc then check for heals on all in range.

      local crucibleRange = ITEMS["Mikael's Crucible"].range

      local target = ADC
      if target and target.name ~= me.name and 
         GetDistance(target, me) < crucibleRange and
         HasBuff("cc", target)
      then 
         CastSpellTarget(slot, target)
         pp("uncc adc,", target, 1) 
      else
         target = APC
         if target and target.name ~= me.name and 
            GetDistance(target, me) < crucibleRange and
            HasBuff("cc", target)
         then 
            CastSpellTarget(slot, target)
            pp("uncc apc,", target, 1)
         end
      end

      for _,hero in ipairs(GetInRange(me, crucibleRange, ALLIES)) do
         if GetHPerc(hero) < .25 then
            CastSpellTarget(slot, hero)
            pp("heal "..hero.name.." "..hero.health/hero.maxHealth, nil, 1)
         end
      end

   elseif itemName == "Crystaline Flask" then
      if GetDistance(HOME) < 800 then
         flaskCharges = 3
      end
      PrintState(0, flaskCharges)
      if flaskCharges > 0 then
         if GetHPerc(me) < .75 and not P.healthPotion then
            CastSpellTarget(slot, me)
            flaskCharges = flaskCharges - 1
            PrintAction("Flask for health")
            PersistTemp("healthPotion", 1)
            return true
         elseif GetMPerc(me) < .5 and not P.manaPotion then
            CastSpellTarget(slot, me)
            flaskCharges = flaskCharges - 1
            PrintAction("Flask for mana")
            PersistTemp("manaPotion", 1)
            return true
         elseif me.maxHealth - me.health > (120+30) and 
                me.maxMana - me.mana < (60+30) and
                not P.manaPotion and not P.healthPotion
         then
            CastSpellTarget(slot, me)
            flaskCharges = flaskCharges - 1
            PrintAction("Flask for regen")
            PersistTemp("healthPotion", 1)
            PersistTemp("manaPotion", 1)
            return true
         end
      end
      
   else
      -- CastSpellTarget(slot, me)
   end

end

function CastAtCC(thing, hardCCOnly, targetOnly)
   local spell = GetSpell(thing)

   if not CanUse(spell) then return end

   local target = GetWeakest(spell, GetWithBuff("cc", GetInRange(me, GetSpellRange(spell)+50, ENEMIES)))
   local stillMoving = false
   if not target then

      if hardCCOnly then
         return nil
      end

      local targets = GetInRange(me, thing, ENEMIES)
      for _,t in ipairs(targets) do
         if t.movespeed < 200 then
            target = t
            stillMoving = true
            break
         end
      end
   end
   if target and IsInRange(spell, target) then
      if not targetOnly then
         if spell.noblock then
            if stillMoving then
               CastFireahead(spell, target)
            else
               CastXYZ(spell, target)
            end
         else
            if IsUnblocked(target, spell, me, MINIONS, ENEMIES) then
               if stillMoving then
                  CastFireahead(spell, target)
               else
                  CastXYZ(spell, target)
               end
            else
               return false
            end
         end

         if stillMoving then
            PrintAction(thing.." on very slow ("..trunc(target.movespeed)..")", target)
         else
            PrintAction(thing.." on immobile", target)
         end
      end
      return target, not stilMoving
   end
   return nil
end

function OnWndMsg(msg, key)

end

Combo = class()
function Combo:__init(name, timeout, onEnd)
   self.state = nil   
   self.states = {}
   self.vars = {}
   self.target = nil

   self.name = name
   self.timeout = timeout
   self.onEnd = onEnd
end


function Combo:__tostring()
   return self.name..":"..self.state
end

function Combo:__concat(a)
    return tostring(self) .. tostring(a) 
end

function Combo:reset()
   self.state = nil
   self.vars = {}
   if self.onEnd then
      self.onEnd()
   end
end

function Combo:set(var, value)
   self.vars[var] = value
end
function Combo:get(var)
   return self.vars[var]
end

function Combo:start()
   self.endTime = time() + self.timeout
   self.state = self.startState
end

function Combo:run()
   if self.state then
      if time() > self.endTime then
         PrintAction(self.name.." timeout")
         self:reset()
         return false
      end

      PrintState(0, tostring(self))
      self.states[self.state](self)
      return true
   end
end

function Combo:addState(state, action)
   if not self.startState then
      self.startState = state
   end
   self.states[state] = action
end


RegisterLibraryOnWndMsg(OnWndMsg)
AddOnTick(TimTick)