require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Veigar")

spells["strike"] = {key="Q", range=650, color=violet, base={80,125,170,215,260}, ap=.6}
spells["dark"]   = {key="W", range=900, color=red,    base={120,170,220,270,320}, ap=1, area=115}
spells["event"]  = {key="E", range=600, color=yellow, area=400}
spells["burst"]  = {key="R", range=650, color=red,    base={250,375,500}, ap=1.2}

local nearRange = 800    -- if no enemies in this range consider them not "near"

-- last hit weakest nearby minion with Balefule Strike
AddToggle("lastH", {on=true, key=112, label="Farm", auxLabel="{0}", args={"strike"}})
---- kill graoups of weak minions with Incinerate
--AddToggle("flame", {on=true, key=113, label="Extra Crispy", auxLabel="{0}", args={"inc"}})


function Run()
   TimTick()      
   
   if IsRecalling(me) then
      return 
   end

   if HotKey() then
      local target = GetWeakEnemy('MAGIC',700,"NEARMOUSE")
      if target then
         UseItems()

         if CanUse("event") then
            local delta = {x = target.x-me.x, z = target.z-me.z}
            local dist = math.sqrt(math.pow(delta.x,2)+math.pow(delta.z,2))
            dist = dist + 75
            local eSpell = {x = target.x-(spells["event"].area/dist)*delta.x, z = target.z-(spells["event"].area/dist)*delta.z}
            CastSpellXYZ("E", eSpell.x, 0, eSpell.z)
            
         elseif CanUse("dark") then
            CastSpellTarget("W", target)
            
         elseif CanUse("burst") then
            CastSpellTarget("R", target)
            
         elseif CanUse("strike") then
            CastSpellTarget("Q", target)
         end
      end
   end   
   
   if IsOn("lastH") then
      if not GetWeakEnemy("MAGIC", nearRange) then
         if CanUse("strike") then
            KillWeakMinion(spells["strike"], 100)
         else
            KillWeakMinion(spells["AA"], 100)
         end
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