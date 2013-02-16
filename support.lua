require "timCommon"

local mortalStrikes = {}

function SupportTick()
	Clean(mortalStrikes, "charName", "Mortal_Strike")
end

function isWounded(hero)
	for _,obj in ipairs(mortalStrikes) do
		if obj and GetDistance(hero, obj) < 50 then
			return true
		end
	end
	return false
end

function onCreateObjectSupport(object)
	if find(object.charName, "Mortal_Strike") then
		table.insert(mortalStrikes, object)
	end
end

AddOnCreate(onCreateObjectSupport)