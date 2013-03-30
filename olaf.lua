require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Olaf")

local berserkToggleTime = GetClock()
function getBerserkTime()
   return math.floor(10.5 - (GetClock() - berserkToggleTime)/1000)
end

AddToggle("berserk", {on=false, key=112, label="BERSERK", auxLabel="{0}", args={getBerserkTime}})
AddToggle("jungle", {on=true, key=113, label="Jungle"})

spells["axe"] = {key="Q", range=1000, color=violet, base={80,125,170,215,260}, adBonus=1, type="P"}
spells["strikes"] = {key="W"}
spells["swing"] = {key="E", range=325, color=yellow, base={100,160,220,280,340}, type="T"}

--[[
Jungling
   Axe stuff. Hit everything I can. Keep it close so I can pick it up.
   Swing at stuff as long as I have enough health.
Ganking
   Axe people.
   Attack people.
   If I can hit people pop W.
   Swing at people.
]]--

function Run()
   TimTick()
   
   if GetWeakEnemy("MAGIC", 1200) or not IsOn("berserk") then
      berserkToggleTime = GetClock()
   elseif GetClock() - berserkToggleTime > 10000 then
      keyToggles["berserk"].on = false
   end   
   
   if HotKey() then
      killPlayer()
   end
   
--   if IsOn("lasthit") and not GetWeakEnemy("MAGIC", 1000) then
--      KillMinionsInLine("axe", 50, 2, 0, false)
--      KillWeakMinion("AA", 50)
--   end
      
   if IsOn("jungle") then
      local creeps = GetInRange(me, 350, CREEPS)
      for _,creep in ipairs(creeps) do
         if ListContains(creep.name, MajorCreepNames, true) or 
            ListContains(creep.name, BigCreepNames, true) 
         then
            if GetDistance(creep) < 275 and creep.dead ~= 1 then
               if CanUse("axe") then 
                  local a = AngleBetween(me, creep)
                  local d = 60
                  local x = me.x+d*math.sin(a)
                  local z = me.z+d*math.cos(a)
                  CastSpellXYZ("Q", x, 0, z)
                  break
               elseif CanUse("swing") then
                  CastSpellTarget("E", creep)
               end
            end
         end
      end
   end
end

function killPlayer()
   local target = GetWeakEnemy("PHYSICAL", spells["axe"].range-100)
   local targetaa = GetWeakEnemy("PHYSICAL", spells["swing"].range+50)
   if target then
      UseItems()
      if CanCastSpell("Q") then        
         CastHotkey('SPELLQ:WEAKENEMY RANGE=950 FIREAHEAD=2,16 OVERSHOOT CD')
         return
      end           
      
      if IsOn("berserk") then
         if targetaa then
            if CanUse("strikes") then
               CastSpellTarget("W", me)
            end
            if CanUse("swing") then
               CastSpellTarget("E", target)
            end
         end
         AttackTarget(target)
      end
   end

end

local function onObject(object)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
