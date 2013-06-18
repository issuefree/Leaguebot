local function table_print (tt, indent, done)
   done = done or {}
   indent = indent or 0
   if type(tt) == "table" then
      local sb = {}
      for key, value in pairs (tt) do
         table.insert(sb, string.rep (" ", indent)) -- indent it
         if type (value) == "table" and not done [value] then
            done [value] = true
            table.insert(sb, "{\n");
            table.insert(sb, table_print (value, indent + 2, done))
            table.insert(sb, string.rep (" ", indent)) -- indent it
            table.insert(sb, "}\n");
         elseif "number" == type(key) then
            table.insert(sb, string.format("\"%s\"\n", tostring(value)))
         else
            table.insert(sb, string.format(
            "%s = \"%s\"\n", tostring (key), tostring(value)))
         end
      end
      return table.concat(sb)
   else
      return tt .. "\n"
   end
end

function pp(str)
   if str == nil then
      pp("nil")
   elseif type(str) == "table" then
      pp(table_print(str, 2))
   else
      printtext(str.."\n")
   end
end

function merge(table1, table2)
   local resTable = {}
   for k,v in pairs(table1) do
      resTable[k] = v
   end
   for k,v in pairs(table2) do
      resTable[k] = v
   end
   return resTable
end

function concat(...)
   --arg = GetVarArg(arg)
   local resTable = {}
   for _,tablex in ipairs(...) do
      if type(tablex) == "table" then
         for _,v in ipairs(tablex) do
            table.insert(resTable, v)
         end
      else
         table.insert(resTable, tablex)
      end      
   end
   return resTable
end

function rpairs(t)
   return prev, t, table.getn(t)+1
end

function prev(t, i)
   if i == 1 then
      return nil
   end
   return i-1, t[i-1]
end

local line = 0
function PrintState(state, str)
   DrawText(str,100,100+state*15,0xFFCCEECC);
-- pp(state.."."..str)
end

LOADING = true

OBJECT_CALLBACKS = {}
SPELL_CALLBACKS = {}

function AddOnCreate(callback)
   table.insert(OBJECT_CALLBACKS, callback)
end

function AddOnSpell(callback)
   table.insert(SPELL_CALLBACKS, callback)   
end

-- circle colors
yellow = 0
green  = 1
red    = 2
blue   = 3
violet = 4

-- globals for convenience
me = GetSelf()
hotKey = GetScriptKey()
playerTeam = ""

-- common item / spell defs
ITEMS = {}
spells = {}

-- simple attempt to grab high priority targets
ADC = nil
APC = nil

EADC = nil
EAPC = nil

-- object arrays
MINIONS = {}
MYMINIONS = {}
CREEPS = {}
ALLIES = {}
ENEMIES = {}
RECALLS = {}
TURRETS = {}
MYTURRETS = {}
CCS = {}
WARDS = {}

DRAGON = {}
BARON = {}

-- name field
MinorCreepNames = {
   "wolf", 
   "YoungLizard", 
   "LesserWraith",
   "SmallGolem"
}
BigCreepNames = {
   "GiantWolf", 
   "Wraith", 
   "Golem"
}
MajorCreepNames = {
   "AncientGolem", 
   "LizardElder",
   "Dragon",
   "Worm"
}

CreepNames = concat(MinorCreepNames, BigCreepNames, MajorCreepNames)

