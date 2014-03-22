require "timCommon"
require "modules"

print("Tim's Kassadin")

local pulseReady

spells["sphere"] = {
	key="Q", 
	range=650, 
	color=yellow, 
	base={80,110,140,170,200}, 
	ap=.7,
	cost={70,75,80,85,90}
}
spells["pulse"] = {
	key="E", 
	range=650, 
	color=red,
	base={80,120,160,200,240}, 
	ap=.7
}
spells["rift"] = {
	key="R", 
	range=700, 
	color=yellow, 
	base={80,100,120},
	ap=.8
}

function getExecuteLabel()
	local str = ""
	local d
	local dam = 0
	local spell = spells["sphere"]
	if CanUse(spell) then
		d = GetSpellDamage(spell)
		str = str..d.." / "
		dam = dam + d
	else
		str = str.."-- / "
	end
	spell = spells["pulse"]
	if pulseReady and CanUse(spell) then
		d = GetSpellDamage(spell)
		str = str..d.." / "
		dam = dam + d
	else
		str = str.."-- / "
	end
	spell = spells["rift"]
	if CanUse(spell) then
		d = GetSpellDamage(spell)
		str = str..d.." / "
		dam = dam + d
	else
		str = str.."-- / "
	end
	str = str..dam
	return str
end

AddToggle("execute", {on=false, key=112, label="Execute", auxLabel="{0}", args={getExecuteLabel}})

function Run()
	if IsKeyDown(hotKey) ~= 0 then
		if IsOn("execute") then
			local qDam = 0
			local eDam = 0
			local rDam = 0
	
			-- try to kill a close enemy
			local target = GetWeakEnemy("MAGIC", 650)
			if target then
				if CanUse("sphere") then qDam = GetSpellDamage("sphere", target) end
				if CanUse("pulse") and pulseReady then eDam = GetSpellDamage("pulse", target) end
				if CanUse("rift") then rDam = GetSpellDamage("rift", target) end
				
				if qDam + eDam + rDam > target.health then
					if qDam > 0 then
						CastSpellTarget("Q", target)
					elseif eDam > 0 then
						CastSpellTarget("E", target)
					elseif rDam > 0 then
						CastSpellTarget("R", target)
					end
				end
			else
				qDam = 0
				eDam = 0
				rDam = 0
				-- try to get close to a killable enemy
				target = GetWeakEnemy("MAGIC", 1350)
				if target and CanUse("rift") then
					if CanUse("sphere") then qDam = GetSpellDamage("sphere", target) end
					if CanUse("pulse") and pulseReady then eDam = GetSpellDamage("pulse", target) end
					if CanUse("rift") then rDam = GetSpellDamage("rift", target) end
	
					if qDam + eDam + rDam > target.health then
						CastHotkey("SPELLR:WEAKENEMY RANGE=1350 SMARTCAST")
					end
				end
			end
		end
		-- just hit shit that's weak
		local target = GetWeakEnemy('MAGIC',650,"NEARMOUSE")
		if target then
			UseItems(target)
			if CanUse("sphere") then 
				CastSpellTarget("Q",target) 
			elseif CanUse("pulse") then
				CastSpellTarget("E",target)
			elseif GetDistance(target) < me.range+100 then 
				CastSpellTarget("W", me)
				AttackTarget(target) 
			end
		end
	end
end

function onCreateOb(object)
	if find(object.charName, "ForcewalkReady") then
		pulseReady = true
	elseif find(object.charName, "ForcePulse_tar") then
		pulseReady = false
	end
end 

SetTimerCallback("Run")