require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Annie")

spells["dis"] = {
   key="Q", 
   range=625, 
   color=violet, 
   base={85,125,165,205,245}, 
   cost={60,65,70,75,80},
   ap=.7
}
spells["inc"] = {
   key="W", 
   range=600, 
   color=red,    
   base={80,130,180,230,280},
   cost={70,80,90,100,110}, 
   ap=.75, 
   cone=45
}
spells["shield"] = {
   key="E"
}
spells["tibbers"] = {
   key="R", 
   range=600, 
   color=red, 
   base={200,325,450},
   cost={125,175,225}, 
   ap=.7,
   area=250
}

local aloneRange = 2000  -- if no enemies in this range consider yourself alone
local nearRange = 900    -- if no enemies in this range consider them not "near"

local stun = nil
function stunOn()
   if Check(stun) then
      return "ON"
   else
      return "off"
   end
end

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
-- build up and hold on to stun
AddToggle("stoke", {on=true, key=113, label="Stoke", auxLabel="{0}", args={stunOn}})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1} / {2}", args={GetAADamage, "dis", "inc"}})

function Run()
   TimTick()
   

   if IsRecalling(me) or me.dead == 1 then
      return
   end

   if HotKey() and CanAct() then
      if Action() then
         return
      end
   end
   
   -- if i don't have stun and I have mana and I'm alone, stack stun with shield
   if IsOn("stoke") and Alone() and
      not Check(stun) and 
      CanUse("shield") and
      me.mana / me.maxMana > .25 
   then
      Cast("shield", me)
      return
   end
   
   -- if we're alone blast everything.
   -- if there's a near, try to save stun

   if IsOn("lasthit") then
      if VeryAlone() then
         if KillWeakMinion("dis") then
            return
         end
      elseif Alone() then
         if IsOn("stoke") and not Check(stun) then
            if KillWeakMinion("dis") then
               return
            end
         end         
      end
   end   

   -- if we're alone blast 2 or more
   -- if we're not alone but not near blast 2 if we're stoking else 3
   if IsOn("lasthit") then
      if VeryAlone() then
         if KillMinionsInCone(spells["inc"], 2, 0, false) then
            return
         end
      elseif Alone() then
         if IsOn("stoke") and not Check(stun) then
            if KillMinionsInCone(spells["inc"], 2, 0, Check(stun)) then
               return
            end
         else
            if KillMinionsInCone(spells["inc"], 3, 0, false) then
               return
            end
         end
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

-- actually I think it's simple. just hit whoever I can with disintigrate
-- and incinerate and rely on movement to get me in range for shit.

-- if I can hit 2 people with tibbers or kill with tibbers do that.

-- so scan everyone in range of tibbers. Check each target for most hits.
-- if hits >= 2 hit the best one

-- then hit best target with dis or int

-- check for finish offs with tibbers. (handle the one target left kill case)

   if CanUse("tibbers") then
      local targets = SortByHealth(GetInRange(me, "tibbers", ENEMIES))
      local bestS = 1
      local bestT = nil
      for _,enemy in ipairs(targets) do
         local hits = GetInRange(enemy, spells["tibbers"].area, ENEMIES)
         if #hits > bestS then
            bestS = #hits
            bestT = enemy
         end
      end
      if bestT then
         Cast("tibbers", bestT)
         return true
      end
   end

   if CanUse("inc") then
      local target = GetWeakEnemy("MAGIC", spells["inc"].range)
      if target then
         Cast("inc", target)
         return true
      end
   end

   if CanUse("dis") then
      local target = GetWeakEnemy("MAGIC", spells["dis"].range)
      if target then
         Cast("dis", target)
         return true
      end
   end

   if CanUse("tibbers") then
      local target = GetWeakEnemy("MAGIC", spells["tibbers"].range)
      if target and target.health < GetSpellDamage("tibbers", target) then
         Cast("tibbers", target)
         return true
      end
   end

   local target = GetWeakEnemy("PHYSICAL", spells["AA"].range)
   if target and AA(target) then
      return true
   end

   return false
end   

function FollowUp()
   if IsOn("lasthit") and Alone() then
      if KillWeakMinion("AA") then
         return true
      end
   end

   if IsOn("move") then
      MoveToCursor() 
      return true
   end
   return false
end



local function onObject(object)
   if find(object.charName,"StunReady") and 
      GetDistance(object) < 50 
   then
      stun = StateObj(object)
   end
end

local function onSpell(object, spell)
   if find(object.name, "Minion") then return end
   if object.team == me.team then return end
   if spell.target and spell.target.name == me.name and CanUse("shield") then
      Cast("shield", me)
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)

SetTimerCallback("Run")