ENEMY_SPELLS = {
   {charName = "Akali", spellName = "akalimota", spellType = "Damage"},
   {charName = "Alistar", spellName = "headbutt", spellType = "Stun"},
   {charName = "Amumu", spellName = "bandagetoss", spellType = "Stun"},
   {charName = "Anivia", spellName = "flashfrost", spellType = "Stun"},
   {charName = "Anivia", spellName = "frostbite", spellType = "Damage"},
   {charName = "Annie", spellName = "disintigrate", spellType = "Stun"},
   {charName = "Annie", spellName = "infernalguardian", spellType = "Stun"},   
   {charName = "Ahri", spellName = "ahriseduce", spellType = "Stun"},   
   {charName = "Ashe", spellName = "volley", spellType = "Slow"},
   {charName = "Blitzcrank", spellName = "rocketgrab", spellType = "Stun"},   
   {charName = "Brand", spellName = "brandblaze", spellType = "Damage"},   
   {charName = "Brand", spellName = "brandconflagration", spellType = "Damage"},   
   {charName = "Brand", spellName = "brandwildfire", spellType = "Damage"},   
   {charName = "Caitlyn", spellName = "caitlynpiltoverpeacemaker", spellType = "Damage"},   
   {charName = "Caitlyn", spellName = "caitlynentrapment", spellType = "Slow"},   
   {charName = "Caitlyn", spellName = "caitlynaceinthehole", spellType = "Damage"},   
   {charName = "Chogath", spellName = "rupture", spellType = "Damage"},   
   {charName = "Chogath", spellName = "feralscream", spellType = "Damage"},   
   {charName = "Chogath", spellName = "feast", spellType = "Damage"},   
   {charName = "Corki", spellName = "missilebarrage", spellType = "Damage"},   
   {charName = "Darius", spellName = "dariusaxegrabcone", spellType = "Stun"},
   {charName = "Darius", spellName = "dariusexecute", spellType = "Damage"},
   {charName = "Draven", spellName = "dravendoubleshot", spellType = "Slow"},
   {charName = "Draven", spellName = "dravenrcast", spellType = "Damage"},
   {charName = "Dr. Mundo", spellName = "infectedcleavermissilecast", spellType = "Slow"},
   {charName = "Fiddlesticks", spellName = "terrify", spellType = "Stun"},
   {charName = "Fiddlesticks", spellName = "drain", spellType = "Damage"},
   {charName = "Fizz", spellName = "fizzmarinerdoom", spellType = "Damage"},
   {charName = "Galio", spellName = "galioresolutesmite", spellType = "Damage"},
   {charName = "Gangplank", spellName = "parley", spellType = "Damage"},
   {charName = "Garen", spellName = "garenjustice", spellType = "Silence"},
   {charName = "Graves", spellName = "gravesclustershot", spellType = "Damage"},
   {charName = "Graves", spellName = "graveschargeshot", spellType = "Damage"},
   {charName = "Heimerdinger", spellName = "hextechmicrorockets", spellType = "Damage"},
   {charName = "Irelia", spellName = "ireliaequilibriumstrike", spellType = "Stun"},
   {charName = "Janna", spellName = "sowthewind", spellType = "Slow"},
   {charName = "Jayce", spellName = "jayceshockblast", spellType = "Damage"},
   {charName = "Karthus", spellName = "fallenone", spellType = "Damage"},
   {charName = "Kassadin", spellName = "nulllance", spellType = "Damage"},
   {charName = "Kassadin", spellName = "forcepulse", spellType = "Damage"},
   {charName = "Kayle", spellName = "judicatorreckoning", spellType = "Slow"},
   {charName = "LeBlanc", spellName = "leblancchaosorb", spellType = "Slow"},
   {charName = "LeBlanc", spellName = "leblancsoulshackle", spellType = "Slow"},
   {charName = "LeeSin", spellName = "blindmonkqone", spellType = "Damage"},
   {charName = "Leona", spellName = "leonasolarflare", spellType = "Stun"},
   {charName = "Lulu", spellName = "luluw", spellType = "Slow"},
   {charName = "Lux", spellName = "luxlightbinding", spellType = "Stun"},
   {charName = "Malphite", spellName = "ufslash", spellType = "Stun"},
   {charName = "Malphite", spellName = "seismicshard", spellType = "Slow"},
   {charName = "Malzahar", spellName = "alzaharnethergrasp", spellType = "Stun"},
   {charName = "Malzahar", spellName = "alzaharmaleficvisions", spellType = "Damage"},
   {charName = "Maoki", spellName = "maokaitrunkline", spellType = "Stun"},
   {charName = "Maoki", spellName = "maokaiunstablegrowth", spellType = "Stun"},
   {charName = "MasterYi", spellName = "alphastrike", spellType = "Damage"},
   {charName = "MissFortune", spellName = "missfortunericochetshot", spellType = "Damage"},
   {charName = "Mordekaiser", spellName = "mordekaiserchildrenofthegrave", spellType = "Damage"},
   {charName = "Morgana", spellName = "darkbinding", spellType = "Stun"},
   {charName = "Nasus", spellName = "wither", spellType = "Stun"},
   {charName = "Nautilus", spellName = "nautilusanchordrag", spellType = "Stun"},
   {charName = "Nautilus", spellName = "nautilusgrandline", spellType = "Stun"},
   {charName = "Nidalee", spellName = "javelintoss", spellType = "Damage"},
   {charName = "Nocturne", spellName = "nocturneduskbringer", spellType = "Damage"},
   {charName = "Nunu", spellName = "iceblast", spellType = "Stun"},
   {charName = "Olaf", spellName = "olafaxethrowcast", spellType = "Slow"},
   {charName = "Olaf", spellName = "olafrecklessstrike", spellType = "Slow"},
   {charName = "Pantheon", spellName = "pantheon_throw", spellType = "Damage"},
   {charName = "Pantheon", spellName = "pantheon_leapbash", spellType = "Stun"},
   {charName = "Rammus", spellName = "puncturingtaunt", spellType = "Stun"},
   {charName = "Rengar", spellName = "rengarE", spellType = "Stun"},
   {charName = "Ryze", spellName = "runeprison", spellType = "Stun"},
   {charName = "Ryze", spellName = "overload", spellType = "Damage"},
   {charName = "Shen", spellName = "shenshadowdash", spellType = "Stun"},
   {charName = "Sion", spellName = "crypticgaze", spellType = "Stun"},
   {charName = "Skarner", spellName = "skarnerimpale", spellType = "Stun"},
   {charName = "Sona", spellName = "sonacrescendo", spellType = "Stun"},
   {charName = "Taric", spellName = "dazzle", spellType = "Stun"},
   {charName = "Teemo", spellName = "blindingdart", spellType = "Damage"},
   {charName = "Tristana", spellName = "detonatingshot", spellType = "Damage"},
   {charName = "Tristana", spellName = "bustershot", spellType = "Damage"},
   {charName = "Tryndamere", spellName = "mockingshout", spellType = "Slow"},
   {charName = "Twisted Fate", spellName = "redcard", spellType = "Slow"},
   {charName = "Twisted Fate", spellName = "yellowcard", spellType = "Stun"},    
   {charName = "Twisted Fate", spellName = "wildcards", spellType = "Stun"},    
   {charName = "Twitch", spellName = "TwitchVenomCask", spellType = "Slow"},    
   {charName = "Varus", spellName = "varusr", spellType = "Stun"},    
   {charName = "Vayne", spellName = "VayneCondemn", spellType = "Stun"},    
   {charName = "Veigar", spellName = "veigarbalefulstrike", spellType = "Damage"},    
   {charName = "Veigar", spellName = "veigareventhorizon", spellType = "Stun"},    
   {charName = "Veigar", spellName = "veigarprimordialburst", spellType = "Damage"},    
   {charName = "Volibear", spellName = "volibearq", spellType = "Stun"},    
   {charName = "Vi", spellName = "assaultandbattery", spellType = "Stun"},
   {charName = "Xerath", spellName = "xeratharcanopulse", spellType = "Damage"},
   {charName = "Zyra", spellName = "ZyraGraspingRoots", spellType = "Stun"}
}


