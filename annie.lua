require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Annie")

spells["dis"] = {key="Q", range=625, color=violet, base={85,125,165,205,245}, ap=.7}
spells["inc"] = {key="W", range=625, color=red,    base={80,130,180,230,280}, ap=.75, cone=45}
spells["tibbers"] = {key="R", range=600, color=red, base={200,325,450}, ap=.7}

local stun = nil
function stunOn()
   if Check(stun) then
      return "ON"
   else
      return "off"
   end
end

-- last hit weakest nearby minion with Disintegrate
AddToggle("lastH", {on=true, key=112, label="Crispy Critters", auxLabel="{0}", args={"dis"}})
-- kill graoups of weak minions with Incinerate
AddToggle("flame", {on=true, key=113, label="Extra Crispy", auxLabel="{0}", args={"inc"}})
-- build up and hold on to stun
AddToggle("stoke", {on=false, key=114, label="Stoke", auxLabel="{0}", args={stunOn}})


function Run()
   TimTick()      
   
   if HotKey() then
      local target = GetWeakEnemy('MAGIC',625+50,"NEARMOUSE")
      if target then
         UseAllItems() 
      
         if Check(stun) then
            if CanUse("tibbers") and GetDistance(target) < 600 then
               CastSpellTarget("R", target)
            elseif CanUse("inc") and GetDistance(target) < 600 then
               CastSpellTarget("W", target)
            elseif CanUse("dis") then
               CastSpellTarget("Q", target)
            end
         else
            if CanUse("dis") then
               CastSpellTarget("Q", target)
            elseif CanUse("inc") then
               CastSpellTarget("W", target)
            end
         end
      end
   end
   
   if IsRecalling(me) then
      return
   end
   
   if IsOn("lastH") and not GetWeakEnemy("MAGIC", 750) then
      if (IsOn("stoke") and Check(stun)) or not CanUse("dis") then
         KillWeakMinion(spells["AA"])
      else
         KillWeakMinion(spells["dis"])
      end
   end   
   
   if IsOn("flame") and not GetWeakEnemy("MAGIC", 750) then
      if IsOn("stoke") and not Check(stun) then
         KillMinionsInCone(spells["inc"], 2, 200, Check(stun))
      else
         KillMinionsInCone(spells["inc"], 3, 200, Check(stun))
      end
   end
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
               MoveToXYZ(farMinion.x, farMinion.y, farMinion.z)
            end
         end
      end
   end
end

local function onObject(object)
--   if GetDistance(object) < 100 then
--      pp(object.charName)
--   end
   if find(object.charName,"StunReady") then
      stun = {object.charName, object}
   end
end

local function onSpell(object, spell)
   if find(object.name, "Minion") then return end
   if object.team == me.team then return end
   if spell.target and spell.target.name == me.name and CanCastSpell("E") then
      CastSpellTarget("E", me)
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)

SetTimerCallback("Run")