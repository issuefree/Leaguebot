require "timCommon"

local mortalStrikes = {}

--AddToggle("hug", {on=false, key=113, label="Hug Tower"})
--   if IsOn("hug") then
--      SortByDistance(ALLIES, me)
--      local hugTarget = ALLIES[2]
--      hugTower(hugTarget, 500)
--   end
--function hugTower(target, range)
--   SortByDistance(MYTURRETS, target)   
--   local tower = MYTURRETS[1]
--   LineBetween(target, tower)
--   local angle = AngleBetween(target, tower)
--   local dist = math.min(GetDistance(target, tower), range)
--   local x = target.x + math.sin(angle)*dist
--   local z = target.z + math.cos(angle)*dist
--   DrawCircle(x, 0, z, 35, yellow)
--   if GetDistance({x=x,z=z}) > 200 then
--      MoveToXYZ(x, 0, z)
--   end
--end


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

local function onCreateObjectSupport(object)
	if find(object.charName, "Mortal_Strike") then
		table.insert(mortalStrikes, object)
	end
end

AddOnCreate(onCreateObjectSupport)