enrage = nil
lichbane = nil
-- tear of the goddess items
tear = nil

-- globals for the toggle menus
keyToggles = {}
toggleOrder = {}

spells["AA"] = {range=me.range+50, base={0}, ad=1, type="P", color=red} 


-- stuns roots fears taunts?
ccNames = {"Stun_glb", "summoner_banish", "Global_Taunt", "Global_Fear", "Ahri_Charm_buf", "leBlanc_shackle_tar", "LuxLightBinding_tar", "RunePrison_tar", "DarkBinding_tar", "Amumu_SadRobot_Ultwrap", "Amumu_Ultwrap", "maokai_elementalAdvance_root_01", "VarusRHitFlash"}

--Active offense
ITEMS["Entropy"]                  = {id=3184, range=me.range+50, type="active"}
ITEMS["Bilgewater Cutlass"]       = {id=3144, range=500,         type="active", color=violet}
ITEMS["Hextech Gunblade"]         = {id=3146, range=700,         type="active", color=violet}
ITEMS["Blade of the Ruined King"] = {id=3153, range=500,         type="active", color=violet}
ITEMS["Deathfire Grasp"]          = {id=3128, range=750,         type="active", color=violet}
ITEMS["Tiamat"]                   = {id=3077, range=350,         type="active", color=red}
ITEMS["Ravenous Hydra"]           = {id=3074, range=350,         type="active", color=red}
ITEMS["Youmuu's Ghostblade"]      = {id=3142, range=me.range+50, type="active"}
ITEMS["Randuin's Omen"]           = {id=3143, range=500,         type="active", color=yellow}

--Active defense
ITEMS["Locket of the Iron Solari"] = {id=3190, range=700, type="active", color=green}
ITEMS["Guardian's Horn"] = {id=2051, type="active"}

--Aura offense
ITEMS["Abyssal Scepter"] = {id=3001, range=700, type="aura", color=violet}
ITEMS["Frozen Heart"]    = {id=3110, range=700, type="aura", color=blue}

--Aura Defense
ITEMS["Mana Manipulator"]     = {id=3037, range=1200, type="aura", color=blue}
ITEMS["Aegis of Legion"]      = {id=3105, range=1200, type="aura", color=green}
ITEMS["Banner of Command"]    = {id=3060, range=1000, type="aura", color=yellow}
ITEMS["Emblem of Valor"]      = {id=3097, range=1200, type="aura", color=green}
ITEMS["Runic Bulwark"]        = {id=3107, range=1200, type="aura", color=green}
ITEMS["Shard of True Ice"]    = {id=3092, range=1200, type="aura", color=blue}
ITEMS["Will of the Ancients"] = {id=3152, range=1200, type="aura", color=yellow}
ITEMS["Zeke's Herald"]        = {id=3050, range=1200, type="aura", color=yellow}

--Active cleanse
ITEMS["Quicksilver Sash"]   = {id=3140,            type="active"}
ITEMS["Mercurial Scimitar"] = {id=3139,            type="active"}
ITEMS["Mikael's Crucible"]  = {id=3222, range=750, type="active"}

--On Hit
ITEMS["Malady"] = {id=3114, base={15}, ap=.1}
ITEMS["Wit's End"] = {id=3091, base={42}}

ITEMS["Sheen"]         = {id=3057, base={0}, adBase=1}
ITEMS["Trinity Force"] = {id=3078, base={0}, adBase=1.5}
ITEMS["Lich Bane"]     = {id=3100, base={50}, ap=.75}

-- Tear
ITEMS["Tear of the Goddess"] = {id=3070}
ITEMS["Archangel's Staff"] = {id=3003}
ITEMS["Manamune"] = {id=3004}


repeat
   if string.format(me.team) == "100" then
      playerTeam = "Blue"
      HOME = {x=27, z=265}
   elseif string.format(me.team) == "200" then  
      playerTeam = "Red"
      HOME = {x=13923, z=14169}
   end
until playerTeam ~= nil and playerTeam ~= "0"

local function drawCommon()
   if me.dead == 1 then
      return
   end
end

function LoadConfig(name)
   local config = {}
   for line in io.lines(name..".cfg") do
      for k,v in string.gmatch(line, "(%w+)=(%w+)") do
         config[k] = v
      end
   end
   return config
end

function SaveConfig(name, config)
   local file = io.open(name..".cfg", "w")
   for k,v in pairs(config) do
      file:write(k.."="..v.."\n")
   end
   file:close()
end

function AddToggle(key, value)
   keyToggles[key] = value
   table.insert(toggleOrder, key)
end

function IsOn(key)
   return keyToggles[key].on
end

function GetMousePos()
   return {x=GetCursorWorldX(), y=GetCursorWorldY(), z=GetCursorWorldZ()}
end

local pressed = {}
local function checkToggles()
   for _,toggle in pairs(keyToggles) do      
      local key = toggle.key     
      if IsKeyDown(key) == 1 then
         pressed[key] = true
      elseif IsKeyDown(key) == 0 then
         if pressed[key] == true then 
            toggle.on = not toggle.on 
            pressed[key] = false
         end
      end
   end
   DrawToggles()
end

