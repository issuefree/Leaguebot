require "Utils"
require "timCommon"
require "modules"

print("\nTim's Jax")

spells["leap"] = {key="Q", range=700, color=violet, base={70,110,150,190,230}, ap=.6, adBonus=1}
spells["empower"] = {key="W", range=spells["AA"].range, color=yellow, base={40,75,110,145,180}, ap=.6, ad=1}
spells["counter"] = {key="E", range=375, color=red}

AddToggle("autoStun", {on=true,  key=112, label="AutoStun"})
AddToggle("autoW",    {on=true,  key=113, label="Auto W"})
AddToggle("autoUlt",  {on=false, key=114, label="AutoUlt"})

local target
local targetaa
local attackDelay = 0.32
local lastAttack = os.clock()

function Run()
	TimTick()
	Draw()

	if IsKeyDown(string.byte("X")) == 1 then
		WardJump("Q")
	end


   -- try to stick to a target
   if not target or 
      not (GetDistance(target) < spells["leap"].range+150) 
   then
   	target = GetWeakEnemy('PHYS', spells["leap"].range+150)      -- find the weakest I can jump to with a little buffer
   end

   if not targetaa or
      not (GetDistance(targetaa) < spells["counter"].range-50)
   then
	  targetaa = GetWeakEnemy('PHYS', spells["counter"].range-50) -- find the weakest I can reasonably hit/stun
	end

	if HotKey() then
	
		UseItems()
		
		if target then
         -- if there's a good target far away but not near    
			if not targetaa then
				if CanCastSpell("Q") then
					CastSpellTarget("Q",target)
				end

				if IsOn("autoStun") and CanCastSpell("E") then
					CastSpellTarget("E", me)
				end
			else
				if IsOn("autoStun") and
				   CanCastSpell("E")
				then
					CastSpellTarget("E", me)
				end
				
				if CanCastSpell("W") and os.clock() - lastAttack > attackDelay then
					CastSpellTarget("W", targetaa)
				end

				AttackTarget(targetaa)
			end

			if IsOn("autoUlt") and CanCastSpell("R") then
				CastSpellTarget("R", me)
			end
		end
	end
end

function OnProcessSpell(unit,spell)
	if spell.name == "JaxBasicAttack" or 
		spell.name == "JaxBasicAttack2" or 
		spell.name == "JaxCritAttack" or 
		spell.name == "jaxrelentlessattack" 
	then
		lastAttack = os.clock()
	end
end

function Draw()
    if me.dead == 0 then
        CustomCircle(700,6,3,me)
    end
    DrawTarget()
end

function DrawTarget()
	if CanCastSpell("Q") then
		if target then
			CustomCircle(100,6,2,target)
	    end
	elseif targetaa then
		CustomCircle(100,6,2,targetaa)
	end
end

SetTimerCallback("Run")