require "issuefree/timCommon"
require "issuefree/modules"

print("\nTim's Sivir")

AddToggle("block", {on=true, key=112, label="SpellShield"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["boomerang"] = {
   key="Q", 
   range=1000, 
   color=violet, 
   base={25,45,65,85,105}, 
   ap=.5, 
   ad={.7,.8,.9,1,1.1},
   type="P",
   delay=2.4,  -- testskillshot
   speed=14,   -- testskillshot
   width=100,
   noblock=true,
   overShoot=-200,
   cost={70,80,90,100,110}
}
spells["doubleMinBoomerang"] = copy(spells["boomerang"])
spells["doubleMinBoomerang"].base = mult(spells["boomerang"].base, .8)
spells["doubleMinBoomerang"].ad = mult(spells["boomerang"].ad, .8)
spells["doubleMinBoomerang"].ap = spells["boomerang"].ap*.8

spells["ricochet"] = {
   key="W",
   cost=40,
   ad={.5,.55,.6,.65,.7},
   bounceRange=400 --?
}
spells["shield"] = {
   key="E",
   range=10  
}
spells["hunt"] = {
   key="R",
   cost=100
}

function Run()
   if StartTickActions() then
      return true
   end

   if CastAtCC("boomerang") then
      return true
   end

   if HotKey() and CanAct() then
      if Action() then
         return true
      end
   end

   if IsOn("lasthit") then
      if Alone() then

         if CanUse("boomerang") then
            if KillMinionsInLine("doubleMinBoomerang") then
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

   EndTickActions()
end

function Action()
   -- TestSkillShot("boomerang")

   if CanUse("ricochet") then      
      if JustAttacked() and GetWeakestEnemy("AA") then
         Cast("ricochet", me)
         PrintAction("Ricochet for aa reset")
         return true
      end
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end

   if SkillShot("boomerang") then
      return true
   end

   return false
end

function FollowUp()
   if IsOn("clear") then
      if Alone() then
         if CanUse("ricochet") and GetMPerc(me) > .5 then
            if #GetInRange(me, "AA", MINIONS) >= 3 then
               Cast("ricochet", me)
               PrintAction("ricochet for clear")
               return true
            end
         end
      end
   end

   return false
end

local function onSpell(unit, spell)
   if IsOn("block") then
      CheckShield("shield", unit, spell, "SPELL")
   end
end

AddOnSpell(onSpell)
SetTimerCallback("Run")