local labelX = 280
local labelY = 960
function DrawToggles()
   for i,key in ipairs(toggleOrder) do
      local val = keyToggles[key]
      local label = val.label
      local auxLabel = val.auxLabel
      if val.args then
         for a,v in ipairs(val.args) do
            local arg = expandToggleArg(val.args[a])           
            label = string.gsub(label, "{"..(a-1).."}", arg)
            auxLabel = string.gsub(auxLabel, "{"..(a-1).."}", arg)
         end
      end
      if val.on then
         DrawText(label,labelX,labelY+(i-1)*15,0xFF00EE00);
         if auxLabel then        
            DrawText(auxLabel,labelX+150,labelY+(i-1)*15,0xFF00EE00);
         end
      else
         DrawText(label,labelX,labelY+(i-1)*15,0xFFFFFF00);
         if auxLabel then
            DrawText(auxLabel,labelX+150,labelY+(i-1)*15,0xFFFFFF00);
         end
      end
   end   
end

function expandToggleArg(arg)
   if type(arg) == "string" then
      return GetSpellDamage(arg) 
   elseif type(arg) == "function" then
      return arg()
   end
end

function SafeCall(f, ...)
   local b,e = pcall(f, ...)
   if not b then
      pp(e)
   end
end

function doCreateObj(object)
   if not (object and object.x and object.z) then
      return
   end

   -- find minions
   if ( ( find(object.name, "Blue_Minion") and playerTeam == "Red" ) or 
        ( find(object.name, "Red_Minion") and playerTeam == "Blue" ) )
   then
      table.insert(MINIONS, object)
   end

   -- find minions
   if ( ( find(object.name, "Blue_Minion") and playerTeam == "Blue" ) or 
        ( find(object.name, "Red_Minion") and playerTeam == "Red" ) )
   then
      table.insert(MYMINIONS, object)
   end

   if ListContains(object.name, CreepNames, true) then
      if object.name == "Dragon" then         
         DRAGON = {object.name, object}
      end
      if object.name == "Worm" then
         BARON = {object.name, object}
      end
      table.insert(CREEPS, object)
   end

   if ( find(object.name, "OrderTurret") or
        find(object.name, "ChaosTurret") )
   then
      if object.team ~= me.team then        
         table.insert(TURRETS, object)
      else
         table.insert(MYTURRETS, object)
      end
   end

   if find(object.charName, "TeleportHome") then
      table.insert(RECALLS, object)
   end

   if ListContains(object.charName, ccNames) then
      table.insert(CCS, object)
   end

   if find(object.name, "Ward") then
      table.insert(WARDS, object)
   end

   --sheen / trinity
   if find(object.charName, "enrage_buf") and 
      GetDistance(object) < 50 
   then
      enrage = {object.charName, object}
   end   

   --lich bane
   if find(object.charName, "purplehands_buf") and 
      GetDistance(object) < 50 
   then
      lichbane = {object.charName, object}
   end

   --tear
   if find(object.charName, "TearoftheGoddess") and 
      GetDistance(object) < 50 
   then
      tear = {object.charName, object}
   end
   
   
      
   for i, callback in ipairs(OBJECT_CALLBACKS) do
      callback(object, LOADING)
   end
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

function IsMinion(object)
   return find(object.name, "Minion")
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

function GetVis(list)
   return FilterList(list, function(item) return item.dead == 0 and item.visible == 1 end)
end

local function updateMinions()
   for i,minion in rpairs(MINIONS) do
      if not minion or
         minion.dead == 1 or
         minion.x == nil or 
         minion.y == nil or
         not find(minion.name, "Minion")
      then
         table.remove(MINIONS,i)
      end
   end
   for i,minion in rpairs(MYMINIONS) do
      if not minion or
         minion.dead == 1 or
         minion.x == nil or 
         minion.y == nil or
         not find(minion.name, "Minion")
      then
         table.remove(MYMINIONS,i)
      end
   end
end

local function updateCreeps()
   for i,unit in rpairs(CREEPS) do
      if not unit or
         unit.dead == 1 or
         unit.x == nil or 
         unit.y == nil or
         not ListContains(unit.name, CreepNames)
      then
         table.remove(CREEPS,i)
      end
   end
end

local function updateObjects()
   updateMinions()
   updateCreeps()
   updateHeroes()
   Clean(RECALLS, "charName", "TeleportHome")
   Clean(CCS)
   Clean(WARDS, "name", "Ward")
   Clean(TURRETS, "name", "Turret")
   Clean(MYTURRETS, "name", "Turret")
end

function KillMinionsInLine(thing, minKills, extraRange, drawOnly)
   local spell = GetSpell(thing)
   if not spell then return end
   if not CanUse(spell) then return end

   if not extraRange then extraRange = 0 end

   local width = spell.width
   local minionWidth = 50

   local minions = GetInRange(me, spell.range+extraRange, MINIONS)
   if #minions == 0 then
      return
   end
   SortByDistance(minions)
   
   local bestT
   local bestTK = 0
   
   for i = 1, #minions do
      local minion = minions[i]
      bt = minion 
      tk = 0
      local d = GetDistance(minion)
      for _,min in ipairs(minions) do
         if GetSpellDamage(spell, min) > min.health then 
            local a = AngleBetween(me, min)
            local proj = {x=me.x+math.sin(a)*d, z=me.z+math.cos(a)*d}
            if GetDistance(minion, proj) < width+minionWidth then
               tk = tk + 1
            end
         end         
      end      
   end
   if not bestT or tk > bestTK then
      bestT = bt
      bestTK = tk
   end
   
   if bestT and bestTK >= minKills then
      local a = AngleBetween(me, bestT)
      local x = me.x+math.sin(a)*1000
      local z = me.z+math.cos(a)*1000

      DrawTextObject(bestTK, bestT, 0xff00ffff)
      DrawLineObject(me, 1000, 1, AngleBetween(me, bestT), width)
      if not drawOnly then
         CastSpellXYZ("Q",x,0,z) ;
      end
   end
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

