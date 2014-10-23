require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Ashe")

SetChampStyle("marksman")

InitAAData({
   projSpeed = 2.0, windup = .25, -- can attack faster but seems to mess up move
   minMoveTime = .25, -- ashe can't get move commands too early for some reason
   particles = {"Ashe_Base_BA_mis", "Ashe_Base_Q_mis"},
   attacks = {"attack", "frostarrow"}
})

AddToggle("frost", {on=true, key=112, label="Auto frost"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "volley"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["frost"] = {
   key="Q"
}

spells["volley"] = {
   key="W", 
   range=1100, 
   color=violet, 
   base={40,50,60,70,80}, 
   ad=1,
   delay=2.5,
   speed=20,
   cone=50, -- wiki says 57.5 but through DrawSpellCone aagainst the reticle it's 50
   cost=60,
   width=25
}

spells["hawkshot"] = {
   key="E", 
   range={2500,3250,4000,4750,5500},
   color=blue
}

spells["arrow"] = {
   key="R",
   base={250,425,600}, 
   ap=1,
   delay=2.6,
   speed=16,
   width=160,
   radius=250,
   cost=100,
   particle="Ashe_Base_R_mis.troy",
   spellName="EnchantedCrystalArrow"
}

function Run()
   if StartTickActions() then
      return true
   end

   if IsOn("frost") then
      if GetMPerc(me) > .5 and CanChargeTear() or not Alone() then
         CastBuff("frost")
      else      
         CastBuff("frost", false)
      end
   end

   -- TODO should write an auto hawkshot for people that run into brush

   if HotKey() and CanAct() then
      if Action() then
         return true
      end
   end   

   if IsOn("lasthit") and Alone() then
      if KillMinionsInCone("volley") then
         return true
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
   -- TestSkillShot("arrow")

   if CastBest("volley") then
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
   PersistBuff("frost", object, "Ashe_Base_q_buf", 125)
end

local function onSpell(unit, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
