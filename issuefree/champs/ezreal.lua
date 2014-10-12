require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Ezreal")

SetChampStyle("marksman")

InitAAData({ 
   projSpeed = 2.0, windup=.2,
   minMoveTime=0,
   extraRange=-25,
   particles = {"Ezreal_basicattack_mis", "Ezreal_critattack_mis"}
})

AddToggle("harrass", {on=true, key=112, label="Harrass"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("tear", {on=true, key=114, label="Charge tear"})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Farm", auxLabel="{0} / {1}", args={GetAADamage, "shot"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["shot"] = {
   key="Q", 
   range=1100, 
   width=75, 
   color=violet, 
   base={35,55,75,95,115}, 
   ad=1.1, 
   ap=.4,
   delay=2.3,
   speed=20,    
   type="P",
   onHit=true,
   cost={28,31,34,37,40},
   particle="Ezreal_mysticshot_mis",
   spellName="EzrealMysticShot"
}
spells["flux"] = {
   key="W", 
   range=900, 
   color=yellow, 
   base={70,115,160,205,250}, 
   ap=.8,
   delay=2.3,
   speed=16,
   noblock=true,
   width=75,
   cost={50,60,70,80,90}
}
spells["arrow"] = {
   key="E", 
   range=475+750, 
   color=yellow, 
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
   delay=9,
   speed=20,
   width=150,
   range=99999,
   noblock=true,
   cost=100
}


function Run()
   if StartTickActions() then
      return true
   end

   if IsOn("tear") then
      UseItem("Muramana")
   end

   -- TODO something with ult
--   local target = GetWeakEnemy("MAGIC", 99999)
--   if target then
--      Circle(GetFireahead(target, 1.2, 20),100, red )
--   end

   if HotKey() and CanAct() then
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
      if KillMinion("shot") then
         return true
      end
   end

   if IsOn("clear") then
   end

   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()
   -- TestSkillShot("shot")
   -- TestSkillShot("flux")
   -- TestSkillShot("barrage", "Trueshot")

   local minFluxLevel = 1
   -- flux enemy if flux is over level 1 (waste of mana at low levels)
   if GetSpellLevel("W") >= minFluxLevel then
      if SkillShot("flux") then
         return true
      end
   end
   
   if SkillShot("shot") then -- in case harass is off
      return true
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end

   return false
end

function FollowUp()
   return false
end

local function onObject(object)
end

local function onSpell(unit, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
