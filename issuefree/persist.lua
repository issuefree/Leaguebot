require "issuefree/basicUtils"

-- object arrays
MINIONS = {}
MYMINIONS = {}

CREEPS = {} -- all creeps
MINORCREEPS = {} -- minor creeps (little wolves, lizards)
BIGCREEPS = {} -- Big wolf and big wraith and big golem
MAJORCREEPS = {}

DRAGON = {}
BARON = {}

TURRETS = {}
MYTURRETS = {}

INHIBS = {}
MYINHIBS = {}

WARDS = {}

ALLIES = {}
ENEMIES = {}
-- simple attempt to grab high priority targets
ADC = nil
APC = nil

EADC = nil
EAPC = nil

CURSOR = nil
function ClearCursor()
   CURSOR = nil
end

AA_TARGET = nil

-- persisted particles
P = {}
pOn = {}
PData = {}

-- name field
MinorCreepNames = {
   "Wolf", 
   "YoungLizard", 
   "LesserWraith",
   "SmallGolem",
   "Wraith"
}
BigCreepNames = {
   "GiantWolf", 
   "Golem",
   "GreatWraith"
}
MajorCreepNames = {
   "AncientGolem", 
   "LizardElder",
   "Dragon",
   "Worm"
}

CreepNames = concat(MinorCreepNames, BigCreepNames, MajorCreepNames)

-- stuns roots fears taunts?
ccNames = {
   "Ahri_Charm_buf", 
   "Amumu_SadRobot_Ultwrap", 
   "Amumu_Ultwrap", 
   "CurseBandages",
   "DarkBinding_tar", 
   "Global_Fear", 
   "Global_Taunt", 
   "leBlanc_shackle", 
   "LOC_Stun",
   "LOC_Suppress",
   "LOC_Taunt",
   "LuxLightBinding",
   "maokai_elementalAdvance_root_01", 
   "monkey_king_ult_unit_tar_02",
   "xenZiou_ChainAttack_03",
   "RengarEMax",
   "RunePrison",
   "Stun_glb", 
   "summoner_banish", 
   "tempkarma_spiritbindroot",
   "VarusRHitFlash",
   "Vi_R_land",
   "Zyra_E_sequence_root",

   -- self inflicted ccs
   -- "pantheon_heartseeker_cas2",
   -- "gragas_drunkenRage_attack_buf",
   "Katarina_deathLotus_cas",
   "drain.troy",
   "ReapTheWhirlwind_green_cas",
   "missFortune_ult_cas",
   "AbsoluteZero2",
   "InfiniteDuress_tar"
}


-- find an object and persist it
function Persist(name, object, charName)
   if object and (not charName or find(object.charName, charName)) then
      P[name] = object
      PData[name] = {}
      PData[name].cn = object.charName
      return true
   end
end

function enemyHasName(name)
   for _,enemy in ipairs(ENEMIES) do
      if enemy.name == name then
         return true
      end
   end
end

function PersistToTrack(object, charName, champName, spellName)
   if Persist(spellName, object, charName) then

      -- if the champ that can cast the spell isn't on the other team bail
      if not enemyHasName(champName) then
         return
      end

      -- check if it's an ally casting the spell
      -- if the object comes into creation very close to a character on my team with the right name...
      for _,ally in ipairs(ALLIES) do
         if ally.name == champName then
            if GetDistance(ally, object) < 200 then
               return
            end
         end
      end
      PData[spellName].startPoint = Point(object)
      PData[spellName].type = "trackedSpell"
      PData[spellName].champName = champName
      PData[spellName].spellName = spellName      
   end
end

function PersistAll(name, object, charName)
   if object and (not charName or find(object.charName, charName)) then      
      Persist(name..object.id, object)
      PData[name..object.id].name = name
      return true
   end
end

function GetPersisted(name)
   local persisted = {}
   for pKey,data in pairs(PData) do
      if data.name == name then
         table.insert(persisted, P[pKey])
      end
   end
   return persisted
end

-- find an object only near me and persist it
function PersistBuff(name, object, charName, dist)
   if not dist then
      dist = 100
   end
   if object and find(object.charName, charName) then
      if GetDistance(object) < dist then
         P[name] = object
         PData[name] = {}
         PData[name].cn = object.charName
         return true
      elseif GetDistance(object) < 500 then
         -- pp("Found "..name.." at distance "..math.floor(GetDistance(object)))
      end
   end
   return false
