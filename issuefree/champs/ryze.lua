require "Utils"
require "timCommon"
require "modules"

pp("Tim's Ryze")
pp(" - prison > overload > flux")
pp(" - lasthit w/overload depending on mana")
pp(" - clear w/overload/flux depending on mana")

local attackObject = "ManaLeach_mis"

spells["overload"] = {
   key="Q", 
   range=625, 
   color=violet, 
   base={60,85,110,135,160}, 
   ap=.4, 
   mana=.065,
   cost=60
}
spells["prison"] = {
   key="W", 
   range=601, 
   color=red,    
   base={60,95,130,165,200}, 
   ap=.6, 
   mana=.045,
   cost={60,70,80,90,100}
}
spells["flux"] = {
   key="E", 
   range=600, 
   color=violet, 
   base={50,70,90,110,130},  
   ap=.35, 
   mana=.01,
   cost={80,90,100,110,120}
}
spells["power"] = {
   key="R",
   radius=200
}

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "overload"}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

function Run()
   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return true
   end
   
   if HotKey() then
      UseItems()
      if Action() then
         return true
      end
   end

   if IsOn("lasthit") and Alone() then
      if ( CanChargeTear() and GetMPerc(me) > .33 ) or
         GetMPerc(me) > .5
      then
         if KillMinion("overload") then
            return true
         end
      end
   end

   if HotKey() then
      if FollowUp() then
         return true
      end
   end

end

function Action()   
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

   return false   
end

function CheckPower(target)
   if CanUse("power") then
      if #GetInRange(target, spells["power"].radius, ENEMIES) > 0 then
         Cast("power", me)
         PrintAction("Power UP")
      end
   end
end

function FollowUp()
   if IsOn("lasthit") and Alone() then
      if KillMinion("AA") then
         return true
      end
   end

   if IsOn("clearminions") and Alone() then
      local minions = SortByHealth(GetInRange(me, "overload", MINIONS))
      local minion = minions[#minions]

      if ( CanChargeTear() and GetMPerc(me) > .5 ) or
         GetMPerc(me) > .75
      then
         if #GetInRange(minion, 200, minions) > 0 and CanUse("flux") then
            Cast("flux", minion)
            PrintAction("Flux for clear")
            return true
         end
      end

      local minions = SortByHealth(GetInRange(me, "AA", MINIONS))
      if AA(minions[#minions]) then
         PrintAction("AA clear minions")
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