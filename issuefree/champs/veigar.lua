require "issuefree/timCommon"
require "issuefree/modules"

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

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "strike"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})

function CheckDisrupt()
   -- need to figure out how to place this exactly on the target
   
   -- if Disrupt("DeathLotus", "event") then return true end

   -- if Disrupt("Grasp", "event") then return true end

   -- if Disrupt("AbsoluteZero", "event") then return true end

   -- if Disrupt("BulletTime", "event") then return true end

   -- if Disrupt("Duress", "event") then return true end

   -- if Disrupt("Idol", "event") then return true end

   -- if Disrupt("Monsoon", "event") then return true end

   -- if Disrupt("Meditate", "event") then return true end

   -- if Disrupt("Drain", "event") then return true end

   return false
end

function Run()

   local ccs = GetWithBuff("cc", ENEMIES)
   for _,v in ipairs(ccs) do
      Circle(v)
   end

   if StartTickActions() then
      return true
   end

   if CheckDisrupt() then
      return true
   end

   -- looking for the stun obj and throwing darks at it
   if CastAtCC("dark") then
      return true
   end

   if HotKey() then
      if Action() then
         return true
      end
   end

   if IsOn("lasthit") and Alone() then
      if KillMinion("strike") then
         return true
      end
   end

   if HotKey() then
      if FollowUp() then
         return true
      end
   end
end

function Action()
   UseItems()
   
   local target = GetWeakEnemy('MAGIC', GetSpellRange("event")+250)
   if target then
      if CanUse("event") then
         if FacingMe(target) then
            local point = Projection(me, target, GetDistance(target)-250)
            CastXYZ("event", point)
            PrintAction("Event Horizon <-", target)
            return true
         else
            local point = Projection(me, target, math.min(GetSpellRange("event"), GetDistance(target)+250))
            CastXYZ("event", point)
            PrintAction("Event Horizon ->", target)
            return true
         end            
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
         local tDam = CalculateDamage(enemy, burstBase + enemy.ap)
         -- one hit kill in range. kill it.
         if tDam > enemy.health and GetDistance(enemy) < spell.range then
            Cast("burst", enemy)
            PrintAction("Burst for execute", enemy)
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
            PrintAction("Burst for damage", enemy)
            return true
         end
      end
   end

   if CanUse("strike") then
      local target = GetMarkedTarget() or GetWeakestEnemy("strike")
      if target then
         Cast("strike", target)
         PrintAction("Strike", target)
         return true
      end
   end

   return false
end

function FollowUp()
   if IsOn("lasthit") and not CanUse("strike") and Alone() then
      if KillMinion("AA") then
         return true
      end
   end

   if IsOn("clear") then
      if HitMinionsInArea("dark", 3) then
         return true
      end
   end

   return false
end

local function onObject(object)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)

SetTimerCallback("Run")