require "Utils"

local modules = {}
ModuleConfig = scriptConfig("Module Config", "modules")

function loadModule(module)
	local chunk,msg = loadfile(module)      -- loads/compiles the lua chunk
	if (chunk ~= nil) then
		chunk()
	end
end

loadModule("WardRevealer.lua")
--loadModule("clones.lua")
--loadModule("showskillshots.lua")
loadModule("cleanse.lua")