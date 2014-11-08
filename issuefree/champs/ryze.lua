require "issuefree/timCommon"
require "issuefree/modules"

InitAAData({ 
   projSpeed = 2.4, windup=.25,
   particles = {"ManaLeach_mis"}
})

pp("Tim's Ryze")
pp(" - prison > overload > flux")
pp(" - lasthit w/overload depending on mana")
pp(" - clear w/overload/flux depending on mana")

SetChampStyle("caster")

spells["overload"] = {
   key="Q", 
   range=625, 
   color=violet, 
   base={40,60,80,100,120}, 
   ap=.4, 
   maxMana=.065,
   cost=60
}
spells["prison"] = {
   key="W", 
   range=601, 
   color=red,    
   base={60,95,130,165,200}, 
   ap=.6, 
   maxMana=.045,
   cost={60,70,80,90,100}
}
spells["flux"] = {
   key="E", 
   range=600, 
   color=violet, 
   base={50,70,90,110,130},  
   ap=.35, 
   maxMana=.01,
   cost={80,90,100,110,120}
}
spells["power"] = {
   key="R",
   radius=200
}

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "overload"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

function Run()
   if StartTickActions() then
      return true
   end

   if IsOn("tear") then
      UseItem("Muramana")
   end

   if HotKey() then
      if Action() then
         return true
      end
   end

   if IsOn("lasthit") and Alone() then
      if KillMinion("overload", nil, true) then
         return true
      end
   end

   if HotKey() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()
   if CanUse("prison") and CanUse("overload") and CanUse("flux") then
      UseItem("Deathfire Grasp", GetWeakestEnemy("overload"))
   end
   if CanUse("prison") then
      local target = GetWeakestEnemy("prison", 0, 15)
      if target then
         CheckPower(target)
         Cast("prison", target)
         PrintAction("Prison", target)
         return true
      end
   end

   if CanUse("overload") then
      local target = GetWeakestEnemy("overload", 0, 15)
      if target then
         CheckPower(target)
         Cast("overload", target)
         PrintAction("Overload", target)
         return true
      end
   end

   if CanUse("flux") then
      local target = GetWeakestEnemy("flux", 0, 15)
      if target then
         CheckPower(target)
         Cast("flux", target)
         PrintAction("Flux", target)
         return true
      end
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end

   return false   
end

function CheckPower(target)
   if CanUse("power") then
      if #GetInRange(target, spells["power"].radius, ENEMIES) > 0 then
         Cast("power", me)
         PrintAction("Power UP", nil, 1)
      end
   end
end

function FollowUp()
   if IsOn("clear") and Alone() then
      local minion = GetWeakest("overload", GetInRange(me, "overload", MINIONS))

      if minion then
         if ( CanChargeTear() and GetMPerc(me) > .5 ) or
            GetMPerc(me) > .75
         then
            if #GetInRange(minion, 200, minions) > 0 and CanUse("flux") then
               Cast("flux", minion)
               PrintAction("Flux for clear")
               return true
            end
         end
      end

      if HitMinion("AA", "strong") then
         return true
      end

   end

   return false
end

local function onObject(object)
end

local function onSpell(unit, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")