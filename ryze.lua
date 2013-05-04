require "Utils"
require "timCommon"
require "modules"

pp("Tim's Ryze")

spells["overload"] = {key="Q", range=650, color=violet, base={60,85,110,135,160}, ap=.4, mana=.065}
spells["prison"]   = {key="W", range=625, color=red,    base={60,95,130,165,200}, ap=.6, mana=.045}
spells["flux"]     = {key="E", range=675, color=violet, base={50,70,90,110,130},  ap=.35, mana=.01}

AddToggle("lasthit", {on=true, key=112, label="Last Hit"})

local aloneRange = 1750  -- if no enemies in this range consider yourself alone
local nearRange = 900    -- if no enemies in this range consider them not "near"

local lastAttack = GetClock()

function Run()
   TimTick()
   
	if HotKey() then
      UseItems()
      
   	local target = GetWeakEnemy('MAGIC',625)
		if target then
         if CanUse("overload") then
            CastSpellTarget("Q", target)
         elseif CanUse("prison") then
				CastSpellTarget("W", target)
		   elseif CanUse("flux") then
				CastSpellTarget("E", target)				
			end
		else
         target = GetWeakEnemy("MAGIC", 650)
         if target then
            if CanUse("overload") then
               CastSpellTarget("Q", target)
            elseif CanUse("flux") then
               CastSpellTarget("E", target)           
            else
               AttackTarget(target)
            end
         else
            target = GetWeakEnemy("MAGIC", 675)
            if target then
               if CanUse("flux") then
                  CastSpellTarget("E", target)           
               else
                  AttackTarget(target)
               end
            end
         end            
      end
	end
	
	if IsOn("lasthit") and not GetWeakEnemy("MAGIC", nearRange) then
	  if GetClock() - lastAttack < 250 then
	     KillWeakMinion("Q")
	  else
	     KillWeakMinion("AA")
	  end
	end
end

local function onObject(object)
end

local function onSpell(object, spell)
   if object.name == me.name then
      if find(spell.name, "attack") then
         lastAttack = GetClock()
      end
      pp(spell.name)
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")