require "telemetry"

-- circle colors
yellow = 0
green  = 1
red    = 2
blue   = 3
violet = 4

function LineBetween(object1, object2, thickness)
   if not thickness then
      thickness = 0
   end

   local angle = AngleBetween(object1, object2) 
   if type(object1) == "table" then
      DrawLine(object1.x,object1.y,object1.z, GetDistance(object1, object2), 0, angle, thickness)
   else
      DrawLineObject(object1, GetDistance(object1, object2), 0, angle, thickness)
   end
end

function DrawKnockback(object2, dist)
   local a = object2.x - me.x
   local b = object2.z - me.z 
   
   local angle = math.atan(a/b)
   
   if b < 0 then
      angle = angle+math.pi
   end
   
   DrawLineObject(object2, dist, 0, angle, 0)
end

function DrawBB(t, color)
   if not color then color = yellow end
   DrawCircle(t.x, t.y, t.z, GetWidth(t), color)
end

function Circle(target, radius, color, thickness)
	if not target then return end
	if not thickness then thickness = 1 end
	if not color then color = yellow end
	if not radius then radius = GetWidth(target) end
	if type(target) == "userdata" then
		for i = 1, thickness, 1 do
			DrawCircleObject(target, radius+i-1, color)
		end		
	else
		for i = 1, thickness, 1 do
			DrawCircle(target.x, target.y, target.z, radius+i-1, color)
		end
	end
end