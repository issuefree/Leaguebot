require "issuefree/basicUtils"

Point = class()
function Point:__type()
    return "Point"
end

function Point:__init(a, b, c)
   if not a then
      return nil
   end
   if not b and not c then
      if not a.x then
         return nil
      end
      self.x = a.x+1-1
      if not a.y then
         self.y = 0
      else
         self.y = a.y+1-1
      end
      self.z = a.z+1-1
   elseif a and b and not c then
      self.x = a+1-1
      self.y = 0
      self.z = b+1-1
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

function Point:valid()
   return self.x and self.y and self.z
end

function Point:near(p)
   return GetDistance(self, p) < 25
end

function Point:unpack()
   return self.x, self.y, self.z
end

function Point:__tostring()
   if not self:valid() then
      return "(-)"
   end
   return "("..trunc(self.x,0)..","..trunc(self.y,0)..","..trunc(self.z,0)..")"
end

function Point:__concat(a)
    return tostring(self) .. tostring(a) 
end


function GetDistance(p1, p2)
   p2 = p2 or myHero
   if not p1 or not p1.x then
      if not p1 then
         pp("null p1")
      end
      if not p1.x then
         pp("Incomplete object")
         pp(p1)
      end
      print(debug.traceback())      
      return 99999 
   end
   if not p2.x then
      pp("Incomplete object")
      pp(p2)
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
   
   if a == 0 and b == 0 then
      return 0
   end

   if a > 0 and b < 0 then  -- q2
      angle = angle + (math.pi)
   elseif a < 0 and b < 0 then -- p3
      angle = angle + math.pi
   elseif a < 0 and b > 0 then -- q4
      angle = angle + 2*math.pi
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

function RelativeAngleRight(center, o1, o2)
   local a1 = AngleBetween(center, o1)
   local a2 = AngleBetween(center, o2)
   local ra = a2-a1

   if ra < 0 then
      ra = 2*math.pi + ra
   end
   return ra
end

-- return how far t is from the line between p1 and p2
function GetOrthDist(p1, t, p2)
   p2 = p2 or me
   local angleT = AngleBetween(p1, t) - AngleBetween(p2, p1)
   local h = GetDistance(p1, t)
   local d = h*math.sin(angleT)
   return math.abs(d)   
end

function GetOrthDistRight(p1, t, p2)
   p2 = p2 or me
   local angleT = AngleBetween(p1, t) - AngleBetween(p2, p1)
   local h = GetDistance(p1, t)
   local d = h*math.sin(angleT)
   return d
end

local function areaOfTriangleFromSides(a,b,c)
   local s = (a+b+c)/2
   return math.sqrt(s*(s-a)*(s-b)*(s-c))
end

local function heightOfTriangleFromAreaAndBase(area, base)
   return 2*area/base
end

function RadsToDegs(rads)
   return rads*180/math.pi
end

function DegsToRads(degs)
   return degs/360*math.pi*2
end

--[[
Returns the x,y,z of the center of the targes
--]]
function GetCenter(targets)
   if not targets or #targets == 0 then
      return nil
   end

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

-- Gives the angular center of a set of targets from the perspective of source
function GetAngularCenter(targets, source)
   source = source or me
   if not targets or #targets == 0 then return nil end
   if #targets == 1 then return Point(targets[1]) end

   local l,r
   local maxAngle

   for _,t1 in ipairs(targets) do
      for _,t2 in ipairs(targets) do
         local ra = RelativeAngle(source, t1, t2)
         if not maxAngle or ra > maxAngle then
            l = t1
            r = t2
            maxAngle = ra
         end
      end
   end   

   return GetCenter({l, r})
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

function GetUnblocked(thing, source, ...)
   assert(type(source) ~= "table")

   local targets = GetInRange(source, thing, concat(...))

   local blocked = {}
   for _,target in ipairs(targets) do
      if IsBlocked(target, thing, source, concat(...)) then
         table.insert(blocked, target)
         break
      end      
   end

   return removeItems(targets, blocked)
end

function IsBlocked(target, thing, source, ...)
   local spell = GetSpell(thing)
   local width = spell.width or spell.radius*2
   for _,blocker in ipairs(concat(...)) do
      if GetDistance(source, target) > GetDistance(source, blocker) then
         local blockPoint = Projection(source, target, GetDistance(source, blocker))
         if GetDistance(blocker, blockPoint) < (width/2 + GetWidth(blocker)/2) then
            -- pp(blocker.name.." blocking "..target.name)
            return true
         end
      end
   end
   return false
end

function IsUnblocked(target, thing, source, ...)
   return not IsBlocked(target, thing, source, concat(...))
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

function RetreatingFrom(target)
   if not CURSOR then return false end

   return GetDistance(CURSOR) > 500 and 
          GetDistance(target) < GetDistance(CURSOR, target) and
          GetDistance(CURSOR) < GetDistance(CURSOR, target)
end

-- function Chasing(enemy)
--    return true
--    -- if I was closer last tick than i was the tick before then I'm chasing
--    -- return GetDistance(myPos[1], enemy) > GetDistance(myPos[2], enemy)
--    -- return GetDistance(CURSOR) > GetDistance(CURSOR, enemy)
-- end

