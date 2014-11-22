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

PETS = {}  -- heimer turrets, yorrick ghouls etc. Nothing exists in here yet
MYPETS = {}
-- simple attempt to grab high priority targets
ADC = nil
APC = nil

EADC = nil
EAPC = nil

CURSOR = nil
function ClearCursor()
   CURSOR = nil
end

WK_AA_TARGET = nil

-- persisted particles
P = {}
pOn = {}
PData = {}

-- name field
MinorCreepNames = {
   "SRU_MurkwolfMini", 
   "SRU_RedMini", 
   "SRU_BlueMini", 
   "SRU_BlueMini2", 
   "SRU_RazorbeakMini",
   "SRU_KrugMini",
   "Sru_Crab"
}
BigCreepNames = {
   "SRU_Murkwolf", 
   "SRU_Krug",
   "SRU_Razorbeak",
   "SRU_Gromp"
}
MajorCreepNames = {
   "SRU_Blue", 
   "SRU_Red",
   "SRU_Dragon",
   "SRU_Baron"
}

CreepNames = concat(MinorCreepNames, BigCreepNames, MajorCreepNames)

-- stuns roots fears taunts?
ccNames = {
   "Ahri_Charm_buf", 
   "Amumu_SadRobot_Ultwrap", 
   "Amumu_Ultwrap", 
   "CurseBandages",
   "DarkBinding_tar", 
   "Morgana_Skin06_Q_Tar.troy",

   "Global_Fear", 
   "Global_Taunt", 
   -- "leBlanc_shackle", 
   "LOC_Stun",
   "LOC_Suppress",
   "LOC_Taunt",
   "LuxLightBinding_tar.troy",
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
   "pantheon_heartseeker_cas2",
   "Katarina_deathLotus_cas",
   "drain.troy",
   "ReapTheWhirlwind_green_cas",
   "missFortune_ult_cas",
   "AbsoluteZero2",
   "InfiniteDuress_tar",
   "Xerath_Base_R_buf"
}


-- find an object and persist it
function Persist(name, object, charName, team)
   if team and object.team ~= team then
      return
   end
   if object and (not charName or find(object.charName, charName)) then
      P[name] = object
      PData[name] = {}
      PData[name].cn = object.charName
      return true
   end
end

function PersistTemp(name, ttl)
   if P[name] then
      if PData[name].timeout then
         PData[name].timeout = time() + ttl
      end
   else
      P[name] = {charName=name, x=0, z=0}
      PData[name] = {}
      PData[name].cn = name
      PData[name].timeout = time() + ttl
   end
   return P[name]
end

function IsTemp(name)
   if PData[name] and PData[name].timeout then
      return true
   end
   return false
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

function PersistPet(object, charName, name)
   if find(object.charName, charName) or find(object.name, name) then
      if object.team == me.team then
         return PersistAll("MYPET", object)
      else
         return PersistAll("PET", object)
      end
   end   
end

function PersistAll(name, object, charName)
   if object and (not charName or find(object.charName, charName)) then      
      Persist(name..object.id, object)
      PData[name..object.id].name = name
      PData[name..object.id].time = time()
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
      dist = 150
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
      local target = SortByDistance(GetInRange(object, 125, concat(...)), object)[1]
      if target then
         if not pOn[name] then
            pOn[name] = {}
         end
         Persist(name..object.id, object)
         PData[name..object.id].unit = target
         PData[name..object.id].time = time()
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
         not obj.x or not obj.z or
         ( obj.team ~= 0 and obj.dead == 1 )
      then
         -- pp("Clean "..name)
         P[name] = nil
         PData[name] = nil
      end
   end
   for name, data in pairs(PData) do

      if data.timeout and data.timeout < time() then
         P[name] = nil
         PData[name] = nil
      end

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
         if type(value) == number then
            if obj[field] ~= value then
               table.remove(list, i)
            end
         elseif not find(obj[field], value) then
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
      if IsValid(hero) then
         if hero.team == me.team then
            table.insert(ALLIES, hero)
         else
            table.insert(ENEMIES, hero)
         end
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

function IsMinorCreep(creep)
   if ListContains(creep.name, MinorCreepNames, true) then
      return true
   end
end
function IsBigCreep(creep)
   if ListContains(creep.name, BigCreepNames, true) then
      return true
   end
end
function IsMajorCreep(creep)
   if ListContains(creep.name, MajorCreepNames, true) then
      return true
   end
end   
function IsCreep(creep)
   return creep.team == 300
end   


