require "Utils"
require "timCommon"
require "modules"

print("\nTim's Jax")

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

	keyDown = IsKeyDown(hotKey) == 1

	target = GetWeakEnemy('PHYS',700)
	targetaa = GetWeakEnemy('PHYS',275)

	if keyDown then
		UseAllItems()
		if target then
			if not targetaa then
				if CanCastSpell("Q") then
					CastSpellTarget("Q",target)
				end

				if IsOn("autoStun") and CanCastSpell("E") then
					CastSpellTarget("E", me)
				end
			else
				if IsOn("autoStun") and
				   GetDistance(targetaa) < 180 and
				   CanCastSpell("E")
				then
					CastSpellTarget("E", me)
				end
				
				if CanCastSpell("W") and os.clock() - lastAttack > attackDelay and os.clock() - lastAttack < 2 then
					CastSpellTarget("W", targetaa)
				end
			end

			if IsOn("autoUlt") and CanCastSpell("R") then
				CastSpellTarget("R", me)
			end
			if targetaa then
				AttackTarget(targetaa)
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