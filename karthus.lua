require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Karthus")

AddToggle("farm", {on=true, key=112, label="Waste Minions", auxLabel="{0}", args={"lay"}})

spells["lay"] = {
   key="Q", 
   range=875, 
   color=violet, 
   base={40,60,80,100,120}, 
   ap=.3, 
   radius=137.5,
   delay=5,
   speed=0,
   cost={20,26,32,38,44}
}
spells["wall"] = {
   key="W", 
   range=1000, 
   color=yellow,
   cost=100
}
spells["defile"] = {
   key="E", 
   range=550, 
   color=yellow, 
   base={30,50,70,90,110}, 
   ap=.2
}
spells["ult"] = {
   key="R", 
   base={250,400,550}, 
   ap=.6,
   cost={150,175,200}
}

local function getLayFireAhead(target)
   return GetFireahead(target,5,999)
end

function Run()
   if IsRecalling(me) then
      return
   end

   local target = GetWeakEnemy("MAGIC", 90000) 
   if target and CanUse("ult") and GetSpellDamage("ult", target) > target.health then
      PlaySound("Beep")
   end 
     
   if HotKey() then
      UseItems()
      if Action() then
         return true
      end
   end
            
   Circle(GetMousePos(), spells["lay"].radius, red)
   
   if IsOn("farm") and Alone() and CanUse("lay") then
      local wMinion = nil
      local wMinionK = 0
      local wMinionX = {}

      local nearMinions = GetInRange(me, spells["lay"].range, MINIONS)   
      for _,minion in ipairs(nearMinions) do
         local tK = 0
         local vnMinions = GetInRange(minion, spells["lay"].radius, nearMinions)
         if #vnMinions == 1 then
            if GetSpellDamage("lay", minion)*2 > minion.health then
               if not wMinion or wMinionK < 1 then
                  wMinion = minion
                  wMinionK = 1
                  local x, y, z = getLayFireAhead(wMinion)
                  wMinionX = {x=x,y=y,z=z}
                  Circle(wMinionX, spells["lay"].radius, red, 2)
               end
            end
         else
            for _,vnM in ipairs(vnMinions) do
               if GetSpellDamage("lay", vnM) > minion.health then
                  tK = tK + 1
               end
            end
            if wMinionK < tK then
               wMinion = minion
               wMinionK = tK
               local x, y, z = getLayFireAhead(wMinion)
               wMinionX = {x=x,y=y,z=z}
            end
         end
      end
      
      if wMinion then
         CastXYZ("lay", wMinionX)
         Circle(wMinionX, spells["lay"].radius, yellow)
      end
   end   
end

function Action()
   if CanUse("defile") then
      local target = GetWeakEnemy("MAGIC", spells["defile"].range-50)      
      if target and not P.defiling and CanUse("defile") then
         Cast("defile", me)
      end

      target = GetWeakEnemy("MAGIC", spells["defile"].range+50)
      if not target and P.defiling then
         Cast("defile", me)
      end
   end

   if CanUse("lay") then
      local target = GetWeakestEnemy("lay")
      if target then
         CastSpellFireahead("lay", target)
         PrintAction("Lay", target)
         return true
      end
   end
   
   
end


local function onObject(object)
   PersistBuff("defiling", object, "Defile_glow", 100)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
