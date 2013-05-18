require "Utils"
require "timCommon"
require "modules"
require "support"

pp("\nTim's Nidalee")

AddToggle("healTeam", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"heal"}})
AddToggle("trap", {on=true, key=113, label="Auto Trap", auxLabel="{0}", args={"trap"}})

spells["jav"] = {
   key="Q", 
   range=1500, 
   color=violet, 
   base={55,95,140,185,230}, 
   ap=.65,
   type="M",
   width=80,
   delay=2,
   speed=13
}

spells["trap"] = {
   key="W", 
   range=900,
   base={80,125,170,215,260},
   ap=.4,
   color=yellow
}

spells["heal"] = {
   key="E", 
   range=600, 
   color=green, 
   base={50,85,120,155,190}, 
   ap=.7
}

local isCougar = false

function Run()
   TimTick()
   
   if isCougar then
      PrintState(0, "RAWR")
   end
   
   if IsRecalling(me) then
      return
   end
   
   if IsOn("healTeam") and not isCougar then
      healTeam("heal")      
   end

   if HotKey() then
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
