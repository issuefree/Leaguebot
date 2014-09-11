require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Karthus")

InitAAData({
   projSpeed = 1.25, windup=.55,
   extraRange=-15,
   particles = {"Karthus_Base_AA_tar", "Karthus_Base_AA_mis"},
})

AddToggle("tear", {on=true, key=112, label="Tear"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Waste Minions", auxLabel="{0}", args={"lay"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["lay"] = {
   key="Q", 
   range=900-25, 
   color=violet, 
   base={40,60,80,100,120}, 
   ap=.3, 
   radius=137.5,
   delay=7,
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

   if me.dead == 1 then
      Action()
   end

   if StartTickActions() then
      return true
   end

   Circle(GetMousePos(), spells["lay"].radius, red)

   if CastAtCC("lay") then
      return true
   end   

   if CanUse("defile") and P.defile then
      if #GetInRange(me, spells["defile"].range+50, ENEMIES, MINIONS, CREEPS, PETS) == 0 then
         CastBuff("defile", false)
      end
   end

   if IsOn("tear") and CanChargeTear() and 
      CanUse("lay") and GetMPerc(me) > .66 and
      Alone()
   then
      if #GetInRange(me, spells["defile"].range+50, ENEMIES, MINIONS, CREEPS) == 0 then
         CastXYZ("lay", GetCastPoint(mousePos, "lay"))
         return true
      end
   end
      
   if HotKey() then
      if Action() then
         return true
      end
   end
            
   
   if IsOn("lasthit") and Alone() and CanUse("lay") then
      if KillMinionsInArea("lay", 1) then
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

   if IsOn("tear") then
      if CanChargeTear() then
         if HitMinionsInArea("lay", 1) then
            return true
         end
      end
   end

   EndTickActions()
end

function Action()
   if CanUse("defile") and not P.defile then
      local target = GetWeakEnemy("MAGIC", spells["defile"].range-50)   
      if target then
         CastBuff("defile")
      end
   end

   if SkillShot("lay") then
      -- StartChannel(.5)
      return true
   end
   
   if CanUse("lay") then
      local hits, kills, score = GetBestArea(me, "lay", 1, 1, ENEMIES, PETS)
      if #hits > 0 then
         CastXYZ("lay", GetCastPoint(hits, "lay"))
         PrintAction("lay for AoE")
         return true
      end
   end

   return false
end


local function onObject(object)
   PersistBuff("defile", object, "Karthus_Base_E_Defile.troy", 100)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
