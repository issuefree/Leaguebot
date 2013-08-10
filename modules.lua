require "Utils"

local modules = {}
ModuleConfig = scriptConfig("Module Config", "modules")

function loadModule(module)
	local chunk,msg = loadfile(module)      -- loads/compiles the lua chunk
	if (chunk ~= nil) then
		chunk()
	end
end

--loadModule("clones.lua")
--loadModule("showskillshots.lua")

loadModule("spellRanges.lua")
loadModule("smite.lua")
loadModule("WardRevealer.lua")
loadModule("cleanse.lua")
loadModule("ignite.lua")
loadModule("antiSkillShot.lua")
loadModule("objectFind.lua")
loadModule("testTargets.lua")