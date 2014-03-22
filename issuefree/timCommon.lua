require "Utils"
ModuleConfig = scriptConfig("Module Config", "modules")
require "basicUtils"
require "spell_shot"
require "telemetry"
require "drawing"
require "items"
require "autoAttackUtil"
require "persist"
require "spellUtils"
require "toggles"
require "walls"


if me.SpellLevelQ == 0 and
   me.SpellLevelW == 0 and
   me.SpellLevelE == 0
then
   os.remove("lualog.txt")
end

local lastAction = nil
local lastActionTime = time()
function PrintAction(str, target)
   if str == nil then 
      lastAction = nil
      return
   end
   if str ~= lastAction then
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
      lastAction = str
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


-- do fireahead calculations with a speedup to account for player direction changes
SS_FUDGE = 1.33

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
      if minion.visible == 1 then
         local hits = math.ceil(minion.health/GetAADamage(minion))
         if hits == 1 then
            DrawTextObject(hits.." hp", minion, blueT)
            Circle(minion, 50, red, 3)
         elseif hits <= 3 then
            DrawTextObject(hits.." hp", minion, greenT)
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
               local point = GetSpellFireahead(key, target)

               if GetDistance(point) < GetSpellRange(activeSpell)+100 then

                  if IsGoodFireahead(key, target) then
                     Circle(point, GetDistance(trackedPoints[1], trackedPoints[#trackedPoints]), green, 3)
                  else
                     -- Circle(point, GetDistance(trackedPoints[1], trackedPoints[#trackedPoints]), yellow, 1)
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
            LineBetween(shot.startPoint, shot.endPoint, shot.radius)
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

DISRUPTS = {
   DeathLotus={char="Katarina", obj="Katarina_deathLotus_cas"},
   Meditate={char="MasterYi", obj="MasterYi_Base_W_Buf"},
   Drain={char="FiddleSticks", obj="drain.troy"},
   -- Idol={char="Galio", obj=""},
   Monsoon={char="Janna", obj="ReapTheWhirlwind_green_cas"},
   BulletTime={char="MissFortune", obj="missFortune_ult_cas"},
   AbsoluteZero={char="Nunu", obj="AbsoluteZero2"},
   Duress={char="Warwick", obj="InfiniteDuress_tar"},
   Grasp={char="Malzahar", obj=""}
}

function doCreateObj(object)
   if not (object and object.x and object.z) then
      return
   end

   createForPersist(object)

   for spell, info in pairs(DISRUPTS) do
      persistForDisrupt(info.char, info.obj, spell, object)
   end

   if IsHero(object) and not CHAR_SPELLS[object.name] then
      CHAR_SPELLS[object.name] = LoadConfig("charSpells/"..object.name)
      if not CHAR_SPELLS[object.name] then
         CHAR_SPELLS[object.name] = {}
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
      if IsInRange(target, spell) then
         if spell.delay then
            if spell.noblock then
               CastXYZ(spell, target)
            else
               if IsUnblocked(me, spell, target, MINIONS, ENEMIES) then
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
   return find(unit.name, "Minion")
end

function IsHero(unit)
   for _,hero in ipairs(concat(ALLIES, ENEMIES)) do
      if SameUnit(unit, hero) then
         return true
      end
   end
   return false
end

function IsEnemy(unit)
   if not unit then return false end
   return unit.team ~= me.team and IsHero(unit)
end

function ValidTargets(list)
   if not list then return {} end
   return FilterList(list, 
      function(item)
         if not item.dead then
            return item
         end
         return 
            item.dead == 0 and 
            item.invulnerable == 0 and 
            item.visible == 1 and 
            item.x and item.z 
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


function KillMinionsInLine(thing, killsNeeded)
   local spell = GetSpell(thing)
   if not spell or not CanUse(spell) then return false end

   local hits, kills, score = GetBestLine(me, thing, 0, 1, MINIONS)
   if #kills >= killsNeeded then
      local point = GetCenter(hits)
      if spell.overShoot then
         point = Projection(me, point, GetDistance(point)+spell.overShoot)
      end
      Circle(point, 50, yellow)
      CastXYZ(thing, point)
      PrintAction(thing.." for kills", #kills)
      return true
   end
   return false
end

function HitMinionsInLine(thing, hitsNeeded)
   local spell = GetSpell(thing)
   if not spell or not CanUse(spell) then return false end
   
   local hits, kills, score = GetBestLine(me, thing, 1, 1, MINIONS)
   if #hits >= hitsNeeded then
      local point = GetCenter(hits)
      if spell.overShoot then
         point = OverShoot(me, point, spell.overShoot)         
      end
      Circle(point, 50, yellow)
      CastXYZ(thing, point)
      PrintAction(thing.." for hits", #hits)
      return true
   end
   return false
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
   if target then
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
      local x,y,z = GetFireahead(t, 2, 0)
      MoveToXYZ(x,y,z)
      PrintAction("MTT", t)
   end
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
function KillMinion(thing, method, extraRange)
   local spell = GetSpell(thing)
   if not CanUse(spell) then return end

   if not extraRange then extraRange = 0 end
   if not method then method = "weak" end

   local minions = GetInRange(me, GetSpellRange(spell)+extraRange, MINIONS)
   if method == "weak" then
      SortByHealth(minions)
   elseif method == "far" then
      SortByDistance(minions)
      minions = reverse(minions)
   elseif method == "near" then
      SortByDistance(minions)
   elseif method == "strong" then
      SortByHealth(minions)
      minions = reverse(minions)
   end

   for _,minion in ipairs(minions) do
      if WillKill(thing, minion) then
         if spell.name and spell.name == "attack" then
            AttackTarget(minion)
            PrintAction("AA "..method.." minion")
            return true
         else
            Cast(spell, minion)
            PrintAction(thing.." "..method.." minion")
            return true
         end
      end
   end
   return false
end

-- weak, far, near, strong
function HitMinion(thing, method, extraRange)
   local spell = GetSpell(thing)
   if not CanUse(spell) then return end

   if not extraRange then extraRange = 0 end
   if not method then method = "weak" end

   local minions = GetInRange(me, GetSpellRange(spell)+extraRange, MINIONS)
   if method == "weak" then
      SortByHealth(minions)
   elseif method == "far" then
      SortByDistance(minions)
      minions = reverse(minions)
   elseif method == "near" then
      SortByDistance(minions)
   elseif method == "strong" then
      SortByHealth(minions)
      minions = reverse(minions)
   end

   for _,minion in ipairs(minions) do
      if spell.name and spell.name == "attack" then
         AttackTarget(minion)
         PrintAction("AA "..method.." minion")
         return true
      else
         Cast(spell, minion)
         PrintAction(thing.." "..method.." minion")
         return true
      end
   end
   return false
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
      local kills = {}
      local center
      -- trim outliers until everyone fits
      while true do
         center = GetCenter(hits)
         SortByDistance(hits, center)         
         if GetDistance(center, hits[#hits]) > spell.radius then
            table.remove(hits, #hits)
         else
            break
         end
      end

      center = GetCenter(hits)
      if GetDistance(source, center) > GetSpellRange(spell) then
         hits = {}
      end


      local score = #hits

      if killScore ~= 0 then
         for _,hit in ipairs(hits) do
            if WillKill(thing, hit) then
               score = score + killScore
               table.insert(kills, hit)
            end
         end
      end
      if not bestT or score > bestS then
         bestS = score
         bestT = hits
         bestK = kills
      end
   end
   return bestT, bestK, bestS
end


function GetInLine(source, thing, primary, targets)
   local spell = GetSpell(thing)
   SortByAngle(targets)

   local hits = {primary}
   local pw = GetWidth(primary)
   for _,s in ipairs(targets) do
      if s ~= primary then
         local sw = GetWidth(s)
         local ra = RelativeAngle(source, primary, s)
         if GetOrthDist(primary, s) < spell.width + pw + sw and 
            ra < math.pi/3 -- why?
         then
            table.insert(hits, s)
         end
      end
   end
   return hits
end

function GetBestLine(source, thing, hitScore, killScore, ...)
   local spell = GetSpell(thing)
   if not spell.width then
      spell.width = 80
      pp("No width set for.."..thing)
   end

   local targets = GetAllInRange(source, spell, concat(...))

   local bestS = 0
   local bestT = {}
   local bestK = {}
   for _,target in ipairs(targets) do
      local hits = GetInLine(source, thing, target, targets)
      local score = #hits
      local kills = {}

      if killScore ~= 0 then     
         for _,hit in ipairs(hits) do
            if WillKill(thing, hit) then
               score = score + killScore
               table.insert(kills, hit)
            end
         end
      end
      if not bestT or score > bestS then
         bestS = score
         bestT = hits
         bestK = kills
      end
   end
   return bestT, bestK, bestS
end

function KillMinionsInArea(thing, killsNeeded)
   local spell = GetSpell(thing)
   if not spell or not CanUse(spell) then return false end

   local hits, kills, score = GetBestArea(me, thing, 0, 1, MINIONS)
   if #kills >= killsNeeded then
      CastXYZ(thing, GetCenter(hits))
      PrintAction(thing.." for kills", #kills)
      return true
   end
   return false
end
function HitMinionsInArea(thing, hitsNeeded)
   local spell = GetSpell(thing)
   if not spell or not CanUse(spell) then return false end

   local hits, kills, score = GetBestArea(me, thing, 1, 1, MINIONS)
   if #hits >= hitsNeeded then
      CastXYZ(thing, GetCenter(hits))
      PrintAction(thing.." for hits", #hits)
      return true
   end
   return false
end

function KillMinionsInCone(thing, minKills, extraRange, drawOnly)
   local spell = GetSpell(thing)
   if not spell then return false end
   if not CanUse(spell) then return false end

   if not extraRange then extraRange = 0 end

   -- cache damage calculation      
   local wDam = GetSpellDamage(spell)
   -- convert from degrees   
   local spellAngle = spell.cone/360*math.pi*2

   local minionAngles = {}

   -- clean out the ones I can't kill and get the angles   
   for i,minion in ipairs(GetInRange(me, GetSpellRange(spell)+extraRange, MINIONS)) do
      if CalculateDamage(minion, wDam) > minion.health then
         table.insert(minionAngles, {AngleBetween(minion, me), minion})
      end
   end


   -- results variables
   local bestAngleI
   local bestAngleJ
   local maxDist
   local bestAngleK = 1

   -- are there enough possible targets to bother?
   if #minionAngles >= minKills then
   
      -- sort by angle and make a sweep from left to right
      -- start with the first target and expand the cone until you run out of targets or the next target is out of the cone
      -- do this for each target in order keeping track of the best start and end index 
      
      table.sort(minionAngles, function(a,b) return a[1] < b[1] end)

      for i=1, #minionAngles-1 do
         local angleK = 1
         local j = i
         for li=i, #minionAngles-1 do
            local angleli = minionAngles[li][1]
            while j+1 < #minionAngles+1 and minionAngles[j+1] and 
                  minionAngles[j+1][1] - angleli < spellAngle and minionAngles[j+1][1] - angleli > 0
            do
               angleK = angleK + 1
               j = j + 1
            end
         end
         if angleK > bestAngleK then
            bestAngleI = i
            bestAngleJ = j
            bestAngleK = angleK
         end
      end 

      -- are there enough actual kills to bother?
      if bestAngleK >= minKills then
      
         -- find the furthest target minion so we can move toward it if it's out of range.
         local farMinion
         local farMinionD
         for i = bestAngleI, bestAngleJ do
            local dist = GetDistance(minionAngles[i][2])
            if not farMinion or dist > farMinionD then
               farMinion = minionAngles[i][2]
               farMinionD = dist
            end
         end

         -- find the target point that puts our targets in the cone
         local x = (minionAngles[bestAngleI][2].x + minionAngles[bestAngleJ][2].x)/2  
         local y = (minionAngles[bestAngleI][2].y + minionAngles[bestAngleJ][2].y)/2  
         local z = (minionAngles[bestAngleI][2].z + minionAngles[bestAngleJ][2].z)/2
         
         -- draw the target cone and the target spot  
         Circle(Point(x,y,z), 25, yellow)
         LineBetween(me, minionAngles[bestAngleI][2])
         LineBetween(me, minionAngles[bestAngleJ][2])
         
         -- execute
         if not drawOnly then
            if farMinionD < GetSpellRange(spell) then                        
               CastSpellXYZ(spell.key, x,y,z)
               return true
            end
         end
      end
   end
   return false
end

function SkillShot(thing, purpose)
   local target = GetSkillShot(thing, purpose)
   if target then
      CastFireahead(thing, target)
      PrintAction(thing, target)
      return target
   end
   return false
end

function GetSkillShot(thing, purpose)
   local spell = GetSpell(thing)
   if not CanUse(spell) then return nil end

   local targets = {}
   if not spell.noblock then
      local unblocked = GetUnblocked(me, spell, MINIONS, ENEMIES)
      targets = FilterList(unblocked, function(item) return not IsMinion(item) end)      
   else
      targets = ENEMIES
   end
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

function GetUnblocked(source, thing, ...)
   local spell = GetSpell(thing)
   local minionWidth = 55
   local targets = GetAllInRange(source, spell, concat(...))
   SortByDistance(targets, source)
   
   local blocked = {}
   
   local width = spell.width or spell.radius

   for i,target in ipairs(targets) do
      local d = GetDistance(source, target)
      for m = i+1, #targets do
         local a = AngleBetween(source, targets[m])
         local proj = {x=source.x+math.sin(a)*d, z=source.z+math.cos(a)*d}
         if GetDistance(target, proj) < width+minionWidth then
            table.insert(blocked, targets[m])
         end
      end
   end


   local unblocked = {}
   for i,target in ipairs(targets) do
      local mb = false
      for m,bm in ipairs(blocked) do
         if bm == target then          
            mb = true
            break
         end
      end
      if not mb then
         table.insert(unblocked, target)
      end
   end
   return unblocked
end

function IsUnblocked(me, thing, target, ...)
   local unblocked = GetUnblocked(me, thing, concat(...))
   for _,t in ipairs(unblocked) do
      if SameUnit(t, target) then
         return true
      end
   end
   return false
end

function HotKey()
   return IsKeyDown(hotKey) ~= 0
end

function IsRecalling(hero)
   return HasBuff("recall", hero)
end

function IsInRange(target, thing, source)
   local range
   if type(thing) ~= "number" then
      range = GetSpellRange(thing)
   else
      range = thing
   end
   return GetDistance(target, source) < range
end

function GetInRange(target, thing, ...)
   local range
   if type(thing) ~= "number" then
      range = GetSpellRange(thing)
   else
      range = thing
   end
   local result = {}
   local list = ValidTargets(concat(...))
   for _,test in ipairs(list) do
      if target and test and
         GetDistance(target, test) <= range 
      then
         table.insert(result, test)
      end
   end
   return result
end

function GetAllInRange(target, thing, ...)
   local range
   if type(thing) ~= "number" then
      range = GetSpellRange(thing)
   else
      range = thing
   end
   local result = {}
   local list = concat(...)
   for _,test in ipairs(list) do
      if target and test and test.x and
         GetDistance(target, test) < range 
      then
         table.insert(result, test)
      end
   end
   return result
end

function UseAutoItems()
   UseItem("Zhonya's Hourglass")
   UseItem("Wooglet's Witchcap")
   UseItem("Seraph's Embrace")
   UseItem("Mikael's Crucible")
   UseItem("Locket of the Iron Solari")
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

   local ward = SortByDistance(GetAllInRange(pos, 150, ALLIES, MYMINIONS, WARDS), pos)[1]

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
   local damage = GetSpellDamage("AA")
   
   if spells["AA"].damOnTarget and target then
      damage = damage + spells["AA"].damOnTarget(target)
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
      if spell.name and spell.name == "attack" then
         damage = damage + GetAADamage(target)
      else         
         if CanUse(thing) and usedMana + GetSpellCost(thing) <= me.mana then
            damage = damage + GetSpellDamage(thing, target)
            usedMana = usedMana + GetSpellCost(thing)
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

   return GetWeakEnemy(type, GetSpellRange(spell)+extraRange) or
          GetWeakEnemy(type, GetSpellRange(spell)+extraRange+stretch)
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
         local tScore = target.health / CalculateDamage(target, Damage(100, type))
         if weakest == nil or tScore < wScore then
            weakest = target
            wScore = tScore
         end
      end
   end
   
   return weakest
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

CHANNELBUFFER = false
CHANNELLING = false


function StartChannel(timeout, label)
   if not timeout then timeout = .5 end
   CHANNELBUFFER = true
   if label then
      pp("..."..label.." "..trunc(timeout))
   -- else
   --    pp("...channel "..timeout)
   end
   local start = time()
   DoIn( function() 
            CHANNELBUFFER = false 
            if label then
               pp("   "..label.."..."..trunc(time()-start))
            -- else
            --    pp("   channel..."..time()-start)
            end            
         end, 
         timeout, "ChannelBuffer" )
end

function IsChannelling(object)
   if not object then
      return CHANNELBUFFER or CHANNELLING
   else
      return CHANNELBUFFER or object
   end
end

function PauseToggle(key, timeout)
   Toggle(key, false)
   DoIn( function() Toggle(key, true) end,
         timeout,
         "pause"..key )
end

function CastBuff(spell)
   if not P[spell] then
      Cast(spell, me)
      Persist(spell, me, me.charName)
      DoIn( function()
               if P[spell] and IsMe(P[spell]) then
                  P[spell] = nil
                  PrintAction("endbuffchannel")
               end
            end,
            .5, "CastBuff"..spell
         )
   end
end

function OnProcessSpell(unit, spell)
   if ModuleConfig.ass and unit.team ~= me.team then
      local shot
      if me.dead == 0 and
         not Engaged() and
         not IsChannelling()
      then
         shot = SpellShotTarget(unit, spell, me)
         if shot then
            if not Engaged() and shot.safePoint then
               if not IsChannelling() or (shot.cc and shot.cc >= 3) then
                  BlockingMove(shot.safePoint)
                  PrintAction("Dodge "..unit.name.."'s "..spell.name)
               end
            end
            addSkillShot(shot)
         end
      end
      if not shot then
         shot = GetSpellShot(unit, spell)
         if shot and shot.show then
            addSkillShot(shot)
         end
      end
   end

   if ICast("Recall", unit, spell) then
      StartChannel(1)
   end

   if CHAR_SPELLS[unit.name] then
      if spell.name and IsHero(unit) and not CHAR_SPELLS[unit.name][spell.name] then
         CHAR_SPELLS[unit.name][spell.name] = "new"
         pp("Adding "..spell.name.." to "..unit.name) 
         SaveConfig("charSpells/"..unit.name, CHAR_SPELLS[unit.name])
      end
   end

   -- for i, callback in ipairs(SPELL_CALLBACKS) do
   --    callback(unit, spell)
   -- end   
end
AddOnSpell(OnProcessSpell)

local send = require 'SendInputScheduled'
local function makeStateMatch(changes)
   for scode,flag in pairs(changes) do    
      -- if flag then pp('went down') else pp('went up') end
      local vk = winapi.map_virtual_key(scode, 3)
      local is_down = winapi.get_async_key_state(vk)
      if flag then -- went down
         if is_down then
            send.wait(60)
            send.key_down(scode)
            send.wait(60)
         else
            -- up before, up after, down during, we don't care
         end            
      else -- went up
         if is_down then
            -- down before, down after, up during, we don't care
         else
            send.wait(60)
            send.key_up(scode)
            send.wait(60)
         end
      end
   end
end

local blockAndMove = nil
local blockTimeout = .25
local blockStart = 0
function BlockingMove(move_dest)
   blockStart = time()

   -- send.block_input(true, blockTimeout*1000, makeStateMatch)
   MoveToXYZ(move_dest.x, 0, move_dest.z)

   -- blockAndMove = function()
   --    Circle(move_dest, 75, green)
   --    if time() - blockStart > blockTimeout or 
   --       GetDistance(move_dest)<75 
   --    then
   --       blockAndMove = nil
   --       send.block_input(false)
   --    end
   -- end
end
function Unblock()
   send.block_input(false)
end

-- Common stuff that should happen every time
local tt = time()
function TimTick()
   DrawText(trunc(1/(time()-tt),1),1800,60,0xFFCCEECC);
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
   
   if ModuleConfig.ass then
      if blockAndMove then 
         blockAndMove() 
      end
      send.tick()
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

   UseAutoItems()

   for spell, info in pairs(DISRUPTS) do
      if P[spell] then
         Circle(P[info.char], 100, green, 10)
      end
   end


end

function AA(target)
   if CanAttack() and ValidTarget(target) then
      AttackTarget(target)
      return true
   end
   return false
end

function ModAA(thing, target)
   local dist = GetDistance(target)
   local range = GetSpellRange("AA")
   
   local mod = false

   if CanUse(thing) then
      if ( dist <= range and
           JustAttacked() ) or
         ( dist > range and 
           dist < range+100 )
      then
         Cast(thing, me)
         AttackTarget(target)
         mod = true
      end
   end

   if AA(target) then
      if mod then
         PrintAction("AA ("..thing..")", target)
      else
         PrintAction("AA", target)
      end
      return target
   end

   return false
end


function ModAAFarm(thing, pObj)
   if CanUse(thing) and not pObj then
      local target = SortByHealth(GetInRange(me, "AA", MINIONS))[1]
      if target and WillKill(thing, target) and JustAttacked() then
         Cast(thing, me)
         PrintAction(thing.." lasthit", target)
         AttackTarget(target)
         return true
      end
   end   
   return false
end

function ModAAJungle(thing, pObj)
   if CanUse(thing) and not pObj then
      local creeps = SortByHealth(GetAllInRange(me, GetSpellRange("AA")+50, CREEPS))
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
   if CanMove() then   
      local target = GetMarkedTarget() or GetMeleeTarget()
      if target then
         if GetDistance(target) > spells["AA"].range+25 then
            MoveToTarget(target)
            return true
         end
      else        
         MoveToCursor() 
         return false
      end
   end
   return false
end

-- get the weakest nearby target so we don't get stuck on a tank.
-- don't jump too far as you end up chasing.
-- look out further to find a target if there isn't one at hand.
function GetMeleeTarget()
   return GetWeakEnemy("PHYS", GetSpellRange("AA")*1.25) or
          GetWeakEnemy("PHYS", GetSpellRange("AA")*1.75)
end

function RangedMove()
   if IsOn("move") then
      -- if #GetInRange(GetMousePos(), GetSpellRange("AA")-50, ENEMIES) == 0 or
      --    #GetInRange(me, GetSpellRange("AA")-50, ENEMIES) == 0 
      -- then
      --    MoveToCursor()
      --    return false   
      -- end
   end
   return false
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
      itemName == "Deathfire Grasp" or
      itemName == "Tiamat" or
      itemName == "Ravenous Hydra" or
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
      end

   elseif itemName == "Tiamat" or
          itemName == "Ravenous Hydra"
   then
      if not target then
         target = GetMeleeTarget()
      end
      if target and JustAttacked() then
         CastSpellTarget(slot, me)
         return true
      end

   elseif itemName == "Frost Queen's Claim" then
      local target = SelectFromList(ENEMIES, function(enemy) return #GetInRange(enemy, item.radius, ENEMIES) end)
      -- local nearCount = 0
      -- target = nil
      -- for i,hero in ipairs(ENEMIES) do
      --    if GetDistance(me, hero) < item.range then
      --       local near = #GetInRange(hero, item.radius, ENEMIES)
      --       if near > nearCount then
      --          target = hero
      --          nearCount = near
      --       end
      --    end
      -- end
      if target then
         CastSpellTarget(slot, target)
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
      end

   elseif itemName == "Muramana" then
      if target then
         CastSpellTarget(slot, target)
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
         pp("uncc adc "..target.name) 
      else
         target = APC
         if target and target.name ~= me.name and 
            GetDistance(target, me) < crucibleRange and
            HasBuff("cc", target)
         then 
            CastSpellTarget(slot, target)
            pp("uncc apc "..target.name)
         end
      end

      for _,hero in ipairs(GetInRange(me, crucibleRange, ALLIES)) do
         if GetHPerc(hero) < .25 then
            CastSpellTarget(slot, hero)
             pp("heal "..hero.name.." "..hero.health/hero.maxHealth)            
         end
      end

   else
      -- CastSpellTarget(slot, me)
   end

end

function CastAtCC(thing)
   local spell = GetSpell(thing)

   if not CanUse(spell) then return end

   local target = GetWeakest(spell, GetWithBuff("cc", GetInRange(me, GetSpellRange(spell)+50, ENEMIES)))
   if target and IsInRange(target, spell) then
      if spell.noblock then
         CastXYZ(spell, target)
      else
         if IsUnblocked(me, spell, target, MINIONS, ENEMIES) then
            CastXYZ(spell, target)
         else
            return false
         end
      end

      PrintAction(thing.." on immobile", target)
      return true
   end
   return false
end


AddOnTick(TimTick)