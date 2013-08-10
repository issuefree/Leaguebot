require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Veigar")
pp(" - Farm up Baleful Strike")
pp(" - Event Horizon to stun enemies")
pp(" - Dark Matter stunned enemies")
pp(" - Hit good Primordial Burst targets while trying not to waste")
pp(" - Clear minion waves with Dark Matter")

spells["strike"] = {
   key="Q", 
   range=650, 
   color=violet, 
   base={80,125,170,215,260}, 
   ap=.6,
   cost={60,65,70,75,80}
}
spells["dark"] = {
   key="W", 
   range=900, 
   color=red,    
   base={120,170,220,270,320}, 
   ap=1, 
   cost={70,80,90,100,110},
   radius=250
}
spells["event"] = {
   key="E", 
   range=600, 
   color=yellow, 
   cost={80,90,100,110,120},
   radius=400
}
spells["burst"] = {
   key="R", 
   range=650, 
   color=red,    
   base={250,375,500}, 
   ap=1.2,
   cost={125,175,225}
}

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "strike"}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

local stuns = {}
local stunnedEnemies = {}

function Run()
   TimTick()      
   
   updateStuns()

   if IsRecalling(me) or me.dead == 1 then
      return
   end

   if HotKey() and CanAct() then
      if Action() then
         return
      end
   end

   if IsOn("lasthit") and Alone() then
      if KillWeakMinion(spells["strike"]) then
         return
      end
   end

   if HotKey() and CanAct() then
      if FollowUp() then
         return
      end
   end
end

function Action()
   UseItems()
   
   local target = GetWeakEnemy('MAGIC',spells["event"].range+100)
   if target then
      if CanUse("event") then
         local delta = {x = target.x-me.x, z = target.z-me.z}
         local dist = math.sqrt(math.pow(delta.x,2)+math.pow(delta.z,2))
         dist = dist + 75
         local eSpell = {x = target.x-(spells["event"].radius/dist)*delta.x, y=target.y, z = target.z-(spells["event"].radius/dist)*delta.z}
         CastXYZ("event", eSpell)
         return
      end
   end
      
   -- I want all not moving targets.
   -- I think I want to do this by looking for the stun obj and throwing darks at it
   -- This might even catch other people's stuns.   

   if CanUse("dark") then
      local stunnedEnemies = GetInRange(me, spells["dark"].range+50, stunnedEnemies)
      local bestS = 0
      local bestT = nil
      for _,nearStun in ipairs(stunnedEnemies) do
         local hits = GetInRange(nearStun, spells["dark"].radius, ENEMIES)
         if #hits > bestS then
            bestS = #hits
            bestT = nearStun
         end
      end
      if bestT then
         CastXYZ("dark", bestT)
         return
      end
   end

   if CanUse("burst") then
      -- if there aren't any of those lets find a good target
      -- I want to do the largest % remaining health but
      -- I don't want to waste my ult on a tank just because he's the only
      -- one in range.
      -- So I'm thinking 2 things:
      --  Look for targets at +50% range and don't fire unless it's the best one of those
      --  Don't fire unless it will do 25% of their remaining health

      local spell = spells["burst"]
      local bestS = 0
      local bestT = nil
      local burstBase = GetSpellDamage("burst")

      -- look for 1 hit kills
      for _,enemy in ipairs(GetInRange(me, spell.range*1.5 ,ENEMIES)) do
         local tDam = CalcMagicDamage(enemy, burstBase + enemy.ap)
         -- one hit kill in range. kill it.
         if tDam > enemy.health and GetDistance(enemy < spell.range) then
            Cast("burst", enemy)
            return true
         end

         local score = tDam/enemy.health
         if score > .25 then
            if not bestT or score > bestS then
               bestS = score
               bestT = enemy
            end
         end
         if bestT and GetDistance(bestT) < spell.range then
            Cast("burst", bestT)
            return true
         end
      end
   end

   if CanUse("strike") then
      local target = GetWeakestEnemy("strike")
      if target then
         Cast("strike", target)
         return true
      end
   end

   local target = GetWeakestEnemy("AA")
   if AA(target) then
      return true
   end
   
   return false
end

function FollowUp()
   if IsOn("lasthit") and not CanUse("strike") and Alone() then
      if KillWeakMinion("AA") then
         return
      end
   end

   if IsOn("clearminions") then
      if KillMinionsInArea("dark", 2, false, 0, false) then
         return true
      end

      -- hit the highest health minion
      local minions = SortByHealth(GetInRange(me, "AA", MINIONS))
      local minion = minions[#minions]
      if minion and AA(minion) then
         return
      end         
   end

   if IsOn("move") then
      MoveToCursor() 
      return true
   end
   return false
end

function updateStuns()
   stunnedEnemies = {}

   Clean(stuns, "charName", "LOC_Stun")
   for _,stun in ipairs(stuns) do
      for _,enemy in ipairs(ENEMIES) do
         if GetDistance(stun, enemy) < 100 then
            DrawThickCircleObject(enemy, GetWidth(enemy), red, 5)
            table.insert(stunnedEnemies, enemy)
            break
         end
      end      
   end
end


local function onObject(object)
   if find(object.charName, "LOC_Stun") then
      for _,enemy in ipairs(ENEMIES) do
         if GetDistance(object, enemy) < 100 then
            table.insert(stuns, object)
            break
         end
      end
   end
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)

SetTimerCallback("Run")