require "Utils"
require "timCommon"
require "modules"
require "support"

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
   type="M",
   cost={50,60,70,80,90},
   width=80,
   delay=2,
   speed=13
}

spells["trap"] = {
   key="W", 
   range=900,
   base={80,125,170,215,260},
   ap=.4,   
   color=yellow,
   cost={60,75,90,105,120}
}

spells["heal"] = {
   key="E", 
   range=600, 
   color=green, 
   base={50,85,120,155,190}, 
   ap=.7,
   cost={60,80,100,120,140}
}

local isCougar = false

function Run()
   TimTick()
   
   if isCougar then
      PrintState(0, "RAWR")
   end
   
   if IsRecalling(me) or me.dead == 1 then
      return
   end
   
   if HotKey() and CanAct() then
      if Action() then
         return
      end
   end

   if IsOn("healTeam") and not isCougar then
      healTeam("heal")      
   end

   if HotKey() and CanAct() then
      if FollowUp() then
         return
      end
   end
   
end

function Action()
   UseItems()
   
   if not isCougar then
      SkillShot("jav")
      
      if IsOn("trap") and CanUse("trap") then
         -- plant traps
         local target = GetWeakEnemy("MAGIC", spells["trap"].range)
         if target then
            local x,y,z = GetFireahead(target,5,99)
            if GetDistance({x=x, y=y, z=z}) < spells["trap"].range then
               CastSpellXYZ(spells["trap"].key, x,y,z)
            end
         end
      end
   end
end

function FollowUp()
   if not isCougar then
      if IsOn("lasthit") and Alone() then
         if KillWeakMinion("AA") then
            return true
         end
      end

      if IsOn("clearminions") and Alone() then
         -- hit the highest health minion
         local minions = SortByHealth(GetInRange(me, "AA", MINIONS))
         local minion = minions[#minions]
         if minion and AA(minion) then
            return true
         end
      end

   -- ranged
      if IsOn("move") then
         MoveToCursor() 
         return true
      end
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
