require "timCommon"
require "modules"

pp("\nTim's Ezreal")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("harrass", {on=true, key=113, label="Harrass"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("tear", {on=true, key=115, label="Charge tear"})

AddToggle("lasthit", {on=true, key=116, label="Farm", auxLabel="{0} / {1}", args={GetAADamage, "shot"}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["shot"] = {
   key="Q", 
   range=1100, 
   width=75, 
   color=violet, 
   base={35,55,75,95,115}, 
   ad=1, 
   ap=.2,
   delay=2,
   speed=20,    
   type="P",
   cost={28,31,34,37,40}
}
spells["flux"] = {
   key="W", 
   range=900, 
   color=yellow, 
   base={70,115,160,205,250}, 
   ap=.8,
   delay=2,
   speed=15,
   noblock=true,
   width=75,
   cost={50,60,70,80,90}
}
spells["arrow"] = {
   key="E", 
   range=475+750, 
   color=violet, 
   base={75,125,175,225,275}, 
   ap=.75
}
spells["shift"] = {
   key="E", 
   range=475, 
   color=green,
   cost=90
}
spells["barrage"] = {
   key="R", 
   base={350,500,650}, 
   ad=1, 
   ap=.9,
   delay=12,
   speed=20,
   width=150,
   range=99999,
   noblock=true,
   cost=100
}


function Run()
   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return true
   end
   if IsChannelling() then
      return true
   end

   if IsOn("tear") and not P.muramana then
      UseItem("Muramana", me)
   end

   -- TODO something with ult
--   local target = GetWeakEnemy("MAGIC", 99999)
--   if target then
--      Circle(GetFireahead(target, 1.2, 20),100, red )
--   end
  
   -- -- Circle(Projection(HOME, me, GetDistance(HOME, me)+500))
   -- local enemyTurret = SortByDistance(TURRETS, me)[1]
   -- local myTurret = SortByDistance(MYTURRETS, enemyTurret)[1]

   -- local pointMinion = SortByDistance(MYMINIONS, enemyTurret)[1]
   -- Circle(pointMinion)
   -- local p
   -- if pointMinion then
   --    p = Projection(HOME, pointMinion, GetDistance(HOME, pointMinion)-200)
   -- else
   --    p = Point(myTurret)
   -- end
   -- if p and not UnderTower(p) and GetDistance(p) > 150 then
   --    Circle(p)
   --    MoveToXYZ(p:unpack())
   -- -- Circle(pointMinion)
   -- end

   if HotKey() and CanAct() then
      UseItems()
      if Action() then
         return true
      end
   end

   if IsOn("harrass") then
      if SkillShot("shot") then
         return true
      end
   end
   
   if IsOn("tear") and CanUse("shot") and CanChargeTear() and VeryAlone() and GetMPerc(me) > .75 then
      local minion = SortByDistance(GetInRange(me, "shot", MINIONS))[1]
      if minion then
         CastXYZ("shot", minion)
      else
         CastXYZ("shot", GetMousePos())
      end
      PrintAction("Shot for charge")
      return true
   end


   if IsOn("lasthit") and Alone() then
      if CanUse("shot") then
         for _,minion in ipairs(SortByHealth(GetUnblocked(me, "shot", MINIONS))) do
            if WillKill("shot", minion) and
               ( JustAttacked() or
                 GetDistance(minion) > spells["AA"].range )
            then
               CastXYZ("shot", minion)
               PrintAction("Shot for lasthit")
               return true
            end
         end
      end
   end

   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end
   
end

function Action()
   local minFluxLevel = 0
   -- flux enemy if flux is over level 1 (waste of mana at low levels)
   if GetSpellLevel("W") > minFluxLevel then
      if SkillShot("flux") then
         return true
      end
   end
   
   if SkillShot("shot") then -- in case harass is off
      return true
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AA(target) then
      PrintAction("AA", target)
      return true
   end

   return false
end

function FollowUp()
   if IsOn("lasthit") and Alone() then
      if KillMinion("AA") then
         return true
      end
   end

   if IsOn("clearminions") and Alone() then
      if HitMinion("AA", "strong") then
         return true
      end
   end

   if IsOn("move") then
      if RangedMove() then
         return true
      end
   end
end

local function onObject(object)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
