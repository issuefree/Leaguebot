require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Karthus")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=112, label="Waste Minions", auxLabel="{0}", args={"lay"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["lay"] = {
   key="Q", 
   range=900-35, 
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
   ap=.2,
   extraCooldown=.75
}
spells["ult"] = {
   key="R", 
   base={250,400,550}, 
   ap=.6,
   cost={150,175,200},
   channel=true,
   name="KarthusFallenOne",
   object="Karthus_Base_R_Cas_Hand_Glow"
}

function Run()
   local target = GetWeakEnemy("MAGIC", 90000) 
   if target and CanUse("ult") and WillKill("ult", target) then
      LineBetween(GetMousePos(), target, 3)
      -- PlaySound("Beep")
   end 

   if StartTickActions() then
      return true
   end

   if CastAtCC("lay") then
      return true
   end   

   if CanUse("defile") and P.defile then
      if #GetInRange(me, spells["defile"].range+50, ENEMIES, MINIONS, CREEPS) == 0 then
         CastBuff("defile", false)
      end
   end

     
   if HotKey() or me.dead == 1 then
      if Action() then
         return true
      end
   end
            
   Circle(GetMousePos(), spells["lay"].radius, red)
   
   if IsOn("lasthit") and Alone() and CanUse("lay") then
      if KillMinionsInArea("lay", 1) then
         PrintAction("Lay minions in area")
         return true
      end

      local nearMinions = SortByHealth(GetInRange(me, "lay", MINIONS), "lay")
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

   EndTickActions()
end

function Action()
   if CanUse("defile") then
      local target = GetWeakEnemy("MAGIC", spells["defile"].range-50)   
      if target and not P.defile then
         CastBuff("defile")
      end
   end

   if CanUse("lay") then
      if SkillShot("lay") then
         StartChannel(.5)
         return true
      end
   end
   
end


local function onObject(object)
   PersistBuff("defile", object, "Karthus_Base_E_Defile.troy", 100)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