function createForPersist(object)
   if IsMinorCreep(object) then
      table.insert(MINORCREEPS, object)
      table.insert(CREEPS, object)
   end
   if IsBigCreep(object) then
      table.insert(BIGCREEPS, object)
      table.insert(CREEPS, object)
   end
   if IsMajorCreep(object) then
      table.insert(MAJORCREEPS, object)
      table.insert(CREEPS, object)
      if object.name == "Dragon" then
         Persist("DRAGON", object)
      end
      if object.name == "Worm" then
         Persist("BARON", object)
      end
   end

   if object.team ~= me.team then
      PersistAll("TURRET", object, "Turret_T")
      PersistAll("MINIONS", object, "Minion_T")
   else
      PersistAll("MYTURRET", object, "Turret_T")
      PersistAll("MYMINIONS", object, "Minion_T")
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
      local target = PersistOnTargets("cc", object, object.charName, ENEMIES, ALLIES)
      if target then
         pp("CC on "..target.name.." "..object.charName)
      end
   end

   -- for _,enemy in ipairs(ENEMIES) do
   --    if enemy.y - me.y > 75 then
   --       PersistOnTargets("cc", enemy, enemy.charName, ENEMIES)
   --    else
   --       P["cc"..enemy.id] = nil
   --    end
   -- end

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

   PersistOnTargets("hemoplague", object, "Vladimir_Base_R_debuff.troy", ENEMIES)

   PersistBuff("blind", object, "Global_miss.troy")
   PersistBuff("silence", object, "LOC_Silence.troy")

   PersistBuff("muramana", object, "ItemMuramanaToggle")

   PersistBuff("manaPotion", object, "GLOBAL_Item_Mana")
   PersistBuff("healthPotion", object, "GLOBAL_Item_Health")

   if Persist("cursorA", object, "Cursor_MoveTo_Red") then
      PData.cursorA.lastPos = Point(P.cursorA)
   end
   if Persist("cursorM", object, "Cursor_MoveTo.troy") then
      PData.cursorM.lastPos = Point(P.cursorM)
   end

   for _,spell in pairs(spells) do
      if spell.modAA and spell.object then
         PersistBuff(spell.modAA, object, spell.object, 200)
      end
   end


   -- CREDIT TO LUA for inspiration in his IsInvulnerable script.
   PersistOnTargets("invulnerable", object, "eyeforaneye", ENEMIES) -- kayle intervention
   PersistOnTargets("invulnerable", object, "nickoftime", ENEMIES) -- zilean chronoshift
   PersistOnTargets("invulnerable", object, "UndyingRage_buf", ENEMIES) -- trynd ult
   PersistOnTargets("invulnerable", object, "VladSanguinePool_buf", ENEMIES) -- vlad sanguine pool   
   -- if I am the target of diplomatic immunity don't bother recording diplomatic immunity
   PersistBuff("diplomaticImmunityTarget", object, "DiplomaticImmunity_tar")
   if not P.diplomaticImmunityTarget then
      PersistOnTargets("invulnerable", object, "DiplomaticImmunity_buf", ENEMIES) -- poppy diplomatic immunity
   end

   PersistOnTargets("bansheesVeil", object, "bansheesveil_buf", ENEMIES) -- vlad sanguine pool

   PersistOnTargets("spellImmune", object, "Sivir_Base_E_shield", ENEMIES)
   PersistOnTargets("spellImmune", object, "nocturne_shroudofDarkness_shield", ENEMIES)


   -- PETS
   -- zyra
   PersistPet(object, nil, "ZyraThornPlant")
   PersistPet(object, nil, "ZyraGraspingPlant")
   
   -- malzahar
   PersistPet(object, "Voidling")

   -- yorick
   PersistPet(object, "Inky")
   PersistPet(object, "Blinky")
   PersistPet(object, "Clyde")
   if object.type == 12 then
      for _,hero in ipairs(concat(ENEMIES, ALLIES, me)) do
         if object.charName == hero.charName then
            PersistPet(object, object.charName)
            break
         end
      end
   end

   -- heimerdinger
   PersistPet(object, "H-28G Evolution Turret")

   -- leblanc
   PersistPet(object, "LeblancImage")

   -- morde (-- hard to test)

   -- shaco
   PersistPet(object, "Jack In The Box")
   if object.type == 12 and P.shacoClone then
      PersistPet(object, P.shacoClone.charName)
   end

end

function persistTick()
   Clean(WARDS, "charName", "Ward")
   Clean(INHIBS, "name", "Inhibit_Gem")
   Clean(MYINHIBS, "name", "Inhibit_Gem")

   CleanPersistedObjects()

   updateMinions()
   updateCreeps()
   updateHeroes()
   updateTrackedSpells()

   MINIONS = ValidTargets(GetPersisted("MINIONS"))
   MYMINIONS = ValidTargets(GetPersisted("MYMINIONS"))
   TURRETS = ValidTargets(GetPersisted("TURRET"))
   MYTURRETS = ValidTargets(GetPersisted("MYTURRET"))
   PETS = GetPersisted("PET")
   MYPETS = GetPersisted("MYPET")
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