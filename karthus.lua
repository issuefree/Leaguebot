require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Karthus")

AddToggle("farm", {on=true, key=112, label="Waste Minions", auxLabel="{0}", args={"lay"}})

spells["lay"] = {
   key="Q", 
   range=900, 
   color=violet, 
   base={40,60,80,100,120}, 
   ap=.3, 
   radius=137.5,
   delay=7.5,
   speed=0,
   noblock=true,
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

function Run()
   local target = GetWeakEnemy("MAGIC", 90000) 
   if target and CanUse("ult") and WillKill("ult", target) then
      LineBetween(GetMousePos(), target, 3)
      -- PlaySound("Beep")
   end 

   if IsRecalling(me) then
      return
   end

   if CanUse("defile") and P.defiling then
      if #GetAllInRange(me, spells["defile"].range+50, ENEMIES, MINIONS, CREEPS) == 0 then
         Cast("defile", me)
         PrintAction("Defile off")
      end
   end

     
   if HotKey() then
      UseItems()
      if Action() then
         return true
      end
   end
            
   Circle(GetMousePos(), spells["lay"].radius, red)
   
   if IsOn("farm") and Alone() and CanUse("lay") then
      if KillMinionsInArea("lay", 1) then
         PrintAction("Lay minions in area")
         return true
      end

      local nearMinions = SortByHealth(GetInRange(me, "lay", MINIONS))
      for _,minion in ipairs(nearMinions) do
         if GetSpellDamage("lay", minion)*2 > minion.health then
            if #GetInRange(minion, spells["lay"].radius+5, nearMinions) == 1 then
               CastFireahead("lay", minion)
               PrintAction("Lay lone minion")
               return true
            end
         end
      end
   end
end

function Action()
   if CanUse("defile") then
      local target = GetWeakEnemy("MAGIC", spells["defile"].range-50)      
      if target and not P.defiling and CanUse("defile") then
         Cast("defile", me)
         PrintAction("Defile ON")
      end
   end

   if CanUse("lay") then
      local target = GetWeakestEnemy("lay")
      if target and IsGoodFireahead("lay", target) then
         CastFireahead("lay", target)
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
