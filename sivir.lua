require "Utils"
require "timCommon"
require "modules"

print("\nTim's Sivir")

AddToggle("block", {on=true, key=113, label="SpellShield"})

spells["boomerang"] = {key="Q", range=1000, color=yellow, base={60,105,150,195,240}, ap=.5, adb=1.1, type="P"}

function Run()
	TimTick()	
end

-- looks like it needs to be something with a projectile travel time
local blockBlackList = {"SwainDecrepify"}
function checkBlock(object, spell)
	if find(object.name, "Minion") then return end
	if object.team == me.team then return end
	if not find(spell.name, "ttack") and not ListContains(spell.name, blockBlackList) and spell.target and spell.target.name == me.name and CanCastSpell("E") then
		print(spell.name)
		CastSpellTarget("E", me)
	end
end

AddOnSpell(checkBlock)
SetTimerCallback("Run")