function OrbWalk(millis)
   if not millis then
      millis = 500
   end
   
   DoIn(
      function() 
         local p = GetLastOrder()
         MoveToXYZ(p.x, p.y, p.z)
      end, 
      millis,
      "orb"
   )
end

function MoveToTarget(t)
   MoveToXYZ(t.x, t.y, t.z)
end

-- find lowest health minion in range and smack it if it will die
function KillWeakMinion(thing, extraRange)
   if throttle("kwm", 100) then return nil end

   local spell = GetSpell(thing)
   if spell and not CanUse(spell) then return nil end
   
   if not extraRange then extraRange = 0 end
   -- find a weak minion
   local wMinion
   for _,minion in ipairs(GetInRange(me, spell.range+extraRange, MINIONS)) do
      if not wMinion or minion.health < wMinion.health then
         wMinion = minion
      end
   end

   -- if it's weak enough KILL IT
   if wMinion then
      if spells["AA"] == spell then
         if GetAADamage(wMinion) > wMinion.health then
            AttackTarget(wMinion)
            return wMinion
         end
      else
         if GetSpellDamage(spell, wMinion) > wMinion.health then
            CastSpellTarget(spell.key, wMinion)
            return wMinion
         end
      end
   end
   return nil
end

-- find the furthest away minion that you can kill and smack it
function KillFarMinion(spell)
   if not CanUse(spell) then return end

   local damage = GetSpellDamage(spell)

   local wMinion, wMinionD
   for _,minion in ipairs(GetInRange(me, spell.range, MINIONS)) do
      if GetSpellDamage(spell, minion) > minion.health then
         local minionD = GetDistance(minion)
         if not wMinionD or minionD > wMinionD then
            wMinion = minion
            wMinionD = minionD
         end
      end
   end
   if wMinion then
      if not spell.key then
         AttackTarget(wMinion)
      else
         CastSpellTarget(spell.key, wMinion)
      end
   end
end

--[[
Returns the x,y,z of the center of the targes
--]]
function GetCenter(targets)
   local x = 0
   local y = 0
   local z = 0
         
   for _,t in ipairs(targets) do
      x = x + t.x
      y = y + t.y
      z = z + t.z
   end
   
   x = x / #targets
   y = y / #targets
   z = z / #targets
   
   return x,y,z
end

--[[
returns the width of a unit
--]]
function GetWidth(unit)
   local minbb = GetMinBBox(unit)
   if not minbb.x then -- for when I pass in not a real unit
      return 70
   end
   return GetDistance(unit, minbb)
end

function GetInLine(width, targets, style)
   local hits = {}
   local score = 0
   
   SortByAngle(targets)   
         
   for pi,p in ipairs(targets) do
      local lHits = {p}
      local lScore = 0
      local pw = GetWidth(p)
      for si,s in ipairs(targets) do
         if s ~= p then
            local sw = GetWidth(s)
            local ra = RelativeAngle(me, p, s)
            if GetOrthDist(p, s) < width + pw + sw and ra < math.pi/3 then
               table.insert(lHits, s)
            end
         end
      end
      
      if style == "damage" then
         for _,lHit in ipairs(lHits) do
            lScore = lScore + GetSpellDamage("spark", lHit)
         end
      elseif style == "hits" then
         lScore = lScore + 1      
      else --if style == "kills" then
         for _,lHit in ipairs(lHits) do
            if GetSpellDamage("spark", lHit) > lHit.health then
               lScore = lScore + 1
            end 
         end
      end
      if lScore > score then         
         hits = lHits
         score = lScore
      end
   end
   
   return hits
end

function KillMinionsInCone(thing, minKills, extraRange, drawOnly)
   local spell = GetSpell(thing)
   if not spell then return end
   if not CanUse(spell) then return end

   if not extraRange then extraRange = 0 end

   -- cache damage calculation      
   local wDam = GetSpellDamage(spell)
   -- convert from degrees   
   local spellAngle = spell.cone/360*math.pi*2

   local minionAngles = {}

   -- clean out the ones I can't kill and get the angles   
   for i,minion in ipairs(GetInRange(me, spell.range+extraRange, MINIONS)) do
      if CalcMagicDamage(minion, wDam) > minion.health then
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
         DrawCircle(x,y,z,25,yellow)
         LineBetween(me, minionAngles[bestAngleI][2])
         LineBetween(me, minionAngles[bestAngleJ][2])
         
         -- execute
         if not drawOnly then
            if farMinionD < spell.range then                        
               CastSpellXYZ(spell.key, x,y,z)
            else
               -- move 50 units toward the target spot
               local a = AngleBetween(me, farMinion)
               local d = 50
               local proj = {x=source.x+math.sin(a)*d, z=source.z+math.cos(a)*d}
               MoveToXYZ(proj.x, me.y, proj.z)
            end
         end
      end
   end
end