end

function PersistOnTargets(name, object, charName, ...)
   if object and find(object.charName, charName) then
      local target = SortByDistance(GetInRange(object, 100, concat(...)), object)[1]
      if target then
         if not pOn[name] then
            pOn[name] = {}
         end
         Persist(name..object.id, object)
         PData[name..object.id].unit = target
         table.insert(pOn[name], name..object.id)
         -- pp("Persisting "..name.." on "..target.charName.." as "..name..object.id)
         return target
      end
   end
   return false
end

-- check if a given target has the named buff
function HasBuff(buffName, target)
   if not pOn[buffName] then return false end
   for _,pKey in ipairs(pOn[buffName]) do
      local pd = PData[pKey]
      if pd and pd.unit.charName == target.charName then
         return true
      end
   end
   return false
end

function GetWithBuff(buffName, ...)
   return FilterList(concat(...),
      function(item)
         return HasBuff(buffName, item)
      end
   )
end

function GetTrackedSpells()
   local ts = {}
   for pName,obj in pairs(P) do
      if PData[pName].type == "trackedSpell" then
         table.insert(ts, pName)
      end
   end
   return ts
end

function CleanPersistedObjects()
   for name,obj in pairs(P) do
      if not obj or 
         not obj.charName or obj.charName ~= PData[name].cn or
         not obj.x or not obj.z
      then
         -- pp("Clean "..name)
         P[name] = nil
         PData[name] = nil
      end
   end
   for name, obj in pairs(PData) do
      if not P[name] then
         PData[name] = nil
      end
   end
   for name,pList in pairs(pOn) do
      for i,pKey in rpairs(pList) do
         if not P[pKey] then
            table.remove(pList, i)
         end
      end
   end
end

function Clean(list, field, value)
   for i, obj in rpairs(list) do
      if field and value then
         if not find(obj[field], value) then
            table.remove(list,i)
         end
      elseif not obj or not obj.x or not obj.z then
         table.remove(list,i)
      end
   end
end

function isDupMinion(minionTable, minion)
  local count = 0
  for _,m in pairs(minionTable) do
    if minion.charName == m.charName then count = count + 1 end
    if count > 1 then return true end
  end
  return false
end

local function updateMinions()
   for i,minion in rpairs(MINIONS) do
      if not minion or
         minion.dead == 1 or
         minion.x == nil or 
         minion.z == nil or
         not find(minion.charName, "Minion") or
         isDupMinion(MINIONS, minion)
      then
         table.remove(MINIONS,i)
      end
   end
   for i,minion in rpairs(MYMINIONS) do
      if not minion or
         minion.dead == 1 or
         minion.x == nil or 
         minion.z == nil or
         not find(minion.charName, "Minion") or
         isDupMinion(MYMINIONS, minion)
      then
         table.remove(MYMINIONS,i)
      end
   end
end

local function updateTrackedSpells()
   for pName,obj in pairs(P) do
      if PData[pName].type == "trackedSpell" then
         if PData[pName].lastPos then
            PData[pName].direction = AngleBetween(PData[pName].lastPos, Point(P[pName]))
            -- DrawLine(P[pName].x,P[pName].y,P[pName].z, 1000, 0, PData[pName].direction, 100)
         end
         PData[pName].lastPos = Point(P[pName])
      end
   end
end

local function cleanCreeps(list, names)
   for i,unit in rpairs(list) do
      if not unit or
         unit.dead == 1 or
         unit.x == nil or 
         unit.y == nil or
         not ListContains(unit.name, names)
      then
         table.remove(list,i)
      end
   end
end

local function updateCreeps()
   cleanCreeps(CREEPS, CreepNames)
   cleanCreeps(MINORCREEPS, MinorCreepNames)
   cleanCreeps(BIGCREEPS, BigCreepNames)
   cleanCreeps(MAJORCREEPS, MajorCreepNames)
end

local function updateHeroes()
   ALLIES = {}
   ENEMIES = {}
   ADC = nil
   APC = nil
   EADC = nil
   EAPC = nil
   for i = 1, objManager:GetMaxHeroes(), 1 do
      local hero = objManager:GetHero(i)
      if hero.team == me.team then
         table.insert(ALLIES, hero)
      else
         table.insert(ENEMIES, hero)
      end
   end   
   ADC = getADC(ALLIES)
   APC = getAPC(ALLIES)

   EADC = getADC(ENEMIES)
   EAPC = getAPC(ENEMIES)

   if ADC then
      DrawText("ADC:"..ADC.name, 10, 910, 0xFF00FF00)
   end
   if APC then
      DrawText("APC:"..APC.name, 10, 925, 0xFF00FF00)
   end
   if EADC then
      DrawText("ADC:"..EADC.name, 150, 910, 0xFFFF0000)
   end
   if EAPC then
      DrawText("APC:"..EAPC.name, 150, 925, 0xFFFF0000)
   end
