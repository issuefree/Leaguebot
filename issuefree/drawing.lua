require "issuefree/telemetry"

-- circle colors
yellow = 0
green  = 1
red    = 2
blue   = 3
violet = 4

-- text colors
yellowT = 0xFFFFFF00
greenT  = 0xFF00FF00
redT    = 0xFFFF0000
blueT   = 0xFF00FFFF

function LineBetween(object1, object2, thickness)
   if not thickness then
      thickness = 0
   end

   local angle = AngleBetween(object1, object2) 
   local dist = GetDistance(object1, object2)*1.06
   if type(object1) == "table" then
      DrawLine(object1.x,object1.y,object1.z, dist, 0, angle, thickness)
   else
      DrawLineObject(object1, dist, 0, angle, thickness)
   end
end

function DrawBB(t, color)
   if not color then color = yellow end
   DrawCircle(t.x, t.y, t.z, GetWidth(t), color)
end

function Circle(target, radius, color, thickness)
	if not target then return end
	if target.x == 0 then return end

	thickness = thickness or 1
	color = color or yellow
	radius = radius or GetWidth(target)

	if type(target) == "userdata" then
		for i = 1, thickness, 1 do
			DrawCircleObject(target, radius+i-1, color)
		end		
	else
		local p = Point(target)
		if not p.x or not p.y or not p.z then
			return 
		end
		for i = 1, thickness, 1 do
			DrawCircle(p.x, p.y, p.z, radius+i-1, color)
		end
	end
end