function SkillShot(thing, purpose)
   local spell = GetSpell(thing)

   -- doesn't matter if its phys or mag, we just want to know if there's someone in range
   if GetWeakEnemy("MAGIC", spell.range) and CanUse(spell) then

      -- if we don't have spell speed or delay use some sensible defaults.
      if not spell.delay then spell.delay = 2 end
      if not spell.speed then spell.speed = 20 end
   
      local unblocked = GetUnblocked(me, spell.range, spell.width, GetVis(MINIONS), GetVis(ENEMIES))

      unblocked = FilterList(unblocked, function(item) return not IsMinion(item) end)

      local target
      while true do
         if #unblocked == 0 then
            break
         end
         if purpose == "peel" then
            target = GetPeel({ADC, APC, me}, unblocked)
         else
            target = GetWeakest(spell, unblocked)
         end
         if not target then
            break
         end
         if SSGoodTarget(target, spell) then
            break
         end
         for i,t in ipairs(unblocked) do
            if t.name == target.name then
               table.remove(unblocked, i)
               break
            end
         end
         target = nil
      end
      
      if target then
         local x,y,z = GetFireahead(target,spell.delay,spell.speed*1.2)
         CastSpellXYZ(spell.key, x,y,z)
         return true
      end
   end
   return false
end

function SSGoodTarget(target, spell)
   if not target then
--      pp("no target")
      return false
   end
   -- up speed by 20% so we don't get quite so much leading
   local x,y,z = GetFireahead(target,spell.delay,spell.speed*1.2)
   
   if GetDistance({x=x, y=y, z=z}) > spell.range then
--      pp(target.name.." target leaving range")
      return false
   end
   
   if GetDistance(target, {x=x, y=y, z=z}) < 50 then
--      pp(target.name.." target not moving KILLIT")
      return true
   end
   
   local angleRel = RadsToDegs(ApproachAngle(target, me))
   angleRel = math.abs(angleRel-90)

   if angleRel > 30 then
--      pp(target.name.." angle ("..angleRel..") ok. shoot")
      return true
   end
   
   return false   
end

function GetUnblocked(source, range, width, ...)
   local minionWidth = 55
   local targets = GetInRange(source, range, concat(...))
   SortByDistance(targets, source)
   
   local blocked = {}
   
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

function FacingMe(target)
   local d1 = GetDistance(target)
   local x, y, z = GetFireahead(target,2,10)
   local d2 = GetDistance({x=x, y=y, z=z})
   return d2 < d1 
end

function Check(object)
   if not object or not object[1] or not object[2] then return false end
   if object[1] == object[2].charName or object[1] == object[2].name then
      return true
   end
   return false 
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

function HotKey()
   return IsKeyDown(hotKey) ~= 0
end

function IsRecalling(hero)
   for _, recall in ipairs(RECALLS) do
      if GetDistance(hero, recall) == 0 then
         return true
      end
   end
   return false
end

function find(source, target)
   if not source then
      return false
   end
   if string.len(target) == 0 then
      return false
   end
   return string.find(string.lower(source), string.lower(target))
end

function copy(orig)
   local orig_type = type(orig)
   local copy
   if orig_type == 'table' then
      copy = {}
      for orig_key, orig_value in pairs(orig) do
         copy[orig_key] = orig_value
      end
   else -- number, string, boolean, etc
      copy = orig
   end
   return copy
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

function GetInRange(target, range, ...)
   local result = {}
   local list = GetVis(concat(...))
   for _,test in ipairs(list) do
      if target and test and test.x and test.dead == 0  and
         GetDistance(target, test) < range 
      then
         table.insert(result, test)
      end
   end
   return result
end

function SortByHealth(things, target)
   table.sort(things, function(a,b) return a.health < b.health end)
end

function SortByDistance(things, target)
   table.sort(things, function(a,b) return GetDistance(a, target) < GetDistance(b, target) end)
end

function SortByAngle(things)
   table.sort(things, function(a,b) return AngleBetween(me, a) < AngleBetween(me, b) end)
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

function FilterList(list, f)
   local res = {}
   for _,item in ipairs(list) do
      if f(item) then
         table.insert(res, item)
      end
   end
   return res
end

function ListContains(item, list, exact)
   if type(item) ~= "string" then
      exact = true
   end
   for _,test in pairs(list) do
      if exact then
         if item == test then return true end
      else
         if find(item, test) then return true end
      end
   end
   return false
end

function CanChargeTear()
   if ( GetInventorySlot(ITEMS["Tear of the Goddess"].id) or
        GetInventorySlot(ITEMS["Archangel's Staff"].id) or
        GetInventorySlot(ITEMS["Manamune"].id) ) and 
      not Check(tear) 
   then
      return true
   end
   return false
end


function UseItem(itemName, target)
   local item = ITEMS[itemName]
   local slot = GetInventorySlot(item.id)
   if not slot then return end   
   slot = tostring(slot)
   if not CanCastSpell(slot) then return end

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
      -- locket
      -- how about 3 nearby allies and 2 nearby enemies
      local locketRange = 700
      if #GetInRange(me, locketRange, ALLIES) >= 3 and
      #GetInRange(me, locketRange, ENEMIES) >= 2 
      then
         CastSpellTarget(slot, me)
      end


   elseif itemName == "Mikael's Crucible" then
      -- crucible
      -- It can heal or it can cleans
      -- heal is better the lower they are so how about scan in range heros and heal the lowest under 25%
      -- the cleanse is trickier. should I save it for higher priority targets or just use it on the first who needs it?\
      -- I took (or tried to) take out the slows so it will only work on harder cc.
      -- how about try to free adc then apc then check for heals on all in range.

      local crucibleRange = 750

      local target = ADC
      if target and target.name ~= me.name and 
         GetDistance(target, me) < crucibleRange and
         #GetInRange(target, 50, CCS) > 0
      then 
         CastSpellTarget(slot, target)
         pp("uncc adc "..target.name) 
      else
         target = APC
         if target and target.name ~= me.name and 
         GetDistance(target, me) < crucibleRange and
         #GetInRange(target, 50, CCS) > 0
         then 
            CastSpellTarget(slot, target)
            pp("uncc apc "..target.name)
         end
      end

      for _,hero in ipairs(ALLIES) do
         if hero.health/hero.maxHealth < .25 then
            CastSpellTarget(slot, hero)
            pp("heal "..hero.name.." "..hero.health/hero.maxHealth)            
         end
      end
   end