end

function createForPersist(object)
      -- find minions
   if ( ( find(object.name, "Blue_Minion") and playerTeam == "Red" ) or 
        ( find(object.name, "Red_Minion") and playerTeam == "Blue" ) )
   then
      table.insert(MINIONS, object)
   end

   -- find my minions
   if ( ( find(object.name, "Blue_Minion") and playerTeam == "Blue" ) or 
        ( find(object.name, "Red_Minion") and playerTeam == "Red" ) )
   then
      table.insert(MYMINIONS, object)
   end

   if ListContains(object.name, MinorCreepNames, true) then
      table.insert(MINORCREEPS, object)
      table.insert(CREEPS, object)
   end
   if ListContains(object.name, BigCreepNames, true) then
      table.insert(BIGCREEPS, object)
      table.insert(CREEPS, object)
   end
   if ListContains(object.name, MajorCreepNames, true) then
      table.insert(MAJORCREEPS, object)
      table.insert(CREEPS, object)
      if object.name == "Dragon" then
         Persist("DRAGON", object)
      end
      if object.name == "Worm" then
         Persist("BARON", object)
      end
   end

   if startsWith(object.charName, "Turret_T") then
      if object.team ~= me.team then
         table.insert(TURRETS, object)
      else
         table.insert(MYTURRETS, object)
      end
   end

   if startsWith(object.charName, "Inhibit_Gem") then
      if object.team ~= me.team then
         table.insert(INHIBS, object)
      else
         table.insert(MYINHIBS, object)
      end
   end

   PersistOnTargets("recall", object, "TeleportHome", ENEMIES, ALLIES)

   if ListContains(object.charName, ccNames) then
      PersistOnTargets("cc", object, object.charName, ENEMIES, ALLIES)
   end

   if find(object.charName, "Ward") then
      table.insert(WARDS, object)
   end

   PersistToTrack(object, "Ashe_Base_R_mis", "Ashe", "EnchantedCrystalArrow")
   PersistToTrack(object, "HowlingGale_mis", "Janna", "HowlingGale")
   PersistToTrack(object, "Ezreal_TrueShot_mis", "Ezreal", "EzrealTrueshotBarrage")

   --sheen / trinity
   PersistBuff("enrage", object, "enrage_buf", 100)

   --lich bane
   PersistBuff("lichbane", object, "purplehands_buf", 100)

   --iceborn gauntlet
   PersistBuff("iceborn", object, "bluehands_buf", 100)

   PersistOnTargets("dfg", object, "deathFireGrasp_tar", ENEMIES)

   PersistBuff("muramana", object, "ItemMuramanaToggle")

   if Persist("cursorA", object, "Cursor_MoveTo_Red") then
      PData.cursorA.lastPos = Point(P.cursorA)
   end
   if Persist("cursorM", object, "Cursor_MoveTo.troy") then
      PData.cursorM.lastPos = Point(P.cursorM)
   end
end

function persistTick()
   Clean(WARDS, "charName", "Ward")
   Clean(TURRETS, "name", "Turret")
   Clean(MYTURRETS, "name", "Turret")
   Clean(INHIBS, "name", "Inhibit_Gem")
   Clean(MYINHIBS, "name", "Inhibit_Gem")
   CleanPersistedObjects()

   updateMinions()
   updateCreeps()
   updateHeroes()
   updateTrackedSpells()

end

function getADC(list)
   local value = 0
   local adc
   for i,test in ipairs(list) do
      local tValue = test.addDamage + (test.armorPen + test.armorPenPercent)*5 + test.attackspeed*10    
      if tValue > value then
         value = tValue
         adc = test
      end
   end
   return adc
end

function getAPC(list)
   local value = 0
   local apc
   for i,test in ipairs(list) do
      local tValue = test.ap + (test.magicPen + test.magicPenPercent)*5    
      if tValue > value then
         value = tValue
         apc = test
      end
   end
   return apc
end

SetTimerCallback("persistTick")