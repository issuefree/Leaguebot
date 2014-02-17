require "basicUtils"

Point = class()
function Point:__init(a, b, c)
   if not a then
      return nil
   end
   if not b and not c then
      self.x = a.x+1-1
      self.y = a.y+1-1
      self.z = a.z+1-1
   else
      self.x = a+1-1
      self.y = b+1-1
      self.z = c+1-1
   end
end
function Point:__add(p)
   return Point(self.x+p.x, self.y+p.y, self.z+p.z)
end
function Point:__sub(p)
   return Point(self.x-p.x, self.y-p.y, self.z-p.z)
end
function Point:__eq(p)
   return self.x == p.x and self.y == p.y and self.z == p.z
end

function Point:near(p)
   return GetDistance(p, self) < 10
end

function Point:unpack()
   return self.x, self.y, self.z
end


function GetDistance(p1, p2)
    p2 = p2 or myHero
    if not p1 or not p1.x or not p2.x then
        print(debug.traceback())
        return 99999 
    end
    
    return math.sqrt(GetDistanceSqr(p1, p2))    
end

function GetDistanceSqr(p1, p2)
    p2 = p2 or myHero
    return (p1.x - p2.x)^2 + ((p1.z or p1.y) - (p2.z or p2.y))^2
end

function AngleBetween(object1, object2)
   if not object1 or not object2 then
      pp(debug.traceback())
   end 
   local a = object2.x - object1.x
   local b = object2.z - object1.z  
   
   local angle = math.atan(a/b)
   
   if b < 0 then
      angle = angle+math.pi
   end
   return angle
end

-- gives the targets relative vector
-- 0 means dead on or dead away
-- 90 means perpendicular
function ApproachAngleRel(attacker, target)
   local aa = ApproachAngle(attacker, target)
   if aa > 90 then
      aa = math.abs(aa - 180)
   end
   return aa
end

-- angle of approach of attacker to target
-- 0 should be dead on, 180 should be dead away
function ApproachAngle(attacker, target)
   local point = Point(GetFireahead(attacker, 3, 0))
   local aa = RadsToDegs(math.abs( AngleBetween(attacker, target) - AngleBetween(attacker, point) ))
   if aa > 180 then
      aa = 360 - aa
   end
   if aa == nil then
      aa = 0
   end
   return aa
end

function Projection(source, target, dist) -- returns a point on the line between two objects at a certain distance
   local a = AngleBetween(source, target)
   local y = source.y or target.y
   return Point(source.x+math.sin(a)*dist, y, source.z+math.cos(a)*dist)
end

function ProjectionA(source, angle, dist)
   local y = source.y
   return Point(source.x+math.sin(angle)*dist, y, source.z+math.cos(angle)*dist)
end

function OverShoot(source, target, dist)
   return Projection(source, target, GetDistance(source, target)+dist)
end

function RelativeAngle(center, o1, o2)
   local a1 = AngleBetween(center, o1)
   local a2 = AngleBetween(center, o2)
   local ra = math.abs(a1-a2)
   if ra > math.pi then
      ra = 2*math.pi - ra
   end
   return ra
end

--returns the orthoganal component of the distance between two objects
function GetOrthDist(t1, t2)
   local angleT = AngleBetween(t1, t2) - AngleBetween(me, t1)
   if math.min(10, angleT) == 10 then
      return 0
   end   
   local h = GetDistance(t1, t2)
   local d = h*math.sin(angleT)
   return math.abs(d)   
end

function RadsToDegs(rads)
   return rads*180/math.pi
end

--[[
Returns the x,y,z of the center of the targes
--]]
function GetCenter(targets)
   local x = 0
   local y = 0
   local z = 0
         
   for _,t in ipairs(targets) do
      x = x + t.x
      y = y + t.y
      z = z + t.z
   end
   
   x = x / #targets
   y = y / #targets
   z = z / #targets
   
   return Point(x,y,z)
end

function GetOffset(p1, p2)
   return Point(p1.x-p2.x, p1.y-p2.y, p1.z-p2.z)
end

--[[
returns the width of a unit
--]]
function GetWidth(unit)
   local minbb = GetMinBBox(unit)
   if not minbb.x then -- for when I pass in not a real unit
      if unit.width then
         return unit.width
      end
      return 70
   end
   return GetDistance(unit, minbb)
end

function FacingMe(target)
   local d1 = GetDistance(target)
   local p = Point(GetFireahead(target,3,0))
   local d2 = GetDistance(p)
   return d2 < d1 
end

local trackTicks = 3
local myPos = {}
function TrackMyPosition()
   if #myPos == 0 or GetDistance(myPos[#myPos], Point(me)) > 1 then
      table.insert(myPos, Point(me))
      if #myPos > trackTicks then
         table.remove(myPos, 1)
      end
   end
end

function GetMyLastPosition()
   return myPos[1]
end

function GetMyDirection()
   return AngleBetween(GetMyLastPosition(), me)
end

function GetMousePos()
   return Point(GetCursorWorldX(), GetCursorWorldY(), GetCursorWorldZ())
end

function Engaged()
   return GetWeakEnemy("MAGIC", 400 ) ~= nil
end
function Alone()
   return GetWeakEnemy("MAGIC", 750+(me.selflevel*25)) == nil
end
function VeryAlone()
   return GetWeakEnemy("MAGIC", (750+(me.selflevel*25))*1.5) == nil
end

function UnderTower(target)
   if not target then target = me end
   return #GetAllInRange(target, 950, TURRETS) > 0
end

function SortByHealth(things)
   table.sort(things, function(a,b) return a.health < b.health end)
   return things
end

function SortByDistance(things, target)
   table.sort(things, 
      function(a,b)
         if not b or not b.x then return false end
         if not a or not a.x then return true end
         return GetDistance(a, target) < GetDistance(b, target) 
      end
   )
   return things
end

function SortByAngle(things)
   table.sort(things, function(a,b) return AngleBetween(me, a) < AngleBetween(me, b) end)
   return things
end

function GetCircleLocs(center, dist)
   local num = 16

   local locs = {}
   for i=1,num,1 do
      local angle = 2*math.pi/num*i
      local loc = ProjectionA(center, angle, dist)
      table.insert(locs, loc)
   end
   return locs
end