function GetMousePos()
   return Point(GetCursorWorldX(), GetCursorWorldY(), GetCursorWorldZ())
end

function Skirmishing(target)
   target = target or me
   -- there are multiple enemies in AA range of multiple nearby allies
   local nearAllies = GetInRange(target, 1000, ALLIES)
   if #nearAllies < 2 then
      return false
   end
   local skirmishingAllies = 0
   for _,ally in ipairs(nearAllies) do
      if #GetInRange(ally, GetAARange(ally)+100, ENEMIES) >= 2 then
         skirmishingAllies = skirmishingAllies + 1         
      end
   end

   if skirmishingAllies >= 2 then
      return true
   end
   return false
end
function Engaged(target)
   target = target or me
   local engageRange = math.max(target.range+50, 400)
   return #GetInRange(target, engageRange, ENEMIES) > 0
end
-- this is used for "Can I hit minions with stuff" as much as really being "alone"
-- at low levels we want to last hit stuff over saving stuff for enemies
function Alone(target)  
   target = target or me

   if target.selflevel <= 5 then
      return not Engaged()
   end

   local aloneRange = 750+(target.selflevel*25)
   return #GetInRange(target, aloneRange, ENEMIES) == 0
end
function VeryAlone(target)
   target = target or me
   local vAloneRange = (750+(me.selflevel*25))*1.5
   return #GetInRange(target, vAloneRange, ENEMIES) == 0
end

function UnderTower(target)
   if not target then target = me end
   return #GetInRange(target, 950, TURRETS) > 0
end

function UnderMyTower(target)
   if not target then target = me end
   return #GetInRange(target, 950, MYTURRETS) > 0
end

function IsInRange(thing, target, source)
   if not target then return false end
   local range
   if type(thing) ~= "number" then
      range = GetSpellRange(thing)
   else
      range = thing
   end
   return GetDistance(target, source) < range
end

function GetInRange(target, thing, ...)
   assert(type(target) == "table" or type(target) == "userdata")
   local range
   if type(thing) ~= "number" then
      range = GetSpellRange(thing)
   else
      range = thing
   end
   local result = {}
   local list = ValidTargets(concat(...))
   for _,test in ipairs(list) do
      if target and test and
         GetDistance(target, test) <= range 
      then
         table.insert(result, test)
      end
   end
   return result
end

function GetAllInRange(target, thing, ...)
   local range
   if type(thing) ~= "number" then
      range = GetSpellRange(thing)
   else
      range = thing
   end
   local result = {}
   local list = concat(...)
   for _,test in ipairs(list) do
      if target and test and test.x and
         GetDistance(target, test) < range 
      then
         table.insert(result, test)
      end
   end
   return result
end

function GetInLine(source, thing, point, targets)
   local spell = GetSpell(thing) or thing
   local width = spell.width or spell.radius*2

   return FilterList( targets, function(item)
                                  if RadsToDegs(RelativeAngle(source, point, item)) > 90 then
                                     return false
                                  end
                                  local od = GetOrthDist(source, item, point)
                                  return od < width/2 + GetWidth(item)/2
                               end )
end


function GetInLineR(source, thing, target, targets)
   local spell = GetSpell(thing) or thing
   local width = spell.width or spell.radius*2

   return FilterList( targets, function(item)
                                  local odr = GetOrthDistRight(source, item, target)
                                  return odr >= 0 and odr < width + GetWidth(target)/2 + GetWidth(item)/2
                               end )
end


-- this isn't really telemetry but...
function SortByHealth(things, thing, switch)
   local spell = GetSpell(thing)
   if not spell then
      table.sort(things, function(a,b) return a.health < b.health end)
   else      
      table.sort(things, function(a,b) return (a.health/GetSpellDamage(spell, a)) < (b.health/GetSpellDamage(spell, b)) end)
   end
   return things
end

-- this isn't really telemetry but...
function SortByMaxHealth(things, thing, switch)
   local spell = GetSpell(thing)
   if not spell then
      table.sort(things, function(a,b) return a.maxHealth < b.maxHealth end)
   else      
      table.sort(things, function(a,b) return (a.maxHealth/GetSpellDamage(spell, a)) < (b.maxHealth/GetSpellDamage(spell, b)) end)
   end
   if switch then
      return reverse(things)
   else
      return things
   end
end

function SortByDistance(things, target, switch)
   table.sort(things, 
      function(a,b)
         if not b or not b.x then return false end
         if not a or not a.x then return true end
         return GetDistance(a, target) < GetDistance(b, target) 
      end
   )
   if switch then
      return reverse(things)
   else
      return things
   end
end

function SortByAngle(things, target, switch)
   target = target or me
   table.sort(things, function(a,b) return AngleBetween(target, a) < AngleBetween(target, b) end)
   if switch then
      return reverse(things)
   else
      return things
   end
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

function GetInCone(source, angle, arc, ...)
   local proj = ProjectionA(source, angle, 100)
   return FilterList(concat(...), 
      function(item)
         return RelativeAngle(source, proj, item) < arc/2
      end
   )
end