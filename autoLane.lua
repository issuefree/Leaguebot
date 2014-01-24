require "timCommon"

local loadTime = time()

function AutoLane()
   if not ModuleConfig.autolane or time() - loadTime < 5 then
      return
   end

   -- Circle(Projection(HOME, me, GetDistance(HOME, me)+500))
   local enemyTurret = SortByDistance(TURRETS, me)[1]

   if not enemyTurret or not enemyTurret.x then
      return
   end

   local myTurret = SortByDistance(MYTURRETS, enemyTurret)[1]

   if not myTurret then
      return
   end

   local pointMinion = SortByDistance(MYMINIONS, enemyTurret)[1]
   if not pointMinion then
      return
   end
   Circle(pointMinion)
   local p
   if pointMinion then
      p = Projection(HOME, pointMinion, GetDistance(HOME, pointMinion)-200)
   else
      p = Point(myTurret)
   end
   if p and not UnderTower(p) and GetDistance(p) > 150 then
      Circle(p)
      MoveToXYZ(p:unpack())
   -- Circle(pointMinion)
   end
   KillMinion("AA")
end

AddOnTick(AutoLane)