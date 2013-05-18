require "Utils"
require "timCommon"
require "modules"

pp("Tim's Ryze")

local attackObject = "ManaLeach_mis"

spells["overload"] = {key="Q", range=650, color=violet, base={60,85,110,135,160}, ap=.4, mana=.065}
spells["prison"]   = {key="W", range=625, color=red,    base={60,95,130,165,200}, ap=.6, mana=.045}
spells["flux"]     = {key="E", range=675, color=violet, base={50,70,90,110,130},  ap=.35, mana=.01}

AddToggle("lasthit", {on=true, key=112, label="Last Hit"})

local aloneRange = 1750  -- if no enemies in this range consider yourself alone
local nearRange = 1000    -- if no enemies in this range consider them not "near"

local lastAttack = GetClock()

function Run()
   TimTick()
   
	if HotKey() then
      UseItems()
      
   	local target = GetWeakEnemy('MAGIC', spells["prison"].range)
		if target then
         if CanUse("prison") then
            CastSpellTarget("W", target)
         elseif CanUse("overload") then
				CastSpellTarget("Q", target)
		   elseif CanUse("flux") then
				CastSpellTarget("E", target)				
			end
		else
         target = GetWeakEnemy("MAGIC", spells["overload"].range)
         if target then
            if CanUse("overload") then
               CastSpellTarget("Q", target)
            elseif CanUse("flux") then
               CastSpellTarget("E", target)           
            end
         else
            target = GetWeakEnemy("MAGIC", spells["flux"].range)
            if target then
               if CanUse("flux") then
                  CastSpellTarget("E", target)           
               end
            end
         end
      end
	end
	
	if IsOn("lasthit") and not GetWeakEnemy("MAGIC", nearRange) then
      local mp = me.mana/me.maxMana
      if ( CanChargeTear() and mp > .5 ) or
         mp > .75
      then
         KillWeakMinion("Q")
      end
   end

end

local function onObject(object)
   if find(object.charName, attackObject) then
      lastAttack = GetClock()
   end
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")