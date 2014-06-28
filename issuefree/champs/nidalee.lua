require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Nidalee")

AddToggle("healTeam", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"heal"}})
AddToggle("trap", {on=true, key=113, label="Auto Trap", auxLabel="{0}", args={"trap"}})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["jav"] = {
   key="Q", 
   range=1500, 
   color=violet, 
   base={50,75,100,125,150}, 
   ap=.4,
   cost={50,60,70,80,90},
   width=30,
   delay=1.5,
   speed=12.5
}

spells["trap"] = {
   key="W", 
   range=900,
   base={20,40,60,80,100},
   percHealth={.12,.14,.16,.18,.20},
   percHealthAP=.0002,
   color=yellow,
   cost={40,45,50,55,60},
   delay=5,
   speed=0,
   noblock=true
}

spells["heal"] = {
   key="E", 
   range=600, 
   color=green, 
   base={45,85,125,165,205}, 
   ap=.5,
   type="H",
   cost={60,80,100,120,140}
}

local isCougar = false

function Run()
   if isCougar then
      PrintState(0, "RAWR")
   end
   
   if StartTickActions() then
      return true
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
      if Action() then
         return true
      end
   end

   if HotKey() then
      if FollowUp() then
         return true
      end
   end
   EndTickActions()
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

      local target = GetMarkedTarget() or GetWeakestEnemy("AA")
      if AutoAA(target) then
         return true
      end
      
   else

      local target = GetMarkedTarget() or GetMeleeTarget()
      if AutoAA(target) then
         return true
      end

   end


   return false
end

function FollowUp()
   if isCougar then
      if IsOn("move") then
         if MeleeMove() then
            return true
         end
      end      
   end

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