end

function UseItems(target)
   for item,_ in pairs(ITEMS) do
      UseItem(item, target)
   end
end

local function getWardingSlot()
   local wardSlot = GetInventorySlot(3154) -- Wriggles
   if wardSlot and CanCastSpell(wardSlot) then
      return wardSlot
   end

   wardSlot = GetInventorySlot(2049) -- Sightstone
   if wardSlot and CanCastSpell(wardSlot) then
      return wardSlot
   end

   wardSlot = GetInventorySlot(2045) -- Ruby Sightstone
   if wardSlot and CanCastSpell(wardSlot) then
      return wardSlot
   end

   wardSlot = GetInventorySlot(2044) -- Sight Ward
   if wardSlot and CanCastSpell(wardSlot) then
      return wardSlot
   end
end

function GetManaCost(spell)
   if spell.cost then
      if type(spell.cost) == "number" then
         return spell.cost
      else
         return spell.cost[GetSpellLevel(spell.key)]
      end
   else
      return 0
   end   
end

function CanUse(thing)
   if type(thing) == "table" then -- spell or item
      if thing.id then -- item
         return CanCastSpell(GetInventorySlot(item.id))
      elseif thing.key then -- spell
--         if thing.key == "A" then
--            return IsAttackReady() == 1
--         end
--         if me.mana > GetManaCost(thing) then             
            return CanUse(thing.key)
--         else
--            return false
--         end
      else  -- spells without keys are always ready
         return true
      end
   elseif type(thing) == "number" then -- item id
      return CanCastSpell(GetInventorySlot(thing))
   else -- string
--      if thing == "AA" then
--         return IsAttackReady() == 1
      if spells[thing] then -- passed in the name of a spell
         if spells[thing].key then
            return CanUse(spells[thing].key)
         else
            return true -- a defined spell without a key prob auto attack
         end
      elseif ITEMS[thing] then  -- passed in the name of an item
         return CanCastSpell(GetInventorySlot(ITEMS[thing].id))
      else -- other string must be a slot
         if thing == "D" or thing == "F" then
            return IsSpellReady(thing) == 1
         end
         return CanCastSpell(thing)
      end
   end
end

local wardCastTime = GetClock() 
function WardJump(key)
   if not CanCastSpell(key) then
      return
   end
   local ward = nil

   -- is there a ward already?
   for _,w in ipairs(WARDS) do
      if GetDistance(w, GetMousePos()) < 150 then
         ward = w
         break
      end
   end

   -- there isn't so cast one and return, we'll jump on the next pass -- on second delay between casting wards to prevent doubles
   if not ward then 
      if GetClock() - wardCastTime > 1000 then
         local wardSlot = getWardingSlot()
         if wardSlot then
            CastSpellXYZ(wardSlot, GetCursorWorldX(), GetCursorWorldY(), GetCursorWorldZ())
            wardCastTime = GetClock()
         end
         return
      end
   else
      CastSpellTarget(key, ward)
   end
end

function RadsToDegs(rads)
   return rads*180/math.pi
end


--[[
returns the orthoganal component of the distance between two objects
--]]
function GetOrthDist(t1, t2)
   local angleT = AngleBetween(t1, t2) - AngleBetween(me, t1)
   if math.min(10, angleT) == 10 then
      return 0
   end   
   local h = GetDistance(t1, t2)
   local d = h*math.sin(angleT)
   return math.abs(d)   
end

function RelativeAngle(center, o1, o2)
   local a1 = AngleBetween(center, o1)
   local a2 = AngleBetween(center, o2)
   local ra = math.abs(a1-a2)
   if ra > math.pi then
      ra = 2*math.pi - ra
   end
   return ra
end

function AngleBetween(object1, object2)
   if not object1 or not object2 then
      pp(debug.traceback())
   end 
   local a = object2.x - object1.x
   local b = object2.z - object1.z  
   
   local angle = math.atan(a/b)
   
   if b < 0 then
      angle = angle+math.pi
   end
   return angle
end

-- angle of approach of attacker to target in radians
-- 0 should be dead on, math.pi should be dead away
function ApproachAngle(attacker, target)
   local x,y,z = GetFireahead(attacker, 2, 20)
   return math.abs( AngleBetween(attacker, target) - AngleBetween(attacker, {x=x, y=y,z=z}) )
end

function LineBetween(object1, object2, thickness)
   if not thickness then
      thickness = 0
   end

   local angle = AngleBetween(object1, object2) 
   DrawLineObject(object1, GetDistance(object1, object2), 0, angle, thickness)
end

function DrawKnockback(object2, dist)
   local a = object2.x - me.x
   local b = object2.z - me.z 
   
   local angle = math.atan(a/b)
   
   if b < 0 then
      angle = angle+math.pi
   end
   
   DrawLineObject(object2, dist, 0, angle, 0)
end


function DrawThickCircle(x,y,z,radius,color,thickness)
   local count = math.floor(thickness/2)
   repeat
      DrawCircle(x,y,z,radius+count,color)
      count = count-2
   until count == (math.floor(thickness/2)-(math.floor(thickness/2)*2))-2
end

