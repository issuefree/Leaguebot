require "timCommon"

local smite = {range=750, base=0}
local smiteDam = {390,410,430,450,480,510,540,570,600,640,680,720,760,800,850,900,950,1000}
local smiteTargets = {}

if me.SummonerD == "SummonerSmite" then
   smite.key = "D"
   spells["smite"] = smite
elseif me.SummonerF == "SummonerSmite" then
   smite.key = "F"
   spells["smite"] = smite
end

function smiteTick()
   spells["smite"].base = smiteDam[me.selflevel]
   if not ModuleConfig.smite then
      return
   end
   for i,target in rpairs(smiteTargets) do
      if not target or
         target.dead == 1 or
         not target.x 
      then
         table.remove(smiteTargets,i)
      end
   end

   for _,target in ipairs(smiteTargets) do
      if GetDistance(target) < smite.range+50 and target.health < GetSpellDamage(smite) then
         CastSpellTarget(smite.key, target)
         break 
      end
   end
end

function onCreateSmite(obj)
   if not obj.name then return end
   if find(obj.name, "MechCannon") then
      table.insert(smiteTargets, obj)
   elseif ListContains(obj.name, BigCreepNames) then
      table.insert(smiteTargets, obj)
   elseif ListContains(obj.name, MajorCreepNames) then
      table.insert(smiteTargets, obj)
   end
end 

if spells["smite"] then
   SetTimerCallback("smiteTick")
   AddOnCreate(onCreateSmite)
end
