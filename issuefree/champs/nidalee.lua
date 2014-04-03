require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Nidalee")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("healTeam", {on=true, key=113, label="Heal Team", auxLabel="{0}", args={"heal"}})
AddToggle("trap", {on=true, key=114, label="Auto Trap", auxLabel="{0}", args={"trap"}})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["jav"] = {
   key="Q", 
   range=1500, 
   color=violet, 
   base={55,95,140,185,230}, 
   ap=.65,
   cost={50,60,70,80,90},
   width=80,
   delay=1.5,
   speed=12.5
}

spells["trap"] = {
   key="W", 
   range=900,
   base={80,125,170,215,260},
   ap=.4,   
   color=yellow,
   cost={60,75,90,105,120},
   delay=5,
   speed=0,
   noblock=true
}

spells["heal"] = {
   key="E", 
   range=600, 
   color=green, 
   base={50,85,120,155,190}, 
   ap=.7,
   type="H",
   cost={60,80,100,120,140}
}

local isCougar = false

function Run()
   if isCougar then
      PrintState(0, "RAWR")
   end
   
   if IsRecalling(me) or me.dead == 1 then
      return
   end
   
   if CastAtCC("spear") then
      return true
   end
   if CastAtCC("trap") then
      return true
   end

   if IsOn("healTeam") and not isCougar then
      if HealTeam("heal") then
         return true
      end
   end

   if HotKey() then
      UseItems()
      if Action() then
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
   -- TestSkillShot("jav")

   if not isCougar then
      if SkillShot("jav") then
         return true
      end      
      
      if IsOn("trap") and CanUse("trap") then
         -- plant traps
         local target = GetWeakestEnemy("trap")
         if target then
            if CastFireahead("trap", target) then
               PrintAction("It's a trap")
               return true
            end
         end
      end

      local target = GetWeakestEnemy("AA")
      if AA(target) then
         PrintAction("AA", target)
         return true
      end
      
   end

   return false
end

function FollowUp()
   if not isCougar then
      if IsOn("lasthit") and Alone() then
         if KillMinion("AA") then
            return true
         end
      end

      if IsOn("clearminions") and Alone() then
         -- hit the highest health minion
         local minions = SortByHealth(GetInRange(me, "AA", MINIONS))
         local minion = minions[#minions]
         if minion and AA(minion) then
            PrintAction("AA clear minions")
            return true
         end
      end

   -- ranged
      -- if IsOn("move") then
      --    MoveToCursor() 
      --    return true
      -- end
   end

-- melee
   -- if IsOn("move") then
   --    if aaTarget then
   --       MoveToTarget(aaTarget)
   --       return true
   --    else
   --       MoveToCursor() 
   --       return true
   --    end
   -- end

   return false
end

local function onObject(object)
end

local function onSpell(object, spell)
   if object.name == me.name then
      if find(spell.name, "Pounce") or
         find(spell.name, "Takedown") or
         find(spell.name, "Swipe")
      then
         isCougar = true
      end
      if find(spell.name, "AspectOfTheCougar") then
         isCougar = not isCougar
      end
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