function DrawThickCircleObject(object,radius,color,thickness)
   local count = math.floor(thickness/2)
   repeat
      DrawCircleObject(object,radius+count,color)
      count = count-2
   until count == (math.floor(thickness/2)-(math.floor(thickness/2)*2))-2
end

function CalculateDamage(target, damage, dType)
   local res = 0
   if not dType then
      dType = "M"
   end 
   if dType == "M" then
      res = math.max(target.magicArmor*me.magicPenPercent - me.magicPen, 0)
   elseif dType == "P" then
      res = math.max(target.armor*me.armorPenPercent - me.armorPen, 0)
   end
   return damage*(100/(100+res))
end

function GetAADamage(target)
   local damage
   local damageP = GetSpellDamage("AA") -- base aa damage
   local damageM = 0
   local damageT = 0
   
   -- champ specific stuff
   if me.name == "Teemo" then
      damageM = damageM + GetSpellDamage("toxic")
   elseif me.name == "Akali" then      
      damageM = damageM + damageP*(.06+(me.ap/6/100))
   elseif me.name == "Corki" then
      damageT = damageP*.1
   elseif me.name == "MissFortune" then
      damageM = damageM + GetSpellDamage("impure")
   elseif me.name == "Orianna" then
      damageM = damageM + GetSpellDamage("windup")
   elseif me.name == "Varus" then
      damageM = damageM + GetSpellDamage("quiver")
   elseif me.name == "Caitlyn" then
      damageP = damageP + GetSpellDamage("headshot")
   elseif me.name == "TwistedFate" then
      if spells["card"] then
         damageM = GetSpellDamage("card")
         damageP = 0
      end
      damageM = damageM + GetSpellDamage("stack")  
   end
   
   -- items
   if GetInventorySlot(ITEMS["Malady"].id) then
      damageM = damageM + GetSpellDamage(ITEMS["Malady"])
   end
   if GetInventorySlot(ITEMS["Wit's End"].id) then
      damageM = damageM + GetSpellDamage(ITEMS["Wit's End"])
   end
   
   if Check(enrage) then
      if GetInventorySlot(ITEMS["Sheen"].id) then
         damageP = damageP + GetSpellDamage(ITEMS["Sheen"])
      elseif GetInventorySlot(ITEMS["Trinity Force"].id) then
         damageP = damageP + GetSpellDamage(ITEMS["Trinity Force"])
      end
   end
   
   if Check(lichbane) then
      if GetInventorySlot(ITEMS["Lich Bane"].id) then
         damageM = damageM + GetSpellDamage(ITEMS["Lich Bane"])
      end
   end
   
   if target then
      damage = CalcDamage(target, damageP) + CalcMagicDamage(target, damageM)
   else
      damage = damageP + damageM
   end
   damage = damage + damageT
   return math.floor(damage+.5)
end

function GetSpellCost(thing)
   local spell = GetSpell(thing)
   return spell.cost[GetSpellLevel(spell.key)]
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
   end 
   return spell
end

function GetSpellDamage(thing, target)
   local spell = GetSpell(thing)
   if not spell or not spell.base then
      return 0
   end

   local lvl 
   if spell.key and not (spell.key == "D" or spell.key == "F" or spell.key == "A") then
      lvl = GetSpellLevel(spell.key)
      if lvl == 0 then
         return 0
      end
   else 
      lvl = 1
   end


   local damage = spell.base[lvl]

   if spell.ap then 
      damage = damage + spell.ap*me.ap
   end
   if spell.ad then
      damage = damage + spell.ad*(me.baseDamage+me.addDamage)
   end 
   if spell.adBonus then
      damage = damage + spell.adBonus*me.addDamage
   end 
   if spell.adBase then
      damage = damage + spell.adBase*me.baseDamage
   end
   if spell.mana then
      damage = damage + spell.mana*me.maxMana
   end
   if spell.lvl then
      damage = damage + me.selflevel*spell.lvl
   end
   if spell.bonus then
      damage = damage + spell.bonus
   end

   if target then
      if spell.type and spell.type == "T" then
         
      elseif spell.type and spell.type == "P" then
         damage = CalcDamage(target, damage)
      else
         damage = CalcMagicDamage(target, damage)
      end
   end

   return math.floor(damage)
end

--[[
This should look at the allies in [save] in order 
and return an enemy in [stop] that is trying to kill that ally in [save]
--]]
function GetPeel(save, stop)
   for _,ally in ipairs(save) do
      -- check if the target is moving "directly" toward this ally
      -- check if the target is close enough to the ally to be a threat
      for _,enemy in ipairs(stop) do
         if GetDistance(enemy, ally) < 500 and            
            RadsToDegs(ApproachAngle(enemy, ally)) < 45
         then
            return enemy
         end
      end
   end
end

function GetWeakest(thing, list)
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
      local tScore = target.health / CalculateDamage(target, 100, type)
      if weakest == nil or tScore < wScore then
         weakest = target
         wScore = tScore
      end
   end
   
   return weakest
end

DOLATERS = {}
function DoIn(f, millis, key)
--   pp("Call at: "..GetClock()+millis.." now: "..GetClock())
   if key then
      DOLATERS[key] = {GetClock()+millis, f}
   else
      table.insert(DOLATERS, {GetClock()+millis, f})
   end
end

function OnProcessSpell(object, spell)
   for i, callback in ipairs(SPELL_CALLBACKS) do
      callback(object, spell)
   end   
end

-- Common stuff that should happen every time
function TimTick()
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
   
   checkToggles()
   updateObjects()
   drawCommon()
   
   for key,doLater in pairs(DOLATERS) do
      if doLater[1] < GetClock() then
         doLater[2]()
         DOLATERS[key] = nil
      end
   end
end